import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// 1. IL PROVIDER: Questo espone il nostro Controller a tutta l'app.
// Usiamo 'AsyncNotifierProvider' perché il login è un'operazione asincrona (richiede tempo).
// Questo permette alla UI di reagire automaticamente quando lo stato cambia.
final authControllerProvider = AsyncNotifierProvider<AuthController, UserModel?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserModel?> {

  // 2. IL METODO BUILD: Questo è l'inizializzatore dello stato.
  // All'avvio dell'app, lo stato dell'utente è 'null' (nessuno è loggato).
  @override
  Future<UserModel?> build() async {
    return null;
  }

  // 3. IL METODO LOGIN: La funzione che la pagina di Login chiamerà.
  Future<void> login(String email, String password) async {
    // Diciamo alla UI: "Ehi, sto caricando!" (Farà apparire il cerchietto).
    state = const AsyncLoading();

    // 'guard' è una funzione di Riverpod che cattura gli errori automaticamente.
    state = await AsyncValue.guard(() async {
      // Chiamiamo il Repository che abbiamo creato prima.
      final response = await ref.read(authRepositoryProvider).login(email, password);

      // Trasformiamo il JSON ricevuto dal backend NestJS in un oggetto UserModel.
      final user = UserModel.fromJson(response.data);

      // Qui in futuro salveremo il token nel telefono per non dover rifare il login.

      return user; // Lo stato diventa l'utente loggato!
    });
  }

  // 4. LOGOUT: Semplice e pulito.
  void logout() {
    state = const AsyncData(null);
  }

  //5: REGISTRAZIONE
  // Riceviamo i 4 campi che il tuo Backend si aspetta nel RegisterDto
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String restaurantName
  }) async {
    // 1. STATO DI CARICAMENTO: Diciamo all'app di mostrare il cerchietto.
    // Questo blocca il pulsante "Registrati" per evitare click multipli.
    state = const AsyncLoading();

    // 2. ESECUZIONE PROTETTA: Usiamo AsyncValue.guard per catturare eventuali errori (es. email duplicata)
    state = await AsyncValue.guard(() async {
        // A. CHIAMATA AL BACKEND: Chiediamo al Repository di creare il Tenant e l'Owner
        await ref.read(authRepositoryProvider).register(
          email: email,
          password: password,
          name: name,
          restaurantName: restaurantName,
        );
    
        // B. LOGIN AUTOMATICO: Una volta creato l'utente, dobbiamo ottenere il "badge" (JWT)
        // Chiamiamo il metodo login che abbiamo già scritto.
        final loginResponse = await ref.read(authRepositoryProvider).login(email, password);

        // C. TRASFORMAZIONE: Prendiamo il JSON della risposta del login e lo trasformiamo nel Modello
        final user = UserModel.fromJson(loginResponse.data);

        // D. FINE: Restituiamo l'utente. Riverpod aggiornerà lo stato e il Router ci porterà in Home!
        return user;
      });
  
    }
}   