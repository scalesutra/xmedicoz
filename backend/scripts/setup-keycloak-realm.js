/**
 * Setup Keycloak Realm, Clients, Roles, and Seed Users for Medical Store Management & CRM.
 * Interacts purely through Keycloak Admin REST API.
 * 100% NON-DISRUPTIVE: Leaves existing realms and services completely untouched.
 */
import dotenv from "dotenv";

dotenv.config();

const KEYCLOAK_URL = process.env.KEYCLOAK_BASE_URL || "http://localhost:8081";
const ADMIN_USER = process.env.KEYCLOAK_ADMIN_USER || "admin";
const ADMIN_PASS = process.env.KEYCLOAK_ADMIN_PASSWORD || "";
const TARGET_REALM = process.env.KEYCLOAK_REALM || "medicalcrm";
const API_CLIENT_ID = process.env.KEYCLOAK_CLIENT_ID || "medicalcrm-api";
const API_CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET || "medicalcrm_api_secret_change_me";
const WEB_CLIENT_ID = process.env.KEYCLOAK_WEB_CLIENT_ID || "medicalcrm-web";

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

  const contentType = res.headers.get("content-type");
  if (contentType && contentType.includes("application/json")) {
    return await res.json();
  }
  return await res.text();
}

async function main() {
  console.log(`[Keycloak Setup] Connecting to ${KEYCLOAK_URL}...`);
  const token = await getAdminToken();
  console.log("[Keycloak Setup] Admin token obtained successfully.");

  // 1. Check or Create Realm
  let realm = null;
  try {
    const res = await fetch(`${KEYCLOAK_URL}/admin/realms/${TARGET_REALM}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (res.ok) {
      realm = await res.json();
    }
  } catch (err) {
    // realm doesn't exist
  }

  if (!realm) {
    console.log(`[Keycloak Setup] Creating realm: ${TARGET_REALM}...`);
    const realmPayload = {
      id: TARGET_REALM,
      realm: TARGET_REALM,
      displayName: "Medical Store Management & CRM",
      enabled: true,
      registrationAllowed: false,
      resetPasswordAllowed: true,
      rememberMe: true,
      loginWithEmailAllowed: true,
      duplicateEmailsAllowed: false,
      accessTokenLifespan: 3600, // 1 hour
      ssoSessionIdleTimeout: 86400, // 24 hours
      ssoSessionMaxLifespan: 604800, // 7 days
    };

    const createRes = await fetch(`${KEYCLOAK_URL}/admin/realms`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(realmPayload),
    });

    if (!createRes.ok && createRes.status !== 409) {
      const text = await createRes.text();
      throw new Error(`Failed to create realm: ${createRes.status} ${text}`);
    }
    console.log(`[Keycloak Setup] Realm ${TARGET_REALM} created.`);
  } else {
    console.log(`[Keycloak Setup] Realm ${TARGET_REALM} already exists.`);
  }

  // 2. Roles
  const roles = ["Admin", "Pharmacist", "Cashier", "Staff"];
  for (const roleName of roles) {
    try {
      await request(token, `${TARGET_REALM}/roles`, {
        method: "POST",
        body: JSON.stringify({ name: roleName, description: `${roleName} role for Medical CRM` }),
      });
      console.log(`[Keycloak Setup] Role created: ${roleName}`);
    } catch (err) {
      if (err.message.includes("409")) {
        console.log(`[Keycloak Setup] Role already exists: ${roleName}`);
      } else {
        console.warn(`[Keycloak Setup] Role notice:`, err.message);
      }
    }
  }

  // 3. Clients
  // Client 1: medicalcrm-api (Service Account + Direct Access Grants)
  const existingClients = await request(token, `${TARGET_REALM}/clients`) || [];
  let apiClient = existingClients.find((c) => c.clientId === API_CLIENT_ID);

  if (!apiClient) {
    console.log(`[Keycloak Setup] Creating confidential client: ${API_CLIENT_ID}...`);
    await request(token, `${TARGET_REALM}/clients`, {
      method: "POST",
      body: JSON.stringify({
        clientId: API_CLIENT_ID,
        name: "Medical CRM API Backend",
        enabled: true,
        protocol: "openid-connect",
        publicClient: false,
        bearerOnly: false,
        standardFlowEnabled: true,
        implicitFlowEnabled: false,
        directAccessGrantsEnabled: true,
        serviceAccountsEnabled: true,
        secret: API_CLIENT_SECRET,
        fullScopeAllowed: true,
      }),
    });
    const refreshedClients = await request(token, `${TARGET_REALM}/clients`);
    apiClient = refreshedClients.find((c) => c.clientId === API_CLIENT_ID);
    console.log(`[Keycloak Setup] Client ${API_CLIENT_ID} created.`);
  } else {
    console.log(`[Keycloak Setup] Client ${API_CLIENT_ID} exists.`);
  }

  // Assign realm-management service-account roles to medicalcrm-api
  if (apiClient && apiClient.serviceAccountsEnabled) {
    try {
      const saUser = await request(token, `${TARGET_REALM}/clients/${apiClient.id}/service-account-user`);
      if (saUser && saUser.id) {
        const realmMgmtClient = existingClients.find((c) => c.clientId === "realm-management");
        if (realmMgmtClient) {
          const mgmtRoles = await request(token, `${TARGET_REALM}/clients/${realmMgmtClient.id}/roles`);
          const rolesToAssign = mgmtRoles.filter((r) =>
            ["manage-users", "view-users", "query-users"].includes(r.name)
          );
          if (rolesToAssign.length > 0) {
            await request(token, `${TARGET_REALM}/users/${saUser.id}/role-mappings/clients/${realmMgmtClient.id}`, {
              method: "POST",
              body: JSON.stringify(rolesToAssign),
            });
            console.log(`[Keycloak Setup] Assigned realm-management roles to service-account.`);
          }
        }
      }
    } catch (err) {
      console.warn(`[Keycloak Setup] Service account role notice: ${err.message}`);
    }
  }

  // Client 2: medicalcrm-web (Public client for UI)
  let webClient = existingClients.find((c) => c.clientId === WEB_CLIENT_ID);
  if (!webClient) {
    console.log(`[Keycloak Setup] Creating public client: ${WEB_CLIENT_ID}...`);
    await request(token, `${TARGET_REALM}/clients`, {
      method: "POST",
      body: JSON.stringify({
        clientId: WEB_CLIENT_ID,
        name: "Medical CRM Web Application",
        enabled: true,
        protocol: "openid-connect",
        publicClient: true,
        standardFlowEnabled: true,
        implicitFlowEnabled: false,
        directAccessGrantsEnabled: true,
        redirectUris: ["*"],
        webOrigins: ["*"],
        fullScopeAllowed: true,
      }),
    });
    console.log(`[Keycloak Setup] Client ${WEB_CLIENT_ID} created.`);
  } else {
    console.log(`[Keycloak Setup] Client ${WEB_CLIENT_ID} exists.`);
  }

  // 4. Default Seed Admin User
  const users = await request(token, `${TARGET_REALM}/users?username=admin@medicalcrm.local`) || [];
  if (users.length === 0) {
    console.log("[Keycloak Setup] Creating seed administrator user...");
    await request(token, `${TARGET_REALM}/users`, {
      method: "POST",
      body: JSON.stringify({
        username: "admin@medicalcrm.local",
        email: "admin@medicalcrm.local",
        firstName: "Store",
        lastName: "Admin",
        enabled: true,
        emailVerified: true,
        attributes: {
          phone_number: ["+919999999999"],
          is_phone_verified: ["true"],
          is_email_verified: ["true"],
        },
        credentials: [
          {
            type: "password",
            value: "Admin@MedicalCRM123",
            temporary: false,
          },
        ],
      }),
    });

    const newUsers = await request(token, `${TARGET_REALM}/users?username=admin@medicalcrm.local`);
    if (newUsers && newUsers[0]) {
      const adminRole = await request(token, `${TARGET_REALM}/roles/Admin`);
      if (adminRole) {
        await request(token, `${TARGET_REALM}/users/${newUsers[0].id}/role-mappings/realm`, {
          method: "POST",
          body: JSON.stringify([adminRole]),
        });
        console.log("[Keycloak Setup] Admin role assigned to seed administrator.");
      }
    }
    console.log("[Keycloak Setup] Seed admin user created: admin@medicalcrm.local / Admin@MedicalCRM123 / Phone: +919999999999");
  } else {
    console.log("[Keycloak Setup] Seed administrator already exists.");
  }

  console.log(`\n======================================================`);
  console.log(`Keycloak Realm "${TARGET_REALM}" is ready for Medical CRM!`);
  console.log(`Issuer: ${KEYCLOAK_URL}/realms/${TARGET_REALM}`);
  console.log(`Cert URL: ${KEYCLOAK_URL}/realms/${TARGET_REALM}/protocol/openid-connect/certs`);
  console.log(`API Client: ${API_CLIENT_ID}`);
  console.log(`Web Client: ${WEB_CLIENT_ID}`);
  console.log(`======================================================\n`);
}

main().catch((err) => {
  console.error("[Keycloak Setup Error]:", err);
  process.exit(1);
});
