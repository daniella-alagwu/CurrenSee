import express from "express";
import { createUser, sendOtp, verifyOtp } from "../controllers/userController.js";
import { createConversion, getConversionHistory } from "../controllers/conversionController.js";
import { getPreferences, updatePreferences } from "../controllers/preferencesController.js";
import { getCurrentUser } from "../controllers/profileController.js";
import { requireAuth } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/create", requireAuth, createUser);
router.post("/otp/send", requireAuth, sendOtp);
router.post("/otp/verify", requireAuth, verifyOtp);
router.get("/me", requireAuth, getCurrentUser);
router.get("/preferences", requireAuth, getPreferences);
router.patch("/preferences", requireAuth, updatePreferences);
router.post("/conversions", requireAuth, createConversion);
router.get("/conversions", requireAuth, getConversionHistory);

export default router;
