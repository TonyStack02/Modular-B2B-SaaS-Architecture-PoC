//  lib/features/dashboard/data/dashboard_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/dashboard_stats_model.dart';

// Esponiamo il repository al resto dell'app
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(dio);
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  // Il metodo che chiama il nostro nuovo Direttore d'Orchestra nel backend
  Future<DashboardStatsModel> getStats() async {
    // La chiamata all'endpoint
    final response = await _dio.get('/order/stats');

    // Passiamo i dati al nostro "traduttore"
    return DashboardStatsModel.fromJson(response.data);
  }

}