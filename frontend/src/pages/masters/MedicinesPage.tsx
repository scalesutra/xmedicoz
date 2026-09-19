import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { TableSkeleton } from "../../components/common/LoadingSkeleton.js";
import { EmptyState } from "../../components/common/EmptyState.js";
import { ErrorCard } from "../../components/common/ErrorCard.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import { Pill, Search, Plus, X, Filter, Camera, Sparkles, Edit2, Trash2 } from "lucide-react";
import { OcrScanModal } from "../../components/ocr/OcrScanModal.js";

interface MedicineItem {
  id: string;
  name: string;
  genericName: string;
  dosageForm: string;
  strength?: string;
  hsnCode?: string;
  reorderLevel: number;
  prescriptionRequired: boolean;
  rack?: string | null;
  shelf?: string | null;
  box?: string | null;
  rackId?: string | null;
  symptoms?: string | null;
  status: string;
}

export const MedicinesPage: React.FC = () => {
  const [medicines, setMedicines] = useState<MedicineItem[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Modal State
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [isOcrOpen, setIsOcrOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    genericName: "",
    dosageForm: "Tablet",
    strength: "",
    hsnCode: "3004.90",
    reorderLevel: 20,
    prescriptionRequired: false,
    rack: "B",
    shelf: "3",
    box: "12",
    symptoms: "",
  });

  // Edit Medicine State
  const [editingMedicine, setEditingMedicine] = useState<MedicineItem | null>(null);
  const [editFormData, setEditFormData] = useState({
    name: "",
    genericName: "",
    dosageForm: "Tablet",
    strength: "",
    hsnCode: "3004.90",
    reorderLevel: 20,
    prescriptionRequired: false,
    rack: "B",
    shelf: "3",
    box: "12",
    symptoms: "",
  });

  // Confirmation Modal
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ isOpen: false, title: "", message: "", action: async () => {} });

  const fetchMedicines = async () => {
    setIsLoading(true);
    setErrorMessage(null);

    const res = await apiRequest("/masters/medicines", {
      params: { search: searchQuery || undefined, limit: 50 },
    });

    if (res.success && res.data) {
      setMedicines(Array.isArray(res.data) ? res.data : res.data.items || []);
    } else {
      setErrorMessage(res.message || "Failed to retrieve medicines list");
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchMedicines();
  }, [searchQuery]);

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name || !formData.genericName) {
      alert("Please provide both medicine name and generic formulation");
      return;
    }

    setConfirmModal({
      isOpen: true,
      title: "Register New Medicine",
      message: `Confirm registering "${formData.name}" (${formData.genericName}) into the Master Drug Database with reorder threshold of ${formData.reorderLevel} units?`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest("/masters/medicines", {
          method: "POST",
          body: JSON.stringify(formData),
        });
        setIsSubmitting(false);

        if (res.success) {
          setIsCreateOpen(false);
          setFormData({
            name: "",
            genericName: "",
            dosageForm: "Tablet",
            strength: "",
            hsnCode: "3004.90",
            reorderLevel: 20,
            prescriptionRequired: false,
            rack: "B",
            shelf: "3",
            box: "12",
            symptoms: "",
          });
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchMedicines();
        } else {
          alert(res.message || "Failed to create medicine");
        }
      },
    });
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingMedicine) return;

    setConfirmModal({
      isOpen: true,
      title: "Update Medicine Details",
      message: `Confirm updating drug master for "${editFormData.name}"?`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest(`/masters/medicines/${editingMedicine.id}`, {
          method: "PATCH",
          body: JSON.stringify(editFormData),
        });
        setIsSubmitting(false);

        if (res.success) {
          setEditingMedicine(null);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchMedicines();
        } else {
          alert(res.message || "Failed to update medicine");
        }
      },
    });
  };

  const handleDeleteMedicine = (med: MedicineItem) => {
    setConfirmModal({
      isOpen: true,
      title: "Deactivate Medicine Master",
      message: `Are you sure you want to deactivate "${med.name}" (${med.genericName})? Active batches will remain in stock.`,
      action: async () => {
        setIsSubmitting(true);
        const res = await apiRequest(`/masters/medicines/${med.id}`, {
          method: "DELETE",
        });
        setIsSubmitting(false);

        if (res.success) {
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchMedicines();
        } else {
          alert(res.message || "Failed to delete medicine");
        }
      },
    });
  };

  return (
    <div className="animate-scale-in" style={{ padding: "1.25rem 1.5rem" }}>
      {/* Controls Bar */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "0.85rem",
          marginBottom: "1.25rem",
        }}
      >
        <div style={{ position: "relative", flex: "1 1 280px", maxWidth: "420px" }}>
          <div style={{ position: "absolute", left: "0.85rem", top: "50%", transform: "translateY(-50%)", color: "#94A3B8" }}>
            <Search size={16} />
          </div>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search brand name, generic chemical name..."
            style={{
              width: "100%",
              padding: "0.6rem 0.9rem 0.6rem 2.3rem",
              borderRadius: "8px",
              border: "1px solid #CBD5E1",
              fontSize: "0.85rem",
              backgroundColor: "#FFFFFF",
              outline: "none",
            }}
          />
        </div>

        <div style={{ display: "flex", gap: "0.6rem", flexWrap: "wrap" }}>
          <button
            onClick={() => setIsOcrOpen(true)}
            style={{
              padding: "0.55rem 1rem",
              backgroundColor: "#EFF6FF",
              color: "#1D4ED8",
              border: "1px solid #BFDBFE",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.45rem",
              boxShadow: "0 1px 3px rgba(37, 99, 235, 0.1)",
              whiteSpace: "nowrap",
            }}
          >
            <Camera size={16} color="#2563EB" />
            <span>AI Scan Medicine</span>
          </button>

          <button
            onClick={() => setIsCreateOpen(true)}
            style={{
              padding: "0.55rem 1.1rem",
              backgroundColor: "#059669",
              color: "#FFFFFF",
              border: "none",
              borderRadius: "8px",
              fontSize: "0.85rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.45rem",
              boxShadow: "0 2px 5px rgba(5, 150, 105, 0.25)",
              whiteSpace: "nowrap",
            }}
          >
            <Plus size={16} />
            Add Medicine
          </button>
        </div>
      </div>

      {/* Main Table Container */}
      {isLoading ? (
        <div className="glass-card">
          <TableSkeleton rows={6} cols={6} />
        </div>
      ) : errorMessage ? (
        <ErrorCard message={errorMessage} onRetry={fetchMedicines} />
      ) : (
        <div className="glass-card" style={{ overflowX: "auto", borderRadius: "10px", border: "1px solid #E2E8F0" }}>
          <table style={{ width: "100%", minWidth: "960px", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
            <thead>
              <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                <th style={{ padding: "0.85rem 1.25rem" }}>Medicine Name</th>
                <th style={{ padding: "0.85rem 1rem" }}>Generic Formulation</th>
                <th style={{ padding: "0.85rem 1rem" }}>Dosage & Strength</th>
                <th style={{ padding: "0.85rem 1rem" }}>HSN Code</th>
                <th style={{ padding: "0.85rem 1rem" }}>Reorder Level</th>
                <th style={{ padding: "0.85rem 1rem" }}>Prescription</th>
                <th style={{ padding: "0.85rem 1rem" }}>Status</th>
                <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {medicines.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: "center", padding: "3rem 1rem", color: "#64748B" }}>
                    {searchQuery
                      ? `No registered medicines matched "${searchQuery}". Try a different keyword.`
                      : "The drug master database is currently empty. Click + Add Medicine or AI Scan Medicine above to register medicines."}
                  </td>
                </tr>
              ) : (
                medicines.map((med) => (
                <tr key={med.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                  <td style={{ padding: "0.9rem 1.25rem", fontWeight: 700, color: "#0F172A" }}>
                    <div>{med.name}</div>
                    <div style={{ fontSize: "0.72rem", color: "#1D4ED8", fontWeight: 600, marginTop: "2px" }}>
                      📍 {`Rack ${med.rack || "B"} • Shelf ${med.shelf || "3"} • Box ${med.box || "12"}`}
                    </div>
                  </td>
                  <td style={{ padding: "0.9rem 1rem", color: "#475569" }}>
                    {med.genericName}
                  </td>
                  <td style={{ padding: "0.9rem 1rem", color: "#64748B" }}>
                    {med.dosageForm} {med.strength ? `• ${med.strength}` : ""}
                  </td>
                  <td style={{ padding: "0.9rem 1rem", fontFamily: "var(--font-mono)", color: "#64748B" }}>
                    {med.hsnCode || "3004.90"}
                  </td>
                  <td style={{ padding: "0.9rem 1rem", color: "#0F172A", fontWeight: 600 }}>
                    {med.reorderLevel} units
                  </td>
                  <td style={{ padding: "0.9rem 1rem" }}>
                    {med.prescriptionRequired ? (
                      <span style={{ color: "#DC2626", fontWeight: 700, fontSize: "0.75rem", padding: "0.15rem 0.5rem", borderRadius: "4px", backgroundColor: "rgba(239, 68, 68, 0.1)" }}>
                        Prescription Required
                      </span>
                    ) : (
                      <span style={{ color: "#059669", fontSize: "0.75rem" }}>OTC</span>
                    )}
                  </td>
                  <td style={{ padding: "0.9rem 1rem" }}>
                    <span style={{ color: "#059669", fontWeight: 600, fontSize: "0.78rem" }}>● Active</span>
                  </td>
                  <td style={{ padding: "0.9rem 1rem", textAlign: "right" }}>
                    <div style={{ display: "flex", justifyContent: "flex-end", gap: "6px" }}>
                      <button
                        onClick={() => {
                          setEditingMedicine(med);
                          setEditFormData({
                            name: med.name,
                            genericName: med.genericName,
                            dosageForm: med.dosageForm || "Tablet",
                            strength: med.strength || "",
                            hsnCode: med.hsnCode || "3004.90",
                            reorderLevel: med.reorderLevel || 20,
                            prescriptionRequired: med.prescriptionRequired || false,
                            rack: med.rack || "B",
                            shelf: med.shelf || "3",
                            box: med.box || "12",
                            symptoms: med.symptoms || "",
                          });
                        }}
                        title="Edit Medicine"
                        style={{
                          padding: "4px 8px",
                          backgroundColor: "#EFF6FF",
                          border: "1px solid #DBEAFE",
                          color: "#1D4ED8",
                          borderRadius: "4px",
                          fontSize: "0.72rem",
                          fontWeight: 600,
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          gap: "3px",
                        }}
                      >
                        <Edit2 size={13} /> Edit
                      </button>
                      <button
                        onClick={() => handleDeleteMedicine(med)}
                        title="Delete Medicine"
                        style={{
                          padding: "4px 8px",
                          backgroundColor: "#FEF2F2",
                          border: "1px solid #FEE2E2",
                          color: "#DC2626",
                          borderRadius: "4px",
                          fontSize: "0.72rem",
                          fontWeight: 600,
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          gap: "3px",
                        }}
                      >
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </td>
                </tr>
              )))}
            </tbody>
          </table>
        </div>
      )}

      {/* Add Medicine Modal */}
      {isCreateOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 999,
            backgroundColor: "rgba(13, 24, 34, 0.6)",
            backdropFilter: "blur(4px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: "1rem",
          }}
          className="animate-scale-in"
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "14px",
              width: "100%",
              maxWidth: "520px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div
              style={{
                padding: "1.25rem 1.5rem",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                borderBottom: "1px solid #F1F5F9",
              }}
            >
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Register Medicine in Master Catalog
              </h3>
              <button
                onClick={() => setIsCreateOpen(false)}
                style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateSubmit} style={{ padding: "1.5rem" }}>
              {/* OCR Assistant Quick Bar */}
              <div
                style={{
                  backgroundColor: "#F0FDF4",
                  border: "1px solid #BBF7D0",
                  borderRadius: "8px",
                  padding: "0.6rem 0.85rem",
                  marginBottom: "1.1rem",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                  <Sparkles size={16} color="#16A34A" />
                  <span style={{ fontSize: "0.8rem", color: "#166534", fontWeight: 600 }}>
                    Auto-fill with AI Scanner?
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setIsOcrOpen(true)}
                  style={{
                    backgroundColor: "#FFFFFF",
                    border: "1px solid #86EFAC",
                    borderRadius: "6px",
                    padding: "0.25rem 0.65rem",
                    fontSize: "0.75rem",
                    fontWeight: 700,
                    color: "#15803D",
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                    gap: "0.3rem",
                  }}
                >
                  <Camera size={13} />
                  <span>Scan Packaging</span>
                </button>
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Brand / Trade Name *
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g. Paracetamol 650mg"
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Generic Formulation Name *
                </label>
                <input
                  type="text"
                  required
                  value={formData.genericName}
                  onChange={(e) => setFormData({ ...formData, genericName: e.target.value })}
                  placeholder="e.g. Paracetamol / Acetaminophen"
                  style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Dosage Form
                  </label>
                  <select
                    value={formData.dosageForm}
                    onChange={(e) => setFormData({ ...formData, dosageForm: e.target.value })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none", backgroundColor: "#FFFFFF" }}
                  >
                    <option value="Tablet">Tablet</option>
                    <option value="Capsule">Capsule</option>
                    <option value="Syrup">Syrup</option>
                    <option value="Injection">Injection</option>
                    <option value="Ointment">Ointment</option>
                    <option value="Drops">Drops</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Strength
                  </label>
                  <input
                    type="text"
                    value={formData.strength}
                    onChange={(e) => setFormData({ ...formData, strength: e.target.value })}
                    placeholder="e.g. 650mg, 500IU"
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1.25rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    HSN Code
                  </label>
                  <input
                    type="text"
                    value={formData.hsnCode}
                    onChange={(e) => setFormData({ ...formData, hsnCode: e.target.value })}
                    placeholder="e.g. 3004.90"
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Reorder Threshold
                  </label>
                  <input
                    type="number"
                    min="1"
                    value={formData.reorderLevel}
                    onChange={(e) => setFormData({ ...formData, reorderLevel: Number(e.target.value) })}
                    style={{ width: "100%", padding: "0.6rem 0.8rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              {/* Physical Location: Rack, Shelf, Box */}
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "0.75rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Rack
                  </label>
                  <input
                    type="text"
                    value={formData.rack}
                    onChange={(e) => setFormData({ ...formData, rack: e.target.value })}
                    placeholder="e.g. A, B"
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Shelf
                  </label>
                  <input
                    type="text"
                    value={formData.shelf}
                    onChange={(e) => setFormData({ ...formData, shelf: e.target.value })}
                    placeholder="e.g. 1, 2, 3"
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Box
                  </label>
                  <input
                    type="text"
                    value={formData.box}
                    onChange={(e) => setFormData({ ...formData, box: e.target.value })}
                    placeholder="e.g. 01, 12"
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              {/* Symptoms / Clinical Tags */}
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Symptoms / Indications (for Chemist Smart Search)
                </label>
                <input
                  type="text"
                  value={formData.symptoms}
                  onChange={(e) => setFormData({ ...formData, symptoms: e.target.value })}
                  placeholder="e.g. Cold, Sardi, Cough, Fever, Gas, Acidity"
                  style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1.5rem" }}>
                <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem", color: "#334155", cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={formData.prescriptionRequired}
                    onChange={(e) => setFormData({ ...formData, prescriptionRequired: e.target.checked })}
                  />
                  <span>Prescription Required (Schedule H / H1 Drug)</span>
                </label>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: "pointer" }}
                >
                  Save Medicine
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Medicine Modal */}
      {editingMedicine && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 999,
            backgroundColor: "rgba(13, 24, 34, 0.6)",
            backdropFilter: "blur(4px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: "1rem",
          }}
          className="animate-scale-in"
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "14px",
              width: "100%",
              maxWidth: "520px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.1rem 1.25rem", borderBottom: "1px solid #E2E8F0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, margin: 0, color: "#0F172A" }}>Edit Medicine Formulation</h3>
              <button onClick={() => setEditingMedicine(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#64748B" }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleEditSubmit} style={{ padding: "1.25rem", maxHeight: "80vh", overflowY: "auto" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Brand / Trade Name *
                </label>
                <input
                  type="text"
                  required
                  value={editFormData.name}
                  onChange={(e) => setEditFormData({ ...editFormData, name: e.target.value })}
                  style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Generic Salt Formula *
                </label>
                <input
                  type="text"
                  required
                  value={editFormData.genericName}
                  onChange={(e) => setEditFormData({ ...editFormData, genericName: e.target.value })}
                  style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Dosage Form *
                  </label>
                  <select
                    value={editFormData.dosageForm}
                    onChange={(e) => setEditFormData({ ...editFormData, dosageForm: e.target.value })}
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none", backgroundColor: "#FFFFFF" }}
                  >
                    <option value="Tablet">Tablet</option>
                    <option value="Capsule">Capsule</option>
                    <option value="Syrup">Syrup</option>
                    <option value="Injection">Injection</option>
                    <option value="Ointment">Ointment / Gel</option>
                    <option value="Drops">Eye/Ear Drops</option>
                    <option value="Inhaler">Inhaler / Respule</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Strength (e.g. 500mg)
                  </label>
                  <input
                    type="text"
                    value={editFormData.strength}
                    onChange={(e) => setEditFormData({ ...editFormData, strength: e.target.value })}
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    HSN Code
                  </label>
                  <input
                    type="text"
                    value={editFormData.hsnCode}
                    onChange={(e) => setEditFormData({ ...editFormData, hsnCode: e.target.value })}
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Reorder Threshold Level
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={editFormData.reorderLevel}
                    onChange={(e) => setEditFormData({ ...editFormData, reorderLevel: Number(e.target.value) })}
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "0.5rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Rack
                  </label>
                  <input
                    type="text"
                    value={editFormData.rack}
                    onChange={(e) => setEditFormData({ ...editFormData, rack: e.target.value })}
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Shelf
                  </label>
                  <input
                    type="text"
                    value={editFormData.shelf}
                    onChange={(e) => setEditFormData({ ...editFormData, shelf: e.target.value })}
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                    Box
                  </label>
                  <input
                    type="text"
                    value={editFormData.box}
                    onChange={(e) => setEditFormData({ ...editFormData, box: e.target.value })}
                    style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Treated Symptoms / Indications
                </label>
                <input
                  type="text"
                  value={editFormData.symptoms}
                  onChange={(e) => setEditFormData({ ...editFormData, symptoms: e.target.value })}
                  style={{ width: "100%", padding: "0.55rem 0.7rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", outline: "none" }}
                />
              </div>

              <div style={{ marginBottom: "1.5rem" }}>
                <label style={{ display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem", color: "#334155", cursor: "pointer" }}>
                  <input
                    type="checkbox"
                    checked={editFormData.prescriptionRequired}
                    onChange={(e) => setEditFormData({ ...editFormData, prescriptionRequired: e.target.checked })}
                  />
                  <span>Prescription Required (Schedule H / H1 Drug)</span>
                </label>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setEditingMedicine(null)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: "pointer" }}
                >
                  Update Medicine
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Action Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        isLoading={isSubmitting}
        onConfirm={confirmModal.action}
        onCancel={() => setConfirmModal((prev) => ({ ...prev, isOpen: false }))}
      />

      {/* OCR Scanner Modal */}
      <OcrScanModal
        isOpen={isOcrOpen}
        onClose={() => setIsOcrOpen(false)}
        documentType="MEDICINE"
        title="Scan Medicine Packaging / Strip"
        subtitle="Upload or snap photo of medicine packaging, box, or strip foil to auto-extract trade name, formulation, dosage, and strength."
        onApply={(data) => {
          setFormData((prev) => ({
            ...prev,
            name: data.fields.name || prev.name,
            genericName: data.fields.genericName || prev.genericName,
            dosageForm: data.fields.dosageForm || prev.dosageForm,
            strength: data.fields.strength || prev.strength,
            hsnCode: data.fields.hsnCode || prev.hsnCode,
            reorderLevel: data.fields.reorderLevel ? Number(data.fields.reorderLevel) : prev.reorderLevel,
            prescriptionRequired: data.fields.prescriptionRequired ?? prev.prescriptionRequired,
          }));
          setIsCreateOpen(true);
        }}
      />
    </div>
  );
};
