double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

/// ---------------------------------------------------------------------------
/// 1. Chart of Accounts (COA)
/// ---------------------------------------------------------------------------
class AccountGroupModel {
  final String? id;
  final String code;
  final String name;
  final String? type;

  AccountGroupModel({
    this.id,
    required this.code,
    required this.name,
    this.type,
  });

  factory AccountGroupModel.fromJson(Map<String, dynamic> json) {
    return AccountGroupModel(
      id: json['id']?.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
    );
  }
}

class AccountSummaryModel {
  final String? id;
  final String code;
  final String name;
  final String? type;

  AccountSummaryModel({
    this.id,
    required this.code,
    required this.name,
    this.type,
  });

  factory AccountSummaryModel.fromJson(Map<String, dynamic> json) {
    return AccountSummaryModel(
      id: json['id']?.toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
    );
  }
}

class AccountModel {
  final String id;
  final String code;
  final String name;
  final String type; // ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
  final String? groupId;
  final String? description;
  final bool isSystem;
  final double currentBalance;
  final AccountGroupModel? group;

  AccountModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.groupId,
    this.description,
    this.isSystem = false,
    required this.currentBalance,
    this.group,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final grpJson = json['group'] as Map<String, dynamic>?;

    return AccountModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ASSET',
      groupId: json['groupId']?.toString(),
      description: json['description']?.toString(),
      isSystem: json['isSystem'] == true,
      currentBalance: _parseDouble(json['currentBalance']),
      group: grpJson != null ? AccountGroupModel.fromJson(grpJson) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// ---------------------------------------------------------------------------
/// 2. Double-Entry Journal System
/// ---------------------------------------------------------------------------
class JournalLineModel {
  final String? id;
  final String accountId;
  final String type; // DEBIT or CREDIT
  final double amount;
  final String? narration;
  final AccountSummaryModel? account;

  JournalLineModel({
    this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    this.narration,
    this.account,
  });

