// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'utils/patapata_core_test_utils.dart';

const String kAnalyticsButton = 'analytics-button';
const String kAnalyticsHomeScreenButton = 'analytics-home-screen-button';
const String kAnalyticsSecondScreenButton = 'analytics-second-screen-button';
const String kAnalyticsSecondRemoveScreenButton =
    'analytics-second-remove-screen-button';
const String kAnalyticsStandardPageButton = 'analytics-standard-page-button';
const String kAnalyticsEventButton = 'analytics-event-button';
const String kAnalyticsRawEventButton = 'analytics-raw-event-button';
const String kAnalyticsSingletonButton = 'analytics-singleton-button';
const String kAnalyticsUpdateWidgetButton = 'analytics-update-widget-button';
const String kAnalyticsNotifyDataChangedButton =
    'analytics-notify-data-changed-button';
const String kAnalyticsTestFirstPageButton = 'analytics-test-first-page-button';

// Analytics Test Environment Configuration Class
class _TestAnalyticsEnviroment extends Environment
    with AnalyticsEventFilterEnvironment {
  const _TestAnalyticsEnviroment();
  @override
  final analyticsEventFilter =
      const <Type, AnalyticsEvent? Function(AnalyticsEvent event)>{};
}

// Analytics Test Environment Configuration Class with Filters
class _TestAnalyticsEventFilterEnviroment extends Environment
    with AnalyticsEventFilterEnvironment {
  _TestAnalyticsEventFilterEnviroment();
  @override
  final analyticsEventFilter =
      <Type, AnalyticsEvent? Function(AnalyticsEvent event)>{
        // A test filter for treating a specific event as a different RawEvent.
        _TestAnalyticsEvent: (AnalyticsEvent event) =>
            event is _TestAnalyticsEvent
            ? _TestRawEvent(name: event.name)
            : event,
      };
}

// RawEvent for Analytics Testing
class _TestRawEvent extends AnalyticsEvent {
  _TestRawEvent({required super.name});
}

// AnalyticsEvent for Analytics Testing
class _TestAnalyticsEvent extends AnalyticsEvent {
  _TestAnalyticsEvent({required super.name});
}

// StandardPage for Analytics Testing
class _TestAnalyticsPage extends StandardPage<void> {
  String _interactionContextData = '';
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView(
        children: [
          SizedBox(
            child: TextButton(
              key: const ValueKey(kAnalyticsStandardPageButton),
              onPressed: () {
                AnalyticsEvent tAnalyticsEvent = AnalyticsEvent(
                  name: 'testEvents',
                  data: {'test': 'testData'},
                  context: getApp().analytics.globalContext,
                );
                getApp().analytics.rawEvent(tAnalyticsEvent);

                setState(() {
                  _interactionContextData = context
                      .read<Analytics>()
                      .toString();
                });
              },
              child: const Text('On Tap'),
            ),
          ),
          Text(
            "context.read<Analytics>().interactionContextData:$_interactionContextData",
          ),
        ],
      ),
    );
  }
}

class _TestAnalyticsContextProviderPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: AnalyticsContextProvider(
        reset: false,
        analyticsContext: AnalyticsContext({
          'hogehogeName': 'AnalyticsContextParent',
          'hogehogeData': null,
          'hogehgoeLink': 'HogehogeLink',
        }),
        child: AnalyticsContextProvider(
          reset: true,
          analyticsContext: AnalyticsContext({
            'pageName': 'AnalyticsContextPage',
            'pageData': null,
            'pageLink': 'AnalyticsContextPageLink',
          }),
          child: const AnalyticsEventWidget(
            key: ValueKey(kAnalyticsButton),
            name: 'context analytics event',
            child: Text('On Tap'),
          ),
        ),
      ),
    );
  }
}

