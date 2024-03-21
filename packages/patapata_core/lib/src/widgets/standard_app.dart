// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:provider/provider.dart';

part 'standard_page.dart';
part 'standard_page_widget.dart';
part 'standard_app_mixin.dart';
part 'standard_material_app.dart';
part 'standard_cupertino_app.dart';

final _logger = Logger('patapata.StandardApp');

/// The [BuildContext] directly below [StandardMaterialApp]'s [Navigator]
Element? _findTreeChildElement(List<Type> tree) {
  final Element? tRoot = WidgetsBinding.instance.rootElement;
  Element? tResult;

  if (tRoot == null) {
    return null;
  }
  for (Type tElementType in tree) {
    tResult = _findChildElement(tResult ?? tRoot, tElementType);

    if (tResult == null) {
      return null;
    }
  }

  tResult!.visitChildElements((tChild) {
    tResult = tChild;
  });

  return tResult;
}

Element? _findChildElement(
  Element element,
  Type elementType,
) {
  Element? tResult;

  if (element.widget.runtimeType == elementType) {
    return element;
  } else {
    element.visitChildElements((tChild) {
      tResult = _findChildElement(tChild, elementType);
    });

    return tResult;
  }
}

/// A typedef for the key of a `LinkHandler` used in [StandardAppPlugin].
typedef StandardAppPluginLinkHandlerKey = Object;

/// A plugin that embodies the fundamental concepts of Patapata,
/// which includes rules, pages, and settings for app development, known as `StandardApp`.
/// This plugin is enabled by default.
/// If you want to disable `StandardApp`, you can remove this plugin using [App.removePlugin]
/// or disable it through remote configuration settings after running.
class StandardAppPlugin extends Plugin with StartupNavigatorMixin {
  StandardRouterDelegate? _delegate;

  /// The [RouterDelegate] required for Patapata's `Router`.
  StandardRouterDelegate? get delegate => _delegate;

  StandardRouteInformationParser? _parser;

  /// The [RouteInformationParser] required for Patapata's `Router`.
  StandardRouteInformationParser? get parser => _parser;

  StreamSubscription<AnalyticsEvent>? _sub;

  @override
  FutureOr<bool> init(App<Object> app) async {
    await super.init(app);

    _sub = app.analytics.events.listen((event) {
      if (event.name == 'wefwef') {
        // do something
      }
    });

    return true;
  }

  @override
  FutureOr<void> dispose() {
    _sub?.cancel();
    return super.dispose();
  }

  final _linkHandlers = <StandardAppPluginLinkHandlerKey, bool Function(Uri)>{};

  /// Add a callback function [callback] to the plugin's link handlers and return the key that identifies the added link handler.
  /// The link handler intercepts the link provided as an argument in [StandardAppRouterContext.route].
  /// It is used when you want to perform additional processing when receiving deep links or external notifications without triggering page navigation.
  StandardAppPluginLinkHandlerKey addLinkHandler(
      bool Function(Uri link) callback) {
    final tKey = StandardAppPluginLinkHandlerKey();

    _linkHandlers[tKey] = callback;

    return tKey;
  }

  /// Remove a link handler from the plugin that matches the specified key [key].
  void removeLinkHandler(StandardAppPluginLinkHandlerKey key) {
    _linkHandlers.remove(key);
  }

  /// {@template patapata_widgets.StandardAppPlugin.route}
  /// Navigate to a page with the specified [link].
  /// [link] is a string set in [StandardPageFactory] under `links`.
  /// {@endtemplate}
  void route(String link) async {
    final tRouteInformation = await parser
        ?.parseRouteInformation(RouteInformation(uri: Uri.parse(link)));

    if (tRouteInformation != null) {
      delegate?.routeWithConfiguration(tRouteInformation);
    }
  }

