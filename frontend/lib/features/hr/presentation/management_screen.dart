// lib/features/management/presentation/management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Ci serve per scrivere i giorni (es. "Lun", "Mar")
import '../../hr/presentation/widgets/shift_card_widget.dart';
import '../../hr/presentation/hr_controller.dart';
import '../../hr/presentation/widgets/employee_card_widget.dart';
import '../../crm/presentation/customer_controller.dart';
import '../../crm/presentation/widgets/customer_card_widget.dart';

class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key});

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  
  // 🗓️ NUOVA VARIABILE: Il giorno attualmente selezionato nel Planner
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hrState = ref.watch(hrControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Risorse'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Personale'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Turni (Planner)'),
            Tab(icon: Icon(Icons.star), text: 'Clienti VIP'),
          ],
        ),
      ),
      
      body: TabBarView(
        controller: _tabController,
        children: [
          
          // --- TAB 1: LISTA DEL PERSONALE (Invariato) ---
          hrState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Errore: $err")),
            data: (data) {
              if (data.employees.isEmpty) {
                return const Center(child: Text("Nessun dipendente trovato.\nPremi il tasto + per assumerne uno!", textAlign: TextAlign.center));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: data.employees.length,
                itemBuilder: (context, index) {
                  final employee = data.employees[index];
                  return EmployeeCardWidget(
                    employee: employee,
                    onEdit: () => print("Modifica ${employee.firstName}"),
                    onDelete: () => ref.read(hrControllerProvider.notifier).removeEmployee(employee.id),
                  );
                },
              );
            },
          ),

          // --- TAB 2: IL PLANNER DEI TURNI CON CALENDARIO ---
          hrState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Errore: $err")),
            data: (data) {
              // 1. FILTRIAMO: Prendiamo SOLO i turni del giorno selezionato
              final dailyShifts = data.shifts.where((s) {
                return s.startTime.year == _selectedDate.year &&
                       s.startTime.month == _selectedDate.month &&
                       s.startTime.day == _selectedDate.day;
              }).toList();

              // 2. CALCOLIAMO: Il costo totale solo di QUESTO giorno specifico
              final totalDailyCost = dailyShifts.fold<double>(0, (sum, s) => sum + s.totalCost);

              return Column(
                children: [
                  // --- 🗓️ CALENDARIO ORIZZONTALE IN ALTO ---
                  _buildHorizontalCalendar(),

                  // --- 💰 HEADER RIEPILOGO COSTI ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.blueGrey.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Budget Personale", style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(
                              // Scriviamo la data formattata (es. "15 Aprile 2026")
                              DateFormat('dd MMMM yyyy', 'it_IT').format(_selectedDate), 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                        Text(
                          "€${totalDailyCost.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),

                  // --- 👥 LISTA TURNI DEL GIORNO ---
                  Expanded(
                    child: dailyShifts.isEmpty
                      ? const Center(child: Text("Nessun turno programmato per questa data."))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: dailyShifts.length,
                          itemBuilder: (context, index) {
                            final shift = dailyShifts[index];
                            return ShiftCardWidget(
                              shift: shift,
                              onDelete: () => ref.read(hrControllerProvider.notifier).removeShift(shift.id),
                            );
                          },
                        ),
                  ),
                ],
              );
            },
          ),
          // --- TAB 3: RUBRICA CLIENTI ---
          ref.watch(customerControllerProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Errore: $err")),
            data: (customers) {
              if (customers.isEmpty) {
                return const Center(child: Text("Nessun cliente in rubrica.\nPremi + per aggiungerne uno!"));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  return CustomerCardWidget(
                    customer: customers[index],
                    onDelete: () => ref.read(customerControllerProvider.notifier).removeCustomer(customers[index].id),
                  );
                },
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_currentIndex == 0) {
            context.push('/add-employee');
          } else if(_currentIndex == 1) {
            final currentState = ref.read(hrControllerProvider);
            currentState.whenData((data) {
              _showAddShiftDialog(context, ref, data);
            });
          } else if(_currentIndex == 2) {
            context.push('/add-customer');
          }
        },
        icon: Icon(
          _currentIndex == 0 ? Icons.person_add : 
          _currentIndex == 1 ? Icons.add_alarm : 
          Icons.person_add_alt_1 // Icona per il cliente
        ),
        label: Text(
          _currentIndex == 0 ? 'Assumi' : 
          _currentIndex == 1 ? 'Nuovo Turno' : 
          'Nuovo Cliente'
        ),
      ),
    );
  }

  // --- WIDGET CALENDARIO ORIZZONTALE ---
  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Generiamo 30 giorni (da 5 giorni fa a 25 giorni nel futuro)
        itemCount: 30, 
        // Spostiamo la vista iniziale circa su "oggi"
        controller: ScrollController(initialScrollOffset: 5 * 60.0), 
        itemBuilder: (context, index) {
          // Calcoliamo la data di questo specifico "quadratino"
          final date = DateTime.now().subtract(const Duration(days: 5)).add(Duration(days: index));
          
          // Controlliamo se è il giorno cliccato
          final isSelected = date.year == _selectedDate.year && 
                             date.month == _selectedDate.month && 
                             date.day == _selectedDate.day;

          // Se è "oggi", lo facciamo notare
          final isToday = date.year == DateTime.now().year && 
                          date.month == DateTime.now().month && 
                          date.day == DateTime.now().day;

          return GestureDetector(
            onTap: () {
              // Quando tappi un giorno, aggiorniamo la UI!
              setState(() => _selectedDate = date);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : (isToday ? Colors.blue.shade50 : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'it_IT').format(date).toUpperCase(), // Es. "LUN"
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${date.day}", // Es. "15"
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- POPUP CREAZIONE TURNO ---
  void _showAddShiftDialog(BuildContext context, WidgetRef ref, HrState data) {
    String? selectedEmployeeId;
    TimeOfDay start = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 23, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Turno per il ${DateFormat('dd/MM').format(_selectedDate)}"), // Mostriamo la data!
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Seleziona Dipendente"),
                    items: data.employees.map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text("${e.firstName} ${e.lastName}"),
                    )).toList(),
                    onChanged: (val) => setStateDialog(() => selectedEmployeeId = val),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text("Inizio Turno"),
                    trailing: Text(start.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: start);
                      if (picked != null) setStateDialog(() => start = picked);
                    },
                  ),
                  ListTile(
                    title: const Text("Fine Turno"),
                    trailing: Text(end.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: end);
                      if (picked != null) setStateDialog(() => end = picked);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
                ElevatedButton(
                  onPressed: selectedEmployeeId == null ? null : () {
                    // 🚨 MAGIA: Usiamo _selectedDate al posto di DateTime.now()
                    // Così il turno finisce esattamente nel giorno che hai tappato nel calendario!
                    final startDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, start.hour, start.minute);
                    final endDt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, end.hour, end.minute);

                    ref.read(hrControllerProvider.notifier).addShift({
                      'employeeId': selectedEmployeeId,
                      'startTime': startDt.toUtc().toIso8601String(),
                      'endTime': endDt.toUtc().toIso8601String(),
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Conferma"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}