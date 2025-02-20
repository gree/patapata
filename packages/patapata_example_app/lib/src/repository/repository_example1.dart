// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

import 'default_example.dart';
import 'object_example.dart';

class RepositoryExample1 extends StandardPage<void> {
  final _repositoryExplanation = '''
A Repository is a feature designed to accumulate data, as the name suggests. It provides essential functionalities for handling information in the app, such as adding, updating, retrieving, and synchronizing with Web APIs. It also allows setting cache time for information, imposing limits on accumulation, and clearing old information with LRU, among other capabilities. Once configured, you can interact with information from anywhere in the app through the BuildContext.

It provides the following features:

1. Information Encapsulation
   For example, consider a social networking service (SNS). On the list screen, you may only need "title" and "date." However, on the detailed screen, heavy information such as "body" is required. To optimize, Web APIs are likely prepared separately for each. When dealing with them in the app, most cases involve handling them on the same data class and initializing unretrieved information with empty strings or null. However, since the data exists, there is a risk of accessing "body" on the list screen. To prevent this, the concept of "sets" is provided. Although it's the same data class, by accessing information through "sets," you can block unnecessary information. By blocking access at the code level, it's possible to prevent programmer confusion. In the example, by preparing a "set" for the list screen, you can prevent access to "body" on the list screen. The mechanism of "sets" is complex, but a builder for "sets" is provided, making it easy to create. For preparation for building and detailed usage, please refer to the Example.

2. Information Update and Optimization of Widget Rebuilds
   Continuing with the SNS example, if you press the "like button," the overall number of likes is updated, and the widget is rebuilt. If nothing is done, all widgets associated with the data class will be rebuilt. To prevent this, widgets are built on a "set" basis. Regarding this, using the "sets" from 1 enables automatic optimization.
''';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'Repository Example')),
      ),
      body: Center(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_repositoryExplanation),
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
