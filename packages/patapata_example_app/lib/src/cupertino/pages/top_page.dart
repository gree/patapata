// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

import 'home_page.dart';

/// Cupertino version of the TopPage.
class CupertinoTopPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l(context, 'pages.top.title')),
      ),
      child: ListView(
        children: [
          Text(l(context, 'pages.top.body')),
          CupertinoButton(
            onPressed: () {
              context.go<CupertinoHomePage, void>(null);
            },
            child: Text(l(context, 'pages.top.go_to_tab')),
          ),
        ],
      ),
    );
  }
}
