// lib/features/dashboard/domain/dashboard_stats_model.dart

class DashboardStatsModel {
  final int activeOrders;
  final double todayIncome;

  DashboardStatsModel({
    required this.activeOrders,
    required this.todayIncome
  });

  // Il traduttore dal JSON di NestJS al nostro oggetto Dart
  factory DashboardStatsModel.fromJson(Map<String, dynamic> json){
    return DashboardStatsModel(
      activeOrders: json['activeOrders'] ?? 0,
      todayIncome: (json['todayIncome'] ?? 0).toDouble()
    );
  }
}