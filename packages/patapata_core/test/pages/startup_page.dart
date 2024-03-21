// Copyright (c) GREE, Inc.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.

import 'package:flutter/material.dart';
import 'package:patapata_core/patapata_core.dart';
import 'package:patapata_core/patapata_widgets.dart';

class SplashPage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SplashPage',
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}

class StartupPageA extends StandardPage<StartupPageCompleter> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StartupPageA',
        ),
      ),
      body: ListView(
        children: [
          TextButton(
            onPressed: () {
              pageData(true);
            },
            child: const Text('Complete'),
          ),
          TextButton(
            onPressed: () {
              getApp().startupSequence?.resetMachine();
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => StartupModalPageA(completer: pageData),
              ));
            },
            child: const Text('PushModalA'),
          ),
        ],
      ),
    );
  }
}

class StartupPageB extends StandardPage<StartupPageCompleter> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StartupPageB',
        ),
      ),
      body: ListView(
        children: [
          TextButton(
            onPressed: () {
              pageData(true);
            },
            child: const Text('Complete'),
          ),
          TextButton(
            onPressed: () {
              getApp().startupSequence?.resetMachine();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class StartupModalPageA extends StatelessWidget {
  const StartupModalPageA({
    super.key,
    this.completer,
  });

  final StartupPageCompleter? completer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StartupModalPageA',
        ),
      ),
      body: ListView(
        children: [
          TextButton(
            onPressed: () {
              completer?.call(true);
            },
            child: const Text('Complete'),
          ),
          TextButton(
            onPressed: () {
              completer?.call(true);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const StartupModalPageB(),
              ));
            },
            child: const Text('CompleteAndPushModaB'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).replace(
                oldRoute: ModalRoute.of(context)!,
                newRoute: MaterialPageRoute(
                  builder: (context) => StartupModalPageB(
                    completer: completer,
                  ),
                ),
              );
            },
            child: const Text('ReplaceAtoB'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).removeRoute(ModalRoute.of(context)!);
            },
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () {
              getApp().startupSequence?.resetMachine();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class StartupModalPageB extends StatelessWidget {
  const StartupModalPageB({
    super.key,
    this.completer,
  });

  final StartupPageCompleter? completer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StartupModalPageB',
        ),
      ),
      body: ListView(
        children: [
          TextButton(
            onPressed: () {
              completer?.call(true);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const StartupModalPageC(),
              ));
            },
            child: const Text('CompleteAndPushModaC'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).removeRoute(ModalRoute.of(context)!);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class StartupModalPageC extends StatelessWidget {
  const StartupModalPageC({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StartupModalPageC',
        ),
      ),
      body: ListView(
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).removeRoute(ModalRoute.of(context)!);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class TestHomePage extends StandardPage<void> {
  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HomePage',
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
