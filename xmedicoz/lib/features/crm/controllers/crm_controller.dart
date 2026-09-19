import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/crm_models.dart';
import '../../../core/models/master_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/unique_snackbar.dart';
import '../../inventory/controllers/master_data_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../repositories/crm_repository.dart';

class CrmController extends GetxController {
  final CrmRepository _repository = CrmRepository();

  // Loading States
  final RxBool isLoadingDueRefills = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool isLoadingRules = false.obs;
  final RxBool isLoadingNotifications = false.obs;
  final RxBool isLoadingFollowUps = false.obs;
  final RxBool isSubmitting = false.obs;

  // Data Lists
  final RxList<DueRefillAlertModel> dueRefills = <DueRefillAlertModel>[].obs;
  final RxList<RefillRuleModel> refillRules = <RefillRuleModel>[].obs;
  final RxList<FollowUpModel> followUps = <FollowUpModel>[].obs;
  final RxList<NotificationLogModel> notificationLogs = <NotificationLogModel>[].obs;

  // Active Customer History (Detail Sheet)
  final Rxn<CustomerHistoryModel> currentCustomerHistory = Rxn<CustomerHistoryModel>();

  // Filter Days for Due Refills
  final RxInt dueDays = 7.obs;

  // Computed Counts
  int get overdueCount => dueRefills.where((r) => r.isOverdue).length;
  int get upcomingDueCount => dueRefills.where((r) => !r.isOverdue).length;
  int get pendingFollowUpsCount => followUps.where((f) => f.status == 'PENDING').length;

  @override
  void onInit() {
    super.onInit();
    if (StorageService.hasToken()) {
      loadCrmDashboardData();
    }
  }

  /// Initial / Refresh Batch Load for Hub
  Future<void> loadCrmDashboardData() async {
    await Future.wait([
      fetchDueRefills(),
      fetchFollowUps(),
      fetchNotificationLogs(),
    ]);
  }

  /// 1. Fetch Due & Overdue Refill Alerts
  Future<void> fetchDueRefills({int? days}) async {
    try {
      isLoadingDueRefills.value = true;
      if (days != null) dueDays.value = days;
      final results = await _repository.getDueRefills(days: dueDays.value);
      dueRefills.assignAll(results);
    } catch (e) {
      debugPrint('Error fetching due refills: $e');
    } finally {
      isLoadingDueRefills.value = false;
    }
  }

