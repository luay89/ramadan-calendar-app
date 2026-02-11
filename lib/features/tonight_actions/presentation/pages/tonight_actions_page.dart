import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/tonight_action.dart';
import '../../data/datasources/tonight_actions_datasource.dart';

/// صفحة أعمال الليلة
class TonightActionsPage extends StatefulWidget {
  const TonightActionsPage({super.key});

  @override
  State<TonightActionsPage> createState() => _TonightActionsPageState();
}

class _TonightActionsPageState extends State<TonightActionsPage> {
  final _dataSource = TonightActionsDataSource();
  final _completedActions = <String>{};
  late HijriCalendar _hijriDate;
  late List<TonightAction> _actions;

  @override
  void initState() {
    super.initState();
    _hijriDate = HijriCalendar.now();
    _actions = _dataSource.getTonightActions(_hijriDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أعمال الليلة'),
        actions: [
          IconButton(
            onPressed: _resetProgress,
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة التعيين',
          ),
        ],
      ),
      body: Column(
        children: [
          // معلومات الليلة
          _buildNightInfoCard(),

          // شريط التقدم
          _buildProgressBar(),

          // قائمة الأعمال
          Expanded(child: _buildActionsList()),
        ],
      ),
    );
  }

  Widget _buildNightInfoCard() {
    final String nightName = _getNightName();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.nightPrimary,
            AppColors.nightPrimary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nightName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_hijriDate.hDay} ${_hijriDate.longMonthName} ${_hijriDate.hYear}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNightStat(
                  icon: Icons.list_alt,
                  label: 'الأعمال',
                  value: '${_actions.length}',
                ),
                _buildNightStat(
                  icon: Icons.check_circle,
                  label: 'مكتمل',
                  value: '${_completedActions.length}',
                ),
                _buildNightStat(
                  icon: Icons.pending,
                  label: 'متبقي',
                  value: '${_actions.length - _completedActions.length}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = _actions.isEmpty
        ? 0.0
        : _completedActions.length / _actions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('التقدم'),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsList() {
    // تجميع الأعمال حسب وقت التنفيذ
    final groupedActions = <ActionTimeFrame, List<TonightAction>>{};
    for (var action in _actions) {
      groupedActions.putIfAbsent(action.timeFrame, () => []);
      groupedActions[action.timeFrame]!.add(action);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groupedActions.entries.map((entry) {
        return _buildTimeFrameSection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildTimeFrameSection(
    ActionTimeFrame timeFrame,
    List<TonightAction> actions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                _getTimeFrameIcon(timeFrame),
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                timeFrame.arabicName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        ...actions.map((action) => _buildActionCard(action)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionCard(TonightAction action) {
    final isCompleted = _completedActions.contains(action.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggleAction(action.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // صندوق التحديد
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.success : Colors.grey.shade200,
                  border: Border.all(
                    color: isCompleted ? AppColors.success : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),

              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            action.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted ? Colors.grey : null,
                                ),
                          ),
                        ),
                        _buildPriorityBadge(action.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (action.repeatCount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${action.repeatCount} مرة',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // أيقونة الفتح
              if (action.arabicText != null || action.relatedDuaId != null)
                IconButton(
                  onPressed: () => _showActionDetails(action),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(ActionPriority priority) {
    Color color;
    switch (priority) {
      case ActionPriority.high:
        color = Colors.red;
        break;
      case ActionPriority.normal:
        color = Colors.orange;
        break;
      case ActionPriority.optional:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        priority.arabicName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getTimeFrameIcon(ActionTimeFrame timeFrame) {
    switch (timeFrame) {
      case ActionTimeFrame.afterMaghrib:
        return Icons.wb_twilight;
      case ActionTimeFrame.beforeMidnight:
        return Icons.nightlight;
      case ActionTimeFrame.afterMidnight:
        return Icons.dark_mode;
      case ActionTimeFrame.lastThird:
        return Icons.access_time;
      case ActionTimeFrame.anytime:
        return Icons.schedule;
    }
  }

  String _getNightName() {
    final month = _hijriDate.hMonth;
    final day = _hijriDate.hDay;

    // ليالي القدر
    if (month == 9 && (day == 19 || day == 21 || day == 23)) {
      if (day == 19) return 'ليلة القدر - ليلة ضربة أمير المؤمنين';
      if (day == 21) return 'ليلة القدر الكبرى - ليلة شهادة أمير المؤمنين';
      return 'ليلة القدر';
    }

    // ليلة النصف من شعبان
    if (month == 8 && day == 15) {
      return 'ليلة النصف من شعبان - ولادة الإمام المهدي (عج)';
    }

    // ليلة المبعث
    if (month == 7 && day == 27) {
      return 'ليلة المبعث النبوي الشريف';
    }

    // ليلة عاشوراء
    if (month == 1 && day == 10) {
      return 'ليلة عاشوراء';
    }

    // ليلة الغدير
    if (month == 12 && day == 18) {
      return 'ليلة عيد الغدير الأغر';
    }

    // ليلة الجمعة
    final gregorian = _hijriDate.hijriToGregorian(
      _hijriDate.hYear,
      _hijriDate.hMonth,
      _hijriDate.hDay,
    );
    if (gregorian.weekday == DateTime.thursday) {
      return 'ليلة الجمعة المباركة';
    }

    return 'الليلة';
  }

  void _toggleAction(String actionId) {
    setState(() {
      if (_completedActions.contains(actionId)) {
        _completedActions.remove(actionId);
      } else {
        _completedActions.add(actionId);
      }
    });
  }

  void _resetProgress() {
    setState(() {
      _completedActions.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم إعادة التعيين')));
  }

  void _showActionDetails(TonightAction action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (action.arabicText != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        action.arabicText!,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 2.0,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _toggleAction(action.id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _completedActions.contains(action.id)
                            ? Colors.grey
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _completedActions.contains(action.id)
                            ? 'إلغاء التحديد'
                            : 'تحديد كمكتمل',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
