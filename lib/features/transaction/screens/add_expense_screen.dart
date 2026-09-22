import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../product/models/product.dart';
import '../../product/providers/product_provider.dart';
import '../../transaction/providers/transaction_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final Map<int, int> _restockItems = {};

  String _selectedCategory = 'operasional';
  bool _isLoading = false;

  bool get isStockCategory => _selectedCategory == 'stok';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final products = productsAsync.when(
      data: (items) => items,
      loading: () => const <Product>[],
      error: (_, _) => const <Product>[],
    );
    final restockTotal = _calculateRestockTotal(products);
    final selectedQty = _restockItems.values.fold<int>(0, (sum, qty) => sum + qty);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addExpense),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroCard(restockTotal, selectedQty),
            const SizedBox(height: 16),
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryChip(
                          'stok',
                          AppStrings.categoryStock,
                          Icons.inventory_2_rounded,
                        ),
                        _buildCategoryChip(
                          'operasional',
                          AppStrings.categoryOperational,
                          Icons.settings_outlined,
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
            if (isStockCategory)
              _buildAutoTotalCard(restockTotal, selectedQty)
            else
              AppTextField(
                label: 'Nominal',
                hint: 'Contoh: 50000',
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null) return 'Format nominal tidak valid';
                  if (parsed <= 0) return 'Nominal harus lebih dari 0';
                  return null;
                },
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nominal dihitung otomatis dari harga modal per produk. Tinggal tekan tombol tambah pada produk yang ingin direstok.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      productsAsync.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return Column(
                              children: [
                                const EmptyState(
                                  title: 'Belum ada produk terdaftar',
                                  subtitle:
                                      'Buat produk dulu, lalu restok akan otomatis menghitung total modal.',
                                  icon: Icons.inventory_2_outlined,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => context.push('/products/new'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Produk Baru'),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _buildRestockTile(items[index]);
                                },
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await context.push('/products/new');
                                  ref.invalidate(allProductsProvider);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Produk Baru'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => EmptyState(
                          title: 'Gagal memuat produk',
                          subtitle: error.toString(),
                          icon: Icons.error_outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 96),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            text: isStockCategory ? 'Simpan Restok' : 'Simpan Pengeluaran',
            onPressed: _isLoading ? null : _saveExpense,
            isLoading: _isLoading,
            fullWidth: true,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(double restockTotal, int selectedQty) {
    final title = isStockCategory
        ? 'Restok dengan nominal otomatis'
        : 'Catat pengeluaran tanpa ribet';
    final subtitle = isStockCategory
        ? 'Setiap penambahan quantity langsung mengakumulasi total modal dari produk yang dipilih.'
        : 'Gunakan kategori yang sesuai agar pencatatan pengeluaran tetap rapi.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isStockCategory
                      ? Icons.auto_awesome
                      : Icons.receipt_long_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFE0E7FF),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isStockCategory) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildHeroMetric(
                    label: 'Total Modal',
                    value: CurrencyFormatter.format(restockTotal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeroMetric(
                    label: 'Qty Restok',
                    value: '$selectedQty item',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC7D2FE),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoTotalCard(double restockTotal, int selectedQty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calculate_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Nominal Restok Otomatis',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormatter.format(restockTotal),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedQty == 0
                ? 'Pilih produk yang direstok untuk mulai menghitung total modal.'
                : '$selectedQty item restok sedang dihitung otomatis dari harga modal.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
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
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (!selected) return;

        setState(() {
          _selectedCategory = value;
          if (!isStockCategory) {
            _restockItems.clear();
          }
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );
  }

  Widget _buildRestockTile(Product product) {
    final quantity = _restockItems[product.id] ?? 0;
    final subtotal = product.costPrice * quantity;
    final isSelected = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF5F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xFFC7D2FE) : AppColors.divider,
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$quantity x',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Modal ${CurrencyFormatter.format(product.costPrice)} / ${product.unit}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stok saat ini: ${product.stock}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStepper(product.id!, quantity),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal modal',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(subtotal),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepper(int productId, int quantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepperButton(
          icon: Icons.remove,
          onTap: quantity > 0
              ? () => _updateRestock(productId, quantity - 1)
              : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            quantity.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _buildStepperButton(
          icon: Icons.add,
          onTap: () => _updateRestock(productId, quantity + 1),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.background
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppColors.textSecondary : AppColors.primaryDark,
        ),
      ),
    );
  }

  double _calculateRestockTotal(List<Product> products) {
    final productMap = {for (final product in products) product.id: product};

    return _restockItems.entries.fold<double>(0, (sum, entry) {
      final product = productMap[entry.key];
      if (product == null) return sum;
      return sum + (product.costPrice * entry.value);
    });
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
    if (!isStockCategory && !_formKey.currentState!.validate()) return;

    if (isStockCategory && _restockItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu produk untuk restok.'),
        ),
      );
      return;
    }

    final products = ref.read(allProductsProvider).when(
      data: (items) => items,
      loading: () => const <Product>[],
      error: (_, _) => const <Product>[],
    );

    if (isStockCategory && products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data produk belum siap. Coba lagi sebentar.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final restockItems = isStockCategory
          ? _restockItems.entries
              .map(
                (entry) => {
                  'product_id': entry.key,
                  'quantity': entry.value,
                },
              )
              .toList()
          : null;

      final amount = isStockCategory
          ? _calculateRestockTotal(products)
          : double.parse(_amountController.text);

      await ref.read(addExpenseProvider.notifier).call(
            amount: amount,
            category: _selectedCategory,
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
