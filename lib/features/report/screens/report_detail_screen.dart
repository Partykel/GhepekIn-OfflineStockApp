import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/database/db_helper.dart';

class ReportDetailScreen extends ConsumerWidget {
  final String period;
  final String date;

  const ReportDetailScreen({
    super.key,
    required this.period,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildTitle()),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchReportData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              title: 'Gagal memuat laporan',
              subtitle: snapshot.error.toString(),
              icon: Icons.error_outline,
            );
          }

          final data = snapshot.data!;
          final income = (data['income'] as num).toDouble();
          final expense = (data['expense'] as num).toDouble();
          final profit = income - expense;
          final transactions = data['transactions'] as List<Map<String, dynamic>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(income, expense, profit, context),
                const SizedBox(height: 24),
                const Text(
                  'Detail Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  const EmptyState(
                    title: 'Tidak ada transaksi pada periode ini',
                    icon: Icons.receipt_long_outlined,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildTransactionTile(transactions[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _buildTitle() {
    switch (period) {
      case 'harian':
        return 'Laporan Harian';
      case 'mingguan':
        return 'Laporan Mingguan';
      case 'bulanan':
        return 'Laporan Bulanan';
      default:
        return 'Detail Laporan';
    }
  }

  Widget _buildSummarySection(
    double income,
    double expense,
    double profit,
    BuildContext context,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Pemasukan', income, AppColors.secondary),
            const SizedBox(height: 8),
            _buildSummaryRow('Pengeluaran', expense, AppColors.danger),
            const Divider(height: 24),
            _buildSummaryRow(
              'Laba Bersih',
              profit,
              profit >= 0 ? AppColors.secondary : AppColors.danger,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> trx) {
    final isIncome = trx['type'] == 'income';
    final amount = (trx['amount'] as num).toDouble();
    final createdAt = DateTime.parse(trx['created_at'] as String);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? AppColors.secondary.withValues(alpha: 0.1)
              : AppColors.danger.withValues(alpha: 0.1),
          child: Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            color: isIncome ? AppColors.secondary : AppColors.danger,
            size: 20,
          ),
        ),
        title: Text(
          isIncome ? 'Penjualan' : _getCategoryLabel(trx['category'] as String?),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (trx['note'] != null && (trx['note'] as String).isNotEmpty)
              Text(
                trx['note'] as String,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            Text(
              DateFormatter.formatDateTime(createdAt),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? AppColors.secondary : AppColors.danger,
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'stok':
        return 'Beli Stok';
      case 'operasional':
        return 'Operasional';
      case 'lainnya':
        return 'Lainnya';
      default:
        return 'Pengeluaran';
    }
  }

  Future<Map<String, dynamic>> _fetchReportData() async {
    final db = await DbHelper().database;

    // Tentukan rentang tanggal berdasarkan period
    final dateRange = _getDateRange();
    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

    // Hitung total income
    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.quantity * ti.price_at_sale), 0) as total
      FROM transactions t
      JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.type = 'income'
        AND DATE(t.created_at) BETWEEN ? AND ?
    ''', [startDate, endDate]);

    // Hitung total expense
    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.price_at_sale), 0) as total
      FROM transactions t
      JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.type = 'expense'
        AND DATE(t.created_at) BETWEEN ? AND ?
    ''', [startDate, endDate]);

    // Ambil semua transaksi beserta totalnya
    final transactions = await db.rawQuery('''
      SELECT 
        t.id,
        t.type,
        t.category,
        t.note,
        t.created_at,
        COALESCE(SUM(
          CASE WHEN t.type = 'income' 
               THEN ti.quantity * ti.price_at_sale 
               ELSE ti.price_at_sale 
          END
        ), 0) as amount
      FROM transactions t
      LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE DATE(t.created_at) BETWEEN ? AND ?
      GROUP BY t.id
      ORDER BY t.created_at DESC
    ''', [startDate, endDate]);

    return {
      'income': incomeResult.first['total'],
      'expense': expenseResult.first['total'],
      'transactions': transactions.cast<Map<String, dynamic>>(),
    };
  }

  Map<String, String> _getDateRange() {
    final now = DateTime.now();

    switch (period) {
      case 'mingguan':
        // 7 hari terakhir
        final start = now.subtract(const Duration(days: 6));
        return {
          'start': '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
          'end': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        };
      case 'bulanan':
        // Bulan ini
        return {
          'start': '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
          'end': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        };
      default:
        // Harian — parse dari string date yang dikirim
        // Coba extract tanggal dari date string (misal "hari_ini", "kemarin", atau full date)
        DateTime target = now;
        if (date == 'kemarin') {
          target = now.subtract(const Duration(days: 1));
        }
        final dateStr = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
        return {'start': dateStr, 'end': dateStr};
    }
  }
}
