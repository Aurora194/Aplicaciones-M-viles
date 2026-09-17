import { Router } from "express";
import { chatAI } from "../controllers/ai.controller";
import { authenticateToken } from "../middleware/auth.middleware";

const router = Router();

router.post(
  "/chat",
  authenticateToken,
  chatAI,
);

export default router;