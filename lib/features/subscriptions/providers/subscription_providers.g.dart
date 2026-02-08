// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionsListHash() => r'cb4000f1521b3a070a27d9c4ab16a1801340b201';

/// See also [subscriptionsList].
@ProviderFor(subscriptionsList)
final subscriptionsListProvider =
    AutoDisposeProvider<List<Subscription>>.internal(
  subscriptionsList,
  name: r'subscriptionsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SubscriptionsListRef = AutoDisposeProviderRef<List<Subscription>>;
String _$monthlyTotalHash() => r'3e493dbec2f9e3165fbe8dcf8e992595d60382c1';

/// See also [monthlyTotal].
@ProviderFor(monthlyTotal)
final monthlyTotalProvider = AutoDisposeProvider<double>.internal(
  monthlyTotal,
  name: r'monthlyTotalProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$monthlyTotalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MonthlyTotalRef = AutoDisposeProviderRef<double>;
String _$yearlyTotalHash() => r'8e5ce8c29c86f4dee440b4f86050088b4c239623';

/// See also [yearlyTotal].
@ProviderFor(yearlyTotal)
final yearlyTotalProvider = AutoDisposeProvider<double>.internal(
  yearlyTotal,
  name: r'yearlyTotalProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$yearlyTotalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef YearlyTotalRef = AutoDisposeProviderRef<double>;
String _$dueSoonSubscriptionsHash() =>
    r'7ad98285c90b65bddb40eca709446cbf3186c5a0';

/// See also [dueSoonSubscriptions].
@ProviderFor(dueSoonSubscriptions)
final dueSoonSubscriptionsProvider =
    AutoDisposeProvider<List<Subscription>>.internal(
  dueSoonSubscriptions,
  name: r'dueSoonSubscriptionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dueSoonSubscriptionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DueSoonSubscriptionsRef = AutoDisposeProviderRef<List<Subscription>>;
String _$subscriptionByIdHash() => r'c645f5ef6d4cba4191233b264fcf9abcc51fef78';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [subscriptionById].
@ProviderFor(subscriptionById)
const subscriptionByIdProvider = SubscriptionByIdFamily();

/// See also [subscriptionById].
class SubscriptionByIdFamily extends Family<Subscription?> {
  /// See also [subscriptionById].
  const SubscriptionByIdFamily();

  /// See also [subscriptionById].
  SubscriptionByIdProvider call(
    String id,
  ) {
    return SubscriptionByIdProvider(
      id,
    );
  }

  @override
  SubscriptionByIdProvider getProviderOverride(
    covariant SubscriptionByIdProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'subscriptionByIdProvider';
}

/// See also [subscriptionById].
class SubscriptionByIdProvider extends AutoDisposeProvider<Subscription?> {
  /// See also [subscriptionById].
  SubscriptionByIdProvider(
    String id,
  ) : this._internal(
          (ref) => subscriptionById(
            ref as SubscriptionByIdRef,
            id,
          ),
          from: subscriptionByIdProvider,
          name: r'subscriptionByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$subscriptionByIdHash,
          dependencies: SubscriptionByIdFamily._dependencies,
          allTransitiveDependencies:
              SubscriptionByIdFamily._allTransitiveDependencies,
          id: id,
        );

  SubscriptionByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Subscription? Function(SubscriptionByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionByIdProvider._internal(
        (ref) => create(ref as SubscriptionByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Subscription?> createElement() {
    return _SubscriptionByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SubscriptionByIdRef on AutoDisposeProviderRef<Subscription?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _SubscriptionByIdProviderElement
    extends AutoDisposeProviderElement<Subscription?> with SubscriptionByIdRef {
  _SubscriptionByIdProviderElement(super.provider);

  @override
  String get id => (origin as SubscriptionByIdProvider).id;
}

String _$filteredSubscriptionsHash() =>
    r'634e8ccfdc5a6246ee2e98d3741fbc0e8302975a';

/// See also [filteredSubscriptions].
@ProviderFor(filteredSubscriptions)
final filteredSubscriptionsProvider =
    AutoDisposeProvider<List<Subscription>>.internal(
  filteredSubscriptions,
  name: r'filteredSubscriptionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredSubscriptionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredSubscriptionsRef = AutoDisposeProviderRef<List<Subscription>>;
String _$hasActiveFiltersHash() => r'14a2b6544f748a4b1ed6b77859ba80b94c1ab884';

/// See also [hasActiveFilters].
@ProviderFor(hasActiveFilters)
final hasActiveFiltersProvider = AutoDisposeProvider<bool>.internal(
  hasActiveFilters,
  name: r'hasActiveFiltersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasActiveFiltersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HasActiveFiltersRef = AutoDisposeProviderRef<bool>;
String _$subscriptionsNotifierHash() =>
    r'5f93fe2be98cf91ebe5774054ddc569a1b6b996d';

/// Main async notifier for subscriptions
///
/// Copied from [SubscriptionsNotifier].
@ProviderFor(SubscriptionsNotifier)
final subscriptionsNotifierProvider =
    AsyncNotifierProvider<SubscriptionsNotifier, List<Subscription>>.internal(
  SubscriptionsNotifier.new,
  name: r'subscriptionsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionsNotifier = AsyncNotifier<List<Subscription>>;
String _$searchQueryHash() => r'790bd96a8a13bb944767c7bf06a5378cfc78a54d';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
  SearchQuery.new,
  name: r'searchQueryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchQuery = AutoDisposeNotifier<String>;
String _$categoryFilterHash() => r'c4fd177714b069bc012543e81a8b566a40a32b00';

/// See also [CategoryFilter].
@ProviderFor(CategoryFilter)
final categoryFilterProvider =
    AutoDisposeNotifierProvider<CategoryFilter, SubscriptionCategory?>.internal(
  CategoryFilter.new,
  name: r'categoryFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoryFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CategoryFilter = AutoDisposeNotifier<SubscriptionCategory?>;
String _$sortByHash() => r'606c7378af26594e9c60d269f3b45bae441796c8';

/// See also [SortBy].
@ProviderFor(SortBy)
final sortByProvider = AutoDisposeNotifierProvider<SortBy, SortOption>.internal(
  SortBy.new,
  name: r'sortByProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sortByHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SortBy = AutoDisposeNotifier<SortOption>;
String _$sortAscendingHash() => r'628585c20c23bfd0d3205e1315d64b01664c3337';

/// See also [SortAscending].
@ProviderFor(SortAscending)
final sortAscendingProvider =
    AutoDisposeNotifierProvider<SortAscending, bool>.internal(
  SortAscending.new,
  name: r'sortAscendingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sortAscendingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SortAscending = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
