import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import 'app_button.dart';

/// Next-Gen Ultra-Unique Cyber-Pharma Calendar & Date Picker.
/// Features:
/// - Signature Glassmorphic Bottom Sheet with Clinical Emerald & Teal accents
/// - Real-time animated selected date showcase
/// - Quick Presets (Today, Yesterday, +30 Days, +6 Months, +1 Year, +2 Years for Pharma Expiry)
/// - Fast Month & Year Jump Grid (ideal for Batch Expiries up to 2035)
/// - Haptic feedback on every tap
/// - Call with a single line: `final picked = await UniqueCalendarPicker.show(context);`
class UniqueCalendarPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String? subtitle;
  final bool isExpiryMode;

  const UniqueCalendarPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = 'Select Date',
    this.subtitle,
    this.isExpiryMode = false,
  });

  /// Static helper to show the calendar from anywhere with a single await.
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Select Date',
    String? subtitle,
    bool isExpiryMode = false,
  }) {
    final now = DateTime.now();
    final effectiveInitial = initialDate ?? now;
    final effectiveFirst = firstDate ?? DateTime(now.year - 5);
    final effectiveLast = lastDate ?? DateTime(now.year + 12);

    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniqueCalendarPicker(
        initialDate: effectiveInitial,
        firstDate: effectiveFirst,
        lastDate: effectiveLast,
        title: title,
        subtitle: subtitle,
        isExpiryMode: isExpiryMode,
      ),
    );
  }

  @override
  State<UniqueCalendarPicker> createState() => _UniqueCalendarPickerState();
}

