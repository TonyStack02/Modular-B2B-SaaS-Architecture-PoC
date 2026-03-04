// lib/features/catalog/data/catalog_repository.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/category_model.dart';

// Esponiamo il Repository al resto dell'app
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final dio = ref.read(dioProvider); // Il nostro client HTTP con l'Interceptor per il Token!
  return CatalogRepository(dio);
});

class CatalogRepository {
  final Dio _dio;

  CatalogRepository(this._dio);

  // 1. SCARICA TUTTO IL MENU (GET /catalog)
  Future<List<CategoryModel>> getCatalog() async {
    // Bussiamo alla porta del backend
    final response = await _dio.get('/catalog');

    // Il backend ci risponde con una lista grezza (JSON).
    // La trasformiamo in una bellissima lista di CategoryModel!
    final List<dynamic> data = response.data;
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }
  
  // 2. CREA UNA NUOVA CATEGORIA (POST /catalog/category)
  Future<void> createCategory(String name) async {
    // Mandiamo al backend SOLO quello che si aspetta: il nome!
    await _dio.post(
      '/catalog/category',
      data: {'name': name}
    );
  }
}