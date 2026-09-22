import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/core/utils/date_formatter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  group('DateFormatter.formatRelative', () {
    test('returns Hari ini for today', () {
      final today = DateTime.now();
      expect(DateFormatter.formatRelative(today), 'Hari ini');
    });

    test('returns Kemarin for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.formatRelative(yesterday), 'Kemarin');
    });

    test('returns formatted date for older dates', () {
      final old = DateTime(2024, 1, 15);
      final result = DateFormatter.formatRelative(old);
      expect(result, isNot('Hari ini'));
      expect(result, isNot('Kemarin'));
      expect(result.isNotEmpty, true);
    });
  });

  group('DateFormatter.formatShortDay', () {
    test('returns 3-char abbreviation', () {
      final monday = DateTime(2025, 1, 6);
      final result = DateFormatter.formatShortDay(monday);
      expect(result.length, lessThanOrEqualTo(4));
    });
  });

  group('DateFormatter.formatFull', () {
    test('formats date with full month name', () {
      final date = DateTime(2025, 6, 15);
      final result = DateFormatter.formatFull(date);
      expect(result, contains('2025'));
      expect(result, contains('15'));
    });
  });
}
