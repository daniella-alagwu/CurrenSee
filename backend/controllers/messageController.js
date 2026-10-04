import db from "../config/db.js";
import { notifyUser } from "../utils/notifier.js";

const MAX_LEN = 1000;
const bad = (res, code, message) => res.status(400).json({ error: { code, message } });

function cleanBody(raw) {
  const body = typeof raw === "string" ? raw.trim() : "";
  return body && body.length <= MAX_LEN ? body : null;
}

/* ---------- user side ---------- */

export const getMyMessages = async (req, res, next) => {
  const uid = req.firebaseUser.uid;
  try {
    const [rows] = await db.query(
      `SELECT m.id, m.sender, m.body, m.created_at AS createdAt
       FROM support_messages m JOIN users u ON u.id = m.user_id
       WHERE u.firebase_uid = ?
       ORDER BY m.id DESC LIMIT 200`,
      [uid]
    );
    await db.query(
      `UPDATE support_messages m JOIN users u ON u.id = m.user_id
       SET m.is_read = TRUE
       WHERE u.firebase_uid = ? AND m.sender = 'ADMIN' AND m.is_read = FALSE`,
      [uid]
    );
    res.json({ items: rows.reverse() });
  } catch (err) {
    next(err);
  }
};

export const sendMyMessage = async (req, res, next) => {
  const body = cleanBody(req.body?.body);
  if (!body) return bad(res, "INVALID_MESSAGE", `Write a message up to ${MAX_LEN} characters.`);
  try {
    const [users] = await db.query("SELECT id FROM users WHERE firebase_uid = ?", [req.firebaseUser.uid]);
    if (!users[0]) {
      return res.status(404).json({ error: { code: "PROFILE_NOT_FOUND", message: "Create your user profile first." } });
    }
    const [insert] = await db.query(
      "INSERT INTO support_messages (user_id, sender, body) VALUES (?, 'USER', ?)",
      [users[0].id, body]
    );
    res.status(201).json({ id: insert.insertId });
  } catch (err) {
    next(err);
  }
};

/* ---------- admin side (mounted behind requireAdmin) ---------- */

export const listThreads = async (_req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id AS userId, u.name, u.email,
              (SELECT body FROM support_messages WHERE user_id = u.id ORDER BY id DESC LIMIT 1) AS lastMessage,
              MAX(m.created_at) AS lastAt,
              SUM(m.sender = 'USER' AND m.is_read = FALSE) AS unread
       FROM support_messages m JOIN users u ON u.id = m.user_id
       GROUP BY u.id, u.name, u.email
       ORDER BY lastAt DESC`
    );
    res.json({ items: rows.map((r) => ({ ...r, unread: Number(r.unread) || 0 })) });
  } catch (err) {
    next(err);
  }
};

export const getThread = async (req, res, next) => {
  const userId = Number.parseInt(req.params.userId, 10);
  if (!Number.isInteger(userId)) return bad(res, "INVALID_USER", "Invalid user.");
  try {
    const [rows] = await db.query(
      `SELECT id, sender, body, created_at AS createdAt
       FROM support_messages WHERE user_id = ? ORDER BY id DESC LIMIT 200`,
      [userId]
    );
    await db.query(
      "UPDATE support_messages SET is_read = TRUE WHERE user_id = ? AND sender = 'USER' AND is_read = FALSE",
      [userId]
    );
    res.json({ items: rows.reverse() });
  } catch (err) {
    next(err);
  }
};

export const adminReply = async (req, res, next) => {
  const userId = Number.parseInt(req.params.userId, 10);
  const body = cleanBody(req.body?.body);
  if (!Number.isInteger(userId)) return bad(res, "INVALID_USER", "Invalid user.");
  if (!body) return bad(res, "INVALID_MESSAGE", `Write a message up to ${MAX_LEN} characters.`);
  try {
    const [users] = await db.query("SELECT id FROM users WHERE id = ?", [userId]);
    if (!users[0]) return res.status(404).json({ error: { code: "USER_NOT_FOUND", message: "User not found." } });
    const [insert] = await db.query(
      "INSERT INTO support_messages (user_id, sender, body) VALUES (?, 'ADMIN', ?)",
      [userId, body]
    );
    notifyUser(userId, {
      title: "Support replied",
      body: body.length > 120 ? `${body.slice(0, 117)}…` : body,
      type: "SYSTEM",
    }).catch((err) => console.error("Reply notification failed:", err.message));
    res.status(201).json({ id: insert.insertId });
  } catch (err) {
    next(err);
  }
};