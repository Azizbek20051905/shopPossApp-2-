class DashboardData {
  final double todaySales;
  final double yesterdaySales;
  final double todayProfit;
  final int totalOrders;
  final List<LowStockProduct> lowStock;
  final List<RecentSale> recentSales;

  DashboardData({
    required this.todaySales,
    required this.yesterdaySales,
    required this.todayProfit,
    required this.totalOrders,
    required this.lowStock,
    required this.recentSales,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      todaySales: (json['today_sales'] as num).toDouble(),
      yesterdaySales: (json['yesterday_sales'] as num).toDouble(),
      todayProfit: (json['today_profit'] as num).toDouble(),
      totalOrders: json['total_orders'] as int,
      lowStock: (json['low_stock'] as List)
          .map((item) => LowStockProduct.fromJson(item))
          .toList(),
      recentSales: (json['recent_sales'] as List)
          .map((item) => RecentSale.fromJson(item))
          .toList(),
    );
  }
}

class LowStockProduct {
  final int id;
  final String name;
  final double stock;

  LowStockProduct({
    required this.id,
    required this.name,
    required this.stock,
  });

  factory LowStockProduct.fromJson(Map<String, dynamic> json) {
    return LowStockProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      stock: (json['stock'] as num).toDouble(),
    );
  }
}

class RecentSale {
  final int id;
  final double total;
  final int items;
  final String createdAt;

  RecentSale({
    required this.id,
    required this.total,
    required this.items,
    required this.createdAt,
  });

  factory RecentSale.fromJson(Map<String, dynamic> json) {
    return RecentSale(
      id: json['id'] as int,
      total: (json['total'] as num).toDouble(),
      items: json['items'] as int,
      createdAt: json['created_at'] as String,
    );
  }
}
