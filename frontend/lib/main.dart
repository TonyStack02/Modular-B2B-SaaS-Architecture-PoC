import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';

void main() {
  // ProviderScope gestisce lo stato di tutti i nostri provider
  runApp(const ProviderScope(child: JuicyApp()));
}

class JuicyApp extends ConsumerWidget { // ConsumerWidget permette di leggere i provider
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