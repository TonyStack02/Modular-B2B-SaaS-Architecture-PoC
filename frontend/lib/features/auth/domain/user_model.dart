// 1. DEFINIZIONE DELLA CLASSE: Rappresenta l'utente nel nostro sistema Flutter.
// Usiamo i campi che abbiamo definito nel database Prisma.

class UserModel {
  final String id;
  final String email;
  final String role;
  final String token; // Il JWT per le prossime chiamate protette

  // IL COSTRUTTORE: Serve a creare l'oggetto specificando i valori.
  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
  });

  // 2. IL FACTORY CONSTRUCTOR 'fromJson': Questo è il vero "traduttore".++
  // Prende una Map (il JSON decodificato) e crea un'istanza di UserModel.
  // È fondamentale perché centralizza la logica di conversione in un solo punto.
  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      // Estraiamo i dati usando le chiavi che NestJS invia nella risposta.
      id: json['user']['id'] as String,
      email: json['user']['email'] as String,
      role: json['user']['role'] as String,
      token: json['access_token'] as String,
    );
  }
}