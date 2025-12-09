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

  testWidgets('Standard Nested Page hasNestedPages Test', (
    WidgetTester tester,
  ) async {
    final tStandardFactory = StandardPageFactory<TestPageA, void>(
      create: (data) => TestPageA(),
    );

    final tNestedFactory = StandardPageWithNestedNavigatorFactory<TestNestedA>(
      create: (data) => TestNestedA(),
      nestedPageFactories: [
        StandardPageFactory<TestPageA, void>(create: (data) => TestPageA()),
      ],
    );

    expect(tStandardFactory.hasNestedPages, isFalse);
    expect(tNestedFactory.hasNestedPages, isTrue);

    expect(tStandardFactory.hasChildPages, isFalse);
    expect(tNestedFactory.hasChildPages, isFalse);
  });

  testWidgets('Standard Nested Page Context Go Test', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

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
                ),
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
                ),
              ],
            ),
            StandardPageWithNestedNavigatorFactory<TestNestedB>(
              create: (data) => TestNestedB(),
              nestedPageFactories: [
                StandardPageFactory<TestPageC, void>(
                  create: (data) => TestPageC(),
                ),
                StandardPageFactory<TestCustomPageA, void>(
                  create: (data) => TestCustomPageA(),
                  pageBuilder:
                      (
                        child,
                        name,
                        pageData,
                        pageKey,
                        restorationId,
                        standardPageKey,
                        factoryObject,
                      ) => StandardCustomPage(
                        name: 'Test Custom Standard Page',
                        key: const ValueKey('test-custom-key'),
                        restorationId: 'custom-restorationId',
                        standardPageKey: standardPageKey,
                        factoryObject: factoryObject,
                        barrierColor: Colors.blueAccent,
                        child: Column(
                          children: [
                            Expanded(child: child),
                            const Text('add-custom-standard-page-widget'),
                          ],
                        ),
                        transitionDuration: const Duration(milliseconds: 500),
                        transitionBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                      ),
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

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestPageA',
          'TestPageB',
          'TestNestedB',
          'TestPageC',
        ],
        expectedRootPageInstanceNames: ['TestNestedA', 'TestNestedB'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA', 'TestPageB'],
          'TestNestedB': ['TestPageC'],
        },
        expectedActiveStates: [false, false, false, true, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoA)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoNB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestPageB',
          'TestPageA',
          'TestNestedB',
          'TestPageC',
        ],
        expectedRootPageInstanceNames: ['TestNestedA', 'TestNestedB'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageB', 'TestPageA'],
          'TestNestedB': ['TestPageC'],
        },
        expectedActiveStates: [false, false, false, true, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoNA)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedB',
          'TestPageC',
          'TestNestedA',
          'TestPageB',
          'TestPageA',
        ],
        expectedRootPageInstanceNames: ['TestNestedB', 'TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageB', 'TestPageA'],
          'TestNestedB': ['TestPageC'],
        },
        expectedActiveStates: [false, false, true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      // The root page of TestNestedA, TestPageA, is always present in the history.
      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedB',
          'TestPageC',
          'TestNestedA',
          'TestPageA',
          'TestPageB',
        ],
        expectedRootPageInstanceNames: ['TestNestedB', 'TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA', 'TestPageB'],
          'TestNestedB': ['TestPageC'],
        },
        expectedActiveStates: [false, false, true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedB', 'TestPageC'],
        expectedRootPageInstanceNames: ['TestNestedB'],
        expectedNestedPageInstanceNames: {
          'TestNestedB': ['TestPageC'],
        },
        expectedActiveStates: [true, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoCustomA)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title Custom A'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedB',
          'TestPageC',
          'Test Custom Standard Page',
        ],
        expectedRootPageInstanceNames: ['TestNestedB'],
        expectedNestedPageInstanceNames: {
          'TestNestedB': ['TestPageC', 'Test Custom Standard Page'],
        },
        expectedActiveStates: [true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedB', 'TestPageC'],
        expectedRootPageInstanceNames: ['TestNestedB'],
        expectedNestedPageInstanceNames: {
          'TestNestedB': ['TestPageC'],
        },
        expectedActiveStates: [true, true],
      );

      // Since there is no history, Pop is not possible.
      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('Standard Nested Page Test. activeFirstNestedPage=true', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              activeFirstNestedPage: true,
              nestedPageFactories: [
                StandardPageFactory<TestPageA, void>(
                  create: (data) => TestPageA(),
                ),
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
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

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageA', 'TestPageB'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA', 'TestPageB'],
        },
        expectedActiveStates: [true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoA)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageB', 'TestPageA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageB', 'TestPageA'],
        },
        expectedActiveStates: [true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageA', 'TestPageB'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA', 'TestPageB'],
        },
        expectedActiveStates: [true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA'],
        },
        expectedActiveStates: [true, true],
      );

      // Since there is no history, Pop is not possible.
      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('Standard Nested Page Test. activeFirstNestedPage=false', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              activeFirstNestedPage: false,
              nestedPageFactories: [
                StandardPageFactory<TestPageA, void>(
                  create: (data) => TestPageA(),
                ),
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
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

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageA', 'TestPageB'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA', 'TestPageB'],
        },
        expectedActiveStates: [true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoA)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageB', 'TestPageA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageB', 'TestPageA'],
        },
        expectedActiveStates: [true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageB'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageB'],
        },
        expectedActiveStates: [true, true],
      );

      // Since there is no history, Pop is not possible.
      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('Standard Nested Page Test. SplashPage on Nested Navigator', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    final App tApp = createApp(
      environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              nestedPageFactories: [
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
                ),
                StandardPageFactory<TestPageC, void>(
                  create: (data) => TestPageC(),
                ),
                // If placed at the beginning of nestedPageFactories,
                //it will be automatically added as the default page during processInitialRoute, so place it last.
                SplashPageFactory(
                  create: (data) => TestPageA(),
                  pageName: () => 'SplashPage',
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

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'SplashPage'],
        expectedRootPageInstanceNames: ['TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['SplashPage'],
        },
        expectedActiveStates: [true, true],
      );

      await tApp.standardAppPlugin.delegate?.processInitialRoute();
      await tester.pumpAndSettle();

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageB'],
        expectedRootPageInstanceNames: ['TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageB'],
        },
        expectedActiveStates: [true, true],
      );
    });

    tApp.dispose();
  });

  testWidgets("Standard Nested Page Context StandardAppRouterContext Test", (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

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
                ),
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
                ),
              ],
            ),
            StandardPageWithNestedNavigatorFactory<TestNestedB>(
              create: (data) => TestNestedB(),
              nestedPageFactories: [
                StandardPageFactory<TestPageC, void>(
                  create: (data) => TestPageC(),
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

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      final tContext = tApp.navigatorContext;

      expect(tContext, isNotNull);

      final tPageInstances = tContext.pageInstances;
      final tRootPageInstances = tContext.rootPageInstances;
      final tNestedPageInstances = tContext.nestedPageInstances;

      expect(tPageInstances.map((e) => e.name), [
        'TestNestedA',
        'TestPageA',
        'TestPageB',
        'TestNestedB',
        'TestPageC',
      ]);

      expect(tRootPageInstances.map((e) => e.name), [
        'TestNestedA',
        'TestNestedB',
      ]);

      expect(
        tNestedPageInstances.map(
          (k, v) => MapEntry(k.name, v.map((e) => e.name).toList()),
        ),
        {
          'TestNestedA': ['TestPageA', 'TestPageB'],
          'TestNestedB': ['TestPageC'],
        },
      );
    });

    tApp.dispose();
  });

  testWidgets('Standard Nested Page Test. check default nested page', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

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
                ),
                StandardPageWithNestedNavigatorFactory<TestNestedB>(
                  create: (data) => TestNestedB(),
                  nestedPageFactories: [
                    StandardPageWithNestedNavigatorFactory<TestNestedC>(
                      create: (data) => TestNestedC(),
                      nestedPageFactories: [
                        StandardPageFactory<TestPageB, void>(
                          create: (data) => TestPageB(),
                        ),
                        StandardPageFactory<TestPageC, void>(
                          create: (data) => TestPageC(),
                        ),
                      ],
                    ),
                    StandardPageFactory<TestPageD, void>(
                      create: (data) => TestPageD(),
                    ),
                    StandardPageFactory<TestPageE, void>(
                      create: (data) => TestPageE(),
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

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageA'],
        expectedRootPageInstanceNames: ['TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA'],
        },
        expectedActiveStates: [true, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoE)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title E'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestPageA',
          'TestNestedB',
          'TestNestedC',
          'TestPageB',
          'TestPageE',
        ],
        expectedRootPageInstanceNames: ['TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA', 'TestNestedB'],
          'TestNestedB': ['TestNestedC', 'TestPageE'],
          'TestNestedC': ['TestPageB'],
        },
        expectedActiveStates: [true, false, true, false, false, true],
      );

      // When TestPageB is popped, TestNestedC is also popped, but since the root page of TestNestedB is TestNestedC, it is added again.
      // Furthermore, since the root page of TestNestedC is TestPageB, it is also added again.
      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestBackButton)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title E'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestPageA',
          'TestNestedB',
          'TestNestedC',
          'TestPageB',
          'TestPageE',
        ],
        expectedRootPageInstanceNames: ['TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageA', 'TestNestedB'],
          'TestNestedB': ['TestNestedC', 'TestPageE'],
          'TestNestedC': ['TestPageB'],
        },
        expectedActiveStates: [true, false, true, false, false, true],
      );
    });

    tApp.dispose();
  });

  testWidgets(
    'Standard Nested Page Context Go Test. Navigating to the same page as the current navigator page.',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      final tNavigatorMode = TestNavigatorMode(
        StandardPageNavigationMode.moveToTop,
      );

      final App tApp = createApp(
        appWidget: Provider<TestNavigatorMode>.value(
          value: tNavigatorMode,
          child: StandardMaterialApp(
            onGenerateTitle: (context) => 'Generate Test Title',
            pages: [
              StandardPageWithNestedNavigatorFactory<TestNestedA>(
                create: (data) => TestNestedA(),
                nestedPageFactories: [
                  StandardPageWithNestedNavigatorFactory<TestNestedB>(
                    create: (data) => TestNestedB(),
                    nestedPageFactories: [
                      StandardPageFactory<TestPageA, void>(
                        create: (data) => TestPageA(),
                      ),
                      StandardPageFactory<TestPageB, void>(
                        create: (data) => TestPageB(),
                      ),
                    ],
                  ),
                  StandardPageWithNestedNavigatorFactory<TestNestedC>(
                    create: (data) => TestNestedC(),
                    nestedPageFactories: [
                      StandardPageFactory<TestPageC, void>(
                        create: (data) => TestPageC(),
                      ),
                      StandardPageFactory<TestPageD, void>(
                        create: (data) => TestPageD(),
                      ),
                      StandardPageFactory<TestPageE, void>(
                        create: (data) => TestPageE(),
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

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title B'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title C'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoD)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title D'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoE)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title E'), findsOneWidget);

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestNestedB',
            'TestPageA',
            'TestPageB',
            'TestNestedC',
            'TestPageC',
            'TestPageD',
            'TestPageE',
          ],
          expectedRootPageInstanceNames: ['TestNestedA'],
          expectedNestedPageInstanceNames: {
            'TestNestedA': ['TestNestedB', 'TestNestedC'],
            'TestNestedB': ['TestPageA', 'TestPageB'],
            'TestNestedC': ['TestPageC', 'TestPageD', 'TestPageE'],
          },
          expectedActiveStates: [
            true,
            false,
            false,
            false,
            true,
            false,
            false,
            true,
          ],
        );

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoNC)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title C'), findsOneWidget);

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestNestedB',
            'TestPageA',
            'TestPageB',
            'TestNestedC',
            'TestPageC',
          ],
          expectedRootPageInstanceNames: ['TestNestedA'],
          expectedNestedPageInstanceNames: {
            'TestNestedA': ['TestNestedB', 'TestNestedC'],
            'TestNestedB': ['TestPageA', 'TestPageB'],
            'TestNestedC': ['TestPageC'],
          },
          expectedActiveStates: [true, false, false, false, true, true],
        );

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoNC)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title C'), findsOneWidget);

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestNestedB',
            'TestPageA',
            'TestPageB',
            'TestNestedC',
            'TestPageC',
          ],
          expectedRootPageInstanceNames: ['TestNestedA'],
          expectedNestedPageInstanceNames: {
            'TestNestedA': ['TestNestedB', 'TestNestedC'],
            'TestNestedB': ['TestPageA', 'TestPageB'],
            'TestNestedC': ['TestPageC'],
          },
          expectedActiveStates: [true, false, false, false, true, true],
        );

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoNA)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title'), findsOneWidget);

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestNestedB',
            'TestPageA',
          ],
          expectedRootPageInstanceNames: ['TestNestedA'],
          expectedNestedPageInstanceNames: {
            'TestNestedA': ['TestNestedB'],
            'TestNestedB': ['TestPageA'],
          },
          expectedActiveStates: [true, true, true],
        );
      });

      tApp.dispose();
    },
  );

  group('Standard Nested Page Test. popGestureEnabled', () {
    // Assuming Android's predictive back gesture, check the state of popGestureEnabled.
    // The back gesture is enabled only when both isCurrent and popGestureEnabled of the Route are true.
    testWidgets('Standard Nested Page Test. popGestureEnabled pattern 1', (
      WidgetTester tester,
    ) async {
      await _setTestDeviceSize(tester);

      final tNavigatorMode = TestNavigatorMode(
        StandardPageNavigationMode.moveToTop,
      );

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
                  ),
                  StandardPageFactory<TestPageB, void>(
                    create: (data) => TestPageB(),
                  ),
                ],
              ),
              StandardPageWithNestedNavigatorFactory<TestNestedB>(
                create: (data) => TestNestedB(),
                nestedPageFactories: [
                  StandardPageFactory<TestPageC, void>(
                    create: (data) => TestPageC(),
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

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title B'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title C'), findsOneWidget);

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestPageA',
            'TestPageB',
            'TestNestedB',
            'TestPageC',
          ],
        );

        // The root navigator's current is TestNestedB, the current within TestNestedB is TestPageC, and the current within TestNestedA is TestPageB.

        final tPageInstances = tApp.standardAppPlugin.delegate?.pageInstances
            .cast<StandardPageInterface>();
        final tRouteList = tPageInstances!
            .map((e) => ModalRoute.of(e.standardPageKey.currentContext!)!)
            .toList();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          // TestNestedA
          (false, false),
          // TestPageA
          (false, false),
          // TestPageB
          (true, false),
          // TestNestedB
          (true, true),
          // TestPageC
          (true, false),
        ]);

        // The root navigator's current is TestNestedA, the current within TestNestedA is TestPageB, and the current within TestNestedB is TestPageC.
        await tester.tap(find.byKey(const ValueKey(kTestButtonGoNA)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title B'), findsOneWidget);

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
          (false, false),
          (true, false),
        ]);

        // The root navigator's current is Dialog, the current within TestNestedA is TestPageB, and the current within TestNestedB is TestPageC.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (false, false),
          (false, false),
          (true, false),
          (false, false),
          (true, false),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
          (false, false),
          (true, false),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
          (false, false),
          (true, false),
        ]);

        // The root navigator's current is TestNestedA, the current within TestNestedA is Dialog, and the current within TestNestedB is TestPageC.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (false, true),
          (false, false),
          (true, false),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
          (false, false),
          (true, false),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
          (false, false),
          (true, false),
        ]);
      });

      tApp.dispose();
    });

    testWidgets('Standard Nested Page Test. popGestureEnabled pattern 2', (
      WidgetTester tester,
    ) async {
      await _setTestDeviceSize(tester);

      final tNavigatorMode = TestNavigatorMode(
        StandardPageNavigationMode.moveToTop,
      );

      final App tApp = createApp(
        appWidget: Provider<TestNavigatorMode>.value(
          value: tNavigatorMode,
          child: StandardMaterialApp(
            onGenerateTitle: (context) => 'Generate Test Title',
            pages: [
              StandardPageWithNestedNavigatorFactory<TestNestedA>(
                create: (data) => TestNestedA(),
                nestedPageFactories: [
                  StandardPageWithNestedNavigatorFactory<TestNestedB>(
                    create: (data) => TestNestedB(),
                    nestedPageFactories: [
                      StandardPageFactory<TestPageA, void>(
                        create: (data) => TestPageA(),
                      ),
                      StandardPageFactory<TestPageB, void>(
                        create: (data) => TestPageB(),
                      ),
                    ],
                  ),
                  StandardPageWithNestedNavigatorFactory<TestNestedC>(
                    create: (data) => TestNestedC(),
                    nestedPageFactories: [
                      StandardPageFactory<TestPageC, void>(
                        create: (data) => TestPageC(),
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

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title B'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
        await tester.pumpAndSettle();
        expect(find.text('Test Title C'), findsOneWidget);

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestNestedB',
            'TestPageA',
            'TestPageB',
            'TestNestedC',
            'TestPageC',
          ],
        );

        // The root navigator's current is TestNestedA, the current within TestNestedA is TestNestedC, and the current within TestNestedC is TestPageC.
        // Also, the current within TestNestedB is TestPageB.

        final tPageInstances = tApp.standardAppPlugin.delegate?.pageInstances
            .cast<StandardPageInterface>();
        final tRouteList = tPageInstances!
            .map((e) => ModalRoute.of(e.standardPageKey.currentContext!)!)
            .toList();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          // TestNestedA
          (true, false),
          // TestNestedB
          (false, false),
          // TestPageA
          (false, false),
          // TestPageB
          (true, false),
          // TestNestedC
          (true, true),
          // TestPageC
          (true, false),
        ]);

        // The root navigator's current is Dialog, the current within TestNestedA is TestNestedC, and the current within TestNestedC is TestPageC.
        // Also, the current within TestNestedB is TestPageB.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (false, false),
          (false, false),
          (false, false),
          (true, false),
          (true, false),
          (true, false),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (false, false),
          (true, false),
          (true, true),
          (true, false),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (false, false),
          (true, false),
          (true, true),
          (true, false),
        ]);

        // The root navigator's current is TestNestedA, the current within TestNestedA is TestNestedC, and the current within TestNestedC is Dialog.
        // Also, the current within TestNestedB is TestPageB.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (false, false),
          (true, false),
          (true, false),
          (false, false),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (false, false),
          (true, false),
          (true, true),
          (true, false),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (false, false),
          (true, false),
          (true, true),
          (true, false),
        ]);
      });

      tApp.dispose();
    });

    testWidgets('Standard Nested Page Test. popGestureEnabled pattern 3', (
      WidgetTester tester,
    ) async {
      await _setTestDeviceSize(tester);

      final tNavigatorMode = TestNavigatorMode(
        StandardPageNavigationMode.moveToTop,
      );

      final App tApp = createApp(
        appWidget: Provider<TestNavigatorMode>.value(
          value: tNavigatorMode,
          child: StandardMaterialApp(
            onGenerateTitle: (context) => 'Generate Test Title',
            pages: [
              StandardPageWithNestedNavigatorFactory<TestNestedA>(
                create: (data) => TestNestedA(),
                nestedPageFactories: [
                  StandardPageWithNestedNavigatorFactory<TestNestedB>(
                    create: (data) => TestNestedB(),
                    nestedPageFactories: [
                      StandardPageFactory<TestPageA, void>(
                        create: (data) => TestPageA(),
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

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestNestedB',
            'TestPageA',
          ],
        );

        // The root navigator's current is TestNestedA, the current within TestNestedA is TestNestedB, and the current within TestNestedB is TestPageA.

        final tPageInstances = tApp.standardAppPlugin.delegate?.pageInstances
            .cast<StandardPageInterface>();
        final tRouteList = tPageInstances!
            .map((e) => ModalRoute.of(e.standardPageKey.currentContext!)!)
            .toList();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          // TestNestedA
          (true, false),
          // TestNestedB
          (true, false),
          // TestPageA
          (true, false),
        ]);

        // The root navigator's current is Dialog, the current within TestNestedA is TestNestedB, and the current within TestNestedB is TestPageA.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (false, false),
          (true, false),
          (true, false),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (true, false),
          (true, false),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (true, false),
          (true, false),
        ]);

        // The root navigator's current is TestNestedA, the current within TestNestedA is TestNestedB, and the current within TestNestedB is Dialog.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (true, false),
          (false, false),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (true, false),
          (true, false),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (true, false),
          (true, false),
        ]);
      });

      tApp.dispose();
    });

    testWidgets('Standard Nested Page Test. popGestureEnabled pattern 4', (
      WidgetTester tester,
    ) async {
      await _setTestDeviceSize(tester);

      final tNavigatorMode = TestNavigatorMode(
        StandardPageNavigationMode.moveToTop,
      );

      final App tApp = createApp(
        appWidget: Provider<TestNavigatorMode>.value(
          value: tNavigatorMode,
          child: StandardCupertinoApp(
            onGenerateTitle: (context) => 'Generate Test Title',
            pages: [
              StandardPageWithNestedNavigatorFactory<TestNestedA>(
                create: (data) => TestNestedA(),
                nestedPageFactories: [
                  StandardPageFactory<TestPageA, void>(
                    create: (data) => TestPageA(),
                  ),
                  StandardPageFactory<TestPageB, void>(
                    create: (data) => TestPageB(),
                  ),
                  StandardPageFactory<TestCustomPageA, void>(
                    create: (data) => TestCustomPageA(),
                    pageBuilder:
                        (
                          child,
                          name,
                          pageData,
                          pageKey,
                          restorationId,
                          standardPageKey,
                          factoryObject,
                        ) => StandardCustomPage(
                          name: 'Test Custom Standard Page',
                          key: const ValueKey('test-custom-key'),
                          restorationId: 'custom-restorationId',
                          standardPageKey: standardPageKey,
                          factoryObject: factoryObject,
                          barrierColor: Colors.blueAccent,
                          child: Column(
                            children: [
                              Expanded(child: child),
                              const Text('add-custom-standard-page-widget'),
                            ],
                          ),
                          transitionDuration: const Duration(milliseconds: 500),
                          transitionBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                              },
                        ),
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

        await tester.tap(find.byKey(const ValueKey(kTestButtonGoCustomA)));
        await tester.pumpAndSettle();

        expect(find.text('Test Title Custom A'), findsOneWidget);

        _checkPageInstances(
          tApp,
          expectedPageInstanceNames: [
            'TestNestedA',
            'TestPageA',
            'Test Custom Standard Page',
          ],
        );

        // The root navigator's current is TestNestedA, the current within TestNestedA is TestCustomPageA.

        final tPageInstances = tApp.standardAppPlugin.delegate?.pageInstances
            .cast<StandardPageInterface>();
        final tRouteList = tPageInstances!
            .map((e) => ModalRoute.of(e.standardPageKey.currentContext!)!)
            .toList();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          // TestNestedA
          (true, false),
          // TestPageA
          (false, false),
          // TestCustomPageA
          (true, true),
        ]);

        // The root navigator's current is Dialog, the current within TestNestedA is TestCustomPageA.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (false, false),
          (false, false),
          (true, false),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(find.byKey(const ValueKey(kTestButtonShowDialogRoot)));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
        ]);

        // The root navigator's current is TestNestedA, the current within TestNestedA is Dialog.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (false, true),
        ]);

        await tester.tap(find.byKey(const ValueKey(kTestButtonDialogPop)));
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
        ]);

        // When executing removeRoute instead of Pop.
        await tester.tap(
          find.byKey(const ValueKey(kTestButtonShowDialogCurrent)),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kTestButtonDialogRemoveRoute)),
        );
        await tester.pumpAndSettle();

        expect(tRouteList.map((e) => (e.isCurrent, e.popGestureEnabled)), [
          (true, false),
          (false, false),
          (true, true),
        ]);
      });

      tApp.dispose();
    });
  });

  group('Standard Nested Page StandardPageNavigationMode Test', () {
    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    App fCreateApp() {
      tNavigatorMode.mode = StandardPageNavigationMode.moveToTop;

      return createApp(
        appWidget: Provider<TestNavigatorMode>.value(
          value: tNavigatorMode,
          child: StandardMaterialApp(
            onGenerateTitle: (context) => 'Generate Test Title',
            pages: [
              StandardPageWithNestedNavigatorFactory<TestNestedA>(
                create: (data) => TestNestedA(),
                nestedPageFactories: [
                  StandardPageWithNestedNavigatorFactory<TestNestedB>(
                    create: (data) => TestNestedB(),
                    nestedPageFactories: [
                      StandardPageFactory<TestPageA, void>(
                        create: (data) => TestPageA(),
                      ),
                      StandardPageFactory<TestPageB, void>(
                        create: (data) => TestPageB(),
                      ),
                      StandardPageFactory<TestPageC, void>(
                        create: (data) => TestPageC(),
                      ),
                    ],
                  ),
                  StandardPageWithNestedNavigatorFactory<TestNestedC>(
                    create: (data) => TestNestedC(),
                    nestedPageFactories: [
                      StandardPageFactory<TestPageD, void>(
                        create: (data) => TestPageD(),
                      ),
                      StandardPageFactory<TestPageE, void>(
                        create: (data) => TestPageE(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    testWidgets(
      'Standard Nested Page StandardPageNavigationMode Test. StandardPageNavigationMode.replace',
      (WidgetTester tester) async {
        await _setTestDeviceSize(tester);

        final App tApp = fCreateApp();

        await tApp.run();

        await tApp.runProcess(() async {
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoD)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoE)));
          await tester.pumpAndSettle();

          _checkPageInstances(
            tApp,
            expectedPageInstanceNames: [
              'TestNestedA',
              'TestNestedB',
              'TestPageA',
              'TestPageB',
              'TestPageC',
              'TestNestedC',
              'TestPageD',
              'TestPageE',
            ],
            expectedRootPageInstanceNames: ['TestNestedA'],
            expectedNestedPageInstanceNames: {
              'TestNestedA': ['TestNestedB', 'TestNestedC'],
              'TestNestedB': ['TestPageA', 'TestPageB', 'TestPageC'],
              'TestNestedC': ['TestPageD', 'TestPageE'],
            },
            expectedActiveStates: [
              true,
              false,
              false,
              false,
              false,
              true,
              false,
              true,
            ],
          );

          tNavigatorMode.mode = StandardPageNavigationMode.replace;

          await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
          await tester.pumpAndSettle();

          _checkPageInstances(
            tApp,
            expectedPageInstanceNames: [
              'TestNestedA',
              'TestNestedC',
              'TestPageD',
              'TestNestedB',
              'TestPageA',
              'TestPageC',
              'TestPageB',
            ],
            expectedRootPageInstanceNames: ['TestNestedA'],
            expectedNestedPageInstanceNames: {
              'TestNestedA': ['TestNestedC', 'TestNestedB'],
              'TestNestedB': ['TestPageA', 'TestPageC', 'TestPageB'],
              'TestNestedC': ['TestPageD'],
            },
            expectedActiveStates: [
              true,
              false,
              false,
              true,
              false,
              false,
              true,
            ],
          );
        });

        tApp.dispose();
      },
    );

    testWidgets(
      'Standard Nested Page StandardPageNavigationMode Test. StandardPageNavigationMode.removeAbove',
      (WidgetTester tester) async {
        await _setTestDeviceSize(tester);

        final App tApp = fCreateApp();

        await tApp.run();

        await tApp.runProcess(() async {
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoD)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoE)));
          await tester.pumpAndSettle();

          _checkPageInstances(
            tApp,
            expectedPageInstanceNames: [
              'TestNestedA',
              'TestNestedB',
              'TestPageA',
              'TestPageB',
              'TestPageC',
              'TestNestedC',
              'TestPageD',
              'TestPageE',
            ],
            expectedRootPageInstanceNames: ['TestNestedA'],
            expectedNestedPageInstanceNames: {
              'TestNestedA': ['TestNestedB', 'TestNestedC'],
              'TestNestedB': ['TestPageA', 'TestPageB', 'TestPageC'],
              'TestNestedC': ['TestPageD', 'TestPageE'],
            },
            expectedActiveStates: [
              true,
              false,
              false,
              false,
              false,
              true,
              false,
              true,
            ],
          );

          tNavigatorMode.mode = StandardPageNavigationMode.removeAbove;

          await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
          await tester.pumpAndSettle();

          _checkPageInstances(
            tApp,
            expectedPageInstanceNames: [
              'TestNestedA',
              'TestNestedB',
              'TestPageA',
              'TestPageB',
            ],
            expectedRootPageInstanceNames: ['TestNestedA'],
            expectedNestedPageInstanceNames: {
              'TestNestedA': ['TestNestedB'],
              'TestNestedB': ['TestPageA', 'TestPageB'],
            },
            expectedActiveStates: [true, true, false, true],
          );
        });

        tApp.dispose();
      },
    );

    testWidgets(
      'Standard Nested Page StandardPageNavigationMode Test.StandardPageNavigationMode.removeAll',
      (WidgetTester tester) async {
        await _setTestDeviceSize(tester);

        final App tApp = fCreateApp();

        await tApp.run();

        await tApp.runProcess(() async {
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoD)));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey(kTestButtonGoE)));
          await tester.pumpAndSettle();

          _checkPageInstances(
            tApp,
            expectedPageInstanceNames: [
              'TestNestedA',
              'TestNestedB',
              'TestPageA',
              'TestPageB',
              'TestPageC',
              'TestNestedC',
              'TestPageD',
              'TestPageE',
            ],
            expectedRootPageInstanceNames: ['TestNestedA'],
            expectedNestedPageInstanceNames: {
              'TestNestedA': ['TestNestedB', 'TestNestedC'],
              'TestNestedB': ['TestPageA', 'TestPageB', 'TestPageC'],
              'TestNestedC': ['TestPageD', 'TestPageE'],
            },
            expectedActiveStates: [
              true,
              false,
              false,
              false,
              false,
              true,
              false,
              true,
            ],
          );

          tNavigatorMode.mode = StandardPageNavigationMode.removeAll;

          await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
          await tester.pumpAndSettle();

          _checkPageInstances(
            tApp,
            expectedPageInstanceNames: [
              'TestNestedA',
              'TestNestedB',
              'TestPageA',
              'TestPageB',
            ],
            expectedRootPageInstanceNames: ['TestNestedA'],
            expectedNestedPageInstanceNames: {
              'TestNestedA': ['TestNestedB'],
              'TestNestedB': ['TestPageA', 'TestPageB'],
            },
            expectedActiveStates: [true, true, false, true],
          );
        });

        tApp.dispose();
      },
    );
  });

  testWidgets('Standard Nested Page Remove Route Test', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              nestedPageFactories: [
                StandardPageWithNestedNavigatorFactory<TestNestedB>(
                  create: (data) => TestNestedB(),
                  nestedPageFactories: [
                    StandardPageFactory<TestPageA, void>(
                      create: (data) => TestPageA(),
                    ),
                    StandardPageFactory<TestPageB, void>(
                      create: (data) => TestPageB(),
                    ),
                  ],
                ),
                StandardPageWithNestedNavigatorFactory<TestNestedC>(
                  create: (data) => TestNestedC(),
                  nestedPageFactories: [
                    StandardPageFactory<TestPageC, void>(
                      create: (data) => TestPageC(),
                    ),
                    StandardPageFactory<TestPageD, void>(
                      create: (data) => TestPageD(),
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

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoD)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title D'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestNestedB',
          'TestPageA',
          'TestPageB',
          'TestNestedC',
          'TestPageC',
          'TestPageD',
        ],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestNestedB', 'TestNestedC'],
          'TestNestedB': ['TestPageA', 'TestPageB'],
          'TestNestedC': ['TestPageC', 'TestPageD'],
        },
        expectedActiveStates: [true, false, false, false, true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonRemoveRoute)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestNestedB',
          'TestPageA',
          'TestPageB',
          'TestNestedC',
          'TestPageC',
        ],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestNestedB', 'TestNestedC'],
          'TestNestedB': ['TestPageA', 'TestPageB'],
          'TestNestedC': ['TestPageC'],
        },
        expectedActiveStates: [true, false, false, false, true, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonRemoveRoute)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestNestedB',
          'TestPageA',
          'TestPageB',
        ],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestNestedB'],
          'TestNestedB': ['TestPageA', 'TestPageB'],
        },
        expectedActiveStates: [true, true, false, true],
      );
    });

    tApp.dispose();
  });

  testWidgets('Standard Nested Page Any Navigator Test', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              anyNestedPageFactories: [
                StandardPageFactory<TestPageC, void>(
                  create: (data) => TestPageC(),
                ),
              ],
              nestedPageFactories: [
                StandardPageWithNestedNavigatorFactory<TestNestedB>(
                  create: (data) => TestNestedB(),
                  nestedPageFactories: [
                    StandardPageFactory<TestPageA, void>(
                      create: (data) => TestPageA(),
                    ),
                  ],
                ),
                StandardPageWithNestedNavigatorFactory<TestNestedC>(
                  create: (data) => TestNestedC(),
                  nestedPageFactories: [
                    StandardPageFactory<TestPageB, void>(
                      create: (data) => TestPageB(),
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

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoNC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoNB)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestNestedC',
          'TestPageB',
          'TestNestedB',
          'TestPageA',
        ],
        expectedRootPageInstanceNames: ['TestNestedA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestNestedC', 'TestNestedB'],
          'TestNestedB': ['TestPageA'],
          'TestNestedC': ['TestPageB'],
        },
        expectedActiveStates: [true, false, false, true, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestNestedC',
          'TestPageB',
          'TestNestedB',
          'TestPageA',
          'TestPageC',
        ],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestNestedC', 'TestNestedB'],
          'TestNestedB': ['TestPageA', 'TestPageC'],
          'TestNestedC': ['TestPageB'],
        },
        expectedActiveStates: [true, false, false, true, false, true],
      );

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoNC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonGoC)));
      await tester.pumpAndSettle();
      expect(find.text('Test Title C'), findsOneWidget);

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: [
          'TestNestedA',
          'TestNestedB',
          'TestPageA',
          'TestPageC',
          'TestNestedC',
          'TestPageB',
          'TestPageC',
        ],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestNestedB', 'TestNestedC'],
          'TestNestedB': ['TestPageA', 'TestPageC'],
          'TestNestedC': ['TestPageB', 'TestPageC'],
        },
        expectedActiveStates: [true, false, false, false, true, false, true],
      );
    });

    tApp.dispose();
  });

  testWidgets('Standard Nested Page Group Root Test', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageFactory<TestPageA, void>(create: (data) => TestPageA()),
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              nestedPageFactories: [
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
                  groupRoot: true,
                ),
                StandardPageFactory<TestPageC, void>(
                  create: (data) => TestPageC(),
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

      _checkPageInstances(
        tApp,
        expectedPageInstanceNames: ['TestNestedA', 'TestPageB', 'TestPageA'],
        expectedRootPageInstanceNames: ['TestNestedA', 'TestPageA'],
        expectedNestedPageInstanceNames: {
          'TestNestedA': ['TestPageB'],
        },
        expectedActiveStates: [false, false, true],
      );
    });

    tApp.dispose();
  });

  testWidgets('Standard Nested Page Link Test', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    final tNavigatorMode = TestNavigatorMode(
      StandardPageNavigationMode.moveToTop,
    );

    final App tApp = createApp(
      appWidget: Provider<TestNavigatorMode>.value(
        value: tNavigatorMode,
        child: StandardMaterialApp(
          onGenerateTitle: (context) => 'Generate Test Title',
          pages: [
            StandardPageWithNestedNavigatorFactory<TestNestedA>(
              create: (data) => TestNestedA(),
              nestedPageFactories: [
                // /b
                StandardPageFactory<TestPageB, void>(
                  create: (data) => TestPageB(),
                  links: {r'b': (match, path) {}},
                  linkGenerator: (pageData) => 'b',
                ),
                // /
                StandardPageFactory<TestPageA, void>(
                  create: (data) => TestPageA(),
                  links: {r'': (match, path) {}},
                  linkGenerator: (pageData) => '',
                ),
                StandardPageWithNestedNavigatorFactory<TestNestedB>(
                  create: (data) => TestNestedB(),
                  links: {r'nested-b': (match, path) {}},
                  linkGenerator: (pageData) => 'nested-b',
                  nestedPageFactories: [
                    // /nested-b/c
                    StandardPageFactory<TestPageC, void>(
                      create: (data) => TestPageC(),
                      links: {r'c': (match, path) {}},
                      linkGenerator: (pageData) => 'c',
                    ),
                    // /d
                    StandardPageFactory<TestPageD, void>(
                      create: (data) => TestPageD(),
                      links: {r'/d': (match, path) {}},
                      linkGenerator: (pageData) => '/d',
                    ),
                    StandardPageWithNestedNavigatorFactory<TestNestedC>(
                      links: {r'nested-c': (match, path) {}},
                      linkGenerator: (pageData) => 'nested-c',
                      create: (data) => TestNestedC(),
                      nestedPageFactories: [
                        // /nested-b/nested-c/e
                        StandardPageFactory<TestPageE, void>(
                          create: (data) => TestPageE(),
                          links: {r'e': (match, path) {}},
                          linkGenerator: (pageData) => 'e',
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

      final tParser = tApp.standardAppPlugin.parser!;

      final tTestMap = {
        TestPageA: RouteInformation(uri: Uri.parse('/')),
        TestPageB: RouteInformation(uri: Uri.parse('/b')),
        TestPageC: RouteInformation(uri: Uri.parse('/nested-b/c')),
        TestPageD: RouteInformation(uri: Uri.parse('/d')),
        TestPageE: RouteInformation(uri: Uri.parse('/nested-b/nested-c/e')),
      };

      final tRouteDataMap = <Type, StandardRouteData>{};

      for (final tTest in tTestMap.entries) {
        final tResult = await tParser.parseRouteInformation(tTest.value);
        expect(tResult.factory?.pageType, tTest.key);

        tRouteDataMap[tTest.key] = tResult;
      }

      expect(tRouteDataMap.keys, tTestMap.keys);

      // generateLink test

      for (final tData in tRouteDataMap.entries) {
        final tResult = tParser.restoreRouteInformation(tData.value);
        expect(tResult?.uri.toString(), tTestMap[tData.key]?.uri.toString());
      }
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
      app.standardAppPlugin.delegate?.nestedPageInstances.map(
        (k, v) => MapEntry(k.name, v.map((e) => e.name).toList()),
      ),
      expectedNestedPageInstanceNames,
    );
  }

  if (expectedActiveStates != null) {
    expect(
      app.standardAppPlugin.delegate?.pageInstances.map(
        (e) => e.standardPageKey.currentState!.active,
      ),
      expectedActiveStates,
    );
  }
}

const String kTestButtonGoA = 'test-button-go-a';
const String kTestButtonGoB = 'test-button-go-b';
const String kTestButtonGoC = 'test-button-go-c';
const String kTestButtonGoD = 'test-button-go-d';
const String kTestButtonGoE = 'test-button-go-e';
const String kTestButtonGoNA = 'test-button-go-na';
const String kTestButtonGoNB = 'test-button-go-nb';
const String kTestButtonGoNC = 'test-button-go-nc';
const String kTestButtonGoCustomA = 'test-button-go-custom-a';
const String kTestBackButton = 'test-button-back';
const String kTestButtonRemoveRoute = 'test-button-remove-route';
const String kTestButtonShowDialogRoot = 'test-button-show-dialog-root-context';
const String kTestButtonShowDialogCurrent =
    'test-button-show-dialog-current-context';
const String kTestButtonDialogPop = 'test-button-dialog-pop';
const String kTestButtonDialogRemoveRoute = 'test-button-dialog-remove-route';

class TestNavigatorMode {
  StandardPageNavigationMode mode;

  TestNavigatorMode(this.mode);
}

List<Widget> _buildNavigateButtons(BuildContext context) {
  return [
    TextButton(
      key: const ValueKey(kTestButtonGoA),
      onPressed: () {
        context.go<TestPageA, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Page A'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoB),
      onPressed: () {
        context.go<TestPageB, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Page B'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoC),
      onPressed: () {
        context.go<TestPageC, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Page C'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoD),
      onPressed: () {
        context.go<TestPageD, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Page D'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoE),
      onPressed: () {
        context.go<TestPageE, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Page E'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoNA),
      onPressed: () {
        context.go<TestNestedA, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Nested A'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoNB),
      onPressed: () {
        context.go<TestNestedB, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Nested B'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoNC),
      onPressed: () {
        context.go<TestNestedC, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Nested C'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonGoCustomA),
      onPressed: () {
        context.go<TestCustomPageA, void>(
          null,
          context.read<TestNavigatorMode>().mode,
        );
      },
      child: const Text('Go to Test Custom A'),
    ),
    TextButton(
      key: const ValueKey(kTestBackButton),
      onPressed: () {
        // To replicate the behavior of the platform back button, attempt to pop from the rootNavigator.
        Navigator.of(context, rootNavigator: true).maybePop();
      },
      child: const Text('Back'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonRemoveRoute),
      onPressed: () {
        context.removeRoute();
      },
      child: const Text('Remove route'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonShowDialogRoot),
      onPressed: () {
        _showTestDialog(context, true);
      },
      child: const Text('Show Dialog from Root Context'),
    ),
    TextButton(
      key: const ValueKey(kTestButtonShowDialogCurrent),
      onPressed: () {
        _showTestDialog(context, false);
      },
      child: const Text('Show Dialog from Current Context'),
    ),
  ];
}

Future<Object?> _showTestDialog(BuildContext context, bool useRootNavigator) {
  return showDialog<Object>(
    context: context,
    useRootNavigator: useRootNavigator,
    builder: (context) {
      return AlertDialog(
        title: const Text('Test Dialog'),
        content: const Text('This is a test dialog.'),
        actions: [
          TextButton(
            key: const ValueKey(kTestButtonDialogPop),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Pop'),
          ),
          TextButton(
            key: const ValueKey(kTestButtonDialogRemoveRoute),
            onPressed: () {
              context.removeRoute();
            },
            child: const Text('RemoveRoute'),
          ),
        ],
      );
    },
  );
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

class TestNestedC extends StandardPageWithNestedNavigator {
  @override
  Widget buildPage(BuildContext context) {
    return nestedPages;
  }
}

class TestPageA extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Title')),
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
      appBar: AppBar(title: const Text('Test Title B')),
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

class TestPageC extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Title C')),
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

class TestPageD extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Title D')),
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

class TestPageE extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Title E')),
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

class TestCustomPageA extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'Test Title Custom A'))),
      body: SingleChildScrollView(
        child: Column(children: [..._buildNavigateButtons(context)]),
      ),
    );
  }
}
