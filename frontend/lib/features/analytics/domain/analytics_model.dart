// lib/features/analytics/domain/analytics_model.dart

class AnalyticsData {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final List<DailyTrend> dailyTrend;
  final List<TopProduct> topProducts;
  final List<CategorySplit> categorySplit;

  AnalyticsData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.dailyTrend,
    required this.topProducts,
    required this.categorySplit,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    // Se per qualche motivo kpi o charts sono null, usiamo una mappa vuota {}
    final kpi = json['kpi'] ?? {};
    final charts = json['charts'] ?? {};

    return AnalyticsData(
      // Usiamo ?? 0 per evitare qualsiasi crash se il backend non manda il dato
      totalRevenue: (kpi['totalRevenue'] ?? 0).toDouble(),
      totalOrders: (kpi['totalOrders'] ?? 0) as int,
      averageOrderValue: (kpi['averageOrderValue'] ?? 0).toDouble(),
      
      // Se le liste sono null, restituiamo un array vuoto []
      dailyTrend: (charts['dailyTrend'] as List?)?.map((e) => DailyTrend.fromJson(e)).toList() ?? [],
      topProducts: (charts['topProducts'] as List?)?.map((e) => TopProduct.fromJson(e)).toList() ?? [],
      categorySplit: (charts['categorySplit'] as List?)?.map((e) => CategorySplit.fromJson(e)).toList() ?? [],
    );
  }
}

class DailyTrend {
  final String date;
  final double revenue;
  final int orders;

  DailyTrend({required this.date, required this.revenue, required this.orders});

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'] ?? '1970-01-01',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: (json['orders'] ?? 0) as int,
    );
  }
}

class TopProduct {
  final String name;
  final int quantitySold;

  TopProduct({required this.name, required this.quantitySold});

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      name: json['name'] ?? 'Prodotto Sconosciuto',
      // 🚨 ECCO LA MAGIA: Cerca 'qty' (nuovo backend) o 'quantitySold' (vecchio), o usa 0
      quantitySold: (json['qty'] ?? json['quantitySold'] ?? 0) as int,
    );
  }
}

class CategorySplit {
  final String name;
  final double revenue;

  CategorySplit({required this.name, required this.revenue});

  factory CategorySplit.fromJson(Map<String, dynamic> json) {
    return CategorySplit(
      name: json['name'] ?? 'Sconosciuta', 
      revenue: (json['revenue'] ?? 0).toDouble()
    );
  }
}