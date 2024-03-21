// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';

import '../../page_data.dart';

/// The simplest example of StandardPage without holding any PageData.
class StandardPageExamplePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.standard_page.title')),
      ),
      body: ListView(
        children: [
          Center(
            child: Text(l(context, 'pages.standard_page.body')),
          ),
          TextButton(
            onPressed: () {
              context.go<HasDataPage, PageData>(PageData());
            },
            child: Text(
                l(context, 'pages.standard_page.go_to_next_standard_page')),
          ),
          TextButton(
            onPressed: () {
              context.go<CustomStandardPage, void>(null);
            },
            child: Text(
                l(context, 'pages.standard_page.go_to_custom_standard_page')),
          ),
          TextButton(
            onPressed: () {
              context.go<ChangeListenablePage, BaseListenable>(
                ChangeListenableNumber(),
              );
            },
            child: Text(l(context, 'pages.standard_page.go_to_page_data')),
          ),
        ],
      ),
    );
  }
}

/// An example of a StandardPage that holds PageData.
/// To create a StandardPage with PageData, specify the type of PageData as the type argument for StandardPage.
/// To access members of this PageData, you can use syntax like pageData.hello.
class HasDataPage extends StandardPage<PageData> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.standard_page.title')),
      ),
      body: ListView(
        children: [
          Center(
            child: Text(l(
                context,
                'pages.standard_page.page_data_value',
                // You can access members of PageData like this.
                {'prefix': pageData.hello})),
          ),
          TextButton(
            onPressed: () {
              // You can change the value of PageData like this.
              pageData = PageData(hello: 'change hi!');
              setState(() {});
            },
            child: Text(l(context, 'pages.standard_page.change_page_data')),
          ),
        ],
      ),
    );
  }
}

/// A page to display a customized StandardPage.
class CustomStandardPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.standard_page.title')),
      ),
      body: ListView(
        children: [
          Center(
            child: Text(l(context, 'pages.standard_page.body')),
          ),
        ],
      ),
    );
  }
}

/// Example of manipulating or modifying values in PageData and retrieving values through a Provider in StandardPage.
class ChangeListenablePage extends StandardPage<BaseListenable> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context, 'pages.standard_page.title')),
      ),
      body: ListView(
        children: [
          Center(
            child: Text(l(context, 'pages.standard_page.body')),
          ),
          Center(
            // Observe changes to the value of CountData set in MultiProvider within routableBuilder.
            child: Text(l(context, 'pages.standard_page.page_data_count',
                {'prefix': context.watch<CountData>().count})),
          ),
          TextButton(
            onPressed: () {
              // An example of changing the type of pageData to another class that extends ChangeNotifier.
              if (pageData is ChangeListenableBool) {
                pageData = ChangeListenableNumber();
              } else {
                pageData = ChangeListenableBool();
              }
              setState(() {});
            },
            child:
                Text(l(context, 'pages.standard_page.change_page_data_type')),
          ),
          if (pageData is ChangeListenableBool)
            Center(
              child: Text(l(
                  context,
                  'pages.standard_page.change_page_data_result',
                  {'prefix': context.watch<ChangeListenableBool>().data})),
            ),
          if (pageData is ChangeListenableNumber)
            Center(
              child: Text(l(
                  context,
                  'pages.standard_page.change_page_data_result',
                  {'prefix': context.watch<ChangeListenableNumber>().data})),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<CountData>().increment();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
