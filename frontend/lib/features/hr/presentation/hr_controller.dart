// lib/features/hr/presentation/hr_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/employee_repository.dart';
import '../domain/employee_model.dart';

// 📦 LO STATO DELLA PAGINA HR
// Creiamo una classe "Scatola" che conterrà tutto quello che serve alla pagina HR.
// Per ora ha solo la lista dei dipendenti, ma quando faremo il calendario (Step 2),
// aggiungeremo qui anche la lista dei turni (Shifts), tutto in un unico posto!
class HrState {
  final List<EmployeeModel> employees;

  HrState({required this.employees});
}

// 🔌 IL PROVIDER
// Questo è l'interruttore che la UI (la pagina grafica) userà per accendere e parlare con il Controller
final hrControllerProvider = AsyncNotifierProvider<HrController, HrState>(() {
  return HrController();
});

// 🧠 IL CERVELLO (Il Controller)
class HrController extends AsyncNotifier<HrState> {
  
  // Questa funzione scatta in automatico appena l'Owner apre la pagina "Gestione Personale".
  @override
  Future<HrState> build() async {
    // Chiamiamo subito la funzione per scaricare i dati dal database
    return _fetchData();
  }

  // 1. SCARICA I DATI
  Future<HrState> _fetchData() async {
    // Andiamo a bussare al Repository (Il fattorino)
    final repo = ref.read(employeeRepositoryProvider);
    // Gli diciamo: "Vai su NestJS e portami la lista dei dipendenti"
    final employees = await repo.getEmployees();
    
    // Mettiamo i dipendenti appena scaricati dentro la nostra "Scatola" e la chiudiamo
    return HrState(employees: employees);
  }

  // 2. CREA UN DIPENDENTE
  Future<void> addEmployee(Map<String, dynamic> employeeData) async {
    // Se la pagina non ha ancora caricato i dati, blocchiamo tutto per evitare errori
    if (state.value == null) return;

    try {
      final repo = ref.read(employeeRepositoryProvider);
      
      // Chiediamo al backend di creare il dipendente su Prisma.
      // Il backend ci risponde ridandoci il dipendente appena creato (con il suo ID vero)
      final newEmployee = await repo.createEmployee(employeeData);

      // Aggiorniamo la RAM del telefono SUBITO, senza dover ricaricare la pagina!
      // Prendiamo i vecchi dipendenti e ci aggiungiamo quello nuovo in fondo alla lista.
      final currentState = state.value!;
      state = AsyncData(HrState(
        employees: [...currentState.employees, newEmployee],
      ));
    } catch (e) {
      // Se qualcosa va storto (es. niente internet o errore 500 del server) stampiamo l'errore
      print("Errore durante la creazione del dipendente: $e");
      // Qui in futuro potremmo aggiungere un comando per mostrare un popup di errore rosso sulla UI
    }
  }

  // 3. AGGIORNA UN DIPENDENTE
  Future<void> updateEmployeeData(String id, Map<String, dynamic> updateData) async {
    if (state.value == null) return;

    try {
      // Mandiamo la modifica a NestJS (es. "Cambia lo stipendio a 15€")
      await ref.read(employeeRepositoryProvider).updateEmployee(id, updateData);

      // Ora dobbiamo aggiornare lo schermo del telefono.
      // Invece di riscaricare tutti i dipendenti (che consuma giga e rallenta l'app),
      // cerchiamo il dipendente modificato e gli ricarichiamo i dati "freschi"
      
      // NOTA: Per fare un aggiornamento locale perfetto al 100%, la via più semplice 
      // e sicura in questi casi complessi è richiamare il _fetchData() per risincronizzare
      // le date e i calcoli complessi del backend. 
      // È velocissimo e ci evita bug visivi assurdi.
      state = const AsyncLoading(); // Facciamo apparire la rotellina per un decimo di secondo
      state = AsyncData(await _fetchData()); // Riscarichiamo la lista aggiornata
      
    } catch (e) {
      print("Errore durante l'aggiornamento del dipendente: $e");
    }
  }

  // 4. ELIMINA UN DIPENDENTE
  Future<void> removeEmployee(String id) async {
    if (state.value == null) return;
    
    final currentState = state.value!;

    try {
      // Prima di chiamare il server, lo facciamo "sparire" subito dallo schermo!
      // È un trucco visivo (Optimistic UI) che fa sembrare l'app fulminea.
      // Creiamo una nuova lista tenendo tutti TRANNE quello con l'ID da cancellare
      final updatedList = currentState.employees.where((e) => e.id != id).toList();
      
      // Aggiorniamo la UI con la lista pulita
      state = AsyncData(HrState(employees: updatedList));

      // Ora, in background mentre l'Owner non se ne accorge, mandiamo la richiesta di DELETE a NestJS
      await ref.read(employeeRepositoryProvider).deleteEmployee(id);
      
    } catch (e) {
      print("Errore durante l'eliminazione: $e");
      // Se il server rifiuta l'eliminazione (magari la connessione è caduta), 
      // dovremmo rimettere il dipendente al suo posto richiamando _fetchData().
      state = AsyncData(await _fetchData());
    }
  }
}