  /// {@template patapata_widgets.StandardAppPlugin.generateLinkWithResult}
  /// Retrieve a deep link for the specified [pageData] (when the page that retrieves the deep link returns a value).
  /// [P] is the type of the destination page, [R] is the type of page data, and [E] is the data type of the value that the page returns.
  /// These should be the same as what you set in your [StandardPageWithResultFactory].
  /// {@endtemplate}
  String? generateLinkWithResult<P extends StandardPageWithResult<R, E>,
      R extends Object?, E extends Object?>(R pageData) {
    return delegate?.getPageFactory<P, R, E>().linkGenerator?.call(pageData);
  }

  /// {@template patapata_widgets.StandardAppPlugin.generateLink}
  /// Retrieve a deep link for the specified [pageData] (when the page that retrieves the deep link does not return a value).
  /// [P] is the type of the destination page, [R] is the type of page data, and they should be consistent with what you have set in your [StandardPage].
  /// {@endtemplate}
  String? generateLink<P extends StandardPage<R>, R extends Object?>(
      R pageData) {
    return delegate?.getPageFactory<P, R, void>().linkGenerator?.call(pageData);
  }

  @override
  void startupNavigateToPage(Object page, StartupPageCompleter completer) {
    assert(page is Type);

    delegate?._getFactoryFromPageType(page as Type).goWithResult(completer);
  }

  @override
  void startupProcessInitialRoute() {
    delegate?.processInitialRoute();
  }

  @override
  void startupOnReset() {
    delegate?._factoryTypeMap.values.first
        .goWithResult(null, StandardPageNavigationMode.removeAll);
  }
}

/// A mixin for enabling integration between the 'Patapata' [Route] system and [Plugin], including routing and initialization processes.
/// The method implemented in this mixin is called within the processing of [StandardRouterDelegate.processInitialRoute]
/// when transitioning to the initial page after the app is launched.
///
/// In each plugin, please override and implement the following functions as needed.
/// [parseRouteInformation] is responsible for parsing route information and implementing the process to convert it into [StandardRouteData]. This is implemented when you want to return custom routes on the plugin side.
/// [transformRouteInformation] is used to implement the transformation process of route information in the plugin, primarily when you want to handle redirection.
/// [getInitialRouteData] is used to implement the logic for overwriting the data of the Route before processing the initial route.
mixin StandardAppRoutePluginMixin on Plugin {
  /// A function that parses the route information [routeInformation] and converts it to [StandardRouteData] for [StandardRouterDelegate].
  /// If the plugin's [parseRouteInformation] is implemented and returns a route, the processing of [transformRouteInformation] is ignored.
  Future<StandardRouteData?> parseRouteInformation(
          RouteInformation routeInformation) =>
      SynchronousFuture(null);

  /// A function to transform the route information [routeInformation] into another transformed route information [RouteInformation].
  /// This needs to be implemented when you want to redirect from one route to another based on the received route on the plugin side.
  Future<RouteInformation?> transformRouteInformation(
          RouteInformation routeInformation) =>
      SynchronousFuture(null);

  /// The process of creating [StandardRouteData] to be passed from the plugin to the screen, and this data is passed to [StandardRouterDelegate.routeWithConfiguration].
  /// If multiple plugins implement [getInitialRouteData], the [getInitialRouteData] of the first found plugin will be executed.
  Future<StandardRouteData?> getInitialRouteData() => SynchronousFuture(null);

  /// Create a [StandardAppRoutePluginMixin] that can be used in [App.addPlugin].
  /// This takes all the same parameters as [Plugin.inline] as well as all the methods of [StandardAppRoutePluginMixin].
  static StandardAppRoutePluginMixin inline({
    String name = 'inline',
    List<Type> dependencies = const <Type>[],
    bool requireRemoteConfig = false,
    FutureOr<bool> Function(App app)? init,
    FutureOr<void> Function()? dispose,
    Widget Function(Widget child)? createAppWidgetWrapper,
    RemoteConfig? Function()? createRemoteConfig,
    LocalConfig? Function()? createLocalConfig,
    RemoteMessaging? Function()? createRemoteMessaging,
    List<NavigatorObserver> Function()? navigatorObservers,
    Future<StandardRouteData?> Function(RouteInformation routeInformation)?
        parseRouteInformation,
    Future<RouteInformation?> Function(RouteInformation routeInformation)?
        transformRouteInformation,
    Future<StandardRouteData?> Function()? getInitialRouteData,
  }) =>
      _StandardAppRoutePluginMixinInline(
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
        parseRouteInformation: parseRouteInformation,
        transformRouteInformation: transformRouteInformation,
        getInitialRouteData: getInitialRouteData,
      );
}

