// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of "standard_app.dart";

const Key _childNavigatorKey = Key('childNavigatorKey');

/// Whether to use the Material app or the Cupertino app to design
enum StandardAppType {
  /// Use standard material app
  material,

  /// Use standard cupertino app
  cupertino,
}

/// Specifies how pages created with [StandardPageFactory] should be navigated
enum StandardPageNavigationMode {
  /// Similar to [Navigator.push] used in Flutter's Navigator, it adds the page to the top of the history.
  /// However, if there is already a page with the same page key in the history,
  /// it moves that page to the top without removing other pages with the same page key from the history
  moveToTop,

  /// If the same page exists within the history, all history from that page and up will be removed.
  /// Then the page will be added to the top of the history.
  /// If the same page does not exist within the history, it behaves the same as [moveToTop].
  removeAbove,

  /// After removing all pages from the history, add the page.
  removeAll,

  /// Remove the current page from the history and replace it with the page being navigated to.
  replace,
}

/// A factory class for creating [StandardPageWithResult] instances that returns a value [E].
/// This class can be added to the `pages` property of [StandardMaterialApp.new] or [StandardCupertinoApp.new].
/// [T] is the Represents the data type of the destination page, [R] is the Represents the data type of the page data, [E] is the Represents the data type of the value returned by the page.
///
/// For how to pass and configure this class in [StandardStatefulMixin.pages], please refer to the documentation of [StandardPageFactory].
///
/// The key distinction to [StandardPage] is that this class returns a value.
/// For example, a `PageWithResult` is a screen of type `StandardPageWithResult` that returns a result of type String.
///
/// example:
/// ```dart
/// class PageWithResult extends StandardPageWithResult<void, String> {
///   @override
///   Widget buildPage(BuildContext context) {
///     return Scaffold(
///       body: Center(
///         child: TextButton(
///           onPressed: () {
///             // Set the result of this StandardPageWithResult to the pageResult.
///             pageResult = 'pageResult';
///             Navigator.pop(context);
///           },
///           child: const Text('Navigator Pop Page'),
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// You can retrieve the result of `PageWithResult` as shown below, using [goWithResult] for navigation.
///
/// example:
/// ```dart
/// final tResult = await context.goWithResult<PageWithResult, void, String>(null);
/// ```
base class StandardPageWithResultFactory<T extends StandardPageWithResult<R, E>,
    R extends Object?, E extends Object?> {
  /// The default group name set when no group is specified for the page.
  static const String defaultGroup = 'StandardPageDefaultGroup';

  late final StandardRouterDelegate _delegate;

  /// Creates the [T] page that this factory manages.
  final T Function(R pageData) create;
  final Map<RegExp, R Function(RegExpMatch match, Uri uri)> _links;

  /// The function to create deep links for this page.
  /// The return value must match the keys (regular expressions) passed to links and their corresponding [R] 'pageData' destinations.
  final String Function(R pageData)? linkGenerator;

  /// The group name used to manage multiple pages as part of the same group when they exist.
  final String? group;

  /// Flag indicating whether to set this page as the root group if a group name is specified.
  final bool groupRoot;

  /// Flag indicating whether to stack this page as part of the history or not.
  final bool keepHistory;

  /// Flag indicating whether to enable analytics for navigation.
  final bool enableNavigationAnalytics;

  /// The method for transitioning to this page from other pages.
  /// Please refer to [StandardPageNavigationMode] for navigation modes.
  final StandardPageNavigationMode navigationMode;
  final LocalKey Function(
    R pageData,
  )? _pageKey;

  /// A function for creating [StandardPageInterface].
  ///
  /// The [pageBuilder] function takes the following parameters
  /// `child` : The child widget to be included in the [StandardPageWithResult].
  /// `name` : The name of the page (can be null).
  /// `pageData` : The data associated with the page.
  /// `pageKey` : A [LocalKey] to identify the page.
  /// `restorationId` : A unique ID for state restoration.
  /// `standardPageKey` : A [GlobalKey] for the [StandardPageWithResult] widget.
  /// `factoryObject` : An instance of [StandardPageWithResultFactory].
  final StandardPageInterface<R, E> Function(
    Widget child,
    String? name,
    R pageData,
    LocalKey pageKey,
    String restorationId,
    GlobalKey<StandardPageWithResult<R, E>> standardPageKey,
    StandardPageWithResultFactory<StandardPageWithResult<R, E>, R, E>
        factoryObject,
  )? pageBuilder;

  /// A function to generate a replacement value when the pageData passed during navigation is null.
  final R Function()? pageDataWhenNull;

  /// The name of this page.
  final String? Function()? pageName;

  /// A function for generating a value to pass to [Page.restorationId].
  final String Function(
    R pageData,
  )? restorationId;

  /// When using nested [Navigator]s, specifies what the parent page [Type] of this child page should be.
  final Type? parentPageType;

  /// Create a StandardPageWithResultFactory.
  /// Define deep links for navigating to this page using regular expressions, allowing for multiple configurations.
  /// Set the page key, with page data being of the type [R].
  ///
  /// [create] is a required parameter. Pass a class that extends [StandardPageWithResult] to this argument.
  /// Other arguments are optional.
  ///
  /// [links] define the links to navigate to this page using regular expressions, and [linkGenerator] generates deep links for this page.
  ///
  /// [group] is the group name used to manage multiple pages as part of the same group. [groupRoot] is a flag within the same group name to specify which page should be the root. The default value is `false`.
  ///
  /// [keepHistory] is a flag for whether to push history on the Navigator during transitions. The default is `true`.
  ///
  /// [enableNavigationAnalytics] is a flag indicating whether to enable navigation analytics. The default is `true`.
  ///
  /// [navigationMode] specifies the NavigationMode when navigating to this page. The default is [StandardPageNavigationMode.moveToTop].
  ///
  /// [pageKey] is a [LocalKey] to identify the page.
  ///
  /// [pageBuilder] is a function that wraps the processing when the page is built. The default is the page of [StandardMaterialPage].
  ///
  /// [pageDataWhenNull] is a function that wraps the processing when building when page data is null.
  ///
  /// [pageName] is the name of this page.
  ///
  /// [restorationId] is a unique ID for state restoration.
  ///
  /// [parentPageType] is the page type that specifies which page type to consider as the parent.
  StandardPageWithResultFactory({
    required this.create,
    Map<String, R Function(RegExpMatch match, Uri uri)>? links,
    this.linkGenerator,
    this.groupRoot = false,
    this.group = defaultGroup,
    this.keepHistory = true,
    this.enableNavigationAnalytics = true,
    this.navigationMode = StandardPageNavigationMode.moveToTop,
    LocalKey Function(
      R pageData,
    )? pageKey,
    this.pageBuilder,
    this.pageDataWhenNull,
    this.pageName,
    this.restorationId,
    this.parentPageType,
  })  : assert((links == null && linkGenerator == null) ||
            (links != null && linkGenerator != null)),
        _pageKey = pageKey,
        _links = links != null
            ? {
                for (var i in links.entries) RegExp('^/?${i.key}\$'): i.value,
              }
            : const {};

  /// The page type of this page.
  Type get pageType => T;

  /// The data type of this page.
  Type get dataType => R;

  /// The result type of this page.
  Type get resultType => E;

  /// Flag indicating that the type of page data set for this page is nullable.
  bool get dataTypeIsNonNullable => <R>[] is List<Object>;

  /// Returns the deep link generated by this page given [pageData].
  String? generateLink(Object? pageData) {
    if (linkGenerator != null) {
      // Dart doesn't allow automatic casting 1st citizen objects who
      // have different less than 1st citizen parameters.
      // In this case, linkGenerator could be ((MyClass) => String),
      // But dart only can see ((Object) => String) and therefore
      // can't convert between them.
      // We do this trick here from inside the problematic class
      // to cast as something that we _know_ to be true.
      return linkGenerator!(pageData as R);
    }

    return null;
  }

  /// Navigate to the [StandardPage] of type [T] with the option to pass [pageData] during navigation.
  /// An optional [navigationMode] representing the mode of [StandardPageNavigationMode] to use during navigation can also be provided.
  Future<E?> goWithResult(
    R pageData, [
    StandardPageNavigationMode? navigationMode,
  ]) =>
      _delegate.goWithResult<T, R, E>(pageData, navigationMode);

  /// Get the key set for this page, as configured for this page.
  LocalKey getPageKey(Object? pageData) {
    final tPageData = pageData ?? pageDataWhenNull?.call();

    if (tPageData is R) {
      return (_pageKey ?? _defaultPageKey)(tPageData);
    }

    throw Never;
  }

  LocalKey _defaultPageKey(
    R pageData,
  ) =>
      ValueKey(
          '${pageType.toString()}:${linkGenerator != null ? linkGenerator!(pageData) : pageData}');

  String _defaultRestorationId(
    R pageData,
  ) =>
      '${pageType.toString()}:${linkGenerator != null ? linkGenerator!(pageData) : pageData}';

  StandardPageInterface<R, E> _defaultPageBuilder(
    Widget child,
    String? name,
    Object? pageData,
    LocalKey pageKey,
    String restorationId,
    GlobalKey<StandardPageWithResult<R, E>> standardPageKey,
    StandardPageWithResultFactory<StandardPageWithResult<R, E>, R, E>
        factoryObject,
  ) =>
      StandardMaterialPage<R, E>(
        child: child,
        name: name,
        arguments: pageData,
        key: pageKey,
        restorationId: restorationId,
        standardPageKey: standardPageKey,
        factoryObject: factoryObject,
      );

  Completer<E?> _createResultCompleter() => Completer<E?>();

  StandardPageInterface _createPage(
    LocalKey pageKey,
    R pageData,
  ) {
    if (pageData == null && pageDataWhenNull != null) {
      pageData = pageDataWhenNull!();
    }

    final tGlobalKey = GlobalKey<StandardPageWithResult<R, E>>();

    return (pageBuilder ?? _defaultPageBuilder)(
      _StandardPageWidget<R, E>(
        key: tGlobalKey,
        factoryObject: this,
        pageData: pageData,
      ),
      pageName?.call() ?? T.toString(),
      pageData,
      pageKey,
      restorationId?.call(pageData) ?? _defaultRestorationId(pageData),
      tGlobalKey,
      this,
    );
  }
}

