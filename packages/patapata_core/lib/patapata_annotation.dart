// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// coverage:ignore-file

library patapata_annotation;

import 'package:meta/meta_meta.dart';

/// Annotation used with the separate library patapata_builder.
/// Classes annotated with this are treated as data models in the Repository.
/// It is also possible to impart the concept of sets to the data model by specifying a 'set'.
@Target({TargetKind.classType})
class RepositoryClass {
  const RepositoryClass({required this.sets});

  final Set<Type> sets;
}

/// Annotation used with the separate library patapata_builder.
/// Fields annotated with this are treated as identification IDs in the Repository.
@Target({TargetKind.field})
class RepositoryId {
  const RepositoryId();
}

/// Annotation used with the separate library patapata_builder.
/// Fields annotated with this are treated as data included in a parameter set in the Repository.
@Target({TargetKind.field})
class RepositoryField {
  const RepositoryField({this.sets = const {}});

  final Set<Type> sets;
}
