// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../product/providers/product_provider.dart';
import '../../product/models/product.dart';
import '../../transaction/providers/transaction_provider.dart';

class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({super.key});

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  final Map<int, int> _selectedItems = {};
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Penjualan'),
      ),
      body: Column(
        children: [
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final availableProducts = products.where((p) => p.stock > 0).toList();

                if (availableProducts.isEmpty) {
                  return const EmptyState(
                    title: 'Tidak ada produk dengan stok tersedia',
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = availableProducts[index];
                    return _buildProductTile(product);
                  },
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Catatan (Opsional)',
                  controller: _noteController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(_calculateTotal()),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        text: 'Simpan',
                        onPressed: _selectedItems.isEmpty ? null : _saveSale,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    final quantity = _selectedItems[product.id] ?? 0;
    final isSelected = quantity > 0;

    return Card(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.format(product.sellPrice)} / ${product.unit}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(
                      color: product.stock <= product.minStock
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: quantity > 0
                      ? () => _updateQuantity(product.id!, quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background.withValues(alpha: 1.0),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: quantity < product.stock
                      ? () => _updateQuantity(product.id!, quantity + 1)
                      : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background.withValues(alpha: 1.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(int productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedItems.remove(productId);
      } else {
        _selectedItems[productId] = quantity;
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (final entry in _selectedItems.entries) {
      final product = ref.read(allProductsProvider).value?.firstWhere(
            (p) => p.id == entry.key,
            orElse: () => Product(
              name: '',
              sellPrice: 0,
              costPrice: 0,
            ),
          );
      if (product != null) {
        total += product.sellPrice * entry.value;
      }
    }
    return total;
  }

  Future<void> _saveSale() async {
    setState(() => _isLoading = true);

    try {
      final items = _selectedItems.entries.map((entry) {
        final product = ref.read(allProductsProvider).value!.firstWhere(
              (p) => p.id == entry.key,
            );
        return {
          'product_id': entry.key,
          'quantity': entry.value,
          'price_at_sale': product.sellPrice,
        };
      }).toList();

      await ref.read(addSaleProvider.notifier).call(
        items: items,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
