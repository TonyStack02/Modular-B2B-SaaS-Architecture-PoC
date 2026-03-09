// lib/features/pos/presentation/cart_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart_item_model.dart';
import '../../catalog/domain/product_model.dart';
import '../data/pos_repository.dart';
import '../../auth/presentation/auth_controller.dart';

// Esponiamo il Carrello a tutta l'app
final cartProvider = NotifierProvider<CartNotifier, List<CartItemModel>>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<List<CartItemModel>> {
  @override
  List<CartItemModel> build() {
    return []; // All'inizio il carrello è vuoto!
  }

  // Aggiunge un prodotto o aumenta la quantità se c'è già
  void addProduct(ProductModel product) {
    // Controlliamo se la pizza è già nello scontrino
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Se c'è già, creiamo una nuova lista aggiornando solo la quantità di quella pizza
      final newState = [...state];
      final item = newState[existingIndex];
      newState[existingIndex] = item.copyWith(quantity: item.quantity + 1);
      state = newState;
    } else {
      // Se è una pizza nuova, aggiungiamo una nuova riga allo scontrino
      state = [...state, CartItemModel(product: product)];
    }
  }

  // Rimuove 1 unità di un prodotto (o cancella la riga se la quantità arriva a 0)
  void removeProduct(ProductModel product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final item = state[existingIndex];
      if (item.quantity > 1) {
        // Riduciamo la quantità
        final newState = [...state];
        newState[existingIndex] = item.copyWith(quantity: item.quantity - 1);
        state = newState;
      } else {
        // Se la quantità era 1, togliamo completamente la riga dal carrello
        state = state.where((item) => item.product.id != product.id).toList();
      }
    }
  }

  // Svuota completamente il carrello (es. dopo aver inviato l'ordine con successo)
  void clearCart() {
    state = [];
  }

  // Calcola il totale in Euro di tutto lo scontrino
  double get totalAmount {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

// Invia l'ordine al server
  Future<bool> checkout(WidgetRef ref, String resourceId) async {
    if (state.isEmpty) return false; // Non inviamo ordini vuoti!

    try {
      // 1. Recuperiamo l'ID del ristorante (tenantId) dall'utente attualmente loggato
      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception("Utente non loggato");

      // 2. Chiamiamo il fattorino
      final repository = ref.read(posRepositoryProvider);
      await repository.submitOrder(
        tenantId: user.tenantId,
        resourceId: resourceId , // L'ID del tavolo
        items: state, // Tutto il nostro carrello
      );

      // 3. Se va tutto bene, svuotiamo il carrello!
      clearCart();
      return true; // Ordine inviato con successo!

    } catch (e) {
      print("Errore durante il checkout: $e");
      return false; // Qualcosa è andato storto
    }
  }
}