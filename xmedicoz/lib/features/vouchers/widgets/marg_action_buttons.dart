import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';

class MargActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final String paymentMode;
  final VoidCallback onPrint;
  final VoidCallback onComplete;

  const MargActionButtons({
    super.key,
    required this.isSubmitting,
    required this.paymentMode,
    required this.onPrint,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = paymentMode == 'CREDIT';
    final actionColor = isCredit ? AppColors.debitRose : AppColors.primaryEmerald;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSubmitting ? null : onPrint,
            icon: Icon(Icons.print_rounded,
                size: 17.sp, color: AppColors.primaryCyan),
            label: Text(
              'Print Thermal',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryCyan,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppColors.primaryCyan.withValues(alpha: 0.5),
                width: 1.2.w,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isSubmitting ? null : onComplete,
            icon: isSubmitting
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isCredit
                        ? Icons.schedule_rounded
                        : Icons.check_circle_rounded,
                    size: 18.sp,
                    color: Colors.white,
                  ),
            label: Text(
              isSubmitting
                  ? 'Billing...'
                  : (isCredit ? 'Record Credit Bill' : 'Complete & Dispense'),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              elevation: 4,
              shadowColor: actionColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }
}
