// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:patapata_core/patapata_widgets.dart';

import 'utils/patapata_core_test_utils.dart';

final List<String> _data = List.generate(210, (index) => 'Item $index');
Future<List<String>> _fetch(int offset, int count) {
  assert(offset >= 0);

  return Future.delayed(
    const Duration(milliseconds: 100),
    () => _data.skip(offset).take(count).toList(),
  );
}

// Fake fetchNext function to successfully fetch data
Future<List<String>> fakeFetchNext(int index, int crossAxisCount) async {
  return await _fetch(index, 10);
}

// Fake fetchPrev function to successfully fetch data
Future<List<String>> fakeFetchPrev(int index, int crossAxisCount) async {
  if (index < 0) {
    return [];
  }
  final tNewBackOffset = max(0, index - 10 + 1);
  final tFetchCount = index + 1 - tNewBackOffset;
  return await _fetch(tNewBackOffset, tFetchCount);
}

// Fake fetchNext function that throws an error
Future<List<String>> fakeFetchNextError(int index, int crossAxisCount) async {
  await Future.delayed(const Duration(milliseconds: 100));
  throw Exception('FetchNext Error');
}

// Fake fetchPrev function to throw an error
Future<List<String>> fakeFetchPrevError(int index, int crossAxisCount) async {
  await Future.delayed(const Duration(milliseconds: 100));
  throw Exception('FetchPrev Error');
}

// Item Builder
Widget itemBuilder(BuildContext context, String item, int index) {
  return SizedBox(width: 100, height: 100, child: Text(item));
}

