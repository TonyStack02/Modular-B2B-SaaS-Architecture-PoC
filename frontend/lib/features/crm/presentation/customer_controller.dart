// lib/features/crm/presentation/customer_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repository.dart';
import '../domain/customer_model.dart';

// Questo provider espone il nostro Controller alla UI (la parte grafica)
final customerControllerProvider = AsyncNotifierProvider<CustomerController, List<CustomerModel>>(() {
  return CustomerController();
});

// Il nostro Controller estende AsyncNotifier: gestisce una lista di CustomerModel 
// e capisce da solo se sta caricando, se c'è un errore, o se i dati sono pronti.
class CustomerController extends AsyncNotifier<List<CustomerModel>> {
  
  // La funzione build() parte in automatico appena qualcuno "guarda" questo controller
  @override
  Future<List<CustomerModel>> build() async {
    // Chiamiamo subito la funzione per scaricare i dati iniziali
    return _fetchCustomers();
  }

  // Funzione privata per scaricare i dati tramite il Repository
  Future<List<CustomerModel>> _fetchCustomers() async {
    final repo = ref.read(customerRepositoryProvider); // Recuperiamo il corriere
    return await repo.getCustomers(); // Ci facciamo portare la lista
  }

  // AGGIUNGI UN CLIENTE E RESTITUISCI IL RISULTATO!
  Future<CustomerModel?> addCustomer(Map<String, dynamic> customerData) async {
    if (state.value == null) return null;

    try {
      final repo = ref.read(customerRepositoryProvider);
      final newCustomer = await repo.createCustomer(customerData);

      final currentList = state.value!;
      state = AsyncData([newCustomer, ...currentList]); 
      
      return newCustomer; // 👈 LA MAGIA: Ci facciamo ridare il cliente appena creato!
    } catch (e) {
      print("Errore creazione cliente: $e");
      return null;
    }
  }

  // ELIMINA UN CLIENTE
  Future<void> removeCustomer(String id) async {
    if (state.value == null) return;

    try {
      final currentList = state.value!;
      
      // Prima lo facciamo sparire dalla UI all'istante (senza aspettare il server)
      // Creiamo una nuova lista tenendo solo quelli che NON hanno quell'ID
      final updatedList = currentList.where((c) => c.id != id).toList();
      state = AsyncData(updatedList);

      // Poi lo cancelliamo fisicamente dal database
      await ref.read(customerRepositoryProvider).deleteCustomer(id);
      
    } catch (e) {
      print("Errore eliminazione cliente: $e");
      // Se il server va in errore (es. niente internet), ricarichiamo i dati originali
      // così il cliente che avevamo finto di cancellare riappare.
      state = AsyncData(await _fetchCustomers()); 
    }
  }
}