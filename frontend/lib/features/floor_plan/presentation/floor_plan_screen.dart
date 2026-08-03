// lib/features/floor_plan/presentation/floor_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'floor_plan_controller.dart';
import '../domain/area_model.dart';
import '../domain/resource_model.dart';
import '../../orders/presentation/order_controller.dart'; 
import '../../orders/domain/order_model.dart';

// 1. IMPORTIAMO IL WIDGET DELLA MAPPA CHE ABBIAMO CREATO SEPARATAMENTE
import 'widgets/interactive_map_widget.dart';

// 2. LO TRASFORMIAMO IN STATEFUL WIDGET
// Ci serve "Stateful" perché dobbiamo ricordarci se stiamo guardando la Lista o la Mappa
class FloorPlanScreen extends ConsumerStatefulWidget {
  const FloorPlanScreen({super.key});

  @override
  ConsumerState<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends ConsumerState<FloorPlanScreen> {
  // Questa variabile è il nostro interruttore: 
  // false = mostra la solita lista a tendina, true = mostra la nuova mappa interattiva!
  bool _isMapView = false;

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo i dati dal backend
    final floorPlanState = ref.watch(floorPlanControllerProvider);
    final ordersState = ref.watch(orderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aree e Tavoli 🗺️', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // L'INTERRUTTORE MAPPA / LISTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            // Un bel bottone che cambia icona e testo a seconda di cosa stiamo guardando
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              icon: Icon(_isMapView ? Icons.list : Icons.map),
              label: Text(_isMapView ? "Vedi Lista" : "Vedi Mappa"),
              onPressed: () {
                // Quando lo premiamo, invertiamo la variabile e ricarichiamo la UI
                setState(() {
                  _isMapView = !_isMapView;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(floorPlanControllerProvider.notifier).refresh();
              ref.read(orderControllerProvider.notifier).refresh();
            },
          ),
        ],
      ),
      // Il bottone in basso a destra scompare se siamo nella visuale Mappa (per non dare fastidio)
      floatingActionButton: _isMapView 
        ? null 
        : FloatingActionButton.extended(
            onPressed: () => _showAddAreaDialog(context, ref),
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Nuova Area", style: TextStyle(color: Colors.white)),
          ),
          
      // IL CORPO DELLA PAGINA
      body: floorPlanState.isLoading || ordersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : floorPlanState.when(
              loading: () => const SizedBox.shrink(),
              error: (e, stack) => Center(child: Text('Errore: $e')),
              data: (data) {
                final areas = data.areas;
                final allResources = data.resources;
                final activeOrders = ordersState.value ?? [];

                if (areas.isEmpty) return const Center(child: Text("Nessuna area creata."));

                // IL BIVIO MAGICO: COSA MOSTRIAMO?
                if (_isMapView) {
                  // SE L'INTERRUTTORE E' SU "MAPPA", CHIAMIAMO IL NOSTRO NUOVO WIDGET
                  // e gli passiamo tutti i tavoli da disegnare sulla tela!
                  return InteractiveMapWidget(resources: allResources, mapElements: data.mapElements);
                } else {
                  // ALTRIMENTI, MOSTRIAMO LA TUA VECCHIA E CARA LISTA A TENDINA
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      final areaResources = allResources.where((r) => r.areaId == area.id).toList();
                      return _buildAreaTile(context, ref, area, areaResources, activeOrders);
                    },
                  );
                }
              },
            ),
    );
  }

  // --- WIDGET PER LA SINGOLA AREA E I SUOI TAVOLI (Rimasto invariato) ---
  Widget _buildAreaTile(BuildContext context, WidgetRef ref, AreaModel area, List<ResourceModel> areaResources, List<OrderModel> activeOrders) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true, 
        title: Text(area.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        children: [
          ...areaResources.map((table) {
            final activeOrderForThisTable = activeOrders.where((order) => order.resourceId == table.id).firstOrNull;
            final isOccupied = activeOrderForThisTable != null;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isOccupied ? Colors.redAccent : Colors.green,
                child: const Icon(Icons.table_restaurant, color: Colors.white, size: 20),
              ),
              title: Text(table.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: isOccupied 
                  ? Text("Conto aperto: €${activeOrderForThisTable.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                  : const Text("Tavolo libero", style: TextStyle(color: Colors.green)),
              trailing: isOccupied ? const Icon(Icons.receipt_long) : null,
              onTap: () {
                if (isOccupied) {
                  _showBillBottomSheet(context, ref, activeOrderForThisTable);
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

  // --- IL MENU A TENDINA PER CHIUDERE IL CONTO (Rimasto invariato) ---
  void _showBillBottomSheet(BuildContext context, WidgetRef ref, OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Conto: ${order.resourceName}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const Divider(thickness: 2),
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.payments, color: Colors.white, size: 28),
                label: const Text("PAGATO IN CONTANTI", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final success = await ref.read(orderControllerProvider.notifier).payOrder(order.id);
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

  // --- POPUP: CREA AREA (Rimasto invariato) ---
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

  // --- POPUP: CREA TAVOLO (Rimasto invariato) ---
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
            onPressed: () async { 
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                try {
                  await ref.read(floorPlanControllerProvider.notifier).addResource(name, areaId);
                  if (context.mounted) Navigator.pop(context); 
                } catch (e) {
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