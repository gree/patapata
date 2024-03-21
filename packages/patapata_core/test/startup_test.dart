// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'utils/patapata_core_test_utils.dart';
import 'pages/startup_page.dart';

void main() {
  test('StartupNavigatorMixin blank test', () async {
    final tPlugin = TestBlankNavigatorPlugin();

    // No exceptions thrown
    tPlugin.startupNavigateToPage(Object, (result) {});
    tPlugin.startupOnReset();
    tPlugin.startupProcessInitialRoute();
  });

  test('StartupNavigatorMixin test', () async {
    final tPlugin = TestNavigatorPlugin();

    bool tNavigateResult = false;
    tPlugin.startupNavigateToPage(StartupPageA, (result) {
      tNavigateResult = result as bool;
    });
    tPlugin.startupOnReset();
    tPlugin.startupProcessInitialRoute();

    expect(tPlugin.startupNavigateToPageCalled, true);
    expect(tPlugin.navigatedPage, StartupPageA);
    expect(tPlugin.startupProcessInitialRouteCalled, true);
    expect(tPlugin.startupOnResetCalled, true);
    expect(tNavigateResult, true);
  });

  testWidgets("StartupSequence test", (WidgetTester tester) async {
    StateA? tStateA;
    StateB? tStateB;
    StateC? tStateC;
    StateD? tStateD;

    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StartupPageFactory<StartupPageB>(
            create: (data) => StartupPageB(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        waitSplashScreenDuration: const Duration(milliseconds: 2000),
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => tStateA = StateA(startupSequence),
            [
              LogicStateTransition<StateB>(),
            ],
          ),
          StartupStateFactory<StateB>(
            (startupSequence) => tStateB = StateB(startupSequence),
            [
              LogicStateTransition<StateC>(),
            ],
          ),
          StartupStateFactory<StateC>(
            (startupSequence) => tStateC = StateC(startupSequence),
            [
              LogicStateTransition<StateD>(),
            ],
          ),
          StartupStateFactory<StateD>(
            (startupSequence) => tStateD = StateD(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);
      expect(tStateA?.processed, true);
      expect(tStateB?.processed, null);
      expect(tStateC?.processed, null);
      expect(tStateD?.processed, null);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('SplashPage'), findsOneWidget);
      expect(tStateB?.processed, true);
      expect(tStateB?.navigateResult, false);
      expect(tStateB?.pageResult, false);
      expect(tStateC?.processed, null);
      expect(tStateD?.processed, null);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tStateB?.navigateResult, false);
      expect(tStateB?.pageResult, false);
      expect(tStateC?.processed, null);
      expect(tStateD?.processed, null);

      await tester.tap(find.text('Complete'));
      expect(tStateB?.pageResult, true);

      await tester.pumpAndSettle();
      expect(find.text('StartupPageB'), findsOneWidget);
      expect(tStateB?.navigateResult, true);
      expect(tStateC?.processed, true);
      expect(tStateC?.navigateResult, false);
      expect(tStateC?.pageResult, false);

      await tester.tap(find.text('Complete'));
      expect(tStateC?.pageResult, true);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('HomePage'), findsOneWidget);
      expect(tStateD?.processed, true);
      expect(tStateC?.navigateResult, true);
    });

    tApp.dispose();
  });

  testWidgets("waitForComplete and onSuccess test",
      (WidgetTester tester) async {
    bool tOnSuccess = false;

    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => StateA(startupSequence),
            [],
          ),
        ],
        onSuccess: () => tOnSuccess = true,
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      final tWaitForComplete = Completer<void>();
      tApp.startupSequence!
          .waitForComplete()
          .then((value) => tWaitForComplete.complete());

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      await tWaitForComplete.future;

      await tester.pumpAndSettle();
      expect(find.text('HomePage'), findsOneWidget);

      // Already Complete. To achieve 100% test coverage.
      expect(tApp.startupSequence?.waitForComplete().runtimeType,
          SynchronousFuture<void>);

      expect(tOnSuccess, true);
    });

    tApp.dispose();
  });

  testWidgets("resetMachine test", (WidgetTester tester) async {
    StateA? tStateA;
    StateB? tStateB;
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => tStateA = StateA(startupSequence),
            [
              LogicStateTransition<StateB>(),
            ],
          ),
          StartupStateFactory<StateB>(
            (startupSequence) => tStateB = StateB(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tStateA?.processed, true);
      expect(tStateB?.processed, true);
      expect(tStateB?.navigateResult, false);
      expect(tStateB?.pageResult, false);

      final tOldStateA = tStateA;
      final tOldStateB = tStateB;
      await tester.tap(find.text('Reset'));

      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);
      expect(tStateA.hashCode, isNot(tOldStateA.hashCode));
      expect(tOldStateB?.navigateResult, false);
      expect(tOldStateB?.pageResult, false);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tStateA?.processed, true);
      expect(tStateB?.processed, true);
      expect(tStateB?.navigateResult, false);
      expect(tStateB?.pageResult, false);
      expect(tStateB.hashCode, isNot(tOldStateB.hashCode));

      await tester.tap(find.text('Complete'));

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('HomePage'), findsOneWidget);

      expect(tStateB?.navigateResult, true);
      expect(tStateB?.pageResult, true);
    });

    tApp.dispose();
  });

  testWidgets("error from logger test", (WidgetTester tester) async {
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => StateA(startupSequence),
            [
              LogicStateTransition<StateXB>(),
            ],
          ),
          StartupStateFactory<StateXB>(
            (startupSequence) => StateXB(startupSequence),
            [
              LogicStateTransition<StateC>(),
            ],
          ),
          StartupStateFactory<StateC>(
            (startupSequence) => StateC(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      Object? tError;
      StreamSubscription<ReportRecord> tLogLester =
          tApp.log.reports.listen((event) {
        tError = event.error;
      });

      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsNothing);

      expect(tApp.startupSequence?.error?.error, 'StateXB');
      expect(tError, 'StateXB');

      tLogLester.cancel();
    });

    tApp.dispose();
  });

  testWidgets("waitForComplete cacheError test", (WidgetTester tester) async {
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => StateA(startupSequence),
            [
              LogicStateTransition<StateXB>(),
            ],
          ),
          StartupStateFactory<StateXB>(
            (startupSequence) => StateXB(startupSequence),
            [
              LogicStateTransition<StateC>(),
            ],
          ),
          StartupStateFactory<StateC>(
            (startupSequence) => StateC(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      final tWaitForComplete = Completer<void>();
      tApp.startupSequence!.waitForComplete().catchError((error, stackTrace) {
        tWaitForComplete.completeError(error, stackTrace);
      });

      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsNothing);

      expect(
        () => tWaitForComplete.future,
        throwsA('StateXB'),
      );

      expect(tApp.startupSequence?.error?.error, 'StateXB');

      // Already Complete. To achieve 100% test coverage.
      expect(
        () => tApp.startupSequence?.waitForComplete(),
        throwsA('StateXB'),
      );
    });

    tApp.dispose();
  });

  testWidgets("onError test", (WidgetTester tester) async {
    Object? tError;
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => StateA(startupSequence),
            [
              LogicStateTransition<StateXB>(),
            ],
          ),
          StartupStateFactory<StateXB>(
            (startupSequence) => StateXB(startupSequence),
            [
              LogicStateTransition<StateC>(),
            ],
          ),
          StartupStateFactory<StateC>(
            (startupSequence) => StateC(startupSequence),
            [],
          ),
        ],
        onError: (error, stackTrace) {
          tError = error;
        },
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      Object? tErrorFromLogger;
      StreamSubscription<ReportRecord> tLogLester =
          tApp.log.reports.listen((event) {
        tErrorFromLogger = event.error;
      });

      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsNothing);

      expect(tError, 'StateXB');
      expect(tErrorFromLogger, null);

      tLogLester.cancel();
    });

    tApp.dispose();
  });

  testWidgets("error resetMachine test", (WidgetTester tester) async {
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => StateA(startupSequence),
            [
              LogicStateTransition<StateXB>(),
            ],
          ),
          StartupStateFactory<StateXB>(
            (startupSequence) => StateXB(startupSequence),
            [],
          ),
        ],
        onError: (e, stackTrace) {
          // To avoid extra logging. Already tested.
        },
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      final tError = tApp.startupSequence!.error!;
      expect(tError.error, 'StateXB');

      tApp.startupSequence!.resetMachine();

      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);
      expect(tApp.startupSequence!.error, null);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(tApp.startupSequence!.error!.error, 'StateXB');
      expect(tApp.startupSequence!.error, isNot(tError));
    });

    tApp.dispose();
  });

  testWidgets("navigateToPage throw LogicStateNotCurrent test",
      (WidgetTester tester) async {
    StateB? tStateB;

    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StartupPageFactory<StartupPageB>(
            create: (data) => StartupPageB(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => StateA(startupSequence),
            [
              LogicStateTransition<StateB>(),
            ],
          ),
          StartupStateFactory<StateB>(
            (startupSequence) => tStateB = StateB(startupSequence),
            [
              LogicStateTransition<StateC>(),
            ],
          ),
          StartupStateFactory<StateC>(
            (startupSequence) => StateC(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      expect(
        () => tStateB!.navigateToPage(StartupPageA, (result) {}),
        throwsA(isA<LogicStateNotCurrent>()),
      );
    });

    tApp.dispose();
  });

  testWidgets("resetMachine with splash timer active",
      (WidgetTester tester) async {
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        waitSplashScreenDuration: const Duration(milliseconds: 2000),
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => StateA(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      tApp.startupSequence!.resetMachine();

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('HomePage'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("State is reset during process", (WidgetTester tester) async {
    StateDelayed2000ms? tState;
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        waitSplashScreenDuration: const Duration(milliseconds: 16),
        startupStateFactories: [
          StartupStateFactory<StateDelayed2000ms>(
            (startupSequence) {
              final tS = StateDelayed2000ms(startupSequence);
              tState ??= tS;
              return tS;
            },
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle(const Duration(milliseconds: 20));

      tApp.startupSequence!.resetMachine();

      expect(() => tState!.onComplete, throwsA(isA<ResetStartupSequence>()));

      await tester.pumpAndSettle(const Duration(milliseconds: 2000));
      expect(find.text('HomePage'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("complete before process completion",
      (WidgetTester tester) async {
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateCompleteBeforeProcess>(
            (startupSequence) => StateCompleteBeforeProcess(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle(const Duration(milliseconds: 3000));
      expect(find.text('HomePage'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("completeError before process completion",
      (WidgetTester tester) async {
    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateCompleteErrorBeforeProcess>(
            (startupSequence) =>
                StateCompleteErrorBeforeProcess(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle(const Duration(milliseconds: 3000));

      expect(() => tApp.startupSequence!.waitForComplete(),
          throwsA(isA<String>()));
      expect(tApp.startupSequence!.error?.error,
          'StateCompleteErrorBeforeProcess');
    });

    tApp.dispose();
  });

  testWidgets("back state test", (WidgetTester tester) async {
    StateC? tFirstStateC;
    StartupState? tCurrentState;

    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StartupPageFactory<StartupPageB>(
            create: (data) => StartupPageB(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => tCurrentState = StateA(startupSequence),
            [
              LogicStateTransition<StateB>(),
            ],
          ),
          StartupStateFactory<StateB>(
            (startupSequence) => tCurrentState = StateB(startupSequence),
            [
              LogicStateTransition<StateC>(),
            ],
          ),
          StartupStateFactory<StateC>(
            (startupSequence) {
              final tState = StateC(startupSequence);
              tFirstStateC ??= tState;
              return tCurrentState = tState;
            },
            [
              LogicStateTransition<StateD>(),
            ],
          ),
          StartupStateFactory<StateD>(
            (startupSequence) => tCurrentState = StateD(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsOneWidget);
      await tester.tap(find.text('Complete'));

      await tester.pumpAndSettle();
      expect(find.text('StartupPageB'), findsOneWidget);
      expect(tCurrentState, isA<StateC>());

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tCurrentState, isA<StateB>());
      expect(tFirstStateC?.processed, true);
      expect(tFirstStateC?.navigateResult, false);
      expect(tFirstStateC?.pageResult, false);

      await tester.tap(find.text('Complete'));

      await tester.pumpAndSettle();
      expect(find.text('StartupPageB'), findsOneWidget);
      expect(tCurrentState, isA<StateC>());
      expect(tCurrentState, isNot(tFirstStateC));

      await tester.tap(find.text('Complete'));
      expect(tCurrentState, isA<StateD>());

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('HomePage'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("back state test. remove route", (WidgetTester tester) async {
    StateB? tFirstStateB;
    StartupState? tCurrentState;

    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => tCurrentState = StateA(startupSequence),
            [
              LogicStateTransition<StateB>(),
            ],
          ),
          StartupStateFactory<StateB>(
            (startupSequence) {
              final tState = StateB(startupSequence);
              tFirstStateB ??= tState;
              return tCurrentState = tState;
            },
            [
              LogicStateTransition<StateDelayed2000ms>(),
            ],
          ),
          StartupStateFactory<StateDelayed2000ms>(
            (startupSequence) =>
                tCurrentState = StateDelayed2000ms(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tCurrentState, isA<StateB>());

      await tester.tap(find.text('PushModalA'));
      await tester.pumpAndSettle();
      expect(find.text('StartupModalPageA'), findsOneWidget);
      expect(tCurrentState, isA<StateB>());
      expect(tFirstStateB?.processed, true);
      expect(tFirstStateB?.navigateResult, false);
      expect(tFirstStateB?.pageResult, false);

      await tester.tap(find.text('CompleteAndPushModaB'));
      await tester.pumpAndSettle();
      expect(tCurrentState, isA<StateDelayed2000ms>());
      expect(tFirstStateB?.navigateResult, true);
      expect(tFirstStateB?.pageResult, true);
      expect(find.text('StartupModalPageB'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('StartupModalPageA'), findsOneWidget);
      expect(tCurrentState, isA<StateB>());
      expect(tCurrentState, isNot(tFirstStateB));

      final tTemp = tCurrentState;
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tCurrentState, equals(tTemp));
      expect(tCurrentState, isNot(tFirstStateB));

      await tester.tap(find.text('Complete'));
      expect(tCurrentState, isA<StateDelayed2000ms>());

      await tester.pumpAndSettle(const Duration(milliseconds: 2000));
      expect(find.text('HomePage'), findsOneWidget);
    });

    tApp.dispose();
  });

  testWidgets("back state test. replace route", (WidgetTester tester) async {
    StateB? tFirstStateB;
    StartupState? tCurrentState;

    final tApp = createApp(
      appWidget: StandardMaterialApp(
        onGenerateTitle: (context) => 'StartupSequence Test Title',
        pages: [
          SplashPageFactory<SplashPage>(
            create: (data) => SplashPage(),
          ),
          StartupPageFactory<StartupPageA>(
            create: (data) => StartupPageA(),
          ),
          StandardPageFactory<TestHomePage, void>(
            create: (data) => TestHomePage(),
            links: {
              r'': (match, uri) => TestHomePage(),
            },
            linkGenerator: (pageData) => r'',
          ),
        ],
      ),
      startupSequence: StartupSequence(
        startupStateFactories: [
          StartupStateFactory<StateA>(
            (startupSequence) => tCurrentState = StateA(startupSequence),
            [
              LogicStateTransition<StateB>(),
            ],
          ),
          StartupStateFactory<StateB>(
            (startupSequence) {
              final tState = StateB(startupSequence);
              tFirstStateB ??= tState;
              return tCurrentState = tState;
            },
            [
              LogicStateTransition<StateDelayed2000ms>(),
            ],
          ),
          StartupStateFactory<StateDelayed2000ms>(
            (startupSequence) =>
                tCurrentState = StateDelayed2000ms(startupSequence),
            [],
          ),
        ],
      ),
    );

    tApp.run();

    await tApp.runProcess(() async {
      await tester.pumpAndSettle();
      expect(find.text('SplashPage'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tCurrentState, isA<StateB>());

      await tester.tap(find.text('PushModalA'));
      await tester.pumpAndSettle();
      expect(find.text('StartupModalPageA'), findsOneWidget);
      expect(tCurrentState, isA<StateB>());
      expect(tFirstStateB?.processed, true);
      expect(tFirstStateB?.navigateResult, false);
      expect(tFirstStateB?.pageResult, false);

      await tester.tap(find.text('ReplaceAtoB'));
      await tester.pumpAndSettle();
      expect(find.text('StartupModalPageB'), findsOneWidget);

      await tester.tap(find.text('CompleteAndPushModaC'));
      await tester.pumpAndSettle();
      expect(tCurrentState, isA<StateDelayed2000ms>());
      expect(tFirstStateB?.navigateResult, true);
      expect(tFirstStateB?.pageResult, true);
      expect(find.text('StartupModalPageC'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('StartupModalPageB'), findsOneWidget);
      expect(tCurrentState, isA<StateB>());
      expect(tCurrentState, isNot(tFirstStateB));

      final tTemp = tCurrentState;
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('StartupPageA'), findsOneWidget);
      expect(tCurrentState, equals(tTemp));
      expect(tCurrentState, isNot(tFirstStateB));

      await tester.tap(find.text('Complete'));
      expect(tCurrentState, isA<StateDelayed2000ms>());

      await tester.pumpAndSettle(const Duration(milliseconds: 2000));
      expect(find.text('HomePage'), findsOneWidget);
    });

    tApp.dispose();
  });
}

class StateA extends StartupState {
  StateA(super.startupSequence);

  bool processed = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    return await Future.delayed(const Duration(milliseconds: 500));
  }
}

class StateB extends StartupState {
  StateB(super.startupSequence);

  bool processed = false;
  bool pageResult = false;
  bool navigateResult = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    navigateResult = await navigateToPage(StartupPageA, (result) {
      pageResult = result as bool;
    });
  }
}

class StateXB extends StartupState {
  StateXB(super.startupSequence);

  bool processed = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    throw 'StateXB';
  }
}

class StateC extends StartupState {
  StateC(super.startupSequence);

  bool processed = false;
  bool pageResult = false;
  bool navigateResult = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    navigateResult = await navigateToPage(StartupPageB, (result) {
      pageResult = result as bool;
    });
  }
}

class StateD extends StartupState {
  StateD(super.startupSequence);

  bool processed = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
  }
}

class StateDelayed2000ms extends StartupState {
  StateDelayed2000ms(super.startupSequence);

  bool processed = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    return await Future.delayed(const Duration(milliseconds: 2000));
  }
}

class StateCompleteBeforeProcess extends StartupState {
  StateCompleteBeforeProcess(super.startupSequence);

  bool processed = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    complete();
    return await Future.delayed(const Duration(milliseconds: 2000));
  }
}

class StateCompleteErrorBeforeProcess extends StartupState {
  StateCompleteErrorBeforeProcess(super.startupSequence);

  bool processed = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    completeError('StateCompleteErrorBeforeProcess');
    return await Future.delayed(const Duration(milliseconds: 2000));
  }
}

class StateResetMachine extends StartupState {
  StateResetMachine(super.startupSequence);

  bool processed = false;

  @override
  Future<void> process(Object? data) async {
    processed = true;
    startupSequence.resetMachine();
  }
}

class TestBlankNavigatorPlugin extends Plugin with StartupNavigatorMixin {}

class TestNavigatorPlugin extends Plugin with StartupNavigatorMixin {
  Object? navigatedPage;
  bool startupNavigateToPageCalled = false;
  bool startupProcessInitialRouteCalled = false;
  bool startupOnResetCalled = false;

  @override
  void startupNavigateToPage(Object page, StartupPageCompleter completer) {
    navigatedPage = page;
    startupNavigateToPageCalled = true;
    completer(true);
  }

  @override
  void startupProcessInitialRoute() {
    startupProcessInitialRouteCalled = true;
  }

  @override
  startupOnReset() {
    startupOnResetCalled = true;
  }
}
