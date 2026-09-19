import dotenv from "dotenv";
import { PrismaClient } from "@prisma/client";

dotenv.config();

const prisma = new PrismaClient();
const KEYCLOAK_URL = process.env.KEYCLOAK_BASE_URL || "http://localhost:8081";
const ADMIN_USER = process.env.KEYCLOAK_ADMIN_USER || "admin";
const ADMIN_PASS = process.env.KEYCLOAK_ADMIN_PASSWORD || "";
const TARGET_REALM = process.env.KEYCLOAK_REALM || "medicalcrm";

async function getAdminToken() {
  const body = new URLSearchParams({
    client_id: "admin-cli",
    username: ADMIN_USER,
    password: ADMIN_PASS,
    grant_type: "password",
  });

  const res = await fetch(`${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to get master admin token: ${res.status} ${text}`);
  }

  const data = await res.json();
  return data.access_token;
}

async function request(token, path, options = {}) {
  const headers = {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
    ...(options.headers || {}),
  };

  const res = await fetch(`${KEYCLOAK_URL}/admin/realms/${path}`, {
    ...options,
    headers,
  });

  if (res.status === 404) return null;
  if (res.status === 204) return true;

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Keycloak Admin API error [${options.method || "GET"} ${path}]: ${res.status} ${text}`);
  }

  const text = await res.text();
  return text ? JSON.parse(text) : null;
}

async function createOrUpdateUser(token, userData, password) {
  let existing = await request(token, `${TARGET_REALM}/users?username=${encodeURIComponent(userData.username)}&exact=true`);
  let kcId = null;

  if (existing && existing.length > 0) {
    kcId = existing[0].id;
    console.log(`[Store Users] User ${userData.username} already exists in Keycloak (id: ${kcId}). Resetting password...`);
    // Reset password
    await request(token, `${TARGET_REALM}/users/${kcId}/reset-password`, {
      method: "PUT",
      body: JSON.stringify({
        type: "password",
        value: password,
        temporary: false,
      }),
    });
  } else {
    console.log(`[Store Users] Creating Keycloak user ${userData.username}...`);
    await request(token, `${TARGET_REALM}/users`, {
      method: "POST",
      body: JSON.stringify({
        ...userData,
        enabled: true,
        emailVerified: true,
        credentials: [
          {
            type: "password",
            value: password,
            temporary: false,
          },
        ],
      }),
    });

    const lookup = await request(token, `${TARGET_REALM}/users?username=${encodeURIComponent(userData.username)}&exact=true`);
    if (lookup && lookup.length > 0) {
      kcId = lookup[0].id;
    }
  }

  // Ensure Pharmacist role in Keycloak
  if (kcId) {
    const pharmacistRole = await request(token, `${TARGET_REALM}/roles/Pharmacist`);
    if (pharmacistRole) {
      await request(token, `${TARGET_REALM}/users/${kcId}/role-mappings/realm`, {
        method: "POST",
        body: JSON.stringify([pharmacistRole]),
      }).catch(() => {});
    }
  }

  // Upsert in Prisma
  const user = await prisma.user.upsert({
    where: { email: userData.email },
    create: {
      keycloakId: kcId,
      email: userData.email,
      phone: userData.attributes?.phone_number?.[0] || null,
      firstName: userData.firstName,
      lastName: userData.lastName,
      emailVerified: true,
      phoneVerified: true,
      status: "ACTIVE",
    },
    update: {
      keycloakId: kcId,
      firstName: userData.firstName,
      lastName: userData.lastName,
      status: "ACTIVE",
    },
  });

  return user;
}

async function main() {
  console.log("Connecting to Keycloak and Database...");
  const token = await getAdminToken();

  // 1. Sanjeevani Store Owner
  const sanjeevaniUser = await createOrUpdateUser(
    token,
    {
      username: "sanjeevani@medicalcrm.local",
      email: "sanjeevani@medicalcrm.local",
      firstName: "Dr. Rajesh",
      lastName: "Sharma",
      attributes: {
        phone_number: ["+919811122233"],
        is_phone_verified: ["true"],
      },
    },
    "Store@123456"
  );

  // 2. CarePlus Store Owner
  const careplusUser = await createOrUpdateUser(
    token,
    {
      username: "careplus@medicalcrm.local",
      email: "careplus@medicalcrm.local",
      firstName: "Pooja",
      lastName: "Verma",
      attributes: {
        phone_number: ["+919844455566"],
        is_phone_verified: ["true"],
      },
    },
    "Store@123456"
  );

  // Find the shops
  const sanjeevaniShop = await prisma.shop.findFirst({ where: { slug: { contains: "sanjeevani" } } });
  const careplusShop = await prisma.shop.findFirst({ where: { slug: { contains: "careplus" } } });

  if (sanjeevaniShop) {
    await prisma.shopMember.upsert({
      where: {
        shopId_userId: {
          shopId: sanjeevaniShop.id,
          userId: sanjeevaniUser.id,
        },
      },
      create: {
        shopId: sanjeevaniShop.id,
        userId: sanjeevaniUser.id,
        role: "OWNER",
        status: "ACTIVE",
      },
      update: {
        role: "OWNER",
        status: "ACTIVE",
      },
    });
    console.log(`[Store Users] Assigned ${sanjeevaniUser.email} as OWNER of ${sanjeevaniShop.name}`);
  }

  if (careplusShop) {
    await prisma.shopMember.upsert({
      where: {
        shopId_userId: {
          shopId: careplusShop.id,
          userId: careplusUser.id,
        },
      },
      create: {
        shopId: careplusShop.id,
        userId: careplusUser.id,
        role: "OWNER",
        status: "ACTIVE",
      },
      update: {
        role: "OWNER",
        status: "ACTIVE",
      },
    });
    console.log(`[Store Users] Assigned ${careplusUser.email} as OWNER of ${careplusShop.name}`);
  }

  console.log("\n========================================================");
  console.log(" STORE LOGIN CREDENTIALS GENERATED SUCCESSFULLY:");
  console.log("========================================================");
  console.log("1. Store: Sanjeevani Medicos & Pharmacy (Pro Plan)");
  console.log("   - Email:    sanjeevani@medicalcrm.local");
  console.log("   - Password: Store@123456");
  console.log("   - Role:     Store Owner");
  console.log("--------------------------------------------------------");
  console.log("2. Store: CarePlus 24x7 Chemist (Trial Plan)");
  console.log("   - Email:    careplus@medicalcrm.local");
  console.log("   - Password: Store@123456");
  console.log("   - Role:     Store Owner");
  console.log("--------------------------------------------------------");
  console.log("3. Master Administrator (Access to all stores):");
  console.log("   - Email:    admin@medicalcrm.local");
  console.log("   - Password: Admin@MedicalCRM123");
  console.log("========================================================\n");
}

main()
  .catch((err) => {
    console.error("Error creating store users:", err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
