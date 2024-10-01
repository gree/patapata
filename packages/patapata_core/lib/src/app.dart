// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:patapata_core/patapata_core.dart';
import 'package:provider/provider.dart';

final _logger = Logger('patapata.App');

const _methodChannel = MethodChannel('dev.patapata.patapata_core');

/// A value to check if this is running in a test environment.
/// Defined by setting the dart define IS_TEST to true
///
/// Example: flutter test --dart-define=IS_TEST=true
const bool kIsTest = bool.fromEnvironment('IS_TEST', defaultValue: false);

/// Defines what stage the [App] is currently in.
enum AppStage {
  /// The first stage where the [App] hasn't done any operations
  /// and [App.run] hasn't been executed yet.
  setup,

  /// Entered after [App.run] executes.
  /// Right after changing, the [App.run]'s bootstrapCallback parameter is executed.
  /// At this stage, Flutter's services has been initialized via [WidgetsFlutterBinding.ensureInitialized],
  /// all code is from now on executed in a guarded [Zone] to catch errors,
  /// and the logging system for [App.log] is set up.
  bootstrap,

  /// All [Plugin]s that are able to initialize (all requirements are met)
  /// are initialized in this stage.
  initializingPlugins,

  /// [RemoteConfig] systems from [Plugin.createRemoteConfig] are created
  /// and initialized in this stage.
  setupRemoteConfig,

  /// [Plugin]s that required a [RemoteConfig] to be set up before initialization
  /// are initialized in this stage.
  /// It is in this stage where [Plugin]s that should be disabled via [RemoteConfig]
  /// are removed.
  initializingPluginsWithRemoteConfig,

  /// The main stage of an [App]. After initialization, the [App] will generally be
  /// in this stage forever except during rare cases or tests.
  running,

  /// Entered upon calling [App.dispose].
  /// In general, this does not happen except during rare cases or tests.
  disposed,
}

