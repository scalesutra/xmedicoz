import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/unique_snackbar.dart';

class MargQuantityRow extends StatelessWidget {
  final int quantity;
  final double discountPercent;
  final int maxQty;
  final TextEditingController qtyCtrl;
  final FocusNode qtyFocusNode;
  final void Function(int qty) onQuantityChanged;
  final void Function(String text)? onQuantityTyped;
  final void Function(double discount) onDiscountChanged;
  final void Function() onAddToCart;

  const MargQuantityRow({
    super.key,
    required this.quantity,
    required this.discountPercent,
    required this.maxQty,
    required this.qtyCtrl,
    required this.qtyFocusNode,
    required this.onQuantityChanged,
    this.onQuantityTyped,
    required this.onDiscountChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity & Pack Presets',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [0, 5, 10].map((d) {
                  final isSel = discountPercent == d;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onDiscountChanged(d.toDouble());
                    },
                    child: Container(
                      margin: EdgeInsets.only(left: 4.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryEmerald
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primaryEmerald
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Text(
                        '$d%',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: isSel ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (quantity > 1) {
                    HapticFeedback.selectionClick();
                    onQuantityChanged(quantity - 1);
                  }
                },
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(Icons.remove_rounded,
                      size: 16.sp, color: AppColors.debitRose),
                ),
              ),
              Container(
                width: 48.w,
                height: 28.r,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.4),
                    width: 1.w,
                  ),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: qtyCtrl,
                  focusNode: qtyFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    if (onQuantityTyped != null) {
                      onQuantityTyped!(val);
                    } else {
                      if (val.trim().isEmpty) return;
                      final parsed = int.tryParse(val.trim());
                      if (parsed != null && parsed > 0) {
                        onQuantityChanged(parsed);
                      }
                    }
                  },
                  onSubmitted: (val) {
                    final parsed = int.tryParse(val.trim());
                    final cleanQty = (parsed == null || parsed <= 0)
                        ? 1
                        : parsed.clamp(1, maxQty > 0 ? maxQty : 9999);
                    onQuantityChanged(cleanQty);
                    onAddToCart();
                  },
                ),
              ),
              InkWell(
                onTap: () {
                  if (quantity < maxQty) {
                    HapticFeedback.selectionClick();
                    onQuantityChanged(quantity + 1);
                  } else {
                    UniqueSnackbar.showError(
                      context,
                      title: 'Stock Limit',
                      message: 'Only $maxQty units available in this batch.',
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(Icons.add_rounded,
                      size: 16.sp, color: AppColors.creditGreen),
                ),
              ),
              const Spacer(),
              ...[1, 2, 5, 10].map((q) {
                final isSel = quantity == q;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onQuantityChanged(q);
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 4.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSel ? AppColors.primaryEmerald : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: isSel
                            ? AppColors.primaryEmerald
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Text(
                      '+$q',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            isSel ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
