import { Router } from "express";
import { OcrController } from "./ocr.controller.js";
import { validate } from "../../middleware/validation.middleware.js";
import { authenticateKeycloakJwt } from "../../middleware/auth.middleware.js";
import { tenantMiddleware } from "../../middleware/tenant.middleware.js";
import { ScanDocumentSchema } from "./ocr.schema.js";

export const ocrRouter = Router();

// OCR endpoint requires authentication and shop context
ocrRouter.use(authenticateKeycloakJwt, tenantMiddleware);

ocrRouter.post("/scan", validate(ScanDocumentSchema), OcrController.scanDocument);
