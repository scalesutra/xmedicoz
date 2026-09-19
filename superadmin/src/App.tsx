import React, { useState } from "react";
import { AuthProvider, useAuth } from "./context/AuthContext.js";
import { SuperadminLayout } from "./components/layout/SuperadminLayout.js";
import { SuperadminTab } from "./components/layout/SuperadminSidebar.js";
import { LoginPage } from "./pages/auth/LoginPage.js";
import { OverviewPage } from "./pages/overview/OverviewPage.js";
import { ShopsListPage } from "./pages/shops/ShopsListPage.js";
import { PlansPage } from "./pages/plans/PlansPage.js";
import { UsersPage } from "./pages/users/UsersPage.js";
import { AuditLogsPage } from "./pages/audit/AuditLogsPage.js";
import { SystemHealthPage } from "./pages/health/SystemHealthPage.js";
import { Sparkles } from "lucide-react";

const TAB_METADATA: Record<SuperadminTab, { title: string; subtitle: string }> = {
  overview: {
    title: "Executive Platform Cockpit",
    subtitle: "Real-time SaaS multitenancy metrics, revenue, and active pharmacy telemetry",
  },
  shops: {
    title: "Medical Stores & Tenant Pharmacies",
    subtitle: "Global directory of registered retail pharmacies, license audits & subscriptions",
  },
  plans: {
    title: "SaaS Subscription Plans & Quotas",
    subtitle: "Tier pricing, catalog quotas, invoice caps & active subscriber breakdown",
  },
  users: {
    title: "Platform User Registry",
    subtitle: "Centralized identity governance across all store branches & role assignments",
  },
  audit: {
    title: "Security & Mutation Audit Logs",
    subtitle: "Cross-tenant immutable audit trail of administrative actions and status mutations",
  },
  health: {
    title: "Live Infrastructure Health",
    subtitle: "Active latency probes for PostgreSQL connection pool, Redis cache & Node memory",
  },
};

const SuperadminAppContent: React.FC = () => {
  const { isAuthenticated, isLoading, refreshProfile } = useAuth();
  const [currentTab, setCurrentTab] = useState<SuperadminTab>("overview");
  const [refreshKey, setRefreshKey] = useState(0);

  if (isLoading) {
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          height: "100vh",
          backgroundColor: "#0B0F17",
          color: "#818CF8",
        }}
      >
        <div
          style={{
            width: "56px",
            height: "56px",
            borderRadius: "16px",
            background: "linear-gradient(135deg, #6366F1 0%, #4F46E5 100%)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#FFFFFF",
            boxShadow: "0 10px 25px -5px rgba(99, 102, 241, 0.5)",
            marginBottom: "1.25rem",
          }}
        >
          <Sparkles size={30} />
        </div>
        <div style={{ fontSize: "1.1rem", fontWeight: 700, color: "#F8FAFC", marginBottom: "0.25rem" }}>
          MedicalCRM Superadmin
        </div>
        <div style={{ fontSize: "0.8rem", color: "#64748B" }}>
          Authorizing platform administrator privileges...
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginPage onLoginSuccess={() => refreshProfile()} />;
  }

  const meta = TAB_METADATA[currentTab] || {
    title: "Superadmin Control Center",
    subtitle: "MedicalCRM Platform",
  };

  return (
    <SuperadminLayout
      currentTab={currentTab}
      onSelectTab={setCurrentTab}
      title={meta.title}
      subtitle={meta.subtitle}
      onRefreshCurrentTab={() => setRefreshKey((k) => k + 1)}
    >
      <div key={refreshKey}>
        {currentTab === "overview" && <OverviewPage onNavigate={setCurrentTab} />}
        {currentTab === "shops" && <ShopsListPage />}
        {currentTab === "plans" && <PlansPage />}
        {currentTab === "users" && <UsersPage />}
        {currentTab === "audit" && <AuditLogsPage />}
        {currentTab === "health" && <SystemHealthPage />}
      </div>
    </SuperadminLayout>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <SuperadminAppContent />
    </AuthProvider>
  );
};
