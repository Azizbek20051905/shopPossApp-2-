class Sale {
  final int? id;
  final String? cashierName;
  final DateTime createdAt;
  final double total;

  const Sale({
    this.id,
    this.cashierName,
    required this.createdAt,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cashier_name': cashierName,
      'created_at': createdAt.toIso8601String(),
      'total_price': total,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Sale(
      id: map['id'] as int?,
      cashierName: map['cashier_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      total: parseDouble(map['total_price'] ?? map['total']),
    );
  }
}

class SaleItem {
  final int? id;
  final int? saleId;
  final int? productId;
  final String productName;
  /// Piece count or weight (kg).
  final double quantity;
  final double price;

  const SaleItem({
    this.id,
    this.saleId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale'] as int?,
      productId: map['product'] as int?,
      productName: map['product_name'] as String? ?? '',
      quantity: parseDouble(map['quantity']),
      price: parseDouble(map['price']),
    );
  }
}
