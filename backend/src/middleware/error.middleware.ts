import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import { AppError } from "../utils/errors.js";
import { sendError } from "../utils/response.js";
import { logger } from "../utils/logger.js";
import { ERROR_CODES } from "../config/constants.js";

export function centralErrorHandler(
  err: Error,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction
): void {
  // Schema Validation Error (Zod)
  if (err instanceof ZodError) {
    const errors = err.errors.map((e) => ({
      field: e.path.join("."),
      message: e.message,
    }));
    sendError(res, ERROR_CODES.VALIDATION_ERROR, "Validation failed", 400, errors);
    return;
  }

  // Operational AppError
  if (err instanceof AppError) {
    logger.warn(
      {
        err: err.message,
        code: err.code,
        statusCode: err.statusCode,
        url: req.originalUrl,
        method: req.method,
        requestId: req.headers["x-request-id"],
      },
      "Operational Error Handled"
    );

    sendError(res, err.code, err.message, err.statusCode, err.details);
    return;
  }

  // Unhandled / Internal Server Error
  logger.error(
    {
      err,
      url: req.originalUrl,
      method: req.method,
      requestId: req.headers["x-request-id"],
    },
    "Unhandled Internal Server Error"
  );

  // Strictly follow Section 5 of instruction.md: Never expose raw exception/stack details to clients
  sendError(
    res,
    ERROR_CODES.INTERNAL_SERVER_ERROR,
    "An unexpected internal error occurred. Please contact support.",
    500
  );
}
