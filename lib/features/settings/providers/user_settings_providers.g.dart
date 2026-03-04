// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsApiServiceHash() =>
    r'6bf7c19a8feb18184f4255b66400de3f76f60da7';

/// Provides the [SettingsApiService] instance.
///
/// Copied from [settingsApiService].
@ProviderFor(settingsApiService)
final settingsApiServiceProvider =
    AutoDisposeProvider<SettingsApiService>.internal(
  settingsApiService,
  name: r'settingsApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SettingsApiServiceRef = AutoDisposeProviderRef<SettingsApiService>;
String _$baseCurrencyHash() => r'5ce4c8904bd86633a768493457fe3dd54a21b94b';

/// Derived provider that exposes just the base currency string.
/// Falls back to 'EUR' while loading or on error.
///
/// Copied from [baseCurrency].
@ProviderFor(baseCurrency)
final baseCurrencyProvider = AutoDisposeProvider<String>.internal(
  baseCurrency,
  name: r'baseCurrencyProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$baseCurrencyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BaseCurrencyRef = AutoDisposeProviderRef<String>;
String _$userSettingsNotifierHash() =>
    r'370c51c628d71fb605b404b9d22fe8580a2a20e1';

/// Manages user settings (base currency) with API persistence.
///
/// Copied from [UserSettingsNotifier].
@ProviderFor(UserSettingsNotifier)
final userSettingsNotifierProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettings>.internal(
  UserSettingsNotifier.new,
  name: r'userSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserSettingsNotifier = AsyncNotifier<UserSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