class _StandardAppRoutePluginMixinInline extends InlinePlugin
    with StandardAppRoutePluginMixin {
  final Future<StandardRouteData?> Function(RouteInformation routeInformation)?
      _parseRouteInformation;
  final Future<RouteInformation?> Function(RouteInformation routeInformation)?
      _transformRouteInformation;
  final Future<StandardRouteData?> Function()? _getInitialRouteData;

  _StandardAppRoutePluginMixinInline({
    required super.name,
    super.dependencies,
    super.requireRemoteConfig,
    super.init,
    super.dispose,
    super.createAppWidgetWrapper,
    super.createRemoteConfig,
    super.createLocalConfig,
    super.createRemoteMessaging,
    super.navigatorObservers,
    Future<StandardRouteData?> Function(RouteInformation routeInformation)?
        parseRouteInformation,
    Future<RouteInformation?> Function(RouteInformation routeInformation)?
        transformRouteInformation,
    Future<StandardRouteData?> Function()? getInitialRouteData,
  })  : _parseRouteInformation = parseRouteInformation,
        _transformRouteInformation = transformRouteInformation,
        _getInitialRouteData = getInitialRouteData;

  @override
  Future<StandardRouteData?> parseRouteInformation(
          RouteInformation routeInformation) =>
      _parseRouteInformation != null
          ? _parseRouteInformation!(routeInformation)
          : super.parseRouteInformation(routeInformation);

  @override
  Future<RouteInformation?> transformRouteInformation(
          RouteInformation routeInformation) =>
      _transformRouteInformation != null
          ? _transformRouteInformation!(routeInformation)
          : super.transformRouteInformation(routeInformation);

  @override
  Future<StandardRouteData?> getInitialRouteData() =>
      _getInitialRouteData != null
          ? _getInitialRouteData!()
          : super.getInitialRouteData();
}

/// A mixin for allowing a [Plugin] to modify how a [StandardPage] or [StandardPageWithResult] works.
mixin StandardPagePluginMixin on Plugin {
  /// A function that allows you to modify the [StandardPage] or [StandardPageWithResult] before it is displayed.
  /// It will directly wrap the result of [StandardPage.buildPage] or [StandardPageWithResult.buildPage].
  ///
  /// When there are multiple [Plugin]s, each [Plugin] will wrap the result of the previous [Plugin].
  /// In other words, the result of the first [Plugin] will be wrapped by the second [Plugin], and so on.
  Widget buildPage(BuildContext context, Widget child);

  /// Create a [StandardPagePluginMixin] that can be used in [App.addPlugin].
  /// This takes all the same parameters as [Plugin.inline] as well as all the methods of [StandardPagePluginMixin].
  static StandardPagePluginMixin inline({
    String name = 'inline',
    List<Type> dependencies = const <Type>[],
    bool requireRemoteConfig = false,
    FutureOr<bool> Function(App app)? init,
    FutureOr<void> Function()? dispose,
    Widget Function(Widget child)? createAppWidgetWrapper,
    RemoteConfig? Function()? createRemoteConfig,
    LocalConfig? Function()? createLocalConfig,
    RemoteMessaging? Function()? createRemoteMessaging,
    List<NavigatorObserver> Function()? navigatorObservers,
    required Widget Function(BuildContext context, Widget child) buildPage,
  }) =>
      _StandardPagePluginMixinInline(
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
        buildPage: buildPage,
      );
}

