import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/services.dart';
import 'router.dart';
import 'widgets/session_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final services = await AppServices.create();
  runApp(LibraryAdaptiveApp(services: services));
}

class LibraryAdaptiveApp extends StatefulWidget {
  const LibraryAdaptiveApp({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  State<LibraryAdaptiveApp> createState() => _LibraryAdaptiveAppState();
}

class _LibraryAdaptiveAppState extends State<LibraryAdaptiveApp> {
  late final router = buildRouter(widget.services);

  @override
  void dispose() {
    router.dispose();
    widget.services.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Система управления библиотекой — адаптивная версия',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      routerConfig: router,
      builder: (context, child) {
        // ВАЖНО: Navigator GoRouter больше не перестраивается между разными
        // родителями при смене роли/ширины. Адаптивная навигация находится
        // внутри ShellRoute в router.dart.
        return SessionWatcher(
          services: widget.services,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
