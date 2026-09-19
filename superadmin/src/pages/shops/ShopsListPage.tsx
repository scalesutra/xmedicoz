import React, { useState, useEffect } from "react";
import {
  Search,
  Building2,
  ExternalLink,
  ShieldAlert,
  ShieldCheck,
  CreditCard,
  X,
  Check,
  RefreshCw,
  Phone,
  Mail,
  Calendar,
  Layers,
} from "lucide-react";
import { apiRequest } from "../../api/client.js";

export const ShopsListPage: React.FC = () => {
  const [shops, setShops] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0, totalPages: 1 });
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [planFilter, setPlanFilter] = useState("ALL");
  const [isLoading, setIsLoading] = useState(false);

  // Modals state
  const [selectedShop, setSelectedShop] = useState<any | null>(null);
  const [subModalShop, setSubModalShop] = useState<any | null>(null);
  const [statusModalShop, setStatusModalShop] = useState<any | null>(null);

  // Form states for subscription modal
  const [newPlanCode, setNewPlanCode] = useState("PRO");
  const [extendDays, setExtendDays] = useState(30);
  const [subStatus, setSubStatus] = useState("ACTIVE");
  const [isSavingSub, setIsSavingSub] = useState(false);

  // Form state for status toggle
  const [statusReason, setStatusReason] = useState("");
  const [isSavingStatus, setIsSavingStatus] = useState(false);

  const fetchShops = async (page = 1) => {
    setIsLoading(true);
    const params = new URLSearchParams({
      page: page.toString(),
      limit: pagination.limit.toString(),
      status: statusFilter,
      planCode: planFilter,
      search,
    });
    const res = await apiRequest(`/superadmin/shops?${params.toString()}`);
    if (res.success && res.data) {
      setShops(res.data.items || []);
      setPagination(res.data.pagination || { page: 1, limit: 20, total: 0, totalPages: 1 });
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchShops(1);
  }, [statusFilter, planFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchShops(1);
  };

  const handleSaveSubscription = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!subModalShop) return;
    setIsSavingSub(true);

    const res = await apiRequest(`/superadmin/shops/${subModalShop.id}/subscription`, {
      method: "PATCH",
      body: JSON.stringify({
        planCode: newPlanCode,
        status: subStatus,
        extendDays: Number(extendDays),
      }),
    });

    setIsSavingSub(false);
    if (res.success) {
      setSubModalShop(null);
      fetchShops(pagination.page);
    } else {
      alert(res.error?.message || "Failed to update subscription");
    }
  };

  const handleToggleStatus = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!statusModalShop) return;
    setIsSavingStatus(true);

    const nextStatus = statusModalShop.status === "ACTIVE" ? "SUSPENDED" : "ACTIVE";
    const res = await apiRequest(`/superadmin/shops/${statusModalShop.id}/status`, {
      method: "PATCH",
      body: JSON.stringify({
        status: nextStatus,
        reason: statusReason,
      }),
    });

    setIsSavingStatus(false);
    if (res.success) {
      setStatusModalShop(null);
      setStatusReason("");
      fetchShops(pagination.page);
    } else {
      alert(res.error?.message || "Failed to change store status");
    }
  };

  const storeAppUrl = typeof window !== "undefined"
    ? `http://${window.location.hostname}:5096`
    : "http://localhost:5096";

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1.25rem" }}>
      {/* Header and Controls */}
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "1rem",
        }}
      >
        <form onSubmit={handleSearch} style={{ display: "flex", alignItems: "center", gap: "0.5rem", flex: 1, minWidth: "260px" }}>
          <div style={{ position: "relative", width: "100%", maxWidth: "380px" }}>
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by store name, slug, owner, license..."
              className="input-control"
              style={{ paddingLeft: "2.25rem" }}
            />
            <Search size={16} color="#64748B" style={{ position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)" }} />
          </div>
          <button type="submit" className="btn btn-secondary">
            Filter
          </button>
        </form>

        <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", flexWrap: "wrap" }}>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="input-control"
            style={{ width: "auto" }}
          >
            <option value="ALL">All Statuses</option>
            <option value="ACTIVE">Active Only</option>
            <option value="SUSPENDED">Suspended</option>
          </select>

          <select
            value={planFilter}
            onChange={(e) => setPlanFilter(e.target.value)}
            className="input-control"
            style={{ width: "auto" }}
          >
            <option value="ALL">All Subscription Tiers</option>
            <option value="TRIAL">Free Trial</option>
            <option value="STARTER">Silver Starter</option>
            <option value="PRO">Gold Pro</option>
            <option value="ENTERPRISE">Platinum Enterprise</option>
          </select>

          <button onClick={() => fetchShops(pagination.page)} className="btn btn-secondary" title="Refresh">
            <RefreshCw size={15} />
          </button>
        </div>
      </div>

      {/* Tenants Table */}
      <div className="card" style={{ padding: 0 }}>
        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>Pharmacy Details</th>
                <th>Owner Contact</th>
                <th>Drug License & GSTIN</th>
                <th>Current Plan</th>
                <th>Usage Metrics</th>
                <th>Status</th>
                <th style={{ textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: "center", padding: "3rem", color: "#818CF8" }}>
                    <RefreshCw size={24} className="animate-spin" style={{ animation: "spin 1s linear infinite" }} />
                  </td>
                </tr>
              ) : shops.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: "center", padding: "3rem", color: "#64748B" }}>
                    No medical stores found matching the filters.
                  </td>
                </tr>
              ) : (
                shops.map((s) => (
                  <tr key={s.id}>
                    <td>
                      <div
                        onClick={() => setSelectedShop(s)}
                        style={{ fontWeight: 700, color: "#F8FAFC", cursor: "pointer", display: "flex", alignItems: "center", gap: "6px" }}
                      >
                        <span>{s.name}</span>
                      </div>
                      <div style={{ fontSize: "0.72rem", color: "#64748B" }}>
                        /{s.slug} • {s.city || "India"}
                      </div>
                    </td>

                    <td>
                      <div>{s.ownerName || "Administrator"}</div>
                      <div style={{ fontSize: "0.72rem", color: "#64748B" }}>
                        {s.phone || s.email || "—"}
                      </div>
                    </td>

                    <td>
                      <div style={{ fontFamily: "monospace", fontSize: "0.75rem", color: "#94A3B8" }}>
                        DL: {s.drugLicenseNo || "N/A"}
                      </div>
                      {s.gstin && (
                        <div style={{ fontFamily: "monospace", fontSize: "0.7rem", color: "#64748B" }}>
                          GST: {s.gstin}
                        </div>
                      )}
                    </td>

                    <td>
                      <span className={`badge ${s.subscription?.status === "ACTIVE" ? "badge-active" : "badge-trial"}`}>
                        {s.subscription?.plan?.name || s.subscription?.status || "TRIAL"}
                      </span>
                      {s.subscription?.endDate && (
                        <div style={{ fontSize: "0.68rem", color: "#64748B", marginTop: "2px" }}>
                          Exp: {new Date(s.subscription.endDate).toLocaleDateString()}
                        </div>
                      )}
                    </td>

                    <td>
                      <div style={{ fontSize: "0.75rem", color: "#94A3B8" }}>
                        <div>{s._count?.medicines || 0} drugs in inventory</div>
                        <div>{s._count?.salesInvoices || 0} invoices issued</div>
                        <div>{s._count?.members || 0} staff members</div>
                      </div>
                    </td>

                    <td>
                      <span className={`badge ${s.status === "ACTIVE" ? "badge-active" : "badge-suspended"}`}>
                        {s.status}
                      </span>
                    </td>

                    <td style={{ textAlign: "right" }}>
                      <div style={{ display: "inline-flex", gap: "0.4rem" }}>
                        {/* Open Store App */}
                        <a
                          href={`${storeAppUrl}?shopId=${s.id}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="btn btn-secondary btn-sm"
                          title="Open in Tenant Store ERP App"
                        >
                          <ExternalLink size={13} />
                        </a>

                        {/* Subscription modal */}
                        <button
                          onClick={() => {
                            setSubModalShop(s);
                            setNewPlanCode(s.subscription?.plan?.code || "PRO");
                            setSubStatus(s.subscription?.status || "ACTIVE");
                          }}
                          className="btn btn-secondary btn-sm"
                          title="Manage Subscription"
                        >
                          <CreditCard size={13} />
                        </button>

                        {/* Suspend / Activate */}
                        <button
                          onClick={() => setStatusModalShop(s)}
                          className={`btn btn-sm ${s.status === "ACTIVE" ? "btn-danger" : "btn-primary"}`}
                          title={s.status === "ACTIVE" ? "Suspend Medical Store" : "Activate Medical Store"}
                        >
                          {s.status === "ACTIVE" ? <ShieldAlert size={13} /> : <ShieldCheck size={13} />}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div
          style={{
            padding: "0.75rem 1rem",
            borderTop: "1px solid #1E293B",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            fontSize: "0.78rem",
            color: "#94A3B8",
          }}
        >
          <div>
            Showing {(pagination.page - 1) * pagination.limit + 1} to{" "}
            {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} stores
          </div>

          <div style={{ display: "flex", gap: "0.4rem" }}>
            <button
              disabled={pagination.page <= 1}
              onClick={() => fetchShops(pagination.page - 1)}
              className="btn btn-secondary btn-sm"
            >
              Previous
            </button>
            <button
              disabled={pagination.page >= pagination.totalPages}
              onClick={() => fetchShops(pagination.page + 1)}
              className="btn btn-secondary btn-sm"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Subscription Override Modal */}
      {subModalShop && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: "1.75rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.25rem" }}>
              <div>
                <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#F8FAFC" }}>
                  Manage Store Subscription
                </h3>
                <p style={{ fontSize: "0.75rem", color: "#64748B" }}>
                  {subModalShop.name} ({subModalShop.slug})
                </p>
              </div>
              <button
                onClick={() => setSubModalShop(null)}
                style={{ background: "transparent", border: "none", color: "#94A3B8", cursor: "pointer" }}
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveSubscription} style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
              <div>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                  Subscription Tier
                </label>
                <select
                  value={newPlanCode}
                  onChange={(e) => setNewPlanCode(e.target.value)}
                  className="input-control"
                >
                  <option value="TRIAL">Free Trial (14 Days)</option>
                  <option value="STARTER">Silver Starter (₹599/mo)</option>
                  <option value="PRO">Gold Professional (₹1,299/mo)</option>
                  <option value="ENTERPRISE">Platinum Enterprise (₹2,499/mo)</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                  Subscription Status
                </label>
                <select
                  value={subStatus}
                  onChange={(e) => setSubStatus(e.target.value)}
                  className="input-control"
                >
                  <option value="ACTIVE">ACTIVE (Paid)</option>
                  <option value="TRIAL">TRIAL (Evaluation)</option>
                  <option value="PAST_DUE">PAST_DUE (Grace period)</option>
                  <option value="EXPIRED">EXPIRED (Restricted)</option>
                </select>
              </div>

              <div>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                  Extend Access Duration (+ Days)
                </label>
                <input
                  type="number"
                  min={0}
                  max={365}
                  value={extendDays}
                  onChange={(e) => setExtendDays(parseInt(e.target.value, 10) || 0)}
                  className="input-control"
                />
                <span style={{ fontSize: "0.7rem", color: "#64748B" }}>
                  Adds days to current expiry date ({subModalShop.subscription?.endDate ? new Date(subModalShop.subscription.endDate).toLocaleDateString() : "now"})
                </span>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem", marginTop: "1rem" }}>
                <button type="button" onClick={() => setSubModalShop(null)} className="btn btn-secondary">
                  Cancel
                </button>
                <button type="submit" disabled={isSavingSub} className="btn btn-primary">
                  {isSavingSub ? "Updating..." : "Save Subscription"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Suspend / Activate Modal */}
      {statusModalShop && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: "1.75rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.25rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#F8FAFC" }}>
                {statusModalShop.status === "ACTIVE" ? "Suspend Medical Store" : "Reactivate Medical Store"}
              </h3>
              <button
                onClick={() => setStatusModalShop(null)}
                style={{ background: "transparent", border: "none", color: "#94A3B8", cursor: "pointer" }}
              >
                <X size={20} />
              </button>
            </div>

            <p style={{ fontSize: "0.85rem", color: "#CBD5E1", marginBottom: "1rem" }}>
              Are you sure you want to {statusModalShop.status === "ACTIVE" ? "suspend" : "reactivate"}{" "}
              <strong>{statusModalShop.name}</strong>?
              {statusModalShop.status === "ACTIVE" && (
                <span style={{ display: "block", color: "#FB7185", marginTop: "0.5rem" }}>
                  This will immediately restrict pharmacy staff from logging in and executing sales or stock entries.
                </span>
              )}
            </p>

            <form onSubmit={handleToggleStatus}>
              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "block", fontSize: "0.75rem", fontWeight: 700, color: "#94A3B8", marginBottom: "0.35rem" }}>
                  Audit Reason / Note (Optional)
                </label>
                <input
                  type="text"
                  value={statusReason}
                  onChange={(e) => setStatusReason(e.target.value)}
                  placeholder="e.g. Non-payment, regulatory audit compliance issue, requested by owner"
                  className="input-control"
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button type="button" onClick={() => setStatusModalShop(null)} className="btn btn-secondary">
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSavingStatus}
                  className={`btn ${statusModalShop.status === "ACTIVE" ? "btn-danger" : "btn-primary"}`}
                >
                  {isSavingStatus ? "Processing..." : statusModalShop.status === "ACTIVE" ? "Confirm Suspension" : "Reactivate Store"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Store Detail Modal */}
      {selectedShop && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: "1.75rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.25rem" }}>
              <div>
                <h3 style={{ fontSize: "1.15rem", fontWeight: 800, color: "#F8FAFC" }}>
                  {selectedShop.name}
                </h3>
                <span className={`badge ${selectedShop.status === "ACTIVE" ? "badge-active" : "badge-suspended"}`}>
                  {selectedShop.status}
                </span>
              </div>
              <button
                onClick={() => setSelectedShop(null)}
                style={{ background: "transparent", border: "none", color: "#94A3B8", cursor: "pointer" }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "0.85rem", fontSize: "0.85rem" }}>
              <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "0.5rem", borderBottom: "1px solid #1E293B" }}>
                <span style={{ color: "#64748B" }}>Store Slug:</span>
                <span style={{ color: "#F8FAFC", fontFamily: "monospace" }}>{selectedShop.slug}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "0.5rem", borderBottom: "1px solid #1E293B" }}>
                <span style={{ color: "#64748B" }}>Owner:</span>
                <span style={{ color: "#F8FAFC" }}>{selectedShop.ownerName || "—"}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "0.5rem", borderBottom: "1px solid #1E293B" }}>
                <span style={{ color: "#64748B" }}>Contact Phone:</span>
                <span style={{ color: "#F8FAFC" }}>{selectedShop.phone || "—"}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "0.5rem", borderBottom: "1px solid #1E293B" }}>
                <span style={{ color: "#64748B" }}>Drug License (DL):</span>
                <span style={{ color: "#F8FAFC", fontFamily: "monospace" }}>{selectedShop.drugLicenseNo || "N/A"}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "0.5rem", borderBottom: "1px solid #1E293B" }}>
                <span style={{ color: "#64748B" }}>GSTIN:</span>
                <span style={{ color: "#F8FAFC", fontFamily: "monospace" }}>{selectedShop.gstin || "Unregistered"}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "0.5rem", borderBottom: "1px solid #1E293B" }}>
                <span style={{ color: "#64748B" }}>Location:</span>
                <span style={{ color: "#F8FAFC" }}>{selectedShop.address || selectedShop.city || "—"}, {selectedShop.state || ""} {selectedShop.pincode || ""}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", paddingBottom: "0.5rem", borderBottom: "1px solid #1E293B" }}>
                <span style={{ color: "#64748B" }}>Registered On:</span>
                <span style={{ color: "#F8FAFC" }}>{new Date(selectedShop.createdAt).toLocaleString()}</span>
              </div>
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem", marginTop: "1.5rem" }}>
              <a
                href={`${storeAppUrl}?shopId=${selectedShop.id}`}
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-primary"
                style={{ textDecoration: "none" }}
              >
                <ExternalLink size={15} />
                Open in Store App
              </a>
              <button onClick={() => setSelectedShop(null)} className="btn btn-secondary">
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