class _StandardPagePluginMixinInline extends InlinePlugin
    with StandardPagePluginMixin {
  final Widget Function(BuildContext context, Widget child) _buildPage;

  _StandardPagePluginMixinInline({
    required super.name,
    super.dependencies,
    super.requireRemoteConfig,
    super.init,
    super.dispose,
    super.createAppWidgetWrapper,
    super.createRemoteConfig,
    super.createLocalConfig,
    super.createRemoteMessaging,
    super.navigatorObservers,
    required Widget Function(BuildContext context, Widget child) buildPage,
  }) : _buildPage = buildPage;

  @override
  Widget buildPage(BuildContext context, Widget child) {
    return _buildPage(context, child);
  }
}

/// An extension class that adds the Router functionality of StandardApp to [Router].
extension StandardAppRouter on Router {
  /// {@macro patapata_widgets.StandardRouteDelegate.pageInstances}
  List<Page<dynamic>> get pageInstances {
    assert(routerDelegate is StandardRouterDelegate);
    final tDelegate = routerDelegate as StandardRouterDelegate;

    return tDelegate.pageInstances;
  }

  /// {@template patapata_widgets.StandardAppRouter.pageChildInstances}
  /// Get a List of the actual pages of [Page].
  /// {@endtemplate}
  Map<StandardPageInterface, List<Page<dynamic>>> get pageChildInstances {
    assert(routerDelegate is StandardRouterDelegate);
    final tDelegate = routerDelegate as StandardRouterDelegate;

    return tDelegate._pageChildInstances;
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.getPageFactory}
  StandardPageWithResultFactory<T, R, E> getPageFactory<
      T extends StandardPageWithResult<R, E>,
      R extends Object?,
      E extends Object?>() {
    assert(routerDelegate is StandardRouterDelegate);
    final tDelegate = routerDelegate as StandardRouterDelegate;

    return tDelegate.getPageFactory<T, R, E>();
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.processInitialRoute}
  void processInitialRoute() {
    assert(routerDelegate is StandardRouterDelegate);
    (routerDelegate as StandardRouterDelegate).processInitialRoute();
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.goWithResult}
  Future<E?> goWithResult<T extends StandardPageWithResult<R, E>,
          R extends Object?, E extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    assert(routerDelegate is StandardRouterDelegate);
    final tDelegate = routerDelegate as StandardRouterDelegate;
    return tDelegate.goWithResult<T, R, E>(pageData, navigationMode);
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.go}
  Future<void> go<T extends StandardPage<R>, R extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    assert(routerDelegate is StandardRouterDelegate);
    final tDelegate = routerDelegate as StandardRouterDelegate;
    return tDelegate.go<T, R>(pageData, navigationMode);
  }

  /// {@template patapata_widgets.StandardAppRouter.route}
  /// Navigate to a page with the specified [location].
  /// [navigationMode] represents the mode of [StandardPageNavigationMode] to use during navigation (optional).
  /// {@endtemplate}
  void route(String location,
      [StandardPageNavigationMode? navigationMode]) async {
    assert(routerDelegate is StandardRouterDelegate);
    final tDelegate = routerDelegate as StandardRouterDelegate;
    final tConfiguration = await routeInformationParser
        ?.parseRouteInformation(RouteInformation(uri: Uri.parse(location)));

    if (tConfiguration != null) {
      tDelegate.routeWithConfiguration(tConfiguration, navigationMode);
    }
  }

  /// Remove the nearest page in [context], if it exists. Do nothing if it doesn't exist.
  void removeRoute(BuildContext context) {
    assert(routerDelegate is StandardRouterDelegate);
    final tDelegate = routerDelegate as StandardRouterDelegate;

    final tRoute = ModalRoute.of(context);

    if (tRoute == null) {
      return;
    }

    tDelegate.removeRoute(tRoute, null);
  }
}

