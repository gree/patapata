// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_core_libs.dart';
import 'package:provider/provider.dart';

const int _maxObjectCacheSize = 100;

class ImmutableData with SimpleRepositoryModel<ImmutableData, int> {
  ImmutableData({
    required this.id,
  }) : _name = 'id: $id';

  final int id;

  @override
  ImmutableData repositoryDefaultFactory(int id) => ImmutableData(id: id);

  @override
  int get repositoryId => id;

  String? _name;

  @override
  void update(ImmutableData object) {
    _name = object._name;
  }
}

class ObjectRepository extends Repository<ImmutableData, int> {
  @override
  int get maxObjectCacheSize => _maxObjectCacheSize;

  late final _multiSetFetchers =
      <Type, Future<List<ImmutableData?>> Function(List<int> ids)>{
    ImmutableData: (ids) {
      return Future.value(
        List.generate(ids.length, (i) => ImmutableData(id: ids[i])),
      );
    },
  };

  late final _singleSetFetchers =
      <Type, Future<ImmutableData?> Function(int id)>{
    ImmutableData: (id) {
      return Future.value(ImmutableData(id: id));
    },
  };

  @override
  Map<Type, Future<List<ImmutableData?>> Function(List<int> ids)>
      get multiSetFetchers => _multiSetFetchers;

  @override
  Map<Type, Future<ImmutableData?> Function(int id)> get singleSetFetchers =>
      _singleSetFetchers;

  @override
  Map<Type, Duration> get scheduleThresholds => {
        ImmutableData: const Duration(milliseconds: 100),
      };
}

class ObjectProvider<S extends Object?> extends StatelessWidget {
  const ObjectProvider({
    Key? key,
    required this.ids,
    required this.builder,
    this.notify = true,
  }) : super(key: key);

  final List<int> ids;
  final bool notify;
  final RepositoryObserverBuilder<List<ImmutableData?>> builder;

  @override
  Widget build(BuildContext context) {
    return RepositoryMultiObserver<ImmutableData, int, ObjectRepository>(
      key: ValueKey(Object.hash(ids, S)),
      fetcher: (repository) => repository.fetchMany(ids, S),
      repository: context.read<ObjectRepository>(),
      notify: notify,
      builder: builder,
      //child: const SizedBox.shrink(),
    );
  }
}

class ObjectRepositoryWidget extends StatefulWidget {
  const ObjectRepositoryWidget({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => ObjectRepositoryWidgetState();
}

class ObjectRepositoryWidgetState extends State<ObjectRepositoryWidget> {
  final _recoardIds = <int>[1, 2, 3];
  final _explanation =
      'ObjectProvider is a suitable format for storing immutable data or data with infrequent changes.'
      'It is more convenient to use than RepositoryProvider because there are no constraints on the type of data to store.'
      'While it notifies changes to the child hierarchy if the data type is Listenable, for data with frequent changes,'
      'it is recommended to use RepositoryProvider from an optimization perspective.';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_explanation),
        ),
        StatefulBuilder(builder: (context, setState) {
          return SizedBox(
            height: 200.0,
            child: ObjectProvider<ImmutableData>(
              ids: _recoardIds,
              notify: false,
              builder: (context, child, data) {
                final tList = (data?.nonNulls.toList(growable: false) ?? []);

                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _InsertButton(
                      onPressed: () {
                        setState(() {
                          _recoardIds.add(_recoardIds.last + 1);
                          if (_recoardIds.length > _maxObjectCacheSize) {
                            _recoardIds.removeAt(0);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        constraints:
                            const BoxConstraints.tightFor(width: 200.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tList.length,
                          scrollDirection: Axis.vertical,
                          itemBuilder: (context, index) {
                            final tData = tList[index];

                            return Center(
                              child: Text('reacoard = ${tData._name}'),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }),
        const SizedBox(height: 32.0),
      ],
    );
  }
}

class _InsertButton extends StatelessWidget {
  const _InsertButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tColors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 28.0,
      width: 120.0,
      child: ElevatedButton(
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: tColors.onSecondaryContainer,
          backgroundColor: tColors.secondaryContainer,
          disabledBackgroundColor: tColors.onSurface.withOpacity(0.12),
          hoverColor: tColors.onSecondaryContainer.withOpacity(0.08),
          focusColor: tColors.onSecondaryContainer.withOpacity(0.12),
          highlightColor: tColors.onSecondaryContainer.withOpacity(0.12),
        ),
        onPressed: onPressed,
        child: const Text('insert recoard'),
      ),
    );
  }
}
