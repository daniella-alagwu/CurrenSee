import admin from "../config/firebaseAdmin.js";

export const requireAuth = async (req, res, next) => {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!token) {
    return res
      .status(401)
      .json({ error: { code: "NO_TOKEN", message: "Missing Authorization header." } });
  }

  try {
    req.firebaseUser = await admin.auth().verifyIdToken(token);
    next();
  } catch (err) {
    return res
      .status(401)
      .json({ error: { code: "INVALID_TOKEN", message: "Invalid or expired token." } });
  }
};