// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

import '../pages/home_page.dart';
import '../pages/my_page.dart';

/// A sample StandardApp for Material with a widget displayed in a tab.
class AppTab extends StatelessWidget {
  const AppTab({
    Key? key,
    required this.body,
    this.appBar,
  }) : super(key: key);

  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    var tInterfacePage =
        ModalRoute.of(context)!.settings as StandardPageInterface;
    var tType = tInterfacePage.factoryObject.parentPageType;
    int tIndex = 0;
    if (tType == HomePage) {
      tIndex = 0;
    } else if (tType == MyPage) {
      tIndex = 1;
    }

    return Scaffold(
      body: body,
      appBar: appBar,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          switch (index) {
            case 0:
              context.go<HomePage, void>(null);
              break;
            case 1:
              context.go<MyPage, void>(null);
              break;
            default:
              break;
          }
        },
        currentIndex: tIndex,
        selectedItemColor: Colors.red,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l(context, 'pages.tab.home.title')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.favorite),
              label: l(context, 'pages.tab.my_page.title')),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
