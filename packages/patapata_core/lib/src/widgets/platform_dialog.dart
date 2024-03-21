// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

// ignore_for_file: sort_child_properties_last

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';

final _queue = SequentialWorkQueue();

/// The set of actions that are displayed at the bottom of the dialog.
///
/// On iOS, [CupertinoDialogAction] is used, and on other platforms, [TextButton] is used.
class PlatformDialogAction<T> {
  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// This is called when the dialog is popped, and its return value becomes the
  /// return value of [PlatformDialog.show].
  final T Function() result;

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// This is called after the dialog has been popped.
  final VoidCallback? action;

  /// Whether this action destroys an object.
  ///
  /// This value is effective on iOS only.
  final bool isDestructive;

  /// Set to true if button is the default choice in the dialog.
  ///
  /// This value is effective on iOS only.
  final bool isDefault;

  /// Text to display on the button.
  ///
  /// If [child] is provided, this value is ignored.
  final String? text;

  /// Widget to display as a button.
  ///
  /// If not specified, it displays [text] using the [Text] widget.
  final Widget? child;

  const PlatformDialogAction({
    required this.result,
    this.action,
    this.isDestructive = false,
    this.isDefault = false,
    this.text,
    this.child,
  }) : assert(text != null || child != null);
}

/// By calling [show], a dialog styled according to each platform will be displayed.
/// This wraps Flutter's [showDialog] to match the style of each platform.
///
/// On iOS, [CupertinoAlertDialog] is used, and on other platforms, [AlertDialog] is used.
class PlatformDialog {
  /// Displays a dialog.
  ///
  /// When the dialog is popped, [PlatformDialogAction.result] is called and its
  /// return value becomes the result of the Future.
  static Future<T?> show<T>({
    required BuildContext context,
    required List<PlatformDialogAction<T>> actions,
    String? title,
    String? message,
    Widget? content,
    bool barrierDismissible = true,
    Color? barrierColor = Colors.black54,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    Function()? onClose,
  }) async {
    assert(content != null || message != null);

    return _queue.add<T?>(() {
      if (context.owner == null) {
        return null;
      }

      return showDialog<T>(
        context: context,
        builder: (context) => _PlatformAlertDialog<T>(
          content: content ?? Text(message!),
          actions: actions,
          title: title,
        ),
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
      );
    });
  }
}

class _PlatformAlertDialog<T> extends StatelessWidget {
  const _PlatformAlertDialog({
    Key? key,
    required this.content,
    required this.actions,
    this.title,
  }) : super(key: key);

  final String? title;
  final Widget content;
  final List<PlatformDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return CupertinoAlertDialog(
        title: title != null ? Text(title!) : null,
        // Add a Material so you can use Material library Widgets
        // as a child.
        content: Material(
          child: SingleChildScrollView(child: content),
          color: Colors.transparent,
        ),
        actions: actions.map((action) {
          return CupertinoDialogAction(
            isDefaultAction: action.isDefault,
            isDestructiveAction: action.isDestructive,
            child: action.child ??
                Text(
                  action.text!,
                  textAlign: TextAlign.center,
                ),
            onPressed: () {
              Navigator.pop(context, action.result());
              action.action?.call();
            },
          );
        }).toList(),
      );
    }

    final tTheme = Theme.of(context);

    return Theme(
      data: ThemeData.from(
        colorScheme: tTheme.colorScheme,
        useMaterial3: tTheme.useMaterial3,
      ),
      child: AlertDialog(
        title: title != null ? Text(title!) : null,
        content: SingleChildScrollView(child: content),
        actions: actions.map((action) {
          return TextButton(
            child: action.child ??
                Text(
                  action.text!,
                  textAlign: TextAlign.end,
                ),
            onPressed: () {
              Navigator.pop(context, action.result());
              action.action?.call();
            },
          );
        }).toList(),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: EdgeInsets.fromLTRB(24, title != null ? 16 : 24, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      ),
    );
  }
}
