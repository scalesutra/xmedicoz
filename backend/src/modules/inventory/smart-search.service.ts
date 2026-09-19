import { prisma } from "../../infrastructure/database/prisma.client.js";
import { AppError } from "../../utils/errors.js";

// Comprehensive Symptom Thesaurus & Clinical Synonym Map for Indian Chemist Shops
export const SYMPTOM_THESAURUS: Record<string, { terms: string[]; genericKeys: string[] }> = {
  cold: {
    terms: ["cold", "sardi", "jukham", "flu", "rhinitis", "coryza", "runny nose", "sneezing", "congestion"],
    genericKeys: ["cetirizine", "phenylephrine", "chlorpheniramine", "paracetamol", "fexofenadine", "montelukast"],
  },
  gas: {
    terms: ["gas", "acidity", "pet kharab", "heartburn", "gerd", "bloating", "flatulence", "indigestion", "acid reflux"],
    genericKeys: ["pantoprazole", "omeprazole", "rabeprazole", "antacid", "magaldrate", "simethicone", "esomeprazole", "gelusil", "digene"],
  },
  fever: {
    terms: ["fever", "bukhar", "temperature", "pyrexia", "body ache", "chills"],
    genericKeys: ["paracetamol", "acetaminophen", "mefenamic", "ibuprofen"],
  },
  pain: {
    terms: ["pain", "dard", "headache", "sar dard", "body pain", "backache", "muscle pain", "joint pain", "toothache"],
    genericKeys: ["paracetamol", "aceclofenac", "diclofenac", "tramadol", "ibuprofen", "etoricoxib", "serratiopeptidase"],
  },
  cough: {
    terms: ["cough", "khansi", "balgam", "dry cough", "wet cough", "phlegm", "bronchitis"],
    genericKeys: ["dextromethorphan", "ambroxol", "terbutaline", "guaiphenesin", "levosalbutamol", "chlorpheniramine"],
  },
  vomiting: {
    terms: ["vomiting", "ulti", "nausea", "motion sickness", "morning sickness"],
    genericKeys: ["ondansetron", "domperidone", "metoclopramide", "doxylamine"],
  },
  diarrhea: {
    terms: ["diarrhea", "loose motion", "dast", "dysentery", "stomach infection", "pet dard"],
    genericKeys: ["loperamide", "ofloxacin", "ornidazole", "ors", "zinc", "probiotic", "racecadotril"],
  },
  allergy: {
    terms: ["allergy", "khujli", "itching", "rash", "urticaria", "dermatitis", "skin allergy"],
    genericKeys: ["levocetirizine", "fexofenadine", "cetirizine", "bilastine", "calamine", "betamethasone"],
  },
};

