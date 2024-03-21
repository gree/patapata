// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of "standard_app.dart";

/// This is a mixin for StatefulWidget that is needed to create a `WidgetsApp.Router` for Patapata.
/// If you want to create your own `WidgetsApp.Router`, you can refer to [StandardMaterialApp] or [StandardCupertinoApp].
mixin StandardStatefulMixin on StatefulWidget {
  ///　A list of [StandardPageWithResultFactory]
  List<StandardPageWithResultFactory> get pages;

  /// Wrap the entire Patapata Navigator-related application,
  /// enabling the use of page transition-related functionalities through a function.
  Widget Function(BuildContext context, Widget? child)? get routableBuilder;

  /// A function called when the app is attempting to go back to the previous page.
  bool Function(Route<dynamic> route, dynamic result)? get willPopPage;
}

/// This is a mixin for State that is needed to create a `WidgetsApp.Router` for Patapata.
/// If you want to create your own `WidgetsApp.Router`, you can refer to [StandardMaterialApp] or [StandardCupertinoApp].
mixin StandardWidgetAppMixin<T extends StandardStatefulMixin> on State<T> {
  late StandardRouteInformationParser _routeInformationParser;
  late StandardRouterDelegate _routerDelegate;

  @override
  void initState() {
    super.initState();

    _routerDelegate = StandardRouterDelegate(
      context: context,
      pageFactories: widget.pages,
      routableBuilder: widget.routableBuilder,
      willPopPage: widget.willPopPage,
    );
    _routeInformationParser = StandardRouteInformationParser(
      context: context,
      routerDelegate: _routerDelegate,
    );
    final tPlugin = context.read<App>().getPlugin<StandardAppPlugin>();
    tPlugin?._delegate = _routerDelegate;
    tPlugin?._parser = _routeInformationParser;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.routableBuilder != oldWidget.routableBuilder) {
      _routerDelegate.routableBuilder = widget.routableBuilder;
    }

    if (widget.willPopPage != oldWidget.willPopPage) {
      _routerDelegate.willPopPage = widget.willPopPage;
    }

    if (!const DeepCollectionEquality().equals(widget.pages, oldWidget.pages)) {
      _routerDelegate._updatePageFactories(widget.pages);
    }
  }
}
