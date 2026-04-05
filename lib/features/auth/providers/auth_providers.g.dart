// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isAuthenticatedHash() => r'3619bf2448d714d0044495c1d175cae7180e3c79';

/// Whether the user is currently authenticated.
///
/// Copied from [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = AutoDisposeProvider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsAuthenticatedRef = AutoDisposeProviderRef<bool>;
String _$isAdminHash() => r'9f98e119789655ac300ef3223794542634a5b699';

/// Whether the authenticated user has the Admin role.
///
/// Copied from [isAdmin].
@ProviderFor(isAdmin)
final isAdminProvider = AutoDisposeProvider<bool>.internal(
  isAdmin,
  name: r'isAdminProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isAdminHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsAdminRef = AutoDisposeProviderRef<bool>;
String _$currentUserHash() => r'9fa0fa27d0dee3b9a76759c8c6e8583f3db1d18a';

/// The current user profile, or `null` if not authenticated.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<UserProfile?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentUserRef = AutoDisposeProviderRef<UserProfile?>;
String _$authNotifierHash() => r'4c6ae48c64304068489aed963ac64b3937e0845e';

/// Global authentication notifier.
///
/// Manages the full auth lifecycle: initialisation from stored tokens,
/// login, registration, logout and token refresh.
///
/// Uses [keepAlive] so the auth state persists for the app lifetime.
///
/// Copied from [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = Notifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
