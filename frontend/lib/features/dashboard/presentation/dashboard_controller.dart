// lib/features/dashboard/presentation/dashboard_controller.dart


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_stats_model.dart';

// Provider che le nostre pagine "ascolteranno"
final dashboardControllerProvider = AsyncNotifierProvider<DashboardController, DashboardStatsModel>(() {
  return DashboardController();
});

class DashboardController extends AsyncNotifier<DashboardStatsModel> {
  
  @override
  Future<DashboardStatsModel> build() async {
    // Il metodo 'build' viene chiamato in automatico appena apri la schermata.
    // Diciamo a Flutter di scaricare subito le statistiche!
    return _fetchStats();
  }

  // Funzione privata per chiamare il repository
  Future<DashboardStatsModel> _fetchStats() async {
    final repository = ref.read(dashboardRepositoryProvider);
    return await repository.getStats();
  }

  // Funzione pubblica per ricaricare i dati a mano (es. "Tira giù per aggiornare")
  Future<void> refresh() async {
    // Mettiamo lo stato in caricamento
    state = const AsyncLoading();
    // Scarichiamo di nuovo i dati e aggiorniamo lo stato
    state = await AsyncValue.guard(() => _fetchStats());
  }
}