class Product {
  final int? id;
  final String name;
  final double sellPrice;
  final double costPrice;
  final int stock;
  final int minStock;
  final String unit;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? lastNotifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.sellPrice,
    required this.costPrice,
    this.stock = 0,
    this.minStock = 5,
    this.unit = 'pcs',
    this.isDeleted = false,
    this.deletedAt,
    this.lastNotifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      sellPrice: (map['sell_price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      stock: map['stock'] as int,
      minStock: map['min_stock'] as int,
      unit: map['unit'] as String,
      isDeleted: ((map['is_deleted'] as num?)?.toInt() ?? 0) == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      lastNotifiedAt: map['last_notified_at'] != null
          ? DateTime.parse(map['last_notified_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sell_price': sellPrice,
      'cost_price': costPrice,
      'stock': stock,
      'min_stock': minStock,
      'unit': unit,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'last_notified_at': lastNotifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get stockStatus {
    if (stock <= 0) return 'Habis';
    if (stock <= minStock) return 'Menipis';
    return 'Aman';
  }

  Product copyWith({
    int? id,
    String? name,
    double? sellPrice,
    double? costPrice,
    int? stock,
    int? minStock,
    String? unit,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? lastNotifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sellPrice: sellPrice ?? this.sellPrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
