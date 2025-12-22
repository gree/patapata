// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:patapata_core/patapata_core.dart';

/// A base class that manages the application's Config and
/// provides the functionality to notify changes.
///
/// When the value of Config is changed,
/// please call [onChange] on the implementation side.
///
/// See also:
///
/// [RemoteConfig], [LocalConfig]
abstract class Config extends ChangeNotifier with MethodChannelTestMixin {
  /// Default value for configuration items of type String.
  /// If a configuration item of type String is not set, this value will be used.
  static const defaultValueForString = '';

  /// Default value for configuration items of type Boolean.
  /// If a configuration item of type Boolean is not set, this value will be used.
  static const defaultValueForBool = false;

  /// Default value for configuration items of type Integer.
  /// If a configuration item of type Integer is not set, this value will be used.
  static const defaultValueForInt = 0;

  /// Default value for configuration items of type Double.
  /// If a configuration item of type Double is not set, this value will be used.
  static const defaultValueForDouble = 0.0;

  bool _initialized = false;

  /// Indicates whether the configuration has been initialized.
  bool get initialized => _initialized;

  bool _disposed = false;

  /// Indicates whether the configuration has been disposed.
  bool get disposed => _disposed;

  /// Initializes the configuration.
  ///
  /// If the application is in test mode, it sets the mock method call handler.
  /// After initialization, the configuration is marked as initialized and not disposed.
  @mustCallSuper
  Future<void> init() async {
    if (kIsTest) {
      setMockMethodCallHandler();
    }

    _initialized = true;
    _disposed = false;
  }

  /// Disposes the configuration.
  ///
  /// After disposal, the configuration is marked as not initialized and disposed.
  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    _initialized = false;
    _disposed = true;
  }

  /// The value of Config has been changed.
  @protected
  void onChange() {
    notifyListeners();
  }
}

/// Provides an interface to read values from [Config].
mixin ReadableConfig on Config {
  /// Checks if the given [key] exists in the configuration.
  bool hasKey(String key);

  /// Returns the value corresponding to the given [key] as a String.
  String getString(
    String key, {
    String defaultValue = Config.defaultValueForString,
  });

  /// Returns the value corresponding to the given [key] as a Boolean.
  bool getBool(String key, {bool defaultValue = Config.defaultValueForBool});

  /// Returns the value corresponding to the given [key] as an Integer.
  int getInt(String key, {int defaultValue = Config.defaultValueForInt});

  /// Returns the value corresponding to the given [key] as a Double.
  double getDouble(
    String key, {
    double defaultValue = Config.defaultValueForDouble,
  });

  /// Sets the default values for the configuration.
  ///
  /// The [defaults] parameter is a map containing the default key-value pairs.
  /// These values are used when no other values are specified for the corresponding keys.
  Future<void> setDefaults(Map<String, Object> defaults);
}

/// Provides an interface to write values to [Config].
mixin WritableConfig on Config {
  /// Sets the value of the given [key] to the specified String [value].
  Future<void> setString(String key, String value);

  /// Sets the value of the given [key] to the specified Boolean [value].
  Future<void> setBool(String key, bool value);

  /// Sets the value of the given [key] to the specified Integer [value].
  Future<void> setInt(String key, int value);

  /// Sets the value of the given [key] to the specified Double [value].
  Future<void> setDouble(String key, double value);

  /// Sets the values of multiple keys at once.
  ///
  /// The [objects] parameter is a map where each key-value pair represents a configuration item.
  Future<void> setMany(Map<String, Object> objects);

  /// Resets all configuration items to their default values.
  Future<void> resetAll();

  /// Resets the configuration item corresponding to the given [key] to its default value.
  Future<void> reset(String key);

  /// Resets the configuration items corresponding to the given list of [keys] to their default values.
  Future<void> resetMany(List<String> keys);
}
