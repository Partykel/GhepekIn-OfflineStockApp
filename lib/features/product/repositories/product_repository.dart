import '../../../core/database/db_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DbHelper _dbHelper = DbHelper();

  Future<List<Product>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ? AND is_deleted = 0',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> create(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> update(Product product) async {
    final db = await _dbHelper.database;
    final updatedRows = await db.update(
      'products',
      product.toMap(),
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [product.id],
    );

    if (updatedRows == 0) {
      throw StateError('Produk tidak ditemukan atau sudah dihapus.');
    }

    return updatedRows;
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    final deletedRows = await db.update(
      'products',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (deletedRows == 0) {
      throw StateError('Produk tidak ditemukan atau sudah dihapus.');
    }

    return deletedRows;
  }

  Future<void> updateStock(int productId, int quantityChange) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ?, updated_at = datetime(\'now\', \'localtime\') WHERE id = ? AND is_deleted = 0',
      [quantityChange, productId],
    );
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'stock <= min_stock AND is_deleted = 0',
      orderBy: 'stock ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> updateLastNotifiedAt(int productId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET last_notified_at = datetime(\'now\', \'localtime\') WHERE id = ? AND is_deleted = 0',
      [productId],
    );
  }

  Future<ProductDeletionImpact> getDeletionImpact(int productId) async {
    final db = await _dbHelper.database;
    final product = await getById(productId);

    final incomeResult = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT ti.transaction_id) AS total_sales,
        COALESCE(SUM(ti.quantity * ti.price_at_sale), 0) AS income_total
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE ti.product_id = ?
        AND t.type = 'income'
    ''', [productId]);

    final restockResult = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT sa.transaction_id) AS total_restocks,
        COALESCE(SUM(sa.quantity_change), 0) AS restock_units
      FROM stock_adjustments sa
      WHERE sa.product_id = ?
        AND sa.reason = 'restock'
    ''', [productId]);

    return ProductDeletionImpact(
      productName: product?.name ?? 'Produk',
      totalSales: (incomeResult.first['total_sales'] as num?)?.toInt() ?? 0,
      incomeTotal: (incomeResult.first['income_total'] as num?)?.toDouble() ?? 0,
      totalRestocks: (restockResult.first['total_restocks'] as num?)?.toInt() ?? 0,
      totalRestockUnits:
          (restockResult.first['restock_units'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductDeletionImpact {
  final String productName;
  final int totalSales;
  final double incomeTotal;
  final int totalRestocks;
  final int totalRestockUnits;

  const ProductDeletionImpact({
    required this.productName,
    required this.totalSales,
    required this.incomeTotal,
    required this.totalRestocks,
    required this.totalRestockUnits,
  });
}
