// lib/features/hr/presentation/hr_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/employee_repository.dart';
import '../data/shift_repository.dart'; // 👈 Importiamo il nuovo deposito turni
import '../domain/shift_model.dart';    // 👈 Importiamo il modello turni
import '../domain/employee_model.dart';

// 📦 LO STATO DELLA PAGINA HR
class HrState {
  final List<EmployeeModel> employees;
  final List<ShiftModel> shifts; // 👈 La scatola ora ha anche il cassetto turni!

  HrState({
    required this.employees, 
    required this.shifts, // Obbligatorio inizializzarli entrambi
  });
}

// 🔌 IL PROVIDER
final hrControllerProvider = AsyncNotifierProvider<HrController, HrState>(() {
  return HrController();
});

// 🧠 IL CERVELLO (Il Controller)
class HrController extends AsyncNotifier<HrState> {
  
  @override
  Future<HrState> build() async {
    // Appena si apre la pagina, carichiamo tutto
    return _fetchData();
  }

  // 1. SCARICA I DATI (Dipendenti + Turni)
  Future<HrState> _fetchData() async {
    final employeeRepo = ref.read(employeeRepositoryProvider);
    final shiftRepo = ref.read(shiftRepositoryProvider);

    // Lanciamo le due richieste insieme per risparmiare tempo (Future.wait)
    // results[0] conterrà i dipendenti, results[1] i turni
    final results = await Future.wait([
      employeeRepo.getEmployees(),
      shiftRepo.getShifts(),
    ]);

    // Ritorniamo lo stato completo
    return HrState(
      employees: results[0] as List<EmployeeModel>,
      shifts: results[1] as List<ShiftModel>,
    );
  }

  // --- 👥 GESTIONE DIPENDENTI ---

  Future<void> addEmployee(Map<String, dynamic> employeeData) async {
    if (state.value == null) return;
    try {
      final newEmployee = await ref.read(employeeRepositoryProvider).createEmployee(employeeData);

      final currentState = state.value!;
      // Aggiorniamo la lista dipendenti ma TENIAMO i turni che c'erano già!
      state = AsyncData(HrState(
        employees: [...currentState.employees, newEmployee],
        shifts: currentState.shifts, 
      ));
    } catch (e) {
      print("Errore creazione dipendente: $e");
    }
  }

  Future<void> removeEmployee(String id) async {
    if (state.value == null) return;
    final currentState = state.value!;
    try {
      // Filtriamo via il dipendente eliminato
      final updatedList = currentState.employees.where((e) => e.id != id).toList();
      // Aggiorniamo la UI (Tenendo sempre i turni attuali)
      state = AsyncData(HrState(employees: updatedList, shifts: currentState.shifts));

      await ref.read(employeeRepositoryProvider).deleteEmployee(id);
    } catch (e) {
      print("Errore eliminazione: $e");
      state = AsyncData(await _fetchData()); // Se fallisce, ricarichiamo tutto dal server
    }
  }

  // --- 📅 GESTIONE TURNI ---

  // Funzione per aggiungere un turno (La useremo tra poco dal Planner)
  Future<void> addShift(Map<String, dynamic> shiftData) async {
    if (state.value == null) return;
    try {
      final repo = ref.read(shiftRepositoryProvider);
      final newShift = await repo.createShift(shiftData);

      final currentState = state.value!;
      // Aggiungiamo il turno e TENIAMO i dipendenti che c'erano già
      state = AsyncData(HrState(
        employees: currentState.employees,
        shifts: [...currentState.shifts, newShift],
      ));
    } catch (e) {
      print("Errore creazione turno: $e");
    }
  }

  // Funzione per eliminare un turno
  Future<void> removeShift(String id) async {
    if (state.value == null) return;
    final currentState = state.value!;
    try {
      // Togliamo il turno dalla lista locale
      final updatedShifts = currentState.shifts.where((s) => s.id != id).toList();
      state = AsyncData(HrState(employees: currentState.employees, shifts: updatedShifts));

      await ref.read(shiftRepositoryProvider).deleteShift(id);
    } catch (e) {
      print("Errore eliminazione turno: $e");
      state = AsyncData(await _fetchData());
    }
  }

  // Supporto per aggiornare i dati (es. stipendio)
  Future<void> updateEmployeeData(String id, Map<String, dynamic> updateData) async {
    if (state.value == null) return;
    try {
      await ref.read(employeeRepositoryProvider).updateEmployee(id, updateData);
      state = const AsyncLoading();
      state = AsyncData(await _fetchData());
    } catch (e) {
      print("Errore aggiornamento: $e");
    }
  }
}