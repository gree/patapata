// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:provider/provider.dart';

import './model/test_model1.dart';
import 'test_data.dart';

class FetchException implements Exception {}

class TestApp {
  TestRepository? _repository;

  TestRepository<T>? asRepository<T extends RepositoryModel<T, int>>() {
    if (_repository == null) {
      return null;
    }

    return _repository as TestRepository<T>;
  }

  Widget createMyApp<T extends RepositoryModel<T, int>>(
    TestData testData,
    TestRepository<T> repository,
    bool isRepositoryInTree,
  ) {
    if (isRepositoryInTree) {
      return MaterialApp(
        home: Provider<TestRepository<T>>(
          create: (context) => repository,
          child: TestProvider<T>(repository: null),
        ),
      );
    }

    _repository = repository;
    return MaterialApp(home: TestProvider<T>(repository: repository));
  }
}

abstract class TestRepository<T extends RepositoryModel<T, int>>
    extends Repository<T, int> {
  TestRepository(this.testData);
  final TestData testData;

  void setEnv(dynamic env) {}
}

class TestSingleDataRepository extends TestRepository<TestModel> {
  TestSingleDataRepository(super.testData);

  @override
  Map<Type, Future<TestModel?> Function(int id)> get singleSetFetchers =>
      <Type, Future<TestModel?> Function(int id)>{
        TestModel: (id) {
          final tData = testData.data[id];
          return Future.value(
            TestModel.init(id, v1: tData?.$1, v2: tData?.$2, v3: tData?.$3),
          );
        },
        Filter1: (id) {
          final tData = testData.data[id];
          return Future.value(TestModel.init(id, v2: tData?.$2, v3: tData?.$3));
        },
        Filter2: (id) {
          final tData = testData.data[id];
          return Future.value(TestModel.init(id, v3: tData?.$3));
        },
        Filter3: (id) {
          return Future.error(FetchException());
        },
      };

  @override
  Map<Type, Future<List<TestModel?>> Function(List<int> ids)>
  get multiSetFetchers => {};
}

class TestMultiDataRepository extends TestRepository<TestModel> {
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
        Filter2: (ids) {
          return Future.value(
            List.generate(ids.length, (i) {
              final tId = ids[i];
              final tData = testData.data[tId];
              return TestModel.init(tId, v3: tData?.$3);
            }),
          );
        },
      };
}

class TestOverflowCacheSizeRepository extends TestMultiDataRepository {
  TestOverflowCacheSizeRepository(super.testData);

  @override
  int get maxObjectCacheSize => 5;
}

class TestHasNotProviderBuilderRepository
    extends TestRepository<HasNotBuilderModel> {
  TestHasNotProviderBuilderRepository(super.testData);

  @override
  Map<Type, Future<List<HasNotBuilderModel?>> Function(List<int> ids)>
  get multiSetFetchers => {};

  @override
  Map<Type, Future<HasNotBuilderModel?> Function(int id)>
  get singleSetFetchers => <Type, Future<HasNotBuilderModel?> Function(int id)>{
    HasNotBuilderModel: (id) {
      return Future.value(HasNotBuilderModel.init(id, id));
    },
  };
}

class TestRepositoryForOtherPurposes extends TestRepository<TestModel> {
  TestRepositoryForOtherPurposes(super.testData);

  Duration? cacheDuration;
  bool invalidValueModel = false;
  List<int> testMissingValues = [];

  @override
  void setEnv(dynamic env) {
    if (env == null) {
      cacheDuration = null;
      invalidValueModel = false;
      testMissingValues = [];
      return;
    }

    final tEnv = env as Map<String, dynamic>;

    if (tEnv.containsKey('cacheDuration')) {
      cacheDuration = tEnv['cacheDuration'] as Duration;
    }

    if (tEnv.containsKey('invalidValueModel')) {
      invalidValueModel = tEnv['invalidValueModel'] as bool;
    }

    if (tEnv.containsKey('testMissingValues')) {
      testMissingValues = tEnv['testMissingValues'] as List<int>;
    }
  }

