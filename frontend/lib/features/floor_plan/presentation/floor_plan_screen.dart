// lib/features/floor_plan/presentation/floor_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'floor_plan_controller.dart';
import '../domain/area_model.dart';
import '../domain/resource_model.dart';
// 1. IMPORTIAMO IL CERVELLO DEGLI ORDINI CHE ABBIAMO CREATO IERI
import '../../orders/presentation/order_controller.dart'; 
import '../../orders/domain/order_model.dart';

class FloorPlanScreen extends ConsumerWidget {
  const FloorPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. ASCOLTIAMO ENTRAMBI I PROVIDER
    // floorPlanState contiene Aree e Tavoli (es. Sala 1, Tavolo 1)
    final floorPlanState = ref.watch(floorPlanControllerProvider);
    // ordersState contiene la lista degli scontrini ANCORA APERTI
    final ordersState = ref.watch(orderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aree e Tavoli 🗺️', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Quando aggiorniamo, chiediamo al backend sia i tavoli nuovi che gli ordini nuovi
              ref.read(floorPlanControllerProvider.notifier).refresh();
              ref.read(orderControllerProvider.notifier).refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAreaDialog(context, ref),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuova Area", style: TextStyle(color: Colors.white)),
      ),
      // Mostriamo il caricamento se ANCHE SOLO UNO dei due sta scaricando i dati
      body: floorPlanState.isLoading || ordersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : floorPlanState.when(
              loading: () => const SizedBox.shrink(),
              error: (e, stack) => Center(child: Text('Errore: $e')),
              data: (data) {
                final areas = data.areas;
                final allResources = data.resources;
                
                // Estraiamo la vera lista degli ordini, se è andata in errore mettiamo una lista vuota per non far crashare l'app
                final activeOrders = ordersState.value ?? [];

                if (areas.isEmpty) return const Center(child: Text("Nessuna area creata."));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
                  itemCount: areas.length,
                  itemBuilder: (context, index) {
                    final area = areas[index];
                    final areaResources = allResources.where((r) => r.areaId == area.id).toList();
                    
                    // Disegniamo il blocco dell'area (es. "Sala Interna") passandogli gli ordini attivi
                    return _buildAreaTile(context, ref, area, areaResources, activeOrders);
                  },
                );
              },
            ),
    );
  }

  // --- WIDGET PER LA SINGOLA AREA E I SUOI TAVOLI ---
  Widget _buildAreaTile(BuildContext context, WidgetRef ref, AreaModel area, List<ResourceModel> areaResources, List<OrderModel> activeOrders) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true, // Teniamolo aperto di default per comodità
        title: Text(area.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        children: [
          ...areaResources.map((table) {
            
            // 3. LA MAGIA: CERCHIAMO SE QUESTO TAVOLO HA UN ORDINE APERTO!
            // isOccupiend sarà 'null' se il tavolo è vuoto, altrimenti conterrà lo scontrino.
            final activeOrderForThisTable = activeOrders.where((order) => order.resourceId == table.id).firstOrNull;
            
            final isOccupied = activeOrderForThisTable != null;

            return ListTile(
              // Se è occupato pallino ROSSO, se è libero pallino VERDE
              leading: CircleAvatar(
                backgroundColor: isOccupied ? Colors.redAccent : Colors.green,
                child: Icon(Icons.table_restaurant, color: Colors.white, size: 20),
              ),
              title: Text(table.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              
              // Se è occupato, mostriamo quanti soldi ci sono sul conto finora
              subtitle: isOccupied 
                  ? Text("Conto aperto: €${activeOrderForThisTable.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                  : const Text("Tavolo libero", style: TextStyle(color: Colors.green)),
              
              trailing: isOccupied ? const Icon(Icons.receipt_long) : null,
              
              onTap: () {
                if (isOccupied) {
                  // Se è occupato e ci clicco, APRO IL CONTO!
                  _showBillBottomSheet(context, ref, activeOrderForThisTable);
                } else {
                  // Se è libero non faccio nulla (per ora). Per fare un ordine si passa dalla Dashboard.
                }
              },
            );
          }),
          TextButton.icon(
            onPressed: () => _showAddResourceDialog(context, ref, area.id), 
            icon: const Icon(Icons.add), label: const Text("Aggiungi Tavolo"),
          ),
        ],
      ),
    );
  }

  // --- IL MENU A TENDINA PER CHIUDERE IL CONTO ---
  void _showBillBottomSheet(BuildContext context, WidgetRef ref, OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Conto: ${order.resourceName}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const Divider(thickness: 2),
              
              // Mostriamo le pizze e le birre ordinate
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item.quantity}x ${item.productName}", style: const TextStyle(fontSize: 16)),
                    Text("€${(item.price * item.quantity).toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
                  ],
                ),
              )),
              
              const Divider(thickness: 2),
              Text("TOTALE: €${order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.right),
              const SizedBox(height: 20),
              
              // IL BOTTONE PER PAGARE E LIBERARE IL TAVOLO
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.payments, color: Colors.white, size: 28),
                label: const Text("PAGATO IN CONTANTI", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  // 1. Chiamiamo il backend per cambiare lo stato in PAID
                  final success = await ref.read(orderControllerProvider.notifier).payOrder(order.id);
                  
                  // 2. Se è andata bene, chiudiamo la tendina
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Conto chiuso! Tavolo liberato.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }

  // --- POPUP: CREA AREA ---
  void _showAddAreaDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuova Area"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: "es. Sala Interna, Dehor", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                ref.read(floorPlanControllerProvider.notifier).addArea(name);
                Navigator.pop(context);
              }
            },
            child: const Text("Salva", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- POPUP: CREA TAVOLO (RISORSA) ---
  void _showAddResourceDialog(BuildContext context, WidgetRef ref, String areaId) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuovo Tavolo"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: "es. Tavolo 1, Ombrellone 4", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            // 1. AGGIUNGIAMO 'async' QUI
            onPressed: () async { 
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                try {
                  // 2. METTIAMO 'await' PER ASPETTARE IL BACKEND
                  await ref.read(floorPlanControllerProvider.notifier).addResource(name, areaId);
                  
                  // 3. CHIUDIAMO LA FINESTRA SOLO SE VA TUTTO BENE
                  if (context.mounted) Navigator.pop(context); 
                  
                } catch (e) {
                  // 4. SE IL BACKEND RIFIUTA, MOSTRIAMO L'ERRORE!
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Errore: Impossibile creare il tavolo ($e)"), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text("Salva", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}