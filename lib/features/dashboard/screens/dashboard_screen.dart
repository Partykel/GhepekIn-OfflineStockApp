// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/summary_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transaction/providers/transaction_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  // Simpan tanggal terakhir kali dashboard aktif
  DateTime _lastActiveDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastActiveDate = _today();
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

  // Dipanggil otomatis saat app kembali ke foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _today();
      // Kalau tanggal sudah ganti sejak terakhir buka, refresh semua data
      if (today.isAfter(_lastActiveDate)) {
        _lastActiveDate = today;
        _refreshAll();
      }
    }
  }

  void _refreshAll() {
    ref.invalidate(todayStatsProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(sevenDayTrendProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(todayStatsProvider);
    final topProductsAsync = ref.watch(topProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => context.push('/products'),
            tooltip: 'Manajemen Produk',
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
          ref.invalidate(todayStatsProvider);
          ref.invalidate(topProductsProvider);
          ref.invalidate(sevenDayTrendProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCards(statsAsync),
              const SizedBox(height: 24),
              _buildTopProducts(topProductsAsync),
            ],
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
              color: (stats['profit'] ?? 0) >= 0 ? AppColors.secondary : AppColors.danger,
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

  Widget _buildTopProducts(AsyncValue<List<Map<String, dynamic>>> productsAsync) {
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(product['name'] ?? 'Unknown'),
                    trailing: Text(
                      '${product['total_sold']} terjual',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }
}
