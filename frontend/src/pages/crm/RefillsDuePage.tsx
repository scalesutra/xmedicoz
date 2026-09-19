import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { formatDate } from "../../utils/formatters.js";
import { TableSkeleton } from "../../components/common/LoadingSkeleton.js";
import { EmptyState } from "../../components/common/EmptyState.js";
import { ErrorCard } from "../../components/common/ErrorCard.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import { useToast } from "../../context/ToastContext.js";
import {
  HeartPulse,
  Send,
  CheckCircle2,
  Clock,
  AlertCircle,
  MessageSquare,
  X,
  Phone,
  Zap,
  Calendar,
  PhoneCall,
  Plus,
  Filter,
} from "lucide-react";

interface RefillDueItem {
  id: string;
  customerId: string;
  medicineId: string;
  dailyDosage: number | string;
  daysSupply: number;
  expectedRefillDate: string;
  daysLeft: number;
  isOverdue: boolean;
  notes?: string;
  customer: {
    id: string;
    name: string;
    mobile: string;
    notificationOptOut: boolean;
  };
  medicine: {
    id: string;
    name: string;
    genericName: string;
    dosageForm: string;
  };
}

interface FollowUpItem {
  id: string;
  customerId: string;
  followUpDate: string;
  notes: string;
  status: "PENDING" | "COMPLETED" | "CANCELLED";
  completedAt?: string;
  customer: {
    id: string;
    name: string;
    mobile: string;
  };
}

