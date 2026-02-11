import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// رأس التقويم
class CalendarHeader extends StatelessWidget {
  final int month;
  final int year;
  final bool isHijri;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarHeader({
    super.key,
    required this.month,
    required this.year,
    required this.isHijri,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
          Column(
            children: [
              Text(
                isHijri
                    ? HijriMonths.arabicNames[month - 1]
                    : _getGregorianMonthName(month),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$year ${isHijri ? 'هـ' : 'م'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getGregorianMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month - 1];
  }
}
