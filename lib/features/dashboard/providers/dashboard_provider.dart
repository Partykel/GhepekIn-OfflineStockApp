import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transaction/providers/transaction_provider.dart';

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final stats = await ref.read(todayStatsProvider.future);
  final topProducts = await ref.read(topProductsProvider.future);
  final trend = await ref.read(sevenDayTrendProvider.future);

  return {
    'income': stats['income'] ?? 0,
    'expense': stats['expense'] ?? 0,
    'profit': stats['profit'] ?? 0,
    'topProducts': topProducts,
    'trend': trend,
  };
});
