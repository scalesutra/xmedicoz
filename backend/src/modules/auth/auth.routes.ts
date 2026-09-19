import { Router } from "express";
import { AuthController } from "./auth.controller.js";
import { validate } from "../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import {
  LoginSchema,
  RequestOtpSchema,
  VerifyOtpSchema,
  RefreshTokenSchema,
  ResetPasswordSchema,
  UpdateProfileSchema,
  ChangePasswordSchema,
} from "./auth.schema.js";

export const authRouter = Router();

// Public Authentication Endpoints
authRouter.post("/login", validate(LoginSchema), AuthController.login);
authRouter.post("/request-otp", validate(RequestOtpSchema), AuthController.requestOtp);
authRouter.post("/verify-otp", validate(VerifyOtpSchema), AuthController.verifyOtp);
authRouter.post("/refresh", validate(RefreshTokenSchema), AuthController.refresh);
authRouter.post("/reset-password", validate(ResetPasswordSchema), AuthController.resetPassword);
authRouter.post("/logout", AuthController.logout);

// Protected Profile Endpoints (User must be authenticated via Keycloak JWT)
authRouter.get("/profile", authenticateKeycloakJwt, AuthController.getProfile);
authRouter.patch("/profile", authenticateKeycloakJwt, validate(UpdateProfileSchema), AuthController.updateProfile);
authRouter.post(
  "/change-password",
  authenticateKeycloakJwt,
  validate(ChangePasswordSchema),
  AuthController.changePassword
);
