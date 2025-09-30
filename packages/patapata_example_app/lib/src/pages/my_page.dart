// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/pages/home_page.dart';
import 'package:patapata_example_app/src/widgets/app_container.dart';
import 'package:provider/provider.dart';

class MyPageParent extends StandardPageWithNestedNavigator {
  @override
  void onActive(bool first) {
    super.onActive(first);

    context.read<AppContainer>().selectedFooterType = MyPageParent;
  }

  @override
  Widget buildPage(BuildContext context) {
    return nestedPages;
  }
}

class MyPage extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.my_page';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
        backgroundColor: Colors.grey[300],
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            Text(context.pl('body')),
            TextButton(
              child: Text(l(context, 'pages.tab.test_page_b.title')),
              onPressed: () {
                context.go<TestPageB, void>(null);
              },
            ),
            TextButton(
              child: Text(l(context, 'pages.tab.test_page_a.title')),
              onPressed: () {
                context.go<TestPageA, void>(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TestPageB extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_b';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
        backgroundColor: Colors.grey[300],
      ),
      body: Container(
        color: Colors.lightBlue,
        child: ListView(
          children: [
            Text(context.pl('body')),
            TextButton(
              child: Text(l(context, 'pages.tab.test_page_c.title')),
              onPressed: () {
                context.go<TestPageC, void>(null);
              },
            ),
            TextButton(
              child: Text(l(context, 'pages.tab.test_page_a.title')),
              onPressed: () {
                context.go<TestPageA, void>(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}
