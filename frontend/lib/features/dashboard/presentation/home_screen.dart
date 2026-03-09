// lib/features/dashboard/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'dashboard_controller.dart';
import '../../floor_plan/presentation/floor_plan_controller.dart'; // Per leggere i tavoli

// Usiamo ConsumerWidget invece di StatelessWidget perché abbiamo bisogno di 'ref'
// per parlare con i nostri Provider (il ponte verso il backend).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  // WidgetRef ref è il nostro "pass per il backstage": ci permette di accedere ai dati.
  Widget build( BuildContext context, WidgetRef ref) {

    // 1. L'OSSERVATORE: Diciamo a Flutter di "fissare" il dashboardController.
    // Se il controller cambia stato (es. da caricamento a dati pronti), 
    // questa funzione build riparte da sola.
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold),),
        actions: [
          // TASTO REFRESH MANUALE:
          IconButton(
            // Usiamo ref.read(... .notifier) perché vogliamo CHIAMARE una funzione (refresh),
            // non vogliamo solo stare a guardare i dati.
            onPressed: () => ref.read(dashboardControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh)
          ),
          // LOGOUT
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: Colors.redAccent,),
          ),
        ],
      ) ,

      // ---------------------------------------------------------
      // 2. IL MAGICO .when(): Questo è il cuore di Riverpod.
      // Invece di fare mille "if (loading) ... else if (error) ...",
      // specifichiamo i 3 scenari possibili in modo pulito.
      // ---------------------------------------------------------
      body: dashboardState.when(
        // SCENARIO A: Sto ancora aspettando i dati dal server NestJS.
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange,),),

        // SCENARIO B: Il server è offline o internet non va.
        error: (error, stack) => Center(child: Text('Errore: ${error}', style: const TextStyle(color: Colors.red),),),

        // SCENARIO C: I dati sono arrivati! 'stats' è l'oggetto DashboardStatsModel.
        data: (stats) {
          // Pull-to-refresh: trascina verso il basso per aggiornare.
          return RefreshIndicator(
            onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text("Riepilogo di Oggi 📅", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                const SizedBox(height: 24),

                // ROW & EXPANDED: Fondamentale per il layout.
                // Row mette gli elementi uno di fianco all'altro.
                // Expanded dice: "Prendi tutto lo spazio disponibile a metà, non di più",
                // così le card non escono dallo schermo (Overflow).
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Ordini Attivi",
                        // toStringAsFixed(2) trasforma 150.5 in "150.50" (formato valuta)
                        value: "€${stats.todayIncome.toStringAsFixed(2)}",
                        icon: Icons.euro,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24,),

                // INIZIO AZIONI RAPIDE
                const Text("Azioni Rapide ⚡", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                const SizedBox(height: 16,),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🛒 BOTTONE 1: LA CASSA (Per vendere)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () => _showTableSelection(context), // <-- Va al POS
                      icon: const Icon(Icons.add_shopping_cart, size: 28, color: Colors.white),
                      label: const Text("NUOVO ORDINE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    
                    const SizedBox(height: 16), // Spazio tra i due bottoni
                    
                    // 📝 BOTTONE 2: IL RETROBOTTEGA (Per modificare il menu)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueGrey, // Colore diverso per distinguerlo
                      ),
                      onPressed: () => context.push('/catalog'), // <-- Va al CATALOGO
                      icon: const Icon(Icons.edit_document, size: 28, color: Colors.white),
                      label: const Text("GESTIONE MENU", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),

                    const SizedBox(height: 16), // Spazio tra i due bottoni

                    // 🗺️ BOTTONE 3: GESTIONE TAVOLI E AREE
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo, // Un bel colore per la mappa
                      ),
                      onPressed: () => context.push('/floor-plan'), // <-- Va alle Aree
                      icon: const Icon(Icons.table_restaurant, size: 28, color: Colors.white),
                      label: const Text("MAPPA TAVOLI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }
  // ---------------------------------------------------------
  // 3. WIDGET HELPER: Il trucco per non impazzire.
  // Invece di scrivere 100 righe per ogni Card, creiamo una "stampante"
  // a cui passiamo solo i dati che cambiano (titolo, valore, icona, colore).
  // ---------------------------------------------------------
  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 3, // L'ombra sotto la card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cerchietto colorato attorno all'icona
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Colore molto sfumato
                shape: BoxShape.circle
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  // --- LA TENDINA PER SCEGLIERE IL TAVOLO ---
  void _showTableSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Usiamo un Consumer per leggere i dati della Mappa in tempo reale
        return Consumer(
          builder: (context, ref, child) {
            final floorState = ref.watch(floorPlanControllerProvider);

            return floorState.when(
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.orange))),
              error: (e, stack) => Center(child: Text("Errore: $e")),
              data: (data) {
                final areas = data.areas;
                final resources = data.resources;

                if (resources.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("Nessun tavolo disponibile!\nCreane uno dalla Mappa Tavoli.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                  );
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Seleziona il Tavolo 👇", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: areas.length,
                        itemBuilder: (context, index) {
                          final area = areas[index];
                          final tableInArea = resources.where((r) => r.areaId == area.id).toList();
                          
                          if (tableInArea.isEmpty) return const SizedBox.shrink();

                          return ExpansionTile(
                            initiallyExpanded: true,
                            title: Text(area.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            children: tableInArea.map((table) => ListTile(
                              leading: const Icon(Icons.table_restaurant, color: Colors.orange),
                              title: Text(table.name),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context); // Chiudiamo la tendina
                                context.push('/pos/${table.id}'); // E ANDIAMO IN CASSA CON L'ID VERO!
                              },
                            )).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}