class _UniqueCalendarPickerState extends State<UniqueCalendarPicker> {
  late DateTime _selectedDate;
  late DateTime _currentMonthView;
  bool _isYearPickerOpen = false;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _currentMonthView = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonthView = DateTime(
        _currentMonthView.year,
        _currentMonthView.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonthView = DateTime(
        _currentMonthView.year,
        _currentMonthView.month + 1,
        1,
      );
    });
  }

  void _selectPreset(DateTime date) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _currentMonthView = DateTime(date.year, date.month, 1);
      _isYearPickerOpen = false;
    });
  }

  String _formatDateTitle(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _monthNames[date.month - 1].substring(0, 3);
    final year = date.year;
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        border: Border.all(
          color: AppColors.primaryEmerald.withValues(alpha: 0.25),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryEmerald.withValues(alpha: 0.12),
            blurRadius: 24.r,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18.r,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Drag Pill
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // 2. Showcase Header Card
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryEmerald.withValues(alpha: 0.12),
                      AppColors.bgCard,
                      AppColors.clinicalCyan.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.28),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                            blurRadius: 8.r,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isExpiryMode ? Icons.hourglass_top_rounded : Icons.calendar_month_rounded,
                        color: AppColors.white,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryEmerald.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  widget.isExpiryMode ? 'EXPIRY' : 'TODAY',
                                  style: TextStyle(
                                    fontSize: 8.5.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryEmeraldDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _formatDateTitle(_selectedDate),
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // 3. Quick Presets Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    if (!widget.isExpiryMode) ...[
                      _buildPresetChip('Today', DateTime.now()),
                      SizedBox(width: 6.w),
                      _buildPresetChip('Yesterday', DateTime.now().subtract(const Duration(days: 1))),
                      SizedBox(width: 6.w),
                      _buildPresetChip('+7 Days', DateTime.now().add(const Duration(days: 7))),
                      SizedBox(width: 6.w),
                      _buildPresetChip('+30 Days', DateTime.now().add(const Duration(days: 30))),
                    ] else ...[
                      _buildPresetChip('+6 Months', DateTime(DateTime.now().year, DateTime.now().month + 6, 1)),
                      SizedBox(width: 6.w),
                      _buildPresetChip('+1 Year', DateTime(DateTime.now().year + 1, DateTime.now().month, 1)),
                      SizedBox(width: 6.w),
                      _buildPresetChip('+2 Years', DateTime(DateTime.now().year + 2, DateTime.now().month, 1)),
                      SizedBox(width: 6.w),
                      _buildPresetChip('+3 Years', DateTime(DateTime.now().year + 3, DateTime.now().month, 1)),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 14.h),

              // 4. Month & Year Navigator Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isYearPickerOpen = !_isYearPickerOpen);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
                        border: Border.all(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_monthNames[_currentMonthView.month - 1]} ${_currentMonthView.year}',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmeraldDark,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            _isYearPickerOpen ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                            color: AppColors.primaryEmeraldDark,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      _buildNavArrow(Icons.chevron_left_rounded, _previousMonth),
                      SizedBox(width: 6.w),
                      _buildNavArrow(Icons.chevron_right_rounded, _nextMonth),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // 5. Calendar Grid or Year/Month Quick Jump View
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _isYearPickerOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _buildDaysCalendarView(),
                secondChild: _buildYearMonthSelector(),
              ),

              SizedBox(height: 20.h),

              // 6. Action Footer (Cancel & Confirm)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      title: 'Cancel',
                      variant: ButtonVariant.glass,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      title: 'Confirm Date',
                      icon: Icons.check_circle_rounded,
                      variant: ButtonVariant.gradient,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, _selectedDate);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Center(
          child: Icon(icon, size: 20.sp, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, DateTime date) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;

    return GestureDetector(
      onTap: () => _selectPreset(date),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryEmerald : AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primaryEmerald : AppColors.borderSubtle,
            width: 1.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                    blurRadius: 6.r,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDaysCalendarView() {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonthView.year, _currentMonthView.month);
    final firstDayOffset = (DateTime(_currentMonthView.year, _currentMonthView.month, 1).weekday - 1);
    final totalCells = firstDayOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: [
        // Week Days Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _weekDays.map((d) {
            return SizedBox(
              width: 36.w,
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8.h),

        // Days Grid
        Table(
          children: List.generate(rowCount, (rowIndex) {
            return TableRow(
              children: List.generate(7, (colIndex) {
                final dayNumber = (rowIndex * 7 + colIndex) - firstDayOffset + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox();
                }

                final cellDate = DateTime(_currentMonthView.year, _currentMonthView.month, dayNumber);
                final isSelected = cellDate.year == _selectedDate.year &&
                    cellDate.month == _selectedDate.month &&
                    cellDate.day == _selectedDate.day;

                final now = DateTime.now();
                final isToday = cellDate.year == now.year &&
                    cellDate.month == now.month &&
                    cellDate.day == now.day;

                final isEnabled = !cellDate.isBefore(widget.firstDate) &&
                    !cellDate.isAfter(widget.lastDate);

                return GestureDetector(
                  onTap: isEnabled
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedDate = cellDate);
                        }
                      : null,
                  child: Container(
                    height: 38.h,
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isToday && !isSelected
                          ? AppColors.primaryEmerald.withValues(alpha: 0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primaryEmerald, width: 1.2.w)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryEmerald.withValues(alpha: 0.35),
                                blurRadius: 8.r,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isEnabled
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildYearMonthSelector() {
    final startYear = widget.firstDate.year;
    final endYear = widget.lastDate.year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    return Container(
      height: 220.h,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          // Months Column
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: 12,
              itemBuilder: (ctx, idx) {
                final month = idx + 1;
                final isSelectedMonth = _currentMonthView.month == month;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentMonthView = DateTime(_currentMonthView.year, month, 1);
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isSelectedMonth ? AppColors.primaryEmerald : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _monthNames[idx],
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: isSelectedMonth ? FontWeight.w800 : FontWeight.w600,
                        color: isSelectedMonth ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(width: 1.w, color: AppColors.borderSubtle),

          // Years Column
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: years.length,
              itemBuilder: (ctx, idx) {
                final year = years[idx];
                final isSelectedYear = _currentMonthView.year == year;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentMonthView = DateTime(year, _currentMonthView.month, 1);
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: isSelectedYear ? AppColors.primaryEmeraldDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: isSelectedYear ? FontWeight.w800 : FontWeight.w600,
                          color: isSelectedYear ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
