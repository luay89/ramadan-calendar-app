import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/calendar_day.dart';

/// ويدجت يوم في التقويم
class CalendarDayWidget extends StatelessWidget {
  final CalendarDay day;
  final VoidCallback onTap;

  const CalendarDayWidget({super.key, required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // إذا كان اليوم فارغ، نعرض مربع فارغ
    if (day.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(8),
          border:
              day.isToday
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
          boxShadow:
              day.isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Stack(
          children: [
            // الرقم
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.hijriDate.hDay}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getTextColor(context),
                      fontWeight:
                          day.isToday || day.isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  if (day.hasEvent)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color:
                            day.isMourning
                                ? Colors.black
                                : day.isHoliday
                                ? AppColors.success
                                : AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),

            // مؤشر ليلة القدر
            if (day.isLaylatalQadr)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(Icons.star, size: 12, color: AppColors.ramadanGold),
              ),

            // مؤشر ليلة الجمعة
            if (day.isFridayNight)
              Positioned(
                top: 2,
                left: 2,
                child: Icon(
                  Icons.nightlight_round,
                  size: 10,
                  color: AppColors.primaryLight,
                ),
              ),

            // مؤشر الليالي البيض
            if (day.isWhiteNight)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (day.isSelected) {
      return AppColors.primary.withValues(alpha: 0.2);
    }

    if (day.isMourning) {
      return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    }

    if (day.isHoliday) {
      return isDark
          ? AppColors.success.withValues(alpha: 0.2)
          : AppColors.success.withValues(alpha: 0.1);
    }

    if (day.isLaylatalQadr) {
      return isDark
          ? AppColors.laylatalQadr.withValues(alpha: 0.3)
          : AppColors.laylatalQadr.withValues(alpha: 0.1);
    }

    if (day.isSpecialNight) {
      return isDark
          ? AppColors.secondary.withValues(alpha: 0.2)
          : AppColors.secondary.withValues(alpha: 0.1);
    }

    return Colors.transparent;
  }

  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (day.isMourning) {
      return isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    }

    if (day.isToday) {
      return AppColors.primary;
    }

    if (day.isSelected) {
      return AppColors.primary;
    }

    return isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  }
}
