import db from "../config/db.js";
import admin from "../config/firebaseAdmin.js";
import crypto from "crypto";
import { sendOtpEmail } from "../utils/mailer.js";

const OTP_TTL_MINUTES = 10;
const MAX_ATTEMPTS = 5;
const OTP_RESEND_COOLDOWN_SECONDS = 45;

function hashCode(code) {
  return crypto.createHash("sha256").update(code).digest("hex");
}

export const createUser = async (req, res, next) => {
  const { uid, email } = req.firebaseUser;
  const { name } = req.body;
  const countryCode = req.body.countryCode?.toUpperCase() || null;
  const countryName = req.body.countryName?.trim() || null;
  const currencyCode = req.body.currencyCode?.toUpperCase() || "USD";
  const currencyName = req.body.currencyName?.trim() || currencyCode;
  const currencySymbol = req.body.currencySymbol?.trim() || null;

  if (!email) {
    return res.status(400).json({
      error: { code: "EMAIL_REQUIRED", message: "The signed-in account has no email address." },
    });
  }
  if (countryCode && !/^[A-Z]{2}$/.test(countryCode)) {
    return res.status(400).json({
      error: { code: "INVALID_COUNTRY", message: "Choose a valid country." },
    });
  }
  if (!/^[A-Z]{3}$/.test(currencyCode)) {
    return res.status(400).json({
      error: { code: "INVALID_CURRENCY", message: "Choose a valid currency." },
    });
  }

  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    // Currency selection comes from the supported-currency picker. Ensure it
    // exists before writing preferences, which references currencies(code).
    if (req.body.currencyCode) {
      await connection.query(
        `INSERT INTO currencies (code, name, symbol) VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE name = VALUES(name), symbol = VALUES(symbol)`,
        [currencyCode, currencyName, currencySymbol]
      );
    }
    await connection.query(
      `INSERT INTO users (firebase_uid, email, name, country_code, country_name)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE email = VALUES(email),
         name = COALESCE(VALUES(name), name),
         country_code = COALESCE(VALUES(country_code), country_code),
         country_name = COALESCE(VALUES(country_name), country_name)`,
      [uid, email, name || null, countryCode, countryName]
    );
    await connection.query(
      `INSERT IGNORE INTO user_preferences (user_id)
       SELECT id FROM users WHERE firebase_uid = ?`,
      [uid]
    );
    await connection.query(
      `UPDATE user_preferences p
       JOIN users u ON u.id = p.user_id
       SET p.default_base_currency = ?
       WHERE u.firebase_uid = ? AND ? IS NOT NULL`,
      [currencyCode, uid, req.body.currencyCode ? currencyCode : null]
    );
    await connection.commit();
    res.status(201).json({ message: "User stored" });
  } catch (err) {
    if (connection) await connection.rollback();
    next(err);
  } finally {
    connection?.release();
  }
};


export const sendOtp = async (req, res, next) => {
  const { uid, email } = req.firebaseUser;

  try {
    const [previous] = await db.query(
      "SELECT created_at FROM email_otp_codes WHERE firebase_uid = ?",
      [uid]
    );
    if (previous[0]) {
      const secondsSinceLastSend =
        (Date.now() - new Date(previous[0].created_at).getTime()) / 1000;
      if (secondsSinceLastSend < OTP_RESEND_COOLDOWN_SECONDS) {
        return res.status(429).json({
          error: {
            code: "OTP_COOLDOWN",
            message: `Wait ${Math.ceil(OTP_RESEND_COOLDOWN_SECONDS - secondsSinceLastSend)} seconds before requesting another code.`,
          },
        });
      }
    }

    const code = String(crypto.randomInt(0, 1000000)).padStart(6, "0");
    const codeHash = hashCode(code);
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);

    await db.query(
      `INSERT INTO email_otp_codes (firebase_uid, code_hash, expires_at, attempts)
       VALUES (?, ?, ?, 0)
       ON DUPLICATE KEY UPDATE code_hash = VALUES(code_hash),
                               expires_at = VALUES(expires_at),
                               attempts = 0,
                               created_at = CURRENT_TIMESTAMP`,
      [uid, codeHash, expiresAt]
    );

    await sendOtpEmail(email, code);
    res.json({ message: "Code sent" });
  } catch (err) {
    next(err);
  }
};


export const verifyOtp = async (req, res, next) => {
  const { uid } = req.firebaseUser;
  const { code } = req.body;

  if (typeof code !== "string" || !/^\d{6}$/.test(code)) {
    return res
      .status(400)
      .json({ error: { code: "INVALID_CODE", message: "Enter the 6-digit code." } });
  }

  try {
    const [rows] = await db.query(
      "SELECT code_hash, expires_at, attempts FROM email_otp_codes WHERE firebase_uid = ?",
      [uid]
    );
    const record = rows[0];

    if (!record) {
      return res
        .status(400)
        .json({ error: { code: "NO_CODE", message: "Request a new code first." } });
    }
    if (new Date(record.expires_at) < new Date()) {
      return res.status(400).json({
        error: { code: "EXPIRED", message: "That code expired. Request a new one." },
      });
    }
    if (record.attempts >= MAX_ATTEMPTS) {
      return res.status(429).json({
        error: { code: "TOO_MANY_ATTEMPTS", message: "Too many attempts. Request a new code." },
      });
    }

    const actualHash = Buffer.from(hashCode(code), "hex");
    const expectedHash = Buffer.from(record.code_hash, "hex");
    if (
      actualHash.length !== expectedHash.length ||
      !crypto.timingSafeEqual(actualHash, expectedHash)
    ) {
      await db.query(
        "UPDATE email_otp_codes SET attempts = attempts + 1 WHERE firebase_uid = ?",
        [uid]
      );
      return res
        .status(400)
        .json({ error: { code: "WRONG_CODE", message: "That code is incorrect." } });
    }

    await admin.auth().updateUser(uid, { emailVerified: true });
    await db.query("DELETE FROM email_otp_codes WHERE firebase_uid = ?", [uid]);

    res.json({ message: "Email verified" });
  } catch (err) {
    next(err);
  }
};