export class SmartSearchService {
  /**
   * Search medicines by symptom, brand, generic name, or composition
   * with real-time margin percentage and visual rack coordinates.
   */
  static async smartSearch(
    shopId: string,
    query: {
      q?: string;
      symptomOnly?: boolean;
      inStockOnly?: boolean;
      sortByMargin?: boolean;
      limit?: number;
    }
  ) {
    const rawQ = (query.q || "").trim().toLowerCase();
    const limit = query.limit || 50;

    // Expand search using Symptom Thesaurus
    const matchedGenericKeys: string[] = [];
    let detectedSymptom: string | null = null;

    if (rawQ) {
      for (const [symptomKey, config] of Object.entries(SYMPTOM_THESAURUS)) {
        if (config.terms.some((t) => rawQ.includes(t) || t.includes(rawQ))) {
          detectedSymptom = symptomKey;
          matchedGenericKeys.push(...config.genericKeys);
        }
      }
    }

    // Build OR filters
    const orConditions: any[] = [];

    if (rawQ) {
      orConditions.push(
        { name: { contains: rawQ, mode: "insensitive" } },
        { genericName: { contains: rawQ, mode: "insensitive" } },
        { brand: { contains: rawQ, mode: "insensitive" } },
        { symptoms: { contains: rawQ, mode: "insensitive" } },
        { saltComposition: { contains: rawQ, mode: "insensitive" } }
      );

      // If matched symptom, add generic keys & symptom name
      if (detectedSymptom) {
        orConditions.push({ symptoms: { contains: detectedSymptom, mode: "insensitive" } });
        for (const genKey of matchedGenericKeys) {
          orConditions.push(
            { genericName: { contains: genKey, mode: "insensitive" } },
            { saltComposition: { contains: genKey, mode: "insensitive" } },
            { name: { contains: genKey, mode: "insensitive" } }
          );
        }
      }
    }

    const where: any = {
      shopId,
      status: "ACTIVE",
    };

    if (orConditions.length > 0) {
      where.OR = orConditions;
    }

    // Query medicines with active batches
    const medicines = await prisma.medicine.findMany({
      where,
      take: 100,
      include: {
        category: { select: { id: true, name: true } },
        manufacturer: { select: { id: true, name: true } },
        unit: { select: { id: true, name: true, abbreviation: true } },
        batches: {
          where: {
            expiryDate: { gte: new Date() },
            currentQuantity: { gt: 0 },
          },
          select: {
            id: true,
            batchNumber: true,
            expiryDate: true,
            currentQuantity: true,
            mrp: true,
            sellingPrice: true,
            purchaseRate: true,
          },
          orderBy: { expiryDate: "asc" },
        },
      },
    });

    // Compute live stock, margins, rack string and badges
    const enriched = medicines.map((m) => {
      const totalStock = m.batches.reduce((sum, b) => sum + b.currentQuantity, 0);

      const mrpNum = Number(m.mrp);
      const sellNum = Number(m.sellingPrice || m.mrp);
      const purchaseNum = Number(m.purchaseRate || 0);

      // Profit Margin Percentage = ((SellingPrice - PurchaseRate) / SellingPrice) * 100
      let marginPercent = 0;
      if (sellNum > 0 && purchaseNum > 0) {
        marginPercent = Math.round(((sellNum - purchaseNum) / sellNum) * 100);
      } else if (sellNum > 0 && purchaseNum === 0) {
        // Fallback estimate if purchase rate not set
        marginPercent = 20;
      }

      // Stock status color classification
      // Green: > 5, Orange: 1-5, Red: 0
      let stockStatus: "IN_STOCK" | "LOW_STOCK" | "OUT_OF_STOCK" = "OUT_OF_STOCK";
      if (totalStock > 5) {
        stockStatus = "IN_STOCK";
      } else if (totalStock > 0) {
        stockStatus = "LOW_STOCK";
      }

      // Format physical location tag
      const rack = m.rack || "A";
      const shelf = m.shelf || "1";
      const box = m.box || "01";
      const locationFormatted = `Rack ${rack} • Shelf ${shelf} • Box ${box}`;

      return {
        id: m.id,
        name: m.name,
        genericName: m.genericName,
        brand: m.brand,
        dosageForm: m.dosageForm,
        strength: m.strength,
        symptoms: m.symptoms,
        saltComposition: m.saltComposition || m.genericName,
        mrp: mrpNum,
        sellingPrice: sellNum,
        purchaseRate: purchaseNum,
        marginPercent,
        isHighMargin: marginPercent >= 25,
        totalStock,
        stockStatus,
        location: {
          rack,
          shelf,
          box,
          formatted: locationFormatted,
        },
        category: m.category?.name || "General",
        manufacturer: m.manufacturer?.name || "Standard",
        packing: m.dosageForm || "10's",
        batchesCount: m.batches.length,
        batches: m.batches,
      };
    });

    // Apply filters
    let results = enriched;
    if (query.inStockOnly) {
      results = results.filter((i) => i.totalStock > 0);
    }

    // Sort order:
    // 1. By margin if requested
    // 2. Default: In-stock first, then high margin first, then name
    if (query.sortByMargin) {
      results.sort((a, b) => b.marginPercent - a.marginPercent);
    } else {
      results.sort((a, b) => {
        // In-stock items first
        if (a.totalStock > 0 && b.totalStock === 0) return -1;
        if (a.totalStock === 0 && b.totalStock > 0) return 1;

        // Then by margin percentage (high-margin brands first)
        if (b.marginPercent !== a.marginPercent) {
          return b.marginPercent - a.marginPercent;
        }

        return a.name.localeCompare(b.name);
      });
    }

    return {
      query: rawQ,
      detectedSymptom,
      totalMatches: results.length,
      items: results.slice(0, limit),
    };
  }

