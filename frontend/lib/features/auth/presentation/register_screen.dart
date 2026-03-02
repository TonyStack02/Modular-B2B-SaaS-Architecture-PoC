// lib/features/auth/presentation/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {

  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();

}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // 1. LA CHIAVE DEL FORM: Serve per "validare" tutti i campi insieme.
  final _formKey = GlobalKey<FormState>();

  // 2. I CONTROLLER: Servono per leggere il testo scritto da Mario.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _restaurantController = TextEditingController();

  @override
  void dispose() {
    // Pulizia: cancelliamo i controller quando la pagina viene chiusa per liberare memoria.
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _restaurantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo lo stato del controller (caricamento, errore, ecc.)
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Crea il tuo account Juicy!"),),
      body: SingleChildScrollView( // Permette di scorrere se la tastiera copre i campi
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // CAMPO NOME RISTORANTE
              TextFormField(
                controller: _restaurantController,
                decoration: const InputDecoration(labelText: 'Nome del Ristorante', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Inserisci il nome del locale' : null,
              ),
              const SizedBox(height: 16),

              //CAMPO NOME PROPRIETARIO
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Il tuo nome', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Inserisci il tuo nome' : null,
              ),
              const SizedBox(height: 16),

              //CAMPO EMAIL
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if(value == null || !value.contains('@')) return 'Inserisci una email valida';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CAMPO PASSWORD
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                // Validazione che rispecchia il @MinLength(6) del tuo backend
                validator: (value) => (value != null && value.length < 6) ? 'Minimo 6 caratteri' : null,
              ),
              const SizedBox(height: 32),

              // IL PULSANTE DI AZIONE
              authState.maybeWhen(
                loading: () => const CircularProgressIndicator(),
                orElse: () => ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  onPressed: () {
                    // 3. CONTROLLO VALIDITÀ: Se i campi sono OK, procediamo.
                    if (_formKey.currentState!.validate()) {
                      ref.read(authControllerProvider.notifier).register(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                        name: _nameController.text.trim(),
                        restaurantName: _restaurantController.text.trim(),
                      );
                    }
                  },
                  child: const Text("Registrati e Inizia"),
                ),
              ),

              // GESTIONE ERRORI DAL BACKEND (es. Email già esistente)
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text("Errore: ${authState.error}", style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

}