// lib/features/floor_plan/data/floor_plan_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/floor_plan/domain/map_element_model.dart';
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

  // Aggiorna le coordinate X e Y del tavolo sul database
  Future<void> updateResourcePosition(String resourceId, double x, double y) async {
    // Usiamo PATCH per aggiornare solo alcuni campi e non tutto l'oggetto
    await _dio.patch(
      '/resource/$resourceId', // Controlla che questa rotta esista nel tuo NestJS!
      data: {
        'positionX': x,
        'positionY': y,
      },
    );
  }

  // 1. Scarica i muri all'avvio
  Future<List<MapElementModel>> getMapElements() async {
    final response = await _dio.get('/map-element');
    return (response.data as List).map((json) => MapElementModel.fromJson(json)).toList();
  }

  // 2. Crea un nuovo muro
  Future<MapElementModel> createMapElement(String type, double x, double y, double w, double h, {String? text}) async {
    final response = await _dio.post('/map-element', data: {
      'type': type,
      'positionX': x,
      'positionY': y,
      'width': w,
      'height': h,
      if (text != null) 'text': text,
    });
    return MapElementModel.fromJson(response.data);
  }

  // 3. Salva la nuova posizione del muro dopo il trascinamento
  Future<void> updateMapElementPosition(String id, double x, double y) async {
    await _dio.patch('/map-element/$id', data: {
      'positionX': x,
      'positionY': y,
    });
  }

  // 💥 Elimina un elemento dal server
  Future<void> deleteMapElement(String id) async {
    await _dio.delete('/map-element/$id');
  }

  // 🛠️ Aggiorna dimensioni, rotazione o testo
  Future<void> updateMapElementProperties(String id, {double? w, double? h, double? rot, String? txt}) async {
    // Creiamo un pacchetto solo con i dati che ci servono veramente
    final data = <String, dynamic>{};
    if (w != null) data['width'] = w;
    if (h != null) data['height'] = h;
    if (rot != null) data['rotation'] = rot;
    if (txt != null) data['text'] = txt;

    await _dio.patch('/map-element/$id', data: data);
  }
}