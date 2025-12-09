// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:patapata_core/src/method_channel_test_mixin.dart';

import 'local_config.dart';
import 'remote_config.dart';
import 'remote_messaging.dart';
import 'app.dart';

/// You can inherit from this class to create your own extensions for Patapata.
abstract class Plugin with MethodChannelTestMixin {
  late final App _app;

  bool _initialized = false;
  bool _disposed = false;

  Plugin();

  /// Create a [Plugin] that can be used in [App].
  /// If you want to implement a [Plugin] that you can pass directly
  /// to [App.plugins], you can use this constructor without having to
  /// create your own class.
  factory Plugin.inline({
    String name = 'inline',
    List<Type> dependencies = const [],
    bool requireRemoteConfig = false,
    FutureOr<bool> Function(App app)? init,
    FutureOr<void> Function()? dispose,
    Widget Function(Widget child)? createAppWidgetWrapper,
    RemoteConfig? Function()? createRemoteConfig,
    LocalConfig? Function()? createLocalConfig,
    RemoteMessaging? Function()? createRemoteMessaging,
    List<NavigatorObserver> Function()? navigatorObservers,
  }) => InlinePlugin(
    name: name,
    dependencies: dependencies,
    requireRemoteConfig: requireRemoteConfig,
    init: init,
    dispose: dispose,
    createAppWidgetWrapper: createAppWidgetWrapper,
    createRemoteConfig: createRemoteConfig,
    createLocalConfig: createLocalConfig,
    createRemoteMessaging: createRemoteMessaging,
    navigatorObservers: navigatorObservers,
  );

  /// The unique name of this [Plugin].
  /// This property is referenced in various situations, such as when enabling or disabling the plugin,
  /// and when enabling or disabling the mock, and when communicating with Native code.
  String get name => runtimeType.toString();

  /// The list of other plugins that this plugin depends on.
  /// This property should be used to add the types of other plugins that are required for this [Plugin] to work.
  /// For example, when using the FirebaseAnalyticsPlugin, you need to include FirebaseCorePlugin.
  @protected
  List<Type> get dependencies => const [];

  /// This property determines whether initialization should occur after the RemoteConfig system has started when set to true,
  /// or before it starts when set to false.
  bool get requireRemoteConfig => false;

  /// Get the RemoteConfig key name to enable or disable this plugin.
  String get remoteConfigEnabledKey =>
      'patapata_plugin_${name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}_enabled';

  /// The [App] referenced by the plugin.
  @protected
  App get app => _app;

  /// Whether this [Plugin] is initialized or not.
  @nonVirtual
  bool get initialized => _initialized;

  /// Get whether this [Plugin] has been disposed.
  @nonVirtual
  bool get disposed => _disposed;

  /// Executed when a [PatapataApp] [run]s or when a this [Plugin] is
  /// added to the [PatapataApp] after [run].
  /// This may return a [Future] for asynchronous initialization.
  /// Always call [super.init] before any other overridden code.
  ///
  /// If any of the callbacks fail for any reason,
  /// the [App] will not continue to execute callbacks
  /// and will execute the [onInitFailure] callback if given.
  /// Otherwise, it will silently die. (Not do anything)
  @mustCallSuper
  FutureOr<bool> init(App app) async {
    if (_initialized) {
      throw StateError('$name is already initialized.');
    }

    if (!dependencies.every((t) => app.hasPlugin(t))) {
      throw StateError('$name does not have all dependencies satisfied.');
    }

    if (kIsTest) {
      setMockMethodCallHandler();
      setMockStreamHandler();
    }

    _app = app;
    _initialized = true;

    return true;
  }

  /// Disposes this [Plugin].
  /// Always call [super.dispose] before any other overridden code.
  /// In general you should not call this method as [App] will do that for you.
  @mustCallSuper
  FutureOr<void> dispose() async {
    if (_disposed) {
      throw StateError('$name is already disposed of.');
    }

    _disposed = true;
  }

