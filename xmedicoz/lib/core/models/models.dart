import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

double _safeDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

enum BusinessType {
  retailChemist,
}

class BusinessCategory {
  final BusinessType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final List<String> highlights;

  const BusinessCategory({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.highlights,
  });

  static const List<BusinessCategory> allCategories = [
    BusinessCategory(
      type: BusinessType.retailChemist,
      title: 'Retail Chemist & Pharmacy',
      subtitle: 'Prescription dispensing, OTC medicines, baby care & retail patient billing',
      icon: Icons.local_pharmacy_rounded,
      primaryColor: AppColors.primaryEmerald,
      highlights: ['Batch & Expiry Dates', 'Doctor Prescriptions', 'Customer Receivables Ledger'],
    ),
  ];
}

class ShopModel {
  final String id;
  final String name;
  final BusinessCategory category;
  final String ownerName;
  final String phone;
  final String city;
  final String? gstin; // OPTIONAL
  final String drugLicenseNo; // Drug License (20B/21B)
  double cashInHand;
  double bankBalance;
  final String bankName;

  ShopModel({
    required this.id,
    required this.name,
    required this.category,
    required this.ownerName,
    required this.phone,
    required this.city,
    this.gstin,
    required this.drugLicenseNo,
    required this.cashInHand,
    required this.bankBalance,
    required this.bankName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerName': ownerName,
        'phone': phone,
        'city': city,
        'gstin': gstin,
        'drugLicenseNo': drugLicenseNo,
        'cashInHand': cashInHand,
        'bankBalance': bankBalance,
        'bankName': bankName,
      };

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id']?.toString() ?? 'shop_01',
      name: json['name']?.toString() ?? 'My Pharmacy Store',
      category: BusinessCategory.allCategories[0],
      ownerName: json['ownerName']?.toString() ?? 'Chemist / Pharmacist',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      gstin: json['gstin']?.toString(),
      drugLicenseNo: json['drugLicenseNo']?.toString() ?? '',
      cashInHand: _safeDouble(json['cashInHand']),
      bankBalance: _safeDouble(json['bankBalance']),
      bankName: json['bankName']?.toString() ?? '',
    );
  }

  bool get isGstRegistered => gstin != null && gstin!.trim().isNotEmpty;
}

enum StockCategory {
  tabletsCapsules,
  syrupsSuspensions,
  injectionsVials,
  ointmentsCreams,
  dropsInhalers,
  surgicalDevices,
}

extension StockCategoryExtension on StockCategory {
  String get label {
    switch (this) {
      case StockCategory.tabletsCapsules:
        return 'Tablets & Capsules';
      case StockCategory.syrupsSuspensions:
        return 'Syrups & Suspensions';
      case StockCategory.injectionsVials:
        return 'Injections & Vials';
      case StockCategory.ointmentsCreams:
        return 'Ointments & Creams';
      case StockCategory.dropsInhalers:
        return 'Drops & Inhalers';
      case StockCategory.surgicalDevices:
        return 'Surgical & Devices';
    }
  }

  IconData get icon {
    switch (this) {
      case StockCategory.tabletsCapsules:
        return Icons.medication_rounded;
      case StockCategory.syrupsSuspensions:
        return Icons.sanitizer_rounded;
      case StockCategory.injectionsVials:
        return Icons.vaccines_rounded;
      case StockCategory.ointmentsCreams:
        return Icons.healing_rounded;
      case StockCategory.dropsInhalers:
        return Icons.water_drop_rounded;
      case StockCategory.surgicalDevices:
        return Icons.medical_services_rounded;
    }
  }
}

class StockItemModel {
  final String id;
  final String name;
  final StockCategory category;
  final String batchNumber;
  final String saltComposition;
  final String mfgCompany;
  final String expiryDate; // e.g. "12/2027", "04/2026"
  final String scheduleType; // "Schedule H", "Schedule H1", "OTC", "Rx Only"
  int currentQty;
  final int minAlertQty;
  final String rackLocation; // e.g. "Rack M-02", "Fridge 2-8°C"
  final double purchaseRate;
  final double retailMrp;
  final String unit; // e.g. "10 Tabs/Strip", "100ml Bottle", "1 Vial"
  final bool isNearExpiry;
  final bool isExpired;

  StockItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.batchNumber,
    required this.saltComposition,
    required this.mfgCompany,
    required this.expiryDate,
    required this.scheduleType,
    required this.currentQty,
    required this.minAlertQty,
    required this.rackLocation,
    required this.purchaseRate,
    required this.retailMrp,
    required this.unit,
    this.isNearExpiry = false,
    this.isExpired = false,
  });

  bool get isLowStock => currentQty <= minAlertQty;
  double get totalStockValuation => currentQty * purchaseRate;
  double get profitMargin => purchaseRate > 0 ? ((retailMrp - purchaseRate) / purchaseRate) * 100 : 0.0;
}

enum PartyType { customer, supplier }

class PartyModel {
  final String id;
  final String name;
  final String phone;
  final PartyType type;
  double balance; // Positive = Debit/Receivable (Udhar), Negative = Credit/Payable (Jama)
  final int overdueDays;
  final String city;
  final String partyCategory; // e.g. "Patient", "Doctor Clinic", "Hospital", "Pharma Stockist"

  PartyModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.balance,
    required this.overdueDays,
    required this.city,
    this.partyCategory = 'General Party',
  });

  bool get isReceivable => balance > 0;
  bool get isPayable => balance < 0;
}

enum TransactionType { sale, purchase, paymentIn, paymentOut }
enum PaymentMode { cash, onlineUpi, bankTransfer, credit }

class TransactionModel {
  final String id;
  final String invoiceNo;
  final DateTime date;
  final String partyName;
  final TransactionType type;
  final PaymentMode paymentMode;
  final double amount;
  final int itemsCount;
  final String notes; // Doctor name or medicines list
  final String? doctorName;
  final String? patientName;

  TransactionModel({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.partyName,
    required this.type,
    required this.paymentMode,
    required this.amount,
    required this.itemsCount,
    required this.notes,
    this.doctorName,
    this.patientName,
  });

  bool get isInflow => type == TransactionType.sale || type == TransactionType.paymentIn;
}

/// Zero-Mock Data Service: Fallbacks strictly empty, all data comes live from backend
class MockDataService {
  static List<ShopModel> shops = [
    ShopModel(
      id: 'shop_01',
      name: 'My Pharmacy Store',
      category: BusinessCategory.allCategories[0],
      ownerName: 'Chemist Pharmacist',
      phone: '+91 98000 00000',
      city: 'Delhi NCR',
      gstin: '',
      drugLicenseNo: 'DL-20B/21B-XXXXX',
      cashInHand: 0.0,
      bankBalance: 0.0,
      bankName: 'Current Account',
    ),
  ];

  static List<StockItemModel> stockItems = [];
  static List<PartyModel> parties = [];
  static List<TransactionModel> transactions = [];
}
