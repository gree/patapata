// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/widgets/app_tab.dart';

/// [MyPage] is the parent StandardPage for applications with a tabbed footer.
/// This MyPage has one child StandardPage named [MyFavoritePage].
class MyPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    // When creating an application with features like a footer, please return childNavigator in the buildPage method.
    return childNavigator ?? const SizedBox.shrink();
  }
}

/// [MyPage] is a StandardPage representing the [MyFavoritePage] tab in an application with a tabbed footer.
class MyFavoritePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return AppTab(
      appBar: AppBar(
        title: Text(l(context, 'pages.tab.my_page.title')),
        automaticallyImplyLeading: false,
        leading: const StandardPageBackButton(),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return Text(
                  l(context, 'pages.tab.my_page.body'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
