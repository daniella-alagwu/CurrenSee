import express from "express";
import { createUser, sendOtp, verifyOtp } from "../controllers/userController.js";
import { createConversion, getConversionHistory } from "../controllers/conversionController.js";
import { getPreferences, updatePreferences } from "../controllers/preferencesController.js";
import { getCurrentUser, updateProfile } from "../controllers/profileController.js";
import { getMyMessages, sendMyMessage } from "../controllers/messageController.js";
import {
  registerDeviceToken, removeDeviceToken, listNotifications, markAllRead,
  listAlerts, createAlert, deleteAlert,
} from "../controllers/notificationController.js";
import { requireAuth } from "../middleware/authMiddleware.js";
import { getNews } from "../controllers/newsController.js";

const router = express.Router();

router.post("/create", requireAuth, createUser);
router.post("/otp/send", requireAuth, sendOtp);
router.post("/otp/verify", requireAuth, verifyOtp);
router.get("/me", requireAuth, getCurrentUser);
router.patch("/profile", requireAuth, updateProfile);
router.get("/preferences", requireAuth, getPreferences);
router.patch("/preferences", requireAuth, updatePreferences);
router.post("/conversions", requireAuth, createConversion);
router.get("/conversions", requireAuth, getConversionHistory);
router.get("/messages", requireAuth, getMyMessages);
router.post("/messages", requireAuth, sendMyMessage);

router.post("/device-token", requireAuth, registerDeviceToken);
router.post("/device-token/remove", requireAuth, removeDeviceToken);
router.get("/notifications", requireAuth, listNotifications);
router.post("/notifications/read", requireAuth, markAllRead);
router.get("/alerts", requireAuth, listAlerts);
router.post("/alerts", requireAuth, createAlert);
router.post("/alerts/:id/delete", requireAuth, deleteAlert);

router.get("/news", requireAuth, getNews);

export default router;