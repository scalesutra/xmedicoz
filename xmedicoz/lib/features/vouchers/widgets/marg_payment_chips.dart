import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/master_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/unique_snackbar.dart';

class MargPaymentChips extends StatelessWidget {
  final String selectedMode;
  final bool isWalkIn;
  final CustomerModel? selectedCustomer;
  final List<CustomerModel> customerChoices;
  final void Function(String mode, {bool forceRegistered, CustomerModel? firstCustomer}) onModeChanged;

  const MargPaymentChips({
    super.key,
    required this.selectedMode,
    required this.isWalkIn,
    required this.selectedCustomer,
    required this.customerChoices,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildPayChip(context, 'UPI', 'UPI / QR', Icons.qr_code_2_rounded),
        SizedBox(width: 6.w),
        _buildPayChip(context, 'CASH', 'Cash', Icons.payments_rounded),
        SizedBox(width: 6.w),
        _buildPayChip(context, 'CARD', 'Card', Icons.credit_card_rounded),
        SizedBox(width: 6.w),
        _buildPayChip(context, 'CREDIT', 'Credit', Icons.schedule_rounded),
      ],
    );
  }

  Widget _buildPayChip(
    BuildContext context,
    String mode,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedMode == mode;
    final isCredit = mode == 'CREDIT';
    final activeColor = isCredit ? AppColors.debitRose : AppColors.primaryEmerald;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (isCredit && isWalkIn) {
            onModeChanged(
              mode,
              forceRegistered: true,
              firstCustomer: customerChoices.isNotEmpty ? customerChoices.first : null,
            );
          } else {
            onModeChanged(mode);
          }
          if (isCredit && selectedCustomer == null) {
            UniqueSnackbar.showInfo(
              context,
              title: 'Credit Bill Selected',
              message:
                  'Please choose the customer account to add this credit balance to.',
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.bgCard,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.borderSubtle,
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13.sp,
                color: isSelected
                    ? Colors.white
                    : (isCredit ? AppColors.debitRose : AppColors.textSecondary),
              ),
              SizedBox(width: 3.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isCredit
                          ? AppColors.debitRose
                          : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
