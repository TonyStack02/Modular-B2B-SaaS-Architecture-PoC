// lib/features/auth/presentation/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import '../../../core/token_provider.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, UserModel?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserModel?> {

  @override
  Future<UserModel?> build() async {
    return null;
  }

  // --- LOGIN ---
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final response = await ref.read(authRepositoryProvider).login(email, password);

      // 🚨 RADAR: Stampiamo cosa ci manda VERAMENTE il backend!
      print("🚀 DEBUG LOGIN RESPONSE: ${response.data}");

      // 1. ESTRAIAMO E SALVIAMO IL TOKEN
      final token = response.data['access_token'];
      if (token != null) {
        ref.read(tokenProvider.notifier).state = token;
      }

      // 2. ESTRAZIONE SICURA DELL'UTENTE
      // Se esiste l'oggetto 'user' lo prendiamo, altrimenti usiamo la risposta intera
      Map<String, dynamic> userData = response.data['user'] ?? response.data;

      // Se NestJS ha messo il 'tenantId' fuori dall'oggetto 'user' (nella radice),
      // lo infiliamo a forza dentro 'userData' prima di passarlo al traduttore!
      if (response.data['tenantId'] != null && userData['tenantId'] == null) {
        userData['tenantId'] = response.data['tenantId'];
      }

      return UserModel.fromJson(userData);
    });
  }

  // --- LOGOUT ---
  void logout() {
    ref.read(tokenProvider.notifier).clearToken();
    state = const AsyncData(null);
  }

  // --- REGISTRAZIONE ---
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String restaurantName
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
        // A. CHIAMATA AL BACKEND
        await ref.read(authRepositoryProvider).register(
          email: email,
          password: password,
          name: name,
          restaurantName: restaurantName,
        );
    
        // B. LOGIN AUTOMATICO
        final loginResponse = await ref.read(authRepositoryProvider).login(email, password);
        
        // 🚨 RADAR: Stampiamo la risposta del login automatico!
        print("🚀 DEBUG REGISTER RESPONSE: ${loginResponse.data}");

        final token = loginResponse.data['access_token'];
        if (token != null) {
          ref.read(tokenProvider.notifier).state = token;
        }

        // C. ESTRAZIONE SICURA DELL'UTENTE (Come nel Login)
        Map<String, dynamic> userData = loginResponse.data['user'] ?? loginResponse.data;

        if (loginResponse.data['tenantId'] != null && userData['tenantId'] == null) {
          userData['tenantId'] = loginResponse.data['tenantId'];
        }

        return UserModel.fromJson(userData);
      });
    }
}