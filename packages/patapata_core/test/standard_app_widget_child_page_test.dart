// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';
import 'utils/patapata_core_test_utils.dart';

class NoAutoProcessInitialRouteEnvironment extends Environment
    with StandardAppEnvironment {
  @override
  bool get autoProcessInitialRoute => false;
}

void main() {
  testInitialize();

  testWidgets('Standard Nested Page hasNestedPages Test',
      (WidgetTester tester) async {
    final tStandardFactory = StandardPageFactory<TestPageA, void>(
      create: (data) => TestPageA(),
    );

    final tParentFactory = StandardPageFactory<TestPageA, void>(
      create: (data) => TestPageA(),
      childPageFactories: [
        StandardChildPageFactory<TestPageB, void, void>(
          create: (data) => TestPageB(),
          createParentPageData: (pageData) => {},
        ),
      ],
    );

    expect(tStandardFactory.hasChildPages, isFalse);
    expect(tParentFactory.hasChildPages, isTrue);

    expect(tStandardFactory.hasNestedPages, isFalse);
    expect(tParentFactory.hasNestedPages, isFalse);
  });

  testWidgets('Standard Child Page Context Go Test',
      (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode =
        TestNavigatorMode(StandardPageNavigationMode.moveToTop);

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
              childPageFactories: [
                StandardChildPageFactory<TestPageB, void, void>(
                  create: (data) => TestPageB(),
                  createParentPageData: (pageData) {},
                  childPageFactories: [
                    StandardChildPageFactory<TestPageC, TestPageData, void>(
                      create: (data) => TestPageC(),
                      createParentPageData: (pageData) {},
                      pageDataWhenNull: () => TestPageData(
                        id: 1,
                        data: 'Default Test Data C',
                      ),
                    ),
                    StandardChildPageFactory<TestPageD, TestPageData, void>(
                      create: (data) => TestPageD(),
                      createParentPageData: (pageData) {},
                      pageDataWhenNull: () => TestPageData(
                        id: 2,
                        data: 'Default Test Data D',
                      ),
                      childPageFactories: [
                        StandardChildPageFactory<TestPageE, TestPageData,
                            TestPageData>(
                          create: (data) => TestPageE(),
                          pageDataWhenNull: () => TestPageData(
                            id: 3,
                            data: 'Default Test Data E',
                          ),
                          createParentPageData: (pageData) => TestPageData(
                            id: 2,
                            data: 'Test Data D',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoE)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title E'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageE',
          'TestPageB',
        ],
        expectedActiveStates: [
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();

      expect(find.text('Test Title E'), findsOneWidget);
      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageE',
        ],
        expectedActiveStates: [
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoEwithParent)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title E'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageB',
          'TestPageD',
          'TestPageE',
        ],
        expectedActiveStates: [
          false,
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageB',
          'TestPageD',
          'TestPageE',
          'TestPageC',
        ],
        expectedActiveStates: [
          false,
          false,
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoD)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title D'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageB',
          'TestPageE',
          'TestPageC',
          'TestPageD',
        ],
        expectedActiveStates: [
          false,
          false,
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageB',
          'TestPageE',
          'TestPageC',
        ],
        expectedActiveStates: [
          false,
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title E'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageB',
          'TestPageD',
          'TestPageE',
        ],
        expectedActiveStates: [
          false,
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title D'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageB',
          'TestPageD',
        ],
        expectedActiveStates: [
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
          'TestPageB',
        ],
        expectedActiveStates: [
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestPageA',
        ],
        expectedActiveStates: [
          true,
        ],
      );
    });

    tApp.dispose();
  });

  testWidgets('Standard Child Page in Nested Navigator Context Go Test',
      (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode =
        TestNavigatorMode(StandardPageNavigationMode.moveToTop);

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              nestedPageFactories: [
                StandardPageFactory<TestPageA, void>(
                  create: (data) => TestPageA(),
                  childPageFactories: [
                    StandardChildPageFactory<TestPageB, void, void>(
                      create: (data) => TestPageB(),
                      createParentPageData: (pageData) {},
                      childPageFactories: [
                        StandardChildPageFactory<TestPageC, TestPageData, void>(
                          create: (data) => TestPageC(),
                          createParentPageData: (pageData) {},
                          pageDataWhenNull: () => TestPageData(
                            id: 1,
                            data: 'Default Test Data C',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StandardPageWithNestedNavigatorFactory<TestNestedB>(
              create: (data) => TestNestedB(),
              nestedPageFactories: [
                StandardChildPageFactory<TestPageD, TestPageData, void>(
                  create: (data) => TestPageD(),
                  createParentPageData: (pageData) {},
                  pageDataWhenNull: () => TestPageData(
                    id: 2,
                    data: 'Default Test Data D',
                  ),
                  childPageFactories: [
                    StandardChildPageFactory<TestPageE, TestPageData,
                        TestPageData>(
                      create: (data) => TestPageE(),
                      pageDataWhenNull: () => TestPageData(
                        id: 3,
                        data: 'Default Test Data E',
                      ),
                      createParentPageData: (pageData) => TestPageData(
                        id: 2,
                        data: 'Test Data D',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoA)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoCwithParent)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestPageA',
          'TestPageB',
          'TestPageC',
        ],
        expectedRootPageInstanceNames: [
          'TestNestedA',
        ],
        expectedActiveStates: [
          true,
          false,
          false,
          true,
        ],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoEwithParent)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title E'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestPageA',
          'TestPageB',
          'TestPageC',
          'TestNestedB',
          'TestPageD',
          'TestPageE',
        ],
        expectedRootPageInstanceNames: [
          'TestNestedA',
          'TestNestedB',
        ],
        expectedActiveStates: [
          false,
          false,
          false,
          false,
          true,
          false,
          true,
        ],
      );
    });

    tApp.dispose();
  });
}

Future<void> _setTestDeviceSize(WidgetTester tester) async {
  await setTestDeviceSize(tester, const Size(500, 2000));
}

void _checkPageInstances(
  App app, {
  List<String>? expectedPageInstanceNames,
  List<String>? expectedRootPageInstanceNames,
  Map<String, List<String>>? expectedNestedPageInstanceNames,
  List<bool>? expectedActiveStates,
}) {
  if (expectedPageInstanceNames != null) {
    expect(
      app.standardAppPlugin.delegate?.pageInstances.map((e) => e.name),
      expectedPageInstanceNames,
    );
  }

  if (expectedRootPageInstanceNames != null) {
    expect(
      app.standardAppPlugin.delegate?.rootPageInstances.map((e) => e.name),
      expectedRootPageInstanceNames,
    );
  }

  if (expectedNestedPageInstanceNames != null) {
    expect(
      app.standardAppPlugin.delegate?.nestedPageInstances
          .map((k, v) => MapEntry(k.name, v.map((e) => e.name).toList())),
      expectedNestedPageInstanceNames,
    );
  }

  if (expectedActiveStates != null) {
    expect(
      app.standardAppPlugin.delegate?.pageInstances
          .map((e) => e.standardPageKey.currentState!.active),
      expectedActiveStates,
    );
  }
}

const String kTestButtonGoA = 'test-button-go-a';
const String kTestButtonGoB = 'test-button-go-b';
const String kTestButtonGoC = 'test-button-go-c';
const String kTestButtonGoD = 'test-button-go-d';
const String kTestButtonGoE = 'test-button-go-e';
const String kTestButtonGoCwithParent = 'test-button-go-c-with-parent';
const String kTestButtonGoDwithParent = 'test-button-go-d-with-parent';
const String kTestButtonGoEwithParent = 'test-button-go-e-with-parent';
const String kTestBackButton = 'test-button-back';

class TestNavigatorMode {
  StandardPageNavigationMode mode;

  TestNavigatorMode(this.mode);
}

class TestPageData {
  final int id;
  final String? data;

  TestPageData({
    required this.id,
    required this.data,
  });
}

List<Widget> _buildNavigateButtons(BuildContext context) {
  return [
    TextButton(
      key: const ValueKey(kTestButtonGoA),
      onPressed: () {
        context.go<TestPageA, void>(
            null, context.read<TestNavigatorMode>().mode);
      },
      child: const Text('Go to Test Page A'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoB),
      onPressed: () {
        context.go<TestPageB, void>(
            null, context.read<TestNavigatorMode>().mode);
      },
      child: const Text('Go to Test Page B'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoC),
      onPressed: () {
        context.go<TestPageC, TestPageData>(
            TestPageData(
              id: 1,
              data: 'Test Data C',
            ),
            context.read<TestNavigatorMode>().mode);
      },
      child: const Text('Go to Test Page C'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoD),
      onPressed: () {
        context.go<TestPageD, TestPageData>(
            TestPageData(
              id: 2,
              data: 'Test Data D',
            ),
            context.read<TestNavigatorMode>().mode);
      },
      child: const Text('Go to Test Page D'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoE),
      onPressed: () {
        context.go<TestPageE, TestPageData>(
            TestPageData(
              id: 3,
              data: 'Test Data E',
            ),
            context.read<TestNavigatorMode>().mode);
      },
      child: const Text('Go to Test Page E'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoCwithParent),
      onPressed: () {
        context.go<TestPageC, TestPageData>(
          TestPageData(
            id: 1,
            data: 'Test Data C',
          ),
          context.read<TestNavigatorMode>().mode,
          true,
        );
      },
      child: const Text('Go to Test Page D with Parent'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoDwithParent),
      onPressed: () {
        context.go<TestPageD, TestPageData>(
          TestPageData(
            id: 2,
            data: 'Test Data D',
          ),
          context.read<TestNavigatorMode>().mode,
          true,
        );
      },
      child: const Text('Go to Test Page D with Parent'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoEwithParent),
      onPressed: () {
        context.go<TestPageE, TestPageData>(
          TestPageData(
            id: 3,
            data: 'Test Data E',
          ),
          context.read<TestNavigatorMode>().mode,
          true,
        );
      },
      child: const Text('Go to Test Page E with Parent'),
    ),
    TextButton(
      key: const ValueKey(kTestBackButton),
      onPressed: () {
        // To replicate the behavior of the platform back button, attempt to pop from the rootNavigator.
        Navigator.of(context, rootNavigator: true).maybePop();
      },
      child: const Text('Back'),
    ),
  ];
}

class TestNestedA extends StandardPageWithNestedNavigator {
  @override
  Widget buildPage(BuildContext context) {
    return nestedPages;
  }
}

class TestNestedB extends StandardPageWithNestedNavigator {
  @override
  Widget buildPage(BuildContext context) {
    return nestedPages;
  }
}

class TestPageA extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Title'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text('Test Message');
                },
              ),
            ),
            ..._buildNavigateButtons(context),
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
        title: const Text('Test Title B'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text('Test Message B');
                },
              ),
            ),
            ..._buildNavigateButtons(context),
          ],
        ),
      ),
    );
  }
}

class TestPageC extends StandardPage<TestPageData> {
  @override
  Widget buildPage(BuildContext context) {
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
                  return const Text('Test Message C');
                },
              ),
            ),
            ..._buildNavigateButtons(context),
          ],
        ),
      ),
    );
  }
}

class TestPageD extends StandardPage<TestPageData> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Title D'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text('Test Message D');
                },
              ),
            ),
            ..._buildNavigateButtons(context),
          ],
        ),
      ),
    );
  }
}

class TestPageE extends StandardPage<TestPageData> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Title E'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Builder(
                builder: (context) {
                  return const Text('Test Message E');
                },
              ),
            ),
            ..._buildNavigateButtons(context),
          ],
        ),
      ),
    );
  }
}
