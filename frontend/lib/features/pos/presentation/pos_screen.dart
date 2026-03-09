// lib/features/pos/presentation/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../catalog/presentation/catalog_controller.dart';
import 'cart_controller.dart';

class PosScreen extends ConsumerWidget {
  final String resourceId;

  const PosScreen({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ascoltiamo il Menu (per mostrare i prodotti)
    final catalogState = ref.watch(catalogControllerProvider);
    // Ascoltiamo il Carrello (per sapere quanti soldi stiamo facendo!)
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.read(cartProvider.notifier).totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Ordine 🛒', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      
      // IL CORPO: Mostra il Menu
      body: catalogState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text("Menu vuoto. Aggiungi prodotti prima!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), // Spazio per la barra in basso
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ExpansionTile(
                initiallyExpanded: true, // Teniamo le categorie già aperte per comodità
                title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                children: category.products.map((product) => ListTile(
                  leading: const Icon(Icons.fastfood, color: Colors.orange),
                  title: Text(product.name),
                  subtitle: Text("€${product.price.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                    onPressed: () {
                      // MAGIA: Aggiungiamo al carrello!
                      ref.read(cartProvider.notifier).addProduct(product);
                    },
                  ),
                )).toList(),
              );
            },
          );
        },
      ),

      // LA BARRA IN BASSO: Il nostro Scontrino rapido
      bottomSheet: cartItems.isEmpty 
          ? const SizedBox.shrink() // Se il carrello è vuoto, non mostriamo nulla
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
                        // INVIAMO L'ORDINE! 
                        final success = await ref.read(cartProvider.notifier).checkout(ref, resourceId);
                        
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Ordine inviato con successo!"), backgroundColor: Colors.green),
                          );
                          context.go('/home'); // Torniamo alla Dashboard per vedere i soldi!
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("❌ Errore durante l'invio"), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text("CONFERMA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}