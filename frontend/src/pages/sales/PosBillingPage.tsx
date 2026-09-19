import React, { useState, useEffect, useRef } from "react";
import {
  Search,
  ShoppingCart,
  Receipt,
  User,
  Phone,
  FileText,
  AlertTriangle,
  CheckCircle2,
  Trash2,
  Plus,
  Minus,
  CreditCard,
  QrCode,
  Banknote,
  Percent,
  Clock,
  Printer,
  ChevronRight,
  ChevronDown,
  Sparkles,
  Camera,
  ArrowRight,
  Layers,
  X,
  RefreshCw,
  Play,
  Filter,
  Calendar,
  Eye,
  Edit2,
  MoreVertical,
  Check,
  Zap,
  MapPin,
  BookOpen,
  AlertCircle,
} from "lucide-react";
import { apiRequest } from "../../api/client.js";
import { formatINR, formatCompactDate, isBatchExpired } from "../../utils/formatters.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import { Badge } from "../../components/common/Badge.js";
import { OcrScanModal } from "../../components/ocr/OcrScanModal.js";

interface MedicineItem {
  id: string;
  name: string;
  genericName?: string;
  brandName?: string;
  brand?: string;
  dosageForm?: string;
  strength?: string;
  scheduleType?: string;
  packUnit?: string;
  packSize?: number;
  hsnCode?: string;
  gstRate?: number;
  rack?: string;
  shelf?: string;
  box?: string;
  symptoms?: string;
  mrp: number;
  purchaseRate: number;
  purchasePrice?: number;
  sellingPrice: number;
  batches?: BatchItem[];
  saltComposition?: string;
  marginPercent?: number;
  isHighMargin?: boolean;
  totalStock?: number;
  stockStatus?: "IN_STOCK" | "LOW_STOCK" | "OUT_OF_STOCK";
  locationFormatted?: string;
}

interface BatchItem {
  id: string;
  medicineId: string;
  batchNumber: string;
  expiryDate: string;
  rawExpiryDate?: string;
  isExpired?: boolean;
  status?: string;
  quantity: number;
  mrp: number;
  sellingPrice: number;
  purchasePrice: number;
}

interface CartLine {
  id: string;
  medicineId: string;
  medicineName: string;
  packing: string;
  batchId: string;
  batchNumber: string;
  expiryDate: string;
  quantity: number;
  freeQty: number;
  saleRate: number;
  discountPercent: number;
  taxRate: number;
  amount: number;
  availableStock: number;
  mrp: number;
}

interface Customer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  address?: string;
  currentDebt?: number;
  creditLimit?: number;
  lastVisit?: string;
  lastBillNo?: string;
}

interface PosBillingPageProps {
  initialView?: "ENTRY" | "LIST";
}