class _TestAnalyticsSingletonEventWidgetPage extends StandardPage<void> {
  bool _toggle = false;
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView(
        children: [
          const Center(child: Text('test')),
          Column(
            children: [
              if (_toggle)
                const AnalyticsSingletonEventWidget(
                  name: 'Event1',
                  data: {'test': 'testData1'},
                  child: Text('Event1'),
                )
              else
                const AnalyticsSingletonEventWidget(
                  name: 'Event2',
                  data: {'test': 'testData2'},
                  child: Text('Event2'),
                ),
              TextButton(
                key: const ValueKey(kAnalyticsSingletonButton),
                onPressed: () {
                  setState(() {
                    _toggle = !_toggle;
                  });
                },
                child: const Text('Analytics Event'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestAnalyticsImpressionWidgetPage extends StandardPage<void> {
  final int _itemCount = 25;
  final int _selectedItem = 5;

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView.builder(
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 100,
            child: index == _selectedItem
                ? AnalyticsContextProvider(
                    analyticsContext: AnalyticsContext({
                      'section': 'Section $index',
                    }),
                    child: AnalyticsImpressionWidget(
                      durationThreshold: Duration.zero,
                      visibleThreshold: 0.5,
                      name: 'Analytics Impression',
                      data: {'name': 'Analytics Page Item $index'},
                      child: Text("Impression index : $index"),
                      batchGenerator: (datas, contexts) {
                        return {
                          'name': datas.map((e) => e['name']).join(','),
                          'section': contexts
                              .map((e) => e.resolve()['section'])
                              .join(','),
                        };
                      },
                    ),
                  )
                : Text("Impression index : $index"),
          );
        },
      ),
    );
  }
}

class _TestAnalyticsImpressionWidgetNoneBatchPage extends StandardPage<void> {
  final int _itemCount = 35;

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView.builder(
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 100,
            child: index % 10 == 0
                ? AnalyticsContextProvider(
                    analyticsContext: AnalyticsContext({
                      'section': 'Section $index',
                    }),
                    child: AnalyticsImpressionWidget(
                      durationThreshold: Duration.zero,
                      visibleThreshold: 0.5,
                      name: 'Analytics Impression',
                      data: {'name': 'Analytics Page Item $index'},
                      child: Text("Impression index : $index"),
                    ),
                  )
                : Text("Impression index : $index"),
          );
        },
      ),
    );
  }
}

class _TestAnalyticsImpressionDidUpdateWidgetPage extends StandardPage<void> {
  final int _itemCount = 25;
  final int _selectedItem = 5;
  late AnalyticsEvent _analyticsEvent;

  @override
  void initState() {
    _analyticsEvent = AnalyticsEvent(
      name: 'Analytics Impression',
      data: {'name': 'Analytics Page Item'},
      context: getApp().analytics.globalContext,
    );

    super.initState();
  }

  Widget _getWidget(int index) {
    return index == _selectedItem
        ? TextButton(
            key: const ValueKey(kAnalyticsUpdateWidgetButton),
            onPressed: () {
              setState(() {
                _analyticsEvent = AnalyticsEvent(
                  name: 'Update Analytics Impression $index',
                  data: {'name': 'Update Analytics Page Item $index'},
                  context: getApp().analytics.globalContext,
                );
              });
            },
            child: const Text('test'),
          )
        : const Text('test');
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView.builder(
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 100,
            child: index == _selectedItem
                ? AnalyticsContextProvider(
                    analyticsContext: AnalyticsContext({
                      'section': 'Section $index',
                    }),
                    child: AnalyticsImpressionWidget(
                      durationThreshold: Duration.zero,
                      visibleThreshold: 0.5,
                      event: _analyticsEvent,
                      child: _getWidget(index),
                    ),
                  )
                : _getWidget(index),
          );
        },
      ),
    );
  }
}

class _TestAnalyticsImpressionNotifyDataChangedPage extends StandardPage<void> {
  final int _itemCount = 35;
  Map<String, Object?>? _data = {'name': 'Analytics Page Item'};

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView.builder(
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          if (index != 0 && index % 7 == 0) {
            return TextButton(
              key: const ValueKey(kAnalyticsNotifyDataChangedButton),
              onPressed: () {
                setState(() {
                  _data = {'name': 'Analytics Page Item After Setstate $index'};
                });
              },
              child: Text('On Tap Button $index'),
            );
          }
          return SizedBox(
            height: 100,
            child: index % 10 == 0
                ? AnalyticsContextProvider(
                    analyticsContext: AnalyticsContext({
                      'section': 'Section $index',
                    }),
                    child: AnalyticsImpressionWidget(
                      durationThreshold: Duration.zero,
                      visibleThreshold: 0.5,
                      name: 'Analytics Impression',
                      data: _data,
                      child: Text("Impression index : $index"),
                      batchGenerator: (datas, contexts) {
                        return {
                          'name': datas.map((e) => e['name']).join(','),
                          'section': contexts
                              .map((e) => e.resolve()['section'])
                              .join(','),
                        };
                      },
                    ),
                  )
                : Text("Impression index : $index"),
          );
        },
      ),
    );
  }
}