  /**
   * Instant Salt-Equivalent / Substitute Engine
   * Finds matching therapeutic or generic salt equivalents in ready stock,
   * calculates savings ("₹35 Sasta"), and provides a pitch script for chemist.
   */
  static async getSaltEquivalents(shopId: string, medicineId: string) {
    const targetMed = await prisma.medicine.findFirst({
      where: { id: medicineId, shopId },
      include: {
        batches: {
          where: {
            expiryDate: { gte: new Date() },
            currentQuantity: { gt: 0 },
          },
        },
      },
    });

    if (!targetMed) {
      throw AppError.notFound("Target medicine not found");
    }

    const targetStock = targetMed.batches.reduce((sum, b) => sum + b.currentQuantity, 0);
    const targetMrp = Number(targetMed.mrp);

    // Auto-log to Shortage Diary if stock is low or zero!
    if (targetStock === 0 || targetStock <= targetMed.reorderLevel) {
      this.logShortage(shopId, targetMed.id, 1, "Customer inquiry during counter billing").catch((err) => {
        console.error("Failed to auto-log shortage:", err);
      });
    }

    // Extract salt keywords to find substitutes
    const targetGeneric = (targetMed.genericName || "").toLowerCase();
    const targetSalt = (targetMed.saltComposition || "").toLowerCase();

    // Split into molecule tokens (e.g. "amoxicillin + clavulanic acid" -> ["amoxicillin", "clavulanic"])
    const rawTokens = `${targetGeneric} ${targetSalt}`
      .replace(/[^\w\s]/g, " ")
      .split(/\s+/)
      .filter((t) => t.length >= 4 && !["acid", "with", "plus", "oral", "tablet", "capsule", "syrup"].includes(t));

    const moleculeTokens = Array.from(new Set(rawTokens));

    // Search potential substitutes in the same shop
    const whereOr: any[] = [];
    if (targetGeneric) {
      whereOr.push({ genericName: { contains: targetGeneric, mode: "insensitive" } });
    }
    for (const token of moleculeTokens) {
      whereOr.push(
        { genericName: { contains: token, mode: "insensitive" } },
        { saltComposition: { contains: token, mode: "insensitive" } }
      );
    }

    const candidateMeds = await prisma.medicine.findMany({
      where: {
        shopId,
        id: { not: targetMed.id },
        status: "ACTIVE",
        OR: whereOr.length > 0 ? whereOr : undefined,
      },
      include: {
        manufacturer: { select: { name: true } },
        batches: {
          where: {
            expiryDate: { gte: new Date() },
            currentQuantity: { gt: 0 },
          },
          orderBy: { expiryDate: "asc" },
        },
      },
    });

    // Score and format substitutes
    const substitutes = candidateMeds.map((sub) => {
      const subStock = sub.batches.reduce((sum, b) => sum + b.currentQuantity, 0);
      const subMrp = Number(sub.mrp);
      const subSell = Number(sub.sellingPrice || sub.mrp);
      const subPurchase = Number(sub.purchaseRate || 0);

      // Price difference comparison
      const priceDifference = Math.round((targetMrp - subMrp) * 100) / 100;
      const isCheaper = priceDifference > 0;
      const savingsAmount = Math.abs(priceDifference);

      // Margin
      let marginPercent = 0;
      if (subSell > 0 && subPurchase > 0) {
        marginPercent = Math.round(((subSell - subPurchase) / subSell) * 100);
      }

      // Chemist pitch script
      let pitchScript = "";
      if (isCheaper) {
        pitchScript = `Sir same formula hai (${sub.genericName}), ₹${savingsAmount.toFixed(0)} sasta bhi hai!`;
      } else if (savingsAmount === 0) {
        pitchScript = `Sir same formula hai (${sub.genericName}), same rate par ready stock me hai.`;
      } else {
        pitchScript = `Sir same formula hai (${sub.genericName}), branded option ready stock me hai.`;
      }

      const rack = sub.rack || "A";
      const shelf = sub.shelf || "1";
      const box = sub.box || "01";

      return {
        id: sub.id,
        name: sub.name,
        genericName: sub.genericName,
        brand: sub.brand,
        saltComposition: sub.saltComposition || sub.genericName,
        manufacturer: sub.manufacturer?.name || "Standard",
        dosageForm: sub.dosageForm,
        mrp: subMrp,
        sellingPrice: subSell,
        totalStock: subStock,
        stockStatus: subStock > 5 ? "IN_STOCK" : subStock > 0 ? "LOW_STOCK" : "OUT_OF_STOCK",
        priceDifference,
        isCheaper,
        savingsAmount,
        pitchScript,
        marginPercent,
        isHighMargin: marginPercent >= 25,
        location: {
          rack,
          shelf,
          box,
          formatted: `Rack ${rack} • Shelf ${shelf} • Box ${box}`,
        },
        eligibleBatch: sub.batches[0] || null,
      };
    });

    // Prioritize in-stock substitutes first, then highest savings
    substitutes.sort((a, b) => {
      if (a.totalStock > 0 && b.totalStock === 0) return -1;
      if (a.totalStock === 0 && b.totalStock > 0) return 1;
      if (b.savingsAmount !== a.savingsAmount) {
        return b.savingsAmount - a.savingsAmount;
      }
      return b.marginPercent - a.marginPercent;
    });

    return {
      targetMedicine: {
        id: targetMed.id,
        name: targetMed.name,
        genericName: targetMed.genericName,
        mrp: targetMrp,
        totalStock: targetStock,
        isOutOfStock: targetStock === 0,
        rack: targetMed.rack || "A",
        shelf: targetMed.shelf || "1",
        box: targetMed.box || "01",
        locationFormatted: `Rack ${targetMed.rack || "A"} • Shelf ${targetMed.shelf || "1"} • Box ${targetMed.box || "01"}`,
      },
      substitutesCount: substitutes.length,
      inStockSubstitutesCount: substitutes.filter((s) => s.totalStock > 0).length,
      substitutes,
    };
  }

