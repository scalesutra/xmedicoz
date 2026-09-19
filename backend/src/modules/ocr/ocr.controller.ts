import type { Request, Response, NextFunction } from "express";
import { OcrService } from "./ocr.service.js";
import { sendSuccess } from "../../utils/response.js";

export class OcrController {
  static async scanDocument(req: Request, res: Response, next: NextFunction) {
    try {
      const { documentType, image, options } = req.body;
      const result = await OcrService.scanDocument(
        req.shopId!,
        documentType,
        image,
        options
      );
      sendSuccess(res, result, "Document scanned and parsed successfully");
    } catch (err) {
      next(err);
    }
  }
}
