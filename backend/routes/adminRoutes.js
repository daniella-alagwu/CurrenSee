import express from "express";
import { getAdminIdentity } from "../controllers/adminController.js";
import { requireAuth } from "../middleware/authMiddleware.js";
import { requireAdmin } from "../middleware/adminMiddleware.js";

const router = express.Router();

router.get("/me", requireAuth, requireAdmin, getAdminIdentity);

export default router;
