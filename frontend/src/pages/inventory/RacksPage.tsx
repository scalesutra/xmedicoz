import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { TableSkeleton } from "../../components/common/LoadingSkeleton.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import {
  Layers,
  Search,
  Plus,
  X,
  FolderTree,
  ThermometerSnowflake,
  ShieldAlert,
  Boxes,
  Store,
  ChevronRight,
  Package,
  Edit2,
  Trash2,
  MapPin,
  Sparkles,
  Pill,
  AlertCircle,
  CheckCircle2,
  FileText,
} from "lucide-react";

export interface RackItem {
  id: string;
  code: string;
  name: string;
  zone: "MAIN_COUNTER" | "BACK_STORAGE" | "COLD_STORAGE" | "NARCOTICS_LOCKER" | "OTC_FLOOR" | "GENERAL";
  storageType: "STANDARD" | "REFRIGERATED" | "NARCOTICS_SAFE" | "HAZARDOUS";
  description?: string | null;
  totalShelves: number;
  rowNumber?: number | null;
  columnNumber?: number | null;
  status: "ACTIVE" | "MAINTENANCE" | "INACTIVE";
  activeMedicinesCount?: number;
  totalCapacity?: number;
  occupancyPercent?: number;
  shelves?: ShelfDetail[];
  medicines?: any[];
}

export interface ShelfDetail {
  id: string;
  shelfNumber: number;
  shelfLabel?: string | null;
  maxCapacity?: number;
  temperature?: number | null;
  medicines?: ShelfMedicine[];
}

export interface ShelfMedicine {
  id: string;
  name: string;
  genericName?: string;
  box?: string | null;
  totalStock?: number;
  dosageForm?: string;
}

interface MedicineSelectItem {
  id: string;
  name: string;
  genericName?: string;
  dosageForm?: string;
  rack?: string;
  shelf?: string;
  box?: string;
}

const ZONE_METADATA: Record<string, { label: string; color: string; bg: string; border: string; icon: any }> = {
  MAIN_COUNTER: {
    label: "Main Counter",
    color: "#0F766E",
    bg: "#F0FDFA",
    border: "#99F6E4",
    icon: Store,
  },
  COLD_STORAGE: {
    label: "Cold Storage (2°C - 8°C)",
    color: "#0284C7",
    bg: "#F0F9FF",
    border: "#BAE6FD",
    icon: ThermometerSnowflake,
  },
  NARCOTICS_LOCKER: {
    label: "Narcotics Safe (Sch H1/X)",
    color: "#D97706",
    bg: "#FFFBEB",
    border: "#FDE68A",
    icon: ShieldAlert,
  },
  BACK_STORAGE: {
    label: "Back Storage Aisles",
    color: "#4F46E5",
    bg: "#EEF2FF",
    border: "#C7D2FE",
    icon: Boxes,
  },
  OTC_FLOOR: {
    label: "OTC Self-Service Floor",
    color: "#9333EA",
    bg: "#FAF5FF",
    border: "#E9D5FF",
    icon: Package,
  },
  GENERAL: {
    label: "General Storage",
    color: "#475569",
    bg: "#F8FAFC",
    border: "#E2E8F0",
    icon: Layers,
  },
};

