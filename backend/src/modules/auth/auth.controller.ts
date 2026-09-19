import type { Request, Response, NextFunction } from "express";
import { AuthService } from "./auth.service.js";
import { KeycloakAuthService } from "../../infrastructure/keycloak/keycloak-auth.service.js";
import { sendSuccess } from "../../utils/response.js";
import { AppError } from "../../utils/errors.js";

export class AuthController {
  static async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { identifier, password } = req.body;
      const result = await AuthService.login(identifier, password);
      sendSuccess(res, result, "Login successful");
    } catch (err) {
      next(err);
    }
  }

  static async requestOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { identifier, channel, purpose } = req.body;
      const result = await AuthService.requestOtp(identifier, channel, purpose);
      sendSuccess(res, result, `OTP dispatched to ${channel.toLowerCase()} successfully`);
    } catch (err) {
      next(err);
    }
  }

  static async verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { identifier, code, channel, purpose } = req.body;
      const result = await AuthService.verifyOtp(identifier, code, channel, purpose);
      sendSuccess(res, result, "OTP verified successfully");
    } catch (err) {
      next(err);
    }
  }

  static async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;
      const tokens = await AuthService.refreshTokens(refreshToken);
      sendSuccess(res, tokens, "Tokens refreshed successfully");
    } catch (err) {
      next(err);
    }
  }

  static async resetPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { identifier, code, channel, newPassword } = req.body;
      const result = await AuthService.resetPassword(identifier, code, channel, newPassword);
      sendSuccess(res, result, "Password reset successfully");
    } catch (err) {
      next(err);
    }
  }

  static async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;
      if (refreshToken) {
        await KeycloakAuthService.logout(refreshToken);
      }
      sendSuccess(res, null, "Logged out successfully");
    } catch (err) {
      next(err);
    }
  }

  static async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw AppError.unauthorized();
      }
      const profile = await AuthService.getProfile(req.user.id);
      sendSuccess(res, profile, "Profile retrieved successfully");
    } catch (err) {
      next(err);
    }
  }

  static async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw AppError.unauthorized();
      }
      const updated = await AuthService.updateProfile(req.user.id, req.body);
      sendSuccess(res, updated, "Profile updated successfully");
    } catch (err) {
      next(err);
    }
  }

  static async changePassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        throw AppError.unauthorized();
      }
      const { currentPassword, newPassword } = req.body;
      await AuthService.changePassword(req.user.keycloakId, currentPassword, newPassword);
      sendSuccess(res, null, "Password changed successfully");
    } catch (err) {
      next(err);
    }
  }
}
