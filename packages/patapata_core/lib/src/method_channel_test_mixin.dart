// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
import 'package:flutter/services.dart';

/// A mixin for adding a function to mock processing in a test environment
/// to a class.
mixin MethodChannelTestMixin {
  final List<MethodCall> methodCallLogs = <MethodCall>[];

  /// A function for mocking a MethodChannel.
  ///
  /// Currently supported by [App], [Plugin] and [Config].
  /// If you override this function in a subclass that inherits from each,
  /// the processing described here will be executed
  /// when the constructor is called for [App],
  /// and when the init function is called for [Plugin] and [Config].
  void setMockMethodCallHandler() {}

  /// A function for mocking a MockStreamHandler.
  ///
  /// Currently supported by [Plugin].
  /// If you override this function in a subclass that inherits from [Plugin],
  /// the processing described here will be executed when the init function
  /// for [Plugin] is called.
  void setMockStreamHandler() {}
}
