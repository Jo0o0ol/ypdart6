import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/roles.dart';
import '../core/services.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 76,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                'Доступ запрещён',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Роль «${services.auth.serverRole?.title ?? 'не определена'}» '
                'не имеет доступа к этому маршруту.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
