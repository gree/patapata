// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'app.dart';
import 'provider_model.dart';

final _logger = Logger('patapata.User');

class _CompareMap extends MapBase<String, Object?> {
  final _store = HashMap<String, Object?>();

  _CompareMap([Map<String, Object?> store = const {}]) {
    _store.addAll(store);
  }

  @override
  Object? operator [](Object? key) => _store[key];

  @override
  void operator []=(String key, Object? value) {
    _store[key] = value;
  }

  // coverage:ignore-start
  @override
  void clear() {
    _store.clear();
  }
  // coverage:ignore-end

  @override
  Iterable<String> get keys => _store.keys;

  // coverage:ignore-start
  @override
  Object? remove(Object? key) {
    _store.remove(key);
    return null;
  }
  // coverage:ignore-end

  @override
  operator ==(Object other) => other is Map<String, Object?>
      ? mapEquals(_store, other is _CompareMap ? other._store : other)
      : false;

  // coverage:ignore-start
  @override
  int get hashCode => const MapEquality<String, Object?>().hash(_store);
  // coverage:ignore-end
}

/// User data while attempting to change the [User].
class UserChangeData {
  /// The user id. Corresponds to [User.id].
  ///
  /// By using [getIdFor], you can obtain values overridden for each [Type].
  String? id;

  /// The user properties. Corresponds to [User.properties].
  ///
  /// By using [getPropertiesFor], you can obtain values overridden for each [Type].
  final Map<String, Object?> properties;

  /// The user arbitrary data. Corresponds to [User.getData].
  final Map<String, Object?> data;

  /// The user id that has been overridden for each [Type].
  final Map<Type, String?> idOverrides;

  /// The user properties that have been overridden for each [Type].
  final Map<Type, Map<String, Object?>> propertiesOverrides;

  UserChangeData({
    required this.id,
    required this.properties,
    required this.data,
    required this.idOverrides,
    required this.propertiesOverrides,
  });

  /// Retrieves the [id] that has been overridden for each [Type].
  String? getIdFor<T>() => idOverrides.containsKey(T) ? idOverrides[T] : id;

  /// Retrieves the [properties] that have been overridden for each [Type].
  Map<String, Object?> getPropertiesFor<T>() =>
      propertiesOverrides.containsKey(T)
          ? (Map.from(properties)..addAll(propertiesOverrides[T]!))
          : Map.from(properties);

  /// Sets all values of properties to null.
  void removeAllProperties() {
    final tOldProperties = {
      for (var i in properties.keys) i: null,
    };

    properties
      ..clear()
      ..addAll(_CompareMap()..addAll(tOldProperties));
  }
}

/// User information of the application.
///
/// This class is automatically created during application initialization
/// and can be accessed from [App.user] or [context.read] or [context.watch].
class User extends ProviderModel<User> {
  /// The [App] that was passed in the constructor.
  final App app;

  User({
    required this.app,
  });

  final _key = ProviderLockKey('patapata.UserKey');

  /// The [ProviderLockKey] used for updating user data.
  @protected
  ProviderLockKey get key => _key;

  late final ProviderModelVariable<String?> _id = createVariable<String?>(null);
  final Map<Type, String?> _idOverrides = {};

  /// The user id.
  ///
  /// By using [getIdFor], you can obtain values overridden for each [Type].
  ///
  /// The value obtained may not be the latest.
  String? get id => _id.unsafeValue;

  /// Retrieves the [id] that has been overridden for each [Type].
  ///
  /// The value obtained may not be the latest.
  String? getIdFor<T>() => _idOverrides.containsKey(T) ? _idOverrides[T] : id;

  late final ProviderModelVariable<_CompareMap> _properties =
      createVariable<_CompareMap>(_CompareMap());
  final Map<Type, _CompareMap> _propertiesOverrides = {};

  /// The user properties.
  ///
  /// This value can be shared outside of the application (such as in external packages).
  /// (e.g., Analytics or Sentry)
  ///
  /// By using [getPropertiesFor], you can obtain values overridden for each [Type].
  ///
  /// The value obtained may not be the latest.
  Map<String, Object?> get properties => Map.from(_properties.unsafeValue);

  /// Retrieves the [properties] that have been overridden for each [Type].
  ///
  /// The value obtained may not be the latest.
  Map<String, Object?> getPropertiesFor<T>() =>
      _propertiesOverrides.containsKey(T)
          ? (properties..addAll(_propertiesOverrides[T]!))
          : properties;

  late final ProviderModelVariable<_CompareMap> _data =
      createVariable<_CompareMap>(_CompareMap());

  final List<FutureOr<void> Function(User user, UserChangeData changes)>
      _synchronousChangeListeners = [];

