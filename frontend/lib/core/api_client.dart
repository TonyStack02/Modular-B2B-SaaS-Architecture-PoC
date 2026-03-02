import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Questo è il provider che useremo in tutta l'app
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000', // L'indirizzo del tuo backend NestJS
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // Aggiungiamo un intercettore per il logging (comodissimo per il debug)
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  // Qui in futuro aggiungeremo l'intercettore per il Token JWT
  
  return dio;
});