class DbMigrations {
  static const int currentVersion = 2;

  static List<String> get onCreateQueries => [
        _createProductsTable,
        _createTransactionsTable,
        _createTransactionItemsTable,
        _createStockAdjustmentsTable,
      ];

  static const String _createProductsTable = '''
    CREATE TABLE products (
      id               INTEGER PRIMARY KEY AUTOINCREMENT,
      name             TEXT    NOT NULL,
      sell_price       REAL    NOT NULL,
      cost_price       REAL    NOT NULL,
      stock            INTEGER NOT NULL DEFAULT 0,
      min_stock        INTEGER NOT NULL DEFAULT 5,
      unit             TEXT    NOT NULL DEFAULT 'pcs',
      is_deleted       INTEGER NOT NULL DEFAULT 0,
      deleted_at       TEXT,
      last_notified_at TEXT,
      created_at       TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
      updated_at       TEXT    NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  static const String _createTransactionsTable = '''
    CREATE TABLE transactions (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      type        TEXT    NOT NULL CHECK (type IN ('income', 'expense')),
      category    TEXT,
      note        TEXT,
      created_at  TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
      updated_at  TEXT    NOT NULL DEFAULT (datetime('now', 'localtime'))
    )
  ''';

  static const String _createTransactionItemsTable = '''
    CREATE TABLE transaction_items (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id  INTEGER NOT NULL,
      product_id      INTEGER,
      quantity        INTEGER NOT NULL DEFAULT 1,
      price_at_sale   REAL    NOT NULL,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id)     REFERENCES products(id)     ON DELETE SET NULL
    )
  ''';

  static const String _createStockAdjustmentsTable = '''
    CREATE TABLE stock_adjustments (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id      INTEGER NOT NULL,
      quantity_change INTEGER NOT NULL,
      reason          TEXT    NOT NULL,
      transaction_id  INTEGER,
      created_at      TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
      FOREIGN KEY (product_id)     REFERENCES products(id)     ON DELETE CASCADE,
      FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
    )
  ''';

  static List<String> getUpgradeQueries(int oldVersion, int newVersion) {
    final queries = <String>[];

    if (oldVersion < 2 && newVersion >= 2) {
      queries.addAll([
        '''
        ALTER TABLE products
        ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0
        ''',
        '''
        ALTER TABLE products
        ADD COLUMN deleted_at TEXT
        ''',
      ]);
    }

    return queries;
  }
}
