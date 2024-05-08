// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:provider/provider.dart';

const String kTestChangePageDataButton = 'test-change-page-data-button';
const String kTestButton = 'test-button';
const String kTestButtonSecond = 'test-button-second';
const String kLinkButton = 'link-button';
const String kOnPopButton = 'on-pop-button';
const String kGoPageDataButton = 'go-page-data-button';
const String kGoChangeDataButton = 'go-change-data-button';
const String kChangePageDataButton = 'change-page-data-button';
const String kProcessInitialRouteButton = 'process-initial-route-button';
const String kRemoveRouteButton = 'remove-route-buton';
const String kCheckNavigatorButton = 'check-navigator-buton';
const String kGoToRouterDelegateButton = 'go-to-router-delegate-button';
const String kGetPageFactoryButton = 'get-page-factory-button';
const String kGetStandardAppRouterContext = 'get-standard-app-router-context';
const String kGetStandardAppPluginRoute = 'get-standard-app-plugin-route';
const String kGetStandardAppPluginGenerateLink =
    'get-standard-app-plugin-generate-link';

TestAnalyticsEvent? testAnalytics;
GlobalKey<NavigatorState>? navigatorKey;
NavigatorState? navigatorState;
BuildContext? navigatorContext;
StandardPageWithResultFactory? pageFactory;
bool isLinkHander = false;
Uri? linkHanderUri;
BuildContext? buildContext;

bool onLink(Uri link) {
  isLinkHander = true;
  linkHanderUri = link;
  return true;
}

// Test Data
class TestChangeNotifierData extends ChangeNotifier {
  TestChangeNotifierData({
    required this.title,
    required this.pages,
  });

  String title = '';
  List<StandardPageFactory> pages = [];
  Widget Function(BuildContext context, Widget? child)? routableBuilder;
  bool Function(Route<dynamic> route, dynamic result)? willPopPage;

  void changeTitle(String title) {
    this.title = title;
    notifyListeners();
  }

  void changePages(List<StandardPageFactory> pages) {
    this.pages = pages;
    notifyListeners();
  }

  void changeRoutableBuilder(
    Widget Function(BuildContext context, Widget? child)? routableBuilder,
  ) {
    this.routableBuilder = routableBuilder;
    notifyListeners();
  }

  void changeWillPopPage(
    bool Function(Route<dynamic> route, dynamic result)? willPopPage,
  ) {
    this.willPopPage = willPopPage;
    notifyListeners();
  }
}

// Material Page
class TestPageA extends StandardPage<void> {
  @override
  AnalyticsEvent? get analyticsSingletonEvent => testAnalytics;

  String testText = '';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'Test Title'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text("Test Message");
                },
              ),
            ),
            TextButton(
              key: const ValueKey(kTestButton),
              onPressed: () {
                context.go<TestPageB, void>(null);
              },
              child: const Text('Go to Test Page B'),
            ),
            TextButton(
              key: const ValueKey(kGoToRouterDelegateButton),
              onPressed: () {
                // Go To Test Page B for Router Delegate
                var routerDelegate = (Router.of(context).routerDelegate
                    as StandardRouterDelegate);
                routerDelegate.go<TestPageB, void>(null);
              },
              child: const Text('Go to Test Page B'),
            ),
            TextButton(
              key: const ValueKey(kLinkButton),
              onPressed: () {
                context.route('testPageData/10');
              },
              child: const Text('Go to Link Page'),
            ),
            TextButton(
              key: const ValueKey(kGoPageDataButton),
              onPressed: () {
                context.go<TestPageC, TestPageData>(
                  TestPageData(id: 10, data: 'go to test data page data'),
                );
              },
              child: const Text('Go to Test TestPage C'),
            ),
            TextButton(
              key: const ValueKey(kGoChangeDataButton),
              onPressed: () {
                context.go<TestPageE, BaseListenable>(ChangeListenableBool());
              },
              child: const Text('Go to Test Page E'),
            ),
            TextButton(
              key: const ValueKey(kProcessInitialRouteButton),
              onPressed: () {
                Router.of(context).processInitialRoute();
              },
              child: const Text('Go to Test Page E'),
            ),
            TextButton(
              key: const ValueKey(kRemoveRouteButton),
              onPressed: () {
                Router.of(context).removeRoute(context);
              },
              child: const Text('Remove Route'),
            ),
            TextButton(
              key: const ValueKey(kGetPageFactoryButton),
              onPressed: () {
                var routerDelegate = (Router.of(context).routerDelegate
                    as StandardRouterDelegate);
                pageFactory =
                    routerDelegate.getPageFactory<TestPageA, void, void>();
              },
              child: const Text('Get Page Factory'),
            ),
            TextButton(
              key: const ValueKey(kGetStandardAppRouterContext),
              onPressed: () {
                buildContext = context;
              },
              child: const Text('Get StandardAppRouter Context'),
            ),
            TextButton(
              key: const ValueKey(kGetStandardAppPluginRoute),
              onPressed: () {
                getApp()
                    .getPlugin<StandardAppPlugin>()
                    ?.route('testPageData/10');
              },
              child: const Text('Get StandardAppRouter Context'),
            ),
            if (analyticsSingletonEvent == null) ...[
              TextButton(
                key: const ValueKey(kGetStandardAppPluginGenerateLink),
                onPressed: () {
                  testText = context
                          .read<App>()
                          .getPlugin<StandardAppPlugin>()!
                          .generateLink<TestPageC, TestPageData>(
                            TestPageData(id: 9999, data: 'test page data'),
                          ) ??
                      '';
                  setState(() {});
                },
                child: const Text('Get Standard GenerateLink App'),
              ),
              Center(
                child: Text('generateLink testText $testText'),
              ),
            ],
            if (analyticsSingletonEvent != null)
              Center(
                child: Text(
                    "Analytics Event Data : ${analyticsSingletonEvent!.data}"),
              ),
          ],
        ),
      ),
    );
  }
}