// Helper function to build the widget for testing
Widget buildTestWidget({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}

Future<void> _setTestDeviceSize(WidgetTester tester) async {
  await setTestDeviceSize(tester, const Size(300, 600));
}

void main() {
  testWidgets('Initialization test in list mode', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // CircularProgressIndicator is present in the listing as a load trigger.
    // CircularProgressIndicator cannot use pumpAndSettle because of infinite animation.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    for (var i = 0; i < 6; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 6'), findsNothing);
  });

  testWidgets('Initialization test in grid mode', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.grid(
          fetchNext: fakeFetchNext,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 200,
          ),
          itemBuilder: itemBuilder,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    for (var i = 0; i < 6; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 6'), findsNothing);
  });

  testWidgets('Test if fetchNext throws an error', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    await runZonedGuarded(
      () async {
        Object? tExceptionA;
        Object? tExceptionB;
        await tester.pumpWidget(
          buildTestWidget(
            child: InfiniteScrollListView.list(
              fetchNext: (index, crossAxisCount) async {
                try {
                  return await fakeFetchNextError(index, crossAxisCount);
                } catch (e) {
                  tExceptionA = e;
                  rethrow;
                }
              },
              itemBuilder: itemBuilder,
              errorBuilder: (context, error) {
                tExceptionB = error;
                return Center(child: Text(error.toString()));
              },
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);

        expect(tExceptionA, equals(tExceptionB));
        expect(find.text(tExceptionA.toString()), findsOneWidget);
      },
      (error, stackTrace) {
        if (error.toString() == 'Exception: FetchNext Error') {
          return;
        }
        throw error;
      },
    );
  });

  testWidgets('Test for empty data', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    Future<List<String>> fetchNextEmpty(int index, int crossAxisCount) async {
      return [];
    }

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fetchNextEmpty,
          itemBuilder: itemBuilder,
          empty: const Text('empty'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('Test if canFetchNext works', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    int tLastFetchIndex = 0;
    final tShouldCallFetch = expectAsync0(() => null, count: 3);
    Future<List<String>> fetchNext(int index, int crossAxisCount) async {
      tLastFetchIndex = index;
      tShouldCallFetch();
      return await fakeFetchNext(index, crossAxisCount);
    }

    int tLastCanFetchIndex = 0;
    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fetchNext,
          itemBuilder: itemBuilder,
          canFetchNext: (index) {
            tLastCanFetchIndex = index;
            return index < 30;
          },
          // Disable cache area for easier testing.
          cacheExtent: 0.0,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tLastCanFetchIndex, equals(0));
    expect(tLastFetchIndex, equals(0));

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(tLastFetchIndex, equals(0));
    expect(find.text('Item 6'), findsNothing);
    expect(tLastCanFetchIndex, equals(10));

    const tDragType = InfiniteScrollListView<String>;

    // Scroll to just before load trigger
    await tester.drag(find.byType(tDragType), const Offset(0, -400));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    for (var i = 6; i < 10; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 10'), findsNothing);

    // Scroll to load trigger and call fetchNext
    // 10 to 19 will be loaded.
    await tester.drag(find.byType(tDragType), const Offset(0, -100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Item 10'), findsOneWidget);
    expect(find.text('Item 11'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -600));
    await tester.pump();
    for (var i = 11; i < 17; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 17'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -300));
    await tester.pump();
    for (var i = 17; i < 20; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 20'), findsNothing);
    expect(tLastFetchIndex, equals(10));
    expect(tLastCanFetchIndex, equals(20));
    // 20 to 29 will be loaded.
    await tester.drag(find.byType(tDragType), const Offset(0, -100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Item 20'), findsOneWidget);
    expect(find.text('Item 21'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -600));
    await tester.pump();
    for (var i = 21; i < 27; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 27'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -300));
    await tester.pump();
    for (var i = 27; i < 30; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 30'), findsNothing);
    expect(tLastFetchIndex, equals(20));
    expect(tLastCanFetchIndex, equals(30));

    // Confirm that fetchNext is not called
    await tester.drag(find.byType(tDragType), const Offset(0, -100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Item 29'), findsOneWidget);
    expect(find.text('Item 30'), findsNothing);

    expect(tLastFetchIndex, equals(20));
    expect(tLastCanFetchIndex, equals(30));
  });

  testWidgets('Test to keep calling fetchNext until there is no more data', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tShouldCallFetch = expectAsync0(() => null, count: 4);
    int tLastFetchIndex = 0;
    Future<List<String>> fetchNext(int index, int crossAxisCount) async {
      tShouldCallFetch();
      tLastFetchIndex = index;
      if (index < 30) {
        return await fakeFetchNext(index, crossAxisCount);
      }
      return [];
    }

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fetchNext,
          itemBuilder: itemBuilder,
          // Disable cache area for easier testing.
          cacheExtent: 0.0,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tLastFetchIndex, equals(0));

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 6'), findsNothing);
    expect(tLastFetchIndex, equals(0));

    const tDragType = InfiniteScrollListView<String>;

    // Scroll to load trigger and call fetchNext.
    // 10 to 19 will be loaded.
    await tester.drag(find.byType(tDragType), const Offset(0, -500));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Item 10'), findsOneWidget);
    expect(find.text('Item 11'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -600));
    await tester.pump();
    for (var i = 11; i < 17; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 17'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -300));
    await tester.pump();
    for (var i = 17; i < 20; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 20'), findsNothing);
    expect(tLastFetchIndex, equals(10));
    // 20 to 29 will be loaded.
    await tester.drag(find.byType(tDragType), const Offset(0, -100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Item 20'), findsOneWidget);
    expect(find.text('Item 21'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -600));
    await tester.pump();
    for (var i = 21; i < 27; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 27'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, -300));
    await tester.pump();
    for (var i = 27; i < 30; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 30'), findsNothing);
    expect(tLastFetchIndex, equals(20));

    // Confirm that empty data is returned and that fetchNext will not be called next time.
    await tester.drag(find.byType(tDragType), const Offset(0, -100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Item 29'), findsOneWidget);
    expect(find.text('Item 30'), findsNothing);
    expect(tLastFetchIndex, equals(30));
    await tester.drag(find.byType(tDragType), const Offset(0, -100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Item 29'), findsOneWidget);
    expect(find.text('Item 30'), findsNothing);
    expect(tLastFetchIndex, equals(30));
  });

  testWidgets(
    'Even if canFetchNext returns true, if fetchNext returns an empty list, no further data will be loaded.',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      final tShouldCallFetch = expectAsync0(() => null, count: 3);
      int tLastFetchIndex = 0;
      Future<List<String>> fetchNext(int index, int crossAxisCount) async {
        tShouldCallFetch();
        tLastFetchIndex = index;
        if (index < 20) {
          return await fakeFetchNext(index, crossAxisCount);
        }
        return [];
      }

      int tLastCanFetchIndex = 0;
      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.list(
            fetchNext: fetchNext,
            itemBuilder: itemBuilder,
            canFetchNext: (index) {
              tLastCanFetchIndex = index;
              return true;
            },
            // Disable cache area for easier testing.
            cacheExtent: 0.0,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tLastFetchIndex, equals(0));
      expect(tLastCanFetchIndex, equals(0));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 6'), findsNothing);
      expect(tLastFetchIndex, equals(0));
      expect(tLastCanFetchIndex, equals(10));

      const tDragType = InfiniteScrollListView<String>;

      // 10 to 19 will be loaded.
      await tester.drag(find.byType(tDragType), const Offset(0, -500));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 10'), findsOneWidget);
      expect(find.text('Item 11'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, -600));
      await tester.pump();
      for (var i = 11; i < 17; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 17'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, -300));
      await tester.pump();
      for (var i = 17; i < 20; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 20'), findsNothing);
      expect(tLastFetchIndex, equals(10));
      expect(tLastCanFetchIndex, equals(20));

      // Confirm that empty data is returned and that fetchNext will not be called next time.
      await tester.drag(find.byType(tDragType), const Offset(0, -100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 19'), findsOneWidget);
      expect(find.text('Item 20'), findsNothing);
      expect(tLastFetchIndex, equals(20));
      expect(tLastCanFetchIndex, equals(20));
      await tester.drag(find.byType(tDragType), const Offset(0, -100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Item 19'), findsOneWidget);
      expect(find.text('Item 20'), findsNothing);

      expect(tLastFetchIndex, equals(20));
      expect(tLastCanFetchIndex, equals(20));
    },
  );

  testWidgets('Test reset when data key is changed', (
    WidgetTester tester,
  ) async {
    final tKey1 = UniqueKey();
    final tKey2 = UniqueKey();

    final tShouldCall = expectAsync0(() => null, count: 2);

    int fInitialIndex() {
      tShouldCall();
      return 0;
    }

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          dataKey: tKey1,
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          initialIndex: fInitialIndex,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    expect(find.text('Item 0'), findsOneWidget);

    // Change data key
    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          dataKey: tKey2,
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          initialIndex: fInitialIndex,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    expect(find.text('Item 0'), findsOneWidget);
  });

  testWidgets('Test when initialIndex is present in the data', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          initialIndex: () => 6,
          canFetchNext: (index) {
            return index < 15;
          },
          canFetchPrev: (index) => false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the initial indexed item is displayed.
    expect(find.text('Item 0'), findsNothing);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 3'), findsNothing);
    expect(find.text('Item 4'), findsNothing);
    expect(find.text('Item 5'), findsNothing);
    expect(find.text('Item 6'), findsOneWidget);
    expect(find.text('Item 7'), findsOneWidget);
    expect(find.text('Item 8'), findsOneWidget);
    expect(find.text('Item 9'), findsOneWidget);
    expect(find.text('Item 10'), findsOneWidget);
    expect(find.text('Item 11'), findsOneWidget);
    expect(find.text('Item 12'), findsNothing);
  });

  testWidgets(
    'Test that retry succeeds when initialIndex is not present in the data',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      int tNotFoundIndex = 0;
      bool tGiveup = false;
      int tInitialIndex = 15;
      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.list(
            fetchNext: fakeFetchNext,
            itemBuilder: itemBuilder,
            initialIndex: () => tInitialIndex,
            canFetchNext: (index) {
              return index < 10;
            },
            initialIndexNotFoundCallback: (index, giveup) {
              tNotFoundIndex = index;
              tGiveup = giveup;
              tInitialIndex = 0;
              return true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tGiveup, isFalse);
      expect(tNotFoundIndex, equals(15));
      for (var i = 0; i < 6; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 6'), findsNothing);
    },
  );

  testWidgets(
    'Test to abort retry if initialIndex is not present in the data',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      int tNotFoundIndex = 0;
      bool tGiveup = false;
      Future<List<String>> fetchNextFail(int index, int crossAxisCount) async {
        return [];
      }

      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.list(
            fetchNext: fetchNextFail,
            itemBuilder: itemBuilder,
            initialIndex: () => 15,
            initialIndexNotFoundCallback: (index, giveup) {
              tNotFoundIndex = index;
              tGiveup = giveup;
              return false;
            },
            empty: const Text('empty'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tGiveup, isFalse);
      expect(tNotFoundIndex, equals(15));
      expect(find.text('empty'), findsOneWidget);
    },
  );

  testWidgets(
    'Test where retry fails if initialIndex is not present in the data',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      Future<List<String>> fetchNextFail(int index, int crossAxisCount) async {
        return [];
      }

      bool tGiveup = false;
      int tRetryCount = 0;
      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.list(
            fetchNext: fetchNextFail,
            itemBuilder: itemBuilder,
            initialIndex: () => 15,
            initialIndexNotFoundCallback: (index, giveup) {
              if (giveup) {
                tGiveup = giveup;
              } else {
                tRetryCount++;
              }
              return true;
            },
            empty: const Text('empty'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tGiveup, isTrue);
      expect(tRetryCount, equals(10));
      expect(find.text('empty'), findsOneWidget);
    },
  );

  testWidgets('Test treated as 0 if initialIndex is less than 0', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tShouldCallFetch = expectAsync0(() => null, count: 1);
    int? tIndex;
    Future<List<String>> fetchNextFail(int index, int crossAxisCount) async {
      tShouldCallFetch();
      tIndex = index;
      return await fakeFetchNext(index, crossAxisCount);
    }

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fetchNextFail,
          itemBuilder: itemBuilder,
          initialIndex: () => -1,
          empty: const Text('empty'),
          canFetchNext: (index) => index < 10,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tIndex, equals(0));
  });

  testWidgets(
    'Test if crossAxisCount is correctly passed to fetch function in grid mode',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.grid(
            fetchNext: (index, crossAxisCount) async {
              expect(crossAxisCount, equals(3));
              return await fakeFetchNext(index, crossAxisCount);
            },
            fetchPrev: (index, crossAxisCount) async {
              expect(crossAxisCount, equals(3));
              return await fakeFetchPrev(index, crossAxisCount);
            },
            canFetchPrev: (index) => index >= 0,
            initialIndex: () => 3,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 100,
            ),
            itemBuilder: itemBuilder,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Because 18 elements are assumed to be displayed on the screen, fetchNext is called twice.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      for (var i = 3; i < 21; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 21'), findsNothing);

      await tester.drag(
        find.byType(InfiniteScrollListView<String>),
        const Offset(0, 100),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      for (var i = 0; i < 18; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 18'), findsNothing);
    },
  );

  testWidgets('Test if onIndexChanged is working in grid mode', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    int? tIndex;
    int? tCrossAxisCount;
    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.grid(
          fetchNext: (index, crossAxisCount) async {
            return await _fetch(index, 100);
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: 100,
          ),
          onIndexChanged: (index, crossAxisCount) {
            tIndex = index;
            tCrossAxisCount = crossAxisCount;
          },
          itemBuilder: itemBuilder,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 0),
    );
    await tester.pump();
    expect(tIndex, equals(3));
    expect(tCrossAxisCount, equals(3));

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 0),
    );
    await tester.pump();
    expect(tIndex, equals(6));
    expect(tCrossAxisCount, equals(3));

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 0),
    );
    await tester.pump();
    expect(tIndex, equals(9));
    expect(tCrossAxisCount, equals(3));
  });

  testWidgets(
    'In grid mode, test that initialIndex is recalculated to a multiple of crossAxisCount',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      int? tIndex;

      Object tDataKey = Object();
      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.grid(
            dataKey: ObjectKey(tDataKey),
            fetchNext: (index, crossAxisCount) async {
              tIndex = index;
              return await _fetch(index, 100);
            },
            initialIndex: () => 5,
            canFetchNext: (index) => index < 100,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 300,
            ),
            itemBuilder: itemBuilder,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      expect(tIndex, equals(3));

      for (var i = 3; i < 9; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 9'), findsNothing);

      tIndex = null;
      tDataKey = Object();
      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.grid(
            dataKey: ObjectKey(tDataKey),
            fetchNext: (index, crossAxisCount) async {
              tIndex = index;
              return await _fetch(index, 100);
            },
            initialIndex: () => 1,
            canFetchNext: (index) => index < 100,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 300,
            ),
            itemBuilder: itemBuilder,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      expect(tIndex, equals(0));

      for (var i = 0; i < 6; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 6'), findsNothing);
    },
  );

  testWidgets('Test if fetchPrev,canFetchPrev works', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    final tShouldCallFetch = expectAsync0(() => null, count: 2);
    int tLastFetchIndex = 0;
    Future<List<String>> fetchPrev(int index, int crossAxisCount) async {
      tShouldCallFetch();
      tLastFetchIndex = index;
      return await fakeFetchPrev(index, crossAxisCount);
    }

    int tLastCanFetchIndex = 0;
    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          initialIndex: () => 20,
          fetchPrev: fetchPrev,
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          canFetchPrev: (index) {
            tLastCanFetchIndex = index;
            return index >= 0;
          },
          canFetchNext: (index) {
            return index < 30;
          },
          // Disable cache area for easier testing.
          cacheExtent: 0.0,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tLastCanFetchIndex, equals(0));
    expect(tLastFetchIndex, equals(0));

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    for (var i = 20; i < 26; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(tLastFetchIndex, equals(0));
    expect(find.text('Item 19'), findsNothing);
    expect(tLastCanFetchIndex, equals(19));

    const tDragType = InfiniteScrollListView<String>;

    // 19 to 10 will be loaded.
    await tester.drag(find.byType(tDragType), const Offset(0, 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Item 19'), findsOneWidget);
    expect(find.text('Item 18'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, 600));
    await tester.pump();
    for (var i = 13; i < 18; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 12'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, 300));
    await tester.pump();
    for (var i = 10; i < 12; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 9'), findsNothing);
    expect(tLastFetchIndex, equals(19));
    expect(tLastCanFetchIndex, equals(9));
    // 9 to 0 will be loaded.
    await tester.drag(find.byType(tDragType), const Offset(0, 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Item 9'), findsOneWidget);
    expect(find.text('Item 8'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, 600));
    await tester.pump();
    for (var i = 3; i < 8; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 2'), findsNothing);
    await tester.drag(find.byType(tDragType), const Offset(0, 300));
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item -1'), findsNothing);
    expect(tLastFetchIndex, equals(9));
    expect(tLastCanFetchIndex, equals(-1));

    await tester.drag(find.byType(tDragType), const Offset(0, 100));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item -1'), findsNothing);

    expect(tLastFetchIndex, equals(9));
    expect(tLastCanFetchIndex, equals(-1));
  });

  testWidgets(
    'Test to keep calling fetchPrev until no more data is available.',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      final tShouldCallFetch = expectAsync0(() => null, count: 3);
      int tLastFetchIndex = 0;
      Future<List<String>> fetchPrev(int index, int crossAxisCount) async {
        tShouldCallFetch();
        tLastFetchIndex = index;
        return await fakeFetchPrev(index, crossAxisCount);
      }

      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.list(
            initialIndex: () => 20,
            fetchPrev: fetchPrev,
            fetchNext: fakeFetchNext,
            itemBuilder: itemBuilder,
            canFetchNext: (index) {
              return index < 30;
            },
            // Disable cache area for easier testing.
            cacheExtent: 0.0,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tLastFetchIndex, equals(0));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      for (var i = 20; i < 26; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(tLastFetchIndex, equals(0));
      expect(find.text('Item 19'), findsNothing);

      const tDragType = InfiniteScrollListView<String>;

      // 19 to 10 will be loaded.
      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 19'), findsOneWidget);
      expect(find.text('Item 18'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 600));
      await tester.pump();
      for (var i = 13; i < 18; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 12'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 300));
      await tester.pump();
      for (var i = 10; i < 12; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 9'), findsNothing);
      expect(tLastFetchIndex, equals(19));
      // 9 to 0 will be loaded.
      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 9'), findsOneWidget);
      expect(find.text('Item 8'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 600));
      await tester.pump();
      for (var i = 3; i < 8; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 2'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 300));
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item -1'), findsNothing);
      expect(tLastFetchIndex, equals(9));

      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item -1'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item -1'), findsNothing);

      expect(tLastFetchIndex, equals(-1));
    },
  );

  testWidgets(
    'Even if canFetchPrev returns true, if fetchPrev returns an empty list, no further data will be loaded.',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      final tShouldCallFetch = expectAsync0(() => null, count: 3);
      int tLastFetchIndex = 0;
      Future<List<String>> fetchPrev(int index, int crossAxisCount) async {
        tShouldCallFetch();
        tLastFetchIndex = index;
        return await fakeFetchPrev(index, crossAxisCount);
      }

      int tLastCanFetchIndex = 0;
      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.list(
            initialIndex: () => 20,
            fetchPrev: fetchPrev,
            fetchNext: fakeFetchNext,
            itemBuilder: itemBuilder,
            canFetchPrev: (index) {
              tLastCanFetchIndex = index;
              return true;
            },
            canFetchNext: (index) {
              return index < 30;
            },
            // Disable cache area for easier testing.
            cacheExtent: 0.0,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tLastCanFetchIndex, equals(0));
      expect(tLastFetchIndex, equals(0));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      for (var i = 20; i < 26; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(tLastFetchIndex, equals(0));
      expect(find.text('Item 19'), findsNothing);
      expect(tLastCanFetchIndex, equals(19));

      const tDragType = InfiniteScrollListView<String>;

      // 19 to 10 will be loaded.
      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 19'), findsOneWidget);
      expect(find.text('Item 18'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 600));
      await tester.pump();
      for (var i = 13; i < 18; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 12'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 300));
      await tester.pump();
      for (var i = 10; i < 12; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 9'), findsNothing);
      expect(tLastFetchIndex, equals(19));
      expect(tLastCanFetchIndex, equals(9));
      // 9 to 0 will be loaded.
      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 9'), findsOneWidget);
      expect(find.text('Item 8'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 600));
      await tester.pump();
      for (var i = 3; i < 8; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 2'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 300));
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item -1'), findsNothing);
      expect(tLastFetchIndex, equals(9));
      expect(tLastCanFetchIndex, equals(-1));

      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item -1'), findsNothing);
      await tester.drag(find.byType(tDragType), const Offset(0, 100));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item -1'), findsNothing);

      expect(tLastFetchIndex, equals(-1));
      expect(tLastCanFetchIndex, equals(-1));
    },
  );

  testWidgets('Test if fetchPrev throws an error', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    await runZonedGuarded(
      () async {
        Object? tExceptionA;
        Object? tExceptionB;
        await tester.pumpWidget(
          buildTestWidget(
            child: InfiniteScrollListView.list(
              fetchPrev: (index, crossAxisCount) async {
                try {
                  return await fakeFetchPrevError(index, crossAxisCount);
                } catch (e) {
                  tExceptionA = e;
                  rethrow;
                }
              },
              initialIndex: () => 10,
              fetchNext: fakeFetchNext,
              itemBuilder: itemBuilder,
              errorBuilder: (context, error) {
                tExceptionB = error;
                return Center(child: Text(error.toString()));
              },
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.drag(
          find.byType(InfiniteScrollListView<String>),
          const Offset(0, 100),
        );
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        expect(tExceptionA, equals(tExceptionB));
        expect(find.text(tExceptionA.toString()), findsOneWidget);
      },
      (error, stackTrace) {
        if (error.toString() == 'Exception: FetchPrev Error') {
          return;
        }
        throw error;
      },
    );
  });

  testWidgets('Test that loading,loadingMore is displayed correctly', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fakeFetchNext,
          fetchPrev: fakeFetchPrev,
          itemBuilder: itemBuilder,
          loading: const Center(child: Text('loading')),
          loadingMore: const SizedBox(
            height: 100,
            child: Center(child: Text('loadingMore')),
          ),
          initialIndex: () => 10,
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('loading'), findsNothing);

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, -500),
    );
    await tester.pump();

    expect(find.text('loadingMore'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('loadingMore'), findsNothing);

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 600),
    );
    await tester.pump();

    expect(find.text('loadingMore'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('loadingMore'), findsNothing);
  });

  testWidgets('Test that the refresh function works', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    bool tRefreshed = false;
    Future<void> onRefresh() async {
      tRefreshed = true;
    }

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: (index, crossAxisCount) async {
            final tResult = await fakeFetchNext(index, crossAxisCount);
            return tResult.map((e) => '$e:$tRefreshed').toList();
          },
          itemBuilder: itemBuilder,
          canRefresh: true,
          onRefresh: onRefresh,
          canFetchNext: (index) => index < 10,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item 0:false'), findsOneWidget);

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    expect(tRefreshed, isTrue);
    expect(find.text('Item 0:true'), findsOneWidget);
    expect(find.text('Item 0:false'), findsNothing);
  });

  testWidgets('Test that refreshIndicatorBuilder works', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    bool tRefreshed = false;
    Future<void> onRefresh() async {
      tRefreshed = true;
    }

    final tShouldCallRefresh = expectAsync0(() => null, count: 1);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: (index, crossAxisCount) async {
            final tResult = await fakeFetchNext(index, crossAxisCount);
            return tResult.map((e) => '$e:$tRefreshed').toList();
          },
          itemBuilder: itemBuilder,
          canRefresh: true,
          refreshIndicatorBuilder: (context, child, refresh) {
            return RefreshIndicator(
              onRefresh: () {
                tShouldCallRefresh();
                return refresh();
              },
              child: child,
            );
          },
          onRefresh: onRefresh,
          canFetchNext: (index) => index < 10,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item 0:false'), findsOneWidget);

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    expect(tRefreshed, isTrue);
    expect(find.text('Item 0:true'), findsOneWidget);
    expect(find.text('Item 0:false'), findsNothing);
  });

  testWidgets('Test that refresh does not work if canRefresh is false', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    bool tRefreshed = false;
    Future<void> onRefresh() async {
      tRefreshed = true;
    }

    final tShouldCallRefresh = expectAsync0(() => null, count: 0);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: (index, crossAxisCount) async {
            final tResult = await fakeFetchNext(index, crossAxisCount);
            return tResult.map((e) => '$e:$tRefreshed').toList();
          },
          itemBuilder: itemBuilder,
          canRefresh: false,
          refreshIndicatorBuilder: (context, child, refresh) {
            return RefreshIndicator(
              onRefresh: () {
                tShouldCallRefresh();
                return refresh();
              },
              child: child,
            );
          },
          onRefresh: onRefresh,
          canFetchNext: (index) => index < 10,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item 0:false'), findsOneWidget);

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    expect(tRefreshed, isFalse);
    expect(find.text('Item 0:false'), findsOneWidget);
    expect(find.text('Item 0:true'), findsNothing);
  });

  testWidgets('Test when scroll direction is horizontal', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          scrollDirection: Axis.horizontal,
          fetchNext: fakeFetchNext,
          fetchPrev: fakeFetchPrev,
          itemBuilder: itemBuilder,
          initialIndex: () => 10,
          loading: const Center(child: Text('loading')),
          loadingMore: const SizedBox(
            height: 100,
            width: 100,
            child: Center(child: Text('loadingMore')),
          ),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('loading'), findsNothing);

    expect(find.text('Item 10'), findsOneWidget);
    expect(find.text('Item 9'), findsNothing);

    // fetchNext
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(-700, 0),
    );
    await tester.pump();
    expect(find.text('Item 10'), findsNothing);
    expect(find.text('Item 19'), findsOneWidget);
    expect(find.text('Item 20'), findsNothing);
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(-100, 0),
    );
    await tester.pump();
    expect(find.text('loadingMore'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('loadingMore'), findsNothing);
    expect(find.text('Item 20'), findsOneWidget);

    // fetchPrev
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(900, 0),
    );
    await tester.pump();
    expect(find.text('loadingMore'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('loadingMore'), findsNothing);
    expect(find.text('Item 9'), findsOneWidget);
  });

  testWidgets('Test that overlaySlivers are displayed correctly', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          overlaySlivers: const [
            SliverToBoxAdapter(
              child: SizedBox(height: 100, child: Text('overlay')),
            ),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('overlay'), findsOneWidget);
  });

  testWidgets('Test that prefixes are displayed correctly', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          prefix: const SizedBox(height: 100, child: Text('prefix')),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('prefix'), findsOneWidget);
  });

  testWidgets('Test for correct display of suffixes', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: (index, crossAxisCount) async {
            return ['Item 0'];
          },
          itemBuilder: itemBuilder,
          canFetchNext: (index) => index < 1,
          suffix: const SizedBox(height: 100, child: Text('suffix')),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('suffix'), findsOneWidget);
  });

  testWidgets('Test that the onIndexChanged callback is called', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    int? tChangedIndex;
    int? tCrossAxisCount;

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          onIndexChanged: (index, crossAxisCount) {
            tChangedIndex = index;
            tCrossAxisCount = crossAxisCount;
          },
          canFetchNext: (index) => index < 10,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // onIndexChanged is called upon ScrollEndNotification, but index calculation is invoked during performLayout.
    // When a drag occurs, ScrollEndNotification is triggered, but the index calculation has not yet been performed.
    // Since index calculation is performed during pump, by performing drag -> pump -> drag, the calculated index can be obtained.
    // If running on an actual device, performLayout is always called during a drag, so there is no problem.
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 0),
    );
    await tester.pump();

    expect(tChangedIndex, equals(1));
    expect(tCrossAxisCount, equals(1));

    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.drag(
      find.byType(InfiniteScrollListView<String>),
      const Offset(0, 0),
    );
    await tester.pump();

    expect(tChangedIndex, equals(2));
    expect(tCrossAxisCount, equals(1));
  });

  testWidgets(
    'Test that fetchNext continues to be called during initialization until the screen is filled with elements.',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      final tShouldCallFetch = expectAsync0(() => null, count: 6);

      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView.list(
            fetchNext: (index, crossAxisCount) async {
              tShouldCallFetch();
              await Future.delayed(const Duration(milliseconds: 100));
              return List.generate(1, (i) => 'Item ${index + i}');
            },
            itemBuilder: itemBuilder,
            canFetchNext: (index) => index < 10,
            cacheExtent: 0.0,
          ),
        ),
      );

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
      }

      for (var i = 0; i < 6; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 6'), findsNothing);
    },
  );

  testWidgets(
    'At initialization, if there are overlaySlivers or prefixes with initialIndex specified, test that fetchPrev will continue to be called until the area is filled.',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      final tShouldCallFetch = expectAsync0(() => null, count: 2);

      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView<String>.list(
            overlaySlivers: const [
              SliverToBoxAdapter(
                child: SizedBox(height: 100, child: Text('overlay')),
              ),
            ],
            prefix: const SizedBox(height: 100, child: Text('prefix')),
            initialIndex: () => 3,
            fetchPrev: (index, crossAxisCount) async {
              tShouldCallFetch();

              await Future.delayed(const Duration(milliseconds: 100));
              if (index < 0) return [];
              final tNewBackOffset = max(0, index - 1 + 1);
              final tFetchCount = index + 1 - tNewBackOffset;
              return List.generate(
                tFetchCount,
                (i) => 'Item ${tNewBackOffset + i}',
              );
            },
            fetchNext: fakeFetchNext,
            itemBuilder: itemBuilder,
            canFetchNext: (index) => index < 10,
            cacheExtent: 0.0,
          ),
        ),
      );

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
      }

      expect(find.text('overlay'), findsNothing);
      expect(find.text('prefix'), findsNothing);

      for (var i = 1; i < 7; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 0'), findsNothing);
      expect(find.text('Item 7'), findsNothing);
    },
  );

  testWidgets(
    'Test that fetchPrev and fetchNext continue to be called until the screen area is filled during initialization.',
    (WidgetTester tester) async {
      await _setTestDeviceSize(tester);

      final tShouldCallFetchPrev = expectAsync0(() => null, count: 2);
      final tShouldCallFetchNext = expectAsync0(() => null, count: 4);

      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView<String>.list(
            overlaySlivers: const [
              SliverToBoxAdapter(
                child: SizedBox(height: 100, child: Text('overlay')),
              ),
            ],
            prefix: const SizedBox(height: 100, child: Text('prefix')),
            initialIndex: () => 3,
            fetchPrev: (index, crossAxisCount) async {
              tShouldCallFetchPrev();

              await Future.delayed(const Duration(milliseconds: 100));
              if (index < 0) return [];
              final tNewBackOffset = max(0, index - 1 + 1);
              final tFetchCount = index + 1 - tNewBackOffset;
              return List.generate(
                tFetchCount,
                (i) => 'Item ${tNewBackOffset + i}',
              );
            },
            fetchNext: (index, crossAxisCount) async {
              tShouldCallFetchNext();
              await Future.delayed(const Duration(milliseconds: 100));
              return List.generate(1, (i) => 'Item ${index + i}');
            },
            itemBuilder: itemBuilder,
            canFetchNext: (index) => index < 10,
            cacheExtent: 0.0,
          ),
        ),
      );

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
      }

      expect(find.text('overlay'), findsNothing);
      expect(find.text('prefix'), findsNothing);

      for (var i = 1; i < 7; i++) {
        expect(find.text('Item $i'), findsOneWidget);
      }
      expect(find.text('Item 0'), findsNothing);
      expect(find.text('Item 7'), findsNothing);
    },
  );

  testWidgets('padding test', (WidgetTester tester) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView<String>.list(
          padding: const EdgeInsets.symmetric(vertical: 100.0),
          initialIndex: () => 11,
          fetchPrev: fakeFetchPrev,
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
          canFetchNext: (index) => index < 21,
          canFetchPrev: (index) => index >= 0,
          canRefresh: false,
          cacheExtent: 0.0,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    for (var i = 10; i < 16; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 16'), findsNothing);

    const tDragType = InfiniteScrollListView<String>;

    await tester.drag(find.byType(tDragType), const Offset(0, 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.drag(find.byType(tDragType), const Offset(0, 1000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.drag(find.byType(tDragType), const Offset(0, 1000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 5'), findsNothing);

    await tester.drag(find.byType(tDragType), const Offset(0, -3000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('Item 15'), findsNothing);
    for (var i = 16; i < 21; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 21'), findsNothing);
  });

  testWidgets(
    "Test whether data and index information can be retrieved from Item's Widget via Provider",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: InfiniteScrollListView<String>.list(
            fetchNext: (index, crossAxisCount) async {
              return ['Item $index'];
            },
            canFetchNext: (index) => index < 1,
            itemBuilder: (context, item, index) {
              return SizedBox(
                height: 100,
                child: Builder(
                  builder: (context) {
                    final tItem = context.read<String>();
                    final tInfo = context.read<InfiniteScrollItemInformation>();
                    return Text('$tItem:${tInfo.index}');
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Item 0:0'), findsOneWidget);
    },
  );

  testWidgets('Test for correct operation when Item is Listenable', (
    WidgetTester tester,
  ) async {
    final tListenable = ChangeNotifier();
    bool tNotified = false;
    fListener() {
      tNotified = true;
    }

    // itemBuilder is called twice in the initialization phase.
    // then changeNotifier's notifyListeners is called twice.
    final tShouldCallBuild = expectAsync0(() => null, count: 4);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView<ChangeNotifier>.list(
          fetchNext: (index, crossAxisCount) async {
            return [tListenable];
          },
          canFetchNext: (index) => index < 1,
          itemBuilder: (context, item, index) {
            tShouldCallBuild();

            context.watch<ChangeNotifier>();
            return SizedBox(height: 100, child: Text('Item $index'));
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    tListenable.addListener(fListener);
    tListenable.notifyListeners();
    await tester.pumpAndSettle();

    expect(tNotified, isTrue);

    tListenable.removeListener(fListener);
    tNotified = false;
    tListenable.notifyListeners();
    await tester.pumpAndSettle();

    expect(tNotified, isFalse);
  });

  testWidgets('Test that overlaySlivers and prefixes are resized', (
    WidgetTester tester,
  ) async {
    await _setTestDeviceSize(tester);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          overlaySlivers: const [
            SliverToBoxAdapter(
              child: SizedBox(height: 100, child: Text('overlay')),
            ),
          ],
          prefix: const SizedBox(height: 100, child: Text('prefix')),
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('overlay'), findsOneWidget);
    expect(find.text('prefix'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 4'), findsNothing);

    await tester.pumpWidget(
      buildTestWidget(
        child: InfiniteScrollListView.list(
          overlaySlivers: const [
            SliverToBoxAdapter(
              child: SizedBox(height: 50, child: Text('overlay')),
            ),
          ],
          prefix: const SizedBox(height: 50, child: Text('prefix')),
          fetchNext: fakeFetchNext,
          itemBuilder: itemBuilder,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('overlay'), findsOneWidget);
    expect(find.text('prefix'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 5'), findsNothing);
  });

  testWidgets('Test for correct recovery from error states', (
    WidgetTester tester,
  ) async {
    bool tShouldFail = true;

    Object? tExceptionA;
    Object? tExceptionB;
    await runZonedGuarded(
      () async {
        Future<List<String>> fetchNextToggle(
          int index,
          int crossAxisCount,
        ) async {
          await Future.delayed(const Duration(milliseconds: 100));
          if (tShouldFail) {
            tExceptionA = Exception('Error');
            throw tExceptionA!;
          }
          return await fakeFetchNext(index, crossAxisCount);
        }

        await tester.pumpWidget(
          buildTestWidget(
            child: InfiniteScrollListView.list(
              fetchNext: fetchNextToggle,
              itemBuilder: itemBuilder,
              errorBuilder: (context, error) {
                tExceptionB = error;
                return Center(child: Text(error.toString()));
              },
              canRefresh: true,
              onRefresh: () {
                tShouldFail = false;
              },
              canFetchNext: (index) => index < 10,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(tExceptionA, equals(tExceptionB));
        expect(find.text(tExceptionA.toString()), findsOneWidget);

        await tester.drag(
          find.byType(InfiniteScrollListView<String>),
          const Offset(0, 500),
        );
        await tester.pumpAndSettle();

        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text(tExceptionA.toString()), findsNothing);
      },
      (error, stackTrace) {
        if (error.toString() == 'Exception: Error') {
          return;
        }
        throw error;
      },
    );
  });
}
