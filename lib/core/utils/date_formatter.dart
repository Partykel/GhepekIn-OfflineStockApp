import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _fullDate = DateFormat('d MMMM y', 'id_ID');
  static final DateFormat _shortDate = DateFormat('d MMM y', 'id_ID');
  static final DateFormat _dateTime = DateFormat('d MMM y HH:mm', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM y', 'id_ID');
  static final DateFormat _shortDay = DateFormat('E', 'id_ID');

  static String formatFull(DateTime date) => _fullDate.format(date);
  static String formatShort(DateTime date) => _shortDate.format(date);
  static String formatDateTime(DateTime date) => _dateTime.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  static String formatShortDay(DateTime date) {
    return _shortDay.format(date).substring(0, 3);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hari ini';

    final yesterday = today.subtract(const Duration(days: 1));
    if (dateOnly == yesterday) return 'Kemarin';

    return _shortDate.format(date);
  }
}
