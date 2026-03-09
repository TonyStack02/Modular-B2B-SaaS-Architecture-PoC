// lib/features/floor_plan/presentation/floor_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'floor_plan_controller.dart';
import '../domain/area_model.dart';

class FloorPlanScreen extends ConsumerWidget {
  const FloorPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ascoltiamo il nostro Cervello della mappa
    final floorPlanState = ref.watch(floorPlanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aree e Tavoli 🗺️', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(floorPlanControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      
      // Bottone gigante per creare una nuova Area (es. Sala Interna)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAreaDialog(context, ref),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuova Area", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: floorPlanState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (error, stack) => Center(child: Text('Errore: $error', style: const TextStyle(color: Colors.red))),
        data: (data) {
          final areas = data.areas;
          final allResources = data.resources;

          if (areas.isEmpty) {
            return const Center(
              child: Text("Nessuna area creata.\nAggiungi la prima (es. Terrazza)!", 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 18, color: Colors.grey)
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(floorPlanControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16, left: 16, right: 16),
              itemCount: areas.length,
              itemBuilder: (context, index) {
                final area = areas[index];
                // Filtriamo solo i tavoli che appartengono a QUESTA area
                final areaResources = allResources.where((r) => r.areaId == area.id).toList();
                
                return _buildAreaTile(context, ref, area, areaResources);
              },
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET PER LA SINGOLA AREA E I SUOI TAVOLI ---
  Widget _buildAreaTile(BuildContext context, WidgetRef ref, AreaModel area, List areaResources) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(area.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text("${areaResources.length} tavoli", style: TextStyle(color: Colors.grey.shade600)),
        children: [
          if (areaResources.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Nessun tavolo in questa area."),
            )
          else
            ...areaResources.map((resource) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.table_restaurant, color: Colors.white, size: 20),
              ),
              title: Text(resource.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            
          // Bottone per aggiungere un Tavolo a QUESTA area
          TextButton.icon(
            onPressed: () => _showAddResourceDialog(context, ref, area.id), 
            icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
            label: const Text("Aggiungi Tavolo", style: TextStyle(color: Colors.blueAccent)),
          ),
          const SizedBox(height: 8),
        ],
      ),
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