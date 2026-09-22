import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final int? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _minStockController = TextEditingController();

  String _unit = 'pcs';
  bool _isLoading = false;
  bool _isInitializing = false;
  bool _productNotFound = false;
  Product? _existingProduct;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isInitializing = true;
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final product =
        await ref.read(productRepositoryProvider).getById(widget.productId!);
    if (!mounted) return;

    if (product != null) {
      setState(() {
        _existingProduct = product;
        _nameController.text = product.name;
        _sellPriceController.text = product.sellPrice.toString();
        _costPriceController.text = product.costPrice.toString();
        _minStockController.text = product.minStock.toString();
        _unit = product.unit;
        _isInitializing = false;
        _productNotFound = false;
      });
      return;
    }

    setState(() {
      _isInitializing = false;
      _productNotFound = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellPriceController.dispose();
    _costPriceController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _productNotFound
              ? const EmptyState(
                  title: 'Produk tidak ditemukan',
                  subtitle:
                      'Produk ini mungkin sudah dihapus dari daftar aktif.',
                  icon: Icons.inventory_2_outlined,
                )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppTextField(
                    label: 'Nama Produk',
                    hint: 'Contoh: Keripik Singkong',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama produk wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Harga Jual',
                    hint: 'Contoh: 10000',
                    controller: _sellPriceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga jual wajib diisi';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null) return 'Format harga tidak valid';
                      if (parsed <= 0) return 'Harga jual harus lebih dari 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Harga Modal',
                    hint: 'Contoh: 7000',
                    controller: _costPriceController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga modal wajib diisi';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null) return 'Format harga tidak valid';
                      if (parsed < 0) return 'Harga modal tidak boleh negatif';
                      final sellPrice = double.tryParse(_sellPriceController.text);
                      if (sellPrice != null && parsed > sellPrice) {
                        return 'Harga modal tidak boleh melebihi harga jual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStockInfoCard(isEdit),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Stok Minimum',
                    hint: '5',
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      final parsed = int.tryParse(value);
                      if (parsed == null) return 'Harus berupa angka';
                      if (parsed < 0) return 'Tidak boleh negatif';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: InputDecoration(
                      labelText: 'Satuan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pcs', child: Text('Pcs')),
                      DropdownMenuItem(
                        value: 'bungkus',
                        child: Text('Bungkus'),
                      ),
                      DropdownMenuItem(value: 'botol', child: Text('Botol')),
                      DropdownMenuItem(value: 'kg', child: Text('Kg')),
                      DropdownMenuItem(value: 'liter', child: Text('Liter')),
                    ],
                    onChanged: (value) => setState(() => _unit = value!),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 24),
                    _buildDeleteSection(),
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
            text: isEdit ? 'Update Produk' : 'Simpan Produk',
            onPressed: _productNotFound ? null : _saveProduct,
            isLoading: _isLoading,
            fullWidth: true,
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfoCard(bool isEdit) {
    final stockLabel = isEdit ? _existingProduct?.stock ?? 0 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF6F7FF),
            Color(0xFFEEF2FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9DEFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stok awal ditetapkan otomatis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit
                      ? 'Stok produk tetap mengikuti data yang sudah ada. Tambah stok dilakukan dari menu Beli Stok.'
                      : 'Produk baru selalu dibuat dengan stok 0. Tambah stok dilakukan dari menu Beli Stok di fitur Pengeluaran.',
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Stok $stockLabel',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF4338CA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.delete_forever_outlined,
                color: AppColors.danger,
              ),
              SizedBox(width: 8),
              Text(
                'Hapus Produk',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Produk akan dihapus dari daftar aktif, tetapi seluruh histori pemasukan, pengeluaran, dan laporan yang sudah tercatat tetap aman di sistem.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteProduct,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Dari Daftar Aktif'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    final productId = widget.productId;
    if (productId == null) return;

    final repo = ref.read(productRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final impact = await repo.getDeletionImpact(productId);
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Hapus ${impact.productName}?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Produk ini akan hilang dari daftar aktif dan tidak bisa dipakai lagi untuk jual/restok. Histori keuangan lama tetap tersimpan.',
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
                      Text('Riwayat penjualan: ${impact.totalSales} transaksi'),
                      const SizedBox(height: 6),
                      Text(
                        'Total pemasukan tersimpan: ${CurrencyFormatter.format(impact.incomeTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Riwayat restok: ${impact.totalRestocks} transaksi - ${impact.totalRestockUnits} item',
                      ),
                    ],
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

      await ref.read(allProductsProvider.notifier).deleteProduct(productId);
      ref.invalidate(todaySoldCountByProductProvider);
      ref.invalidate(topProductsProvider);
      ref.invalidate(lowStockProductsProvider);

      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${impact.productName} berhasil dihapus dari daftar aktif'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: $e')),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.productId != null) {
        final existing = _existingProduct;
        final product = (existing ??
                Product(
                  id: widget.productId,
                  name: _nameController.text.trim(),
                  sellPrice: double.parse(_sellPriceController.text),
                  costPrice: double.parse(_costPriceController.text),
                  stock: 0,
                ))
            .copyWith(
              name: _nameController.text.trim(),
              sellPrice: double.parse(_sellPriceController.text),
              costPrice: double.parse(_costPriceController.text),
              minStock: int.tryParse(_minStockController.text) ?? 5,
              unit: _unit,
            );

        await ref.read(allProductsProvider.notifier).updateProduct(product);
      } else {
        final product = Product(
          name: _nameController.text.trim(),
          sellPrice: double.parse(_sellPriceController.text),
          costPrice: double.parse(_costPriceController.text),
          stock: 0,
          minStock: int.tryParse(_minStockController.text) ?? 5,
          unit: _unit,
        );

        await ref.read(allProductsProvider.notifier).addProduct(product);
      }

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
