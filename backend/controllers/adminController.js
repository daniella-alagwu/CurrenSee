export const getAdminIdentity = (req, res) => {
  res.json({
    uid: req.firebaseUser.uid,
    email: req.firebaseUser.email ?? null,
    role: "admin",
    primaryAdmin: req.firebaseUser.primaryAdmin === true,
  });
};
