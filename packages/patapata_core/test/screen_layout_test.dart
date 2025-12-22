// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';
import 'utils/patapata_core_test_utils.dart';

const String kGetScreenLayoutScaleButton = 'get-screen-layout-scale-button';
const String kTapGestureDetector = 'tap-gesture-detector';
const String kRedContainer = 'red-container';
const String kBlueContainer = 'blue-container';

const _testDeviceSizes = [
  Size(375, 667), // iPhone6
  Size(414, 736), // iPhone6Plus
  Size(375, 812), // iPhoneX
  Size(414, 896), // iPhoneXS MAX
  Size(768, 1024), // iPad Air
  Size(1668, 2224), // iPad Pro (10.5inch)
  Size(1668, 2388), //iPad Pro (11inch)
  Size(2048, 2732), // iPad Pro (12.9inch)
  Size(1920, 1080), // PC
];

late Uint8List _svgBytes;

class _TestRow extends StatelessWidget {
  const _TestRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 37.5,
          height: 300,
          child: ColoredBox(color: Colors.blue.shade100),
        ),
        SizedBox(
          width: 300,
          height: 300,
          child: ColoredBox(
            color: Colors.deepOrange.shade100,
            child: Center(
              child: SvgPicture.memory(_svgBytes, width: 200, height: 200),
            ),
          ),
        ),
        SizedBox(
          width: 37.5,
          height: 300,
          child: ColoredBox(color: Colors.blue.shade100),
        ),
      ],
    );
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(child: Center(child: _TestScreenLayout())),
      ),
    );
  }
}

class _TestScreenLayout extends StatelessWidget {
  const _TestScreenLayout({
    this.name,
    this.breakpoints,
    this.disableScreenLayout = false,
  });

  final String? name;
  final ScreenLayoutBreakpoints? breakpoints;
  final bool disableScreenLayout;

  @override
  Widget build(BuildContext context) {
    return ScreenLayout(
      name: name,
      breakpoints: breakpoints,
      child: disableScreenLayout
          ? const ScreenLayoutDisable(child: _TestRow())
          : const _TestRow(),
    );
  }
}

class _AngleChangeNotifier extends ChangeNotifier {
  double _angle;

  _AngleChangeNotifier(this._angle);

  double get angle => _angle;

  void rotate() {
    _angle -= 90;
    if (_angle < 0) {
      _angle = 360 - _angle;
    }
    notifyListeners();
  }
}

class _TestTransformScreenLayout extends StatelessWidget {
  const _TestTransformScreenLayout({
    this.disableScreenLayout = false,
    required this.initialRotate,
  });

  final bool disableScreenLayout;
  final double initialRotate;

