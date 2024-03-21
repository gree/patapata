// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patapata_core/patapata_core.dart';

class RiverpodPlugin extends Plugin {
  @override
  Widget createAppWidgetWrapper(Widget child) {
    return ProviderScope(child: child);
  }
}
