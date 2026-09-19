/**
 * Formatting & Currency Utilities
 */

export function formatINR(amount: number | string | null | undefined): string {
  if (amount === null || amount === undefined || isNaN(Number(amount))) {
    return "₹0.00";
  }
  const val = Number(amount);
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 2,
  }).format(val);
}

export function formatDate(dateStr: string | Date | null | undefined): string {
  if (!dateStr) return "N/A";
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return "Invalid Date";
  return d.toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export function formatCompactDate(dateStr: string | Date | null | undefined): string {
  if (!dateStr) return "—";
  if (typeof dateStr === "string" && /^\d{2}\/\d{2}$/.test(dateStr)) return dateStr;
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return "—";
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const y = String(d.getFullYear()).slice(-2);
  return `${m}/${y}`;
}

export function isBatchExpired(dateStr: string | Date | null | undefined): boolean {
  if (!dateStr) return false;

  if (dateStr instanceof Date) {
    if (isNaN(dateStr.getTime())) return false;
    return dateStr <= new Date();
  }

  const str = String(dateStr).trim();

  // 1. Pharmaceutical MM/YY format (e.g. "09/28" -> September 2028)
  const mmYyMatch = str.match(/^(\d{1,2})\/(\d{2})$/);
  if (mmYyMatch) {
    const month = parseInt(mmYyMatch[1], 10);
    const year = 2000 + parseInt(mmYyMatch[2], 10);
    // End of that month (e.g. 30th Sept 2028 23:59:59)
    const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999);
    return endOfMonth <= new Date();
  }

  // 2. Pharmaceutical MM/YYYY format (e.g. "09/2028")
  const mmYyyyMatch = str.match(/^(\d{1,2})\/(\d{4})$/);
  if (mmYyyyMatch) {
    const month = parseInt(mmYyyyMatch[1], 10);
    const year = parseInt(mmYyyyMatch[2], 10);
    const endOfMonth = new Date(year, month, 0, 23, 59, 59, 999);
    return endOfMonth <= new Date();
  }

  // 3. ISO format or standard date string (e.g. "2028-09-28T00:00:00.000Z")
  const d = new Date(str);
  if (isNaN(d.getTime())) return false;
  return d <= new Date();
}

export function formatDateTime(dateStr: string | Date | null | undefined): string {
  if (!dateStr) return "N/A";
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return "Invalid Date";
  return d.toLocaleString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function getExpiryStatus(expiryDateStr: string | Date): {
  status: "ACTIVE" | "NEAR_EXPIRY" | "EXPIRED";
  daysRemaining: number;
  label: string;
  badgeClass: string;
} {
  const expiry = new Date(expiryDateStr);
  const now = new Date();
  const diffMs = expiry.getTime() - now.getTime();
  const days = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  if (days <= 0) {
    return {
      status: "EXPIRED",
      daysRemaining: days,
      label: "Expired",
      badgeClass: "badge-expired",
    };
  } else if (days <= 90) {
    return {
      status: "NEAR_EXPIRY",
      daysRemaining: days,
      label: `Expiring in ${days}d`,
      badgeClass: "badge-near-expiry",
    };
  } else {
    return {
      status: "ACTIVE",
      daysRemaining: days,
      label: "Active",
      badgeClass: "badge-active",
    };
  }
}
