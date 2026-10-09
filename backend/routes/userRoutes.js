import express from "express";

import {
  createUser,
  sendOtp,
  verifyOtp,
} from "../controllers/userController.js";

import {
  createConversion,
  getConversionHistory,
} from "../controllers/conversionController.js";

import {
  getPreferences,
  updatePreferences,
} from "../controllers/preferencesController.js";

import {
  getCurrentUser,
  updateProfile,
} from "../controllers/profileController.js";

import {
  getMyMessages,
  sendMyMessage,
  submitSuspensionAppeal,
} from "../controllers/messageController.js";

import {
  registerDeviceToken,
  removeDeviceToken,
  listNotifications,
  markAllRead,
  listAlerts,
  createAlert,
  deleteAlert,
} from "../controllers/notificationController.js";

import {
  requireAuth,
  requireActiveAccount,
} from "../middleware/authMiddleware.js";

import { getNews } from "../controllers/newsController.js";

const router = express.Router();

// Profile creation.
// Missing profiles are allowed through requireActiveAccount.
router.post("/create", requireAuth, requireActiveAccount, createUser);

// Account status must remain accessible so the frontend can show
// the suspension page instead of treating this as a normal login error.
router.get("/me", requireAuth, getCurrentUser);

// Suspended users must retain access to support conversations and appeals.
router.get("/messages", requireAuth, getMyMessages);
router.post("/messages", requireAuth, sendMyMessage);
router.post("/suspension-appeal", requireAuth, submitSuspensionAppeal);

// Email verification endpoints.
router.post("/otp/send", requireAuth, requireActiveAccount, sendOtp);

router.post("/otp/verify", requireAuth, requireActiveAccount, verifyOtp);

// Profile editing.
router.patch("/profile", requireAuth, requireActiveAccount, updateProfile);

// Preferences.
router.get("/preferences", requireAuth, requireActiveAccount, getPreferences);

router.patch(
  "/preferences",
  requireAuth,
  requireActiveAccount,
  updatePreferences,
);

// Currency conversion.
router.post(
  "/conversions",
  requireAuth,
  requireActiveAccount,
  createConversion,
);

router.get(
  "/conversions",
  requireAuth,
  requireActiveAccount,
  getConversionHistory,
);

// Device tokens.
router.post(
  "/device-token",
  requireAuth,
  requireActiveAccount,
  registerDeviceToken,
);

router.post(
  "/device-token/remove",
  requireAuth,
  requireActiveAccount,
  removeDeviceToken,
);

// Notifications.
router.get(
  "/notifications",
  requireAuth,
  requireActiveAccount,
  listNotifications,
);

router.post(
  "/notifications/read",
  requireAuth,
  requireActiveAccount,
  markAllRead,
);

// Rate alerts.
router.get("/alerts", requireAuth, requireActiveAccount, listAlerts);

router.post("/alerts", requireAuth, requireActiveAccount, createAlert);

router.post(
  "/alerts/:id/delete",
  requireAuth,
  requireActiveAccount,
  deleteAlert,
);

// News.
router.get("/news", requireAuth, requireActiveAccount, getNews);

export default router;
