// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';

import './model.dart';
import 'example_parts.dart';
import 'repository_example2.dart';

class DataRepository extends Repository<Data, int> {
  @override
  int get maxObjectCacheSize => 100;

  late final _multiSetFetchers =
      <Type, Future<List<Data?>> Function(List<int> ids)>{
    Data: (ids) {
      return Future.value(List.generate(ids.length, (i) => Data.init(ids[i])));
    },
    DataListSet: (ids) {
      return Future.value(List.generate(ids.length, (i) => Data.init(ids[i])));
    },
  };

  late final _singleSetFetchers = <Type, Future<Data?> Function(int id)>{
    Data: (id) {
      return Future.value(Data.init(id));
    },
    DataListSet: (id) {
      return Future.value(Data.init(id));
    },
  };

  @override
  Map<Type, Future<List<Data?>> Function(List<int> ids)> get multiSetFetchers =>
      _multiSetFetchers;

  @override
  Map<Type, Future<Data?> Function(int id)> get singleSetFetchers =>
      _singleSetFetchers;

  @override
  Map<Type, Duration> get scheduleThresholds => {};
}

class DataProvider<S extends Object> extends StatelessWidget {
  const DataProvider({
    super.key,
    required this.ids,
    required this.builder,
  });

  final List<int> ids;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    assert(ids.isNotEmpty);

    if (ids.length != 1) {
      return RepositoryMultiProvider<Data, int, DataRepository, S>(
        key: ValueKey(Object.hash(ids, S)),
        fetcher: (repository) => repository.fetchMany(ids, S),
        repository: context.read<DataRepository>(),
        builder: builder,
      );
    }

    return RepositoryProvider<Data, int, DataRepository>(
      key: ValueKey(Object.hash(ids, S)),
      id: ids.first,
      fetcher: (repository) => repository.fetch(ids.single, S),
      repository: context.read<DataRepository>(),
      builder: builder,
    );
  }
}

class DefaultRepositoryWidget extends StatelessWidget {
  const DefaultRepositoryWidget({
    super.key,
  });

  final ids = const <int>[1, 2, 3];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(context.pl('default_example.explanation1')),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(context.pl('default_example.explanation2')),
        ),
        const DataStructure(),
        for (final id in ids)
          _DataRecord(
            id: id,
          ),
      ],
    );
  }
}

class _DataRecord extends StatelessWidget {
  const _DataRecord({
    required this.id,
  });

  final int id;

  @override
  Widget build(BuildContext context) {
    return DataProvider<DataListSet>(
      ids: [id],
      builder: (context) {
        final tListData = context.watch<DataListSet>();
        final tColorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 32.0,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: tColorScheme.primary,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 32.0,
                        child: Center(
                          child: Text(tListData.name),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ResetButton(
                        onPressed: () {
                          final tNewData = Data.init(id);
                          context.read<DataRepository>().store(tNewData);
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                        'translationDate / ${tListData.translationConfition}'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('counter 1 = ${tListData.counter1}'),
                      const SizedBox(width: 8.0),
                      AddButton(
                        onPressed: () {
                          tListData.addCounter1();
                        },
                      ),
                      const SizedBox(width: 16.0),
                      const Text('counter 2 = ???'),
                      const SizedBox(width: 8.0),
                      TransferButton(
                        onPressed: () async {
                          await context
                              .read<DataRepository>()
                              .store(Data.fromDateTime(id, DateTime.now()));

                          if (!context.mounted) {
                            return;
                          }

                          context.go<RepositoryExample2,
                                  RepositoryExsamplePageData>(
                              RepositoryExsamplePageData(id: id));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
