import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_migrations.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  factory DbHelper() => _instance;

  DbHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ghepek_in.db');

    return openDatabase(
      path,
      version: DbMigrations.currentVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (final query in DbMigrations.onCreateQueries) {
          await db.execute(query);
        }
        await _ensureProductsSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        final queries = DbMigrations.getUpgradeQueries(oldVersion, newVersion);
        for (final query in queries) {
          await db.execute(query);
        }

        await _ensureProductsSchema(db);
      },
      onOpen: (db) async {
        await _ensureProductsSchema(db);
      },
    );
  }

  Future<void> _ensureProductsSchema(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info(products)");
    final existingColumns = columns
        .map((column) => column['name'] as String?)
        .whereType<String>()
        .toSet();

    if (!existingColumns.contains('is_deleted')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (!existingColumns.contains('deleted_at')) {
      await db.execute('ALTER TABLE products ADD COLUMN deleted_at TEXT');
    }

    if (!existingColumns.contains('last_notified_at')) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN last_notified_at TEXT',
      );
    }
  }
}
