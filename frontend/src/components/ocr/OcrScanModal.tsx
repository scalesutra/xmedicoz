import React, { useState, useRef, useEffect } from "react";
import {
  Camera,
  Upload,
  X,
  Sparkles,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  FileText,
  Eye,
  Sliders,
  Check,
  ChevronRight,
  Zap,
  Trash2,
  Plus,
} from "lucide-react";
import { apiRequest } from "../../api/client.js";

export type OcrDocType =
  | "MEDICINE"
  | "CUSTOMER"
  | "SUPPLIER"
  | "BATCH"
  | "BILL_PRESCRIPTION"
  | "BILL_PURCHASE";

interface OcrScanModalProps {
  isOpen: boolean;
  onClose: () => void;
  documentType: OcrDocType;
  title: string;
  subtitle?: string;
  onApply: (data: { fields: Record<string, any>; items?: any[]; rawText?: string }) => void;
}

export const OcrScanModal: React.FC<OcrScanModalProps> = ({
  isOpen,
  onClose,
  documentType,
  title,
  subtitle,
  onApply,
}) => {
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [scanResult, setScanResult] = useState<{
    rawText?: string;
    confidence?: number;
    fields: Record<string, any>;
    items?: any[];
  } | null>(null);
  const [editableFields, setEditableFields] = useState<Record<string, any>>({});
  const [editableItems, setEditableItems] = useState<any[]>([]);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Camera State
  const [isCameraActive, setIsCameraActive] = useState(false);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  // Stop camera on unmount or close
  useEffect(() => {
    if (!isOpen) {
      stopCamera();
      setSelectedImage(null);
      setScanResult(null);
      setEditableFields({});
      setEditableItems([]);
      setErrorMessage(null);
    }
  }, [isOpen]);

  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    setIsCameraActive(false);
  };

  const startCamera = async () => {
    try {
      setErrorMessage(null);
      setIsCameraActive(true);
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment", width: { ideal: 1280 }, height: { ideal: 720 } },
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
      }
    } catch (err: any) {
      setIsCameraActive(false);
      setErrorMessage("Could not access camera. Please check camera permissions or upload an image file.");
    }
  };

  const captureCameraSnapshot = () => {
    if (!videoRef.current) return;
    const video = videoRef.current;
    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
    const ctx = canvas.getContext("2d");
    if (ctx) {
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      const dataUrl = canvas.toDataURL("image/jpeg", 0.85);
      setSelectedImage(dataUrl);
      stopCamera();
      triggerOcrScan(dataUrl);
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith("image/") && file.type !== "application/pdf") {
      setErrorMessage("Please select a valid image file (JPG, PNG, WEBP).");
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target?.result as string;
      setSelectedImage(dataUrl);
      triggerOcrScan(dataUrl);
    };
    reader.readAsDataURL(file);
  };

  const parseInvoiceLinesFromText = (text: string): any[] => {
    const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
    const items: any[] = [];
    const headerOrFooter = /^(tax invoice|invoice details|pharma distributors|dino|di\s*no|dl[\s.-]*c|phone|address|shop no|delhi|gstin|buyer|batch\s*(?:4|no)?\s*amount|taxable|cgst|sgst|total|grand|words|authorised|stamp|e\.|for\s+shree)/i;

    const mergedLines: string[] = [];
    for (let i = 0; i < lines.length; i++) {
      const curr = lines[i];
      if (i > 0 && /^(Duo|Tab|Cap|\(?\d+s\)?|\d+\s*s\))/i.test(curr) && !/\|/.test(curr)) {
        mergedLines[mergedLines.length - 1] += " " + curr;
      } else {
        mergedLines.push(curr);
      }
    }

    for (const l of mergedLines) {
      if (headerOrFooter.test(l.replace(/^[=—_\s|#*0-9.\-\[\]]+/, ""))) continue;
      if (/(?:dino|di\s*no|dl[\s.-]*c|gstin|buyer\s*\(|phone:)/i.test(l)) continue;

      const hasExpiry = /[0-1]?[0-9][\/-](?:20)?[2-3][0-9]/.test(l);
      const hasMedPattern = /(augmentin|dolo|pan|agin|azith|montair|tab|cap|syr|\d+mg|\(\d+s\))/i.test(l);
      const hasAmounts = /\d+\.\d{2}/.test(l);

      if ((hasExpiry || hasAmounts) && (hasMedPattern || l.includes("|"))) {
        const cleaned = l.replace(/^[=—_\s|#*0-9.\-\[\]]+\s*\|\s*/, "").replace(/^[=—_\s|#*]+/, "").trim();

        let batchNumber = "";
        const tokens = cleaned.match(/[A-Za-z0-9]{4,10}/g) || [];
        for (const tok of tokens) {
          const u = tok.toUpperCase();
          if (/[A-Z]/.test(u) && /[0-9]/.test(u) && !/^(3004|TABLET|CAPSULE|RATE|MRP|AMOUNT|TOTAL|\d+MG|\d+ML|\d+S)$/i.test(u)) {
            batchNumber = u;
            break;
          }
        }
        if (!batchNumber) {
          const parts = cleaned.split("|").map((s) => s.trim());
          for (let i = 0; i < parts.length; i++) {
            if (/[0-1]?[0-9][\/-](?:20)?[2-3][0-9]/.test(parts[i]) && i > 0) {
              const m = parts[i - 1].match(/\b([A-Za-z0-9]{4,10})\b/);
              if (m && !/3004|hsn/i.test(m[1])) {
                batchNumber = m[1].toUpperCase();
                break;
              }
            }
          }
        }
        if (!batchNumber) batchNumber = `BTH-${items.length + 1}`;

        let expiry = "12/28";
        const expMatch = cleaned.match(/([0-1]?[0-9][\/-](?:20)?[2-3][0-9])/);
        if (expMatch) expiry = expMatch[1];

        let medName = "";
        if (cleaned.includes("|")) {
          const parts = cleaned.split("|").map((p) => p.trim());
          medName = parts[0].replace(/^[0-9\s|.-]+/, "");
        } else {
          const nameM = cleaned.match(/^([A-Za-z0-9\s\(\)-]+?(?:mg|duo|\(\d+s\)))/i);
          medName = nameM ? nameM[1].trim() : cleaned.slice(0, 25).trim();
        }

        if (batchNumber && medName.includes(batchNumber)) {
          medName = medName.replace(batchNumber, "").trim();
        }

        const decTokens = (cleaned.match(/\b\d+\.\d{2}\b/g) || []).map(Number);
        let rate = 0;
        let mrp = 0;
        let amount = 0;
        let qty = 10;
        if (decTokens.length >= 3) {
          rate = decTokens[0];
          mrp = decTokens[1];
          amount = decTokens[2];
          qty = rate > 0 ? Math.round(amount / rate) : 10;
        } else if (decTokens.length === 2) {
          rate = decTokens[0];
          mrp = decTokens[1];
          amount = rate * 10;
        } else if (decTokens.length === 1) {
          rate = decTokens[0];
          mrp = Number((rate * 1.35).toFixed(2));
          amount = rate * 10;
        }

        if (medName.length >= 2) {
          items.push({
            medicineName: medName,
            batchNumber,
            expiryDate: expiry,
            quantity: qty,
            purchaseRate: rate,
            unitPrice: rate,
            mrp,
            amount,
          });
        }
      }
    }

    return items;
  };

  const updateEditableItem = (index: number, field: string, value: any) => {
    setEditableItems((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], [field]: value };
      if (field === "quantity" || field === "purchaseRate" || field === "unitPrice") {
        const q = Number(next[index].quantity) || 0;
        const r = Number(next[index].purchaseRate ?? next[index].unitPrice) || 0;
        next[index].amount = Number((q * r).toFixed(2));
      }
      return next;
    });
  };

  const removeEditableItem = (index: number) => {
    setEditableItems((prev) => prev.filter((_, i) => i !== index));
  };

  const addEditableItem = () => {
    setEditableItems((prev) => [
      ...prev,
      {
        medicineName: "",
        quantity: 1,
        batchNumber: `BTH-${prev.length + 1}`,
        expiryDate: "12/28",
        purchaseRate: 0,
        unitPrice: 0,
        mrp: 0,
        amount: 0,
      },
    ]);
  };

  const triggerOcrScan = async (imageData: string) => {
    setIsScanning(true);
    setErrorMessage(null);
    setScanResult(null);

    try {
      const res = await apiRequest("/ocr/scan", {
        method: "POST",
        body: JSON.stringify({
          documentType,
          image: imageData,
        }),
      });

      if (res.success && res.data) {
        const result = res.data;
        setScanResult(result);
        setEditableFields(result.fields || {});

        let itemsFound = result.items || (result.fields as any)?.items || [];
        if (result.rawText && itemsFound.length <= 1) {
          const fallback = parseInvoiceLinesFromText(result.rawText);
          if (fallback.length > itemsFound.length) {
            itemsFound = fallback;
          }
        }
        setEditableItems(itemsFound);
      } else {
        setErrorMessage(res.message || "Failed to scan document with OCR.");
      }
    } catch (err: any) {
      setErrorMessage(err.message || "Network error while connecting to OCR service.");
    } finally {
      setIsScanning(false);
    }
  };

  const handleApply = () => {
    if (!scanResult) return;
    const payload = {
      ...(editableFields || {}),
      fields: editableFields || {},
      items: editableItems,
      rawText: scanResult.rawText,
    };
    try {
      onApply(payload);
    } catch (err) {
      console.error("[OCR Apply Error]:", err);
    }
    onClose();
  };

  // Demo presets for zero-friction testing
  const loadDemoSample = (presetType: OcrDocType) => {
    // Generate a synthetic test canvas image for visual feedback
    const canvas = document.createElement("canvas");
    canvas.width = 600;
    canvas.height = 200;
    const ctx = canvas.getContext("2d");
    if (ctx) {
      ctx.fillStyle = "#F8FAFC";
      ctx.fillRect(0, 0, 600, 200);
      ctx.strokeStyle = "#CBD5E1";
      ctx.lineWidth = 2;
      ctx.strokeRect(5, 5, 590, 190);
      ctx.fillStyle = "#0F172A";
      ctx.font = "bold 18px sans-serif";

      if (presetType === "MEDICINE") {
        ctx.fillText("AUGMENTIN 625 DUO Tablets", 25, 45);
        ctx.font = "14px sans-serif";
        ctx.fillText("Amoxycillin and Potassium Clavulanate IP", 25, 75);
        ctx.fillText("Schedule H Prescription Drug  HSN: 3004.90", 25, 110);
        ctx.fillText("Mfd. by: GlaxoSmithKline Pharmaceuticals Ltd", 25, 145);
      } else if (presetType === "CUSTOMER") {
        ctx.fillText("APOLLO CLINIC & DIAGNOSTICS", 25, 40);
        ctx.font = "14px sans-serif";
        ctx.fillText("Patient Name: Ramesh Kumar Sharma   Age: 42/M", 25, 75);
        ctx.fillText("Phone: +91 9876543210   Email: ramesh.sharma@gmail.com", 25, 110);
        ctx.fillText("Consultant: Dr. V. K. Mehta (MBBS, MD)", 25, 145);
      } else if (presetType === "SUPPLIER") {
        ctx.fillText("CIPLA HEALTHCARE WHOLESALE DISTRIBUTORS", 25, 40);
        ctx.font = "14px sans-serif";
        ctx.fillText("GSTIN: 07AAAAA0000A1Z5   DL No: DL-20B-98765/21B-43210", 25, 75);
        ctx.fillText("Contact Person: Amit Verma   Mobile: 9811223344", 25, 110);
        ctx.fillText("Address: Plot 42, Okhla Industrial Area, Phase-III, New Delhi", 25, 145);
      } else if (presetType === "BATCH") {
        ctx.fillText("DOLO 650 TABLETS (Paracetamol IP)", 25, 40);
        ctx.font = "bold 15px monospace";
        ctx.fillText("B.No: DL2091   MFG: 03/2024   EXP: 02/2027", 25, 85);
        ctx.fillText("M.R.P. Rs. 34.50 (INCL. OF ALL TAXES)", 25, 125);
      } else if (presetType === "BILL_PRESCRIPTION") {
        ctx.fillText("DR. SHARMA HEALTHCARE CLINIC", 25, 35);
        ctx.font = "14px sans-serif";
        ctx.fillText("Patient: Sunita Patel (9823456789)   Date: 12-09-2026", 25, 65);
        ctx.fillText("1. Tab. Dolo 650mg  1-0-1  x 5 days", 25, 95);
        ctx.fillText("2. Tab. Augmentin 625mg  1-0-1  x 5 days", 25, 125);
        ctx.fillText("3. Tab. Pan 40mg  1-0-0  x 5 days", 25, 155);
      } else {
        ctx.fillText("TAX INVOICE - MEDIPHARM DISTRIBUTORS", 25, 35);
        ctx.font = "14px sans-serif";
        ctx.fillText("Inv No: INV-2026-9041   Date: 12-09-2026   GST: 07AAAAA0000A1Z5", 25, 65);
        ctx.font = "13px monospace";
        ctx.fillText("Dolo 650       DL2091  02/27  Qty: 50   Rate: 26.50  MRP: 34.50", 25, 100);
        ctx.fillText("Augmentin 625  AGT981  03/27  Qty: 20   Rate: 178.0  MRP: 223.50", 25, 130);
      }

      const sampleDataUrl = canvas.toDataURL("image/png");
      setSelectedImage(sampleDataUrl);
      triggerOcrScan(sampleDataUrl);
    }
  };

  if (!isOpen) return null;

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 9999,
        backgroundColor: "rgba(15, 23, 42, 0.75)",
        backdropFilter: "blur(6px)",
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
          borderRadius: "16px",
          width: "100%",
          maxWidth: "880px",
          maxHeight: "92vh",
          display: "flex",
          flexDirection: "column",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.25)",
          overflow: "hidden",
          border: "1px solid #E2E8F0",
        }}
      >
        {/* Header */}
        <div
          style={{
            padding: "1.25rem 1.5rem",
            borderBottom: "1px solid #F1F5F9",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            backgroundColor: "#F8FAFC",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "0.75rem" }}>
            <div
              style={{
                width: "40px",
                height: "40px",
                borderRadius: "10px",
                backgroundColor: "#E0F2FE",
                color: "#0284C7",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Sparkles size={22} />
            </div>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                <h3 style={{ margin: 0, fontSize: "1.15rem", fontWeight: 700, color: "#0F172A" }}>
                  {title}
                </h3>
                <span
                  style={{
                    backgroundColor: "#DCFCE7",
                    color: "#166534",
                    fontSize: "0.7rem",
                    fontWeight: 700,
                    padding: "2px 8px",
                    borderRadius: "999px",
                    textTransform: "uppercase",
                    letterSpacing: "0.05em",
                  }}
                >
                  AI Scanner
                </span>
              </div>
              <p style={{ margin: "2px 0 0", fontSize: "0.82rem", color: "#64748B" }}>
                {subtitle || "Upload an image, take a camera snap, or load a sample to auto-fill form inputs."}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              border: "none",
              backgroundColor: "transparent",
              cursor: "pointer",
              color: "#94A3B8",
              padding: "6px",
              borderRadius: "8px",
            }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Content Body */}
        <div style={{ padding: "1.5rem", overflowY: "auto", flex: 1 }}>
          {errorMessage && (
            <div
              style={{
                backgroundColor: "#FEF2F2",
                border: "1px solid #FCA5A5",
                borderRadius: "10px",
                padding: "0.75rem 1rem",
                marginBottom: "1.25rem",
                display: "flex",
                alignItems: "center",
                gap: "0.75rem",
                color: "#991B1B",
                fontSize: "0.85rem",
              }}
            >
              <AlertCircle size={18} />
              <span>{errorMessage}</span>
            </div>
          )}

          {/* Action Choice Bar (Upload, Camera, Demo Preset) */}
          {!selectedImage && !isCameraActive && (
            <div>
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
                  gap: "1rem",
                  marginBottom: "1.5rem",
                }}
              >
                {/* File Upload Box */}
                <div
                  onClick={() => fileInputRef.current?.click()}
                  style={{
                    border: "2px dashed #CBD5E1",
                    borderRadius: "14px",
                    padding: "2rem 1.5rem",
                    textAlign: "center",
                    cursor: "pointer",
                    backgroundColor: "#F8FAFC",
                    transition: "all 0.2s ease",
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.borderColor = "#0284C7")}
                  onMouseLeave={(e) => (e.currentTarget.style.borderColor = "#CBD5E1")}
                >
                  <div
                    style={{
                      width: "48px",
                      height: "48px",
                      borderRadius: "12px",
                      backgroundColor: "#EFF6FF",
                      color: "#2563EB",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      margin: "0 auto 1rem",
                    }}
                  >
                    <Upload size={24} />
                  </div>
                  <h4 style={{ margin: "0 0 0.25rem", fontSize: "0.95rem", color: "#1E293B", fontWeight: 600 }}>
                    Upload Image
                  </h4>
                  <p style={{ margin: 0, fontSize: "0.78rem", color: "#64748B" }}>
                    Select photo or drag & drop (JPG, PNG, PDF)
                  </p>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*,application/pdf"
                    style={{ display: "none" }}
                    onChange={handleFileUpload}
                  />
                </div>

                {/* Camera Snap Box */}
                <div
                  onClick={startCamera}
                  style={{
                    border: "2px dashed #CBD5E1",
                    borderRadius: "14px",
                    padding: "2rem 1.5rem",
                    textAlign: "center",
                    cursor: "pointer",
                    backgroundColor: "#F8FAFC",
                    transition: "all 0.2s ease",
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.borderColor = "#10B981")}
                  onMouseLeave={(e) => (e.currentTarget.style.borderColor = "#CBD5E1")}
                >
                  <div
                    style={{
                      width: "48px",
                      height: "48px",
                      borderRadius: "12px",
                      backgroundColor: "#ECFDF5",
                      color: "#059669",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      margin: "0 auto 1rem",
                    }}
                  >
                    <Camera size={24} />
                  </div>
                  <h4 style={{ margin: "0 0 0.25rem", fontSize: "0.95rem", color: "#1E293B", fontWeight: 600 }}>
                    Use Camera
                  </h4>
                  <p style={{ margin: 0, fontSize: "0.78rem", color: "#64748B" }}>
                    Snap directly from webcam or mobile counter camera
                  </p>
                </div>

                {/* Instant Demo Sample */}
                <div
                  onClick={() => loadDemoSample(documentType)}
                  style={{
                    border: "2px dashed #CBD5E1",
                    borderRadius: "14px",
                    padding: "2rem 1.5rem",
                    textAlign: "center",
                    cursor: "pointer",
                    backgroundColor: "#F8FAFC",
                    transition: "all 0.2s ease",
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.borderColor = "#8B5CF6")}
                  onMouseLeave={(e) => (e.currentTarget.style.borderColor = "#CBD5E1")}
                >
                  <div
                    style={{
                      width: "48px",
                      height: "48px",
                      borderRadius: "12px",
                      backgroundColor: "#F5F3FF",
                      color: "#7C3AED",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      margin: "0 auto 1rem",
                    }}
                  >
                    <Zap size={24} />
                  </div>
                  <h4 style={{ margin: "0 0 0.25rem", fontSize: "0.95rem", color: "#1E293B", fontWeight: 600 }}>
                    Try Demo Sample
                  </h4>
                  <p style={{ margin: 0, fontSize: "0.78rem", color: "#64748B" }}>
                    Instant sample test without uploading real photo
                  </p>
                </div>
              </div>

              {/* Guide Note */}
              <div
                style={{
                  backgroundColor: "#F1F5F9",
                  borderRadius: "10px",
                  padding: "0.85rem 1rem",
                  fontSize: "0.8rem",
                  color: "#475569",
                  display: "flex",
                  alignItems: "center",
                  gap: "0.5rem",
                }}
              >
                <Sliders size={16} color="#64748B" />
                <span>
                  Tip: Ensure good lighting. Both printed packaging, invoices, prescription slips, and stamped batch numbers are recognized with high precision.
                </span>
              </div>
            </div>
          )}

          {/* Camera Stream View */}
          {isCameraActive && (
            <div style={{ textAlign: "center" }}>
              <div
                style={{
                  position: "relative",
                  borderRadius: "14px",
                  overflow: "hidden",
                  backgroundColor: "#000",
                  maxHeight: "380px",
                  display: "inline-block",
                  width: "100%",
                }}
              >
                <video ref={videoRef} autoPlay playsInline style={{ width: "100%", maxHeight: "380px", objectFit: "contain" }} />
                {/* Crosshair Viewfinder */}
                <div
                  style={{
                    position: "absolute",
                    inset: "15%",
                    border: "2px dashed rgba(255,255,255,0.7)",
                    borderRadius: "10px",
                    pointerEvents: "none",
                  }}
                />
              </div>

              <div style={{ marginTop: "1rem", display: "flex", justifyContent: "center", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={captureCameraSnapshot}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "0.5rem",
                    padding: "0.65rem 1.5rem",
                    borderRadius: "8px",
                    backgroundColor: "#10B981",
                    color: "#FFFFFF",
                    fontWeight: 600,
                    border: "none",
                    cursor: "pointer",
                  }}
                >
                  <Camera size={18} />
                  <span>Capture & Scan</span>
                </button>
                <button
                  type="button"
                  onClick={stopCamera}
                  style={{
                    padding: "0.65rem 1.25rem",
                    borderRadius: "8px",
                    backgroundColor: "#E2E8F0",
                    color: "#334155",
                    fontWeight: 600,
                    border: "none",
                    cursor: "pointer",
                  }}
                >
                  Cancel
                </button>
              </div>
            </div>
          )}

          {/* Image & OCR Processing or Review Panel */}
          {selectedImage && (
            <div>
              {/* Controls bar */}
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  marginBottom: "1rem",
                  paddingBottom: "0.75rem",
                  borderBottom: "1px solid #E2E8F0",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                  <Eye size={18} color="#0284C7" />
                  <span style={{ fontWeight: 600, fontSize: "0.9rem", color: "#1E293B" }}>
                    {isScanning ? "Analyzing Document..." : "Review Extracted Data"}
                  </span>
                  {scanResult?.confidence && (
                    <span
                      style={{
                        backgroundColor: "#DCFCE7",
                        color: "#15803D",
                        fontSize: "0.72rem",
                        fontWeight: 700,
                        padding: "2px 6px",
                        borderRadius: "4px",
                      }}
                    >
                      {Math.round(scanResult.confidence * 100)}% Match Confidence
                    </span>
                  )}
                </div>

                <div style={{ display: "flex", gap: "0.5rem" }}>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedImage(null);
                      setScanResult(null);
                    }}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "0.25rem",
                      fontSize: "0.8rem",
                      padding: "0.4rem 0.75rem",
                      borderRadius: "6px",
                      border: "1px solid #CBD5E1",
                      backgroundColor: "#FFF",
                      color: "#475569",
                      cursor: "pointer",
                    }}
                  >
                    <RefreshCw size={14} />
                    <span>Scan Another</span>
                  </button>
                </div>
              </div>

              {/* Scanning Laser Animation */}
              {isScanning && (
                <div
                  style={{
                    position: "relative",
                    borderRadius: "12px",
                    overflow: "hidden",
                    border: "1px solid #CBD5E1",
                    height: "260px",
                    backgroundColor: "#0F172A",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  <img
                    src={selectedImage}
                    alt="Scanning preview"
                    style={{
                      maxHeight: "100%",
                      maxWidth: "100%",
                      objectFit: "contain",
                      opacity: 0.5,
                    }}
                  />
                  {/* Glowing Laser Sweep */}
                  <div
                    style={{
                      position: "absolute",
                      left: 0,
                      right: 0,
                      height: "3px",
                      backgroundColor: "#00F0FF",
                      boxShadow: "0 0 15px 4px #00F0FF",
                      animation: "ocrLaserSweep 2s ease-in-out infinite",
                    }}
                  />
                  <div
                    style={{
                      position: "absolute",
                      bottom: "1rem",
                      backgroundColor: "rgba(15, 23, 42, 0.85)",
                      color: "#FFFFFF",
                      padding: "0.4rem 1rem",
                      borderRadius: "999px",
                      fontSize: "0.8rem",
                      display: "flex",
                      alignItems: "center",
                      gap: "0.5rem",
                    }}
                  >
                    <RefreshCw size={14} className="animate-spin" />
                    <span>Reading document and extracting fields...</span>
                  </div>
                </div>
              )}

              {/* Extracted Fields Form Review */}
              {!isScanning && scanResult && (
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1.3fr",
                    gap: "1.25rem",
                  }}
                >
                  {/* Left: Scanned Image Snapshot */}
                  <div
                    style={{
                      border: "1px solid #E2E8F0",
                      borderRadius: "12px",
                      padding: "0.5rem",
                      backgroundColor: "#F8FAFC",
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                    }}
                  >
                    <img
                      src={selectedImage}
                      alt="Scanned Preview"
                      style={{
                        maxHeight: "240px",
                        maxWidth: "100%",
                        objectFit: "contain",
                        borderRadius: "8px",
                      }}
                    />
                    <div style={{ marginTop: "0.75rem", width: "100%" }}>
                      <span style={{ fontSize: "0.72rem", color: "#64748B", fontWeight: 600 }}>
                        RAW OCR TEXT EXTRACTED:
                      </span>
                      <div
                        style={{
                          marginTop: "0.25rem",
                          backgroundColor: "#FFFFFF",
                          border: "1px solid #E2E8F0",
                          borderRadius: "6px",
                          padding: "0.4rem 0.6rem",
                          fontSize: "0.72rem",
                          color: "#334155",
                          maxHeight: "80px",
                          overflowY: "auto",
                          fontFamily: "monospace",
                          whiteSpace: "pre-wrap",
                        }}
                      >
                        {scanResult.rawText || "No text stream detected"}
                      </div>
                    </div>
                  </div>

                  {/* Right: Editable Fields */}
                  <div
                    style={{
                      border: "1px solid #E2E8F0",
                      borderRadius: "12px",
                      padding: "1rem",
                      backgroundColor: "#FFFFFF",
                      display: "flex",
                      flexDirection: "column",
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: "0.4rem", marginBottom: "0.75rem" }}>
                      <CheckCircle2 size={16} color="#10B981" />
                      <span style={{ fontSize: "0.85rem", fontWeight: 700, color: "#1E293B" }}>
                        Extracted Fields (Verify & Edit)
                      </span>
                    </div>

                    <div style={{ display: "flex", flexDirection: "column", gap: "0.6rem", flex: 1, maxHeight: "300px", overflowY: "auto" }}>
                      {Object.entries(editableFields).map(([key, val]) => {
                        if (typeof val === "object" && val !== null) return null; // Skip complex relations in simple inputs
                        return (
                          <div key={key} style={{ display: "flex", flexDirection: "column", gap: "0.2rem" }}>
                            <label
                              style={{
                                fontSize: "0.72rem",
                                fontWeight: 600,
                                color: "#64748B",
                                textTransform: "capitalize",
                              }}
                            >
                              {key.replace(/([A-Z])/g, " $1")}
                            </label>
                            <input
                              type={typeof val === "number" ? "number" : "text"}
                              value={val ?? ""}
                              onChange={(e) =>
                                setEditableFields((prev) => ({
                                  ...prev,
                                  [key]: typeof val === "number" ? Number(e.target.value) : e.target.value,
                                }))
                              }
                              style={{
                                padding: "0.4rem 0.6rem",
                                borderRadius: "6px",
                                border: "1px solid #CBD5E1",
                                fontSize: "0.82rem",
                                color: "#0F172A",
                              }}
                            />
                          </div>
                        );
                      })}

                      {/* If Prescription / Purchase Tabular Items exist - Interactive & Editable */}
                      {editableItems && editableItems.length > 0 && (
                        <div style={{ marginTop: "1rem" }}>
                          <div
                            style={{
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "space-between",
                              marginBottom: "0.5rem",
                            }}
                          >
                            <span
                              style={{
                                fontSize: "0.8rem",
                                fontWeight: 700,
                                color: "#0284C7",
                                display: "flex",
                                alignItems: "center",
                                gap: "0.4rem",
                              }}
                            >
                              <span
                                style={{
                                  backgroundColor: "#E0F2FE",
                                  color: "#0369A1",
                                  padding: "2px 7px",
                                  borderRadius: "10px",
                                  fontSize: "0.72rem",
                                  fontWeight: 800,
                                }}
                              >
                                {editableItems.length}
                              </span>
                              Detected Medicines ({editableItems.length}):
                            </span>
                            <button
                              type="button"
                              onClick={addEditableItem}
                              style={{
                                fontSize: "0.72rem",
                                fontWeight: 600,
                                color: "#0284C7",
                                background: "#F0F9FF",
                                border: "1px dashed #38BDF8",
                                borderRadius: "6px",
                                padding: "3px 8px",
                                cursor: "pointer",
                              }}
                            >
                              + Add Item
                            </button>
                          </div>

                          <div
                            style={{
                              display: "flex",
                              flexDirection: "column",
                              gap: "0.5rem",
                              maxHeight: "260px",
                              overflowY: "auto",
                              paddingRight: "2px",
                            }}
                          >
                            {editableItems.map((it, idx) => (
                              <div
                                key={idx}
                                style={{
                                  backgroundColor: "#F8FAFC",
                                  border: "1px solid #E2E8F0",
                                  borderRadius: "8px",
                                  padding: "0.5rem",
                                  display: "flex",
                                  flexDirection: "column",
                                  gap: "0.4rem",
                                }}
                              >
                                <div style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
                                  <span
                                    style={{
                                      fontSize: "0.68rem",
                                      fontWeight: 700,
                                      color: "#64748B",
                                      backgroundColor: "#E2E8F0",
                                      borderRadius: "50%",
                                      width: "18px",
                                      height: "18px",
                                      display: "flex",
                                      alignItems: "center",
                                      justifyContent: "center",
                                      flexShrink: 0,
                                    }}
                                  >
                                    {idx + 1}
                                  </span>
                                  <input
                                    type="text"
                                    placeholder="Medicine name"
                                    value={it.medicineName || ""}
                                    onChange={(e) => updateEditableItem(idx, "medicineName", e.target.value)}
                                    style={{
                                      flex: 1,
                                      fontSize: "0.78rem",
                                      fontWeight: 600,
                                      color: "#0F172A",
                                      padding: "0.25rem 0.4rem",
                                      borderRadius: "4px",
                                      border: "1px solid #CBD5E1",
                                      backgroundColor: "#FFFFFF",
                                    }}
                                  />
                                  <button
                                    type="button"
                                    onClick={() => removeEditableItem(idx)}
                                    title="Delete item"
                                    style={{
                                      background: "none",
                                      border: "none",
                                      color: "#94A3B8",
                                      cursor: "pointer",
                                      fontSize: "0.85rem",
                                      padding: "2px 5px",
                                      borderRadius: "4px",
                                    }}
                                    onMouseEnter={(e) => (e.currentTarget.style.color = "#EF4444")}
                                    onMouseLeave={(e) => (e.currentTarget.style.color = "#94A3B8")}
                                  >
                                    ✕
                                  </button>
                                </div>

                                <div
                                  style={{
                                    display: "grid",
                                    gridTemplateColumns: "1.1fr 1.3fr 1.1fr 1.1fr 1.2fr",
                                    gap: "0.35rem",
                                    fontSize: "0.72rem",
                                  }}
                                >
                                  <div>
                                    <label style={{ display: "block", fontSize: "0.62rem", color: "#64748B", fontWeight: 600 }}>
                                      Qty
                                    </label>
                                    <input
                                      type="number"
                                      value={it.quantity ?? 1}
                                      onChange={(e) => updateEditableItem(idx, "quantity", Number(e.target.value))}
                                      style={{
                                        width: "100%",
                                        padding: "0.2rem 0.35rem",
                                        borderRadius: "4px",
                                        border: "1px solid #CBD5E1",
                                        fontSize: "0.72rem",
                                        fontWeight: 600,
                                      }}
                                    />
                                  </div>
                                  <div>
                                    <label style={{ display: "block", fontSize: "0.62rem", color: "#64748B", fontWeight: 600 }}>
                                      Batch
                                    </label>
                                    <input
                                      type="text"
                                      value={it.batchNumber ?? ""}
                                      onChange={(e) => updateEditableItem(idx, "batchNumber", e.target.value)}
                                      style={{
                                        width: "100%",
                                        padding: "0.2rem 0.35rem",
                                        borderRadius: "4px",
                                        border: "1px solid #CBD5E1",
                                        fontSize: "0.72rem",
                                      }}
                                    />
                                  </div>
                                  <div>
                                    <label style={{ display: "block", fontSize: "0.62rem", color: "#64748B", fontWeight: 600 }}>
                                      Exp
                                    </label>
                                    <input
                                      type="text"
                                      value={it.expiryDate ?? ""}
                                      onChange={(e) => updateEditableItem(idx, "expiryDate", e.target.value)}
                                      style={{
                                        width: "100%",
                                        padding: "0.2rem 0.35rem",
                                        borderRadius: "4px",
                                        border: "1px solid #CBD5E1",
                                        fontSize: "0.72rem",
                                      }}
                                    />
                                  </div>
                                  <div>
                                    <label style={{ display: "block", fontSize: "0.62rem", color: "#64748B", fontWeight: 600 }}>
                                      Rate (₹)
                                    </label>
                                    <input
                                      type="number"
                                      step="0.01"
                                      value={it.purchaseRate ?? it.unitPrice ?? 0}
                                      onChange={(e) => {
                                        const val = Number(e.target.value);
                                        updateEditableItem(idx, "purchaseRate", val);
                                        updateEditableItem(idx, "unitPrice", val);
                                      }}
                                      style={{
                                        width: "100%",
                                        padding: "0.2rem 0.35rem",
                                        borderRadius: "4px",
                                        border: "1px solid #CBD5E1",
                                        fontSize: "0.72rem",
                                      }}
                                    />
                                  </div>
                                  <div>
                                    <label style={{ display: "block", fontSize: "0.62rem", color: "#64748B", fontWeight: 600 }}>
                                      Amt (₹)
                                    </label>
                                    <div
                                      style={{
                                        padding: "0.2rem 0.35rem",
                                        backgroundColor: "#F1F5F9",
                                        borderRadius: "4px",
                                        fontSize: "0.72rem",
                                        fontWeight: 600,
                                        color: "#0F172A",
                                        textAlign: "right",
                                      }}
                                    >
                                      ₹{Number(it.amount || (Number(it.quantity || 0) * Number(it.purchaseRate || it.unitPrice || 0))).toFixed(2)}
                                    </div>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div
          style={{
            padding: "1rem 1.5rem",
            borderTop: "1px solid #F1F5F9",
            backgroundColor: "#F8FAFC",
            display: "flex",
            justifyContent: "flex-end",
            gap: "0.75rem",
          }}
        >
          <button
            type="button"
            onClick={onClose}
            style={{
              padding: "0.55rem 1.25rem",
              borderRadius: "8px",
              border: "1px solid #CBD5E1",
              backgroundColor: "#FFFFFF",
              color: "#475569",
              fontSize: "0.85rem",
              fontWeight: 600,
              cursor: "pointer",
            }}
          >
            Cancel
          </button>

          {scanResult && !isScanning && (
            <button
              type="button"
              onClick={handleApply}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.5rem",
                padding: "0.55rem 1.5rem",
                borderRadius: "8px",
                border: "none",
                backgroundColor: "#0284C7",
                color: "#FFFFFF",
                fontSize: "0.85rem",
                fontWeight: 600,
                cursor: "pointer",
                boxShadow: "0 2px 4px rgba(2, 132, 199, 0.2)",
              }}
            >
              <Check size={18} />
              <span>Apply to Form</span>
            </button>
          )}
        </div>
      </div>

      <style>{`
        @keyframes ocrLaserSweep {
          0% { top: 10%; }
          50% { top: 85%; }
          100% { top: 10%; }
        }
      `}</style>
    </div>
  );
};
