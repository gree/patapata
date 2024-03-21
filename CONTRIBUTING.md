# Contribution to Patapata

This is a guideline on how to contribute to Patapata. By following these guidelines, anyone can contribute to Patapata.

## Issues

If you have any issues related to Patapata, please report them. When you do, use a template from GitHub Issues.

- Report errors here in this Issue.
- Share your opinions on questions or feature requests related to Patapata here in this Issue.
- For any other questions, please use this Issue.

## Pull Request

If you have any modifications related to Patapata, please submit a PR (Pull Request). In this case, please adhere to the following guidelines:

- Submit the PR against the next branch.
- Fill in the necessary items in the template when creating the PR.
- Assign it an issue number and appropriate labels.
- Ensure it meets the test and coverage requirements with `melos run test:all` or manually with `flutter test --dart-define=IS_TEST=true` for all plugins and core.
- Generally, if you're adding additional Dart files, include their corresponding test code as well.

## Copyright Notice

Patapata uses the MIT License. The rights to this open-source software are owned by GREE, Inc., and the company retains these rights even after the software is publicly released.

Regarding modifications made by individuals other than GREE, Inc., the rights to the modified portions belong to the person who made the modifications.

When creating source code in languages like Dart, Kotlin, Swift, etc., it is essential to include the MIT License at the beginning of the file. Please follow the formatting guidelines specific to the programming language. Below, I'll provide an example of the license statements that are typically included in Dart, Kotlin, and Swift files managed in Patapata:

dart

```dart
// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
```

Kotlin

```kotlin
/*
 * Copyright (c) GREE, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
```

Swift

```swift
// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
```

You can also use the melos command to automatically add the license statement to the file.

`melos run add-license-header`

Note that you will need a working go environment with [addlicense](https://github.com/google/addlicense) installed to use this command.

## Coding Conventions

- We generally follow the [effective-dart](https://dart.dev/guides/language/effective-dart/style) guidelines.
- We adhere to the [Flutter formatting rules](https://flutter.dev/docs/development/tools/formatting).
- We follow the rules of the [Linter](https://dart-lang.github.io/linter/lints/index.html).

### Other Coding Conventions

- Start all local variables with 't,' where 't' stands for temporary. We do this to instantly understand if a variable will affect something outside of the current scope without having to manually looking at the declaration.

```dart
void main() async {
  final App tApp = createApp();
    ...
  tApp.run();
}
```

- Iterator-related variables in constructs like `for` loops can remain as 'i' or similar; there's no issue with that.

```dart
  for (var i = 0; i < 10; i++) {
    print("count : $i");
  }
```

- For internal function names, begin with 'f.' We do this to instantly understand when a function is a local function versus anything else. For example:

```dart
  void exampleFunc() {
    fHogeHoge() {
      ...
    }

    fHogeHoge();
  }
```

- Start private static variables with '_s.’ This is to instantly understand that these variables are static and will possibly affect multiple areas of the codebase as well as not being tied to the current instance.

```dart
static var _sCounter = 0;
```

- For constants, begin private ones with '_k' and public ones with 'k.’

```dart
const _kMyNum = 1;
const kMyPublicNum = 1;
```

- After an 'if (...)' statement, always include curly braces '{}' and a newline. Avoid writing it on a single line without curly braces. For if expressions this is not required.

```dart
// OK
if (something) {
  doThat();
}

// NG
if (something) doThat();

// OK
final tArray = [
  if (something) 2,
];
```

## Project Management

Patapata uses [melos](https://melos.invertase.dev/) to manage this monorepository. Please refer to the melos documentation for more information.

## Quality Assurance

- Patapata aims to support the latest Flutter version as much as possible. However, there may be times when it cannot be compatible with that version due to Flutter's update changes.
- Patapata strives to achieve as close to 100% test code coverage as possible.