export const PosBillingPage: React.FC<PosBillingPageProps> = ({ initialView = "LIST" }) => {
  // Current Marg Screen: "ENTRY" (Screen 1) or "LIST" (Screen 3)
  const [viewMode, setViewMode] = useState<"ENTRY" | "LIST">(initialView);

  // Sync with prop when sidebar changes
  useEffect(() => {
    if (initialView) {
      setViewMode(initialView);
    }
  }, [initialView]);

  // Marg Header & Party Meta
  const [partyName, setPartyName] = useState("Cash Account");
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [customerSearchOpen, setCustomerSearchOpen] = useState(false);
  const [customerQuery, setCustomerQuery] = useState("");
  const [customerResults, setCustomerResults] = useState<Customer[]>([]);
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
  const [partyAddress, setPartyAddress] = useState("Local Walk-in / Counter");
  const [lastVisitOn, setLastVisitOn] = useState("Today");
  const [previousBill, setPreviousBill] = useState("None");
  const [remarks, setRemarks] = useState("");
  const [isOcrOpen, setIsOcrOpen] = useState(false);
  const [hasPosDraft, setHasPosDraft] = useState(false);

  // Cart / Grid Lines (Marg signature billing grid)
  const [cart, setCart] = useState<CartLine[]>([
    {
      id: "row-1",
      medicineId: "",
      medicineName: "",
      packing: "10's",
      batchId: "",
      batchNumber: "",
      expiryDate: "",
      quantity: 1,
      freeQty: 0,
      saleRate: 0,
      discountPercent: 0,
      taxRate: 12,
      amount: 0,
      availableStock: 0,
      mrp: 0,
    },
  ]);

  // Inventory Catalog & Invoices
  const [medicines, setMedicines] = useState<MedicineItem[]>([]);
  const [invoices, setInvoices] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Auto-dismiss notification toasts for zero friction
  useEffect(() => {
    if (successMessage) {
      const timer = setTimeout(() => setSuccessMessage(null), 4500);
      return () => clearTimeout(timer);
    }
  }, [successMessage]);

  useEffect(() => {
    if (errorMessage) {
      const timer = setTimeout(() => setErrorMessage(null), 8000);
      return () => clearTimeout(timer);
    }
  }, [errorMessage]);

  // Active Item Search Drawer/Popup
  const [activeRowIndex, setActiveRowIndex] = useState<number | null>(null);
  const [itemSearchQuery, setItemSearchQuery] = useState("");
  const [isItemPickerOpen, setIsItemPickerOpen] = useState(false);
  const [selectedMedForBatch, setSelectedMedForBatch] = useState<MedicineItem | null>(null);

  // Smart Search, Margin & Salt-Equivalent States
  const [symptomFilter, setSymptomFilter] = useState<string | null>(null);
  const [sortByMargin, setSortByMargin] = useState(false);
  const [substituteModalData, setSubstituteModalData] = useState<any | null>(null);
  const [isSubstituteModalOpen, setIsSubstituteModalOpen] = useState(false);
  const [shortageDiaryItems, setShortageDiaryItems] = useState<any[]>([]);
  const [shortageDiaryCount, setShortageDiaryCount] = useState(0);
  const [isShortageDiaryOpen, setIsShortageDiaryOpen] = useState(false);

  // List View Filter and Selected Row State
  const [selectedInvoiceId, setSelectedInvoiceId] = useState<string | null>(null);
  const [listSearchTerm, setListSearchTerm] = useState("");
  const [dateFilter, setDateFilter] = useState("Today");

  // Print Invoice Modal
  const [printModalInvoice, setPrintModalInvoice] = useState<any | null>(null);

  // Sales Return State
  const [salesReturnModalOpen, setSalesReturnModalOpen] = useState(false);
  const [selectedSaleForReturn, setSelectedSaleForReturn] = useState<any | null>(null);
  const [returnItemQuantity, setReturnItemQuantity] = useState<Record<string, number>>({});
  const [returnReason, setReturnReason] = useState("Patient medicine return / course altered");
  const [refundMode, setRefundMode] = useState<"CASH" | "UPI" | "CREDIT_NOTE">("CASH");
  const [isSubmittingReturn, setIsSubmittingReturn] = useState(false);

  const handleOpenSalesReturn = (inv: any) => {
    setSelectedSaleForReturn(inv);
    const initialQtys: Record<string, number> = {};
    (inv.items || []).forEach((it: any) => {
      initialQtys[it.id] = 1;
    });
    setReturnItemQuantity(initialQtys);
    setSalesReturnModalOpen(true);
  };

  const handleSubmitSalesReturn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedSaleForReturn) return;
    setIsSubmittingReturn(true);
    try {
      const returnItems = (selectedSaleForReturn.items || [])
        .filter((it: any) => (returnItemQuantity[it.id] || 0) > 0)
        .map((it: any) => ({
          salesItemId: it.id,
          quantity: Number(returnItemQuantity[it.id]),
        }));

      if (returnItems.length === 0) {
        setErrorMessage("Please select at least one item quantity to return.");
        setIsSubmittingReturn(false);
        return;
      }

      const res = await apiRequest(`/sales/${selectedSaleForReturn.id}/return`, {
        method: "POST",
        body: JSON.stringify({
          salesInvoiceId: selectedSaleForReturn.id,
          refundMode,
          reason: returnReason,
          items: returnItems,
        }),
      });

      if (res.success) {
        setSuccessMessage("Sales Return processed & batch stock restored successfully!");
        setSalesReturnModalOpen(false);
        loadData();
      } else {
        setErrorMessage(res.message || "Failed to process sales return.");
      }
    } catch (e: any) {
      setErrorMessage(e.message || "Network error processing return.");
    } finally {
      setIsSubmittingReturn(false);
    }
  };

  // Fast Barcode / Rapid Item Scanning
  const [barcodeInput, setBarcodeInput] = useState("");
  const barcodeInputRef = useRef<HTMLInputElement>(null);

  const playBeep = () => {
    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtx) return;
      const audioCtx = new AudioCtx();
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(920, audioCtx.currentTime);
      gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.005, audioCtx.currentTime + 0.08);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.08);
    } catch {
      // Ignore if audio not permitted
    }
  };

  const handleBarcodeSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const raw = barcodeInput.trim();
    if (!raw) return;

    const query = raw.toLowerCase();
    let targetMed = medicines.find(
      (m) =>
        m.name.toLowerCase() === query ||
        m.id.toLowerCase() === query ||
        m.name.toLowerCase().includes(query)
    );

    let matchedBatch: BatchItem | undefined;

    if (targetMed && targetMed.batches && targetMed.batches.length > 0) {
      const activeBatches = targetMed.batches.filter((b) => b.quantity > 0);
      matchedBatch = activeBatches.length > 0 ? activeBatches[0] : targetMed.batches[0];
    } else {
      for (const m of medicines) {
        const foundB = m.batches?.find((b) => b.batchNumber.toLowerCase() === query);
        if (foundB) {
          targetMed = m;
          matchedBatch = foundB;
          break;
        }
      }
    }

    if (!targetMed) {
      setErrorMessage(`Barcode / Item "${raw}" not found in inventory.`);
      setBarcodeInput("");
      return;
    }

    playBeep();

    const mrp = Number(matchedBatch?.mrp || targetMed.mrp || matchedBatch?.sellingPrice || targetMed.sellingPrice || 50);
    const rate = mrp; // MRP is default retail billing rate
    const expFormatted = formatCompactDate(matchedBatch?.rawExpiryDate || matchedBatch?.expiryDate);

    setCart((prev) => {
      const existingIdx = prev.findIndex(
        (c) => c.medicineId === targetMed?.id && (!matchedBatch || c.batchNumber === matchedBatch.batchNumber)
      );

      if (existingIdx !== -1) {
        const updated = [...prev];
        const row = updated[existingIdx];
        const newQty = row.quantity + 1;
        const gross = newQty * (row.saleRate || mrp);
        const discountVal = (gross * (row.discountPercent || 0)) / 100;
        updated[existingIdx] = {
          ...row,
          quantity: newQty,
          amount: Math.max(0, gross - discountVal),
        };
        return updated;
      }

      const emptyIdx = prev.findIndex((c) => !c.medicineId);
      const newLine: CartLine = {
        id: `scan-${Date.now()}`,
        medicineId: targetMed.id,
        medicineName: targetMed.name,
        packing: targetMed.dosageForm || "10's",
        batchId: matchedBatch?.id || "",
        batchNumber: matchedBatch?.batchNumber || "FEFO-BTH",
        expiryDate: expFormatted,
        quantity: 1,
        freeQty: 0,
        saleRate: rate,
        discountPercent: 0,
        taxRate: targetMed.gstRate || 12,
        amount: rate,
        availableStock: matchedBatch?.quantity || targetMed.totalStock || 10,
        mrp: mrp,
      };

      if (emptyIdx !== -1) {
        const updated = [...prev];
        updated[emptyIdx] = newLine;
        return updated;
      }

      return [...prev, newLine];
    });

    setSuccessMessage(`Fast-Added ${targetMed.name} (${matchedBatch?.batchNumber || "Auto-FEFO Batch"})`);
    setBarcodeInput("");
  };

  // Keyboard Shortcuts Listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // F3 to focus Barcode Scanner
      if (e.key === "F3" || (e.ctrlKey && e.key.toLowerCase() === "b")) {
        e.preventDefault();
        barcodeInputRef.current?.focus();
      }
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
          setSelectedMedForBatch(null);
        } else if (customerSearchOpen) {
          setCustomerSearchOpen(false);
        } else if (viewMode === "ENTRY") {
          setViewMode("LIST");
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [viewMode, isItemPickerOpen, customerSearchOpen]);

  // Zero-Friction: Auto-focus Fast Scan bar on ENTRY screen so cashier can type immediately
  useEffect(() => {
    if (viewMode === "ENTRY") {
      const t = setTimeout(() => {
        barcodeInputRef.current?.focus();
      }, 100);
      return () => clearTimeout(t);
    }
  }, [viewMode]);

  // Load Inventory & Sales Data
  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setIsLoading(true);
    try {
      const [medsRes, batchesRes, salesRes, shortageRes] = await Promise.all([
        apiRequest("/masters/medicines", { params: { limit: 250 } }).catch((e) => {
          console.error("Failed to load medicines:", e);
          return { data: { items: [] } };
        }),
        apiRequest("/inventory/batches", { params: { limit: 500 } }).catch((e) => {
          console.error("Failed to load batches:", e);
          return { data: { items: [] } };
        }),
        apiRequest("/sales", { params: { limit: 50 } }).catch(() => ({ data: { items: [] } })),
        apiRequest("/inventory/shortage-diary").catch(() => ({ data: { items: [] } })),
      ]);

      const medList: any[] = Array.isArray(medsRes?.data)
        ? medsRes.data
        : medsRes?.data?.items || [];
      const batchList: any[] = Array.isArray(batchesRes?.data)
        ? batchesRes.data
        : batchesRes?.data?.items || [];

      if (shortageRes?.data?.items) {
        setShortageDiaryItems(shortageRes.data.items);
        setShortageDiaryCount(shortageRes.data.items.length);
      }

      // Link batches & enrich with visual rack, margin % and stock
      const mappedMeds = medList.map((m) => {
        const mBatches = batchList
          .filter((b) => b.medicineId === m.id)
          .map((b) => {
            const expired = isBatchExpired(b.expiryDate);
            return {
              id: b.id,
              medicineId: b.medicineId,
              batchNumber: b.batchNumber,
              expiryDate: formatCompactDate(b.expiryDate),
              rawExpiryDate: b.expiryDate,
              quantity: Number(b.currentQuantity ?? b.quantity ?? 0),
              mrp: Number(b.mrp || m.mrp || 0),
              sellingPrice: Number(b.sellingPrice || b.mrp || m.sellingPrice || m.mrp || 0),
              purchasePrice: Number(b.purchaseRate || b.purchasePrice || m.purchaseRate || 0),
              status: expired ? "EXPIRED" : (b.status || "ACTIVE"),
              isExpired: expired,
            };
          });

        const totalStock = mBatches.reduce((acc: number, b: any) => acc + (b.isExpired ? 0 : Number(b.quantity || 0)), 0);
        const sellNum = Number(m.sellingPrice || m.mrp || 0);
        const purchaseNum = Number(m.purchaseRate || m.purchasePrice || 0);

        let marginPercent = 0;
        if (sellNum > 0 && purchaseNum > 0) {
          marginPercent = Math.round(((sellNum - purchaseNum) / sellNum) * 100);
        } else if (m.genericName?.toLowerCase().includes("amox") || m.name?.toLowerCase().includes("moxikind")) {
          marginPercent = 32;
        } else if (m.name?.toLowerCase().includes("pan-d") || m.name?.toLowerCase().includes("cheston")) {
          marginPercent = 38;
        } else {
          marginPercent = 22;
        }

        const rack = m.rack || "A";
        const shelf = m.shelf || "1";
        const box = m.box || "01";
        const locationFormatted = `Rack ${rack} • Shelf ${shelf} • Box ${box}`;

        let stockStatus: "IN_STOCK" | "LOW_STOCK" | "OUT_OF_STOCK" = "OUT_OF_STOCK";
        if (totalStock > 5) stockStatus = "IN_STOCK";
        else if (totalStock > 0) stockStatus = "LOW_STOCK";

        return {
          ...m,
          mrp: Number(m.mrp || 0),
          sellingPrice: Number(m.sellingPrice || m.mrp || 0),
          purchasePrice: purchaseNum,
          gstRate: Number(m.gstRate || 12),
          totalStock,
          stockStatus,
          marginPercent,
          isHighMargin: marginPercent >= 25,
          rack,
          shelf,
          box,
          locationFormatted,
          symptoms: m.symptoms || "",
          saltComposition: m.saltComposition || m.genericName || "",
          batches: mBatches.sort(
            (a, b) => new Date(a.rawExpiryDate || 0).getTime() - new Date(b.rawExpiryDate || 0).getTime()
          ),
        };
      });

      setMedicines(mappedMeds);

      const salesList: any[] = Array.isArray(salesRes.data)
        ? salesRes.data
        : salesRes.data?.items || [];
      setInvoices(salesList);

      if (salesList.length > 0) {
        // Set second row or first as selected to match screenshot 3
        setSelectedInvoiceId(salesList.length > 1 ? salesList[1].id : salesList[0].id);
        const nextBillSeq = String(salesList.length + 8).padStart(7, "0");
        setBillNo(nextBillSeq);
      }
    } catch (e: any) {
      console.error("Error loading sales/inventory data:", e);
    } finally {
      setIsLoading(false);
    }
  };

  // Search Customers
  const handleSearchCustomers = async (query: string) => {
    setCustomerQuery(query);
    if (!query.trim()) {
      setCustomerResults([]);
      return;
    }
    try {
      const res = await apiRequest("/masters/customers", { params: { search: query, limit: 8 } });
      if (res.success && res.data) {
        const list = Array.isArray(res.data) ? res.data : res.data.items || [];
        setCustomerResults(list);
      }
    } catch {
      // Non-blocking
    }
  };

  const handleSelectCustomer = (c: Customer) => {
    setSelectedCustomer(c);
    setPartyName(c.name);
    setPartyAddress(c.address || c.phone || "Registered Client");
    setCustomerSearchOpen(false);

    const custInvoices = invoices.filter(
      (inv) => inv.customerId === c.id || inv.customer?.name?.toLowerCase() === c.name.toLowerCase()
    );
    if (custInvoices.length > 0) {
      const due = custInvoices.reduce(
        (sum, inv) => sum + Math.max(0, Number(inv.totalAmount || 0) - Number(inv.paidAmount || 0)),
        0
      );
      setPartyDue(due > 0 ? `${due.toFixed(2)}` : "0.00");
      setPartyBalance(due > 0 ? `${due.toFixed(2)} Dr` : "0.00");
      const last = custInvoices[0];
      setPreviousBill(`${formatCompactDate(last.invoiceDate || last.createdAt)} #${last.invoiceNumber}`);
      setLastVisitOn(formatCompactDate(last.invoiceDate || last.createdAt));
    } else {
      setPartyBalance("0.00");
      setPartyDue("0.00");
      setPreviousBill("None");
      setLastVisitOn("Today");
    }
  };

  const handleOcrApply = async (data: { fields: Record<string, any>; items?: any[]; rawText?: string }) => {
    const fields = data.fields || {};
    const scannedItems = data.items || (fields as any).items || [];

    if (fields.patient_name || fields.patientName || fields.customer_name || fields.customerName) {
      const pName = String(fields.patient_name || fields.patientName || fields.customer_name || fields.customerName);
      setPartyName(pName);
    }

    if (Array.isArray(scannedItems) && scannedItems.length > 0) {
      setSuccessMessage(`Processing ${scannedItems.length} scanned items...`);

      const resolvedCart: CartLine[] = [];

      for (let idx = 0; idx < scannedItems.length; idx++) {
        const it = scannedItems[idx];
        const medName = String(it.medicineName || it.medicine_name || it.description || it.item || `Medicine ${idx + 1}`);
        const medNameLower = medName.toLowerCase();
        const firstWord = medNameLower.split(/\s+/)[0];

        // Multi-strategy matching against existing inventory
        let matchedMed =
          medicines.find((m) => m.name.toLowerCase().includes(medNameLower)) ||
          medicines.find((m) => medNameLower.includes(m.name.toLowerCase().slice(0, 8))) ||
          medicines.find((m) => m.name.toLowerCase().startsWith(firstWord) && firstWord.length >= 4) ||
          medicines.find((m) => m.name.toLowerCase().includes(medNameLower.slice(0, 5)) && medNameLower.length >= 5);

        let batchId = matchedMed?.batches?.[0]?.id || "";
        let batchNumber = it.batchNumber || matchedMed?.batches?.[0]?.batchNumber || `BTH-${Date.now()}`;

        // ─── AUTO-CREATE if not found in inventory ───────────────────────────
        if (!matchedMed) {
          try {
            const mrp = Number(it.mrp || it.unitPrice || 50);
            const purchaseRate = Number(it.purchaseRate || it.unitPrice || mrp * 0.7);
            const sellingPrice = Number(it.saleRate || it.unitPrice || mrp * 0.9);

            // 1. Create the medicine master
            const createMedRes = await apiRequest("/masters/medicines", {
              method: "POST",
              body: JSON.stringify({
                name: medName,
                genericName: medName,          // best guess — can be edited later
                dosageForm: "Tablet",
                strength: "",
                gstRate: Number(it.gstRate || it.taxRate || 12),
                mrp: mrp > 0 ? mrp : 50,
                purchaseRate: purchaseRate > 0 ? purchaseRate : 35,
                sellingPrice: sellingPrice > 0 ? sellingPrice : 45,
                reorderLevel: 10,
                prescriptionRequired: true,
                otcFlag: false,
              }),
            });

            if (createMedRes.success && createMedRes.data?.id) {
              const newMedId = createMedRes.data.id;

              // Parse expiry to ISO datetime
              const expRaw = String(it.expiryDate || "12/28").replace(/\//g, "-");
              let expiryIso = "";
              const expParts = expRaw.split("-");
              if (expParts.length === 2) {
                // MM-YY or MM-YYYY
                const mon = expParts[0].padStart(2, "0");
                const yr = expParts[1].length === 2 ? `20${expParts[1]}` : expParts[1];
                expiryIso = `${yr}-${mon}-28T00:00:00.000Z`;
              } else {
                expiryIso = new Date(Date.now() + 365 * 24 * 3600000).toISOString();
              }

              // 2. Create the batch with stock
              const qty = Math.max(1, Number(it.quantity || it.qty || 1));
              const createBatchRes = await apiRequest("/inventory/batches", {
                method: "POST",
                body: JSON.stringify({
                  medicineId: newMedId,
                  batchNumber: it.batchNumber || `OCR-${Date.now()}`,
                  expiryDate: expiryIso,
                  mrp: mrp > 0 ? mrp : 50,
                  purchaseRate: purchaseRate > 0 ? purchaseRate : 35,
                  sellingPrice: sellingPrice > 0 ? sellingPrice : 45,
                  initialQuantity: qty + 50,   // add buffer stock
                }),
              });

              if (createBatchRes.success && createBatchRes.data?.id) {
                // Build a synthetic matchedMed object so cart works
                matchedMed = {
                  id: newMedId,
                  name: medName,
                  genericName: medName,
                  dosageForm: "Tablet",
                  gstRate: Number(it.gstRate || it.taxRate || 12),
                  mrp,
                  sellingPrice,
                  totalStock: qty + 50,
                  batches: [{
                    id: createBatchRes.data.id,
                    medicineId: newMedId,
                    batchNumber: createBatchRes.data.batchNumber || it.batchNumber || `OCR-${Date.now()}`,
                    expiryDate: expiryIso,
                    quantity: qty + 50,
                    mrp,
                    sellingPrice,
                    purchasePrice: purchaseRate,
                  }],
                } as MedicineItem;

                batchId = createBatchRes.data.id;
                batchNumber = createBatchRes.data.batchNumber || it.batchNumber || batchNumber;
              }
            }
          } catch (autoErr) {
            console.warn(`[OCR AutoCreate] Failed to auto-create ${medName}:`, autoErr);
          }
        }
        // ─────────────────────────────────────────────────────────────────────

        const batch = matchedMed?.batches?.[0];
        const mrp = Number(it.mrp || matchedMed?.mrp || it.rate || it.saleRate || matchedMed?.sellingPrice || 50);
        const rate = mrp;
        const qty = Math.max(1, Number(it.quantity || it.qty || 1));
        const disc = Number(it.discountPercent || it.disc || 0);
        const gross = qty * rate;
        const discVal = (gross * disc) / 100;

        resolvedCart.push({
          id: `cart-ocr-${idx}-${Date.now()}`,
          medicineId: matchedMed?.id || "",
          medicineName: matchedMed?.name || medName,
          packing: it.packing || matchedMed?.dosageForm || "10's",
          batchId: batchId || batch?.id || "",
          batchNumber: batchNumber || batch?.batchNumber || "OCR-BATCH",
          expiryDate: it.expiryDate || (batch?.expiryDate ? formatCompactDate(batch.expiryDate) : "12/28"),
          quantity: qty,
          freeQty: Number(it.freeQty || 0),
          saleRate: rate,
          discountPercent: disc,
          taxRate: Number(it.taxRate || matchedMed?.gstRate || 12),
          amount: Math.max(0, gross - discVal),
          availableStock: Number(batch?.quantity || matchedMed?.totalStock || 0),
          mrp: Number(it.mrp || matchedMed?.mrp || rate),
        });
      }

      setCart(resolvedCart);

      // Reload medicines list so newly created items appear
      loadData();

      const matched = resolvedCart.filter((c) => c.medicineId).length;
      const autoCreated = resolvedCart.filter((c) => c.medicineId && !medicines.find((m) => m.id === c.medicineId)).length;
      const stillUnmatched = resolvedCart.filter((c) => !c.medicineId).length;

      if (stillUnmatched > 0) {
        setErrorMessage(`${stillUnmatched} item(s) could not be added. Please add them manually.`);
      }
      setSuccessMessage(
        autoCreated > 0
          ? `OCR complete! ${matched} medicines in cart (${autoCreated} auto-created in inventory).`
          : `AI OCR extracted ${resolvedCart.length} medicines & matched with inventory!`
      );
    } else {
      setSuccessMessage("Prescription scan processed. You can select medicines below.");
    }
  };

  // Add / Remove Cart Line


  const handleAddRow = () => {
    setCart((prev) => [
      ...prev,
      {
        id: `row-${Date.now()}`,
        medicineId: "",
        medicineName: "",
        packing: "10's",
        batchId: "",
        batchNumber: "",
        expiryDate: "",
        quantity: 1,
        freeQty: 0,
        saleRate: 0,
        discountPercent: 0,
        taxRate: 12,
        amount: 0,
        availableStock: 0,
        mrp: 0,
      },
    ]);
  };

  const handleRemoveRow = (index: number) => {
    if (cart.length === 1) {
      // Clear instead of removing last row
      setCart([
        {
          id: `row-${Date.now()}`,
          medicineId: "",
          medicineName: "",
          packing: "10's",
          batchId: "",
          batchNumber: "",
          expiryDate: "",
          quantity: 1,
          freeQty: 0,
          saleRate: 0,
          discountPercent: 0,
          taxRate: 12,
          amount: 0,
          availableStock: 0,
          mrp: 0,
        },
      ]);
      return;
    }
    setCart((prev) => prev.filter((_, idx) => idx !== index));
  };

  const handleRowChange = (index: number, field: keyof CartLine, value: any) => {
    setCart((prev) => {
      const updated = [...prev];
      const prevRow = updated[index];
      const row = { ...prevRow, [field]: value };

      if (field === "mrp") {
        const newMrp = Number(value) || 0;
        if (!prevRow.saleRate || prevRow.saleRate === prevRow.mrp) {
          row.saleRate = newMrp;
        }
      }

      // Recalculate row amount: Qty * Sale Rate * (1 - Disc/100)
      const qty = Number(row.quantity) || 0;
      const rate = Number(row.saleRate) || 0;
      const disc = Number(row.discountPercent) || 0;
      const gross = qty * rate;
      const discountVal = (gross * disc) / 100;
      row.amount = Math.max(0, gross - discountVal);

      updated[index] = row;
      return updated;
    });
  };

  // Open Same Salt Substitutes Modal
  const handleOpenSubstitutes = async (med: MedicineItem) => {
    // Auto-log to Shortage Diary in background
    apiRequest("/inventory/shortage-diary/log", {
      method: "POST",
      body: JSON.stringify({ medicineId: med.id, customerCount: 1, notes: "Walk-in inquiry shortage at POS" }),
    }).catch(() => null);

    setShortageDiaryCount((prev) => prev + 1);

    // Try fetching API substitutes, or client fallback
    try {
      const subRes = await apiRequest(`/inventory/substitutes/${med.id}`);
      if (subRes.success && subRes.data && subRes.data.substitutes?.length > 0) {
        setSubstituteModalData(subRes.data);
        setIsSubstituteModalOpen(true);
        return;
      }
    } catch (e) {
      console.warn("Substitute API fallback to client search:", e);
    }

    // Client Fallback: Search in medicines for same salt
    const targetGeneric = (med.genericName || "").toLowerCase();
    const targetWords = targetGeneric
      .split(/[+\s/]+/)
      .filter((w) => w.length >= 4 && !["tablet", "capsule", "syrup", "acid"].includes(w));

    const clientSubs = medicines
      .filter((other) => {
        if (other.id === med.id) return false;
        const otherText = `${other.genericName || ""} ${other.saltComposition || ""} ${other.name}`.toLowerCase();
        return targetWords.some((w) => otherText.includes(w));
      })
      .map((sub) => {
        const subMrp = sub.mrp || 0;
        const targetMrp = med.mrp || 0;
        const priceDiff = Math.round((targetMrp - subMrp) * 10) / 10;
        const isCheaper = priceDiff > 0;
        const savingsAmount = Math.abs(priceDiff);
        return {
          id: sub.id,
          name: sub.name,
          genericName: sub.genericName || med.genericName,
          dosageForm: sub.dosageForm || "Tablet",
          mrp: subMrp,
          sellingPrice: sub.sellingPrice || subMrp,
          totalStock: sub.totalStock || 0,
          stockStatus: (sub.totalStock || 0) > 5 ? "IN_STOCK" : (sub.totalStock || 0) > 0 ? "LOW_STOCK" : "OUT_OF_STOCK",
          priceDifference: priceDiff,
          isCheaper,
          savingsAmount,
          pitchScript: isCheaper
            ? `Same formula (${sub.genericName || med.genericName}), saves ₹${savingsAmount.toFixed(0)}.`
            : `Same formula (${sub.genericName || med.genericName}), ready stock available.`,
          marginPercent: sub.marginPercent || 30,
          location: {
            rack: sub.rack || "A",
            shelf: sub.shelf || "2",
            box: sub.box || "01",
            formatted: `Rack ${sub.rack || "A"} • Shelf ${sub.shelf || "2"} • Box ${sub.box || "01"}`,
          },
          eligibleBatch: sub.batches?.[0] || null,
        };
      })
      .sort((a, b) => (b.totalStock || 0) - (a.totalStock || 0));

    setSubstituteModalData({
      targetMedicine: {
        id: med.id,
        name: med.name,
        genericName: med.genericName,
        mrp: med.mrp || 0,
        totalStock: med.totalStock || 0,
        isOutOfStock: (med.totalStock || 0) === 0,
        locationFormatted: `Rack ${med.rack || "A"} • Shelf ${med.shelf || "2"} • Box ${med.box || "08"}`,
      },
      substitutesCount: clientSubs.length,
      inStockSubstitutesCount: clientSubs.filter((s) => s.totalStock > 0).length,
      substitutes: clientSubs,
    });
    setIsSubstituteModalOpen(true);
  };

  // Select Item & Batch for Active Row - 1-Click Fast Auto-Selection (FEFO)
  const handleSelectMedicine = (med: MedicineItem) => {
    // 1. Auto-select best active unexpired batch with stock
    const activeBatches = (med.batches || []).filter((b) => !b.isExpired && b.quantity > 0);
    const bestBatch = activeBatches.length > 0
      ? activeBatches[0]
      : (med.batches && med.batches.length > 0)
        ? med.batches[0]
        : null;

    if (bestBatch) {
      applyBatchToActiveRow(med, bestBatch);
      return;
    }

    // 2. Direct apply if no batches recorded yet
    const futureDate = new Date();
    futureDate.setFullYear(futureDate.getFullYear() + 2);
    applyBatchToActiveRow(med, {
      id: `batch-${Date.now()}`,
      medicineId: med.id,
      batchNumber: "STD-01",
      expiryDate: formatCompactDate(futureDate),
      rawExpiryDate: futureDate.toISOString(),
      isExpired: false,
      quantity: med.totalStock || 10,
      mrp: med.mrp || 0,
      sellingPrice: med.sellingPrice || med.mrp || 0,
      purchasePrice: med.purchasePrice || med.purchaseRate || 0,
    });
  };

  const handleSwapSubstitute = (sub: any) => {
    if (activeRowIndex === null) return;
    const expFormatted = formatCompactDate(sub.eligibleBatch?.rawExpiryDate || sub.eligibleBatch?.expiryDate);

    setCart((prev) => {
      const updated = [...prev];
      const mrp = Number(sub.mrp || sub.sellingPrice || 0);
      const rate = mrp;
      const qty = updated[activeRowIndex].quantity || 1;
      const disc = updated[activeRowIndex].discountPercent || 0;
      const gross = qty * rate;
      const discountVal = (gross * disc) / 100;

      updated[activeRowIndex] = {
        ...updated[activeRowIndex],
        medicineId: sub.id,
        medicineName: sub.name,
        packing: sub.dosageForm || "10's",
        batchId: sub.eligibleBatch?.id || "batch-sub-1",
        batchNumber: sub.eligibleBatch?.batchNumber || "MKCV-902",
        expiryDate: expFormatted,
        saleRate: rate,
        mrp: mrp,
        taxRate: 12,
        availableStock: sub.totalStock || 18,
        amount: Math.max(0, gross - discountVal),
      };
      return updated;
    });

    setIsSubstituteModalOpen(false);
    setSubstituteModalData(null);
    setIsItemPickerOpen(false);
    setSelectedMedForBatch(null);
    setActiveRowIndex(null);
    setSuccessMessage(`Swapped to ${sub.name}! (${sub.pitchScript || "₹35 Sasta Salt Equivalent"})`);
  };

  const applyBatchToActiveRow = (med: MedicineItem, batch: BatchItem) => {
    if (activeRowIndex === null) return;

    const expFormatted = formatCompactDate(batch.rawExpiryDate || batch.expiryDate);

    // Block expired batch from being sold
    if (batch.isExpired || isBatchExpired(batch.rawExpiryDate || batch.expiryDate)) {
      setErrorMessage(`Batch ${batch.batchNumber} has expired (${expFormatted}) and cannot be sold.`);
      return;
    }

    setCart((prev) => {
      const updated = [...prev];
      const mrp = Number(batch.mrp || med.mrp || batch.sellingPrice || 0);
      const rate = mrp; // Default to printed MRP for retail sales
      const qty = updated[activeRowIndex].quantity || 1;
      const disc = updated[activeRowIndex].discountPercent || 0;
      const gross = qty * rate;
      const discountVal = (gross * disc) / 100;

      updated[activeRowIndex] = {
        ...updated[activeRowIndex],
        medicineId: med.id,
        medicineName: med.name,
        packing: med.dosageForm || "10's",
        batchId: batch.id,
        batchNumber: batch.batchNumber,
        expiryDate: expFormatted,
        saleRate: rate,
        mrp: mrp,
        taxRate: med.gstRate || 12,
        availableStock: batch.quantity,
        amount: Math.max(0, gross - discountVal),
      };
      return updated;
    });

    const targetRow = activeRowIndex;
    setIsItemPickerOpen(false);
    setSelectedMedForBatch(null);
    setActiveRowIndex(null);

    // Zero-Friction: Immediately focus Qty input so cashier types number without touching mouse
    setTimeout(() => {
      const qtyInput = document.getElementById(`qty-input-${targetRow}`);
      if (qtyInput) {
        (qtyInput as HTMLInputElement).focus();
        (qtyInput as HTMLInputElement).select();
      }
    }, 80);
  };

  // Calculations for Summary and Tax Info
  const subtotal = cart.reduce((acc, row) => acc + (Number(row.quantity || 0) * Number(row.saleRate || 0)), 0);
  const totalDiscount = cart.reduce((acc, row) => {
    const gross = Number(row.quantity || 0) * Number(row.saleRate || 0);
    return acc + (gross * (Number(row.discountPercent || 0) / 100));
  }, 0);
  const taxableAmount = Math.max(0, subtotal - totalDiscount);
  // Average GST breakdown (CGST 6% + SGST 6% on taxable)
  const cgstAmount = Number((taxableAmount * 0.06).toFixed(2));
  const sgstAmount = Number((taxableAmount * 0.06).toFixed(2));
  const invoiceValue = Number((taxableAmount + cgstAmount + sgstAmount).toFixed(2));

  // Reset all billing states cleanly
  const resetBillForm = () => {
    setCart([
      {
        id: `row-${Date.now()}`,
        medicineId: "",
        medicineName: "",
        packing: "10's",
        batchId: "",
        batchNumber: "",
        expiryDate: "",
        quantity: 1,
        freeQty: 0,
        saleRate: 0,
        discountPercent: 0,
        taxRate: 12,
        amount: 0,
        availableStock: 0,
        mrp: 0,
      },
    ]);
    setSelectedCustomer(null);
    setPartyName("Cash Account");
    setPartyAddress("Local Walk-in / Counter");
    setPartyDue("0.00");
    setPartyBalance("0.00");
    setRemarks("");
    setBillNo(`SB-${Math.floor(100000 + Math.random() * 900000)}`);
    localStorage.removeItem("mcrm_pos_draft");
    setHasPosDraft(false);
  };

  // Save Invoice (F10 / F9)
  const handleSaveInvoice = async (isSaveAndNew: boolean) => {
    const validLines = cart.filter((c) => c.medicineId && c.quantity > 0);
    const unmatchedLines = cart.filter((c) => !c.medicineId && (c.medicineName?.trim()));
    if (validLines.length === 0) {
      if (unmatchedLines.length > 0) {
        setErrorMessage(
          `These medicines were not found in your inventory and cannot be billed: ${unmatchedLines.map((c) => c.medicineName).join(", ")}. Please search each medicine using the Fast Scan bar to select from stock.`
        );
      } else {
        setErrorMessage("Please enter at least one medicine item with valid quantity.");
      }
      return;
    }

    // Pre-validate for expired batches for zero-friction shopkeeper experience
    for (const line of validLines) {
      if (line.expiryDate && isBatchExpired(line.expiryDate)) {
        setErrorMessage(
          `Cannot save bill: "${line.medicineName}" has an expired batch (${line.batchNumber || "Selected"}, exp ${line.expiryDate}). Please click the batch column to select an active batch.`
        );
        return;
      }
    }

    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      const payload = {
        customerId: selectedCustomer?.id,
        customerName: selectedCustomer?.name || partyName || "Cash Account",
        items: validLines.map((c) => ({
          medicineId: c.medicineId,
          batchId: c.batchId,
          quantity: Number(c.quantity),
          unitPrice: Number(c.saleRate),
          discountAmount: (Number(c.saleRate) * Number(c.quantity) * Number(c.discountPercent || 0)) / 100,
          taxRate: c.taxRate || 12,
        })),
        payments: [
          {
            amount: invoiceValue,
            paymentMode: "CASH",
          },
        ],
      };

      const res = await apiRequest("/sales", {
        method: "POST",
        body: JSON.stringify(payload),
      });

      if (res.success && res.data) {
        setSuccessMessage(`Invoice ${res.data.invoiceNumber || billNo} saved successfully!`);
        setPrintModalInvoice(res.data);
        loadData();

        // Only reset if user explicitly clicked "Save & New" (F9); avoid unwanted empty state on standard Save
        if (isSaveAndNew) {
          resetBillForm();
          setViewMode("ENTRY");
        }
      } else {
        let msg = res.message || "Failed to save sale bill.";
        if (msg.includes("is expired and cannot be sold")) {
          msg = `Expired Batch: ${msg}. Please pick an active batch from stock.`;
        } else if (msg.includes("Insufficient stock")) {
          msg = `Stock Limit: ${msg}. Please reduce the quantity.`;
        }
        setErrorMessage(msg);
      }
    } catch (e: any) {
      setErrorMessage(e.message || "Network error while saving invoice.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Fallback Thesaurus Dictionary
  const CLIENT_SYMPTOM_MAP: Record<string, string[]> = {
    Cold: ["cold", "sardi", "jukham", "flu", "coryza", "runny", "sneezing", "cetirizine", "phenylephrine", "chlorpheniramine", "cheston", "sinarest"],
    Gas: ["gas", "acidity", "heartburn", "gerd", "bloating", "flatulence", "indigestion", "pantoprazole", "omeprazole", "pan-d", "omee", "gelusil", "digene"],
    Fever: ["fever", "bukhar", "temperature", "pyrexia", "bodyache", "paracetamol", "dolo", "calpol", "mefenamic"],
    Pain: ["pain", "dard", "headache", "sar dard", "body pain", "backache", "aceclofenac", "diclofenac", "ibuprofen", "combiflam"],
    Cough: ["cough", "khansi", "balgam", "dextromethorphan", "ambroxol", "terbutaline", "ascoril", "benadryl", "grilinctus"],
    Vomiting: ["vomiting", "ulti", "nausea", "ondansetron", "emset", "domperidone", "vomikind"],
    Diarrhea: ["diarrhea", "loose motion", "dast", "loperamide", "ofloxacin", "ornidazole", "ors", "norflox", "econorm"],
    Allergy: ["allergy", "khujli", "itching", "rash", "urticaria", "levocetirizine", "fexofenadine", "allegra", "cetirizine"],
  };

  // Filtered Medicines with Symptom Smart Search & Margin Sorting
  const filteredMedicines = medicines
    .filter((m) => {
      // 1. Text Search matching name, generic, brand, symptoms, salt composition
      const query = itemSearchQuery.trim().toLowerCase();
      let matchesText = true;
      if (query) {
        matchesText = Boolean(
          m.name.toLowerCase().includes(query) ||
          (m.genericName && m.genericName.toLowerCase().includes(query)) ||
          (m.brand && m.brand.toLowerCase().includes(query)) ||
          (m.symptoms && m.symptoms.toLowerCase().includes(query)) ||
          (m.saltComposition && m.saltComposition.toLowerCase().includes(query))
        );

        // Thesaurus synonym matching
        if (!matchesText) {
          for (const [, terms] of Object.entries(CLIENT_SYMPTOM_MAP)) {
            if (terms.some((t) => t.includes(query) || query.includes(t))) {
              const symText = `${m.symptoms || ""} ${m.name} ${m.genericName || ""}`.toLowerCase();
              if (terms.some((t) => symText.includes(t))) {
                matchesText = true;
                break;
              }
            }
          }
        }
      }

      // 2. Symptom Chip Filter
      let matchesSymptom = true;
      if (symptomFilter) {
        const terms = CLIENT_SYMPTOM_MAP[symptomFilter] || [symptomFilter.toLowerCase()];
        const targetText = `${m.symptoms || ""} ${m.name} ${m.genericName || ""} ${m.saltComposition || ""}`.toLowerCase();
        matchesSymptom = terms.some((t) => targetText.includes(t));
      }

      return matchesText && matchesSymptom;
    })
    .sort((a, b) => {
      if (sortByMargin) {
        return (b.marginPercent || 0) - (a.marginPercent || 0);
      }
      // Default: In-stock first, then high margin
      if ((a.totalStock || 0) > 0 && (b.totalStock || 0) === 0) return -1;
      if ((a.totalStock || 0) === 0 && (b.totalStock || 0) > 0) return 1;
      return (b.marginPercent || 0) - (a.marginPercent || 0);
    });

  // Filtered Invoices for List View
  const filteredInvoices = invoices.filter((inv) => {
    const invNo = (inv.invoiceNumber || "").toLowerCase();
    const customer = (inv.customer?.name || inv.customerName || "Cash Account").toLowerCase();
    const query = listSearchTerm.toLowerCase();
    return invNo.includes(query) || customer.includes(query);
  });

  return (
    <div style={{ display: "flex", flexDirection: "column", flex: 1, minHeight: "100%", backgroundColor: "#FFFFFF" }}>
      {/* Toast Notifications for Zero-Friction Cashier Feedback */}
      {(errorMessage || successMessage) && (
        <div
          style={{
            position: "fixed",
            top: "20px",
            right: "24px",
            zIndex: 9999,
            display: "flex",
            flexDirection: "column",
            gap: "10px",
            maxWidth: "460px",
            pointerEvents: "auto",
          }}
        >
          {errorMessage && (
            <div
              style={{
                backgroundColor: "#FEF2F2",
                border: "1px solid #FCA5A5",
                borderLeft: "5px solid #DC2626",
                borderRadius: "6px",
                padding: "12px 16px",
                color: "#991B1B",
                fontSize: "0.85rem",
                boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.15), 0 8px 10px -6px rgba(0, 0, 0, 0.1)",
                display: "flex",
                alignItems: "flex-start",
                gap: "10px",
              }}
            >
              <AlertCircle size={18} color="#DC2626" style={{ flexShrink: 0, marginTop: "2px" }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: "0.86rem", marginBottom: "2px", color: "#B91C1C" }}>
                  Action Needed
                </div>
                <div style={{ lineHeight: 1.4 }}>{errorMessage}</div>
              </div>
              <button
                onClick={() => setErrorMessage(null)}
                style={{
                  background: "none",
                  border: "none",
                  color: "#991B1B",
                  cursor: "pointer",
                  fontSize: "1rem",
                  padding: "0 4px",
                  lineHeight: 1,
                }}
              >
                ✕
              </button>
            </div>
          )}
          {successMessage && (
            <div
              style={{
                backgroundColor: "#F0FDF4",
                border: "1px solid #86EFAC",
                borderLeft: "5px solid #16A34A",
                borderRadius: "6px",
                padding: "12px 16px",
                color: "#166534",
                fontSize: "0.85rem",
                boxShadow: "0 10px 25px -5px rgba(0, 0, 0, 0.15), 0 8px 10px -6px rgba(0, 0, 0, 0.1)",
                display: "flex",
                alignItems: "flex-start",
                gap: "10px",
              }}
            >
              <CheckCircle2 size={18} color="#16A34A" style={{ flexShrink: 0, marginTop: "2px" }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: "0.86rem", marginBottom: "2px", color: "#15803D" }}>
                  Bill Status
                </div>
                <div style={{ lineHeight: 1.4 }}>{successMessage}</div>
              </div>
              <button
                onClick={() => setSuccessMessage(null)}
                style={{
                  background: "none",
                  border: "none",
                  color: "#166534",
                  cursor: "pointer",
                  fontSize: "1rem",
                  padding: "0 4px",
                  lineHeight: 1,
                }}
              >
                ✕
              </button>
            </div>
          )}
        </div>
      )}

      {/* ========================================================= */}
      {/* VIEW 1: SALE BILL ENTRY SCREEN (EXACT MATCH SCREEN 1)     */}
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
            {/* Left Controls: >> Toggle, Video icon, Balance & Due */}
            <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
              <button
                onClick={() => setViewMode("LIST")}
                title="Back to Sale Bill List (Esc)"
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
                title="Scan prescription or doctor slip with AI"
              >
                <Camera size={13} />
                <span>Scan Slip</span>
              </button>

              <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                <span style={{ color: "#0F172A", fontWeight: 700 }}>Balance :</span>
                <span style={{ color: "#0F766E", fontWeight: 800 }}>₹ {partyBalance}</span>
              </div>

              <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                <span style={{ color: "#0F172A", fontWeight: 700 }}>Due Amount :</span>
                <span style={{ color: "#EF4444", fontWeight: 800 }}>₹ {partyDue}</span>
              </div>

              {/* Shortage Diary Button */}
              <button
                type="button"
                onClick={() => setIsShortageDiaryOpen(true)}
                title="View Shortage Diary (Kami Register / Want Book)"
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "5px",
                  backgroundColor: shortageDiaryCount > 0 ? "#FEF2F2" : "#F8FAFC",
                  border: shortageDiaryCount > 0 ? "1px solid #FCA5A5" : "1px solid #CBD5E1",
                  color: shortageDiaryCount > 0 ? "#B91C1C" : "#475569",
                  padding: "3px 8px",
                  borderRadius: "4px",
                  fontSize: "0.75rem",
                  fontWeight: 700,
                  cursor: "pointer",
                }}
              >
                <BookOpen size={13} />
                Shortage Diary ({shortageDiaryCount})
              </button>
            </div>

            {/* Center Controls: Party Input, Bill No, Date */}
            <div style={{ display: "flex", alignItems: "center", gap: "12px", flex: 1, maxWidth: "680px" }}>
              {/* Party Autocomplete Input */}
              <div style={{ position: "relative", flex: 1 }}>
                <input
                  type="text"
                  value={partyName}
                  onChange={(e) => {
                    setPartyName(e.target.value);
                    handleSearchCustomers(e.target.value);
                    setCustomerSearchOpen(true);
                  }}
                  onFocus={() => setCustomerSearchOpen(true)}
                  placeholder="Cash Account / Search Customer"
                  style={{
                    width: "100%",
                    border: "1px solid #CBD5E1",
                    borderRadius: "4px",
                    padding: "4px 8px",
                    fontSize: "0.82rem",
                    outline: "none",
                  }}
                />
                {customerSearchOpen && (
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
                        setSelectedCustomer(null);
                        setPartyAddress("Counter Cash Walk-in");
                        setPartyBalance("0.00");
                        setPartyDue("0.00");
                        setPreviousBill("None");
                        setLastVisitOn("Today");
                        setCustomerSearchOpen(false);
                      }}
                      style={{
                        padding: "6px 10px",
                        cursor: "pointer",
                        borderBottom: "1px solid #F1F5F9",
                        fontWeight: 600,
                        color: "#0F766E",
                      }}
                    >
                      Cash Account (Counter Patient)
                    </div>
                    {customerResults.map((c) => (
                      <div
                        key={c.id}
                        onClick={() => handleSelectCustomer(c)}
                        style={{
                          padding: "6px 10px",
                          cursor: "pointer",
                          borderBottom: "1px solid #F1F5F9",
                          display: "flex",
                          justifyContent: "space-between",
                          fontSize: "0.8rem",
                        }}
                      >
                        <span style={{ fontWeight: 600 }}>{c.name}</span>
                        <span style={{ color: "#64748B" }}>{c.phone}</span>
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

            {/* Right Quick Summary Panel matching Screenshot 1 */}
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

          {/* RAPID BARCODE & SCANNER ENTRY BAR */}
          <div
            style={{
              padding: "0.4rem 0.85rem",
              backgroundColor: "#F0FDF4",
              borderBottom: "1px solid #BBF7D0",
              display: "flex",
              alignItems: "center",
              gap: "0.75rem",
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.35rem", color: "#15803D", fontWeight: 700, fontSize: "0.78rem" }}>
              <Zap size={15} />
              <span>Fast Scan (F3):</span>
            </div>
            <form onSubmit={handleBarcodeSubmit} style={{ flex: 1, display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <div style={{ position: "relative", flex: 1 }}>
                <input
                  ref={barcodeInputRef}
                  type="text"
                  value={barcodeInput}
                  onChange={(e) => setBarcodeInput(e.target.value)}
                  placeholder="Scan barcode or type medicine name / batch... (Press Enter to auto-add FEFO batch)"
                  style={{
                    width: "100%",
                    padding: "0.4rem 0.75rem 0.4rem 2rem",
                    borderRadius: "6px",
                    border: "1px solid #86EFAC",
                    backgroundColor: "#FFFFFF",
                    fontSize: "0.82rem",
                    outline: "none",
                    fontFamily: "var(--font-mono, monospace)",
                  }}
                />
                <QrCode
                  size={14}
                  color="#16A34A"
                  style={{ position: "absolute", left: "0.6rem", top: "50%", transform: "translateY(-50%)" }}
                />
              </div>
              <button
                type="submit"
                style={{
                  padding: "0.4rem 0.85rem",
                  borderRadius: "6px",
                  border: "none",
                  backgroundColor: "#16A34A",
                  color: "#FFFFFF",
                  fontSize: "0.78rem",
                  fontWeight: 700,
                  cursor: "pointer",
                  display: "inline-flex",
                  alignItems: "center",
                  gap: "0.3rem",
                  whiteSpace: "nowrap",
                }}
              >
                + Auto-Add
              </button>
            </form>
            <div style={{ fontSize: "0.72rem", color: "#166534", fontWeight: 600 }}>
              Auto-selects nearest expiring batch
            </div>
          </div>

          {/* MARG SIGNATURE BILLING GRID */}
          <div style={{ flex: 1, overflowY: "auto", borderBottom: "1px solid #CBD5E1", minHeight: "260px" }}>
            <table className="marg-grid-table">
              <thead>
                <tr>
                  <th style={{ width: "26%" }}>Particulars / Medicine</th>
                  <th style={{ width: "7%" }}>Packing</th>
                  <th style={{ width: "9%" }}>Batch</th>
                  <th style={{ width: "8%" }}>Exp. Date</th>
                  <th style={{ width: "6%", textAlign: "right" }}>Qty</th>
                  <th style={{ width: "5%", textAlign: "right" }}>Free</th>
                  <th style={{ width: "8%", textAlign: "right" }}>MRP (₹)</th>
                  <th style={{ width: "8%", textAlign: "right" }}>Rate (₹)</th>
                  <th style={{ width: "7%", textAlign: "right" }}>Disc %</th>
                  <th style={{ width: "10%", textAlign: "right" }}>₹ Amount</th>
                  <th style={{ width: "4%", textAlign: "center" }}>Act</th>
                </tr>
              </thead>
              <tbody>
                {cart.map((row, idx) => (
                  <tr key={row.id}>
                    {/* Item / Medicine Name */}
                    <td>
                      <div style={{ position: "relative" }}>
                        <input
                          id={`med-input-${idx}`}
                          type="text"
                          className="marg-grid-input"
                          placeholder="Select Medicine (Click or type)"
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
                        {row.medicineId && (
                          <div style={{ display: "flex", gap: "5px", marginTop: "2px", alignItems: "center" }}>
                            {medicines.find((m) => m.id === row.medicineId)?.locationFormatted && (
                              <span style={{ fontSize: "0.66rem", color: "#1D4ED8", backgroundColor: "#EFF6FF", padding: "1px 5px", borderRadius: "3px", fontWeight: 600 }}>
                                {medicines.find((m) => m.id === row.medicineId)?.locationFormatted}
                              </span>
                            )}
                            {medicines.find((m) => m.id === row.medicineId)?.marginPercent !== undefined && (
                              <span style={{ fontSize: "0.66rem", color: "#065F46", backgroundColor: "#ECFDF5", padding: "1px 5px", borderRadius: "3px", fontWeight: 700 }}>
                                {medicines.find((m) => m.id === row.medicineId)?.marginPercent}% Margin
                              </span>
                            )}
                          </div>
                        )}
                      </div>
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
                        readOnly
                        onClick={() => {
                          setActiveRowIndex(idx);
                          const med = medicines.find((m) => m.id === row.medicineId);
                          if (med) {
                            setSelectedMedForBatch(med);
                            setIsItemPickerOpen(true);
                          }
                        }}
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

                    {/* Qty with Enter key rapid navigation */}
                    <td>
                      <input
                        id={`qty-input-${idx}`}
                        type="number"
                        min="1"
                        className="marg-grid-input tabular-nums"
                        style={{ textAlign: "right", fontWeight: 700 }}
                        value={row.quantity}
                        onChange={(e) => handleRowChange(idx, "quantity", Number(e.target.value))}
                        onKeyDown={(e) => {
                          if (e.key === "Enter") {
                            e.preventDefault();
                            if (idx === cart.length - 1) {
                              handleAddRow();
                              setTimeout(() => {
                                const nextMedInput = document.getElementById(`med-input-${idx + 1}`);
                                if (nextMedInput) (nextMedInput as HTMLInputElement).focus();
                              }, 60);
                            } else {
                              const nextMedInput = document.getElementById(`med-input-${idx + 1}`);
                              if (nextMedInput) (nextMedInput as HTMLInputElement).focus();
                            }
                          }
                        }}
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

                    {/* MRP */}
                    <td>
                      <input
                        type="number"
                        step="0.01"
                        className="marg-grid-input tabular-nums"
                        style={{ textAlign: "right", color: "#475569" }}
                        value={row.mrp || ""}
                        onChange={(e) => handleRowChange(idx, "mrp", Number(e.target.value))}
                      />
                    </td>

                    {/* Sale Rate */}
                    <td>
                      <input
                        type="number"
                        step="0.01"
                        className="marg-grid-input tabular-nums"
                        style={{ textAlign: "right", fontWeight: 600 }}
                        value={row.saleRate}
                        onChange={(e) => handleRowChange(idx, "saleRate", Number(e.target.value))}
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
                        title="Delete item"
                      >
                        <Trash2 size={13} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Marg Bottom Panels: Remarks, Tax Info, Additional Details & Invoice Value */}
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
              <div style={{ color: "#64748B", fontSize: "0.72rem", marginBottom: "4px" }}>Narration / Remarks :</div>
              <textarea
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
                placeholder="Doctor prescription ref or patient notes..."
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

            {/* Additional Details (GST Output breakdown table) */}
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
            {/* F10 / End Save */}
            <button
              onClick={() => handleSaveInvoice(false)}
              disabled={isSubmitting}
              className="marg-btn-teal"
              title="Save Sale Bill (F10 or End)"
            >
              <span>F10 / End Save</span>
              <span style={{ borderLeft: "1px solid rgba(255,255,255,0.3)", paddingLeft: "4px" }}>▾</span>
            </button>

            {/* F9 Save & New */}
            <button
              onClick={() => handleSaveInvoice(true)}
              disabled={isSubmitting}
              className="marg-btn-teal"
              style={{ backgroundColor: "#0D9488" }}
              title="Save and Open New Bill (F9)"
            >
              <span>F9 Save & New</span>
            </button>

            {/* Save As Draft */}
            <button
              onClick={() => {
                const draft = {
                  partyName,
                  partyAddress,
                  partyBalance,
                  partyDue,
                  cart,
                  remarks,
                  savedAt: new Date().toISOString(),
                };
                localStorage.setItem("medicalcrm_pos_draft", JSON.stringify(draft));
                setHasPosDraft(true);
                setSuccessMessage("POS bill saved as draft in browser!");
              }}
              className="marg-btn-outline"
              title="Save current billing progress as draft"
            >
              <span>Save As Draft</span>
            </button>

            {hasPosDraft && (
              <button
                onClick={() => {
                  try {
                    const raw = localStorage.getItem("medicalcrm_pos_draft");
                    if (raw) {
                      const parsed = JSON.parse(raw);
                      if (parsed.partyName) setPartyName(parsed.partyName);
                      if (parsed.partyAddress) setPartyAddress(parsed.partyAddress);
                      if (Array.isArray(parsed.cart) && parsed.cart.length > 0) {
                        setCart(parsed.cart);
                      }
                      if (parsed.remarks) setRemarks(parsed.remarks);
                      setSuccessMessage("POS draft restored successfully!");
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

            {/* Esc Close */}
            <button
              onClick={() => setViewMode("LIST")}
              className="marg-btn-outline"
              title="Close and return to list (Esc)"
            >
              <span>Esc Close ✕</span>
            </button>

            {/* Last Deal */}
            <button
              onClick={() => {
                const custInvoices = invoices.filter(
                  (inv) =>
                    inv.customer?.name?.toLowerCase() === partyName.toLowerCase() ||
                    inv.customerId === selectedCustomer?.id
                );
                const last = custInvoices.length > 0 ? custInvoices[0] : invoices[0];
                if (last) {
                  setSuccessMessage(
                    `Last transaction for ${partyName}: Bill #${last.invoiceNumber} on ${formatCompactDate(
                      last.invoiceDate || last.createdAt
                    )} for ₹ ${Number(last.totalAmount || 0).toLocaleString("en-IN", {
                      minimumFractionDigits: 2,
                    })}`
                  );
                } else {
                  setSuccessMessage(`No previous transactions found for ${partyName}`);
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
      {/* VIEW 2: SALE BILL LIST SCREEN (EXACT MATCH SCREEN 3)      */}
      {/* ========================================================= */}
      {viewMode === "LIST" && (
        <div style={{ display: "flex", flexDirection: "column", flex: 1, minHeight: "100%" }}>
          {/* Header Row: Title, Watch Video, + Create/F2 */}
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
                Sale Bill List
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
                <Sparkles size={11} /> AI Scan Ready
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
                title="Scan prescription or bill slip with AI"
              >
                <Camera size={14} />
                <span>Scan Slip</span>
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

          {/* Filter Bar: Search, Today Dropdown, Filter Button */}
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
              {/* Search here input */}
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

              {/* Date Range Selector */}
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

              {/* F10 Filter button */}
              <button
                onClick={() => alert("Filter drawer: Filter by customer, payment mode, or station")}
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
              Total Bills: <strong style={{ color: "#0F172A" }}>{filteredInvoices.length}</strong>
            </div>
          </div>

          {/* Data Table: Exactly matching Screenshot 3 */}
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
                {filteredInvoices.length === 0 ? (
                  <tr>
                    <td colSpan={8} style={{ textAlign: "center", padding: "3rem", color: "#64748B" }}>
                      No bills found. Click <strong>+ Create/F2</strong> to issue a new bill.
                    </td>
                  </tr>
                ) : (
                  filteredInvoices.map((inv, idx) => {
                    const isSelected = selectedInvoiceId === inv.id;
                    const dateFormatted = formatCompactDate(inv.createdAt || inv.invoiceDate || new Date());
                    const party = inv.customer?.name || inv.customerName || "Cash Account";
                    const amt = Number(inv.netPayable || inv.totalAmount || 0);

                    return (
                      <tr
                        key={inv.id || idx}
                        onClick={() => setSelectedInvoiceId(inv.id)}
                        onDoubleClick={() => {
                          setBillNo(inv.invoiceNumber);
                          setPartyName(party);
                          setViewMode("ENTRY");
                        }}
                        style={{
                          backgroundColor: isSelected ? "#FEF3C7" : undefined, // Signature Marg highlight row!
                          cursor: "pointer",
                        }}
                      >
                        {/* Checkbox */}
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

                        {/* Invoice No */}
                        <td style={{ fontWeight: 700, color: "#0F172A" }}>
                          .. {inv.invoiceNumber || `INV-000${idx + 1}`}
                        </td>

                        {/* Date */}
                        <td style={{ color: "#334155" }}>
                          {dateFormatted}
                        </td>

                        {/* Party */}
                        <td style={{ fontWeight: 600, color: "#1E293B" }}>
                          {party}
                        </td>

                        {/* Station */}
                        <td style={{ color: "#64748B" }}>
                          {inv.station || "Counter"}
                        </td>

                        {/* Status */}
                        <td>
                          <span style={{ color: "#15803D", fontWeight: 700, fontSize: "0.78rem" }}>
                            Paid
                          </span>
                        </td>

                        {/* Amount */}
                        <td style={{ textAlign: "right", fontWeight: 800, color: "#0F172A" }}>
                          {amt.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </td>

                        {/* Action Icons: Edit, Print, 3-dots */}
                        <td style={{ textAlign: "center" }}>
                          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "6px" }}>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setBillNo(inv.invoiceNumber);
                                setPartyName(party);
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
                                setPrintModalInvoice(inv);
                              }}
                              style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", padding: "2px" }}
                              title="Print Bill"
                            >
                              <Printer size={13} />
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                handleOpenSalesReturn(inv);
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
                              title="Customer Sales Return"
                            >
                              Return
                            </button>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                setPrintModalInvoice(inv);
                              }}
                              style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", padding: "2px" }}
                              title="Print & Details"
                            >
                              <MoreVertical size={13} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Bottom Audit Details Bar: Exact match Screenshot 3 */}
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
                No.Of Bills : <strong style={{ color: "#0F172A" }}>{filteredInvoices.length}</strong>
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

      {/* ========================================================= */}
      {/* MARG ITEM & BATCH SELECTOR POPUP MODAL                    */}
      {/* ========================================================= */}
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
          onClick={() => {
            setIsItemPickerOpen(false);
            setSelectedMedForBatch(null);
          }}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "10px",
              width: "920px",
              maxWidth: "96vw",
              maxHeight: "88vh",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.25)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Professional Clean Header */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "12px 18px",
                backgroundColor: "#0F172A",
                color: "#FFFFFF",
              }}
            >
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                  {selectedMedForBatch && (
                    <button
                      type="button"
                      onClick={() => setSelectedMedForBatch(null)}
                      style={{
                        background: "rgba(255, 255, 255, 0.15)",
                        border: "none",
                        color: "#FFFFFF",
                        padding: "3px 8px",
                        borderRadius: "4px",
                        fontSize: "0.75rem",
                        cursor: "pointer",
                        fontWeight: 600,
                      }}
                    >
                      ← Back
                    </button>
                  )}
                  <span style={{ fontWeight: 700, fontSize: "0.95rem", letterSpacing: "-0.01em" }}>
                    {selectedMedForBatch ? `Select Batch: ${selectedMedForBatch.name}` : "Product & Medicine Catalog"}
                  </span>
                </div>
                <div style={{ fontSize: "0.72rem", color: "#94A3B8", marginTop: "2px" }}>
                  {selectedMedForBatch
                    ? `Choose batch for billing (${selectedMedForBatch.genericName || "Standard formulation"})`
                    : "Search by product name, generic molecule, or therapeutic symptom category"}
                </div>
              </div>
              <button
                onClick={() => {
                  setIsItemPickerOpen(false);
                  setSelectedMedForBatch(null);
                }}
                style={{
                  background: "rgba(255, 255, 255, 0.1)",
                  border: "none",
                  color: "#FFFFFF",
                  width: "28px",
                  height: "28px",
                  borderRadius: "6px",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: "0.85rem",
                }}
              >
                ✕
              </button>
            </div>

            {/* Search Input & Clean Symptom Filter Bar */}
            {!selectedMedForBatch && (
              <div style={{ padding: "12px 18px", borderBottom: "1px solid #E2E8F0", backgroundColor: "#F8FAFC" }}>
                <div style={{ display: "flex", gap: "10px", alignItems: "center", marginBottom: "10px" }}>
                  <div style={{ position: "relative", flex: 1 }}>
                    <input
                      type="text"
                      placeholder="Type medicine name (e.g. Paracetamol, Dolo, Pan-D)... Press Enter to 1-click select"
                      value={itemSearchQuery}
                      onChange={(e) => setItemSearchQuery(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter" && filteredMedicines.length > 0) {
                          e.preventDefault();
                          handleSelectMedicine(filteredMedicines[0]);
                        }
                      }}
                      autoFocus
                      style={{
                        width: "100%",
                        padding: "8px 12px 8px 34px",
                        border: "1px solid #CBD5E1",
                        borderRadius: "6px",
                        fontSize: "0.85rem",
                        outline: "none",
                        backgroundColor: "#FFFFFF",
                        color: "#0F172A",
                      }}
                    />
                    <Search size={16} color="#64748B" style={{ position: "absolute", left: "10px", top: "10px" }} />
                  </div>

                  {/* Margin Sorting Toggle */}
                  <button
                    type="button"
                    onClick={() => setSortByMargin((prev) => !prev)}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "6px",
                      backgroundColor: sortByMargin ? "#ECFDF5" : "#FFFFFF",
                      border: sortByMargin ? "1px solid #059669" : "1px solid #CBD5E1",
                      color: sortByMargin ? "#065F46" : "#475569",
                      padding: "8px 12px",
                      borderRadius: "6px",
                      fontSize: "0.78rem",
                      fontWeight: 600,
                      cursor: "pointer",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {sortByMargin ? "High Margin Sorted" : "Sort by Margin"}
                  </button>
                </div>

                {/* Clean Professional Category / Symptom Filter Chips */}
                <div style={{ display: "flex", gap: "6px", overflowX: "auto", paddingBottom: "2px", alignItems: "center" }}>
                  <span style={{ fontSize: "0.74rem", color: "#64748B", fontWeight: 700, whiteSpace: "nowrap", marginRight: "4px" }}>
                    Categories:
                  </span>
                  {[
                    { label: "All Products", value: null },
                    { label: "Cold & Flu", value: "Cold" },
                    { label: "Gas & Acidity", value: "Gas" },
                    { label: "Fever & Pain", value: "Fever" },
                    { label: "Cough", value: "Cough" },
                    { label: "Pain Relief", value: "Pain" },
                    { label: "Vomiting & Nausea", value: "Vomiting" },
                    { label: "Diarrhea", value: "Diarrhea" },
                    { label: "Allergy", value: "Allergy" },
                  ].map((chip) => (
                    <button
                      key={chip.label}
                      type="button"
                      onClick={() => setSymptomFilter(chip.value)}
                      style={{
                        padding: "3px 10px",
                        borderRadius: "16px",
                        fontSize: "0.73rem",
                        fontWeight: symptomFilter === chip.value ? 700 : 500,
                        backgroundColor: symptomFilter === chip.value ? "#0F766E" : "#FFFFFF",
                        color: symptomFilter === chip.value ? "#FFFFFF" : "#334155",
                        border: symptomFilter === chip.value ? "1px solid #0F766E" : "1px solid #E2E8F0",
                        cursor: "pointer",
                        whiteSpace: "nowrap",
                        transition: "all 0.15s ease",
                      }}
                    >
                      {chip.label}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Content List */}
            <div style={{ flex: 1, overflowY: "auto", padding: "0" }}>
              {!selectedMedForBatch ? (
                /* Medicine Catalog List */
                <table className="marg-grid-table" style={{ width: "100%", borderCollapse: "collapse" }}>
                  <thead>
                    <tr style={{ backgroundColor: "#F8FAFC", borderBottom: "1px solid #E2E8F0" }}>
                      <th style={{ width: "32%", padding: "8px 12px", textAlign: "left", fontSize: "0.75rem", color: "#475569" }}>Product & Location</th>
                      <th style={{ width: "24%", padding: "8px 12px", textAlign: "left", fontSize: "0.75rem", color: "#475569" }}>Generic Formula</th>
                      <th style={{ width: "12%", padding: "8px 12px", textAlign: "center", fontSize: "0.75rem", color: "#475569" }}>Margin</th>
                      <th style={{ width: "14%", padding: "8px 12px", textAlign: "center", fontSize: "0.75rem", color: "#475569" }}>Stock Status</th>
                      <th style={{ width: "10%", padding: "8px 12px", textAlign: "right", fontSize: "0.75rem", color: "#475569" }}>MRP</th>
                      <th style={{ width: "8%", padding: "8px 12px", textAlign: "center", fontSize: "0.75rem", color: "#475569" }}>Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredMedicines.length === 0 ? (
                      <tr>
                        <td colSpan={6} style={{ textAlign: "center", padding: "40px 16px", color: "#64748B" }}>
                          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "6px" }}>
                            <span style={{ fontWeight: 700, fontSize: "0.92rem", color: "#1E293B" }}>
                              {medicines.length === 0 ? "Loading medicine catalog..." : "No medicines found"}
                            </span>
                            <span style={{ fontSize: "0.78rem" }}>
                              {medicines.length === 0
                                ? "Fetching inventory and master records..."
                                : `No items matching "${itemSearchQuery}". Check spelling or try a generic name.`}
                            </span>
                          </div>
                        </td>
                      </tr>
                    ) : (
                      filteredMedicines.map((m) => {
                        const totalStock = m.totalStock ?? 0;
                        const isOutOfStock = totalStock === 0;
                        const isLowStock = totalStock > 0 && totalStock <= 5;
                        const margin = m.marginPercent ?? 20;

                        return (
                          <tr
                            key={m.id}
                            onClick={() => handleSelectMedicine(m)}
                            style={{
                              cursor: "pointer",
                              borderBottom: "1px solid #F1F5F9",
                              backgroundColor: isOutOfStock ? "#FAFAFA" : "#FFFFFF",
                            }}
                          >
                            {/* Product Name & Clean Location */}
                            <td style={{ padding: "8px 12px" }}>
                              <div style={{ display: "flex", flexDirection: "column", gap: "2px" }}>
                                <span style={{ fontWeight: 700, color: "#0F172A", fontSize: "0.84rem" }}>
                                  {m.name}
                                </span>
                                <span
                                  style={{
                                    fontSize: "0.68rem",
                                    color: "#1E40AF",
                                    backgroundColor: "#EFF6FF",
                                    border: "1px solid #DBEAFE",
                                    padding: "1px 6px",
                                    borderRadius: "3px",
                                    fontWeight: 600,
                                    width: "fit-content",
                                  }}
                                >
                                  {m.locationFormatted || `Rack ${m.rack || "A"} • Shelf ${m.shelf || "1"} • Box ${m.box || "01"}`}
                                </span>
                              </div>
                            </td>

                            {/* Generic Molecule */}
                            <td style={{ padding: "8px 12px" }}>
                              <div style={{ fontSize: "0.75rem", color: "#475569" }}>
                                {m.saltComposition || m.genericName || "—"}
                              </div>
                            </td>

                            {/* Clean Margin Badge (No emojis) */}
                            <td style={{ padding: "8px 12px", textAlign: "center" }}>
                              <span
                                style={{
                                  backgroundColor: margin >= 25 ? "#ECFDF5" : "#F1F5F9",
                                  color: margin >= 25 ? "#065F46" : "#475569",
                                  border: margin >= 25 ? "1px solid #A7F3D0" : "1px solid #E2E8F0",
                                  padding: "2px 6px",
                                  borderRadius: "4px",
                                  fontSize: "0.72rem",
                                  fontWeight: 700,
                                  whiteSpace: "nowrap",
                                }}
                              >
                                {margin}% Margin
                              </span>
                            </td>

                            {/* Clean Stock Status Badge (No emojis) */}
                            <td style={{ padding: "8px 12px", textAlign: "center" }}>
                              <span
                                style={{
                                  backgroundColor: isOutOfStock ? "#FEF2F2" : isLowStock ? "#FEF3C7" : "#ECFDF5",
                                  color: isOutOfStock ? "#DC2626" : isLowStock ? "#B45309" : "#047857",
                                  border: isOutOfStock ? "1px solid #FCA5A5" : isLowStock ? "1px solid #FDE68A" : "1px solid #A7F3D0",
                                  padding: "2px 8px",
                                  borderRadius: "12px",
                                  fontSize: "0.72rem",
                                  fontWeight: 700,
                                  whiteSpace: "nowrap",
                                }}
                              >
                                {isOutOfStock
                                  ? "Out of Stock"
                                  : isLowStock
                                  ? `Low Stock (${totalStock})`
                                  : `In Stock (${totalStock})`}
                              </span>
                            </td>

                            {/* MRP */}
                            <td style={{ padding: "8px 12px", fontWeight: 700, textAlign: "right", color: "#0F172A", fontSize: "0.84rem" }}>
                              ₹ {Number(m.mrp || 0).toFixed(2)}
                            </td>

                            {/* Action Buttons: Always allow Select */}
                            <td style={{ padding: "8px 12px", textAlign: "center" }}>
                              <div style={{ display: "flex", gap: "4px", justifyContent: "center" }}>
                                <button
                                  type="button"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleSelectMedicine(m);
                                  }}
                                  style={{
                                    padding: "3px 10px",
                                    fontSize: "0.72rem",
                                    backgroundColor: "#0F766E",
                                    color: "#FFFFFF",
                                    border: "none",
                                    borderRadius: "4px",
                                    fontWeight: 700,
                                    cursor: "pointer",
                                    whiteSpace: "nowrap",
                                  }}
                                  title="1-Click Auto-Select best active batch"
                                >
                                  Select
                                </button>
                                {m.batches && m.batches.length > 1 && (
                                  <button
                                    type="button"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      setSelectedMedForBatch(m);
                                    }}
                                    style={{
                                      padding: "3px 6px",
                                      fontSize: "0.7rem",
                                      backgroundColor: "#F1F5F9",
                                      color: "#334155",
                                      border: "1px solid #CBD5E1",
                                      borderRadius: "4px",
                                      fontWeight: 600,
                                      cursor: "pointer",
                                      whiteSpace: "nowrap",
                                    }}
                                    title="Choose specific batch"
                                  >
                                    Batches ({m.batches.length})
                                  </button>
                                )}
                                {isOutOfStock && (
                                  <button
                                    type="button"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleOpenSubstitutes(m);
                                    }}
                                    style={{
                                      padding: "3px 6px",
                                      fontSize: "0.7rem",
                                      backgroundColor: "#FEF3C7",
                                      color: "#92400E",
                                      border: "1px solid #FCD34D",
                                      borderRadius: "4px",
                                      fontWeight: 600,
                                      cursor: "pointer",
                                      whiteSpace: "nowrap",
                                    }}
                                    title="Search salt-equivalent alternatives"
                                  >
                                    Substitutes
                                  </button>
                                )}
                              </div>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              ) : (
                /* Batches for Selected Medicine */
                <div style={{ padding: "12px 16px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "10px" }}>
                    <div>
                      <span style={{ fontWeight: 700, fontSize: "0.9rem", color: "#0F172A" }}>
                        Available Batches for {selectedMedForBatch.name}
                      </span>
                      <span style={{ marginLeft: "8px", fontSize: "0.75rem", color: "#64748B" }}>
                        Total Stock: {selectedMedForBatch.totalStock || 0} units
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        const futureDate = new Date();
                        futureDate.setFullYear(futureDate.getFullYear() + 2);
                        applyBatchToActiveRow(selectedMedForBatch, {
                          id: `batch-${Date.now()}`,
                          medicineId: selectedMedForBatch.id,
                          batchNumber: "NEW-01",
                          expiryDate: formatCompactDate(futureDate),
                          rawExpiryDate: futureDate.toISOString(),
                          isExpired: false,
                          quantity: 10,
                          mrp: selectedMedForBatch.mrp || 0,
                          sellingPrice: selectedMedForBatch.sellingPrice || selectedMedForBatch.mrp || 0,
                          purchasePrice: selectedMedForBatch.purchasePrice || selectedMedForBatch.purchaseRate || 0,
                        });
                      }}
                      style={{
                        padding: "4px 10px",
                        fontSize: "0.72rem",
                        backgroundColor: "#F1F5F9",
                        color: "#334155",
                        border: "1px solid #CBD5E1",
                        borderRadius: "4px",
                        cursor: "pointer",
                        fontWeight: 600,
                      }}
                    >
                      + Add Custom Batch
                    </button>
                  </div>

                  <table className="marg-grid-table" style={{ width: "100%", borderCollapse: "collapse" }}>
                    <thead>
                      <tr style={{ backgroundColor: "#F8FAFC", borderBottom: "1px solid #E2E8F0" }}>
                        <th style={{ padding: "8px", textAlign: "left", fontSize: "0.75rem", color: "#475569" }}>Batch No.</th>
                        <th style={{ padding: "8px", textAlign: "left", fontSize: "0.75rem", color: "#475569" }}>Expiry</th>
                        <th style={{ padding: "8px", textAlign: "right", fontSize: "0.75rem", color: "#475569" }}>Stock Available</th>
                        <th style={{ padding: "8px", textAlign: "right", fontSize: "0.75rem", color: "#475569" }}>MRP</th>
                        <th style={{ padding: "8px", textAlign: "right", fontSize: "0.75rem", color: "#475569" }}>Sale Rate</th>
                        <th style={{ padding: "8px", textAlign: "center", fontSize: "0.75rem", color: "#475569" }}>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {(!selectedMedForBatch.batches || selectedMedForBatch.batches.length === 0) ? (
                        <tr>
                          <td colSpan={6} style={{ textAlign: "center", padding: "24px 8px", color: "#64748B" }}>
                            No existing batch records. Click "+ Add Custom Batch" or "Select" to bill this item.
                          </td>
                        </tr>
                      ) : (
                        selectedMedForBatch.batches.map((b) => {
                          const isExpired = b.isExpired || isBatchExpired(b.rawExpiryDate || b.expiryDate);
                          return (
                            <tr
                              key={b.id}
                              onClick={() => {
                                if (isExpired) {
                                  setErrorMessage(`Batch ${b.batchNumber} expired on ${b.expiryDate} and cannot be sold.`);
                                  return;
                                }
                                applyBatchToActiveRow(selectedMedForBatch, b);
                              }}
                              style={{
                                cursor: isExpired ? "not-allowed" : "pointer",
                                borderBottom: "1px solid #F1F5F9",
                                backgroundColor: isExpired ? "#FFF5F5" : "transparent",
                                opacity: isExpired ? 0.7 : 1,
                              }}
                            >
                              <td style={{ padding: "8px", fontWeight: 700, color: "#0F172A" }}>{b.batchNumber}</td>
                              <td style={{ padding: "8px", color: isExpired ? "#DC2626" : "#334155" }}>
                                <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                                  <span style={{ fontWeight: isExpired ? 700 : 500 }}>{b.expiryDate}</span>
                                  {isExpired && (
                                    <span
                                      style={{
                                        backgroundColor: "#FEE2E2",
                                        color: "#DC2626",
                                        fontSize: "0.68rem",
                                        padding: "1px 6px",
                                        borderRadius: "4px",
                                        fontWeight: 700,
                                      }}
                                    >
                                      Expired
                                    </span>
                                  )}
                                </div>
                              </td>
                              <td style={{ padding: "8px", textAlign: "right", fontWeight: 700, color: !isExpired && b.quantity > 0 ? "#0F766E" : "#DC2626" }}>
                                {b.quantity}
                              </td>
                              <td style={{ padding: "8px", textAlign: "right" }}>₹ {Number(b.mrp || 0).toFixed(2)}</td>
                              <td style={{ padding: "8px", textAlign: "right", fontWeight: 700, color: "#0F172A" }}>
                                ₹ {Number(b.sellingPrice || 0).toFixed(2)}
                              </td>
                              <td style={{ padding: "8px", textAlign: "center" }}>
                                <button
                                  type="button"
                                  disabled={isExpired || b.quantity <= 0}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (isExpired) {
                                      setErrorMessage(`Batch ${b.batchNumber} expired on ${b.expiryDate} and cannot be sold.`);
                                      return;
                                    }
                                    applyBatchToActiveRow(selectedMedForBatch, b);
                                  }}
                                  className={isExpired || b.quantity <= 0 ? "marg-btn-disabled" : "marg-btn-teal"}
                                  style={{
                                    padding: "3px 10px",
                                    fontSize: "0.72rem",
                                    borderRadius: "4px",
                                    opacity: isExpired || b.quantity <= 0 ? 0.5 : 1,
                                    cursor: isExpired || b.quantity <= 0 ? "not-allowed" : "pointer",
                                    backgroundColor: isExpired ? "#94A3B8" : undefined,
                                  }}
                                >
                                  {isExpired ? "Expired" : "Select"}
                                </button>
                              </td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* INSTANT SALT-EQUIVALENT ENGINE (RED ALERT & SUBSTITUTE)   */}
      {/* ========================================================= */}
      {isSubstituteModalOpen && substituteModalData && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(3px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 150,
          }}
          onClick={() => setIsSubstituteModalOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "12px",
              width: "720px",
              maxWidth: "94vw",
              maxHeight: "88vh",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.35)",
              border: "2px solid #EF4444",
              overflow: "hidden",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Red Alert Header */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "12px 18px",
                backgroundColor: "#DC2626",
                color: "#FFFFFF",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                <AlertTriangle size={22} color="#FFFFFF" />
                <div>
                  <div style={{ fontWeight: 800, fontSize: "0.98rem" }}>
                    OUT OF STOCK ALERT: {substituteModalData.targetMedicine?.name}
                  </div>
                  <div style={{ fontSize: "0.78rem", opacity: 0.9 }}>
                    Current Stock: 0 Units • Location: {substituteModalData.targetMedicine?.locationFormatted || "Rack A-2"} • Auto-logged to Shortage Diary
                  </div>
                </div>
              </div>
              <button
                onClick={() => setIsSubstituteModalOpen(false)}
                style={{ background: "none", border: "none", color: "#FFFFFF", fontSize: "1.2rem", cursor: "pointer" }}
              >
                ✕
              </button>
            </div>

            {/* Instant In-Stock Substitutes Body */}
            <div style={{ padding: "16px", overflowY: "auto", flex: 1, backgroundColor: "#F8FAFC" }}>
              <div
                style={{
                  backgroundColor: "#FEF2F2",
                  borderLeft: "4px solid #EF4444",
                  padding: "10px 14px",
                  borderRadius: "6px",
                  marginBottom: "14px",
                  fontSize: "0.84rem",
                  color: "#991B1B",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <div>
                  <strong>Zero Customer Loss Engine:</strong> Same Active Molecule / Formula found in ready stock!
                </div>
                <span style={{ fontSize: "0.75rem", backgroundColor: "#FEE2E2", padding: "2px 8px", borderRadius: "12px", fontWeight: 700 }}>
                  {substituteModalData.substitutes?.length || 0} Alternatives
                </span>
              </div>

              {substituteModalData.substitutes?.length === 0 ? (
                <div style={{ textAlign: "center", padding: "2rem", color: "#64748B" }}>
                  <p style={{ fontWeight: 600, fontSize: "0.9rem" }}>No direct salt substitute in stock right now.</p>
                  <p style={{ fontSize: "0.8rem", marginTop: "4px" }}>Item has been registered in the Shortage Diary for procurement.</p>
                </div>
              ) : (
                <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                  {substituteModalData.substitutes?.map((sub: any) => (
                    <div
                      key={sub.id}
                      style={{
                        backgroundColor: "#FFFFFF",
                        border: "1px solid #CBD5E1",
                        borderRadius: "8px",
                        padding: "14px",
                        boxShadow: "0 2px 4px rgba(0,0,0,0.04)",
                        display: "flex",
                        flexDirection: "column",
                        gap: "8px",
                      }}
                    >
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                        <div>
                          <div style={{ display: "flex", alignItems: "center", gap: "8px", flexWrap: "wrap" }}>
                            <span style={{ fontWeight: 800, fontSize: "0.95rem", color: "#0F172A" }}>
                              {sub.name}
                            </span>
                            <span
                              style={{
                                backgroundColor: "#ECFDF5",
                                color: "#047857",
                                border: "1px solid #A7F3D0",
                                padding: "2px 7px",
                                borderRadius: "4px",
                                fontSize: "0.72rem",
                                fontWeight: 800,
                              }}
                            >
                              {sub.marginPercent || 32}% Margin
                            </span>
                            <span
                              style={{
                                backgroundColor: (sub.totalStock || 0) > 5 ? "#ECFDF5" : "#FEF3C7",
                                color: (sub.totalStock || 0) > 5 ? "#065F46" : "#92400E",
                                padding: "2px 7px",
                                borderRadius: "4px",
                                fontSize: "0.72rem",
                                fontWeight: 700,
                              }}
                            >
                              Qty: {sub.totalStock || 18} In Stock
                            </span>
                          </div>

                          <div style={{ fontSize: "0.78rem", color: "#475569", marginTop: "3px" }}>
                            <strong>Same Salt Formula:</strong> {sub.saltComposition || sub.genericName}
                          </div>

                          <div style={{ fontSize: "0.76rem", color: "#1D4ED8", marginTop: "3px", fontWeight: 600 }}>
                            Physical Location: {sub.location?.formatted || "Rack A • Shelf 2 • Box 09"}
                          </div>
                        </div>

                        {/* Price & Savings */}
                        <div style={{ textAlign: "right" }}>
                          <div style={{ fontSize: "1.05rem", fontWeight: 800, color: "#0F172A" }}>
                            ₹ {Number(sub.sellingPrice || sub.mrp || 0).toFixed(2)}
                          </div>
                          {sub.isCheaper && (
                            <div
                              style={{
                                fontSize: "0.76rem",
                                color: "#059669",
                                fontWeight: 800,
                                backgroundColor: "#ECFDF5",
                                padding: "2px 6px",
                                borderRadius: "4px",
                                marginTop: "2px",
                              }}
                            >
                              ₹{Math.abs(sub.priceDifference || 35.5).toFixed(1)} Sasta! (vs ₹{Number(substituteModalData.targetMedicine?.mrp || 0).toFixed(2)})
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Chemist Pitch Script Highlight Box */}
                      <div
                        style={{
                          backgroundColor: "#F0FDF4",
                          border: "1px dashed #86EFAC",
                          borderRadius: "6px",
                          padding: "8px 12px",
                          fontSize: "0.82rem",
                          color: "#166534",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "space-between",
                          marginTop: "2px",
                          gap: "8px",
                          flexWrap: "wrap",
                        }}
                      >
                        <div>
                          <span style={{ fontWeight: 800, marginRight: "6px" }}>Chemist Pitch:</span>
                          <em>"{sub.pitchScript || `Sir same formula hai, ₹${Math.abs(sub.priceDifference || 35.5).toFixed(0)} sasta bhi hai aur ready stock me hai!`}"</em>
                        </div>
                        <button
                          type="button"
                          onClick={() => handleSwapSubstitute(sub)}
                          style={{
                            backgroundColor: "#059669",
                            color: "#FFFFFF",
                            border: "none",
                            borderRadius: "6px",
                            padding: "6px 14px",
                            fontWeight: 800,
                            fontSize: "0.78rem",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            gap: "5px",
                            whiteSpace: "nowrap",
                            boxShadow: "0 2px 5px rgba(5, 150, 105, 0.3)",
                          }}
                        >
                          <Zap size={14} />
                          Swap into Bill
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Footer */}
            <div
              style={{
                padding: "10px 16px",
                borderTop: "1px solid #E2E8F0",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                backgroundColor: "#FFFFFF",
              }}
            >
              <span style={{ fontSize: "0.75rem", color: "#64748B" }}>
                Press Esc or Close to return without substitution
              </span>
              <button
                type="button"
                onClick={() => setIsSubstituteModalOpen(false)}
                style={{
                  padding: "6px 14px",
                  borderRadius: "6px",
                  border: "1px solid #CBD5E1",
                  backgroundColor: "#FFFFFF",
                  fontSize: "0.8rem",
                  fontWeight: 600,
                  cursor: "pointer",
                }}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* SHORTAGE DIARY (KAMI REGISTER / WANT BOOK) MODAL           */}
      {/* ========================================================= */}
      {isShortageDiaryOpen && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 160,
          }}
          onClick={() => setIsShortageDiaryOpen(false)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "10px",
              width: "780px",
              maxWidth: "94vw",
              maxHeight: "85vh",
              display: "flex",
              flexDirection: "column",
              boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.3)",
              border: "1px solid #CBD5E1",
              overflow: "hidden",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "10px 16px",
                backgroundColor: "#0F766E",
                color: "#FFFFFF",
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <BookOpen size={20} color="#FFFFFF" />
                <span style={{ fontWeight: 800, fontSize: "0.92rem" }}>
                  Shortage Diary (Kami Register / Want Book)
                </span>
                <span
                  style={{
                    backgroundColor: "#CCFBF1",
                    color: "#0F766E",
                    padding: "1px 8px",
                    borderRadius: "12px",
                    fontSize: "0.72rem",
                    fontWeight: 800,
                  }}
                >
                  {shortageDiaryItems.length} Depleted Items
                </span>
              </div>
              <button
                type="button"
                onClick={() => setIsShortageDiaryOpen(false)}
                style={{ background: "none", border: "none", color: "#FFFFFF", fontSize: "1.1rem", cursor: "pointer" }}
              >
                ✕
              </button>
            </div>

            {/* Content Table */}
            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
              {shortageDiaryItems.length === 0 ? (
                <div style={{ textAlign: "center", padding: "3rem 1rem", color: "#64748B" }}>
                  <p style={{ fontWeight: 600 }}>No active shortage items logged!</p>
                  <p style={{ fontSize: "0.78rem" }}>When items run out of stock during billing, they auto-record here.</p>
                </div>
              ) : (
                <table className="marg-grid-table">
                  <thead>
                    <tr>
                      <th>Medicine Name</th>
                      <th>Generic Formula</th>
                      <th style={{ textAlign: "center" }}>Customer Inquiries</th>
                      <th style={{ textAlign: "center" }}>Current Stock</th>
                      <th>Location</th>
                      <th style={{ textAlign: "center" }}>Reorder Qty</th>
                      <th style={{ textAlign: "center" }}>Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {shortageDiaryItems.map((item) => (
                      <tr key={item.id}>
                        <td style={{ fontWeight: 700, color: "#0F172A" }}>{item.medicineName}</td>
                        <td style={{ color: "#64748B", fontSize: "0.75rem" }}>{item.genericName}</td>
                        <td style={{ textAlign: "center" }}>
                          <span
                            style={{
                              backgroundColor: "#FEE2E2",
                              color: "#B91C1C",
                              padding: "2px 8px",
                              borderRadius: "10px",
                              fontWeight: 800,
                              fontSize: "0.74rem",
                            }}
                          >
                            {item.customerCount} requests
                          </span>
                        </td>
                        <td style={{ textAlign: "center" }}>
                          <span
                            style={{
                              backgroundColor: (item.currentStock || 0) === 0 ? "#FEF2F2" : "#FEF3C7",
                              color: (item.currentStock || 0) === 0 ? "#DC2626" : "#B45309",
                              padding: "2px 6px",
                              borderRadius: "4px",
                              fontWeight: 700,
                              fontSize: "0.72rem",
                            }}
                          >
                            {(item.currentStock || 0) === 0 ? "Khatam (0)" : `${item.currentStock} left`}
                          </span>
                        </td>
                        <td style={{ fontSize: "0.74rem", color: "#1D4ED8", fontWeight: 600 }}>
                          {item.rackLocation || "Rack A • Shelf 2"}
                        </td>
                        <td style={{ textAlign: "center", fontWeight: 700 }}>
                          {item.suggestedReorderQty || 30}
                        </td>
                        <td style={{ textAlign: "center" }}>
                          <button
                            type="button"
                            onClick={() => {
                              setSuccessMessage(`Order requisition placed for ${item.medicineName} (${item.suggestedReorderQty || 30} units) to stockist!`);
                              setShortageDiaryItems((prev) => prev.filter((i) => i.id !== item.id));
                              setShortageDiaryCount((c) => Math.max(0, c - 1));
                            }}
                            className="marg-btn-teal"
                            style={{ padding: "2px 8px", fontSize: "0.72rem" }}
                          >
                            Order Now
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>

            {/* Footer */}
            <div
              style={{
                padding: "8px 16px",
                borderTop: "1px solid #CBD5E1",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                backgroundColor: "#F8FAFC",
              }}
            >
              <span style={{ fontSize: "0.74rem", color: "#64748B" }}>
                Auto-updated whenever walk-in inquiries or counter billing hits depleted stock.
              </span>
              <button
                type="button"
                onClick={() => setIsShortageDiaryOpen(false)}
                style={{
                  padding: "4px 12px",
                  borderRadius: "4px",
                  border: "1px solid #CBD5E1",
                  backgroundColor: "#FFFFFF",
                  fontSize: "0.78rem",
                  fontWeight: 600,
                  cursor: "pointer",
                }}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* THERMAL PRINT SLIP MODAL                                  */}
      {/* ========================================================= */}
      {printModalInvoice && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            backgroundColor: "rgba(15, 23, 42, 0.6)",
            backdropFilter: "blur(2px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 999,
          }}
          onClick={() => setPrintModalInvoice(null)}
        >
          <div
            style={{
              backgroundColor: "#FFFFFF",
              borderRadius: "10px",
              width: "400px",
              maxWidth: "92vw",
              padding: "1.25rem",
              boxShadow: "0 20px 25px -5px rgba(0,0,0,0.2)",
              border: "1px solid #CBD5E1",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
              <h3 style={{ fontSize: "1rem", fontWeight: 800, margin: 0, color: "#0F172A" }}>
                Invoice Print Preview
              </h3>
              <button onClick={() => setPrintModalInvoice(null)} style={{ background: "none", border: "none", cursor: "pointer" }}>✕</button>
            </div>

            <div
              id="thermal-print-slip"
              style={{
                border: "1px dashed #CBD5E1",
                padding: "12px",
                fontFamily: "monospace",
                fontSize: "0.75rem",
                color: "#000000",
                backgroundColor: "#FFFDF9",
              }}
            >
              <div style={{ textAlign: "center", fontWeight: "bold", fontSize: "0.9rem" }}>
                PHRMA WHOLSL (PHWH)
              </div>
              <div style={{ textAlign: "center", fontSize: "0.68rem" }}>
                Licensed Pharmacy ERP • GSTIN: 27AAAAA0000A1Z5
              </div>
              <div style={{ borderBottom: "1px dashed #000", margin: "6px 0" }} />
              <div>Bill No: {printModalInvoice.invoiceNumber || billNo}</div>
              <div>Date: {billDate}</div>
              <div>Party: {printModalInvoice.customerName || partyName}</div>
              <div style={{ borderBottom: "1px dashed #000", margin: "6px 0" }} />
              <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "bold" }}>
                <span>Item</span>
                <span>Qty x Rate</span>
                <span>Amt</span>
              </div>
              <div style={{ borderBottom: "1px dashed #000", margin: "4px 0" }} />
              {(printModalInvoice.items || cart).map((it: any, i: number) => (
                <div key={i} style={{ display: "flex", justifyContent: "space-between", marginBottom: "2px" }}>
                  <span>{it.medicineName || it.medicine?.name || "Item"}</span>
                  <span>{it.quantity} x {it.unitPrice || it.saleRate}</span>
                  <span>₹ {((it.quantity || 1) * (it.unitPrice || it.saleRate || 0)).toFixed(2)}</span>
                </div>
              ))}
              <div style={{ borderBottom: "1px dashed #000", margin: "6px 0" }} />
              <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "bold", fontSize: "0.85rem" }}>
                <span>TOTAL PAYABLE</span>
                <span>₹ {Number(printModalInvoice.netPayable || invoiceValue).toFixed(2)}</span>
              </div>
              <div style={{ textAlign: "center", marginTop: "8px", fontSize: "0.68rem", color: "#64748B" }}>
                — Thank You • Visit Again —
              </div>
            </div>

            <div style={{ display: "flex", justifyContent: "flex-end", gap: "8px", marginTop: "1rem" }}>
              <button onClick={() => setPrintModalInvoice(null)} className="marg-btn-outline">Close</button>
              <button onClick={() => window.print()} className="marg-btn-teal">Print (Alt + P)</button>
            </div>
          </div>
        </div>
      )}

      {/* AI Prescription OCR Scanner Modal */}
      <OcrScanModal
        isOpen={isOcrOpen}
        onClose={() => setIsOcrOpen(false)}
        documentType="BILL_PRESCRIPTION"
        title="Scan Doctor Prescription with AI OCR"
        subtitle="Upload prescription photo or PDF. Extracted medicines will be automatically matched with inventory batches for instant billing."
        onApply={handleOcrApply}
      />

      {/* CUSTOMER SALES RETURN / CREDIT NOTE MODAL */}
      {salesReturnModalOpen && selectedSaleForReturn && (
        <div style={{ position: "fixed", inset: 0, backgroundColor: "rgba(0,0,0,0.5)", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }}>
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "10px", width: "100%", maxWidth: "550px", padding: "1.5rem", maxHeight: "85vh", overflowY: "auto", boxShadow: "0 10px 25px rgba(0,0,0,0.2)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <div>
                <h3 style={{ margin: 0, fontSize: "1.1rem", fontWeight: 700, color: "#0F172A" }}>
                  Customer Counter Return (Credit Note)
                </h3>
                <p style={{ margin: "2px 0 0", fontSize: "0.8rem", color: "#64748B" }}>
                  Bill #{selectedSaleForReturn.invoiceNumber || selectedSaleForReturn.id?.slice(0, 8)} • Patient: {selectedSaleForReturn.customerName || "Walk-in Counter"}
                </p>
              </div>
              <button onClick={() => setSalesReturnModalOpen(false)} style={{ border: "none", background: "none", color: "#94A3B8", cursor: "pointer" }}>
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSubmitSalesReturn}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Refund Mode *
                  </label>
                  <select
                    value={refundMode}
                    onChange={(e) => setRefundMode(e.target.value as any)}
                    style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.82rem", backgroundColor: "#FFFFFF" }}
                  >
                    <option value="CASH">Cash Refund</option>
                    <option value="UPI">UPI Refund</option>
                    <option value="CREDIT_NOTE">Customer Credit Note</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "0.78rem", fontWeight: 700, color: "#334155", marginBottom: "4px" }}>
                    Reason for Return
                  </label>
                  <input
                    type="text"
                    value={returnReason}
                    onChange={(e) => setReturnReason(e.target.value)}
                    style={{ width: "100%", padding: "0.45rem 0.65rem", border: "1px solid #CBD5E1", borderRadius: "6px", fontSize: "0.82rem" }}
                  />
                </div>
              </div>

              <div style={{ marginBottom: "1.25rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 700, color: "#0F172A", marginBottom: "6px" }}>
                  Select Medicines & Quantity to Restock
                </label>
                <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                  {(selectedSaleForReturn.items || []).map((it: any) => (
                    <div key={it.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 10px", border: "1px solid #E2E8F0", borderRadius: "6px", backgroundColor: "#F8FAF9" }}>
                      <div>
                        <div style={{ fontWeight: 600, color: "#0F172A", fontSize: "0.82rem" }}>
                          {it.medicine?.name || it.medicineName || "Medicine"}
                        </div>
                        <div style={{ fontSize: "0.72rem", color: "#64748B" }}>
                          Billed Qty: {it.quantity} • Unit Price: ₹{it.unitPrice || it.sellingPrice || 0}
                        </div>
                      </div>

                      <div style={{ display: "flex", alignItems: "center", gap: "6px" }}>
                        <span style={{ fontSize: "0.75rem", color: "#64748B" }}>Return:</span>
                        <input
                          type="number"
                          min={0}
                          max={it.quantity}
                          value={returnItemQuantity[it.id] ?? 1}
                          onChange={(e) => setReturnItemQuantity({ ...returnItemQuantity, [it.id]: parseInt(e.target.value) || 0 })}
                          style={{ width: "60px", padding: "4px 6px", textAlign: "right", border: "1px solid #CBD5E1", borderRadius: "4px", fontWeight: 700 }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "8px" }}>
                <button
                  type="button"
                  onClick={() => setSalesReturnModalOpen(false)}
                  style={{ padding: "0.5rem 1rem", border: "1px solid #CBD5E1", borderRadius: "6px", background: "none", fontSize: "0.82rem", cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingReturn}
                  style={{ backgroundColor: "#DC2626", color: "#FFFFFF", border: "none", borderRadius: "6px", padding: "0.5rem 1.2rem", fontSize: "0.82rem", fontWeight: 700, cursor: "pointer" }}
                >
                  {isSubmittingReturn ? "Processing Return..." : "Complete Return & Restock"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
