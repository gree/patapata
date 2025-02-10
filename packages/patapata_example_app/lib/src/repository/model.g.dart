// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// Generator: RepositoryBuilder
// **************************************************************************

// ignore_for_file: override_on_non_overriding_member

extension RepositoryExtensionDataListSet on DataListSet {
  int get id => (this as Data).id;

  /// Variables will also be reproduced in the same manner.
  String get name => (this as Data).name;

  int get counter1 => (this as Data).counter1;
}

/// Doc comments attached to classes will be
/// reproduced in automatically generated files.
class Data extends _Data with RepositoryModel<Data, int>, DataListSet {
  Data({
    required super.id,
  });

  Data.init(super.id) : super.init();

  Data.fromDateTime(super.id, super.date) : super.fromDateTime();

  @override
  String get name => _name.unsafeValue;

  @override
  int get counter1 => _counter1.unsafeValue;

  @override
  int get counter2 => _counter2.unsafeValue;

  @override
  DateTime get translationDate => _translationDate.unsafeValue;

  @override
  Data repositoryDefaultFactory(int id) => Data(id: id);

  @override
  Widget providersBuilder(Widget child) {
    return MultiProvider(
      providers: [
        InheritedProvider<Data>.value(
          value: this,
          startListening: (c, v) {
            v.addListener(c.markNeedsNotifyDependents);
            return () => v.removeListener(c.markNeedsNotifyDependents);
          },
        ),
        InheritedProvider<DataListSet>.value(
          value: this,
          startListening: (c, v) {
            final tInstance = (v as Data);
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
        Data: {_name, _counter1, _counter2, _translationDate},
        DataListSet: {_name, _counter1},
      };
}
