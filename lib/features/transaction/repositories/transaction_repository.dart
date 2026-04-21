import '../../../core/database/db_helper.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final DbHelper _dbHelper = DbHelper();

  Future<Transaction> createSale({
    required List<Map<String, dynamic>> items,
    String? note,
  }) async {
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
        await txn.insert('transaction_items', {
          'transaction_id': transactionId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price_at_sale': item['price_at_sale'],
        });

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?',
          [item['quantity'], now, item['product_id']],
        );

        await txn.insert('stock_adjustments', {
          'product_id': item['product_id'],
          'quantity_change': -item['quantity'],
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
    required double amount,
    required String category,
    String? note,
    List<Map<String, dynamic>>? restockItems,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

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
        'price_at_sale': amount,
      });

      if (category == 'stok' && restockItems != null) {
        for (final item in restockItems) {
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
            [item['quantity'], now, item['product_id']],
          );

          await txn.insert('stock_adjustments', {
            'product_id': item['product_id'],
            'quantity_change': item['quantity'],
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
              'UPDATE products SET stock = stock + ? WHERE id = ?',
              [quantity, productId],
            );
          }
        }
      }

      await txn.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [id]);
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
      SELECT ti.*, p.name as product_name
      FROM transaction_items ti
      LEFT JOIN products p ON p.id = ti.product_id
      WHERE ti.transaction_id = ?
    ''', [transactionId]);
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
      WHERE DATE(t.created_at) >= DATE('now', '-6 days')
      GROUP BY DATE(t.created_at)
      ORDER BY date ASC
    ''');
  }
}
