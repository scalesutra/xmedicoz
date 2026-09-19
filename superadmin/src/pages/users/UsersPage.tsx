import React, { useState, useEffect } from "react";
import { Users, Search, ShieldCheck, ShieldAlert, Mail, Phone, Building2, RefreshCw, X, Check } from "lucide-react";
import { apiRequest } from "../../api/client.js";

export const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 25, total: 0, totalPages: 1 });
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("ALL");
  const [isLoading, setIsLoading] = useState(false);

  // Role toggle modal
  const [roleModalUser, setRoleModalUser] = useState<any | null>(null);
  const [isSavingRole, setIsSavingRole] = useState(false);

  const fetchUsers = async (page = 1) => {
    setIsLoading(true);
    const params = new URLSearchParams({
      page: page.toString(),
      limit: pagination.limit.toString(),
      role: roleFilter,
      search,
    });
    const res = await apiRequest(`/superadmin/users?${params.toString()}`);
    if (res.success && res.data) {
      setUsers(res.data.items || []);
      setPagination(res.data.pagination || { page: 1, limit: 25, total: 0, totalPages: 1 });
    }
    setIsLoading(false);
  };

  useEffect(() => {
    fetchUsers(1);
  }, [roleFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchUsers(1);
  };

  const handleToggleAdminRole = async (user: any) => {
    setIsSavingRole(true);
    const hasAdmin = user.roles?.includes("Admin");
    const action = hasAdmin ? "REMOVE" : "ADD";

    const res = await apiRequest(`/superadmin/users/${user.id}/role`, {
      method: "PATCH",
      body: JSON.stringify({ roleName: "Admin", action }),
    });

    setIsSavingRole(false);
    if (res.success) {
      setRoleModalUser(null);
      fetchUsers(pagination.page);
    } else {
      alert(res.error?.message || "Failed to update role");
    }
  };

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
              placeholder="Search users by name, email, phone..."
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
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="input-control"
            style={{ width: "auto" }}
          >
            <option value="ALL">All System Roles</option>
            <option value="Admin">Admin Only</option>
            <option value="Staff">Staff Only</option>
          </select>

          <button onClick={() => fetchUsers(pagination.page)} className="btn btn-secondary" title="Refresh">
            <RefreshCw size={15} />
          </button>
        </div>
      </div>

      {/* Users Table */}
      <div className="card" style={{ padding: 0 }}>
        <div className="data-table-wrapper">
          <table className="data-table">
            <thead>
              <tr>
                <th>User Identity</th>
                <th>Contact</th>
                <th>System Roles</th>
                <th>Pharmacy Affiliations</th>
                <th>Registered On</th>
                <th style={{ textAlign: "right" }}>Privileges</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: "center", padding: "3rem", color: "#818CF8" }}>
                    <RefreshCw size={24} className="animate-spin" style={{ animation: "spin 1s linear infinite" }} />
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: "center", padding: "3rem", color: "#64748B" }}>
                    No users found matching the query.
                  </td>
                </tr>
              ) : (
                users.map((u) => {
                  const isAdmin = u.roles?.includes("Admin");
                  return (
                    <tr key={u.id}>
                      <td>
                        <div style={{ fontWeight: 700, color: "#F8FAFC" }}>
                          {u.firstName} {u.lastName}
                        </div>
                        <div style={{ fontSize: "0.72rem", color: "#64748B", fontFamily: "monospace" }}>
                          {u.id}
                        </div>
                      </td>

                      <td>
                        <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "0.8rem", color: "#CBD5E1" }}>
                          <Mail size={13} color="#64748B" />
                          <span>{u.email}</span>
                        </div>
                        {u.phone && (
                          <div style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "0.72rem", color: "#94A3B8", marginTop: "2px" }}>
                            <Phone size={12} color="#64748B" />
                            <span>{u.phone}</span>
                          </div>
                        )}
                      </td>

                      <td>
                        <div style={{ display: "flex", gap: "4px", flexWrap: "wrap" }}>
                          {u.roles && u.roles.length > 0 ? (
                            u.roles.map((r: string) => (
                              <span
                                key={r}
                                className={`badge ${r === "Admin" ? "badge-admin" : "badge-trial"}`}
                              >
                                {r}
                              </span>
                            ))
                          ) : (
                            <span style={{ fontSize: "0.75rem", color: "#64748B" }}>—</span>
                          )}
                        </div>
                      </td>

                      <td>
                        {u.shops && u.shops.length > 0 ? (
                          <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
                            {u.shops.map((s: any, idx: number) => (
                              <div key={idx} style={{ fontSize: "0.75rem", color: "#E2E8F0" }}>
                                <strong>{s.shopName}</strong>{" "}
                                <span style={{ color: "#34D399", fontSize: "0.7rem" }}>({s.role})</span>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <span style={{ fontSize: "0.75rem", color: "#64748B" }}>No active shop membership</span>
                        )}
                      </td>

                      <td style={{ fontSize: "0.75rem", color: "#94A3B8" }}>
                        {new Date(u.createdAt).toLocaleDateString()}
                      </td>

                      <td style={{ textAlign: "right" }}>
                        <button
                          onClick={() => setRoleModalUser(u)}
                          className={`btn btn-sm ${isAdmin ? "btn-danger" : "btn-secondary"}`}
                          title={isAdmin ? "Revoke Superadmin Rights" : "Promote to Superadmin"}
                        >
                          {isAdmin ? "Revoke Admin" : "Make Admin"}
                        </button>
                      </td>
                    </tr>
                  );
                })
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
            {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} users
          </div>

          <div style={{ display: "flex", gap: "0.4rem" }}>
            <button
              disabled={pagination.page <= 1}
              onClick={() => fetchUsers(pagination.page - 1)}
              className="btn btn-secondary btn-sm"
            >
              Previous
            </button>
            <button
              disabled={pagination.page >= pagination.totalPages}
              onClick={() => fetchUsers(pagination.page + 1)}
              className="btn btn-secondary btn-sm"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Role Confirmation Modal */}
      {roleModalUser && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ padding: "1.75rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1.25rem" }}>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 800, color: "#F8FAFC" }}>
                {roleModalUser.roles?.includes("Admin") ? "Revoke Superadmin Role" : "Grant Superadmin Role"}
              </h3>
              <button
                onClick={() => setRoleModalUser(null)}
                style={{ background: "transparent", border: "none", color: "#94A3B8", cursor: "pointer" }}
              >
                <X size={20} />
              </button>
            </div>

            <p style={{ fontSize: "0.85rem", color: "#CBD5E1", marginBottom: "1.25rem" }}>
              Are you sure you want to{" "}
              <strong>
                {roleModalUser.roles?.includes("Admin") ? "remove Superadmin privileges from" : "grant full Superadmin access to"}
              </strong>{" "}
              {roleModalUser.firstName} {roleModalUser.lastName} ({roleModalUser.email})?
            </p>

            <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
              <button type="button" onClick={() => setRoleModalUser(null)} className="btn btn-secondary">
                Cancel
              </button>
              <button
                type="button"
                disabled={isSavingRole}
                onClick={() => handleToggleAdminRole(roleModalUser)}
                className={`btn ${roleModalUser.roles?.includes("Admin") ? "btn-danger" : "btn-primary"}`}
              >
                {isSavingRole ? "Updating..." : "Confirm Role Mutation"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
