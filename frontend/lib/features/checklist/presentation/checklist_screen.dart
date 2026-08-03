// lib/features/checklist/presentation/checklist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checklist_controller.dart';
import 'checklist_builder_screen.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  final String instanceId;
  final String tenantId;
  final String currentEmployeeId; 

  const ChecklistScreen({
    super.key,
    required this.instanceId,
    required this.tenantId,
    required this.currentEmployeeId,
  });

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  
  @override
  void initState() {
    super.initState();
    // Appena entriamo nella pagina, diciamo al controller di caricare QUESTA checklist specifica
    Future.microtask(() {
      ref.read(checklistControllerProvider.notifier).loadChecklist(widget.instanceId, widget.tenantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo lo stato (che non richiede più di passare i parametri qui)
    final checklistState = ref.watch(checklistControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist di Turno', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: checklistState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange)),
        error: (err, stack) => Center(
          child: Text('Errore: $err', style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
        data: (checklist) {
          // Se il backend risponde picche (nessuna istanza attiva per oggi)
          if (checklist == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Nessuna checklist attiva in questo momento.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          if (checklist.tasks.isEmpty) {
            return Center(
              child: Text(
                "Nessun compito per questa checklist.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: checklist.tasks.length,
            itemBuilder: (context, index) {
              final task = checklist.tasks[index];
              
              final currentResult = checklist.results.where((r) => r.taskTemplateId == task.id).firstOrNull;
              final isChecked = currentResult?.value == 'true';
              final completedBy = currentResult?.employeeName;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      
                      if (task.type == 'BOOLEAN')
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(isChecked 
                              ? 'Fatto (da $completedBy)' 
                              : 'Da completare',
                              style: TextStyle(color: isChecked ? Colors.green : Colors.grey.shade700)
                          ),
                          value: isChecked,
                          activeColor: Colors.orange,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(checklistControllerProvider.notifier).updateTask(
                                taskTemplateId: task.id,
                                employeeId: widget.currentEmployeeId,
                                value: val.toString(),
                              );
                            }
                          },
                        )
                      else if (task.type == 'NUMBER')
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: currentResult != null 
                                ? 'Ultimo inserimento: ${currentResult.value}°C ($completedBy)' 
                                : 'Registra valore (es. temperatura)',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.thermostat),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              ref.read(checklistControllerProvider.notifier).updateTask(
                                taskTemplateId: task.id,
                                employeeId: widget.currentEmployeeId,
                                value: val.trim(),
                              );
                            }
                          },
                        )
                      else if (task.type == 'PHOTO')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade100,
                            foregroundColor: Colors.orange.shade900,
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(currentResult != null 
                              ? 'Foto aggiornata (da $completedBy)' 
                              : 'Scatta o Carica Foto'),
                          onPressed: () {
                            ref.read(checklistControllerProvider.notifier).updateTask(
                              taskTemplateId: task.id,
                              employeeId: widget.currentEmployeeId,
                              value: 'foto_fake_caricata.jpg',
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigazione verso il costruttore dei modelli
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChecklistBuilderScreen(tenantId: widget.tenantId),
            ),
          );
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Crea Modello", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      
    );
  }
}