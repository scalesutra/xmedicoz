import { spawn } from "node:child_process";
import path from "node:path";
import { prisma } from "../../infrastructure/database/prisma.client.js";
import { logger } from "../../utils/logger.js";
import { AppError } from "../../utils/errors.js";
import { ERROR_CODES } from "../../config/constants.js";
import type { OcrDocumentType } from "./ocr.schema.js";

const PYTHON_PATH = "/root/karratflow/ocr-service/venv/bin/python3";
const RUNNER_SCRIPT_PATH = path.resolve(process.cwd(), "scripts/medical_ocr_runner.py");

interface PythonOcrResult {
  success: boolean;
  rawText?: string;
  confidence?: number;
  documentType?: string;
  fields?: Record<string, any>;
  items?: Array<Record<string, any>>;
  error?: string;
}

export class OcrService {
  /**
   * Executes OCR processing on the supplied image using the isolated local runner
   */
  static async scanDocument(
    shopId: string,
    documentType: OcrDocumentType,
    image: string,
    options?: { hints?: string }
  ) {
    // 1. Run Python OCR subprocess
    const ocrOutput = await this.executePythonRunner({
      documentType,
      image,
      options,
    });

    if (!ocrOutput.success) {
      logger.error({ error: ocrOutput.error, documentType }, "OCR Runner execution error");
      throw new AppError(
        ocrOutput.error || "Failed to extract text from document",
        400,
        ERROR_CODES.BAD_REQUEST
      );
    }

    const fields: Record<string, any> = ocrOutput.fields || {};
    const items: Array<Record<string, any>> = ocrOutput.items || [];

    // 2. Database Enrichment based on document type
    if (documentType === "BATCH") {
      const candidate = (fields.candidateMedicine as string) || "";
      if (candidate) {
        // Search matching medicines in shop
        const matchedMedicines = await prisma.medicine.findMany({
          where: {
            shopId,
            status: "ACTIVE",
            OR: [
              { name: { contains: candidate.slice(0, 8), mode: "insensitive" } },
              { genericName: { contains: candidate.slice(0, 8), mode: "insensitive" } },
            ],
          },
          select: {
            id: true,
            name: true,
            genericName: true,
            dosageForm: true,
            strength: true,
            mrp: true,
          },
          take: 5,
        });

        fields.matchedMedicines = matchedMedicines;
        if (matchedMedicines.length > 0) {
          fields.matchedMedicineId = matchedMedicines[0].id;
          fields.matchedMedicineName = matchedMedicines[0].name;
        }
      }
    } else if (documentType === "CUSTOMER") {
      const mobile = fields.mobile as string | undefined;
      if (mobile) {
        const existing = await prisma.customer.findFirst({
          where: { shopId, mobile },
          select: { id: true, name: true, mobile: true, customerType: true },
        });
        if (existing) {
          fields.existingCustomer = existing;
        }
      }
    } else if (documentType === "SUPPLIER") {
      const gstin = fields.gstin as string | undefined;
      const mobile = fields.mobile as string | undefined;
      const conditions = [];
      if (gstin) conditions.push({ gstin });
      if (mobile) conditions.push({ mobile });

      if (conditions.length > 0) {
        const existing = await prisma.supplier.findFirst({
          where: {
            shopId,
            OR: conditions,
          },
          select: { id: true, name: true, gstin: true, mobile: true },
        });
        if (existing) {
          fields.existingSupplier = existing;
        }
      }
    } else if (documentType === "MEDICINE") {
      const name = fields.name as string | undefined;
      if (name) {
        const existing = await prisma.medicine.findFirst({
          where: { shopId, name: { equals: name, mode: "insensitive" } },
          select: { id: true, name: true, genericName: true, status: true },
        });
        if (existing) {
          fields.existingMedicine = existing;
        }
      }
    } else if (documentType === "BILL_PRESCRIPTION") {
      // Find matching medicines and available stock for each line item
      const enrichedItems = await Promise.all(
        items.map(async (item: any) => {
          const medName = item.medicineName || "";
          const firstWord = medName.split(" ")[0] || medName;

          const candidates = await prisma.medicine.findMany({
            where: {
              shopId,
              status: "ACTIVE",
              name: { contains: firstWord, mode: "insensitive" },
            },
            include: {
              batches: {
                where: {
                  status: "ACTIVE",
                  currentQuantity: { gt: 0 },
                },
                orderBy: { expiryDate: "asc" }, // FEFO
                take: 3,
              },
            },
            take: 3,
          });

          return {
            ...item,
            candidates: candidates.map((c) => ({
              id: c.id,
              name: c.name,
              genericName: c.genericName,
              dosageForm: c.dosageForm,
              strength: c.strength,
              batches: c.batches.map((b) => ({
                id: b.id,
                batchNumber: b.batchNumber,
                expiryDate: b.expiryDate,
                currentQuantity: b.currentQuantity,
                mrp: Number(b.mrp),
                sellingPrice: Number(b.sellingPrice),
              })),
            })),
          };
        })
      );

      return {
        rawText: ocrOutput.rawText || "",
        confidence: ocrOutput.confidence || 0.9,
        documentType,
        fields,
        items: enrichedItems,
      };
    } else if (documentType === "BILL_PURCHASE") {
      // Look up supplier match
      const supp = fields.supplier || {};
      const suppConditions = [];
      if (supp.gstin) suppConditions.push({ gstin: supp.gstin });
      if (supp.name) suppConditions.push({ name: { contains: supp.name.slice(0, 8), mode: "insensitive" as const } });

      if (suppConditions.length > 0) {
        const matchedSupplier = await prisma.supplier.findFirst({
          where: {
            shopId,
            OR: suppConditions,
          },
          select: { id: true, name: true, gstin: true, mobile: true },
        });
        if (matchedSupplier) {
          fields.matchedSupplier = matchedSupplier;
        }
      }

      // Match each line item to existing medicines using store catalog
      const enrichedPurchaseItems = await Promise.all(
        items.map(async (item: any) => {
          const medName = item.medicineName || "";
          const firstWord = medName.split(" ")[0] || medName;

          let match = null;
          // 1. Direct name lookup if first word is clean
          if (firstWord.length >= 3 && !["eee", "tab", "cap", "item", "sno"].includes(firstWord.toLowerCase())) {
            match = await prisma.medicine.findFirst({
              where: {
                shopId,
                name: { contains: firstWord, mode: "insensitive" },
              },
              select: { id: true, name: true, genericName: true },
            });
          }

          // 2. Intelligent Catalog Lookup by batch prefix (e.g. 'AZ' in 'AZ5001' -> 'Azithral')
          if (!match && item.batchNumber) {
            const batchPrefix = item.batchNumber.replace(/[^A-Za-z]/g, "");
            if (batchPrefix.length >= 2) {
              match = await prisma.medicine.findFirst({
                where: {
                  shopId,
                  name: { startsWith: batchPrefix, mode: "insensitive" },
                },
                select: { id: true, name: true, genericName: true },
              });
            }
          }

          return {
            ...item,
            medicineName: match ? match.name : medName,
            matchedMedicine: match || null,
          };
        })
      );

      return {
        rawText: ocrOutput.rawText || "",
        confidence: ocrOutput.confidence || 0.9,
        documentType,
        fields,
        items: enrichedPurchaseItems,
      };
    }

    return {
      rawText: ocrOutput.rawText || "",
      confidence: ocrOutput.confidence || 0.9,
      documentType,
      fields,
      items,
    };
  }

