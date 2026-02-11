import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dua_entity.dart';
import '../../data/datasources/duas_local_datasource.dart';
import '../widgets/dua_card.dart';
import '../widgets/dua_detail_page.dart';

/// صفحة الأدعية والزيارات
class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  final _dataSource = DuasLocalDataSource();
  DuaCategory? _selectedCategory;
  final String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأدعية والزيارات'),
        actions: [
          IconButton(
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التصنيفات
          _buildCategoryChips(),

          // قائمة الأدعية
          Expanded(child: _buildDuasList()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(null, 'الكل'),
          ...DuaCategory.values.map(
            (category) => _buildChip(category, category.arabicName),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(DuaCategory? category, String label) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDuasList() {
    var duas = _dataSource.getAllDuas();

    // تصفية حسب التصنيف
    if (_selectedCategory != null) {
      duas = duas.where((d) => d.category == _selectedCategory).toList();
    }

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      duas = duas
          .where(
            (d) =>
                d.title.contains(_searchQuery) ||
                d.arabicText.contains(_searchQuery),
          )
          .toList();
    }

    if (duas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // تجميع الأدعية حسب التصنيف
    if (_selectedCategory == null && _searchQuery.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: DuaCategory.values.map((category) {
          final categoryDuas = duas
              .where((d) => d.category == category)
              .toList();
          if (categoryDuas.isEmpty) return const SizedBox.shrink();

          return _buildCategorySection(category, categoryDuas);
        }).toList(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: duas.length,
      itemBuilder: (context, index) {
        return DuaCard(
          dua: duas[index],
          onTap: () => _openDuaDetail(duas[index]),
        );
      },
    );
  }

  Widget _buildCategorySection(DuaCategory category, List<DuaEntity> duas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              category.arabicName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: duas.length > 5 ? 5 : duas.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200,
                child: DuaCard(
                  dua: duas[index],
                  onTap: () => _openDuaDetail(duas[index]),
                  isCompact: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: DuaSearchDelegate(_dataSource, _openDuaDetail),
    );
  }

  void _openDuaDetail(DuaEntity dua) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DuaDetailPage(dua: dua)),
    );
  }
}

/// مندوب البحث
class DuaSearchDelegate extends SearchDelegate<DuaEntity?> {
  final DuasLocalDataSource dataSource;
  final Function(DuaEntity) onDuaSelected;

  DuaSearchDelegate(this.dataSource, this.onDuaSelected);

  @override
  String get searchFieldLabel => 'ابحث في الأدعية...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = dataSource.getAllDuas().where((dua) {
      return dua.title.contains(query) || dua.arabicText.contains(query);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final dua = results[index];
        return ListTile(
          title: Text(dua.title),
          subtitle: Text(
            dua.category.arabicName,
            style: TextStyle(color: AppColors.primary),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(dua.category.icon),
          ),
          onTap: () {
            close(context, dua);
            onDuaSelected(dua);
          },
        );
      },
    );
  }
}
