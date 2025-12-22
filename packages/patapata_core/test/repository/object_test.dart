// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:provider/provider.dart';

import './model/test_model2.dart';
import 'test_data.dart';

class TestApp {
  Widget createMyApp(TestData testData, TestRepository repository) {
    return MaterialApp(
      home: Provider<TestRepository>(
        create: (context) => repository,
        child: const TestProvider(),
      ),
    );
  }
}

abstract class TestRepository extends Repository<TestModel, int> {
  TestRepository(this.testData);
  final TestData testData;

  void setEnv(dynamic env) {}
}

class TestSingleDataRepository extends TestRepository {
  TestSingleDataRepository(super.testData);

  @override
  Map<Type, Future<TestModel?> Function(int id)> get singleSetFetchers =>
      <Type, Future<TestModel?> Function(int id)>{
        TestModel: (id) {
          final tData = testData.data[id];
          return Future.value(TestModel.fromRecord(id, tData!));
        },
        Filter1: (id) {
          final tData = testData.data[id];
          return Future.value(TestModel.init(id, v2: tData?.$2, v3: tData?.$3));
        },
      };

  @override
  Map<Type, Future<List<TestModel?>> Function(List<int> ids)>
  get multiSetFetchers => {};
}

class TestMultiDataRepository extends TestRepository {
  TestMultiDataRepository(super.testData);

  @override
  Map<Type, Future<TestModel?> Function(int id)> get singleSetFetchers => {};

  @override
  Map<Type, Future<List<TestModel?>> Function(List<int> ids)>
  get multiSetFetchers =>
      <Type, Future<List<TestModel?>> Function(List<int> ids)>{
        TestModel: (ids) {
          return Future.value(
            List.generate(ids.length, (i) {
              final tId = ids[i];
              final tData = testData.data[tId];
              return TestModel.init(
                tId,
                v1: tData?.$1,
                v2: tData?.$2,
                v3: tData?.$3,
              );
            }),
          );
        },
        Filter1: (ids) {
          return Future.value(
            List.generate(ids.length, (i) {
              final tId = ids[i];
              final tData = testData.data[tId];
              return TestModel.init(tId, v2: tData?.$2, v3: tData?.$3);
            }),
          );
        },
      };
}

class TestRepositoryForOtherPurposes extends TestRepository {
  TestRepositoryForOtherPurposes(super.testData);

  bool singleMode = true;

  @override
  void setEnv(dynamic env) {
    if (env == null) {
      singleMode = true;
      return;
    }

    final tEnv = env as Map<String, dynamic>;

    if (tEnv.containsKey('singleMode')) {
      singleMode = tEnv['singleMode'] as bool;
    }
  }

  @override
  Map<Type, Future<TestModel?> Function(int id)> get singleSetFetchers =>
      singleMode
      ? <Type, Future<TestModel?> Function(int id)>{
          TestModel: (id) {
            final tData = testData.data[id];
            return Future.value(
              TestModelWithNotifier.init(
                id,
                v1: tData?.$1,
                v2: tData?.$2,
                v3: tData?.$3,
              ),
            );
          },
        }
      : {};

  @override
  Map<Type, Future<List<TestModel?>> Function(List<int> ids)>
  get multiSetFetchers => !singleMode
      ? <Type, Future<List<TestModel?>> Function(List<int> ids)>{
          TestModel: (ids) {
            return Future.value(
              List.generate(ids.length, (i) {
                final tId = ids[i];
                final tData = testData.data[tId];
                return TestModelWithNotifier.init(
                  tId,
                  v1: tData?.$1,
                  v2: tData?.$2,
                  v3: tData?.$3,
                );
              }),
            );
          },
        }
      : {};
}