  /// Adds a listener to monitor updates to user data.
  ///
  /// When user-related data is updating, the [callback] is invoked,
  /// and the changed value is set to [changes].
  /// The content of [changes] can be modified within the [callback].
  ///
  /// Once all the listener's [callback]s have successfully completed,
  /// the final values in [changes] are committed.
  /// If any listener returns an error, the changes are discarded.
  void addSynchronousChangeListener(
          FutureOr<void> Function(User user, UserChangeData changes)
              callback) =>
      _synchronousChangeListeners.add(callback);

  /// Removes the listener that was added using [addSynchronousChangeListener].
  void removeSynchronousChangeListener(
          FutureOr<void> Function(User user, UserChangeData changes)
              callback) =>
      _synchronousChangeListeners.remove(callback);

  /// All values of [User].
  ///
  /// `[id, properties, data]`
  List<ProviderModelVariable> get variables => [
        _id,
        _properties,
        _data,
      ];

  /// Sets arbitrary data.
  ///
  /// This value can be used for data exchange within the application and
  /// is not intended to be sent to external packages.
  Future<void> setData<T extends Object?>(
    String key,
    T value,
  ) async {
    await lock((batch) {
      _logger.fine('setData:$key=$value');
      final tNewData = _CompareMap(batch.get(_data));
      tNewData[key] = value;
      batch.set(_data, tNewData);
      batch.commit();
    }, lockKey: _key);
  }

  /// Retrieves arbitrary data.
  ///
  /// This value can be used for data exchange within the application and
  /// is not intended to be sent to external packages.
  Future<T?> getData<T extends Object?>(String key) async {
    final tData = await _data.getValue();
    return tData[key] as T?;
  }

  /// Synchronous process of [getData]
  ///
  /// The value obtained may not be the latest.
  T? getDataSync<T extends Object?>(String key) {
    return _data.unsafeValue[key] as T?;
  }

  /// Removes the data of [key] that was set using [setData] or similar functions.
  Future<void> removeData(String key) async {
    await lock((batch) {
      _logger.fine('removeData:$key');
      final tData = batch.get(_data);
      tData.remove(key);
      batch.set(_data, _CompareMap(tData));
      batch.commit();
    }, lockKey: _key);
  }

  /// Removes all the data that was set using [setData] and similar functions.
  Future<void> removeAllData() async {
    await lock((batch) {
      _logger.fine('removeAllData');
      batch.set(_data, _CompareMap());
      batch.commit();
    }, lockKey: _key);
  }

  /// Retrieves the value specified by [key] from [properties].
  ///
  /// [defaultValue] will be returned if [key] does not exist.
  ///
  /// The value obtained may not be the latest.
  T? getProperty<T>(String key, [T? defaultValue]) =>
      _properties.unsafeValue.containsKey(key)
          ? _properties.unsafeValue[key] as T?
          : defaultValue;

  Future<void> _runSynchronousChangeListeners(ProviderModelBatch lock) async {
    final tChangeData = UserChangeData(
      id: lock.get(_id),
      properties: Map.from(lock.get(_properties)),
      data: Map.from(lock.get(_data)),
      idOverrides: Map.from(_idOverrides),
      propertiesOverrides: Map.from(_propertiesOverrides),
    );

    final tSynchronousChangeListeners =
        _synchronousChangeListeners.toList(growable: false);
    final tPossibleExternalChanges = tSynchronousChangeListeners.isNotEmpty;

    if (tPossibleExternalChanges) {
      await lock.blockOverride(() async {
        for (var i in tSynchronousChangeListeners) {
          await i(this, tChangeData);
        }
      });

      if (_id.unsafeValue != tChangeData.id) {
        _logger
            .info('Synchronous change listener changed id: ${tChangeData.id}');
        lock.set(_id, tChangeData.id);
      }

      if (_properties.unsafeValue != tChangeData.properties) {
        _logger.info(
            'Synchronous change listener changed properties: ${tChangeData.properties}');
        lock.set<_CompareMap>(_properties, _CompareMap(tChangeData.properties));
      }

      if (_data.unsafeValue != tChangeData.data) {
        _logger.info(
            'Synchronous change listener changed data: ${tChangeData.data}');
        lock.set<_CompareMap>(_data, _CompareMap(tChangeData.data));
      }

      _idOverrides
        ..clear()
        ..addAll(tChangeData.idOverrides);
      _propertiesOverrides
        ..clear()
        ..addAll(tChangeData.propertiesOverrides
            .map((key, value) => MapEntry(key, _CompareMap()..addAll(value))));
    }
  }