  factory JournalLineModel.fromJson(Map<String, dynamic> json) {
    final accJson = json['account'] as Map<String, dynamic>?;

    return JournalLineModel(
      id: json['id']?.toString(),
      accountId: json['accountId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DEBIT',
      amount: _parseDouble(json['amount']),
      narration: json['narration']?.toString(),
      account: accJson != null ? AccountSummaryModel.fromJson(accJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'type': type,
        'amount': amount,
        if (narration != null) 'narration': narration,
      };
}

class JournalEntryModel {
  final String id;
  final String entryNumber;
  final DateTime? entryDate;
  final String referenceType;
  final String? referenceId;
  final String narration;
  final String status;
  final double totalDebit;
  final double totalCredit;
  final String? createdById;
  final List<JournalLineModel> lines;

  JournalEntryModel({
    required this.id,
    required this.entryNumber,
    this.entryDate,
    required this.referenceType,
    this.referenceId,
    required this.narration,
    required this.status,
    required this.totalDebit,
    required this.totalCredit,
    this.createdById,
    required this.lines,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    final linesList = (json['lines'] as List?)
            ?.map((item) => JournalLineModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return JournalEntryModel(
      id: json['id']?.toString() ?? '',
      entryNumber: json['entryNumber']?.toString() ?? '',
      entryDate: json['entryDate'] != null ? DateTime.tryParse(json['entryDate']) : null,
      referenceType: json['referenceType']?.toString() ?? 'MANUAL',
      referenceId: json['referenceId']?.toString(),
      narration: json['narration']?.toString() ?? '',
      status: json['status']?.toString() ?? 'POSTED',
      totalDebit: _parseDouble(json['totalDebit']),
      totalCredit: _parseDouble(json['totalCredit']),
      createdById: json['createdById']?.toString(),
      lines: linesList,
    );
  }
}

/// ---------------------------------------------------------------------------
/// 3. Financial Statements & General Ledgers
/// ---------------------------------------------------------------------------
class TrialBalanceAccountModel {
  final String id;
  final String code;
  final String name;
  final String type;
  final String group;
  final double debit;
  final double credit;

  TrialBalanceAccountModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.group,
    required this.debit,
    required this.credit,
  });

  factory TrialBalanceAccountModel.fromJson(Map<String, dynamic> json) {
    return TrialBalanceAccountModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ASSET',
      group: json['group']?.toString() ?? '',
      debit: _parseDouble(json['debit']),
      credit: _parseDouble(json['credit']),
    );
  }
}

class TrialBalanceModel {
  final List<TrialBalanceAccountModel> accounts;
  final double totalDebit;
  final double totalCredit;
  final double difference;
  final bool isBalanced;

  TrialBalanceModel({
    required this.accounts,
    required this.totalDebit,
    required this.totalCredit,
    required this.difference,
    required this.isBalanced,
  });

  factory TrialBalanceModel.fromJson(Map<String, dynamic> json) {
    final accs = (json['accounts'] as List?)
            ?.map((item) => TrialBalanceAccountModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return TrialBalanceModel(
      accounts: accs,
      totalDebit: _parseDouble(json['totalDebit']),
      totalCredit: _parseDouble(json['totalCredit']),
      difference: _parseDouble(json['difference']),
      isBalanced: json['isBalanced'] == true,
    );
  }
}

class LedgerTransactionModel {
  final String id;
  final DateTime? date;
  final String entryNumber;
  final String referenceType;
  final String narration;
  final double debit;
  final double credit;
  final double runningBalance;

  LedgerTransactionModel({
    required this.id,
    this.date,
    required this.entryNumber,
    required this.referenceType,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });

  factory LedgerTransactionModel.fromJson(Map<String, dynamic> json) {
    return LedgerTransactionModel(
      id: json['id']?.toString() ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      entryNumber: json['entryNumber']?.toString() ?? '',
      referenceType: json['referenceType']?.toString() ?? '',
      narration: json['narration']?.toString() ?? '',
      debit: _parseDouble(json['debit']),
      credit: _parseDouble(json['credit']),
      runningBalance: _parseDouble(json['runningBalance']),
    );
  }
}

class GeneralLedgerModel {
  final AccountModel account;
  final List<LedgerTransactionModel> transactions;

  GeneralLedgerModel({
    required this.account,
    required this.transactions,
  });

  factory GeneralLedgerModel.fromJson(Map<String, dynamic> json) {
    final acc = AccountModel.fromJson(json['account'] as Map<String, dynamic>? ?? {});
    final txs = (json['transactions'] as List?)
            ?.map((item) => LedgerTransactionModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return GeneralLedgerModel(
      account: acc,
      transactions: txs,
    );
  }
}

/// ---------------------------------------------------------------------------
/// 4. Operating Expenses
/// ---------------------------------------------------------------------------
class ExpenseModel {
  final String id;
  final String expenseNumber;
  final DateTime? expenseDate;
  final String accountId;
  final String paidFromAccountId;
  final double amount;
  final String paymentMode; // CASH, BANK_TRANSFER, UPI, CHEQUE
  final String? referenceNumber;
  final String? payee;
  final String? description;
  final String? journalEntryId;
  final AccountSummaryModel? account;
  final AccountSummaryModel? paidFromAccount;
  final String? journalEntryNumber;

  ExpenseModel({
    required this.id,
    required this.expenseNumber,
    this.expenseDate,
    required this.accountId,
    required this.paidFromAccountId,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    this.payee,
    this.description,
    this.journalEntryId,
    this.account,
    this.paidFromAccount,
    this.journalEntryNumber,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final accJson = json['account'] as Map<String, dynamic>?;
    final paidAccJson = json['paidFromAccount'] as Map<String, dynamic>?;
    final jeJson = json['journalEntry'] as Map<String, dynamic>?;

    return ExpenseModel(
      id: json['id']?.toString() ?? '',
      expenseNumber: json['expenseNumber']?.toString() ?? '',
      expenseDate: json['expenseDate'] != null ? DateTime.tryParse(json['expenseDate']) : null,
      accountId: json['accountId']?.toString() ?? '',
      paidFromAccountId: json['paidFromAccountId']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      paymentMode: json['paymentMode']?.toString() ?? 'CASH',
      referenceNumber: json['referenceNumber']?.toString(),
      payee: json['payee']?.toString(),
      description: json['description']?.toString(),
      journalEntryId: json['journalEntryId']?.toString(),
      account: accJson != null ? AccountSummaryModel.fromJson(accJson) : null,
      paidFromAccount: paidAccJson != null ? AccountSummaryModel.fromJson(paidAccJson) : null,
      journalEntryNumber: jeJson?['entryNumber']?.toString(),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 5. Receivables & Payables Aging
/// ---------------------------------------------------------------------------
class AgingBucketsModel {
  final double current0To30;
  final double days31To60;
  final double days61To90;
  final double over90Days;

  AgingBucketsModel({
    required this.current0To30,
    required this.days31To60,
    required this.days61To90,
    required this.over90Days,
  });

  factory AgingBucketsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AgingBucketsModel(current0To30: 0, days31To60: 0, days61To90: 0, over90Days: 0);
    }
    return AgingBucketsModel(
      current0To30: _parseDouble(json['current0To30']),
      days31To60: _parseDouble(json['days31To60']),
      days61To90: _parseDouble(json['days61To90']),
      over90Days: _parseDouble(json['over90Days']),
    );
  }
}

class PartyAgingModel {
  final String partyId;
  final String name;
  final String mobile;
  final double totalOutstanding;
  final AgingBucketsModel buckets;

  PartyAgingModel({
    required this.partyId,
    required this.name,
    required this.mobile,
    required this.totalOutstanding,
    required this.buckets,
  });

  factory PartyAgingModel.fromJsonCustomer(Map<String, dynamic> json) {
    final cust = json['customer'] as Map<String, dynamic>? ?? {};
    return PartyAgingModel(
      partyId: cust['id']?.toString() ?? '',
      name: cust['name']?.toString() ?? '',
      mobile: cust['mobile']?.toString() ?? '',
      totalOutstanding: _parseDouble(json['totalOutstanding']),
      buckets: AgingBucketsModel.fromJson(json['buckets'] as Map<String, dynamic>?),
    );
  }

  factory PartyAgingModel.fromJsonSupplier(Map<String, dynamic> json) {
    final supp = json['supplier'] as Map<String, dynamic>? ?? {};
    return PartyAgingModel(
      partyId: supp['id']?.toString() ?? '',
      name: supp['name']?.toString() ?? '',
      mobile: supp['mobile']?.toString() ?? '',
      totalOutstanding: _parseDouble(json['totalOutstanding']),
      buckets: AgingBucketsModel.fromJson(json['buckets'] as Map<String, dynamic>?),
    );
  }
}

class AgingReportModel {
  final double totalAmount;
  final AgingBucketsModel summaryBuckets;
  final List<PartyAgingModel> items;

  AgingReportModel({
    required this.totalAmount,
    required this.summaryBuckets,
    required this.items,
  });

  factory AgingReportModel.fromJsonReceivables(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final list = (json['customers'] as List?)
            ?.map((item) => PartyAgingModel.fromJsonCustomer(item as Map<String, dynamic>))
            .toList() ??
        [];

    return AgingReportModel(
      totalAmount: _parseDouble(summary['totalReceivables']),
      summaryBuckets: AgingBucketsModel.fromJson(summary['buckets'] as Map<String, dynamic>?),
      items: list,
    );
  }

  factory AgingReportModel.fromJsonPayables(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final list = (json['suppliers'] as List?)
            ?.map((item) => PartyAgingModel.fromJsonSupplier(item as Map<String, dynamic>))
            .toList() ??
        [];

    return AgingReportModel(
      totalAmount: _parseDouble(summary['totalPayables']),
      summaryBuckets: AgingBucketsModel.fromJson(summary['buckets'] as Map<String, dynamic>?),
      items: list,
    );
  }
}

/// ---------------------------------------------------------------------------
/// 6. Cash & Bank Daybook
/// ---------------------------------------------------------------------------
class DaybookTransactionModel {
  final String entryNumber;
  final String narration;
  final String type; // DEBIT or CREDIT
  final double amount;

  DaybookTransactionModel({
    required this.entryNumber,
    required this.narration,
    required this.type,
    required this.amount,
  });

  factory DaybookTransactionModel.fromJson(Map<String, dynamic> json) {
    return DaybookTransactionModel(
      entryNumber: json['entryNumber']?.toString() ?? '',
      narration: json['narration']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DEBIT',
      amount: _parseDouble(json['amount']),
    );
  }
}

class DaybookAccountMovementModel {
  final double openingBalance;
  final double totalIn;
  final double totalOut;
  final double netMovement;
  final double closingBalance;
  final List<DaybookTransactionModel> transactions;

  DaybookAccountMovementModel({
    required this.openingBalance,
    required this.totalIn,
    required this.totalOut,
    required this.netMovement,
    required this.closingBalance,
    required this.transactions,
  });

  factory DaybookAccountMovementModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DaybookAccountMovementModel(
        openingBalance: 0,
        totalIn: 0,
        totalOut: 0,
        netMovement: 0,
        closingBalance: 0,
        transactions: [],
      );
    }

    final txs = (json['transactions'] as List?)
            ?.map((item) => DaybookTransactionModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return DaybookAccountMovementModel(
      openingBalance: _parseDouble(json['openingBalance']),
      totalIn: _parseDouble(json['totalIn']),
      totalOut: _parseDouble(json['totalOut']),
      netMovement: _parseDouble(json['netMovement']),
      closingBalance: _parseDouble(json['closingBalance']),
      transactions: txs,
    );
  }
}

class DaybookStatementModel {
  final String date;
  final DaybookAccountMovementModel cash;
  final DaybookAccountMovementModel bank;

  DaybookStatementModel({
    required this.date,
    required this.cash,
    required this.bank,
  });

  factory DaybookStatementModel.fromJson(Map<String, dynamic> json) {
    return DaybookStatementModel(
      date: json['date']?.toString() ?? '',
      cash: DaybookAccountMovementModel.fromJson(json['cash'] as Map<String, dynamic>?),
      bank: DaybookAccountMovementModel.fromJson(json['bank'] as Map<String, dynamic>?),
    );
  }
}
