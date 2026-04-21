import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction.dart';
import '../../product/providers/product_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_formatter.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final todayStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final income = await repository.getTodayIncome();
  final expense = await repository.getTodayExpense();
  return {
    'income': income,
    'expense': expense,
    'profit': income - expense,
  };
});

final topProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(transactionRepositoryProvider).getTopProductsToday(limit: 3);
});

final transactionHistoryProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  return repository.getHistory();
});

final sevenDayTrendProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(transactionRepositoryProvider).getSevenDayTrend();
});

// FIX BUG #1: build() tidak boleh throw — kembalikan Transaction dummy sebagai placeholder.
// State ini tidak dikonsumsi di UI manapun; provider ini hanya dipakai via .notifier.call().
class AddSaleNotifier extends Notifier<Transaction?> {
  @override
  Transaction? build() => null;

  Future<Transaction> call({
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    final repository = ref.read(transactionRepositoryProvider);
    final transaction = await repository.createSale(items: items, note: note);

    // FIX BUG #4: Trigger notifikasi stok menipis setelah penjualan
    await _checkAndNotifyLowStock(items);

    ref.invalidate(todayStatsProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(sevenDayTrendProvider);
    ref.invalidate(allProductsProvider);

    state = transaction;
    return transaction;
  }

  Future<void> _checkAndNotifyLowStock(List<Map<String, dynamic>> items) async {
    final productRepo = ref.read(productRepositoryProvider);
    final notificationService = NotificationService();
    final today = DateTime.now();

    for (final item in items) {
      final productId = item['product_id'] as int;
      final product = await productRepo.getById(productId);
      if (product == null) continue;

      if (product.stock <= product.minStock) {
        final lastNotified = product.lastNotifiedAt;
        final alreadyNotifiedToday = lastNotified != null &&
            lastNotified.year == today.year &&
            lastNotified.month == today.month &&
            lastNotified.day == today.day;

        if (!alreadyNotifiedToday) {
          await notificationService.showStockAlert(product.name, product.stock);
          await productRepo.updateLastNotifiedAt(productId);
        }
      }
    }
  }
}

final addSaleProvider = NotifierProvider<AddSaleNotifier, Transaction?>(() {
  return AddSaleNotifier();
});

// FIX BUG #1: sama seperti AddSaleNotifier
class AddExpenseNotifier extends Notifier<Transaction?> {
  @override
  Transaction? build() => null;

  Future<Transaction> call({
    required double amount,
    required String category,
    String? note,
    List<Map<String, dynamic>>? restockItems,
  }) async {
    final repository = ref.read(transactionRepositoryProvider);
    final transaction = await repository.createExpense(
      amount: amount,
      category: category,
      note: note,
      restockItems: restockItems,
    );

    // FIX BUG #4: Trigger notifikasi defisit setelah pengeluaran
    await _checkAndNotifyDeficit();

    ref.invalidate(todayStatsProvider);
    ref.invalidate(sevenDayTrendProvider);
    if (restockItems != null && restockItems.isNotEmpty) {
      ref.invalidate(allProductsProvider);
    }

    state = transaction;
    return transaction;
  }

  Future<void> _checkAndNotifyDeficit() async {
    final repo = ref.read(transactionRepositoryProvider);
    final income = await repo.getTodayIncome();
    final expense = await repo.getTodayExpense();

    if (expense > income) {
      await NotificationService().showDeficitAlert(
        DateFormatter.formatFull(DateTime.now()),
        expense - income,
      );
    }
  }
}

final addExpenseProvider = NotifierProvider<AddExpenseNotifier, Transaction?>(() {
  return AddExpenseNotifier();
});
