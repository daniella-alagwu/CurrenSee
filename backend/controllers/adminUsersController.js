import db from "../config/db.js";
import admin from "../config/firebaseAdmin.js";

const bad = (res, code, message, status = 400) => res.status(status).json({ error: { code, message } });
const ACTIONS = new Set(["suspend", "unsuspend", "promote", "demote", "delete"]);

export const getStats = async (_req, res, next) => {
  try {
    const [[row]] = await db.query(
      `SELECT
         (SELECT COUNT(*) FROM users) AS users,
         (SELECT COUNT(*) FROM users WHERE created_at >= NOW() - INTERVAL 7 DAY) AS newThisWeek,
         (SELECT COUNT(*) FROM users WHERE status = 'SUSPENDED') AS suspended,
         (SELECT COUNT(*) FROM users WHERE role = 'ADMIN') AS admins,
         (SELECT COUNT(*) FROM support_messages WHERE sender = 'USER' AND is_read = FALSE) AS unreadMessages`
    );
    res.json(Object.fromEntries(Object.entries(row).map(([k, v]) => [k, Number(v)])));
  } catch (err) {
    next(err);
  }
};

export const listUsers = async (req, res, next) => {
  const q = typeof req.query.q === "string" ? req.query.q.trim().slice(0, 100) : "";
  const reqLimit = Number.parseInt(req.query.limit, 10);
  const reqOffset = Number.parseInt(req.query.offset, 10);
  const limit = Number.isInteger(reqLimit) && reqLimit > 0 ? Math.min(reqLimit, 100) : 30;
  const offset = Number.isInteger(reqOffset) && reqOffset >= 0 ? reqOffset : 0;
  const like = `%${q.replace(/[\\%_]/g, "\\$&")}%`;
  const where = q ? "WHERE u.name LIKE ? OR u.email LIKE ?" : "";
  const params = q ? [like, like] : [];
  try {
    // avatar is left out on purpose: it is large and only needed on the detail screen
    const [items] = await db.query(
      `SELECT u.id, u.name, u.email, u.country_name AS countryName, u.role,
              u.is_primary_admin AS primaryAdmin, u.status, u.created_at AS createdAt
       FROM users u ${where} ORDER BY u.id DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );
    const [[{ total }]] = await db.query(`SELECT COUNT(*) AS total FROM users u ${where}`, params);
    res.json({ items, total: Number(total), limit, offset });
  } catch (err) {
    next(err);
  }
};

export const getUser = async (req, res, next) => {
  const id = Number.parseInt(req.params.id, 10);
  if (!Number.isInteger(id)) return bad(res, "INVALID_USER", "Invalid user.");
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.firebase_uid AS firebaseUid, u.email, u.name, u.avatar,
              u.country_code AS countryCode, u.country_name AS countryName,
              u.role, u.is_primary_admin AS primaryAdmin, u.status, u.created_at AS createdAt,
              p.default_base_currency AS baseCurrency,
              p.push_enabled AS pushEnabled, p.alert_notifications_enabled AS alertsEnabled,
              (SELECT COUNT(*) FROM conversion_history WHERE user_id = u.id) AS conversions,
              (SELECT COUNT(*) FROM rate_alerts WHERE user_id = u.id AND is_active = TRUE) AS activeAlerts,
              (SELECT COUNT(*) FROM support_messages WHERE user_id = u.id) AS messages,
              (SELECT COUNT(*) FROM device_tokens WHERE user_id = u.id) AS devices
       FROM users u LEFT JOIN user_preferences p ON p.user_id = u.id
       WHERE u.id = ?`,
      [id]
    );
    const row = rows[0];
    if (!row) return bad(res, "USER_NOT_FOUND", "User not found.", 404);

    let emailVerified = null;
    let lastSignIn = null;
    try {
      const fb = await admin.auth().getUser(row.firebaseUid);
      emailVerified = fb.emailVerified;
      lastSignIn = fb.metadata.lastSignInTime ? new Date(fb.metadata.lastSignInTime).toISOString() : null;
    } catch {
      /* Firebase record missing: leave unknown */
    }

    const { firebaseUid, ...user } = row;
    res.json({
      user: {
        ...user,
        conversions: Number(row.conversions),
        activeAlerts: Number(row.activeAlerts),
        messages: Number(row.messages),
        devices: Number(row.devices),
        pushEnabled: !!row.pushEnabled,
        alertsEnabled: !!row.alertsEnabled,
        emailVerified,
        lastSignIn,
        isSelf: firebaseUid === req.firebaseUser.uid,
        canManageAdmins: req.firebaseUser.primaryAdmin === true,
      },
    });
  } catch (err) {
    next(err);
  }
};

