import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('formats zero correctly', () {
      expect(CurrencyFormatter.format(0), contains('Rp'));
      expect(CurrencyFormatter.format(0), contains('0'));
    });

    test('formats thousands with separator', () {
      final result = CurrencyFormatter.format(10000);
      expect(result, contains('Rp'));
      expect(result, contains('10'));
    });

    test('formats millions correctly', () {
      final result = CurrencyFormatter.format(1500000);
      expect(result, contains('Rp'));
      expect(result, contains('1'));
    });

    test('no decimal digits for whole numbers', () {
      final result = CurrencyFormatter.format(15000);
      expect(result.contains(','), false);
    });

    test('formatInt gives same result as format for whole numbers', () {
      expect(CurrencyFormatter.formatInt(20000), CurrencyFormatter.format(20000));
    });
  });
}
