// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionsListHash() => r'3a26de520475e95acf7fcce7888594a2264e36c2';

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
String _$monthlyTotalHash() => r'efc07e78be0ca4be0163f16215ebbded13993452';

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
String _$yearlyTotalHash() => r'767cae49329de4d667f7fcba6cba639b92c9b573';

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
    r'7e4da5451d5412552b086c4abf0bd1b05366aa69';

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
String _$subscriptionByIdHash() => r'e8ac28f28f86488b6258c4eb4d591a8a19b6209c';

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

/// Provider that filters active subscriptions based on the search query.
/// Searches in name, description, and category label.
///
/// Copied from [filteredSubscriptions].
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

/// Returns true if any filter or sort is active (non-default).
///
/// Copied from [hasActiveFilters].
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
    r'1f7884cb7e4413cf23475e541561f4725478c667';

/// Main provider that holds the list of all subscriptions.
/// This is the single source of truth - all other providers derive from this.
///
/// Copied from [SubscriptionsNotifier].
@ProviderFor(SubscriptionsNotifier)
final subscriptionsNotifierProvider =
    NotifierProvider<SubscriptionsNotifier, List<Subscription>>.internal(
  SubscriptionsNotifier.new,
  name: r'subscriptionsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscriptionsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionsNotifier = Notifier<List<Subscription>>;
String _$searchQueryHash() => r'b07ebd22fb9cb0db36c8d833cc6e21f4fcbd9b7b';

/// Provider for the search query state.
///
/// Copied from [SearchQuery].
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
String _$categoryFilterHash() => r'ef9e96c70615e3974cca3c7ecc26bfe2905fe447';

/// Provider for the selected category filter.
/// null means "All Categories".
///
/// Copied from [CategoryFilter].
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
String _$sortByHash() => r'e02daf01cac0ab4d7242db3544513da000be8f15';

/// Provider for the current sort option.
///
/// Copied from [SortBy].
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
String _$sortAscendingHash() => r'361c60808efbf979242ac54040dde891eb043bbe';

/// Provider for the sort direction.
/// true = ascending, false = descending.
///
/// Copied from [SortAscending].
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
