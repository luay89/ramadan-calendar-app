import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/location_service.dart';

/// ويدجت البحث عن الموقع
class LocationSearchWidget extends StatefulWidget {
  final VoidCallback? onLocationChanged;

  const LocationSearchWidget({super.key, this.onLocationChanged});

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final _searchController = TextEditingController();
  List<String> _filteredCities = [];
  List<String> _allCities = [];
  String _selectedCity = '';

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    _allCities = LocationService.instance.getAvailableCities();
    _selectedCity = await LocationService.instance.getSavedCityName();
    setState(() {
      _filteredCities = _allCities;
    });
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _allCities;
      } else {
        _filteredCities =
            _allCities.where((city) => city.contains(query)).toList();
      }
    });
  }

  Future<void> _selectCity(String city) async {
    await LocationService.instance.saveSelectedCity(city);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تغيير الموقع إلى: $city'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onLocationChanged?.call();
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (context, scrollController) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // مقبض السحب
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // العنوان
                Text(
                  'تغيير الموقع',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // حقل البحث
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مدينة...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterCities('');
                              },
                              icon: const Icon(Icons.clear),
                            )
                            : null,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: _filterCities,
                ),
                const SizedBox(height: 8),
                const Divider(),

                // قائمة المدن
                Expanded(
                  child:
                      _filteredCities.isEmpty
                          ? const Center(child: Text('لم يتم العثور على نتائج'))
                          : ListView.builder(
                            controller: scrollController,
                            itemCount: _filteredCities.length,
                            itemBuilder: (context, index) {
                              final city = _filteredCities[index];
                              final isSelected = city == _selectedCity;
                              return ListTile(
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.location_on,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                                title: Text(
                                  city,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected ? FontWeight.bold : null,
                                    color:
                                        isSelected ? AppColors.primary : null,
                                  ),
                                ),
                                onTap: () => _selectCity(city),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }
}
