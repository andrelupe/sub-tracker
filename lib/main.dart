import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/router/app_router.dart';
import 'package:subtracker/core/theme/app_theme.dart';
import 'package:subtracker/features/auth/models/auth_state.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/settings/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  runApp(
    const ProviderScope(
      child: SubTrackerApp(),
    ),
  );
}

/// Global key for showing SnackBars outside of widget context.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SubTrackerApp extends ConsumerWidget {
  const SubTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    // Listen for auth state changes to show session-expired message.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous != null &&
          previous.status == AuthStatus.authenticated &&
          next.status == AuthStatus.unauthenticated) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return MaterialApp.router(
      title: 'SubTracker',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
