// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filtered = _filterType == 'all'
                    ? transactions
                    : transactions.where((t) => t.type == _filterType).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada transaksi',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(filtered[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => EmptyState(
                title: 'Gagal memuat transaksi',
                subtitle: error.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('all', 'Semua'),
          const SizedBox(width: 8),
          _buildFilterChip('income', 'Pemasukan'),
          const SizedBox(width: 8),
          _buildFilterChip('expense', 'Pengeluaran'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filterType = value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.isIncome;

    return FutureBuilder<double>(
      future: _getTransactionAmount(transaction.id!),
      builder: (context, snapshot) {
        final amount = snapshot.data ?? 0.0;

        return Dismissible(
          key: ValueKey(transaction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Hapus Transaksi?'),
                content: const Text(
                  'Transaksi ini akan dihapus secara permanen.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(AppStrings.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    child: const Text(AppStrings.delete),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            await ref.read(transactionRepositoryProvider).deleteTransaction(transaction.id!);
            ref.invalidate(transactionHistoryProvider);
            ref.invalidate(todayStatsProvider);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.deleteSuccess)),
            );
          },
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isIncome
                    ? AppColors.secondary.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                child: Icon(
                  isIncome ? Icons.trending_up : Icons.trending_down,
                  color: isIncome ? AppColors.secondary : AppColors.danger,
                ),
              ),
              title: Text(
                _getTransactionTitle(transaction),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (transaction.category != null)
                    Text(
                      transaction.category!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDateTime(transaction.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              trailing: Text(
                CurrencyFormatter.format(amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.secondary : AppColors.danger,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<double> _getTransactionAmount(int transactionId) async {
    final details = await ref
        .read(transactionRepositoryProvider)
        .getTransactionDetails(transactionId);
    if (details.isEmpty) return 0.0;
    // FIX BUG #3: Harus quantity × price_at_sale, bukan hanya price_at_sale
    return details.fold<double>(
      0.0,
      (sum, item) =>
          sum +
          ((item['quantity'] as num).toDouble() *
              (item['price_at_sale'] as num).toDouble()),
    );
  }

  String _getTransactionTitle(Transaction transaction) {
    if (transaction.isIncome) {
      return 'Penjualan';
    }
    final categoryMap = {
      'stok': 'Beli Stok',
      'operasional': 'Operasional',
      'lainnya': 'Lainnya',
    };
    return categoryMap[transaction.category] ?? 'Pengeluaran';
  }
}
