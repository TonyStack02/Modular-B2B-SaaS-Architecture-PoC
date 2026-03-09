// lib/features/floor_plan/data/floor_plan_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/area_model.dart';
import '../domain/resource_model.dart';

final floorPlanRepositoryProvider = Provider<FloorPlanRepository>((ref) {
  return FloorPlanRepository(ref.read(dioProvider));
});

class FloorPlanRepository {
  final Dio _dio;
  FloorPlanRepository(this._dio);

  // --- AREE ---
  Future<List<AreaModel>> getAreas() async {
    final response = await _dio.get('/area');
    final List<dynamic> data = response.data;
    return data.map((json) => AreaModel.fromJson(json)).toList();
  }

  Future<void> createArea(String name) async{
    await _dio.post('/area',data: {'name': name});
  }

  // --- RISORSE (TAVOLI) ---
  Future<List<ResourceModel>> getResources() async{
    final response = await _dio.get('resource');
    final List<dynamic> data = response.data;
    return data.map((json) => ResourceModel.fromJson(json)).toList();
  }

  Future<void> createResource(String name, String areaId) async {
    await _dio.post('/resource', data: ({'name': name, 'areaId': areaId}));
  }
}