// lib/features/pos/presentation/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../catalog/presentation/catalog_controller.dart';
import '../../crm/presentation/customer_controller.dart'; 
import 'cart_controller.dart';

class PosScreen extends ConsumerWidget {
  final String resourceId;

  const PosScreen({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogControllerProvider);
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.read(cartProvider.notifier).totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Ordine 🛒', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      
      body: catalogState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
        data: (categories) {
          if (categories.isEmpty) return const Center(child: Text("Menu vuoto."));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ExpansionTile(
                initiallyExpanded: true,
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                children: category.products.map((product) => ListTile(
                  leading: const Icon(Icons.fastfood, color: Colors.orange),
                  title: Text(product.name),
                  subtitle: Text("€${product.price.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                    onPressed: () {
                      ref.read(cartProvider.notifier).addProduct(product);
                    },
                  ),
                )).toList(),
              );
            },
          );
        },
      ),

      // LA BARRA IN BASSO
      bottomSheet: cartItems.isEmpty 
          ? const SizedBox.shrink()
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${cartItems.length} Prodotti", style: const TextStyle(color: Colors.grey)),
                        Text("Totale: €${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      onPressed: () async {
                        // 🚀 IL CAMERIERE SPARA L'ORDINE IN CUCINA (Anonimo e Aperto)
                        final success = await ref.read(cartProvider.notifier).checkout(ref, resourceId);
                        
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Ordine inviato!"), backgroundColor: Colors.green),
                          );
                          context.pop(); // Chiudiamo il POS e torniamo alla mappa
                        }
                      },
                      child: const Text("INVIA ORDINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}