  @override
  Map<Type, Duration> get scheduleThresholds => {
    Filter1: const Duration(seconds: 1),
    Filter2: const Duration(seconds: 1),
  };

  @override
  Map<Type, Future<TestModel?> Function(int id)> get singleSetFetchers =>
      <Type, Future<TestModel?> Function(int id)>{
        TestModel: (id) {
          if (invalidValueModel) {
            final tData = testData.data[id];
            return Future.value(
              TestModel.init(
                id,
                v2: tData?.$2,
                v3: tData?.$3,
                cacheDuration: cacheDuration,
              ),
            );
          }

          return Future.value(null);
        },
        Filter1: (id) {
          final tData = testData.data[id];
          return Future.delayed(const Duration(milliseconds: 200), () {
            return Future.value(
              TestModel.init(
                id,
                v2: tData?.$2,
                v3: tData?.$3,
                cacheDuration: cacheDuration,
              ),
            );
          });
        },
        Filter3: (id) {
          return Future.error(FetchException());
        },
      };

  @override
  Map<Type, Future<List<TestModel?>> Function(List<int> ids)>
  get multiSetFetchers =>
      <Type, Future<List<TestModel?>> Function(List<int> ids)>{
        Filter2: (ids) {
          if (testMissingValues.isNotEmpty) {
            ids = ids.where((e) => !testMissingValues.contains(e)).toList();
          }

          return Future.delayed(const Duration(milliseconds: 200), () {
            return Future.value(
              List.generate(ids.length, (i) {
                final tId = ids[i];
                final tData = testData.data[tId];
                return TestModel.init(tId, v3: tData?.$3);
              }),
            );
          });
        },
      };
}

