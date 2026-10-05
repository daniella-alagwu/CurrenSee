import express from "express";
import { getAdminIdentity } from "../controllers/adminController.js";
import { listThreads, getThread, adminReply } from "../controllers/messageController.js";
import { sendAnnouncement } from "../controllers/notificationController.js";
import { requireAuth } from "../middleware/authMiddleware.js";
import { requireAdmin } from "../middleware/adminMiddleware.js";

const router = express.Router();

router.get("/me", requireAuth, requireAdmin, getAdminIdentity);
router.get("/messages/threads", requireAuth, requireAdmin, listThreads);
router.get("/messages/threads/:userId", requireAuth, requireAdmin, getThread);
router.post("/messages/threads/:userId", requireAuth, requireAdmin, adminReply);

router.post("/announcements", requireAuth, requireAdmin, sendAnnouncement);

export default router;