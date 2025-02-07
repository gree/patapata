// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';

import '../test_data.dart';

mixin Filter1 {
  int get id => (this as TestModel).id;
  double? get value2 => (this as TestModel).value2;
  String? get text => (this as TestModel).text;
}

class TestModel with SimpleRepositoryModel<TestModel, int>, Filter1 {
  TestModel({
    required this.id,
  });

  TestModel.init(this.id, {int? v1, double? v2, String? v3}) {
    _value1 = v1;
    _value2 = v2;
    _text = v3;
  }

  TestModel.fromRecord(
    int id,
    TestRecord v,
  ) : this.init(id, v1: v.$1, v2: v.$2, v3: v.$3);

  @override
  final int id;

  @override
  TestModel repositoryDefaultFactory(int id) => TestModel(id: id);

  @override
  int get repositoryId => id;

  int? _value1;
  int? get value1 => _value1;

  double? _value2;
  @override
  double? get value2 => _value2;

  String? _text;
  @override
  String? get text => _text;

  @override
  void update(TestModel object) {
    _value1 = object._value1;
    _value2 = object._value2;
    _text = object._text;
  }
}

class TestModelWithNotifier extends TestModel with ChangeNotifier {
  TestModelWithNotifier({
    required super.id,
  });

  TestModelWithNotifier.init(super.id, {super.v1, super.v2, super.v3})
      : super.init();

  void setText(String text) {
    _text = text;
    notifyListeners();
  }
}
