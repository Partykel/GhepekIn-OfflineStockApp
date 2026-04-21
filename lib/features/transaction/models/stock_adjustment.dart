class StockAdjustment {
  final int? id;
  final int productId;
  final int quantityChange;
  final String reason;
  final int? transactionId;
  final DateTime createdAt;

  StockAdjustment({
    this.id,
    required this.productId,
    required this.quantityChange,
    required this.reason,
    this.transactionId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StockAdjustment.fromMap(Map<String, dynamic> map) {
    return StockAdjustment(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      quantityChange: map['quantity_change'] as int,
      reason: map['reason'] as String,
      transactionId: map['transaction_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity_change': quantityChange,
      'reason': reason,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isIncrease => quantityChange > 0;
  bool get isDecrease => quantityChange < 0;

  StockAdjustment copyWith({
    int? id,
    int? productId,
    int? quantityChange,
    String? reason,
    int? transactionId,
    DateTime? createdAt,
  }) {
    return StockAdjustment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantityChange: quantityChange ?? this.quantityChange,
      reason: reason ?? this.reason,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