  /// 2. Fetch Customer Medical History & Invoices
  Future<CustomerHistoryModel?> fetchCustomerHistory(String customerId) async {
    try {
      isLoadingHistory.value = true;
      final history = await _repository.getCustomerHistory(customerId);
      currentCustomerHistory.value = history;
      return history;
    } catch (e) {
      debugPrint('CRM History API error for customer $customerId: $e');

      // Zero-mock real data fallback:
      // If the customer does not have an existing CRM dossier record on the server,
      // synthesize the real clinical profile from MasterDataController and SalesController.
      CustomerModel? localCustomer;
      if (Get.isRegistered<MasterDataController>()) {
        localCustomer = Get.find<MasterDataController>()
            .customers
            .firstWhereOrNull((c) => c.id == customerId);
      }

      if (localCustomer != null) {
        final List<CustomerHistoryInvoiceModel> customerInvoices = [];
        final Map<String, FrequentlyPurchasedMedicineModel> medMap = {};
        double totalSpent = 0.0;
        DateTime? firstVisit;
        DateTime? lastVisit;

        if (Get.isRegistered<SalesController>()) {
          final salesCtrl = Get.find<SalesController>();
          final sales = salesCtrl.salesInvoices
              .where((s) => s.customerId == customerId)
              .toList();

          for (final inv in sales) {
            totalSpent += inv.totalAmount;
            final d = inv.invoiceDate ?? inv.createdAt;
            if (d != null) {
              if (firstVisit == null || d.isBefore(firstVisit)) {
                firstVisit = d;
              }
              if (lastVisit == null || d.isAfter(lastVisit)) {
                lastVisit = d;
              }
            }

            final items = inv.items.map((it) {
              if (it.medicineId.isNotEmpty) {
                final existing = medMap[it.medicineId];
                if (existing != null) {
                  medMap[it.medicineId] = FrequentlyPurchasedMedicineModel(
                    medicineId: it.medicineId,
                    name: it.medicineName,
                    genericName: it.genericName ?? existing.genericName,
                    dosageForm: it.dosageForm ?? existing.dosageForm,
                    totalQuantity: existing.totalQuantity + it.quantity,
                    totalSpent: existing.totalSpent + it.totalAmount,
                    lastPurchasedDate: d ?? existing.lastPurchasedDate,
                    purchaseCount: existing.purchaseCount + 1,
                  );
                } else {
                  medMap[it.medicineId] = FrequentlyPurchasedMedicineModel(
                    medicineId: it.medicineId,
                    name: it.medicineName,
                    genericName: it.genericName ?? '',
                    dosageForm: it.dosageForm ?? '',
                    totalQuantity: it.quantity,
                    totalSpent: it.totalAmount,
                    lastPurchasedDate: d,
                    purchaseCount: 1,
                  );
                }
              }

              return CustomerHistoryInvoiceItemModel(
                id: it.id,
                quantity: it.quantity,
                unitPrice: it.unitPrice,
                totalAmount: it.totalAmount,
                medicineName: it.medicineName,
                genericName: it.genericName ?? '',
                dosageForm: it.dosageForm ?? '',
                batchNumber: it.batchNumber,
                expiryDate: it.expiryDate,
              );
            }).toList();

            customerInvoices.add(CustomerHistoryInvoiceModel(
              id: inv.id,
              invoiceNumber: inv.invoiceNumber,
              invoiceDate: d,
              totalAmount: inv.totalAmount,
              paymentStatus: inv.paymentStatus,
              items: items,
            ));
          }
        }

        final fallbackHistory = CustomerHistoryModel(
          customer: localCustomer,
          stats: CustomerHistoryStatsModel(
            totalInvoices: customerInvoices.length,
            totalSpent: totalSpent,
            currentDebt: localCustomer.currentBalance,
            firstVisit: firstVisit,
            lastVisit: lastVisit,
          ),
          frequentlyPurchasedMedicines: medMap.values.toList(),
          invoices: customerInvoices,
        );

        currentCustomerHistory.value = fallbackHistory;
        return fallbackHistory;
      }

      final msg = e is ApiException ? e.message : 'Error fetching medical history';
      UniqueSnackbar.showError(null, message: msg, title: 'History Error');
      return null;
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// 3. Fetch Refill Rules
  Future<void> fetchRefillRules({String? customerId, String? status}) async {
    try {
      isLoadingRules.value = true;
      final result = await _repository.getRefillRules(
        customerId: customerId,
        status: status,
      );
      final List<RefillRuleModel> items = result['items'] ?? [];
      refillRules.assignAll(items);
    } catch (e) {
      debugPrint('Error fetching refill rules: $e');
    } finally {
      isLoadingRules.value = false;
    }
  }

  /// 4. Create Refill Schedule Rule
  Future<bool> createRefillRule({
    required String customerId,
    required String medicineId,
    required double dailyDosage,
    required int daysSupply,
    String? lastPurchaseDate,
    String? notes,
  }) async {
    try {
      isSubmitting.value = true;
      final created = await _repository.createRefillRule(
        customerId: customerId,
        medicineId: medicineId,
        dailyDosage: dailyDosage,
        daysSupply: daysSupply,
        lastPurchaseDate: lastPurchaseDate,
        notes: notes,
      );

      refillRules.insert(0, created);
      // Refresh due list as this might now be due
      fetchDueRefills();

      UniqueSnackbar.showSuccess(
        null,
        message: 'Next refill planned for ${created.expectedRefillDate ?? "auto-calculated date"}',
        title: 'Refill Schedule Active',
      );
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to configure refill schedule';
      UniqueSnackbar.showError(null, message: msg, title: 'Refill Setup Error');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 5. Trigger Refill Reminder (WhatsApp / SMS)
  Future<bool> triggerReminder(
    String refillRuleId, {
    String channel = 'WHATSAPP',
    String? customMessage,
  }) async {
    try {
      isSubmitting.value = true;
      final result = await _repository.sendRefillReminder(
        refillRuleId: refillRuleId,
        channel: channel,
        customMessage: customMessage,
      );

      // Refresh alerts & notification logs
      fetchDueRefills();
      fetchNotificationLogs();

      UniqueSnackbar.showSuccess(
        null,
        message: result['message'] ?? 'Notification queued successfully via $channel',
        title: 'Reminder Dispatched',
      );
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Could not send reminder';
      UniqueSnackbar.showError(null, message: msg, title: 'Dispatch Failed');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 6. Fetch Outgoing Notification Audit Logs
  Future<void> fetchNotificationLogs({String? customerId}) async {
    try {
      isLoadingNotifications.value = true;
      final result = await _repository.getNotificationLogs(customerId: customerId);
      final List<NotificationLogModel> items = result['items'] ?? [];
      notificationLogs.assignAll(items);
    } catch (e) {
      debugPrint('Error fetching notification logs: $e');
    } finally {
      isLoadingNotifications.value = false;
    }
  }

  /// 7. Fetch Follow-Ups
  Future<void> fetchFollowUps({String? customerId, String? status}) async {
    try {
      isLoadingFollowUps.value = true;
      final result = await _repository.getFollowUps(customerId: customerId, status: status);
      final List<FollowUpModel> items = result['items'] ?? [];
      followUps.assignAll(items);
    } catch (e) {
      debugPrint('Error fetching follow-ups: $e');
    } finally {
      isLoadingFollowUps.value = false;
    }
  }

  /// 8. Schedule Follow-Up
  Future<bool> scheduleFollowUp({
    required String customerId,
    required String followUpDate,
    required String notes,
  }) async {
    try {
      isSubmitting.value = true;
      final created = await _repository.scheduleFollowUp(
        customerId: customerId,
        followUpDate: followUpDate,
        notes: notes,
      );

      followUps.insert(0, created);

      UniqueSnackbar.showSuccess(
        null,
        message: 'Patient callback noted for $followUpDate',
        title: 'Follow-up Scheduled',
      );
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to schedule follow-up';
      UniqueSnackbar.showError(null, message: msg, title: 'Scheduling Failed');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 9. Resolve / Update Follow-Up
  Future<bool> resolveFollowUp(
    String followUpId, {
    String status = 'COMPLETED',
    String? notes,
  }) async {
    try {
      isSubmitting.value = true;
      final updated = await _repository.updateFollowUp(
        followUpId: followUpId,
        status: status,
        notes: notes,
      );

      final index = followUps.indexWhere((f) => f.id == followUpId);
      if (index != -1) {
        followUps[index] = updated;
      }

      UniqueSnackbar.showSuccess(
        null,
        message: 'Status marked as $status',
        title: 'Follow-up Updated',
      );
      return true;
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Failed to update follow-up';
      UniqueSnackbar.showError(null, message: msg, title: 'Update Failed');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Completely clear all in-memory CRM data on logout
  void clearData() {
    dueRefills.clear();
    refillRules.clear();
    followUps.clear();
    notificationLogs.clear();
    currentCustomerHistory.value = null;
  }
}
