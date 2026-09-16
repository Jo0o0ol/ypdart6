import 'package:flutter_test/flutter_test.dart';
import 'package:ypdart_pr6/core/roles.dart';

void main() {
  test('корректный пароль проходит все требования', () {
    expect(PasswordRules('Password1!').isValid, isTrue);
  });

  test('пароль короче восьми символов не проходит', () {
    expect(PasswordRules('Ab1!').isValid, isFalse);
  });

  test('пароль без цифры не проходит', () {
    expect(PasswordRules('Password!').isValid, isFalse);
  });

  test('пароль без специального символа не проходит', () {
    expect(PasswordRules('Password1').isValid, isFalse);
  });
}
