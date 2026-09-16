import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../core/roles.dart';
import '../core/services.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

class SecurityDemoScreen extends StatefulWidget {
  const SecurityDemoScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<SecurityDemoScreen> createState() => _SecurityDemoScreenState();
}

class _SecurityDemoScreenState extends State<SecurityDemoScreen> {
  String? _result;
  bool _working = false;

  Future<void> _reloadUiRole() async {
    await widget.services.auth.reloadUiRoleFromStorage();
    if (!mounted) return;
    setState(() {
      _result = 'UI-роль перечитана из localStorage.';
    });
  }

  Future<void> _resetUiRole() async {
    await widget.services.auth.resetUiRoleFromServer();
    if (!mounted) return;
    setState(() {
      _result = 'UI-роль снова совпадает с ролью сервера.';
    });
  }

  Future<void> _adminRequest() async {
    setState(() {
      _working = true;
      _result = null;
    });
    try {
      final stats = await widget.services.admin.stats();
      if (!mounted) return;
      setState(() {
        _result = 'Сервер разрешил admin-запрос. Книг: ${stats.books}.';
      });
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() {
        _result = 'Сервер ответил 403: ${e.message}';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _result = e.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        services: widget.services,
        title: 'Проверка защиты',
      ),
      body: AnimatedBuilder(
        animation: widget.services.auth,
        builder: (context, _) {
          final serverRole = widget.services.auth.serverRole;
          final uiRole = widget.services.auth.uiRole;
          return PageFrame(
            maxWidth: 850,
            child: ListView(
              children: [
                Text(
                  'Клиентская роль и настоящая серверная защита',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Роль от сервера: ${serverRole?.title ?? '—'}'),
                        Text('Роль для интерфейса: ${uiRole?.title ?? '—'}'),
                        const SizedBox(height: 8),
                        const SelectableText(
                          'SharedPreferences key: auth_ui_role\n'
                          'В Chrome localStorage обычно отображается как: flutter.auth_ui_role',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Для пункта 17 войдите как reader, откройте DevTools → '
                  'Application → Local Storage, замените значение UI-роли на admin, '
                  'затем нажмите кнопку ниже. Интерфейс изменится, но access token '
                  'останется токеном читателя.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _reloadUiRole,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Перечитать UI-роль из localStorage'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _resetUiRole,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Вернуть роль сервера'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                RoleVisibility(
                  currentRole: uiRole,
                  requiredRole: AppRole.admin,
                  replacement: const Text(
                    'Admin-кнопка скрыта текущей UI-ролью.',
                    textAlign: TextAlign.center,
                  ),
                  child: FilledButton.icon(
                    onPressed: _working ? null : _adminRequest,
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Выполнить admin-запрос к /api/admin/stats'),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _result!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _result!.contains('403')
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
