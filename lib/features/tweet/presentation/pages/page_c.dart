// lib/features/sample_pages/page_c.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

class PageC extends ConsumerWidget {
  final String? id;
  const PageC({super.key, this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page C')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('This is Page C with ID: ${id ?? "N/A"}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.goNamed(AppRouteNames.HomeTimeLineScreen);
              },
              child: const Text('Go to HomeTimeLineScreen'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                while(context.canPop()) {
                  context.pop();
                }
              },
              child: const Text('Pop to Top (or Go to HomeTimeLineScreen)'),
            ),
          ],
        ),
      ),
    );
  }
}