import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/calendar_day.dart';
import '../bloc/calendar_bloc.dart';
import '../widgets/calendar_day_widget.dart';
import '../widgets/calendar_header.dart';
import '../widgets/event_list_widget.dart';

/// صفحة التقويم الرئيسية
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  void initState() {
    super.initState();
    // تحميل التقويم الهجري للشهر الحالي
    final today = AppDateUtils.currentHijri;
    context.read<CalendarBloc>().add(
      LoadCalendarDays(year: today.hYear, month: today.hMonth, isHijri: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقويم'),
        actions: [
          BlocBuilder<CalendarBloc, CalendarState>(
            builder: (context, state) {
              if (state is CalendarLoaded) {
                return IconButton(
                  onPressed: () {
                    context.read<CalendarBloc>().add(
                      const ToggleCalendarType(),
                    );
                  },
                  icon: Icon(
                    state.isHijri ? Icons.calendar_today : Icons.calendar_month,
                  ),
                  tooltip: state.isHijri
                      ? 'التقويم الميلادي'
                      : 'التقويم الهجري',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CalendarError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final today = AppDateUtils.currentHijri;
                      context.read<CalendarBloc>().add(
                        LoadCalendarDays(
                          year: today.hYear,
                          month: today.hMonth,
                          isHijri: true,
                        ),
                      );
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is CalendarLoaded) {
            return Column(
              children: [
                // رأس التقويم
                CalendarHeader(
                  month: state.currentMonth,
                  year: state.currentYear,
                  isHijri: state.isHijri,
                  onPreviousMonth: () {
                    context.read<CalendarBloc>().add(const ChangeMonth(-1));
                  },
                  onNextMonth: () {
                    context.read<CalendarBloc>().add(const ChangeMonth(1));
                  },
                ),

                // أيام الأسبوع
                _buildWeekDaysHeader(),

                // شبكة الأيام
                Expanded(flex: 2, child: _buildCalendarGrid(state.days)),

                // قائمة الأحداث
                if (state.selectedDay != null &&
                    state.selectedDayEvents != null &&
                    state.selectedDayEvents!.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: EventListWidget(
                      events: state.selectedDayEvents!,
                      selectedDay: state.selectedDay!,
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// بناء رأس أيام الأسبوع
  Widget _buildWeekDaysHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: WeekDays.arabicNames.map((day) {
          return Text(
            day,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          );
        }).toList(),
      ),
    );
  }

  /// بناء شبكة التقويم
  Widget _buildCalendarGrid(List<CalendarDay> days) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return CalendarDayWidget(
          day: day,
          onTap: () {
            context.read<CalendarBloc>().add(SelectDay(day));
          },
        );
      },
    );
  }
}