  /**
   * Log or increment an item in the Shortage Diary (Kami Register)
   */
  static async logShortage(
    shopId: string,
    medicineId: string,
    customerCount: number = 1,
    notes?: string
  ) {
    const med = await prisma.medicine.findFirst({
      where: { id: medicineId, shopId },
      include: {
        batches: {
          where: {
            expiryDate: { gte: new Date() },
            currentQuantity: { gt: 0 },
          },
        },
      },
    });

    if (!med) {
      throw AppError.notFound("Medicine not found");
    }

    const currentStock = med.batches.reduce((sum, b) => sum + b.currentQuantity, 0);

    const existing = await prisma.shortageDiaryItem.findUnique({
      where: {
        shopId_medicineId: {
          shopId,
          medicineId,
        },
      },
    });

    if (existing) {
      return await prisma.shortageDiaryItem.update({
        where: { id: existing.id },
        data: {
          customerCount: existing.customerCount + customerCount,
          lastRequestedAt: new Date(),
          currentStock,
          status: "PENDING", // Reopen if was previously pending
          notes: notes || existing.notes,
        },
        include: {
          medicine: true,
          preferredSupplier: true,
        },
      });
    }

    return await prisma.shortageDiaryItem.create({
      data: {
        shopId,
        medicineId,
        customerCount,
        currentStock,
        suggestedReorderQty: Math.max(med.reorderLevel * 2, 20),
        status: "PENDING",
        notes: notes || "Counter inquiry shortage",
      },
      include: {
        medicine: true,
        preferredSupplier: true,
      },
    });
  }

  /**
   * List all Shortage Diary items
   */
  static async listShortageDiary(shopId: string, status?: string) {
    const where: any = { shopId };
    if (status) {
      where.status = status;
    }

    const items = await prisma.shortageDiaryItem.findMany({
      where,
      orderBy: [{ customerCount: "desc" }, { lastRequestedAt: "desc" }],
      include: {
        medicine: {
          include: {
            manufacturer: { select: { name: true } },
            unit: { select: { name: true, abbreviation: true } },
          },
        },
        preferredSupplier: {
          select: {
            id: true,
            name: true,
            mobile: true,
            contactPerson: true,
          },
        },
      },
    });

    return {
      total: items.length,
      items: items.map((item) => ({
        id: item.id,
        medicineId: item.medicineId,
        medicineName: item.medicine.name,
        genericName: item.medicine.genericName,
        manufacturer: item.medicine.manufacturer?.name || "Standard",
        packing: item.medicine.dosageForm || "10's",
        currentStock: item.currentStock,
        customerCount: item.customerCount,
        suggestedReorderQty: item.suggestedReorderQty,
        lastRequestedAt: item.lastRequestedAt,
        status: item.status,
        notes: item.notes,
        preferredSupplier: item.preferredSupplier,
        mrp: Number(item.medicine.mrp),
        purchaseRate: Number(item.medicine.purchaseRate),
        rackLocation: `Rack ${item.medicine.rack || "A"} • Shelf ${item.medicine.shelf || "1"}`,
      })),
    };
  }

  /**
   * Update status or notes of a shortage item
   */
  static async updateShortageItem(
    shopId: string,
    id: string,
    data: {
      status?: "PENDING" | "PO_CREATED" | "RESOLVED" | "DISMISSED";
      suggestedReorderQty?: number;
      preferredSupplierId?: string | null;
      notes?: string | null;
    }
  ) {
    const item = await prisma.shortageDiaryItem.findFirst({
      where: { id, shopId },
    });

    if (!item) {
      throw AppError.notFound("Shortage diary item not found");
    }

    return await prisma.shortageDiaryItem.update({
      where: { id },
      data,
      include: {
        medicine: true,
        preferredSupplier: true,
      },
    });
  }
}
