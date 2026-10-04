import db from "../config/db.js";
import admin from "../config/firebaseAdmin.js";

const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

/** Sends one push to many tokens (FCM max 500 per call) and prunes dead tokens. */
async function sendPush(tokens, { title, body, type }) {
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    try {
      const res = await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: { title, body },
        data: { type },
        android: { priority: "high" },
      });
      const dead = chunk.filter((_, idx) => !res.responses[idx].success && DEAD_TOKEN_CODES.has(res.responses[idx].error?.code));
      if (dead.length) await db.query("DELETE FROM device_tokens WHERE fcm_token IN (?)", [dead]);
    } catch (err) {
      console.error("Push failed:", err.message);
    }
  }
}

/**
 * Saves an in-app notification for the user, then pushes it to their devices
 * when they have "Push notifications" switched on.
 */
export async function notifyUser(userId, { title, body, type = "SYSTEM" }) {
  const t = String(title).slice(0, 150);
  const b = String(body).slice(0, 500);
  await db.query("INSERT INTO notifications (user_id, title, body, type) VALUES (?, ?, ?, ?)", [userId, t, b, type]);

  const [prefs] = await db.query("SELECT push_enabled FROM user_preferences WHERE user_id = ?", [userId]);
  if (prefs[0] && !prefs[0].push_enabled) return;
  const [tokens] = await db.query("SELECT fcm_token FROM device_tokens WHERE user_id = ?", [userId]);
  if (tokens.length) await sendPush(tokens.map((r) => r.fcm_token), { title: t, body: b, type });
}

/** Announcement to every user (admin tool). */
export async function broadcast({ title, body }) {
  const t = String(title).slice(0, 150);
  const b = String(body).slice(0, 500);
  await db.query("INSERT INTO notifications (user_id, title, body, type) SELECT id, ?, ?, 'SYSTEM' FROM users", [t, b]);
  const [rows] = await db.query(
    `SELECT d.fcm_token FROM device_tokens d
     LEFT JOIN user_preferences p ON p.user_id = d.user_id
     WHERE COALESCE(p.push_enabled, TRUE) = TRUE`
  );
  if (rows.length) await sendPush(rows.map((r) => r.fcm_token), { title: t, body: b, type: "SYSTEM" });
}