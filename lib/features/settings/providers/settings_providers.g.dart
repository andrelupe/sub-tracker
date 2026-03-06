// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$themeModeNotifierHash() => r'1e88411263c1cd54ad437c193b0564930206f461';

/// See also [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
  ThemeModeNotifier.new,
  name: r'themeModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeModeNotifier = Notifier<ThemeMode>;
String _$analyticsEnabledNotifierHash() =>
    r'305872d332671a280245c5e89a9da2d3a7daea45';

/// Whether the Analytics screen is enabled.
///
/// Disabled by default. Persisted in SharedPreferences.
///
/// Copied from [AnalyticsEnabledNotifier].
@ProviderFor(AnalyticsEnabledNotifier)
final analyticsEnabledNotifierProvider =
    NotifierProvider<AnalyticsEnabledNotifier, bool>.internal(
  AnalyticsEnabledNotifier.new,
  name: r'analyticsEnabledNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsEnabledNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnalyticsEnabledNotifier = Notifier<bool>;
String _$analyticsBannerDismissedNotifierHash() =>
    r'4baa1903c530cf8aab0bd58005f4b3607cc49789';

/// Whether the analytics promotional banner on the Home screen has been
/// permanently dismissed by the user.
///
/// Copied from [AnalyticsBannerDismissedNotifier].
@ProviderFor(AnalyticsBannerDismissedNotifier)
final analyticsBannerDismissedNotifierProvider =
    NotifierProvider<AnalyticsBannerDismissedNotifier, bool>.internal(
  AnalyticsBannerDismissedNotifier.new,
  name: r'analyticsBannerDismissedNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsBannerDismissedNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnalyticsBannerDismissedNotifier = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
