import { prisma } from "../src/infrastructure/database/prisma.client.js";
import { ROLES, PERMISSIONS } from "../src/config/constants.js";

async function seed() {
  console.log("[Seed] Seeding database roles and permissions...");

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

  // 3. Link Admin user to Admin role in DB if exists
  const adminRole = await prisma.role.findUnique({ where: { name: ROLES.ADMIN } });
  const adminUser = await prisma.user.findFirst({ where: { email: "admin@medicalcrm.local" } });

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
    console.log("[Seed] Linked admin user to Admin role in database.");
  }

  console.log("[Seed] Database roles and permissions seeded successfully.");
  await prisma.$disconnect();
}

seed().catch((err) => {
  console.error("[Seed Error]:", err);
  process.exit(1);
});
