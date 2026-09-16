import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ypdart_pr6/core/roles.dart';
import 'package:ypdart_pr6/widgets/responsive.dart';

void main() {
  testWidgets('на узком экране выбираются карточки', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveEntityLayout(
            cards: Text('Карточки'),
            table: Text('Таблица'),
          ),
        ),
      ),
    );

    expect(find.text('Карточки'), findsOneWidget);
    expect(find.text('Таблица'), findsNothing);
  });

  testWidgets('на широком экране выбирается таблица', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveEntityLayout(
            cards: Text('Карточки'),
            table: Text('Таблица'),
          ),
        ),
      ),
    );

    expect(find.text('Таблица'), findsOneWidget);
    expect(find.text('Карточки'), findsNothing);
  });

  testWidgets('недоступный элемент скрывается для reader', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoleVisibility(
            currentRole: AppRole.reader,
            requiredRole: AppRole.admin,
            child: Text('Удалить физически'),
          ),
        ),
      ),
    );

    expect(find.text('Удалить физически'), findsNothing);
  });
}
