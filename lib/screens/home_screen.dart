import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/roles.dart';
import '../core/services.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        services: services,
        title: 'Библиотека',
        showHome: false,
      ),
      body: AnimatedBuilder(
        animation: services.auth,
        builder: (context, _) {
          final role = services.auth.uiRole;
          final serverRole = services.auth.serverRole;
          final user = services.auth.user;
          final widthClass =
              widthClassFor(MediaQuery.sizeOf(context).width);

          return Center(
            child: PageFrame(
              maxWidth: 900,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_library_outlined,
                    size: widthClass == AppWidthClass.compact ? 58 : 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Система управления библиотекой',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user == null
                        ? 'Адаптивная web-версия'
                        : '${user.fullName} · ${serverRole?.title ?? user.role}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _layoutText(widthClass),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/books'),
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Книги'),
                      ),
                      if (role == AppRole.reader)
                        OutlinedButton.icon(
                          onPressed: () => context.go('/reader'),
                          icon: const Icon(Icons.account_circle_outlined),
                          label: const Text('Мои выдачи'),
                        ),
                      if (role == AppRole.librarian)
                        OutlinedButton.icon(
                          onPressed: () => context.go('/librarian'),
                          icon: const Icon(Icons.local_library_outlined),
                          label: const Text('Рабочее место'),
                        ),
                      if (role == AppRole.admin)
                        OutlinedButton.icon(
                          onPressed: () => context.go('/admin'),
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: const Text('Администрирование'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => context.go('/security-demo'),
                    icon: const Icon(Icons.security_outlined),
                    label: const Text('Проверка защиты'),
                  ),
                  if (role != null &&
                      serverRole != null &&
                      role != serverRole) ...[
                    const SizedBox(height: 14),
                    Text(
                      'UI-роль: ${role.title}; серверная роль: ${serverRole.title}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _layoutText(AppWidthClass value) {
    switch (value) {
      case AppWidthClass.compact:
        return 'Компактный режим: нижняя навигация и карточки.';
      case AppWidthClass.medium:
        return 'Средний режим: боковая навигация и карточки.';
      case AppWidthClass.wide:
        return 'Широкий режим: таблицы и развёрнутая навигация.';
      case AppWidthClass.ultraWide:
        return 'Очень широкий режим: ограниченная ширина содержимого.';
    }
  }
}
