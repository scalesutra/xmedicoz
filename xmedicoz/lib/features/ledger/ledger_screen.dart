import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/master_models.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/unique_snackbar.dart';
import '../../core/widgets/unique_3d_refresh_indicator.dart';
import '../inventory/controllers/master_data_controller.dart';
import '../purchases/controllers/purchases_controller.dart';
import '../sales/controllers/sales_controller.dart';
import 'party_detail_sheet.dart';
import '../../core/models/ocr_models.dart';
import '../ocr/widgets/ocr_scanner_modal.dart';

class LedgerScreen extends StatefulWidget {
  final ShopModel activeShop;

  const LedgerScreen({super.key, required this.activeShop});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late final MasterDataController masterController;
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedTabIndex = 0; // 0 = Customers, 1 = Suppliers

  @override
  void initState() {
    super.initState();
    masterController = Get.isRegistered<MasterDataController>()
        ? Get.find<MasterDataController>()
        : Get.put(MasterDataController());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_selectedTabIndex == 0) {
      masterController.customerSearch.value = val.trim();
      masterController.fetchCustomers(search: val.trim());
    } else {
      masterController.supplierSearch.value = val.trim();
      masterController.fetchSuppliers(search: val.trim());
    }
  }

  Widget _buildClassificationPill({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bgSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: isSelected
                ? Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.6),
                    width: 1.2,
                  )
                : Border.all(color: Colors.transparent),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                      blurRadius: 6.r,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: isSelected
                    ? AppColors.primaryEmerald
                    : AppColors.textTertiary,
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryEmerald
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: isSelected
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController(text: '5000');
    String customerType = 'REGULAR';
    bool isPermanent = false;
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          return Container(
            height: MediaQuery.sizeOf(sheetCtx).height * 0.92,
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // 2. Futuristic Cyber Header (Pinned)
                Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryEmerald,
                            AppColors.clinicalCyan,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 8.r,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Patient / Customer',
                            style: AppTypography.h3.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Cloud Master • Digital Ledger',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final result = await OcrScannerModal.show(
                          context,
                          initialType: OcrDocumentType.customer,
                        );
                        if (result != null) {
                          final f = result.fields;
                          if (f['name'] != null &&
                              f['name'].toString().isNotEmpty) {
                            nameCtrl.text = f['name'].toString();
                          }
                          final phone = (f['phone'] ?? f['mobile'])?.toString();
                          if (phone != null && phone.isNotEmpty) {
                            mobileCtrl.text = phone
                                .replaceAll('+91', '')
                                .replaceAll(' ', '');
                          }
                          if (f['address'] != null &&
                              f['address'].toString().isNotEmpty) {
                            addressCtrl.text = f['address'].toString();
                          }
                          if (f['email'] != null &&
                              f['email'].toString().isNotEmpty) {
                            emailCtrl.text = f['email'].toString();
                          }
                          setModalState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.primaryEmerald.withValues(
                              alpha: 0.4,
                            ),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 14.sp,
                              color: AppColors.primaryEmerald,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Scan',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 18, color: AppColors.borderSubtle),

                // 3. Scrollable Body
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
                    ),
                    child: ListView(
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(bottom: 24.h),
                      children: [
                        // 2. Classification Segmented Dock
                        Text(
                          'ACCOUNT CLASSIFICATION',
                          style: AppTypography.label.copyWith(
                            fontSize: 10.sp,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: AppColors.bgInput,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              _buildClassificationPill(
                                label: 'Regular',
                                subtitle: 'Counter Rx',
                                icon: Icons.storefront_outlined,
                                isSelected: customerType == 'REGULAR',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    customerType = 'REGULAR';
                                    isPermanent = false;
                                  });
                                },
                              ),
                              SizedBox(width: 4.w),
                              _buildClassificationPill(
                                label: 'Khata',
                                subtitle: 'Permanent',
                                icon: Icons.book_outlined,
                                isSelected: customerType == 'PERMANENT',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    customerType = 'PERMANENT';
                                    isPermanent = true;
                                  });
                                },
                              ),
                              SizedBox(width: 4.w),
                              _buildClassificationPill(
                                label: 'Walk-In',
                                subtitle: 'Instant Cash',
                                icon: Icons.bolt_outlined,
                                isSelected: customerType == 'WALK_IN',
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    customerType = 'WALK_IN';
                                    isPermanent = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // 3. Form Input Fields
                        AppTextField(
                          controller: nameCtrl,
                          hintText: 'e.g. Ramesh Patel / Dr. Sharma',
                          labelText: 'Customer / Patient Full Name *',
                          prefixIcon: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        AppTextField(
                          controller: mobileCtrl,
                          hintText: '10-digit mobile number',
                          labelText: 'Mobile Number *',
                          prefixText: '+91 ',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(
                            Icons.phone_android_rounded,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        AppTextField(
                          controller: addressCtrl,
                          hintText: 'e.g. Flat 102, Royal Palms, Pune',
                          labelText: 'Delivery / Residence Address',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        AppTextField(
                          controller: emailCtrl,
                          hintText: 'e.g. ramesh@example.com (Optional)',
                          labelText: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // 4. Credit Limit with Quick Presets
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CREDIT LIMIT',
                              style: AppTypography.label.copyWith(
                                fontSize: 10.sp,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              'Tap preset to select',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10.sp,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        AppTextField(
                          controller: creditLimitCtrl,
                          hintText: '5000',
                          labelText: 'Credit Limit Amount',
                          prefixText: '₹ ',
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 8.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [2000, 5000, 10000, 25000, 50000].map((
                              preset,
                            ) {
                              final isCur =
                                  creditLimitCtrl.text == preset.toString();
                              return Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(() {
                                      creditLimitCtrl.text = preset.toString();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCur
                                          ? AppColors.primaryEmerald.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppColors.bgInput,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: isCur
                                            ? AppColors.primaryEmerald
                                            : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Text(
                                      '₹$preset',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: isCur
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isCur
                                            ? AppColors.primaryEmerald
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // 5. Action Button
                        AppButton(
                          title: 'Register to Customer Master',
                          icon: Icons.check_circle_outline_rounded,
                          isLoading: isSaving,
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final mobile = mobileCtrl.text.trim();
                            if (name.isEmpty || mobile.isEmpty) {
                              UniqueSnackbar.showWarning(
                                context,
                                title: 'Required Fields',
                                message:
                                    'Customer name and 10-digit mobile are required.',
                              );
                              return;
                            }

                            final formattedPhone = mobile.startsWith('+91')
                                ? mobile
                                : '+91$mobile';
                            setModalState(() => isSaving = true);

                            final payload = {
                              'name': name,
                              'mobile': formattedPhone,
                              if (emailCtrl.text.trim().isNotEmpty)
                                'email': emailCtrl.text.trim(),
                              if (addressCtrl.text.trim().isNotEmpty)
                                'address': addressCtrl.text.trim(),
                              'customerType': customerType,
                              'isPermanent': isPermanent,
                              'creditLimit':
                                  double.tryParse(
                                    creditLimitCtrl.text.trim(),
                                  ) ??
                                  5000.0,
                            };

                            final success = await masterController
                                .createCustomer(payload);
                            setModalState(() => isSaving = false);

                            if (sheetCtx.mounted && mounted) {
                              if (success) {
                                Navigator.of(sheetCtx).pop();
                                UniqueSnackbar.showSuccess(
                                  context,
                                  title: 'Customer Registered',
                                  message:
                                      '$name added to live Customer Master & Ledger.',
                                );
                              } else {
                                UniqueSnackbar.showError(
                                  context,
                                  title: 'Registration Failed',
                                  message:
                                      masterController
                                          .errorMessage
                                          .value
                                          .isNotEmpty
                                      ? masterController.errorMessage.value
                                      : 'Failed to create customer record.',
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final contactPersonCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final dlNumberCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final termsCtrl = TextEditingController(text: '30');
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          return Container(
            height: MediaQuery.sizeOf(sheetCtx).height * 0.92,
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // 2. Futuristic Cyber Header (Pinned)
                Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.debitRose, AppColors.clinicalCyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.debitRose.withValues(alpha: 0.3),
                            blurRadius: 8.r,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Supplier / Stockist',
                            style: AppTypography.h3.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Live Cloud Master • Supply Chain Ledger',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final result = await OcrScannerModal.show(
                          context,
                          initialType: OcrDocumentType.supplier,
                        );
                        if (result != null) {
                          final f = result.fields;
                          if (f['name'] != null &&
                              f['name'].toString().isNotEmpty) {
                            nameCtrl.text = f['name'].toString();
                          }
                          final phone = (f['phone'] ?? f['mobile'])?.toString();
                          if (phone != null && phone.isNotEmpty) {
                            mobileCtrl.text = phone
                                .replaceAll('+91', '')
                                .replaceAll(' ', '');
                          }
                          if (f['gstin'] != null &&
                              f['gstin'].toString().isNotEmpty) {
                            gstinCtrl.text = f['gstin'].toString();
                          }
                          if (f['address'] != null &&
                              f['address'].toString().isNotEmpty) {
                            addressCtrl.text = f['address'].toString();
                          }
                          if (f['dlNumber'] != null &&
                              f['dlNumber'].toString().isNotEmpty) {
                            dlNumberCtrl.text = f['dlNumber'].toString();
                          }
                          if (f['contactPerson'] != null &&
                              f['contactPerson'].toString().isNotEmpty) {
                            contactPersonCtrl.text = f['contactPerson']
                                .toString();
                          }
                          setModalState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.debitRose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.debitRose.withValues(alpha: 0.4),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 14.sp,
                              color: AppColors.debitRose,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Scan',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.debitRose,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 18, color: AppColors.borderSubtle),

                // 3. Scrollable Body
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom,
                    ),
                    child: ListView(
                      physics: const ClampingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(bottom: 24.h),
                      children: [
                        SizedBox(height: 16.h),

                        // 2. Input Fields
                        AppTextField(
                          controller: nameCtrl,
                          hintText:
                              'e.g. Apex Medico Distributors / Cipla Stockist',
                          labelText: 'Supplier Agency Name *',
                          prefixIcon: const Icon(
                            Icons.storefront_rounded,
                            color: AppColors.debitRose,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: contactPersonCtrl,
                                hintText: 'e.g. Vikas Shah',
                                labelText: 'Contact Person',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: AppTextField(
                                controller: mobileCtrl,
                                hintText: 'Mobile *',
                                prefixText: '+91 ',
                                keyboardType: TextInputType.phone,
                                prefixIcon: const Icon(
                                  Icons.phone_android_rounded,
                                  color: AppColors.debitRose,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: gstinCtrl,
                                hintText: '27AABCU9603R1ZM',
                                labelText: 'GSTIN',
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: AppTextField(
                                controller: dlNumberCtrl,
                                hintText: '20B/21B-45892',
                                labelText: 'Drug License',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),

                        AppTextField(
                          controller: addressCtrl,
                          hintText: 'Warehouse / Wholesale Office address',
                          labelText: 'Supplier Address',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // 3. Payment Terms Presets
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CREDIT PAYMENT TERMS (DAYS)',
                              style: AppTypography.label.copyWith(
                                fontSize: 10.sp,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              'Net days for invoice due',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10.sp,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        AppTextField(
                          controller: termsCtrl,
                          hintText: '30',
                          labelText: 'Payment Terms (Days)',
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 8.h),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [7, 15, 21, 30, 45, 60].map((days) {
                              final isCur = termsCtrl.text == days.toString();
                              return Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(() {
                                      termsCtrl.text = days.toString();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCur
                                          ? AppColors.debitRose.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppColors.bgInput,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: isCur
                                            ? AppColors.debitRose
                                            : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Text(
                                      '$days Days',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: isCur
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isCur
                                            ? AppColors.debitRose
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // 4. Action Button
                        AppButton(
                          title: 'Register Supplier to Master',
                          icon: Icons.check_circle_outline_rounded,
                          isLoading: isSaving,
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final mobile = mobileCtrl.text.trim();
                            if (name.isEmpty || mobile.isEmpty) {
                              UniqueSnackbar.showWarning(
                                context,
                                title: 'Required Fields',
                                message:
                                    'Supplier agency name and mobile number are required.',
                              );
                              return;
                            }

                            final formattedPhone = mobile.startsWith('+91')
                                ? mobile
                                : '+91$mobile';
                            setModalState(() => isSaving = true);

                            final payload = {
                              'name': name,
                              if (contactPersonCtrl.text.trim().isNotEmpty)
                                'contactPerson': contactPersonCtrl.text.trim(),
                              'mobile': formattedPhone,
                              if (emailCtrl.text.trim().isNotEmpty)
                                'email': emailCtrl.text.trim(),
                              if (gstinCtrl.text.trim().isNotEmpty)
                                'gstin': gstinCtrl.text.trim(),
                              if (dlNumberCtrl.text.trim().isNotEmpty)
                                'dlNumber': dlNumberCtrl.text.trim(),
                              if (addressCtrl.text.trim().isNotEmpty)
                                'address': addressCtrl.text.trim(),
                              'paymentTermsDays':
                                  int.tryParse(termsCtrl.text.trim()) ?? 30,
                            };

                            final success = await masterController
                                .createSupplier(payload);
                            setModalState(() => isSaving = false);

                            if (sheetCtx.mounted && mounted) {
                              if (success) {
                                Navigator.of(sheetCtx).pop();
                                UniqueSnackbar.showSuccess(
                                  context,
                                  title: 'Supplier Registered',
                                  message:
                                      '$name added to live Supplier Master & Ledger.',
                                );
                              } else {
                                UniqueSnackbar.showError(
                                  context,
                                  title: 'Registration Failed',
                                  message:
                                      masterController
                                          .errorMessage
                                          .value
                                          .isNotEmpty
                                      ? masterController.errorMessage.value
                                      : 'Failed to create supplier record.',
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: SafeArea(
        child: Obx(() {
          final isCustomerTab = _selectedTabIndex == 0;
          final isBusy = isCustomerTab
              ? masterController.isLoadingCustomers.value
              : masterController.isLoadingSuppliers.value;
          final customers = masterController.customers;
          final suppliers = masterController.suppliers;
          final receivables = masterController.totalReceivables;
          final payables = masterController.totalPayables;

          return Column(
            children: [
              // Header & Live Balance Summary Cards
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.ledgerTitle,
                              style: AppTypography.h2,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Live Customer & Supplier Master Data',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryEmerald,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primaryEmerald,
                          ),
                          onPressed: () {
                            if (isCustomerTab) {
                              masterController.fetchCustomers();
                            } else {
                              masterController.fetchSuppliers();
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Receivables & Payables Summary Row
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            title: 'Customer Receivables',
                            subtitle:
                                '${masterController.totalCustomersCount} Accounts',
                            amount: Formatters.formatCurrency(receivables),
                            color: AppColors.creditGreen,
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _summaryCard(
                            title: 'Supplier Payables',
                            subtitle:
                                '${masterController.totalSuppliersCount} Stockists',
                            amount: Formatters.formatCurrency(payables),
                            color: AppColors.debitRose,
                            icon: Icons.arrow_upward_rounded,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Segmented Tabs Switcher (Customers vs Suppliers)
                    Container(
                      height: 42.h,
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusMd,
                        ),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedTabIndex = 0);
                                masterController.fetchCustomers();
                              },
                              borderRadius: BorderRadius.circular(
                                AppDecorations.radiusMd - 2,
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCustomerTab
                                      ? AppColors.creditGreen
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppDecorations.radiusMd - 2,
                                  ),
                                ),
                                child: Text(
                                  'Customers (${masterController.totalCustomersCount})',
                                  style: TextStyle(
                                    color: isCustomerTab
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() => _selectedTabIndex = 1);
                                masterController.fetchSuppliers();
                              },
                              borderRadius: BorderRadius.circular(
                                AppDecorations.radiusMd - 2,
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: !isCustomerTab
                                      ? AppColors.debitRose
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppDecorations.radiusMd - 2,
                                  ),
                                ),
                                child: Text(
                                  'Suppliers (${masterController.totalSuppliersCount})',
                                  style: TextStyle(
                                    color: !isCustomerTab
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Search Input
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      style: AppTypography.bodyMedium,
                      decoration: AppDecorations.searchDecoration(
                        hintText: isCustomerTab
                            ? 'Search customers...'
                            : 'Search suppliers...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isCustomerTab
                              ? AppColors.creditGreen
                              : AppColors.debitRose,
                        ),
                        focusColor: isCustomerTab
                            ? AppColors.creditGreen
                            : AppColors.debitRose,
                      ),
                    ),
                  ],
                ),
              ),

              // Content List with 3D Cyber-Pharma Refresh Indicator
              Expanded(
                child:
                    isBusy &&
                        (isCustomerTab ? customers.isEmpty : suppliers.isEmpty)
                    ? Center(
                        child: CircularProgressIndicator(
                          color: isCustomerTab
                              ? AppColors.creditGreen
                              : AppColors.debitRose,
                        ),
                      )
                    : Unique3DRefreshIndicator(
                        title: isCustomerTab
                            ? 'Syncing Customers Master...'
                            : 'Syncing Suppliers Master...',
                        primaryColor: isCustomerTab
                            ? AppColors.creditGreen
                            : AppColors.debitRose,
                        secondaryColor: isCustomerTab
                            ? AppColors.clinicalCyan
                            : Colors.orangeAccent,
                        onRefresh: () async {
                          if (isCustomerTab) {
                            await masterController.fetchCustomers(
                              search: _searchCtrl.text.trim(),
                            );
                          } else {
                            await masterController.fetchSuppliers(
                              search: _searchCtrl.text.trim(),
                            );
                          }
                        },
                        child:
                            (isCustomerTab
                                ? customers.isEmpty
                                : suppliers.isEmpty)
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: 80.h),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          isCustomerTab
                                              ? Icons.groups_outlined
                                              : Icons
                                                    .store_mall_directory_outlined,
                                          size: 48.sp,
                                          color: AppColors.textMuted,
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          isCustomerTab
                                              ? 'No customers found in database'
                                              : 'No suppliers found in database',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                        SizedBox(height: 6.h),
                                        Text(
                                          isCustomerTab
                                              ? 'Tap "+ Add Party" to register a customer master.'
                                              : 'Tap "+ Add Party" to register a supplier distributor.',
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  18.w,
                                  4.h,
                                  18.w,
                                  80.h,
                                ),
                                itemCount: isCustomerTab
                                    ? customers.length
                                    : suppliers.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 10.h),
                                itemBuilder: (context, index) {
                                  if (isCustomerTab) {
                                    final customer = customers[index];
                                    return _buildCustomerTile(customer);
                                  } else {
                                    final supplier = suppliers[index];
                                    return _buildSupplierTile(supplier);
                                  }
                                },
                              ),
                      ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: AppFloatingButton(
        label: '+ Add Party',
        icon: Icons.person_add_alt_1_rounded,
        glowColor: _selectedTabIndex == 0
            ? AppColors.creditGreen
            : AppColors.debitRose,
        onPressed: () {
          if (_selectedTabIndex == 0) {
            _showAddCustomerDialog();
          } else {
            _showAddSupplierDialog();
          }
        },
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: color),
              SizedBox(width: 6.w),
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            amount,
            style: AppTypography.h3.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.5.sp, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(CustomerModel customer) {
    double balance = customer.currentBalance;
    if (balance <= 0 && Get.isRegistered<SalesController>()) {
      final sales = Get.find<SalesController>().salesInvoices;
      final unpaid = sales
          .where(
            (s) =>
                (s.customerId == customer.id ||
                    (customer.mobile.isNotEmpty &&
                        s.customerMobile == customer.mobile)) &&
                (s.isCreditSale || s.isUnpaid),
          )
          .fold(
            0.0,
            (sum, s) =>
                sum + (s.balanceAmount > 0 ? s.balanceAmount : s.totalAmount),
          );
      if (unpaid > 0) balance = unpaid;
    }
    final hasBalance = balance > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          PartyDetailSheet.showCustomer(context, customer: customer);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasBalance
                  ? AppColors.creditGreen.withValues(alpha: 0.22)
                  : AppColors.borderSubtle,
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              // Slim Modern Squircle Avatar
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.creditGreen.withValues(alpha: 0.20),
                      AppColors.creditGreen.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.creditGreen.withValues(alpha: 0.35),
                    width: 1.w,
                  ),
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      color: AppColors.creditGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Customer Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.name,
                            style: AppTypography.h4.copyWith(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.creditGreen.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: AppColors.creditGreen.withValues(
                                alpha: 0.25,
                              ),
                              width: 0.6.w,
                            ),
                          ),
                          child: Text(
                            customer.customerType,
                            style: TextStyle(
                              color: AppColors.creditGreen,
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 10.sp,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          customer.mobile,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Balance & Quick Status Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.formatCurrency(balance),
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w900,
                      color: hasBalance
                          ? AppColors.creditGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: hasBalance
                          ? AppColors.creditGreen.withValues(alpha: 0.12)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      hasBalance ? 'Receivable' : 'Settled',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: hasBalance
                            ? AppColors.creditGreen
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 16.sp,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierTile(SupplierModel supplier) {
    double balance = supplier.outstandingBalance;
    if (balance <= 0 && Get.isRegistered<PurchasesController>()) {
      final purchases = Get.find<PurchasesController>().purchases;
      final unpaid = purchases
          .where(
            (p) =>
                p.supplierId == supplier.id &&
                (p.isUnpaid || p.isPartiallyPaid),
          )
          .fold(
            0.0,
            (sum, p) =>
                sum + (p.balanceAmount > 0 ? p.balanceAmount : p.totalAmount),
          );
      if (unpaid > 0) balance = unpaid;
    }
    final hasBalance = balance > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          PartyDetailSheet.showSupplier(context, supplier: supplier);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasBalance
                  ? AppColors.debitRose.withValues(alpha: 0.22)
                  : AppColors.borderSubtle,
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              // Slim Modern Squircle Avatar
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.debitRose.withValues(alpha: 0.20),
                      AppColors.debitRose.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.debitRose.withValues(alpha: 0.35),
                    width: 1.w,
                  ),
                ),
                child: Center(
                  child: Text(
                    supplier.name.isNotEmpty
                        ? supplier.name[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      color: AppColors.debitRose,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Supplier Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      supplier.name,
                      style: AppTypography.h4.copyWith(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 10.sp,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            supplier.contactPerson != null &&
                                    supplier.contactPerson!.isNotEmpty
                                ? '${supplier.contactPerson} • ${supplier.mobile}'
                                : supplier.mobile,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (supplier.gstin != null &&
                            supplier.gstin!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            'GST',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Balance & Quick Status Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.formatCurrency(balance),
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w900,
                      color: hasBalance
                          ? AppColors.debitRose
                          : AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: hasBalance
                          ? AppColors.debitRose.withValues(alpha: 0.12)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      hasBalance ? 'Payable' : 'Clear',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: hasBalance
                            ? AppColors.debitRose
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 16.sp,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
