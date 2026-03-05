// lib/features/catalog/presentation/catalog_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/catalog_repository.dart';
import '../domain/category_model.dart';

// Esponiamo il Controller al resto dell'app
final catalogControllerProvider = AsyncNotifierProvider<CatalogController,List<CategoryModel>>( () {
  return CatalogController();
});

class CatalogController extends AsyncNotifier<List<CategoryModel>> {
  
  @override
  Future<List<CategoryModel>> build() async {
    // Appena si apre la pagina del Menu, scarichiamo i dati!
    return _fetchCatalog();
  }

  // Funzione privata per chiamare il repository
  Future <List<CategoryModel>> _fetchCatalog() async {
    final repository = ref.read(catalogRepositoryProvider);
    return await repository.getCatalog();
  }

  // Ricarica manualmente il menu (es. Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchCatalog());
  }

  // --- LA MAGIA: CREARE UNA CATEGORIA ---
  Future<void> addCategory(String name) async {
    try{
      // 1. Chiamiamo il fattorino per spedire il nome al backend
      final repository = ref.read(catalogRepositoryProvider);
      await repository.createCategory(name);

      // 2. Se è andato tutto bene, ricarichiamo i dati!
      // In questo modo la nuova categoria apparirà magicamente a schermo
      await refresh();
    } catch(e) {
      // Se c'è un errore (es. no internet), potremmo gestirlo qui
      print("Errore durante la creazione della categoria: $e");
      rethrow; // Passiamo l'errore alla UI per mostrare un popup rosso
    }
  }

  // --- LA MAGIA: CREARE UN PRODOTTO ---
  Future<void> addProduct({
    required String name,
    String? description,
    required double price,
    required String categoryId
  }) async {
    try {
      // 1. Chiamiamo il fattorino
      final respository = ref.read(catalogRepositoryProvider);
      await respository.createProduct(
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
      );

      // 2. Ricarichiamo TUTTO il menu!
      // Così il nuovo prodotto apparirà magicamente dentro la sua categoria
      await refresh();
    } catch (e) {
      print("Errore durante la creazione del prodotto: $e");
      rethrow;
    }
  }
}