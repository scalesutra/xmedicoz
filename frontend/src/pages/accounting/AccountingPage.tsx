import React, { useState, useEffect } from "react";
import { apiRequest } from "../../api/client.js";
import { formatINR, formatDate } from "../../utils/formatters.js";
import { TableSkeleton } from "../../components/common/LoadingSkeleton.js";
import { EmptyState } from "../../components/common/EmptyState.js";
import { ErrorCard } from "../../components/common/ErrorCard.js";
import { ConfirmModal } from "../../components/common/ConfirmModal.js";
import { useToast } from "../../context/ToastContext.js";
import {
  BookOpen,
  Plus,
  Landmark,
  Scale,
  Receipt,
  Clock,
  CheckCircle2,
  X,
  CreditCard,
  ArrowRight,
  Sparkles,
  FileText,
  ExternalLink,
} from "lucide-react";

interface AccountItem {
  id: string;
  code: string;
  name: string;
  type: string;
  currentBalance: number | string;
  group?: { name: string };
}

export const AccountingPage: React.FC = () => {
  const toast = useToast();
  const [activeSubTab, setActiveSubTab] = useState<"COA" | "JOURNAL" | "EXPENSES" | "TRIAL" | "AGING" | "DAYBOOK">("COA");
  const [accounts, setAccounts] = useState<AccountItem[]>([]);
  const [trialBalance, setTrialBalance] = useState<any | null>(null);
  const [daybook, setDaybook] = useState<any | null>(null);
  const [expenses, setExpenses] = useState<any[]>([]);
  const [arAging, setArAging] = useState<any | null>(null);
  const [apAging, setApAging] = useState<any | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isSeeding, setIsSeeding] = useState(false);

  // General Ledger Statement Modal State
  const [selectedAccount, setSelectedAccount] = useState<AccountItem | null>(null);
  const [ledgerStatement, setLedgerStatement] = useState<any | null>(null);
  const [isLedgerLoading, setIsLedgerLoading] = useState(false);

  // Expense Modal State
  const [isExpenseOpen, setIsExpenseOpen] = useState(false);
  const [expenseAccountId, setExpenseAccountId] = useState("");
  const [expensePaidFromId, setExpensePaidFromId] = useState("");
  const [expenseAmount, setExpenseAmount] = useState<number>(500);
  const [expensePayee, setExpensePayee] = useState("");
  const [expenseDesc, setExpenseDesc] = useState("");
  const [expenseMode, setExpenseMode] = useState<"CASH" | "BANK_TRANSFER" | "UPI">("CASH");

  // Customer Debt Payment Modal State
  const [isPaymentOpen, setIsPaymentOpen] = useState(false);
  const [payCustomerId, setPayCustomerId] = useState("");
  const [payCustomerName, setPayCustomerName] = useState("");
  const [payMaxDebt, setPayMaxDebt] = useState(0);
  const [payAmount, setPayAmount] = useState<number>(0);

  // Manual Journal Builder Modal State
  const [isJournalOpen, setIsJournalOpen] = useState(false);
  const [journalNarration, setJournalNarration] = useState("");
  const [journalLines, setJournalLines] = useState<Array<{ accountId: string; type: "DEBIT" | "CREDIT"; amount: number }>>([
    { accountId: "", type: "DEBIT", amount: 1000 },
    { accountId: "", type: "CREDIT", amount: 1000 },
  ]);

  // Confirmation Modal
  const [confirmModal, setConfirmModal] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    action: () => Promise<void>;
  }>({ isOpen: false, title: "", message: "", action: async () => { } });

  const fetchAccountingData = async () => {
    setIsLoading(true);
    setErrorMessage(null);

    try {
      const [accRes, tbRes, dayRes, expRes, arRes, apRes] = await Promise.all([
        apiRequest("/accounting/accounts"),
        apiRequest("/accounting/reports/trial-balance"),
        apiRequest("/accounting/daybook"),
        apiRequest("/accounting/expenses"),
        apiRequest("/accounting/receivables/aging"),
        apiRequest("/accounting/payables/aging"),
      ]);

      if (accRes.success) setAccounts(accRes.data || []);
      if (tbRes.success) setTrialBalance(tbRes.data);
      if (dayRes.success) setDaybook(dayRes.data);
      if (expRes.success) setExpenses(expRes.data?.items || expRes.data || []);
      if (arRes.success) setArAging(arRes.data);
      if (apRes.success) setApAging(apRes.data);
    } catch (err: any) {
      setErrorMessage(err.message || "Failed to load accounting data");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAccountingData();
  }, []);

  // Seed Standard Chart of Accounts
  const handleSeedChartOfAccounts = () => {
    setConfirmModal({
      isOpen: true,
      title: "Seed Standard 24-Account Chart of Accounts",
      message:
        "This will initialize your store with standard pharmacy accounting accounts (Cash drawer, Bank, Receivables, Inventory, Payables, GST Output, Equity, Sales Revenue, COGS, Operating Expenses). Continue?",
      action: async () => {
        setIsSeeding(true);
        const res = await apiRequest("/accounting/accounts/seed", {
          method: "POST",
          body: JSON.stringify({}),
        });
        setIsSeeding(false);
        setConfirmModal((prev) => ({ ...prev, isOpen: false }));
        if (res.success) {
          toast.success("Standard 24-Account Chart of Accounts seeded successfully!");
          await fetchAccountingData();
        } else {
          toast.error(res.message || "Failed to seed chart of accounts");
        }
      },
    });
  };

  // Open Ledger Statement for an Account
  const handleOpenLedger = async (account: AccountItem) => {
    setSelectedAccount(account);
    setIsLedgerLoading(true);
    setLedgerStatement(null);
    try {
      const res = await apiRequest(`/accounting/ledger/${account.id}`);
      if (res.success) {
        setLedgerStatement(res.data);
      } else {
        toast.error(res.message || "Failed to load account ledger");
      }
    } catch (err: any) {
      toast.error(err.message || "Failed to load account ledger");
    } finally {
      setIsLedgerLoading(false);
    }
  };

  // Submit Expense
  const handleExpenseSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!expenseAccountId || !expensePaidFromId || expenseAmount <= 0) return;

    setConfirmModal({
      isOpen: true,
      title: "Record Store Operating Expense",
      message: `Confirm recording expense of ${formatINR(expenseAmount)} for "${expenseDesc}"? This will auto-post a balanced journal entry.`,
      action: async () => {
        const res = await apiRequest("/accounting/expenses", {
          method: "POST",
          body: JSON.stringify({
            accountId: expenseAccountId,
            paidFromAccountId: expensePaidFromId,
            amount: expenseAmount,
            paymentMode: expenseMode,
            payee: expensePayee || undefined,
            description: expenseDesc,
          }),
        });

        if (res.success) {
          setIsExpenseOpen(false);
          setExpenseDesc("");
          setExpensePayee("");
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchAccountingData();
        } else {
          alert(res.message || "Failed to record expense");
        }
      },
    });
  };

  // Submit Customer Debt Payment
  const handlePaymentSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!payCustomerId || payAmount <= 0) return;

    setConfirmModal({
      isOpen: true,
      title: "Record Customer Debt Payment",
      message: `Confirm receiving ${formatINR(payAmount)} from ${payCustomerName}? This will decrement the customer's outstanding balance and post an automated journal entry.`,
      action: async () => {
        const res = await apiRequest("/accounting/receivables/payment", {
          method: "POST",
          body: JSON.stringify({
            customerId: payCustomerId,
            amount: payAmount,
            paymentMode: "CASH",
          }),
        });

        if (res.success) {
          setIsPaymentOpen(false);
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchAccountingData();
        } else {
          alert(res.message || "Payment settlement failed");
        }
      },
    });
  };

  // Journal Builder sums
  const journalDebitSum = journalLines
    .filter((l) => l.type === "DEBIT")
    .reduce((sum, l) => sum + (Number(l.amount) || 0), 0);
  const journalCreditSum = journalLines
    .filter((l) => l.type === "CREDIT")
    .reduce((sum, l) => sum + (Number(l.amount) || 0), 0);
  const isJournalBalanced = Math.abs(journalDebitSum - journalCreditSum) < 0.01;

  // Submit Manual Journal
  const handleJournalSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!isJournalBalanced) {
      alert("Cannot post unbalanced journal entry. Total Debit must equal Total Credit.");
      return;
    }

    setConfirmModal({
      isOpen: true,
      title: "Post Balanced Journal Entry",
      message: `Confirm posting journal entry for ${formatINR(journalDebitSum)}? Narration: "${journalNarration}".`,
      action: async () => {
        const res = await apiRequest("/accounting/journals", {
          method: "POST",
          body: JSON.stringify({
            referenceType: "MANUAL",
            narration: journalNarration,
            lines: journalLines.map((l) => ({
              accountId: l.accountId,
              type: l.type,
              amount: Number(l.amount),
            })),
          }),
        });

        if (res.success) {
          setIsJournalOpen(false);
          setJournalNarration("");
          setConfirmModal((prev) => ({ ...prev, isOpen: false }));
          await fetchAccountingData();
        } else {
          alert(res.message || "Failed to post journal entry");
        }
      },
    });
  };

  return (
    <div className="animate-scale-in">
      {/* Subtabs Bar */}
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
        <div style={{ display: "flex", gap: "0.35rem", flexWrap: "wrap" }}>
          {[
            { id: "COA", label: "Chart of Accounts" },
            { id: "EXPENSES", label: "Store Expenses" },
            { id: "TRIAL", label: "Trial Balance" },
            { id: "AGING", label: "AR & AP Aging" },
            { id: "DAYBOOK", label: "Cash & Bank Daybook" },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveSubTab(tab.id as any)}
              style={{
                padding: "0.5rem 1rem",
                borderRadius: "6px",
                border: "none",
                backgroundColor: activeSubTab === tab.id ? "#059669" : "transparent",
                color: activeSubTab === tab.id ? "#FFFFFF" : "#64748B",
                fontWeight: activeSubTab === tab.id ? 700 : 500,
                fontSize: "0.82rem",
                cursor: "pointer",
                transition: "all 0.15s ease",
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div style={{ display: "flex", gap: "0.5rem" }}>
          {/* <button
            onClick={handleSeedChartOfAccounts}
            disabled={isSeeding}
            style={{
              padding: "0.5rem 1rem",
              borderRadius: "6px",
              border: "1px solid #10B981",
              backgroundColor: "#ECFDF5",
              color: "#065F46",
              fontSize: "0.82rem",
              fontWeight: 600,
              cursor: isSeeding ? "not-allowed" : "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.35rem",
            }}
          >
            <Sparkles size={14} /> {isSeeding ? "Seeding..." : "Seed 24-Account COA"}
          </button> */}
          <button
            onClick={() => {
              const expAcc = accounts.find((a) => a.type === "EXPENSE");
              const cashAcc = accounts.find((a) => a.code === "1010");
              if (expAcc) setExpenseAccountId(expAcc.id);
              if (cashAcc) setExpensePaidFromId(cashAcc.id);
              setIsExpenseOpen(true);
            }}
            style={{
              padding: "0.5rem 1rem",
              borderRadius: "6px",
              border: "1px solid #CBD5E1",
              backgroundColor: "#FFFFFF",
              color: "#334155",
              fontSize: "0.82rem",
              fontWeight: 600,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.35rem",
            }}
          >
            <Plus size={14} /> Record Expense
          </button>
          <button
            onClick={() => {
              if (accounts.length >= 2) {
                setJournalLines([
                  { accountId: accounts[0].id, type: "DEBIT", amount: 1000 },
                  { accountId: accounts[1].id, type: "CREDIT", amount: 1000 },
                ]);
              }
              setIsJournalOpen(true);
            }}
            style={{
              padding: "0.5rem 1.1rem",
              borderRadius: "6px",
              border: "none",
              backgroundColor: "#0F766E",
              color: "#FFFFFF",
              fontSize: "0.82rem",
              fontWeight: 700,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              gap: "0.35rem",
            }}
          >
            <Scale size={14} /> Post Journal
          </button>
        </div>
      </div>

      {/* Tab 1: Chart of Accounts */}
      {activeSubTab === "COA" && (
        <div className="glass-card" style={{ overflow: "hidden" }}>
          {accounts.length === 0 ? (
            <EmptyState
              icon={<BookOpen size={32} />}
              title="Chart of Accounts Not Initialized"
              description="No accounting ledger accounts found for your pharmacy store. Seed the standard 24-account COA with one click to begin automated bookkeeping."
              actionLabel="Seed Standard 24-Account COA"
              onAction={handleSeedChartOfAccounts}
            />
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
              <thead>
                <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                  <th style={{ padding: "0.85rem 1.25rem" }}>Account Code</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Account Name</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Classification Type</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Group</th>
                  <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Current Live Balance</th>
                  <th style={{ padding: "0.85rem 1rem", textAlign: "center" }}>Statement</th>
                </tr>
              </thead>
              <tbody>
                {accounts.map((acc) => (
                  <tr key={acc.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.85rem 1.25rem", fontFamily: "var(--font-mono)", fontWeight: 700, color: "#0F766E" }}>
                      {acc.code}
                    </td>
                    <td style={{ padding: "0.85rem 1rem", fontWeight: 600, color: "#0F172A" }}>
                      {acc.name}
                    </td>
                    <td style={{ padding: "0.85rem 1rem" }}>
                      <span
                        style={{
                          padding: "0.15rem 0.55rem",
                          borderRadius: "9999px",
                          fontSize: "0.72rem",
                          fontWeight: 700,
                          backgroundColor:
                            acc.type === "ASSET"
                              ? "#ECFDF5"
                              : acc.type === "LIABILITY"
                                ? "#FFFBEB"
                                : acc.type === "EXPENSE"
                                  ? "rgba(239, 68, 68, 0.1)"
                                  : "#F1F5F9",
                          color:
                            acc.type === "ASSET"
                              ? "#065F46"
                              : acc.type === "LIABILITY"
                                ? "#92400E"
                                : acc.type === "EXPENSE"
                                  ? "#DC2626"
                                  : "#334155",
                        }}
                      >
                        {acc.type}
                      </span>
                    </td>
                    <td style={{ padding: "0.85rem 1rem", color: "#64748B" }}>
                      {acc.group?.name || acc.type}
                    </td>
                    <td style={{ padding: "0.85rem 1rem", textAlign: "right", fontWeight: 700, color: "#0F172A" }}>
                      {formatINR(acc.currentBalance)}
                    </td>
                    <td style={{ padding: "0.85rem 1rem", textAlign: "center" }}>
                      <button
                        onClick={() => handleOpenLedger(acc)}
                        style={{
                          padding: "0.3rem 0.65rem",
                          borderRadius: "5px",
                          border: "1px solid #CBD5E1",
                          backgroundColor: "#F8FAFC",
                          color: "#0F766E",
                          fontSize: "0.75rem",
                          fontWeight: 600,
                          cursor: "pointer",
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "0.3rem",
                        }}
                      >
                        <FileText size={12} /> Statement
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Tab 2: Store Operating Expenses */}
      {activeSubTab === "EXPENSES" && (
        <div className="glass-card" style={{ overflow: "hidden" }}>
          {expenses.length === 0 ? (
            <EmptyState
              icon={<Receipt size={32} />}
              title="No Store Expenses Recorded"
              description="No operating expenses recorded yet. Click 'Record Expense' above to log utility, rent, or supply costs."
              actionLabel="Record First Expense"
              onAction={() => setIsExpenseOpen(true)}
            />
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
              <thead>
                <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                  <th style={{ padding: "0.85rem 1.25rem" }}>Expense Voucher</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Date</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Expense Head</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Description & Payee</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Payment Mode</th>
                  <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Amount</th>
                </tr>
              </thead>
              <tbody>
                {expenses.map((exp) => (
                  <tr key={exp.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.85rem 1.25rem", fontFamily: "var(--font-mono)", fontWeight: 700, color: "#0F766E" }}>
                      {exp.expenseNumber}
                    </td>
                    <td style={{ padding: "0.85rem 1rem", color: "#64748B" }}>
                      {formatDate(exp.expenseDate)}
                    </td>
                    <td style={{ padding: "0.85rem 1rem", fontWeight: 600, color: "#0F172A" }}>
                      {exp.account?.name}
                    </td>
                    <td style={{ padding: "0.85rem 1rem", color: "#475569" }}>
                      {exp.description} {exp.payee ? `(Payee: ${exp.payee})` : ""}
                    </td>
                    <td style={{ padding: "0.85rem 1rem" }}>
                      <span style={{ padding: "0.2rem 0.5rem", borderRadius: "4px", backgroundColor: "#F1F5F9", fontSize: "0.75rem", fontWeight: 600 }}>
                        {exp.paymentMode}
                      </span>
                    </td>
                    <td style={{ padding: "0.85rem 1rem", textAlign: "right", fontWeight: 700, color: "#DC2626" }}>
                      {formatINR(exp.amount)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Tab 3: Trial Balance */}
      {activeSubTab === "TRIAL" && trialBalance && (
        <div>
          {/* Balance Banner */}
          <div
            style={{
              padding: "1rem 1.5rem",
              borderRadius: "10px",
              backgroundColor: trialBalance.isBalanced ? "#ECFDF5" : "rgba(239, 68, 68, 0.1)",
              border: trialBalance.isBalanced ? "1px solid #10B981" : "1px solid #DC2626",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: "1.25rem",
            }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}>
              <CheckCircle2 size={22} color={trialBalance.isBalanced ? "#059669" : "#DC2626"} />
              <div>
                <strong style={{ color: trialBalance.isBalanced ? "#065F46" : "#991B1B" }}>
                  {trialBalance.isBalanced ? "Books in Strict Double-Entry Balance" : "Books Unbalanced"}
                </strong>
                <div style={{ fontSize: "0.78rem", color: "#64748B" }}>
                  Total Debits equal Total Credits down to 2 decimal places.
                </div>
              </div>
            </div>
            <div style={{ textAlign: "right" }}>
              <span style={{ fontSize: "0.8rem", color: "#64748B" }}>Balance Total: </span>
              <strong style={{ fontSize: "1.1rem", color: "#0F172A" }}>{formatINR(trialBalance.totalDebit)}</strong>
            </div>
          </div>

          <div className="glass-card" style={{ overflow: "hidden" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", textAlign: "left", fontSize: "0.85rem" }}>
              <thead>
                <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                  <th style={{ padding: "0.85rem 1.25rem" }}>Code</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Account</th>
                  <th style={{ padding: "0.85rem 1rem" }}>Classification</th>
                  <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Debit (₹)</th>
                  <th style={{ padding: "0.85rem 1rem", textAlign: "right" }}>Credit (₹)</th>
                </tr>
              </thead>
              <tbody>
                {trialBalance.accounts?.map((a: any) => (
                  <tr key={a.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                    <td style={{ padding: "0.75rem 1.25rem", fontFamily: "var(--font-mono)", color: "#0F766E" }}>{a.code}</td>
                    <td style={{ padding: "0.75rem 1rem", fontWeight: 600 }}>{a.name}</td>
                    <td style={{ padding: "0.75rem 1rem", color: "#64748B", fontSize: "0.78rem" }}>{a.type}</td>
                    <td style={{ padding: "0.75rem 1rem", textAlign: "right", fontWeight: a.debit > 0 ? 700 : 400 }}>
                      {a.debit > 0 ? formatINR(a.debit) : "—"}
                    </td>
                    <td style={{ padding: "0.75rem 1rem", textAlign: "right", fontWeight: a.credit > 0 ? 700 : 400 }}>
                      {a.credit > 0 ? formatINR(a.credit) : "—"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 4: AR & AP Aging */}
      {activeSubTab === "AGING" && (
        <div style={{ display: "grid", gap: "1.75rem" }}>
          {/* AR Aging */}
          <div className="glass-card" style={{ padding: "1.5rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h4 style={{ fontSize: "1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Customer Accounts Receivable (AR) Aging
              </h4>
              <span style={{ fontSize: "0.85rem", fontWeight: 700, color: "#DC2626" }}>
                Total Debt: {formatINR(arAging?.summary?.totalReceivables || 0)}
              </span>
            </div>

            {arAging?.customers?.length === 0 ? (
              <div style={{ textAlign: "center", padding: "1rem", color: "#94A3B8" }}>
                All customer credit debts are settled.
              </div>
            ) : (
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.82rem" }}>
                <thead>
                  <tr style={{ backgroundColor: "#F1F5F9", color: "#475569" }}>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "left" }}>Customer</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>Total Debt</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>0-30 Days</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>31-60 Days</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>90+ Days</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "center" }}>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {arAging?.customers?.map((item: any) => (
                    <tr key={item.customer.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                      <td style={{ padding: "0.7rem 0.75rem", fontWeight: 700 }}>
                        {item.customer.name} ({item.customer.mobile})
                      </td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right", fontWeight: 700, color: "#DC2626" }}>
                        {formatINR(item.totalOutstanding)}
                      </td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right" }}>{formatINR(item.buckets.current0To30)}</td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right" }}>{formatINR(item.buckets.days31To60)}</td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right" }}>{formatINR(item.buckets.over90Days)}</td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "center" }}>
                        <button
                          onClick={() => {
                            setPayCustomerId(item.customer.id);
                            setPayCustomerName(item.customer.name);
                            setPayMaxDebt(Number(item.totalOutstanding));
                            setPayAmount(Number(item.totalOutstanding));
                            setIsPaymentOpen(true);
                          }}
                          style={{
                            padding: "0.3rem 0.7rem",
                            backgroundColor: "#059669",
                            color: "#FFFFFF",
                            border: "none",
                            borderRadius: "5px",
                            fontSize: "0.75rem",
                            fontWeight: 600,
                            cursor: "pointer",
                          }}
                        >
                          Receive Payment
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* AP Aging */}
          <div className="glass-card" style={{ padding: "1.5rem" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
              <h4 style={{ fontSize: "1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                Supplier Accounts Payable (AP) Aging
              </h4>
              <span style={{ fontSize: "0.85rem", fontWeight: 700, color: "#D97706" }}>
                Total Payables: {formatINR(apAging?.summary?.totalPayables || 0)}
              </span>
            </div>

            {apAging?.suppliers?.length === 0 ? (
              <div style={{ textAlign: "center", padding: "1rem", color: "#94A3B8" }}>
                All supplier purchase invoices are settled.
              </div>
            ) : (
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.82rem" }}>
                <thead>
                  <tr style={{ backgroundColor: "#F1F5F9", color: "#475569" }}>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "left" }}>Distributor</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>Total Outstanding</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>0-30 Days</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>31-60 Days</th>
                    <th style={{ padding: "0.6rem 0.75rem", textAlign: "right" }}>90+ Days</th>
                  </tr>
                </thead>
                <tbody>
                  {apAging?.suppliers?.map((item: any) => (
                    <tr key={item.supplier.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                      <td style={{ padding: "0.7rem 0.75rem", fontWeight: 700 }}>{item.supplier.name}</td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right", fontWeight: 700, color: "#D97706" }}>
                        {formatINR(item.totalOutstanding)}
                      </td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right" }}>{formatINR(item.buckets.current0To30)}</td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right" }}>{formatINR(item.buckets.days31To60)}</td>
                      <td style={{ padding: "0.7rem 0.75rem", textAlign: "right" }}>{formatINR(item.buckets.over90Days)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {/* Tab 5: Daybook */}
      {activeSubTab === "DAYBOOK" && daybook && (
        <div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1.25rem", marginBottom: "1.5rem" }}>
            <div className="glass-card" style={{ padding: "1.5rem" }}>
              <div style={{ fontSize: "0.8rem", color: "#64748B", fontWeight: 700 }}>CASH DRAWER RECONCILIATION</div>
              <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#059669", marginTop: "0.25rem" }}>
                {formatINR(daybook.cash?.closingBalance)}
              </div>
              <div style={{ display: "flex", gap: "1rem", fontSize: "0.8rem", color: "#64748B", marginTop: "0.5rem" }}>
                <span>In: <strong style={{ color: "#059669" }}>+{formatINR(daybook.cash?.totalIn)}</strong></span>
                <span>Out: <strong style={{ color: "#DC2626" }}>-{formatINR(daybook.cash?.totalOut)}</strong></span>
              </div>
            </div>

            <div className="glass-card" style={{ padding: "1.5rem" }}>
              <div style={{ fontSize: "0.8rem", color: "#64748B", fontWeight: 700 }}>BANK ACCOUNT MOVEMENT</div>
              <div style={{ fontSize: "1.6rem", fontWeight: 800, color: "#0284C7", marginTop: "0.25rem" }}>
                {formatINR(daybook.bank?.closingBalance)}
              </div>
              <div style={{ display: "flex", gap: "1rem", fontSize: "0.8rem", color: "#64748B", marginTop: "0.5rem" }}>
                <span>In: <strong style={{ color: "#059669" }}>+{formatINR(daybook.bank?.totalIn)}</strong></span>
                <span>Out: <strong style={{ color: "#DC2626" }}>-{formatINR(daybook.bank?.totalOut)}</strong></span>
              </div>
            </div>
          </div>

          <div className="glass-card" style={{ padding: "1.5rem" }}>
            <h4 style={{ fontSize: "1rem", fontWeight: 700, color: "#0F172A", marginBottom: "1rem" }}>
              Today's Reconciled Transactions
            </h4>
            {daybook.cash?.transactions?.length === 0 ? (
              <div style={{ textAlign: "center", padding: "1rem", color: "#94A3B8" }}>No transactions today.</div>
            ) : (
              <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.82rem" }}>
                <thead>
                  <tr style={{ backgroundColor: "#F1F5F9", color: "#475569" }}>
                    <th style={{ padding: "0.55rem 0.75rem", textAlign: "left" }}>Entry Number</th>
                    <th style={{ padding: "0.55rem 0.75rem", textAlign: "left" }}>Narration</th>
                    <th style={{ padding: "0.55rem 0.75rem", textAlign: "left" }}>Type</th>
                    <th style={{ padding: "0.55rem 0.75rem", textAlign: "right" }}>Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {daybook.cash?.transactions?.map((t: any, idx: number) => (
                    <tr key={idx} style={{ borderBottom: "1px solid #F1F5F9" }}>
                      <td style={{ padding: "0.6rem 0.75rem", fontFamily: "var(--font-mono)", fontWeight: 700 }}>{t.entryNumber}</td>
                      <td style={{ padding: "0.6rem 0.75rem" }}>{t.narration}</td>
                      <td style={{ padding: "0.6rem 0.75rem", fontWeight: 700, color: t.type === "DEBIT" ? "#059669" : "#DC2626" }}>
                        {t.type}
                      </td>
                      <td style={{ padding: "0.6rem 0.75rem", textAlign: "right", fontWeight: 700 }}>
                        {formatINR(t.amount)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      )}

      {/* Record Expense Modal */}
      {isExpenseOpen && (
        <div style={{ position: "fixed", inset: 0, zIndex: 999, backgroundColor: "rgba(13, 24, 34, 0.6)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }} className="animate-scale-in">
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "14px", width: "100%", maxWidth: "480px", border: "1px solid #E2E8F0", overflow: "hidden" }}>
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>Record Operating Expense</h3>
              <button onClick={() => setIsExpenseOpen(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}><X size={20} /></button>
            </div>
            <form onSubmit={handleExpenseSubmit} style={{ padding: "1.5rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>Expense Account Head *</label>
                <select value={expenseAccountId} onChange={(e) => setExpenseAccountId(e.target.value)} style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", backgroundColor: "#FFFFFF" }}>
                  {accounts.filter((a) => a.type === "EXPENSE").map((a) => (
                    <option key={a.id} value={a.id}>{a.name} ({a.code})</option>
                  ))}
                </select>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "1rem", marginBottom: "1rem" }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>Paid From Source *</label>
                  <select value={expensePaidFromId} onChange={(e) => setExpensePaidFromId(e.target.value)} style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem", backgroundColor: "#FFFFFF" }}>
                    {accounts.filter((a) => a.type === "ASSET" && (a.code === "1010" || a.code === "1020")).map((a) => (
                      <option key={a.id} value={a.id}>{a.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>Amount (₹) *</label>
                  <input type="number" min="1" step="0.01" value={expenseAmount} onChange={(e) => setExpenseAmount(Number(e.target.value))} style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem" }} />
                </div>
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>Description / Purpose *</label>
                <input type="text" required value={expenseDesc} onChange={(e) => setExpenseDesc(e.target.value)} placeholder="e.g. Monthly clinic power & electricity bill" style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem" }} />
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button type="button" onClick={() => setIsExpenseOpen(false)} style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem" }}>Cancel</button>
                <button type="submit" style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700 }}>Record Expense</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Customer Debt Payment Modal */}
      {isPaymentOpen && (
        <div style={{ position: "fixed", inset: 0, zIndex: 999, backgroundColor: "rgba(13, 24, 34, 0.6)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }} className="animate-scale-in">
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "14px", width: "100%", maxWidth: "440px", border: "1px solid #E2E8F0", overflow: "hidden" }}>
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>Receive Customer Debt Settlement</h3>
              <button onClick={() => setIsPaymentOpen(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}><X size={20} /></button>
            </div>
            <form onSubmit={handlePaymentSubmit} style={{ padding: "1.5rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <div style={{ fontSize: "0.85rem", color: "#64748B" }}>Patient: <strong>{payCustomerName}</strong></div>
                <div style={{ fontSize: "0.85rem", color: "#DC2626" }}>Current Total Debt: <strong>{formatINR(payMaxDebt)}</strong></div>
              </div>
              <div style={{ marginBottom: "1.5rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>Payment Amount Received (₹) *</label>
                <input type="number" min="1" max={payMaxDebt} value={payAmount} onChange={(e) => setPayAmount(Number(e.target.value))} style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "1rem", fontWeight: 700 }} />
              </div>
              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button type="button" onClick={() => setIsPaymentOpen(false)} style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem" }}>Cancel</button>
                <button type="submit" style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: "#059669", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700 }}>Confirm Receipt</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Manual Journal Modal with Live Invariant Balance Checker */}
      {isJournalOpen && (
        <div style={{ position: "fixed", inset: 0, zIndex: 999, backgroundColor: "rgba(13, 24, 34, 0.6)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center", padding: "1rem" }} className="animate-scale-in">
          <div style={{ backgroundColor: "#FFFFFF", borderRadius: "14px", width: "100%", maxWidth: "600px", border: "1px solid #E2E8F0", overflow: "hidden" }}>
            <div style={{ padding: "1.25rem 1.5rem", display: "flex", alignItems: "center", justifyContent: "space-between", borderBottom: "1px solid #F1F5F9" }}>
              <h3 style={{ fontSize: "1.05rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>Post Manual Double-Entry Journal</h3>
              <button onClick={() => setIsJournalOpen(false)} style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}><X size={20} /></button>
            </div>
            <form onSubmit={handleJournalSubmit} style={{ padding: "1.5rem" }}>
              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.35rem" }}>Narration / Memo *</label>
                <input type="text" required value={journalNarration} onChange={(e) => setJournalNarration(e.target.value)} placeholder="e.g. Owner capital injection or year-end adjustment" style={{ width: "100%", padding: "0.6rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.85rem" }} />
              </div>

              <div style={{ marginBottom: "1rem" }}>
                <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 600, color: "#334155", marginBottom: "0.5rem" }}>Journal Lines (Debit & Credit)</label>
                {journalLines.map((line, idx) => (
                  <div key={idx} style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr", gap: "0.5rem", marginBottom: "0.5rem" }}>
                    <select value={line.accountId} onChange={(e) => { const updated = [...journalLines]; updated[idx].accountId = e.target.value; setJournalLines(updated); }} style={{ padding: "0.5rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.82rem", backgroundColor: "#FFFFFF" }}>
                      {accounts.map((a) => (
                        <option key={a.id} value={a.id}>{a.name} ({a.code})</option>
                      ))}
                    </select>
                    <select value={line.type} onChange={(e) => { const updated = [...journalLines]; updated[idx].type = e.target.value as any; setJournalLines(updated); }} style={{ padding: "0.5rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.82rem", backgroundColor: "#FFFFFF" }}>
                      <option value="DEBIT">DEBIT</option>
                      <option value="CREDIT">CREDIT</option>
                    </select>
                    <input type="number" min="1" step="0.01" value={line.amount} onChange={(e) => { const updated = [...journalLines]; updated[idx].amount = Number(e.target.value); setJournalLines(updated); }} style={{ padding: "0.5rem", borderRadius: "6px", border: "1px solid #CBD5E1", fontSize: "0.82rem" }} />
                  </div>
                ))}
              </div>

              {/* Invariant Checker Badge */}
              <div style={{ padding: "0.75rem", borderRadius: "8px", backgroundColor: isJournalBalanced ? "#ECFDF5" : "rgba(239, 68, 68, 0.1)", border: isJournalBalanced ? "1px solid #10B981" : "1px solid #DC2626", marginBottom: "1.25rem", display: "flex", justifyContent: "space-between", fontSize: "0.82rem" }}>
                <span>Debit Total: <strong>{formatINR(journalDebitSum)}</strong></span>
                <span>Credit Total: <strong>{formatINR(journalCreditSum)}</strong></span>
                <span style={{ fontWeight: 700, color: isJournalBalanced ? "#065F46" : "#DC2626" }}>
                  {isJournalBalanced ? "✓ Balanced" : `✗ Unbalanced (Diff: ${formatINR(Math.abs(journalDebitSum - journalCreditSum))})`}
                </span>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "0.75rem" }}>
                <button type="button" onClick={() => setIsJournalOpen(false)} style={{ padding: "0.55rem 1.1rem", borderRadius: "6px", border: "1px solid #CBD5E1", backgroundColor: "#FFFFFF", fontSize: "0.85rem" }}>Cancel</button>
                <button type="submit" disabled={!isJournalBalanced} style={{ padding: "0.55rem 1.25rem", borderRadius: "6px", border: "none", backgroundColor: isJournalBalanced ? "#059669" : "#CBD5E1", color: "#FFFFFF", fontSize: "0.85rem", fontWeight: 700, cursor: isJournalBalanced ? "pointer" : "not-allowed" }}>Post Entry</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Account General Ledger Statement Modal */}
      {selectedAccount && (
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
              maxWidth: "840px",
              maxHeight: "90vh",
              display: "flex",
              flexDirection: "column",
              border: "1px solid #E2E8F0",
              boxShadow: "0 20px 25px -5px rgba(0,0,0,0.2)",
              overflow: "hidden",
            }}
          >
            {/* Header */}
            <div
              style={{
                padding: "1.25rem 1.5rem",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                borderBottom: "1px solid #F1F5F9",
                backgroundColor: "#F8FAF9",
              }}
            >
              <div>
                <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                  <span
                    style={{
                      padding: "0.2rem 0.5rem",
                      borderRadius: "4px",
                      backgroundColor: "#0F766E",
                      color: "#FFFFFF",
                      fontFamily: "var(--font-mono)",
                      fontSize: "0.8rem",
                      fontWeight: 700,
                    }}
                  >
                    {selectedAccount.code}
                  </span>
                  <h3 style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F172A", margin: 0 }}>
                    {selectedAccount.name}
                  </h3>
                  <span
                    style={{
                      padding: "0.15rem 0.5rem",
                      borderRadius: "9999px",
                      fontSize: "0.72rem",
                      fontWeight: 700,
                      backgroundColor: "#F1F5F9",
                      color: "#475569",
                    }}
                  >
                    {selectedAccount.type}
                  </span>
                </div>
                <div style={{ fontSize: "0.8rem", color: "#64748B", marginTop: "0.25rem" }}>
                  General Ledger Statement & Chronological Double-Entry Journal Trail
                </div>
              </div>
              <button
                onClick={() => {
                  setSelectedAccount(null);
                  setLedgerStatement(null);
                }}
                style={{ background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}
              >
                <X size={20} />
              </button>
            </div>

            {/* Summary Ribbon */}
            <div
              style={{
                padding: "1rem 1.5rem",
                borderBottom: "1px solid #E2E8F0",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                backgroundColor: "#FFFFFF",
              }}
            >
              <div>
                <span style={{ fontSize: "0.78rem", color: "#64748B", fontWeight: 600 }}>CURRENT LIVE BALANCE</span>
                <div style={{ fontSize: "1.35rem", fontWeight: 800, color: "#0F172A" }}>
                  {formatINR(selectedAccount.currentBalance)}
                </div>
              </div>
              <div style={{ textAlign: "right" }}>
                <span style={{ fontSize: "0.75rem", color: "#64748B", fontWeight: 600 }}>RECONCILED TRANSACTIONS</span>
                <div style={{ fontSize: "1.1rem", fontWeight: 700, color: "#0F766E" }}>
                  {ledgerStatement?.transactions?.length || 0} Entries
                </div>
              </div>
            </div>

            {/* Content Table */}
            <div style={{ padding: "1.25rem 1.5rem", overflowY: "auto", flex: 1 }}>
              {isLedgerLoading ? (
                <TableSkeleton rows={4} cols={5} />
              ) : !ledgerStatement?.transactions || ledgerStatement.transactions.length === 0 ? (
                <EmptyState
                  icon={<FileText size={32} />}
                  title="No Journal Transactions Found"
                  description="No debits or credits have been posted to this general ledger account yet."
                />
              ) : (
                <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.82rem", textAlign: "left" }}>
                  <thead>
                    <tr style={{ backgroundColor: "#F8FAF9", borderBottom: "1px solid #E2E8F0", color: "#64748B", fontWeight: 700 }}>
                      <th style={{ padding: "0.65rem 0.75rem" }}>Date</th>
                      <th style={{ padding: "0.65rem 0.75rem" }}>Voucher / JE #</th>
                      <th style={{ padding: "0.65rem 0.75rem" }}>Ref Type</th>
                      <th style={{ padding: "0.65rem 0.75rem" }}>Narration</th>
                      <th style={{ padding: "0.65rem 0.75rem", textAlign: "right" }}>Debit (₹)</th>
                      <th style={{ padding: "0.65rem 0.75rem", textAlign: "right" }}>Credit (₹)</th>
                      <th style={{ padding: "0.65rem 0.75rem", textAlign: "right" }}>Balance (₹)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {ledgerStatement.transactions.map((t: any) => (
                      <tr key={t.id} style={{ borderBottom: "1px solid #F1F5F9" }}>
                        <td style={{ padding: "0.65rem 0.75rem", color: "#64748B" }}>
                          {formatDate(t.date)}
                        </td>
                        <td style={{ padding: "0.65rem 0.75rem", fontFamily: "var(--font-mono)", fontWeight: 700, color: "#0F766E" }}>
                          {t.entryNumber}
                        </td>
                        <td style={{ padding: "0.65rem 0.75rem" }}>
                          <span style={{ padding: "0.15rem 0.45rem", borderRadius: "4px", backgroundColor: "#F1F5F9", fontSize: "0.72rem", fontWeight: 600 }}>
                            {t.referenceType}
                          </span>
                        </td>
                        <td style={{ padding: "0.65rem 0.75rem", color: "#334155" }}>
                          {t.narration || "—"}
                        </td>
                        <td style={{ padding: "0.65rem 0.75rem", textAlign: "right", fontWeight: t.debit > 0 ? 700 : 400, color: t.debit > 0 ? "#059669" : "#64748B" }}>
                          {t.debit > 0 ? formatINR(t.debit) : "—"}
                        </td>
                        <td style={{ padding: "0.65rem 0.75rem", textAlign: "right", fontWeight: t.credit > 0 ? 700 : 400, color: t.credit > 0 ? "#DC2626" : "#64748B" }}>
                          {t.credit > 0 ? formatINR(t.credit) : "—"}
                        </td>
                        <td style={{ padding: "0.65rem 0.75rem", textAlign: "right", fontWeight: 700, color: "#0F172A" }}>
                          {formatINR(t.balance)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>

            {/* Footer */}
            <div style={{ padding: "1rem 1.5rem", borderTop: "1px solid #F1F5F9", display: "flex", justifyContent: "flex-end" }}>
              <button
                onClick={() => {
                  setSelectedAccount(null);
                  setLedgerStatement(null);
                }}
                style={{
                  padding: "0.5rem 1.25rem",
                  borderRadius: "6px",
                  border: "1px solid #CBD5E1",
                  backgroundColor: "#FFFFFF",
                  fontSize: "0.85rem",
                  fontWeight: 600,
                  cursor: "pointer",
                }}
              >
                Close Statement
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Modal */}
      <ConfirmModal
        isOpen={confirmModal.isOpen}
        title={confirmModal.title}
        message={confirmModal.message}
        onConfirm={confirmModal.action}
        onCancel={() => setConfirmModal((prev) => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
};