  /**
   * Spawns Python runner process
   */
  private static executePythonRunner(payload: {
    documentType: string;
    image: string;
    options?: any;
  }): Promise<PythonOcrResult> {
    return new Promise((resolve) => {
      const child = spawn(PYTHON_PATH, [RUNNER_SCRIPT_PATH], {
        env: {
          ...process.env,
          PYTHONUNBUFFERED: "1",
        },
      });

      let stdout = "";
      let stderr = "";

      child.stdout.on("data", (chunk) => {
        stdout += chunk.toString();
      });

      child.stderr.on("data", (chunk) => {
        stderr += chunk.toString();
      });

      child.on("close", (code) => {
        if (code !== 0 && !stdout) {
          return resolve({
            success: false,
            error: stderr || `OCR Runner exited with code ${code}`,
          });
        }

        try {
          const startIdx = stdout.indexOf("{");
          const endIdx = stdout.lastIndexOf("}");
          if (startIdx === -1 || endIdx === -1) {
            return resolve({
              success: false,
              error: `Invalid runner output: ${stdout || stderr}`,
            });
          }

          const parsed: PythonOcrResult = JSON.parse(stdout.slice(startIdx, endIdx + 1));
          resolve(parsed);
        } catch (err: any) {
          resolve({
            success: false,
            error: `Failed to parse runner JSON output: ${err.message}. Output: ${stdout}`,
          });
        }
      });

      child.on("error", (err) => {
        resolve({
          success: false,
          error: `Subprocess spawn error: ${err.message}`,
        });
      });

      // Send payload via stdin
      child.stdin.write(JSON.stringify(payload));
      child.stdin.end();
    });
  }
}