const ignoreMissing = async (promise) => {
  try {
    await promise;
  } catch (err) {
    if (err?.code !== "auth/user-not-found") throw err;
  }
};

export const userAction = async (req, res, next) => {
  const id = Number.parseInt(req.params.id, 10);
  const action = req.params.action;
  if (!Number.isInteger(id) || !ACTIONS.has(action)) return bad(res, "INVALID_REQUEST", "Invalid request.");

  try {
    const [rows] = await db.query(
      "SELECT id, firebase_uid AS uid, role, status, is_primary_admin AS primaryAdmin FROM users WHERE id = ?",
      [id]
    );
    const target = rows[0];
    if (!target) return bad(res, "USER_NOT_FOUND", "User not found.", 404);
    if (target.uid === req.firebaseUser.uid) {
      return bad(res, "SELF_ACTION", "You can't do that to your own account.");
    }
    const auth = admin.auth();
    let firebaseTarget;
    try {
      firebaseTarget = await auth.getUser(target.uid);
    } catch (err) {
      if (err?.code !== "auth/user-not-found") throw err;
    }
    if (target.primaryAdmin || firebaseTarget?.customClaims?.primaryAdmin === true) {
      return bad(res, "PRIMARY_ADMIN_PROTECTED", "The primary admin cannot be changed from the app.", 403);
    }
    if ((action === "promote" || action === "demote") && req.firebaseUser.primaryAdmin !== true) {
      return bad(res, "PRIMARY_ADMIN_REQUIRED", "Only the primary admin can change admin access.", 403);
    }
    if ((action === "suspend" || action === "delete") && target.role === "ADMIN") {
      if (req.firebaseUser.primaryAdmin !== true) {
        return bad(res, "PRIMARY_ADMIN_REQUIRED", "Only the primary admin can suspend or delete another admin.", 403);
      }
      return bad(res, "TARGET_IS_ADMIN", "Demote this admin before suspending or deleting the account.");
    }

    switch (action) {
      case "suspend":
        await ignoreMissing(auth.updateUser(target.uid, { disabled: true }));
        await ignoreMissing(auth.revokeRefreshTokens(target.uid)); // ends their sessions
        await db.query("UPDATE users SET status = 'SUSPENDED' WHERE id = ?", [id]);
        return res.json({ message: "Account suspended" });

      case "unsuspend":
        await ignoreMissing(auth.updateUser(target.uid, { disabled: false }));
        await db.query("UPDATE users SET status = 'ACTIVE' WHERE id = ?", [id]);
        return res.json({ message: "Account reactivated" });

      case "promote": {
        if (target.status !== "ACTIVE") return bad(res, "SUSPENDED", "Reactivate this account before promoting it.");
        if (!firebaseTarget) return bad(res, "FIREBASE_USER_NOT_FOUND", "Firebase account not found.", 404);
        if (!firebaseTarget.emailVerified) return bad(res, "EMAIL_NOT_VERIFIED", "Only verified accounts can be promoted.");
        const claims = { ...(firebaseTarget.customClaims ?? {}), admin: true };
        delete claims.primaryAdmin;
        await auth.setCustomUserClaims(target.uid, claims);
        await db.query("UPDATE users SET role = 'ADMIN', is_primary_admin = FALSE WHERE id = ?", [id]);
        return res.json({ message: "Account promoted to admin" });
      }

      case "demote": {
        if (!firebaseTarget) return bad(res, "FIREBASE_USER_NOT_FOUND", "Firebase account not found.", 404);
        const claims = { ...(firebaseTarget.customClaims ?? {}) };
        delete claims.admin;
        delete claims.primaryAdmin;
        await auth.setCustomUserClaims(target.uid, claims);
        await auth.revokeRefreshTokens(target.uid);
        await db.query("UPDATE users SET role = 'USER', is_primary_admin = FALSE WHERE id = ?", [id]);
        return res.json({ message: "Admin access removed" });
      }

      case "delete":
        await ignoreMissing(auth.deleteUser(target.uid));
        await db.query("DELETE FROM users WHERE id = ?", [id]); // cascades to history, alerts, chat, devices
        return res.json({ message: "Account deleted" });
    }
  } catch (err) {
    next(err);
  }
};
