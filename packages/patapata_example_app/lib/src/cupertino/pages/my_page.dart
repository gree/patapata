// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/cupertino/widgets/app_container.dart';
import 'package:patapata_example_app/src/cupertino/pages/home_page.dart';
import 'package:provider/provider.dart';

class CupertinoMyPageParent extends StandardPageWithNestedNavigator {
  @override
  void onActive(bool first) {
    super.onActive(first);

    context.read<CupertinoAppContainer>().selectedFooterType =
        CupertinoMyPageParent;
  }

  @override
  Widget buildPage(BuildContext context) {
    return nestedPages;
  }
}

class CupertinoMyPage extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.my_page';

  @override
  Widget buildPage(BuildContext context) {
    return Container(
      color: CupertinoColors.white,
      child: ListView(
        children: [
          Center(
            child: Text(
              context.pl('title'),
            ),
          ),
          Text(context.pl('body')),
          CupertinoButton(
            child: Text(l(context, 'pages.tab.test_page_b.title')),
            onPressed: () {
              context.go<CupertinoTestPageB, void>(null);
            },
          ),
          CupertinoButton(
            child: Text(l(context, 'pages.tab.test_page_a.title')),
            onPressed: () {
              context.go<CupertinoTestPageA, void>(null);
            },
          ),
          CupertinoButton(
            child: Text('Show dialog'),
            onPressed: () {
              context.read<CupertinoAppContainer>().dialog(context);
            },
          ),
        ],
      ),
    );
  }
}

class CupertinoTestPageB extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_b';

  @override
  Widget buildPage(BuildContext context) {
    return Container(
      color: CupertinoColors.systemBlue,
      child: ListView(
        children: [
          Center(
            child: Text(
              context.pl('title'),
            ),
          ),
          Text(context.pl('body')),
          CupertinoButton(
            child: Text(
              l(context, 'pages.tab.test_page_c.title'),
              style: TextStyle(
                color: CupertinoColors.white,
              ),
            ),
            onPressed: () {
              context.go<CupertinoTestPageC, void>(null);
            },
          ),
          CupertinoButton(
            child: Text(
              l(context, 'pages.tab.test_page_a.title'),
              style: TextStyle(
                color: CupertinoColors.white,
              ),
            ),
            onPressed: () {
              context.go<CupertinoTestPageA, void>(null);
            },
          ),
          CupertinoButton(
            child: Text(
              'Show dialog',
              style: TextStyle(
                color: CupertinoColors.white,
              ),
            ),
            onPressed: () {
              context.read<CupertinoAppContainer>().dialog(context);
            },
          ),
        ],
      ),
    );
  }
}
