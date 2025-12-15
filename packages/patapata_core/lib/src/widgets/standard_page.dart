// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of "standard_app.dart";

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

typedef StandardPageBuilder<R, E> =
    StandardPageInterface<R, E> Function(
      Widget child,
      String? name,
      R pageData,
      LocalKey pageKey,
      String restorationId,
      GlobalKey<StandardPageWithResult<R, E>> standardPageKey,
      StandardPageWithResultFactory<StandardPageWithResult<R, E>, R, E>
      factoryObject,
    );

class _StandardPageFactoryExtendedData {
  final StandardRouterDelegate delegate;

  final StandardPageWithResultFactory? parentPageFactory;

  final StandardPageWithResultFactory? navigatorPageFactory;

  final bool anyNavigator;

  const _StandardPageFactoryExtendedData({
    required this.delegate,
    this.parentPageFactory,
    this.navigatorPageFactory,
    this.anyNavigator = false,
  });
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
base class StandardPageWithResultFactory<
  T extends StandardPageWithResult<R, E>,
  R extends Object?,
  E extends Object?
> {
  /// The default group name set when no group is specified for the page.
  static const String defaultGroup = 'StandardPageDefaultGroup';

  static final _extendedDataMap = Expando<_StandardPageFactoryExtendedData>();

  StandardRouterDelegate get _delegate => _extendedDataMap[this]!.delegate;

  /// The parent page factory of this page, if any.
  StandardPageWithResultFactory? get parentPageFactory =>
      _extendedDataMap[this]?.parentPageFactory;

  /// The navigator page factory of this page, if any.
  StandardPageWithResultFactory? get navigatorPageFactory =>
      _extendedDataMap[this]?.navigatorPageFactory;

  /// Add to the deepest navigator when there are multiple nested navigators.
  bool get anyNavigator => _extendedDataMap[this]?.anyNavigator ?? false;

  /// Creates the [T] page that this factory manages.
  final T Function(R pageData) create;
  final Map<String, R Function(RegExpMatch match, Uri uri)> _links;

  /// The function to create deep links for this page.
  ///
  /// This function generates a deep link path from the given `pageData`.
  /// The return value must match the keys (regular expressions) passed to `links` and their corresponding [R] pageData destinations.
  ///
  /// The generated link can be either an absolute path (starting with '/') or a relative path.
  /// When [generateLink] is used, it builds the complete deep link path by combining this function's return value with the parent page's path if the link is relative.
  ///
  /// See also:
  /// * [generateLink], which uses this function to build the complete deep link path.
  final String Function(R pageData)? linkGenerator;

  /// The group name used to manage multiple pages as part of the same group when they exist.
  final String? group;

  /// Flag indicating whether to set this page as the root group if a group name is specified.
  final bool groupRoot;

  /// Flag indicating whether to stack this page as part of the history or not.
  final bool keepHistory;

  /// Flag indicating whether to enable analytics for navigation.
  final bool enableNavigationAnalytics;

  /// The list of child pages that can be navigated to from this page.
  ///
  /// See also:
  /// [StandardChildPageWithResultFactory]
  final List<StandardChildPageWithResultFactory> childPageFactories;

  /// When using child pages, specifies how to create the parent page data from the page data of this page.
  ///
  /// See also:
  /// [StandardChildPageWithResultFactory]
  Object? createParentPageData(R pageData) => null;

  /// Flag indicating whether there are child pages that can be navigated to from this page.
  bool get hasChildPages => childPageFactories.isNotEmpty;

  /// The list of nested pages when using nested Navigators.
  ///
  /// See also:
  /// [StandardPageWithNestedNavigatorFactory]
  List<StandardPageWithResultFactory> get nestedPageFactories => const [];

  /// The list of nested pages that can be used in any nested Navigator.
  ///
  /// See also:
  /// [StandardPageWithNestedNavigatorFactory]
  List<StandardPageWithResultFactory> get anyNestedPageFactories => const [];

  /// Flag indicating whether the first page in [nestedPageFactories]
  /// should always be stacked as the first page of the nested Navigator.
  ///
  /// The default value is `true`.
  ///
  /// See also:
  /// [StandardPageWithNestedNavigatorFactory]
  bool get activeFirstNestedPage => true; // coverage:ignore-line

  /// Flag indicating whether there are nested pages.
  bool get hasNestedPages =>
      nestedPageFactories.isNotEmpty || anyNestedPageFactories.isNotEmpty;

  /// The method for transitioning to this page from other pages.
  /// Please refer to [StandardPageNavigationMode] for navigation modes.
  final StandardPageNavigationMode navigationMode;
  final LocalKey Function(R pageData)? _pageKey;

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
  final StandardPageBuilder<R, E>? pageBuilder;

  /// A function to generate a replacement value when the pageData passed during navigation is null.
  final R Function()? pageDataWhenNull;

  /// The name of this page.
  final String? Function()? pageName;

  /// A function for generating a value to pass to [Page.restorationId].
  final String Function(R pageData)? restorationId;

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
  /// [childPageFactories] is a list of child pages that can be navigated to from this page.
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
  const StandardPageWithResultFactory({
    required this.create,
    Map<String, R Function(RegExpMatch match, Uri uri)>? links,
    this.linkGenerator,
    this.groupRoot = false,
    this.group = defaultGroup,
    this.keepHistory = true,
    this.enableNavigationAnalytics = true,
    this.childPageFactories = const [],
    this.navigationMode = StandardPageNavigationMode.moveToTop,
    LocalKey Function(R pageData)? pageKey,
    this.pageBuilder,
    this.pageDataWhenNull,
    this.pageName,
    this.restorationId,
  }) : assert(
         (links == null && linkGenerator == null) ||
             (links != null && linkGenerator != null),
       ),
       _pageKey = pageKey,
       _links = links ?? const {};

  /// The page type of this page.
  Type get pageType => T;

  /// The data type of this page.
  Type get dataType => R;

  /// The result type of this page.
  Type get resultType => E;

  /// Flag indicating that the type of page data set for this page is nullable.
  bool get dataTypeIsNonNullable => <R>[] is List<Object>;

  /// Returns the deep link generated by this page for the given [pageData].
  ///
  /// If [linkGenerator] is not set, it returns null.
  ///
  /// If the [linkGenerator] is set and the generated link does not start with a '/',
  /// it recursively calls the [generateLink] method of the parent page factory to create a complete link.
  /// In this case, the [createParentPageData] method is used to generate the parent page data.
  String? generateLink(Object? pageData) {
    if (linkGenerator == null) {
      return null;
    }

    assert(
      pageData is R,
      'pageData must be of type $R, but got ${pageData.runtimeType}', // coverage:ignore-line
    );

    return _buildFullLinkPath(pageData as R);
  }

  String? _buildFullLinkPath(R pageData) {
    final String? tPath = (linkGenerator != null)
        ? linkGenerator!(pageData)
        : null;

    String? tParentPath;
    if (tPath == null || !tPath.startsWith('/')) {
      final tParentFactory = parentPageFactory ?? navigatorPageFactory;
      if (tParentFactory != null) {
        final tParentPageData = createParentPageData(pageData);
        tParentPath = tParentFactory._buildFullLinkPath(tParentPageData);
      }
    }

    return tParentPath != null
        ? tPath == null
              ? tParentPath
              : '${tParentPath == '/' ? '' : tParentPath}/$tPath'
        : tPath;
  }

  /// Navigate to the [StandardPage] of type [T] with the option to pass [pageData] during navigation.
  /// An optional [navigationMode] representing the mode of [StandardPageNavigationMode] to use during navigation can also be provided.
  /// [pushParentPage] indicates whether to push the parent page when navigating to a child page. default is `false`.
  Future<E?> goWithResult(
    R pageData, [
    StandardPageNavigationMode? navigationMode,
    bool pushParentPage = false,
  ]) =>
      _delegate.goWithResult<T, R, E>(pageData, navigationMode, pushParentPage);

  /// Get the key set for this page, as configured for this page.
  LocalKey getPageKey(Object? pageData) {
    final tPageData = pageData ?? pageDataWhenNull?.call();

    if (tPageData is R) {
      return (_pageKey ?? _defaultPageKey)(tPageData);
    }

    throw Never;
  }

  LocalKey _defaultPageKey(R pageData) =>
      ValueKey('${pageType.toString()}:${generateLink(pageData) ?? pageData}');

  String _defaultRestorationId(R pageData) =>
      '${pageType.toString()}:${generateLink(pageData) ?? pageData}';

  StandardPageInterface<R, E> _defaultMaterialPageBuilder(
    Widget child,
    String? name,
    Object? pageData,
    LocalKey pageKey,
    String restorationId,
    GlobalKey<StandardPageWithResult<R, E>> standardPageKey,
    StandardPageWithResultFactory<StandardPageWithResult<R, E>, R, E>
    factoryObject,
  ) => StandardMaterialPage<R, E>(
    child: child,
    name: name,
    arguments: pageData,
    key: pageKey,
    restorationId: restorationId,
    standardPageKey: standardPageKey,
    factoryObject: factoryObject,
  );

  StandardPageInterface<R, E> _defaultCupertinoPageBuilder(
    Widget child,
    String? name,
    Object? pageData,
    LocalKey pageKey,
    String restorationId,
    GlobalKey<StandardPageWithResult<R, E>> standardPageKey,
    StandardPageWithResultFactory<StandardPageWithResult<R, E>, R, E>
    factoryObject,
  ) => StandardCupertinoPage<R, E>(
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
    bool pushParentHistory,
    StandardAppType appType,
  ) {
    if (pageData == null && pageDataWhenNull != null) {
      pageData = pageDataWhenNull!();
    }

    final tGlobalKey = GlobalKey<StandardPageWithResult<R, E>>(
      debugLabel: pageName?.call() ?? T.toString(),
    );

    return (pageBuilder ??
        (appType == StandardAppType.cupertino
            ? _defaultCupertinoPageBuilder
            : _defaultMaterialPageBuilder))(
      _StandardPageWidget<R, E>(
        key: tGlobalKey,
        factoryObject: this,
        pageData: pageData,
        initPushParentHistory: pushParentHistory,
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

/// Factory class for [StandardPage] to be set in the `page` property of [StandardMaterialApp] or [StandardCupertinoApp].
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
/// [StandardChildPageFactory] can be used to define child pages that can be navigated to from this page.
///
/// [StandardPageWithNestedNavigatorFactory] can be used to define pages with nested Navigators.
/// This is useful, for example, when implementing applications with multiple footer menus.
base class StandardPageFactory<T extends StandardPage<R>, R extends Object?>
    extends StandardPageWithResultFactory<T, R, void> {
  /// Create a StandardPageFactory
  const StandardPageFactory({
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
    super.childPageFactories,
  });
}

/// A factory class for creating [StandardPageWithNestedNavigator] pages with nested Navigators.
///
/// Nested navigators are useful for implementing applications with multiple navigation contexts,
/// such as apps with footer menus where each tab maintains its own navigation stack.
///
/// This class can be added to the `pages` property of [StandardMaterialApp.new] or [StandardCupertinoApp.new].
/// [T] represents the type of the page that extends [StandardPageWithNestedNavigator].
///
/// ## Navigation
///
/// You can navigate to pages created by this factory using `context.go<PageA, void>(null)`.
/// When navigating to this page, if the nested page stack is empty, the first page from
/// [nestedPageFactories] will be automatically pushed onto the nested Navigator.
///
/// You can also navigate directly to nested pages using `context.go<NestedPageA, void>(null)`.
/// When navigating to a nested page, this parent page will also be pushed onto the navigation stack.
///
/// When nested pages are popped and the nested page stack becomes empty, this parent page
/// will also be automatically popped from the navigation stack.
///
/// ## Properties
///
/// The [nestedPageFactories] property defines the pages that will be displayed in each nested Navigator.
/// At least one page factory must be specified in [nestedPageFactories].
///
/// The [anyNestedPageFactories] property defines pages that can be used in any nested Navigator,
/// allowing shared pages across different navigation contexts.
/// When navigating to pages defined in [anyNestedPageFactories], the navigation is performed
/// against the currently active Navigator among the nested navigators.
/// Pages added by [anyNestedPageFactories] are independent for each Navigator, and will not be
/// moved to other Navigators by [StandardPageNavigationMode.moveToTop].
///
/// The [activeFirstNestedPage] property controls whether the first page in [nestedPageFactories]
/// is always stacked as the first page of the nested Navigator. The default value is `true`.
///
/// See also:
/// * [StandardPageWithNestedNavigator], which is the page class used with this factory.
///
/// example:
/// ```dart
/// StandardMaterialApp(
///   onGenerateTitle: (context) => 'sample',
///   pages: [
///     StandardPageWithNestedNavigatorFactory<PageA>(
///       create: (data) => PageA(),
///       nestedPageFactories: [
///         StandardPageFactory<NestedPageA, void>(
///           create: (data) => NestedPageA(),
///         ),
///         StandardPageFactory<NestedPageB, void>(
///           create: (data) => NestedPageB(),
///         ),
///       ],
///     ),
///   ],
/// );
///
/// class PageA extends StandardPageWithNestedNavigator {
///   @override
///   Widget buildPage(BuildContext context) {
///     return nestedPages;
///   }
/// }
///
/// class NestedPageA extends StandardPage<void> {
///   @override
///   Widget buildPage(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text('Nested Page A'),
///       ),
///       body: Text('Nested Page A Message'),
///     );
///   }
/// }
///
/// class NestedPageB extends StandardPage<void> {
///   @override
///   Widget buildPage(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text('Nested Page B'),
///       ),
///       body: Text('Nested Page B Message'),
///     );
///   }
/// }
/// ```
///
base class StandardPageWithNestedNavigatorFactory<
  T extends StandardPageWithNestedNavigator
>
    extends StandardPageWithResultFactory<T, void, void> {
  /// Create a StandardPageWithNestedNavigatorFactory.
  ///
  /// [create] is a required parameter. Pass a class that extends [StandardPageWithNestedNavigator] to this argument.
  ///
  /// [nestedPageFactories] is a required list of page factories that will be displayed in the nested Navigator.
  /// At least one page factory must be specified.
  ///
  /// [anyNestedPageFactories] is an optional list of page factories that can be used in any nested Navigator.
  ///
  /// [activeFirstNestedPage] controls whether the first page in [nestedPageFactories] should always be stacked
  /// as the first page of the nested Navigator. The default value is `true`.
  ///
  /// [links] and [linkGenerator] are optional parameters for deep linking support.
  ///
  /// [pageBuilder] is an optional function for customizing page creation.
  ///
  /// [pageName] is an optional function for specifying the page name.
  const StandardPageWithNestedNavigatorFactory({
    required super.create,
    required this.nestedPageFactories,
    this.anyNestedPageFactories = const [],
    this.activeFirstNestedPage = true,
    super.links,
    super.linkGenerator,
    super.pageBuilder,
    super.pageName,
  }) : assert(
         nestedPageFactories.length > 0,
         'At least one nestedPageFactory is required.',
       ),
       super(group: null);

  @override
  final List<StandardPageWithResultFactory> nestedPageFactories;

  @override
  final List<StandardPageWithResultFactory> anyNestedPageFactories;

  @override
  final bool activeFirstNestedPage;
}

/// A factory class for creating child pages of [StandardPageWithResult].
///
/// This class can be added to the `childPageFactories` property of [StandardPageWithResultFactory] or [StandardPageFactory].
/// [T] represents the data type of the destination page, [R] represents the data type of the page data,
/// [E] represents the data type of the value returned by the page, [P] represents the data type of the parent page data.
///
/// Child pages are designed to have a parent-child relationship with their parent page.
/// The [createParentPageData] function is required to generate the parent page data from the child page data,
/// which is used when navigating through the page hierarchy and building deep links.
///
/// When navigating to a child page using the `go` method, you can set the `pushParentPage` parameter to `true`
/// to automatically push the parent page onto the navigation stack before navigating to the child page.
/// This ensures that the parent page is included in the navigation history.
///
/// See also:
/// * [StandardChildPageFactory], which is a non-result-returning version of this class.
///
/// example:
/// ```dart
/// StandardMaterialApp(
///   onGenerateTitle: (context) => 'sample',
///   pages: [
///     StandardPageFactory<TestPageA, void>(
///       create: (data) => TestPageA(),
///       links: {
///         r'pageA': (match, uri) {},
///       },
///       linkGenerator: (pageData) => 'pageA',
///       childPageFactories: [
///         StandardChildPageWithResultFactory<TestPageB, String, Object, void>(
///           create: (data) => TestPageB(),
///           links: {
///             r'pageB': (match, uri) {
///               return 'pageData';
///             },
///           },
///           linkGenerator: (pageData) => 'pageB',
///           createParentPageData: (_) {},
///           childPageFactories: [
///             StandardChildPageWithResultFactory<TestPageC, String, Object, String>(
///               create: (data) => TestPageC(),
///               links: {
///                 r'pageC': (match, uri) {
///                   return 'childPageData';
///                 },
///               },
///               linkGenerator: (pageData) => 'pageC',
///               createParentPageData: (pageData) {
///                 return 'parentPageData';
///               },
///             ),
///           ],
///         ),
///       ],
///     ),
///   ],
/// );
/// ```
///
base class StandardChildPageWithResultFactory<
  T extends StandardPageWithResult<R, E>,
  R extends Object?,
  E extends Object?,
  P extends Object?
>
    extends StandardPageWithResultFactory<T, R, E> {
  /// Create a StandardChildPageWithResultFactory
  const StandardChildPageWithResultFactory({
    required super.create,
    required P Function(R pageData) createParentPageData,
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
    super.childPageFactories,
  }) : _createParentPageData = createParentPageData;

  final P Function(R pageData) _createParentPageData;

  @override
  P createParentPageData(R pageData) => _createParentPageData(pageData);
}

/// A factory class for creating child pages of [StandardPage].
///
/// This class can be added to the `childPageFactories` property of [StandardPageFactory] or [StandardPageWithResultFactory].
/// [T] represents the data type of the destination page, [R] represents the data type of the page data,
/// [P] represents the data type of the parent page data.
///
/// Child pages are designed to have a parent-child relationship with their parent page.
/// The [createParentPageData] function is required to generate the parent page data from the child page data,
/// which is used when navigating through the page hierarchy and building deep links.
///
/// When navigating to a child page using the `go` method, you can set the `pushParentPage` parameter to `true`
/// to automatically push the parent page onto the navigation stack before navigating to the child page.
/// This ensures that the parent page is included in the navigation history.
///
/// See also:
/// * [StandardChildPageWithResultFactory], which is a result-returning version of this class.
///
/// example:
/// ```dart
/// StandardMaterialApp(
///   onGenerateTitle: (context) => 'sample',
///   pages: [
///     StandardPageFactory<TestPageA, void>(
///       create: (data) => TestPageA(),
///       links: {
///         r'pageA': (match, uri) {},
///       },
///       linkGenerator: (pageData) => 'pageA',
///       childPageFactories: [
///         StandardChildPageFactory<TestPageB, String, void>(
///           create: (data) => TestPageB(),
///           links: {
///             r'pageB': (match, uri) {
///               return 'pageData';
///             },
///           },
///           linkGenerator: (pageData) => 'pageB',
///           createParentPageData: (_) {},
///           childPageFactories: [
///             StandardChildPageFactory<TestPageC, String, String>(
///               create: (data) => TestPageC(),
///               links: {
///                 r'pageC': (match, uri) {
///                   return 'childPageData';
///                 },
///               },
///               linkGenerator: (pageData) => 'pageC',
///               createParentPageData: (pageData) {
///                 return 'parentPageData';
///               },
///             ),
///           ],
///         ),
///       ],
///     ),
///   ],
/// );
/// ```
///
base class StandardChildPageFactory<
  T extends StandardPage<R>,
  R extends Object?,
  P extends Object?
>
    extends StandardChildPageWithResultFactory<T, R, void, P> {
  /// Create a StandardChildPageFactory
  const StandardChildPageFactory({
    required super.create,
    required super.createParentPageData,
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
    super.childPageFactories,
  });
}

/// This is a special factory class for creating a splash page after app launch,
/// and it is required to collaborate with the functionality of [StartupSequence].
base class SplashPageFactory<T extends StandardPage<void>>
    extends StandardPageFactory<T, void> {
  /// Create a SplashPageFactory
  const SplashPageFactory({
    required super.create,
    super.pageKey,
    super.pageBuilder,
    super.pageDataWhenNull,
    super.pageName,
    super.restorationId,
    super.enableNavigationAnalytics,
  }) : super(group: 'splash', keepHistory: false);
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
  }) : super(group: 'startup${group?.isNotEmpty == true ? '@$group' : ''}');
}

/// A special factory class for creating an error page that [PatapataException] can navigate to
/// if an error has a [PatapataException.userLogLevel] of [Level.SHOUT].
base class StandardErrorPageFactory<T extends StandardPage<ReportRecord>>
    extends StandardPageFactory<T, ReportRecord> {
  static const String errorGroup = 'error';

  /// Create a StandardErrorPageFactory
  const StandardErrorPageFactory({
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
abstract interface class StandardPageInterface<
  R extends Object?,
  E extends Object?
>
    extends Page<E> {
  /// The page key for the corresponding [StandardPageWithResult].
  GlobalKey<StandardPageWithResult<R, E>> get standardPageKey;

  /// The factory class that created this page.
  StandardPageWithResultFactory get factoryObject;
}

abstract class _BaseStandardPage<R extends Object?, E extends Object?>
    extends Page<E>
    implements StandardPageInterface<R, E> {
  @override
  final GlobalKey<StandardPageWithResult<R, E>> standardPageKey;

  @override
  final StandardPageWithResultFactory factoryObject;

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.PageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  /// {@macro flutter.widgets.TransitionRoute.allowSnapshotting}
  final bool allowSnapshotting;

  const _BaseStandardPage({
    super.key,
    super.name,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    super.arguments,
    super.restorationId,
    required this.standardPageKey,
    required this.factoryObject,
    required this.child,
  });
}

abstract class _BaseStandardPageRoute<R extends Object?, E extends Object?>
    extends PageRoute<E> {
  _BaseStandardPageRoute({
    required StandardPageInterface<R, E> page,
    super.allowSnapshotting,
  }) : super(settings: page) {
    assert(opaque);
  }

  @override
  void onPopInvokedWithResult(bool didPop, E? result) {
    super.onPopInvokedWithResult(didPop, result);

    getApp().standardAppPlugin.delegate?._onPopInvokedWithResult(
      this,
      didPop,
      result,
    );
  }

  @override
  bool get popGestureEnabled {
    final tDelegate = getApp().standardAppPlugin.delegate;

    return (tDelegate?._checkPopGestureEnabled(this) ?? true) &&
        super.popGestureEnabled;
  }
}

/// A [Page] implementation that creates a Material-styled route.
///
/// This class includes the [standardPageKey] property for accessing the page's key
/// and the [factoryObject] property for obtaining the factory that created this page.
///
/// [R] represents the type of page data.
/// [E] represents the type of the value that the page returns.
class StandardMaterialPage<R extends Object?, E extends Object?>
    extends _BaseStandardPage<R, E> {
  /// Create a StandardMaterialPage
  const StandardMaterialPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required super.standardPageKey,
    required super.factoryObject,
    required super.child,
  });

  @override
  Route<E> createRoute(BuildContext context) {
    return _StandardMaterialPageRoute<R, E>(
      page: this,
      allowSnapshotting: allowSnapshotting,
    );
  }
}

class _StandardMaterialPageRoute<R extends Object?, E extends Object?>
    extends _BaseStandardPageRoute<R, E>
    with MaterialRouteTransitionMixin<E> {
  _StandardMaterialPageRoute({
    required StandardMaterialPage<R, E> page,
    super.allowSnapshotting,
  }) : super(page: page);

  StandardMaterialPage<R, E> get _page =>
      settings as StandardMaterialPage<R, E>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

/// A [Page] implementation that creates a Cupertino-styled route.
///
/// This class includes the [standardPageKey] property for accessing the page's key
/// and the [factoryObject] property for obtaining the factory that created this page.
///
/// [R] represents the type of page data.
/// [E] represents the type of the value that the page returns.
class StandardCupertinoPage<R extends Object?, E extends Object?>
    extends _BaseStandardPage<R, E> {
  /// Create a StandardCupertinoPage
  const StandardCupertinoPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required super.standardPageKey,
    required super.factoryObject,
    required super.child,
    this.title,
  });

  /// {@macro flutter.cupertino.CupertinoRouteTransitionMixin.title}
  final String? title;

  @override
  Route<E> createRoute(BuildContext context) {
    return _StandardCupertinoPageRoute<R, E>(
      page: this,
      allowSnapshotting: allowSnapshotting,
    );
  }
}

class _StandardCupertinoPageRoute<R extends Object?, E extends Object?>
    extends _BaseStandardPageRoute<R, E>
    with CupertinoRouteTransitionMixin<E> {
  _StandardCupertinoPageRoute({
    required StandardCupertinoPage<R, E> page,
    super.allowSnapshotting = true,
  }) : super(page: page);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      fullscreenDialog ? null : CupertinoPageTransition.delegatedTransition;

  StandardCupertinoPage<R, E> get _page =>
      settings as StandardCupertinoPage<R, E>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  String? get title => _page.title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

/// Implements functionality to extend [Page] and create a customized [StandardPageWithResult].
///
/// This class includes the [standardPageKey] property for accessing the page's key
/// and the [factoryObject] property for obtaining the factory that created this page.
///
/// [R] represents the type of page data.
/// [E] represents the type of the value that the page returns.
class StandardCustomPage<R, E> extends Page<E>
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
  )?
  transitionBuilder;

  @override
  Route<E> createRoute(BuildContext context) {
    return _StandardCustomPageRoute<R, E>(page: this);
  }
}

class _StandardCustomPageRoute<R, E> extends ModalRoute<E> {
  _StandardCustomPageRoute({required StandardCustomPage<R, E> page})
    : super(settings: page);

  StandardCustomPage<R, E> get _page => settings as StandardCustomPage<R, E>;

  @override
  void onPopInvokedWithResult(bool didPop, E? result) {
    super.onPopInvokedWithResult(didPop, result);

    getApp().standardAppPlugin.delegate?._onPopInvokedWithResult(
      this,
      didPop,
      result,
    );
  }

  @override
  bool get popGestureEnabled {
    final tDelegate = getApp().standardAppPlugin.delegate;

    return (tDelegate?._checkPopGestureEnabled(this) ?? true) &&
        super.popGestureEnabled;
  }

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
      return tBuilder(context, animation, secondaryAnimation, child);
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

  final bool initPushParentHistory;

  const _StandardPageWidget({
    super.key,
    required this.factoryObject,
    required this.pageData,
    required this.initPushParentHistory,
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
    extends State<_StandardPageWidget<T, E>>
    with RouteAware {
  late StandardPageWithResultFactory<StandardPageWithResult<T, E>, T, E>
  _factory;

  late StandardRouterDelegate _delegate;

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

  bool _pushParentHistory = false;

  void _onPageDataChanged() {
    if (!mounted) {
      return;
    }

    if (!_ready) {
      _doPageDataChangedOnReady = true;

      return;
    }

    _sendPageDataEvent();
    getApp().standardAppPlugin.delegate?._updatePages();
    onPageData();
  }

  AnalyticsContext _generateAnalyticsContext() => AnalyticsContext({
    'pageName': name,
    'pageData': pageData,
    'pageLink': link,
    ...Analytics.tryConvertToLoggableJsonParameters('pageDataJson', pageData),
  });

  void _updateRouteAnalyticsContext() {
    context.read<Analytics>().setRouteContext(
      _kAnalyticsGlobalContextKey,
      _generateAnalyticsContext(),
    );
  }

  void _sendPageDataEvent() {
    _updateRouteAnalyticsContext();
    context.read<Analytics>().event(name: 'pageDataUpdate', context: context);
  }

  /// Called when the page data is updated.
  void onPageData() {}

  /// The name of this page.
  String get name => runtimeType.toString();

  /// Get the deep link for this page.
  /// Returns null if [StandardPageFactory.linkGenerator] is not defined for this page.
  String? get link => _factory.generateLink(pageData);

  RouteObserver<ModalRoute<void>>? _routeObserver;

  bool _ready = false;

  bool _firstActive = true;
  bool _active = false;

  /// A flag indicating whether this page is at the top of the history, i.e., whether it's the currently user-interacted page.
  bool get active => _active && mounted;

  @protected
  AnalyticsEvent? get analyticsSingletonEvent => null;

  /// Localization key for the page.
  ///
  /// Used to localize with [pl] or `context.pl`.
  /// Override this property if you want to localize.
  String get localizationKey => '';

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _pushParentHistory = widget.initPushParentHistory;
    _pageData = widget.pageData;
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();

    _ready = true;

    _delegate = context.read<StandardRouterDelegate>();
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

  void _updateActiveStatus({bool? forcedStatus, bool recursive = true}) {
    final tIsCurrentlyActive = _active;

    if (!mounted) {
      // Testing this case is difficult.
      _active = false; // coverage:ignore-line
    } else if (forcedStatus != null) {
      _active = forcedStatus;
    } else {
      final tRoute = ModalRoute.of(context);
      _active = tRoute?.isCurrent ?? false;
      if (_active) {
        StandardPageInterface? tNavigatorPage =
            _delegate._pageInstanceToNavigatorPage[tRoute!.settings];
        while (tNavigatorPage != null) {
          final tContext = tNavigatorPage.standardPageKey.currentContext;
          if (tContext == null) {
            // Testing this case is difficult.
            _active = false; // coverage:ignore-line
            break;
          }
          _active = ModalRoute.of(tContext)?.isCurrent ?? false;
          if (!_active) {
            break;
          }
          tNavigatorPage =
              _delegate._pageInstanceToNavigatorPage[tNavigatorPage];
        }
      }
    }

    if (_active != tIsCurrentlyActive) {
      void fUpdateNestedPageActiveStatus() {
        // If nested Navigators exist, the status of their subordinate pages will also be updated.
        final tPage = ModalRoute.of(context)?.settings;
        final tNestedPage = tPage != null
            ? _delegate._nestedPageInstances[tPage]?.lastOrNull
            : null;
        if (tNestedPage != null) {
          tNestedPage.standardPageKey.currentState?._updateActiveStatus(
            forcedStatus: forcedStatus,
            recursive: recursive,
          );
        }
      }

      if (_active) {
        _updateRouteAnalyticsContext();
        onActive(_firstActive);
        if (_firstActive) {
          _firstActive = false;
        }

        if (recursive && widget.factoryObject.hasNestedPages) {
          fUpdateNestedPageActiveStatus();
        }
      } else {
        if (recursive && widget.factoryObject.hasNestedPages) {
          fUpdateNestedPageActiveStatus();
        }

        onInactive();
      }
    }
  }

  @protected
  @mustCallSuper
  void onActive(bool first) {
    if (_pushParentHistory && widget.factoryObject.parentPageFactory != null) {
      var tStandardPageInterface =
          ModalRoute.of(context)?.settings as StandardPageInterface;

      scheduleFunction(() {
        _delegate._pushParentPageHistory(tStandardPageInterface);
      });
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

  /// {@template patapata_widgets.StandardPageWithResult.pl}
  /// Calls [l] with the specified [localizationKey].
  ///
  /// For example, if [localizationKey] is `pages.home` and [key] is `title`, it is localized as `pages.home.title`.
  /// An assertion error occurs if [localizationKey] is not set.
  /// {@endtemplate}
  @protected
  String pl(String key, [Map<String, Object>? namedParameters]) {
    assert(
      localizationKey.isNotEmpty,
      'localizationKey is not set. Please override localizationKey.',
    );

    return l(context, '$localizationKey.$key', namedParameters);
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
      tChild = _SingleChildPluginBuilder(plugin: i, child: tChild);
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

    return tChild;
  }

  /// Describe the user interface for this [StandardPage]
  /// The regular build method should generally not be used.
  ///
  /// The context passed to this method is wrapped with a [Builder] from the [StandardPage]'s context.
  @protected
  Widget buildPage(BuildContext context);
}

class _SingleChildPluginBuilder extends StatelessWidget {
  final StandardPagePluginMixin plugin;
  final Widget child;

  const _SingleChildPluginBuilder({required this.plugin, required this.child});

  @override
  Widget build(BuildContext context) => plugin.buildPage(context, child);
}

/// {@macro patapata_widgets.StandardPageWithResult}
abstract class StandardPage<T extends Object?>
    extends StandardPageWithResult<T, void> {}

/// This class is used to create pages that return values when building an application with Patapata.
///
/// Define page classes that inherit from this class and pass them to [StandardPageWithNestedNavigatorFactory].
/// Pages created with [StandardPageWithNestedNavigator] must override [buildPage].
///
/// This class is used to create pages that contain a nested Navigator.
/// The nested Navigator manages its own stack of pages independently from the parent Navigator.
///
/// The [nestedPages] property provides access to the Widget containing the nested Navigator
/// and its page stack. This widget should be included in the [buildPage] method to display
/// the nested navigation structure.
abstract class StandardPageWithNestedNavigator extends StandardPage<void> {
  final nestedNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'StandardPageWithNestedNavigator:nestedNavigatorKey',
  );

  late Widget _nestedPages;

  /// The nested pages managed by the nested Navigator.
  ///
  /// This widget contains the nested Navigator and should be included in your page's widget tree
  /// to display the nested navigation stack. The pages displayed in this Navigator are defined
  /// by the [StandardPageWithNestedNavigatorFactory.nestedPageFactories] and
  /// [StandardPageWithNestedNavigatorFactory.anyNestedPageFactories] properties.
  Widget get nestedPages => _nestedPages;

  final _nestedPageRouteObserver = RouteObserver<ModalRoute<void>>();

  List<StandardPageInterface> _pageInstances = const [];

  void _onNestedNavigatorPopHandler(Object? result) {
    nestedNavigatorKey.currentState?.maybePop(result);
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    _nestedPages = Builder(
      builder: (context) {
        final tPage = ModalRoute.of(context)?.settings as StandardPageInterface;
        final tDelegate = context.watch<StandardRouterDelegate>();

        final tPageInstances = tDelegate._nestedPageInstances[tPage];
        // Update the page instances.
        //
        // Do not update when the list is empty, as Navigator cannot handle an empty page list.
        // This situation occurs when the parent Navigator has been popped.
        if (tPageInstances?.isNotEmpty == true) {
          // Flutter's Navigator detects a change in the page stack when the reference to the List<Page> changes.
          // Therefore, instead of mutating the list, we must assign a new List instance.
          _pageInstances = tPageInstances!.toList();
        }

        return Provider<RouteObserver<ModalRoute<void>>>.value(
          value: _nestedPageRouteObserver,
          child: NavigatorPopHandler(
            onPopWithResult: _onNestedNavigatorPopHandler,
            child: Navigator(
              key: nestedNavigatorKey,
              pages: _pageInstances,
              observers: [
                ...getApp().navigatorObservers,
                _nestedPageRouteObserver,
              ],
              onDidRemovePage: _delegate._onDidRemovePage,
            ),
          ),
        );
      },
    );

    return super.build(context);
  }
}

/// A data class to be specified when implementing Patapata's [Router] using [StandardRouterDelegate].
class StandardRouteData {
  /// The factory class for [StandardPage].
  final StandardPageWithResultFactory? factory;

  /// The page data to be passed to [StandardPage].
  final Object? pageData;

  /// Create a StandardRouteData
  StandardRouteData({required this.factory, required this.pageData});
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
    RouteInformation routeInformation,
  ) async {
    final tApp = context.read<App>();
    final tPlugins = tApp.getPluginsOfType<StandardAppRoutePluginMixin>();

    for (var i in tPlugins) {
      final tParsed = await i.parseRouteInformation(routeInformation);

      if (tParsed != null) {
        return tParsed;
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
            return StandardRouteData(factory: null, pageData: null);
          }
        } catch (e, stackTrace) {
          _logger.severe('Error while handling link', e, stackTrace);
        }
      }
    }

    final tRouteData =
        routerDelegate._getStandardRouteDataForPath(tLocation) ??
        StandardRouteData(factory: null, pageData: null);

    return tRouteData;
  }

  @override
  RouteInformation? restoreRouteInformation(StandardRouteData configuration) {
    final tStringLocation = configuration.factory?.generateLink(
      configuration.pageData ?? configuration.factory?.pageDataWhenNull?.call(),
    );

    if (tStringLocation != null) {
      final tLocation = Uri.tryParse(
        tStringLocation.startsWith('/') ? tStringLocation : '/$tStringLocation',
      );

      if (tLocation != null) {
        return RouteInformation(uri: tLocation);
      }
    }

    return null;
  }
}

/// A class that implements [RouterDelegate] required for Patapata's [Router].
class StandardRouterDelegate extends RouterDelegate<StandardRouteData>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  final _navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'StandardRouterDelegate:navigatorKey',
  );
  final _multiProviderKey = GlobalKey(
    debugLabel: 'StandardRouterDelegate:multiProviderKey',
  );

  /// Navigator observer that notifies RouteAware of changes in route state.
  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  late final _RootNavigatorObserver _rootNavigatorObserver =
      _RootNavigatorObserver(this);

  /// A handle to the location of a widget in the widget tree.
  final BuildContext context;

  final StandardAppType _appType;

  List<StandardPageInterface> _rootPageInstances = [];
  final Map<StandardPageInterface, List<StandardPageInterface>>
  _nestedPageInstances = {};

  final _pageInstanceToRouteData = <StandardPageInterface, StandardRouteData>{};
  final _pageInstanceCompleterMap = <StandardPageInterface, Completer>{};
  final _pageInstanceToNavigatorPage =
      <StandardPageInterface, StandardPageInterface?>{};
  final _pageInstanceToPageType = <StandardPageInterface, Type>{};

  /// Wrap the entire Patapata Navigator-related application,
  /// enabling the use of screen transition-related functionalities through a function.
  Widget Function(BuildContext context, Widget? child)? routableBuilder;

  /// A function called when a page is removed from the navigator.
  void Function(Page page)? onDidRemovePage;

  final _factoryTypeMap = <Type, StandardPageWithResultFactory>{};
  final _links = Expando<List<(RegExp, Object? Function(RegExpMatch, Uri))>>();

  /// Get the default root page factory.
  StandardPageWithResultFactory get defaultRootPageFactory =>
      (_factoryTypeMap.entries
          .firstWhereOrNull(
            (e) => e.value.group == StandardPageWithResultFactory.defaultGroup,
          )
          ?.value) ??
      _factoryTypeMap.values.first;

  bool _initialRouteProcessed = false;

  bool _continueProcessInitialRoute = false;

  bool _startupSequenceProcessed = false;

  /// Create a StandardRouterDelegate
  StandardRouterDelegate({
    required this.context,
    required List<StandardPageWithResultFactory> pageFactories,
    StandardAppType appType = StandardAppType.material,
    this.routableBuilder,
    this.onDidRemovePage,
  }) : _appType = appType,
       assert(pageFactories.isNotEmpty) {
    _updatePageFactories(pageFactories);
  }

  void _updatePageFactories(List<StandardPageWithResultFactory> pageFactories) {
    void fMappedPageFactory(
      StandardPageWithResultFactory factory,
      StandardPageWithResultFactory? parentPageFactory,
      StandardPageWithResultFactory? navigatorPageFactory,
      bool anyNavigator,
      List<String> parentPathList,
    ) {
      assert(
        _factoryTypeMap.containsKey(factory.pageType) == false,
        'Duplicate pageType found: ${factory.pageType}. Each pageType must be unique.', // coverage:ignore-line
      );

      StandardPageWithResultFactory._extendedDataMap[factory] =
          _StandardPageFactoryExtendedData(
            delegate: this,
            parentPageFactory: parentPageFactory,
            navigatorPageFactory: navigatorPageFactory,
            anyNavigator: anyNavigator,
          );

      _factoryTypeMap[factory.pageType] = factory;

      Map<String, String> tLinkMap = {};
      if (factory._links.isNotEmpty) {
        final tLinks = factory._links.keys;
        if (parentPathList.isNotEmpty) {
          final tAbsoluteLinks = tLinks.where((e) => e.startsWith('/'));
          for (var tLink in tAbsoluteLinks) {
            tLinkMap[tLink] = tLink;
          }

          final tRelativeLinks = tLinks.where((e) => !e.startsWith('/'));
          for (var tParentPath in parentPathList) {
            for (var tLink in tRelativeLinks) {
              tLinkMap[tLink] =
                  '${tParentPath == '/' ? '' : tParentPath}/$tLink';
            }
          }
        } else {
          for (var tLink in tLinks) {
            tLinkMap[tLink] = tLink;
          }
        }

        final tCallbackList = <(RegExp, Object? Function(RegExpMatch, Uri))>[];
        for (var tLink in tLinkMap.entries) {
          final tRegExp = RegExp(
            '^/?${tLink.value.startsWith('/') ? tLink.value.substring(1) : tLink.value}\$',
          );
          tCallbackList.add((tRegExp, factory._links[tLink.key]!));
        }
        _links[factory] = tCallbackList;
      }

      for (var childPageFactory in factory.childPageFactories) {
        fMappedPageFactory(
          childPageFactory,
          factory,
          navigatorPageFactory,
          anyNavigator,
          (tLinkMap.isNotEmpty) ? tLinkMap.values.toList() : parentPathList,
        );
      }
      for (var nestedPageFactories in factory.nestedPageFactories) {
        fMappedPageFactory(
          nestedPageFactories,
          null,
          factory,
          false,
          (tLinkMap.isNotEmpty) ? tLinkMap.values.toList() : parentPathList,
        );
      }
      for (var anyNestedPageFactories in factory.anyNestedPageFactories) {
        fMappedPageFactory(
          anyNestedPageFactories,
          null,
          factory,
          true,
          (tLinkMap.isNotEmpty) ? tLinkMap.values.toList() : parentPathList,
        );
      }
    }

    // Remove the deleted page from the _factoryTypeMap Map variable during hot reloading
    _factoryTypeMap.clear();

    for (var i in pageFactories) {
      fMappedPageFactory(i, null, null, false, const []);
    }

    final tWithDummySplashPage =
        _factoryTypeMap.values.whereType<SplashPageFactory>().firstOrNull ==
        null;

    if (tWithDummySplashPage) {
      final tDummySplashPageFactory = SplashPageFactory(
        create: (_) => _DummySplashPage(),
        enableNavigationAnalytics: false,
      );
      StandardPageWithResultFactory._extendedDataMap[tDummySplashPageFactory] =
          _StandardPageFactoryExtendedData(delegate: this);
      _factoryTypeMap[tDummySplashPageFactory.pageType] =
          tDummySplashPageFactory;
    }

    if (_rootPageInstances.isNotEmpty) {
      final tDeletedPage = _pageInstanceToPageType.entries.firstWhereOrNull(
        (entry) => !_factoryTypeMap.containsKey(entry.value),
      );

      if (tDeletedPage != null) {
        // The page has been deleted.
        // Wipe out everything and start the app over.
        _rootPageInstances = [];
        _nestedPageInstances.clear();
        _pageInstanceToRouteData.clear();
        _pageInstanceToNavigatorPage.clear();
        _pageInstanceToPageType.clear();
        for (var i in _pageInstanceCompleterMap.values) {
          if (!i.isCompleted) {
            // Basically this only happens during development
            // so we will not have an official error code or class.
            i.completeError('Page deleted');
          }
        }
        _pageInstanceCompleterMap.clear();
      }
    }

    if (_rootPageInstances.isEmpty) {
      final tRouteDatas = <StandardRouteData>[];

      StandardPageWithResultFactory? tRootPageFactory =
          (!_initialRouteProcessed)
          ? _factoryTypeMap.values.whereType<SplashPageFactory>().first
          : defaultRootPageFactory;
      Object? tRootPageData = tRootPageFactory.pageDataWhenNull?.call();

      final tNavigatorHierarchy = _getNavigatorHierarchy(tRootPageFactory);

      for (var tFactory in tNavigatorHierarchy) {
        tRouteDatas.add(StandardRouteData(factory: tFactory, pageData: null));
      }

      tRouteDatas.add(
        StandardRouteData(factory: tRootPageFactory, pageData: tRootPageData),
      );

      for (var tRouteData in tRouteDatas) {
        final tPage = _initializePage(tRouteData, true);
        _pushPageInstance(tPage, tRouteData);
      }
    }
  }

  void _pushPageInstance(
    StandardPageInterface page,
    StandardRouteData routeData, [
    int? index,
  ]) {
    final tFactory = page.factoryObject;
    final tNavigatorPageFactory = tFactory.navigatorPageFactory;

    if (tNavigatorPageFactory != null) {
      final StandardPageInterface tNavigatorPage;
      if (tFactory.anyNavigator) {
        StandardPageInterface tBaseNavigatorPage = _pageInstanceToPageType
            .entries
            .firstWhere(
              (entry) => entry.value == tNavigatorPageFactory.pageType,
            )
            .key;
        StandardPageInterface? tLastPage =
            _nestedPageInstances[tBaseNavigatorPage]?.lastOrNull;
        while (tLastPage != null && tLastPage.factoryObject.hasNestedPages) {
          tBaseNavigatorPage = tLastPage;
          tLastPage = _nestedPageInstances[tLastPage]?.lastOrNull;
        }

        tNavigatorPage = tBaseNavigatorPage;
      } else {
        tNavigatorPage = _pageInstanceToPageType.entries
            .firstWhere(
              (entry) => entry.value == tNavigatorPageFactory.pageType,
            )
            .key;
      }

      assert(_nestedPageInstances.containsKey(tNavigatorPage));

      if (index != null) {
        _nestedPageInstances[tNavigatorPage]!.insert(index, page);
      } else {
        _nestedPageInstances[tNavigatorPage]!.add(page);
      }
      _pageInstanceToNavigatorPage[page] = tNavigatorPage;
    } else {
      if (index != null) {
        _rootPageInstances.insert(index, page);
      } else {
        _rootPageInstances.add(page);
      }
      _pageInstanceToNavigatorPage[page] = null;
    }

    if (tFactory.hasNestedPages) {
      _nestedPageInstances.putIfAbsent(page, () => []);
    }

    _pageInstanceToPageType[page] = tFactory.pageType;
    _pageInstanceToRouteData[page] = routeData;
    _pageInstanceCompleterMap[page] = tFactory._createResultCompleter();
  }

  void _checkDefaultNestedPage(StandardPageInterface navigatorPage) {
    assert(_nestedPageInstances[navigatorPage] != null);

    final tPageInstances = _nestedPageInstances[navigatorPage]!;

    if (tPageInstances.length <= 1) {
      final tDefaultFirstPageFactory =
          navigatorPage.factoryObject.nestedPageFactories.first;

      if (tPageInstances.isEmpty) {
        // Add the default nested page if there is no nested page.
        final tPageData = tDefaultFirstPageFactory.pageDataWhenNull?.call();
        final tRouteData = StandardRouteData(
          factory: tDefaultFirstPageFactory,
          pageData: tPageData,
        );
        final tPage = _initializePage(tRouteData);
        _pushPageInstance(tPage, tRouteData);

        if (tPage.factoryObject.hasNestedPages) {
          _checkDefaultNestedPage(tPage);
        }
      } else if (navigatorPage.factoryObject.activeFirstNestedPage) {
        // Ensure that the first nested page is the default one.
        final tFirstPage = tPageInstances.first;
        final tDefaultFirstPageData = tDefaultFirstPageFactory.pageDataWhenNull
            ?.call(); // coverage:ignore-line
        if (_pageInstanceToPageType[tFirstPage] !=
                tDefaultFirstPageFactory.pageType &&
            tFirstPage.key !=
                tDefaultFirstPageFactory.getPageKey(tDefaultFirstPageData)) {
          final tRouteData = StandardRouteData(
            factory: tDefaultFirstPageFactory,
            pageData: tDefaultFirstPageData,
          );
          final tPage = _initializePage(tRouteData);
          _pushPageInstance(tPage, tRouteData, 0);

          if (tPage.factoryObject.hasNestedPages) {
            _checkDefaultNestedPage(tPage);
          }
        }
      }
    }
  }

  void _pushParentPageHistory(StandardPageInterface page) {
    final tParentFactory = page.factoryObject.parentPageFactory;
    if (tParentFactory == null) {
      return;
    }

    final Object? tParentPageData;
    if (page.standardPageKey.currentState != null) {
      tParentPageData =
          page.factoryObject.createParentPageData(
            page.standardPageKey.currentState?.pageData,
          ) ??
          tParentFactory.pageDataWhenNull?.call();
    } else {
      final tPageRoute = _pageInstanceToRouteData[page];
      tParentPageData =
          page.factoryObject.createParentPageData(tPageRoute?.pageData) ??
          tParentFactory.pageDataWhenNull?.call();
    }
    final tParentPageKey = tParentFactory.getPageKey(tParentPageData);

    final tNavigatorPage = _pageInstanceToNavigatorPage[page];

    assert(
      tNavigatorPage == null ||
          _nestedPageInstances.containsKey(tNavigatorPage),
    );

    final tPageInstances = (tNavigatorPage != null)
        ? _nestedPageInstances[tNavigatorPage]!
        : _rootPageInstances;
    final tPageIndex = tPageInstances.indexOf(page);

    assert(tPageIndex > -1);

    if (tPageIndex > 0) {
      final tPrevPage = tPageInstances[tPageIndex - 1];
      if (tPrevPage.factoryObject.pageType == tParentFactory.pageType ||
          tPrevPage.key == tParentPageKey) {
        // The parent page is already the previous page.
        tPrevPage.standardPageKey.currentState?._pushParentHistory = true;
        _pushParentPageHistory(tPrevPage);
        return;
      }
    }

    for (var i = tPageInstances.length - 1; i >= 0; i--) {
      final tExistingPage = tPageInstances[i];
      if (tExistingPage.key == tParentPageKey) {
        tPageInstances.removeAt(i);
        final tIndex = tPageInstances.indexOf(page);
        tPageInstances.insert(tIndex, tExistingPage);

        tExistingPage.standardPageKey.currentState?._pushParentHistory = true;
        tExistingPage.standardPageKey.currentState?._updateActiveStatus(
          forcedStatus: false,
        );

        _updatePages();

        _pushParentPageHistory(tExistingPage);
        return;
      }
    }

    final tParentRouteData = StandardRouteData(
      factory: tParentFactory,
      pageData: tParentPageData,
    );

    final tParentPage = _initializePage(tParentRouteData, true);
    _pushPageInstance(tParentPage, tParentRouteData, tPageIndex);

    _updatePages();

    _pushParentPageHistory(tParentPage);
  }

  void _checkGroupRoot(StandardPageInterface page) {
    final tFactory = page.factoryObject;

    if (!tFactory.groupRoot && tFactory.group != null) {
      // Search to see if a group root exists and add it.
      final tGroup = tFactory.group;

      for (var i in _factoryTypeMap.entries) {
        final tGroupRootFactory = i.value;

        if (tGroupRootFactory.group == tGroup && tGroupRootFactory.groupRoot) {
          // Found one. See if it's already in the history.
          if (!_pageInstanceToPageType.containsValue(i.key)) {
            // There isn't. So add it.
            final tNavigatorHierarchy = _getNavigatorHierarchy(
              tGroupRootFactory,
            );
            for (var tNavigatorFactory in tNavigatorHierarchy) {
              if (!_pageInstanceToPageType.containsValue(
                tNavigatorFactory.pageType,
              )) {
                final tRouteData = StandardRouteData(
                  factory: tNavigatorFactory,
                  pageData: null,
                );
                final tPage = _initializePage(tRouteData);
                _pushPageInstance(tPage, tRouteData, 0);
              }
            }

            final tGroupRootPageData = tGroupRootFactory.pageDataWhenNull
                ?.call(); // coverage:ignore-line
            final tGroupRootRouteData = StandardRouteData(
              factory: tGroupRootFactory,
              pageData: tGroupRootPageData,
            );
            final tGroupRootPage = _initializePage(tGroupRootRouteData);
            _pushPageInstance(tGroupRootPage, tGroupRootRouteData, 0);
          }
        }
      }
    }
  }

  StandardPageInterface _initializePage(
    StandardRouteData routeData, [
    bool pushParentHistory = false,
  ]) {
    assert(routeData.factory != null);

    final tFactory = routeData.factory!;
    final tPageData = routeData.pageData;
    final tPageKey = tFactory.getPageKey(tPageData);

    return routeData.factory!._createPage(
      tPageKey,
      tPageData,
      pushParentHistory,
      _appType,
    );
  }

  StandardPageWithResultFactory<T, R, E> _getFactory<
    T extends StandardPageWithResult<R, E>,
    R extends Object?,
    E extends Object?
  >() {
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
  ///
  /// Returns a flattened list of all [Page] instances, including both root pages
  /// and nested pages within nested navigators, collected recursively in order of addition.
  /// {@endtemplate}
  List<StandardPageInterface> get pageInstances {
    final tInstances = <StandardPageInterface>[];

    void fPushNestedPages(StandardPageInterface page) {
      tInstances.add(page);

      final tNestedPages = _nestedPageInstances[page];
      if (tNestedPages != null) {
        for (var i in tNestedPages) {
          fPushNestedPages(i);
        }
      }
    }

    for (var i in _rootPageInstances) {
      fPushNestedPages(i);
    }

    return tInstances;
  }

  /// {@template patapata_widgets.StandardRouteDelegate.rootPageInstances}
  /// The root Navigator's current page instances.
  /// {@endtemplate}
  List<StandardPageInterface> get rootPageInstances =>
      List<StandardPageInterface>.from(_rootPageInstances);

  /// {@template patapata_widgets.StandardRouteDelegate.nestedPageInstances}
  /// The current nested page instances within each navigator.
  ///
  /// Returns a map where each key is a [StandardPageInterface] representing a navigator page,
  /// and the corresponding value is a list of [StandardPageInterface] instances that are nested within that navigator.
  /// {@endtemplate}
  Map<StandardPageInterface, List<StandardPageInterface>>
  get nestedPageInstances =>
      Map<StandardPageInterface, List<StandardPageInterface>>.fromEntries(
        _nestedPageInstances.entries.map(
          (e) => MapEntry<StandardPageInterface, List<StandardPageInterface>>(
            e.key,
            List<StandardPageInterface>.from(e.value),
          ),
        ),
      );

  /// {@template patapata_widgets.StandardRouteDelegate.getPageFactory}
  /// Get the factory class [StandardPageWithResultFactory] of [StandardPageWithResult].
  /// [T] is the type of the destination page. [R] is the type of page data. [E] is the data type of the value that the page returns.
  /// {@endtemplate}
  StandardPageWithResultFactory<T, R, E> getPageFactory<
    T extends StandardPageWithResult<R, E>,
    R extends Object?,
    E extends Object?
  >() => _getFactory<T, R, E>();

  /// {@template patapata_widgets.StandardRouteDelegate.goWithResult}
  /// Navigate to the [StandardPageWithResult] of type [T] that returns a value, with the option to pass [pageData] during the navigation.
  /// [T] is the type of the destination page. [R] is the type of page data. [E] is the data type of the value that the page returns.
  /// [navigationMode] is optional and represents the mode of [StandardPageNavigationMode] to use during navigation.
  /// [pushParentPage] indicates whether to push the parent page when navigating to a child page. default is `false`.
  /// {@endtemplate}
  Future<E?> goWithResult<
    T extends StandardPageWithResult<R, E>,
    R extends Object?,
    E extends Object?
  >(
    R pageData, [
    StandardPageNavigationMode? navigationMode,
    bool pushParentPage = false,
  ]) {
    return _goWithFactory<E>(
      _getFactory<T, R, E>(),
      pageData,
      navigationMode,
      pushParentPage,
    );
  }

  /// {@template patapata_widgets.StandardRouteDelegate.go}
  /// Navigate to the [StandardPage] of type [T] with the option to pass [pageData]
  /// during navigation.
  /// [T] represents the type of the destination page, and [R] signifies the type of page data.
  /// [navigationMode] is an optional mode of [StandardPageNavigationMode] to use during navigation.
  /// [pushParentPage] indicates whether to push the parent page when navigating to a child page. default is `false`.
  ///
  /// When the page is a [StandardPageWithNestedNavigator] and that page does not yet exist,
  /// the default first page within the nested navigator is also automatically pushed.
  /// Additionally, if the current page is the same [StandardPageWithNestedNavigator],
  /// the page stack within the nested navigator is cleared, and the default first page is pushed again.
  /// {@endtemplate}
  Future<void> go<T extends StandardPage<R>, R extends Object?>(
    R pageData, [
    StandardPageNavigationMode? navigationMode,
    bool pushParentPage = false,
  ]) {
    return goWithResult<T, R, void>(pageData, navigationMode, pushParentPage);
  }

  /// {@template patapata_widgets.StandardRouteDelegate.goErrorPage}
  /// Navigate to the error page with the option to pass an error log information [record].
  /// [record] represents the error log information to be passed to the error page.
  /// [navigationMode] is an optional mode of [StandardPageNavigationMode] to use during navigation.
  /// [pushParentPage] indicates whether to push the parent page when navigating to a child page. default is `false`.
  /// {@endtemplate}
  void goErrorPage(
    ReportRecord record, [
    StandardPageNavigationMode? navigationMode,
    bool pushParentPage = false,
  ]) {
    _factoryTypeMap.values
        .whereType<StandardErrorPageFactory>()
        .firstOrNull
        ?.goWithResult(record, navigationMode, pushParentPage);
  }

  /// {@template patapata_widgets.StandardRouteDelegate.routeWithConfiguration}
  /// Takes `StandardRouteData` data and performs page navigation.
  /// This function is used when a reference to [context] is not available,
  /// for example, when navigating from a plugin.
  /// [configuration] represents the page data to be passed to [goWithResult],
  /// [navigationMode] is an optional mode of [StandardPageNavigationMode] to use during navigation.
  /// [pushParentPage] indicates whether to push the parent page when navigating to a child page. default is `true`.
  /// {@endtemplate}
  void routeWithConfiguration(
    StandardRouteData configuration, [
    StandardPageNavigationMode? navigationMode,
    bool pushParentPage = true,
  ]) {
    if (kIsWeb || StandardAppPlugin.debugIsWeb) {
      if (configuration.factory == null) {
        throw WebPageNotFound();
      }
    }

    configuration.factory?.goWithResult(
      configuration.pageData,
      navigationMode,
      pushParentPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    _markRebuild = false;

    Widget tChild = Navigator(
      key: _navigatorKey,
      restorationScopeId: 'StandardAppNavigator',
      observers: [
        _rootNavigatorObserver,
        ...getApp().navigatorObservers,
        routeObserver,
      ],
      pages: _rootPageInstances,
      onDidRemovePage: _onDidRemovePage,
    );

    if (routableBuilder != null) {
      tChild = Builder(
        builder: ((child) =>
            (context) => routableBuilder!(context, child))(tChild),
      );
    }

    return MultiProvider(
      key: _multiProviderKey,
      providers: [
        ChangeNotifierProvider<StandardRouterDelegate>.value(value: this),
        Provider<RouteObserver<ModalRoute<void>>>.value(value: routeObserver),
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

  bool _markRebuild = false;

  void _updatePages() {
    if (_markRebuild) {
      return;
    }

    // Flutter's Navigator detects a change in the page stack when the reference to the List<Page> changes.
    // Therefore, instead of mutating the list, we must assign a new List instance.
    _rootPageInstances = _rootPageInstances.toList();

    _markRebuild = true;
    notifyListeners();
  }

  bool _popGestureEnabled = true;

  bool _checkPopGestureEnabled(Route route) {
    if (!_popGestureEnabled) {
      return false;
    }

    // Get the current active navigator.
    // This is important for nested navigators to prevent unintended pops.
    NavigatorState? tCurrentNavigator = currentNavigator;

    // If the current navigator cannot pop, traverse the page hierarchy to find a navigator that can pop.
    // This ensures that the pop gesture is only enabled when there is a valid navigator to handle the pop action.
    if (tCurrentNavigator.canPop() != true) {
      tCurrentNavigator = navigator;

      for (
        var tPage = _pageInstanceToNavigatorPage[currentPage];
        tPage != null;
        tPage = _pageInstanceToNavigatorPage[tPage]
      ) {
        if (tPage.standardPageKey.currentContext != null) {
          tCurrentNavigator = Navigator.of(
            tPage.standardPageKey.currentContext!,
          );
          if (tCurrentNavigator.canPop()) {
            break;
          }
        }
      }

      if (tCurrentNavigator?.canPop() != true) {
        // If no navigator can pop, fall back to the route navigator.
        tCurrentNavigator = route.navigator;
      }
    }

    return tCurrentNavigator == route.navigator;
  }

  void _onPopInvokedWithResult(Route route, bool didPop, dynamic result) {
    if (didPop) {
      final tRouteSettings = route.settings;
      if (_pageInstanceToPageType.containsKey(tRouteSettings)) {
        _onRemovePageInvoked(
          tRouteSettings as StandardPageInterface,
          result,
          true,
        );

        scheduleFunction(_updatePages);
      }
    }
  }

  void _onDidRemovePage(Page page) {
    if (_pageInstanceToPageType.containsKey(page)) {
      // Handling cases where a page is removed directly without going through Patapata's mechanism,
      // such as Navigator.removeRoute.
      //
      // However, prior to Flutter 3.35.7, page-based routes cannot be completed with imperative APIs.
      // In this case, Navigator.removeRoute will result in an assert error.
      // Therefore, it cannot be covered by code coverage.

      // coverage:ignore-start
      _onRemovePageInvoked(page as StandardPageInterface, null, false);

      scheduleFunction(_updatePages);
      // coverage:ignore-end
    }

    onDidRemovePage?.call(page);
  }

  void _onRemovePageInvoked(
    StandardPageInterface page,
    Object? result,
    bool onPop,
  ) {
    final tNavigatorHierarchy = <StandardPageInterface>[];
    for (
      var i = _pageInstanceToNavigatorPage[page];
      i != null;
      i = _pageInstanceToNavigatorPage[i]
    ) {
      tNavigatorHierarchy.add(i);
    }

    _removePage(page, result);

    // After removing the page, check if the navigator page needs a default nested page.
    for (var i in tNavigatorHierarchy) {
      if (_pageInstanceToPageType.containsKey(i)) {
        _checkDefaultNestedPage(i);
        break;
      }
    }

    // After removing the page, update the active page.
    //
    // When onPop is true, RouteObserver handles the update automatically.
    // When onPop is false (e.g., removeRoute directly deletes Route), manually traverse
    // the navigator hierarchy to find and activate the appropriate page.
    if (!onPop) {
      StandardPageInterface? tPage = currentPage;
      if (tPage != null &&
          tPage.standardPageKey.currentState?.active == false) {
        while (tPage != null) {
          final tNavigatorPage = _pageInstanceToNavigatorPage[tPage];
          if (tNavigatorPage == null ||
              tNavigatorPage.standardPageKey.currentState?.active == true) {
            break;
          }
          tPage = tNavigatorPage;
        }

        tPage?.standardPageKey.currentState?._updateActiveStatus(
          forcedStatus: true,
        );
      }
    }
  }

  void _removePage(
    StandardPageInterface page,
    Object? result, [
    bool keepEmptyNavigatorPage = false,
  ]) {
    final tPageInstances = _nestedPageInstances[page]?.reversed.toList();
    if (tPageInstances != null) {
      for (var tPage in tPageInstances) {
        _removePage(tPage, null, true);
      }
      _nestedPageInstances.remove(page);
    }

    final tCompleter = _pageInstanceCompleterMap.remove(page);
    final tState = page.standardPageKey.currentState;

    if (tCompleter != null) {
      tState?._completeResult(tCompleter, result);
    }

    tState?._updateActiveStatus(forcedStatus: false, recursive: false);

    _pageInstanceToPageType.remove(page);
    _pageInstanceToRouteData.remove(page);

    final tNavigatorPage = _pageInstanceToNavigatorPage.remove(page);
    if (tNavigatorPage != null) {
      final tPageInstances = _nestedPageInstances[tNavigatorPage];
      tPageInstances?.remove(page);
      if (!keepEmptyNavigatorPage && tPageInstances?.isEmpty == true) {
        _removePage(tNavigatorPage, null, keepEmptyNavigatorPage);
      }
    } else {
      _rootPageInstances.remove(page);
    }
  }

  /// Removes the specified [route] from the navigation stack.
  ///
  /// {@template patapata_widgets.StandardRouteDelegate.removeRoute}
  /// If the route corresponds to a [StandardPageInterface], it performs necessary cleanup
  /// and updates the page stack accordingly.
  /// If the route does not correspond to a [StandardPageInterface], it directly removes the
  /// route from the navigator.
  /// {@endtemplate}
  void removeRoute(Route<dynamic> route, Object? result) {
    final tRouteSettings = route.settings;
    if (tRouteSettings is StandardPageInterface) {
      if (_pageInstanceToPageType.containsKey(tRouteSettings)) {
        _onRemovePageInvoked(tRouteSettings, result, false);

        _updatePages();
      }
    } else {
      route.navigator?.removeRoute(route, result);

      _updatePages();
    }
  }

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

    StandardRouteData? tInitialRouteData =
        _initialRouteData ??
        (await getApp().standardAppPlugin.parser?.parseRouteInformation(
          RouteInformation(uri: Uri(path: Navigator.defaultRouteName)),
        ));
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
          _ => true,
        };
        if (tAutoProcessInitialRoute) {
          return processInitialRoute();
        }
      }

      return SynchronousFuture(null);
    }

    routeWithConfiguration(configuration);

    return SynchronousFuture(null);
  }

  @override
  StandardRouteData? get currentConfiguration {
    final tCurrentPage = currentPage;
    if (tCurrentPage == null) {
      return null;
    }
    return _pageInstanceToRouteData[tCurrentPage];
  }

  /// Retrieves the root `NavigatorKey`.
  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Retrieves the current `NavigatorKey`.
  GlobalKey<NavigatorState>? get currentNavigatorKey {
    final tCurrentPage = currentPage;
    if (tCurrentPage == null) {
      return navigatorKey; // coverage:ignore-line
    }

    final tNavigatorPage =
        _pageInstanceToNavigatorPage[tCurrentPage]?.standardPageKey.currentState
            as StandardPageWithNestedNavigator?;

    return tNavigatorPage?.nestedNavigatorKey ?? navigatorKey;
  }

  /// Retrieves the current `StandardPageInterface`.
  StandardPageInterface? get currentPage {
    StandardPageInterface? tPage = _rootPageInstances.lastOrNull;

    if (tPage != null) {
      StandardPageInterface? tNestedPageInstance;
      do {
        tNestedPageInstance = _nestedPageInstances[tPage]?.lastOrNull;
        tPage = tNestedPageInstance ?? tPage;
      } while (tNestedPageInstance != null);
    }

    return tPage;
  }

  /// Retrieves the root `Navigator`.
  NavigatorState get navigator {
    assert(
      _navigatorKey.currentState != null,
      'Navigator does not exist yet. Wait for the first build to finish before using [navigator].',
    );

    return _navigatorKey.currentState!;
  }

  /// Retrieves the `BuildContext` of the root Navigator.
  BuildContext get navigatorContext {
    assert(
      _navigatorKey.currentContext != null,
      'Navigator does not exist yet. Wait for the first build to finish before using [navigatorContext].',
    );

    return _navigatorKey.currentContext!;
  }

  /// Retrieves the current `Navigator`.
  NavigatorState get currentNavigator {
    final tKey = currentNavigatorKey;

    assert(
      tKey?.currentState != null,
      'Navigator does not exist yet. Wait for the first build to finish before using [navigator].',
    );

    return tKey!.currentState!;
  }

  /// Retrieves the `BuildContext` of the current Navigator.
  BuildContext get currentNavigatorContext {
    final tKey = currentNavigatorKey;

    assert(
      tKey?.currentContext != null,
      'Navigator does not exist yet. Wait for the first build to finish before using [navigatorContext].',
    );

    return tKey!.currentContext!;
  }

  StandardRouteData? _getStandardRouteDataForPath(Uri location) {
    for (var i in _factoryTypeMap.values) {
      final tLinks = _links[i] ?? const [];
      for (var j in tLinks) {
        final tMatch = j.$1.firstMatch(location.path);

        if (tMatch != null) {
          try {
            return StandardRouteData(
              factory: i,
              pageData: j.$2(tMatch, location),
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

  List<StandardPageWithResultFactory> _getNavigatorHierarchy(
    StandardPageWithResultFactory factory,
  ) {
    final tHierarchy = <StandardPageWithResultFactory>[];
    StandardPageWithResultFactory? tPageFactory = factory.navigatorPageFactory;
    while (tPageFactory != null) {
      tHierarchy.add(tPageFactory);
      tPageFactory = tPageFactory.navigatorPageFactory;
    }
    return tHierarchy.reversed.toList();
  }

  Future<E?> _goWithFactory<E extends Object?>(
    StandardPageWithResultFactory factory,
    Object? pageData,
    StandardPageNavigationMode? navigationMode,
    bool pushParentHistory,
  ) {
    _continueProcessInitialRoute = false;

    final tNavigationMode = navigationMode ?? factory.navigationMode;

    final StandardPageInterface? tCurrentPage = currentPage;

    assert(
      tCurrentPage == null || _pageInstanceToPageType.containsKey(tCurrentPage),
    );

    if (tCurrentPage != null) {
      bool tRemoved = false;
      for (
        var tNavigatorPage = _pageInstanceToNavigatorPage[tCurrentPage];
        tNavigatorPage != null;
        tNavigatorPage = _pageInstanceToNavigatorPage[tNavigatorPage]
      ) {
        if (tNavigatorPage.factoryObject.pageType == factory.pageType) {
          // Navigating to the same page as the current navigator page.
          // Remove all nested pages.
          final tReversedPageInstances = _nestedPageInstances[tNavigatorPage]!
              .reversed
              .toList();
          for (var tPageInstance in tReversedPageInstances) {
            _removePage(tPageInstance, null);
          }
          tRemoved = true;
          break;
        }
      }

      if (!tRemoved) {
        if (!tCurrentPage.factoryObject.keepHistory ||
            tNavigationMode == StandardPageNavigationMode.replace) {
          // Current page does not keep history or navigation mode is replace.
          // Remove the current page from history.
          _removePage(tCurrentPage, null);
        } else {
          if ((tNavigationMode == StandardPageNavigationMode.removeAll) ||
              (factory.group != null &&
                  tCurrentPage.factoryObject.group != null &&
                  tCurrentPage.factoryObject.group != factory.group)) {
            // Different group than the current one.
            // Remove all history.
            final tReversedPageInstances = _rootPageInstances.reversed.toList();

            for (var tPageInstance in tReversedPageInstances) {
              _removePage(tPageInstance, null);
            }
          }
        }
      }
    }

    StandardPageInterface fNavigate(
      StandardPageWithResultFactory factory,
      Object? pageData,
      StandardPageNavigationMode mode,
      bool pushParentHistory, [
      bool isHierarchyPage = false,
    ]) {
      final StandardPageInterface? tNavigatorPage;
      if (factory.navigatorPageFactory != null) {
        final tNavigatorPageFactory = factory.navigatorPageFactory!;

        if (factory.anyNavigator) {
          // Add to the deepest nested navigator page starting from the base navigator.
          StandardPageInterface tBaseNavigatorPage = _pageInstanceToPageType
              .entries
              .firstWhere(
                (entry) => entry.value == tNavigatorPageFactory.pageType,
              )
              .key;
          StandardPageInterface? tLastPage =
              _nestedPageInstances[tBaseNavigatorPage]?.lastOrNull;
          while (tLastPage != null && tLastPage.factoryObject.hasNestedPages) {
            tBaseNavigatorPage = tLastPage;
            tLastPage = _nestedPageInstances[tLastPage]?.lastOrNull;
          }

          tNavigatorPage = tBaseNavigatorPage;
        } else {
          tNavigatorPage = _pageInstanceToPageType.entries
              .firstWhere(
                (entry) => entry.value == tNavigatorPageFactory.pageType,
              )
              .key;
        }
      } else {
        tNavigatorPage = null;
      }

      assert(
        factory.navigatorPageFactory == null ||
            (tNavigatorPage != null &&
                _nestedPageInstances.containsKey(tNavigatorPage)),
      );

      final tPageInstances =
          _nestedPageInstances[tNavigatorPage] ?? _rootPageInstances;

      final tPageKey = factory.getPageKey(pageData);

      // First check to see if we already have this page's representation
      // in the history stack. If we do, modify the history stack and use the old instance.
      for (var i = 0, il = tPageInstances.length; i < il; i++) {
        if (tPageInstances[i].key == tPageKey) {
          switch (mode) {
            case StandardPageNavigationMode.moveToTop:
            case StandardPageNavigationMode.replace:
              if (i == il - 1) {
                break;
              }

              final tLastPage = tPageInstances.lastOrNull;

              // Update active status of all pages being moved to inactive status.
              if (tLastPage != null) {
                tLastPage.standardPageKey.currentState?._updateActiveStatus(
                  forcedStatus: false,
                );
              }

              final tPageToMove = tPageInstances[i];

              // Shift all instances from this point to the left by one.
              // Ignore the last index as we just replace it
              for (var j = i; j < il - 1; j++) {
                tPageInstances[j] = tPageInstances[j + 1];
              }

              tPageInstances[il - 1] = tPageToMove;

              break;
            case StandardPageNavigationMode.removeAbove:
              for (var j = il - 1; j > i; j--) {
                final tLastPage = tPageInstances.lastOrNull;
                if (tLastPage != null) {
                  _removePage(tLastPage, null);
                }
              }

              break;
            default:
              break;
          }

          break;
        }
      }

      if (tPageInstances.lastOrNull?.key == tPageKey) {
        final tLastPage = tPageInstances.last;
        final tLastPageState = tLastPage.standardPageKey.currentState;

        bool tLastPageDataChanged = false;

        if (tLastPageState != null) {
          if (tLastPageState.pageData != pageData) {
            tLastPageState.pageData = pageData;
            tLastPageDataChanged = true;
          }

          if (tLastPageState.active) {
            tLastPageState.onRefocus();
          } else {
            final tRoute = ModalRoute.of(tLastPageState.context);

            if (tRoute != null) {
              tLastPageState.context.read<Analytics>().routeViewEvent(
                tRoute,
                navigationType: AnalyticsNavigationType.push,
              );
            }
            tLastPageState._pushParentHistory = pushParentHistory;
            // Update active status to true.
            // If it's a hierarchy page, do not update recursively.
            // This is because it is not yet known which of the subordinate pages is active.
            tLastPageState._updateActiveStatus(
              forcedStatus: true,
              recursive: !isHierarchyPage,
            );
          }
        }

        if (tLastPageDataChanged) {
          _pageInstanceToRouteData[tLastPage] = StandardRouteData(
            factory: factory,
            pageData: pageData,
          );
        }

        return tLastPage;
      } else {
        final tRouteData = StandardRouteData(
          factory: factory,
          pageData: pageData,
        );

        final tPage = _initializePage(tRouteData, pushParentHistory);
        _pushPageInstance(tPage, tRouteData);

        return tPage;
      }
    }

    final tNavigatorHierarchy = _getNavigatorHierarchy(factory);
    for (var tNavigatorFactory in tNavigatorHierarchy) {
      final tNavigatorPage = fNavigate(
        tNavigatorFactory,
        null,
        tNavigationMode,
        false,
        true,
      );
      _checkDefaultNestedPage(tNavigatorPage);
    }
    final tPage = fNavigate(
      factory,
      pageData,
      tNavigationMode,
      pushParentHistory,
    );
    if (tPage.factoryObject.hasNestedPages) {
      _checkDefaultNestedPage(tPage);
    }
    if (pushParentHistory) {
      tPage.standardPageKey.currentState?._pushParentHistory = true;
      _pushParentPageHistory(tPage);
    }

    final tCompleter = _pageInstanceCompleterMap[tPage]!;

    assert(
      tCompleter is Completer<E?>,
      'Same PageKey used for pages that have different return types.'
      'This is not allowed. PageKey: ${factory.getPageKey(pageData)}', // coverage:ignore-line
    );

    _checkGroupRoot(currentPage!);

    _updatePages();

    return (tCompleter as Completer<E?>).future;
  }
}

class _RootNavigatorObserver extends NavigatorObserver {
  final StandardRouterDelegate _delegate;

  _RootNavigatorObserver(this._delegate);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is! StandardPageInterface && route.isCurrent) {
      _delegate._popGestureEnabled = false;
      return;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is! StandardPageInterface &&
        (previousRoute?.settings == null ||
            previousRoute?.settings is StandardPageInterface &&
                previousRoute!.isCurrent)) {
      _delegate._popGestureEnabled = true;
      return;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is! StandardPageInterface &&
        (previousRoute?.settings == null ||
            previousRoute?.settings is StandardPageInterface &&
                previousRoute!.isCurrent)) {
      _delegate._popGestureEnabled = true;
      return;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) {
      return;
    }

    if (newRoute.isCurrent == true) {
      _delegate._popGestureEnabled = newRoute.settings is StandardPageInterface;
    }
  }
}

/// An extension class that adds StandardPage functionality to [BuildContext].
extension StandardPageContext on BuildContext {
  /// {@macro patapata_widgets.StandardPageWithResult.pl}
  ///
  /// Throws an exception if [StandardPageWithResult] does not exist in the widget tree of the context.
  String pl(String key, [Map<String, Object>? namedParameters]) {
    if (this is StatefulElement) {
      final tElement = (this as StatefulElement);
      if (tElement.state is StandardPageWithResult) {
        final tState = tElement.state as StandardPageWithResult;
        return tState.pl(key, namedParameters);
      }
    }

    return Provider.of<StandardPageWithResult>(this).pl(key, namedParameters);
  }
}

/// Exception thrown when a web page is not found.
class WebPageNotFound extends PatapataCoreException {
  WebPageNotFound() : super(code: PatapataCoreExceptionCode.PPE601);

  @override
  Level? get logLevel => Level.INFO;

  @override
  Level? get userLogLevel => Level.SHOUT;
}
