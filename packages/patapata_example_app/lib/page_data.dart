// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// This file contains the bundled PageData used as an example in StandardPage.

import 'package:flutter/widgets.dart';

class PageData {
  PageData({
    this.hello = 'hi!',
  });
  final String hello;
}

class CountData extends ChangeNotifier {
  int count = 0;

  void increment() {
    count = count + 1;
    notifyListeners();
  }
}

class BaseListenable extends ChangeNotifier {}

class ChangeListenableBool extends BaseListenable {
  bool data = false;
}

class ChangeListenableNumber extends BaseListenable {
  int data = 100;
}
