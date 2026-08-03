// lib/features/checklist/presentation/checklist_builder_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checklist_repository.dart';

// 1. DEFINIZIONE DEL PROVIDER ESATTAMENTE COME IN BOOKING_CONTROLLER
// Usiamo AsyncNotifierProvider classico, esplicitando il Controller e il tipo di dato dello stato (bool)
final checklistBuilderControllerProvider = AsyncNotifierProvider<ChecklistBuilderController, bool>(() {
  return ChecklistBuilderController(); // Ritorna l'istanza del controller senza sintassi strane
});

// 2. LA CLASSE CONTROLLER
// Estendiamo AsyncNotifier<bool> proprio come fai tu nel resto dell'app
class ChecklistBuilderController extends AsyncNotifier<bool> {
  
  // Il metodo build viene eseguito alla creazione del controller
  @override
  Future<bool> build() async {
    // Partiamo con uno stato 'false' (che per noi significa semplicemente "pronto, in attesa di salvare")
    return false; 
  }

  // 3. IL METODO PER INVIARE I DATI A NESTJS
  // Questa funzione viene chiamata dalla schermata quando premi il tasto "SALVA"
  Future<bool> createTemplate({
    required String tenantId, // ID del ristorante
    required String name, // Nome della checklist
    required List<String> daysOfWeek,  
    required List<String> targetTimes,
    String? description, // Descrizione opzionale
    required List<Map<String, dynamic>> tasks, // Le domande che hai creato nella UI
  }) async {
    
    // Mettiamo lo stato in Loading così la UI può mostrare (se vuole) un caricamento
    state = const AsyncLoading(); 
    
    try {
      // Leggiamo il repository usando ref.read per avere accesso alle chiamate API
      final repository = ref.read(checklistRepositoryProvider);
      
      // Costruiamo il pacchetto JSON (Payload) esattamente come se lo aspetta il backend NestJS
      final payload = {
        'tenantId': tenantId,
        'name': name,
        'daysOfWeek': daysOfWeek,
        'targetTimes': targetTimes,
        'description': description,
        'tasks': tasks, // Passiamo direttamente la lista creata dal form
      };

      // Lanciamo la richiesta POST verso il backend
      await repository.createTemplateHttp(payload);
      
      // Se non ci sono stati errori (nessun crash), settiamo lo stato a completato (true)
      state = const AsyncData(true); 
      
      // Ritorniamo true alla UI per dirgli di chiudere la pagina e dare il messaggio di successo
      return true;
      
    } catch (e) {
      // Se il server va in errore (es. 500) o cade la connessione, catturiamo l'errore
      print("🚨 Errore durante la creazione del template: $e");
      
      // Aggiorniamo lo stato interno salvando l'errore (utile se volessimo mostrarlo nella UI)
      state = AsyncError(e, StackTrace.current);
      
      // Diciamo alla UI che è fallito, così magari non chiude la pagina e ti fa riprovare
      return false;
    }
  }
}