import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/features/product/models/product.dart';

void main() {
  group('Product.stockStatus', () {
    test('returns Aman when stock > minStock', () {
      final p = Product(name: 'A', sellPrice: 1000, costPrice: 500, stock: 10, minStock: 5);
      expect(p.stockStatus, 'Aman');
    });

    test('returns Menipis when stock == minStock', () {
      final p = Product(name: 'A', sellPrice: 1000, costPrice: 500, stock: 5, minStock: 5);
      expect(p.stockStatus, 'Menipis');
    });

    test('returns Menipis when stock < minStock but > 0', () {
      final p = Product(name: 'A', sellPrice: 1000, costPrice: 500, stock: 3, minStock: 5);
      expect(p.stockStatus, 'Menipis');
    });

    test('returns Habis when stock == 0', () {
      final p = Product(name: 'A', sellPrice: 1000, costPrice: 500, stock: 0, minStock: 5);
      expect(p.stockStatus, 'Habis');
    });
  });

  group('Product.toMap / fromMap', () {
    test('round-trip preserves all fields', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final p = Product(
        id: 1, name: 'Keripik Singkong', sellPrice: 15000, costPrice: 8000,
        stock: 20, minStock: 5, unit: 'bungkus', createdAt: now, updatedAt: now,
      );
      final restored = Product.fromMap({
        ...p.toMap(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(restored.id, 1);
      expect(restored.name, 'Keripik Singkong');
      expect(restored.sellPrice, 15000);
      expect(restored.costPrice, 8000);
      expect(restored.stock, 20);
      expect(restored.minStock, 5);
      expect(restored.unit, 'bungkus');
    });

    test('fromMap handles null lastNotifiedAt', () {
      final p = Product.fromMap({
        'id': 1, 'name': 'Test', 'sell_price': 1000, 'cost_price': 500,
        'stock': 10, 'min_stock': 5, 'unit': 'pcs', 'last_notified_at': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      expect(p.lastNotifiedAt, isNull);
    });
  });

  group('Product.copyWith', () {
    test('only updates specified fields', () {
      final p = Product(name: 'A', sellPrice: 1000, costPrice: 500, stock: 10, minStock: 5);
      final updated = p.copyWith(stock: 20, name: 'B');
      expect(updated.stock, 20);
      expect(updated.name, 'B');
      expect(updated.sellPrice, 1000);
    });
  });
}
