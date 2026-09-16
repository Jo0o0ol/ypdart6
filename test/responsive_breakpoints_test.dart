import 'package:flutter_test/flutter_test.dart';
import 'package:ypdart_pr6/widgets/responsive.dart';

void main() {
  test('360 относится к compact', () {
    expect(widthClassFor(360), AppWidthClass.compact);
  });

  test('768 относится к medium', () {
    expect(widthClassFor(768), AppWidthClass.medium);
  });

  test('1280 относится к wide', () {
    expect(widthClassFor(1280), AppWidthClass.wide);
  });

  test('1920 относится к ultraWide', () {
    expect(widthClassFor(1920), AppWidthClass.ultraWide);
  });
}
