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
                      onPressed: () {
                        // 🚨 INVECE DI INVIARE SUBITO, APRIAMO IL MENU FEDELTÀ!
                        _showCheckoutOptions(context, ref);
                      },
                      child: const Text("CONFERMA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  // --- IL POPUP DI CHECKOUT (Anonimo o CRM) ---
  void _showCheckoutOptions(BuildContext context, WidgetRef ref) {
    String? selectedCustomerId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Leggiamo la rubrica in tempo reale
            final customersState = ref.watch(customerControllerProvider);
            final customers = customersState.value ?? [];

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Chiudi Conto", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text("Vuoi associare questo scontrino a un cliente per il programma fedeltà?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),

                  // SELETTORE CLIENTE DALLA RUBRICA
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Cerca in Rubrica (Opzionale)", 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star, color: Colors.orange),
                    ),
                    value: selectedCustomerId,
                    items: customers.map((c) {
                      return DropdownMenuItem<String>(
                        value: c.id,
                        child: Text("${c.firstName} ${c.lastName ?? ''} ${c.phone != null ? '(${c.phone})' : ''}"),
                      );
                    }).toList(),
                    onChanged: (value) => setModalState(() => selectedCustomerId = value),
                  ),
                  
                  const SizedBox(height: 24),

                  // BOTTONE INVIO DEFINITIVO
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      // Chiudiamo il popup di selezione
                      Navigator.pop(context);

                      // INVIAMO L'ORDINE (Passando l'ID cliente se è stato scelto, sennò sarà null!)
                      final success = await ref.read(cartProvider.notifier).checkout(ref, resourceId, customerId: selectedCustomerId);
                      
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ Ordine inviato con successo!"), backgroundColor: Colors.green),
                        );
                        context.go('/home'); // Torniamo alla home per vedere l'incasso salire!
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("❌ Errore durante l'invio"), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text(
                      selectedCustomerId == null ? "INVIA COME ANONIMO" : "INVIA E ASSEGNA PUNTI", 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }
}