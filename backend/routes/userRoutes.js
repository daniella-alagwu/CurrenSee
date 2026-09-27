import express from "express";
import { createUser, sendOtp, verifyOtp } from "../controllers/userController.js";
import { requireAuth } from "../middleware/authMiddleware.js";

const router = express.Router();

router.post("/create", requireAuth, createUser);
router.post("/otp/send", requireAuth, sendOtp);
router.post("/otp/verify", requireAuth, verifyOtp);

export default router;