class _TestAnalyticsImpressionBatchToIgnorePage extends StandardPage<void> {
  final int _itemCount = 35;

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView.builder(
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 100,
            child: index % 10 == 0
                ? AnalyticsContextProvider(
                    analyticsContext: AnalyticsContext({
                      'section': 'Section $index',
                      'index': '$index',
                    }),
                    child: AnalyticsImpressionWidget(
                      durationThreshold: Duration.zero,
                      name: 'Analytics Impression',
                      thresholdCallback: (info) {
                        return true;
                      },
                      batchDataToIgnore: const {'section'}, // 例えばsectionは無視する
                      child: Text("Impression index : $index"),
                      batchGenerator: (datas, contexts) {
                        return {};
                      },
                    ),
                  )
                : Text("Impression index : $index"),
          );
        },
      ),
    );
  }
}

class _TestAnalyticsImpressionVisibilityPage extends StandardPage<void> {
  final int _itemCount = 30;

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView.builder(
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 100,
            child: index == 10
                ? AnalyticsContextProvider(
                    analyticsContext: AnalyticsContext({
                      'section': 'Section $index',
                    }),
                    child: AnalyticsImpressionWidget(
                      durationThreshold: Duration.zero,
                      visibleThreshold: 0.5,
                      name: 'Analytics Impression $index',
                      data: {'name': 'Analytics Page Item $index'},
                      child: Text("Impression index : $index"),
                      batchGenerator: (datas, contexts) {
                        return {};
                      },
                    ),
                  )
                : Text("Impression index : $index"),
          );
        },
      ),
    );
  }
}

class _TestAnalyticsImpressionThresholdCallbackPage extends StandardPage<void> {
  final int _itemCount = 50;

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context, 'title'))),
      body: ListView.builder(
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 100,
            child: index % 10 == 0
                ? AnalyticsContextProvider(
                    analyticsContext: AnalyticsContext({
                      'section': 'Section $index',
                      'index': '$index',
                    }),
                    child: AnalyticsImpressionWidget(
                      name: 'Analytics Impression $index',
                      thresholdCallback: (info) {
                        return info.visibleFraction >= 0.5;
                      },
                      child: Text("Impression index : $index"),
                      batchGenerator: (datas, contexts) {
                        return {};
                      },
                    ),
                  )
                : Text("Impression index : $index"),
          );
        },
      ),
    );
  }
}

// Other Test Widgets
class _TestAnalyticsHomeScreen extends StatelessWidget {
  const _TestAnalyticsHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Home Screen')),
      body: Center(
        child: ElevatedButton(
          key: const ValueKey(kAnalyticsHomeScreenButton),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/second',
              arguments: 'Hello from Test Home Screen',
            );
          },
          child: const Text('Go to Test Second Screen'),
        ),
      ),
    );
  }
}

class _TestAnalyticsSecondScreen extends StatelessWidget {
  const _TestAnalyticsSecondScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Second Screen')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              key: const ValueKey(kAnalyticsSecondScreenButton),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go back to Test Home Screen'),
            ),
            ElevatedButton(
              key: const ValueKey(kAnalyticsSecondRemoveScreenButton),
              onPressed: () async {
                Navigator.removeRoute(context, ModalRoute.of(context)!);
              },
              child: const Text('Remove to Test Screen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestFirstPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test First Page')),
      body: Center(
        child: ElevatedButton(
          key: const ValueKey(kAnalyticsTestFirstPageButton),
          onPressed: () {
            context.go<_TestSecondPage, void>(null);
          },
          child: const Text('Go to Test Second Page'),
        ),
      ),
    );
  }
}

class _TestSecondPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Second Page')),
      body: const Center(child: Text('Test Second Page')),
    );
  }
}

