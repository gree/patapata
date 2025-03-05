// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
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
  @override
  String get localizationKey => 'pages.repository_example2';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(context.pl('explanation1')),
          ),
          const Center(
            child: DataStructure(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(context.pl('explanation2')),
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
            child: Text(context.pl('explanation3')),
          ),
        ],
      ),
    );
  }
}
