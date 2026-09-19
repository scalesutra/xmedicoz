import React from "react";

export const TableSkeleton: React.FC<{
  headers?: string[];
  rows?: number;
  cols?: number;
}> = ({
  headers,
  rows = 5,
  cols = 6,
}) => {
  const resolvedHeaders = headers || Array.from({ length: cols }).map((_, i) => i === 0 ? "Description" : i === cols - 1 ? "Actions" : `Field ${i}`);

  return (
    <div style={{ width: "100%", overflow: "hidden" }}>
      <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
        <thead>
          <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
            {resolvedHeaders.map((h, i) => (
              <th key={i} style={{ padding: "0.85rem 1rem" }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {Array.from({ length: rows }).map((_, r) => (
            <tr key={r} style={{ borderBottom: "1px solid #F1F5F9" }}>
              {resolvedHeaders.map((_, c) => (
                <td key={c} style={{ padding: "0.9rem 1rem" }}>
                  <div
                    className="shimmer-loader"
                    style={{
                      height: "16px",
                      width: c === 0 ? "75%" : c === resolvedHeaders.length - 1 ? "40px" : "60%",
                    }}
                  />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export const CardSkeleton: React.FC<{ count?: number }> = ({ count = 4 }) => {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
        gap: "1.25rem",
        marginBottom: "1.75rem",
      }}
    >
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="glass-card"
          style={{
            padding: "1.25rem 1.5rem",
            backgroundColor: "#FFFFFF",
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "0.75rem" }}>
            <div className="shimmer-loader" style={{ height: "12px", width: "45%" }} />
            <div className="shimmer-loader" style={{ height: "28px", width: "28px", borderRadius: "8px" }} />
          </div>
          <div className="shimmer-loader" style={{ height: "28px", width: "60%", marginBottom: "0.5rem" }} />
          <div className="shimmer-loader" style={{ height: "12px", width: "80%" }} />
        </div>
      ))}
    </div>
  );
};
