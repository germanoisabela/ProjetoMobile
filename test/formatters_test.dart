import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/core/utils/formatters.dart';

void main() {
  group('formatDecimal', () {
    test('usa vírgula e duas casas', () {
      expect(formatDecimal(12.5), '12,50');
      expect(formatDecimal(3), '3,00');
      expect(formatDecimal(0.333), '0,33');
    });
  });

  group('parseDecimal', () {
    test('aceita vírgula e ponto', () {
      expect(parseDecimal('3,5'), 3.5);
      expect(parseDecimal('3.5'), 3.5);
    });

    test('ignora espaços nas pontas', () {
      expect(parseDecimal('  4,2  '), 4.2);
    });

    test('devolve null para texto inválido ou vazio', () {
      expect(parseDecimal('abc'), isNull);
      expect(parseDecimal(''), isNull);
      expect(parseDecimal(null), isNull);
    });
  });
}