export const RacksPage: React.FC = () => {
  const [racks, setRacks] = useState<RackItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedZone, setSelectedZone] = useState<string>("ALL");
  const [viewType, setViewType] = useState<"GRID" | "TABLE">("GRID");

  // Detailed Rack Drawer (Inspector)
  const [inspectingRack, setInspectingRack] = useState<RackItem | null>(null);
  const [inspectLoading, setInspectLoading] = useState(false);

  // Create / Edit Modal State
  const [isFormModalOpen, setIsFormModalOpen] = useState(false);
  const [editingRackId, setEditingRackId] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    code: "",
    name: "",
    zone: "MAIN_COUNTER" as RackItem["zone"],
    storageType: "STANDARD" as RackItem["storageType"],
    description: "",
    totalShelves: 4,
    rowNumber: 1,
    columnNumber: 1,
  });

  // Assign Medicine Modal State
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [medicinesList, setMedicinesList] = useState<MedicineSelectItem[]>([]);
  const [assignForm, setAssignForm] = useState({
    medicineId: "",
    rackId: "",
    rackCode: "",
    shelfNumber: 1,
    boxNumber: "1",
  });

  // Physical Stocktake Audit Modal
  const [auditModalOpen, setAuditModalOpen] = useState(false);
  const [auditRack, setAuditRack] = useState<RackItem | null>(null);
  const [auditSheet, setAuditSheet] = useState<any | null>(null);
  const [auditCounts, setAuditCounts] = useState<Record<string, number>>({});
  const [isSubmittingAudit, setIsSubmittingAudit] = useState(false);

  // Unassigned Medicines State
  const [isUnassignedOpen, setIsUnassignedOpen] = useState(false);
  const [unassignedMeds, setUnassignedMeds] = useState<any[]>([]);
  const [isLoadingUnassigned, setIsLoadingUnassigned] = useState(false);

  // Delete Confirm Modal
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ isOpen: false, title: "", message: "", action: async () => {} });

  const getRackMedicineCount = (rack: RackItem) => {
    if (typeof rack.activeMedicinesCount === "number" && rack.activeMedicinesCount > 0) {
      return rack.activeMedicinesCount;
    }
    const localMatch = medicinesList.filter(
      (m) =>
        (m.rack && m.rack.trim().toUpperCase() === rack.code.trim().toUpperCase()) ||
        (m as any).rackId === rack.id
    ).length;
    return localMatch || rack.activeMedicinesCount || 0;
  };

  useEffect(() => {
    fetchRacks();
    fetchMedicines();
  }, []);

  const fetchRacks = async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const res = await apiRequest("/inventory/racks");
      if (res.success && res.data) {
        setRacks(Array.isArray(res.data) ? res.data : res.data.items || []);
      } else {
        setErrorMessage(res.message || "Failed to load physical racks.");
      }
    } catch (e: any) {
      setErrorMessage(e.message || "Network error while loading racks.");
    } finally {
      setIsLoading(false);
    }
  };

  const fetchMedicines = async () => {
    try {
      const res = await apiRequest("/masters/medicines", { params: { limit: 100 } });
      if (res.success && res.data) {
        setMedicinesList(Array.isArray(res.data) ? res.data : res.data.items || []);
      }
    } catch {
      // Non-blocking
    }
  };

  const inspectRackDetails = async (rack: RackItem) => {
    setInspectingRack(rack);
    setInspectLoading(true);
    try {
      const res = await apiRequest(`/inventory/racks/${rack.id}`);
      if (res.success && res.data) {
        setInspectingRack(res.data);
      }
    } catch (e: any) {
      console.error("Failed to load rack details:", e);
    } finally {
      setInspectLoading(false);
    }
  };

  const handleOpenCreate = () => {
    setEditingRackId(null);
    setFormData({
      code: "",
      name: "",
      zone: "MAIN_COUNTER",
      storageType: "STANDARD",
      description: "",
      totalShelves: 4,
      rowNumber: 1,
      columnNumber: 1,
    });
    setIsFormModalOpen(true);
  };

  const handleOpenEdit = (rack: RackItem) => {
    setEditingRackId(rack.id);
    setFormData({
      code: rack.code,
      name: rack.name,
      zone: rack.zone,
      storageType: rack.storageType,
      description: rack.description || "",
      totalShelves: rack.totalShelves,
      rowNumber: rack.rowNumber || 1,
      columnNumber: rack.columnNumber || 1,
    });
    setIsFormModalOpen(true);
  };

  const handleSaveRack = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setSuccessMessage(null);

    const code = formData.code.trim().toUpperCase();
    const name = formData.name.trim();

    if (!code || !name) {
      setErrorMessage("Please enter both rack code and name.");
      return;
    }

    try {
      const payload = {
        code,
        name,
        zone: formData.zone,
        storageType: formData.storageType,
        description: formData.description?.trim() || null,
        totalShelves: Math.max(1, Math.min(50, Number(formData.totalShelves) || 4)),
        rowNumber: formData.rowNumber ? Number(formData.rowNumber) : null,
        columnNumber: formData.columnNumber ? Number(formData.columnNumber) : null,
      };

      let res;
      if (editingRackId) {
        res = await apiRequest(`/inventory/racks/${editingRackId}`, {
          method: "PATCH",
          body: JSON.stringify(payload),
        });
      } else {
        res = await apiRequest("/inventory/racks", {
          method: "POST",
          body: JSON.stringify(payload),
        });
      }

      if (res.success) {
        setSuccessMessage(`Rack "${code}" saved successfully!`);
        setIsFormModalOpen(false);
        fetchRacks();
      } else {
        setErrorMessage(res.message || "Failed to save rack.");
      }
    } catch (e: any) {
      setErrorMessage(e.message || "Network error while saving rack.");
    }
  };

  const handleDeleteRack = (rack: RackItem) => {
    setConfirmModal({
      isOpen: true,
      title: `Delete Rack ${rack.code}`,
      message: `Are you sure you want to delete Rack ${rack.code} (${rack.name})? All assigned shelf mappings will be detached.`,
      action: async () => {
        try {
          const res = await apiRequest(`/inventory/racks/${rack.id}`, { method: "DELETE" });
          if (res.success) {
            setSuccessMessage(`Rack ${rack.code} deleted successfully.`);
            if (inspectingRack?.id === rack.id) setInspectingRack(null);
            fetchRacks();
          } else {
            setErrorMessage(res.message || "Failed to delete rack.");
          }
        } catch (e: any) {
          setErrorMessage(e.message || "Network error while deleting rack.");
        }
      },
    });
  };

  const handleAssignMedicine = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!assignForm.medicineId) {
      setErrorMessage("Please select a medicine.");
      return;
    }

    try {
      const selectedRack = racks.find((r) => r.id === assignForm.rackId);
      const res = await apiRequest("/inventory/racks/assign", {
        method: "POST",
        body: JSON.stringify({
          medicineId: assignForm.medicineId,
          rackId: assignForm.rackId || undefined,
          rackCode: selectedRack?.code || assignForm.rackCode || "A",
          shelfNumber: String(assignForm.shelfNumber),
          boxCode: assignForm.boxNumber || "1",
        }),
      });

      if (res.success) {
        setSuccessMessage("Medicine assigned to physical location successfully!");
        setIsAssignModalOpen(false);
        fetchRacks();
        fetchMedicines();
        if (inspectingRack) inspectRackDetails(inspectingRack);
      } else {
        setErrorMessage(res.message || "Failed to assign medicine.");
      }
    } catch (e: any) {
      setErrorMessage(e.message || "Network error while assigning medicine.");
    }
  };

  // 1-Click Quick Starter Packs for Empty Stores
  const handleQuickSetupRacks = async () => {
    setIsLoading(true);
    try {
      const defaultPacks = [
        { code: "A", name: "Front Counter - Fast Movers", zone: "MAIN_COUNTER", storageType: "STANDARD", totalShelves: 4, description: "Paracetamol, Cetirizine, Antacids" },
        { code: "B", name: "Front Counter - Antibiotics", zone: "MAIN_COUNTER", storageType: "STANDARD", totalShelves: 4, description: "Amoxicillin, Azithromycin, Cefixime" },
        { code: "FRIDGE-1", name: "Cold Storage Refrigerator", zone: "COLD_STORAGE", storageType: "REFRIGERATED", totalShelves: 3, description: "Insulin vials, Vaccines, Eye Drops (2°C-8°C)" },
        { code: "SAFE-1", name: "Narcotics Locked Safe", zone: "NARCOTICS_LOCKER", storageType: "NARCOTICS_SAFE", totalShelves: 2, description: "Schedule H1 & X Sedatives & Analgesics" },
        { code: "C", name: "Back Storage - Tablets Reserve", zone: "BACK_STORAGE", storageType: "STANDARD", totalShelves: 5, description: "Secondary stock cartons and bulk strips" },
      ];

      for (const pack of defaultPacks) {
        await apiRequest("/inventory/racks", {
          method: "POST",
          body: JSON.stringify(pack),
        });
      }

      setSuccessMessage("Standard pharmacy racks & cold storage units set up successfully!");
      fetchRacks();
    } catch (e: any) {
      setErrorMessage(e.message || "Failed to initialize sample racks.");
    } finally {
      setIsLoading(false);
    }
  };

  const openAuditModal = async (rack: RackItem) => {
    setAuditRack(rack);
    setAuditModalOpen(true);
    setAuditSheet(null);
    try {
      const res = await apiRequest(`/inventory/racks/${rack.id}/audit-sheet`);
      if (res.success && res.data) {
        setAuditSheet(res.data);
        const initialCounts: Record<string, number> = {};
        (res.data.items || []).forEach((it: any) => {
          initialCounts[it.batchId] = it.systemStock;
        });
        setAuditCounts(initialCounts);
      }
    } catch (e: any) {
      setErrorMessage("Failed to generate audit sheet: " + e.message);
    }
  };

  const handleSubmitAudit = async () => {
    if (!auditRack || !auditSheet) return;
    setIsSubmittingAudit(true);
    try {
      const auditItems = (auditSheet.items || []).map((it: any) => ({
        batchId: it.batchId,
        physicalCount: Number(auditCounts[it.batchId] ?? it.systemStock),
        systemCount: it.systemStock,
      }));
      const res = await apiRequest(`/inventory/racks/${auditRack.id}/audit-verify`, {
        method: "POST",
        body: JSON.stringify({ auditItems }),
      });
      if (res.success) {
        setSuccessMessage("Physical stock audit submitted & variance ledger adjusted successfully!");
        setAuditModalOpen(false);
        fetchRacks();
        setTimeout(() => setSuccessMessage(null), 4000);
      } else {
        setErrorMessage(res.message || "Failed to submit audit.");
      }
    } catch (e: any) {
      setErrorMessage(e.message || "Network error while submitting audit.");
    } finally {
      setIsSubmittingAudit(false);
    }
  };

  const loadUnassignedMeds = async () => {
    setIsUnassignedOpen(true);
    setIsLoadingUnassigned(true);
    try {
      const res = await apiRequest("/inventory/racks/unassigned");
      if (res.success && res.data) {
        setUnassignedMeds(Array.isArray(res.data) ? res.data : (res.data as any).items || []);
      }
    } catch (e: any) {
      console.error(e);
    } finally {
      setIsLoadingUnassigned(false);
    }
  };

  // Filtering
  const filteredRacks = racks.filter((r) => {
    const matchesSearch =
      r.code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (r.description && r.description.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesZone = selectedZone === "ALL" || r.zone === selectedZone;
    return matchesSearch && matchesZone;
  });

  // Metric Aggregates
  const totalRacksCount = racks.length;
  const totalShelvesCount = racks.reduce((acc, r) => acc + (r.totalShelves || 0), 0);
  const coldStorageCount = racks.filter((r) => r.storageType === "REFRIGERATED" || r.zone === "COLD_STORAGE").length;
  const narcoticsCount = racks.filter((r) => r.storageType === "NARCOTICS_SAFE" || r.zone === "NARCOTICS_LOCKER").length;

  return (
    <div style={{ display: "flex", flexDirection: "column", flex: 1, minHeight: "100%", backgroundColor: "#F8FAFC" }}>
      {/* Header Banner */}
      <div
        style={{
          padding: "1rem 1.5rem",
          backgroundColor: "#FFFFFF",
          borderBottom: "1px solid #E2E8F0",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "1rem",
        }}
      >
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <FolderTree size={22} color="#0F766E" />
            <h1 style={{ fontSize: "1.25rem", fontWeight: 800, color: "#0F172A", margin: 0 }}>
              Physical Rack & Shelf Management
            </h1>
          </div>
          <p style={{ margin: "4px 0 0 0", fontSize: "0.82rem", color: "#64748B" }}>
            Map and manage physical store locations, cold storage units, and drug shelves for instant retrieval at POS.
          </p>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
          {racks.length === 0 && (
            <button
              onClick={handleQuickSetupRacks}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "6px",
                backgroundColor: "#0284C7",
                color: "#FFFFFF",
                border: "none",
                borderRadius: "6px",
                padding: "8px 14px",
                fontSize: "0.82rem",
                fontWeight: 700,
                cursor: "pointer",
              }}
              title="Set up pre-configured pharmacy racks with cold storage"
            >
              <Sparkles size={14} /> Quick-Setup Pharmacy Racks
            </button>
          )}

          <button
            onClick={loadUnassignedMeds}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              backgroundColor: "#FFFBEB",
              color: "#B45309",
              border: "1px solid #FDE68A",
              borderRadius: "6px",
              padding: "8px 14px",
              fontSize: "0.82rem",
              fontWeight: 700,
              cursor: "pointer",
            }}
          >
            <AlertCircle size={14} color="#B45309" /> Unallocated Drugs
          </button>

          <button
            onClick={() => {
              if (racks.length > 0) {
                setAssignForm({
                  medicineId: medicinesList[0]?.id || "",
                  rackId: racks[0]?.id || "",
                  rackCode: racks[0]?.code || "A",
                  shelfNumber: 1,
                  boxNumber: "1",
                });
              }
              setIsAssignModalOpen(true);
            }}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              backgroundColor: "#F1F5F9",
              color: "#334155",
              border: "1px solid #CBD5E1",
              borderRadius: "6px",
              padding: "8px 14px",
              fontSize: "0.82rem",
              fontWeight: 700,
              cursor: "pointer",
            }}
          >
            <MapPin size={14} color="#0F766E" /> Assign Medicine Location
          </button>

          <button
            onClick={handleOpenCreate}
            className="marg-btn-teal"
            style={{ display: "flex", alignItems: "center", gap: "6px", padding: "8px 16px" }}
          >
            <Plus size={15} /> + Add New Rack
          </button>
        </div>
      </div>

      {/* Messages */}
      {errorMessage && (
        <div
          style={{
            margin: "0.75rem 1.5rem 0",
            backgroundColor: "#FEF2F2",
            borderLeft: "4px solid #EF4444",
            padding: "10px 16px",
            color: "#991B1B",
            fontSize: "0.84rem",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            borderRadius: "4px",
          }}
        >
          <span>{errorMessage}</span>
          <button onClick={() => setErrorMessage(null)} style={{ background: "none", border: "none", color: "#991B1B", cursor: "pointer" }}>✕</button>
        </div>
      )}

      {successMessage && (
        <div
          style={{
            margin: "0.75rem 1.5rem 0",
            backgroundColor: "#ECFDF5",
            borderLeft: "4px solid #10B981",
            padding: "10px 16px",
            color: "#065F46",
            fontSize: "0.84rem",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            borderRadius: "4px",
          }}
        >
          <span>{successMessage}</span>
          <button onClick={() => setSuccessMessage(null)} style={{ background: "none", border: "none", color: "#065F46", cursor: "pointer" }}>✕</button>
        </div>
      )}

      {/* Simple, Clean Controls Bar */}
      <div
        style={{
          padding: "1rem 1.5rem",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "12px",
          backgroundColor: "#FFFFFF",
          borderBottom: "1px solid #E2E8F0",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: "10px", flex: "1 1 340px", maxWidth: "560px" }}>
          {/* Search Box */}
          <div style={{ position: "relative", flex: 1 }}>
            <Search size={15} color="#94A3B8" style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)" }} />
            <input
              type="text"
              placeholder="Search rack (e.g. A, Front Counter, Fridge)..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                width: "100%",
                padding: "7px 10px 7px 32px",
                border: "1px solid #CBD5E1",
                borderRadius: "6px",
                fontSize: "0.84rem",
                backgroundColor: "#F8FAFC",
                outline: "none",
              }}
            />
          </div>

          {/* Simple Location Filter */}
          <select
            value={selectedZone}
            onChange={(e) => setSelectedZone(e.target.value)}
            style={{
              padding: "7px 10px",
              border: "1px solid #CBD5E1",
              borderRadius: "6px",
              fontSize: "0.82rem",
              backgroundColor: "#F8FAFC",
              color: "#1E293B",
              fontWeight: 600,
              outline: "none",
              cursor: "pointer",
            }}
          >
            <option value="ALL">All Locations ({racks.length})</option>
            <option value="MAIN_COUNTER">Main Counter ({racks.filter((r) => r.zone === "MAIN_COUNTER").length})</option>
            <option value="COLD_STORAGE">Cold Storage / Refrigerator ({racks.filter((r) => r.zone === "COLD_STORAGE").length})</option>
            <option value="NARCOTICS_LOCKER">Schedule H1 Locker ({racks.filter((r) => r.zone === "NARCOTICS_LOCKER").length})</option>
            <option value="BACK_STORAGE">Back Storage / Aisles ({racks.filter((r) => r.zone === "BACK_STORAGE").length})</option>
            <option value="OTC_FLOOR">OTC Self-Service Floor ({racks.filter((r) => r.zone === "OTC_FLOOR").length})</option>
            <option value="GENERAL">General Storage ({racks.filter((r) => r.zone === "GENERAL").length})</option>
          </select>
        </div>

        {/* View Switcher: Cards vs Table */}
        <div style={{ display: "flex", alignItems: "center", gap: "4px", backgroundColor: "#F1F5F9", padding: "3px", borderRadius: "6px" }}>
          <button
            onClick={() => setViewType("GRID")}
            style={{
              padding: "5px 12px",
              borderRadius: "4px",
              border: "none",
              backgroundColor: viewType === "GRID" ? "#0F766E" : "transparent",
              color: viewType === "GRID" ? "#FFFFFF" : "#475569",
              fontSize: "0.78rem",
              fontWeight: 700,
              cursor: "pointer",
            }}
          >
            Cards
          </button>
          <button
            onClick={() => setViewType("TABLE")}
            style={{
              padding: "5px 12px",
              borderRadius: "4px",
              border: "none",
              backgroundColor: viewType === "TABLE" ? "#0F766E" : "transparent",
              color: viewType === "TABLE" ? "#FFFFFF" : "#475569",
              fontSize: "0.78rem",
              fontWeight: 700,
              cursor: "pointer",
            }}
          >
            Table
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div
        style={{
          display: "flex",
          flex: 1,
          padding: "1.25rem 1.5rem 2rem",
          gap: "1.25rem",
          flexWrap: "wrap",
          alignItems: "flex-start",
          minWidth: 0,
        }}
      >
        {/* Rack List / Grid */}
        <div
          style={{
            flex: inspectingRack ? "1 1 580px" : "1 1 100%",
            minWidth: 0,
            maxWidth: "100%",
            transition: "all 0.2s",
          }}
        >
          {isLoading ? (
            <TableSkeleton rows={5} cols={4} />
          ) : filteredRacks.length === 0 ? (
            <div style={{ backgroundColor: "#FFFFFF", borderRadius: "8px", border: "1px solid #E2E8F0", padding: "2.5rem 1.5rem", textAlign: "center" }}>
              <FolderTree size={36} color="#94A3B8" style={{ margin: "0 auto 0.75rem" }} />
              <h3 style={{ fontSize: "1rem", fontWeight: 700, color: "#1E293B", margin: "0 0 4px 0" }}>No Racks Found</h3>
              <p style={{ fontSize: "0.82rem", color: "#64748B", maxWidth: "400px", margin: "0 auto 1rem" }}>
                {searchQuery || selectedZone !== "ALL"
                  ? "No racks match your search filters."
                  : "No physical storage racks have been created yet. Click + Add New Rack above."}
              </p>
              <button onClick={handleOpenCreate} className="marg-btn-teal">
                <Plus size={14} /> + Add First Rack
              </button>
            </div>
          ) : viewType === "TABLE" ? (
            /* SIMPLE TABLE VIEW FOR SHOPKEEPERS */
            <div className="glass-card" style={{ overflowX: "auto", borderRadius: "8px", border: "1px solid #E2E8F0" }}>
              <table style={{ width: "100%", minWidth: "750px", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
                <thead>
                  <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                    <th style={{ padding: "0.75rem 1rem", minWidth: "110px", whiteSpace: "nowrap" }}>Rack Code</th>
                    <th style={{ padding: "0.75rem 1rem", minWidth: "180px" }}>Rack Name</th>
                    <th style={{ padding: "0.75rem 1rem", minWidth: "160px", whiteSpace: "nowrap" }}>Location / Zone</th>
                    <th style={{ padding: "0.75rem 1rem", minWidth: "90px", whiteSpace: "nowrap" }}>Shelves</th>
                    <th style={{ padding: "0.75rem 1rem", minWidth: "110px", whiteSpace: "nowrap" }}>Medicines</th>
                    <th style={{ padding: "0.75rem 1rem", minWidth: "140px", whiteSpace: "nowrap", textAlign: "right" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRacks.map((rack) => {
                    const zoneMeta = ZONE_METADATA[rack.zone] || ZONE_METADATA.GENERAL;
                    const isInspecting = inspectingRack?.id === rack.id;
                    const medCount = getRackMedicineCount(rack);
                    return (
                      <tr
                        key={rack.id}
                        onClick={() => inspectRackDetails(rack)}
                        style={{
                          borderBottom: "1px solid #F1F5F9",
                          backgroundColor: isInspecting ? "#FEF3C7" : undefined,
                          cursor: "pointer",
                        }}
                      >
                        <td style={{ padding: "0.75rem 1rem", fontWeight: 800, color: "#0F766E", fontFamily: "monospace", fontSize: "0.95rem", whiteSpace: "nowrap" }}>
                          {rack.code}
                        </td>
                        <td style={{ padding: "0.75rem 1rem", fontWeight: 700, color: "#0F172A" }}>
                          <div>{rack.name}</div>
                          {rack.description && (
                            <div style={{ fontSize: "0.74rem", color: "#64748B", fontWeight: 400 }}>{rack.description}</div>
                          )}
                        </td>
                        <td style={{ padding: "0.75rem 1rem", whiteSpace: "nowrap" }}>
                          <span
                            style={{
                              fontSize: "0.72rem",
                              fontWeight: 700,
                              color: zoneMeta.color,
                              backgroundColor: zoneMeta.bg,
                              border: `1px solid ${zoneMeta.border}`,
                              padding: "2px 8px",
                              borderRadius: "12px",
                              whiteSpace: "nowrap",
                            }}
                          >
                            {zoneMeta.label}
                          </span>
                        </td>
                        <td style={{ padding: "0.75rem 1rem", color: "#334155", fontWeight: 600, whiteSpace: "nowrap" }}>
                          {rack.totalShelves} Shelves
                        </td>
                        <td style={{ padding: "0.75rem 1rem", whiteSpace: "nowrap" }}>
                          <span
                            style={{
                              fontSize: "0.75rem",
                              fontWeight: 700,
                              color: medCount > 0 ? "#0F766E" : "#64748B",
                              backgroundColor: medCount > 0 ? "#ECFDF5" : "#F1F5F9",
                              border: `1px solid ${medCount > 0 ? "#A7F3D0" : "#E2E8F0"}`,
                              padding: "2px 8px",
                              borderRadius: "12px",
                              display: "inline-block",
                            }}
                          >
                            {medCount} items
                          </span>
                        </td>
                        <td style={{ padding: "0.75rem 1rem", textAlign: "right", whiteSpace: "nowrap" }}>
                          <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                inspectRackDetails(rack);
                              }}
                              style={{
                                padding: "4px 8px",
                                backgroundColor: "#F0FDFA",
                                border: "1px solid #CCFBF1",
                                color: "#0F766E",
                                borderRadius: "4px",
                                fontSize: "0.75rem",
                                fontWeight: 600,
                                cursor: "pointer",
                              }}
                            >
                              Shelves
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                openAuditModal(rack);
                              }}
                              style={{
                                padding: "4px 8px",
                                backgroundColor: "#FEF3C7",
                                border: "1px solid #FDE68A",
                                color: "#92400E",
                                borderRadius: "4px",
                                fontSize: "0.75rem",
                                fontWeight: 600,
                                cursor: "pointer",
                              }}
                            >
                              Audit
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                handleOpenEdit(rack);
                              }}
                              style={{
                                padding: "4px 8px",
                                backgroundColor: "#EFF6FF",
                                border: "1px solid #DBEAFE",
                                color: "#1D4ED8",
                                borderRadius: "4px",
                                fontSize: "0.75rem",
                                fontWeight: 600,
                                cursor: "pointer",
                              }}
                            >
                              Edit
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                handleDeleteRack(rack);
                              }}
                              style={{
                                padding: "4px 6px",
                                backgroundColor: "#FEF2F2",
                                border: "1px solid #FEE2E2",
                                color: "#DC2626",
                                borderRadius: "4px",
                                fontSize: "0.75rem",
                                cursor: "pointer",
                              }}
                            >
                              <Trash2 size={12} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          ) : (
            /* CLEAN, USER-FRIENDLY CARD VIEW */
            <div style={{ display: "grid", gridTemplateColumns: inspectingRack ? "1fr" : "repeat(auto-fill, minmax(280px, 1fr))", gap: "14px" }}>
              {filteredRacks.map((rack) => {
                const zoneMeta = ZONE_METADATA[rack.zone] || ZONE_METADATA.GENERAL;
                const isInspecting = inspectingRack?.id === rack.id;

                return (
                  <div
                    key={rack.id}
                    onClick={() => inspectRackDetails(rack)}
                    style={{
                      backgroundColor: "#FFFFFF",
                      borderRadius: "8px",
                      border: isInspecting ? "2px solid #0F766E" : "1px solid #E2E8F0",
                      boxShadow: isInspecting ? "0 4px 12px rgba(15, 118, 110, 0.15)" : "0 1px 3px rgba(0,0,0,0.04)",
                      padding: "1rem",
                      cursor: "pointer",
                      display: "flex",
                      flexDirection: "column",
                      justifyContent: "space-between",
                      gap: "12px",
                      transition: "all 0.15s ease-in-out",
                    }}
                  >
                    <div>
                      {/* Top Row: Code Badge & Zone Tag */}
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: "8px", marginBottom: "6px" }}>
                        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                          <span
                            style={{
                              fontFamily: "monospace",
                              fontSize: "1.05rem",
                              fontWeight: 900,
                              backgroundColor: "#0F766E",
                              color: "#FFFFFF",
                              padding: "2px 8px",
                              borderRadius: "4px",
                            }}
                          >
                            {rack.code}
                          </span>
                          <div>
                            <div style={{ fontWeight: 800, fontSize: "0.92rem", color: "#0F172A" }}>{rack.name}</div>
                            {rack.storageType === "REFRIGERATED" && (
                              <span style={{ fontSize: "0.7rem", color: "#0284C7", fontWeight: 700 }}>❄️ Cold Chain 2°C-8°C</span>
                            )}
                            {rack.storageType === "NARCOTICS_SAFE" && (
                              <span style={{ fontSize: "0.7rem", color: "#D97706", fontWeight: 700 }}>🔒 Schedule H1 Lock</span>
                            )}
                          </div>
                        </div>

                        {/* Zone Tag */}
                        <span
                          style={{
                            fontSize: "0.68rem",
                            fontWeight: 700,
                            color: zoneMeta.color,
                            backgroundColor: zoneMeta.bg,
                            border: `1px solid ${zoneMeta.border}`,
                            padding: "2px 8px",
                            borderRadius: "12px",
                            whiteSpace: "nowrap",
                          }}
                        >
                          {zoneMeta.label}
                        </span>
                      </div>

                      {rack.description && (
                        <p style={{ margin: "4px 0 8px 0", fontSize: "0.78rem", color: "#64748B", lineHeight: 1.4 }}>
                          {rack.description}
                        </p>
                      )}

                      {/* Clean Simple Stats */}
                      <div
                        style={{
                          display: "flex",
                          justifyContent: "space-between",
                          fontSize: "0.78rem",
                          backgroundColor: "#F8FAFC",
                          border: "1px solid #E2E8F0",
                          borderRadius: "6px",
                          padding: "8px 12px",
                          marginTop: "8px",
                        }}
                      >
                        <span style={{ color: "#475569" }}>
                          Shelves: <strong style={{ color: "#0F172A" }}>{rack.totalShelves}</strong>
                        </span>
                        <span style={{ color: "#475569" }}>
                          Medicines: <strong style={{ color: getRackMedicineCount(rack) > 0 ? "#0F766E" : "#64748B" }}>{getRackMedicineCount(rack)} items</strong>
                        </span>
                      </div>
                    </div>

                    {/* Bottom Action Bar */}
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        paddingTop: "8px",
                        borderTop: "1px solid #F1F5F9",
                      }}
                    >
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          inspectRackDetails(rack);
                        }}
                        style={{
                          padding: "4px 10px",
                          backgroundColor: isInspecting ? "#0F766E" : "#F0FDFA",
                          color: isInspecting ? "#FFFFFF" : "#0F766E",
                          border: "1px solid #0F766E",
                          borderRadius: "4px",
                          fontSize: "0.75rem",
                          fontWeight: 700,
                          cursor: "pointer",
                        }}
                      >
                        View Shelves →
                      </button>

                      <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleOpenEdit(rack);
                          }}
                          style={{
                            padding: "4px 8px",
                            backgroundColor: "#F8FAFC",
                            border: "1px solid #CBD5E1",
                            color: "#334155",
                            borderRadius: "4px",
                            fontSize: "0.75rem",
                            fontWeight: 600,
                            cursor: "pointer",
                          }}
                        >
                          Edit
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDeleteRack(rack);
                          }}
                          style={{
                            padding: "4px 6px",
                            backgroundColor: "#FEF2F2",
                            border: "1px solid #FEE2E2",
                            color: "#DC2626",
                            borderRadius: "4px",
                            fontSize: "0.75rem",
                            cursor: "pointer",
                          }}
                          title="Delete Rack"
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Detailed Shelf Inspector Drawer */}
        {inspectingRack && (() => {
          const allRackMeds = (inspectingRack.medicines && inspectingRack.medicines.length > 0)
            ? inspectingRack.medicines
            : medicinesList.filter(
                (m) =>
                  (m.rack && m.rack.trim().toUpperCase() === inspectingRack.code.trim().toUpperCase()) ||
                  (m as any).rackId === inspectingRack.id
              );
          const totalRackMeds = allRackMeds.length;

          return (
            <div
              style={{
                flex: "1 1 380px",
                width: "380px",
                minWidth: "320px",
                maxWidth: "100%",
                backgroundColor: "#FFFFFF",
                borderRadius: "8px",
                border: "1px solid #CBD5E1",
                boxShadow: "0 4px 16px rgba(0,0,0,0.08)",
                padding: "1.25rem",
                display: "flex",
                flexDirection: "column",
                maxHeight: "calc(100vh - 180px)",
                overflowY: "auto",
                boxSizing: "border-box",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "0.75rem", borderBottom: "1px solid #E2E8F0", paddingBottom: "0.75rem" }}>
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <span style={{ fontFamily: "monospace", fontSize: "1.2rem", fontWeight: 900, backgroundColor: "#0F766E", color: "#FFFFFF", padding: "2px 8px", borderRadius: "4px" }}>
                      {inspectingRack.code}
                    </span>
                    <h3 style={{ margin: 0, fontSize: "1.05rem", fontWeight: 800, color: "#0F172A" }}>
                      {inspectingRack.name}
                    </h3>
                  </div>
                  <div style={{ fontSize: "0.76rem", color: "#64748B", marginTop: "4px" }}>
                    Zone: <strong>{inspectingRack.zone}</strong> • Storage: <strong>{inspectingRack.storageType}</strong>
                  </div>
                </div>

                <button
                  onClick={() => setInspectingRack(null)}
                  style={{ background: "none", border: "none", color: "#64748B", cursor: "pointer", padding: "4px" }}
                  title="Close Inspector"
                >
                  <X size={18} />
                </button>
              </div>

              {/* Summary Stats Row */}
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(3, 1fr)",
                  gap: "6px",
                  backgroundColor: "#F8FAFC",
                  border: "1px solid #E2E8F0",
                  borderRadius: "8px",
                  padding: "8px 10px",
                  marginBottom: "1rem",
                  textAlign: "center",
                }}
              >
                <div>
                  <div style={{ fontSize: "0.68rem", color: "#64748B", textTransform: "uppercase", fontWeight: 700 }}>Medicines</div>
                  <div style={{ fontSize: "0.95rem", fontWeight: 800, color: "#0F766E" }}>
                    {totalRackMeds} items
                  </div>
                </div>
                <div style={{ borderLeft: "1px solid #E2E8F0", borderRight: "1px solid #E2E8F0" }}>
                  <div style={{ fontSize: "0.68rem", color: "#64748B", textTransform: "uppercase", fontWeight: 700 }}>Shelves</div>
                  <div style={{ fontSize: "0.95rem", fontWeight: 800, color: "#1E293B" }}>
                    {inspectingRack.totalShelves}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: "0.68rem", color: "#64748B", textTransform: "uppercase", fontWeight: 700 }}>Capacity</div>
                  <div style={{ fontSize: "0.95rem", fontWeight: 800, color: "#475569" }}>
                    {inspectingRack.totalCapacity || inspectingRack.totalShelves * 100}
                  </div>
                </div>
              </div>

              {/* Quick Shelf Mapping Breakdown */}
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem", flexWrap: "wrap", gap: "6px" }}>
                <h4 style={{ margin: 0, fontSize: "0.85rem", fontWeight: 700, color: "#334155" }}>
                  Shelves & Box Locations
                </h4>
                <button
                  onClick={() => {
                    setAssignForm({
                      medicineId: medicinesList[0]?.id || "",
                      rackId: inspectingRack.id,
                      rackCode: inspectingRack.code,
                      shelfNumber: 1,
                      boxNumber: "1",
                    });
                    setIsAssignModalOpen(true);
                  }}
                  className="marg-btn-teal"
                  style={{ padding: "4px 8px", fontSize: "0.72rem", whiteSpace: "nowrap" }}
                >
                  + Put Medicine
                </button>
              </div>

              {inspectLoading ? (
                <TableSkeleton rows={4} cols={2} />
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                  {Array.from({ length: inspectingRack.totalShelves }).map((_, idx) => {
                    const shelfNum = idx + 1;
                    const medicinesOnShelf = allRackMeds.filter(
                      (m: any) => String(m.shelf || "1").trim() === String(shelfNum)
                    );

                    return (
                      <div
                        key={shelfNum}
                        style={{
                          backgroundColor: "#F8FAFC",
                          borderRadius: "6px",
                          border: "1px solid #E2E8F0",
                          padding: "10px 12px",
                        }}
                      >
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "6px" }}>
                          <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                            <span style={{ fontSize: "0.78rem", fontWeight: 800, color: "#0F766E", backgroundColor: "#ECFDF5", padding: "2px 6px", borderRadius: "4px" }}>
                              Shelf {shelfNum}
                            </span>
                            <span style={{ fontSize: "0.74rem", color: "#64748B" }}>
                              {medicinesOnShelf.length} {medicinesOnShelf.length === 1 ? "medicine" : "medicines"} stored
                            </span>
                          </div>
                        </div>

                        {medicinesOnShelf.length === 0 ? (
                          <div style={{ fontSize: "0.72rem", color: "#94A3B8", fontStyle: "italic", padding: "4px 0" }}>
                            Empty shelf — Ready for stock placement
                          </div>
                        ) : (
                          <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                            {medicinesOnShelf.map((med: any) => (
                              <div
                                key={med.id}
                                style={{
                                  display: "flex",
                                  justifyContent: "space-between",
                                  alignItems: "center",
                                  backgroundColor: "#FFFFFF",
                                  padding: "5px 8px",
                                  borderRadius: "4px",
                                  border: "1px solid #CBD5E1",
                                  fontSize: "0.76rem",
                                  gap: "8px",
                                }}
                              >
                                <div style={{ display: "flex", alignItems: "center", gap: "6px", minWidth: 0, overflow: "hidden" }}>
                                  <Pill size={12} color="#0F766E" style={{ flexShrink: 0 }} />
                                  <strong style={{ color: "#0F172A", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }} title={med.name}>
                                    {med.name}
                                  </strong>
                                  <span style={{ color: "#64748B", fontSize: "0.7rem", flexShrink: 0 }}>
                                    ({med.dosageForm || "10's"})
                                  </span>
                                </div>
                                <div style={{ fontSize: "0.7rem", color: "#475569", fontWeight: 600, flexShrink: 0, whiteSpace: "nowrap" }}>
                                  Box: <span style={{ color: "#0F766E" }}>{med.box || "1"}</span>
                                </div>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          );
        })()}
      </div>

      {/* CREATE / EDIT RACK MODAL */}
      {isFormModalOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 100,
          }}
          onClick={() => setIsFormModalOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "8px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              width: "100%",
              maxWidth: "520px",
              padding: "1.5rem",
              border: "1px solid #CBD5E1",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#0F172A", margin: 0 }}>
                {editingRackId ? "Edit Storage Rack" : "Create Physical Storage Rack"}
              </h3>
              <button
                onClick={() => setIsFormModalOpen(false)}
                style={{ background: "none", border: "none", color: "#64748B", cursor: "pointer" }}
              >
                <X size={18} />
              </button>
            </div>

            {errorMessage && (
              <div
                style={{
                  backgroundColor: "#FEF2F2",
                  border: "1px solid #FCA5A5",
                  color: "#991B1B",
                  padding: "8px 12px",
                  borderRadius: "6px",
                  fontSize: "0.8rem",
                  marginBottom: "10px",
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                }}
              >
                <ShieldAlert size={16} />
                <span>{errorMessage}</span>
              </div>
            )}

            <form onSubmit={handleSaveRack} style={{ display: "flex", flexDirection: "column", gap: "12px", fontSize: "0.82rem" }}>
              <div style={{ display: "grid", gridTemplateColumns: "120px 1fr", gap: "10px" }}>
                <div>
                  <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Rack Code *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. A, B1, FRIDGE"
                    value={formData.code}
                    onChange={(e) => setFormData({ ...formData, code: e.target.value.toUpperCase() })}
                    style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", outline: "none", fontWeight: 700 }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Rack Name *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Antibiotics & Fever Counter"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "10px" }}>
                <div>
                  <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Pharmacy Zone
                  </label>
                  <select
                    value={formData.zone}
                    onChange={(e) => setFormData({ ...formData, zone: e.target.value as any })}
                    style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", backgroundColor: "#FFFFFF" }}
                  >
                    <option value="MAIN_COUNTER">Main Counter Desk</option>
                    <option value="COLD_STORAGE">Cold Storage (Refrigerator)</option>
                    <option value="NARCOTICS_LOCKER">Narcotics Safe (Sch H1/X)</option>
                    <option value="BACK_STORAGE">Back Storage Aisles</option>
                    <option value="OTC_FLOOR">OTC Self-Service Floor</option>
                    <option value="GENERAL">General Shelving</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Storage Type
                  </label>
                  <select
                    value={formData.storageType}
                    onChange={(e) => setFormData({ ...formData, storageType: e.target.value as any })}
                    style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", backgroundColor: "#FFFFFF" }}
                  >
                    <option value="STANDARD">Standard Ambient</option>
                    <option value="REFRIGERATED">Refrigerated (2°C - 8°C)</option>
                    <option value="NARCOTICS_SAFE">Double-Locked Safe</option>
                    <option value="HAZARDOUS">Hazardous / Flammable</option>
                  </select>
                </div>
              </div>

              <div>
                <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Number of Shelves (Levels)
                </label>
                <input
                  type="number"
                  min="1"
                  max="20"
                  required
                  value={formData.totalShelves}
                  onChange={(e) => setFormData({ ...formData, totalShelves: parseInt(e.target.value) || 4 })}
                  style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", outline: "none" }}
                />
              </div>

              <div>
                <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Description / Notes
                </label>
                <textarea
                  rows={2}
                  placeholder="e.g. Oral cephalosporins, cough syrups, eye drops"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", outline: "none", resize: "none" }}
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "8px", marginTop: "1rem" }}>
                <button type="button" onClick={() => setIsFormModalOpen(false)} className="marg-btn-outline">
                  Cancel
                </button>
                <button type="submit" className="marg-btn-teal">
                  {editingRackId ? "Update Rack" : "Create Rack"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ASSIGN MEDICINE MODAL */}
      {isAssignModalOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 100,
          }}
          onClick={() => setIsAssignModalOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "8px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              width: "100%",
              maxWidth: "500px",
              padding: "1.5rem",
              border: "1px solid #CBD5E1",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#0F172A", margin: 0 }}>
                📍 Assign Medicine to Physical Rack
              </h3>
              <button
                onClick={() => setIsAssignModalOpen(false)}
                style={{ background: "none", border: "none", color: "#64748B", cursor: "pointer" }}
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleAssignMedicine} style={{ display: "flex", flexDirection: "column", gap: "12px", fontSize: "0.82rem" }}>
              <div>
                <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Select Medicine *
                </label>
                <select
                  required
                  value={assignForm.medicineId}
                  onChange={(e) => setAssignForm({ ...assignForm, medicineId: e.target.value })}
                  style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", backgroundColor: "#FFFFFF" }}
                >
                  <option value="">-- Choose Medicine --</option>
                  {medicinesList.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name} ({m.genericName || m.dosageForm || "Strip"})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Target Physical Rack *
                </label>
                <select
                  required
                  value={assignForm.rackId}
                  onChange={(e) => {
                    const r = racks.find((rk) => rk.id === e.target.value);
                    setAssignForm({
                      ...assignForm,
                      rackId: e.target.value,
                      rackCode: r?.code || "A",
                    });
                  }}
                  style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", backgroundColor: "#FFFFFF" }}
                >
                  <option value="">-- Choose Rack --</option>
                  {racks.map((r) => (
                    <option key={r.id} value={r.id}>
                      Rack {r.code} - {r.name} ({r.zone})
                    </option>
                  ))}
                </select>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "10px" }}>
                <div>
                  <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Shelf Tier (1 to N) *
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="20"
                    required
                    value={assignForm.shelfNumber}
                    onChange={(e) => setAssignForm({ ...assignForm, shelfNumber: parseInt(e.target.value) || 1 })}
                    style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", outline: "none" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Box / Bin Label
                  </label>
                  <input
                    type="text"
                    placeholder="e.g. 1, 12, FRONT"
                    value={assignForm.boxNumber}
                    onChange={(e) => setAssignForm({ ...assignForm, boxNumber: e.target.value })}
                    style={{ width: "100%", padding: "6px 8px", border: "1px solid #CBD5E1", borderRadius: "4px", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ backgroundColor: "#F0FDFA", border: "1px solid #99F6E4", borderRadius: "6px", padding: "8px 12px", marginTop: "4px" }}>
                <span style={{ fontSize: "0.76rem", color: "#0F766E", fontWeight: 600 }}>
                  💡 Pharmacists will instantly see <strong>Rack {assignForm.rackCode || "A"} • Shelf {assignForm.shelfNumber} • Box {assignForm.boxNumber}</strong> when searching for this medicine during fast counter billing.
                </span>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "8px", marginTop: "1rem" }}>
                <button type="button" onClick={() => setIsAssignModalOpen(false)} className="marg-btn-outline">
                  Cancel
                </button>
                <button type="submit" className="marg-btn-teal">
                  Save Physical Location
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* PHYSICAL AUDIT SHEET MODAL */}
      {auditModalOpen && (
        <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", width: "100%", maxWidth: "750px", padding: "1.5rem", maxHeight: "90vh", overflowY: "auto", boxShadow: "0 10px 25px rgba(0,0,0,0.2)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1rem" }}>
              <div>
                <h3 style={{ margin: 0, fontSize: "1.1rem", fontWeight: 700, color: "#0F172A" }}>
                  Physical Stocktake Audit: Rack {auditRack?.code} ({auditRack?.name})
                </h3>
                <p style={{ margin: "2px 0 0", fontSize: "0.8rem", color: "#64748B" }}>
                  Count physical quantities on shelf. Any discrepancies will automatically generate adjustment audit logs.
                </p>
              </div>
              <button onClick={() => setAuditModalOpen(false)} style={{ border: "none", background: "none", color: "#94A3B8", cursor: "pointer" }}>
                <X size={18} />
              </button>
            </div>

            {!auditSheet ? (
              <div style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                Generating physical checklist...
              </div>
            ) : auditSheet.items?.length === 0 ? (
              <div style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>
                No active drug batches currently allocated to Rack {auditRack?.code}.
              </div>
            ) : (
              <div>
                <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.82rem", textAlign: "left", marginBottom: "1rem" }}>
                  <thead>
                    <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#475569" }}>
                      <th style={{ padding: "6px 10px" }}>Location</th>
                      <th style={{ padding: "6px 10px" }}>Medicine</th>
                      <th style={{ padding: "6px 10px" }}>Batch</th>
                      <th style={{ padding: "6px 10px", textAlign: "right" }}>System Qty</th>
                      <th style={{ padding: "6px 10px", textAlign: "right" }}>Physical Count</th>
                      <th style={{ padding: "6px 10px", textAlign: "right" }}>Variance</th>
                    </tr>
                  </thead>
                  <tbody>
                    {auditSheet.items.map((it: any) => {
                      const count = auditCounts[it.batchId] ?? it.systemStock;
                      const diff = count - it.systemStock;
                      return (
                        <tr key={it.batchId} style={{ borderBottom: "1px solid #F1F5F9" }}>
                          <td style={{ padding: "6px 10px", fontWeight: 600, color: "#0F766E" }}>
                            Shelf {it.shelf} {it.box !== "-" ? `• Box ${it.box}` : ""}
                          </td>
                          <td style={{ padding: "6px 10px", fontWeight: 600, color: "#0F172A" }}>
                            {it.medicineName}
                          </td>
                          <td style={{ padding: "6px 10px" }}>
                            <span style={{ backgroundColor: "#F1F5F9", padding: "1px 5px", borderRadius: "3px", fontSize: "0.75rem" }}>
                              {it.batchNumber}
                            </span>
                          </td>
                          <td style={{ padding: "6px 10px", textAlign: "right", fontWeight: 700 }}>
                            {it.systemStock}
                          </td>
                          <td style={{ padding: "6px 10px", textAlign: "right" }}>
                            <input
                              type="number"
                              min={0}
                              value={count}
                              onChange={(e) => setAuditCounts({ ...auditCounts, [it.batchId]: parseInt(e.target.value) || 0 })}
                              style={{ width: "70px", padding: "4px 6px", textAlign: "right", border: "1px solid #CBD5E1", borderRadius: "4px", fontWeight: 700 }}
                            />
                          </td>
                          <td style={{ padding: "6px 10px", textAlign: "right", fontWeight: 800, color: diff === 0 ? "#64748B" : diff > 0 ? "#059669" : "#DC2626" }}>
                            {diff > 0 ? `+${diff}` : diff}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>

                <div style={{ display: "flex", justifyContent: "flex-end", gap: "8px" }}>
                  <button onClick={() => setAuditModalOpen(false)} style={{ padding: "0.5rem 1rem", border: "1px solid #CBD5E1", borderRadius: "6px", background: "none", cursor: "pointer", fontSize: "0.82rem" }}>
                    Cancel
                  </button>
                  <button
                    onClick={handleSubmitAudit}
                    disabled={isSubmittingAudit}
                    style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1.2rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}
                  >
                    {isSubmittingAudit ? "Submitting Audit..." : "Submit Audit & Sync Stock"}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* UNASSIGNED MEDICINES MODAL */}
      {isUnassignedOpen && (
        <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", width: "100%", maxWidth: "650px", padding: "1.5rem", maxHeight: "85vh", overflowY: "auto", boxShadow: "0 10px 25px rgba(0,0,0,0.2)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <div>
                <h3 style={{ margin: 0, fontSize: "1.1rem", fontWeight: 700, color: "#0F172A" }}>
                  Unallocated Medicines ({unassignedMeds.length})
                </h3>
                <p style={{ margin: "2px 0 0", fontSize: "0.8rem", color: "#64748B" }}>
                  Medicines currently in inventory without assigned physical rack & shelf coordinates.
                </p>
              </div>
              <button onClick={() => setIsUnassignedOpen(false)} style={{ border: "none", background: "none", color: "#94A3B8", cursor: "pointer" }}>
                <X size={18} />
              </button>
            </div>

            {isLoadingUnassigned ? (
              <div style={{ padding: "2rem", textAlign: "center", color: "#64748B" }}>Loading unallocated medicines...</div>
            ) : unassignedMeds.length === 0 ? (
              <div style={{ padding: "2rem", textAlign: "center", color: "#059669", fontWeight: 700 }}>
                ✓ All active medicines are assigned to physical rack locations!
              </div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                {unassignedMeds.map((med: any) => (
                  <div key={med.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 12px", border: "1px solid #E2E8F0", borderRadius: "6px", backgroundColor: "#F8FAF9" }}>
                    <div>
                      <div style={{ fontWeight: 700, color: "#0F172A", fontSize: "0.85rem" }}>{med.name}</div>
                      <div style={{ fontSize: "0.72rem", color: "#64748B" }}>{med.genericName || med.dosageForm || "Medicine"}</div>
                    </div>
                    <button
                      onClick={() => {
                        setIsUnassignedOpen(false);
                        setAssignForm({
                          medicineId: med.id,
                          rackId: racks[0]?.id || "",
                          rackCode: racks[0]?.code || "A",
                          shelfNumber: 1,
                          boxNumber: "1",
                        });
                        setIsAssignModalOpen(true);
                      }}
                      style={{ padding: "4px 10px", backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "4px", fontSize: "0.75rem", fontWeight: 700, cursor: "pointer" }}
                    >
                      Assign Rack
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* CONFIRM MODAL */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        onConfirm={async () => {
          await confirmModal.action();
          setConfirmModal({ ...confirmModal, isOpen: false });
        }}
        onCancel={() => setConfirmModal({ ...confirmModal, isOpen: false })}
      />
    </div>
  );
};