/// Returns the [App] for the current [Zone].
/// In almost all cases in your application, you can use this to
/// grab your [App] instance without a [BuildContext]
/// [T] is not required and will work undefined (as dynamic).
App<T> getApp<T extends Object>() => ((kDebugMode && !kIsTest)
    ? (Zone.current[#patapataApp] ?? // coverage:ignore-line
        _debugAppZone[#patapataApp]) // coverage:ignore-line
    : Zone.current[#patapataApp]) as App<T>;

// https://github.com/flutter/flutter/issues/93676
late Zone _debugAppZone; // coverage:ignore-line

/// The main class for a Patapata app.
/// Typically passed to [runApp].
/// The main class for a Patapata-based application.
class App<T extends Object> {
  static final StreamController<App> _stageStreamController =
      StreamController<App>.broadcast(sync: true);

  /// A [Stream] that can be listened to for global changes to all [App]s that exist.
  static Stream<App> get appStageChangeStream => _stageStreamController.stream;

  /// These are [Plugin]s required for the core of Patapata to work.
  final _defaultRequiredPlugins = <Plugin>[
    I18nPlugin(),
    NativeLocalConfigPlugin(),
    NetworkPlugin(),
    PackageInfoPlugin(),
    DeviceInfoPlugin(),
    NotificationsPlugin(),
    StandardAppPlugin(),
  ];

  AppStage __stage = AppStage.setup;

  /// The current stage of this [App].
  AppStage get stage => __stage;
  set _stage(AppStage value) {
    assert(__stage != AppStage.disposed);

    __stage = value;
    _logger.fine('Stage ${value.name}');
    _stageStreamController.add(this);
  }

  /// The Environment object that will be accessible to all
  /// Widgets via a [Provider].
  /// This is also used to customize [Plugin]s usually via a Mixin.
  final T environment;

  /// A helper function to attempt to cast [environment] as the given Type [V].
  /// If [environment] is not a [V] this function returns null.
  /// Useful for a [Plugin] to check an Environment supports that [Plugin]s Mixin features.
  V? environmentAs<V>() => environment is V ? environment as V : null;

  /// Use this to access all the logging features of Patapata.
  late final Log log;

  /// A function that can create a custom [User] object or subclass for this [App].
  /// This is usually used to provide custom functions, properties, login methods
  /// and such for your own application.
  ///
  /// For example:
  /// ```dart
  ///
  /// class MyCustomUser extends User {
  ///   MyCustomUser({super.app});
  ///
  ///   void login() async {
  ///     // Contact your server to login.
  ///     changeId(await _apiLogin());
  ///   }
  /// }
  ///
  /// void main() {
  ///   App(
  ///     userFactory: (app) => MyCustomUser(app: app),
  ///   ).run();
  /// }
  /// ```
  final User Function(App<T> app) userFactory;

  static User _sDefaultUserFactory(App app) => User(app: app);

  User? _user;

  /// Gets the current [User] and if not yet created, creates one
  /// via [userFactory]. If there is no [userFactory] set, creates
  /// a default [User].
  User get user => _user ??= userFactory(this);

  final Analytics _analytics = Analytics();

  /// Use this to access the [Analytics] system for this [App].
  Analytics get analytics => _analytics;

  late final Permissions _permissions = Permissions(app: this);

  /// Use this to access the [Permissions] system for this [App].
  Permissions get permissions => _permissions;

  /// The [Widget] ultimately passed in to flutter's [runApp] function.
  /// If you are using the [StandardAppPlugin], you usually return a
  /// [StandardMaterialApp] or [StandardCupertinoApp] from this function.
  final Widget Function(BuildContext context, App<T> app) createAppWidget;

  /// The error widget to show in a non-debug build when
  /// a [FlutterError] occurrs.
  /// Default is to show nothing `const SizedBox.shrink()`.
  final ErrorWidgetBuilder nonDebugErrorWidgetBuilder;
  ErrorWidgetBuilder? _originalErrorWidgetBuilder;

  /// A callback that gets called when this [App] fails to initialize at any stage.
  final FutureOr<void> Function(T, dynamic, StackTrace)? onInitFailure;

  final List<Plugin> _plugins = [];

  /// Access to the [RemoteConfig] system.
  /// This particular [RemoteConfig] acts as a proxy between
  /// all of the [RemoteConfig]s created from all initialized [Plugin]s.
  ///
  /// When getting a value from this, it will attempt to get the first value
  /// that exists from the given key amongst the registered [RemoteConfig]s in [Plugin]
  /// registration order. ie, the order that [Plugin]s were passed in to the plugins
  /// parameter in the constuctor of this [App] appending anything added via [addPlugin] afterwards.
  ///
  /// The [RemoteConfig.fetch] called from this [RemoteConfig] is guaranteed to succeed,
  /// ignoring all exceptions.
  final RemoteConfig remoteConfig = ProxyRemoteConfig();
  ProxyRemoteConfig get _proxyRemoteConfig => remoteConfig as ProxyRemoteConfig;
  final Map<Plugin, RemoteConfig> _pluginToRemoteConfigMap = {};

  /// Access to the [LocalConfig] system.
  /// This particular [LocalConfig] acts as a proxy between
  /// all of the [LocalConfig]s created from all initialized [Plugin]s.
  ///
  /// When getting a value from this, it will attempt to get the first value
  /// that exists from the given key amongst the registered [LocalConfig]s in [Plugin]
  /// registration order. ie, the order that [Plugin]s were passed in to the plugins
  /// parameter in the constuctor of this [App] appending anything added via [addPlugin] afterwards.
  ///
  /// If no [Plugin]s support [LocalConfig], a default in-memory [LocalConfig] is used with no persistence.
  final LocalConfig localConfig = ProxyLocalConfig();
  ProxyLocalConfig get _proxyLocalConfig => localConfig as ProxyLocalConfig;
  final Map<Plugin, LocalConfig> _pluginToLocalConfigMap = {};

  /// Access to the [RemoteMessaging] system.
  /// This particular [RemoteMessaging] acts as a proxy between
  /// all of the [RemoteMessaging]s created from all initialized [Plugin]s.
  ///
  /// For any get-style methods like [RemoteMessaging.getToken] or [RemoteMessaging.getInitialMessage],
  /// only the first registered [RemoteMessaging] in [Plugin] registration order's value is returned.
  /// All other methods execute on all registered [RemoteMessaging].
  /// All streams are joined to be accessed via one stream from this object.
  final RemoteMessaging remoteMessaging = ProxyRemoteMessaging();
  ProxyRemoteMessaging get _proxyRemoteMessaging =>
      remoteMessaging as ProxyRemoteMessaging;
  final Map<Plugin, RemoteMessaging> _pluginToRemoteMessagingMap = {};

  /// Access to the [StartupSequence] system.
  /// If the app is rendering widgets using the [StandardAppPlugin] system,
  /// [StartupSequence.resetMachine] is automatically executed only once when the app is launched.
  final StartupSequence? startupSequence;

  bool _loadedFakeNow = false;

  late final Zone _appZone;

  /// Runs [func] in this [App]s error [Zone].
  /// Usually you do not need to use this. However in cases
  /// where you are executing code that was in or forked from the
  /// root [Zone] you may want to execute your code via this
  /// function to allow for Patapata to catch errors, logs, etc correctly.
  Future<R> runProcess<R>(FutureOr<R> Function() func) {
    final tCompleter = Completer<R>();

    _appZone.run<Future<void>>(() async {
      try {
        final tResult = await func();
        tCompleter.complete(tResult);
      } catch (error, stackTrace) {
        tCompleter.completeError(error, stackTrace);
        rethrow;
      }
    });

    return tCompleter.future;
  }

  final GlobalKey _providerKey;
  final bool _customProviderKey;

  @visibleForTesting
  static bool debugIsWeb = false;

  /// All providers registered inside of
  /// Patapata are accessible from with function, along with all
  /// providers above the providerKey given in this [App]'s constructor if provided.
  R getProvider<R>() => _providerKey.currentContext!.read<R>();

  /// Creates a new Patapata [App].
  /// This is generally created in your main.dart files main function.
  ///
  /// In a normal Flutter application, you will pass your application's main
  /// [Widget] in to [runApp].
  ///
  /// With Patapata, you create this [App], passing [createAppWidget] which should return
  /// a [Widget]. This [Widget] will eventually get passed in to [runApp] after executing [run].
  ///
  /// [environment] is a [T] that you use to customize the Environment of your application.
  /// [Plugin]s use this object with Mixins to customize how a [Plugin] may behave.
  ///
  /// Example using [LogEnvironment] to customize the logging system:
  /// ```dart
  /// class Environment with LogLevelEnvironment {
  ///   @override
  ///   final int logLevel;
  ///
  ///   @override
  ///   final bool printLog;
  ///
  ///   const Environment({
  ///     required this.logLevel,
  ///     required this.printLog,
  ///   });
  /// }
  ///
  /// void main() {
  ///   App({
  ///     environment: const Environment({
  ///       // Take the value from --dart-define
  ///       logLevel: int.fromEnvironment('LOG_LEVEL'),
  ///       printLog: bool.fromEnvironment('PRINT_LOG'),
  ///     }),
  ///   });
  /// }
  /// ```
  ///
  /// [providerKey] can be passed here to declare your own location in the
  /// widget hiearchy to allow for adding your own [MultiProvider] or single [Provider]
  /// for your own applications purposes.
  /// One set, you can use [getProvider] to get access to these providers without access
  /// to a [BuildContext].
  ///
  /// Example using [StandardAppPlugin]
  /// ```dart
  /// final _providerKey = GlobalKey();
  ///
  /// void main() {
  ///   App({
  ///     providerKey: _providerKey,
  ///     createAppWidget: (context, app) => StandardMaterialApp(
  ///       pages: [],
  ///       routableBuilder: (context, child) => MultiProvider(
  ///         providers: [
  ///           Provider<ClassA>(
  ///             create: (context) => ClassA(),
  ///           ),
  ///           Provider<MyCustomUser>.value(
  ///             value: context.read<User>() as MyCustomUser,
  ///           ),
  ///         ],
  ///         child: KeyedSubtree(
  ///           key: _providerKey,
  ///           child: child,
  ///         ),
  ///     ),
  ///   });
  /// }
  ///
  /// // (In a different Widget somewhere in your app)
  /// getApp().getProvider<ClassA>();
  /// ```
  ///
  /// [userFactory] is used to create customized [User] objects.
  ///
  /// [nonDebugErrorWidgetBuilder] is used to customize the [Widget]
  /// shown in place of the standard 'red screen of death' that Flutter
  /// shows. Only active in release builds and defaults to a [SizedBox.shrink].
  ///
  /// [onInitFailure] will be executed when this [App] fails to run for some reason.
  ///
  /// [plugins] is a list of [Plugin] instances that you want to enable in this [App].
  App({
    required this.environment,
    required this.createAppWidget,
    GlobalKey? providerKey,
    this.userFactory = _sDefaultUserFactory,
    this.nonDebugErrorWidgetBuilder = _defaultNonDebugErrorWidgetBuilder,
    this.onInitFailure,
    this.startupSequence,
    Iterable<Plugin>? plugins,
  })  : _customProviderKey = providerKey != null,
        _providerKey =
            providerKey ?? GlobalKey(debugLabel: 'patapata.App.providerKey') {
    _plugins.addAll(_defaultRequiredPlugins);

    if (kIsTest) {
      // ignore: invalid_use_of_visible_for_testing_member
      permissions.setMockMethodCallHandler();
    }

    if (plugins != null) {
      _plugins.addAll(plugins);
    }
  }

  // coverage:ignore-start
  /// The default for non-debug builds is to get rid of the
  /// red screen of death.
  static Widget _defaultNonDebugErrorWidgetBuilder(
      FlutterErrorDetails details) {
    return const SizedBox.shrink();
  }
  // coverage:ignore-end

  Future<bool> _initializePlugin(Plugin plugin) async {
    _logger.fine('initializePlugin start: ${plugin.name}');

    // Initialize. If it returns false, that means the plugin
    // wants to silently not enable itself.
    if (!await plugin.init(this)) {
      _logger.fine('initializePlugin silent fail: ${plugin.name}');

      return false;
    }

    // Register any [LocalConfig].
    final tLocalConfig = plugin.createLocalConfig();

    if (tLocalConfig != null) {
      await _proxyLocalConfig.addLocalConfig(tLocalConfig);
      _pluginToLocalConfigMap[plugin] = tLocalConfig;
    }

    // Register any [RemoteConfig].
    final tRemoteConfig = plugin.createRemoteConfig();

    if (tRemoteConfig != null) {
      await _proxyRemoteConfig.addRemoteConfig(tRemoteConfig);
      _pluginToRemoteConfigMap[plugin] = tRemoteConfig;
    }

    // Register any [RemoteMessaging].
    final tRemoteMessaging = plugin.createRemoteMessaging();

    if (tRemoteMessaging != null) {
      await _proxyRemoteMessaging.addRemoteMessaging(tRemoteMessaging);
      _pluginToRemoteMessagingMap[plugin] = tRemoteMessaging;
    }

    if (!kIsTest) {
      // coverage:ignore-start
      await _methodChannel.invokeMethod('enablePlugin', plugin.name);
      // coverage:ignore-end
    } else {
      // ignore: invalid_use_of_visible_for_testing_member
      plugin.mockPatapataEnable();
    }

    _logger.fine('initializePlugin done: ${plugin.name}');

    return true;
  }

  Future<void> _disposePlugin(Plugin plugin) async {
    _logger.fine('disposePlugin start: ${plugin.name}');

    // Unregister any [RemoteMessaging]
    if (_pluginToRemoteMessagingMap.containsKey(plugin)) {
      _proxyRemoteMessaging
          .removeRemoteMessaging(_pluginToRemoteMessagingMap.remove(plugin)!);
    }

    // Unregister any [RemoteConfig]
    if (_pluginToRemoteConfigMap.containsKey(plugin)) {
      _proxyRemoteConfig
          .removeRemoteConfig(_pluginToRemoteConfigMap.remove(plugin)!);
    }

    // Unregister any [LocalConfig]
    if (_pluginToLocalConfigMap.containsKey(plugin)) {
      _proxyLocalConfig
          .removeLocalConfig(_pluginToLocalConfigMap.remove(plugin)!);
    }

    if (!kIsTest) {
      // coverage:ignore-start
      await _methodChannel.invokeMethod('disablePlugin', plugin.name);
      // coverage:ignore-end
    } else {
      // ignore: invalid_use_of_visible_for_testing_member
      plugin.mockPatapataDisable();
    }

    // Dispose of it
    await plugin.dispose();

    _logger.fine('disposePlugin done: ${plugin.name}');
  }

  /// Adds a plugin to this [App].
  ///
  /// The [plugin] will be added to the list of active plugins.
  Future<void> addPlugin(Plugin plugin) async {
    if (stage.index > AppStage.initializingPluginsWithRemoteConfig.index) {
      try {
        if (await _initializePlugin(plugin)) {
          _plugins.add(plugin);
        }
      } catch (error) {
        // Failed to initialize this plugin at runtime.
        // We don't fail the entire app in this case.
        // However, we do allow the error system to find out
        // what's going on so we rethrow.
        rethrow;
      }
    } else {
      _plugins.add(plugin);
    }
  }

  /// Removes a plugin from this [App].
  Future<void> removePlugin(Plugin plugin) async {
    if (!_plugins.remove(plugin)) {
      return;
    }

    if (!plugin.initialized) {
      return;
    }

    if (!plugin.disposed) {
      try {
        await _disposePlugin(plugin);
      } catch (error) {
        // Allow the error system to find out
        // what's going on so we rethrow.
        rethrow;
      }
    }
  }

  /// Returns true if the given [Plugin] type is currently registered.
  bool hasPlugin(Type type) => _plugins.any((p) => p.runtimeType == type);

  /// Attempts to get the given [P] [Plugin] or null if it doesn't exist.
  P? getPlugin<P>() => _plugins.firstWhereOrNull((p) => p is P) as P?;

  /// Gets a list of [Plugin]s of type [P].
  /// This is usually used to look for [Plugin]s that have a specific Mixin
  /// to apply features to them.
  List<P> getPluginsOfType<P>() => _plugins.whereType<P>().toList();

  /// Access to information about the network.
  NetworkPlugin get network {
    final tNetworkPlugin = getPlugin<NetworkPlugin>();
    assert(tNetworkPlugin != null,
        'Default required plugin NetworkPlugin removed.');

    return tNetworkPlugin!;
  }

  /// Access to information about this application's metadata.
  PackageInfoPlugin get package {
    final tPackageInfoPlugin = getPlugin<PackageInfoPlugin>();
    assert(tPackageInfoPlugin != null,
        'Default required plugin PackageInfoPlugin removed.');

    return tPackageInfoPlugin!;
  }

  /// Access to information about the device that this application is running on.
  DeviceInfoPlugin get device {
    final tDeviceInfoPlugin = getPlugin<DeviceInfoPlugin>();
    assert(tDeviceInfoPlugin != null,
        'Default required plugin DeviceInfoPlugin removed.');

    return tDeviceInfoPlugin!;
  }

  void _onRemoteConfigChange() {
    _updateLogLevel();
  }

  void _updateLogLevel() {
    log.setLevelByValue(remoteConfig.getInt(
      'patapata_log_level',
      defaultValue: -kPataInHex,
    ));
  }

  late final StartupNavigatorObserver _startupNavigatorObserver =
      StartupNavigatorObserver(startupSequence: startupSequence!);

  /// A list of all [NavigatorObserver]s to use in a [Navigator]
  /// from all the [Plugin]s registered to this [App].
  /// The [Analytics] and [StartupSequence] system also relies on setting these to any
  /// [Navigator]s in the application.
  List<NavigatorObserver> get navigatorObservers => [
        for (var v in _plugins) ...v.navigatorObservers,
        AnalyticsNavigatorObserver(analytics: analytics),
        if (startupSequence != null) _startupNavigatorObserver,
      ];

  static const _forceRemoveNativeSplashScreenDuration =
      Duration(milliseconds: 5000);
  Timer? _forceRemoveNativeSplashScreenTimer;
  bool _removedNativeSplashScreen = false;

  /// Remove the native splash screen for this application.
  Future<void> removeNativeSplashScreen() async {
    if (_removedNativeSplashScreen) {
      return;
    }
    _removedNativeSplashScreen = true;

    if (_forceRemoveNativeSplashScreenTimer?.isActive == true) {
      // The timer does not work in the test environment.
      // coverage:ignore-start
      _forceRemoveNativeSplashScreenTimer?.cancel();
      _forceRemoveNativeSplashScreenTimer = null;
      // coverage:ignore-end
    }

    // When invokeMethod fails to find the platform plugin, it returns null
    // instead of throwing an exception.
    await const OptionalMethodChannel('plugin/splash_screen')
        .invokeMethod<void>('removeNativeSplashScreen');
  }

  /// Run the app.
  /// Returns true if the app was successfully run.
  ///
  /// This will actually start up Flutter (via [runApp]) and
  /// begin running through each of the [AppStage]s.
  /// Pass [boostrapCallback] to run a callback after Flutter services are initialized
  /// and logging systems are initialized but before anything else during the [AppStage.bootstrap] stage.
  Future<bool> run([FutureOr<void> Function()? bootstrapCallback]) async {
    final tCompleter = Completer<bool>();

    try {
      _stageStreamController.add(this);

      Future<void> fRun() async {
        try {
          if (kDebugMode && !kIsTest) {
            // coverage:ignore-start
            _debugAppZone = Zone.current;
            // coverage:ignore-end
          }
          bool tIsDebug = false;
          assert(tIsDebug = true);

          _appZone = Zone.current;

          // Before we do anything,
          // make sure the WidgetBindings are up and running so we can execute all of Flutter's APIs.
          WidgetsFlutterBinding.ensureInitialized();

          if (kIsTest) {
            removeNativeSplashScreen();
          } else {
            // coverage:ignore-start
            _forceRemoveNativeSplashScreenTimer ??= Timer(
                _forceRemoveNativeSplashScreenDuration,
                removeNativeSplashScreen);
            // coverage:ignore-end
          }

          log = Log(this);

          if (!tIsDebug) {
            // coverage:ignore-start
            _originalErrorWidgetBuilder = ErrorWidget.builder;
            ErrorWidget.builder = nonDebugErrorWidgetBuilder;
            // coverage:ignore-end
          }

          _stage = AppStage.bootstrap;

          if (bootstrapCallback != null) {
            await bootstrapCallback();
          }

          _stage = AppStage.initializingPlugins;

          await _proxyRemoteMessaging.init(this);

          // Initialize plugins that don't require RemoteConfig
          final tPluginsCopy = _plugins.toList(growable: false);

          for (var tPlugin in tPluginsCopy) {
            if (!tPlugin.requireRemoteConfig) {
              if (!await _initializePlugin(tPlugin)) {
                _plugins.remove(tPlugin);
              }
            }
          }

          _stage = AppStage.setupRemoteConfig;

          // Update RemoteConfigs
          await remoteConfig.init();
          // Allow this fetch to fail like for offline startups.
          remoteConfig.addListener(_onRemoteConfigChange);
          await remoteConfig
              .fetch()
              .timeout(const Duration(seconds: 2), onTimeout: () {});

          _stage = AppStage.initializingPluginsWithRemoteConfig;

          // Now we can remotely disable plugins that need to be.
          // Initialize plugins that do require RemoteConfig.
          // And remove plugins that should be disabled.
          final tPlugins = _plugins.toList(growable: false);

          for (var tPlugin in tPlugins) {
            if (!remoteConfig.getBool(tPlugin.remoteConfigEnabledKey,
                defaultValue: true)) {
              // Remotely disabled, remove it without initializing.
              await removePlugin(tPlugin);

              continue;
            }

            if (!tPlugin.initialized) {
              if (!await _initializePlugin(tPlugin)) {
                // Failed or rejected to initialize, remove it.
                await removePlugin(tPlugin);
              }
            }
          }

          _stage = AppStage.running;

          runApp(
            MultiProvider(
              providers: [
                Provider<App>.value(
                  value: this,
                ),
                Provider<App<T>>.value(
                  value: this,
                ),
                Provider<T>.value(
                  value: environment,
                ),
                ChangeNotifierProvider<User>.value(
                  value: user,
                ),
                ChangeNotifierProvider<RemoteConfig>.value(
                  value: remoteConfig,
                ),
                ChangeNotifierProvider<LocalConfig>.value(
                  value: localConfig,
                ),
                ChangeNotifierProvider<RemoteMessaging>.value(
                  value: remoteMessaging,
                ),
                Provider<Analytics>.value(
                  value: analytics,
                ),
                Provider<AnalyticsContext>.value(
                  value: analytics.globalContext,
                ),
              ],
              child: AnalyticsPointerEventListener(
                child: (() {
                  Widget tChild = Builder(
                    builder: (context) {
                      // Load fake time now and only once.
                      if (!_loadedFakeNow) {
                        _loadedFakeNow = true;
                        loadFakeNow();
                      }

                      return createAppWidget(context, this);
                    },
                  );

                  if (!_customProviderKey) {
                    tChild = KeyedSubtree(
                      key: _providerKey,
                      child: tChild,
                    );
                  }

                  for (var tPlugin in _plugins.reversed) {
                    tChild = tPlugin.createAppWidgetWrapper(tChild);
                  }

                  return tChild;
                })(),
              ),
            ),
          );

          tCompleter.complete(true);
        } catch (e, stackTrace) {
          if (onInitFailure != null) {
            await onInitFailure!(environment, e, stackTrace);
          } else {
            // ignore: avoid_print
            print(e);
            // ignore: avoid_print
            print(stackTrace);
          }

          tCompleter.complete(false);
          rethrow;
        }
      }

      if (kIsWeb || debugIsWeb) {
        // Execute in a guarded Zone to catch all errors correctly.
        // This also allows [getApp] to work as we set a zone value for it here.
        runZonedGuarded<Future<void>>(
          () {
            return fRun();
          },
          (error, stackTrace) async {
            removeNativeSplashScreen();

            if (kDebugMode) {
              // In debug mode, always print errors.
              debugPrint(error.toString());

              try {
                debugPrintStack(stackTrace: stackTrace);
              } catch (e) {
                // coverage:ignore-start
                // Sometimes debugPrintStack can't print custom stack traces
                debugPrint(stackTrace.toString());
                // coverage:ignore-end
              }
            }

            final tLevel = (error is PatapataException)
                ? (error.logLevel != null && error.logLevel! > Level.SEVERE)
                    ? error.logLevel!
                    : Level.SEVERE
                : Level.SEVERE;
            log.report(
              ReportRecord(
                level: tLevel,
                error: error,
                stackTrace: stackTrace,
                fingerprint:
                    (error is PatapataException) ? error.fingerprint : null,
                mechanism: Log.kUnhandledErrorMechanism,
              ),
            );
          },
          zoneValues: {
            #patapataApp: this,
          },
        );
      } else {
        // All errors are caught by [PlatformDispatcher] in the [Log] system.
        // This also allows [getApp] to work as we set a zone value for it here.
        runZoned<Future<void>>(
          () {
            return fRun();
          },
          zoneValues: {
            #patapataApp: this,
          },
        );
      }
    } catch (e, stackTrace) {
      // coverage:ignore-start
      // We don't care at this point.
      // It is possible that AppStage initialization failed or
      // runZoned itself failed to execute.
      if (onInitFailure != null) {
        await onInitFailure!(environment, e, stackTrace);
      } else {
        // ignore: avoid_print
        print(e);
        // ignore: avoid_print
        print(stackTrace);
      }
      tCompleter.complete(false);
      // coverage:ignore-end
    }

    return tCompleter.future;
  }

  /// Should be called when you want to get rid of this [App]
  /// and all resources associated with it, including static callbacks.
  /// Not usually needed in a real app, but used mostly in test tearDown.
  void dispose() {
    _stage = AppStage.disposed;

    _forceRemoveNativeSplashScreenTimer?.cancel();
    _forceRemoveNativeSplashScreenTimer = null;

    if (_originalErrorWidgetBuilder != null) {
      // coverage:ignore-start
      ErrorWidget.builder = _originalErrorWidgetBuilder!;
      _originalErrorWidgetBuilder = null;
      // coverage:ignore-end
    }

    try {
      user.dispose();
    } catch (e, stackTrace) {
      // coverage:ignore-start
      // We don't care at this point.
      // Some other libraries may have already disposed of the user.
      _logger.fine('Failed to dispose user', e, stackTrace);
      // coverage:ignore-end
    }
    _user = null;

    // Remove all plugins.
    final tPlugins = _plugins.toList(growable: false);
    for (var i in tPlugins) {
      try {
        removePlugin(i);
      } catch (e, stackTrace) {
        // coverage:ignore-start
        // We don't care at this point.
        // Just try to remove the next one.
        _logger.fine('Failed to remove plugin $i', e, stackTrace);
        // coverage:ignore-end
      }
    }

    try {
      remoteConfig.dispose();
    } catch (e, stackTrace) {
      // coverage:ignore-start
      // We don't care at this point.
      // Some other libraries may have already disposed of the remoteConfig.
      _logger.fine('Failed to dispose remoteConfig', e, stackTrace);
      // coverage:ignore-end
    }

    try {
      localConfig.dispose();
    } catch (e, stackTrace) {
      // coverage:ignore-start
      // We don't care at this point.
      // Some other libraries may have already disposed of the localConfig.
      _logger.fine('Failed to dispose localConfig', e, stackTrace);
      // coverage:ignore-end
    }

    try {
      remoteMessaging.dispose();
    } catch (e, stackTrace) {
      // coverage:ignore-start
      // We don't care at this point.
      // Some other libraries may have already disposed of the remoteMessaging.
      _logger.fine('Failed to dispose remoteMessaging', e, stackTrace);
      // coverage:ignore-end
    }

    try {
      permissions.dispose();
    } catch (e, stackTrace) {
      // coverage:ignore-start
      // We don't care at this point.
      // Some other libraries may have already disposed of the permissions.
      _logger.fine('Failed to dispose permissions', e, stackTrace);
      // coverage:ignore-end
    }

    try {
      log.dispose();
    } catch (e, stackTrace) {
      // coverage:ignore-start
      // We don't care at this point.
      // Some other libraries may have already disposed of the log.
      _logger.fine('Failed to dispose log', e, stackTrace);
      // coverage:ignore-end
    }
  }
}
