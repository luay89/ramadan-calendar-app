import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/islamic_event.dart';

/// ويدجت قائمة الأحداث
class EventListWidget extends StatelessWidget {
  final List<IslamicEvent> events;
  final CalendarDay selectedDay;

  const EventListWidget({
    super.key,
    required this.events,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان اليوم
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppDateUtils.formatHijriArabic(selectedDay.hijriDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  AppDateUtils.getDayNameArabic(selectedDay.gregorianDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // قائمة الأحداث
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _EventCard(event: event);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final IslamicEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getEventColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getEventIcon(), color: _getEventColor(), size: 24),
        ),
        title: Text(
          event.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          event.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: event.isMourning
            ? const Icon(Icons.flag, color: Colors.black54, size: 16)
            : event.isHoliday
            ? const Icon(Icons.celebration, color: AppColors.success, size: 16)
            : null,
        onTap: () {
          _showEventDetails(context, event);
        },
      ),
    );
  }

  Color _getEventColor() {
    if (event.isMourning) return Colors.grey.shade700;
    switch (event.type) {
      case EventType.birth:
        return AppColors.success;
      case EventType.martyrdom:
        return Colors.red.shade700;
      case EventType.death:
        return Colors.grey.shade600;
      case EventType.eid:
        return AppColors.secondary;
      case EventType.religious:
        return AppColors.primary;
      case EventType.historical:
        return Colors.brown;
      case EventType.special:
        return AppColors.ramadanPurple;
    }
  }

  IconData _getEventIcon() {
    switch (event.type) {
      case EventType.birth:
        return Icons.child_care;
      case EventType.martyrdom:
        return Icons.bookmark;
      case EventType.death:
        return Icons.bookmark_outline;
      case EventType.eid:
        return Icons.celebration;
      case EventType.religious:
        return Icons.mosque;
      case EventType.historical:
        return Icons.history;
      case EventType.special:
        return Icons.stars;
    }
  }

  void _showEventDetails(BuildContext context, IslamicEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقبض السحب
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // العنوان
              Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // نوع الحدث
              Chip(
                label: Text(event.type.arabicName),
                backgroundColor: _getEventColor().withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),

              // الوصف
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              // الإمام المرتبط
              if (event.imam != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      event.imam!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],

              // الأعمال المستحبة
              if (event.actions != null && event.actions!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'الأعمال المستحبة:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: event.actions!
                      .map(
                        (action) => Chip(
                          label: Text(action),
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
