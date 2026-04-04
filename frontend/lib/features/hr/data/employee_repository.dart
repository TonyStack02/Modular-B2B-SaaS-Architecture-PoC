// lib/features/hr/data/employee_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/employee_model.dart';

// Creiamo il provider per poter richiamare questo repository da qualsiasi parte dell'app
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return EmployeeRepository(dio);
});

class EmployeeRepository {
  final Dio _dio;

  // Passiamo l'istanza di Dio già configurata (con il token JWT e l'URL di base)
  EmployeeRepository(this._dio);

  // 1. SCARICA TUTTI I DIPENDENTI
  Future<List<EmployeeModel>> getEmployees() async {
    // Facciamo una richiesta GET alla rotta /employee di NestJS
    final response = await _dio.get('/employee');
    // Trasformiamo la lista JSON in una lista di EmployeeModel grazie alla nostra fabbrica
    return (response.data as List).map((json) => EmployeeModel.fromJson(json)).toList();
  }

  // 2. CREA UN NUOVO DIPENDENTE
  // Passiamo una mappa (Map<String, dynamic>) con tutti i dati compilati nel form
  Future<EmployeeModel> createEmployee(Map<String, dynamic> employeeData) async {
    // Facciamo una richiesta POST inviando i dati
    final response = await _dio.post('/employee', data: employeeData);
    // NestJS ci restituisce il dipendente appena creato (con il suo nuovo ID), lo trasformiamo e lo ritorniamo
    return EmployeeModel.fromJson(response.data);
  }

  // 3. AGGIORNA UN DIPENDENTE ESISTENTE
  // Ci serve l'ID del dipendente e i dati da modificare
  Future<void> updateEmployee(String id, Map<String, dynamic> updateData) async {
    // Usiamo PATCH perché stiamo modificando solo alcuni campi, non tutto
    await _dio.patch('/employee/$id', data: updateData);
  }

  // 4. ELIMINA UN DIPENDENTE
  Future<void> deleteEmployee(String id) async {
    // Richiesta DELETE passandogli l'ID nell'URL
    await _dio.delete('/employee/$id');
  }
}