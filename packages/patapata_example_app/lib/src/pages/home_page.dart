// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/pages/my_page.dart';
import 'package:patapata_example_app/src/widgets/app_container.dart';
import 'package:provider/provider.dart';

class HomePageParent extends StandardPageWithNestedNavigator {
  @override
  void onActive(bool first) {
    super.onActive(first);

    context.read<AppContainer>().selectedFooterType = HomePageParent;
  }

  @override
  Widget buildPage(BuildContext context) {
    return nestedPages;
  }
}

class HomePage extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.home';

  @override
  Widget buildPage(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView(
        children: [
          Center(
            child: Text(
              context.pl('title'),
            ),
          ),
          Text(context.pl('body')),
          TextButton(
            child: Text(l(context, 'pages.tab.test_page_a.title')),
            onPressed: () {
              context.go<TestPageA, void>(null);
            },
          ),
          TextButton(
            child: Text(l(context, 'pages.tab.test_page_b.title')),
            onPressed: () {
              context.go<TestPageB, void>(null);
            },
          ),
          TextButton(
            child: Text('Show dialog'),
            onPressed: () {
              context.read<AppContainer>().dialog(context);
            },
          ),
        ],
      ),
    );
  }
}

class TestPageA extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_a';

  @override
  Widget buildPage(BuildContext context) {
    return Container(
      color: Colors.lightBlue,
      child: ListView(
        children: [
          Center(
            child: Text(
              context.pl('title'),
            ),
          ),
          Text(context.pl('body')),
          TextButton(
            child: Text(l(context, 'pages.tab.test_page_c.title')),
            onPressed: () {
              context.go<TestPageC, void>(null);
            },
          ),
          TextButton(
            child: Text(l(context, 'pages.tab.test_page_b.title')),
            onPressed: () {
              context.go<TestPageB, void>(null);
            },
          ),
          TextButton(
            child: Text('Show dialog'),
            onPressed: () {
              context.read<AppContainer>().dialog(context);
            },
          ),
        ],
      ),
    );
  }
}

class TestPageC extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_c';

  @override
  Widget buildPage(BuildContext context) {
    return Container(
      color: Colors.lightGreen,
      child: ListView(
        children: [
          Center(
            child: Text(
              context.pl('title'),
            ),
          ),
          Text(context.pl('body')),
          TextButton(
            child: Text(l(context, 'pages.tab.test_page_d.title')),
            onPressed: () {
              context.go<TestPageD, void>(null);
            },
          ),
          TextButton(
            child: Text('Show dialog'),
            onPressed: () {
              context.read<AppContainer>().dialog(context);
            },
          ),
        ],
      ),
    );
  }
}

class TestPageD extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_d';

  @override
  Widget buildPage(BuildContext context) {
    return Container(
      color: Colors.red[300],
      child: ListView(
        children: [
          Center(
            child: Text(
              context.pl('title'),
            ),
          ),
          Text(context.pl('body')),
          TextButton(
            child: Text('Show dialog'),
            onPressed: () {
              context.read<AppContainer>().dialog(context);
            },
          ),
        ],
      ),
    );
  }
}
