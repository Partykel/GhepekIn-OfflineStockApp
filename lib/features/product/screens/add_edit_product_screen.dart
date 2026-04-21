import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final int? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  String _unit = 'pcs';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final product = await ref.read(productRepositoryProvider).getById(widget.productId!);
    if (product != null && mounted) {
      setState(() {
        _nameController.text = product.name;
        _sellPriceController.text = product.sellPrice.toString();
        _costPriceController.text = product.costPrice.toString();
        _stockController.text = product.stock.toString();
        _minStockController.text = product.minStock.toString();
        _unit = product.unit;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellPriceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: 'Nama Produk',
              hint: 'Contoh: Keripik Singkong',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
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
                if (double.tryParse(value) == null) {
                  return 'Format harga tidak valid';
                }
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
                if (double.tryParse(value) == null) {
                  return 'Format harga tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Stok Awal',
                    hint: '0',
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: 'Stok Minimum',
                    hint: '5',
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
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
                DropdownMenuItem(value: 'bungkus', child: Text('Bungkus')),
                DropdownMenuItem(value: 'botol', child: Text('Botol')),
                DropdownMenuItem(value: 'kg', child: Text('Kg')),
                DropdownMenuItem(value: 'liter', child: Text('Liter')),
              ],
              onChanged: (value) => setState(() => _unit = value!),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: isEdit ? 'Update Produk' : 'Simpan Produk',
              onPressed: _saveProduct,
              isLoading: _isLoading,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: widget.productId,
        name: _nameController.text,
        sellPrice: double.parse(_sellPriceController.text),
        costPrice: double.parse(_costPriceController.text),
        stock: int.tryParse(_stockController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        unit: _unit,
      );

      if (widget.productId != null) {
        await ref.read(allProductsProvider.notifier).updateProduct(product);
      } else {
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
