import db from "../config/db.js";

const currencyCodePattern = /^[A-Za-z]{3}$/;
const amountPattern = /^\d{1,14}(?:\.\d{1,4})?$/;
const ratePattern = /^\d{1,10}(?:\.\d{1,8})?$/;

export const createConversion = async (req, res, next) => {
  const { uid } = req.firebaseUser;
  const { fromCode, toCode, amount, rateUsed } = req.body;
  const from = typeof fromCode === "string" ? fromCode.toUpperCase() : "";
  const to = typeof toCode === "string" ? toCode.toUpperCase() : "";
  const amountText = String(amount ?? "");
  const rateText = String(rateUsed ?? "");

  if (!currencyCodePattern.test(from) || !currencyCodePattern.test(to)) {
    return res.status(400).json({ error: { code: "INVALID_CURRENCY", message: "Use valid three-letter currency codes." } });
  }
  if (!amountPattern.test(amountText) || Number(amountText) <= 0) {
    return res.status(400).json({ error: { code: "INVALID_AMOUNT", message: "Amount must be positive with at most 4 decimal places." } });
  }
  if (!ratePattern.test(rateText) || Number(rateText) <= 0) {
    return res.status(400).json({ error: { code: "INVALID_RATE", message: "Rate must be positive with at most 8 decimal places." } });
  }

  try {
    const [users] = await db.query("SELECT id FROM users WHERE firebase_uid = ?", [uid]);
    if (!users[0]) {
      return res.status(404).json({ error: { code: "PROFILE_NOT_FOUND", message: "Create your user profile first." } });
    }

    const [currencies] = await db.query(
      "SELECT code FROM currencies WHERE code IN (?, ?) AND is_active = TRUE",
      [from, to]
    );
    if (currencies.length !== new Set([from, to]).size) {
      return res.status(400).json({ error: { code: "UNSUPPORTED_CURRENCY", message: "One or both currencies are not supported." } });
    }

    const resultValue = Number(amountText) * Number(rateText);
    if (!Number.isFinite(resultValue) || resultValue > 99999999999999.9999) {
      return res.status(400).json({
        error: { code: "RESULT_TOO_LARGE", message: "The converted amount is too large to save." },
      });
    }
    const result = resultValue.toFixed(4);
    const [insert] = await db.query(
      `INSERT INTO conversion_history (user_id, from_code, to_code, amount, rate_used, result)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [users[0].id, from, to, amountText, rateText, result]
    );
    res.status(201).json({
      id: insert.insertId,
      fromCode: from,
      toCode: to,
      amount: amountText,
      rateUsed: rateText,
      result,
    });
  } catch (err) {
    next(err);
  }
};

export const getConversionHistory = async (req, res, next) => {
  const requestedLimit = Number.parseInt(req.query.limit, 10);
  const requestedOffset = Number.parseInt(req.query.offset, 10);
  const limit = Number.isInteger(requestedLimit) && requestedLimit > 0 ? Math.min(requestedLimit, 100) : 50;
  const offset = Number.isInteger(requestedOffset) && requestedOffset >= 0 ? requestedOffset : 0;

  try {
    const [items] = await db.query(
      `SELECT h.id, h.from_code AS fromCode, h.to_code AS toCode,
              h.amount, h.rate_used AS rateUsed, h.result, h.created_at AS createdAt
       FROM conversion_history h
       JOIN users u ON u.id = h.user_id
       WHERE u.firebase_uid = ?
       ORDER BY h.created_at DESC, h.id DESC
       LIMIT ? OFFSET ?`,
      [req.firebaseUser.uid, limit, offset]
    );
    res.json({ items, limit, offset });
  } catch (err) {
    next(err);
  }
};
