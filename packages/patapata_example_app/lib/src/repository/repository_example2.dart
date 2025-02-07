// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';

import 'default_example.dart';
import 'example_parts.dart';
import 'model.dart';

class RepositoryExsamplePageData {
  const RepositoryExsamplePageData({
    required this.id,
  });

  final int id;
}

class RepositoryExample2 extends StandardPage<RepositoryExsamplePageData> {
  final _explanation1 =
      'On this screen, DataListSet is used. The original class is also treated as a set that allows access to all variables.';

  final _explanation2 =
      'On the previous screen, access to counter2 and translationDate was prohibited in the set.'
      'Additionally, translationDate was not initialized.'
      'When transitioning to this screen, translationDate was updated, making it accessible.';

  final _explanation3 =
      'Pressing the reset button will reset the data, but you may notice that translationDate is not reset.'
      'This is because when updating the data through the repository, translationDate was passed without initialization.'
      'Conversely, when transitioning to this screen, only translationDate was initialized.'
      'In this way, when updating data on the repository, it is possible to merge data on the cache with information by not initializing parts in the model.'
      'Of course, it is also possible to update variables directly as usual.';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'Repository Example')),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_explanation1),
          ),
          const Center(
            child: DataStructure(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_explanation2),
          ),
          DataProvider<Data>(
            ids: [pageData.id],
            builder: (context) {
              final tColorScheme = Theme.of(context).colorScheme;
              final tData = context.watch<Data>();

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
                                child: Text(tData.name),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            ResetButton(
                              onPressed: () {
                                final tNewData = Data.init(pageData.id);
                                context.read<DataRepository>().store(tNewData);
                              },
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                              'translationDate = ${tData.translationDate}'),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('counter 1 = ${tData.counter1}'),
                            const SizedBox(width: 8.0),
                            AddButton(
                              onPressed: () {
                                tData.addCounter1();
                              },
                            ),
                            const SizedBox(width: 16.0),
                            Text('counter 2 = ${tData.counter2}'),
                            const SizedBox(width: 8.0),
                            AddButton(
                              onPressed: () {
                                tData.addCounter2();
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
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_explanation3),
          ),
        ],
      ),
    );
  }
}
