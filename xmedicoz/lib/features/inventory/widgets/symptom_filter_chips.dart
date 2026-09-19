import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/smart_search_controller.dart';

class SymptomFilterChips extends StatelessWidget {
  final SmartSearchController controller;
  final Function(String symptom)? onSymptomSelected;

  const SymptomFilterChips({
    super.key,
    required this.controller,
    this.onSymptomSelected,
  });

  static const List<Map<String, String>> symptoms = [
    {'key': 'All', 'label': 'All'},
    {'key': 'Cold', 'label': 'Cold & Flu 🤧'},
    {'key': 'Gas', 'label': 'Gas & Acidity 🫧'},
    {'key': 'Fever', 'label': 'Fever & Pain 🌡️'},
    {'key': 'Cough', 'label': 'Cough 🫁'},
    {'key': 'Vomiting', 'label': 'Vomiting 🤢'},
    {'key': 'Diarrhea', 'label': 'Diarrhea 💧'},
    {'key': 'Allergy', 'label': 'Allergy 🌿'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: symptoms.length,
        separatorBuilder: (_, _) => SizedBox(width: 6.w),
        itemBuilder: (ctx, index) {
          final s = symptoms[index];
          final key = s['key']!;
          final label = s['label']!;

          return Obx(() {
            final isSelected = controller.selectedSymptomChip.value == key;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                controller.selectSymptom(key);
                if (onSymptomSelected != null) {
                  onSymptomSelected!(key);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryEmerald.withValues(alpha: 0.18)
                      : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryEmerald
                        : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? AppColors.primaryEmerald
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
