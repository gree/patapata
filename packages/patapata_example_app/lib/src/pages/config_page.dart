// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';
import 'package:provider/provider.dart';

/// This is a page demonstrating how to use LocalConfig.
/// Here, values are being saved, modified, and retrieved for a LocalConfig with the key name counter.
class ConfigPage extends StandardPage<void> {
  @override
  String localizationKey = 'pages.config';

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.pl('title')),
      ),
      body: ListView(
        children: [
          Center(
            child: Text(context.pl('body')),
          ),
          Center(
            child: Builder(
              builder: (context) {
                // Retrieve the value of counter from LocalConfig.
                return Text(l(context, 'plurals.test1', {
                  'count': context
                      .select<LocalConfig, int>((v) => v.getInt('counter'))
                }));
              },
            ),
          ),
          TextButton(
            onPressed: () {
              // Set the value of counter in LocalConfig.
              getApp().localConfig.setInt(
                  'counter', getApp().localConfig.getInt('counter') + 1);
            },
            child: Text(context.pl('increment')),
          ),
          TextButton(
            onPressed: () {
              // Delete the value stored in LocalConfig.
              getApp().localConfig.reset('counter');
            },
            child: Text(context.pl('clear')),
          ),
        ],
      ),
    );
  }
}
