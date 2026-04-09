// lib/features/pos/data/pos_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/cart_item_model.dart';

// Esponiamo il repository
final posRepositoryProvider = Provider<PosRepository>((ref) {
  final dio = ref.read(dioProvider);
  return PosRepository(dio);
});

class PosRepository {
  final Dio _dio;

  PosRepository(this._dio);

  // Il metodo che spara l'ordine a NestJS!
  Future<void> submitOrder({
    required String tenantId,
    required String resourceId,
    String? customerId, 
    required List<CartItemModel> items,
  }) async {
    
    // 1. Traduciamo il nostro carrello nel formato esatto del tuo CreateOrderDto
    final payload = {
      'tenantId': tenantId,
      'resourceId': resourceId,
      'customerId': customerId,
      'items': items.map((cartItem) => {
        'productId': cartItem.product.id,
        'quantity': cartItem.quantity,
        'notes': cartItem.notes,
      }).toList(),
    };

    // 2. Inviamo la richiesta POST al tuo endpoint 'guest'
    await _dio.post('/guest/order', data: payload);
  }
}