  /// Wraps the [Widget] that will ultimately be passed to Flutter's [runApp] function.
  /// This is used when the plugin needs to wrap [App.createAppWidget] to add widgets to the [App]'s widget tree.
  Widget createAppWidgetWrapper(Widget child) => child;

  /// Specify the [RemoteConfig] to register with Patapata for this plugin.
  RemoteConfig? createRemoteConfig() => null;

  /// Specify the [LocalConfig] to register with Patapata for this plugin.
  LocalConfig? createLocalConfig() => null;

  /// Specify the [RemoteMessaging] to register with Patapata for this plugin.
  RemoteMessaging? createRemoteMessaging() => null;

  /// Get the list of [NavigatorObserver]s to pass to Patapata for this plugin.
  /// This Observers list will ultimately be added to the [App.navigatorObservers] list.
  List<NavigatorObserver> get navigatorObservers => const [];

  /// This is a function to mock patapataEnable running in native code.
  /// It will only be called when [kIsTest] is true.
  @visibleForTesting
  void mockPatapataEnable() {}

  /// This is a function to mock patapataDisable running in native code.
  /// It will only be called when [kIsTest] is true.
  @visibleForTesting
  void mockPatapataDisable() {}
}

/// A [Plugin] that can define all methods in the constructor.
class InlinePlugin extends Plugin {
  @override
  final String name;
  @override
  final List<Type> dependencies;
  @override
  final bool requireRemoteConfig;
  final FutureOr<bool> Function(App app)? _init;
  final FutureOr<void> Function()? _dispose;
  final Widget Function(Widget child)? _createAppWidgetWrapper;
  final RemoteConfig? Function()? _createRemoteConfig;
  final LocalConfig? Function()? _createLocalConfig;
  final RemoteMessaging? Function()? _createRemoteMessaging;
  final List<NavigatorObserver> Function()? _navigatorObservers;

  /// Creates a [Plugin] that can define all methods in the constructor.
  /// See [Plugin]'s various methods for details on each method.
  InlinePlugin({
    required this.name,
    this.dependencies = const <Type>[],
    this.requireRemoteConfig = false,
    FutureOr<bool> Function(App app)? init,
    FutureOr<void> Function()? dispose,
    Widget Function(Widget child)? createAppWidgetWrapper,
    RemoteConfig? Function()? createRemoteConfig,
    LocalConfig? Function()? createLocalConfig,
    RemoteMessaging? Function()? createRemoteMessaging,
    List<NavigatorObserver> Function()? navigatorObservers,
  }) : _init = init,
       _dispose = dispose,
       _createAppWidgetWrapper = createAppWidgetWrapper,
       _createRemoteConfig = createRemoteConfig,
       _createLocalConfig = createLocalConfig,
       _createRemoteMessaging = createRemoteMessaging,
       _navigatorObservers = navigatorObservers;

  @override
  FutureOr<bool> init(App app) async {
    if (_init != null) {
      if (!await _init(app)) {
        return false;
      }
    }

    return super.init(app);
  }

  @override
  FutureOr<void> dispose() async {
    if (_dispose != null) {
      await _dispose();
    }

    return super.dispose();
  }

  @override
  Widget createAppWidgetWrapper(Widget child) {
    if (_createAppWidgetWrapper != null) {
      return _createAppWidgetWrapper(child);
    }

    return super.createAppWidgetWrapper(child);
  }

  @override
  RemoteConfig? createRemoteConfig() {
    if (_createRemoteConfig != null) {
      return _createRemoteConfig();
    }

    return super.createRemoteConfig();
  }

  @override
  LocalConfig? createLocalConfig() {
    if (_createLocalConfig != null) {
      return _createLocalConfig();
    }

    return super.createLocalConfig();
  }

  @override
  RemoteMessaging? createRemoteMessaging() {
    if (_createRemoteMessaging != null) {
      return _createRemoteMessaging();
    }

    return super.createRemoteMessaging();
  }

  @override
  List<NavigatorObserver> get navigatorObservers {
    if (_navigatorObservers != null) {
      return _navigatorObservers();
    }

    return super.navigatorObservers;
  }
}
