import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/summary_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/services/notification_service.dart';
import '../../product/providers/product_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  DateTime _lastActiveDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActiveDate = _today();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSendLowStockNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _today();
      if (today.isAfter(_lastActiveDate)) {
        _lastActiveDate = today;
        _refreshAll();
      }
      _checkAndSendLowStockNotifications();
    }
  }

  void _refreshAll() {
    ref.invalidate(todayStatsProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(sevenDayTrendProvider);
    ref.invalidate(lowStockProductsProvider);
  }

  Future<void> _checkAndSendLowStockNotifications() async {
    try {
      final lowProducts = await ref.read(productRepositoryProvider).getLowStockProducts();
      final today = DateTime.now();
      final notif = NotificationService();
      for (final product in lowProducts) {
        final last = product.lastNotifiedAt;
        final alreadyToday = last != null &&
            last.year == today.year &&
            last.month == today.month &&
            last.day == today.day;
        if (!alreadyToday) {
          await notif.showStockAlert(
            product.name,
            product.stock,
            productId: product.id ?? 0,
          );
          await ref.read(productRepositoryProvider).updateLastNotifiedAt(product.id!);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(todayStatsProvider);
    final topProductsAsync = ref.watch(topProductsProvider);
    final trendAsync = ref.watch(sevenDayTrendProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    final lowStockCount = lowStockAsync.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => context.push('/products'),
            tooltip: 'Kelola Produk',
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.inventory_2_rounded),
                onPressed: () => context.push('/low-stock'),
                tooltip: 'Monitor Stok',
              ),
              if (lowStockCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      lowStockCount > 99 ? '99+' : '$lowStockCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/transactions'),
            tooltip: 'Riwayat Transaksi',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/reports'),
            tooltip: 'Laporan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAll();
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.pageTopTint,
                AppColors.background,
                AppColors.pageBottomTint,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.35, 1],
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeBanner(lowStockCount),
                const SizedBox(height: 24),
                _buildStatsCards(statsAsync),
                const SizedBox(height: 24),
                _buildTrendChart(trendAsync),
                const SizedBox(height: 24),
                _buildTopProducts(topProductsAsync),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'expense',
            onPressed: () => context.push('/expense/new'),
            icon: const Icon(Icons.money_off),
            label: const Text('Pengeluaran'),
            backgroundColor: AppColors.danger,
          ),
          const SizedBox(width: 8),
          FloatingActionButton.extended(
            heroTag: 'sale',
            onPressed: () => context.push('/sale/new'),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Penjualan'),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(int lowStockCount) {
    final today = DateFormatter.formatFull(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B5CE2),
            Color(0xFF14B8A6),
            Color(0xFFFF8A3D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              today,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kasir harian yang lebih hidup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lowStockCount > 0
                ? '$lowStockCount produk perlu perhatian. Semua data penjualan, stok, dan laporan siap dipakai hari ini.'
                : 'Semua area utama siap dipakai. Catat transaksi, cek stok, dan pantau usaha tanpa ribet.',
            style: const TextStyle(
              color: Color(0xFFF8FAFF),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AsyncValue<Map<String, double>> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: AppStrings.income,
                    value: CurrencyFormatter.format(stats['income'] ?? 0),
                    icon: Icons.trending_up,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: AppStrings.expense,
                    value: CurrencyFormatter.format(stats['expense'] ?? 0),
                    icon: Icons.trending_down,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: AppStrings.profit,
              value: CurrencyFormatter.format(stats['profit'] ?? 0),
              icon: Icons.account_balance_wallet,
              color: (stats['profit'] ?? 0) >= 0
                  ? AppColors.secondary
                  : AppColors.danger,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => EmptyState(
        title: 'Gagal memuat data',
        subtitle: error.toString(),
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildTrendChart(AsyncValue<List<Map<String, dynamic>>> trendAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tren Pemasukan 7 Hari Terakhir',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            trendAsync.when(
              data: (data) {
                final now = DateTime.now();
                final Map<String, double> incomeMap = {};
                for (final d in data) {
                  incomeMap[d['date'] as String] =
                      (d['income'] as num).toDouble();
                }

                final List<BarChartGroupData> barGroups = [];
                double maxY = 1000;
                for (int i = 6; i >= 0; i--) {
                  final day = now.subtract(Duration(days: i));
                  final key =
                      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final income = incomeMap[key] ?? 0;
                  if (income > maxY) maxY = income;
                  barGroups.add(BarChartGroupData(
                    x: 6 - i,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: income > 0
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.2),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ));
                }

                if (barGroups.every((g) => g.barRods.first.toY == 0)) {
                  return const SizedBox(
                    height: 80,
                    child: Center(
                      child: Text(
                        'Belum ada data penjualan minggu ini',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return SizedBox(
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
                              final day = now.subtract(
                                  Duration(days: 6 - value.toInt()));
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormatter.formatShortDay(day),
                                  style: const TextStyle(
                                    fontSize: 10,
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
                );
              },
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(
      AsyncValue<List<Map<String, dynamic>>> productsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produk Terlaris Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return const EmptyState(
                title: 'Belum ada penjualan hari ini',
                icon: Icons.shopping_bag_outlined,
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(product['name'] as String? ?? 'Unknown'),
                    trailing: Text(
                      '${product['total_sold']} terjual',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => EmptyState(
            title: 'Gagal memuat produk terlaris',
            icon: Icons.error_outline,
          ),
        ),
      ],
    );
  }
}
