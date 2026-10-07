import express from "express";
import { getAdminIdentity } from "../controllers/adminController.js";
import { listThreads, getThread, adminReply } from "../controllers/messageController.js";
import { sendAnnouncement } from "../controllers/notificationController.js";
import { getStats, listUsers, getUser, userAction } from "../controllers/adminUsersController.js";
import { requireAuth } from "../middleware/authMiddleware.js";
import { requireAdmin } from "../middleware/adminMiddleware.js";

const router = express.Router();

router.get("/me", requireAuth, requireAdmin, getAdminIdentity);

// Support chat
router.get("/messages/threads", requireAuth, requireAdmin, listThreads);
router.get("/messages/threads/:userId", requireAuth, requireAdmin, getThread);
router.post("/messages/threads/:userId", requireAuth, requireAdmin, adminReply);

router.post("/announcements", requireAuth, requireAdmin, sendAnnouncement);

// Dashboard + user management
router.get("/stats", requireAuth, requireAdmin, getStats);
router.get("/users", requireAuth, requireAdmin, listUsers);
router.get("/users/:id", requireAuth, requireAdmin, getUser);
// :action = suspend | unsuspend | promote | demote | delete
router.post("/users/:id/:action", requireAuth, requireAdmin, userAction);

export default router;