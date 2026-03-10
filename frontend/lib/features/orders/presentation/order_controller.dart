// lib/features/orders/presentation/order_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_repository.dart';
import '../domain/order_model.dart';

final orderControllerProvider = AsyncNotifierProvider<OrderController,List<OrderModel>>(() {
  return OrderController();
});

class OrderController extends AsyncNotifier<List<OrderModel>> {
  @override 
  Future<List<OrderModel>> build() async {
    return _fetchOrders();
  }

  Future<List<OrderModel>> _fetchOrders() async {
    try {
      print("⏳ Provo a scaricare gli ordini...");
      
      // 1. Chiamiamo il backend
      final orders = await ref.read(orderRepositoryProvider).getOrders();
      print("✅ Ordini totali trovati nel DB: ${orders.length}");

      // 2. Filtriamo solo quelli da pagare
      final activeOrders = orders.where((o) => o.status != 'PAID' && o.status != 'CANCELLED').toList();
      print("🔴 Ordini ANCORA APERTI (da colorare di rosso): ${activeOrders.length}");

      return activeOrders;
      
    } catch (e, stacktrace) {
      // SE C'È UN ERRORE SILENZIOSO, ORA LO VEDREMO URLARE IN CONSOLE!
      print("🚨 ERRORE FATALE NELLA LETTURA ORDINI: $e");
      print(stacktrace);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchOrders());
  }

  // Funzione per chiudere il conto!
  Future<bool> payOrder(String orderId) async {
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(orderId, 'PAID');
      await refresh(); // Ricarichiamo la lista per far sparire l'ordine pagato
      return true;
    } catch (e) {
      print("Errore durante il pagamento: $e");
      return false;
    }
  } 
}