/// An extension class that adds the Router functionality of StandardApp to [BuildContext].
extension StandardAppRouterContext on BuildContext {
  /// Retrieves the [Router].
  Router get router => Router.of(this);

  /// {@macro patapata_widgets.StandardRouteDelegate.goWithResult}
  Future<E?> goWithResult<T extends StandardPageWithResult<R, E>,
          R extends Object?, E extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    return Router.of(this).goWithResult<T, R, E>(pageData, navigationMode);
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.go}
  Future<void> go<T extends StandardPage<R>, R extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    return Router.of(this).go<T, R>(pageData, navigationMode);
  }

  /// {@macro patapata_widgets.StandardAppRouter.route}
  void route(String location, [StandardPageNavigationMode? navigationMode]) {
    Router.of(this).route(location, navigationMode);
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.pageInstances}
  List<Page<dynamic>> get pageInstances => Router.of(this).pageInstances;

  /// {@macro patapata_widgets.StandardAppRouter.pageChildInstances}
  Map<StandardPageInterface, List<Page<dynamic>>> get pageChildInstances =>
      Router.of(this).pageChildInstances;

  /// {@macro patapata_widgets.StandardRouteDelegate.getPageFactory}
  StandardPageWithResultFactory<T, R, E> getPageFactory<
      T extends StandardPageWithResult<R, E>,
      R extends Object?,
      E extends Object?>() {
    return Router.of(this).getPageFactory<T, R, E>();
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.removeRoute}
  void removeRoute() {
    Router.of(this).removeRoute(this);
  }
}

/// An extension class that adds references to the Router and Plugin functionalities of StandardApp to [App].
extension StandardAppApp on App {
  /// Retrieves [StandardAppPlugin] from the [App].
  StandardAppPlugin get standardAppPlugin {
    final tPlugin = getPlugin<StandardAppPlugin>();

    assert(tPlugin != null,
        'Could not find StandardApp. Was it removed from the plugins?');

    return tPlugin!;
  }

  /// The BuildContext of the Navigator from [StandardAppPlugin.delegate].
  BuildContext get navigatorContext =>
      standardAppPlugin.delegate!.navigatorContext;

  /// The Navigator from [StandardAppPlugin.delegate].
  NavigatorState get navigator => standardAppPlugin.delegate!.navigator;

  /// {@macro patapata_widgets.StandardRouteDelegate.goWithResult}
  Future<E?> goWithResult<T extends StandardPageWithResult<R, E>,
          R extends Object?, E extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    return navigatorContext.goWithResult<T, R, E>(pageData, navigationMode);
  }

  /// {@macro patapata_widgets.StandardRouteDelegate.goWithResult}
  Future<void> go<T extends StandardPage<R>, R extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    return navigatorContext.go<T, R>(pageData, navigationMode);
  }

  /// {@macro patapata_widgets.StandardAppPlugin.route}
  void route(String link) async {
    return standardAppPlugin.route(link);
  }

  /// Pops the Navigator of [StandardAppApp.navigator].
  /// This is used when context is not accessible.
  void removeRoute() {
    navigator.pop();
  }

  /// {@macro patapata_widgets.StandardAppPlugin.generateLinkWithResult}
  String? generateLinkWithResult<P extends StandardPageWithResult<R, E>,
      R extends Object?, E extends Object?>(R pageData) {
    return standardAppPlugin.generateLinkWithResult<P, R, E>(pageData);
  }

  /// {@macro patapata_widgets.StandardAppPlugin.generateLink}
  String? generateLink<P extends StandardPage<R>, R extends Object?>(
      R pageData) {
    return standardAppPlugin.generateLink<P, R>(pageData);
  }
}
