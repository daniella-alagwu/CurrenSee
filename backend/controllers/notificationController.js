import db from "../config/db.js";
import { broadcast } from "../utils/notifier.js";

const bad = (res, code, message) => res.status(400).json({ error: { code, message } });
const noProfile = (res) =>
  res.status(404).json({ error: { code: "PROFILE_NOT_FOUND", message: "Create your user profile first." } });

async function userId(uid) {
  const [rows] = await db.query("SELECT id FROM users WHERE firebase_uid = ?", [uid]);
  return rows[0]?.id ?? null;
}

/* ---------- device tokens ---------- */

export const registerDeviceToken = async (req, res, next) => {
  const { token, platform } = req.body ?? {};
  if (typeof token !== "string" || token.length < 20 || token.length > 512) {
    return bad(res, "INVALID_TOKEN", "Invalid device token.");
  }
  if (platform !== "android" && platform !== "ios") return bad(res, "INVALID_PLATFORM", "Invalid platform.");
  try {
    const id = await userId(req.firebaseUser.uid);
    if (!id) return noProfile(res);
    // A token belongs to one device; if another account signed in there, it moves to this user.
    await db.query(
      `INSERT INTO device_tokens (user_id, fcm_token, platform) VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), platform = VALUES(platform)`,
      [id, token, platform]
    );
    res.status(201).json({ message: "Device registered" });
  } catch (err) {
    next(err);
  }
};

export const removeDeviceToken = async (req, res, next) => {
  const token = req.body?.token;
  if (typeof token !== "string") return bad(res, "INVALID_TOKEN", "Invalid device token.");
  try {
    await db.query(
      `DELETE d FROM device_tokens d JOIN users u ON u.id = d.user_id
       WHERE d.fcm_token = ? AND u.firebase_uid = ?`,
      [token, req.firebaseUser.uid]
    );
    res.json({ message: "Device removed" });
  } catch (err) {
    next(err);
  }
};

/* ---------- notification inbox ---------- */

export const listNotifications = async (req, res, next) => {
  try {
    const [items] = await db.query(
      `SELECT n.id, n.title, n.body, n.type, n.is_read AS isRead, n.created_at AS createdAt
       FROM notifications n JOIN users u ON u.id = n.user_id
       WHERE u.firebase_uid = ? ORDER BY n.id DESC LIMIT 100`,
      [req.firebaseUser.uid]
    );
    const [[{ unread }]] = await db.query(
      `SELECT COUNT(*) AS unread FROM notifications n JOIN users u ON u.id = n.user_id
       WHERE u.firebase_uid = ? AND n.is_read = FALSE`,
      [req.firebaseUser.uid]
    );
    res.json({ items: items.map((i) => ({ ...i, isRead: !!i.isRead })), unread: Number(unread) });
  } catch (err) {
    next(err);
  }
};

export const markAllRead = async (req, res, next) => {
  try {
    await db.query(
      `UPDATE notifications n JOIN users u ON u.id = n.user_id
       SET n.is_read = TRUE WHERE u.firebase_uid = ? AND n.is_read = FALSE`,
      [req.firebaseUser.uid]
    );
    res.json({ message: "Marked as read" });
  } catch (err) {
    next(err);
  }
};

/* ---------- rate alerts ---------- */

const MAX_ACTIVE_ALERTS = 20;
const thresholdPattern = /^\d{1,10}(?:\.\d{1,8})?$/;

export const listAlerts = async (req, res, next) => {
  try {
    const [items] = await db.query(
      `SELECT a.id, a.base_code AS baseCode, a.target_code AS targetCode, a.threshold,
              a.direction, a.is_active AS isActive, a.triggered_at AS triggeredAt, a.created_at AS createdAt
       FROM rate_alerts a JOIN users u ON u.id = a.user_id
       WHERE u.firebase_uid = ? ORDER BY a.id DESC LIMIT 100`,
      [req.firebaseUser.uid]
    );
    res.json({ items: items.map((i) => ({ ...i, isActive: !!i.isActive })) });
  } catch (err) {
    next(err);
  }
};

export const createAlert = async (req, res, next) => {
  const { baseCode, targetCode, threshold, direction } = req.body ?? {};
  const base = typeof baseCode === "string" ? baseCode.toUpperCase() : "";
  const target = typeof targetCode === "string" ? targetCode.toUpperCase() : "";
  const thresholdText = String(threshold ?? "");
  if (!/^[A-Z]{3}$/.test(base) || !/^[A-Z]{3}$/.test(target) || base === target) {
    return bad(res, "INVALID_CURRENCY", "Pick two different currencies.");
  }
  if (!thresholdPattern.test(thresholdText) || Number(thresholdText) <= 0) {
    return bad(res, "INVALID_THRESHOLD", "Target rate must be positive with at most 8 decimal places.");
  }
  if (direction !== "ABOVE" && direction !== "BELOW") return bad(res, "INVALID_DIRECTION", "Choose above or below.");
  try {
    const id = await userId(req.firebaseUser.uid);
    if (!id) return noProfile(res);
    const [currencies] = await db.query(
      "SELECT code FROM currencies WHERE code IN (?, ?) AND is_active = TRUE",
      [base, target]
    );
    if (currencies.length !== 2) return bad(res, "UNSUPPORTED_CURRENCY", "One or both currencies are not supported.");
    const [[{ active }]] = await db.query(
      "SELECT COUNT(*) AS active FROM rate_alerts WHERE user_id = ? AND is_active = TRUE",
      [id]
    );
    if (Number(active) >= MAX_ACTIVE_ALERTS) {
      return bad(res, "TOO_MANY_ALERTS", `You can have up to ${MAX_ACTIVE_ALERTS} active alerts.`);
    }
    const [insert] = await db.query(
      "INSERT INTO rate_alerts (user_id, base_code, target_code, threshold, direction) VALUES (?, ?, ?, ?, ?)",
      [id, base, target, thresholdText, direction]
    );
    res.status(201).json({ id: insert.insertId });
  } catch (err) {
    next(err);
  }
};

export const deleteAlert = async (req, res, next) => {
  const alertId = Number.parseInt(req.params.id, 10);
  if (!Number.isInteger(alertId)) return bad(res, "INVALID_ALERT", "Invalid alert.");
  try {
    await db.query(
      `DELETE a FROM rate_alerts a JOIN users u ON u.id = a.user_id
       WHERE a.id = ? AND u.firebase_uid = ?`,
      [alertId, req.firebaseUser.uid]
    );
    res.json({ message: "Alert deleted" });
  } catch (err) {
    next(err);
  }
};

/* ---------- admin announcement ---------- */

export const sendAnnouncement = async (req, res, next) => {
  const title = typeof req.body?.title === "string" ? req.body.title.trim() : "";
  const body = typeof req.body?.body === "string" ? req.body.body.trim() : "";
  if (!title || title.length > 150 || !body || body.length > 500) {
    return bad(res, "INVALID_ANNOUNCEMENT", "Add a title (max 150) and a message (max 500).");
  }
  try {
    await broadcast({ title, body });
    res.status(201).json({ message: "Announcement sent" });
  } catch (err) {
    next(err);
  }
};