import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/features/settings/screens/settings_screen.dart';
import 'package:subtracker/features/subscriptions/screens/home_screen.dart';
import 'package:subtracker/features/subscriptions/screens/subscription_form_screen.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const home = '/';
  static const addSubscription = '/subscription/add';
  static const editSubscription = '/subscription/edit/:id';
  static const settings = '/settings';

  static String editSubscriptionPath(String id) => '/subscription/edit/$id';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
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
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
}
