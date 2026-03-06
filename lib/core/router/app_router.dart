import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/core/widgets/scaffold_with_navigation.dart';
import 'package:subtracker/features/analytics/screens/analytics_screen.dart';
import 'package:subtracker/features/settings/providers/settings_providers.dart';
import 'package:subtracker/features/settings/screens/settings_screen.dart';
import 'package:subtracker/features/subscriptions/screens/home_screen.dart';
import 'package:subtracker/features/subscriptions/screens/subscription_form_screen.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const home = '/';
  static const analytics = '/analytics';
  static const addSubscription = '/subscription/add';
  static const editSubscription = '/subscription/edit/:id';
  static const settings = '/settings';

  static String editSubscriptionPath(String id) => '/subscription/edit/$id';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Read the initial value once — the router is created only once.
  // We listen for changes and call router.refresh() so that the redirect
  // re-evaluates without recreating the entire GoRouter (which would lose
  // the current location).
  final refreshNotifier = ValueNotifier<bool>(
    ref.read(analyticsEnabledNotifierProvider),
  );

  ref
    ..listen(analyticsEnabledNotifierProvider, (_, next) {
      refreshNotifier.value = next;
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      refreshNotifier.notifyListeners();
    })
    ..onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final analyticsEnabled = refreshNotifier.value;
      if (!analyticsEnabled && state.matchedLocation == AppRoutes.analytics) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavigation(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.analytics,
                name: 'analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addSubscription,
        name: 'addSubscription',
        builder: (context, state) => const SubscriptionFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.editSubscription,
        name: 'editSubscription',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SubscriptionFormScreen(subscriptionId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );

  return router;
}
