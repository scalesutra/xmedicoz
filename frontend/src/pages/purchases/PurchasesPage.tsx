import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { formatINR, formatCompactDate } from "../../utils/formatters.js";
import {
  ShoppingCart,
  Plus,
  ArrowRight,
  ArrowLeft,
  Trash2,
  CheckCircle2,
  Camera,
  Sparkles,
  X,
  Play,
  Search,
  Filter,
  Calendar,
  Eye,
  Edit2,
  Printer,
  MoreVertical,
} from "lucide-react";
import { OcrScanModal } from "../../components/ocr/OcrScanModal.js";

interface SupplierItem {
  id: string;
  name: string;
  gstin?: string;
  phone?: string;
  address?: string;
}

interface MedicineItem {
  id: string;
  name: string;
  genericName?: string;
  mrp?: number;
  purchasePrice?: number;
  purchaseRate?: number;
  dosageForm?: string;
}

interface PurchaseLine {
  id: string;
  medicineId: string;
  medicineName: string;
  packing: string;
  batchNumber: string;
  expiryDate: string;
  quantity: number;
  freeQty: number;
  purchaseRate: number;
  mrp: number;
  discountPercent: number;
  taxRate: number;
  amount: number;
}

interface PurchasesPageProps {
  initialView?: "ENTRY" | "LIST";
}

