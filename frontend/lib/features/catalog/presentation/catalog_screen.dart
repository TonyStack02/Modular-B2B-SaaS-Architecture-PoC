// lib/features/catalog/presentation/catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'catalog_controller.dart';
import '../domain/category_model.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ascoltiamo il nostro "Cervello"
    final catalogState = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Menu 🍕', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(catalogControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      
      // Il bottone galleggiante in basso a destra per creare le Categorie
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, ref),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuova Categoria", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      // Il corpo della pagina reagisce ai 3 stati: Caricamento, Errore, Dati
      body: catalogState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange)),
        error: (error, stack) => Center(child: Text('Errore: $error', style: const TextStyle(color: Colors.red))),
        data: (categories) {
          // Se la lista è vuota, mostriamo un bel messaggio di benvenuto
          if (categories.isEmpty) {
            return const Center(
              child: Text("Il menu è vuoto.\nCrea la tua prima categoria!", 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 18, color: Colors.grey)
              ),
            );
          }

          // Se ci sono categorie, disegniamo la lista!
          return RefreshIndicator(
            onRefresh: () => ref.read(catalogControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16), // Spazio per non coprire l'ultimo col bottone
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryTile(context, ref, category);
              },
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET PER LA SINGOLA CATEGORIA ---
  Widget _buildCategoryTile(BuildContext context, WidgetRef ref, CategoryModel category) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // ExpansionTile crea una tendina che si apre e si chiude!
      child: ExpansionTile(
        title: Text(category.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text("${category.products.length} prodotti", style: TextStyle(color: Colors.grey.shade600)),
        children: [
          // Se non ci sono prodotti, mostriamo un testo.
          if (category.products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Nessun prodotto in questa categoria."),
            )
          // Altrimenti, disegniamo una riga per ogni prodotto!
          else
            ...category.products.map((product) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.fastfood, color: Colors.white, size: 20),
              ),
              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(product.description ?? "Nessuna descrizione"),
              trailing: Text("€${product.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
            )),
            
          // Un bottone extra alla fine della tendina per aggiungere prodotti a QUESTA categoria (lo faremo dopo!)
          TextButton.icon(
            onPressed: () => _showAddProductDialog(context, ref, category.id),
            icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
            label: const Text("Aggiungi Prodotto", style: TextStyle(color: Colors.orange)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --- IL POPUP PER CREARE LA CATEGORIA ---
  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuova Categoria"),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: "es. Pizze, Bevande, Dolci",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Chiude il popup senza fare nulla
              child: const Text("Annulla", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  // Chiamiamo la magia del nostro Controller!
                  ref.read(catalogControllerProvider.notifier).addCategory(name);
                  Navigator.pop(context); // Chiudiamo il popup
                }
              },
              child: const Text("Salva", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- IL POPUP PER CREARE IL PRODOTTO ---
  void _showAddProductDialog(BuildContext context, WidgetRef ref, String categoryId) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuovo Prodotto"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nome (es. Margherita)"),
                  autofocus: true,
                ),
                const SizedBox(height: 8,),

                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Prezzo (es. 6.50)"),
                ),
                const SizedBox(height: 8,),

                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Descrizione (opzionale)"),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla", style: TextStyle(color: Colors.grey),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                final name = nameController.text.trim();
                // Sostituiamo eventuale virgola con il punto per i decimali (es. 6,50 diventa 6.50)
                final priceText = priceController.text.trim().replaceAll(',', '.');
                final price = double.tryParse(priceText) ?? 0.0;
                final desc = descController.text.trim();

                // Validazione base: nome pieno e prezzo maggiore di zero
                if (name.isNotEmpty && price >= 0){
                  ref.read(catalogControllerProvider.notifier).addProduct(
                    name: name,
                    price: price,
                    description: desc,
                    categoryId: categoryId
                  );
                  Navigator.pop(context); // Chiudiamo il popup
                }
              } ,
              child: const Text("Salva", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      }
    );

  }
}