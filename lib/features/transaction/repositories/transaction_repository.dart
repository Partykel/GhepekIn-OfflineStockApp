import '../../../core/database/db_helper.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final DbHelper _dbHelper = DbHelper();

  Future<Transaction> createSale({
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Minimal satu item diperlukan untuk transaksi penjualan.');
    }

    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      final transactionId = await txn.insert('transactions', {
        'type': 'income',
        'note': note,
        'created_at': now,
        'updated_at': now,
      });

      for (final item in items) {
        final productId = item['product_id'] as int?;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final priceAtSale = (item['price_at_sale'] as num?)?.toDouble() ?? 0;

        if (productId == null) {
          throw ArgumentError('product_id tidak boleh kosong.');
        }
        if (quantity <= 0) {
          throw ArgumentError('Quantity harus lebih dari 0.');
        }
        if (priceAtSale <= 0) {
          throw ArgumentError('price_at_sale harus lebih dari 0.');
        }

        final productRows = await txn.query(
          'products',
          columns: ['stock', 'is_deleted'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (productRows.isEmpty) {
          throw StateError('Produk dengan ID $productId tidak ditemukan.');
        }
        if (((productRows.first['is_deleted'] as num?)?.toInt() ?? 0) == 1) {
          throw StateError('Produk dengan ID $productId sudah dihapus.');
        }

        final currentStock = (productRows.first['stock'] as num).toInt();
        if (currentStock < quantity) {
          throw StateError('Stok produk ID $productId tidak mencukupi.');
        }

        await txn.insert('transaction_items', {
          'transaction_id': transactionId,
          'product_id': productId,
          'quantity': quantity,
          'price_at_sale': priceAtSale,
        });

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?',
          [quantity, now, productId],
        );

        await txn.insert('stock_adjustments', {
          'product_id': productId,
          'quantity_change': -quantity,
          'reason': 'sale',
          'transaction_id': transactionId,
          'created_at': now,
        });
      }

      return Transaction(
        id: transactionId,
        type: 'income',
        note: note,
        createdAt: DateTime.parse(now),
        updatedAt: DateTime.parse(now),
      );
    });
  }

  Future<Transaction> createExpense({
    double? amount,
    required String category,
    String? note,
    List<Map<String, dynamic>>? restockItems,
  }) async {
    if (category == 'stok' && (restockItems == null || restockItems.isEmpty)) {
      throw ArgumentError('Minimal satu produk harus dipilih untuk kategori Beli Stok.');
    }

    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final normalizedRestockItems = <({int productId, int quantity})>[];
      double finalAmount = amount ?? 0;

      if (category == 'stok' && restockItems != null) {
        finalAmount = 0;

        for (final item in restockItems) {
          final productId = item['product_id'] as int?;
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

          if (productId == null) {
            throw ArgumentError('product_id restock tidak boleh kosong.');
          }
          if (quantity <= 0) {
            throw ArgumentError('Quantity restock harus lebih dari 0.');
          }

          final productRows = await txn.query(
            'products',
            columns: ['id', 'cost_price', 'is_deleted'],
            where: 'id = ?',
            whereArgs: [productId],
            limit: 1,
          );
          if (productRows.isEmpty) {
            throw StateError('Produk dengan ID $productId tidak ditemukan.');
          }
          if (((productRows.first['is_deleted'] as num?)?.toInt() ?? 0) == 1) {
            throw StateError('Produk dengan ID $productId sudah dihapus.');
          }

          final costPrice = (productRows.first['cost_price'] as num).toDouble();
          normalizedRestockItems.add((productId: productId, quantity: quantity));
          finalAmount += costPrice * quantity;
        }
      }

      if (finalAmount <= 0) {
        throw ArgumentError('Nominal pengeluaran harus lebih dari 0.');
      }

      final transactionId = await txn.insert('transactions', {
        'type': 'expense',
        'category': category,
        'note': note,
        'created_at': now,
        'updated_at': now,
      });

      await txn.insert('transaction_items', {
        'transaction_id': transactionId,
        'product_id': null,
        'quantity': 1,
        'price_at_sale': finalAmount,
      });

      if (category == 'stok') {
        for (final item in normalizedRestockItems) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
            [item.quantity, now, item.productId],
          );

          await txn.insert('stock_adjustments', {
            'product_id': item.productId,
            'quantity_change': item.quantity,
            'reason': 'restock',
            'transaction_id': transactionId,
            'created_at': now,
          });
        }
      }

      return Transaction(
        id: transactionId,
        type: 'expense',
        category: category,
        note: note,
        createdAt: DateTime.parse(now),
        updatedAt: DateTime.parse(now),
      );
    });
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final maps = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return;
      final transaction = Transaction.fromMap(maps.first);

      if (transaction.type == 'income') {
        final items = await txn.query(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [id],
        );
        for (final item in items) {
          final productId = item['product_id'] as int?;
          if (productId != null) {
            final quantity = item['quantity'] as int;
            await txn.rawUpdate(
              'UPDATE products SET stock = stock + ?, updated_at = datetime(\'now\', \'localtime\') WHERE id = ?',
              [quantity, productId],
            );
          }
        }
      } else if (transaction.type == 'expense' &&
          transaction.category == 'stok') {
        final adjustments = await txn.query(
          'stock_adjustments',
          where: 'transaction_id = ? AND reason = ?',
          whereArgs: [id, 'restock'],
        );
        for (final adj in adjustments) {
          final productId = adj['product_id'] as int?;
          if (productId != null) {
            final qty = (adj['quantity_change'] as int).abs();
            await txn.rawUpdate(
              'UPDATE products SET stock = MAX(0, stock - ?), updated_at = datetime(\'now\', \'localtime\') WHERE id = ?',
              [qty, productId],
            );
          }
        }
      }

      await txn.delete('stock_adjustments',
          where: 'transaction_id = ?', whereArgs: [id]);
      await txn.delete('transaction_items',
          where: 'transaction_id = ?', whereArgs: [id]);
      await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<double> getTodayIncome() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.quantity * ti.price_at_sale), 0) as total
      FROM transactions t
      JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.type = 'income'
        AND DATE(t.created_at) = DATE('now', 'localtime')
    ''');
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTodayExpense() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(ti.price_at_sale), 0) as total
      FROM transactions t
      JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE t.type = 'expense'
        AND DATE(t.created_at) = DATE('now', 'localtime')
    ''');
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getTopProductsToday({int limit = 3}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT p.id, p.name, SUM(ti.quantity) as total_sold
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      JOIN products p ON p.id = ti.product_id
      WHERE t.type = 'income'
        AND DATE(t.created_at) = DATE('now', 'localtime')
      GROUP BY ti.product_id
      ORDER BY total_sold DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<Map<int, int>> getTodaySoldCountByProduct() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT ti.product_id, SUM(ti.quantity) AS total_sold
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.type = 'income'
        AND DATE(t.created_at) = DATE('now', 'localtime')
      GROUP BY ti.product_id
    ''');

    return {
      for (final row in rows)
        (row['product_id'] as int): (row['total_sold'] as num).toInt(),
    };
  }

  Future<List<Transaction>> getHistory({DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbHelper.database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      where += 'DATE(t.created_at) >= DATE(?)';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'DATE(t.created_at) <= DATE(?)';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.rawQuery('''
      SELECT t.* FROM transactions t
      ${where.isNotEmpty ? 'WHERE $where' : ''}
      ORDER BY t.created_at DESC
    ''', whereArgs);

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionDetails(int transactionId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT
        ti.id,
        ti.transaction_id,
        ti.product_id,
        ti.quantity,
        ti.price_at_sale,
        p.name as product_name
      FROM transaction_items ti
      LEFT JOIN products p ON p.id = ti.product_id
      WHERE ti.transaction_id = ?
      UNION ALL
      SELECT
        NULL as id,
        sa.transaction_id,
        sa.product_id,
        ABS(sa.quantity_change) as quantity,
        0 as price_at_sale,
        p.name as product_name
      FROM stock_adjustments sa
      LEFT JOIN products p ON p.id = sa.product_id
      WHERE sa.transaction_id = ?
        AND sa.reason = 'restock'
    ''', [transactionId, transactionId]);
  }

  Future<List<Map<String, dynamic>>> getSevenDayTrend() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT
        DATE(t.created_at) as date,
        COALESCE(SUM(CASE WHEN t.type = 'income' THEN ti.quantity * ti.price_at_sale ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN ti.price_at_sale ELSE 0 END), 0) as expense
      FROM transactions t
      LEFT JOIN transaction_items ti ON ti.transaction_id = t.id
      WHERE DATE(t.created_at) >= DATE('now', 'localtime', '-6 days')
      GROUP BY DATE(t.created_at)
      ORDER BY date ASC
    ''');
  }
}
