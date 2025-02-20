// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_model1.dart';

// **************************************************************************
// Generator: RepositoryBuilder
// **************************************************************************

// ignore_for_file: override_on_non_overriding_member

extension RepositoryExtensionFilter1 on Filter1 {
  int get id => (this as TestModel).id;

  double get value2 => (this as TestModel).value2;

  String get text => (this as TestModel).text;
}

extension RepositoryExtensionFilter2 on Filter2 {
  int get id => (this as TestModel).id;

  String get text => (this as TestModel).text;
}

extension RepositoryExtensionFilter3 on Filter3 {
  int get id => (this as TestModel).id;

  String get text => (this as TestModel).text;
}

class TestModel extends _TestModel
    with RepositoryModel<TestModel, int>, Filter1, Filter2, Filter3 {
  TestModel({
    required super.id,
  });

  TestModel.init(
    super.id, {
    super.v1,
    super.v2,
    super.v3,
    super.cacheDuration,
  }) : super.init();

  TestModel.fromRecord(
    super.id,
    super.v, {
    super.cacheDuration,
  }) : super.fromRecord();

  @override
  int get value1 => _value1.unsafeValue;

  @override
  double get value2 => _value2.unsafeValue;

  @override
  String get text => _text.unsafeValue;

  @override
  HasNotBuilderModel get deepModel => _deepModel.unsafeValue;

  @override
  TestModel repositoryDefaultFactory(int id) => TestModel(id: id);

  @override
  Widget providersBuilder(Widget child) {
    return MultiProvider(
      providers: [
        InheritedProvider<TestModel>.value(
          value: this,
          startListening: (c, v) {
            v.addListener(c.markNeedsNotifyDependents);
            return () => v.removeListener(c.markNeedsNotifyDependents);
          },
        ),
        InheritedProvider<Filter1>.value(
          value: this,
          startListening: (c, v) {
            final tInstance = (v as TestModel);
            tInstance.addListener(c.markNeedsNotifyDependents);
            return () => tInstance.removeListener(c.markNeedsNotifyDependents);
          },
        ),
        InheritedProvider<Filter2>.value(
          value: this,
          startListening: (c, v) {
            final tInstance = (v as TestModel);
            tInstance.addListener(c.markNeedsNotifyDependents);
            return () => tInstance.removeListener(c.markNeedsNotifyDependents);
          },
        ),
        InheritedProvider<Filter3>.value(
          value: this,
          startListening: (c, v) {
            final tInstance = (v as TestModel);
            tInstance.addListener(c.markNeedsNotifyDependents);
            return () => tInstance.removeListener(c.markNeedsNotifyDependents);
          },
        ),
      ],
      child: child,
    );
  }

  @override
  int get repositoryId => id;

  @override
  Map<Type, Set<ProviderModelVariable>> get repositorySetVariables => {
        TestModel: {_value1, _value2, _text, _deepModel},
        Filter1: {_value2, _text},
        Filter2: {_text},
        Filter3: {_text},
      };
}
