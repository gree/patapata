// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

import '../pages/home_page.dart';
import '../pages/my_page.dart';

/// Sample StandardApp for Cupertino with a widget displayed in a tab.
class CupertinoAppBar extends StatelessWidget {
  const CupertinoAppBar({
    super.key,
    required this.body,
    this.appBar,
  });

  final Widget body;
  final Widget? appBar;

  @override
  Widget build(BuildContext context) {
    var tInterfacePage =
        ModalRoute.of(context)!.settings as StandardPageInterface;
    var tType = tInterfacePage.factoryObject.parentPageType;
    int tIndex = 0;
    if (tType == CupertinoHomePage) {
      tIndex = 0;
    } else if (tType == CupertinoMyPage) {
      tIndex = 1;
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: const StandardPageBackButton(),
        middle: tIndex == 0
            ? Text(l(context, 'pages.tab.home.title'))
            : Text(l(context, 'pages.tab.my_page.title')),
      ),
      child: Column(
        children: [
          Expanded(
            child: body,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CupertinoButton(
                onPressed: () {
                  context.go<CupertinoHomePage, void>(null);
                },
                child: const Icon(CupertinoIcons.home),
              ),
              CupertinoButton(
                onPressed: () {
                  context.go<CupertinoMyPage, void>(null);
                },
                child: const Icon(CupertinoIcons.heart),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
