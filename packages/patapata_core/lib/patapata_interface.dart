// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_interface;

/// Sets the expiration period for the cache.
///　Used in [RepositoryModel].
interface class RepositoryModelCache {
  Duration? get repositoryCacheDuration => null;
}

/// @nodoc
interface class ProviderModelInterface {
  static String get className => (ProviderModelInterface).toString();
}

/// @nodoc
interface class ProviderModelVariableInterface {
  static String get className => (ProviderModelVariableInterface).toString();
}
