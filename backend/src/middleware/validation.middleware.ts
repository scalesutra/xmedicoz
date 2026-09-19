import type { Request, Response, NextFunction } from "express";
import { type ZodTypeAny, ZodError } from "zod";
import { sendError } from "../utils/response.js";
import { ERROR_CODES } from "../config/constants.js";

export function validate(schema: ZodTypeAny, source: "body" | "query" | "params" = "body") {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const validated = await schema.parseAsync(req[source]);
      req[source] = validated;
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        const errors = err.errors.map((e) => ({
          field: e.path.join("."),
          message: e.message,
        }));
        sendError(res, ERROR_CODES.VALIDATION_ERROR, "Validation failed", 400, errors);
        return;
      }
      next(err);
    }
  };
}
