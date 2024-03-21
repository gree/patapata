// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/widgets/app_tab.dart';

/// [HomePage] is the parent StandardPage for applications with a tabbed footer.
/// This HomePage has two child StandardPages, namely [TitlePage] and [TitleDetailsPage].
class HomePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    // When creating an application with features like a footer, please return childNavigator in the buildPage method.
    return childNavigator ?? const SizedBox.shrink();
  }
}

/// [TitlePage] is a StandardPage representing the [HomePage] tab in an application with a tabbed footer.
class TitlePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return AppTab(
      appBar: AppBar(
        title: Text(l(context, 'pages.tab.home.title')),
        automaticallyImplyLeading: false,
        leading: const StandardPageBackButton(),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return Text(l(context, 'pages.tab.home.body'));
              },
            ),
          ),
          TextButton(
            child: Text(l(context, 'pages.tab.title_details.title')),
            onPressed: () {
              context.go<TitleDetailsPage, void>(null);
            },
          ),
        ],
      ),
    );
  }
}

/// [TitleDetailsPage] is a StandardPage that serves as a child of [TitlePage] in the [HomePage] tab of an application with a tabbed footer.
class TitleDetailsPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return AppTab(
      appBar: AppBar(
        title: Text(l(context, 'pages.tab.title_details.title')),
        automaticallyImplyLeading: false,
        leading: const StandardPageBackButton(),
      ),
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return Text(
                  l(context, 'pages.tab.title_details.body'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
