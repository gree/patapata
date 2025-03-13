// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_widgets.dart';

import 'default_example.dart';
import 'object_example.dart';

class RepositoryExample1 extends StandardPage<void> {
  @override
  String get localizationKey => 'pages.repository_example1';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
      ),
      body: Center(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(context.pl('explanation')),
            ),
            const Center(
              child: Text(
                'Repository Provider',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const DefaultRepositoryWidget(),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Object Provider',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const ObjectRepositoryWidget(),
          ],
        ),
      ),
    );
  }
}
