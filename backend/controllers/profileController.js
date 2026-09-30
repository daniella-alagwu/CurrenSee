import db from "../config/db.js";

export const getCurrentUser = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.email, u.name, u.country_code AS countryCode,
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
        error: {
          code: "PROFILE_NOT_FOUND",
          message: "Create your user profile first.",
        },
      });
    }

    res.json({
      user: {
        id: row.id,
        email: row.email,
        name: row.name,
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
