import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../core/services.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.services.auth.login(
        _username.text.trim(),
        _password.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = widget.services.auth.lastLogoutMessage;
    final registered = GoRouterState.of(context).uri.queryParameters['registered'] == '1';

    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека')),
      body: SingleChildScrollView(
        child: PageFrame(
        maxWidth: 520,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_library_outlined, size: 58),
                    const SizedBox(height: 10),
                    Text(
                      'Вход в библиотеку',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 18),
                    if (registered)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Регистрация выполнена. Теперь войдите в систему.',
                          style: TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (reason != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          reason,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Логин',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Введите логин'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: Icon(Icons.password),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Введите пароль'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: const Text('Войти'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Нет аккаунта? Зарегистрироваться'),
                    ),
                    const Divider(height: 26),
                    const Text(
                      'Проверка ролей:\nreader / reader123\nlibrarian / librarian123\nadmin / admin123',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