void main() {
  // widget tests
  group('Analytics Wdget Tests', () {
    testWidgets("AnalyticsEvent eventsFor test", (WidgetTester tester) async {
      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox.expand(child: Center(child: SizedBox())),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<_TestRawEvent>();

        var tFuture = expectLater(
          tEventStream,
          emitsInOrder([AnalyticsEvent(name: 'testEvents')]),
        );

        // send analytics event
        tAnalytics.rawEvent(AnalyticsEvent(name: 'testEvents'));

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("AnalyticsEvent filter event test", (
      WidgetTester tester,
    ) async {
      final App tApp = createApp(
        environment: _TestAnalyticsEventFilterEnviroment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox.expand(child: Center(child: SizedBox())),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<_TestAnalyticsEvent>();

        var tFuture = expectLater(
          tEventStream,
          emitsInOrder([_TestRawEvent(name: 'testEvents')]),
        );

        // send analytics event
        tAnalytics.rawEvent(_TestAnalyticsEvent(name: 'testEvents'));

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("AnalyticsEvent context test", (WidgetTester tester) async {
      final App tApp = createApp(
        environment: _TestAnalyticsEventFilterEnviroment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox.expand(child: Center(child: SizedBox())),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tContextKey = Object();
        final tAnalyticsContext = AnalyticsContext({});

        tApp.analytics.setGlobalContext(tContextKey, tAnalyticsContext);
        expect(tApp.analytics.getGlobalContext(tContextKey), tAnalyticsContext);

        tApp.analytics.setGlobalContext(tContextKey, null);
        expect(tApp.analytics.getGlobalContext(tContextKey), isNull);
      });

      tApp.dispose();
    });

    testWidgets("SetRouteContext test", (WidgetTester tester) async {
      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox.expand(child: Center(child: SizedBox())),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tKey = Object();
        final tContext = AnalyticsContext({});

        tApp.analytics.setRouteContext(tKey, tContext);
        expect(tApp.analytics.getRouteContext(tKey), tContext);

        tApp.analytics.setRouteContext(tKey, null);
        expect(tApp.analytics.getRouteContext(tKey), isNull);
      });

      tApp.dispose();
    });

    testWidgets("GetRouteContext test navigate page", (
      WidgetTester tester,
    ) async {
      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<_TestFirstPage, void>(
              create: (data) => _TestFirstPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
            ),
            StandardPageFactory<_TestSecondPage, void>(
              create: (data) => _TestSecondPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tKey = Object();
        final tContext = AnalyticsContext({});

        tApp.analytics.setRouteContext(tKey, tContext);
        expect(tApp.analytics.getRouteContext(tKey), tContext);

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsTestFirstPageButton)),
        );

        await tester.pumpAndSettle();

        expect(tApp.analytics.getRouteContext(tKey), isNull);
      });

      tApp.dispose();
    });

    testWidgets("Test sending analytics with null context", (
      WidgetTester tester,
    ) async {
      final App tApp = createApp(
        environment: _TestAnalyticsEventFilterEnviroment(),
        appWidget: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return SizedBox.expand(
                  child: Center(
                    child: SizedBox(
                      child: TextButton(
                        key: const ValueKey(kAnalyticsButton),
                        onPressed: () {
                          getApp().analytics.event(
                            name: 'testEvents',
                            context: null,
                          );
                        },
                        child: const Text('On Tap'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<_TestAnalyticsEvent>();

        var tFuture = expectLater(
          tEventStream,
          emitsInOrder([AnalyticsEvent(name: 'testEvents')]),
        );

        await tester.tap(find.byKey(const ValueKey(kAnalyticsButton)));

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics revenueEvent test", (WidgetTester tester) async {
      AnalyticsRevenueEvent fConvertAnalyticsRevenueEvent(
        AnalyticsEvent event,
      ) {
        return event as AnalyticsRevenueEvent;
      }

      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox.expand(child: Center(child: SizedBox())),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<AnalyticsRevenueEvent>();

        var tFuture = expectLater(
          tEventStream,
          emitsInOrder([
            AnalyticsRevenueEvent(
              revenue: 100.0,
              currency: 'USD',
              orderId: '123456',
              receipt: 'receipt123',
              productId: 'product123',
              productName: 'Product 123',
              eventName: 'revenueEvent',
              context: null,
            ),
          ]),
        );

        final List<Future> tFutureGetPropertyList = <Future>[
          expectLater(
            tAnalytics.events.asyncMap(
              (event) => fConvertAnalyticsRevenueEvent(event).revenue,
            ),
            emitsInOrder([100.0]),
          ),
          expectLater(
            tAnalytics.events.asyncMap(
              (event) => fConvertAnalyticsRevenueEvent(event).currency,
            ),
            emitsInOrder(['USD']),
          ),
          expectLater(
            tAnalytics.events.asyncMap(
              (event) => fConvertAnalyticsRevenueEvent(event).orderId,
            ),
            emitsInOrder(['123456']),
          ),
          expectLater(
            tAnalytics.events.asyncMap(
              (event) => fConvertAnalyticsRevenueEvent(event).receipt,
            ),
            emitsInOrder(['receipt123']),
          ),
          expectLater(
            tAnalytics.events.asyncMap(
              (event) => fConvertAnalyticsRevenueEvent(event).productId,
            ),
            emitsInOrder(['product123']),
          ),
          expectLater(
            tAnalytics.events.asyncMap(
              (event) => fConvertAnalyticsRevenueEvent(event).productName,
            ),
            emitsInOrder(['Product 123']),
          ),
        ];

        // send revenue event
        tAnalytics.revenueEvent(
          revenue: 100.0,
          currency: 'USD',
          orderId: '123456',
          receipt: 'receipt123',
          productId: 'product123',
          productName: 'Product 123',
          eventName: 'revenueEvent',
        );

        await tFuture;

        await Future.wait(tFutureGetPropertyList);
      });

      tApp.dispose();
    });

    testWidgets("AnalyticsEventWidget test", (WidgetTester tester) async {
      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox.expand(
              child: Center(
                key: ValueKey(kAnalyticsEventButton),
                child: AnalyticsEventWidget(
                  name: 'testEvents',
                  data: {'test': 'testData'},
                  child: Text('On Tap'),
                ),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<AnalyticsRevenueEvent>();

        var tFuture = expectLater(
          tEventStream.asyncMap((event) => event.toString()),
          emitsInOrder([
            'AnalyticsEvent:testEvents: data={test: testData}, context={}, navigationInteractionContext=null',
          ]),
        );

        await tester.tap(find.byKey(const ValueKey(kAnalyticsEventButton)));

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("AnalyticsEventWidget raw test", (WidgetTester tester) async {
      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SizedBox.expand(
              child: Center(
                key: const ValueKey(kAnalyticsRawEventButton),
                child: AnalyticsEventWidget(
                  event: AnalyticsEvent(
                    name: 'eventRawName',
                    data: {'testRaw': 'testRawData'},
                  ),
                  child: const Text('On Tap'),
                ),
              ),
            ),
          ),
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<AnalyticsRevenueEvent>();

        var tFutureRawEvent = expectLater(
          tEventStream.asyncMap((event) => event.toString()),
          emitsInOrder([
            'AnalyticsEvent:eventRawName: data={testRaw: testRawData}, context=null, navigationInteractionContext=null',
          ]),
        );

        await tester.tap(find.byKey(const ValueKey(kAnalyticsRawEventButton)));

        await tester.pumpAndSettle();

        await tFutureRawEvent;
      });

      tApp.dispose();
    });

    testWidgets("AnalyticsNavigatorObserver test", (WidgetTester tester) async {
      final Analytics tAnalytics = Analytics();

      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: MaterialApp(
          navigatorObservers: [
            AnalyticsNavigatorObserver(analytics: tAnalytics),
          ],
          home: const _TestAnalyticsHomeScreen(),
          routes: {'/second': (context) => const _TestAnalyticsSecondScreen()},
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<AnalyticsRouteViewEvent>();

        var tFuture = expectLater(
          tEventStream.asyncMap((event) {
            AnalyticsRouteViewEvent tEvent = event as AnalyticsRouteViewEvent;
            return {
              'isFirst': tEvent.isFirst,
              'arguments': tEvent.arguments,
              'routeName': tEvent.routeName,
              'navigationType': tEvent.navigationType,
            };
          }),
          emitsInOrder([
            {
              'isFirst': false,
              'arguments': 'Hello from Test Home Screen',
              'routeName': '/second',
              'navigationType': 'push',
            },
          ]),
        );

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsHomeScreenButton)),
        );

        await tester.pumpAndSettle();

        await tFuture;

        tFuture = expectLater(
          tEventStream.asyncMap((event) {
            AnalyticsRouteViewEvent tEvent = event as AnalyticsRouteViewEvent;
            return {
              'isFirst': tEvent.isFirst,
              'arguments': tEvent.arguments,
              'routeName': tEvent.routeName,
              'navigationType': tEvent.navigationType,
            };
          }),
          emitsInOrder([
            {
              'isFirst': true,
              'arguments': null,
              'routeName': '/',
              'navigationType': 'pop',
            },
          ]),
        );

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsSecondScreenButton)),
        );

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("AnalyticsNavigatorObserver remove route test", (
      WidgetTester tester,
    ) async {
      final Analytics tAnalytics = Analytics();

      final App tApp = createApp(
        environment: const _TestAnalyticsEnviroment(),
        appWidget: MaterialApp(
          navigatorObservers: [
            AnalyticsNavigatorObserver(analytics: tAnalytics),
          ],
          home: const _TestAnalyticsHomeScreen(),
          routes: {'/second': (context) => const _TestAnalyticsSecondScreen()},
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<AnalyticsRouteViewEvent>();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {
              'isFirst': event.flatData?['isFirst'],
              'routeName': event.flatData?['routeName'],
              'navigationType': event.flatData?['navigationType'],
            },
          ),
          emitsInOrder([
            {
              'isFirst': false,
              'routeName': '/second',
              'navigationType': 'push',
            },
          ]),
        );

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsHomeScreenButton)),
        );

        await tester.pumpAndSettle();

        await tFuture;

        tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {
              'isFirst': event.flatData?['isFirst'],
              'routeName': event.flatData?['routeName'],
              'navigationType': event.flatData?['navigationType'],
            },
          ),
          emitsInOrder([
            {'isFirst': true, 'routeName': '/', 'navigationType': 'remove'},
          ]),
        );

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsSecondRemoveScreenButton)),
        );

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });
  });

  // StandardPages tests
  group('Analytics Standard Page Tests', () {
    testWidgets("Analytics flatData test", (WidgetTester tester) async {
      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<_TestAnalyticsPage, void>(
              create: (data) => _TestAnalyticsPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();
        final tAnalytics = tApp.analytics;
        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<AnalyticsRevenueEvent>();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {
              'pageName': event.flatData?['pageName'],
              'pageLink': event.flatData?['pageLink'],
              'test': event.flatData?['test'],
            },
          ),
          emitsInOrder([
            {
              'pageName': '_TestAnalyticsPage',
              'pageLink': '',
              'test': 'testData',
            },
          ]),
        );

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsStandardPageButton)),
        );

        await tester.pumpAndSettle();

        await tFuture;

        expect(
          find.text(
            'context.read<Analytics>().interactionContextData:interactionContext:{pageName: _TestAnalyticsPage, pageData: null, pageLink: }',
          ),
          findsOneWidget,
        );
      });

      tApp.dispose();
    });

    testWidgets("Analytics context provider reset test", (
      WidgetTester tester,
    ) async {
      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<_TestAnalyticsContextProviderPage, void>(
              create: (data) => _TestAnalyticsContextProviderPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        final tAnalytics = tApp.analytics;
        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<AnalyticsRevenueEvent>();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {
              'pageName': 'AnalyticsContextPage',
              'pageData': null,
              'pageLink': 'AnalyticsContextPageLink',
            },
          ),
          emitsInOrder([
            {
              'pageName': 'AnalyticsContextPage',
              'pageData': null,
              'pageLink': 'AnalyticsContextPageLink',
            },
          ]),
        );

        await tester.tap(find.byKey(const ValueKey(kAnalyticsButton)));

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics singleton event widget test", (
      WidgetTester tester,
    ) async {
      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<_TestAnalyticsSingletonEventWidgetPage, void>(
              create: (data) => _TestAnalyticsSingletonEventWidgetPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        await tester.pumpAndSettle();

        final tAnalytics = tApp.analytics;
        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {'pageName': event.name, 'eventData': event.data},
          ),
          emitsInOrder([
            {
              'pageName': 'Event1',
              'eventData': {'test': 'testData1'},
            },
          ]),
        );

        await tester.tap(find.byKey(const ValueKey(kAnalyticsSingletonButton)));

        await tester.pumpAndSettle();

        await tFuture;

        tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {'pageName': event.name, 'eventData': event.data},
          ),
          emitsInOrder([
            {
              'pageName': 'Event2',
              'eventData': {'test': 'testData2'},
            },
          ]),
        );

        await tester.tap(find.byKey(const ValueKey(kAnalyticsSingletonButton)));

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics impression test", (WidgetTester tester) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<_TestAnalyticsImpressionWidgetPage, void>(
              create: (data) => _TestAnalyticsImpressionWidgetPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        await tester.pumpAndSettle();

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {'pageName': event.name, 'eventData': event.data},
          ),
          emitsInOrder([
            {
              'pageName': 'Analytics Impression',
              'eventData': {
                'name': 'Analytics Page Item 5',
                'section': 'Section 5',
              },
            },
          ]),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -100));

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics impression did update widget test", (
      WidgetTester tester,
    ) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<
              _TestAnalyticsImpressionDidUpdateWidgetPage,
              void
            >(
              create: (data) => _TestAnalyticsImpressionDidUpdateWidgetPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        await tester.pumpAndSettle();

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        await tester.drag(find.byType(ListView), const Offset(0, -100));

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsUpdateWidgetButton)),
        );

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {'pageName': event.name, 'eventData': event.data},
          ),
          emitsInOrder([
            {
              'pageName': 'Update Analytics Impression 5',
              'eventData': {'name': 'Update Analytics Page Item 5'},
            },
          ]),
        );

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics impression None batch test", (
      WidgetTester tester,
    ) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<
              _TestAnalyticsImpressionWidgetNoneBatchPage,
              void
            >(
              create: (data) => _TestAnalyticsImpressionWidgetNoneBatchPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        await tester.pumpAndSettle();

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {'pageName': event.name, 'eventData': event.data},
          ),
          emitsInOrder([
            {
              'pageName': 'Analytics Impression',
              'eventData': {'name': 'Analytics Page Item 30'},
            },
          ]),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -3000));

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics impression notify data changed test", (
      WidgetTester tester,
    ) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<
              _TestAnalyticsImpressionNotifyDataChangedPage,
              void
            >(
              create: (data) => _TestAnalyticsImpressionNotifyDataChangedPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        await tester.pumpAndSettle();

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        await tester.drag(find.byType(ListView), const Offset(0, -500));

        await tester.pumpAndSettle();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {'pageName': event.name, 'eventData': event.data},
          ),
          emitsInOrder([
            {
              'pageName': 'Analytics Impression',
              'eventData': {
                'name': 'Analytics Page Item After Setstate 7',
                'section': 'Section 10',
              },
            },
          ]),
        );

        await tester.tap(
          find.byKey(const ValueKey(kAnalyticsNotifyDataChangedButton)),
        );

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics impression batch to ignore data test", (
      WidgetTester tester,
    ) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<
              _TestAnalyticsImpressionBatchToIgnorePage,
              void
            >(
              create: (data) => _TestAnalyticsImpressionBatchToIgnorePage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        await tester.pumpAndSettle();

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        var tFuture = expectLater(
          tEventStream.asyncMap(
            (event) => {
              'pageName': event.flatData?['pageName'],
              'index': event.flatData?['index'],
              'section': event.flatData?['section'],
            },
          ),
          emitsInOrder([
            {
              'pageName': '_TestAnalyticsImpressionBatchToIgnorePage',
              'index': '30',
              'section': null,
            },
          ]),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -3000));

        await tester.pumpAndSettle();

        await tFuture;
      });

      tApp.dispose();
    });

    testWidgets("Analytics impression visibility test", (
      WidgetTester tester,
    ) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<_TestAnalyticsImpressionVisibilityPage, void>(
              create: (data) => _TestAnalyticsImpressionVisibilityPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        await tester.pumpAndSettle();

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        var tFuture = expectLater(
          tEventStream.asyncMap((event) => {'pageName': event.name}),
          emitsInOrder([
            {'pageName': 'Analytics Impression 10'},
          ]),
        );

        // If you scroll too quickly, the VisibilityChanged won't be triggered, so scroll slowly.
        await tester.timedDrag(
          find.byType(ListView),
          const Offset(0, -500),
          const Duration(seconds: 1),
        );

        await tester.pumpAndSettle();

        // Check the state before scrolling.
        expect(find.text('Impression index : 10'), findsOneWidget);

        await tFuture;

        // If you scroll too quickly, the VisibilityChanged won't be triggered, so scroll slowly.
        await tester.timedDrag(
          find.byType(ListView),
          const Offset(0, -500),
          const Duration(seconds: 1),
        );

        await tester.pumpAndSettle();

        // Check the state after scrolling.
        expect(find.text('Impression index : 10'), findsNothing);
      });

      tApp.dispose();
    });

    testWidgets("Analytics impression threshold callback test", (
      WidgetTester tester,
    ) async {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;

      final App tApp = createApp(
        environment: const Environment(),
        appWidget: StandardMaterialApp(
          onGenerateTitle: (context) => 'title',
          pages: [
            StandardPageFactory<
              _TestAnalyticsImpressionThresholdCallbackPage,
              void
            >(
              create: (data) => _TestAnalyticsImpressionThresholdCallbackPage(),
              links: {r'': (match, uri) {}},
              linkGenerator: (pageData) => '',
              groupRoot: true,
            ),
          ],
        ),
      );

      await tApp.run();

      await tApp.runProcess(() async {
        final tAnalytics = tApp.analytics;

        await tester.pumpAndSettle();

        final Stream<AnalyticsEvent> tEventStream = tAnalytics
            .eventsFor<Analytics>();

        var tFuture = expectLater(
          tEventStream.asyncMap((event) => {'pageName': event.name}),
          emitsInOrder([
            {'pageName': 'Analytics Impression 10'},
          ]),
        );

        // If you scroll too quickly, the VisibilityChanged won't be triggered, so scroll slowly.
        await tester.timedDrag(
          find.byType(ListView),
          const Offset(0, -500),
          const Duration(seconds: 2),
        );

        await tester.pumpAndSettle();

        // Check the state before scrolling.
        expect(find.text('Impression index : 10'), findsOneWidget);

        // If you scroll too quickly, the VisibilityChanged won't be triggered, so scroll slowly.
        await tester.timedDrag(
          find.byType(ListView),
          const Offset(0, -800),
          const Duration(seconds: 2),
        );

        await tester.pumpAndSettle();

        await tFuture;

        // Check the state after scrolling.
        expect(find.text('Impression index : 10'), findsNothing);
      });

      tApp.dispose();
    });
  });

  // unit tests
  group('Analytics Unit Tests', () {
    // defaultMakeLoggableToNative tests
    test('defaultMakeLoggableToNative test with null object', () {
      const object = null;
      final result = Analytics.defaultMakeLoggableToNative(object);
      expect(result, equals(''));
    });

    test('defaultMakeLoggableToNative test with int object', () {
      const object = 123;
      final result = Analytics.defaultMakeLoggableToNative(object);
      expect(result, equals(object));
    });

    test('defaultMakeLoggableToNative test with double object', () {
      const object = 123.456;
      final result = Analytics.defaultMakeLoggableToNative(object);
      expect(result, equals(object));
    });

    test('defaultMakeLoggableToNative test with String object', () {
      const object = 'This is a test string';
      final result = Analytics.defaultMakeLoggableToNative(object);
      expect(result, equals(object.characters.take(100).toString()));
    });

    test('defaultMakeLoggableToNative test with long String object', () {
      final object = 'a' * 200;
      final result = Analytics.defaultMakeLoggableToNative(object);
      expect(result, equals(object.characters.take(100).toString()));
    });

    test('defaultMakeLoggableToNative test with json encodable object', () {
      final object = {'key': 'value'};
      final result = Analytics.defaultMakeLoggableToNative(object);
      expect(
        result,
        equals(jsonEncode(object).characters.take(100).toString()),
      );
    });

    test('defaultMakeLoggableToNative test with non-json encodable object', () {
      final object = Object();
      final result = Analytics.defaultMakeLoggableToNative(object);
      expect(result, equals(object.toString()));
    });

    // tryConvertToLoggableJsonParameters tests
    test('tryConvertToLoggableJsonParameters test with null object', () {
      final result = Analytics.tryConvertToLoggableJsonParameters('', null);
      expect(result, equals({}));
    });

    test('tryConvertToLoggableJsonParameters test with String object', () {
      const object = 'This is a test string';
      final result = Analytics.tryConvertToLoggableJsonParameters('', object);
      expect(result, equals({'1': object}));
    });

    test('tryConvertToLoggableJsonParameters test with int object', () {
      const object = 123;
      final result = Analytics.tryConvertToLoggableJsonParameters('', object);
      expect(result, equals({'1': object.toString()}));
    });

    test('tryConvertToLoggableJsonParameters test with double object', () {
      const object = 123.456;
      final result = Analytics.tryConvertToLoggableJsonParameters('', object);
      expect(result, equals({'1': object.toString()}));
    });

    test(
      'tryConvertToLoggableJsonParameters test with json encodable object',
      () {
        final object = {'key': 'value'};
        final result = Analytics.tryConvertToLoggableJsonParameters('', object);
        expect(result, equals({'1': jsonEncode(object)}));
      },
    );

    test(
      'tryConvertToLoggableJsonParameters test with non-json encodable object',
      () {
        final object = Object();
        final result = Analytics.tryConvertToLoggableJsonParameters('', object);
        expect(result, equals({}));
      },
    );

    // hashcode tests
    test('AnalyticsContext hashCode test', () {
      final analyticsContext1 = AnalyticsContext({'key': 'value'});
      final analyticsContext2 = AnalyticsContext({'key': 'value'});

      expect(analyticsContext1.hashCode, equals(analyticsContext2.hashCode));

      final analyticsContext3 = AnalyticsContext({'key': 'otherValue'});

      expect(
        analyticsContext1.hashCode,
        isNot(equals(analyticsContext3.hashCode)),
      );
    });
  });
}