/// Factory class for [StandardPage] to be set in the `page` property of [StandardMaterialApp].
/// [T] is the type of the destination page, and [R] is the type of page data.
/// The following source code is an example of passing [StandardPageFactory] to [StandardMaterialApp.pages].
///
/// example:
/// ```dart
/// StandardMaterialApp(
///   onGenerateTitle: (context) => 'sample',
///   pages: [
///     StandardPageFactory<PageA, void>(
///       create: (_) => PageA(),
///     ),
///     StandardPageFactory<PageB, PageBData>(
///       create: (_) => PageB(),
///     ),
///   ],
/// );
/// ```
///
/// Page navigation is generally done using `context.go`.
/// You pass the type of the specified page and the page data associated with that type during navigation.
/// For pages like PageA that do not involve data transfer, you can navigate using `context.go<PageA, void>(null)`.
/// For screens with PageBData class page data reception, you can navigate using `context.go<PageB, PageBData>(PageBData());`.
/// For pages with PageBData class as page data, you can navigate using `context.go<PageB, PageBData>(PageBData());`.
///
/// There is a concept called "group" that can be configured for each page.
/// If no group is specified, it defaults to [defaultGroup].
/// When transitioning to a group different from the current page's group, all pages other than the destination group will be removed.
///
/// You can set deep links for each page.
/// [StandardPageFactory.new]'s `links` allows you to define regular expressions for deep links to navigate to this page. Multiple configurations are possible.
/// [linkGenerator] creates deep links to navigate to this page from the page data's state for this page.
///
/// example:
/// ```dart
/// StandardPageFactory<PageC, DeepLinkData>(
///   create: (_) => PageC(),
///   links: {
///     r'pageC/(\d+)' : (match, uri) => DeepLinkData(
///       id: int.parse(uri.queryParameters([‘id’])!),
///       message: 'this is message',
///     ),
///   },
///   linkGenerator: (pageC) => 'pageC/${pageC.id}',
/// ),
///
/// class DeepLinkData {
///   DeepLinkData({
///     required this.id,
///     required this.message,
///   });
///   final int id;
///   final String? message;
/// }
/// ```
///
/// For each page, you can specify which page class to use as the parent page type using `parentPageType`.
/// This is useful, for example, when implementing applications with multiple footer menus.
///
/// example:
/// ```dart
/// StandardMaterialApp(
///   onGenerateTitle: (context) => l(context, 'title'),
///   pages: [
///     // HomePage Menu
///     StandardPageFactory<HomePage, void>(
///       create: (data) => HomePage(),
///     ),
///     StandardPageFactory<TitlePage, void>(
///       create: (data) => TitlePage(),
///       parentPageType: HomePage,
///     ),
///     StandardPageFactory<TitleDetailsPage, void>(
///       create: (data) => TitleDetailsPage(),
///       parentPageType: HomePage,
///     ),
///     // MyPage Menu
///     StandardPageFactory<MyPage, void>(
///       create: (data) => MyPage(),
///     ),
///     StandardPageFactory<MyFavoritePage, void>(
///       create: (data) => MyFavoritePage(),
///       parentPageType: MyPage,
///     ),
///   ],
/// );
/// ```
base class StandardPageFactory<T extends StandardPage<R>, R extends Object?>
    extends StandardPageWithResultFactory<T, R, void> {
  /// Create a StandardPageFactory
  StandardPageFactory({
    required super.create,
    super.links,
    super.linkGenerator,
    super.groupRoot,
    super.group,
    super.keepHistory,
    super.enableNavigationAnalytics,
    super.navigationMode,
    super.pageKey,
    super.pageBuilder,
    super.pageDataWhenNull,
    super.pageName,
    super.restorationId,
    super.parentPageType,
  });
}

/// This is a special factory class for creating a splash page after app launch,
/// and it is required to collaborate with the functionality of [StartupSequence].
base class SplashPageFactory<T extends StandardPage<void>>
    extends StandardPageFactory<T, void> {
  /// Create a SplashPageFactory
  SplashPageFactory({
    required super.create,
    super.pageKey,
    super.pageBuilder,
    super.pageDataWhenNull,
    super.pageName,
    super.restorationId,
    super.enableNavigationAnalytics,
  }) : super(
          group: 'splash',
          keepHistory: false,
        );
}

/// A special factory class for creating a page used during a [StartupSequence].
/// Used for scenarios like creating a consent screen for the user on the first app launch.
base class StartupPageFactory<T extends StandardPage<StartupPageCompleter>>
    extends StandardPageFactory<T, StartupPageCompleter> {
  /// Create a StartupPageFactory
  StartupPageFactory({
    required super.create,
    super.groupRoot,
    String? group,
    super.keepHistory,
    super.enableNavigationAnalytics,
    super.navigationMode,
    super.pageKey,
    super.pageBuilder,
    super.pageDataWhenNull,
    super.pageName,
    super.restorationId,
  }) : super(
          group: 'startup${group?.isNotEmpty == true ? '@$group' : ''}',
        );
}

