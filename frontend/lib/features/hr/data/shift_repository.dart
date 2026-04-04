// lib/features/hr/data/shift_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🚨 Importa il TUO api_client dove hai definito il dioProvider
import '../../../core/api_client.dart'; 
import '../domain/shift_model.dart';

// --- IL PROVIDER CHE MANCAVA ---
// Questo è quello che il Controller "non sa cos'è". 
// Ora lo stiamo definendo ufficialmente!
final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  // Recuperiamo il client Dio già configurato con i Token JWT
  final dio = ref.watch(dioProvider); 
  return ShiftRepository(dio);
});

class ShiftRepository {
  final Dio _dio;

  ShiftRepository(this._dio);

  // Scarica i turni dal backend NestJS
  Future<List<ShiftModel>> getShifts({DateTime? start, DateTime? end}) async {
    final response = await _dio.get(
      '/shift',
      // Passiamo eventuali filtri per data (es. solo oggi)
      queryParameters: {
        if (start != null) 'start': start.toUtc().toIso8601String(),
        if (end != null) 'end': end.toUtc().toIso8601String(),
      },
    );
    // Trasformiamo la lista JSON in oggetti ShiftModel
    return (response.data as List).map((json) => ShiftModel.fromJson(json)).toList();
  }

  // Crea un nuovo turno su Prisma
  Future<ShiftModel> createShift(Map<String, dynamic> shiftData) async {
    final response = await _dio.post('/shift', data: shiftData);
    return ShiftModel.fromJson(response.data);
  }

  // Elimina un turno
  Future<void> deleteShift(String id) async {
    await _dio.delete('/shift/$id');
  }
}