// lib/features/crm/domain/customer_model.dart

class CustomerModel {
  // --- CAMPI ANAGRAFICI ---
  final String id; // L'ID univoco generato dal database
  final String firstName; // Nome (obbligatorio)
  final String? lastName; // Cognome (opzionale, quindi col ?)
  final String? phone; // Telefono (il nostro ponte magico, opzionale)
  final String? email; // Email (opzionale)
  final String? notes; // Note varie (opzionale)

  // --- STATISTICHE CALCOLATE DAL BACKEND ---
  final int totalBookings; // Quante volte ha prenotato
  final int totalOrders; // Quanti ordini ha fatto
  final double totalSpent; // Quanti soldi ha speso in totale (in Euro)

  // Il costruttore per creare l'oggetto in Flutter
  CustomerModel({
    required this.id,
    required this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.notes,
    this.totalBookings = 0, // Se non ci sono dati, partiamo da 0
    this.totalOrders = 0,
    this.totalSpent = 0.0,
  });

  // La "Fabbrica" che prende il JSON grezzo del backend e lo converte in CustomerModel
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'].toString(), // Convertiamo sempre in stringa per sicurezza
      firstName: json['firstName'].toString(),
      lastName: json['lastName']?.toString(), // Se è null, resta null grazie al ?
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      notes: json['notes']?.toString(),
      
      // I numeri vanno parsati con attenzione: proviamo a leggerli dal JSON, 
      // se qualcosa va storto (es. arrivano come null), mettiamo 0 come paracadute.
      totalBookings: json['totalBookings'] != null ? int.parse(json['totalBookings'].toString()) : 0,
      totalOrders: json['totalOrders'] != null ? int.parse(json['totalOrders'].toString()) : 0,
      totalSpent: json['totalSpent'] != null ? double.parse(json['totalSpent'].toString()) : 0.0,
    );
  }
}