  Widget _getWidget(_AngleChangeNotifier angleNotifier) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 37.5,
              height: 300,
              child: ColoredBox(color: Colors.blue.shade100),
            ),
            SizedBox(
              width: 300,
              height: 300,
              child: ColoredBox(
                color: Colors.deepOrange.shade100,
                child: Center(
                  child: SvgPicture.memory(_svgBytes, width: 200, height: 200),
                ),
              ),
            ),
            SizedBox(
              width: 37.5,
              height: 300,
              child: ColoredBox(color: Colors.blue.shade100),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () {
              angleNotifier.rotate();
            },
            child: angleNotifier.angle == 90
                ? Container(
                    key: const ValueKey(kRedContainer),
                    width: 100,
                    height: 30,
                    color: Colors.redAccent,
                  )
                : Container(
                    key: const ValueKey(kBlueContainer),
                    width: 100,
                    height: 30,
                    color: Colors.blueAccent,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _AngleChangeNotifier(initialRotate),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SizedBox.expand(
            child: Center(
              child: Consumer<_AngleChangeNotifier>(
                builder: (context, angleNotifier, child) {
                  return ScreenLayout(
                    breakpoints: const ScreenLayoutBreakpoints(
                      portraitStandardBreakpoint: 375,
                      portraitConstrainedWidth: double.infinity,
                      landscapeStandardBreakpoint: 375,
                      landscapeConstrainedWidth: double.infinity,
                      maxScale: 1.2,
                    ),
                    child: Transform.rotate(
                      angle: angleNotifier.angle * (math.pi / 180),
                      child: disableScreenLayout
                          ? ScreenLayoutDisable(
                              child: _getWidget(angleNotifier),
                            )
                          : _getWidget(angleNotifier),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenLayoutEnvironment extends Environment
    with ScreenLayoutEnvironment {
  const _ScreenLayoutEnvironment();
  @override
  Map<String, ScreenLayoutBreakpoints> get screenLayoutBreakpoints => {
    'testBreakPoints': const ScreenLayoutBreakpoints(
      name: 'normal',
      portraitStandardBreakpoint: 375.0,
      portraitConstrainedWidth: double.infinity,
      landscapeStandardBreakpoint: 375.0,
      landscapeConstrainedWidth: double.infinity,
      maxScale: 1.2,
    ),
  };
}

class _ScreenLayoutBreakpointsModel extends ChangeNotifier {
  ScreenLayoutBreakpoints? _breakpoints = ScreenLayoutDefaultBreakpoints.normal;

  ScreenLayoutBreakpoints? get breakpoints => _breakpoints;

  void setBreakpoints(ScreenLayoutBreakpoints breakpoints) {
    _breakpoints = breakpoints;
    notifyListeners();
  }
}

class _ScaleListenableBuilder extends StatelessWidget {
  const _ScaleListenableBuilder({required this.tScaleNotifier});

  final ValueNotifier<double> tScaleNotifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Builder(
          builder: (context) => TextButton(
            key: const ValueKey(kGetScreenLayoutScaleButton),
            onPressed: () {
              tScaleNotifier.value = context.screenLayoutScale;
            },
            child: ValueListenableBuilder<double>(
              valueListenable: tScaleNotifier,
              builder: (context, scale, child) =>
                  Text("Test Data Scale : $scale"),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 37.5,
              height: 300,
              child: ColoredBox(color: Colors.blue.shade100),
            ),
            SizedBox(
              width: 300,
              height: 300,
              child: ColoredBox(
                color: Colors.deepOrange.shade100,
                child: Center(
                  child: SvgPicture.memory(_svgBytes, width: 200, height: 200),
                ),
              ),
            ),
            SizedBox(
              width: 37.5,
              height: 300,
              child: ColoredBox(color: Colors.blue.shade100),
            ),
          ],
        ),
      ],
    );
  }
}

void main() {
  setUp(() async {
    File svgFile = File('test/assets/images/logo.svg');
    _svgBytes = await svgFile.readAsBytes();
  });

  group('ScreenLayoutGoldenTests', () {
    for (final size in _testDeviceSizes) {
      testGoldens('Test ScreenLayout: $size', (WidgetTester tester) async {
        await loadAppFonts();
        await tester.pumpWidgetBuilder(const _TestApp(), surfaceSize: size);
        await screenMatchesGolden(tester, 'ScreenLayout_$size');
      });
    }

    testGoldens("ScreenLayoutAppStandardTest", (WidgetTester tester) async {
      await loadAppFonts();

      var tTestDeviceSize = _testDeviceSizes[0];

      final App tApp = createApp(
        environment: const _ScreenLayoutEnvironment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(
              child: Center(child: _TestScreenLayout(name: 'testBreakPoints')),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'ScreenLayout_$tTestDeviceSize');
      });

      tApp.dispose();
    });

    testGoldens("ScreenLayoutAppFactoryMethodTest", (
      WidgetTester tester,
    ) async {
      await loadAppFonts();

      var tTestDeviceSize = _testDeviceSizes[0];

      final App tApp = createApp(
        environment: const _ScreenLayoutEnvironment(),
        appWidget: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(
              child: Center(
                child: ScreenLayout.named(
                  name: 'testBreakePoints',
                  child: const _TestRow(),
                ),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'ScreenLayout_$tTestDeviceSize');
      });

      tApp.dispose();
    });

    testGoldens('ScreenLayoutBreakPointCopyTest', (WidgetTester tester) async {
      await loadAppFonts();

      var tTestDeviceSize = _testDeviceSizes[0];

      const tBreakpoints = ScreenLayoutBreakpoints(
        name: 'normal',
        portraitStandardBreakpoint: 375.0,
        portraitConstrainedWidth: 482,
        landscapeStandardBreakpoint: 375.0,
        landscapeConstrainedWidth: 482,
        maxScale: 1.2,
      );

      final tModifiedBreakpoints = tBreakpoints.copyWith(
        name: null,
        maxScale: null,
      );

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(
              child: Center(
                child: _TestScreenLayout(breakpoints: tModifiedBreakpoints),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'ScreenLayout_BreakPoint_CopyTest');
      });

      tApp.dispose();
    });

    testGoldens("ScreenLayoutUpdateRotationTest", (WidgetTester tester) async {
      await loadAppFonts();

      var tTestDeviceSize = _testDeviceSizes[0];

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(child: Center(child: _TestScreenLayout())),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'ScreenLayout_$tTestDeviceSize');

        tTestDeviceSize = Size(tTestDeviceSize.height, tTestDeviceSize.width);

        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await screenMatchesGolden(tester, 'ScreenLayout_$tTestDeviceSize');
      });

      tApp.dispose();
    });

    testGoldens("ScreenLayoutUpdateBreakpointsTest", (
      WidgetTester tester,
    ) async {
      await loadAppFonts();

      late _ScreenLayoutBreakpointsModel tProvider =
          _ScreenLayoutBreakpointsModel();

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: ChangeNotifierProvider<_ScreenLayoutBreakpointsModel>(
          create: (BuildContext context) {
            return _ScreenLayoutBreakpointsModel();
          },
          child: Builder(
            builder: (BuildContext context) {
              tProvider = context.watch<_ScreenLayoutBreakpointsModel>();
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  backgroundColor: Colors.white,
                  body: SizedBox.expand(
                    child: Center(
                      child: GestureDetector(
                        key: const ValueKey(kTapGestureDetector),
                        onTap: () => tProvider.setBreakpoints(
                          ScreenLayoutDefaultBreakpoints.large,
                        ),
                        child: _TestScreenLayout(
                          breakpoints: tProvider.breakpoints,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey(kTapGestureDetector)));

        for (final size in _testDeviceSizes) {
          await setTestDeviceSize(tester, size);

          await screenMatchesGolden(
            tester,
            'ScreenLayout_ChangeBreakPoint_$size',
          );
        }
      });

      tApp.dispose();
    });

    testGoldens("ScreenLayoutDiableTest", (WidgetTester tester) async {
      await loadAppFonts();

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(
              child: Center(
                child: _TestScreenLayout(disableScreenLayout: true),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        for (final size in _testDeviceSizes) {
          await setTestDeviceSize(tester, size);

          await tester.pumpAndSettle();

          await screenMatchesGolden(tester, 'ScreenLayout_Disable_$size');
        }
      });

      tApp.dispose();
    });

    testGoldens("ScreenLayoutApplyPaintTransformTest", (
      WidgetTester tester,
    ) async {
      await loadAppFonts();
      var tTestDeviceSize = _testDeviceSizes[1];
      final App tApp = createApp(
        environment: const Environment(),
        appWidget: const _TestTransformScreenLayout(initialRotate: 90),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey(kRedContainer)), findsOneWidget);

        await tester.tapAt(const Offset(40, 565));

        await screenMatchesGolden(
          tester,
          'ScreenLayout_Transform_$tTestDeviceSize',
        );

        expect(find.byKey(const ValueKey(kBlueContainer)), findsOneWidget);
      });

      tApp.dispose();
    });

    testGoldens("ScreenLayoutDisableApplyPaintTransformTest", (
      WidgetTester tester,
    ) async {
      await loadAppFonts();
      var tTestDeviceSize = _testDeviceSizes[1];
      final App tApp = createApp(
        environment: const Environment(),
        appWidget: const _TestTransformScreenLayout(
          disableScreenLayout: true,
          initialRotate: 90,
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey(kRedContainer)), findsOneWidget);

        await tester.tapAt(const Offset(58, 567));

        await screenMatchesGolden(
          tester,
          'ScreenLayout_Transform_Disable_$tTestDeviceSize',
        );

        expect(find.byKey(const ValueKey(kBlueContainer)), findsOneWidget);
      });

      tApp.dispose();
    });
  });

  group('ScreenLayoutWidgetTests', () {
    testWidgets("ScreenLayoutGetScreenLayoutScaleTest", (
      WidgetTester tester,
    ) async {
      final ValueNotifier<double> tScaleNotifier = ValueNotifier(-1.0);

      await loadAppFonts();

      var tTestDeviceSize = _testDeviceSizes[4];

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(
              child: Center(
                child: ScreenLayout(
                  child: _ScaleListenableBuilder(
                    tScaleNotifier: tScaleNotifier,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kGetScreenLayoutScaleButton)),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Data Scale : 1.2'), findsOneWidget);
      });

      tApp.dispose();
    });

    testWidgets("ScreenLayoutDisableGetScreenLayoutScaleTest", (
      WidgetTester tester,
    ) async {
      final ValueNotifier<double> tScaleNotifier = ValueNotifier(-1.0);

      await loadAppFonts();

      var tTestDeviceSize = _testDeviceSizes[4];

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(
              child: Center(
                child: ScreenLayoutDisable(
                  child: _ScaleListenableBuilder(
                    tScaleNotifier: tScaleNotifier,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kGetScreenLayoutScaleButton)),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Data Scale : 1.0'), findsOneWidget);
      });

      tApp.dispose();
    });

    testWidgets('ScreenLayout ConstrainedWidth Zero', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<double> tScaleNotifier = ValueNotifier(-1.0);

      await loadAppFonts();

      var tTestDeviceSize = _testDeviceSizes[4];

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SizedBox.expand(
              child: Center(
                child: ScreenLayout(
                  breakpoints: const ScreenLayoutBreakpoints(
                    name: 'normal',
                    portraitStandardBreakpoint: 375.0,
                    portraitConstrainedWidth: 0,
                    landscapeStandardBreakpoint: 375.0,
                    landscapeConstrainedWidth: 0,
                    maxScale: 1.2,
                  ),
                  child: _ScaleListenableBuilder(
                    tScaleNotifier: tScaleNotifier,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await setTestDeviceSize(tester, tTestDeviceSize);

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kGetScreenLayoutScaleButton)),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Data Scale : 1.0'), findsOneWidget);
      });

      tApp.dispose();
    });
  });

  group('ScreenLayoutUnitTests', () {
    test('Test for identical hash codes of ScreenLayoutBreakpoints', () {
      final breakpoints1 = const ScreenLayoutBreakpoints(
        name: 'Test Breakpoint',
        portraitStandardBreakpoint: 600.0,
        portraitConstrainedWidth: 800.0,
        landscapeStandardBreakpoint: 900.0,
        landscapeConstrainedWidth: 1200.0,
        maxScale: 1.5,
      ).hashCode;

      final breakpoints2 = const ScreenLayoutBreakpoints(
        name: 'Test Breakpoint',
        portraitStandardBreakpoint: 600.0,
        portraitConstrainedWidth: 800.0,
        landscapeStandardBreakpoint: 900.0,
        landscapeConstrainedWidth: 1200.0,
        maxScale: 1.5,
      ).hashCode;

      expect(breakpoints1, breakpoints2);
    });
  });
}