export const RefillsDuePage: React.FC = () => {
  const toast = useToast();
  const [activeTab, setActiveTab] = useState<"REFILLS" | "FOLLOWUPS">("REFILLS");

  // Refills State
  const [refills, setRefills] = useState<RefillDueItem[]>([]);
  const [daysWindow, setDaysWindow] = useState(7);
  const [isLoadingRefills, setIsLoadingRefills] = useState(true);
  const [refillsError, setRefillsError] = useState<string | null>(null);

  // Follow-ups State
  const [followUps, setFollowUps] = useState<FollowUpItem[]>([]);
  const [isLoadingFollowUps, setIsLoadingFollowUps] = useState(false);
  const [followUpsError, setFollowUpsError] = useState<string | null>(null);
  const [followUpStatusFilter, setFollowUpStatusFilter] = useState<string>("ALL");

  // Customers for callback selection
  const [customerOptions, setCustomerOptions] = useState<Array<{ id: string; name: string; mobile: string }>>([]);

  // Remind Modal State
  const [remindRule, setRemindRule] = useState<RefillDueItem | null>(null);
  const [channel, setChannel] = useState<"WHATSAPP" | "SMS" | "EMAIL">("WHATSAPP");
  const [customMsg, setCustomMsg] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [isBatchSending, setIsBatchSending] = useState(false);

  // Schedule Callback Modal State
  const [isScheduleOpen, setIsScheduleOpen] = useState(false);
  const [scheduleCustomerId, setScheduleCustomerId] = useState("");
  const [scheduleCustomerName, setScheduleCustomerName] = useState("");
  const [scheduleDate, setScheduleDate] = useState(() => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow.toISOString().split("T")[0];
  });
  const [scheduleNotes, setScheduleNotes] = useState("");
  const [isScheduling, setIsScheduling] = useState(false);

  // Confirmation Modal
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ isOpen: false, title: "", message: "", action: async () => {} });

  // 1. Fetch Due Refills
  const fetchDueRefills = async () => {
    setIsLoadingRefills(true);
    setRefillsError(null);

    const res = await apiRequest("/crm/refills/due", {
      params: { days: daysWindow },
    });

    if (res.success && Array.isArray(res.data)) {
      setRefills(res.data);
    } else {
      setRefillsError(res.message || "Failed to load due refills");
    }
    setIsLoadingRefills(false);
  };

  // 2. Fetch Follow-ups
  const fetchFollowUps = async () => {
    setIsLoadingFollowUps(true);
    setFollowUpsError(null);

    const res = await apiRequest("/crm/follow-ups");
    if (res.success && res.data) {
      const list = Array.isArray(res.data) ? res.data : res.data.items || [];
      setFollowUps(list);
    } else {
      setFollowUpsError(res.message || "Failed to load follow-up schedules");
    }
    setIsLoadingFollowUps(false);
  };

  // 3. Fetch Customers for Follow-up picker
  const fetchCustomerOptions = async () => {
    const res = await apiRequest("/masters/customers", { params: { limit: 100 } });
    if (res.success && res.data) {
      const list = Array.isArray(res.data) ? res.data : res.data.items || [];
      setCustomerOptions(list);
    }
  };

  useEffect(() => {
    fetchDueRefills();
  }, [daysWindow]);

  useEffect(() => {
    if (activeTab === "FOLLOWUPS") {
      fetchFollowUps();
      fetchCustomerOptions();
    }
  }, [activeTab]);

  const handleOpenRemind = (rule: RefillDueItem) => {
    setRemindRule(rule);
    setCustomMsg(
      `Dear ${rule.customer.name}, your prescription refill for ${rule.medicine.name} is due on ${formatDate(
        rule.expectedRefillDate
      )}. Please visit our pharmacy to replenish your supply.`
    );
  };

  const handleSendReminder = () => {
    if (!remindRule) return;

    setConfirmModal({
      isOpen: true,
      title: `Dispatch ${channel} Refill Alert`,
      message: `Send prescription refill reminder to ${remindRule.customer.name} (${remindRule.customer.mobile}) via ${channel}?`,
      action: async () => {
        setIsSending(true);
        const res = await apiRequest(`/crm/refills/${remindRule.id}/remind`, {
          method: "POST",
          body: JSON.stringify({
            channel,
            customMessage: customMsg || undefined,
          }),
        });
        setIsSending(false);

        if (res.success) {
          toast.success(`Reminder successfully dispatched via ${channel}!`);
          setRemindRule(null);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
        } else {
          toast.error(res.message || "Failed to send notification");
        }
      },
    });
  };

  const handleBatchSendDueReminders = () => {
    const eligible = refills.filter((r) => !r.customer.notificationOptOut && r.customer.mobile);
    if (eligible.length === 0) {
      toast.error("No eligible patients with active mobile numbers to notify.");
      return;
    }

    setConfirmModal({
      isOpen: true,
      title: `Batch Dispatch ${eligible.length} WhatsApp Reminders`,
      message: `Send automated prescription refill WhatsApp alerts to all ${eligible.length} patients due in this window?`,
      action: async () => {
        setIsBatchSending(true);
        let successCount = 0;
        let failCount = 0;

        for (const rule of eligible) {
          try {
            const defaultMsg = `Dear ${rule.customer.name}, your prescription refill for ${rule.medicine.name} is due on ${formatDate(
              rule.expectedRefillDate
            )}. Please visit our pharmacy to replenish your supply.`;

            const res = await apiRequest(`/crm/refills/${rule.id}/remind`, {
              method: "POST",
              body: JSON.stringify({
                channel: "WHATSAPP",
                customMessage: defaultMsg,
              }),
            });
            if (res.success) {
              successCount++;
            } else {
              failCount++;
            }
          } catch {
            failCount++;
          }
        }

        setIsBatchSending(false);
        setConfirmModal((prev) => ({ ...prev, isOpen: false }));
        if (successCount > 0) {
          toast.success(`Successfully dispatched ${successCount} WhatsApp refill reminders!`);
        }
        if (failCount > 0) {
          toast.error(`${failCount} reminders failed to deliver.`);
        }
        fetchDueRefills();
      },
    });
  };

  // Open Schedule Callback modal
  const handleOpenSchedule = (customer?: { id: string; name: string }) => {
    if (customer) {
      setScheduleCustomerId(customer.id);
      setScheduleCustomerName(customer.name);
      setScheduleNotes(`Prescription refill callback check for ${customer.name}`);
    } else {
      setScheduleCustomerId(customerOptions[0]?.id || "");
      setScheduleCustomerName("");
      setScheduleNotes("");
    }
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    setScheduleDate(tomorrow.toISOString().split("T")[0]);
    setIsScheduleOpen(true);
  };

  // Submit Callback Schedule
  const handleCreateSchedule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!scheduleCustomerId || !scheduleDate || !scheduleNotes.trim()) {
      toast.error("Please fill in all required callback fields.");
      return;
    }

    setIsScheduling(true);
    const res = await apiRequest("/crm/follow-ups", {
      method: "POST",
      body: JSON.stringify({
        customerId: scheduleCustomerId,
        followUpDate: scheduleDate,
        notes: scheduleNotes.trim(),
      }),
    });
    setIsScheduling(false);

    if (res.success) {
      toast.success("Patient follow-up callback scheduled successfully!");
      setIsScheduleOpen(false);
      if (activeTab === "FOLLOWUPS") {
        fetchFollowUps();
      }
    } else {
      toast.error(res.message || "Failed to schedule follow-up");
    }
  };

  // Update Callback Status (Complete or Cancel)
  const handleUpdateFollowUpStatus = (item: FollowUpItem, status: "COMPLETED" | "CANCELLED") => {
    const actionLabel = status === "COMPLETED" ? "Mark Callback as Completed" : "Cancel Callback";
    setConfirmModal({
      isOpen: true,
      title: actionLabel,
      message: `Confirm updating follow-up callback for ${item.customer.name} to "${status}"?`,
      action: async () => {
        const res = await apiRequest(`/crm/follow-ups/${item.id}`, {
          method: "PATCH",
          body: JSON.stringify({ status }),
        });
        setConfirmModal((prev) => ({ ...prev, isOpen: false }));
        if (res.success) {
          toast.success(`Follow-up callback updated to ${status}`);
          fetchFollowUps();
        } else {
          toast.error(res.message || "Failed to update follow-up");
        }
      },
    });
  };

  // Filtered Follow-ups
  const filteredFollowUps = followUps.filter((f) => {
    if (followUpStatusFilter === "ALL") return true;
    return f.status === followUpStatusFilter;
  });

  return (
    <div className="animate-scale-in">
      {/* Subtab Switcher */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "1rem",
          marginBottom: "1.25rem",
          borderBottom: "1px solid #E2E8F0",
          paddingBottom: "0.75rem",
        }}
      >
        <div style={{ display: "flex", gap: "0.5rem" }}>
          <button
            onClick={() => setActiveTab("REFILLS")}
            style={{
              padding: "0.5rem 1rem",
              borderRadius: "6px",
              border: "none",
              backgroundColor: activeTab === "REFILLS" ? "#059669" : "transparent",
              color: activeTab === "REFILLS" ? "#FFFFFF" : "#64748B",
              fontWeight: activeTab === "REFILLS" ? 700 : 500,
              fontSize: "0.85rem",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.4rem",
              transition: "all 0.15s ease",
            }}
          >
            <HeartPulse size={15} /> Prescription Refills Due
          </button>
          <button
            onClick={() => setActiveTab("FOLLOWUPS")}
            style={{
              padding: "0.5rem 1rem",
              borderRadius: "6px",
              border: "none",
              backgroundColor: activeTab === "FOLLOWUPS" ? "#059669" : "transparent",
              color: activeTab === "FOLLOWUPS" ? "#FFFFFF" : "#64748B",
              fontWeight: activeTab === "FOLLOWUPS" ? 700 : 500,
              fontSize: "0.85rem",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.4rem",
              transition: "all 0.15s ease",
            }}
          >
            <PhoneCall size={15} /> Patient Callback Schedule
          </button>
        </div>

        <button
          onClick={() => handleOpenSchedule()}
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: "0.4rem",
            padding: "0.5rem 1rem",
            borderRadius: "6px",
            backgroundColor: "#0F766E",
            color: "#FFFFFF",
            fontWeight: 700,
            fontSize: "0.82rem",
            border: "none",
            cursor: "pointer",
          }}
        >
          <Plus size={15} /> Schedule Patient Callback
        </button>
      </div>

      {/* TAB 1: REFILLS DUE */}
      {activeTab === "REFILLS" && (
        <div>
          {/* Controls Bar */}
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              flexWrap: "wrap",
              gap: "1rem",
              marginBottom: "1.25rem",
            }}
          >
            <div>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Automated Chronic Refill Reminders
              </h3>
              <p style={{ fontSize: "0.8rem", color: "#64748B", margin: 0 }}>
                Identify patients with upcoming due or overdue monthly prescriptions.
              </p>
            </div>

            <div style={{ display: "flex", alignItems: "center", gap: "0.75rem", flexWrap: "wrap" }}>
              {refills.length > 0 && (
                <button
                  onClick={handleBatchSendDueReminders}
                  disabled={isBatchSending}
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "0.4rem",
                    padding: "0.45rem 0.95rem",
                    borderRadius: "6px",
                    backgroundColor: "#059669",
                    color: "#FFFFFF",
                    fontWeight: 700,
                    fontSize: "0.82rem",
                    border: "none",
                    cursor: isBatchSending ? "not-allowed" : "pointer",
                    boxShadow: "0 2px 4px rgba(5,150,105,0.25)",
                  }}
                >
                  <Zap size={15} />
                  {isBatchSending
                    ? "Dispatching..."
                    : `Dispatch All ${refills.filter((r) => !r.customer.notificationOptOut).length} Due Reminders (WhatsApp)`}
                </button>
              )}

              <div style={{ display: "flex", alignItems: "center", gap: "0.4rem" }}>
                <span style={{ fontSize: "0.82rem", color: "#64748B", fontWeight: 600 }}>Window:</span>
                {[3, 7, 14, 30].map((d) => (
                  <button
                    key={d}
                    onClick={() => setDaysWindow(d)}
                    style={{
                      padding: "0.4rem 0.75rem",
                      borderRadius: "6px",
                      border: daysWindow === d ? "2px solid #059669" : "1px solid #CBD5E1",
                      backgroundColor: daysWindow === d ? "#ECFDF5" : "#FFFFFF",
                      color: daysWindow === d ? "#065F46" : "#475569",
                      fontWeight: daysWindow === d ? 700 : 500,
                      fontSize: "0.8rem",
                      cursor: "pointer",
                    }}
                  >
                    {d}D
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Main Refills Table */}
          {isLoadingRefills ? (
            <div className="glass-card">
              <TableSkeleton rows={5} cols={7} />
            </div>
          ) : refillsError ? (
            <ErrorCard message={refillsError} onRetry={fetchDueRefills} />
          ) : refills.length === 0 ? (
            <EmptyState
              icon={<HeartPulse size={32} />}
              title="No Prescriptions Due for Refill"
              description={`No chronic refill rules are due in the next ${daysWindow} days. Active patients are fully supplied.`}
            />
          ) : (
            <div className="glass-card" style={{ overflow: "hidden" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
                <thead>
                  <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                    <th style={{ padding: "0.85rem 1.25rem" }}>Patient Name</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Contact Mobile</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Chronic Medicine</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Dosage & Supply</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Refill Due Date</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Status Window</th>
                    <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {refills.map((r) => (
                    <tr key={r.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                      <td style={{ padding: "0.9rem 1.25rem", fontWeight: 700, color: "#0F172A" }}>
                        {r.customer.name}
                      </td>
                      <td style={{ padding: "0.9rem 1rem", fontFamily: "var(--font-mono)", color: "#0F766E", fontWeight: 600 }}>
                        {r.customer.mobile}
                      </td>
                      <td style={{ padding: "0.9rem 1rem" }}>
                        <div style={{ fontWeight: 600, color: "#0F172A" }}>{r.medicine.name}</div>
                        <div style={{ fontSize: "0.75rem", color: "#64748B" }}>{r.medicine.genericName}</div>
                      </td>
                      <td style={{ padding: "0.9rem 1rem", color: "#475569" }}>
                        {r.dailyDosage} daily ({r.daysSupply} days supply)
                      </td>
                      <td style={{ padding: "0.9rem 1rem", fontWeight: 600, color: "#0F172A" }}>
                        {formatDate(r.expectedRefillDate)}
                      </td>
                      <td style={{ padding: "0.9rem 1rem" }}>
                        <span
                          style={{
                            padding: "0.2rem 0.6rem",
                            borderRadius: "9999px",
                            fontSize: "0.75rem",
                            fontWeight: 700,
                            backgroundColor: r.isOverdue ? "rgba(239, 68, 68, 0.1)" : "#FFFBEB",
                            color: r.isOverdue ? "#DC2626" : "#D97706",
                          }}
                        >
                          {r.isOverdue ? "⚠️ Overdue" : `Due in ${r.daysLeft} days`}
                        </span>
                      </td>
                      <td style={{ padding: "0.9rem 1rem", textAlign: "right" }}>
                        <div style={{ display: "inline-flex", gap: "0.4rem" }}>
                          <button
                            onClick={() => handleOpenRemind(r)}
                            disabled={r.customer.notificationOptOut}
                            title="Dispatch WhatsApp/SMS alert"
                            style={{
                              padding: "0.4rem 0.75rem",
                              backgroundColor: r.customer.notificationOptOut ? "#F1F5F9" : "#059669",
                              color: r.customer.notificationOptOut ? "#94A3B8" : "#FFFFFF",
                              border: "none",
                              borderRadius: "6px",
                              fontSize: "0.78rem",
                              fontWeight: 600,
                              cursor: r.customer.notificationOptOut ? "not-allowed" : "pointer",
                              display: "inline-flex",
                              alignItems: "center",
                              gap: "0.3rem",
                            }}
                          >
                            <Send size={13} />
                            Alert
                          </button>
                          <button
                            onClick={() => handleOpenSchedule({ id: r.customerId, name: r.customer.name })}
                            title="Schedule follow-up phone call"
                            style={{
                              padding: "0.4rem 0.7rem",
                              backgroundColor: "#FFFFFF",
                              color: "#0F766E",
                              border: "1px solid #CBD5E1",
                              borderRadius: "6px",
                              fontSize: "0.78rem",
                              fontWeight: 600,
                              cursor: "pointer",
                              display: "inline-flex",
                              alignItems: "center",
                              gap: "0.3rem",
                            }}
                          >
                            <PhoneCall size={13} />
                            Callback
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* TAB 2: PATIENT CALLBACK SCHEDULE */}
      {activeTab === "FOLLOWUPS" && (
        <div>
          {/* Filter Bar */}
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              flexWrap: "wrap",
              gap: "1rem",
              marginBottom: "1.25rem",
            }}
          >
            <div>
              <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Clinical & Refill Callback Tasks
              </h3>
              <p style={{ fontSize: "0.8rem", color: "#64748B", margin: 0 }}>
                Track scheduled telephone and clinic follow-ups with patients.
              </p>
            </div>

            <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <Filter size={14} color="#64748B" />
              {(["ALL", "PENDING", "COMPLETED", "CANCELLED"] as const).map((st) => (
                <button
                  key={st}
                  onClick={() => setFollowUpStatusFilter(st)}
                  style={{
                    padding: "0.4rem 0.75rem",
                    borderRadius: "6px",
                    border: followUpStatusFilter === st ? "2px solid #059669" : "1px solid #CBD5E1",
                    backgroundColor: followUpStatusFilter === st ? "#ECFDF5" : "#FFFFFF",
                    color: followUpStatusFilter === st ? "#065F46" : "#475569",
                    fontWeight: followUpStatusFilter === st ? 700 : 500,
                    fontSize: "0.8rem",
                    cursor: "pointer",
                  }}
                >
                  {st === "ALL" ? "All Tasks" : st}
                </button>
              ))}
            </div>
          </div>

          {/* Follow-ups Table */}
          {isLoadingFollowUps ? (
            <div className="glass-card">
              <TableSkeleton rows={5} cols={5} />
            </div>
          ) : followUpsError ? (
            <ErrorCard message={followUpsError} onRetry={fetchFollowUps} />
          ) : filteredFollowUps.length === 0 ? (
            <EmptyState
              icon={<PhoneCall size={32} />}
              title="No Patient Callbacks Scheduled"
              description="No follow-up calls match the selected filter. Click 'Schedule Patient Callback' above to log a new appointment or patient reminder call."
              actionLabel="Schedule Patient Callback"
              onAction={() => handleOpenSchedule()}
            />
          ) : (
            <div className="glass-card" style={{ overflow: "hidden" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
                <thead>
                  <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                    <th style={{ padding: "0.85rem 1.25rem" }}>Patient Name</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Phone Number</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Scheduled Date</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Purpose & Clinical Notes</th>
                    <th style={{ padding: "0.85rem 1rem" }}>Status</th>
                    <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredFollowUps.map((f) => (
                    <tr key={f.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                      <td style={{ padding: "0.85rem 1.25rem", fontWeight: 700, color: "#0F172A" }}>
                        {f.customer?.name}
                      </td>
                      <td style={{ padding: "0.85rem 1rem", fontFamily: "var(--font-mono)", color: "#0F766E", fontWeight: 600 }}>
                        {f.customer?.mobile}
                      </td>
                      <td style={{ padding: "0.85rem 1rem", fontWeight: 600, color: "#0F172A" }}>
                        {formatDate(f.followUpDate)}
                      </td>
                      <td style={{ padding: "0.85rem 1rem", color: "#334155" }}>
                        {f.notes}
                      </td>
                      <td style={{ padding: "0.85rem 1rem" }}>
                        <span
                          style={{
                            padding: "0.18rem 0.55rem",
                            borderRadius: "9999px",
                            fontSize: "0.72rem",
                            fontWeight: 700,
                            backgroundColor:
                              f.status === "COMPLETED"
                                ? "#ECFDF5"
                                : f.status === "PENDING"
                                ? "#FFFBEB"
                                : "#F1F5F9",
                            color:
                              f.status === "COMPLETED"
                                ? "#065F46"
                                : f.status === "PENDING"
                                ? "#D97706"
                                : "#64748B",
                          }}
                        >
                          {f.status === "COMPLETED" ? "✓ Completed" : f.status === "PENDING" ? "⏳ Pending" : "Cancelled"}
                        </span>
                      </td>
                      <td style={{ padding: "0.85rem 1rem", textAlign: "right" }}>
                        {f.status === "PENDING" && (
                          <div style={{ display: "inline-flex", gap: "0.35rem" }}>
                            <button
                              onClick={() => handleUpdateFollowUpStatus(f, "COMPLETED")}
                              style={{
                                padding: "0.3rem 0.65rem",
                                borderRadius: "5px",
                                border: "none",
                                backgroundColor: "#059669",
                                color: "#FFFFFF",
                                fontSize: "0.75rem",
                                fontWeight: 600,
                                cursor: "pointer",
                                display: "inline-flex",
                                alignItems: "center",
                                gap: "0.3rem",
                              }}
                            >
                              <CheckCircle2 size={12} /> Done
                            </button>
                            <button
                              onClick={() => handleUpdateFollowUpStatus(f, "CANCELLED")}
                              style={{
                                padding: "0.3rem 0.65rem",
                                borderRadius: "5px",
                                border: "1px solid #CBD5E1",
                                backgroundColor: "#FFFFFF",
                                color: "#64748B",
                                fontSize: "0.75rem",
                                fontWeight: 600,
                                cursor: "pointer",
                              }}
                            >
                              Cancel
                            </button>
                          </div>
                        )}
                        {f.status === "COMPLETED" && (
                          <span style={{ fontSize: "0.75rem", color: "#059669", fontWeight: 600 }}>
                            Resolved
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Schedule Callback Modal */}
      {isScheduleOpen && (
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
              maxWidth: "480px",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Schedule Patient Follow-up Callback
              </h3>
              <button onClick={() => setIsScheduleOpen(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleCreateSchedule} style={{ padding: "1.5rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Patient *
                </label>
                {scheduleCustomerName ? (
                  <div style={{ padding: "0.6rem 0.8rem", borderRadius: "6px", backgroundColor: "#F8FAFC", border: "1px solid #CBD5E1", fontSize: "0.85rem", fontWeight: 700, color: "#0F172A" }}>
                    {scheduleCustomerName}
                  </div>
                ) : (
                  <select
                    required
                    value={scheduleCustomerId}
                    onChange={(e) => setScheduleCustomerId(e.target.value)}
                    style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", backgroundColor: "#FFFFFF" }}
                  >
                    <option value="">Select a registered patient...</option>
                    {customerOptions.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name} ({c.mobile})
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Scheduled Callback Date *
                </label>
                <input
                  type="date"
                  required
                  value={scheduleDate}
                  onChange={(e) => setScheduleDate(e.target.value)}
                  style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem" }}
                />
              </div>

              <div style={{ marginBottom: "1.5rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Clinical Purpose & Follow-up Notes *
                </label>
                <textarea
                  rows={3}
                  required
                  value={scheduleNotes}
                  onChange={(e) => setScheduleNotes(e.target.value)}
                  placeholder="e.g. Check patient blood pressure response, drug tolerance, or refill requirement"
                  style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", resize: "vertical" }}
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setIsScheduleOpen(false)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem" }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isScheduling}
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: isScheduling ? "not-allowed" : "pointer" }}
                >
                  {isScheduling ? "Saving..." : "Save Callback Task"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Send Reminder Modal */}
      {remindRule && (
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
              maxWidth: "500px",
              boxShadow: "0 20px 25px -5px rgba(0, 0, 0, 0.2)",
              border: "1px solid #E2E8F0",
              overflow: "hidden",
            }}
          >
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <div>
                <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                  Dispatch Refill Reminder
                </h3>
                <div style={{ fontSize: "0.78rem", color: "#64748B", marginTop: "2px" }}>
                  To: {remindRule.customer.name} ({remindRule.customer.mobile})
                </div>
              </div>
              <button onClick={() => setRemindRule(null)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}>
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: "1.5rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Communication Channel
                </label>
                <div style={{ display: "flex", gap: "0.75rem" }}>
                  {(["WHATSAPP", "SMS", "EMAIL"] as const).map((c) => (
                    <label key={c} style={{ display: "flex", alignItems: "center", gap: "0.4rem", fontSize: "0.85rem", color: "#334155", cursor: "pointer" }}>
                      <input
                        type="radio"
                        name="remindChannel"
                        checked={channel === c}
                        onChange={() => setChannel(c)}
                      />
                      {c === "WHATSAPP" ? "WhatsApp Message" : c === "SMS" ? "SMS" : "Email"}
                    </label>
                  ))}
                </div>
              </div>

              <div style={{ marginBottom: "1.5rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>
                  Message Template / Preview
                </label>
                <textarea
                  rows={4}
                  value={customMsg}
                  onChange={(e) => setCustomMsg(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "0.65rem 0.8rem",
                    borderRadius: "8px",
                    border: "1px solid #CBD5E1",
                    fontSize: "0.85rem",
                    outline: "none",
                    lineHeight: 1.5,
                  }}
                />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button
                  type="button"
                  onClick={() => setRemindRule(null)}
                  style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem", fontWeight: 600, cursor: "pointer" }}
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleSendReminder}
                  style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: "pointer", display: "flex", alignItems: "center", gap: "0.45rem" }}
                >
                  <Send size={15} /> Send Notification
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Action Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        isLoading={isSending}
        onConfirm={confirmModal.action}
        onCancel={() => setConfirmModal((prev) => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
};
