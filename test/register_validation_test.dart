import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ypdart_pr6/core/auth_controller.dart';
import 'package:ypdart_pr6/core/services.dart';
import 'package:ypdart_pr6/screens/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('форма регистрации не принимает пустые обязательные поля',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthController(prefs);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api'));
    final services = AppServices.forTest(auth, dio);

    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(services: services)),
    );

    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pump();

    expect(find.text('Обязательное поле'), findsWidgets);
    expect(find.text('Введите пароль'), findsOneWidget);

    auth.dispose();
  });
}
