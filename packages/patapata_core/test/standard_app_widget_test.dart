// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:provider/provider.dart';
import 'utils/patapata_core_test_utils.dart';
import 'utils/standard_app_widget_test_data.dart';
import 'pages/startup_page.dart';

class NoAutoProcessInitialRouteEnvironment extends Environment
    with StandardAppEnvironment {
  @override
  bool get autoProcessInitialRoute => false;
}

class DefaultEnvironment extends Environment with StandardAppEnvironment {}

void main() {
  testInitialize();

  testWidgets("Standard Page Test, Initial Page", (WidgetTester tester) async {
    final App tApp = createApp(
      environment: DefaultEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Test, No auto processInitialRoute Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'title',
        pages: [
          SplashPageFactory(
            create: (data) => TestSplash(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsNothing);
      expect(find.text('Test Message'), findsNothing);

      tApp.getPlugin<StandardAppPlugin>()!.delegate!.processInitialRoute();

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page with Splash Test, Initial Page",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'title',
        pages: [
          SplashPageFactory(
            create: (data) => TestSplash(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Splash'), findsNothing);
      expect(find.text('Test Splash Message'), findsNothing);

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets(
      "Standard Page with Splash  Test, No auto processInitialRoute Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'title',
        pages: [
          SplashPageFactory(
            create: (data) => TestSplash(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Splash'), findsOneWidget);
      expect(find.text('Test Splash Message'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kProcessInitialRouteButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Test, Pages added", (WidgetTester tester) async {
    late TestChangeNotifierData tProvider;
    final App tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();
          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);

      await tester.pumpAndSettle();

      // update widget using provider
      tProvider.changeTitle('Change Test Title');

      tProvider.changePages([
        StandardPageFactory<TestPageB, void>(
          create: (data) => TestPageB(),
        ),
        StandardPageFactory<TestPageA, void>(
          create: (data) => TestPageA(),
        ),
      ]);

      await tester.pumpAndSettle();

      // Keep currently active page.
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Test, Pages removed", (WidgetTester tester) async {
    int tExceptionCount = 0;
    await runZonedGuarded(() async {
      late TestChangeNotifierData tProvider;
      final App tApp = createApp(
        appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
          create: (context) => TestChangeNotifierData(
            title: "title",
            pages: [
              StandardPageFactory<TestPageA, void>(
                create: (data) => TestPageA(),
              ),
              StandardPageFactory<TestPageB, void>(
                create: (data) => TestPageB(),
              ),
            ],
          ),
          child: Builder(builder: (context) {
            tProvider = context.watch<TestChangeNotifierData>();

            return StandardMaterialApp(
              onGenerateTitle: (context) => tProvider.title,
              pages: tProvider.pages,
            );
          }),
        ),
      );

      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Message'), findsOneWidget);

        await tester.pumpAndSettle();

        // update widget using provider
        tProvider.changeTitle('Change Test Title');

        tProvider.changePages([
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
          ),
        ]);

        await tester.pumpAndSettle();

        expect(find.text('Test Title B'), findsOneWidget);
        expect(find.text('Test Message B'), findsOneWidget);
      });

      tApp.dispose();
    }, (error, stackTrace) {
      if (error != 'Page deleted') {
        throw error;
      }
      tExceptionCount++;
    });

    expect(tExceptionCount, 1);
  });

  testWidgets("Standard Page Test, Pages removed in history",
      (WidgetTester tester) async {
    int tExceptionCount = 0;
    await runZonedGuarded(() async {
      late TestChangeNotifierData tProvider;
      final App tApp = createApp(
        appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
          create: (context) => TestChangeNotifierData(
            title: "title",
            pages: [
              StandardPageFactory<TestPageA, void>(
                create: (data) => TestPageA(),
              ),
              StandardPageFactory<TestPageB, void>(
                create: (data) => TestPageB(),
              ),
              StandardPageFactory<TestPageC, TestPageData>(
                create: (data) => TestPageC(),
              ),
            ],
          ),
          child: Builder(builder: (context) {
            tProvider = context.watch<TestChangeNotifierData>();

            return StandardMaterialApp(
              onGenerateTitle: (context) => tProvider.title,
              pages: tProvider.pages,
            );
          }),
        ),
      );

      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Message'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey(kGoPageDataButton)));

        await tester.pumpAndSettle();

        expect(find.text('Test Title C'), findsOneWidget);
        expect(find.text('Test Message C'), findsOneWidget);

        // update widget using provider
        tProvider.changeTitle('Change Test Title');

        tProvider.changePages([
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
          ),
          StandardPageFactory<TestPageC, TestPageData>(
            create: (data) => TestPageC(),
          ),
        ]);

        await tester.pumpAndSettle();

        expect(find.text('Test Title B'), findsOneWidget);
        expect(find.text('Test Message B'), findsOneWidget);
      });

      tApp.dispose();
    }, (error, stackTrace) {
      if (error != 'Page deleted') {
        throw error;
      }
      tExceptionCount++;
    });

    expect(tExceptionCount, 2);
  });

  testWidgets("Standard Page Test, Pages swapped", (WidgetTester tester) async {
    int tExceptionCount = 0;
    await runZonedGuarded(() async {
      late TestChangeNotifierData tProvider;
      final App tApp = createApp(
        appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
          create: (context) => TestChangeNotifierData(
            title: "title",
            pages: [
              StandardPageFactory<TestPageA, void>(
                create: (data) => TestPageA(),
              ),
            ],
          ),
          child: Builder(builder: (context) {
            tProvider = context.watch<TestChangeNotifierData>();
            return StandardMaterialApp(
              onGenerateTitle: (context) => tProvider.title,
              pages: tProvider.pages,
            );
          }),
        ),
      );

      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Message'), findsOneWidget);

        await tester.pumpAndSettle();

        // update widget using provider
        tProvider.changeTitle('Change Test Title');

        tProvider.changePages([
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
          ),
        ]);

        await tester.pumpAndSettle();

        expect(find.text('Test Title B'), findsOneWidget);
        expect(find.text('Test Message B'), findsOneWidget);
      });

      tApp.dispose();
    }, (error, stackTrace) {
      if (error != 'Page deleted') {
        throw error;
      }
      tExceptionCount++;
    });

    expect(tExceptionCount, 1);
  });

  testWidgets("Standard Page Test, Same pages (Not Update)",
      (WidgetTester tester) async {
    late TestChangeNotifierData tProvider;
    final App tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);

      await tester.pumpAndSettle();

      // If you do not transition to another page once,
      // the array will not be entered in _pageInstances
      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      // update widget using provider
      tProvider.changeTitle('Change Test Title');

      tProvider.changePages([
        StandardPageFactory<TestPageA, void>(
          create: (data) => TestPageA(),
        ),
        StandardPageFactory<TestPageB, void>(
          create: (data) => TestPageB(),
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
      expect(find.text('Test Message B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Test, Reverse order pages (Update Pages)",
      (WidgetTester tester) async {
    late TestChangeNotifierData tProvider;
    final App tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);

      // If you do not transition to another page once,
      // the array will not be entered in _pageInstances
      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      // update widget using provider
      tProvider.changeTitle('Change Test Title');

      tProvider.changePages([
        StandardPageFactory<TestPageB, void>(
          create: (data) => TestPageB(),
        ),
        StandardPageFactory<TestPageA, void>(
          create: (data) => TestPageA(),
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
      expect(find.text('Test Message B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Test, Did update widgets",
      (WidgetTester tester) async {
    int tExceptionCount = 0;
    await runZonedGuarded(() async {
      late TestChangeNotifierData tProvider;
      final App tApp = createApp(
        appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
          create: (context) => TestChangeNotifierData(
            title: "title",
            pages: [
              StandardPageFactory<TestPageA, void>(
                create: (data) => TestPageA(),
              ),
            ],
          ),
          child: Builder(builder: (context) {
            tProvider = context.watch<TestChangeNotifierData>();

            return StandardMaterialApp(
              onGenerateTitle: (context) => tProvider.title,
              pages: tProvider.pages,
              routableBuilder: tProvider.routableBuilder,
              willPopPage: tProvider.willPopPage,
            );
          }),
        ),
      );

      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        // update widget using provider
        tProvider.changeTitle('Change Test Title');
        tProvider.changePages(
          [
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
            ),
          ],
        );
        tProvider.changeRoutableBuilder((context, child) {
          return child!;
        });
        tProvider.changeWillPopPage((route, result) {
          return false;
        });

        await tester.pumpAndSettle();

        expect(find.text('Test Title B'), findsOneWidget);
        expect(find.text('Test Message B'), findsOneWidget);
      });
      tApp.dispose();
    }, (error, stackTrace) {
      if (error != 'Page deleted') {
        throw error;
      }
      tExceptionCount++;
    });

    expect(tExceptionCount, 1);
  });

  testWidgets(
      "Standard Page Test, UpdatePageFactories If the first page of pageFactories has a parentType.",
      (WidgetTester tester) async {
    int tExceptionCount = 0;
    await runZonedGuarded(() async {
      late TestChangeNotifierData tProvider;
      final App tApp = createApp(
        appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
          create: (context) => TestChangeNotifierData(
            title: "title",
            pages: [
              StandardPageFactory<TestPageF, void>(
                create: (data) => TestPageF(),
              ),
            ],
          ),
          child: Builder(builder: (context) {
            tProvider = context.watch<TestChangeNotifierData>();
            return StandardMaterialApp(
              onGenerateTitle: (context) => tProvider.title,
              pages: tProvider.pages,
            );
          }),
        ),
      );

      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(find.text('Test title F'), findsOneWidget);
        expect(find.text('Test Message F'), findsOneWidget);

        // update widget using provider
        tProvider.changeTitle('Change Test Title');

        tProvider.changePages([
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
            parentPageType: TestPageA,
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ]);

        await tester.pumpAndSettle();

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Message'), findsOneWidget);
      });

      tApp.dispose();
    }, (error, stackTrace) {
      if (error != 'Page deleted') {
        throw error;
      }
      tExceptionCount++;
    });

    expect(tExceptionCount, 1);
  });

  testWidgets("Standard Material App global Navigator Context Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Generate Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(StandardMaterialApp.globalNavigatorContext, isNotNull);
    });

    tApp.dispose();
  });

  testWidgets("Standard Cupertino Page Test", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => 'Generate Test Title',
        pages: [
          StandardPageFactory<TestPageF, void>(
            create: (data) => TestPageF(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Message F'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Context Go Test", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => 'Generate Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
            pageDataWhenNull: () => TestPageData(id: 0, data: 'test page data'),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(kGetPageFactoryButton)));

      await tester.pumpAndSettle();

      // Check Page Factory
      expect(pageFactory, isNotNull);
      expect(pageFactory, isA<StandardPageFactory<TestPageA, void>>());

      // Go To Test Page B
      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
      expect(find.text('Test Message B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kCheckNavigatorButton)));

      await tester.pumpAndSettle();

      // Check Navigator Data
      expect(navigatorState, isNotNull);
      expect(navigatorState, isA<NavigatorState>());
      expect(navigatorKey, isNotNull);
      expect(navigatorKey, isA<GlobalKey<NavigatorState>>());
      expect(navigatorContext, isNotNull);

      // Back Test Page
      await tester.tap(find.byKey(const ValueKey(kOnPopButton)));

      await tester.pumpAndSettle();

      // Go To Test Page B (Router Delegate)
      await tester.tap(find.byKey(const ValueKey(kGoToRouterDelegateButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
      expect(find.text('Test Message B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page PageData Test", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => 'Link Generate Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageC, TestPageData>(
            create: (data) => TestPageC(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(kGoPageDataButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Link Data is 10'), findsOneWidget);

      // Press the transition button twice to test onRefocus
      await tester.tap(find.byKey(const ValueKey(kGoPageDataButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Link Data is 20'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page PageData Test. pageDataWhenNull",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => 'Link Generate Test Title',
        pages: [
          StandardPageFactory<TestPageC, TestPageData>(
            pageDataWhenNull: () => TestPageData(
              id: 9999,
              data: 'test page data',
            ),
            create: (data) => TestPageC(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Link Data is 9999'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets(
      "Standard Page PageData Test. UpdatePageFactories pageDataWhenNull",
      (WidgetTester tester) async {
    int tExceptionCount = 0;
    await runZonedGuarded(() async {
      late TestChangeNotifierData tProvider;
      final App tApp = createApp(
        appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
          create: (context) => TestChangeNotifierData(
            title: "title",
            pages: [
              StandardPageFactory<TestPageA, void>(
                create: (data) => TestPageA(),
              ),
            ],
          ),
          child: Builder(builder: (context) {
            tProvider = context.watch<TestChangeNotifierData>();
            return StandardMaterialApp(
              onGenerateTitle: (context) => tProvider.title,
              pages: tProvider.pages,
            );
          }),
        ),
      );

      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Message'), findsOneWidget);

        await tester.pumpAndSettle();

        // update widget using provider
        tProvider.changeTitle('Change Test Title');

        tProvider.changePages([
          StandardPageFactory<TestPageC, TestPageData>(
            pageDataWhenNull: () => TestPageData(
              id: 9999,
              data: 'test page data',
            ),
            create: (data) => TestPageC(),
          ),
        ]);

        await tester.pumpAndSettle();

        expect(find.text('Test Link Data is 9999'), findsOneWidget);
      });

      tApp.dispose();
    }, (error, stackTrace) {
      if (error != 'Page deleted') {
        throw error;
      }
      tExceptionCount++;
    });

    expect(tExceptionCount, 1);
  });

  testWidgets("Standard Page Link Generator And Change PageData Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => 'Link Generate Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageC, TestPageData>(
            create: (data) => TestPageC(),
            links: {
              r'testPageData/(\d+)': (match, uri) => TestPageData(
                    data: 'test page data',
                    id: int.parse(match.group(1)!),
                  ),
            },
            linkGenerator: (pageData) => 'testPageData/${pageData.id}',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(kLinkButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title C'), findsOneWidget);
      expect(find.text('Test Message C'), findsOneWidget);
      expect(find.text('Test Link Data is 10'), findsOneWidget);
      expect(
          find.text('Test Generate Link is testPageData/10'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestChangePageDataButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Link Data is 30'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Change Listenable PageData Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => 'Change Listenable PageData Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageE, BaseListenable>(
            create: (data) => TestPageE(),
          ),
        ],
        routableBuilder: (context, child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ChangeListenableBool>(
                create: (context) => ChangeListenableBool(),
              ),
              ChangeNotifierProvider<ChangeListenableNumber>(
                create: (context) => ChangeListenableNumber(),
              ),
            ],
            child: child,
          );
        },
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(kGoChangeDataButton)));

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(kChangePageDataButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Data Number : 100'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kChangePageDataButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Data Bool : true'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page PageData Test Before Ready",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageG, TestPageData>(
            create: (data) => TestPageG(),
            pageDataWhenNull: () => TestPageData(
              data: 'test page data',
              id: 76,
            ),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('77 overridden test page data'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page On pop page", (WidgetTester tester) async {
    late TestChangeNotifierData tProvider;
    final App tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "Standard Page OnPopPage Test Title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
            willPopPage: tProvider.willPopPage,
          );
        }),
      ),
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
      expect(find.text('Test Message B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kOnPopButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);

      tProvider.changePages([
        StandardPageFactory<TestPageA, void>(
          create: (data) => TestPageA(),
        ),
        StandardPageFactory<TestPageB, void>(
          create: (data) => TestPageB(),
        ),
      ]);
      tProvider.changeWillPopPage((route, result) => true);

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
      expect(find.text('Test Message B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kOnPopButton)));

      await tester.pumpAndSettle();

      // here the provider made a change to return true
      expect(find.text('Test Title B'), findsOneWidget);
      expect(find.text('Test Message B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Custom Standard Page Test", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardCupertinoApp(
        onGenerateTitle: (context) => "Custom Standard Page Test",
        pages: [
          StandardPageFactory<TestPageD, void>(
            create: (data) => TestPageD(),
            pageBuilder: (
              child,
              name,
              pageData,
              pageKey,
              restorationId,
              standardPageKey,
              factoryObject,
            ) =>
                StandardCustomPage(
              name: "Test Custom Standard Page",
              arguments: TestPageData(id: 10, data: 'test-custom-test-data'),
              key: const ValueKey("test-custom-key"),
              restorationId: "custom-restorationId",
              standardPageKey: standardPageKey,
              factoryObject: factoryObject,
              opaque: false,
              barrierDismissible: true,
              barrierColor: Colors.blueAccent,
              child: Column(
                children: [
                  Expanded(child: child),
                  const Text("add-custom-standard-page-widget"),
                ],
              ),
              transitionDuration: const Duration(milliseconds: 500),
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position:
                      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                          .animate(animation),
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Page Id : 10'), findsOneWidget);
      expect(
          find.text('Test Page Data : test-custom-test-data'), findsOneWidget);
      expect(find.text('Test Interface Name : Test Custom Standard Page'),
          findsOneWidget);
      expect(find.text('Test Interface RestorationId : custom-restorationId'),
          findsOneWidget);
      expect(find.text('add-custom-standard-page-widget'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page StandardPageNavigationMode Test",
      (WidgetTester tester) async {
    late TestChangeNotifierData tProvider;
    App tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
              navigationMode: StandardPageNavigationMode.moveToTop,
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
              navigationMode: StandardPageNavigationMode.moveToTop,
            ),
            StandardPageFactory<TestPageC, TestPageData>(
              create: (data) => TestPageC(),
              navigationMode: StandardPageNavigationMode.removeAll,
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
            routableBuilder: tProvider.routableBuilder,
            willPopPage: tProvider.willPopPage,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      // PageA -[moveToTop]-> PageB -> -[moveToTop]-> PageC -[removeAll] -> PageC
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title C'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kOnPopButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title C'), findsOneWidget);
    });

    tApp.dispose();

    // PageA -[moveToTop]-> PageB -> -[moveToTop]-> PageC -[replace] -> PageA
    tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
              navigationMode: StandardPageNavigationMode.moveToTop,
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
              navigationMode: StandardPageNavigationMode.moveToTop,
            ),
            StandardPageFactory<TestPageC, TestPageData>(
              create: (data) => TestPageC(),
              navigationMode: StandardPageNavigationMode.replace,
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
            routableBuilder: tProvider.routableBuilder,
            willPopPage: tProvider.willPopPage,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title C'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kOnPopButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    tApp.dispose();

    // duplicate page key check (moveToTop)
    LocalKey tLocalKey = const ValueKey("test-page-key");
    tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
              navigationMode: StandardPageNavigationMode.moveToTop,
              pageKey: (pageData) => tLocalKey,
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
              navigationMode: StandardPageNavigationMode.moveToTop,
            ),
            StandardPageFactory<TestPageD, void>(
              create: (data) => TestPageD(),
              navigationMode: StandardPageNavigationMode.moveToTop,
              pageKey: (pageData) => tLocalKey,
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
            routableBuilder: tProvider.routableBuilder,
            willPopPage: tProvider.willPopPage,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonSecond)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    tApp.dispose();

    // duplicate page key check (replace)
    tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
              navigationMode: StandardPageNavigationMode.moveToTop,
              pageKey: (pageData) => tLocalKey,
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
              navigationMode: StandardPageNavigationMode.moveToTop,
            ),
            StandardPageFactory<TestPageD, void>(
              create: (data) => TestPageD(),
              navigationMode: StandardPageNavigationMode.replace,
              pageKey: (pageData) => tLocalKey,
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
            routableBuilder: tProvider.routableBuilder,
            willPopPage: tProvider.willPopPage,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonSecond)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    tApp.dispose();

    // duplicate page key check (removeAbove)
    tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
              navigationMode: StandardPageNavigationMode.moveToTop,
              pageKey: (pageData) => tLocalKey,
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
              navigationMode: StandardPageNavigationMode.moveToTop,
            ),
            StandardPageFactory<TestPageD, void>(
              create: (data) => TestPageD(),
              navigationMode: StandardPageNavigationMode.removeAbove,
              pageKey: (pageData) => tLocalKey,
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
            routableBuilder: tProvider.routableBuilder,
            willPopPage: tProvider.willPopPage,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kTestButtonSecond)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Keep History Test", (WidgetTester tester) async {
    late TestChangeNotifierData tProvider;
    final App tApp = createApp(
      appWidget: ChangeNotifierProvider<TestChangeNotifierData>(
        create: (context) => TestChangeNotifierData(
          title: "title",
          pages: [
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
              keepHistory: false,
            ),
            StandardPageFactory<TestPageB, void>(
              create: (data) => TestPageB(),
              keepHistory: false,
            ),
          ],
        ),
        child: Builder(builder: (context) {
          tProvider = context.watch<TestChangeNotifierData>();

          return StandardMaterialApp(
            onGenerateTitle: (context) => tProvider.title,
            pages: tProvider.pages,
            routableBuilder: tProvider.routableBuilder,
            willPopPage: tProvider.willPopPage,
          );
        }),
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey(kOnPopButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Group And GroupRoot Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Group And GroupRoot Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
            group: 'test-group',
            groupRoot: true,
          ),
          StandardPageFactory<TestPageC, TestPageData>(
            create: (data) => TestPageC(),
            links: {
              r'testPageData/(\d+)': (match, uri) => TestPageData(
                    data: 'test page data',
                    id: int.parse(match.group(1)!),
                  ),
            },
            linkGenerator: (pageData) => 'testPageData/${pageData.id}',
            group: 'test-group',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      // Show Link Page
      await tester.tap(find.byKey(const ValueKey(kLinkButton)));

      await tester.pumpAndSettle();

      // Go Back TestPageB
      await tester.tap(find.byKey(const ValueKey(kOnPopButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Analytics Event Test",
      (WidgetTester tester) async {
    testAnalytics = testAnalytics = TestAnalyticsEvent(
      name: "test analytics",
      data: {"data": 99999},
    );
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Analytics Event Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Analytics Event Data : {data: 99999}'), findsOneWidget);

      testAnalytics = null;
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Remove Route Test", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Analytics Event Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      // Go To Next Test A2 Page
      await tester.tap(find.byKey(const ValueKey(kTestButton)));

      await tester.pumpAndSettle();

      // Remove Route Page
      await tester.tap(find.byKey(const ValueKey(kRemoveRouteButton)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page App LinkHandler", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'App LinkHander Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    // add link handler
    var tPlugin = tApp.getPlugin<StandardAppPlugin>();
    tPlugin?.addLinkHandler(onLink);

    await tester.pumpAndSettle();

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(isLinkHander, isTrue);
      expect(linkHanderUri, isNotNull);
      expect(linkHanderUri!.path, equals('/'));

      // remove link handler
      tPlugin?.removeLinkHandler(onLink);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Context StandardAppRouterContext Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StandardAppRouterContext Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey(kGetStandardAppRouterContext)));

      await tester.pumpAndSettle();

      expect(buildContext, isNotNull);
      expect(buildContext!.router, isNotNull);
      expect(buildContext!.getPageFactory<TestPageA, void, void>(),
          isA<StandardPageWithResultFactory<TestPageA, void, void>>());
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Default Route Test. Link with an empty string",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
            links: {
              r'': (match, uri) {},
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Default Route Test", (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';

    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
            links: {
              r'': (match, uri) {},
            },
            linkGenerator: (pageData) => r'',
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Message'), findsNothing);

      expect(find.text('9999 test A'), findsOneWidget);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  testWidgets("Standard Page Default Route Test. No Auto processInitialRoute",
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';

    final App tApp = createApp(
      environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          SplashPageFactory(
            create: (data) => TestSplash(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
            links: {
              r'': (match, uri) {},
            },
            linkGenerator: (pageData) => r'',
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Splash'), findsOneWidget);

      tApp.getPlugin<StandardAppPlugin>()!.delegate!.processInitialRoute();

      await tester.pumpAndSettle();

      expect(find.text('9999 test A'), findsOneWidget);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  testWidgets("Standard Page Default Route Bad Links Test",
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';

    final App tApp = createApp(
      environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          SplashPageFactory(
            create: (data) => TestSplash(),
          ),
          StandardPageFactory<TestPageF, void>(
            create: (data) => TestPageF(),
            links: {
              r'': (match, uri) {},
            },
            linkGenerator: (pageData) => r'',
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => throw Exception('Bad Links Handler'),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    bool tGotIt = false;

    final tSub = Logger.root.onRecord.listen((record) {
      if (record.level == Level.INFO &&
          record.message == 'Exception during links callback' &&
          record.error is Exception &&
          record.error.toString() == 'Exception: Bad Links Handler') {
        tGotIt = true;
      }
    });

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Splash'), findsOneWidget);

      tApp.getPlugin<StandardAppPlugin>()!.delegate!.processInitialRoute();

      await tester.pumpAndSettle();

      expect(find.text('Test Message F'), findsOneWidget);

      expect(tGotIt, isTrue);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
    tSub.cancel();
  });

  testWidgets(
      "Standard Page Bad Links Test. Initial Page Not Found. To defaultRootPageFactory",
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';

    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          SplashPageFactory(
            create: (data) => TestSplash(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testB': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test B',
                  ),
            },
            group: 'test-group',
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  testWidgets(
      "Standard Page Bad Links Test. Initial Page Not Found. To defaultRootPageFactory. Bad Group Name",
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';

    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          SplashPageFactory(
            create: (data) => TestSplash(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
            group: 'test-group',
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testB': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test B',
                  ),
            },
            group: 'test-group',
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Splash'), findsOneWidget);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  testWidgets("Standard Page Bad Links Test. Web Page Not Found.",
      (WidgetTester tester) async {
    int tExceptionCount = 0;
    WebPageNotFound? tException;

    await runZonedGuarded(() async {
      StandardAppPlugin.debugIsWeb = true;
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';

      final App tApp = createApp(
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'Test Title',
          pages: [
            SplashPageFactory(
              create: (data) => TestSplash(),
            ),
            StandardPageFactory<TestPageA, void>(
              create: (data) => TestPageA(),
            ),
            StandardPageFactory<TestPageH, TestPageData>(
              create: (data) => TestPageH(),
              links: {
                r'testB': (match, uri) => TestPageData(
                      id: 9999,
                      data: 'test B',
                    ),
              },
              linkGenerator: (pageData) => r'testB',
            ),
          ],
        ),
      );

      tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        expect(find.text('Test Splash'), findsOneWidget);
      });

      tApp.dispose();
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
      StandardAppPlugin.debugIsWeb = false;
    }, (error, stackTrace) {
      if (error is! WebPageNotFound) {
        throw error;
      }
      tExceptionCount++;
      tException = error;
    });

    expect(tExceptionCount, 1);
    expect(tException?.logLevel, Level.INFO);
    expect(tException?.userLogLevel, Level.SHOUT);
  });

  testWidgets("Standard Page OS Extra Route Test", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageF, void>(
            create: (data) => TestPageF(),
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Message F'), findsOneWidget);

      // https://github.com/flutter/flutter/blob/master/packages/flutter/test/widgets/router_test.dart#L815C14-L815C14
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        const JSONMethodCodec().encodeMethodCall(
          const MethodCall('pushRoute', '/testA'),
        ),
        (_) {},
      );
      await tester.pump();

      await tester.pumpAndSettle();

      expect(find.text('9999 test A'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Plugin Route Test. parseRouteInformation Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      plugins: [
        TestDataParseRouteInformationPlugin(),
      ],
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageF, void>(
            create: (data) => TestPageF(),
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
          )
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('70 parsed route'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Plugin Route Test. getInitialRouteData Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      plugins: [
        TestGetInitialRoutePlugin(),
      ],
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageF, void>(
            create: (data) => TestPageF(),
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
          )
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('70 initial route'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets(
      "Standard Page Plugin Route Test. getInitialRouteData No Link Test",
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';

    final App tApp = createApp(
      plugins: [
        TestNoLinkPlugin(),
      ],
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          SplashPageFactory(create: (data) => TestSplash()),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
            links: {
              r'': (match, uri) {},
            },
            linkGenerator: (pageData) => r'',
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Splash'), findsOneWidget);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  testWidgets("Standard Page Plugin Route Test. defaultRootPageFactory Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      plugins: [
        TestGoDefaultRootPagePlugin(),
      ],
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
            links: {
              r'': (match, uri) {},
            },
            group: 'test-group',
            linkGenerator: (pageData) => r'',
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('9999 test plugin data'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets(
      "Standard Page Plugin Route Test. defaultRootPageFactory Bad Group Name Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      plugins: [
        TestGoDefaultRootPagePlugin(),
      ],
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
            links: {
              r'': (match, uri) {},
            },
            group: 'test-group',
            linkGenerator: (pageData) => r'',
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            group: 'test-group',
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Plugin Route Test. Null Data Test",
      (WidgetTester tester) async {
    Plugin tPlugin = TestNullDataPlugin();
    final App tApp = createApp(
      plugins: [
        tPlugin,
      ],
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'ProcessInitialRoute Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("Standard Page Bad Link Handler Test",
      (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageF, void>(
            create: (data) => TestPageF(),
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
          )
        ],
      ),
    );

    tApp.run();

    bool tGotIt = false;

    final tSub = Logger.root.onRecord.listen((record) {
      if (record.level == Level.SEVERE &&
          record.message == 'Error while handling link' &&
          record.error is Exception &&
          record.error.toString() == 'Exception: Bad Link') {
        tGotIt = true;
      }
    });

    tApp.getPlugin<StandardAppPlugin>()!.addLinkHandler((link) {
      throw Exception('Bad Link');
    });

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('Test Message F'), findsOneWidget);

      expect(tGotIt, isTrue);

      await tester.pumpAndSettle();
    });

    tApp.dispose();
    tSub.cancel();
  });

  testWidgets("Standard Page App Route Test", (WidgetTester tester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Group And Route Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageC, TestPageData>(
            create: (data) => TestPageC(),
            links: {
              r'testPageData/(\d+)': (match, uri) => TestPageData(
                    data: 'test page data',
                    id: int.parse(match.group(1)!),
                  ),
            },
            linkGenerator: (pageData) => 'testPageData/${pageData.id}',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey(kGetStandardAppPluginGenerateLink)));

      await tester.pumpAndSettle();

      expect(
          find.text('generateLink testText testPageData/9999'), findsOneWidget);

      // Show Link Page
      await tester.tap(find.byKey(const ValueKey(kGetStandardAppPluginRoute)));

      await tester.pumpAndSettle();

      expect(find.text('Test Title C'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("StandardAppPlugin with StartupNavigatorMixin Test",
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';
    final App tApp = createApp(
      environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupNavigatorMixin Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('SplashPage'), findsOneWidget);

      final tCompleter = Completer<bool>();

      tApp.getPlugin<StandardAppPlugin>()?.startupNavigateToPage(StartupPageA,
          (result) {
        tCompleter.complete(result as bool);
      });

      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete'));

      final tResult = await tCompleter.future;

      expect(tResult, true);

      tApp.getPlugin<StandardAppPlugin>()?.startupProcessInitialRoute();

      await tester.pumpAndSettle();

      expect(find.text('9999 test A'), findsOneWidget);

      tApp.getPlugin<StandardAppPlugin>()?.startupOnReset();

      await tester.pumpAndSettle();

      expect(find.text('SplashPage'), findsOneWidget);

      tApp.getPlugin<StandardAppPlugin>()?.startupProcessInitialRoute();

      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  testWidgets(
      "StandardAppPlugin with StartupNavigatorMixin Test. Call startupOnReset in the middle of a sequence.",
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/testA';
    final App tApp = createApp(
      environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupNavigatorMixin Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageH, TestPageData>(
            create: (data) => TestPageH(),
            links: {
              r'testA': (match, uri) => TestPageData(
                    id: 9999,
                    data: 'test A',
                  ),
            },
            linkGenerator: (pageData) => r'testA',
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();

      expect(find.text('SplashPage'), findsOneWidget);

      final tCompleter = Completer<bool>();

      tApp.getPlugin<StandardAppPlugin>()?.startupNavigateToPage(StartupPageA,
          (result) {
        tCompleter.complete(result as bool);
      });

      await tester.pumpAndSettle();

      expect(find.text('StartupPageA'), findsOneWidget);

      tApp.getPlugin<StandardAppPlugin>()?.startupOnReset();

      await tester.pumpAndSettle();

      expect(find.text('SplashPage'), findsOneWidget);

      tApp.getPlugin<StandardAppPlugin>()?.startupNavigateToPage(StartupPageA,
          (result) {
        tCompleter.complete(result as bool);
      });

      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete'));

      final tResult = await tCompleter.future;

      expect(tResult, true);

      tApp.getPlugin<StandardAppPlugin>()?.startupProcessInitialRoute();

      await tester.pumpAndSettle();

      expect(find.text('9999 test A'), findsOneWidget);
    });

    tApp.dispose();
    tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  // Test the results system
  testWidgets(
      'You can navigate to a StandardPageWithResult and get the result values',
      (widgetTester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageContextGoWithResult, void>(
            create: (data) => TestPageContextGoWithResult(),
          ),
          StandardPageWithResultFactory<TestPageWithResult, void, String>(
            create: (data) => TestPageWithResult(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();

      // Navigate to the page with results
      await widgetTester.tap(find.byKey(const ValueKey(kTestButton)));

      await widgetTester.pumpAndSettle();

      expect(find.text('TestPageWithResult'), findsOneWidget);

      // Tap the button to return the result
      await widgetTester.tap(find.byKey(const ValueKey(kTestButton)));

      await widgetTester.pumpAndSettle();

      // Check that the result is correct
      expect(find.text('TestPageContextGoWithResult'), findsOneWidget);
      expect(find.text('pageResult'), findsOneWidget);

      // Navigate to the page with results
      await widgetTester.tap(find.byKey(const ValueKey(kTestButton)));

      await widgetTester.pumpAndSettle();

      expect(find.text('TestPageWithResult'), findsOneWidget);

      // Tap the button to return the result
      await widgetTester.tap(find.byKey(const ValueKey(kTestButtonSecond)));

      await widgetTester.pumpAndSettle();

      // Check that the result is correct
      expect(find.text('TestPageContextGoWithResult'), findsOneWidget);
      expect(find.text('popResult'), findsOneWidget);
    });

    tApp.dispose();
  });

  // Test the StandardAppApp extension on App
  testWidgets('StandardAppApp extension on App', (widgetTester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageContextGoWithResult, void>(
            create: (data) => TestPageContextGoWithResult(),
            links: {
              r'': (match, uri) {},
            },
            linkGenerator: (pageData) => '',
          ),
          StandardPageWithResultFactory<TestPageWithResult, void, String>(
            create: (data) => TestPageWithResult(),
            links: {
              r'results': (match, uri) {},
            },
            linkGenerator: (pageData) => 'results',
          ),
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
            links: {
              r'b': (match, uri) {},
            },
            linkGenerator: (pageData) => 'b',
          ),
          StandardPageFactory<TestPageRemoveRoute, void>(
            create: (data) => TestPageRemoveRoute(),
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();

      final tApp = getApp();

      expect(tApp.navigator, isNotNull);
      expect(tApp.navigatorContext, isNotNull);
      expect(find.text('TestPageContextGoWithResult'), findsOneWidget);

      String? tResult;

      tApp.goWithResult<TestPageWithResult, void, String>(null).then((value) {
        tResult = value;
      });

      await widgetTester.pumpAndSettle();

      expect(find.text('TestPageWithResult'), findsOneWidget);

      // Tap the button to return the result
      await widgetTester.tap(find.byKey(const ValueKey(kTestButton)));

      await widgetTester.pumpAndSettle();

      // Check that the result is correct
      expect(find.text('TestPageContextGoWithResult'), findsOneWidget);
      expect(tResult, 'pageResult');

      tApp.go<TestPageB, void>(null);
      await widgetTester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      tApp.route('results');
      await widgetTester.pumpAndSettle();

      expect(find.text('TestPageWithResult'), findsOneWidget);

      tApp.removeRoute();
      await widgetTester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);

      expect(
          tApp.generateLinkWithResult<TestPageWithResult, void, String>(null),
          'results');
      expect(tApp.generateLink<TestPageB, void>(null), 'b');

      tApp.go<TestPageRemoveRoute, void>(null);
      await widgetTester.pumpAndSettle();

      expect(find.text('TestPageRemoveRoute'), findsOneWidget);

      await widgetTester.tap(find.byKey(const ValueKey(kTestButton)));
      await widgetTester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('You can access navigation APIs from routableBuilder',
      (widgetTester) async {
    final tCompleter = Completer<void>();
    bool tInited = false;
    BuildContext? tContext;

    final App tApp = createApp(
      // environment: NoAutoProcessInitialRouteEnvironment(),
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageRemoveRoute, void>(
            create: (data) => TestPageRemoveRoute(),
          ),
        ],
        routableBuilder: (context, child) {
          tContext = context;

          if (!tInited) {
            tInited = true;

            Future.microtask(() async {
              tContext!.go<TestPageRemoveRoute, void>(null);

              await widgetTester.pumpAndSettle();

              expect(find.text('TestPageRemoveRoute'), findsOneWidget);

              tCompleter.complete();
            });
          }

          return child!;
        },
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();
      await tCompleter.future;
    });

    tApp.dispose();
  });

  testWidgets('You can wrap the contents of a StandardPage with a Plugin',
      (widgetTester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
        ],
      ),
      plugins: [
        StandardPagePluginMixin.inline(
          buildPage: (context, child) => Stack(
            children: [
              child,
              const Text('StandardPagePluginMixin'),
            ],
          ),
        ),
      ],
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();

      expect(find.text('StandardPagePluginMixin'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('You can override the initial route with a Plugin',
      (widgetTester) async {
    final tPageBFactory = StandardPageFactory<TestPageB, void>(
      create: (data) => TestPageB(),
    );
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          tPageBFactory,
        ],
      ),
      plugins: [
        StandardAppRoutePluginMixin.inline(
          getInitialRouteData: () => Future.value(
            StandardRouteData(
              factory: tPageBFactory,
              pageData: null,
            ),
          ),
        ),
      ],
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();

      tApp.standardAppPlugin.delegate!.processInitialRoute();

      await widgetTester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('You can override route parsing with a Plugin',
      (widgetTester) async {
    final tPageBFactory = StandardPageFactory<TestPageB, void>(
      create: (data) => TestPageB(),
    );
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          tPageBFactory,
        ],
      ),
      plugins: [
        StandardAppRoutePluginMixin.inline(
          parseRouteInformation: (routeInformation) => Future.value(
            StandardRouteData(
              factory: tPageBFactory,
              pageData: null,
            ),
          ),
        ),
      ],
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();

      tApp.standardAppPlugin.delegate!.processInitialRoute();

      await widgetTester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets('You can transform a route with a Plugin', (widgetTester) async {
    final App tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'Test Title',
        pages: [
          StandardPageFactory<TestPageA, void>(
            create: (data) => TestPageA(),
          ),
          StandardPageFactory<TestPageB, void>(
            create: (data) => TestPageB(),
            links: {
              r'testB': (match, uri) {},
            },
            linkGenerator: (pageData) => 'testB',
          ),
        ],
      ),
      plugins: [
        StandardAppRoutePluginMixin.inline(
          transformRouteInformation: (routeInformation) => Future.value(
            RouteInformation(uri: Uri(path: '/testB')),
          ),
        ),
      ],
    );

    await tApp.run();

    await tApp.runProcess(() async {
      await widgetTester.pumpAndSettle();

      tApp.standardAppPlugin.delegate!.processInitialRoute();

      await widgetTester.pumpAndSettle();

      expect(find.text('Test Title B'), findsOneWidget);
    });

    tApp.dispose();
  });
}
