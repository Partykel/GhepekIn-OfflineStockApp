import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/database/db_helper.dart';

class ReportDetailScreen extends StatefulWidget {
  final String period;
  final String date;
  final String? label;

  const ReportDetailScreen({
    super.key,
    required this.period,
    required this.date,
    this.label,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<Map<String, dynamic>> _futureData;

  DateTime get _baseDate {
    try {
      return DateTime.parse(widget.date);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  void initState() {
    super.initState();
    _futureData = _fetchReportData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildTitle()),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
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
          final trendData = data['trend'] as List<Map<String, dynamic>>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(income, expense, profit),
                if (widget.period != 'harian' && trendData.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildTrendChart(trendData),
                ],
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
    switch (widget.period) {
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

  Widget _buildTrendChart(List<Map<String, dynamic>> trendData) {
    final isWeekly = widget.period == 'mingguan';
    double maxY = 1000;
    for (final d in trendData) {
      final income = (d['income'] as num).toDouble();
      if (income > maxY) maxY = income;
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < trendData.length; i++) {
      final income = (trendData[i]['income'] as num).toDouble();
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: income,
            color: income > 0
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            width: isWeekly ? 20 : 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWeekly ? 'Tren Pemasukan Per Hari' : 'Tren Pemasukan Per Minggu',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  barGroups: barGroups,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= trendData.length) return const SizedBox();
                          final label = trendData[idx]['label'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(double income, double expense, double profit) {
    final displayDate = widget.label ?? DateFormatter.formatFull(_baseDate);
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
              displayDate,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
    final title = _buildTransactionTitle(trx);
    final subtitle = _buildTransactionSubtitle(trx, title);

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
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            Text(
              DateFormatter.formatDateTime(createdAt),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
    const map = {'stok': 'Beli Stok', 'operasional': 'Operasional', 'lainnya': 'Lainnya'};
    return map[category] ?? 'Pengeluaran';
  }

  String _buildTransactionTitle(Map<String, dynamic> trx) {
    final isIncome = trx['type'] == 'income';
    final itemSummary = _summarizeItemNames(trx['item_names'] as String?);

    if (isIncome) {
      return itemSummary ?? 'Penjualan';
    }

    if (trx['category'] == 'stok') {
      return itemSummary ?? 'Beli Stok';
    }

    final note = (trx['note'] as String?)?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }

    return _getCategoryLabel(trx['category'] as String?);
  }

  String _buildTransactionSubtitle(
    Map<String, dynamic> trx,
    String title,
  ) {
    final isIncome = trx['type'] == 'income';
    final typeLabel = isIncome
        ? 'Penjualan'
        : _getCategoryLabel(trx['category'] as String?);

    if (title == typeLabel) {
      return '';
    }

    return typeLabel;
  }

  String? _summarizeItemNames(String? rawNames) {
    if (rawNames == null || rawNames.trim().isEmpty) return null;

    final uniqueNames = LinkedHashSet<String>.from(
      rawNames
          .split(',')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty),
    ).toList();

    if (uniqueNames.isEmpty) return null;
    if (uniqueNames.length == 1) return uniqueNames.first;

    return '${uniqueNames.first} +${uniqueNames.length - 1} lainnya';
  }

  Future<Map<String, dynamic>> _fetchReportData() async {
    final db = await DbHelper().database;
    final dateRange = _getDateRange();
    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.quantity * ti.price_at_sale), 0) as total
      FROM transactions t
      JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.type = 'income' AND DATE(t.created_at) BETWEEN ? AND ?
    ''', [startDate, endDate]);

    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.price_at_sale), 0) as total
      FROM transactions t
      JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.type = 'expense' AND DATE(t.created_at) BETWEEN ? AND ?
    ''', [startDate, endDate]);

    final transactions = await db.rawQuery('''
      SELECT t.id, t.type, t.category, t.note, t.created_at,
        COALESCE(SUM(
          CASE WHEN t.type = 'income' THEN ti.quantity * ti.price_at_sale
               ELSE ti.price_at_sale END
        ), 0) as amount,
        (
          SELECT GROUP_CONCAT(item_name)
          FROM (
            SELECT DISTINCT p1.name as item_name
            FROM transaction_items ti1
            LEFT JOIN products p1 ON p1.id = ti1.product_id
            WHERE ti1.transaction_id = t.id
              AND p1.name IS NOT NULL

            UNION

            SELECT DISTINCT p2.name as item_name
            FROM stock_adjustments sa
            LEFT JOIN products p2 ON p2.id = sa.product_id
            WHERE sa.transaction_id = t.id
              AND sa.reason = 'restock'
              AND p2.name IS NOT NULL
          )
        ) as item_names
      FROM transactions t
      LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE DATE(t.created_at) BETWEEN ? AND ?
      GROUP BY t.id ORDER BY t.created_at DESC
    ''', [startDate, endDate]);

    List<Map<String, dynamic>> trend = [];
    final baseDate = _baseDate;

    if (widget.period == 'mingguan') {
      for (int i = 6; i >= 0; i--) {
        final day = baseDate.subtract(Duration(days: i));
        final ds = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final r = await db.rawQuery('''
          SELECT COALESCE(SUM(ti.quantity * ti.price_at_sale), 0) as income
          FROM transactions t
          JOIN transaction_items ti ON ti.transaction_id = t.id
          WHERE t.type = 'income' AND DATE(t.created_at) = ?
        ''', [ds]);
        trend.add({'label': DateFormatter.formatShortDay(day), 'income': r.first['income']});
      }
    } else if (widget.period == 'bulanan') {
      for (int week = 0; week < 4; week++) {
        final wStart = DateTime(baseDate.year, baseDate.month, 1 + week * 7);
        final wEnd = week == 3
            ? DateTime(baseDate.year, baseDate.month + 1, 0)
            : DateTime(baseDate.year, baseDate.month, 7 + week * 7);
        final ws = '${wStart.year}-${wStart.month.toString().padLeft(2, '0')}-${wStart.day.toString().padLeft(2, '0')}';
        final we = '${wEnd.year}-${wEnd.month.toString().padLeft(2, '0')}-${wEnd.day.toString().padLeft(2, '0')}';
        final r = await db.rawQuery('''
          SELECT COALESCE(SUM(ti.quantity * ti.price_at_sale), 0) as income
          FROM transactions t
          JOIN transaction_items ti ON ti.transaction_id = t.id
          WHERE t.type = 'income' AND DATE(t.created_at) BETWEEN ? AND ?
        ''', [ws, we]);
        trend.add({'label': 'Mg ${week + 1}', 'income': r.first['income']});
      }
    }

    return {
      'income': incomeResult.first['total'],
      'expense': expenseResult.first['total'],
      'transactions': transactions.cast<Map<String, dynamic>>(),
      'trend': trend,
    };
  }

  Map<String, String> _getDateRange() {
    final baseDate = _baseDate;

    switch (widget.period) {
      case 'mingguan':
        final start = baseDate.subtract(const Duration(days: 6));
        return {
          'start': '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
          'end': '${baseDate.year}-${baseDate.month.toString().padLeft(2, '0')}-${baseDate.day.toString().padLeft(2, '0')}',
        };
      case 'bulanan':
        final lastDay = DateTime(baseDate.year, baseDate.month + 1, 0).day;
        return {
          'start': '${baseDate.year}-${baseDate.month.toString().padLeft(2, '0')}-01',
          'end': '${baseDate.year}-${baseDate.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}',
        };
      default:
        return {'start': widget.date, 'end': widget.date};
    }
  }
}
