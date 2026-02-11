import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// الهيكل الرئيسي للتطبيق مع شريط التنقل السفلي
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/settings'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    int selectedIndex = 0;
    if (currentLocation.startsWith('/prayer-times')) {
      selectedIndex = 0;
    } else if (currentLocation.startsWith('/calendar')) {
      selectedIndex = 1;
    } else if (currentLocation.startsWith('/tonight')) {
      selectedIndex = 2;
    } else if (currentLocation.startsWith('/ramadan')) {
      selectedIndex = 3;
    } else if (currentLocation.startsWith('/duas')) {
      selectedIndex = 4;
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/prayer-times');
            break;
          case 1:
            context.go('/calendar');
            break;
          case 2:
            context.go('/tonight');
            break;
          case 3:
            context.go('/ramadan');
            break;
          case 4:
            context.go('/duas');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.access_time_outlined),
          selectedIcon: Icon(Icons.access_time_filled),
          label: 'الصلاة',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'التقويم',
        ),
        NavigationDestination(
          icon: Icon(Icons.nightlight_outlined),
          selectedIcon: Icon(Icons.nightlight),
          label: 'الليلة',
        ),
        NavigationDestination(
          icon: Icon(Icons.nights_stay_outlined),
          selectedIcon: Icon(Icons.nights_stay),
          label: 'رمضان',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'الأدعية',
        ),
      ],
    );
  }
}
