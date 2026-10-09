import db from "../config/db.js";
import { notifyUser } from "../utils/notifier.js";

const MAX_LEN = 1000;
const APPEAL_TAG = "ACCOUNT_SUSPENSION_APPEAL";

const bad = (res, code, message, status = 400) =>
  res.status(status).json({
    error: { code, message },
  });

function cleanBody(raw) {
  const body = typeof raw === "string" ? raw.trim() : "";
  return body && body.length <= MAX_LEN ? body : null;
}

/* ---------- user side ---------- */

export const getMyMessages = async (req, res, next) => {
  const uid = req.firebaseUser.uid;

  try {
    const [rows] = await db.query(
      `SELECT m.id, m.sender, m.body, m.tag,
              m.created_at AS createdAt
       FROM support_messages m
       JOIN users u ON u.id = m.user_id
       WHERE u.firebase_uid = ?
       ORDER BY m.id DESC
       LIMIT 200`,
      [uid],
    );

    await db.query(
      `UPDATE support_messages m
       JOIN users u ON u.id = m.user_id
       SET m.is_read = TRUE
       WHERE u.firebase_uid = ?
         AND m.sender = 'ADMIN'
         AND m.is_read = FALSE`,
      [uid],
    );

    res.json({ items: rows.reverse() });
  } catch (err) {
    next(err);
  }
};

export const sendMyMessage = async (req, res, next) => {
  const body = cleanBody(req.body?.body);

  if (!body) {
    return bad(
      res,
      "INVALID_MESSAGE",
      `Write a message up to ${MAX_LEN} characters.`,
    );
  }

  try {
    const [users] = await db.query(
      "SELECT id, status FROM users WHERE firebase_uid = ?",
      [req.firebaseUser.uid],
    );

    if (!users[0]) {
      return bad(
        res,
        "PROFILE_NOT_FOUND",
        "Create your user profile first.",
        404,
      );
    }

    // Anything a suspended user writes is treated as an appeal.
    const tag =
      String(users[0].status).toUpperCase() === "SUSPENDED" ? APPEAL_TAG : null;

    const [insert] = await db.query(
      `INSERT INTO support_messages (user_id, sender, body, tag)
       VALUES (?, 'USER', ?, ?)`,
      [users[0].id, body, tag],
    );

    res.status(201).json({ id: insert.insertId });
  } catch (err) {
    next(err);
  }
};

/**
 * Dedicated endpoint for suspended users to appeal.
 * The server assigns the tag; clients cannot choose arbitrary tags.
 */
export const submitSuspensionAppeal = async (req, res, next) => {
  const body = cleanBody(req.body?.body);

  if (!body) {
    return bad(
      res,
      "INVALID_APPEAL",
      `Write an appeal of up to ${MAX_LEN} characters.`,
    );
  }

  try {
    const [users] = await db.query(
      `SELECT id, status
       FROM users
       WHERE firebase_uid = ?
       LIMIT 1`,
      [req.firebaseUser.uid],
    );

    const user = users[0];

    if (!user) {
      return bad(
        res,
        "PROFILE_NOT_FOUND",
        "Your user profile could not be found.",
        404,
      );
    }

    if (String(user.status).toUpperCase() !== "SUSPENDED") {
      return bad(
        res,
        "ACCOUNT_NOT_SUSPENDED",
        "Only suspended accounts can submit a suspension appeal.",
        409,
      );
    }

    const [insert] = await db.query(
      `INSERT INTO support_messages (user_id, sender, body, tag)
       VALUES (?, 'USER', ?, ?)`,
      [user.id, body, APPEAL_TAG],
    );

    return res.status(201).json({
      id: insert.insertId,
      tag: APPEAL_TAG,
      message: "Your suspension appeal has been sent to the administrator.",
    });
  } catch (err) {
    next(err);
  }
};

//for admin

export const listThreads = async (_req, res, next) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id AS userId, u.name, u.email, u.status AS userStatus,
              (
                SELECT m2.body
                FROM support_messages m2
                WHERE m2.user_id = u.id
                ORDER BY m2.id DESC
                LIMIT 1
              ) AS lastMessage,
              (
                SELECT m3.tag
                FROM support_messages m3
                WHERE m3.user_id = u.id
                  AND m3.tag IS NOT NULL
                ORDER BY m3.id DESC
                LIMIT 1
              ) AS lastTag,
              MAX(m.created_at) AS lastAt,
              SUM(
                m.sender = 'USER' AND m.is_read = FALSE
              ) AS unread
       FROM support_messages m
       JOIN users u ON u.id = m.user_id
       GROUP BY u.id, u.name, u.email, u.status
       ORDER BY lastAt DESC`,
    );

    res.json({
      items: rows.map((row) => ({
        ...row,
        unread: Number(row.unread) || 0,
      })),
    });
  } catch (err) {
    next(err);
  }
};

export const getThread = async (req, res, next) => {
  const userId = Number.parseInt(req.params.userId, 10);

  if (!Number.isInteger(userId)) {
    return bad(res, "INVALID_USER", "Invalid user.");
  }

  try {
    const [rows] = await db.query(
      `SELECT id, sender, body, tag, created_at AS createdAt
       FROM support_messages
       WHERE user_id = ?
       ORDER BY id DESC
       LIMIT 200`,
      [userId],
    );

    await db.query(
      `UPDATE support_messages
       SET is_read = TRUE
       WHERE user_id = ?
         AND sender = 'USER'
         AND is_read = FALSE`,
      [userId],
    );

    res.json({ items: rows.reverse() });
  } catch (err) {
    next(err);
  }
};

export const adminReply = async (req, res, next) => {
  const userId = Number.parseInt(req.params.userId, 10);
  const body = cleanBody(req.body?.body);

  if (!Number.isInteger(userId)) {
    return bad(res, "INVALID_USER", "Invalid user.");
  }

  if (!body) {
    return bad(
      res,
      "INVALID_MESSAGE",
      `Write a message up to ${MAX_LEN} characters.`,
    );
  }

  try {
    const [users] = await db.query("SELECT id FROM users WHERE id = ?", [
      userId,
    ]);

    if (!users[0]) {
      return bad(res, "USER_NOT_FOUND", "User not found.", 404);
    }

    const [insert] = await db.query(
      `INSERT INTO support_messages (user_id, sender, body)
       VALUES (?, 'ADMIN', ?)`,
      [userId, body],
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
