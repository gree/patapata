// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('StandardPageFactory instantiation test.', () {
    expect(
      StandardPageWithResultFactory<_TestPageA, void, int>(
        create: (data) => _TestPageA(),
      ),
      isInstanceOf<StandardPageWithResultFactory<_TestPageA, void, int>>(),
    );
  });

  test('StandardPageFactory factory getter test.', () {
    // void type check
    var tFactory = StandardPageWithResultFactory<_TestPageA, void, int>(
      create: (data) => _TestPageA(),
    );

    expect(tFactory.pageType, _TestPageA);
    expect(tFactory.dataType, isA<void>());
    expect(tFactory.dataTypeIsNonNullable, false);
    expect(tFactory.resultType, int);

    // page data type check
    tFactory = StandardPageWithResultFactory<_TestPageA, TestPageDataA, int>(
      create: (data) => _TestPageA(),
    );

    expect(tFactory.pageType, _TestPageA);
    expect(tFactory.dataType, TestPageDataA);
    expect(tFactory.dataTypeIsNonNullable, true);
    expect(tFactory.resultType, int);
  });
}

class TestPageDataA {
  final String test = 'test';
}

class _TestPageA extends StandardPageWithResult<TestPageDataA, int> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l(context, 'title test page A'),
        ),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return const Text("test page A");
              },
            ),
          ),
        ],
      ),
    );
  }
}
