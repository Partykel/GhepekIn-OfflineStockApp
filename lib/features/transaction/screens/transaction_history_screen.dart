
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../product/providers/product_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  String _filterType = 'all';
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pilih tanggal',
            onPressed: _pickDate,
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Hapus filter tanggal',
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildDateBanner(),
          _buildFilterChips(),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final filtered = transactions.where((t) {
                  final matchesType = _filterType == 'all' || t.type == _filterType;
                  final matchesDate = _selectedDate == null
                      ? true
                      : _isSameDate(t.createdAt, _selectedDate!);
                  return matchesType && matchesDate;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada transaksi',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
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

  Widget _buildDateBanner() {
    final label = _selectedDate == null
        ? 'Semua tanggal'
        : DateFormatter.formatFull(_selectedDate!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_selectedDate != null)
            TextButton(
              onPressed: () => setState(() => _selectedDate = null),
              child: const Text('Tampilkan semua'),
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

  Future<void> _pickDate() async {
    final initial = _selectedDate ?? DateTime.now();
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

    return FutureBuilder<_TransactionCardData>(
      future: _getTransactionCardData(transaction),
      builder: (context, snapshot) {
        final cardData = snapshot.data ??
            _TransactionCardData(
              amount: 0,
              title: _getTransactionTypeLabel(transaction),
              subtitle: _getTransactionTypeLabel(transaction),
            );

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
            ref.invalidate(sevenDayTrendProvider);
            if (transaction.isIncome ||
                (transaction.isExpense && transaction.category == 'stok')) {
              ref.invalidate(allProductsProvider);
              ref.invalidate(lowStockProductsProvider);
            }
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
                cardData.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (cardData.subtitle.isNotEmpty)
                    Text(
                      cardData.subtitle,
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
                CurrencyFormatter.format(cardData.amount),
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

  Future<_TransactionCardData> _getTransactionCardData(
    Transaction transaction,
  ) async {
    final details = await ref
        .read(transactionRepositoryProvider)
        .getTransactionDetails(transaction.id!);

    final amount = details.fold<double>(
      0.0,
      (sum, item) =>
          sum +
          ((item['quantity'] as num).toDouble() *
              (item['price_at_sale'] as num).toDouble()),
    );

    final title = _buildTransactionItemTitle(transaction, details);

    return _TransactionCardData(
      amount: amount,
      title: title,
      subtitle: _buildTransactionSubtitle(transaction, title),
    );
  }

  String _buildTransactionItemTitle(
    Transaction transaction,
    List<Map<String, dynamic>> details,
  ) {
    final itemSummary = _summarizeProductNames(details);

    if (transaction.isIncome) {
      return itemSummary ?? 'Penjualan';
    }

    if (transaction.category == 'stok') {
      return itemSummary ?? 'Beli Stok';
    }

    final note = transaction.note?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }

    return _getTransactionTypeLabel(transaction);
  }

  String _buildTransactionSubtitle(Transaction transaction, String title) {
    final typeLabel = _getTransactionTypeLabel(transaction);
    return title == typeLabel ? '' : typeLabel;
  }

  String _getTransactionTypeLabel(Transaction transaction) {
    const categoryMap = {
      'stok': 'Beli Stok',
      'operasional': 'Operasional',
      'lainnya': 'Lainnya',
    };

    if (transaction.isIncome) {
      return 'Penjualan';
    }

    return categoryMap[transaction.category] ?? 'Pengeluaran';
  }

  String? _summarizeProductNames(List<Map<String, dynamic>> details) {
    final uniqueNames = LinkedHashSet<String>.from(
      details
          .map((item) => (item['product_name'] as String?)?.trim())
          .whereType<String>()
          .where((name) => name.isNotEmpty),
    ).toList();

    if (uniqueNames.isEmpty) return null;
    if (uniqueNames.length == 1) return uniqueNames.first;

    return '${uniqueNames.first} +${uniqueNames.length - 1} lainnya';
  }
}

class _TransactionCardData {
  final double amount;
  final String title;
  final String subtitle;

  const _TransactionCardData({
    required this.amount,
    required this.title,
    required this.subtitle,
  });
}
