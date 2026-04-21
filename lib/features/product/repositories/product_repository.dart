import '../../../core/database/db_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DbHelper _dbHelper = DbHelper();

  Future<List<Product>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ?',
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
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStock(int productId, int quantityChange) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock + ?, updated_at = datetime(\'now\', \'localtime\') WHERE id = ?',
      [quantityChange, productId],
    );
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'stock <= min_stock',
      orderBy: 'stock ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> updateLastNotifiedAt(int productId) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE products SET last_notified_at = datetime(\'now\', \'localtime\') WHERE id = ?',
      [productId],
    );
  }
}
