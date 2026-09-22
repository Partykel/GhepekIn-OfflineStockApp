import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/product_repository.dart';
import '../models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final allProductsProvider = AsyncNotifierProvider<AllProductsNotifier, List<Product>>(() {
  return AllProductsNotifier();
});

class AllProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return ref.read(productRepositoryProvider).getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).getAll());
  }

  Future<void> addProduct(Product product) async {
    await ref.read(productRepositoryProvider).create(product);
    await refresh();
  }

  Future<void> updateProduct(Product product) async {
    await ref.read(productRepositoryProvider).update(product);
    await refresh();
  }

  Future<void> deleteProduct(int id) async {
    await ref.read(productRepositoryProvider).delete(id);
    await refresh();
  }
}

final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.read(productRepositoryProvider).getLowStockProducts();
});
