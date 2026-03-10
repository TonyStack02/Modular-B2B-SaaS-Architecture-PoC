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
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _dio.patch('/order/$orderId/status', data: {'status': status});
  }
}