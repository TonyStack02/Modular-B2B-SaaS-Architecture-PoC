//C:\Users\Samsung\Desktop\juicy_project\frontend\lib\core\api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_provider.dart'; // Importiamo la cassaforte

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.41.0.25:3000/', //  10.0.2.2:3000 localhost:3000 per pc funziona
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // IL NOSTRO INTERCEPTOR
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // 1. Apriamo la cassaforte
      final token = ref.read(tokenProvider);
      
      // 2. Se c'è il badge, lo appuntiamo sulla richiesta (Header Authorization)
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      
      // 3. Lasciamo partire la richiesta
      return handler.next(options);
    },
  ));

  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  
  return dio;
});