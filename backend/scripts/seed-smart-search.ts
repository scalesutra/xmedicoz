import { PrismaClient, Prisma } from "@prisma/client";

const prisma = new PrismaClient();
const Decimal = Prisma.Decimal;

async function seedSmartSearch() {
  console.log("[Seed] Seeding Symptom Search, Rack Coordinates, Salt-Equivalents & Showcase Medicines...");

  const shops = await prisma.shop.findMany();
  if (shops.length === 0) {
    console.error("No shops found to seed.");
    return;
  }

  for (const shop of shops) {
    console.log(`Processing shop: ${shop.name} (${shop.id})`);

    // Ensure Default Unit & Category
    let stripUnit = await prisma.unit.findFirst({ where: { shopId: shop.id, name: { contains: "Strip" } } });
    if (!stripUnit) {
      stripUnit = await prisma.unit.create({
        data: {
          shopId: shop.id,
          name: "Strip (10 Tablets)",
          abbreviation: "STRIP",
          status: "ACTIVE",
        },
      });
    }

    let antibioticCat = await prisma.category.findFirst({ where: { shopId: shop.id, name: "Antibiotics" } });
    if (!antibioticCat) {
      antibioticCat = await prisma.category.create({
        data: { shopId: shop.id, name: "Antibiotics", status: "ACTIVE" },
      });
    }

    let otcCat = await prisma.category.findFirst({ where: { shopId: shop.id, name: "OTC & General" } });
    if (!otcCat) {
      otcCat = await prisma.category.create({
        data: { shopId: shop.id, name: "OTC & General", status: "ACTIVE" },
      });
    }

    let gastroCat = await prisma.category.findFirst({ where: { shopId: shop.id, name: "Gastroenterology" } });
    if (!gastroCat) {
      gastroCat = await prisma.category.create({
        data: { shopId: shop.id, name: "Gastroenterology", status: "ACTIVE" },
      });
    }

    // Showcase Meds:
    // 1. Augmentin 625 (Out of Stock, Red)
    const augmentin = await prisma.medicine.upsert({
      where: {
        id: "00000000-0000-0000-0000-000000000001",
      },
      update: {
        name: "Augmentin 625 Duo Tablet",
        genericName: "Amoxicillin + Clavulanic Acid 625mg",
        saltComposition: "Amoxicillin (500mg) + Clavulanic Acid (125mg)",
        brand: "GSK",
        dosageForm: "Tablet",
        strength: "625mg",
        mrp: new Decimal(203.50),
        purchaseRate: new Decimal(162.80),
        sellingPrice: new Decimal(203.50),
        rack: "A",
        shelf: "2",
        box: "08",
        symptoms: "Bacterial Infection, Throat Infection, Dental Infection, Severe Cold",
        otcFlag: false,
        categoryId: antibioticCat.id,
        unitId: stripUnit.id,
      },
      create: {
        id: "00000000-0000-0000-0000-000000000001",
        shopId: shop.id,
        name: "Augmentin 625 Duo Tablet",
        genericName: "Amoxicillin + Clavulanic Acid 625mg",
        saltComposition: "Amoxicillin (500mg) + Clavulanic Acid (125mg)",
        brand: "GSK",
        dosageForm: "Tablet",
        strength: "625mg",
        mrp: new Decimal(203.50),
        purchaseRate: new Decimal(162.80),
        sellingPrice: new Decimal(203.50),
        rack: "A",
        shelf: "2",
        box: "08",
        symptoms: "Bacterial Infection, Throat Infection, Dental Infection, Severe Cold",
        otcFlag: false,
        categoryId: antibioticCat.id,
        unitId: stripUnit.id,
      },
    });

    // Zero-stock batch for Augmentin to make it RED (Khatam / Out of Stock)
    await prisma.medicineBatch.deleteMany({ where: { medicineId: augmentin.id } });

    // 2. Moxikind-CV 625 (In Stock: 18, Qty: 18, Rack A-2, Same Salt, Sasta by Rs. 35.50, High Margin: 32%)
    const moxikind = await prisma.medicine.upsert({
      where: {
        id: "00000000-0000-0000-0000-000000000002",
      },
      update: {
        name: "Moxikind-CV 625 Tablet",
        genericName: "Amoxicillin + Clavulanic Acid 625mg",
        saltComposition: "Amoxicillin (500mg) + Clavulanic Acid (125mg)",
        brand: "Mankind Pharma",
        dosageForm: "Tablet",
        strength: "625mg",
        mrp: new Decimal(168.00),
        purchaseRate: new Decimal(114.24), // 32% Margin!
        sellingPrice: new Decimal(168.00),
        rack: "A",
        shelf: "2",
        box: "09",
        symptoms: "Bacterial Infection, Throat Infection, Dental Infection, Severe Cold",
        otcFlag: false,
        categoryId: antibioticCat.id,
        unitId: stripUnit.id,
      },
      create: {
        id: "00000000-0000-0000-0000-000000000002",
        shopId: shop.id,
        name: "Moxikind-CV 625 Tablet",
        genericName: "Amoxicillin + Clavulanic Acid 625mg",
        saltComposition: "Amoxicillin (500mg) + Clavulanic Acid (125mg)",
        brand: "Mankind Pharma",
        dosageForm: "Tablet",
        strength: "625mg",
        mrp: new Decimal(168.00),
        purchaseRate: new Decimal(114.24),
        sellingPrice: new Decimal(168.00),
        rack: "A",
        shelf: "2",
        box: "09",
        symptoms: "Bacterial Infection, Throat Infection, Dental Infection, Severe Cold",
        otcFlag: false,
        categoryId: antibioticCat.id,
        unitId: stripUnit.id,
      },
    });

    const expDate = new Date();
    expDate.setFullYear(expDate.getFullYear() + 2);

    await prisma.medicineBatch.upsert({
      where: {
        shopId_medicineId_batchNumber: {
          shopId: shop.id,
          medicineId: moxikind.id,
          batchNumber: "MKCV-902",
        },
      },
      update: {
        currentQuantity: 18,
        mrp: new Decimal(168.00),
        sellingPrice: new Decimal(168.00),
        purchaseRate: new Decimal(114.24),
        expiryDate: expDate,
      },
      create: {
        shopId: shop.id,
        medicineId: moxikind.id,
        batchNumber: "MKCV-902",
        currentQuantity: 18,
        mrp: new Decimal(168.00),
        sellingPrice: new Decimal(168.00),
        purchaseRate: new Decimal(114.24),
        expiryDate: expDate,
      },
    });

    // 3. Pan-D Capsule (Gas, Acidity, High Margin 38%)
    const panD = await prisma.medicine.upsert({
      where: { id: "00000000-0000-0000-0000-000000000003" },
      update: {
        name: "Pan-D Capsule",
        genericName: "Pantoprazole + Domperidone",
        saltComposition: "Pantoprazole (40mg) + Domperidone (30mg)",
        brand: "Alkem",
        dosageForm: "Capsule",
        strength: "40mg+30mg",
        mrp: new Decimal(198.00),
        purchaseRate: new Decimal(122.76), // 38% Margin
        sellingPrice: new Decimal(198.00),
        rack: "B",
        shelf: "3",
        box: "12",
        symptoms: "Gas, Acidity, GERD, Heartburn, Bloating, Indigestion",
        otcFlag: true,
        categoryId: gastroCat.id,
        unitId: stripUnit.id,
      },
      create: {
        id: "00000000-0000-0000-0000-000000000003",
        shopId: shop.id,
        name: "Pan-D Capsule",
        genericName: "Pantoprazole + Domperidone",
        saltComposition: "Pantoprazole (40mg) + Domperidone (30mg)",
        brand: "Alkem",
        dosageForm: "Capsule",
        strength: "40mg+30mg",
        mrp: new Decimal(198.00),
        purchaseRate: new Decimal(122.76),
        sellingPrice: new Decimal(198.00),
        rack: "B",
        shelf: "3",
        box: "12",
        symptoms: "Gas, Acidity, GERD, Heartburn, Bloating, Indigestion",
        otcFlag: true,
        categoryId: gastroCat.id,
        unitId: stripUnit.id,
      },
    });

    await prisma.medicineBatch.upsert({
      where: {
        shopId_medicineId_batchNumber: {
          shopId: shop.id,
          medicineId: panD.id,
          batchNumber: "PAND-104",
        },
      },
      update: {
        currentQuantity: 24,
        mrp: new Decimal(198.00),
        sellingPrice: new Decimal(198.00),
        purchaseRate: new Decimal(122.76),
        expiryDate: expDate,
      },
      create: {
        shopId: shop.id,
        medicineId: panD.id,
        batchNumber: "PAND-104",
        currentQuantity: 24,
        mrp: new Decimal(198.00),
        sellingPrice: new Decimal(198.00),
        purchaseRate: new Decimal(122.76),
        expiryDate: expDate,
      },
    });

    // 4. Cheston Cold Tablet (Cold, Flu, 39% Margin)
    const cheston = await prisma.medicine.upsert({
      where: { id: "00000000-0000-0000-0000-000000000004" },
      update: {
        name: "Cheston Cold Tablet",
        genericName: "Cetirizine + Phenylephrine + Paracetamol",
        saltComposition: "Cetirizine (5mg) + Phenylephrine (10mg) + Paracetamol (325mg)",
        brand: "Cipla",
        dosageForm: "Tablet",
        strength: "Standard",
        mrp: new Decimal(64.00),
        purchaseRate: new Decimal(39.04), // 39% Margin
        sellingPrice: new Decimal(64.00),
        rack: "C",
        shelf: "1",
        box: "05",
        symptoms: "Cold, Sardi, Runny Nose, Sneezing, Nasal Congestion, Watery Eyes",
        otcFlag: true,
        categoryId: otcCat.id,
        unitId: stripUnit.id,
      },
      create: {
        id: "00000000-0000-0000-0000-000000000004",
        shopId: shop.id,
        name: "Cheston Cold Tablet",
        genericName: "Cetirizine + Phenylephrine + Paracetamol",
        saltComposition: "Cetirizine (5mg) + Phenylephrine (10mg) + Paracetamol (325mg)",
        brand: "Cipla",
        dosageForm: "Tablet",
        strength: "Standard",
        mrp: new Decimal(64.00),
        purchaseRate: new Decimal(39.04),
        sellingPrice: new Decimal(64.00),
        rack: "C",
        shelf: "1",
        box: "05",
        symptoms: "Cold, Sardi, Runny Nose, Sneezing, Nasal Congestion, Watery Eyes",
        otcFlag: true,
        categoryId: otcCat.id,
        unitId: stripUnit.id,
      },
    });

    await prisma.medicineBatch.upsert({
      where: {
        shopId_medicineId_batchNumber: {
          shopId: shop.id,
          medicineId: cheston.id,
          batchNumber: "CHST-882",
        },
      },
      update: {
        currentQuantity: 20,
        mrp: new Decimal(64.00),
        sellingPrice: new Decimal(64.00),
        purchaseRate: new Decimal(39.04),
        expiryDate: expDate,
      },
      create: {
        shopId: shop.id,
        medicineId: cheston.id,
        batchNumber: "CHST-882",
        currentQuantity: 20,
        mrp: new Decimal(64.00),
        sellingPrice: new Decimal(64.00),
        purchaseRate: new Decimal(39.04),
        expiryDate: expDate,
      },
    });

    // 5. Sinarest Tablet (Cold, Fever, Standard Margin 18%)
    const sinarest = await prisma.medicine.upsert({
      where: { id: "00000000-0000-0000-0000-000000000005" },
      update: {
        name: "Sinarest New Tablet",
        genericName: "Chlorpheniramine + Phenylephrine + Paracetamol",
        saltComposition: "Paracetamol (500mg) + Phenylephrine (10mg) + Chlorpheniramine (2mg)",
        brand: "Centaur",
        dosageForm: "Tablet",
        strength: "Standard",
        mrp: new Decimal(76.00),
        purchaseRate: new Decimal(62.32), // 18% Margin
        sellingPrice: new Decimal(76.00),
        rack: "C",
        shelf: "1",
        box: "06",
        symptoms: "Cold, Headache, Fever, Bodyache, Blocked Nose",
        otcFlag: true,
        categoryId: otcCat.id,
        unitId: stripUnit.id,
      },
      create: {
        id: "00000000-0000-0000-0000-000000000005",
        shopId: shop.id,
        name: "Sinarest New Tablet",
        genericName: "Chlorpheniramine + Phenylephrine + Paracetamol",
        saltComposition: "Paracetamol (500mg) + Phenylephrine (10mg) + Chlorpheniramine (2mg)",
        brand: "Centaur",
        dosageForm: "Tablet",
        strength: "Standard",
        mrp: new Decimal(76.00),
        purchaseRate: new Decimal(62.32),
        sellingPrice: new Decimal(76.00),
        rack: "C",
        shelf: "1",
        box: "06",
        symptoms: "Cold, Headache, Fever, Bodyache, Blocked Nose",
        otcFlag: true,
        categoryId: otcCat.id,
        unitId: stripUnit.id,
      },
    });

    await prisma.medicineBatch.upsert({
      where: {
        shopId_medicineId_batchNumber: {
          shopId: shop.id,
          medicineId: sinarest.id,
          batchNumber: "SNRT-411",
        },
      },
      update: {
        currentQuantity: 30,
        mrp: new Decimal(76.00),
        sellingPrice: new Decimal(76.00),
        purchaseRate: new Decimal(62.32),
        expiryDate: expDate,
      },
      create: {
        shopId: shop.id,
        medicineId: sinarest.id,
        batchNumber: "SNRT-411",
        currentQuantity: 30,
        mrp: new Decimal(76.00),
        sellingPrice: new Decimal(76.00),
        purchaseRate: new Decimal(62.32),
        expiryDate: expDate,
      },
    });

    // 6. Calpol 650 (Low stock Orange alert: 3 units left)
    const calpol = await prisma.medicine.upsert({
      where: { id: "00000000-0000-0000-0000-000000000006" },
      update: {
        name: "Calpol 650 Tablet",
        genericName: "Paracetamol 650mg",
        saltComposition: "Paracetamol (650mg)",
        brand: "GSK",
        dosageForm: "Tablet",
        strength: "650mg",
        mrp: new Decimal(33.00),
        purchaseRate: new Decimal(27.06), // 18% Margin
        sellingPrice: new Decimal(33.00),
        rack: "D",
        shelf: "4",
        box: "02",
        symptoms: "Fever, Bodyache, Headache, High Temperature, Bukhar",
        otcFlag: true,
        categoryId: otcCat.id,
        unitId: stripUnit.id,
      },
      create: {
        id: "00000000-0000-0000-0000-000000000006",
        shopId: shop.id,
        name: "Calpol 650 Tablet",
        genericName: "Paracetamol 650mg",
        saltComposition: "Paracetamol (650mg)",
        brand: "GSK",
        dosageForm: "Tablet",
        strength: "650mg",
        mrp: new Decimal(33.00),
        purchaseRate: new Decimal(27.06),
        sellingPrice: new Decimal(33.00),
        rack: "D",
        shelf: "4",
        box: "02",
        symptoms: "Fever, Bodyache, Headache, High Temperature, Bukhar",
        otcFlag: true,
        categoryId: otcCat.id,
        unitId: stripUnit.id,
      },
    });

    await prisma.medicineBatch.upsert({
      where: {
        shopId_medicineId_batchNumber: {
          shopId: shop.id,
          medicineId: calpol.id,
          batchNumber: "CALP-119",
        },
      },
      update: {
        currentQuantity: 3, // Low stock -> ORANGE
        mrp: new Decimal(33.00),
        sellingPrice: new Decimal(33.00),
        purchaseRate: new Decimal(27.06),
        expiryDate: expDate,
      },
      create: {
        shopId: shop.id,
        medicineId: calpol.id,
        batchNumber: "CALP-119",
        currentQuantity: 3,
        mrp: new Decimal(33.00),
        sellingPrice: new Decimal(33.00),
        purchaseRate: new Decimal(27.06),
        expiryDate: expDate,
      },
    });

    // Also enrich any existing medicines with default racks and symptoms if missing
    const existingMeds = await prisma.medicine.findMany({ where: { shopId: shop.id } });
    for (const m of existingMeds) {
      if (!m.rack || !m.shelf || !m.box) {
        await prisma.medicine.update({
          where: { id: m.id },
          data: {
            rack: m.rack || "B",
            shelf: m.shelf || "3",
            box: m.box || "12",
            saltComposition: m.saltComposition || m.genericName,
            symptoms: m.symptoms || (m.genericName.toLowerCase().includes("paracetamol") ? "Fever, Bodyache, Pain" : "General Treatment"),
          },
        });
      }
    }

    // Seed Shortage Diary initial entry for Augmentin 625 (demanded 4 times)
    await prisma.shortageDiaryItem.upsert({
      where: {
        shopId_medicineId: {
          shopId: shop.id,
          medicineId: augmentin.id,
        },
      },
      update: {
        customerCount: 4,
        currentStock: 0,
        suggestedReorderQty: 30,
        status: "PENDING",
        notes: "High customer counter demand (Out of stock)",
      },
      create: {
        shopId: shop.id,
        medicineId: augmentin.id,
        customerCount: 4,
        currentStock: 0,
        suggestedReorderQty: 30,
        status: "PENDING",
        notes: "High customer counter demand (Out of stock)",
      },
    });

    // Seed Shortage Diary for Calpol (low stock)
    await prisma.shortageDiaryItem.upsert({
      where: {
        shopId_medicineId: {
          shopId: shop.id,
          medicineId: calpol.id,
        },
      },
      update: {
        customerCount: 2,
        currentStock: 3,
        suggestedReorderQty: 50,
        status: "PENDING",
        notes: "Stock critical below 5 units",
      },
      create: {
        shopId: shop.id,
        medicineId: calpol.id,
        customerCount: 2,
        currentStock: 3,
        suggestedReorderQty: 50,
        status: "PENDING",
        notes: "Stock critical below 5 units",
      },
    });
  }

  console.log("[Seed] Finished seeding smart search showcase medicines and shortage diary!");
}

seedSmartSearch()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
