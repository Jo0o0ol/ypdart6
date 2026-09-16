import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_exceptions.dart';
import '../core/roles.dart';
import '../core/services.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.services});
  final AppServices services;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  Map<String, String> _serverErrors = <String, String>{};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_passwordChanged);
  }

  void _passwordChanged() => setState(() {});

  @override
  void dispose() {
    _password.removeListener(_passwordChanged);
    _username.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    final server = _serverErrors[field];
    if (server != null) return server;
    if (value == null || value.trim().isEmpty) return 'Обязательное поле';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = <String, String>{});
    if (!_formKey.currentState!.validate()) return;
    if (!PasswordRules(_password.text).isValid) return;

    setState(() => _loading = true);
    try {
      await widget.services.auth.register(
        username: _username.text,
        password: _password.text,
        email: _email.text,
        fullName: _fullName.text,
      );
      if (!mounted) return;
      context.go('/login?registered=1');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ok ? Colors.green : null,
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = PasswordRules(_password.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека')),
      body: SingleChildScrollView(
        child: PageFrame(
        maxWidth: 620,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Регистрация читателя',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(labelText: 'Логин'),
                      validator: (value) => _required(value, 'username'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _fullName,
                      decoration: const InputDecoration(labelText: 'ФИО'),
                      validator: (value) => _required(value, 'fullName'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (value) {
                        final required = _required(value, 'email');
                        if (required != null) return required;
                        final text = value!.trim();
                        if (!text.contains('@') || !text.contains('.')) {
                          return 'Некорректный e-mail';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Пароль'),
                      validator: (value) {
                        final server = _serverErrors['password'];
                        if (server != null) return server;
                        if (value == null || value.isEmpty) return 'Введите пароль';
                        if (!PasswordRules(value).isValid) {
                          return 'Пароль не соответствует требованиям';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _rule('не менее 8 символов', rules.hasMinLength),
                          _rule('есть хотя бы одна цифра', rules.hasDigit),
                          _rule('есть специальный символ', rules.hasSpecial),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Повторите пароль'),
                      validator: (value) => value != _password.text
                          ? 'Пароли не совпадают'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Зарегистрироваться'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Уже есть аккаунт? Войти'),
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
