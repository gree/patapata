// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of "standard_app.dart";

/// This class is used to create applications using Material Design with Patapata.
/// Widgets that have this class as their parent cannot use widgets intended for use with [CupertinoApp].
/// Properties other than [pages], [routableBuilder], and [willPopPage] are properties to be passed to [MaterialApp.router].
class StandardMaterialApp<T> extends StatefulWidget with StandardStatefulMixin {
  /// A GlobalKey to pass to [scaffoldMessengerKey] of [MaterialApp.router].
  /// See [MaterialApp.scaffoldMessengerKey] of [MaterialApp] for more details.
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// {@macro flutter.widgets.widgetsApp.routeInformationProvider}
  final RouteInformationProvider? routeInformationProvider;

  /// {@macro flutter.widgets.widgetsApp.backButtonDispatcher}
  final BackButtonDispatcher? backButtonDispatcher;

  /// {@macro flutter.widgets.widgetsApp.builder}
  final TransitionBuilder? builder;

  /// {@macro flutter.widgets.widgetsApp.onGenerateTitle}
  final String Function(BuildContext) onGenerateTitle;

  /// A ThemeData to pass to [theme] of [MaterialApp.router].
  /// See [MaterialApp.theme] of [MaterialApp] for more details.
  final ThemeData? theme;

  /// A ThemeData to pass to [darkTheme] of [MaterialApp.router].
  /// See [MaterialApp.darkTheme] of [MaterialApp] for more details.
  final ThemeData? darkTheme;

  /// A ThemeData to pass to [highContrastTheme] of [MaterialApp.router].
  /// See [MaterialApp.highContrastTheme] of [MaterialApp] for more details.
  final ThemeData? highContrastTheme;

  /// A ThemeData to pass to [highContrastDarkTheme] of [MaterialApp.router].
  /// See [MaterialApp.highContrastDarkTheme] of [MaterialApp] for more details.
  final ThemeData? highContrastDarkTheme;

  /// A ThemeMode to pass to [themeMode] of [MaterialApp.router].
  /// See [MaterialApp.themeMode] of [MaterialApp] for more details.
  final ThemeMode? themeMode;

  /// {@macro flutter.widgets.widgetsApp.color}
  final Color? color;

  /// {@macro flutter.widgets.widgetsApp.locale}
  final Locale? locale;

  /// {@macro flutter.widgets.widgetsApp.localeListResolutionCallback}
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// {@macro flutter.widgets.LocaleResolutionCallback}
  final LocaleResolutionCallback? localeResolutionCallback;

  /// A bool to pass to [showPerformanceOverlay] of [MaterialApp.router].
  /// See [MaterialApp.showPerformanceOverlay] of [MaterialApp] for more details.
  final bool showPerformanceOverlay;

  /// A bool to pass to [checkerboardRasterCacheImages] of [MaterialApp.router].
  /// See [MaterialApp.checkerboardRasterCacheImages] of [MaterialApp] for more details.
  final bool checkerboardRasterCacheImages;

  /// A bool to pass to [checkerboardOffscreenLayers] of [MaterialApp.router].
  /// See [MaterialApp.checkerboardOffscreenLayers] of [MaterialApp] for more details.
  final bool checkerboardOffscreenLayers;

  /// A bool to pass to [showSemanticsDebugger] of [MaterialApp.router].
  /// See [MaterialApp.showSemanticsDebugger] of [MaterialApp] for more details.
  final bool showSemanticsDebugger;

  /// A bool to pass to [debugShowCheckedModeBanner] of [MaterialApp.router].
  /// See [MaterialApp.debugShowCheckedModeBanner] of [MaterialApp] for more details.
  final bool debugShowCheckedModeBanner;

  /// {@macro flutter.widgets.widgetsApp.shortcuts.seeAlso}
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// {@macro flutter.widgets.widgetsApp.actions.seeAlso}
  final Map<Type, Action<Intent>>? actions;

  /// {@macro flutter.widgets.widgetsApp.restorationScopeId}
  final String? restorationScopeId;

  /// A ScrollBehavior to pass to [scrollBehavior] of [MaterialApp.router].
  /// See [MaterialApp.scrollBehavior] of [MaterialApp] for more details.
  final ScrollBehavior? scrollBehavior;

