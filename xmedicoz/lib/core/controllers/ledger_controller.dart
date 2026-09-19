import 'package:get/get.dart';
import '../../features/inventory/controllers/master_data_controller.dart';
import '../../features/accounting/controllers/accounting_controller.dart';
import '../../features/sales/controllers/sales_controller.dart';
import '../../features/purchases/controllers/purchases_controller.dart';
import '../storage/storage_service.dart';
import '../models/models.dart';

class LedgerController extends GetxController {
  // Active Shop (Reactive)
  late Rx<ShopModel> activeShop;

  // Reactive Collections
  final RxList<ShopModel> shops = <ShopModel>[].obs;
  final RxList<StockItemModel> stockItems = <StockItemModel>[].obs;
  final RxList<PartyModel> parties = <PartyModel>[].obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final savedShop = StorageService.getShop();
    if (savedShop != null) {
      shops.assignAll([savedShop]);
    } else {
      shops.assignAll(MockDataService.shops);
    }
    // Zero mock fallback for stock & parties & transactions - 100% Live from API
    stockItems.clear();
    parties.clear();
    transactions.clear();
    activeShop = shops.first.obs;
    syncLiveTransactions();
  }

  /// Populate transactions live from Sales and Purchases APIs
  void syncLiveTransactions() {
    final List<TransactionModel> liveList = [];

    // 1. Live Sales Invoices
    if (Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      for (final s in sales) {
        final isCredit = s.isCreditSale || s.paymentStatus == 'UNPAID';
        final isCash = s.payments.isNotEmpty && s.payments.first.paymentMode.toUpperCase() == 'CASH';
        final isBank = s.payments.isNotEmpty && (s.payments.first.paymentMode.toUpperCase() == 'BANK' || s.payments.first.paymentMode.toUpperCase() == 'CARD');
        final paymentMode = isCredit
            ? PaymentMode.credit
            : (isCash
                ? PaymentMode.cash
                : (isBank ? PaymentMode.bankTransfer : PaymentMode.onlineUpi));
        liveList.add(
          TransactionModel(
            id: s.id,
            invoiceNo: s.invoiceNumber,
            date: s.invoiceDate ?? DateTime.now(),
            partyName: s.customerName.isNotEmpty ? s.customerName : 'Walk-in Retail Patient',
            type: TransactionType.sale,
            paymentMode: paymentMode,
            amount: s.totalAmount,
            itemsCount: s.items.length,
            notes: isCredit ? 'Udhar / Credit Billing' : 'Fast POS Counter Billing',
          ),
        );
      }
    }

    // 2. Live Purchase Bills
    if (Get.isRegistered<PurchasesController>()) {
      final purchases = Get.find<PurchasesController>().purchases;
      for (final p in purchases) {
        liveList.add(
          TransactionModel(
            id: p.id,
            invoiceNo: p.invoiceNumber,
            date: p.invoiceDate ?? DateTime.now(),
            partyName: p.supplier?.name.isNotEmpty == true ? p.supplier!.name : 'Distributor / Stockist',
            type: TransactionType.purchase,
            paymentMode: PaymentMode.bankTransfer,
            amount: p.totalAmount,
            itemsCount: p.items.length,
            notes: 'Supplier Inward Stock Purchase',
          ),
        );
      }
    }

    // Sort by date descending
    liveList.sort((a, b) => b.date.compareTo(a.date));
    transactions.assignAll(liveList);
  }

  void switchShop(ShopModel shop) {
    activeShop.value = shop;
    StorageService.saveShop(shop);
  }

  void addShop(ShopModel newShop) {
    shops.insert(0, newShop);
    activeShop.value = newShop;
    StorageService.saveShop(newShop);
  }

  void updateShop(ShopModel updatedShop) {
    activeShop.value = updatedShop;
    final index = shops.indexWhere((s) => s.id == updatedShop.id);
    if (index != -1) {
      shops[index] = updatedShop;
    }
    StorageService.saveShop(updatedShop);
    activeShop.refresh();
    shops.refresh();
  }

  void addStockItem(StockItemModel item) {
    stockItems.insert(0, item);
  }

  void adjustStock(String itemId, int delta) {
    final index = stockItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final current = stockItems[index];
      final newQty = (current.currentQty + delta).clamp(0, 99999);
      current.currentQty = newQty;
      stockItems.refresh();
    }
  }

  void addParty(PartyModel party) {
    parties.insert(0, party);
  }

  void settleParty(String partyId) {
    final index = parties.indexWhere((p) => p.id == partyId);
    if (index != -1) {
      parties[index].balance = 0.0;
      parties.refresh();
    }
  }

  void addTransaction(TransactionModel tx) {
    transactions.insert(0, tx);

    // Credit transactions do not alter cash or bank balances immediately
    if (tx.paymentMode == PaymentMode.credit) {
      return;
    }

    // Adjust shop cash or bank balance
    if (tx.isInflow) {
      if (tx.paymentMode == PaymentMode.cash) {
        activeShop.value.cashInHand += tx.amount;
      } else {
        activeShop.value.bankBalance += tx.amount;
      }
    } else {
      if (tx.paymentMode == PaymentMode.cash) {
        activeShop.value.cashInHand = (activeShop.value.cashInHand - tx.amount).clamp(0, double.infinity);
      } else {
        activeShop.value.bankBalance = (activeShop.value.bankBalance - tx.amount).clamp(0, double.infinity);
      }
    }
    activeShop.refresh();
  }

  // Live Metrics (Powered directly by Master Data API)
  double get totalStockValuation {
    if (Get.isRegistered<MasterDataController>()) {
      return Get.find<MasterDataController>().totalStockValuation;
    }
    return 0.0;
  }

  double get totalReceivables {
    if (Get.isRegistered<MasterDataController>()) {
      final val = Get.find<MasterDataController>().totalReceivables;
      if (val > 0) return val;
    }
    if (Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      final creditSum = sales
          .where((s) => s.isCreditSale || s.isUnpaid)
          .fold(0.0, (sum, s) => sum + (s.balanceAmount > 0 ? s.balanceAmount : s.totalAmount));
      if (creditSum > 0) return creditSum;
    }
    if (Get.isRegistered<AccountingController>()) {
      final ar = Get.find<AccountingController>().receivablesAging.value?.totalAmount ?? 0.0;
      if (ar > 0) return ar;
    }
    return 0.0;
  }

  double get totalPayables {
    if (Get.isRegistered<MasterDataController>()) {
      final val = Get.find<MasterDataController>().totalPayables;
      if (val > 0) return val;
    }
    if (Get.isRegistered<PurchasesController>()) {
      final purchases = Get.find<PurchasesController>().purchases;
      final unpaidSum = purchases
          .where((p) => p.paymentStatus == 'UNPAID' || p.paymentStatus == 'PARTIALLY_PAID')
          .fold(0.0, (sum, p) => sum + (p.balanceAmount > 0 ? p.balanceAmount : p.totalAmount));
      if (unpaidSum > 0) return unpaidSum;
    }
    if (Get.isRegistered<AccountingController>()) {
      final ap = Get.find<AccountingController>().payablesAging.value?.totalAmount ?? 0.0;
      if (ap > 0) return ap;
    }
    return 0.0;
  }

  double get netSalesToday => transactions
      .where((t) => t.type == TransactionType.sale)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get netPurchasesToday => transactions
      .where((t) => t.type == TransactionType.purchase)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalInflow {
    final cash = cashInflow;
    final online = onlineInflow;
    if (cash > 0 || online > 0) return cash + online;

    if (Get.isRegistered<AccountingController>()) {
      final db = Get.find<AccountingController>().daybook.value;
      if (db != null && (db.cash.totalIn > 0 || db.bank.totalIn > 0)) {
        return db.cash.totalIn + db.bank.totalIn;
      }
    }
    return transactions
        .where((t) => t.isInflow)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalOutflow {
    if (Get.isRegistered<AccountingController>()) {
      final db = Get.find<AccountingController>().daybook.value;
      if (db != null && (db.cash.totalOut > 0 || db.bank.totalOut > 0)) {
        return db.cash.totalOut + db.bank.totalOut;
      }
    }
    return transactions
        .where((t) => !t.isInflow)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get cashInflow {
    if (Get.isRegistered<AccountingController>()) {
      final db = Get.find<AccountingController>().daybook.value;
      if (db != null && db.cash.totalIn > 0) return db.cash.totalIn;
    }
    if (Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      final cashSum = sales
          .where((s) => s.payments.any((p) => p.paymentMode.toUpperCase() == 'CASH'))
          .fold(0.0, (sum, s) => sum + s.paidAmount);
      if (cashSum > 0) return cashSum;
    }
    return transactions
        .where((t) => t.isInflow && t.paymentMode == PaymentMode.cash)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get onlineInflow {
    if (Get.isRegistered<AccountingController>()) {
      final db = Get.find<AccountingController>().daybook.value;
      if (db != null && db.bank.totalIn > 0) return db.bank.totalIn;
    }
    if (Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      final onlineSum = sales
          .where((s) => s.payments.any((p) =>
              p.paymentMode.toUpperCase() == 'UPI' ||
              p.paymentMode.toUpperCase() == 'BANK' ||
              p.paymentMode.toUpperCase() == 'CARD' ||
              p.paymentMode.toUpperCase() == 'ONLINE'))
          .fold(0.0, (sum, s) => sum + s.paidAmount);
      if (onlineSum > 0) return onlineSum;
    }
    return transactions
        .where((t) =>
            t.isInflow &&
            (t.paymentMode == PaymentMode.onlineUpi ||
                t.paymentMode == PaymentMode.bankTransfer))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Pharma-specific metrics
  int get nearExpiryCount => stockItems.where((i) => i.isNearExpiry).length;
  int get lowStockCount => stockItems.where((i) => i.isLowStock).length;
  List<StockItemModel> get nearExpiryItems => stockItems.where((i) => i.isNearExpiry).toList();

  /// Completely clear all in-memory ledger data on logout
  void clearData() {
    stockItems.clear();
    parties.clear();
    transactions.clear();
    shops.clear();
  }
}