/// A special factory class for creating an error page that [PatapataException] can navigate to
/// if an error has a [PatapataException.userLogLevel] of [Level.SHOUT].
base class StandardErrorPageFactory<T extends StandardPage<ReportRecord>>
    extends StandardPageFactory<T, ReportRecord> {
  static const String errorGroup = 'error';

  /// Create a StandardErrorPageFactory
  StandardErrorPageFactory({
    required super.create,
    Map<String, ReportRecord Function(RegExpMatch match, Uri uri)>? links,
    super.linkGenerator,
    super.groupRoot = false,
    super.group = StandardErrorPageFactory.errorGroup,
    super.keepHistory = true,
    super.enableNavigationAnalytics,
    super.navigationMode = StandardPageNavigationMode.removeAll,
    super.pageKey,
    super.pageBuilder,
    super.pageDataWhenNull,
    super.pageName,
    super.restorationId,
  });
}

/// A mixin for creating a [Page] that creates [StandardPageWithResult].
mixin StandardPageInterface<R extends Object?, E extends Object?>
    on Page<void> {
  /// The page key for the corresponding [StandardPageWithResult].
  GlobalKey<StandardPageWithResult<R, E>> get standardPageKey;

  /// The factory class that created this page.
  StandardPageWithResultFactory get factoryObject;
}

/// Implements functionality to extend [MaterialPage] and create a [StandardPage].
///
/// This class includes the [standardPageKey] property for accessing the page's key
/// and the [factoryObject] property for obtaining an object of the StandardPageFactory class.
///
/// [R] represents the type of the page's result.
/// [E] represents the type of the value that the page returns.
class StandardMaterialPage<R extends Object?, E extends Object?>
    extends MaterialPage<void> implements StandardPageInterface<R, E> {
  @override
  final GlobalKey<StandardPageWithResult<R, E>> standardPageKey;

  @override
  final StandardPageWithResultFactory factoryObject;

  /// Create a StandardMaterialPage
  const StandardMaterialPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required this.standardPageKey,
    required this.factoryObject,
    required super.child,
  });
}

/// Implements functionality to extend [Page] and create a customized [StandardPageWithResult].
///
/// This class includes the [standardPageKey] property for accessing the page's key
/// and the [factoryObject] property for obtaining an object of the StandardPageWithResult class.
///
/// [R] represents the type of the page's result.
/// [E] represents the type of the value that the page returns.
class StandardCustomPage<R, E> extends Page<void>
    implements StandardPageInterface<R, E> {
  @override
  final GlobalKey<StandardPageWithResult<R, E>> standardPageKey;

  @override
  final StandardPageWithResultFactory factoryObject;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// Create a StandardCustomPage
  const StandardCustomPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.maintainState = true,
    this.barrierDismissible = false,
    this.barrierColor,
    this.barrierLabel,
    this.barrierCurve = Curves.ease,
    this.opaque = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    required this.standardPageKey,
    required this.factoryObject,
    this.transitionBuilder,
    required this.child,
  });

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.ModalRoute.barrierDismissible}
  final bool barrierDismissible;

  /// {@macro flutter.widgets.ModalRoute.barrierColor}
  final Color? barrierColor;

  /// {@macro flutter.widgets.ModalRoute.barrierLabel}
  final String? barrierLabel;

  /// {@macro flutter.widgets.ModalRoute.barrierCurve}
  final Curve barrierCurve;

  /// {@macro flutter.widgets.ModalRoute.opaque}
  final bool opaque;

  /// {@macro flutter.widgets.ModalRoute.transitionDuration}
  final Duration transitionDuration;

  /// An animated builder process used when transitioning to this page.
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )? transitionBuilder;

  @override
  Route<R> createRoute(BuildContext context) {
    return _StandardCustomPageRoute<R, E>(page: this);
  }
}

class _StandardCustomPageRoute<R, E> extends ModalRoute<R> {
  _StandardCustomPageRoute({
    required StandardCustomPage<R, E> page,
  }) : super(
          settings: page,
        );

  StandardCustomPage<R, E> get _page => settings as StandardCustomPage<R, E>;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: _page.child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final tBuilder = _page.transitionBuilder;