class Anchor extends StatelessWidget {
  const Anchor({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class TestProvider extends StatefulWidget {
  const TestProvider({super.key});

  @override
  TestProviderState createState() => TestProviderState();
}

class TestProviderState extends State<TestProvider> {
  WidgetBuilder? generator;

  void change<S extends Object>(
    List<int> ids,
    Function(dynamic data)? receiver, {
    bool notify = false,
  }) {
    setState(() {
      generator = (BuildContext context) {
        if (ids.length != 1) {
          return RepositoryMultiObserver<TestModel, int, TestRepository>(
            key: ValueKey(Object.hash(ids, S)),
            fetcher: (repository) => repository.fetchMany(ids, S),
            repository: context.read<TestRepository>(),
            notify: notify,
            builder: (context, child, dataList) {
              receiver?.call(dataList);
              return Column(
                children: [
                  if (dataList != null)
                    for (final data in dataList) ...[Text(data?.text ?? '')],
                  child ?? const Anchor(),
                ],
              );
            },
            child: const Anchor(),
          );
        }

        return RepositoryObserver<TestModel, int, TestRepository>(
          key: ValueKey(Object.hash(ids.single, S)),
          id: ids.single,
          fetcher: (repository) => repository.fetch(ids.single, S),
          repository: context.read<TestRepository>(),
          notify: notify,
          builder: (context, child, data) {
            receiver?.call(data);
            return Column(
              children: [Text(data?.text ?? ''), child ?? const Anchor()],
            );
          },
          child: const Anchor(),
        );
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return generator?.call(context) ?? const Anchor();
  }
}

BuildContext findContext(WidgetTester tester) {
  return tester.element(find.byType(Anchor));
}

TestProviderState findProvider(WidgetTester tester) {
  return tester.state<TestProviderState>(find.byType(TestProvider));
}

void execute(Object m, TestValue tv, TestRecord tr) {
  final tModel = m as TestModel;

  final f = switch (tv) {
    TestValue.v1 => (tModel.value1, tr.$1),
    TestValue.v2 => (tModel.value2, tr.$2),
    TestValue.v3 => (tModel.text, tr.$3),
  };

  expect(f.$1, f.$2);
}

void main() {
  late TestApp testApp;
  late TestData testData;

  setUp(() {
    testData = TestData();
    testApp = TestApp();
  });

  group('Test object repository', () {
    testWidgets('Test single set and fetch.', (WidgetTester tester) async {
      await tester.pumpWidget(
        testApp.createMyApp(testData, TestSingleDataRepository(testData)),
      );
      await tester.pumpAndSettle();

      final tRepository = findContext(tester).read<TestRepository>();
      final tProvider = findProvider(tester);

      // Test for the occurrence of an error when using sets is not allowed.
      bool tErrorCalled = false;
      await runZonedGuarded(
        () async {
          tProvider.change<Filter1>([1], null);
          await tester.pumpAndSettle();
        },
        (error, stack) {
          if (error is AssertionError) {
            if (error.message == repositorySetCannotUsedAssertionMessage) {
              tErrorCalled = true;
              return;
            }
          }

          throw error;
        },
      );
      expect(tErrorCalled, isTrue);

      fCompare(int id, bool checkNull) async {
        final tData = testData.data[id]!;

        TestModel? tModel;
        tProvider.change<TestModel>([id], (data) => tModel = data);
        await tester.pumpAndSettle();
        expect(tModel, isNotNull);
        execute(tModel!, TestValue.v1, tData);
        execute(tModel!, TestValue.v2, tData);
        execute(tModel!, TestValue.v3, tData);
      }

      // test first set
      await fCompare(1, true);

      // Test for errors that occur when fetching from a different set after a fetch.
      await expectLater(
        () => tRepository.fetch(1, Filter1),
        throwsAssertionError,
      );

      // fetch cache
      bool tCacheFetchCalled = false;
      TestModel? fCacheThen(TestModel? v) {
        tCacheFetchCalled = true;
        return v;
      }

      // default fetch cache
      Future<TestModel?> tCacheFuture = tRepository
          .fetch(1, TestModel)
          .then(fCacheThen);
      expect(tCacheFetchCalled, isFalse);
      await tCacheFuture;
      expect(tCacheFetchCalled, isTrue);
      // synchronous fetch cache
      tCacheFetchCalled = false;
      tCacheFuture = tRepository
          .fetch(1, TestModel, synchronousCache: true)
          .then(fCacheThen);
      expect(tCacheFetchCalled, isTrue);
      await tCacheFuture;
      // asynchronous fetch cache
      tCacheFetchCalled = false;
      tCacheFuture = tRepository
          .fetch(1, TestModel, synchronousCache: false)
          .then(fCacheThen);
      expect(tCacheFetchCalled, isFalse);
      await tCacheFuture;
      expect(tCacheFetchCalled, isTrue);

      // test build
      tProvider.change<TestModel>([2], (data) async {
        data = data as TestModel;
        await tester.pumpAndSettle();
        expect(data.text, isNotNull);
        expect(find.text(data.text!), findsOneWidget);
      });

      // test clear
      await tRepository.clear();
      await tester.pumpAndSettle();

      // test after clear
      testData.pattern = TestPattern.type2;
      await fCompare(1, true);

      // test refresh, and after refresh compare
      testData.pattern = TestPattern.type1;
      await fCompare(2, true);
      testData.pattern = TestPattern.type2;
      final tCompleter = Completer();
      tRepository.refreshAll().then((value) => tCompleter.complete());
      await tester.pumpAndSettle();
      await tCompleter.future;
      await fCompare(2, false);
    });

    testWidgets('Test multi set and fetch.', (WidgetTester tester) async {
      await tester.pumpWidget(
        testApp.createMyApp(testData, TestMultiDataRepository(testData)),
      );
      await tester.pumpAndSettle();

      final tRepository = findContext(tester).read<TestRepository>();
      final tProvider = findProvider(tester);

      // Test for the occurrence of an error when using sets is not allowed.
      bool tErrorCalled = false;
      await runZonedGuarded(
        () async {
          tProvider.change<Filter1>([1, 2, 3], null);
          await tester.pumpAndSettle();
        },
        (error, stack) {
          if (error is AssertionError) {
            if (error.message == repositorySetCannotUsedAssertionMessage) {
              tErrorCalled = true;
              return;
            }
          }

          throw error;
        },
      );
      expect(tErrorCalled, isTrue);

      fCompare(List<int> ids) async {
        List<TestModel?>? tModelList;
        tProvider.change<TestModel>(ids, (data) => tModelList = data);
        await tester.pumpAndSettle();
        expect(tModelList, isNotNull);

        for (final id in ids) {
          final tData = testData.data[id]!;

          final tModel = tModelList!.firstWhere(
            (e) => e?.id == id,
            orElse: () => null,
          );
          expect(tModel, isNotNull);
          if (tModel != null) {
            execute(tModel, TestValue.v1, tData);
            execute(tModel, TestValue.v2, tData);
            execute(tModel, TestValue.v3, tData);
          }
        }
      }

      // test first set
      await fCompare([1, 2, 3]);

      // Test for errors that occur when fetching from a different set after a fetch.
      await expectLater(
        () => tRepository.fetchMany([1, 2, 3], Filter1),
        throwsAssertionError,
      );

      // fetch cache
      bool tCacheFetchCalled = false;
      List<TestModel?> fCacheThen(List<TestModel?> v) {
        tCacheFetchCalled = true;
        return v;
      }

      // default fetch cache
      Future<List<TestModel?>> tCacheFuture = tRepository
          .fetchMany([1, 2, 3], TestModel)
          .then(fCacheThen);
      expect(tCacheFetchCalled, isFalse);
      await tCacheFuture;
      expect(tCacheFetchCalled, isTrue);
      // synchronous fetch cache
      tCacheFetchCalled = false;
      tCacheFuture = tRepository
          .fetchMany([1, 2, 3], TestModel, synchronousCache: true)
          .then(fCacheThen);
      expect(tCacheFetchCalled, isTrue);
      await tCacheFuture;
      // asynchronous fetch cache
      tCacheFetchCalled = false;
      tCacheFuture = tRepository
          .fetchMany([1, 2, 3], TestModel, synchronousCache: false)
          .then(fCacheThen);
      expect(tCacheFetchCalled, isFalse);
      await tCacheFuture;
      expect(tCacheFetchCalled, isTrue);

      // test build
      tProvider.change<TestModel>([4, 5, 6], (data) async {
        data = data as List<TestModel?>;
        await tester.pumpAndSettle();
        expect(data.length, 3);
        for (final e in data) {
          expect(e, isNotNull);
          expect(e!.text, isNotNull);
          expect(find.text(e.text!), findsOneWidget);
        }
      });

      // test clear
      await tRepository.clear();
      await tester.pumpAndSettle();

      // test after clear
      testData.pattern = TestPattern.type2;
      await fCompare([1, 2, 3]);

      // test refresh, and after refresh compare
      testData.pattern = TestPattern.type1;
      await fCompare([4, 5, 6]);
      testData.pattern = TestPattern.type2;
      final tCompleter = Completer();
      tRepository.refreshAll().then((value) => tCompleter.complete());
      await tester.pumpAndSettle();
      await tCompleter.future;
      await fCompare([4, 5, 6]);

      await tRepository.clear();
      await tester.pumpAndSettle();
    });

    testWidgets('Test single set and store.', (WidgetTester tester) async {
      await tester.pumpWidget(
        testApp.createMyApp(testData, TestSingleDataRepository(testData)),
      );
      await tester.pumpAndSettle();

      final tRepository = findContext(tester).read<TestRepository>();
      final tProvider = findProvider(tester);

      fCompare(int id) async {
        final tData = testData.data[id]!;

        // Is the data entered correct?
        tRepository.store(TestModel.fromRecord(id, tData));
        final tCache = tRepository.get(id);
        expect(tCache, isNotNull);
        if (tCache != null) {
          execute(tCache, TestValue.v1, tData);
          execute(tCache, TestValue.v2, tData);
          execute(tCache, TestValue.v3, tData);
        }

        // In store after fetch, is the value overwritten or not?
        const tOtherRecord = (42, 0.42, 'test store');
        tProvider.change<TestModel>([id], null);
        await tester.pumpAndSettle();
        tRepository.store(TestModel.fromRecord(id, tOtherRecord));
        final tModel = tRepository.get(id);
        expect(tModel, isNotNull);
        if (tModel != null) {
          expect(tModel.value1, tOtherRecord.$1);
          expect(tModel.value2, tOtherRecord.$2);
          expect(tModel.text, tOtherRecord.$3);
        }
      }

      // test first set
      await fCompare(1);

      // test clear
      tRepository.clear();
      await tester.pumpAndSettle();

      // test after clear
      testData.pattern = TestPattern.type2;
      await fCompare(1);
    });

    testWidgets('Test multi set and store.', (WidgetTester tester) async {
      await tester.pumpWidget(
        testApp.createMyApp(testData, TestMultiDataRepository(testData)),
      );
      await tester.pumpAndSettle();

      final tRepository = findContext(tester).read<TestRepository>();
      final tProvider = findProvider(tester);

      fCompare(List<int> ids, bool checkAssertion) async {
        // Is the data entered correct?
        await tRepository.storeMany(
          ids.map((e) => TestModel.fromRecord(e, testData.data[e]!)),
        );

        for (final id in ids) {
          final tCache = tRepository.get(id);
          expect(tCache, isNotNull);
          if (tCache != null) {
            final tData = testData.data[id]!;
            execute(tCache, TestValue.v1, tData);
            execute(tCache, TestValue.v2, tData);
            execute(tCache, TestValue.v3, tData);
          }
        }

        // In store after fetch, is the value overwritten or not?
        final tOtherRecords = Map.fromIterables(
          ids,
          ids.map((e) => (42 + e, 0.42 + e, 'id / $e test store')).toList(),
        );
        tProvider.change<TestModel>(ids, null);
        await tester.pumpAndSettle();
        await tRepository.storeMany(
          ids.map((e) => TestModel.fromRecord(e, tOtherRecords[e]!)),
        );

        final tModelList = tRepository.getMany(ids);
        expect(tModelList, isNotNull);

        for (final id in ids) {
          final tModel = tModelList.firstWhere((e) => e.id == id);
          expect(tModel.value1, tOtherRecords[id]!.$1);
          expect(tModel.value2, tOtherRecords[id]!.$2);
          expect(tModel.text, tOtherRecords[id]!.$3);
        }
      }

      // test first set
      await fCompare([1, 2, 3], true);

      // test clear
      await tRepository.clear();
      await tester.pumpAndSettle();

      // test after clear
      testData.pattern = TestPattern.type2;
      await fCompare([1, 2, 3], true);

      // test refresh, and after refresh compare
      testData.pattern = TestPattern.type1;
      await fCompare([4, 5, 6], true);
      testData.pattern = TestPattern.type2;
      final tCompleter = Completer();
      tRepository.refreshAll().then((value) => tCompleter.complete());
      await tester.pumpAndSettle();
      await tCompleter.future;
      await fCompare([4, 5, 6], false);
    });

    testWidgets('Other test.', (WidgetTester tester) async {
      await tester.pumpWidget(
        testApp.createMyApp(testData, TestRepositoryForOtherPurposes(testData)),
      );
      await tester.pumpAndSettle();

      final tRepository = findContext(tester).read<TestRepository>();
      final tProvider = findProvider(tester);
      TestModel? tModel;

      // notifier test for single
      tProvider.change<TestModel>([1], (data) => tModel = data, notify: true);
      await tester.pumpAndSettle();
      expect(tModel, isNotNull);
      expect(tModel!.runtimeType, TestModelWithNotifier);
      if (tModel is TestModelWithNotifier) {
        bool tCalledNotifier = false;
        final tNotifierModel = tModel as TestModelWithNotifier;
        Completer tCompleter = Completer();
        fListener() {
          tCalledNotifier = true;
          tCompleter.complete();
        }

        tNotifierModel.addListener(fListener);
        tNotifierModel.setText('from test');
        await Future.wait([tCompleter.future, tester.pumpAndSettle()]);
        expect(tCalledNotifier, true);
        expect(find.text('from test'), findsOneWidget);
        tNotifierModel.removeListener(fListener);
      }

      // notifier test for multi
      final tExpectStrings = <String>[];
      List<TestModel?>? tModels;
      tRepository.setEnv({'singleMode': false});
      tProvider.change<TestModel>(
        [4, 5, 6],
        (data) => tModels = data,
        notify: true,
      );
      await tester.pumpAndSettle();
      expect(tModels, isNotNull);
      expect(tModels!.any((e) => e is TestModelWithNotifier), isTrue);
      for (final m in tModels!) {
        bool tCalledNotifier = false;
        final tNotifierModel = m as TestModelWithNotifier;
        Completer tCompleter = Completer();
        tListener() {
          tCalledNotifier = true;
          tCompleter.complete();
        }

        tNotifierModel.addListener(tListener);
        final tExpectString = 'from test ${m.id}';
        tExpectStrings.add(tExpectString);
        tNotifierModel.setText(tExpectString);
        await Future.wait([tCompleter.future, tester.pumpAndSettle()]);
        expect(tCalledNotifier, true);
        expect(find.text(tExpectString), findsOneWidget);
        tNotifierModel.removeListener(tListener);
      }
      for (final text in tExpectStrings) {
        expect(find.text(text), findsOneWidget);
      }
      tRepository.setEnv(null);

      // test clone
      tModel = TestModel.fromRecord(1, testData.data[1]!);
      final tClonedModel = tModel!.clone();
      expect(tModel == tClonedModel, isTrue);
    });
  });
}