export const PurchasesPage: React.FC<PurchasesPageProps> = ({ initialView = "LIST" }) => {
  const [viewMode, setViewMode] = useState<"ENTRY" | "LIST">(initialView);

  // Sync with prop when sidebar changes
  useEffect(() => {
    if (initialView) {
      setViewMode(initialView);
    }
  }, [initialView]);

  // Marg Header & Party Meta
  const [partyName, setPartyName] = useState("Cash Account");
  const [selectedSupplier, setSelectedSupplier] = useState<SupplierItem | null>(null);
  const [supplierSearchOpen, setSupplierSearchOpen] = useState(false);
  const [supplierQuery, setSupplierQuery] = useState("");
  const [billNo, setBillNo] = useState("0000008");
  const [billDate, setBillDate] = useState(() => {
    const d = new Date();
    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const year = d.getFullYear();
    return `${day}-${month}-${year}`;
  });
  const [partyBalance, setPartyBalance] = useState("0.00");
  const [partyDue, setPartyDue] = useState("0.00");
  const [partyAddress, setPartyAddress] = useState("Local Wholesale Market");
  const [lastVisitOn, setLastVisitOn] = useState("Today");
  const [previousBill, setPreviousBill] = useState("None");
  const [remarks, setRemarks] = useState("");
  const [isOcrOpen, setIsOcrOpen] = useState(false);
  const [hasDraft, setHasDraft] = useState(false);

  // Data Lists
  const [invoices, setInvoices] = useState<any[]>([]);
  const [suppliers, setSuppliers] = useState<SupplierItem[]>([]);
  const [medicines, setMedicines] = useState<MedicineItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Grid Lines
  const [purchaseLines, setPurchaseLines] = useState<PurchaseLine[]>([
    {
      id: "line-1",
      medicineId: "",
      medicineName: "",
      packing: "10's",
      batchNumber: "BTH-9901",
      expiryDate: "12/28",
      quantity: 10,
      freeQty: 0,
      purchaseRate: 160.0,
      mrp: 240.0,
      discountPercent: 0,
      taxRate: 12,
      amount: 1600.0,
    },
  ]);

  // Item Picker Popup
  const [activeRowIndex, setActiveRowIndex] = useState<number | null>(null);
  const [isItemPickerOpen, setIsItemPickerOpen] = useState(false);
  const [itemSearchQuery, setItemSearchQuery] = useState("");

  // List View Filter & Selection
  const [selectedInvoiceId, setSelectedInvoiceId] = useState<string | null>(null);
  const [listSearchTerm, setListSearchTerm] = useState("");
  const [dateFilter, setDateFilter] = useState("Today");

  // Load Invoices, Suppliers, Medicines & check local draft
  useEffect(() => {
    loadData();
    try {
      if (localStorage.getItem("medicalcrm_purchase_draft")) {
        setHasDraft(true);
      }
    } catch {
      // ignore
    }
  }, []);

  // Supplier Return (Debit Note) State
  const [isDebitNoteOpen, setIsDebitNoteOpen] = useState(false);
  const [selectedBillForReturn, setSelectedBillForReturn] = useState<any | null>(null);
  const [returnReason, setReturnReason] = useState<"EXPIRED" | "DAMAGED" | "EXCESS" | "RECALLED" | "OTHER">("EXPIRED");
  const [returnQty, setReturnQty] = useState(1);
  const [returnRate, setReturnRate] = useState(50);
  const [isSubmittingReturn, setIsSubmittingReturn] = useState(false);

  const handleOpenDebitNote = (inv: any) => {
    setSelectedBillForReturn(inv);
    const firstItem = inv.items?.[0];
    if (firstItem) {
      setReturnQty(1);
      setReturnRate(firstItem.purchaseRate || 50);
    }
    setIsDebitNoteOpen(true);
  };

  const handleSubmitDebitNote = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedBillForReturn) return;
    setIsSubmittingReturn(true);
    try {
      const firstItem = selectedBillForReturn.items?.[0];
      const batchId = firstItem?.batchId || firstItem?.id || selectedBillForReturn.id;
      const res = await apiRequest("/purchases/returns", {
        method: "POST",
        body: JSON.stringify({
          supplierId: selectedBillForReturn.supplierId || selectedBillForReturn.supplier?.id,
          purchaseInvoiceId: selectedBillForReturn.id,
          reason: returnReason,
          items: [
            {
              batchId,
              quantity: Number(returnQty),
              returnRate: Number(returnRate),
            },
          ],
        }),
      });

      if (res.success) {
        setSuccessMessage("Supplier Debit Note recorded and AP balance adjusted!");
        setIsDebitNoteOpen(false);
        loadData();
      } else {
        setErrorMessage(res.message || "Failed to record return.");
      }
    } catch (err: any) {
      setErrorMessage(err.message);
    } finally {
      setIsSubmittingReturn(false);
    }
  };

  // Keyboard Shortcuts Listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // F10 or End to Save
      if (e.key === "F10" || (e.key === "End" && !["INPUT", "TEXTAREA"].includes((e.target as HTMLElement)?.tagName))) {
        e.preventDefault();
        if (viewMode === "ENTRY") {
          handleSaveInvoice(false);
        }
      }
      // F9 to Save & New
      if (e.key === "F9") {
        e.preventDefault();
        if (viewMode === "ENTRY") {
          handleSaveInvoice(true);
        }
      }
      // F2 to Create / Switch to Entry
      if (e.key === "F2") {
        e.preventDefault();
        setViewMode("ENTRY");
      }
      // Esc to Close / Switch to List
      if (e.key === "Escape") {
        if (isItemPickerOpen) {
          setIsItemPickerOpen(false);
        } else if (supplierSearchOpen) {
          setSupplierSearchOpen(false);
        } else if (viewMode === "ENTRY") {
          setViewMode("LIST");
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [viewMode, isItemPickerOpen, supplierSearchOpen, purchaseLines, selectedSupplier, partyName]);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const [invRes, suppRes, medRes] = await Promise.all([
        apiRequest("/purchases/invoices"),
        apiRequest("/masters/suppliers"),
        apiRequest("/masters/medicines"),
      ]);

      const invList = Array.isArray(invRes.data) ? invRes.data : invRes.data?.items || [];
      setInvoices(invList);
      if (suppRes.success) setSuppliers(Array.isArray(suppRes.data) ? suppRes.data : suppRes.data?.items || []);
      if (medRes.success) setMedicines(Array.isArray(medRes.data) ? medRes.data : medRes.data?.items || []);
    } catch (e: any) {
      console.error("Error fetching purchase data:", e);
    } finally {
      setIsLoading(false);
    }
  };

  // Add / Remove Row
  const handleAddRow = () => {
    setPurchaseLines((prev) => [
      ...prev,
      {
        id: `line-${Date.now()}`,
        medicineId: "",
        medicineName: "",
        packing: "10's",
        batchNumber: `BTH-${Math.floor(1000 + Math.random() * 9000)}`,
        expiryDate: "12/28",
        quantity: 10,
        freeQty: 0,
        purchaseRate: 0,
        mrp: 0,
        discountPercent: 0,
        taxRate: 12,
        amount: 0,
      },
    ]);
  };

  const handleRemoveRow = (idx: number) => {
    if (purchaseLines.length === 1) return;
    setPurchaseLines((prev) => prev.filter((_, i) => i !== idx));
  };

  const handleRowChange = (index: number, field: keyof PurchaseLine, value: any) => {
    let formattedVal = value;
    if (field === "expiryDate" && typeof value === "string") {
      const clean = value.replace(/[^\d]/g, "");
      if (clean.length === 4) {
        formattedVal = `${clean.slice(0, 2)}/${clean.slice(2)}`;
      } else if (clean.length === 6) {
        formattedVal = `${clean.slice(0, 2)}/${clean.slice(2, 6)}`;
      }
    }

    setPurchaseLines((prev) => {
      const updated = [...prev];
      const row = { ...updated[index], [field]: formattedVal };
      const qty = Number(row.quantity) || 0;
      const rate = Number(row.purchaseRate) || 0;
      const disc = Number(row.discountPercent) || 0;
      const gross = qty * rate;
      const discountVal = (gross * disc) / 100;
      row.amount = Math.max(0, gross - discountVal);
      updated[index] = row;
      return updated;
    });
  };

  const handleSelectMedicine = (med: MedicineItem) => {
    if (activeRowIndex === null) return;
    setPurchaseLines((prev) => {
      const updated = [...prev];
      const rate = med.purchasePrice || med.purchaseRate || (med.mrp ? med.mrp * 0.7 : 50);
      const mrp = med.mrp || (rate * 1.35);
      const qty = updated[activeRowIndex].quantity || 10;
      const disc = updated[activeRowIndex].discountPercent || 0;
      const gross = qty * rate;
      const discountVal = (gross * disc) / 100;

      updated[activeRowIndex] = {
        ...updated[activeRowIndex],
        medicineId: med.id,
        medicineName: med.name,
        packing: med.dosageForm || "10's",
        purchaseRate: rate,
        mrp: mrp,
        amount: Math.max(0, gross - discountVal),
      };
      return updated;
    });

    setIsItemPickerOpen(false);
    setActiveRowIndex(null);
  };

  // Calculations
  const subtotal = purchaseLines.reduce((acc, row) => acc + (Number(row.quantity || 0) * Number(row.purchaseRate || 0)), 0);
  const totalDiscount = purchaseLines.reduce((acc, row) => {
    const gross = Number(row.quantity || 0) * Number(row.purchaseRate || 0);
    return acc + (gross * (Number(row.discountPercent || 0) / 100));
  }, 0);
  const taxableAmount = Math.max(0, subtotal - totalDiscount);
  const cgstAmount = Number((taxableAmount * 0.06).toFixed(2));
  const sgstAmount = Number((taxableAmount * 0.06).toFixed(2));
  const invoiceValue = Number((taxableAmount + cgstAmount + sgstAmount).toFixed(2));

  const formatExpiryForBackend = (exp: string): string => {
    if (!exp) return "2028-12-01";
    const trimmed = exp.trim();
    if (/^\d{4}-\d{2}-\d{2}/.test(trimmed)) return trimmed.slice(0, 10);
    if (/^\d{2}\/\d{2}$/.test(trimmed)) {
      const [mm, yy] = trimmed.split("/");
      return `20${yy}-${mm}-01`;
    }
    if (/^\d{2}\/\d{4}$/.test(trimmed)) {
      const [mm, yyyy] = trimmed.split("/");
      return `${yyyy}-${mm}-01`;
    }
    if (/^\d{4}-\d{2}$/.test(trimmed)) {
      return `${trimmed}-01`;
    }
    return "2028-12-01";
  };

  // OCR Auto-Fill Handler
  const handleOcrApply = (data: { fields: Record<string, any>; items?: any[]; rawText?: string }) => {
    const fields = data.fields || {};
    const scannedItems = data.items || (fields as any).items || [];

    if (fields.supplier_name || fields.supplierName) {
      const sName = String(fields.supplier_name || fields.supplierName);
      setPartyName(sName);
      const match = suppliers.find((s) => s.name.toLowerCase().includes(sName.toLowerCase()));
      if (match) {
        setSelectedSupplier(match);
        setPartyAddress(match.address || match.phone || "Registered Stockist");
      }
    }

    if (fields.invoice_number || fields.invoiceNumber) {
      setBillNo(String(fields.invoice_number || fields.invoiceNumber));
    }

    if (fields.invoice_date || fields.invoiceDate) {
      setBillDate(String(fields.invoice_date || fields.invoiceDate));
    }

    if (Array.isArray(scannedItems) && scannedItems.length > 0) {
      const newLines: PurchaseLine[] = scannedItems.map((it: any, idx: number) => {
        const qty = Math.max(1, Number(it.quantity || it.qty || 1));
        const rate = Number(it.rate || it.purchaseRate || it.purchase_rate || 0);
        const mrp = Number(it.mrp || (rate > 0 ? Number((rate * 1.3).toFixed(2)) : 0));
        const disc = Number(it.discountPercent || it.discount_percent || it.disc || 0);
        const tax = Number(it.taxRate || it.tax_percent || it.gstRate || 12);
        const gross = qty * rate;
        const discAmt = (gross * disc) / 100;
        const amt = Number(it.amount || Math.max(0, gross - discAmt).toFixed(2));

        const medName = String(it.medicineName || it.medicine_name || it.description || it.item || `Medicine ${idx + 1}`);
        const matched = medicines.find((m) => m.name.toLowerCase().includes(medName.toLowerCase()));

        return {
          id: `line-ocr-${idx}-${Date.now()}`,
          medicineId: matched?.id || "",
          medicineName: matched?.name || medName,
          packing: it.packing || matched?.dosageForm || "10's",
          batchNumber: it.batchNumber || it.batch_number || it.batch || `BTH-${Math.floor(1000 + Math.random() * 9000)}`,
          expiryDate: it.expiryDate || it.expiry_date || it.exp || "12/28",
          quantity: qty,
          freeQty: Number(it.freeQty || it.free_qty || 0),
          purchaseRate: rate,
          mrp: mrp,
          discountPercent: disc,
          taxRate: tax,
          amount: amt,
        };
      });

      setPurchaseLines(newLines);
      setSuccessMessage(`AI OCR successfully extracted ${newLines.length} medicines, batches, expiries & rates into inward form!`);
    } else {
      setSuccessMessage("Scanned invoice metadata updated. You can add medicines below.");
    }

    setViewMode("ENTRY");
  };

  // Save Purchase Invoice
  const handleSaveInvoice = async (isSaveAndNew: boolean) => {
    const validLines = purchaseLines.filter((l) => (l.medicineId || l.medicineName?.trim()) && Number(l.quantity) > 0);
    if (validLines.length === 0) {
      setErrorMessage("Please select or scan at least one medicine item with valid quantity and batch.");
      return;
    }

    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      const targetSupplierId = selectedSupplier?.id;
      const payload: any = {
        invoiceNumber: billNo || `PUR-${Date.now()}`,
        invoiceDate: new Date().toISOString(),
        paymentTermsDays: 30,
        items: validLines.map((l) => ({
          medicineId: l.medicineId || undefined,
          medicineName: l.medicineName,
          batchNumber: l.batchNumber || "BTH-NEW",
          expiryDate: formatExpiryForBackend(l.expiryDate),
          quantity: Number(l.quantity),
          freeQuantity: Number(l.freeQty || 0),
          purchaseRate: Number(l.purchaseRate || 10),
          mrp: Number(l.mrp || Number(l.purchaseRate || 10) * 1.3),
          sellingPrice: Number(l.mrp || Number(l.purchaseRate || 10) * 1.25),
          discountPercent: Number(l.discountPercent || 0),
          taxRate: Number(l.taxRate || 12),
        })),
        notes: remarks,
      };

      if (targetSupplierId) {
        payload.supplierId = targetSupplierId;
      } else {
        payload.supplier = {
          name: partyName || "Cash Account",
          address: partyAddress || undefined,
        };
      }

      const res = await apiRequest("/purchases/invoices", {
        method: "POST",
        body: JSON.stringify(payload),
      });

      if (res.success) {
        setSuccessMessage(`Purchase Bill ${billNo} saved successfully & stock inward completed!`);
        localStorage.removeItem("medicalcrm_purchase_draft");
        setHasDraft(false);
        loadData();

        if (isSaveAndNew) {
          setPurchaseLines([
            {
              id: `line-${Date.now()}`,
              medicineId: "",
              medicineName: "",
              packing: "10's",
              batchNumber: `BTH-${Math.floor(1000 + Math.random() * 9000)}`,
              expiryDate: "12/28",
              quantity: 10,
              freeQty: 0,
              purchaseRate: 0,
              mrp: 0,
              discountPercent: 0,
              taxRate: 12,
              amount: 0,
            },
          ]);
          setRemarks("");
        } else {
          setViewMode("LIST");
        }
      } else {
        setErrorMessage(res.message || "Failed to save purchase invoice.");
      }
    } catch (e: any) {
      setErrorMessage(e.message || "Network error while saving purchase invoice.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Real Invoices from Backend Database (Zero fake mock rows)
  const displayInvoices = invoices.map((inv, idx) => ({
    id: inv.id || `inv-${idx}`,
    invoiceNumber: inv.invoiceNumber || `${idx + 1000}`,
    invoiceDate: formatCompactDate(inv.invoiceDate || inv.createdAt || new Date()),
    party: inv.supplier?.name || "Cash Account",
    station: inv.supplier?.address || "",
    status: inv.paymentStatus || (Number(inv.paidAmount || 0) >= Number(inv.totalAmount || 0) ? "Paid" : "Due"),
    amount: Number(inv.totalAmount || inv.paidAmount || 0),
  }));

  const filteredDisplayInvoices = displayInvoices.filter((inv) => {
    const q = listSearchTerm.toLowerCase();
    return inv.invoiceNumber.toLowerCase().includes(q) || inv.party.toLowerCase().includes(q);
  });

  return (
    <div style={{ display: "flex", flexDirection: "column", flex: 1, minHeight: "100%", backgroundColor: "#FFFFFF" }}>
      {/* Toast Messages */}
      {errorMessage && (
        <div
          style={{
            backgroundColor: "#FEF2F2",
            borderLeft: "4px solid #EF4444",
            padding: "8px 16px",
            color: "#991B1B",
            fontSize: "0.82rem",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <span>{errorMessage}</span>
          <button onClick={() => setErrorMessage(null)} style={{ background: "none", border: "none", color: "#991B1B", cursor: "pointer" }}>✕</button>
        </div>
      )}
      {successMessage && (
        <div
          style={{
            backgroundColor: "#ECFDF5",
            borderLeft: "4px solid #10B981",
            padding: "8px 16px",
            color: "#065F46",
            fontSize: "0.82rem",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <span>{successMessage}</span>
          <button onClick={() => setSuccessMessage(null)} style={{ background: "none", border: "none", color: "#065F46", cursor: "pointer" }}>✕</button>
        </div>
      )}

      {/* ========================================================= */}
      {/* VIEW 1: PURCHASE BILL ENTRY SCREEN (SCREEN 2)             */}
      {/* ========================================================= */}
      {viewMode === "ENTRY" && (
        <div style={{ display: "flex", flexDirection: "column", flex: 1, minHeight: "100%" }}>
          {/* Top Info & Party Bar */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "6px 14px",
              backgroundColor: "#FFFFFF",
              borderBottom: "1px solid #CBD5E1",
              fontSize: "0.82rem",
              gap: "10px",
              flexWrap: "wrap",
            }}
          >
            {/* Left Controls: >> Toggle, OCR Button, Balance & Due */}
            <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
              <button
                onClick={() => setViewMode("LIST")}
                title="Back to Purchase Bill List (Esc)"
                style={{
                  background: "transparent",
                  border: "none",
                  fontWeight: 900,
                  fontSize: "1rem",
                  color: "#334155",
                  cursor: "pointer",
                  padding: "0 4px",
                }}
              >
                &gt;&gt;
              </button>

              <button
                onClick={() => setIsOcrOpen(true)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "5px",
                  backgroundColor: "#059669",
                  color: "#FFFFFF",
                  border: "none",
                  borderRadius: "4px",
                  padding: "4px 8px",
                  fontSize: "0.78rem",
                  fontWeight: 700,
                  cursor: "pointer",
                  boxShadow: "0 1px 2px rgba(0,0,0,0.1)",
                }}
                title="Scan stockist invoice with AI OCR"
              >
                <Camera size={13} />
                <span>📷 Scan Bill (AI)</span>
              </button>

              <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                <span style={{ color: "#0F172A", fontWeight: 700 }}>Balance :</span>
                <span style={{ color: "#0F766E", fontWeight: 800 }}>₹ {partyBalance}</span>
              </div>

              <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                <span style={{ color: "#0F172A", fontWeight: 700 }}>Due Amount :</span>
                <span style={{ color: "#EF4444", fontWeight: 800 }}>₹ {partyDue}</span>
              </div>
            </div>

            {/* Center Controls: Party Input, Bill No, Date */}
            <div style={{ display: "flex", alignItems: "center", gap: "12px", flex: 1, maxWidth: "680px" }}>
              {/* Supplier Autocomplete Input */}
              <div style={{ position: "relative", flex: 1 }}>
                <input
                  type="text"
                  value={partyName}
                  onChange={(e) => {
                    setPartyName(e.target.value);
                    setSupplierSearchOpen(true);
                  }}
                  onFocus={() => setSupplierSearchOpen(true)}
                  placeholder="Cash Account / Search Supplier"
                  style={{
                    width: "100%",
                    border: "1px solid #CBD5E1",
                    borderRadius: "4px",
                    padding: "4px 8px",
                    fontSize: "0.82rem",
                    outline: "none",
                  }}
                />
                {supplierSearchOpen && (
                  <div
                    style={{
                      position: "absolute",
                      top: "100%",
                      left: 0,
                      width: "100%",
                      backgroundColor: "#FFFFFF",
                      boxShadow: "0 8px 16px rgba(0,0,0,0.15)",
                      borderRadius: "4px",
                      border: "1px solid #CBD5E1",
                      zIndex: 60,
                      maxHeight: "180px",
                      overflowY: "auto",
                    }}
                  >
                    <div
                      onClick={() => {
                        setPartyName("Cash Account");
                        setSelectedSupplier(null);
                        setPartyAddress("Local Wholesale Market");
                        setPartyBalance("0.00");
                        setPartyDue("0.00");
                        setPreviousBill("None");
                        setLastVisitOn("Today");
                        setSupplierSearchOpen(false);
                      }}
                      style={{
                        padding: "6px 10px",
                        cursor: "pointer",
                        borderBottom: "1px solid #F1F5F9",
                        fontWeight: 600,
                        color: "#0F766E",
                      }}
                    >
                      Cash Account (Spot Purchase)
                    </div>
                    {suppliers.map((s) => (
                      <div
                        key={s.id}
                        onClick={() => {
                          setSelectedSupplier(s);
                          setPartyName(s.name);
                          setPartyAddress(s.address || s.phone || "Wholesale Distributor");
                          setSupplierSearchOpen(false);
                          const sInvoices = invoices.filter(
                            (inv) => inv.supplierId === s.id || inv.supplier?.name === s.name
                          );
                          if (sInvoices.length > 0) {
                            const due = sInvoices.reduce(
                              (sum, inv) =>
                                sum + Math.max(0, Number(inv.totalAmount || 0) - Number(inv.paidAmount || 0)),
                              0
                            );
                            setPartyDue(due > 0 ? `${due.toFixed(2)}` : "0.00");
                            setPartyBalance(due > 0 ? `${due.toFixed(2)} Cr` : "0.00");
                            const last = sInvoices[0];
                            setPreviousBill(
                              `${formatCompactDate(last.invoiceDate || last.createdAt)} #${last.invoiceNumber}`
                            );
                            setLastVisitOn(formatCompactDate(last.invoiceDate || last.createdAt));
                          } else {
                            setPartyBalance("0.00");
                            setPartyDue("0.00");
                            setPreviousBill("None");
                            setLastVisitOn("Today");
                          }
                        }}
                        style={{
                          padding: "6px 10px",
                          cursor: "pointer",
                          borderBottom: "1px solid #F1F5F9",
                          display: "flex",
                          justifyContent: "space-between",
                          fontSize: "0.8rem",
                        }}
                      >
                        <span style={{ fontWeight: 600 }}>{s.name}</span>
                        <span style={{ color: "#64748B" }}>{s.gstin || s.phone || ""}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Bill No Input */}
              <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                <span style={{ color: "#334155", fontWeight: 600 }}>Bill No.</span>
                <input
                  type="text"
                  value={billNo}
                  onChange={(e) => setBillNo(e.target.value)}
                  style={{
                    width: "100px",
                    border: "1px solid #CBD5E1",
                    borderRadius: "4px",
                    padding: "4px 6px",
                    fontSize: "0.82rem",
                    textAlign: "center",
                    outline: "none",
                  }}
                />
              </div>

              {/* Date Input */}
              <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                <span style={{ color: "#334155", fontWeight: 600 }}>Date</span>
                <div style={{ position: "relative", display: "flex", alignItems: "center" }}>
                  <input
                    type="text"
                    value={billDate}
                    onChange={(e) => setBillDate(e.target.value)}
                    style={{
                      width: "95px",
                      border: "1px solid #CBD5E1",
                      borderRadius: "4px",
                      padding: "4px 6px",
                      fontSize: "0.82rem",
                      textAlign: "center",
                      outline: "none",
                    }}
                  />
                  <Calendar size={14} color="#64748B" style={{ marginLeft: "-22px", pointerEvents: "none" }} />
                </div>
              </div>
            </div>

            {/* Right Quick Summary Panel */}
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                borderLeft: "1px solid #CBD5E1",
                paddingLeft: "12px",
                fontSize: "0.74rem",
                color: "#475569",
                minWidth: "160px",
              }}
            >
              <div style={{ fontWeight: 700, color: "#1E293B" }}>Address</div>
              <div style={{ color: "#64748B", textOverflow: "ellipsis", overflow: "hidden", whiteSpace: "nowrap" }}>
                {partyAddress}
              </div>
              <div style={{ marginTop: "2px", fontWeight: 600 }}>
                Last Visit On: <span style={{ color: "#0F172A" }}>{lastVisitOn}</span>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: "4px", marginTop: "1px" }}>
                <span>Previous Bills:</span>
                <span style={{ color: "#0F766E", fontWeight: 600 }}>{previousBill}</span>
                <Eye size={12} color="#0F766E" style={{ cursor: "pointer" }} />
              </div>
            </div>
          </div>

          {/* MARG SIGNATURE INWARD BILLING GRID */}
          <div style={{ flex: 1, overflowY: "auto", borderBottom: "1px solid #CBD5E1", minHeight: "260px" }}>
            <table className="marg-grid-table">
              <thead>
                <tr>
                  <th style={{ width: "28%" }}>Particulars / Medicine</th>
                  <th style={{ width: "8%" }}>Packing</th>
                  <th style={{ width: "10%" }}>Batch</th>
                  <th style={{ width: "9%" }}>Exp. Date</th>
                  <th style={{ width: "7%", textAlign: "right" }}>Qty</th>
                  <th style={{ width: "6%", textAlign: "right" }}>Free</th>
                  <th style={{ width: "10%", textAlign: "right" }}>Cost Rate</th>
                  <th style={{ width: "8%", textAlign: "right" }}>Disc 1.%</th>
                  <th style={{ width: "10%", textAlign: "right" }}>₹ Amount</th>
                  <th style={{ width: "4%", textAlign: "center" }}>Acti...</th>
                </tr>
              </thead>
              <tbody>
                {purchaseLines.map((row, idx) => (
                  <tr key={row.id}>
                    {/* Item / Medicine Name */}
                    <td>
                      <input
                        type="text"
                        className="marg-grid-input"
                        placeholder="Select Medicine Inward..."
                        value={row.medicineName}
                        onFocus={() => {
                          setActiveRowIndex(idx);
                          setIsItemPickerOpen(true);
                          setItemSearchQuery(row.medicineName);
                        }}
                        onChange={(e) => {
                          handleRowChange(idx, "medicineName", e.target.value);
                          setItemSearchQuery(e.target.value);
                          setIsItemPickerOpen(true);
                        }}
                      />
                    </td>

                    {/* Packing */}
                    <td>
                      <input
                        type="text"
                        className="marg-grid-input"
                        value={row.packing}
                        onChange={(e) => handleRowChange(idx, "packing", e.target.value)}
                      />
                    </td>

                    {/* Batch */}
                    <td>
                      <input
                        type="text"
                        className="marg-grid-input"
                        value={row.batchNumber}
                        placeholder="Batch"
                        onChange={(e) => handleRowChange(idx, "batchNumber", e.target.value)}
                      />
                    </td>

                    {/* Exp Date */}
                    <td>
                      <input
                        type="text"
                        className="marg-grid-input"
                        value={row.expiryDate}
                        placeholder="MM/YY"
                        onChange={(e) => handleRowChange(idx, "expiryDate", e.target.value)}
                      />
                    </td>

                    {/* Qty */}
                    <td>
                      <input
                        type="number"
                        min="1"
                        className="marg-grid-input tabular-nums"
                        style={{ textAlign: "right", fontWeight: 700 }}
                        value={row.quantity}
                        onChange={(e) => handleRowChange(idx, "quantity", Number(e.target.value))}
                      />
                    </td>

                    {/* Free */}
                    <td>
                      <input
                        type="number"
                        min="0"
                        className="marg-grid-input tabular-nums"
                        style={{ textAlign: "right" }}
                        value={row.freeQty}
                        onChange={(e) => handleRowChange(idx, "freeQty", Number(e.target.value))}
                      />
                    </td>

                    {/* Cost Rate */}
                    <td>
                      <input
                        type="number"
                        step="0.01"
                        className="marg-grid-input tabular-nums"
                        style={{ textAlign: "right", fontWeight: 600 }}
                        value={row.purchaseRate}
                        onChange={(e) => handleRowChange(idx, "purchaseRate", Number(e.target.value))}
                      />
                    </td>

                    {/* Disc % */}
                    <td>
                      <input
                        type="number"
                        step="0.1"
                        className="marg-grid-input tabular-nums"
                        style={{ textAlign: "right" }}
                        value={row.discountPercent}
                        onChange={(e) => handleRowChange(idx, "discountPercent", Number(e.target.value))}
                      />
                    </td>

                    {/* Amount */}
                    <td style={{ textAlign: "right", fontWeight: 700, color: "#0F172A" }}>
                      ₹ {row.amount.toFixed(2)}
                    </td>

                    {/* Action */}
                    <td style={{ textAlign: "center" }}>
                      <button
                        onClick={() => handleRemoveRow(idx)}
                        style={{
                          border: "none",
                          background: "transparent",
                          color: "#EF4444",
                          cursor: "pointer",
                          padding: "2px",
                        }}
                        title="Delete row"
                      >
                        <Trash2 size={13} />
                      </button>
                    </td>
                  </tr>
                ))}

                {purchaseLines.length < 6 &&
                  Array.from({ length: 6 - purchaseLines.length }).map((_, i) => (
                    <tr key={`empty-${i}`} style={{ height: "28px" }}>
                      <td onClick={handleAddRow} style={{ cursor: "pointer", color: "#94A3B8" }}>
                        + Add inward line...
                      </td>
                      <td></td>
                      <td></td>
                      <td></td>
                      <td></td>
                      <td></td>
                      <td></td>
                      <td></td>
                      <td></td>
                      <td></td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>

          {/* Marg Bottom Panels */}
          <div
            className="billing-summary-grid"
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 180px 180px 240px 180px",
              borderBottom: "1px solid #CBD5E1",
              backgroundColor: "#FFFFFF",
              fontSize: "0.82rem",
            }}
          >
            {/* Remarks / Narration */}
            <div style={{ padding: "8px 12px", borderRight: "1px solid #CBD5E1" }}>
              <div style={{ color: "#64748B", fontSize: "0.72rem", marginBottom: "4px" }}>Supplier Memo / Note :</div>
              <textarea
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
                placeholder="Transporter name, LR number, or inward notes..."
                style={{
                  width: "100%",
                  height: "54px",
                  border: "1px solid #E2E8F0",
                  borderRadius: "4px",
                  padding: "4px 8px",
                  fontSize: "0.78rem",
                  resize: "none",
                  outline: "none",
                }}
              />
            </div>

            {/* Tax Info Box */}
            <div style={{ padding: "8px 12px", borderRight: "1px solid #CBD5E1", display: "flex", flexDirection: "column", justifyContent: "center" }}>
              <div style={{ fontWeight: 700, color: "#334155", marginBottom: "6px" }}>Tax Info</div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "2px" }}>
                <span style={{ color: "#64748B" }}>CGST :</span>
                <span style={{ fontWeight: 700, color: "#0F172A" }}>{cgstAmount.toFixed(2)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: "#64748B" }}>SGST :</span>
                <span style={{ fontWeight: 700, color: "#0F172A" }}>{sgstAmount.toFixed(2)}</span>
              </div>
            </div>

            {/* Total Disc Center */}
            <div style={{ padding: "8px 12px", borderRight: "1px solid #CBD5E1", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ textAlign: "center" }}>
                <div style={{ color: "#64748B", fontSize: "0.74rem" }}>Total Disc. :</div>
                <div style={{ fontSize: "1rem", fontWeight: 800, color: "#0F172A" }}>
                  {totalDiscount.toFixed(2)}
                </div>
              </div>
            </div>

            {/* Additional Details */}
            <div style={{ padding: "6px 10px", borderRight: "1px solid #CBD5E1" }}>
              <div style={{ fontWeight: 700, color: "#334155", marginBottom: "4px", fontSize: "0.78rem" }}>
                Additional Details
              </div>
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.74rem" }}>
                <tbody>
                  <tr style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ color: "#475569" }}>CGST Output</td>
                    <td style={{ textAlign: "center", color: "#64748B" }}>6%</td>
                    <td style={{ textAlign: "right", fontWeight: 700 }}>₹ {cgstAmount.toFixed(2)}</td>
                  </tr>
                  <tr>
                    <td style={{ color: "#475569" }}>SGST Output</td>
                    <td style={{ textAlign: "center", color: "#64748B" }}>6%</td>
                    <td style={{ textAlign: "right", fontWeight: 700 }}>₹ {sgstAmount.toFixed(2)}</td>
                  </tr>
                </tbody>
              </table>
            </div>

            {/* Big Invoice Value */}
            <div style={{ padding: "8px 12px", display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "flex-end" }}>
              <span style={{ color: "#64748B", fontSize: "0.78rem", fontWeight: 700 }}>Invoice Value :</span>
              <span style={{ fontSize: "1.35rem", fontWeight: 900, color: "#0F766E", letterSpacing: "-0.02em" }}>
                ₹ {invoiceValue.toFixed(2)}
              </span>
            </div>
          </div>

          {/* FIXED MARG ACTION FOOTER TOOLBAR */}
          <div className="marg-footer-bar">
            <button
              onClick={() => handleSaveInvoice(false)}
              disabled={isSubmitting}
              className="marg-btn-teal"
              title="Save Purchase Bill (F10 or End)"
            >
              <span>F10 / End Save 💾</span>
              <span style={{ borderLeft: "1px solid rgba(255,255,255,0.3)", paddingLeft: "4px" }}>▾</span>
            </button>

            <button
              onClick={() => handleSaveInvoice(true)}
              disabled={isSubmitting}
              className="marg-btn-teal"
              style={{ backgroundColor: "#0D9488" }}
              title="Save and Open New Bill (F9)"
            >
              <span>F9 Save & New</span>
            </button>

            <button
              onClick={() => {
                const draft = {
                  partyName,
                  partyAddress,
                  partyBalance,
                  partyDue,
                  billNo,
                  billDate,
                  purchaseLines,
                  remarks,
                  savedAt: new Date().toISOString(),
                };
                localStorage.setItem("medicalcrm_purchase_draft", JSON.stringify(draft));
                setHasDraft(true);
                setSuccessMessage("Purchase inward saved as draft in browser!");
              }}
              className="marg-btn-outline"
              title="Save current progress as draft"
            >
              <span>Save As Draft</span>
            </button>

            {hasDraft && (
              <button
                onClick={() => {
                  try {
                    const raw = localStorage.getItem("medicalcrm_purchase_draft");
                    if (raw) {
                      const parsed = JSON.parse(raw);
                      if (parsed.partyName) setPartyName(parsed.partyName);
                      if (parsed.billNo) setBillNo(parsed.billNo);
                      if (parsed.billDate) setBillDate(parsed.billDate);
                      if (Array.isArray(parsed.purchaseLines) && parsed.purchaseLines.length > 0) {
                        setPurchaseLines(parsed.purchaseLines);
                      }
                      if (parsed.remarks) setRemarks(parsed.remarks);
                      setSuccessMessage("Purchase draft restored successfully!");
                    }
                  } catch {
                    // ignore
                  }
                }}
                className="marg-btn-outline"
                style={{ borderColor: "#059669", color: "#059669" }}
                title="Restore saved draft"
              >
                <span>Restore Draft</span>
              </button>
            )}

            <button
              onClick={() => setViewMode("LIST")}
              className="marg-btn-outline"
              title="Close and return to list (Esc)"
            >
              <span>Esc Close ✕</span>
            </button>

            <button
              onClick={() => {
                const deal = invoices.find(
                  (i) => i.supplier?.name?.toLowerCase() === partyName.toLowerCase()
                ) || invoices[0];
                if (deal) {
                  setSuccessMessage(
                    `Last deal for ${deal.supplier?.name || partyName}: Invoice #${deal.invoiceNumber} on ${formatCompactDate(
                      deal.invoiceDate || deal.createdAt
                    )} for ₹ ${Number(deal.totalAmount || 0).toLocaleString("en-IN", {
                      minimumFractionDigits: 2,
                    })}`
                  );
                } else {
                  setSuccessMessage(`No previous deals recorded for ${partyName}`);
                }
              }}
              className="marg-btn-outline"
            >
              <span>Last Deal</span>
            </button>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* VIEW 2: PURCHASE BILL LIST SCREEN (EXACT MATCH SCREEN 3)  */}
      {/* ========================================================= */}
      {viewMode === "LIST" && (
        <div style={{ display: "flex", flexDirection: "column", flex: 1, minHeight: "100%" }}>
          {/* Header Row: Purchase Bill List, Watch Video, + Create/F2 */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "8px 16px",
              backgroundColor: "#FFFFFF",
              borderBottom: "1px solid #CBD5E1",
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
              <h2 style={{ fontSize: "1.05rem", fontWeight: 800, color: "#0F172A", margin: 0 }}>
                Purchase Bill List
              </h2>
              <span
                style={{
                  backgroundColor: "#ECFDF5",
                  color: "#059669",
                  border: "1px solid #A7F3D0",
                  borderRadius: "9999px",
                  padding: "2px 10px",
                  fontSize: "0.72rem",
                  fontWeight: 700,
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "4px",
                }}
              >
                <Sparkles size={11} /> AI OCR Ready
              </span>
            </div>

            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <button
                onClick={() => setIsOcrOpen(true)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                  backgroundColor: "#059669",
                  color: "#FFFFFF",
                  border: "none",
                  borderRadius: "4px",
                  padding: "6px 12px",
                  fontSize: "0.82rem",
                  fontWeight: 700,
                  cursor: "pointer",
                  boxShadow: "0 1px 3px rgba(0,0,0,0.12)",
                }}
                title="Scan any Distributor / Stockist Invoice with AI OCR"
              >
                <Camera size={14} />
                <span>📷 Scan Bill (AI OCR)</span>
              </button>

              <button
                onClick={() => setViewMode("ENTRY")}
                className="marg-btn-teal"
                title="Create New Bill (F2)"
              >
                <Plus size={14} /> + Create/F2
              </button>
            </div>
          </div>

          {/* Filter Bar: Search here, Today dropdown, F10 Filter */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              padding: "6px 16px",
              backgroundColor: "#F8FAF9",
              borderBottom: "1px solid #CBD5E1",
              gap: "10px",
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "10px", flex: 1, maxWidth: "500px" }}>
              <div
                style={{
                  position: "relative",
                  display: "flex",
                  alignItems: "center",
                  width: "100%",
                  maxWidth: "320px",
                }}
              >
                <input
                  type="text"
                  placeholder="Search here.."
                  value={listSearchTerm}
                  onChange={(e) => setListSearchTerm(e.target.value)}
                  style={{
                    width: "100%",
                    border: "1px solid #CBD5E1",
                    borderRadius: "4px",
                    padding: "4px 28px 4px 8px",
                    fontSize: "0.82rem",
                    outline: "none",
                    backgroundColor: "#FFFFFF",
                  }}
                />
                <Search size={14} color="#94A3B8" style={{ position: "absolute", right: "8px", pointerEvents: "none" }} />
              </div>

              <select
                value={dateFilter}
                onChange={(e) => setDateFilter(e.target.value)}
                style={{
                  border: "1px solid #CBD5E1",
                  borderRadius: "4px",
                  padding: "4px 10px",
                  fontSize: "0.82rem",
                  backgroundColor: "#FFFFFF",
                  color: "#334155",
                  outline: "none",
                  cursor: "pointer",
                }}
              >
                <option value="Today">Today</option>
                <option value="Yesterday">Yesterday</option>
                <option value="This Week">This Week</option>
                <option value="This Month">This Month</option>
                <option value="All Bills">All Bills</option>
              </select>

              <button
                onClick={() => alert("Filter drawer: Filter by supplier, payment status, station")}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "4px",
                  backgroundColor: "#FFFFFF",
                  border: "1px solid #CBD5E1",
                  borderRadius: "4px",
                  padding: "4px 10px",
                  fontSize: "0.8rem",
                  color: "#475569",
                  fontWeight: 600,
                  cursor: "pointer",
                }}
              >
                <span>F10 Filter</span>
                <Filter size={12} />
              </button>
            </div>

            <div style={{ fontSize: "0.78rem", color: "#64748B" }}>
              Total Bills: <strong style={{ color: "#0F172A" }}>{filteredDisplayInvoices.length}</strong>
            </div>
          </div>

          {/* Data Table: Exact match Screenshot 3 */}
          <div style={{ flex: 1, overflowY: "auto" }}>
            <table className="marg-grid-table">
              <thead>
                <tr>
                  <th style={{ width: "35px", textAlign: "center" }}>
                    <input type="checkbox" />
                  </th>
                  <th style={{ width: "16%" }}>Invoice No.</th>
                  <th style={{ width: "14%" }}>Date</th>
                  <th style={{ width: "24%" }}>Party</th>
                  <th style={{ width: "12%" }}>Station</th>
                  <th style={{ width: "10%" }}>Status</th>
                  <th style={{ width: "14%", textAlign: "right" }}>₹ Amount</th>
                  <th style={{ width: "10%", textAlign: "center" }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredDisplayInvoices.map((inv) => {
                  const isSelected = selectedInvoiceId === inv.id;

                  return (
                    <tr
                      key={inv.id}
                      onClick={() => setSelectedInvoiceId(inv.id)}
                      onDoubleClick={() => {
                        setBillNo(inv.invoiceNumber);
                        setPartyName(inv.party);
                        setViewMode("ENTRY");
                      }}
                      style={{
                        backgroundColor: isSelected ? "#FEF3C7" : undefined, // Exact yellow highlight from Screenshot 3 row 4354!
                        cursor: "pointer",
                      }}
                    >
                      <td style={{ textAlign: "center" }}>
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={(e) => {
                            e.stopPropagation();
                            setSelectedInvoiceId(inv.id);
                          }}
                        />
                      </td>

                      <td style={{ fontWeight: 700, color: "#0F172A" }}>
                        .. {inv.invoiceNumber}
                      </td>

                      <td style={{ color: "#334155" }}>
                        {inv.invoiceDate}
                      </td>

                      <td style={{ fontWeight: 600, color: "#1E293B" }}>
                        {inv.party}
                      </td>

                      <td style={{ color: "#64748B" }}>
                        {inv.station || ""}
                      </td>

                      <td>
                        <span style={{ color: "#15803D", fontWeight: 700, fontSize: "0.78rem" }}>
                          Paid
                        </span>
                      </td>

                      <td style={{ textAlign: "right", fontWeight: 800, color: "#0F172A" }}>
                        {inv.amount.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                      </td>

                      <td style={{ textAlign: "center" }}>
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "6px" }}>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setBillNo(inv.invoiceNumber);
                              setPartyName(inv.party);
                              setViewMode("ENTRY");
                            }}
                            style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", padding: "2px" }}
                            title="Edit Bill"
                          >
                            <Edit2 size={13} />
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              window.print();
                            }}
                            style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", padding: "2px" }}
                            title="Print Bill"
                          >
                            <Printer size={13} />
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleOpenDebitNote(inv);
                            }}
                            style={{
                              padding: "2px 6px",
                              backgroundColor: "#FEF2F2",
                              border: "1px solid #FECACA",
                              color: "#991B1B",
                              borderRadius: "3px",
                              fontSize: "0.72rem",
                              fontWeight: 700,
                              cursor: "pointer",
                            }}
                            title="Supplier Debit Note / Return"
                          >
                            Return
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Bottom Summary Bar: Exact match Screenshot 3 */}
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              padding: "8px 16px",
              backgroundColor: "#FFFFFF",
              borderTop: "1px solid #CBD5E1",
              fontSize: "0.78rem",
            }}
          >
            {/* Bill & User Details */}
            <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
              <strong style={{ color: "#1E293B" }}>Bill & User Details</strong>
              <div style={{ color: "#475569" }}>
                No.Of Bills : <strong style={{ color: "#0F172A" }}>{filteredDisplayInvoices.length}</strong>
              </div>
              <div style={{ color: "#475569" }}>
                User : <strong style={{ color: "#0F172A" }}>ankit</strong>
              </div>
            </div>

            {/* Printout Details */}
            <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
              <strong style={{ color: "#1E293B" }}>Printout Details</strong>
              <div style={{ color: "#475569" }}>
                Print : <strong style={{ color: "#0F172A" }}>0</strong>
              </div>
              <div style={{ color: "#475569" }}>
                Print After Modification : <strong style={{ color: "#0F172A" }}>0</strong>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Item Picker Modal */}
      {isItemPickerOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.4)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 100,
          }}
          onClick={() => setIsItemPickerOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "8px",
              width: "650px",
              maxWidth: "92vw",
              maxHeight: "75vh",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #CBD5E1",
              overflow: "hidden",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "8px 14px",
                backgroundColor: "#0F766E",
                color: "#FFFFFF",
              }}
            >
              <span style={{ fontWeight: 700, fontSize: "0.88rem" }}>Select Product to Inward</span>
              <button onClick={() => setIsItemPickerOpen(false)} style={{ background: "none", border: "none", color: "#FFFFFF", cursor: "pointer" }}>✕</button>
            </div>

            <div style={{ padding: "8px 14px", borderBottom: "1px solid #E2E8F0" }}>
              <input
                type="text"
                placeholder="Search medicine / molecule..."
                value={itemSearchQuery}
                onChange={(e) => setItemSearchQuery(e.target.value)}
                autoFocus
                style={{
                  width: "100%",
                  padding: "6px 10px",
                  border: "1px solid #CBD5E1",
                  borderRadius: "4px",
                  fontSize: "0.82rem",
                  outline: "none",
                }}
              />
            </div>

            <div style={{ flex: 1, overflowY: "auto", padding: "6px 0" }}>
              <table className="marg-grid-table">
                <thead>
                  <tr>
                    <th>Product Name</th>
                    <th>Generic Molecule</th>
                    <th>Packing</th>
                    <th style={{ textAlign: "right" }}>MRP</th>
                    <th style={{ textAlign: "center" }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {medicines
                    .filter((m) => m.name.toLowerCase().includes(itemSearchQuery.toLowerCase()))
                    .map((m) => (
                      <tr key={m.id} onClick={() => handleSelectMedicine(m)} style={{ cursor: "pointer" }}>
                        <td style={{ fontWeight: 700, color: "#0F172A" }}>{m.name}</td>
                        <td style={{ color: "#64748B" }}>{m.genericName || "—"}</td>
                        <td>{m.dosageForm || "10's"}</td>
                        <td style={{ textAlign: "right", fontWeight: 600 }}>₹ {Number(m.mrp || 0).toFixed(2)}</td>
                        <td style={{ textAlign: "center" }}>
                          <button className="marg-btn-teal" style={{ padding: "2px 8px", fontSize: "0.72rem" }}>
                            Select
                          </button>
                        </td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* AI Invoice OCR Scanner Modal */}
      <OcrScanModal
        isOpen={isOcrOpen}
        onClose={() => setIsOcrOpen(false)}
        documentType="BILL_PURCHASE"
        title="Scan Purchase Invoice with AI OCR"
        subtitle="Upload distributor bill photo or PDF. Extracted medicines, batches, quantities, rates, and taxes will automatically populate this form."
        onApply={handleOcrApply}
      />

      {/* SUPPLIER DEBIT NOTE / RETURN MODAL */}
      {isDebitNoteOpen && selectedBillForReturn && (
        <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", width: "100%", maxWidth: "480px", padding: "1.5rem", boxShadow: "0 10px 25px rgba(0,0,0,0.2)" }}>
            <h3 style={{ margin: "0 0 0.5rem", fontSize: "1.1rem", fontWeight: 700, color: "#0F172A" }}>
              Supplier Debit Note / Purchase Return
            </h3>
            <p style={{ margin: "0 0 1rem", fontSize: "0.8rem", color: "#64748B" }}>
              Bill #{selectedBillForReturn.invoiceNumber} • {selectedBillForReturn.party || "Stockist"}
            </p>

            <form onSubmit={handleSubmitDebitNote}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                  Return Reason *
                </label>
                <select
                  value={returnReason}
                  onChange={(e) => setReturnReason(e.target.value as any)}
                  style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem", backgroundColor: "#FFFFFF" }}
                >
                  <option value="EXPIRED">Expired Medicine Stock</option>
                  <option value="DAMAGED">Damaged / Broken Packaging</option>
                  <option value="EXCESS">Excess / Slow Moving Stock</option>
                  <option value="RECALLED">Company Batch Recall</option>
                  <option value="OTHER">Other Reason</option>
                </select>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem", marginBottom: "1.25rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Return Quantity *
                  </label>
                  <input
                    type="number"
                    min={1}
                    required
                    value={returnQty}
                    onChange={(e) => setReturnQty(parseInt(e.target.value) || 1)}
                    style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Debit Rate (₹) *
                  </label>
                  <input
                    type="number"
                    min={0.01}
                    step="0.01"
                    required
                    value={returnRate}
                    onChange={(e) => setReturnRate(parseFloat(e.target.value) || 0)}
                    style={{ width: "100%", padding: "0.5rem 0.75rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.85rem" }}
                  />
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.5rem" }}>
                <button
                  type="button"
                  onClick={() => setIsDebitNoteOpen(false)}
                  style={{ padding: "0.5rem 1rem", border: "1px solid #CBD5E1", borderRadius: "6px", background: "none", fontSize: "0.82rem", cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingReturn}
                  style={{ backgroundColor: "#DC2626", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1.2rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}
                >
                  {isSubmittingReturn ? "Issuing Debit Note..." : "Issue Debit Note"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
