// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:patapata_example_app/src/cupertino/widgets/app_tab.dart';

/// This sample transforms the HomePage, designed with Material's design, into Cupertino's design.
/// The structure remains the same as HomePage.
class CupertinoHomePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    // When creating an application with features like a footer, please return childNavigator in the buildPage method.
    return childNavigator ?? const SizedBox.shrink();
  }
}

/// This sample transforms the TitlePage, designed with Material's design, into Cupertino's design.
/// The basic structure remains the same as TitlePage, but it uses an AppBar tailored for Cupertino.
class CupertinoTitlePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return CupertinoAppBar(
      body: ListView(
        children: [
          Center(
            child: Builder(
              builder: (context) {
                return Text(
                  l(context, 'pages.tab.home.body'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
