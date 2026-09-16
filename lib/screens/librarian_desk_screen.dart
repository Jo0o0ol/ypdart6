import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/services.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';

class LibrarianDeskScreen extends StatelessWidget {
  const LibrarianDeskScreen({super.key, required this.services});
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, String)>[
      ('Управление книгами', Icons.menu_book, '/books'),
      ('Авторы', Icons.people_alt_outlined, '/authors'),
      ('Жанры', Icons.category_outlined, '/genres'),
      ('Издательства', Icons.business_outlined, '/publishers'),
      ('Читатели', Icons.badge_outlined, '/readers'),
      ('Оформление и закрытие выдач', Icons.swap_horiz, '/loans'),
    ];

    return Scaffold(
      appBar: AppTopBar(
        services: services,
        title: 'Рабочее место библиотекаря',
      ),
      body: PageFrame(
        maxWidth: 760,
        child: ListView(
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.local_library_outlined, size: 68),
            const SizedBox(height: 10),
            Text(
              'Функции библиотекаря',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.icon(
                  onPressed: () => context.go(action.$3),
                  icon: Icon(action.$2),
                  label: Text(action.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
