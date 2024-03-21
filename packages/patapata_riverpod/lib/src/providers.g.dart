// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appHash() => r'b221fc2a0f1007056310f6ab8af4b3bdb50f2ecc';

/// The [App] instance.
///
/// Copied from [app].
@ProviderFor(app)
final appProvider = AutoDisposeProvider<App>.internal(
  app,
  name: r'appProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppRef = AutoDisposeProviderRef<App>;
String _$userHash() => r'185492973048a3679bb21cb6e2bf4ce15012ec7e';

/// The current [User].
/// Whenever [User] changes, this provider will be updated.
///
/// Copied from [user].
@ProviderFor(user)
final userProvider = AutoDisposeProvider<Raw<User>>.internal(
  user,
  name: r'userProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserRef = AutoDisposeProviderRef<Raw<User>>;
String _$remoteConfigHash() => r'8e75aba0bc4b5c62efcad5a0d20aba8538c17cd3';

/// Access to [RemoteConfig].
/// Whenever [RemoteConfig] changes, this provider will be updated.
///
/// Copied from [remoteConfig].
@ProviderFor(remoteConfig)
final remoteConfigProvider = AutoDisposeProvider<Raw<RemoteConfig>>.internal(
  remoteConfig,
  name: r'remoteConfigProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$remoteConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RemoteConfigRef = AutoDisposeProviderRef<Raw<RemoteConfig>>;
String _$remoteConfigStringHash() =>
    r'd3defab5f7870a383673f72bbe259deb968ff000';

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

/// Gets a [RemoteConfig] value as a [String].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigString].
@ProviderFor(remoteConfigString)
const remoteConfigStringProvider = RemoteConfigStringFamily();

/// Gets a [RemoteConfig] value as a [String].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigString].
class RemoteConfigStringFamily extends Family<String> {
  /// Gets a [RemoteConfig] value as a [String].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigString].
  const RemoteConfigStringFamily();

  /// Gets a [RemoteConfig] value as a [String].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigString].
  RemoteConfigStringProvider call(
    String key, [
    String defaultValue = Config.defaultValueForString,
  ]) {
    return RemoteConfigStringProvider(
      key,
      defaultValue,
    );
  }

  @override
  RemoteConfigStringProvider getProviderOverride(
    covariant RemoteConfigStringProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'remoteConfigStringProvider';
}

/// Gets a [RemoteConfig] value as a [String].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigString].
class RemoteConfigStringProvider extends AutoDisposeProvider<String> {
  /// Gets a [RemoteConfig] value as a [String].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigString].
  RemoteConfigStringProvider(
    String key, [
    String defaultValue = Config.defaultValueForString,
  ]) : this._internal(
          (ref) => remoteConfigString(
            ref as RemoteConfigStringRef,
            key,
            defaultValue,
          ),
          from: remoteConfigStringProvider,
          name: r'remoteConfigStringProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$remoteConfigStringHash,
          dependencies: RemoteConfigStringFamily._dependencies,
          allTransitiveDependencies:
              RemoteConfigStringFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  RemoteConfigStringProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final String defaultValue;

  @override
  Override overrideWith(
    String Function(RemoteConfigStringRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RemoteConfigStringProvider._internal(
        (ref) => create(ref as RemoteConfigStringRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _RemoteConfigStringProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RemoteConfigStringProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RemoteConfigStringRef on AutoDisposeProviderRef<String> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  String get defaultValue;
}

class _RemoteConfigStringProviderElement
    extends AutoDisposeProviderElement<String> with RemoteConfigStringRef {
  _RemoteConfigStringProviderElement(super.provider);

  @override
  String get key => (origin as RemoteConfigStringProvider).key;
  @override
  String get defaultValue =>
      (origin as RemoteConfigStringProvider).defaultValue;
}

String _$remoteConfigIntHash() => r'102555b16644b3768133e933fbb7e6b4e84efe61';

/// Gets a [RemoteConfig] value as a [int].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigInt].
@ProviderFor(remoteConfigInt)
const remoteConfigIntProvider = RemoteConfigIntFamily();

/// Gets a [RemoteConfig] value as a [int].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigInt].
class RemoteConfigIntFamily extends Family<int> {
  /// Gets a [RemoteConfig] value as a [int].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigInt].
  const RemoteConfigIntFamily();

  /// Gets a [RemoteConfig] value as a [int].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigInt].
  RemoteConfigIntProvider call(
    String key, [
    int defaultValue = Config.defaultValueForInt,
  ]) {
    return RemoteConfigIntProvider(
      key,
      defaultValue,
    );
  }

  @override
  RemoteConfigIntProvider getProviderOverride(
    covariant RemoteConfigIntProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'remoteConfigIntProvider';
}

/// Gets a [RemoteConfig] value as a [int].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigInt].
class RemoteConfigIntProvider extends AutoDisposeProvider<int> {
  /// Gets a [RemoteConfig] value as a [int].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigInt].
  RemoteConfigIntProvider(
    String key, [
    int defaultValue = Config.defaultValueForInt,
  ]) : this._internal(
          (ref) => remoteConfigInt(
            ref as RemoteConfigIntRef,
            key,
            defaultValue,
          ),
          from: remoteConfigIntProvider,
          name: r'remoteConfigIntProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$remoteConfigIntHash,
          dependencies: RemoteConfigIntFamily._dependencies,
          allTransitiveDependencies:
              RemoteConfigIntFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  RemoteConfigIntProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final int defaultValue;

  @override
  Override overrideWith(
    int Function(RemoteConfigIntRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RemoteConfigIntProvider._internal(
        (ref) => create(ref as RemoteConfigIntRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _RemoteConfigIntProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RemoteConfigIntProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RemoteConfigIntRef on AutoDisposeProviderRef<int> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  int get defaultValue;
}

class _RemoteConfigIntProviderElement extends AutoDisposeProviderElement<int>
    with RemoteConfigIntRef {
  _RemoteConfigIntProviderElement(super.provider);

  @override
  String get key => (origin as RemoteConfigIntProvider).key;
  @override
  int get defaultValue => (origin as RemoteConfigIntProvider).defaultValue;
}

String _$remoteConfigDoubleHash() =>
    r'f7cf93febfff6eab6e48c05bb7aa177e31aaf84b';

/// Gets a [RemoteConfig] value as a [double].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigDouble].
@ProviderFor(remoteConfigDouble)
const remoteConfigDoubleProvider = RemoteConfigDoubleFamily();

/// Gets a [RemoteConfig] value as a [double].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigDouble].
class RemoteConfigDoubleFamily extends Family<double> {
  /// Gets a [RemoteConfig] value as a [double].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigDouble].
  const RemoteConfigDoubleFamily();

  /// Gets a [RemoteConfig] value as a [double].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigDouble].
  RemoteConfigDoubleProvider call(
    String key, [
    double defaultValue = Config.defaultValueForDouble,
  ]) {
    return RemoteConfigDoubleProvider(
      key,
      defaultValue,
    );
  }

  @override
  RemoteConfigDoubleProvider getProviderOverride(
    covariant RemoteConfigDoubleProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'remoteConfigDoubleProvider';
}

/// Gets a [RemoteConfig] value as a [double].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigDouble].
class RemoteConfigDoubleProvider extends AutoDisposeProvider<double> {
  /// Gets a [RemoteConfig] value as a [double].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigDouble].
  RemoteConfigDoubleProvider(
    String key, [
    double defaultValue = Config.defaultValueForDouble,
  ]) : this._internal(
          (ref) => remoteConfigDouble(
            ref as RemoteConfigDoubleRef,
            key,
            defaultValue,
          ),
          from: remoteConfigDoubleProvider,
          name: r'remoteConfigDoubleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$remoteConfigDoubleHash,
          dependencies: RemoteConfigDoubleFamily._dependencies,
          allTransitiveDependencies:
              RemoteConfigDoubleFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  RemoteConfigDoubleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final double defaultValue;

  @override
  Override overrideWith(
    double Function(RemoteConfigDoubleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RemoteConfigDoubleProvider._internal(
        (ref) => create(ref as RemoteConfigDoubleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<double> createElement() {
    return _RemoteConfigDoubleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RemoteConfigDoubleProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RemoteConfigDoubleRef on AutoDisposeProviderRef<double> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  double get defaultValue;
}

class _RemoteConfigDoubleProviderElement
    extends AutoDisposeProviderElement<double> with RemoteConfigDoubleRef {
  _RemoteConfigDoubleProviderElement(super.provider);

  @override
  String get key => (origin as RemoteConfigDoubleProvider).key;
  @override
  double get defaultValue =>
      (origin as RemoteConfigDoubleProvider).defaultValue;
}

String _$remoteConfigBoolHash() => r'13a9e5417b965b88f843d5fa69b7cb03cb9fea95';

/// Gets a [RemoteConfig] value as a [bool].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigBool].
@ProviderFor(remoteConfigBool)
const remoteConfigBoolProvider = RemoteConfigBoolFamily();

/// Gets a [RemoteConfig] value as a [bool].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigBool].
class RemoteConfigBoolFamily extends Family<bool> {
  /// Gets a [RemoteConfig] value as a [bool].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigBool].
  const RemoteConfigBoolFamily();

  /// Gets a [RemoteConfig] value as a [bool].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigBool].
  RemoteConfigBoolProvider call(
    String key, [
    bool defaultValue = Config.defaultValueForBool,
  ]) {
    return RemoteConfigBoolProvider(
      key,
      defaultValue,
    );
  }

  @override
  RemoteConfigBoolProvider getProviderOverride(
    covariant RemoteConfigBoolProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'remoteConfigBoolProvider';
}

/// Gets a [RemoteConfig] value as a [bool].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [remoteConfigBool].
class RemoteConfigBoolProvider extends AutoDisposeProvider<bool> {
  /// Gets a [RemoteConfig] value as a [bool].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [remoteConfigBool].
  RemoteConfigBoolProvider(
    String key, [
    bool defaultValue = Config.defaultValueForBool,
  ]) : this._internal(
          (ref) => remoteConfigBool(
            ref as RemoteConfigBoolRef,
            key,
            defaultValue,
          ),
          from: remoteConfigBoolProvider,
          name: r'remoteConfigBoolProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$remoteConfigBoolHash,
          dependencies: RemoteConfigBoolFamily._dependencies,
          allTransitiveDependencies:
              RemoteConfigBoolFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  RemoteConfigBoolProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final bool defaultValue;

  @override
  Override overrideWith(
    bool Function(RemoteConfigBoolRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RemoteConfigBoolProvider._internal(
        (ref) => create(ref as RemoteConfigBoolRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _RemoteConfigBoolProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RemoteConfigBoolProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RemoteConfigBoolRef on AutoDisposeProviderRef<bool> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  bool get defaultValue;
}

class _RemoteConfigBoolProviderElement extends AutoDisposeProviderElement<bool>
    with RemoteConfigBoolRef {
  _RemoteConfigBoolProviderElement(super.provider);

  @override
  String get key => (origin as RemoteConfigBoolProvider).key;
  @override
  bool get defaultValue => (origin as RemoteConfigBoolProvider).defaultValue;
}

String _$localConfigHash() => r'2d0900f1e1f41f25456b738fcc2a18d4fd7cca59';

/// Access to [LocalConfig].
/// Whenever [LocalConfig] changes, this provider will be updated.
///
/// Copied from [localConfig].
@ProviderFor(localConfig)
final localConfigProvider = AutoDisposeProvider<Raw<LocalConfig>>.internal(
  localConfig,
  name: r'localConfigProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$localConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LocalConfigRef = AutoDisposeProviderRef<Raw<LocalConfig>>;
String _$localConfigStringHash() => r'5d87800e6aa2139e9129dba2d78145a941927fc5';

/// Gets a [LocalConfig] value as a [String].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigString].
@ProviderFor(localConfigString)
const localConfigStringProvider = LocalConfigStringFamily();

/// Gets a [LocalConfig] value as a [String].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigString].
class LocalConfigStringFamily extends Family<String> {
  /// Gets a [LocalConfig] value as a [String].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigString].
  const LocalConfigStringFamily();

  /// Gets a [LocalConfig] value as a [String].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigString].
  LocalConfigStringProvider call(
    String key, [
    String defaultValue = Config.defaultValueForString,
  ]) {
    return LocalConfigStringProvider(
      key,
      defaultValue,
    );
  }

  @override
  LocalConfigStringProvider getProviderOverride(
    covariant LocalConfigStringProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'localConfigStringProvider';
}

/// Gets a [LocalConfig] value as a [String].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigString].
class LocalConfigStringProvider extends AutoDisposeProvider<String> {
  /// Gets a [LocalConfig] value as a [String].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigString].
  LocalConfigStringProvider(
    String key, [
    String defaultValue = Config.defaultValueForString,
  ]) : this._internal(
          (ref) => localConfigString(
            ref as LocalConfigStringRef,
            key,
            defaultValue,
          ),
          from: localConfigStringProvider,
          name: r'localConfigStringProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$localConfigStringHash,
          dependencies: LocalConfigStringFamily._dependencies,
          allTransitiveDependencies:
              LocalConfigStringFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  LocalConfigStringProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final String defaultValue;

  @override
  Override overrideWith(
    String Function(LocalConfigStringRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LocalConfigStringProvider._internal(
        (ref) => create(ref as LocalConfigStringRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<String> createElement() {
    return _LocalConfigStringProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalConfigStringProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LocalConfigStringRef on AutoDisposeProviderRef<String> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  String get defaultValue;
}

class _LocalConfigStringProviderElement
    extends AutoDisposeProviderElement<String> with LocalConfigStringRef {
  _LocalConfigStringProviderElement(super.provider);

  @override
  String get key => (origin as LocalConfigStringProvider).key;
  @override
  String get defaultValue => (origin as LocalConfigStringProvider).defaultValue;
}

String _$localConfigIntHash() => r'4050a4918e2d6b5b05931444019231f0dd3def14';

/// Gets a [LocalConfig] value as a [int].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigInt].
@ProviderFor(localConfigInt)
const localConfigIntProvider = LocalConfigIntFamily();

/// Gets a [LocalConfig] value as a [int].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigInt].
class LocalConfigIntFamily extends Family<int> {
  /// Gets a [LocalConfig] value as a [int].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigInt].
  const LocalConfigIntFamily();

  /// Gets a [LocalConfig] value as a [int].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigInt].
  LocalConfigIntProvider call(
    String key, [
    int defaultValue = Config.defaultValueForInt,
  ]) {
    return LocalConfigIntProvider(
      key,
      defaultValue,
    );
  }

  @override
  LocalConfigIntProvider getProviderOverride(
    covariant LocalConfigIntProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'localConfigIntProvider';
}

/// Gets a [LocalConfig] value as a [int].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigInt].
class LocalConfigIntProvider extends AutoDisposeProvider<int> {
  /// Gets a [LocalConfig] value as a [int].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigInt].
  LocalConfigIntProvider(
    String key, [
    int defaultValue = Config.defaultValueForInt,
  ]) : this._internal(
          (ref) => localConfigInt(
            ref as LocalConfigIntRef,
            key,
            defaultValue,
          ),
          from: localConfigIntProvider,
          name: r'localConfigIntProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$localConfigIntHash,
          dependencies: LocalConfigIntFamily._dependencies,
          allTransitiveDependencies:
              LocalConfigIntFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  LocalConfigIntProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final int defaultValue;

  @override
  Override overrideWith(
    int Function(LocalConfigIntRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LocalConfigIntProvider._internal(
        (ref) => create(ref as LocalConfigIntRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _LocalConfigIntProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalConfigIntProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LocalConfigIntRef on AutoDisposeProviderRef<int> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  int get defaultValue;
}

class _LocalConfigIntProviderElement extends AutoDisposeProviderElement<int>
    with LocalConfigIntRef {
  _LocalConfigIntProviderElement(super.provider);

  @override
  String get key => (origin as LocalConfigIntProvider).key;
  @override
  int get defaultValue => (origin as LocalConfigIntProvider).defaultValue;
}

String _$localConfigDoubleHash() => r'177c15a70d201d5ec197ec3569a654193b6297fb';

/// Gets a [LocalConfig] value as a [double].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigDouble].
@ProviderFor(localConfigDouble)
const localConfigDoubleProvider = LocalConfigDoubleFamily();

/// Gets a [LocalConfig] value as a [double].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigDouble].
class LocalConfigDoubleFamily extends Family<double> {
  /// Gets a [LocalConfig] value as a [double].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigDouble].
  const LocalConfigDoubleFamily();

  /// Gets a [LocalConfig] value as a [double].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigDouble].
  LocalConfigDoubleProvider call(
    String key, [
    double defaultValue = Config.defaultValueForDouble,
  ]) {
    return LocalConfigDoubleProvider(
      key,
      defaultValue,
    );
  }

  @override
  LocalConfigDoubleProvider getProviderOverride(
    covariant LocalConfigDoubleProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'localConfigDoubleProvider';
}

/// Gets a [LocalConfig] value as a [double].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigDouble].
class LocalConfigDoubleProvider extends AutoDisposeProvider<double> {
  /// Gets a [LocalConfig] value as a [double].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigDouble].
  LocalConfigDoubleProvider(
    String key, [
    double defaultValue = Config.defaultValueForDouble,
  ]) : this._internal(
          (ref) => localConfigDouble(
            ref as LocalConfigDoubleRef,
            key,
            defaultValue,
          ),
          from: localConfigDoubleProvider,
          name: r'localConfigDoubleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$localConfigDoubleHash,
          dependencies: LocalConfigDoubleFamily._dependencies,
          allTransitiveDependencies:
              LocalConfigDoubleFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  LocalConfigDoubleProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final double defaultValue;

  @override
  Override overrideWith(
    double Function(LocalConfigDoubleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LocalConfigDoubleProvider._internal(
        (ref) => create(ref as LocalConfigDoubleRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<double> createElement() {
    return _LocalConfigDoubleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalConfigDoubleProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LocalConfigDoubleRef on AutoDisposeProviderRef<double> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  double get defaultValue;
}

class _LocalConfigDoubleProviderElement
    extends AutoDisposeProviderElement<double> with LocalConfigDoubleRef {
  _LocalConfigDoubleProviderElement(super.provider);

  @override
  String get key => (origin as LocalConfigDoubleProvider).key;
  @override
  double get defaultValue => (origin as LocalConfigDoubleProvider).defaultValue;
}

String _$localConfigBoolHash() => r'45ff874a484e20c2ae29d4113d77914e6cf46696';

/// Gets a [LocalConfig] value as a [bool].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigBool].
@ProviderFor(localConfigBool)
const localConfigBoolProvider = LocalConfigBoolFamily();

/// Gets a [LocalConfig] value as a [bool].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigBool].
class LocalConfigBoolFamily extends Family<bool> {
  /// Gets a [LocalConfig] value as a [bool].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigBool].
  const LocalConfigBoolFamily();

  /// Gets a [LocalConfig] value as a [bool].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigBool].
  LocalConfigBoolProvider call(
    String key, [
    bool defaultValue = Config.defaultValueForBool,
  ]) {
    return LocalConfigBoolProvider(
      key,
      defaultValue,
    );
  }

  @override
  LocalConfigBoolProvider getProviderOverride(
    covariant LocalConfigBoolProvider provider,
  ) {
    return call(
      provider.key,
      provider.defaultValue,
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
  String? get name => r'localConfigBoolProvider';
}

/// Gets a [LocalConfig] value as a [bool].
/// Whenever this [key] changes, this provider will be updated.
///
/// Copied from [localConfigBool].
class LocalConfigBoolProvider extends AutoDisposeProvider<bool> {
  /// Gets a [LocalConfig] value as a [bool].
  /// Whenever this [key] changes, this provider will be updated.
  ///
  /// Copied from [localConfigBool].
  LocalConfigBoolProvider(
    String key, [
    bool defaultValue = Config.defaultValueForBool,
  ]) : this._internal(
          (ref) => localConfigBool(
            ref as LocalConfigBoolRef,
            key,
            defaultValue,
          ),
          from: localConfigBoolProvider,
          name: r'localConfigBoolProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$localConfigBoolHash,
          dependencies: LocalConfigBoolFamily._dependencies,
          allTransitiveDependencies:
              LocalConfigBoolFamily._allTransitiveDependencies,
          key: key,
          defaultValue: defaultValue,
        );

  LocalConfigBoolProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
    required this.defaultValue,
  }) : super.internal();

  final String key;
  final bool defaultValue;

  @override
  Override overrideWith(
    bool Function(LocalConfigBoolRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LocalConfigBoolProvider._internal(
        (ref) => create(ref as LocalConfigBoolRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
        defaultValue: defaultValue,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _LocalConfigBoolProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LocalConfigBoolProvider &&
        other.key == key &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);
    hash = _SystemHash.combine(hash, defaultValue.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LocalConfigBoolRef on AutoDisposeProviderRef<bool> {
  /// The parameter `key` of this provider.
  String get key;

  /// The parameter `defaultValue` of this provider.
  bool get defaultValue;
}

class _LocalConfigBoolProviderElement extends AutoDisposeProviderElement<bool>
    with LocalConfigBoolRef {
  _LocalConfigBoolProviderElement(super.provider);

  @override
  String get key => (origin as LocalConfigBoolProvider).key;
  @override
  bool get defaultValue => (origin as LocalConfigBoolProvider).defaultValue;
}

String _$remoteMessagingHash() => r'3202165a9ba8b104810ce6db9ab4a689b08397f3';

/// Access to [RemoteMessaging].
/// Whenever [RemoteMessaging] changes, this provider will be updated.
///
/// Copied from [remoteMessaging].
@ProviderFor(remoteMessaging)
final remoteMessagingProvider =
    AutoDisposeProvider<Raw<RemoteMessaging>>.internal(
  remoteMessaging,
  name: r'remoteMessagingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteMessagingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RemoteMessagingRef = AutoDisposeProviderRef<Raw<RemoteMessaging>>;
String _$remoteMessagingMessagesHash() =>
    r'cceead0236a21e44607e4fdd1fb2e064ec52f6ae';

/// Access to [RemoteMessaging.messages].
/// Whenever a new [RemoteMessage] is receieved via [RemoteMessaging.messages], this provider will be updated.
/// The first execution of this will return the initial message from [RemoteMessaging.getInitialMessage].
///
/// Copied from [remoteMessagingMessages].
@ProviderFor(remoteMessagingMessages)
final remoteMessagingMessagesProvider =
    AutoDisposeStreamProvider<RemoteMessage>.internal(
  remoteMessagingMessages,
  name: r'remoteMessagingMessagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteMessagingMessagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RemoteMessagingMessagesRef
    = AutoDisposeStreamProviderRef<RemoteMessage>;
String _$remoteMessagingTokensHash() =>
    r'b336b909e5704473fc7b36dfa176063c7a9c66c2';

/// Access to [RemoteMessaging.tokens].
/// Whenever a new token is receieved via [RemoteMessaging.tokens], this provider will be updated.
/// The first execution of this will return the current token from [RemoteMessaging.getToken].
///
/// Copied from [remoteMessagingTokens].
@ProviderFor(remoteMessagingTokens)
final remoteMessagingTokensProvider =
    AutoDisposeStreamProvider<String?>.internal(
  remoteMessagingTokens,
  name: r'remoteMessagingTokensProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$remoteMessagingTokensHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RemoteMessagingTokensRef = AutoDisposeStreamProviderRef<String?>;
String _$analyticsHash() => r'1fd69a6ec7906d89d0ebaf111bed072b736dc3f3';

/// Access to [Analytics].
///
/// Copied from [analytics].
@ProviderFor(analytics)
final analyticsProvider = AutoDisposeProvider<Analytics>.internal(
  analytics,
  name: r'analyticsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$analyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AnalyticsRef = AutoDisposeProviderRef<Analytics>;
String _$globalAnalyticsContextHash() =>
    r'0f4421d75f4445217509cff50843e89797133fce';

/// Access to the global [AnalyticsContext] from [Analytics.globalContext].
///
/// Copied from [globalAnalyticsContext].
@ProviderFor(globalAnalyticsContext)
final globalAnalyticsContextProvider =
    AutoDisposeProvider<AnalyticsContext>.internal(
  globalAnalyticsContext,
  name: r'globalAnalyticsContextProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$globalAnalyticsContextHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GlobalAnalyticsContextRef = AutoDisposeProviderRef<AnalyticsContext>;
String _$networkInformationHash() =>
    r'13d7cae849d6733c528c329d79f79e1a43d5f53c';

/// Access to a stream of [NetworkInformation].
/// Whenever [NetworkInformation] changes, this provider will be updated.
///
/// Copied from [networkInformation].
@ProviderFor(networkInformation)
final networkInformationProvider =
    AutoDisposeProvider<NetworkInformation>.internal(
  networkInformation,
  name: r'networkInformationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkInformationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetworkInformationRef = AutoDisposeProviderRef<NetworkInformation>;
String _$packageInfoHash() => r'bb4b207e4e72b204cb2ce57645ec41ad09115b53';

/// Access to [PackageInfo].
///
/// Copied from [packageInfo].
@ProviderFor(packageInfo)
final packageInfoProvider = AutoDisposeProvider<PackageInfoPlugin>.internal(
  packageInfo,
  name: r'packageInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$packageInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PackageInfoRef = AutoDisposeProviderRef<PackageInfoPlugin>;
String _$deviceInfoHash() => r'737aa403f7f02cb999e488554c1110ae3b2f03d2';

/// Access to [DeviceInfo].
///
/// Copied from [deviceInfo].
@ProviderFor(deviceInfo)
final deviceInfoProvider = AutoDisposeProvider<DeviceInfoPlugin>.internal(
  deviceInfo,
  name: r'deviceInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$deviceInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DeviceInfoRef = AutoDisposeProviderRef<DeviceInfoPlugin>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