  /// A bool to pass to [debugShowMaterialGrid] of [MaterialApp.router].
  /// See [MaterialApp.debugShowMaterialGrid] of [MaterialApp] for more details.
  final bool debugShowMaterialGrid;

  final List<StandardPageWithResultFactory> _pages;
  final Widget Function(BuildContext context, Widget? child)? _routableBuilder;
  final bool Function(Route<dynamic> route, dynamic result)? _willPopPage;

  /// A list of pages using the [StandardPageFactory] class implemented with StandardMaterialApp.
  /// It is passed to the pageFactories of [StandardRouterDelegate].
  @override
  List<
      StandardPageWithResultFactory<StandardPageWithResult<Object?, Object?>,
          Object?, Object?>> get pages => _pages;

  /// Wrap the entire Patapata Navigator-related application,
  /// enabling the use of screen transition-related functionalities through a function.
  /// It is passed to the routableBuilder of [StandardRouterDelegate].
  @override
  Widget Function(BuildContext context, Widget? child)? get routableBuilder =>
      _routableBuilder;

  /// See [PopScope] for more details.
  /// It is passed to the willPopPage of [StandardRouterDelegate].
  @override
  bool Function(Route<dynamic> route, dynamic result)? get willPopPage =>
      _willPopPage;

  /// BuildContext directly under Navigator of StandardMaterialApp
  static Element? get globalNavigatorContext =>
      _findTreeChildElement([StandardMaterialApp, Navigator]);

  /// Creates a StandardMaterialApp.
  const StandardMaterialApp({
    Key? key,
    this.scaffoldMessengerKey,
    this.routeInformationProvider,
    this.backButtonDispatcher,
    this.builder,
    required this.onGenerateTitle,
    this.theme,
    this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode,
    this.color,
    this.locale,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.actions,
    this.restorationScopeId,
    this.scrollBehavior,
    required List<StandardPageWithResultFactory> pages,
    Widget Function(BuildContext context, Widget? child)? routableBuilder,
    bool Function(Route<dynamic> route, dynamic result)? willPopPage,
  })  : _pages = pages,
        _routableBuilder = routableBuilder,
        _willPopPage = willPopPage,
        super(key: key);

  @override
  State<StandardMaterialApp<T>> createState() => _StandardMaterialAppState<T>();
}

class _StandardMaterialAppState<T> extends State<StandardMaterialApp<T>>
    with StandardWidgetAppMixin {
  @override
  Widget build(BuildContext context) {
    return Provider<StandardAppType>.value(
      value: StandardAppType.material,
      child: MaterialApp.router(
        scaffoldMessengerKey: widget.scaffoldMessengerKey,
        routeInformationProvider: widget.routeInformationProvider,
        routeInformationParser: _routeInformationParser,
        routerDelegate: _routerDelegate,
        backButtonDispatcher: widget.backButtonDispatcher,
        builder: widget.builder,
        onGenerateTitle: widget.onGenerateTitle,
        color: widget.color,
        theme: widget.theme,
        darkTheme: widget.darkTheme,
        highContrastTheme: widget.highContrastTheme,
        highContrastDarkTheme: widget.highContrastDarkTheme,
        themeMode: widget.themeMode,
        locale: widget.locale,
        localizationsDelegates:
            context.read<App>().getPlugin<I18nPlugin>()!.i18n.l10nDelegates,
        localeListResolutionCallback: widget.localeListResolutionCallback,
        localeResolutionCallback: widget.localeResolutionCallback,
        supportedLocales:
            context.read<App>().getPlugin<I18nPlugin>()!.i18n.supportedL10ns,
        debugShowMaterialGrid: widget.debugShowMaterialGrid,
        showPerformanceOverlay: widget.showPerformanceOverlay,
        checkerboardRasterCacheImages: widget.checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: widget.checkerboardOffscreenLayers,
        showSemanticsDebugger: widget.showSemanticsDebugger,
        debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
        shortcuts: widget.shortcuts,
        actions: widget.actions,
        restorationScopeId: widget.restorationScopeId,
        scrollBehavior: widget.scrollBehavior,
      ),
    );
  }
}
