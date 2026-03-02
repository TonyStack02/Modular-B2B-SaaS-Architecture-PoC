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
}   