// lib/features/crm/data/customer_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart'; // Importiamo il nostro client di rete con i token
import '../domain/customer_model.dart'; // Importiamo il modello appena creato

// Creiamo il provider globale per poter usare questo corriere in tutta l'app
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dio = ref.watch(dioProvider); // Recuperiamo il client Dio configurato
  return CustomerRepository(dio); // Lo passiamo alla classe
});

class CustomerRepository {
  final Dio _dio;

  // Costruttore: riceve l'istanza di Dio pronta all'uso
  CustomerRepository(this._dio);

  // 1. SCARICA TUTTI I CLIENTI
  Future<List<CustomerModel>> getCustomers() async {
    // Facciamo una richiesta GET alla rotta /customer del backend
    final response = await _dio.get('/customer');
    
    // Il backend ci risponde con una lista JSON. 
    // La mappiamo passandola alla nostra "Fabbrica" per ottenere una lista di oggetti Flutter.
    return (response.data as List).map((json) => CustomerModel.fromJson(json)).toList();
  }

  // 2. CREA UN NUOVO CLIENTE
  Future<CustomerModel> createCustomer(Map<String, dynamic> customerData) async {
    // Facciamo una POST inviando i dati inseriti dall'utente nel form
    final response = await _dio.post('/customer', data: customerData);
    
    // Ritorniamo il cliente appena creato (con il suo nuovo ID)
    return CustomerModel.fromJson(response.data);
  }

  // 3. ELIMINA UN CLIENTE
  Future<void> deleteCustomer(String id) async {
    // Richiesta DELETE passandogli l'ID da cancellare
    await _dio.delete('/customer/$id');
  }
}