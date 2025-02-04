// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

part of 'repository.dart';

/// Base class that serves as the foundation for the repository model.
/// [RepositoryModel] and [SimpleRepositoryModel] inherit from this class.
mixin RepositoryModelBase<T extends RepositoryModelBase<T, I>,
    I extends Object> {
  /// The unique ID in the repository.
  I get repositoryId;

  /// A map of variables entrusted to the repository for management.
  /// Set the keys of the map to the sets specified in [RepositoryClass].
  /// Please configure the combinations of parameter sets and variables used in each parameter set.
  ///
  /// For example:
  /// ```dart
  ///
  /// @override
  /// Map<Type, Set<ProviderModelVariable>> get repositorySetVariables => {
  ///       Set1: {_value1, _value2},
  ///       Set2: {_value1, _value2, _value3},
  ///     };
  /// ```
  Map<Type, Set<ProviderModelVariable>> get repositorySetVariables;

  /// Called by a Repository to create a default object of type [T] from [id].
  T repositoryDefaultFactory(I id);

  /// Function for creating a widget that encapsulates a data model.
  /// Add it to the Widget tree using [Provider] or [InheritedWidget], etc.
  /// You may need to change the created widget depending on the type of data model and how it is used.
  ///
  /// For example, if you are using [RepositoryClass.sets], you need to prepare a data model and a [MultiProvider] for the set.
  /// For example:
  /// ```dart
  ///
  /// @override
  /// Widget providersBuilder(Widget child) {
  ///   return MultiProvider(
  ///     providers: [
  ///       InheritedProvider<DataModel>.value(
  ///         value: this,
  ///         startListening: (c, v) {
  ///           v.addListener(c.markNeedsNotifyDependents);
  ///           return () => v.removeListener(c.markNeedsNotifyDependents);
  ///         },
  ///       ),
  ///       InheritedProvider<DataModelSet>.value(
  ///         value: this,
  ///         startListening: (c, v) {
  ///           final tInstance = (v as DataModel);
  ///           tInstance.addListener(c.markNeedsNotifyDependents);
  ///           return () => tInstance.removeListener(c.markNeedsNotifyDependents);
  ///         },
  ///       ),
  ///     ],
  ///     child: child,
  ///   );
  /// }
  /// ```
  ///
  /// If you prepare data using global (such as riverpod), there is no need to override it.
  /// However, since the repository system needs to understand how to retrieve data,
  /// please specify that method in [RepositoryProvider.reader].
  Widget providersBuilder(Widget child);

  /// Returns a list of sets specified in [RepositoryClass].
  Set<Type> get repositorySets;

  /// Checks if the specified parameter set is included in [repositorySets].
  bool repositoryHasSet(Type set);

  /// Returns whether the repository has change notifications.
  bool get _repositoryHasListeners;

  /// Notifies the repository of changes.
  void _repositoryNotifyListeners();

  /// Clones this [RepositoryObjectBase] object.
  /// Setting deep to true will also copy the contents if the source is [RepositoryModelBase].
  T clone([bool deep = true]);

  static T2 _clone<T2 extends RepositoryModelBase<T2, I>, I extends Object>(
    RepositoryModelBase<T2, I> original, [
    bool deep = true,
  ]) {
    final tClone = original.repositoryDefaultFactory(original.repositoryId);
    if (tClone is! ProviderModel) {
      if (tClone is SimpleRepositoryModel) {
        (tClone as SimpleRepositoryModel).update(original);
      }

      return tClone;
    }

    final tCloneBatch = (tClone as ProviderModel).begin();

    for (var i in original.repositorySetVariables.entries) {
      final tCloneSetVariables = tClone.repositorySetVariables[i.key]!;
      final tOriginalSetVariables = i.value;

      for (var j = 0, jl = tCloneSetVariables.length; j < jl; j++) {
        final tOriginalVariable = tOriginalSetVariables.elementAt(j);

        if (tOriginalVariable.set) {
          final tOriginalValue = tOriginalVariable.unsafeValue;

          tCloneBatch.set(
            tCloneSetVariables.elementAt(j),
            deep && tOriginalValue is RepositoryModelBase
                ? tOriginalValue.clone(true)
                : tOriginalValue,
          );
        }
      }
    }

    tCloneBatch.commit(notify: false);

    return tClone;
  }
}

/// When creating a repository model that requires change notifications, mix-in this class.
/// It is assumed that the inheriting class is a [ProviderModel].
mixin RepositoryModel<T extends RepositoryModelBase<T, I>, I extends Object>
    on ProviderModel<T> implements RepositoryModelBase<T, I> {
  /// Updates the variables held by the repository.
  /// The data is copied from [object].
  /// Using [batch] allows for bulk updates and simultaneous change notifications.
  void update(ProviderModelBatch batch, T object) {
    final tVariables = repositorySetVariables[T]!;
    final tObjectVariables =
        object.repositorySetVariables[T]!.toList(growable: false);

    for (final v in tObjectVariables.where((e) => e.set)) {
      final i = tObjectVariables.indexOf(v);
      batch.set(tVariables.elementAt(i), v.unsafeValue);
    }
  }

  @override
  Set<Type> get repositorySets => {
        for (var i in repositorySetVariables.entries)
          if (i.value.every((e) => e.set)) i.key,
      };

  @override
  bool repositoryHasSet(Type set) =>
      repositorySetVariables[set]?.every((e) => e.set) ?? false;

  @override
  Widget providersBuilder(Widget child) => child;

  @override
  bool get _repositoryHasListeners => hasListeners;

  @override
  void _repositoryNotifyListeners() {
    if (hasListeners) {
      scheduleFunction(() {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  @override
  T clone([bool deep = true]) {
    return RepositoryModelBase._clone<T, I>(this, deep);
  }

  @override
  int get hashCode => repositoryId.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is T && other.repositoryId == repositoryId) {
      return true;
    }

    return false;
  }
}

/// Mix-in when creating a simple repository model that does not require change notifications.
/// It is possible to have change notifications, but it is often preferable to use [RepositoryModel].
/// Use this when, due to the structure of the data model, [RepositoryModel] cannot be used.
mixin SimpleRepositoryModel<T extends RepositoryModelBase<T, I>,
    I extends Object> implements RepositoryModelBase<T, I> {
  /// Updates the variables held by the repository.
  /// The specifics of the update are left to the derived class.
  void update(T object);

  @override
  Set<Type> get repositorySets => {T};

  @override
  Map<Type, Set<ProviderModelVariable>> get repositorySetVariables => {
        T: {},
      };

  // coverage:ignore-start
  // This method is not used in SimpleRepositoryModel.
  @override
  Widget providersBuilder(Widget child) => child;
  // coverage:ignore-end

  @override
  bool repositoryHasSet(Type set) => true;

  @override
  void _repositoryNotifyListeners() {
    // Do nothing.
  }

  @override
  T clone([deep = true]) {
    return RepositoryModelBase._clone<T, I>(this, deep);
  }

  @override
  int get hashCode => repositoryId.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is T && other.repositoryId == repositoryId) {
      return true;
    }

    return false;
  }
}
