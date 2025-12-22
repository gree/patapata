// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_annotation.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_interface.dart';
import 'package:provider/provider.dart';

import '../test_data.dart';

part 'test_model1.g.dart';

mixin Filter1 {}
mixin Filter2 {}
mixin Filter3 {}
mixin InvalidFilter {}

class CacheDurationException implements Exception {}

@RepositoryClass(sets: {Filter1, Filter2, Filter3})
abstract class _TestModel extends ProviderModel<TestModel>
    implements RepositoryModelCache {
  _TestModel({required this.id});

  _TestModel.init(
    this.id, {
    int? v1,
    double? v2,
    String? v3,
    this.cacheDuration,
  }) {
    final tBatch = begin();

    if (v1 != null) {
      tBatch.set<int?>(_value1, v1);
      tBatch.set<HasNotBuilderModel>(
        _deepModel,
        HasNotBuilderModel.init(id, v1),
      );
    }

    if (v2 != null) {
      tBatch.set<double?>(_value2, v2);
    }

    if (v3 != null) {
      tBatch.set<String?>(_text, v3);
    }

    tBatch.commit(notify: false);
  }

  _TestModel.fromRecord(int id, TestRecord v, {Duration? cacheDuration})
    : this.init(id, v1: v.$1, v2: v.$2, v3: v.$3, cacheDuration: cacheDuration);

  Duration? cacheDuration;
  bool errorOnCacheDuration = false;

  @RepositoryId()
  final int id;

  @RepositoryField()
  late final _value1 = createUnsetVariable<int>();

  @RepositoryField(sets: {Filter1})
  late final _value2 = createUnsetVariable<double>();

  @RepositoryField(sets: {Filter1, Filter2, Filter3})
  late final _text = createUnsetVariable<String>();

  @RepositoryField()
  late final _deepModel = createUnsetVariable<HasNotBuilderModel>();

  @override
  Duration? get repositoryCacheDuration =>
      errorOnCacheDuration ? throw CacheDurationException() : cacheDuration;
}

class HasNotBuilderModel extends ProviderModel<HasNotBuilderModel>
    with RepositoryModel<HasNotBuilderModel, int> {
  HasNotBuilderModel({required this.id});

  HasNotBuilderModel.init(this.id, int value) {
    final tBatch = begin();
    tBatch.set<int?>(_value, value);
    tBatch.commit(notify: false);
  }

  final int id;
  late final _value = createUnsetVariable<int>();

  int get value => _value.unsafeValue;

  @override
  HasNotBuilderModel repositoryDefaultFactory(int id) =>
      HasNotBuilderModel(id: id);

  @override
  int get repositoryId => id;

  @override
  Map<Type, Set<ProviderModelVariable>> get repositorySetVariables => {
    HasNotBuilderModel: {_value},
  };
}
