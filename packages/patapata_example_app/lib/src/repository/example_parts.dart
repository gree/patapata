// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';

ButtonStyle iconButtonDefaultStyle(ColorScheme color) => IconButton.styleFrom(
      padding: EdgeInsets.zero,
      foregroundColor: color.onSecondaryContainer,
      backgroundColor: color.secondaryContainer,
      // In the latest Flutter, withValues should be used.
      // However, it has not yet been implemented in Flutter 3.24.0.
      // ignore: deprecated_member_use
      disabledBackgroundColor: color.onSurface.withOpacity(0.12),
      // ignore: deprecated_member_use
      hoverColor: color.onSecondaryContainer.withOpacity(0.08),
      // ignore: deprecated_member_use
      focusColor: color.onSecondaryContainer.withOpacity(0.12),
      // ignore: deprecated_member_use
      highlightColor: color.onSecondaryContainer.withOpacity(0.12),
    );

class AddButton extends StatelessWidget {
  const AddButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tColors = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: 28.0,
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.plus_one, size: 16.0),
          style: iconButtonDefaultStyle(tColors),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class ResetButton extends StatelessWidget {
  const ResetButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tColors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 28.0,
      width: 58.0,
      child: ElevatedButton(
        style: iconButtonDefaultStyle(tColors),
        onPressed: onPressed,
        child: const Text('reset'),
      ),
    );
  }
}

class TransferButton extends StatelessWidget {
  const TransferButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tColors = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: 28.0,
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.arrow_right_alt, size: 16.0),
          style: iconButtonDefaultStyle(tColors),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class DataStructure extends StatelessWidget {
  const DataStructure({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        border: Border.all(
          color: Colors.black,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Class : Data',
            style: TextStyle(fontSize: 18),
          ),
          const Divider(
            color: Colors.black,
            height: 4,
            indent: 16,
            endIndent: 16,
          ),
          Column(
            children: [
              const Text('int counter2'),
              const Text('DateTime translationDate'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(
                      color: Colors.black,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Set : DataListSet',
                        style: TextStyle(fontSize: 18),
                      ),
                      Divider(
                        color: Colors.black,
                        height: 4,
                        indent: 16,
                        endIndent: 16,
                      ),
                      Text('String name'),
                      Text('int counter1'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
