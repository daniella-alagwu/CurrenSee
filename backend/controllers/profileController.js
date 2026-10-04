import db from "../config/db.js";

export const getCurrentUser = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.email, u.name, u.avatar, u.country_code AS countryCode,
              u.country_name AS countryName,
              p.default_base_currency AS defaultBaseCurrency,
              base.name AS defaultBaseCurrencyName,
              base.symbol AS defaultBaseCurrencySymbol,
              p.default_target_currency AS defaultTargetCurrency,
              target.name AS defaultTargetCurrencyName,
              target.symbol AS defaultTargetCurrencySymbol,
              p.push_enabled AS pushEnabled,
              p.alert_notifications_enabled AS alertNotificationsEnabled
       FROM users u
       LEFT JOIN user_preferences p ON p.user_id = u.id
       LEFT JOIN currencies base ON base.code = p.default_base_currency
       LEFT JOIN currencies target ON target.code = p.default_target_currency
       WHERE u.firebase_uid = ?
       LIMIT 1`,
      [req.firebaseUser.uid]
    );

    const row = rows[0];
    if (!row) {
      return res.status(404).json({
        error: { code: "PROFILE_NOT_FOUND", message: "Create your user profile first." },
      });
    }

    res.json({
      user: {
        id: row.id,
        email: row.email,
        name: row.name,
        avatar: row.avatar,
        countryCode: row.countryCode,
        countryName: row.countryName,
        preferences: {
          defaultBaseCurrency: row.defaultBaseCurrency,
          defaultBaseCurrencyName: row.defaultBaseCurrencyName,
          defaultBaseCurrencySymbol: row.defaultBaseCurrencySymbol,
          defaultTargetCurrency: row.defaultTargetCurrency,
          defaultTargetCurrencyName: row.defaultTargetCurrencyName,
          defaultTargetCurrencySymbol: row.defaultTargetCurrencySymbol,
          pushEnabled: row.pushEnabled,
          alertNotificationsEnabled: row.alertNotificationsEnabled,
        },
      },
    });
  } catch (err) {
    next(err);
  }
};

const bad = (res, code, message) => res.status(400).json({ error: { code, message } });
const MAX_AVATAR_CHARS = 90000; // stays under express.json()'s default 100kb body limit

export const updateProfile = async (req, res, next) => {
  const body = req.body ?? {};
  const sets = [];
  const values = [];

  if (Object.hasOwn(body, "name")) {
    const name = typeof body.name === "string" ? body.name.trim() : "";
    if (!name || name.length > 100) return bad(res, "INVALID_NAME", "Enter a name up to 100 characters.");
    sets.push("name = ?");
    values.push(name);
  }
  if (Object.hasOwn(body, "countryCode")) {
    if (typeof body.countryCode !== "string" || !/^[A-Za-z]{2}$/.test(body.countryCode)) {
      return bad(res, "INVALID_COUNTRY", "Choose a valid country.");
    }
    const countryName = typeof body.countryName === "string" ? body.countryName.trim().slice(0, 100) : null;
    sets.push("country_code = ?", "country_name = ?");
    values.push(body.countryCode.toUpperCase(), countryName || null);
  }
  if (Object.hasOwn(body, "avatar")) {
    const avatar = body.avatar;
    if (typeof avatar !== "string" || !avatar.startsWith("data:image/")) {
      return bad(res, "INVALID_AVATAR", "Upload a valid image.");
    }
    if (avatar.length > MAX_AVATAR_CHARS) return bad(res, "AVATAR_TOO_LARGE", "That image is too large.");
    sets.push("avatar = ?");
    values.push(avatar);
  }

  let currency = null;
  if (Object.hasOwn(body, "currencyCode")) {
    if (typeof body.currencyCode !== "string" || !/^[A-Za-z]{3}$/.test(body.currencyCode)) {
      return bad(res, "INVALID_CURRENCY", "Choose a valid currency.");
    }
    currency = body.currencyCode.toUpperCase();
  }
  if (sets.length === 0 && !currency) return bad(res, "NOTHING_TO_UPDATE", "Provide something to update.");

  const uid = req.firebaseUser.uid;
  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    const [users] = await connection.query("SELECT id FROM users WHERE firebase_uid = ?", [uid]);
    if (!users[0]) {
      await connection.rollback();
      return res.status(404).json({ error: { code: "PROFILE_NOT_FOUND", message: "Create your user profile first." } });
    }

    if (currency) {
      const [found] = await connection.query(
        "SELECT code FROM currencies WHERE code = ? AND is_active = TRUE",
        [currency]
      );
      if (!found[0]) {
        await connection.rollback();
        return bad(res, "UNSUPPORTED_CURRENCY", "That currency is not supported.");
      }
      await connection.query("INSERT IGNORE INTO user_preferences (user_id) VALUES (?)", [users[0].id]);
      // New base currency; if it collides with the target, move the target to USD (or EUR).
      await connection.query(
        `UPDATE user_preferences
         SET default_base_currency = ?,
             default_target_currency = IF(default_target_currency = ?, ?, default_target_currency)
         WHERE user_id = ?`,
        [currency, currency, currency === "USD" ? "EUR" : "USD", users[0].id]
      );
    }
    if (sets.length) {
      await connection.query(`UPDATE users SET ${sets.join(", ")} WHERE id = ?`, [...values, users[0].id]);
    }
    await connection.commit();
    res.json({ message: "Profile updated" });
  } catch (err) {
    if (connection) await connection.rollback();
    next(err);
  } finally {
    connection?.release();
  }
};