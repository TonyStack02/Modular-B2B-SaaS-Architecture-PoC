// lib/features/pos/domain/cart_item_model.dart

import '../../catalog/domain/product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1 // Di base, quando aggiungo un prodotto, la quantità è 1
  });

  // Un metodo comodo per calcolare il totale di questa riga (es. 2 Margherite x 6.50€ = 13.00€)
  double get totalPrice => product.price * quantity;
  
  // Un metodo per creare una copia di questo oggetto con una quantità diversa 
  // (Riverpod preferisce oggetti immutabili)
  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      product: product,
      quantity: quantity ?? this.quantity
    );
  }
  
}