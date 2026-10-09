import admin from "../config/firebaseAdmin.js";
import db from "../config/db.js";

export const requireAuth = async (req, res, next) => {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({
      error: {
        code: "NO_TOKEN",
        message: "Missing Authorization header.",
      },
    });
  }

  try {
    req.firebaseUser = await admin.auth().verifyIdToken(token);
    next();
  } catch (err) {
    return res.status(401).json({
      error: {
        code: "INVALID_TOKEN",
        message: "Invalid or expired token.",
      },
    });
  }
};

//blocking suspended users from accessing the app
export const requireActiveAccount = async (req, res, next) => {
  try {
    const [rows] = await db.query(
      "SELECT status FROM users WHERE firebase_uid = ? LIMIT 1",
      [req.firebaseUser.uid],
    );

    // Allow profile creation if this Firebase user has no MySQL profile.
    if (!rows.length) {
      return next();
    }

    const status = String(rows[0].status || "ACTIVE").toUpperCase();

    if (status === "SUSPENDED") {
      return res.status(403).json({
        error: {
          code: "ACCOUNT_SUSPENDED",
          message:
            "Your account is suspended. Please submit an appeal to the administrator.",
        },
        status: "SUSPENDED",
      });
    }

    return next();
  } catch (err) {
    return next(err);
  }
};
