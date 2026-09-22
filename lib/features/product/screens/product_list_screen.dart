import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

enum ProductSortOption { name, stock, status, sold }

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _sortProducts(
    List<Product> products,
    Map<int, int> soldCountByProduct,
  ) {
    final sorted = List<Product>.from(products);

    int statusRank(Product p) {
      if (p.stock <= 0) return 0;
      if (p.stock <= p.minStock) return 1;
      return 2;
    }

    sorted.sort((a, b) {
      switch (_sortOption) {
        case ProductSortOption.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortOption.stock:
          final byStock = a.stock.compareTo(b.stock);
          if (byStock != 0) return byStock;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortOption.status:
          final byStatus = statusRank(a).compareTo(statusRank(b));
          if (byStatus != 0) return byStatus;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortOption.sold:
          final soldA = soldCountByProduct[a.id] ?? 0;
          final soldB = soldCountByProduct[b.id] ?? 0;
          final bySold = soldB.compareTo(soldA);
          if (bySold != 0) return bySold;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final soldCountAsync = ref.watch(todaySoldCountByProductProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.products),
        actions: [
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: ProductSortOption.name,
                checked: _sortOption == ProductSortOption.name,
                child: const Text('Nama (A-Z)'),
              ),
              CheckedPopupMenuItem(
                value: ProductSortOption.stock,
                checked: _sortOption == ProductSortOption.stock,
                child: const Text('Stok (Rendah -> Tinggi)'),
              ),
              CheckedPopupMenuItem(
                value: ProductSortOption.status,
                checked: _sortOption == ProductSortOption.status,
                child: const Text('Status Stok'),
              ),
              CheckedPopupMenuItem(
                value: ProductSortOption.sold,
                checked: _sortOption == ProductSortOption.sold,
                child: const Text('Terlaris Hari Ini'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/products/new'),
            tooltip: AppStrings.addProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.search,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF8FAFF),
                        Color(0xFFEEF2FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD7DEFF)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola produk lebih aman',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Produk bisa dihapus dari daftar aktif tanpa menghapus histori pemasukan dan pengeluaran yang sudah tercatat.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                return soldCountAsync.when(
                  data: (soldCountByProduct) {
                    final filtered = _sortProducts(
                      _searchQuery.isEmpty
                          ? products
                          : products
                              .where(
                                (p) => p.name
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()),
                              )
                              .toList(),
                      soldCountByProduct,
                    );

                    if (filtered.isEmpty) {
                      return EmptyState(
                        title: _searchQuery.isEmpty
                            ? 'Belum ada produk'
                            : 'Produk tidak ditemukan',
                        icon: _searchQuery.isEmpty
                            ? Icons.inventory_2_outlined
                            : Icons.search_off,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _buildProductCard(product, soldCountByProduct);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => EmptyState(
                    title: 'Gagal memuat data penjualan',
                    subtitle: error.toString(),
                    icon: Icons.error_outline,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => EmptyState(
                title: 'Gagal memuat produk',
                subtitle: error.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, Map<int, int> soldCountByProduct) {
    final stockColor = product.stock <= 0
        ? AppColors.stockEmpty
        : product.stock <= product.minStock
            ? AppColors.stockLow
            : AppColors.stockSafe;
    final soldCount = soldCountByProduct[product.id] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/products/${product.id}/edit'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: AppColors.primaryDark,
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
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${CurrencyFormatter.format(product.sellPrice)} / ${product.unit}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Aksi Produk',
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await context.push('/products/${product.id}/edit');
                          return;
                        }
                        await _confirmDeleteProduct(product);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit Produk'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline, color: AppColors.danger),
                            title: Text(
                              'Hapus Produk',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoPill(
                        label: 'Stok',
                        value: '${product.stock} (${product.stockStatus})',
                        valueColor: stockColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoPill(
                        label: 'Terjual Hari Ini',
                        value: '$soldCount item',
                        valueColor: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/products/${product.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _confirmDeleteProduct(product),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final repo = ref.read(productRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final impact = await repo.getDeletionImpact(product.id!);
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Hapus ${product.name}?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Produk akan dihapus dari daftar aktif, tetapi histori pemasukan, pengeluaran, dan laporan yang sudah tercatat akan tetap tersimpan di sistem.',
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat penjualan: ${impact.totalSales} transaksi',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total pemasukan tercatat: ${CurrencyFormatter.format(impact.incomeTotal)}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Riwayat restok: ${impact.totalRestocks} transaksi - ${impact.totalRestockUnits} item',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Setelah dihapus, produk tidak akan muncul lagi di menu jual, restok, dan daftar produk aktif.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Ya, Hapus'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await ref.read(allProductsProvider.notifier).deleteProduct(product.id!);
      ref.invalidate(todaySoldCountByProductProvider);
      ref.invalidate(topProductsProvider);
      ref.invalidate(lowStockProductsProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${product.name} berhasil dihapus dari daftar aktif'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }
}
