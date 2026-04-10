import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'package:intl/date_symbol_data_local.dart'; // Ottimo, l'avevi già messo!

// 1. Aggiungiamo 'async' perché dobbiamo ASPETTARE che carichi la lingua
void main() async {
  // 2. Fondamentale: diciamo a Flutter di preparare il suo motore interno
  // PRIMA di fare operazioni asincrone, altrimenti va in crash
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 🇮🇹 Carichiamo il calendario in italiano!
  await initializeDateFormatting('it_IT', null);  

  // 4. Ora possiamo lanciare l'app in sicurezza
  runApp(const ProviderScope(child: JuicyApp()));
}

class JuicyApp extends ConsumerWidget { 
  const JuicyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leggiamo il router dal provider invece che dal file statico
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Juicy',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange, // Il brand Juicy
      ),
      routerConfig: router, // Il GoRouter che abbiamo configurato prima
    );
  }
}