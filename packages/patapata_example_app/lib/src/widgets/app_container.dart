// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';

import '../pages/home_page.dart';
import '../pages/my_page.dart';

class AppContainer extends StandardPageWithNestedNavigator {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
      ),
      body: Provider<AppContainer>.value(
        value: this,
        child: nestedPages,
      ),
      bottomNavigationBar: ChangeNotifierProvider<ValueNotifier<Type>>.value(
        value: _selectedFooterType,
        child: const _Footer(),
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
    HomePageParent,
    MyPageParent,
  ];

  @override
  Widget build(BuildContext context) {
    final tSelectedFooterType = context.watch<ValueNotifier<Type>>().value;

    int tActiveIndex = _kFooterTypes.indexOf(tSelectedFooterType);
    if (tActiveIndex < 0) {
      tActiveIndex = 0;
    }

    return BottomNavigationBar(
      onTap: (index) {
        switch (index) {
          case 0:
            context.go<HomePageParent, void>(null);
            break;
          case 1:
            context.go<MyPageParent, void>(null);
            break;
          default:
            break;
        }
      },
      currentIndex: tActiveIndex,
      selectedItemColor: Colors.red,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l(context, 'pages.tab.home.title')),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l(context, 'pages.tab.my_page.title')),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}
