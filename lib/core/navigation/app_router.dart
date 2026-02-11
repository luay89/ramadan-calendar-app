import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// DI
import '../di/injection.dart';

// Blocs
import '../../features/prayer_times/presentation/bloc/prayer_times_bloc.dart';
import '../../features/calendar/presentation/bloc/calendar_bloc.dart';

// الصفحات
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/prayer_times/presentation/pages/prayer_times_page.dart';
import '../../features/ramadan/presentation/pages/ramadan_page.dart';
import '../../features/tonight_actions/presentation/pages/tonight_actions_page.dart';
import '../../features/duas/presentation/pages/duas_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import 'app_shell.dart';

/// إعدادات التوجيه
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/prayer-times',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/prayer-times',
            name: 'prayer-times',
            pageBuilder:
                (context, state) => NoTransitionPage(
                  child: BlocProvider(
                    create: (context) => getIt<PrayerTimesBloc>(),
                    child: const PrayerTimesPage(),
                  ),
                ),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            pageBuilder:
                (context, state) => NoTransitionPage(
                  child: BlocProvider(
                    create: (context) => getIt<CalendarBloc>(),
                    child: const CalendarPage(),
                  ),
                ),
          ),
          GoRoute(
            path: '/tonight',
            name: 'tonight',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: TonightActionsPage()),
          ),
          GoRoute(
            path: '/ramadan',
            name: 'ramadan',
            pageBuilder:
                (context, state) => NoTransitionPage(
                  child: BlocProvider(
                    create:
                        (context) =>
                            getIt<PrayerTimesBloc>()
                              ..add(const LoadPrayerTimes()),
                    child: const RamadanPage(),
                  ),
                ),
          ),
          GoRoute(
            path: '/duas',
            name: 'duas',
            pageBuilder:
                (context, state) => const NoTransitionPage(child: DuasPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'الصفحة غير موجودة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  state.uri.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/prayer-times'),
                  icon: const Icon(Icons.home),
                  label: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
  );
}
