// lib/features/orders/data/order_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(dioProvider));
});

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  // Scarica tutti gli ordini
  Future<List<OrderModel>> getOrders() async {
    final response = await _dio.get('/order');
    final List<dynamic> data = response.data;
    return data.map((json) => OrderModel.fromJson(json)).toList();
  }

  // Cambia lo stato di un ordine (es. in 'PAID')
  // 🌉 AGGIUNTO: parametro opzionale customerId per il programma fedeltà
  Future<void> updateOrderStatus(String orderId, String status, {String? customerId}) async {
    // Prepariamo i dati base (lo stato)
    final data = <String, dynamic>{
      'status': status,
    };

    // Se ci passano anche un cliente (es. durante il pagamento), lo aggiungiamo al pacchetto
    if (customerId != null) {
      data['customerId'] = customerId;
    }

    // Inviamo la PATCH al backend con i dati aggiornati
    await _dio.patch('/order/$orderId/status', data: data);
  }
}