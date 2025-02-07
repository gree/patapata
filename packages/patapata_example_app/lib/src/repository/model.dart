// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_annotation.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_interface.dart';
import 'package:provider/provider.dart';

part 'model.g.dart';

mixin DataListSet {
  void addCounter1() {
    final tInstance = (this as Data);
    final tBatch = tInstance.begin();
    tBatch.set(tInstance._counter1, tInstance.counter1 + 1);
    tBatch.commit();
  }

  // This is a process that should not normally be done, but it is added for the sake of the example.
  String get translationConfition {
    final tInstance = (this as Data);
    if (tInstance._translationDate.set) {
      return 'available for use';
    }

    return 'not initialized';
  }
}

/// Doc comments attached to classes will be
/// reproduced in automatically generated files.
@RepositoryClass(sets: {DataListSet})
abstract class _Data extends ProviderModel<Data>
    implements RepositoryModelCache {
  _Data({
    required this.id,
  });

  _Data.init(this.id) {
    final tData = Data(id: id);
    final tBatch = tData.begin();

    tBatch
      ..set(_name, 'id: $id')
      ..set(_counter1, 0)
      ..set(_counter2, 0)
      ..commit(notify: false);
  }

  _Data.fromDateTime(this.id, DateTime date) {
    final tData = Data(id: id);
    final tBatch = tData.begin();

    tBatch
      ..set(_translationDate, date)
      ..commit(notify: false);
  }

  @RepositoryId()
  final int id;

  /// Variables will also be reproduced in the same manner.
  @RepositoryField(sets: {DataListSet})
  late final _name = createUnsetVariable<String>();

  @RepositoryField(sets: {DataListSet})
  late final _counter1 = createUnsetVariable<int>();

  @RepositoryField()
  late final _counter2 = createUnsetVariable<int>();

  @RepositoryField()
  late final _translationDate = createUnsetVariable<DateTime>();

  @override
  Duration? get repositoryCacheDuration => const Duration(seconds: 500);
}

extension ExtendData on Data {
  void addCounter2() {
    begin()
      ..set(_counter2, counter2 + 1)
      ..commit();
  }
}
