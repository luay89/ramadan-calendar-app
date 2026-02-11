import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/laylatal_qadr_action.dart';
import '../../data/datasources/ramadan_local_datasource.dart';

/// ويدجت ليالي القدر
class LaylatalQadrWidget extends StatefulWidget {
  const LaylatalQadrWidget({super.key});

  @override
  State<LaylatalQadrWidget> createState() => _LaylatalQadrWidgetState();
}

class _LaylatalQadrWidgetState extends State<LaylatalQadrWidget> {
  int _selectedNight = 23;
  final _dataSource = RamadanLocalDataSource();
  final Map<String, bool> _completedActions = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // اختيار الليلة
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNightChip(19),
              _buildNightChip(21),
              _buildNightChip(23),
            ],
          ),
        ),

        // وصف الليلة
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.nightGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.star, color: AppColors.ramadanGold, size: 40),
              const SizedBox(height: 8),
              Text(
                'ليلة $_selectedNight',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getNightDescription(),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // قائمة الأعمال
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _dataSource.getActionsForNight(_selectedNight).length,
            itemBuilder: (context, index) {
              final action = _dataSource.getActionsForNight(
                _selectedNight,
              )[index];
              return _buildActionCard(action);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNightChip(int night) {
    final isSelected = _selectedNight == night;
    return GestureDetector(
      onTap: () => setState(() => _selectedNight = night),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.laylatalQadr : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.laylatalQadr.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (night == 23)
              const Icon(Icons.star, size: 16, color: AppColors.ramadanGold),
            Text(
              'ليلة $night',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNightDescription() {
    switch (_selectedNight) {
      case 19:
        return 'أولى ليالي القدر المحتملة';
      case 21:
        return 'ليلة شهادة أمير المؤمنين عليه السلام';
      case 23:
        return 'أرجح ليالي القدر - خير من ألف شهر';
      default:
        return '';
    }
  }

  Widget _buildActionCard(LaylatalQadrAction action) {
    final isCompleted = _completedActions[action.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.success.withValues(alpha: 0.2)
                : _getActionColor(action.type).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActionIcon(action.type),
            color: isCompleted
                ? AppColors.success
                : _getActionColor(action.type),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                action.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (action.repeatCount != null)
              Chip(
                label: Text('${action.repeatCount} مرة'),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                labelStyle: const TextStyle(fontSize: 10),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: Text(
          action.type.arabicName,
          style: TextStyle(fontSize: 12, color: _getActionColor(action.type)),
        ),
        trailing: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            setState(() {
              _completedActions[action.id] = value ?? false;
            });
          },
          activeColor: AppColors.success,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.description),
                if (action.arabicText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      action.arabicText!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Amiri',
                        height: 2,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(ActionType type) {
    switch (type) {
      case ActionType.ghusl:
        return Icons.water_drop;
      case ActionType.prayer:
        return Icons.mosque;
      case ActionType.dua:
        return Icons.front_hand;
      case ActionType.quran:
        return Icons.menu_book;
      case ActionType.dhikr:
        return Icons.repeat;
      case ActionType.ziyarat:
        return Icons.place;
      case ActionType.sadaqa:
        return Icons.volunteer_activism;
      case ActionType.other:
        return Icons.star;
    }
  }

  Color _getActionColor(ActionType type) {
    switch (type) {
      case ActionType.ghusl:
        return Colors.blue;
      case ActionType.prayer:
        return AppColors.primary;
      case ActionType.dua:
        return AppColors.ramadanPurple;
      case ActionType.quran:
        return Colors.teal;
      case ActionType.dhikr:
        return Colors.orange;
      case ActionType.ziyarat:
        return Colors.brown;
      case ActionType.sadaqa:
        return Colors.pink;
      case ActionType.other:
        return AppColors.secondary;
    }
  }
}
