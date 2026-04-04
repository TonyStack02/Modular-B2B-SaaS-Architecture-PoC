// lib/features/management/presentation/management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../hr/presentation/hr_controller.dart';
import '../../hr/presentation/widgets/employee_card_widget.dart';

class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ascoltiamo il nostro "Cervello" HR
    final hrState = ref.watch(hrControllerProvider);

    // 2. Usiamo DefaultTabController per creare i menu a scorrimento in alto
    return DefaultTabController(
      length: 2, // Per ora facciamo 2 schede: Personale e Turni
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestione Risorse'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Personale'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Turni (Planner)'),
            ],
          ),
        ),
        
        // 3. Il corpo della pagina cambierà in base al Tab selezionato
        body: TabBarView(
          children: [
            
            // --- TAB 1: LISTA DEL PERSONALE ---
            hrState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Errore: $err")),
              data: (data) {
                // Se non c'è nessun dipendente, mostriamo un bel messaggio vuoto
                if (data.employees.isEmpty) {
                  return const Center(
                    child: Text("Nessun dipendente trovato.\nPremi il tasto + per assumerne uno!", textAlign: TextAlign.center),
                  );
                }
                
                // Se ci sono dipendenti, stampiamo le nostre bellissime Card!
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Lascia spazio in fondo per il tasto +
                  itemCount: data.employees.length,
                  itemBuilder: (context, index) {
                    final employee = data.employees[index];
                    return EmployeeCardWidget(
                      employee: employee,
                      onEdit: () {
                        // TODO: Apriremo il form pre-compilato
                        print("Cliccato Modifica su ${employee.firstName}");
                      },
                      onDelete: () {
                        // Richiamiamo la funzione di cancellazione del controller!
                        ref.read(hrControllerProvider.notifier).removeEmployee(employee.id);
                      },
                    );
                  },
                );
              },
            ),

            // --- TAB 2: IL PLANNER DEI TURNI (Vuoto per ora) ---
            const Center(
              child: Text(
                'Qui metteremo il calendario interattivo dei turni!\n(Step successivo 📅)', 
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),

        // 4. Il Tasto per assumere qualcuno! (Floating Action Button)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push('/add-employee');
          },
          icon: const Icon(Icons.person_add),
          label: const Text('Assumi'),
        ),
      ),
    );
  }
}