class TestPageB extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Test Title B',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text("Test Message B");
                },
              ),
            ),
            TextButton(
              key: const ValueKey(kTestButton),
              onPressed: () {
                context.go<TestPageC, TestPageData>(
                  TestPageData(id: 40, data: 'Go to Page C'),
                );
              },
              child: const Text('On pop page'),
            ),
            TextButton(
              key: const ValueKey(kOnPopButton),
              onPressed: () {
                Navigator.maybePop(context);
              },
              child: const Text('On pop page'),
            ),
            TextButton(
              key: const ValueKey(kTestButtonSecond),
              onPressed: () {
                context.go<TestPageD, void>(
                  null,
                );
              },
              child: const Text('Go to Test TestPage D'),
            ),
            TextButton(
              key: const ValueKey(kRemoveRouteButton),
              onPressed: () {
                Router.of(context).removeRoute(context);
              },
              child: const Text('Remove Route'),
            ),
            TextButton(
              key: const ValueKey(kCheckNavigatorButton),
              onPressed: () {
                navigatorState = (Router.of(context).routerDelegate
                        as StandardRouterDelegate)
                    .navigator;
                navigatorContext = (Router.of(context).routerDelegate
                        as StandardRouterDelegate)
                    .navigatorContext;
                navigatorKey = (Router.of(context).routerDelegate
                        as StandardRouterDelegate)
                    .navigatorKey;
              },
              child: const Text('Set Navigator Key'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestPageC extends StandardPage<TestPageData> {
  @override
  Widget buildPage(BuildContext context) {
    String? tGenerateLink;
    final ModalRoute<Object?>? tRoute = ModalRoute.of(context);
    if (tRoute != null) {
      final tInterfacePage = tRoute.settings as StandardPageInterface;
      tGenerateLink = tInterfacePage.factoryObject.generateLink(pageData);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Title C'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text("Test Message C");
                },
              ),
            ),
            Center(
              child: Builder(
                builder: (context) {
                  return Text("Test Link Data is ${pageData.id}");
                },
              ),
            ),
            TextButton(
              key: const ValueKey(kGoPageDataButton),
              onPressed: () {
                context.go<TestPageC, TestPageData>(
                  TestPageData(id: 20, data: 'go to test page data'),
                );

                setState(() {});
              },
              child: const Text('Go to Test TestPageC'),
            ),
            TextButton(
              key: const ValueKey(kTestChangePageDataButton),
              onPressed: () {
                pageData = TestPageData(
                    id: 30, data: 'changed test page data by button');
                setState(() {});
              },
              child: const Text('On Change PageData'),
            ),
            TextButton(
              key: const ValueKey(kOnPopButton),
              onPressed: () {
                Navigator.maybePop(context);
              },
              child: const Text('On pop page'),
            ),
            if (tGenerateLink != null)
              Center(
                child: Builder(
                  builder: (context) {
                    return Text("Test Generate Link is $tGenerateLink");
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TestPageD extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    var tModalRoute = ModalRoute.of(context);
    var tInterfacePage = tModalRoute?.settings as StandardPageInterface;
    var tTestPageData = tInterfacePage.arguments as TestPageData;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'Test Title D'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text("Test Page Id : ${tTestPageData.id}"),
            Text("Test Page Data : ${tTestPageData.data}"),
            Text("Test Interface Name : ${tInterfacePage.name}"),
            Text(
                "Test Interface RestorationId : ${tInterfacePage.restorationId}"),
          ],
        ),
      ),
    );
  }
}

