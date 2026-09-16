import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ypdart_pr6/widgets/common.dart';

void main() {
  testWidgets('состояние загрузки показывает индикатор', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoadingView())),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Загрузка'), findsOneWidget);
  });

  testWidgets('пустой результат показывает понятное сообщение', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyView())),
    );

    expect(find.textContaining('ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('экран ошибки содержит кнопку повтора', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Сервер недоступен',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Сервер недоступен'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
  });
}
