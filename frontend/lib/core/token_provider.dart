// lib/core/token_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IL PROVIDER: Usa NotifierProvider invece del vecchio StateProvider
final tokenProvider = NotifierProvider<TokenNotifier, String?>(() {
  return TokenNotifier();
});

// 2. IL NOTIFIER: La vera "cassaforte" intelligente
class TokenNotifier extends Notifier<String?> {
  @override
  String? build() {
    // All'avvio dell'app, il token è vuoto (nessuno è loggato)
    return null;
  }

  // Metodo per salvare il badge (lo useremo nel login)
  void saveToken(String token) {
    state = token;
  }

  // Metodo per distruggere il badge (lo useremo in futuro per il Logout!)
  void clearToken() {
    state = null;
  }
}