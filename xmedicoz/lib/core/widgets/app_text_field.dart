import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? labelText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final int maxLines;
  final String? prefixText;
  final bool readOnly;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final bool? isDense;
  final TextStyle? style;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final EdgeInsets? scrollPadding;

  const AppTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.labelText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixText,
    this.readOnly = false,
    this.onTap,
    this.contentPadding,
    this.isDense,
    this.style,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.scrollPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5.h),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          scrollPadding: scrollPadding ?? EdgeInsets.only(bottom: 80.h),
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          obscureText: obscureText,
          maxLines: maxLines,
          style: style ??
              AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
          cursorColor: AppColors.primaryEmerald,
          decoration: AppDecorations.inputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            helperText: helperText,
            isDense: isDense ?? true,
            contentPadding: contentPadding ??
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          ).copyWith(
            prefixText: prefixText != null ? '$prefixText ' : null,
            prefixStyle: AppTypography.bodyLarge.copyWith(
              color: AppColors.primaryEmerald,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
