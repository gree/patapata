// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of "standard_app.dart";

/// This class is used to create applications using Cupertino with Patapata.
/// Widgets that have this class as their parent cannot use widgets intended for use with [MaterialApp].
/// Properties other than [pages], [routableBuilder], and [willPopPage] are the same as [CupertinoApp].
class StandardCupertinoApp<T> extends StatefulWidget
    with StandardStatefulMixin {
  /// {@macro flutter.widgets.widgetsApp.routeInformationProvider}
  final RouteInformationProvider? routeInformationProvider;

  /// {@macro flutter.widgets.widgetsApp.backButtonDispatcher}
  final BackButtonDispatcher? backButtonDispatcher;

  /// {@macro flutter.widgets.widgetsApp.routerConfig}
  final RouterConfig<Object>? routerConfig;

  /// {@macro flutter.widgets.widgetsApp.builder}
  final TransitionBuilder? builder;

  /// {@macro flutter.widgets.widgetsApp.onGenerateTitle}
  final String Function(BuildContext) onGenerateTitle;

  /// A CupertinoThemeData to pass to [theme] of [CupertinoApp.router].
  /// See [CupertinoApp.theme] of [CupertinoApp] for more details.
  final CupertinoThemeData? theme;

  /// {@macro flutter.widgets.widgetsApp.color}
  final Color? color;

  /// {@macro flutter.widgets.widgetsApp.locale}
  final Locale? locale;

  /// {@macro flutter.widgets.widgetsApp.localeListResolutionCallback}
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// {@macro flutter.widgets.LocaleResolutionCallback}
  final LocaleResolutionCallback? localeResolutionCallback;

  /// A bool to pass to [showPerformanceOverlay] of [CupertinoApp.router].
  /// See [CupertinoApp.showPerformanceOverlay] of [CupertinoApp] for more details.
  final bool showPerformanceOverlay;

  /// A bool to pass to [checkerboardRasterCacheImages] of [CupertinoApp.router].
  /// See [CupertinoApp.checkerboardRasterCacheImages] of [CupertinoApp] for more details.
  final bool checkerboardRasterCacheImages;

  /// A bool to pass to [checkerboardOffscreenLayers] of [CupertinoApp.router].
  /// See [CupertinoApp.checkerboardOffscreenLayers] of [CupertinoApp] for more details.
  final bool checkerboardOffscreenLayers;

  /// A bool to pass to [showSemanticsDebugger] of [CupertinoApp.router].
  /// See [CupertinoApp.showSemanticsDebugger] of [CupertinoApp] for more details.
  final bool showSemanticsDebugger;

  /// {@macro flutter.widgets.widgetsApp.debugShowCheckedModeBanner}
  final bool debugShowCheckedModeBanner;

  /// {@macro flutter.widgets.widgetsApp.shortcuts.seeAlso}
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// {@macro flutter.widgets.widgetsApp.actions.seeAlso}
  final Map<Type, Action<Intent>>? actions;

  /// {@macro flutter.widgets.widgetsApp.restorationScopeId}
  final String? restorationScopeId;

  /// {@macro flutter.material.materialApp.scrollBehavior}
  final ScrollBehavior? scrollBehavior;

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

  /// A function called when the app goes back to the previous page.
  /// It is passed to the willPopPage of [StandardRouterDelegate].
  @override
  bool Function(Route<dynamic> route, dynamic result)? get willPopPage =>
      _willPopPage;

  /// Creates a StandardCupertinoApp.
  const StandardCupertinoApp({
    super.key,
    this.routeInformationProvider,
    this.backButtonDispatcher,
    this.routerConfig,
    this.builder,
    required this.onGenerateTitle,
    this.theme,
    this.color,
    this.locale,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
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
        _willPopPage = willPopPage;

  @override
  State<StandardCupertinoApp> createState() => _StandardCupertinoAppState();
}

class _StandardCupertinoAppState<T> extends State<StandardCupertinoApp<T>>
    with StandardWidgetAppMixin {
  @override
  Widget build(BuildContext context) {
    return Provider<StandardAppType>.value(
      value: StandardAppType.cupertino,
      child: CupertinoApp.router(
        routeInformationProvider: widget.routeInformationProvider,
        routeInformationParser: _routeInformationParser,
        routerDelegate: _routerDelegate,
        backButtonDispatcher: widget.backButtonDispatcher,
        routerConfig: widget.routerConfig,
        builder: widget.builder,
        onGenerateTitle: widget.onGenerateTitle,
        color: widget.color,
        theme: widget.theme,
        locale: widget.locale,
        localizationsDelegates:
            context.read<App>().getPlugin<I18nPlugin>()!.i18n.l10nDelegates,
        localeListResolutionCallback: widget.localeListResolutionCallback,
        localeResolutionCallback: widget.localeResolutionCallback,
        supportedLocales:
            context.read<App>().getPlugin<I18nPlugin>()!.i18n.supportedL10ns,
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
