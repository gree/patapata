// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

/// This file is for the sole purpose of providing an empty ffi shell for
/// the web. Just to compile things. Not execute.
library;

class Pointer {}

class Struct {}

class Union {}

final class DynamicLibrary {
  static DynamicLibrary open(String name) {
    throw UnimplementedError();
  }
}
