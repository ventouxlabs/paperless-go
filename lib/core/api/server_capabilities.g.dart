// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_capabilities.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$serverCapabilitiesHash() =>
    r'97af4728ed8483e19cf1b71b7ef8568835903f9c';

/// Raw result of asking the active server for its capabilities. Watches
/// [paperlessApiProvider], so it rebuilds on login, logout and profile switch;
/// nothing invalidates it manually.
///
/// A failed request is rethrown, so an error state means "couldn't ask", which
/// is not the same as the server saying AI is off (a screen can offer a
/// refresh). UI must NOT gate on this provider or on `.future`: Riverpod keeps
/// the previous value on a loading or error rebuild, so a profile switch would
/// briefly show the previous server's capabilities. Use
/// [effectiveServerCapabilitiesProvider].
///
/// Copied from [serverCapabilities].
@ProviderFor(serverCapabilities)
final serverCapabilitiesProvider = FutureProvider<ServerCapabilities>.internal(
  serverCapabilities,
  name: r'serverCapabilitiesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$serverCapabilitiesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ServerCapabilitiesRef = FutureProviderRef<ServerCapabilities>;
String _$effectiveServerCapabilitiesHash() =>
    r'de851b5aed66c09d3bb0285c019a08cc32b7244e';

/// THE API for consumers: the capabilities UI should gate on. Synchronous and
/// fail-closed: it is [ServerCapabilities.none] while loading, after an error
/// and while signed out, and it never carries the previous server's value
/// (`unwrapPrevious` drops it).
///
/// Copied from [effectiveServerCapabilities].
@ProviderFor(effectiveServerCapabilities)
final effectiveServerCapabilitiesProvider =
    AutoDisposeProvider<ServerCapabilities>.internal(
      effectiveServerCapabilities,
      name: r'effectiveServerCapabilitiesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$effectiveServerCapabilitiesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EffectiveServerCapabilitiesRef =
    AutoDisposeProviderRef<ServerCapabilities>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
