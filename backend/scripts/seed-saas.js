import { PrismaClient, Prisma } from "@prisma/client";
import { ROLES, PERMISSIONS } from "../src/config/constants.js";

const prisma = new PrismaClient();
const Decimal = Prisma.Decimal;

async function seed() {
  console.log("[Seed] Seeding SaaS Multi-Tenant Platform...");

  // 1. Roles
  for (const roleName of Object.values(ROLES)) {
    await prisma.role.upsert({
      where: { name: roleName },
      update: {},
      create: {
        name: roleName,
        description: `${roleName} default role`,
        isSystem: true,
      },
    });
  }

  // 2. Permissions
  for (const [key, code] of Object.entries(PERMISSIONS)) {
    const module = code.split(".")[0] || "general";
    await prisma.permission.upsert({
      where: { code },
      update: {},
      create: {
        code,
        module,
        description: `Permission for ${key}`,
      },
    });
  }

  // 3. Subscription Plans
  const plans = [
    {
      code: "TRIAL",
      name: "Free Trial (14 Days)",
      priceMonthly: 0,
      priceYearly: 0,
      maxUsers: 2,
      maxMedicines: 500,
      maxInvoicesPerMonth: 200,
      features: {
        fefo: true,
        posBilling: true,
        expiryAlerts: true,
        whatsappReminders: false,
        accounting: false,
        support: "Community",
      },
    },
    {
      code: "STARTER",
      name: "Silver Starter",
      priceMonthly: 599,
      priceYearly: 5990,
      maxUsers: 3,
      maxMedicines: 2500,
      maxInvoicesPerMonth: 1500,
      features: {
        fefo: true,
        posBilling: true,
        expiryAlerts: true,
        whatsappReminders: true,
        accounting: true,
        support: "Email",
      },
    },
    {
      code: "PRO",
      name: "Gold Professional",
      priceMonthly: 1299,
      priceYearly: 12990,
      maxUsers: 8,
      maxMedicines: 15000,
      maxInvoicesPerMonth: 8000,
      features: {
        fefo: true,
        posBilling: true,
        expiryAlerts: true,
        whatsappReminders: true,
        accounting: true,
        gstFilingReports: true,
        multiCounter: true,
        support: "Priority Phone & Chat",
      },
    },
    {
      code: "ENTERPRISE",
      name: "Platinum Enterprise",
      priceMonthly: 2499,
      priceYearly: 24990,
      maxUsers: 25,
      maxMedicines: 100000,
      maxInvoicesPerMonth: 999999,
      features: {
        fefo: true,
        posBilling: true,
        expiryAlerts: true,
        whatsappReminders: true,
        accounting: true,
        gstFilingReports: true,
        multiCounter: true,
        customBranding: true,
        dedicatedManager: true,
        support: "24/7 Dedicated Relationship Manager",
      },
    },
  ];

  for (const plan of plans) {
    await prisma.subscriptionPlan.upsert({
      where: { code: plan.code },
      update: {
        name: plan.name,
        priceMonthly: new Decimal(plan.priceMonthly),
        priceYearly: new Decimal(plan.priceYearly),
        maxUsers: plan.maxUsers,
        maxMedicines: plan.maxMedicines,
        maxInvoicesPerMonth: plan.maxInvoicesPerMonth,
        features: plan.features,
      },
      create: {
        code: plan.code,
        name: plan.name,
        priceMonthly: new Decimal(plan.priceMonthly),
        priceYearly: new Decimal(plan.priceYearly),
        maxUsers: plan.maxUsers,
        maxMedicines: plan.maxMedicines,
        maxInvoicesPerMonth: plan.maxInvoicesPerMonth,
        features: plan.features,
        isActive: true,
      },
    });
  }
  console.log("[Seed] Seeded 4 Subscription Plans (Trial, Starter, Pro, Enterprise)");

  // 4. Check or create default admin user
  const adminRole = await prisma.role.findUnique({ where: { name: ROLES.ADMIN } });
  let adminUser = await prisma.user.findFirst({ where: { email: "admin@medicalcrm.local" } });
  if (!adminUser) {
    adminUser = await prisma.user.create({
      data: {
        keycloakId: "admin-system-keycloak-id",
        email: "admin@medicalcrm.local",
        firstName: "System",
        lastName: "Admin",
        status: "ACTIVE",
        emailVerified: true,
      },
    });
  }

  if (adminRole && adminUser) {
    await prisma.userRole.upsert({
      where: {
        userId_roleId: {
          userId: adminUser.id,
          roleId: adminRole.id,
        },
      },
      update: {},
      create: {
        userId: adminUser.id,
        roleId: adminRole.id,
      },
    });
  }

  // 5. Create default Medical Stores
  const proPlan = await prisma.subscriptionPlan.findUnique({ where: { code: "PRO" } });
  const trialPlan = await prisma.subscriptionPlan.findUnique({ where: { code: "TRIAL" } });

  // Store 1: Sanjeevani Medicos
  const store1 = await prisma.shop.upsert({
    where: { slug: "sanjeevani-medicos" },
    update: {},
    create: {
      name: "Sanjeevani Medicos & Pharmacy",
      slug: "sanjeevani-medicos",
      ownerName: "Dr. R. K. Sharma",
      phone: "+91 98765 43210",
      email: "sanjeevani@medicalcrm.local",
      drugLicenseNo: "DL-20B-10928 / DL-21B-10929",
      gstin: "07AAAAA1234A1Z5",
      address: "Shop 14, Main Market, Sector 18",
      city: "New Delhi",
      state: "Delhi",
      pincode: "110001",
      invoicePrefix: "SANJ",
      status: "ACTIVE",
    },
  });

  // Link Admin to Store 1 as OWNER
  await prisma.shopMember.upsert({
    where: { shopId_userId: { shopId: store1.id, userId: adminUser.id } },
    update: { role: "OWNER" },
    create: {
      shopId: store1.id,
      userId: adminUser.id,
      role: "OWNER",
      status: "ACTIVE",
    },
  });

  // Subscribe Store 1 to PRO plan (valid for 1 year)
  if (proPlan) {
    const nextYear = new Date();
    nextYear.setFullYear(nextYear.getFullYear() + 1);
    await prisma.shopSubscription.upsert({
      where: { shopId: store1.id },
      update: {
        planId: proPlan.id,
        status: "ACTIVE",
        billingCycle: "YEARLY",
        endDate: nextYear,
      },
      create: {
        shopId: store1.id,
        planId: proPlan.id,
        status: "ACTIVE",
        billingCycle: "YEARLY",
        startDate: new Date(),
        endDate: nextYear,
        autoRenew: true,
      },
    });
  }

  // Store 2: CarePlus Pharmacy
  const store2 = await prisma.shop.upsert({
    where: { slug: "careplus-pharmacy" },
    update: {},
    create: {
      name: "CarePlus 24x7 Chemist",
      slug: "careplus-pharmacy",
      ownerName: "Vikas Verma",
      phone: "+91 98111 22334",
      email: "careplus@medicalcrm.local",
      drugLicenseNo: "DL-20B-55412 / DL-21B-55413",
      gstin: "07BBBBB5678B1Z2",
      address: "GF-02, Apollo Hospital Road, Okhla",
      city: "New Delhi",
      state: "Delhi",
      pincode: "110025",
      invoicePrefix: "CARE",
      status: "ACTIVE",
    },
  });

  // Link Admin to Store 2 as OWNER as well
  await prisma.shopMember.upsert({
    where: { shopId_userId: { shopId: store2.id, userId: adminUser.id } },
    update: { role: "OWNER" },
    create: {
      shopId: store2.id,
      userId: adminUser.id,
      role: "OWNER",
      status: "ACTIVE",
    },
  });

  // Subscribe Store 2 to TRIAL plan (valid for 14 days)
  if (trialPlan) {
    const trialEnd = new Date();
    trialEnd.setDate(trialEnd.getDate() + 14);
    await prisma.shopSubscription.upsert({
      where: { shopId: store2.id },
      update: {
        planId: trialPlan.id,
        status: "TRIAL",
        endDate: trialEnd,
      },
      create: {
        shopId: store2.id,
        planId: trialPlan.id,
        status: "TRIAL",
        startDate: new Date(),
        endDate: trialEnd,
        autoRenew: false,
      },
    });
  }

  // Seed default Categories & Units for both stores
  for (const store of [store1, store2]) {
    // Categories
    const categories = ["Antibiotics", "Analgesics & Pain", "Cardiology", "Diabetic Care", "Dermatology", "Vitamins & Supplements"];
    for (const cat of categories) {
      await prisma.category.upsert({
        where: { shopId_name: { shopId: store.id, name: cat } },
        update: {},
        create: {
          shopId: store.id,
          name: cat,
          status: "ACTIVE",
        },
      });
    }

    // Units
    const units = [
      { name: "Strip (10 Tablets)", abbreviation: "STRIP" },
      { name: "Strip (15 Tablets)", abbreviation: "STRIP-15" },
      { name: "Bottle (100ml)", abbreviation: "BTL-100" },
      { name: "Bottle (200ml)", abbreviation: "BTL-200" },
      { name: "Tube (30g)", abbreviation: "TUBE" },
      { name: "Vial / Injection", abbreviation: "VIAL" },
      { name: "Box", abbreviation: "BOX" },
    ];
    for (const u of units) {
      await prisma.unit.upsert({
        where: { shopId_name: { shopId: store.id, name: u.name } },
        update: {},
        create: {
          shopId: store.id,
          name: u.name,
          abbreviation: u.abbreviation,
          status: "ACTIVE",
        },
      });
    }

    // Taxes
    const taxes = [
      { name: "GST 0%", rate: 0, cgst: 0, sgst: 0, igst: 0 },
      { name: "GST 5%", rate: 5, cgst: 2.5, sgst: 2.5, igst: 5 },
      { name: "GST 12%", rate: 12, cgst: 6, sgst: 6, igst: 12 },
      { name: "GST 18%", rate: 18, cgst: 9, sgst: 9, igst: 18 },
    ];
    for (const t of taxes) {
      await prisma.tax.upsert({
        where: { shopId_name: { shopId: store.id, name: t.name } },
        update: {},
        create: {
          shopId: store.id,
          name: t.name,
          rate: new Decimal(t.rate),
          cgst: new Decimal(t.cgst),
          sgst: new Decimal(t.sgst),
          igst: new Decimal(t.igst),
          status: "ACTIVE",
        },
      });
    }

    // Account Groups
    const accountGroups = [
      { code: "ASSETS", name: "Current & Fixed Assets", type: "ASSET" },
      { code: "LIABILITIES", name: "Current & Long Term Liabilities", type: "LIABILITY" },
      { code: "EQUITY", name: "Owner Equity & Reserves", type: "EQUITY" },
      { code: "REVENUE", name: "Operating Revenue & Sales", type: "REVENUE" },
      { code: "EXPENSES", name: "Operational Expenses & COGS", type: "EXPENSE" },
    ];
    for (const g of accountGroups) {
      await prisma.accountGroup.upsert({
        where: { shopId_code: { shopId: store.id, code: g.code } },
        update: {},
        create: {
          shopId: store.id,
          code: g.code,
          name: g.name,
          type: g.type,
        },
      });
    }

    // Standard Accounts
    const assetGroup = await prisma.accountGroup.findUnique({
      where: { shopId_code: { shopId: store.id, code: "ASSETS" } },
    });
    const revenueGroup = await prisma.accountGroup.findUnique({
      where: { shopId_code: { shopId: store.id, code: "REVENUE" } },
    });
    const expenseGroup = await prisma.accountGroup.findUnique({
      where: { shopId_code: { shopId: store.id, code: "EXPENSES" } },
    });

    if (assetGroup) {
      await prisma.account.upsert({
        where: { shopId_code: { shopId: store.id, code: "1010" } },
        update: {},
        create: {
          shopId: store.id,
          code: "1010",
          name: "Main Cash Drawer",
          type: "ASSET",
          groupId: assetGroup.id,
          isSystem: true,
        },
      });
      await prisma.account.upsert({
        where: { shopId_code: { shopId: store.id, code: "1020" } },
        update: {},
        create: {
          shopId: store.id,
          code: "1020",
          name: "Bank Current Account (HDFC/ICICI)",
          type: "ASSET",
          groupId: assetGroup.id,
          isSystem: true,
        },
      });
    }

    if (revenueGroup) {
      await prisma.account.upsert({
        where: { shopId_code: { shopId: store.id, code: "4010" } },
        update: {},
        create: {
          shopId: store.id,
          code: "4010",
          name: "Medicine Counter Sales Revenue",
          type: "REVENUE",
          groupId: revenueGroup.id,
          isSystem: true,
        },
      });
    }

    if (expenseGroup) {
      await prisma.account.upsert({
        where: { shopId_code: { shopId: store.id, code: "5010" } },
        update: {},
        create: {
          shopId: store.id,
          code: "5010",
          name: "Shop Rent & Maintenance",
          type: "EXPENSE",
          groupId: expenseGroup.id,
          isSystem: false,
        },
      });
      await prisma.account.upsert({
        where: { shopId_code: { shopId: store.id, code: "5020" } },
        update: {},
        create: {
          shopId: store.id,
          code: "5020",
          name: "Electricity & Air Conditioning",
          type: "EXPENSE",
          groupId: expenseGroup.id,
          isSystem: false,
        },
      });
    }
  }

  console.log("[Seed] Successfully initialized SaaS Multi-Tenant Platform with sample shops & subscriptions!");
  await prisma.$disconnect();
}

seed().catch((err) => {
  console.error("[Seed Error]:", err);
  process.exit(1);
});
