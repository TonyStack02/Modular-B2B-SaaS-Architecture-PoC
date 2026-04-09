// lib/features/pos/presentation/widgets/cart_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../cart_controller.dart';
import '../../domain/cart_item_model.dart'; // Aggiusta il percorso del tuo model

class CartDrawer extends ConsumerWidget {
  final String resourceId;

  const CartDrawer({super.key, required this.resourceId});

  // 📝 FUNZIONE: Mostra il popup per scrivere la nota per la cucina
  void _showNoteDialog(BuildContext context, WidgetRef ref, CartItemModel item) {
    final noteController = TextEditingController(text: item.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note per ${item.product.name}'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: "es. Senza cipolla, Ben cotta...",
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              // Salviamo la nota nel carrello!
              ref.read(cartProvider.notifier).updateNote(item, noteController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Salva Nota', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.read(cartProvider.notifier).totalAmount;

    return Drawer(
      // Se vuoi renderlo più largo su tablet, puoi impostare un width fisso, 
      // altrimenti di default prende un terzo di schermo.
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.orange.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Comanda 🧾', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (cartItems.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      tooltip: "Svuota tutto",
                      onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                    )
                ],
              ),
            ),
            const Divider(height: 1, thickness: 2),

            // --- LISTA PIATTI ---
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(
                      child: Text("Il carrello è vuoto.\nAggiungi qualcosa dal menu!", 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NOME PIATTO E PREZZO TOTALE DELLA RIGA
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  Text("€${item.totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              
                              // NOTA (se presente, la mostriamo in rosso)
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text("📝 ${item.notes}", style: const TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic)),
                                ),

                              const SizedBox(height: 8),

                              // LA PULSANTIERA DI CONTROLLO (- / QTA / + / NOTE / CESTINO)
                              Row(
                                children: [
                                  // Tasto Cestino per eliminare tutta la riga
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                    onPressed: () => ref.read(cartProvider.notifier).removeRow(item),
                                  ),
                                  // Tasto Nota
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.blue),
                                    onPressed: () => _showNoteDialog(context, ref, item),
                                  ),
                                  const Spacer(),
                                  // Tasto Meno
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                    onPressed: () => ref.read(cartProvider.notifier).removeProduct(item),
                                  ),
                                  // Quantità
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  // Tasto Più
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => ref.read(cartProvider.notifier).addProduct(item.product, notes: item.notes), // Mantengo la nota se aumento!
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // --- FOOTER (PAGAMENTO) ---
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTALE", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text("€${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    onPressed: cartItems.isEmpty ? null : () async {
                      // 🚀 INVIO ORDINE AL BACKEND E AL WEBSOCKET!
                      final success = await ref.read(cartProvider.notifier).checkout(ref, resourceId);
                      
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Ordine inviato in cucina!"), backgroundColor: Colors.green));
                        context.pop(); // Torna alla Plancia Attività
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Errore durante l'invio"), backgroundColor: Colors.red));
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text("INVIA IN CUCINA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}