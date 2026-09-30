import db from "../config/db.js";

const currencyPattern = /^[A-Za-z]{3}$/;
const columns = {
  defaultBaseCurrency: "default_base_currency",
  defaultTargetCurrency: "default_target_currency",
  pushEnabled: "push_enabled",
  alertNotificationsEnabled: "alert_notifications_enabled",
};

async function loadPreferences(uid) {
  const [rows] = await db.query(
    `SELECT p.default_base_currency AS defaultBaseCurrency,
            p.default_target_currency AS defaultTargetCurrency,
            p.push_enabled AS pushEnabled,
            p.alert_notifications_enabled AS alertNotificationsEnabled
     FROM user_preferences p JOIN users u ON u.id = p.user_id
     WHERE u.firebase_uid = ?`,
    [uid]
  );
  return rows[0] ?? null;
}

export const getPreferences = async (req, res, next) => {
  try {
    const preferences = await loadPreferences(req.firebaseUser.uid);
    if (!preferences) {
      return res.status(404).json({ error: { code: "PROFILE_NOT_FOUND", message: "Create your user profile first." } });
    }
    res.json({ preferences });
  } catch (err) {
    next(err);
  }
};

export const updatePreferences = async (req, res, next) => {
  const body = req.body ?? {};
  const allowed = Object.keys(columns);
  const supplied = allowed.filter((key) => Object.hasOwn(body, key));
  if (supplied.length === 0) {
    return res.status(400).json({ error: { code: "NO_PREFERENCES", message: "Provide at least one preference to update." } });
  }
  for (const key of ["defaultBaseCurrency", "defaultTargetCurrency"]) {
    if (Object.hasOwn(body, key) && (typeof body[key] !== "string" || !currencyPattern.test(body[key]))) {
      return res.status(400).json({ error: { code: "INVALID_CURRENCY", message: `${key} must be a three-letter currency code.` } });
    }
  }
  for (const key of ["pushEnabled", "alertNotificationsEnabled"]) {
    if (Object.hasOwn(body, key) && typeof body[key] !== "boolean") {
      return res.status(400).json({ error: { code: "INVALID_PREFERENCE", message: `${key} must be true or false.` } });
    }
  }

  try {
    const [users] = await db.query("SELECT id FROM users WHERE firebase_uid = ?", [req.firebaseUser.uid]);
    if (!users[0]) {
      return res.status(404).json({ error: { code: "PROFILE_NOT_FOUND", message: "Create your user profile first." } });
    }

    const requestedCurrencies = ["defaultBaseCurrency", "defaultTargetCurrency"]
      .filter((key) => Object.hasOwn(body, key))
      .map((key) => body[key].toUpperCase());
    if (requestedCurrencies.length) {
      const [currencies] = await db.query(
        `SELECT code FROM currencies WHERE is_active = TRUE AND code IN (${requestedCurrencies.map(() => "?").join(",")})`,
        requestedCurrencies
      );
      if (currencies.length !== new Set(requestedCurrencies).size) {
        return res.status(400).json({ error: { code: "UNSUPPORTED_CURRENCY", message: "Choose an active supported currency." } });
      }
    }

    await db.query("INSERT IGNORE INTO user_preferences (user_id) VALUES (?)", [users[0].id]);
    const assignments = supplied.map((key) => `${columns[key]} = ?`);
    const values = supplied.map((key) => typeof body[key] === "string" ? body[key].toUpperCase() : body[key]);
    values.push(users[0].id);
    await db.query(
      `UPDATE user_preferences SET ${assignments.join(", ")} WHERE user_id = ?`,
      values
    );
    res.json({ preferences: await loadPreferences(req.firebaseUser.uid) });
  } catch (err) {
    next(err);
  }
};
