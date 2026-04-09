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
    return [];
  }

  // 1. Aggiunge un prodotto o aumenta la quantità se ESISTE GIA' UNA RIGA UGUALE (stesso prodotto, stesse note)
  void addProduct(ProductModel product, {String? notes}) {
    // Cerchiamo una riga che abbia lo STESSO prodotto e le STESSE identiche note
    final existingIndex = state.indexWhere(
        (item) => item.product.id == product.id && item.notes == notes
    );

    if (existingIndex >= 0) {
      final newState = [...state];
      final item = newState[existingIndex];
      newState[existingIndex] = item.copyWith(quantity: item.quantity + 1);
      state = newState;
    } else {
      // Se ha note diverse (o è la prima volta), facciamo una riga nuova!
      state = [...state, CartItemModel(product: product, notes: notes)];
    }
  }

  // 2. Rimuove 1 unità di un prodotto
  void removeProduct(CartItemModel itemToRemove) {
    // Cerchiamo l'indice ESATTO di quella riga (passiamo tutto l'oggetto CartItemModel per sicurezza)
    final existingIndex = state.indexOf(itemToRemove);
    if (existingIndex >= 0) {
      final item = state[existingIndex];
      if (item.quantity > 1) {
        final newState = [...state];
        newState[existingIndex] = item.copyWith(quantity: item.quantity - 1);
        state = newState;
      } else {
        removeRow(itemToRemove); // Se arriva a zero, la cancelliamo
      }
    }
  }

  // 3. Cancella brutalmente un'intera riga (es. se ho per sbaglio aggiunto 5 birre, premo l'icona del cestino)
  void removeRow(CartItemModel itemToRemove) {
    state = state.where((item) => item != itemToRemove).toList();
  }

  // 4. Aggiorna la nota di una riga esistente
  void updateNote(CartItemModel itemToUpdate, String newNote) {
    final existingIndex = state.indexOf(itemToUpdate);
    if (existingIndex >= 0) {
      final newState = [...state];
      newState[existingIndex] = newState[existingIndex].copyWith(notes: newNote);
      state = newState;
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<bool> checkout(WidgetRef ref, String resourceId, {String? customerId}) async {
    if (state.isEmpty) return false;

    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception("Utente non loggato");

      final repository = ref.read(posRepositoryProvider);
      await repository.submitOrder(
        tenantId: user.tenantId!,
        resourceId: resourceId ,
        customerId: customerId,
        items: state, 
      );

      clearCart();
      return true;

    } catch (e) {
      print("Errore checkout: $e");
      return false;
    }
  }
}