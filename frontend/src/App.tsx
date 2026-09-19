import React, { useState } from "react";
import { Plus } from "lucide-react";
import { useAuth } from "./context/AuthContext.js";
import { MainLayout } from "./components/layout/MainLayout.js";
import { NavTab } from "./components/layout/Sidebar.js";

// Pages
import { LoginPage } from "./pages/auth/LoginPage.js";
import { DashboardPage } from "./pages/dashboard/DashboardPage.js";
import { PosBillingPage } from "./pages/sales/PosBillingPage.js";
import { BatchesPage } from "./pages/inventory/BatchesPage.js";
import { RacksPage } from "./pages/inventory/RacksPage.js";
import { PurchasesPage } from "./pages/purchases/PurchasesPage.js";
import { RefillsDuePage } from "./pages/crm/RefillsDuePage.js";
import { AccountingPage } from "./pages/accounting/AccountingPage.js";
import { MedicinesPage } from "./pages/masters/MedicinesPage.js";
import { CustomersPage } from "./pages/masters/CustomersPage.js";
import { SuppliersPage } from "./pages/masters/SuppliersPage.js";
import { StoreSettingsPage } from "./pages/settings/StoreSettingsPage.js";
import { MasterLookupsPage } from "./pages/masters/MasterLookupsPage.js";
import { PurchaseOrdersPage } from "./pages/purchases/PurchaseOrdersPage.js";
import { StockLedgerPage } from "./pages/inventory/StockLedgerPage.js";
import { ShopOnboardModal } from "./components/shop/ShopOnboardModal.js";
import { SubscriptionModal } from "./components/shop/SubscriptionModal.js";

const TAB_METADATA: Record<NavTab, { title: string; subtitle: string }> = {
  dashboard: {
    title: "Executive Medical CRM Dashboard",
    subtitle: "Real-time enterprise overview & operational telemetry",
  },
  pos: {
    title: "Sale Counter POS",
    subtitle: "High-speed counter sales billing with GST & batch tracking",
  },
  "pos-bill": {
    title: "Sale Bill Entry",
    subtitle: "High-speed counter sales billing & tax computation",
  },
  "pos-list": {
    title: "Sale Bill List",
    subtitle: "Audit log of all issued counter sales bills",
  },
  inventory: {
    title: "Inventory & Batch FEFO Explorer",
    subtitle: "Real-time batch stock tracking, expiry monitoring & stock audits",
  },
  racks: {
    title: "Physical Rack & Shelf Explorer",
    subtitle: "Store layout mapping, cold storage units (2°C-8°C), and drug shelf finder",
  },
  purchases: {
    title: "Purchase Bill Management",
    subtitle: "Stockist procurement, inward receipt & GST reconciliation",
  },
  "purchase-bill": {
    title: "Purchase Bill Entry",
    subtitle: "Stockist inward receipt & supplier AP accounting",
  },
  "purchase-list": {
    title: "Purchase Bill List",
    subtitle: "Directory of inward procurement invoices & stock receipts",
  },
  crm: {
    title: "Patient CRM & Chronic Refill Reminders",
    subtitle: "Proactive compliance outreach, WhatsApp/SMS alerts & patient history",
  },
  accounting: {
    title: "Financial Accounting & Double-Entry Daybook",
    subtitle: "24-Account COA, Trial Balance, Expense Tracking & Cash Daybook",
  },
  medicines: {
    title: "Pharmaceutical Medicine Master",
    subtitle: "Generic molecules, Schedule H/H1 tags, HSN & dosage directory",
  },
  customers: {
    title: "Patient & Customer Directory",
    subtitle: "Chronic illness tagging, credit limits & transaction logs",
  },
  suppliers: {
    title: "Vendor & Supplier Registry",
    subtitle: "Drug License, GSTIN verification & credit payment terms",
  },
  lookups: {
    title: "Pharmaceutical Master Catalogs",
    subtitle: "Therapeutic categories, packaging units & GST tax slabs",
  },
  "purchase-orders": {
    title: "Stockist Purchase Orders (PO)",
    subtitle: "Draft, place & monitor procurement orders sent to pharmaceutical distributors",
  },
  "stock-ledger": {
    title: "Stock Movement Audit Ledger",
    subtitle: "Chronological transaction audit trail for every batch in/out movement",
  },
  settings: {
    title: "Pharmacy Administration & Settings",
    subtitle: "Drug License compliance, GSTIN, invoice headers, and staff dispensary access",
  },
};

export const AppContent: React.FC = () => {
  const { isAuthenticated, isLoading, refreshProfile } = useAuth();
  const [currentTab, setCurrentTab] = useState<NavTab>("pos-bill");

  if (isLoading) {
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          height: "100vh",
          backgroundColor: "#F8FAF9",
          color: "#0F766E",
          fontFamily: "'Plus Jakarta Sans', sans-serif",
        }}
      >
        <div
          style={{
            width: "56px",
            height: "56px",
            borderRadius: "14px",
            background: "linear-gradient(135deg, #059669 0%, #0F766E 100%)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#FFFFFF",
            fontSize: "1.5rem",
            fontWeight: 800,
            boxShadow: "0 10px 25px -5px rgba(5, 150, 105, 0.4)",
            marginBottom: "1.25rem",
            animation: "pulse 2s infinite ease-in-out",
          }}
        >
          <Plus size={32} strokeWidth={3} />
        </div>
        <div style={{ fontSize: "1.15rem", fontWeight: 700, color: "#0F172A", marginBottom: "0.25rem" }}>
          MedicalCRM Enterprise
        </div>
        <div style={{ fontSize: "0.85rem", color: "#64748B" }}>
          Initializing verified clinical session...
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginPage onLoginSuccess={() => refreshProfile()} />;
  }

  const meta = TAB_METADATA[currentTab] || {
    title: "Medical Store Management",
    subtitle: "Enterprise Pharmacy & Clinical CRM",
  };

  return (
    <MainLayout
      currentTab={currentTab}
      onSelectTab={setCurrentTab}
      title={meta.title}
      subtitle={meta.subtitle}
    >
      {currentTab === "dashboard" && <DashboardPage onNavigate={setCurrentTab} />}
      {(currentTab === "pos" || currentTab === "pos-bill" || currentTab === "pos-list") && (
        <PosBillingPage initialView={currentTab === "pos-list" ? "LIST" : "ENTRY"} />
      )}
      {currentTab === "inventory" && <BatchesPage />}
      {currentTab === "racks" && <RacksPage />}
      {(currentTab === "purchases" || currentTab === "purchase-bill" || currentTab === "purchase-list") && (
        <PurchasesPage initialView={currentTab === "purchase-bill" ? "ENTRY" : "LIST"} />
      )}
      {currentTab === "crm" && <RefillsDuePage />}
      {currentTab === "accounting" && <AccountingPage />}
      {currentTab === "medicines" && <MedicinesPage />}
      {currentTab === "customers" && <CustomersPage />}
      {currentTab === "suppliers" && <SuppliersPage />}
      {currentTab === "lookups" && <MasterLookupsPage />}
      {currentTab === "purchase-orders" && <PurchaseOrdersPage />}
      {currentTab === "stock-ledger" && <StockLedgerPage />}
      {currentTab === "settings" && <StoreSettingsPage />}
      <ShopOnboardModal />
      <SubscriptionModal />
    </MainLayout>
  );
};
