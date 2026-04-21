import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transaction/providers/transaction_provider.dart';

final reportDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final trend = await ref.read(sevenDayTrendProvider.future);

  double totalIncome = 0;
  double totalExpense = 0;

  for (final day in trend) {
    totalIncome += (day['income'] as num).toDouble();
    totalExpense += (day['expense'] as num).toDouble();
  }

  return {
    'income': totalIncome,
    'expense': totalExpense,
    'profit': totalIncome - totalExpense,
    'dailyData': trend,
  };
});
