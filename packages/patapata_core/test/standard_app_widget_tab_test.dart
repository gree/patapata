// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';
import 'utils/patapata_core_test_utils.dart';

const String _kTestGoSecondPageButton = 'test-go-second-page-button';
const String _kTestGoHomePageButton = 'test-go-home-page-button';
const String _kTestGoTitlePageButton = 'test-go-title-page-button';
const String _kTestGoTitleDetailsPageButton =
    'test-go-title-details-page-button';
const String _kTestGoMyPageButton = 'test-go-my-page-button';
const String _kTestGoMyFavoritePageButton = 'test-go-myfavorite-page-button';
const String _kTestStandardPageBackButton = 'standard-page-back-button';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("Standard Page Test, Child Page Instances (Standard Material)",
      (WidgetTester tester) async {
    // Standard Material Page Test
    final App tApp = createApp(
      environment: const Environment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => l(context, 'title'),
        pages: [
          StandardPageFactory<_TestFirstPage, void>(
            create: (data) => _TestFirstPage(),
          ),
          StandardPageFactory<_TestSecondPage, void>(
            create: (data) => _TestSecondPage(),
          ),
          StandardPageFactory<_TestHomePage, void>(
            create: (data) => _TestHomePage(),
          ),
          StandardPageFactory<_TestTitlePage, void>(
            create: (data) => _TestTitlePage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestTitleDetailsPage, void>(
            create: (data) => _TestTitleDetailsPage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestMyPage, void>(
            create: (data) => _TestMyPage(),
          ),
          StandardPageFactory<_TestMyFavoritePage, void>(
            create: (data) => _TestMyFavoritePage(),
            parentPageType: _TestMyPage,
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      // Show First Page
      await tester.pumpAndSettle();

      expect(find.text('Test First Page'), findsOneWidget);

      // Show Second Page
      await tester.tap(find.byKey(const ValueKey(_kTestGoSecondPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Second Page'), findsOneWidget);

      // Show Home Tab and Show Title Page
      await tester.tap(find.byKey(const ValueKey(_kTestGoHomePageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Page'), findsOneWidget);

      // Show Title Details Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestGoTitleDetailsPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Details Page'), findsOneWidget);

      // Show MyPage Tab and Show My Favorite Page
      await tester.tap(find.byKey(const ValueKey(_kTestGoMyPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test MyFavorite Page'), findsOneWidget);

      // GO Back Before Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestStandardPageBackButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Details Page'), findsOneWidget);

      // GO Back Before Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestStandardPageBackButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Page'), findsOneWidget);

      // GO Back Before Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestStandardPageBackButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Second Page'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Test, Only Tab App", (WidgetTester tester) async {
    // Standard Material Page Test
    final App tApp = createApp(
      environment: const Environment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => l(context, 'title'),
        pages: [
          StandardPageFactory<_TestTitlePage, void>(
            create: (data) => _TestTitlePage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestHomePage, void>(
            create: (data) => _TestHomePage(),
          ),
          StandardPageFactory<_TestTitleDetailsPage, void>(
            create: (data) => _TestTitleDetailsPage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestMyPage, void>(
            create: (data) => _TestMyPage(),
          ),
          StandardPageFactory<_TestMyFavoritePage, void>(
            create: (data) => _TestMyFavoritePage(),
            parentPageType: _TestMyPage,
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      // Show Home Tab and Show Title Page
      await tester.pumpAndSettle();

      expect(find.text('Test Title Page'), findsOneWidget);

      // Show Title Details Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestGoTitleDetailsPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Details Page'), findsOneWidget);

      // Show MyPage Tab and Show My Favorite Page
      await tester.tap(find.byKey(const ValueKey(_kTestGoMyPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test MyFavorite Page'), findsOneWidget);

      // GO Back Before Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestStandardPageBackButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Details Page'), findsOneWidget);

      // GO Back Before Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestStandardPageBackButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Page'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Will Pop Page Test", (WidgetTester tester) async {
    // Standard Material Page Test
    final App tApp = createApp(
      environment: const Environment(),
      appWidget: StandardMaterialApp(
        willPopPage: (route, result) {
          return true;
        },
        onGenerateTitle: (context) => l(context, 'title'),
        pages: [
          StandardPageFactory<_TestFirstPage, void>(
            create: (data) => _TestFirstPage(),
          ),
          StandardPageFactory<_TestSecondPage, void>(
            create: (data) => _TestSecondPage(),
          ),
          StandardPageFactory<_TestHomePage, void>(
            create: (data) => _TestHomePage(),
          ),
          StandardPageFactory<_TestTitlePage, void>(
            create: (data) => _TestTitlePage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestTitleDetailsPage, void>(
            create: (data) => _TestTitleDetailsPage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestMyPage, void>(
            create: (data) => _TestMyPage(),
          ),
          StandardPageFactory<_TestMyFavoritePage, void>(
            create: (data) => _TestMyFavoritePage(),
            parentPageType: _TestMyPage,
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      // Show First Page
      await tester.pumpAndSettle();

      expect(find.text('Test First Page'), findsOneWidget);

      // Show Second Page
      await tester.tap(find.byKey(const ValueKey(_kTestGoSecondPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Second Page'), findsOneWidget);

      // Show Home Tab and Show Title Page
      await tester.tap(find.byKey(const ValueKey(_kTestGoHomePageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Page'), findsOneWidget);

      // Show Title Details Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestGoTitleDetailsPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Details Page'), findsOneWidget);

      // GO Back Before Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestStandardPageBackButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Details Page'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets(
      "Standard Page Test, Child Page Instances (Go To Title Details Pages)",
      (WidgetTester tester) async {
    // Standard Material Page Test
    final App tApp = createApp(
      environment: const Environment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => l(context, 'title'),
        pages: [
          StandardPageFactory<_TestFirstPage, void>(
            create: (data) => _TestFirstPage(),
          ),
          StandardPageFactory<_TestHomePage, void>(
            create: (data) => _TestHomePage(),
          ),
          StandardPageFactory<_TestTitlePage, void>(
            create: (data) => _TestTitlePage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestTitleDetailsPage, void>(
            create: (data) => _TestTitleDetailsPage(),
            parentPageType: _TestHomePage,
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      // Show First Page
      await tester.pumpAndSettle();

      expect(find.text('Test First Page'), findsOneWidget);

      // Show Title Details Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestGoTitleDetailsPageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Details Page'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets(
      "Standard Page Test, Child Page Instances (Child page is set first parent page is set after)",
      (WidgetTester tester) async {
    // Standard Material Page Test
    final App tApp = createApp(
      environment: const Environment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => l(context, 'title'),
        pages: [
          StandardPageFactory<_TestFirstPage, void>(
            create: (data) => _TestFirstPage(),
          ),
          StandardPageFactory<_TestTitlePage, void>(
            create: (data) => _TestTitlePage(),
            parentPageType: _TestHomePage,
          ),
          StandardPageFactory<_TestHomePage, void>(
            create: (data) => _TestHomePage(),
          ),
          StandardPageFactory<_TestMyFavoritePage, void>(
            create: (data) => _TestMyFavoritePage(),
            parentPageType: _TestMyPage,
          ),
          StandardPageFactory<_TestMyPage, void>(
            create: (data) => _TestMyPage(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      // Show First Page
      await tester.pumpAndSettle();

      expect(find.text('Test First Page'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(_kTestGoHomePageButton)));

      // Show Home Tab
      await tester.pumpAndSettle();

      expect(find.text('Test Title Page'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Test, Child Page Instances (Cupertino)",
      (WidgetTester tester) async {
    // Standard Cupertino Page Test
    final App tApp = createApp(
      environment: const Environment(),
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => l(context, 'title'),
        pages: [
          // add all pages that inherit from StandardPage here
          // not tabs page
          StandardPageFactory<_TestCupertinoFirstPage, void>(
            create: (data) => _TestCupertinoFirstPage(),
          ),
          // tabs page
          // Home
          StandardPageFactory<_TestCupertinoHomePage, void>(
            create: (data) => _TestCupertinoHomePage(),
          ),
          StandardPageFactory<_TestCupertinoTitlePage, void>(
            create: (data) => _TestCupertinoTitlePage(),
            parentPageType: _TestCupertinoHomePage,
          ),
          // MyPage
          StandardPageFactory<_TestCupertinoMyPage, void>(
            create: (data) => _TestCupertinoMyPage(),
          ),
          StandardPageFactory<_TestCupertinoMyFavoritePage, void>(
            create: (data) => _TestCupertinoMyFavoritePage(),
            parentPageType: _TestCupertinoMyPage,
          ),
        ],
        routableBuilder: (context, child) {
          return CupertinoTheme(
            data: CupertinoTheme.of(context)
                .copyWith(brightness: Brightness.light),
            child: child!,
          );
        },
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      // Show First Page
      await tester.pumpAndSettle();

      expect(find.text('Test First Page'), findsOneWidget);

      // Show Home Page
      await tester.tap(find.byKey(const ValueKey(_kTestGoHomePageButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title Cupertino Page'), findsOneWidget);

      // Go Back First Page
      await tester
          .tap(find.byKey(const ValueKey(_kTestStandardPageBackButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test First Page'), findsOneWidget);
    });

    tApp.dispose();
  });
}

// Test Multi Tabs Material Page
class _TestFirstPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'Test First Page'),
        ),
      ),
      body: ListView(
        children: [
          TextButton(
            key: const ValueKey(_kTestGoSecondPageButton),
            child: const Text("Go to Second Page"),
            onPressed: () {
              context.go<_TestSecondPage, void>(null);
            },
          ),
          TextButton(
            key: const ValueKey(_kTestGoHomePageButton),
            child: const Text("Go to Test Home Page"),
            onPressed: () {
              context.go<_TestHomePage, void>(null);
            },
          ),
          TextButton(
            key: const ValueKey(_kTestGoMyPageButton),
            child: const Text("Go to Test My Page"),
            onPressed: () {
              context.go<_TestMyPage, void>(null);
            },
          ),
          TextButton(
            key: const ValueKey(_kTestGoTitlePageButton),
            child: const Text("Go to Title Page"),
            onPressed: () {
              context.go<_TestTitlePage, void>(null);
            },
          ),
          TextButton(
            key: const ValueKey(_kTestGoTitleDetailsPageButton),
            child: const Text("Go to Title Details Page"),
            onPressed: () {
              context.go<_TestTitleDetailsPage, void>(null);
            },
          ),
          TextButton(
            key: const ValueKey(_kTestGoMyFavoritePageButton),
            child: const Text("Go to MyFavorite Page"),
            onPressed: () {
              context.go<_TestMyFavoritePage, void>(null);
            },
          ),
        ],
      ),
    );
  }
}

class _TestSecondPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'Test Second Page'),
        ),
      ),
      body: ListView(
        children: [
          TextButton(
            key: const ValueKey(_kTestGoHomePageButton),
            child: const Text("Go to Test Home Page"),
            onPressed: () {
              context.go<_TestHomePage, void>(null);
            },
          ),
        ],
      ),
    );
  }
}

class _TestAppTab extends StatelessWidget {
  const _TestAppTab({
    required this.body,
    this.appBar,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    var tInterfacePage =
        ModalRoute.of(context)!.settings as StandardPageInterface;
    var tType = tInterfacePage.factoryObject.parentPageType;
    int tIndex = 0;
    if (tType == _TestHomePage) {
      tIndex = 0;
    } else if (tType == _TestMyPage) {
      tIndex = 1;
    }

    return Scaffold(
      body: body,
      appBar: appBar,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          switch (index) {
            case 0:
              context.go<_TestHomePage, void>(null);
              break;
            case 1:
              context.go<_TestMyPage, void>(null);
              break;
            default:
              break;
          }
        },
        currentIndex: tIndex,
        selectedItemColor: Colors.red,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'mypage'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _TestHomePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return childNavigator ?? const SizedBox.shrink();
  }
}

class _TestTitlePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return _TestAppTab(
      appBar: AppBar(
        title: const Text("Test Title Page"),
        automaticallyImplyLeading: false,
        // Purposely not using `const` because the current version of flutter is flagging const constructors as not being executed in coverage tests.
        // ignore: prefer_const_constructors
        leading: StandardPageBackButton(
          key: const ValueKey(_kTestStandardPageBackButton),
        ),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return const Text(
                  "Title Page",
                );
              },
            ),
          ),
          TextButton(
            key: const ValueKey(_kTestGoTitleDetailsPageButton),
            child: const Text("Go to Test Title Details Page"),
            onPressed: () {
              context.go<_TestTitleDetailsPage, void>(null);
            },
          ),
        ],
      ),
    );
  }
}

class _TestTitleDetailsPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return _TestAppTab(
      appBar: AppBar(
        title: const Text("Title Details Page"),
        automaticallyImplyLeading: false,
        leading: const StandardPageBackButton(
          key: ValueKey(_kTestStandardPageBackButton),
        ),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return const Text(
                  "Test Title Details Page",
                );
              },
            ),
          ),
          TextButton(
            key: const ValueKey(_kTestGoMyPageButton),
            child: const Text("Go to Test My Page"),
            onPressed: () {
              context.go<_TestMyPage, void>(null);
            },
          ),
        ],
      ),
    );
  }
}

class _TestMyPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return childNavigator ?? const SizedBox.shrink();
  }
}

class _TestMyFavoritePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return _TestAppTab(
      appBar: AppBar(
        title: const Text("MyFavorite Page"),
        automaticallyImplyLeading: false,
        leading: const StandardPageBackButton(
          key: ValueKey(_kTestStandardPageBackButton),
        ),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return const Text(
                  "Test MyFavorite Page",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Test Multi Tabs Cupertino Page
class _TestCupertinoFirstPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Test First Page'),
      ),
      child: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return Text(
                  l(context, 'plurals.test1', {
                    'count': context
                        .select<LocalConfig, int>((v) => v.getInt('counter'))
                  }),
                );
              },
            ),
          ),
          CupertinoButton(
            key: const ValueKey(_kTestGoHomePageButton),
            child: const Text("Go to Test Home Page"),
            onPressed: () {
              context.go<_TestCupertinoHomePage, void>(null);
            },
          ),
          CupertinoButton(
            key: const ValueKey(_kTestGoTitlePageButton),
            child: const Text("Go to Test Title Page"),
            onPressed: () {
              context.go<_TestCupertinoTitlePage, void>(null);
            },
          ),
          CupertinoButton(
            key: const ValueKey(_kTestGoMyPageButton),
            child: const Text("Go to Test My Page"),
            onPressed: () {
              context.go<_TestCupertinoMyPage, void>(null);
            },
          ),
          CupertinoButton(
            key: const ValueKey(_kTestGoMyFavoritePageButton),
            child: const Text("Go to Test MyFavorite Page"),
            onPressed: () {
              context.go<_TestCupertinoMyFavoritePage, void>(null);
            },
          ),
        ],
      ),
    );
  }
}

class _TestCupertinoAppBar extends StatelessWidget {
  const _TestCupertinoAppBar({
    required this.body,
    this.appBar,
  });

  final Widget body;
  final Widget? appBar;

  @override
  Widget build(BuildContext context) {
    var tInterfacePage =
        ModalRoute.of(context)!.settings as StandardPageInterface;
    var tType = tInterfacePage.factoryObject.parentPageType;
    int tIndex = 0;
    if (tType == _TestCupertinoHomePage) {
      tIndex = 0;
    } else if (tType == _TestCupertinoMyPage) {
      tIndex = 1;
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const StandardPageBackButton(
          key: ValueKey(_kTestStandardPageBackButton),
        ),
        middle: tIndex == 0 ? const Text('Home Page') : const Text('My Page'),
      ),
      child: Column(
        children: [
          Expanded(
            child: body,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CupertinoButton(
                onPressed: () {
                  context.go<_TestCupertinoHomePage, void>(null);
                },
                child: const Icon(CupertinoIcons.home),
              ),
              CupertinoButton(
                onPressed: () {
                  context.go<_TestCupertinoMyFavoritePage, void>(null);
                },
                child: const Icon(CupertinoIcons.heart),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestCupertinoHomePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return childNavigator ?? const SizedBox.shrink();
  }
}

class _TestCupertinoTitlePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return _TestCupertinoAppBar(
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return const Text(
                  "Test Title Cupertino Page",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCupertinoMyPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return childNavigator ?? const SizedBox.shrink();
  }
}

class _TestCupertinoMyFavoritePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return _TestCupertinoAppBar(
      appBar: AppBar(
        title: const Text("Test Title Cupertino Page"),
        automaticallyImplyLeading: false,
        leading: const StandardPageBackButton(
          key: ValueKey(_kTestStandardPageBackButton),
        ),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return const Text(
                  "Title Cupertino Page",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