  /// Sets a property.
  ///
  /// This value can be shared outside of the application (such as in external packages).
  /// (e.g., Analytics or Sentry)
  ///
  /// With [overrideProperties], you can override property values in any [Type].
  /// Overridden values can be retrieved using [getPropertiesFor].
  Future<void> setProperties(
    Map<String, Object?> properties, {
    Map<Type, Map<String, Object?>>? overrideProperties,
  }) async {
    await lock((batch) async {
      _logger.fine('setProperties:$properties');

      final tProperties = batch.get(_properties);
      final tNewProperties = _CompareMap(tProperties);
      tNewProperties.addAll(properties);
      batch.set(_properties, tNewProperties);

      if (overrideProperties != null) {
        for (var i in overrideProperties.entries) {
          _propertiesOverrides[i.key] ??= _CompareMap();
          _propertiesOverrides[i.key]!.addAll(i.value);
        }
      }

      await _runSynchronousChangeListeners(batch);

      await app.remoteConfig.fetch();

      batch.commit();
    }, lockKey: _key);
  }

  /// Sets the user's id and various values.
  ///
  /// Executing this function will discard the current values of [User.properties].
  ///
  /// With [overrideId], you can override the id value in any [Type].
  /// Overridden values can be retrieved using [getIdFor].
  ///
  /// With [overrideProperties], you can override property values in any [Type].
  /// Overridden values can be retrieved using [getPropertiesFor].
  Future<void> changeId(
    String? id, {
    Map<String, Object?>? properties,
    Map<String, Object?>? data,
    Map<Type, String?>? overrideId,
    Map<Type, Map<String, Object?>>? overrideProperties,
  }) async {
    await lock((batch) async {
      await changeIdWithBatch(
        batch: batch,
        id: id,
        properties: properties,
        data: data,
        overrideId: overrideId,
        overrideProperties: overrideProperties,
      );

      batch.commit();
    }, lockKey: _key);
  }

  /// Sets the user's id and various values using the provided [ProviderModelBatch].
  @protected
  Future<void> changeIdWithBatch({
    required ProviderModelBatch batch,
    required String? id,
    Map<String, Object?>? properties,
    Map<String, Object?>? data,
    Map<Type, String?>? overrideId,
    Map<Type, Map<String, Object?>>? overrideProperties,
  }) async {
    _logger.fine('changeId:$id, $properties, $data');

    batch.set(_id, id);

    _idOverrides.clear();

    if (overrideId != null) {
      for (var i in overrideId.entries) {
        _idOverrides[i.key] = i.value;
      }
    }

    // notify listeners to remove old properties.
    final tOldProperties = {
      for (var i in batch.get(_properties).keys) i: null,
    };

    final tProperties = _CompareMap(tOldProperties);

    if (properties != null) {
      tProperties.addAll(properties);
    }

    batch.set(_properties, tProperties);

    if (data != null) {
      batch.set(_data, _CompareMap(data));
    }

    _propertiesOverrides.clear();

    if (overrideProperties != null) {
      for (var i in overrideProperties.entries) {
        _propertiesOverrides[i.key] ??= _CompareMap();
        _propertiesOverrides[i.key]!.addAll(i.value);
      }
    }

    await _runSynchronousChangeListeners(batch);

    await app.remoteConfig.fetch(force: true);
  }

  /// Sets the properties and arbitrary data.
  ///
  /// With [overrideProperties], you can override property values in any [Type].
  /// Overridden values can be retrieved using [getPropertiesFor].
  Future<void> set({
    Map<String, Object?>? properties,
    Map<String, Object?>? data,
    Map<Type, Map<String, Object?>>? overrideProperties,
  }) async {
    await lock((batch) async {
      await setWithBatch(
        batch: batch,
        properties: properties,
        data: data,
        overrideProperties: overrideProperties,
      );

      batch.commit();
    }, lockKey: _key);
  }

  /// Sets the properties and arbitrary data using the provided [ProviderModelBatch].
  @protected
  Future<void> setWithBatch({
    required ProviderModelBatch batch,
    Map<String, Object?>? properties,
    Map<String, Object?>? data,
    Map<Type, Map<String, Object?>>? overrideProperties,
  }) async {
    _logger.fine('set:$properties, $data');

    if (properties != null) {
      final tProperties = batch.get(_properties);
      final tNewProperties = _CompareMap(tProperties);
      tNewProperties.addAll(properties);
      batch.set(_properties, tNewProperties);
    }

    if (data != null) {
      final tData = batch.get(_data);
      final tNewData = _CompareMap(tData);
      tNewData.addAll(data);
      batch.set(_data, tNewData);
    }

    if (overrideProperties != null) {
      for (var i in overrideProperties.entries) {
        _propertiesOverrides[i.key] ??= _CompareMap();
        _propertiesOverrides[i.key]!.addAll(i.value);
      }
    }

    await _runSynchronousChangeListeners(batch);

    try {
      await app.remoteConfig.fetch(
        force: batch.get(_id) != _id.unsafeValue,
      );
    } catch (e, stackTrace) {
      _logger.info('Failed to refresh RemoteConfig.', e, stackTrace);
    }
  }

  @override
  operator ==(Object other) => other is User ? other.id == id : false;

  @override
  int get hashCode => Object.hash(null, id.hashCode);
}
