import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';

/// تقويم مدمج يعرض التاريخ الهجري والميلادي معاً
class HijriGregorianCalendar extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime>? onDateSelected;

  const HijriGregorianCalendar({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.onDateSelected,
  });

  @override
  State<HijriGregorianCalendar> createState() => _HijriGregorianCalendarState();
}

class _HijriGregorianCalendarState extends State<HijriGregorianCalendar> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildWeekDaysHeader(),
        const SizedBox(height: 4),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    final hijriMonth = AppDateUtils.gregorianToHijri(_currentMonth);
    final hijriMonthName = AppDateUtils.getHijriMonthName(hijriMonth.hMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _canGoNext ? _nextMonth : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(
            children: [
              // الشهر الميلادي
              Text(
                _getGregorianMonthName(_currentMonth.month) +
                    ' ${_currentMonth.year}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              // الشهر الهجري
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.brightness_2, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '$hijriMonthName ${hijriMonth.hYear} هـ',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.amber),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _canGoPrevious ? _previousMonth : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildWeekDaysHeader() {
    const weekDays = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    return Row(
      children:
          weekDays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    // تحويل weekday ليبدأ من السبت (السبت = 0)
    final startOffset = (firstWeekday + 1) % 7;

    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.7, // جعل الخلايا أطول لاستيعاب التاريخين
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(
          _currentMonth.year,
          _currentMonth.month,
          dayNumber,
        );
        return _buildDayCell(date);
      },
    );
  }

  Widget _buildDayCell(DateTime date) {
    final hijriDate = AppDateUtils.gregorianToHijri(date);
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final isEnabled =
        !date.isBefore(widget.firstDate) && !date.isAfter(widget.lastDate);

    return GestureDetector(
      onTap: isEnabled ? () => _selectDate(date) : null,
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary
                  : isToday
                  ? AppColors.primary.withOpacity(0.2)
                  : null,
          borderRadius: BorderRadius.circular(8),
          border:
              isToday && !isSelected
                  ? Border.all(color: AppColors.primary, width: 1)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // التاريخ الميلادي
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isSelected
                        ? Colors.white
                        : isEnabled
                        ? null
                        : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            // التاريخ الهجري
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${hijriDate.hDay}',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.amber.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected?.call(date);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  bool get _canGoPrevious {
    final previousMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month - 1,
      1,
    );
    return !previousMonth.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month, 1),
    );
  }

  bool get _canGoNext {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    return !nextMonth.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month, 1),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

/// دالة لعرض dialog التقويم المدمج
Future<DateTime?> showHijriGregorianCalendarPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  DateTime? selectedDate;

  final result = await showDialog<DateTime>(
    context: context,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'اختيار التاريخ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // التقويم
                HijriGregorianCalendar(
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onDateSelected: (date) {
                    selectedDate = date;
                  },
                ),
                const SizedBox(height: 16),
                // زر التأكيد
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        () =>
                            Navigator.pop(context, selectedDate ?? initialDate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );

  return result;
}
