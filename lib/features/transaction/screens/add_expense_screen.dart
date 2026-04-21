// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../product/providers/product_provider.dart';
import '../../product/models/product.dart';
import '../../transaction/providers/transaction_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'operasional';
  final Map<int, int> _restockItems = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get isStockCategory => _selectedCategory == 'stok';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addExpense),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildCategoryChip(
                          'stok',
                          AppStrings.categoryStock,
                          Icons.inventory,
                        ),
                        _buildCategoryChip(
                          'operasional',
                          AppStrings.categoryOperational,
                          Icons.settings,
                        ),
                        _buildCategoryChip(
                          'lainnya',
                          AppStrings.categoryOther,
                          Icons.more_horiz,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nominal',
              hint: 'Contoh: 50000',
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nominal wajib diisi';
                }
                if (double.tryParse(value) == null) {
                  return 'Format nominal tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Keterangan (Opsional)',
              hint: 'Contoh: Beli beras 5kg',
              controller: _noteController,
              maxLines: 2,
            ),
            if (isStockCategory) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Produk yang Direstok',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      productsAsync.when(
                        data: (products) {
                          if (products.isEmpty) {
                            return const Text(
                              'Tambahkan produk terlebih dahulu',
                              style: TextStyle(color: AppColors.textSecondary),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _buildRestockTile(products[index]);
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error: $error'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              text: 'Simpan Pengeluaran',
              onPressed: _saveExpense,
              isLoading: _isLoading,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = value);
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildRestockTile(Product product) {
    final quantity = _restockItems[product.id] ?? 0;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text('Stok saat ini: ${product.stock}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _updateRestock(product.id!, quantity > 0 ? quantity - 1 : 0),
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
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
            onPressed: () => _updateRestock(product.id!, quantity + 1),
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  void _updateRestock(int productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _restockItems.remove(productId);
      } else {
        _restockItems[productId] = quantity;
      }
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>>? restockItems;
      if (isStockCategory && _restockItems.isNotEmpty) {
        restockItems = _restockItems.entries.map((entry) {
          return {
            'product_id': entry.key,
            'quantity': entry.value,
          };
        }).toList();
      }

      await ref.read(addExpenseProvider.notifier).call(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        restockItems: restockItems,
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
