import { ERROR_CODES, type ErrorCode } from "../config/constants.js";

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: ErrorCode | string;
  public readonly isOperational: boolean;
  public readonly details?: unknown;

  constructor(
    message: string,
    statusCode: number = 500,
    code: ErrorCode | string = ERROR_CODES.INTERNAL_SERVER_ERROR,
    details?: unknown
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;
    this.details = details;
    Error.captureStackTrace(this, this.constructor);
  }

  static badRequest(message: string, code: ErrorCode | string = ERROR_CODES.BAD_REQUEST, details?: unknown) {
    return new AppError(message, 400, code, details);
  }

  static unauthorized(message: string = "Unauthorized access", code: ErrorCode | string = ERROR_CODES.UNAUTHORIZED) {
    return new AppError(message, 401, code);
  }

  static forbidden(message: string = "Permission denied", code: ErrorCode | string = ERROR_CODES.FORBIDDEN) {
    return new AppError(message, 403, code);
  }

  static notFound(message: string = "Resource not found", code: ErrorCode | string = ERROR_CODES.NOT_FOUND) {
    return new AppError(message, 404, code);
  }

  static conflict(message: string, code: ErrorCode | string = ERROR_CODES.CONFLICT) {
    return new AppError(message, 409, code);
  }

  static rateLimited(message: string = "Too many requests. Please try again later.") {
    return new AppError(message, 429, ERROR_CODES.RATE_LIMITED);
  }

  static internal(message: string = "An internal server error occurred") {
    return new AppError(message, 500, ERROR_CODES.INTERNAL_SERVER_ERROR);
  }
}
