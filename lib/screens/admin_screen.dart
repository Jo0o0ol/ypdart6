import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../core/services.dart';
import '../models/models.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminStats? _stats;
  List<AppUser> _users = <AppUser>[];
  bool _loading = true;
  String? _error;
  int? _changingUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        widget.services.admin.stats(),
        widget.services.users.find(size: 100),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = values[0] as AdminStats;
        _users = (values[1] as PageResult<AppUser>).items;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(AppUser user, String role) async {
    setState(() => _changingUserId = user.id);
    try {
      await widget.services.users.changeRole(user.id, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Роль пользователя ${user.username} изменена.')),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _changingUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        services: widget.services,
        title: 'Панель администратора',
      ),
      body: PageFrame(
        child: _loading && _stats == null
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _stat('Пользователи', _stats?.users ?? 0, Icons.people_outline),
                          _stat('Книги', _stats?.books ?? 0, Icons.menu_book),
                          _stat('Читатели', _stats?.readers ?? 0, Icons.badge_outlined),
                          _stat('Активные выдачи', _stats?.activeLoans ?? 0, Icons.swap_horiz),
                          _stat('Просрочено', _stats?.overdueLoans ?? 0, Icons.warning_amber),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.go('/books'),
                            icon: const Icon(Icons.menu_book),
                            label: const Text('Книги'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/authors'),
                            icon: const Icon(Icons.people_alt_outlined),
                            label: const Text('Авторы'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/genres'),
                            icon: const Icon(Icons.category_outlined),
                            label: const Text('Жанры'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/publishers'),
                            icon: const Icon(Icons.business_outlined),
                            label: const Text('Издательства'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/readers'),
                            icon: const Icon(Icons.badge_outlined),
                            label: const Text('Читатели'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Управление пользователями и ролями',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'На узком экране пользователи отображаются карточками, '
                        'на широком — компактными строками.',
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 700;
                            return ListView.separated(
                              itemCount: _users.length,
                              separatorBuilder: (_, __) => compact
                                  ? const SizedBox(height: 8)
                                  : const Divider(),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return compact
                                    ? _userCard(user)
                                    : _userRow(user);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _userCard(AppUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user.fullName} (${user.username})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(user.email, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            _roleDropdown(user, double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _userRow(AppUser user) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          user.username.isEmpty ? '?' : user.username.substring(0, 1).toUpperCase(),
        ),
      ),
      title: Text(
        '${user.fullName} (${user.username})',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(user.email, overflow: TextOverflow.ellipsis),
      trailing: _roleDropdown(user, 190),
    );
  }

  Widget _roleDropdown(AppUser user, double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: user.role,
        decoration: const InputDecoration(
          labelText: 'Роль',
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: 'reader', child: Text('Читатель')),
          DropdownMenuItem(value: 'librarian', child: Text('Библиотекарь')),
          DropdownMenuItem(value: 'admin', child: Text('Администратор')),
        ],
        onChanged: _changingUserId == user.id ||
                user.id == widget.services.auth.user?.id
            ? null
            : (value) {
                if (value != null && value != user.role) {
                  _changeRole(user, value);
                }
              },
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
