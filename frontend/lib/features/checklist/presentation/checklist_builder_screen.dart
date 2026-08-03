// lib/features/checklist/presentation/checklist_builder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'checklist_builder_controller.dart';

class ChecklistBuilderScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const ChecklistBuilderScreen({super.key, required this.tenantId});

  @override
  ConsumerState<ChecklistBuilderScreen> createState() => _ChecklistBuilderScreenState();
}

class _ChecklistBuilderScreenState extends ConsumerState<ChecklistBuilderScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<Map<String, dynamic>> _tasks = [];

  // --- NUOVE VARIABILI PER LA SCHEDULAZIONE ---
  
  // Teniamo traccia dei giorni selezionati (es. "MONDAY", "FRIDAY")
  final Set<String> _selectedDays = {}; 
  
  // Lista degli orari scelti (es. "14:30", "23:45")
  final List<String> _selectedTimes = [];

  // Mappatura per comodità visiva: backend string -> label UI
  final Map<String, String> _weekDays = {
    'MONDAY': 'Lun', 'TUESDAY': 'Mar', 'WEDNESDAY': 'Mer', 
    'THURSDAY': 'Gio', 'FRIDAY': 'Ven', 'SATURDAY': 'Sab', 'SUNDAY': 'Dom'
  };

  void _addNewTask() {
    setState(() {
      _tasks.add({'title': '', 'type': 'BOOLEAN', 'order': _tasks.length});
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      for (int i = 0; i < _tasks.length; i++) {
        _tasks[i]['order'] = i;
      }
    });
  }

  // Apre il TimePicker nativo di Flutter per selezionare un nuovo orario
  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 30),
      builder: (context, child) => MediaQuery(
        // Forziamo il formato 24 ore così è più pulito da salvare nel DB
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), 
        child: child!,
      ),
    );

    if (time != null) {
      // Trasformiamo l'orario in una stringa "HH:mm" (es. "09:05" o "23:45")
      final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (!_selectedTimes.contains(formattedTime)) {
          _selectedTimes.add(formattedTime);
          // Ordiniamo gli orari dal più presto al più tardi in modo naturale
          _selectedTimes.sort(); 
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(checklistBuilderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea Nuovo Modello', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: builderState.isLoading ? null : _saveTemplate,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('SALVA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("Dettagli Generali", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nome Modello (es. Chiusura)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: "Istruzioni (Opzionale)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Divider(thickness: 2)),
          
          // 🔴 SEZIONE SCHEDULAZIONE (GIORNI E ORARI) 🔴
          const Text("Programmazione", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("In quali giorni deve attivarsi?", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          
          // GENERATORE DEI CHIPS DEI GIORNI DELLA SETTIMANA
          Wrap(
            spacing: 8.0,
            children: _weekDays.entries.map((entry) {
              final isSelected = _selectedDays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                selected: isSelected,
                selectedColor: Colors.orange,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(entry.key);
                    } else {
                      _selectedDays.remove(entry.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          const Text("A che ora deve essere compilata?", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: const Text("Aggiungi Orario"),
              ),
              const SizedBox(width: 16),
              
              // Mostra gli orari scelti sotto forma di "Chips" rimuovibili
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  children: _selectedTimes.map((time) {
                    return Chip(
                      label: Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.orange.shade100,
                      deleteIcon: const Icon(Icons.cancel, size: 18),
                      onDeleted: () {
                        setState(() => _selectedTimes.remove(time));
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Divider(thickness: 2)),
          
          // SEZIONE TASKS (Identica a prima)
          const Text("Lista Compiti (Tasks)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (_tasks.isEmpty)
            const Padding(padding: EdgeInsets.all(16.0), child: Text("Nessun compito aggiunto.", style: TextStyle(color: Colors.grey))),

          ..._tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: Colors.orange, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: task['title'],
                            decoration: const InputDecoration(labelText: "Cosa c'è da fare?", border: UnderlineInputBorder()),
                            onChanged: (val) => task['title'] = val, 
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeTask(index))
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Tipo di Risposta", border: OutlineInputBorder()),
                      value: task['type'],
                      items: const [
                        DropdownMenuItem(value: 'BOOLEAN', child: Text("✔️ Spunta (Fatto / Non Fatto)")),
                        DropdownMenuItem(value: 'NUMBER', child: Text("🌡️ Valore Numerico")),
                        DropdownMenuItem(value: 'PHOTO', child: Text("📸 Scatto Fotografico")),
                      ],
                      onChanged: (val) => setState(() => task['type'] = val!),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 80), 
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewTask,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Aggiungi Compito", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _saveTemplate() async {
    final name = _nameController.text.trim();
    
    // Controlli di sicurezza estesi
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci un nome per il modello!")));
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleziona almeno un giorno della settimana!")));
      return;
    }
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aggiungi almeno un orario di esecuzione!")));
      return;
    }
    if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aggiungi almeno un compito!")));
      return;
    }
    for (var task in _tasks) {
      if ((task['title'] as String).trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tutti i compiti devono avere un titolo!")));
        return;
      }
    }

    final success = await ref.read(checklistBuilderControllerProvider.notifier).createTemplate(
      tenantId: widget.tenantId,
      name: name,
      daysOfWeek: _selectedDays.toList(), // Convertiamo il Set in List
      targetTimes: _selectedTimes,
      description: _descController.text.trim(),
      tasks: _tasks,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Modello salvato con successo!"), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }
}