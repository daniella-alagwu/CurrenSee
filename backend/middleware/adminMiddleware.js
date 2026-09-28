export const requireAdmin = (req, res, next) => {
  if (req.firebaseUser?.admin !== true) {
    return res.status(403).json({
      error: {
        code: "ADMIN_REQUIRED",
        message: "Administrator access is required.",
      },
    });
  }

  next();
};
