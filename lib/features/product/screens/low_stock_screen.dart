import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../../../core/utils/currency_formatter.dart';

enum StockFilter { all, empty, low }
enum StockSort { nameAsc, nameDesc, stockAsc, stockDesc, statusAsc }

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
  StockFilter _filter = StockFilter.all;
  StockSort _sort = StockSort.statusAsc;

  List<Product> _applyFilterAndSort(List<Product> products) {
    List<Product> result;

    switch (_filter) {
      case StockFilter.empty:
        result = products.where((p) => p.stock <= 0).toList();
        break;
      case StockFilter.low:
        result = products.where((p) => p.stock > 0 && p.stock <= p.minStock).toList();
        break;
      case StockFilter.all:
        result = List.from(products);
        break;
    }

    switch (_sort) {
      case StockSort.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case StockSort.nameDesc:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case StockSort.stockAsc:
        result.sort((a, b) {
          final s = a.stock.compareTo(b.stock);
          return s != 0 ? s : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case StockSort.stockDesc:
        result.sort((a, b) {
          final s = b.stock.compareTo(a.stock);
          return s != 0 ? s : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case StockSort.statusAsc:
        result.sort((a, b) {
          int rank(Product p) => p.stock <= 0 ? 0 : p.stock <= p.minStock ? 1 : 2;
          final s = rank(a).compareTo(rank(b));
          return s != 0 ? s : a.stock.compareTo(b.stock);
        });
        break;
    }

    return result;
  }

  String get _sortLabel {
    switch (_sort) {
      case StockSort.nameAsc:    return 'Nama A→Z';
      case StockSort.nameDesc:   return 'Nama Z→A';
      case StockSort.stockAsc:   return 'Stok Terendah';
      case StockSort.stockDesc:  return 'Stok Tertinggi';
      case StockSort.statusAsc:  return 'Status Kritis';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProductsAsync = ref.watch(allProductsProvider);

    return allProductsAsync.when(
      data: (allProducts) {
        final lowStockProducts = allProducts
            .where((p) => p.stock <= 0 || p.stock <= p.minStock)
            .toList();
        final filtered = _applyFilterAndSort(lowStockProducts);

        final emptyCount = lowStockProducts.where((p) => p.stock <= 0).length;
        final lowCount = lowStockProducts.where((p) => p.stock > 0 && p.stock <= p.minStock).length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monitor Stok'),
                if (lowStockProducts.isNotEmpty)
                  Text(
                    '${lowStockProducts.length} produk perlu perhatian',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            actions: [
              PopupMenuButton<StockSort>(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Urutkan',
                onSelected: (s) => setState(() => _sort = s),
                itemBuilder: (_) => [
                  _sortItem(StockSort.statusAsc,  Icons.priority_high_rounded, 'Status Kritis Dulu'),
                  _sortItem(StockSort.stockAsc,   Icons.arrow_upward_rounded,  'Stok Terendah Dulu'),
                  _sortItem(StockSort.stockDesc,  Icons.arrow_downward_rounded,'Stok Tertinggi Dulu'),
                  _sortItem(StockSort.nameAsc,    Icons.sort_by_alpha_rounded, 'Nama A → Z'),
                  _sortItem(StockSort.nameDesc,   Icons.sort_by_alpha_rounded, 'Nama Z → A'),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(allProductsProvider),
              ),
            ],
          ),
          body: lowStockProducts.isEmpty
              ? _buildAllSafeState()
              : Column(
                  children: [
                    _buildSummaryBanner(emptyCount, lowCount),
                    _buildFilterBar(emptyCount, lowCount),
                    _buildSortChip(),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyFilter()
                          : RefreshIndicator(
                              onRefresh: () async => ref.invalidate(allProductsProvider),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildStockCard(filtered[index]),
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  PopupMenuItem<StockSort> _sortItem(StockSort value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: _sort == value ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: _sort == value ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: _sort == value ? FontWeight.w600 : FontWeight.normal)),
          if (_sort == value) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(int emptyCount, int lowCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _bannerStat(emptyCount.toString(), 'Stok Habis', AppColors.stockEmpty),
          Container(width: 1, height: 36, color: Colors.white24),
          _bannerStat(lowCount.toString(), 'Stok Menipis', AppColors.stockLow),
          Container(width: 1, height: 36, color: Colors.white24),
          _bannerStat('${emptyCount + lowCount}', 'Total Produk', Colors.white),
        ],
      ),
    );
  }

  Widget _bannerStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(int emptyCount, int lowCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _filterChip(StockFilter.all, 'Semua', '${emptyCount + lowCount}', AppColors.primary),
          const SizedBox(width: 8),
          _filterChip(StockFilter.empty, 'Habis', '$emptyCount', AppColors.stockEmpty),
          const SizedBox(width: 8),
          _filterChip(StockFilter.low, 'Menipis', '$lowCount', AppColors.stockLow),
        ],
      ),
    );
  }

  Widget _filterChip(StockFilter value, String label, String count, Color color) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            'Diurutkan: $_sortLabel',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Product product) {
    final isEmpty = product.stock <= 0;
    final statusColor = isEmpty ? AppColors.stockEmpty : AppColors.stockLow;
    final statusLabel = isEmpty ? 'HABIS' : 'MENIPIS';
    final percentage = product.minStock > 0
        ? (product.stock / product.minStock).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEmpty
                        ? Icons.inventory_2_outlined
                        : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(product.sellPrice)} / ${product.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stockInfoPill(
                  'Stok Saat Ini',
                  '${product.stock} ${product.unit}',
                  statusColor,
                ),
                const SizedBox(width: 8),
                _stockInfoPill(
                  'Stok Minimum',
                  '${product.minStock} ${product.unit}',
                  AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                _stockInfoPill(
                  'Kekurangan',
                  isEmpty
                      ? '${product.minStock} ${product.unit}'
                      : '${product.minStock - product.stock} ${product.unit}',
                  AppColors.textSecondary,
                ),
              ],
            ),
            if (!isEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppColors.divider,
                        color: percentage < 0.3
                            ? AppColors.stockEmpty
                            : percentage < 0.6
                                ? AppColors.stockLow
                                : AppColors.stockSafe,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stockInfoPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSafeState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.stockSafe.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 64,
              color: AppColors.stockSafe,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Semua Stok Aman!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tidak ada produk yang menipis atau habis.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => ref.invalidate(allProductsProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_off_rounded,
            size: 48,
            color: AppColors.divider,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada produk dengan filter ini',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _filter = StockFilter.all),
            child: const Text('Tampilkan Semua'),
          ),
        ],
      ),
    );
  }
}
