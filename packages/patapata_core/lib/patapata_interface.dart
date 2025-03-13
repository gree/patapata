// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

library patapata_interface;

/// Sets the expiration period for the cache.
///　Used in [RepositoryModel].
///
/// The repository system internally treats the delay time as a 32-bit signed integer.
/// Therefore, if a delay time exceeding 2,147,483,647 milliseconds (approximately 24.8 days) is set,
/// it will be set as 2,147,483,647 milliseconds.
interface class RepositoryModelCache {
  // coverage:ignore-start
  Duration? get repositoryCacheDuration => null;
  // coverage:ignore-end
}

/// @nodoc
interface class ProviderModelInterface {
  // coverage:ignore-start
  static String get className => (ProviderModelInterface).toString();
  // coverage:ignore-end
}

/// @nodoc
interface class ProviderModelVariableInterface {
  // coverage:ignore-start
  static String get className => (ProviderModelVariableInterface).toString();
  // coverage:ignore-end
}
