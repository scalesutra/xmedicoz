import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../inventory/controllers/master_data_controller.dart';

class MargPatientSwitcher extends StatelessWidget {
  final bool isWalkIn;
  final CustomerModel? selectedCustomer;
  final TextEditingController patientCtrl;
  final TextEditingController mobileCtrl;
  final MasterDataController masterController;
  final void Function(bool isWalkIn) onToggle;
  final void Function(CustomerModel customer) onCustomerSelected;

  const MargPatientSwitcher({
    super.key,
    required this.isWalkIn,
    required this.selectedCustomer,
    required this.patientCtrl,
    required this.mobileCtrl,
    required this.masterController,
    required this.onToggle,
    required this.onCustomerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PATIENT / CUSTOMER',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                height: 26.h,
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  children: [
                    _buildToggleOption(context, 'Walk-in', isWalkIn, () {
                      HapticFeedback.selectionClick();
                      onToggle(true);
                    }),
                    _buildToggleOption(context, 'Registered', !isWalkIn, () {
                      HapticFeedback.selectionClick();
                      onToggle(false);
                    }),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          if (isWalkIn)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(patientCtrl, 'Patient Name'),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    mobileCtrl,
                    'Mobile No',
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            )
          else
            Obx(() {
              final displayedCustomers = masterController.customerChoices;
              return SearchableDropdown<CustomerModel>(
                value: selectedCustomer,
                items: displayedCustomers,
                itemName: 'customer',
                itemPlural: 'customers',
                itemIcon: Icons.person_outline_rounded,
                label: (c) =>
                    c.mobile.isNotEmpty ? '${c.name} • ${c.mobile}' : c.name,
                loadItems: masterController.loadCustomerChoices,
                decoration: AppDecorations.inputDecoration(
                  hintText: 'Search & select registered patient...',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_search_rounded,
                    color: AppColors.primaryEmerald,
                    size: 19,
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    HapticFeedback.selectionClick();
                    onCustomerSelected(val);
                  }
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryEmerald : Colors.transparent,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
        ),
      ),
    );
  }
}
