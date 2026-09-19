import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import 'sale_item_draft.dart';

class MargCartList extends StatelessWidget {
  final List<SaleItemDraft> cartItems;
  final int totalUnitsCount;
  final void Function(int index) onRemoveItem;

  const MargCartList({
    super.key,
    required this.cartItems,
    required this.totalUnitsCount,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    if (cartItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryEmerald.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 15.sp,
                        color: AppColors.primaryEmerald,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Items in Bill (${cartItems.length})',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$totalUnitsCount Total Units',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ...cartItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final expStr = item.batch.expiryDate != null
                    ? DateFormat('MM/yy').format(item.batch.expiryDate!)
                    : 'N/A';
                return Dismissible(
                  key: ValueKey(
                    'cart_item_${item.medicine.id}_${item.batch.id}_$idx',
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    HapticFeedback.mediumImpact();
                    onRemoveItem(idx);
                  },
                  background: Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 16.w),
                    decoration: BoxDecoration(
                      color: AppColors.debitRose.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.debitRose,
                      size: 20.sp,
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${idx + 1}. ${item.medicine.name}',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Batch: ${item.batch.batchNumber} • Exp: $expStr • ${item.quantity}x @ ₹${item.unitPrice.toInt()}${item.discountPercent > 0 ? " (-${item.discountPercent.toInt()}%)" : ""}',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          Formatters.formatCurrency(item.totalAmount),
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.clinicalCyan,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        InkWell(
                          onTap: () => onRemoveItem(idx),
                          child: Padding(
                            padding: EdgeInsets.all(4.r),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 16.sp,
                              color: AppColors.debitRose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
