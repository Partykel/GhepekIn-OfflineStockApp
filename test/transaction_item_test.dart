import 'package:flutter_test/flutter_test.dart';
import 'package:ghepek_in/features/transaction/models/transaction.dart';
import 'package:ghepek_in/features/transaction/models/transaction_item.dart';

void main() {
  group('TransactionItem.total', () {
    test('total = quantity x priceAtSale', () {
      final item = TransactionItem(transactionId: 1, productId: 2, quantity: 3, priceAtSale: 12500);
      expect(item.total, 37500);
    });

    test('total with quantity 1', () {
      final item = TransactionItem(transactionId: 1, productId: 2, quantity: 1, priceAtSale: 20000);
      expect(item.total, 20000);
    });

    test('total with large qty', () {
      final item = TransactionItem(transactionId: 1, productId: 2, quantity: 100, priceAtSale: 5000);
      expect(item.total, 500000);
    });
  });

  group('TransactionItem.toMap / fromMap', () {
    test('round-trip preserves all fields', () {
      final item = TransactionItem(
        id: 5, transactionId: 10, productId: 3, quantity: 2, priceAtSale: 15000,
      );
      final map = item.toMap();
      final restored = TransactionItem.fromMap({...map, 'id': 5});
      expect(restored.id, 5);
      expect(restored.transactionId, 10);
      expect(restored.productId, 3);
      expect(restored.quantity, 2);
      expect(restored.priceAtSale, 15000);
      expect(restored.total, 30000);
    });

    test('fromMap handles null productId (produk dihapus)', () {
      final item = TransactionItem.fromMap({
        'id': 1, 'transaction_id': 1, 'product_id': null, 'quantity': 2, 'price_at_sale': 5000,
      });
      expect(item.productId, isNull);
      expect(item.total, 10000);
    });
  });

  group('TransactionItem.copyWith', () {
    test('only updates specified fields', () {
      final item = TransactionItem(transactionId: 1, productId: 2, quantity: 3, priceAtSale: 10000);
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.priceAtSale, 10000);
      expect(updated.total, 50000);
    });
  });

  group('Transaction model', () {
    test('isIncome returns true for income type', () {
      final t = Transaction(type: 'income');
      expect(t.isIncome, true);
      expect(t.isExpense, false);
    });

    test('isExpense returns true for expense type', () {
      final t = Transaction(type: 'expense', category: 'operasional');
      expect(t.isExpense, true);
      expect(t.isIncome, false);
    });

    test('toMap / fromMap round-trip', () {
      final now = DateTime(2025, 6, 1, 12, 0);
      final t = Transaction(
        id: 1, type: 'income', note: 'Penjualan siang',
        createdAt: now, updatedAt: now,
      );
      final map = t.toMap();
      final restored = Transaction.fromMap({
        ...map,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      expect(restored.id, 1);
      expect(restored.type, 'income');
      expect(restored.note, 'Penjualan siang');
    });
  });
}