    if (tBuilder != null) {
      return tBuilder(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    return child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  Duration get transitionDuration => _page.transitionDuration;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  Curve get barrierCurve => _page.barrierCurve;

  @override
  bool get opaque => _page.opaque;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

class _StandardPageWidget<T extends Object?, E extends Object?>
    extends StatefulWidget {
  final StandardPageWithResultFactory<StandardPageWithResult<T, E>, T, E>
      factoryObject;
  final T pageData;

  const _StandardPageWidget({
    super.key,
    required this.factoryObject,
    required this.pageData,
  });

  @override
  State<_StandardPageWidget<T, E>> createState() =>
      // ignore: no_logic_in_create_state
      factoryObject.create(pageData).._factory = factoryObject;
}

const _kAnalyticsGlobalContextKey = Object();

/// {@template patapata_widgets.StandardPageWithResult}
/// This class is used to create pages that return values when building an application with Patapata.
///
/// Define page classes that inherit from this class and pass them to [StandardPageWithResultFactory.create].
/// Pages created with [StandardPageWithResult] must override [buildPage].
/// [T] represents the type of page data associated with the page
/// {@endtemplate}
/// [E] signifies the type of data that the page returns.
abstract class StandardPageWithResult<T extends Object?, E extends Object?>
    extends State<_StandardPageWidget<T, E>> with RouteAware {
  late StandardPageWithResultFactory<StandardPageWithResult<T, E>, T, E>
      _factory;

  void _completeResult(Completer completer, dynamic popResult) {
    if (completer.isCompleted) {
      return;
    }

    assert(completer is Completer<E?>);

    if (popResult != null && popResult is E) {
      (completer as Completer<E?>).complete(popResult);
    } else {
      (completer as Completer<E?>).complete(pageResult);
    }
  }

  bool _pageResultSet = false;
  E? _pageResult;

  /// Get the result returned by this page.
  E? get pageResult => _pageResultSet ? _pageResult as E : null;

  /// Set the result returned by this page.
  set pageResult(E? value) {
    _pageResultSet = true;
    _pageResult = value;
  }

  bool _doPageDataChangedOnReady = false;
  late T _pageData;

  /// Get the page data.
  T get pageData => _pageData;

  /// Set the page data.
  set pageData(T value) {
    if (value is Listenable) {
      if (_pageData != null) {
        (_pageData as Listenable).removeListener(_onPageDataChanged);
      }

      value.addListener(_onPageDataChanged);
    }

    final tSame = _pageData == value;
    _pageData = value;

    // We are dealing with the Listenable check above this
    // changed check because with overridden == operators, it's
    // likely that the actual object has changed and therefore the listeners
    // also need to be reset, but the data part of the object is the same.
    // So we just replace the listeners but don't notify of changes.
    if (tSame) {
      // ignore
      return;
    }

    _onPageDataChanged();
  }

  Navigator? _navigator;

  /// When [StandardPageWithResultFactory.parentPageType] is set, it retrieves the child [Navigator] widget.
  /// This is used when creating applications with features like footer tabs.
  ///
  /// For example, let's say there's a page called PageA, which is a tab, and it is set as the parentPageType for PageB.
  /// ```dart
  ///  StandardMaterialApp(
  ///    onGenerateTitle: (context) => l(context, 'tab page'),
  ///    pages: [
  ///      StandardPageFactory<PageA, void>(
  ///        create: (data) => PageA(),
  ///      ),
  ///      StandardPageFactory<PageB, void>(
  ///        create: (data) => PageB,
  ///        parentPageType: PageA,
  ///      ),
  ///    ],
  ///  );
  /// ```
  ///
  /// In this case, PageA displays the widget that shows the tab in the footer,
  /// but there is no widget to display within it. Therefore, you can use [childNavigator] to retrieve and display the content of PageB
  /// ```dart
  /// class PageA extends StandardPage<void> {
  ///   @override
  ///   Widget buildPage(BuildContext context) {
  ///     return childNavigator!; // Display the content of PageB
  ///   }
  /// }
  /// ```
  Navigator? get childNavigator => _navigator;

  void _onPageDataChanged() {
    if (!mounted) {
      return;
    }

    if (!_ready) {
      _doPageDataChangedOnReady = true;

      return;
    }

    // TODO: In the future, we should look at use cases here
    // And decide if we want to update the current navigation
    // data (like the URL) or not. Currently, we do not.
    // If we were to, we'd need to update _pageInstanceToRouteData
    // with the newest pageData.

    _sendPageDataEvent();
    (Router.of(context).routerDelegate as StandardRouterDelegate?)
        ?._updatePages();
    onPageData();
  }

  AnalyticsContext _generateAnalyticsContext() => AnalyticsContext({
        'pageName': name,
        'pageData': pageData,
        'pageLink': link,
        ...Analytics.tryConvertToLoggableJsonParameters(
            'pageDataJson', pageData),
      });

  void _updateRouteAnalyticsContext() {
    context.read<Analytics>().setRouteContext(
          _kAnalyticsGlobalContextKey,
          _generateAnalyticsContext(),
        );
  }

  void _sendPageDataEvent() {
    _updateRouteAnalyticsContext();
    context.read<Analytics>().event(
          name: 'pageDataUpdate',
          context: context,
        );
  }

  /// Called when the page data is updated.
  void onPageData() {}

  /// The name of this page.
  String get name => runtimeType.toString();

  /// Get the deep link for this page.
  /// Returns null if [StandardPageFactory.linkGenerator] is not defined for this page.
  String? get link =>
      _factory.linkGenerator != null ? _factory.linkGenerator!(pageData) : null;

  RouteObserver<ModalRoute<void>>? _routeObserver;

  bool _ready = false;

  bool _firstActive = true;
  bool _active = false;

  /// A flag indicating whether this page is at the top of the history, i.e., whether it's the currently user-interacted page.
  bool get active => _active && mounted;

  @protected
  AnalyticsEvent? get analyticsSingletonEvent => null;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _pageData = widget.pageData;
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();

    _ready = true;

    _routeObserver ??= context.read<RouteObserver<ModalRoute<void>>>();
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);

    if (_doPageDataChangedOnReady) {
      _doPageDataChangedOnReady = false;
      scheduleFunction(_onPageDataChanged);
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _routeObserver?.unsubscribe(this);
    _routeObserver = null;

    super.dispose();
  }

  @override
  @mustCallSuper
  void didPopNext() {
    _updateActiveStatus();
  }

  @override
  @mustCallSuper
  void didPush() {
    _updateActiveStatus();
  }

  @override
  @mustCallSuper
  void didPop() {
    _updateActiveStatus();
  }

  @override
  @mustCallSuper
  void didPushNext() {
    bool tIgnore = false;

    // We aren't actually popping.
    // This is a hack to get access to the most
    // recent Route object...
    if (mounted) {
      Navigator.of(context).popUntil((route) {
        if (route is ModalRoute &&
            !route.opaque &&
            route.settings is! StandardCustomPage) {
          tIgnore = true;
        }

        return true;
      });
    }

    if (!tIgnore) {
      _updateActiveStatus();
    }
  }

  void _updateActiveStatus([bool? forcedStatus]) {
    // ignore: todo
    // TODO: Go up the entire tree to support multiple Navigators.
    // We only want to be active if our [Navigator] is also actually in the front.
    final tIsCurrentlyActive = _active;
    _active = mounted &&
        (forcedStatus ?? (ModalRoute.of(context)?.isCurrent ?? false));

    if (_active != tIsCurrentlyActive) {
      if (_active) {
        _updateRouteAnalyticsContext();
        onActive(_firstActive);

        if (_firstActive) {
          _firstActive = false;
        }
      } else {
        onInactive();
      }
    }
  }

  StandardRouterDelegate? _delegate;
  Map<StandardPageInterface, List<Page<dynamic>>>? _pageChildInstances;
  StandardPageWithResultFactory<StandardPageWithResult<Object?, Object?>,
      Object?, Object?>? _firstPageFactory;

  @protected
  @mustCallSuper
  void onActive(bool first) {
    _delegate = Router.of(context).routerDelegate as StandardRouterDelegate?;

    _pageChildInstances = _delegate?._pageChildInstances;

    final Map<Type, List<Type>>? tStandardPagesMap =
        _delegate?._standardPagesMap;

    if (first && _pageChildInstances != null && tStandardPagesMap != null) {
      if (tStandardPagesMap.containsKey(_factory.pageType) &&
          tStandardPagesMap[_factory.pageType]!.isNotEmpty) {
        // Create an instance of the first child element to be displayed by default.
        var tStandardPageInterface =
            ModalRoute.of(context)?.settings as StandardPageInterface;

        final Type tChildPageType;
        if (_delegate?._targetFirstChildPage != null) {
          tChildPageType = _delegate!._targetFirstChildPage!.pageType;
        } else {
          tChildPageType = tStandardPagesMap[_factory.pageType]!.first;
        }

        _delegate?._standardPageInterfaceToType[tStandardPageInterface]!
            .add(tChildPageType);

        _firstPageFactory = _delegate?._addChildFirstPage(
          tChildPageType,
          tStandardPageInterface,
        );
      }
    }
  }

  @protected
  void onInactive() {}

  @protected
  void onRefocus() {
    final tScrollController = PrimaryScrollController.of(context);

    if (tScrollController.hasClients == true) {
      for (var i in tScrollController.positions.where((e) => e.hasPixels)) {
        i.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    Widget tChild = Builder(builder: buildPage);

    final tPlugins = context
        .read<App>()
        .getPluginsOfType<StandardPagePluginMixin>()
        .where((v) => v.initialized && !v.disposed);

    for (var i in tPlugins) {
      tChild = _SingleChildPluginBuilder(
        plugin: i,
        child: tChild,
      );
    }

    final tAnalyticsEvent = analyticsSingletonEvent;

    if (tAnalyticsEvent != null) {
      tChild = AnalyticsSingletonEventWidget(
        event: tAnalyticsEvent,
        child: tChild,
      );
    }

    tChild = AnalyticsContextProvider(
      analyticsContext: _generateAnalyticsContext(),
      child: tChild,
    );

    tChild = Provider<StandardPageWithResult>.value(
      value: this,
      child: Provider<StandardPageWithResult<T, E>>.value(
        value: this,
        child: tChild,
      ),
    );

    if (this is StandardPage<T>) {
      tChild = Provider<StandardPage>.value(
        value: this as StandardPage,
        child: Provider<StandardPage<T>>.value(
          value: this as StandardPage<T>,
          child: tChild,
        ),
      );
    }

    // Build Child Navigator
    if (_firstPageFactory != null) {
      // Create a Navigator by referencing the parent page instance when _firstPageFactory exists
      final tParentPageInstance =
          ModalRoute.of(context)?.settings as StandardPageInterface;

      if (_pageChildInstances![tParentPageInstance] != null &&
          // Countermeasure for an error if the Navigator is empty when
          // proceeding from a page with child to a page without child
          _pageChildInstances![tParentPageInstance]!.isNotEmpty) {
        _navigator = Navigator(
          key: _childNavigatorKey,
          pages: _pageChildInstances![tParentPageInstance]!,
          // TODO: To be addressed in the future.
          // ignore: deprecated_member_use
          onPopPage: (route, result) {
            if (_delegate?.willPopPage != null) {
              if (_delegate!.willPopPage!(route, result)) {
                // We return false here because while a _pop_ was handled elsewhere,
                // it was not _this_ route whose pop is succeeding.
                return false;
              }
            }

            var tCurrentPage =
                _delegate?._pageChildInstances[tParentPageInstance]?.lastOrNull;
            if (tCurrentPage != null) {
              _delegate?._removePageChildInstance(
                  tParentPageInstance, tCurrentPage);
            }

            if (route.settings is StandardPageInterface) {
              return _delegate?.removeRoute(route, result) ?? false;
            }

            return false;
          },
        );

        _delegate?._pageChildInstancesUpdater[tParentPageInstance] = () {
          setState(() {});
        };
      }
    }

    return tChild;
  }

  @protected
  Widget buildPage(BuildContext context);
}

class _SingleChildPluginBuilder extends StatelessWidget {
  final StandardPagePluginMixin plugin;
  final Widget child;

  const _SingleChildPluginBuilder({
    required this.plugin,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => plugin.buildPage(context, child);
}

/// {@macro patapata_widgets.StandardPageWithResult}
abstract class StandardPage<T extends Object?>
    extends StandardPageWithResult<T, void> {}

/// A data class to be specified when implementing Patapata's [Router] using [StandardRouterDelegate].
class StandardRouteData {
  /// The factory class for [StandardPage].
  final StandardPageWithResultFactory? factory;

  /// The page data to be passed to [StandardPage].
  final Object? pageData;

  /// Create a StandardRouteData
  StandardRouteData({
    required this.factory,
    required this.pageData,
  });
}

/// A class that implements [RouteInformationParser] necessary for Patapata's [Router].
class StandardRouteInformationParser
    extends RouteInformationParser<StandardRouteData> {
  /// A handle to the location of a widget in the widget tree.
  final BuildContext context;

  /// Delegate for the standard router.
  final StandardRouterDelegate routerDelegate;

  /// Create a StandardRouteInformationParser
  StandardRouteInformationParser({
    required this.context,
    required this.routerDelegate,
  });

  @override
  Future<StandardRouteData> parseRouteInformation(
      RouteInformation routeInformation) async {
    final tApp = context.read<App>();
    final tPlugins = tApp.getPluginsOfType<StandardAppRoutePluginMixin>();

    for (var i in tPlugins) {
      final tParsed = await i.parseRouteInformation(routeInformation);

      if (tParsed != null) {
        return SynchronousFuture(tParsed);
      }
    }

    for (var i in tPlugins) {
      final tTransformed = await i.transformRouteInformation(routeInformation);

      if (tTransformed != null) {
        routeInformation = tTransformed;
      }
    }

    final tLocation = routeInformation.uri;
    final tStandardAppPlugin = tApp.getPlugin<StandardAppPlugin>();

    if (tStandardAppPlugin != null) {
      for (var i in tStandardAppPlugin._linkHandlers.values) {
        try {
          if (i(tLocation)) {
            // Handled. Return early.
            return SynchronousFuture(StandardRouteData(
              factory: null,
              pageData: null,
            ));
          }
        } catch (e, stackTrace) {
          _logger.severe('Error while handling link', e, stackTrace);
        }
      }
    }

    final tRouteData = routerDelegate._getStandardRouteDataForPath(tLocation) ??
        StandardRouteData(
          factory: null,
          pageData: null,
        );

    return SynchronousFuture(tRouteData);
  }

  @override
  RouteInformation? restoreRouteInformation(StandardRouteData configuration) {
    final tStringLocation = configuration.factory?.generateLink(
        configuration.pageData ??
            configuration.factory?.pageDataWhenNull?.call());

    if (tStringLocation != null) {
      final tLocation = Uri.tryParse(tStringLocation);

      if (tLocation != null) {
        return RouteInformation(
          uri: tLocation,
        );
      }
    }

    return null;
  }
}

/// A class that implements [RouterDelegate] required for Patapata's [Router].
class StandardRouterDelegate extends RouterDelegate<StandardRouteData>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  final _navigatorKey = GlobalKey<NavigatorState>(
      debugLabel: 'StandardRouterDelegate:navigatorKey');
  final _multiProviderKey =
      GlobalKey(debugLabel: 'StandardRouterDelegate:multiProviderKey');

  /// Navigator observer that notifies RouteAware of changes in route state.
  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  /// A handle to the location of a widget in the widget tree.
  final BuildContext context;
  List<Page> _pageInstances = [];
  final Map<StandardPageInterface, List<Page>> _pageChildInstances = {};

  /// Wrap the entire Patapata Navigator-related application,
  /// enabling the use of screen transition-related functionalities through a function.
  Widget Function(BuildContext context, Widget? child)? routableBuilder;

  /// A function called when the app goes back to the previous page.
  bool Function(Route<dynamic> route, dynamic result)? willPopPage;
  final Map<StandardPageInterface, List<Type>> _standardPageInterfaceToType =
      {};

  final _factoryTypeMap = <Type, StandardPageWithResultFactory>{};
  final _pageInstanceToTypeMap = <Page, Type>{};
  final _pageInstanceToRouteData = <Page, StandardRouteData>{};
  final _pageInstanceCompleterMap = <Page, Completer>{};

  StandardPageWithResultFactory get defaultRootPageFactory =>
      (_factoryTypeMap.entries
          .firstWhereOrNull((e) =>
              e.value.group == StandardPageWithResultFactory.defaultGroup)
          ?.value) ??
      _factoryTypeMap.values.first;

  bool _initialRouteProcessed = false;

  bool _startupSequenceProcessed = false;

  final Map<Type, List<Type>> _standardPagesMap = {};

  final Map<StandardPageInterface, VoidCallback> _pageChildInstancesUpdater =
      {};

  StandardPageWithResultFactory<StandardPageWithResult<Object?, Object?>,
      Object?, Object?>? _targetFirstChildPage;

  /// Create a StandardRouterDelegate
  StandardRouterDelegate({
    required this.context,
    required List<StandardPageWithResultFactory> pageFactories,
    this.routableBuilder,
    this.willPopPage,
  }) : assert(pageFactories.isNotEmpty) {
    _updatePageFactories(pageFactories);
  }

  void _updatePageFactories(List<StandardPageWithResultFactory> pageFactories) {
    // Remove the deleted page from the _factoryTypeMap Map variable during hot reloading
    _factoryTypeMap.clear();
    _standardPagesMap.clear();

    final tWithDummySplashPage =
        pageFactories.whereType<SplashPageFactory>().isEmpty;

    for (var tFactory in pageFactories) {
      tFactory._delegate = this;
      _factoryTypeMap[tFactory.pageType] = tFactory;
      // Create Standard Navigator Map
      if (tFactory.parentPageType == null &&
          !_standardPagesMap.containsKey(tFactory.pageType)) {
        _standardPagesMap[tFactory.pageType] = [];
      } else if (tFactory.parentPageType != null) {
        if (!_standardPagesMap.containsKey(tFactory.parentPageType)) {
          _standardPagesMap[tFactory.parentPageType!] = [];
        }
        _standardPagesMap[tFactory.parentPageType]!.add(tFactory.pageType);
      }
    }
    if (tWithDummySplashPage) {
      final tDummySplashPage = SplashPageFactory(
        create: (_) => _DummySplashPage(),
        enableNavigationAnalytics: false,
      ).._delegate = this;
      _factoryTypeMap[_DummySplashPage] = tDummySplashPage;
      _standardPagesMap[_DummySplashPage] = [];
    }

    if (_pageInstances.isNotEmpty) {
      for (var i in _pageInstanceToTypeMap.values) {
        if (!_factoryTypeMap.containsKey(i)) {
          // The page has been deleted.
          // Wipe out everything and start the app over.
          _pageInstances = [];
          _pageChildInstances.clear();
          _pageInstanceToTypeMap.clear();
          _pageInstanceToRouteData.clear();
          for (var i in _pageInstanceCompleterMap.values) {
            if (!i.isCompleted) {
              // Basically this only happens during development
              // so we will not have an official error code or class.
              i.completeError('Page deleted');
            }
          }
          _pageInstanceCompleterMap.clear();
          break;
        }
      }
    }

    if (_pageInstances.isEmpty) {
      final StandardPageWithResultFactory<
          StandardPageWithResult<Object?, Object?>,
          Object?,
          Object?> tStandardPage;

      if (!_initialRouteProcessed) {
        tStandardPage = (tWithDummySplashPage)
            ? _factoryTypeMap[_DummySplashPage]!
            : pageFactories.whereType<SplashPageFactory>().first;
      } else if (pageFactories.first.parentPageType == null) {
        tStandardPage = pageFactories.first;
      } else {
        // If the first page of pageFactories has a parentType set, the parent page will be added first.
        var tResult = pageFactories.where((element) =>
            element.pageType == pageFactories.first.parentPageType);
        tStandardPage = tResult.first;
      }

      final tPageData = tStandardPage.pageDataWhenNull?.call();

      final tPage = _initializePage(
        tStandardPage,
        tStandardPage.getPageKey(tPageData),
        tPageData,
      );

      _pageInstanceToTypeMap[tPage] = tStandardPage.pageType;
      _pageInstanceToRouteData[tPage] =
          StandardRouteData(factory: tStandardPage, pageData: tPageData);
      _pageInstanceCompleterMap[tPage] = tStandardPage._createResultCompleter();
      _pageInstances.add(tPage);
    }
  }

  Page _initializePage(StandardPageWithResultFactory factory, LocalKey pageKey,
      Object? pageData) {
    final tPage = factory._createPage(pageKey, pageData);

    if (factory.parentPageType == null) {
      _pageChildInstances[tPage] = [];
      if (_standardPageInterfaceToType[tPage] == null) {
        _standardPageInterfaceToType[tPage] = [];
      }
      _standardPageInterfaceToType[tPage]?.add(factory.pageType);
    }

    return tPage;
  }

  StandardPageWithResultFactory<T, R, E> _getFactory<
      T extends StandardPageWithResult<R, E>,
      R extends Object?,
      E extends Object?>() {
    final tFactory = _getFactoryFromPageType(T);

    assert(tFactory.dataType == R);

    return tFactory as StandardPageWithResultFactory<T, R, E>;
  }

  StandardPageWithResultFactory _getFactoryFromPageType(Type type) {
    final tFactory = _factoryTypeMap[type];

    assert(tFactory != null);

    return tFactory!;
  }

  /// {@template patapata_widgets.StandardRouteDelegate.pageInstances}
  /// The current [Page] history.
  /// {@endtemplate}
  List<Page<dynamic>> get pageInstances => _pageInstances.toList();

  /// {@template patapata_widgets.StandardRouteDelegate.getPageFactory}
  /// Get the factory class [StandardPageWithResultFactory] of [StandardPageWithResult].
  /// [T] is the type of the destination page. [R] is the type of page data. [E] is the data type of the value that the page returns.
  /// {@endtemplate}
  StandardPageWithResultFactory<T, R, E> getPageFactory<
          T extends StandardPageWithResult<R, E>,
          R extends Object?,
          E extends Object?>() =>
      _getFactory<T, R, E>();

  /// {@template patapata_widgets.StandardRouteDelegate.goWithResult}
  /// Navigate to the [StandardPageWithResult] of type [T] that returns a value, with the option to pass [pageData] during the navigation.
  /// [T] is the type of the destination page. [R] is the type of page data. [E] is the data type of the value that the page returns.
  /// [navigationMode] is optional and represents the mode of [StandardPageNavigationMode] to use during navigation.
  /// {@endtemplate}
  Future<E?> goWithResult<T extends StandardPageWithResult<R, E>,
          R extends Object?, E extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    return _goWithFactory<E>(_getFactory<T, R, E>(), pageData, navigationMode);
  }

  /// {@template patapata_widgets.StandardRouteDelegate.go}
  /// Navigate to the [StandardPage] of type [T] with the option to pass [pageData]
  /// during navigation.
  /// [T] represents the type of the destination page, and [R] signifies the type of page data.
  /// {@endtemplate}
  Future<void> go<T extends StandardPage<R>, R extends Object?>(R pageData,
      [StandardPageNavigationMode? navigationMode]) {
    return goWithResult<T, R, void>(pageData, navigationMode);
  }

  /// {@template patapata_widgets.StandardRouteDelegate.goErrorPage}
  /// Navigate to the error page with the option to pass an error log information [record].
  /// [record] represents the error log information of type [ReportRecord] to pass, and [navigationMode] signifies the optional mode of [StandardPageNavigationMode] to use during navigation.
  /// {@endtemplate}
  void goErrorPage(ReportRecord record,
      [StandardPageNavigationMode? navigationMode]) {
    final tFactory = _factoryTypeMap.values
        .whereType<StandardErrorPageFactory>()
        .firstOrNull;

    if (tFactory != null) {
      _goWithFactory<void>(tFactory, record, navigationMode);
    }
  }

  /// {@template patapata_widgets.StandardRouteDelegate.routeWithConfiguration}
  /// Takes `StandardRouteData` data and performs page navigation.
  /// This function is used when a reference to [context] is not available,
  /// for example, when navigating from a plugin.
  /// [configuration] represents the page data to be passed to [goWithResult],
  /// [navigationMode] is an optional mode of [StandardPageNavigationMode] to use during navigation.
  /// {@endtemplate}
  void routeWithConfiguration(StandardRouteData configuration,
      [StandardPageNavigationMode? navigationMode]) {
    configuration.factory?.goWithResult(configuration.pageData, navigationMode);
  }

  @override
  Widget build(BuildContext context) {
    Widget tChild = Navigator(
      key: _navigatorKey,
      restorationScopeId: 'StandardAppNavigator',
      observers: [
        ...context.read<App>().navigatorObservers,
        routeObserver,
      ],
      pages: _pageInstances,
      // TODO: To be addressed in the future.
      // ignore: deprecated_member_use
      onPopPage: _onPopPage,
    );

    if (routableBuilder != null) {
      tChild = Builder(
        builder:
            ((child) => (context) => routableBuilder!(context, child))(tChild),
      );
    }

    return MultiProvider(
      key: _multiProviderKey,
      providers: [
        Provider<RouteObserver<ModalRoute<void>>>.value(
          value: routeObserver,
        ),
        if (getApp().startupSequence != null)
          Provider(
            lazy: false,
            create: (context) {
              final tStartupSequence = getApp().startupSequence!;
              if (!_startupSequenceProcessed) {
                _startupSequenceProcessed = true;
                tStartupSequence.resetMachine();
              }
              return tStartupSequence;
            },
          ),
      ],
      child: tChild,
    );
  }

  void _updatePages() {
    _pageInstances = _pageInstances.toList();
    final tPageChildInstances = _pageChildInstances;
    for (var entry in tPageChildInstances.entries) {
      _pageChildInstances[entry.key] = _pageChildInstances[entry.key]!.toList();
    }
    notifyListeners();
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (willPopPage != null) {
      if (willPopPage!(route, result)) {
        // We return false here because while a _pop_ was handled elsewhere,
        // it was not _this_ route whose pop is succeeding.
        return false;
      }
    }

    if (route.settings is StandardPageInterface) {
      // Remove child navigator page from pageChildInstances only when swiping back
      var tParentType = _pageInstanceToTypeMap[route.settings];
      if (tParentType != null) {
        final tParentPageInstance = _getStandardPageInterface(tParentType);

        if (tParentPageInstance != null) {
          if (_pageChildInstances.containsKey(tParentPageInstance)) {
            _pageChildInstances[tParentPageInstance]!.clear();
          }

          _pageChildInstances.remove(tParentPageInstance);
          _standardPageInterfaceToType.remove(tParentPageInstance);
          _pageChildInstancesUpdater.remove(tParentPageInstance);
        }
      }

      return removeRoute(route, result);
    }

    return false;
  }

  /// {@template patapata_widgets.StandardRouteDelegate.removeRoute}
  /// Removes the provided [route] from the navigator and returns true if
  /// it is successfully removed, or false if not found.
  /// If the route is removed successfully, it will trigger [Route.didPop].
  /// [route] represents the removed [Route], and [result] signifies the result passed as an argument to [Route.didPop].
  /// {@endtemplate}
  bool removeRoute(Route<dynamic> route, dynamic result) {
    _pageInstances.remove(route.settings);
    _pageInstanceToTypeMap.remove(route.settings);
    _pageInstanceToRouteData.remove(route.settings);

    if (route.settings is StandardPageInterface) {
      final tState = (route.settings as StandardPageInterface)
          .standardPageKey
          .currentState;
      final tCompleter = _pageInstanceCompleterMap.remove(route.settings);

      if (tCompleter != null) {
        tState?._completeResult(tCompleter, result);
      }

      tState?._updateActiveStatus(false);
    }

    _updatePages();

    if (route.didPop(result)) {
      return true;
    }

    return false;
  }

  bool _continueProcessInitialRoute = false;

  /// {@template patapata_widgets.StandardRouteDelegate.processInitialRoute}
  /// Selects the initial page that the application should display and navigates to that page.
  /// If this initialization has already been performed, it does nothing.
  ///
  /// The priority of what page is shown is as follows:
  /// First, if there is a plugin in the [App] that returns data from getInitialRouteData, that data is used to navigate.
  /// Next, if there is a link that opened this application, that link is used.
  /// If there is no link that opened the application, a link with an empty string using [StandardPageFactory.new] in the [StandardMaterialApp.pages] array is searched for and navigated to.
  /// If neither of these conditions are met, the first page in the [StandardMaterialApp.pages] array with [StandardPageFactory.group] having [StandardPageWithResultFactory.defaultGroup] is displayed.
  /// In the case of Web, [WebPageNotFound] is thrown at this point.
  ///
  /// If no page can be found, the first page in [StandardMaterialApp.pages] is displayed.
  /// {@endtemplate}
  Future<void> processInitialRoute() async {
    if (_initialRouteProcessed) {
      return;
    }

    _initialRouteProcessed = true;
    _continueProcessInitialRoute = true;

    StandardRouteData? tInitialRouteData = _initialRouteData ??
        (await getApp().standardAppPlugin.parser?.parseRouteInformation(
            RouteInformation(uri: Uri(path: Navigator.defaultRouteName))));
    _initialRouteData = null;

    if (!_continueProcessInitialRoute) {
      return;
    }

    final tPlugins = _navigatorKey.currentContext
        ?.read<App>()
        .getPluginsOfType<StandardAppRoutePluginMixin>();

    if (tPlugins != null) {
      for (var i in tPlugins) {
        final tRouteData = await i.getInitialRouteData();

        if (!_continueProcessInitialRoute) {
          return;
        }

        if (tRouteData != null) {
          routeWithConfiguration(tRouteData);

          return;
        }
      }
    }

    if (tInitialRouteData?.factory == null) {
      if (kIsWeb || StandardAppPlugin.debugIsWeb) {
        throw WebPageNotFound();
      }

      final tFactory = defaultRootPageFactory;

      tInitialRouteData = StandardRouteData(
        factory: tFactory,
        pageData: tFactory.pageDataWhenNull?.call(),
      );
    }

    routeWithConfiguration(tInitialRouteData!);
  }

  StandardRouteData? _initialRouteData;

  @override
  Future<void> setNewRoutePath(StandardRouteData configuration) {
    if (!_initialRouteProcessed) {
      _initialRouteData = configuration;

      if (!_startupSequenceProcessed) {
        final tEnv = getApp().environment;
        final tAutoProcessInitialRoute = switch (tEnv) {
          StandardAppEnvironment() => tEnv.autoProcessInitialRoute,
          _ => true
        };
        if (tAutoProcessInitialRoute) {
          processInitialRoute();
        }
      }

      return SynchronousFuture(null);
    }

    routeWithConfiguration(configuration);

    return SynchronousFuture(null);
  }

  @override
  StandardRouteData? get currentConfiguration => _pageInstances.isEmpty
      ? null
      : _pageInstanceToRouteData[_pageInstances.last];

  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Retrieves the current `Navigator`.
  NavigatorState get navigator {
    assert(_navigatorKey.currentState != null,
        'Navigator does not exist yet. Wait for the first build to finish before using [navigator].');

    return _navigatorKey.currentState!;
  }

  /// Retrieves the `BuildContext` of the Navigator.
  BuildContext get navigatorContext {
    assert(_navigatorKey.currentContext != null,
        'Navigator does not exist yet. Wait for the first build to finish before using [navigatorContext].');

    return _navigatorKey.currentContext!;
  }

  StandardRouteData? _getStandardRouteDataForPath(Uri location) {
    for (var i in _factoryTypeMap.values) {
      for (var j in i._links.entries) {
        final tMatch = j.key.firstMatch(location.path);

        if (tMatch != null) {
          try {
            return StandardRouteData(
              factory: i,
              pageData: j.value(tMatch, location),
            );
          } catch (e, stackTrace) {
            _logger.info('Exception during links callback', e, stackTrace);
            // But ignore.
          }
        }
      }
    }

    return null;
  }

  Future<E?> _goWithFactory<E extends Object?>(
    StandardPageWithResultFactory factory,
    Object? pageData,
    StandardPageNavigationMode? navigationMode,
  ) {
    _continueProcessInitialRoute = false;

    StandardPageWithResultFactory tFactory = factory;

    var tCurrentPage = _pageInstances.lastOrNull;
    StandardPageWithResultFactory<StandardPageWithResult<Object?, Object?>,
        Object?, Object?>? tParentPageFactory;

    if (factory.parentPageType != null) {
      final tParentPageInstance =
          _getStandardPageInterface(factory.parentPageType!);
      if (tParentPageInstance == null) {
        tParentPageFactory = _getFactoryFromPageType(factory.parentPageType!);
        _targetFirstChildPage = factory;
      } else {
        _targetFirstChildPage = null;
      }
    } else {
      _targetFirstChildPage = null;
    }

    tFactory = tParentPageFactory ?? factory;

    void fCleanupPage(StandardPageInterface page) {
      final tCompleter = _pageInstanceCompleterMap.remove(page);
      final tState = page.standardPageKey.currentState;

      if (tCompleter != null) {
        tState?._completeResult(tCompleter, null);
      }

      tState?._updateActiveStatus(false);
    }

    void fRemoveLastPage() {
      final tPage = _pageInstances.removeLast();
      _pageInstanceToTypeMap.remove(tPage);
      _pageInstanceToRouteData.remove(tPage);
      fCleanupPage(tPage as StandardPageInterface);
    }

    if (tCurrentPage != null) {
      assert(_pageInstanceToTypeMap.containsKey(tCurrentPage));

      var tCurrentFactory =
          _getFactoryFromPageType(_pageInstanceToTypeMap[tCurrentPage]!);

      if (!tCurrentFactory.keepHistory) {
        fRemoveLastPage();
      }

      if (tFactory.group != null) {
        while (true) {
          tCurrentPage = _pageInstances.lastOrNull;

          if (tCurrentPage == null) {
            break;
          }

          assert(_pageInstanceToTypeMap.containsKey(tCurrentPage));

          tCurrentFactory =
              _getFactoryFromPageType(_pageInstanceToTypeMap[tCurrentPage]!);

          if (tCurrentFactory.group != null) {
            break;
          }
        }

        if (tCurrentPage != null && tCurrentFactory.group != tFactory.group) {
          // Different group than the current one.
          // Remove all history.
          var tReversedPageInstances = _pageInstances.reversed.toList();

          _pageInstanceToTypeMap.clear();
          _pageInstanceToRouteData.clear();
          _pageInstances.clear();
          for (var tPageInstance in tReversedPageInstances) {
            fCleanupPage(tPageInstance as StandardPageInterface);
          }
        }
      }
    }

    final tNavigationMode = navigationMode ?? tFactory.navigationMode;

    if (tNavigationMode == StandardPageNavigationMode.removeAll) {
      // Remove all history.
      var tReversedPageInstances = _pageInstances.reversed.toList();

      _pageInstanceToTypeMap.clear();
      _pageInstanceToRouteData.clear();
      _pageInstances.clear();
      for (var tPageInstance in tReversedPageInstances) {
        fCleanupPage(tPageInstance as StandardPageInterface);
      }
    } else if (tNavigationMode == StandardPageNavigationMode.replace) {
      fRemoveLastPage();
    }

    final tPageKey = tFactory.getPageKey(pageData);

    void fCheckGroupRoot() {
      if (!tFactory.groupRoot) {
        // Search to see if a group root exists and add it.
        final tGroup = tFactory.group;

        for (var i in _factoryTypeMap.entries) {
          final tGroupRootFactory = i.value;

          if (tGroupRootFactory.group == tGroup &&
              tGroupRootFactory.groupRoot) {
            // Found one. See if it's already in the history.
            if (!_pageInstanceToTypeMap.containsValue(i.key)) {
              // There isn't. So add it.
              final tGroupRootPageData =
                  tGroupRootFactory.pageDataWhenNull?.call();
              final tGroupRootPageKey =
                  tGroupRootFactory.getPageKey(tGroupRootPageData);
              final tGroupRootPage = _initializePage(
                  tGroupRootFactory, tGroupRootPageKey, tGroupRootPageData);

              _pageInstanceToTypeMap[tGroupRootPage] =
                  tGroupRootFactory.pageType;
              _pageInstanceToRouteData[tGroupRootPage] = StandardRouteData(
                factory: tGroupRootFactory,
                pageData: tGroupRootPageData,
              );
              _pageInstanceCompleterMap[tGroupRootPage] =
                  tGroupRootFactory._createResultCompleter();
              _pageInstances.insert(0, tGroupRootPage);
            }
          }
        }
      }
    }

    // First check to see if we already have this page's representation
    // in the history stack. If we do, modify the history stack and use the old instance.
    for (var i = 0, il = _pageInstances.length; i < il; i++) {
      if (_pageInstances[i].key == tPageKey) {
        switch (tNavigationMode) {
          case StandardPageNavigationMode.moveToTop:
          case StandardPageNavigationMode.replace:
            if (i == il - 1) {
              break;
            }

            final tLastPage = (_pageInstances.last as StandardPageInterface?)
                ?.standardPageKey
                .currentState;
            tLastPage?._updateActiveStatus(false);

            final tPageToMove = _pageInstances[i];

            // Shift all instances from this point to the left by one.
            // Ignore the last index as we just replace it
            for (var j = i; j < il - 1; j++) {
              _pageInstances[j] = _pageInstances[j + 1];
            }

            _pageInstances[il - 1] = tPageToMove;

            break;
          case StandardPageNavigationMode.removeAbove:
            for (var j = il - 1; j > i; j--) {
              fRemoveLastPage();
            }

            break;
          default:
            break;
        }

        final tLastPageInstance = _pageInstances.last;
        final tLastPage = (tLastPageInstance as StandardPageInterface?)
            ?.standardPageKey
            .currentState;

        bool tLastPageDataChanged = false;

        if (tLastPage != null) {
          if (tLastPage.pageData != pageData) {
            tLastPage.pageData = pageData;
            tLastPageDataChanged = true;
          }

          if (tLastPage.active) {
            tLastPage.onRefocus();
          } else {
            final tRoute = ModalRoute.of(tLastPage.context);

            if (tRoute != null) {
              tLastPage.context.read<Analytics>().routeViewEvent(
                    tRoute,
                    navigationType: AnalyticsNavigationType.push,
                  );
            }
            tLastPage._updateActiveStatus(true);
          }
        }

        fCheckGroupRoot();

        final tCompleter = _pageInstanceCompleterMap[tLastPageInstance]!;

        assert(
          tCompleter is Completer<E?>,
          'Same PageKey used for pages that have different return types.'
          'This is not allowed. PageKey: $tPageKey',
        );

        final tFuture = (tCompleter as Completer<E?>).future;

        if (tLastPageDataChanged) {
          _pageInstanceToRouteData[tLastPageInstance] = StandardRouteData(
            factory: tFactory,
            pageData: pageData,
          );
        }

        _updatePages();

        return tFuture;
      }
    }

    final tPage = _initializePage(tFactory, tPageKey, pageData);

    _pageInstanceToTypeMap[tPage] = tFactory.pageType;
    _pageInstanceToRouteData[tPage] = StandardRouteData(
      factory: tFactory,
      pageData: pageData,
    );
    final tResultCompleter = _pageInstanceCompleterMap[tPage] =
        tFactory._createResultCompleter() as Completer<E?>;

    if (factory.parentPageType == null ||
        (factory.parentPageType != null && tParentPageFactory != null)) {
      _pageInstances.add(tPage);
    } else {
      var tParentStandardPageInterface =
          _getStandardPageInterface(factory.parentPageType!);

      if (tParentStandardPageInterface != null) {
        _addPageChildInstance(tParentStandardPageInterface, tPage);

        if (_pageChildInstancesUpdater[tParentStandardPageInterface] != null) {
          _pageChildInstancesUpdater[tParentStandardPageInterface]!();
        }
      }
    }

    fCheckGroupRoot();

    _updatePages();

    return tResultCompleter.future;
  }

  void _addPageChildInstance(Page parentPage, Page page) {
    _pageChildInstances[parentPage]?.add(page);
  }

  void _removePageChildInstance(Page parentPage, Page page) {
    _pageChildInstances[parentPage]?.remove(page);
  }

  StandardPageInterface? _getStandardPageInterface(Type pageType) {
    // Check the page Type in _standardPageInterfaceToType
    // _addPageChildInstance under which parent entity the tPage
    // generated by _initializePage isdetermine whether to add
    final tStandardPageInterfaceToType = _standardPageInterfaceToType.entries
        .firstWhereOrNull((standardPageInterfaceToType) {
      final tResult = standardPageInterfaceToType.value
          .where((element) => element == pageType);
      return tResult.isNotEmpty;
    });

    if (tStandardPageInterfaceToType == null) {
      return null;
    }

    return tStandardPageInterfaceToType.key;
  }

  StandardPageWithResultFactory _addChildFirstPage(
    Type pageType,
    StandardPageInterface parentPageInstance,
  ) {
    final tFactory = _getFactoryFromPageType(pageType);
    final tPageData = tFactory.pageDataWhenNull?.call();
    final tPageKey = tFactory.getPageKey(tPageData);

    final tPage = _initializePage(tFactory, tPageKey, tPageData);

    _pageInstanceToTypeMap[tPage] = tFactory.pageType;
    _pageInstanceToRouteData[tPage] = StandardRouteData(
      factory: tFactory,
      pageData: tPageData,
    );
    _pageInstanceCompleterMap[tPage] = tFactory._createResultCompleter();

    // If the page to be added belongs to the parent Navigator, add it to _pageChildInstances
    if (_pageChildInstances.keys.contains(parentPageInstance)) {
      _addPageChildInstance(parentPageInstance, tPage);
    }

    return tFactory;
  }
}

class WebPageNotFound extends PatapataCoreException {
  WebPageNotFound() : super(code: PatapataCoreExceptionCode.PPE601);

  @override
  Level? get logLevel => Level.INFO;

  @override
  Level? get userLogLevel => Level.SHOUT;
}
