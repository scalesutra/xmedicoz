import type { Response } from "express";
import { ERROR_CODES, type ErrorCode } from "../config/constants.js";

/**
 * Standard API Success Response
 * Follows Section 5 of instruction.md:
 * { success: true, data: result, message: "..." }
 */
export function sendSuccess<T>(
  res: Response,
  data: T,
  message: string = "Success",
  statusCode: number = 200
): Response {
  return res.status(statusCode).json({
    success: true,
    data,
    message,
  });
}

/**
 * Standard API Error Response
 * Follows Section 5 of instruction.md:
 * { success: false, error: { code: "...", message: "..." } }
 */
export function sendError(
  res: Response,
  code: ErrorCode | string = ERROR_CODES.INTERNAL_SERVER_ERROR,
  message: string = "An unexpected error occurred",
  statusCode: number = 500,
  details?: unknown
): Response {
  return res.status(statusCode).json({
    success: false,
    error: {
      code,
      message,
      ...(details !== undefined ? { details } : {}),
    },
  });
}
