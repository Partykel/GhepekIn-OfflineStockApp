class TransactionItem {
  final int? id;
  final int transactionId;
  final int? productId;
  final int quantity;
  final double priceAtSale;

  TransactionItem({
    this.id,
    required this.transactionId,
    this.productId,
    this.quantity = 1,
    required this.priceAtSale,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      productId: map['product_id'] as int?,
      quantity: map['quantity'] as int,
      priceAtSale: (map['price_at_sale'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
    };
  }

  double get total => quantity * priceAtSale;

  TransactionItem copyWith({
    int? id,
    int? transactionId,
    int? productId,
    int? quantity,
    double? priceAtSale,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      priceAtSale: priceAtSale ?? this.priceAtSale,
    );
  }
}
