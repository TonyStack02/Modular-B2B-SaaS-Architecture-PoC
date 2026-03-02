import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

// 1. IL PROVIDER: Questo è l' "erogatore" del nostro oggetto.
// Serve a Riverpod per creare una sola volta l'AuthRepository e "passarlo" 
// a chiunque ne abbia bisogno nell'app, evitando variabili globali disordinate.
final authRepositoryProvider = Provider<AuthRepository>((ref){
  // Leggiamo il 'dioProvider' che abbiamo configurato nel file core per avere il client API.
  final dio = ref.read(dioProvider);
  return AuthRepository(dio);
});

// 2. LA CLASSE REPOSITORY: Questo è l'oggetto che contiene la logica di rete.
// Non decide cosa mostrare a schermo, si occupa solo di "parlare" con NestJS.
class AuthRepository {
  final Dio _dio;

  // Il costruttore richiede un oggetto Dio per funzionare (Dependency Injection).
  AuthRepository(this._dio);

  // 3. IL METODO LOGIN: Questa è la funzione materiale che "chiama" il backend.
  // Restituisce un 'Future<Response>', ovvero una promessa che il server risponderà.
  Future<Response> login(String email, String password) async {
    return await _dio.post(
      'auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  }
}