// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/cupertino.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';

import '../pages/home_page.dart';
import '../pages/my_page.dart';

class CupertinoAppContainer extends StandardPageWithNestedNavigator {
  @override
  String localizationKey = 'pages.tab';

  final _selectedFooterType =
      ValueNotifier<Type>(_FooterState._kFooterTypes.first);

  Type get selectedFooterType => _selectedFooterType.value;

  set selectedFooterType(Type value) {
    // Since it may be called during build, defer it with scheduleFunction.
    scheduleFunction(() {
      _selectedFooterType.value = value;
    });
  }

  Future<void> dialog(BuildContext context) {
    return PlatformDialog.show(
      context: context,
      message: 'Test Dialog',
      actions: [
        PlatformDialogAction(
          text: 'OK',
          result: () {},
        ),
      ],
    );
  }

  @override
  Widget buildPage(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(context.pl('title')),
      ),
      child: Column(
        children: [
          Expanded(
            child: Provider<CupertinoAppContainer>.value(
              value: this,
              child: nestedPages,
            ),
          ),
          ChangeNotifierProvider<ValueNotifier<Type>>.value(
            value: _selectedFooterType,
            child: const _Footer(),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  static const _kFooterTypes = <Type>[
    CupertinoHomePageParent,
    CupertinoMyPageParent,
  ];

  @override
  Widget build(BuildContext context) {
    final tSelectedFooterType = context.watch<ValueNotifier<Type>>().value;

    int tActiveIndex = _kFooterTypes.indexOf(tSelectedFooterType);
    if (tActiveIndex < 0) {
      tActiveIndex = 0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CupertinoButton(
          onPressed: () {
            context.go<CupertinoHomePageParent, void>(null);
          },
          child: (tActiveIndex == 0)
              ? const Icon(
                  CupertinoIcons.home,
                  color: CupertinoColors.systemRed,
                )
              : const Icon(CupertinoIcons.home),
        ),
        CupertinoButton(
          onPressed: () {
            context.go<CupertinoMyPageParent, void>(null);
          },
          child: (tActiveIndex == 1)
              ? const Icon(
                  CupertinoIcons.person,
                  color: CupertinoColors.systemRed,
                )
              : const Icon(CupertinoIcons.person),
        ),
      ],
    );
  }
}