class Anchor extends StatelessWidget {
  const Anchor({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class TestProvider<T extends RepositoryModel<T, int>> extends StatefulWidget {
  const TestProvider({super.key, required this.repository});

  final TestRepository<T>? repository;

  @override
  TestProviderState<T> createState() => TestProviderState<T>();
}

class TestProviderState<T extends RepositoryModel<T, int>>
    extends State<TestProvider<T>> {
  WidgetBuilder? generator;

  void change<S extends Object>(List<int> ids) {
    setState(() {
      generator = (BuildContext context) {
        if (ids.length != 1) {
          return RepositoryMultiProvider<T, int, TestRepository<T>, S>(
            key: ValueKey(Object.hash(ids, S)),
            fetcher: (repository) => repository.fetchMany(ids, S),
            repository: widget.repository ?? context.read<TestRepository<T>>(),
            errorBuilder: (context, error, _) {
              return Text(error.toString());
            },
            builder: (_) => const Anchor(),
          );
        }

        return RepositoryProvider<T, int, TestRepository<T>>(
          key: ValueKey(Object.hash(ids.single, S)),
          id: ids.single,
          fetcher: (repository) => repository.fetch(ids.single, S),
          repository: widget.repository ?? context.read<TestRepository<T>>(),
          errorBuilder: (context, error, _) {
            return Text(error.toString());
          },
          builder: (_) => const Anchor(),
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

TestProviderState findProvider<T extends RepositoryModel<T, int>>(
  WidgetTester tester,
) {
  return tester.state<TestProviderState>(find.byType(TestProvider<T>));
}

void execute(Object m, TestValue tv, TestRecord tr, bool checkAssertion) {
  final tModel = m as TestModel;

  final f = switch (tv) {
    TestValue.v1 => (() => tModel.value1, tr.$1),
    TestValue.v2 => (() => tModel.value2, tr.$2),
    TestValue.v3 => (() => tModel.text, tr.$3),
  };

  checkAssertion ? expect(f.$1, throwsAssertionError) : expect(f.$1(), f.$2);
}

WidgetTesterCallback monitoringTimers(WidgetTesterCallback body) {
  return (WidgetTester tester) async {
    final tTimers = Queue<Timer>();
    return runZoned<Future>(
      () => body(tester),
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, f) {
          final tTimer = parent.createTimer(zone, duration, f);
          tTimers.addLast(tTimer);
          return tTimer;
        },
      ),
    ).whenComplete(() {
      while (tTimers.isNotEmpty) {
        tTimers.removeFirst().cancel();
      }
    });
  };
}

void main() {
  late TestApp testApp;
  late TestData testData;

  final tTestInTreeRepository = [true, false];

  setUp(() {
    testData = TestData();
    testApp = TestApp();
  });

  group('Test default repository', () {
    for (final flag in tTestInTreeRepository) {
      testWidgets(
        'Test single set and fetch. repository in tree = $flag',
        monitoringTimers((WidgetTester tester) async {
          await tester.pumpWidget(
            testApp.createMyApp(
              testData,
              TestSingleDataRepository(testData),
              flag,
            ),
          );
          await tester.pumpAndSettle();

          final tRepository =
              testApp.asRepository<TestModel>() ??
              findContext(tester).read<TestRepository<TestModel>>();
          final tProvider = findProvider<TestModel>(tester);
          TestModel? tModel;

          fCompare(int id, bool checkAssertion) async {
            final tData = testData.data[id]!;

            tProvider.change<Filter2>([id]);
            await tester.pumpAndSettle();
            final tFilter2 = findContext(tester).read<Filter2>();
            execute(tFilter2, TestValue.v1, tData, checkAssertion);
            execute(tFilter2, TestValue.v2, tData, checkAssertion);
            execute(tFilter2, TestValue.v3, tData, false);

            tProvider.change<Filter1>([id]);
            await tester.pumpAndSettle();
            final tFilter1 = findContext(tester).read<Filter1>();
            execute(tFilter1, TestValue.v1, tData, checkAssertion);
            execute(tFilter1, TestValue.v2, tData, false);
            execute(tFilter1, TestValue.v3, tData, false);

            tProvider.change<TestModel>([id]);
            await tester.pumpAndSettle();
            final tModel = findContext(tester).read<TestModel>();
            execute(tModel, TestValue.v1, tData, false);
            execute(tModel, TestValue.v2, tData, false);
            execute(tModel, TestValue.v3, tData, false);
          }

          // test first set
          await fCompare(1, true);

          // test update cache
          testData.pattern = TestPattern.type2;
          final tData = testData.data[1]!;
          tModel = await tRepository.fetch(
            1,
            TestModel,
            fetchPolicy: RepositoryFetchPolicy.noCache,
          );
          await tester.pumpAndSettle();
          expect(tModel, isNotNull);
          execute(tModel!, TestValue.v1, tData, false);
          execute(tModel, TestValue.v2, tData, false);
          execute(tModel, TestValue.v3, tData, false);

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
        }),
      );

      testWidgets(
        'Test multi set and fetch. repository in tree = $flag',
        monitoringTimers((WidgetTester tester) async {
          await tester.pumpWidget(
            testApp.createMyApp(
              testData,
              TestMultiDataRepository(testData),
              flag,
            ),
          );
          await tester.pumpAndSettle();

          final tRepository =
              testApp.asRepository<TestModel>() ??
              findContext(tester).read<TestRepository<TestModel>>();
          final tProvider = findProvider<TestModel>(tester);
          List<TestModel?>? tModelList;

          fCompare(List<int> ids, bool checkAssertion) async {
            tProvider.change<Filter2>(ids);
            await tester.pumpAndSettle();
            final tFilter2List = findContext(tester).read<List<Filter2>>();
            for (final id in ids) {
              final tData = testData.data[id]!;
              final tFilter2 = tFilter2List.firstWhere((e) => e.id == id);
              execute(tFilter2, TestValue.v1, tData, checkAssertion);
              execute(tFilter2, TestValue.v2, tData, checkAssertion);
              execute(tFilter2, TestValue.v3, tData, false);
            }

            tProvider.change<Filter1>(ids);
            await tester.pumpAndSettle();
            final tFilter1List = findContext(tester).read<List<Filter1>>();
            for (final id in ids) {
              final tData = testData.data[id]!;
              final tFilter1 = tFilter1List.firstWhere((e) => e.id == id);
              execute(tFilter1, TestValue.v1, tData, checkAssertion);
              execute(tFilter1, TestValue.v2, tData, false);
              execute(tFilter1, TestValue.v3, tData, false);
            }

            tProvider.change<TestModel>(ids);
            await tester.pumpAndSettle();
            final tModelList = findContext(tester).read<List<TestModel>>();
            for (final id in ids) {
              final tData = testData.data[id]!;
              final tModel = tModelList.firstWhere((e) => e.id == id);
              execute(tModel, TestValue.v1, tData, false);
              execute(tModel, TestValue.v2, tData, false);
              execute(tModel, TestValue.v3, tData, false);
            }
          }

          // test first set
          await fCompare([1, 2, 3], true);

          // test update cache
          testData.pattern = TestPattern.type2;
          tRepository
              .fetchMany(
                [1, 2, 3],
                TestModel,
                fetchPolicy: RepositoryFetchPolicy.noCache,
              )
              .then((data) => tModelList = data);
          await tester.pumpAndSettle();
          expect(tModelList, isNotNull);
          for (final id in [1, 2, 3]) {
            final tData = testData.data[id]!;
            final tModel = tModelList!.firstWhere((e) => e?.id == id);
            expect(tModel, isNotNull);
            execute(tModel!, TestValue.v1, tData, false);
            execute(tModel, TestValue.v2, tData, false);
            execute(tModel, TestValue.v3, tData, false);
          }

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
        }),
      );

      testWidgets(
        'Test single set and store. repository in tree = $flag',
        monitoringTimers((WidgetTester tester) async {
          await tester.pumpWidget(
            testApp.createMyApp(
              testData,
              TestSingleDataRepository(testData),
              flag,
            ),
          );
          await tester.pumpAndSettle();

          final tRepository =
              testApp.asRepository<TestModel>() ??
              findContext(tester).read<TestRepository<TestModel>>();
          final tProvider = findProvider<TestModel>(tester);

          fCompare(int id) async {
            final tData = testData.data[id]!;

            // Is the data entered correct?
            tRepository.store(TestModel.fromRecord(id, tData));
            final tCache = tRepository.get(id);
            expect(tCache, isNotNull);
            if (tCache != null) {
              execute(tCache, TestValue.v1, tData, false);
              execute(tCache, TestValue.v2, tData, false);
              execute(tCache, TestValue.v3, tData, false);
            }

            // In store after fetch, is the value overwritten or not?
            const tOtherRecord = (42, 0.42, 'test store');
            tProvider.change<TestModel>([id]);
            await tester.pumpAndSettle();
            tRepository.store(TestModel.fromRecord(id, tOtherRecord));
            final tModel = findContext(tester).read<TestModel>();
            expect(tModel.value1, tOtherRecord.$1);
            expect(tModel.value2, tOtherRecord.$2);
            expect(tModel.text, tOtherRecord.$3);
          }

          // test first set
          await fCompare(1);

          // test clear
          tRepository.clear();
          await tester.pumpAndSettle();

          // test after clear
          testData.pattern = TestPattern.type2;
          await fCompare(1);
        }),
      );

      testWidgets(
        'Test multi set and store. repository in tree = $flag',
        monitoringTimers((WidgetTester tester) async {
          await tester.pumpWidget(
            testApp.createMyApp(
              testData,
              TestMultiDataRepository(testData),
              flag,
            ),
          );
          await tester.pumpAndSettle();

          final tRepository =
              testApp.asRepository<TestModel>() ??
              findContext(tester).read<TestRepository<TestModel>>();
          final tProvider = findProvider<TestModel>(tester);

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
                execute(tCache, TestValue.v1, tData, false);
                execute(tCache, TestValue.v2, tData, false);
                execute(tCache, TestValue.v3, tData, false);
              }
            }

            // In store after fetch, is the value overwritten or not?
            final tOtherRecords = Map.fromIterables(
              ids,
              ids.map((e) => (42 + e, 0.42 + e, 'id / $e test store')).toList(),
            );
            tProvider.change<TestModel>(ids);
            await tester.pumpAndSettle();
            await tRepository.storeMany(
              ids.map((e) => TestModel.fromRecord(e, tOtherRecords[e]!)),
            );

            final tModelList = findContext(tester).read<List<TestModel>>();
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
        }),
      );
    }

    testWidgets(
      'Test overflow cache size in repository.',
      monitoringTimers((WidgetTester tester) async {
        await tester.pumpWidget(
          testApp.createMyApp(
            testData,
            TestOverflowCacheSizeRepository(testData),
            true,
          ),
        );
        await tester.pumpAndSettle();

        final tRepository = findContext(
          tester,
        ).read<TestRepository<TestModel>>();
        final tIds = [1, 2, 3, 4, 5, 6];

        // test fetchMany
        await expectLater(
          () => tRepository.fetchMany(tIds, TestModel),
          throwsAssertionError,
        );

        await tRepository.clear();
        await tester.pumpAndSettle();

        // test storeMany
        await expectLater(
          () => tRepository.storeMany(
            tIds.map((e) => TestModel.fromRecord(e, testData.data[e]!)),
          ),
          throwsAssertionError,
        );
      }),
    );

    testWidgets(
      'Other test.',
      monitoringTimers((WidgetTester tester) async {
        await tester.pumpWidget(
          testApp.createMyApp(
            testData,
            TestRepositoryForOtherPurposes(testData),
            true,
          ),
        );
        await tester.pumpAndSettle();

        final tRepository = findContext(
          tester,
        ).read<TestRepository<TestModel>>();
        final tProvider = findProvider<TestModel>(tester);
        TestModel? tModel;
        Object? tError;

        // Mistake in initializing the contents of parameter set
        tRepository.setEnv({'invalidValueModel': true});
        tModel = await tRepository.fetch(1, TestModel);
        expect(tModel, isNull);
        tRepository.setEnv(null);

        // Test for when the fetched result is null
        tProvider.change<TestModel>([1]);
        await tester.pumpAndSettle();
        tModel = tRepository.get(1);
        expect(tModel, isNull);
        expect(
          find.text(
            ProviderNullException(null.runtimeType, TestModel).toString(),
          ),
          findsOneWidget,
        );

        // Error test during fetch
        tError = null;
        await runZonedGuarded(
          () async {
            tProvider.change<Filter3>([1]);
            await tester.pumpAndSettle();
          },
          (error, stack) {
            if (error is FetchException) {
              tError = error;
              return;
            }

            throw error;
          },
        );
        expect(tError, isNotNull);
        expect(find.text(tError!.toString()), findsOneWidget);

        // Checking if the cache expiration time is applied correctly
        await tester.runAsync(() async {
          bool tNotified = false;
          tRepository.setEnv({'cacheDuration': const Duration(seconds: 1)});

          testData.pattern = TestPattern.type1;
          tModel = await tRepository.fetch(1, Filter1);
          tModel?.addListener(() => tNotified = true);

          testData.pattern = TestPattern.type2;
          await Future.delayed(const Duration(seconds: 2));
          await tester.pumpAndSettle();

          expect(tNotified, isTrue);
          tModel = tRepository.get(1);
          expect(tModel!.text, testData.data[1]!.$3);
          tRepository.setEnv(null);
        });

        await tRepository.clear();
        await tester.pumpAndSettle();

        // Checking if batching of fetches is being performed
        // multiSetFetchers version
        testData.pattern = TestPattern.type1;
        await tester.runAsync(() async {
          final tFutures = <Future>[];
          tFutures.add(tRepository.fetch(1, Filter2));
          tFutures.add(tRepository.fetch(2, Filter2));
          tFutures.add(tRepository.fetchMany([1, 3, 4], Filter2));
          tFutures.add(tRepository.fetchMany([2, 5, 6], Filter2));

          final tFetchMap = tRepository.objectFetchMap;
          expect(tFetchMap.length == 6, isTrue);
          expect(tFetchMap.keys.every((e) => e.set == Filter2), isTrue);
          final tFetchIds = <int>[];
          for (var e in tFetchMap.entries) {
            tFetchIds.add(e.key.id);
          }
          tFetchIds.sort();
          expect(listEquals(tFetchIds, [1, 2, 3, 4, 5, 6]), isTrue);

          await Future.wait(tFutures);
          final tDataList = tRepository.getMany([1, 2, 3, 4, 5, 6]);
          expect(tDataList.length, 6);
          for (final data in tDataList) {
            expect(data, isNotNull);
            expect(data.text, testData.data[data.id]!.$3);
          }
        });

        // Checking if batching of fetches is implemented
        // singleSetFetchers version
        testData.pattern = TestPattern.type1;
        await tester.runAsync(() async {
          final tFutures = <Future>[];
          tFutures.add(tRepository.fetch(1, Filter1));
          tFutures.add(tRepository.fetch(2, Filter1));
          tFutures.add(tRepository.fetch(1, Filter1));
          tFutures.add(tRepository.fetch(2, Filter1));

          expect(tFutures[0] == tFutures[2], isTrue);
          expect(tFutures[1] == tFutures[3], isTrue);

          await Future.wait(tFutures);
          final tDataList = tRepository.getMany([1, 2]);
          expect(tDataList.length, 2);
          for (final data in tDataList) {
            expect(data, isNotNull);
            expect(data.text, testData.data[data.id]!.$3);
          }
        });

        await tRepository.clear();
        await tester.pumpAndSettle();

        // Test for differences in expected results after batching fetches
        tRepository.setEnv({
          'testMissingValues': [2, 4, 6],
        });
        await tester.runAsync(() async {
          final tFutures = <Future>[];
          tFutures.add(tRepository.fetchMany([1, 2, 3], Filter2));
          tFutures.add(tRepository.fetchMany([4, 5, 6], Filter2));
          await Future.wait(tFutures);
          final tDataList = tRepository.getMany([1, 2, 3, 4, 5, 6]);
          expect(tDataList.length, 3);
          for (final data in tDataList) {
            expect(data, isNotNull);
            expect(data.text, testData.data[data.id]!.$3);
          }
        });
        tRepository.setEnv(null);

        // Test for errors occurring due to a lock while updating the cache
        tError = null;
        await tester.runAsync(() async {
          final tOrigin = await tRepository.fetch(1, Filter1);
          tOrigin?.errorOnCacheDuration = true;
          try {
            await tRepository.fetch(
              1,
              Filter1,
              fetchPolicy: RepositoryFetchPolicy.noCache,
            );
          } catch (e) {
            if (e is CacheDurationException) {
              tError = e;
              return;
            }

            rethrow;
          }
        });
        expect(tError, isNotNull);

        // test clone
        tModel = TestModel.fromRecord(1, testData.data[1]!);
        final tClonedModel = tModel!.clone();
        expect(tModel == tClonedModel, isTrue);
        expect(tModel!.deepModel.value == tClonedModel.deepModel.value, isTrue);

        // Checking if the hash code is set correctly
        Set<TestModel> tSet = {tModel!, tClonedModel};
        expect(tSet.length, 1);
      }),
    );

    testWidgets(
      'Test without inserting Provider into the Widget Tree',
      monitoringTimers((WidgetTester tester) async {
        await tester.pumpWidget(
          testApp.createMyApp(
            testData,
            TestHasNotProviderBuilderRepository(testData),
            true,
          ),
        );
        await tester.pumpAndSettle();

        final tProvider = findProvider<HasNotBuilderModel>(tester);

        tProvider.change<HasNotBuilderModel>([1]);
        await tester.pumpAndSettle();
        bool tErrorCalled = false;
        try {
          findContext(tester).read<HasNotBuilderModel>();
        } catch (e) {
          if (e is ProviderNotFoundException) {
            tErrorCalled = true;
            return;
          }

          rethrow;
        }
        expect(tErrorCalled, isTrue);
      }),
    );
  });
}
