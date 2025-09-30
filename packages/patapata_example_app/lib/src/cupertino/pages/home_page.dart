// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/cupertino/widgets/app_container.dart';
import 'package:patapata_example_app/src/cupertino/pages/my_page.dart';
import 'package:provider/provider.dart';

class CupertinoHomePageParent extends StandardPageWithNestedNavigator {
  @override
  void onActive(bool first) {
    super.onActive(first);

    context.read<CupertinoAppContainer>().selectedFooterType =
        CupertinoHomePageParent;
  }

  @override
  Widget buildPage(BuildContext context) {
    return nestedPages;
  }
}

class CupertinoHomePage extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.home';

  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(context.pl('title')),
        backgroundColor: CupertinoColors.systemGrey,
      ),
      child: Container(
        color: CupertinoColors.white,
        child: ListView(
          children: [
            Text(context.pl('body')),
            CupertinoButton(
              child: Text(l(context, 'pages.tab.test_page_a.title')),
              onPressed: () {
                context.go<CupertinoTestPageA, void>(null);
              },
            ),
            CupertinoButton(
              child: Text(l(context, 'pages.tab.test_page_b.title')),
              onPressed: () {
                context.go<CupertinoTestPageB, void>(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CupertinoTestPageA extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_a';

  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(context.pl('title')),
        backgroundColor: CupertinoColors.systemGrey,
      ),
      child: Container(
        color: CupertinoColors.systemBlue,
        child: ListView(
          children: [
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
                l(context, 'pages.tab.test_page_b.title'),
                style: TextStyle(
                  color: CupertinoColors.white,
                ),
              ),
              onPressed: () {
                context.go<CupertinoTestPageB, void>(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CupertinoTestPageC extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_c';

  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(context.pl('title')),
        backgroundColor: CupertinoColors.systemGrey,
      ),
      child: Container(
        color: CupertinoColors.systemGreen,
        child: ListView(
          children: [
            Text(context.pl('body')),
            CupertinoButton(
              child: Text(l(context, 'pages.tab.test_page_d.title')),
              onPressed: () {
                context.go<CupertinoTestPageD, void>(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CupertinoTestPageD extends StandardPage<void> {
  @override
  String localizationKey = 'pages.tab.test_page_d';

  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(context.pl('title')),
        backgroundColor: CupertinoColors.systemGrey,
      ),
      child: Container(
        color: CupertinoColors.systemRed,
        child: ListView(
          children: [
            Text(context.pl('body')),
          ],
        ),
      ),
    );
  }
}
