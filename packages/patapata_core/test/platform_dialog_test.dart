// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patapata_core/src/widgets/platform_dialog.dart';

typedef DialogActionBuilder = PlatformDialogAction Function(dynamic result);

abstract class TestButtonBase<T> {
  TestButtonBase({required this.expectedResults});

  final T expectedResults;
  dynamic actuallyResults;

  Finder createFinder(TargetPlatform? target);
  PlatformDialogAction createAction();

  void defaultAction() {
    actuallyResults = expectedResults;
  }

  T defaultReturn() {
    return expectedResults;
  }

  Widget? getTopWidget(Widget widget, TargetPlatform? target) {
    if (target == TargetPlatform.iOS || target == TargetPlatform.macOS) {
      return widget is CupertinoDialogAction ? widget.child : null;
    }

    return widget is TextButton ? widget.child : null;
  }
}

class TestButton1 extends TestButtonBase<bool> {
  TestButton1({required super.expectedResults});

  @override
  Finder createFinder(TargetPlatform? target) {
    return find.byWidgetPredicate((widget) {
      Widget? tChild = getTopWidget(widget, target);
      if (tChild != null && tChild is Text) {
        if (tChild.data == 'text button') {
          return true;
        }
      }

      return false;
    });
  }

  @override
  PlatformDialogAction createAction() {
    return PlatformDialogAction<bool>(
      text: 'text button',
      action: defaultAction,
      result: defaultReturn,
    );
  }
}

class TestButton2 extends TestButtonBase<int> {
  TestButton2({required super.expectedResults});

  @override
  Finder createFinder(TargetPlatform? target) {
    return find.byWidgetPredicate((widget) {
      Widget? tChild = getTopWidget(widget, target);
      if (tChild != null && tChild is SizedBox) {
        if (tChild.width == 20 && tChild.height == 20) {
          tChild = tChild.child;
          if (tChild != null && tChild is ColoredBox) {
            if (tChild.color == Colors.red) {
              return true;
            }
          }
        }
      }

      return false;
    });
  }

  @override
  PlatformDialogAction createAction() {
    return PlatformDialogAction<int>(
      child: const SizedBox(
        width: 20,
        height: 20,
        child: ColoredBox(color: Colors.red),
      ),
      action: defaultAction,
      result: defaultReturn,
    );
  }
}

const _localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

class TestApp {
  TestApp({required this.targetPlatform});

  final TargetPlatform? targetPlatform;
  final appKey = GlobalKey();

  Widget createApp() {
    final tHome = KeyedSubtree(key: appKey, child: const SizedBox.shrink());

    if (targetPlatform == TargetPlatform.iOS ||
        targetPlatform == TargetPlatform.macOS) {
      return CupertinoApp(
        home: tHome,
        localizationsDelegates: _localizationsDelegates,
      );
    }

    return MaterialApp(home: tHome);
  }

  Type? getDialogType() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return CupertinoAlertDialog;
    }

    return AlertDialog;
  }
}

void main() {
  final List<TestApp> tTestApps = kIsWeb
      ? [TestApp(targetPlatform: null)]
      : [
          TestApp(targetPlatform: TargetPlatform.android),
          TestApp(targetPlatform: TargetPlatform.windows),
          TestApp(targetPlatform: TargetPlatform.iOS),
          TestApp(targetPlatform: TargetPlatform.macOS),
        ];

  final tTestButtons = <TestButtonBase>[
    TestButton1(expectedResults: true),
    TestButton2(expectedResults: Random().nextInt(1000)),
  ];

  for (final testApp in tTestApps) {
    final tTestMessage =
        'Test PlatformDialog for ${testApp.targetPlatform?.name ?? 'web'}.';

    group('Guard $tTestMessage', () {
      testWidgets(tTestMessage, (WidgetTester tester) async {
        if (testApp.targetPlatform != null) {
          debugDefaultTargetPlatformOverride = testApp.targetPlatform;
        }

        await tester.pumpWidget(testApp.createApp());

        for (final testButton in tTestButtons) {
          Future? tTapTestFuture;
          final tResultTestCompleter = Completer();

          PlatformDialog.show(
            context: testApp.appKey.currentContext!,
            actions: tTestButtons.map((e) => e.createAction()).toList(),
            message: tTestMessage,
          ).then((value) async {
            await tTapTestFuture;
            expect(value, testButton.expectedResults);
            expect(value, testButton.actuallyResults);
            tResultTestCompleter.complete();
          });
          await tester.pumpAndSettle();

          // Confirmation of the existence of the Widget.
          expect(find.byType(testApp.getDialogType()!), findsOneWidget);
          expect(find.text(tTestMessage), findsOneWidget);
          for (final e in tTestButtons) {
            expect(e.createFinder(testApp.targetPlatform), findsOneWidget);
          }

          // Test the behavior when the button1 is pressed.
          tTapTestFuture = tester.tap(
            testButton.createFinder(testApp.targetPlatform),
          );
          await Future.wait([tTapTestFuture, tResultTestCompleter.future]);
          await tester.pumpAndSettle();
        }

        debugDefaultTargetPlatformOverride = null;
      });
    });
  }
}
