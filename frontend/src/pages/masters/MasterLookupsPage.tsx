import React, { useState, useEffect } from "react";
import {
  Layers,
  Package,
  Receipt,
  Plus,
  Trash2,
  Edit2,
  Save,
  X,
  Search,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
} from "lucide-react";
import { apiRequest } from "../../api/client.js";

interface Category {
  id: string;
  name: string;
  description?: string;
  _count?: { medicines: number };
}

interface Unit {
  id: string;
  name: string;
  abbreviation?: string;
}

interface TaxSlab {
  id: string;
  name: string;
  rate: number;
  cgst?: number;
  sgst?: number;
  igst?: number;
}

export const MasterLookupsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<"categories" | "units" | "taxes">("categories");

  // Categories State
  const [categories, setCategories] = useState<Category[]>([]);
  const [catSearch, setCatSearch] = useState("");
  const [newCat, setNewCat] = useState({ name: "", description: "" });
  const [isAddingCat, setIsAddingCat] = useState(false);

  // Units State
  const [units, setUnits] = useState<Unit[]>([]);
  const [newUnit, setNewUnit] = useState({ name: "", abbreviation: "" });
  const [isAddingUnit, setIsAddingUnit] = useState(false);

  // Taxes State
  const [taxes, setTaxes] = useState<TaxSlab[]>([]);
  const [newTax, setNewTax] = useState({ name: "GST ", rate: 12, cgst: 6, sgst: 6, igst: 12 });
  const [isAddingTax, setIsAddingTax] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    loadTabData();
  }, [activeTab]);

  const showSuccess = (msg: string) => {
    setSuccessMessage(msg);
    setTimeout(() => setSuccessMessage(null), 4000);
  };

  const loadTabData = async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      if (activeTab === "categories") {
        const res = await apiRequest<Category[]>("/masters/categories");
        if (res.success && Array.isArray(res.data)) setCategories(res.data);
      } else if (activeTab === "units") {
        const res = await apiRequest<Unit[]>("/masters/units");
        if (res.success && Array.isArray(res.data)) setUnits(res.data);
      } else if (activeTab === "taxes") {
        const res = await apiRequest<TaxSlab[]>("/masters/taxes");
        if (res.success && Array.isArray(res.data)) setTaxes(res.data);
      }
    } catch (err: any) {
      setErrorMessage(err.message || "Failed to load master records.");
    } finally {
      setIsLoading(false);
    }
  };

  // Category Actions
  const handleCreateCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCat.name.trim()) return;
    try {
      const res = await apiRequest("/masters/categories", {
        method: "POST",
        body: JSON.stringify(newCat),
      });
      if (res.success) {
        showSuccess(`Category "${newCat.name}" created.`);
        setNewCat({ name: "", description: "" });
        setIsAddingCat(false);
        loadTabData();
      } else {
        setErrorMessage(res.message || "Failed to create category");
      }
    } catch (err: any) {
      setErrorMessage(err.message || "Network error");
    }
  };

  const handleDeleteCategory = async (id: string, name: string) => {
    if (!window.confirm(`Delete category "${name}"?`)) return;
    try {
      const res = await apiRequest(`/masters/categories/${id}`, { method: "DELETE" });
      if (res.success) {
        showSuccess(`Category deleted.`);
        loadTabData();
      } else {
        setErrorMessage(res.message || "Failed to delete");
      }
    } catch (err: any) {
      setErrorMessage(err.message);
    }
  };

  // Unit Actions
  const handleCreateUnit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newUnit.name.trim()) return;
    try {
      const res = await apiRequest("/masters/units", {
        method: "POST",
        body: JSON.stringify(newUnit),
      });
      if (res.success) {
        showSuccess(`Packaging Unit "${newUnit.name}" created.`);
        setNewUnit({ name: "", abbreviation: "" });
        setIsAddingUnit(false);
        loadTabData();
      } else {
        setErrorMessage(res.message || "Failed to create unit");
      }
    } catch (err: any) {
      setErrorMessage(err.message);
    }
  };

  // Tax Actions
  const handleCreateTax = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const res = await apiRequest("/masters/taxes", {
        method: "POST",
        body: JSON.stringify(newTax),
      });
      if (res.success) {
        showSuccess(`Tax slab "${newTax.name}" created.`);
        setIsAddingTax(false);
        loadTabData();
      } else {
        setErrorMessage(res.message || "Failed to create tax slab");
      }
    } catch (err: any) {
      setErrorMessage(err.message);
    }
  };

  return (
    <div style={{ padding: "1.5rem", maxWidth: "1200px", margin: "0 auto" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1.5rem" }}>
        <div>
          <h1 style={{ fontSize: "1.35rem", fontWeight: 800, color: "#0F172A", margin: 0, display: "flex", alignItems: "center", gap: "0.5rem" }}>
            <Layers size={22} color="#0F766E" />
            Pharmaceutical Master Catalogs
          </h1>
          <p style={{ margin: "4px 0 0", fontSize: "0.85rem", color: "#64748B" }}>
            Manage therapeutic categories, packaging units, and GST tax slabs.
          </p>
        </div>
      </div>

      {successMessage && (
        <div style={{ backgroundColor: "#ECFDF5", border: "1px solid #A7F3D0", color: "#065F46", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem" }}>
          <CheckCircle2 size={18} />
          {successMessage}
        </div>
      )}

      {errorMessage && (
        <div style={{ backgroundColor: "#FEF2F2", border: "1px solid #FECACA", color: "#991B1B", padding: "0.75rem 1rem", borderRadius: "6px", marginBottom: "1rem", display: "flex", alignItems: "center", gap: "0.5rem", fontSize: "0.85rem" }}>
          <AlertCircle size={18} />
          {errorMessage}
        </div>
      )}

      {/* Navigation Sub-Tabs */}
      <div className="subtabs-scroll" style={{ display: "flex", gap: "0.5rem", borderBottom: "1px solid #E2E8F0", marginBottom: "1.5rem" }}>
        <button
          onClick={() => setActiveTab("categories")}
          style={{
            padding: "0.6rem 1rem",
            border: "none",
            background: "none",
            borderBottom: activeTab === "categories" ? "3px solid #0F766E" : "3px solid transparent",
            color: activeTab === "categories" ? "#0F766E" : "#64748B",
            fontWeight: activeTab === "categories" ? 700 : 500,
            fontSize: "0.88rem",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
          }}
        >
          <Layers size={16} /> Categories ({categories.length})
        </button>

        <button
          onClick={() => setActiveTab("units")}
          style={{
            padding: "0.6rem 1rem",
            border: "none",
            background: "none",
            borderBottom: activeTab === "units" ? "3px solid #0F766E" : "3px solid transparent",
            color: activeTab === "units" ? "#0F766E" : "#64748B",
            fontWeight: activeTab === "units" ? 700 : 500,
            fontSize: "0.88rem",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
          }}
        >
          <Package size={16} /> Packaging Units ({units.length})
        </button>

        <button
          onClick={() => setActiveTab("taxes")}
          style={{
            padding: "0.6rem 1rem",
            border: "none",
            background: "none",
            borderBottom: activeTab === "taxes" ? "3px solid #0F766E" : "3px solid transparent",
            color: activeTab === "taxes" ? "#0F766E" : "#64748B",
            fontWeight: activeTab === "taxes" ? 700 : 500,
            fontSize: "0.88rem",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            gap: "0.4rem",
          }}
        >
          <Receipt size={16} /> GST Tax Slabs ({taxes.length})
        </button>
      </div>

      {/* Categories View */}
      {activeTab === "categories" && (
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <div style={{ display: "flex", alignItems: "center", backgroundColor: "#FFFFFF", border: "1px solid #CBD5E1", borderRadius: "6px", padding: "0.4rem 0.75rem", width: "300px" }}>
              <Search size={15} color="#94A3B8" style={{ marginRight: "0.5rem" }} />
              <input
                type="text"
                placeholder="Search categories..."
                value={catSearch}
                onChange={(e) => setCatSearch(e.target.value)}
                style={{ border: "none", outline: "none", fontSize: "0.82rem", width: "100%" }}
              />
            </div>

            <button
              onClick={() => setIsAddingCat(true)}
              style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", gap: "0.4rem" }}
            >
              <Plus size={16} /> Add Category
            </button>
          </div>

          {isAddingCat && (
            <form onSubmit={handleCreateCategory} style={{ backgroundColor: "#F0FDFA", border: "1px solid #99F6E4", borderRadius: "8px", padding: "1rem", marginBottom: "1rem", display: "flex", gap: "1rem", alignItems: "flex-end" }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>Category Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Antibiotics, Cardiac, OTC, Antihistamines"
                  value={newCat.name}
                  onChange={(e) => setNewCat({ ...newCat, name: e.target.value })}
                  style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                />
              </div>
              <div style={{ flex: 2 }}>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>Description / Therapeutic Class</label>
                <input
                  type="text"
                  placeholder="Optional details"
                  value={newCat.description}
                  onChange={(e) => setNewCat({ ...newCat, description: e.target.value })}
                  style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                />
              </div>
              <div style={{ display: "flex", gap: "0.5rem" }}>
                <button type="submit" style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "4px", padding: "0.5rem 1rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}>Save</button>
                <button type="button" onClick={() => setIsAddingCat(false)} style={{ backgroundColor: "#E2E8F0", color: "#475569", border: "none", borderRadius: "4px", padding: "0.5rem 0.75rem", fontSize: "0.82rem", cursor: "pointer" }}>Cancel</button>
              </div>
            </form>
          )}

          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "8px", border: "1px solid #E2E8F0", overflow: "hidden" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.82rem" }}>
              <thead>
                <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#475569" }}>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Category Name</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Description</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700, textAlign: "right" }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {categories.filter((c) => c.name.toLowerCase().includes(catSearch.toLowerCase())).map((c) => (
                  <tr key={c.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.75rem 1rem", fontWeight: 600, color: "#0F172A" }}>{c.name}</td>
                    <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>{c.description || "—"}</td>
                    <td style={{ padding: "0.75rem 1rem", textAlign: "right" }}>
                      <button onClick={() => handleDeleteCategory(c.id, c.name)} style={{ border: "none", background: "none", color: "#EF4444", cursor: "pointer" }}>
                        <Trash2 size={15} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Units View */}
      {activeTab === "units" && (
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <p style={{ margin: 0, fontSize: "0.85rem", color: "#64748B" }}>
              Standard units of measure for dispensary packing (e.g. Strip, Bottle, Ampoule, Vial, Box, Sachet).
            </p>
            <button
              onClick={() => setIsAddingUnit(true)}
              style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", gap: "0.4rem" }}
            >
              <Plus size={16} /> Add Unit
            </button>
          </div>

          {isAddingUnit && (
            <form onSubmit={handleCreateUnit} style={{ backgroundColor: "#F0FDFA", border: "1px solid #99F6E4", borderRadius: "8px", padding: "1rem", marginBottom: "1rem", display: "flex", gap: "1rem", alignItems: "flex-end" }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>Unit Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Strip, Bottle, Vial, Tube, Box"
                  value={newUnit.name}
                  onChange={(e) => setNewUnit({ ...newUnit, name: e.target.value })}
                  style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                />
              </div>
              <div style={{ flex: 1 }}>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>Abbreviation</label>
                <input
                  type="text"
                  placeholder="e.g. STR, BTL, VIL, BOX"
                  value={newUnit.abbreviation}
                  onChange={(e) => setNewUnit({ ...newUnit, abbreviation: e.target.value.toUpperCase() })}
                  style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                />
              </div>
              <div style={{ display: "flex", gap: "0.5rem" }}>
                <button type="submit" style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "4px", padding: "0.5rem 1rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}>Save</button>
                <button type="button" onClick={() => setIsAddingUnit(false)} style={{ backgroundColor: "#E2E8F0", color: "#475569", border: "none", borderRadius: "4px", padding: "0.5rem 0.75rem", fontSize: "0.82rem", cursor: "pointer" }}>Cancel</button>
              </div>
            </form>
          )}

          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "8px", border: "1px solid #E2E8F0", overflow: "hidden" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.82rem" }}>
              <thead>
                <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#475569" }}>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Unit Name</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Abbreviation</th>
                </tr>
              </thead>
              <tbody>
                {units.map((u) => (
                  <tr key={u.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.75rem 1rem", fontWeight: 600, color: "#0F172A" }}>{u.name}</td>
                    <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>
                      <span style={{ backgroundColor: "#F1F5F9", padding: "2px 6px", borderRadius: "4px", fontWeight: 600 }}>
                        {u.abbreviation || u.name.slice(0, 3).toUpperCase()}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Taxes View */}
      {activeTab === "taxes" && (
        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
            <p style={{ margin: 0, fontSize: "0.85rem", color: "#64748B" }}>
              GST tax rates configured for automatic counter billing split (CGST + SGST or IGST).
            </p>
            <button
              onClick={() => setIsAddingTax(true)}
              style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", gap: "0.4rem" }}
            >
              <Plus size={16} /> Add Tax Slab
            </button>
          </div>

          {isAddingTax && (
            <form onSubmit={handleCreateTax} style={{ backgroundColor: "#F0FDFA", border: "1px solid #99F6E4", borderRadius: "8px", padding: "1rem", marginBottom: "1rem" }}>
              <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr", gap: "0.75rem", marginBottom: "0.75rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>Slab Name *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. GST 18%"
                    value={newTax.name}
                    onChange={(e) => setNewTax({ ...newTax, name: e.target.value })}
                    style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>Total Rate % *</label>
                  <input
                    type="number"
                    required
                    min={0}
                    max={100}
                    value={newTax.rate}
                    onChange={(e) => {
                      const r = parseFloat(e.target.value) || 0;
                      setNewTax({ ...newTax, rate: r, cgst: r / 2, sgst: r / 2, igst: r });
                    }}
                    style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>CGST %</label>
                  <input
                    type="number"
                    value={newTax.cgst}
                    onChange={(e) => setNewTax({ ...newTax, cgst: parseFloat(e.target.value) || 0 })}
                    style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#0F766E", marginBottom: "4px" }}>SGST %</label>
                  <input
                    type="number"
                    value={newTax.sgst}
                    onChange={(e) => setNewTax({ ...newTax, sgst: parseFloat(e.target.value) || 0 })}
                    style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "4px", fontSize: "0.82rem" }}
                  />
                </div>
              </div>
              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.5rem" }}>
                <button type="button" onClick={() => setIsAddingTax(false)} style={{ backgroundColor: "#E2E8F0", color: "#475569", border: "none", borderRadius: "4px", padding: "0.5rem 0.75rem", fontSize: "0.82rem", cursor: "pointer" }}>Cancel</button>
                <button type="submit" style={{ backgroundColor: "#0F766E", color: "#FFFFFF", border: "none", borderRadius: "4px", padding: "0.5rem 1rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}>Save Tax Slab</button>
              </div>
            </form>
          )}

          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "8px", border: "1px solid #E2E8F0", overflow: "hidden" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.82rem" }}>
              <thead>
                <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#475569" }}>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Tax Name</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>Total GST %</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>CGST %</th>
                  <th style={{ padding: "0.75rem 1rem", fontWeight: 700 }}>SGST %</th>
                </tr>
              </thead>
              <tbody>
                {taxes.map((t) => (
                  <tr key={t.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.75rem 1rem", fontWeight: 600, color: "#0F172A" }}>{t.name}</td>
                    <td style={{ padding: "0.75rem 1rem", color: "#0F766E", fontWeight: 700 }}>{t.rate}%</td>
                    <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>{t.cgst || t.rate / 2}%</td>
                    <td style={{ padding: "0.75rem 1rem", color: "#64748B" }}>{t.sgst || t.rate / 2}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};
