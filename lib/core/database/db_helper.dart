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

    return await openDatabase(
      path,
      version: DbMigrations.currentVersion,
      onCreate: (db, version) async {
        for (final query in DbMigrations.onCreateQueries) {
          await db.execute(query);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        final queries = DbMigrations.getUpgradeQueries(oldVersion, newVersion);
        for (final query in queries) {
          await db.execute(query);
        }
      },
    );
  }
}
