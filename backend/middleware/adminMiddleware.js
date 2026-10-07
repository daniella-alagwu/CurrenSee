import admin from "../config/firebaseAdmin.js";

export const requireAdmin = async (req, res, next) => {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({
      error: { code: "NO_TOKEN", message: "Missing Authorization header." },
    });
  }

  try {
   
    req.firebaseUser = await admin.auth().verifyIdToken(token, true);
    if (req.firebaseUser.admin !== true) {
      return res.status(403).json({
        error: {
          code: "ADMIN_REQUIRED",
          message: "Administrator access is required.",
        },
      });
    }
    next();
  } catch (_error) {
    return res.status(401).json({
      error: { code: "INVALID_TOKEN", message: "Invalid, expired, or revoked token." },
    });
  }
};
