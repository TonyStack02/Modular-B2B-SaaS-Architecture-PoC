// lib/features/pos/presentation/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/presentation/catalog_controller.dart';
import 'cart_controller.dart';
import 'widgets/cart_drawer.dart'; 

class PosScreen extends ConsumerWidget {
  final String resourceId;

  const PosScreen({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogControllerProvider);
    final cartItems = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu 🍕', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // 🛒 L'ICONA DEL CARRELLO CON IL NUMERO DI PRODOTTI
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Badge(
              label: Text(cartItems.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              isLabelVisible: cartItems.isNotEmpty,
              backgroundColor: Colors.red,
              child: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.shopping_cart, size: 28),
                    onPressed: () {
                      // Apre il menu laterale di destra
                      Scaffold.of(context).openEndDrawer();
                    },
                  );
                }
              ),
            ),
          ),
        ],
      ),
      
      // 🚀 IL NOSTRO NUOVO SUPER CARRELLO LATERALE
      endDrawer: CartDrawer(resourceId: resourceId),
      
      body: catalogState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
        data: (categories) {
          if (categories.isEmpty) return const Center(child: Text("Menu vuoto."));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ExpansionTile(
                initiallyExpanded: true,
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                children: category.products.map((product) => ListTile(
                  leading: const Icon(Icons.fastfood, color: Colors.orange),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("€${product.price.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                    onPressed: () {
                      // Aggiunge la pizza al carrello e mostra un mini-avviso
                      ref.read(cartProvider.notifier).addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${product.name} aggiunto!"), 
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        )
                      );
                    },
                  ),
                )).toList(),
              );
            },
          );
        },
      ),
    );
  }
}