import React, { useState, useEffect } from "react";
import { ShieldCheck, Search, RefreshCw, Clock, Filter, Eye } from "lucide-react";
import { apiRequest } from "../../api/client.js";

export const AuditLogsPage: React.FC = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 30, total: 0, totalPages: 1 });
  const [search, setSearch] = useState("");
  const [actionFilter, setActionFilter] = useState("ALL");
  const [entityFilter, setEntityFilter] = useState("ALL");
  const [isLoading, setIsLoading] = useState(false);
  const [selectedLog, setSelectedLog] = useState<any | null>(null);

  const fetchLogs = async (page = 1) => {
    setIsLoading(true);
    const params = new URLSearchParams({
      page: page.toString(),
      limit: pagination.limit.toString(),
      action: actionFilter,
      entityType: entityFilter,
      search,
    });
    const res = await apiRequest(`/superadmin/audit-logs?${params.toString()}`);
    if (res.success && res.data) {
      setLogs(res.data.items || []);
      setPagination(res.data.pagination || { page: 1, limit: 30, total: 0, totalPages: 1 });
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchLogs(1);
  }, [actionFilter, entityFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchLogs(1);
  };

  const getActionBadgeClass = (action: string) => {
    if (action.includes("SUSPEND") || action.includes("DELETE")) return "badge-suspended";
    if (action.includes("ACTIVATE") || action.includes("CREATE")) return "badge-active";
    if (action.includes("SUBSCRIPTION") || action.includes("OVERRIDE")) return "badge-trial";
    return "badge-admin";
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1.25rem" }}>
      {/* Header & Controls */}
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
              placeholder="Search by action, user, or entity..."
              className="input-control"
              style={{ paddingLeft: "2.25rem" }}
            />
            <Search size={16} color="#64748B" style={{ position: "absolute", left: "0.75rem", top: "50%", transform: "translateY(-50%)" }} />
          </div>
          <button type="submit" className="btn btn-secondary">
            Filter
          </button>
        </form>

        <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
          <select
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            className="input-control"
            style={{ width: "auto" }}
          >
            <option value="ALL">All Actions</option>
            <option value="SHOP_SUSPENDED">Shop Suspended</option>
            <option value="SHOP_ACTIVATED">Shop Activated</option>
            <option value="SUBSCRIPTION_OVERRIDE">Subscription Override</option>
            <option value="LOGIN">User Login</option>
            <option value="CREATE">Create</option>
            <option value="UPDATE">Update</option>
          </select>

          <button onClick={() => fetchLogs(pagination.page)} className="btn btn-secondary" title="Refresh">
            <RefreshCw size={15} />
          </button>
        </div>
      </div>

      {/* Logs Table */}
      <div className="card" style={{ padding: 0 }}>
        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Action</th>
                <th>Entity Target</th>
                <th>Actor User</th>
                <th>Associated Shop</th>
                <th>Details</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: "center", padding: "3rem", color: "#818CF8" }}>
                    <RefreshCw size={24} className="animate-spin" style={{ animation: "spin 1s linear infinite" }} />
                  </td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: "center", padding: "3rem", color: "#64748B" }}>
                    No audit logs recorded yet for the selected filters.
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id}>
                    <td style={{ whiteSpace: "nowrap", fontSize: "0.75rem", color: "#94A3B8" }}>
                      {new Date(log.createdAt).toLocaleString()}
                    </td>
                    <td>
                      <span className={`badge ${getActionBadgeClass(log.action)}`}>
                        {log.action}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: 600, color: "#F8FAFC" }}>{log.entityType}</div>
                      {log.entityId && (
                        <div style={{ fontFamily: "monospace", fontSize: "0.68rem", color: "#64748B" }}>
                          {log.entityId}
                        </div>
                      )}
                    </td>
                    <td>
                      <div>{log.user?.email || "System Service"}</div>
                      {log.user?.firstName && (
                        <div style={{ fontSize: "0.7rem", color: "#64748B" }}>
                          {log.user.firstName} {log.user.lastName}
                        </div>
                      )}
                    </td>
                    <td>
                      <div style={{ color: log.shop?.name ? "#E2E8F0" : "#64748B" }}>
                        {log.shop?.name || "Global Platform"}
                      </div>
                    </td>
                    <td>
                      <button
                        onClick={() => setSelectedLog(log)}
                        className="btn btn-secondary btn-sm"
                      >
                        <Eye size={12} /> View
                      </button>
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
            {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} audit logs
          </div>

          <div style={{ display: "flex", gap: "0.4rem" }}>
            <button
              disabled={pagination.page <= 1}
              onClick={() => fetchLogs(pagination.page - 1)}
              className="btn btn-secondary btn-sm"
            >
              Previous
            </button>
            <button
              disabled={pagination.page >= pagination.totalPages}
              onClick={() => fetchLogs(pagination.page + 1)}
              className="btn btn-secondary btn-sm"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Log Detail Modal */}
      {selectedLog && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: "1.75rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#F8FAFC" }}>
                Audit Log Payload Details
              </h3>
              <button
                onClick={() => setSelectedLog(null)}
                style={{ background: "transparent", border: "none", color: "#94A3B8", cursor: "pointer" }}
              >
                ✕
              </button>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", fontSize: "0.82rem" }}>
              <div><strong>Action:</strong> <span className="badge badge-trial">{selectedLog.action}</span></div>
              <div><strong>Entity:</strong> {selectedLog.entityType} ({selectedLog.entityId})</div>
              <div><strong>Timestamp:</strong> {new Date(selectedLog.createdAt).toISOString()}</div>
              <div><strong>Actor:</strong> {selectedLog.user?.email || "System Engine"}</div>

              {selectedLog.oldValue && (
                <div>
                  <div style={{ fontWeight: 700, color: "#FDA4AF", marginBottom: "0.25rem" }}>Old Value:</div>
                  <pre style={{ background: "#0B0F17", padding: "0.75rem", borderRadius: "6px", fontSize: "0.72rem", overflowX: "auto" }}>
                    {JSON.stringify(selectedLog.oldValue, null, 2)}
                  </pre>
                </div>
              )}

              {selectedLog.newValue && (
                <div>
                  <div style={{ fontWeight: 700, color: "#34D399", marginBottom: "0.25rem" }}>New Value:</div>
                  <pre style={{ background: "#0B0F17", padding: "0.75rem", borderRadius: "6px", fontSize: "0.72rem", overflowX: "auto" }}>
                    {JSON.stringify(selectedLog.newValue, null, 2)}
                  </pre>
                </div>
              )}
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "1.25rem" }}>
              <button onClick={() => setSelectedLog(null)} className="btn btn-secondary">
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
