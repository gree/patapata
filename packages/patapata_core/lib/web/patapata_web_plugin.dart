// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// Interface for Web Plugin
abstract class PatapataPlugin {
  String get patapataName;
  void patapataEnable() {}
  void patapataDisable() {}
}
