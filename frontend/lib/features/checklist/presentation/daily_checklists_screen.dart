// lib/features/checklist/presentation/daily_checklists_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checklist_repository.dart';
import '../domain/checklist_model.dart';
import 'checklist_screen.dart'; // La schermata di dettaglio che abbiamo già!
import 'checklist_builder_screen.dart'; // Il costruttore per il titolare

// 1. IL PROVIDER PER SCARICARE LA LISTA
// Usiamo un FutureProvider base perché ci serve solo per fare una lettura al volo quando apriamo la pagina.
final dailyChecklistsProvider = FutureProvider.autoDispose.family<List<ChecklistInstanceModel>, String>((ref, tenantId) async {
  final repository = ref.read(checklistRepositoryProvider);
  return await repository.getDailyChecklistsList(tenantId);
});


// 2. LA SCHERMATA UI
class DailyChecklistsScreen extends ConsumerWidget {
  final String tenantId;
  final String currentEmployeeId; // Ci serve da passare poi alla schermata di dettaglio

  const DailyChecklistsScreen({
    super.key,
    required this.tenantId,
    required this.currentEmployeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ci mettiamo in ascolto del provider passando il tenantId
    final dailyState = ref.watch(dailyChecklistsProvider(tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine di Oggi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Bottone per ricaricare la pagina a mano se serve
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dailyChecklistsProvider(tenantId)),
          )
        ],
      ),
      body: dailyState.when(
        // FASE 1: Caricamento
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange)),
        
        // FASE 2: Errore di connessione
        error: (err, stack) => Center(child: Text('Errore: $err', style: const TextStyle(color: Colors.red))),
        
        // FASE 3: Dati ricevuti dal server
        data: (checklists) {
          // Se il locale non ha impostato checklist per oggi (o in generale)
          if (checklists.isEmpty) {
            return const Center(
              child: Text(
                "Nessuna routine prevista per oggi.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Disegniamo la lista delle routine
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: checklists.length,
            itemBuilder: (context, index) {
              final instance = checklists[index];
              
              // Capiamo se è completata per cambiare l'icona
              final isCompleted = instance.status == 'COMPLETED';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  
                  // Icona che cambia colore in base allo stato
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.access_time, 
                      color: isCompleted ? Colors.green : Colors.orange.shade900
                    ),
                  ),
                  
                  // Titolo e orario della checklist
                  title: Text(
                    instance.templateName, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                  subtitle: Text(
                    "Da compilare alle ${instance.targetTime}", 
                    style: const TextStyle(fontSize: 14)
                  ),
                  
                  trailing: const Icon(Icons.chevron_right),
                  
                  // AL CLICK: Apriamo la schermata di dettaglio che abbiamo costruito all'inizio!
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChecklistScreen(
                          instanceId: instance.id, // Passiamo l'ID reale dell'istanza
                          tenantId: tenantId,
                          currentEmployeeId: currentEmployeeId,
                        ),
                      ),
                    ).then((_) {
                      // Quando torniamo indietro dal dettaglio, ricarichiamo la lista 
                      // per aggiornare lo stato (PENDING -> COMPLETED se l'ha finita)
                      ref.refresh(dailyChecklistsProvider(tenantId));
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      
      // IL TASTO PER IL TITOLARE: Permette di creare un nuovo modello
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChecklistBuilderScreen(tenantId: tenantId),
            ),
          );
        },
        backgroundColor: Colors.blueGrey,
        icon: const Icon(Icons.build, color: Colors.white),
        label: const Text(
          "Crea Modello", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}