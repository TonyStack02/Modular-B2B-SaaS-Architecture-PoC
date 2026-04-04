// lib/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import 'package:go_router/go_router.dart';

// Usiamo ConsumerWidget invece di StatelessWidget per poter usare 'ref'
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. IL CONTROLLO DELLO STATO: Guardiamo (watch) se il controller sta caricando o ha errori.
    // Se lo stato cambia, questo intero metodo 'build' viene rieseguito.
    final authState = ref.watch(authControllerProvider);

    // Controller per leggere quello che Mario scrive nei campi di testo
    final emailController = TextEditingController(text: 'gioelegribaudo@gmail.com');
    final passwordController = TextEditingController(text: 'Juicy!');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Benvenuto su Juicy 🍊", style: TextStyle( fontSize: 28, fontWeight: FontWeight.bold),),
            const SizedBox(height: 32),

            // Campo Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Campo Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // 2. IL PULSANTE REATTIVO
            // Usiamo il 'when' di Riverpod per mostrare cose diverse in base allo stato.
            authState.maybeWhen(
              // Se sta caricando (AsyncLoading), mostriamo il cerchietto
              loading: () => CircularProgressIndicator(),
              // In tutti gli altri casi (default), mostriamo il pulsante
              orElse: () => ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  // 3. L'AZIONE: Chiamiamo il metodo login del nostro Controller.
                  // Usiamo 'ref.read' perché qui vogliamo eseguire un'azione, non stare in ascolto.
                  ref.read(authControllerProvider.notifier).login(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                },
                child: const Text("Entra"),
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // 1. LA NAVIGAZIONE: Chiediamo al router di portarci alla pagina di registrazione.
                // Usiamo context.push invece di context.go perché vogliamo che l'utente 
                // possa tornare indietro al login se cambia idea (usando il tasto "back" del telefono).
                context.push('/register'); 
              },
              child: const Text(
                "Non hai un account? Registrati ora",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),

            // 4. GESTIONE ERRORI: Se il login fallisce, mostriamo un messaggio
            if (authState.hasError) 
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text("Errore ${authState.error}", style: const TextStyle( color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}