class TestPageE extends StandardPage<BaseListenable> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'Test Title'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
              key: const ValueKey(kChangePageDataButton),
              onPressed: () {
                if (pageData is ChangeListenableBool) {
                  pageData = ChangeListenableNumber();
                } else {
                  pageData = ChangeListenableBool();
                }
                setState(() {});
              },
              child: const Text('On Change PageData Bool Type'),
            ),
            if (pageData is ChangeListenableBool)
              Center(
                child: Text(
                    "Test Data Bool : ${context.watch<ChangeListenableBool>().data}"),
              ),
            if (pageData is ChangeListenableNumber)
              Center(
                child: Text(
                    "Test Data Number : ${context.watch<ChangeListenableNumber>().data}"),
              ),
          ],
        ),
      ),
    );
  }
}

// Cupertino Page
class TestPageF extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Test title F'),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text("Test Message F");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestPageG extends StandardPage<TestPageData> {
  @override
  void initState() {
    super.initState();

    pageData = TestPageData(id: 77, data: 'overridden test page data');
  }

  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Test title G'),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return Text('${pageData.id} ${pageData.data}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestPageH extends StandardPage<TestPageData> {
  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Test title H'),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return Text('${pageData.id} ${pageData.data}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestPageRemoveRoute extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TestPageRemoveRoute'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
              key: const ValueKey(kTestButton),
              onPressed: () async {
                context.removeRoute();
              },
              child: const Text('Remove the route'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestPageContextGoWithResult extends StandardPage<void> {
  String? _result;

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'TestPageContextGoWithResult'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
              key: const ValueKey(kTestButton),
              onPressed: () async {
                final tResult = await context
                    .goWithResult<TestPageWithResult, void, String>(null);
                setState(() {
                  _result = tResult;
                });
              },
              child: const Text('Go to Test Page For Result'),
            ),
            Text(_result ?? ''),
          ],
        ),
      ),
    );
  }
}

class TestPageWithResult extends StandardPageWithResult<void, String> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'TestPageWithResult'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
              key: const ValueKey(kTestButton),
              onPressed: () {
                pageResult = 'pageResult';
                Navigator.pop(context);
              },
              child: const Text('Go to Test Page For Result'),
            ),
            TextButton(
              key: const ValueKey(kTestButtonSecond),
              onPressed: () {
                Navigator.pop(context, 'popResult');
              },
              child: const Text('On pop page'),
            ),
          ],
        ),
      ),
    );
  }
}

// Test Page Data
class TestPageData {
  final int id;
  final String? data;

  TestPageData({
    required this.id,
    required this.data,
  });
}

class BaseListenable extends ChangeNotifier {}

class ChangeListenableBool extends BaseListenable {
  bool data = true;
}

class ChangeListenableNumber extends BaseListenable {
  int data = 100;
}

class TestAnalyticsEvent extends AnalyticsEvent {
  TestAnalyticsEvent({
    required super.name,
    super.data,
  });
}

class TestDataPlugin extends Plugin with StandardAppRoutePluginMixin {
  @override
  Future<StandardRouteData?> getInitialRouteData() async {
    return StandardRouteData(
      factory: null,
      pageData: TestPageData(id: 9999, data: 'test plugin data'),
    );
  }
}

class TestDataParseRouteInformationPlugin extends Plugin
    with StandardAppRoutePluginMixin {
  @override
  Future<StandardRouteData?> parseRouteInformation(
      RouteInformation routeInformation) async {
    return SynchronousFuture(StandardRouteData(
      factory: app
          .getPlugin<StandardAppPlugin>()!
          .delegate!
          .getPageFactory<TestPageH, TestPageData, void>(),
      pageData: TestPageData(id: 70, data: 'parsed route'),
    ));
  }
}

class TestDataBadLinkHandlerPlugin extends Plugin
    with StandardAppRoutePluginMixin {
  @override
  Future<StandardRouteData?> getInitialRouteData() async {
    return StandardRouteData(
      factory: null,
      pageData: TestPageData(id: 9999, data: 'test plugin data'),
    );
  }
}

class TestNullDataPlugin extends Plugin with StandardAppRoutePluginMixin {}
