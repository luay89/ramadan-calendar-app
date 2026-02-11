import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';

/// ويدجت يوم رمضان الحالي
class TodayRamadanWidget extends StatelessWidget {
  const TodayRamadanWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final hijri = AppDateUtils.currentHijri;
    final isRamadan = AppDateUtils.isRamadan(hijri);

    if (!isRamadan) {
      return _buildNotRamadanView(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // بطاقة اليوم
          _buildDayCard(context, hijri.hDay),
          const SizedBox(height: 16),

          // أوقات السحور والإفطار
          _buildTimesCard(context),
          const SizedBox(height: 16),

          // العد التنازلي
          _buildCountdownCard(context),
          const SizedBox(height: 16),

          // أعمال اليوم
          _buildActionsCard(context, hijri.hDay),
        ],
      ),
    );
  }

  Widget _buildNotRamadanView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mosque,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'لسنا في شهر رمضان حالياً',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض المعلومات عند دخول الشهر الكريم',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, int day) {
    final isLaylatalQadr = [19, 21, 23].contains(day);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isLaylatalQadr
            ? AppColors.nightGradient
            : AppColors.ramadanGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (isLaylatalQadr
                        ? AppColors.laylatalQadr
                        : AppColors.ramadanPurple)
                    .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isLaylatalQadr)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ramadanGold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'ليلة القدر',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'اليوم $day',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'من شهر رمضان المبارك',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppDateUtils.formatGregorianArabic(DateTime.now()),
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesCard(BuildContext context) {
    // هذه القيم ستأتي من PrayerTimesBloc
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTimeItem(
                    context,
                    'السحور',
                    '04:30', // مثال
                    Icons.nightlight_round,
                    AppColors.fajrColor,
                  ),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade300),
                Expanded(
                  child: _buildTimeItem(
                    context,
                    'الإفطار',
                    '18:45', // مثال
                    Icons.wb_sunny,
                    AppColors.maghribColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem(
    BuildContext context,
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.timer, color: AppColors.primary, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الوقت المتبقي للإفطار',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '05:30:45', // مثال - سيأتي من الـ Bloc
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, int day) {
    final actions = _getDayActions(day);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أعمال هذا اليوم',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...actions.map(
              (action) => ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
                title: Text(action),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getDayActions(int day) {
    final baseActions = [
      'صلاة الفجر في وقتها',
      'قراءة دعاء الصباح',
      'تلاوة القرآن الكريم',
      'صلاة الظهرين',
      'دعاء الإفطار',
      'صلاة المغربين',
    ];

    if ([19, 21, 23].contains(day)) {
      return [
        ...baseActions,
        'إحياء ليلة القدر',
        'قراءة دعاء الجوشن الكبير',
        'زيارة الإمام الحسين (ع)',
      ];
    }

    return baseActions;
  }
}
