import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404', style: TextStyle(fontSize: 54, fontWeight: FontWeight.bold)),
            const Text('Страница не найдена'),
            const SizedBox(height: 8),
            SelectableText(location),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/'), child: const Text('На главную')),
          ],
        ),
      ),
    );
  }
}
