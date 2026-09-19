import { Request, Response } from "express";
import { SmartSearchService } from "./smart-search.service.js";

export class SmartSearchController {
  static async search(req: Request, res: Response) {
    const shopId = (req as any).shopId || (req as any).user?.shopId;
    const { q, symptomOnly, inStockOnly, sortByMargin, limit } = req.query as any;

    const result = await SmartSearchService.smartSearch(shopId, {
      q: q as string,
      symptomOnly: symptomOnly === "true",
      inStockOnly: inStockOnly === "true",
      sortByMargin: sortByMargin === "true",
      limit: limit ? Number(limit) : 50,
    });

    res.json({
      success: true,
      data: result,
    });
  }

  static async getSubstitutes(req: Request, res: Response) {
    const shopId = (req as any).shopId || (req as any).user?.shopId;
    const { medicineId } = req.params;

    const result = await SmartSearchService.getSaltEquivalents(shopId, medicineId);

    res.json({
      success: true,
      data: result,
    });
  }

  static async logShortage(req: Request, res: Response) {
    const shopId = (req as any).shopId || (req as any).user?.shopId;
    const { medicineId, customerCount, notes } = req.body;

    const result = await SmartSearchService.logShortage(
      shopId,
      medicineId,
      customerCount || 1,
      notes
    );

    res.status(201).json({
      success: true,
      message: "Item recorded in Shortage Diary",
      data: result,
    });
  }

  static async listShortageDiary(req: Request, res: Response) {
    const shopId = (req as any).shopId || (req as any).user?.shopId;
    const { status } = req.query as { status?: string };

    const result = await SmartSearchService.listShortageDiary(shopId, status);

    res.json({
      success: true,
      data: result,
    });
  }

  static async updateShortageItem(req: Request, res: Response) {
    const shopId = (req as any).shopId || (req as any).user?.shopId;
    const { id } = req.params;

    const result = await SmartSearchService.updateShortageItem(shopId, id, req.body);

    res.json({
      success: true,
      message: "Shortage diary item updated",
      data: result,
    });
  }
}
