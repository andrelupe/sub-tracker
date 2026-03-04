// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exchangeRateApiServiceHash() =>
    r'4208eadf79d661cf3f213e0c610a357a84310786';

/// Provides the [ExchangeRateApiService] instance.
///
/// Copied from [exchangeRateApiService].
@ProviderFor(exchangeRateApiService)
final exchangeRateApiServiceProvider =
    AutoDisposeProvider<ExchangeRateApiService>.internal(
  exchangeRateApiService,
  name: r'exchangeRateApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exchangeRateApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ExchangeRateApiServiceRef
    = AutoDisposeProviderRef<ExchangeRateApiService>;
String _$exchangeRatesNotifierHash() =>
    r'f79d22dd6da656fa237a1089b67a57c6951511e4';

/// Fetches and caches exchange rates for the user's base currency.
///
/// Rates are kept alive to avoid refetching on every screen transition.
/// Automatically rebuilds when the base currency changes.
///
/// Copied from [ExchangeRatesNotifier].
@ProviderFor(ExchangeRatesNotifier)
final exchangeRatesNotifierProvider =
    AsyncNotifierProvider<ExchangeRatesNotifier, ExchangeRate>.internal(
  ExchangeRatesNotifier.new,
  name: r'exchangeRatesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exchangeRatesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ExchangeRatesNotifier = AsyncNotifier<ExchangeRate>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
