// lib/features/bookings/domain/booking_model.dart

class BookingModel {
  final String id;
  final DateTime dateTime;
  final int guests;
  final String status;
  final String customerName;
  final String? customerPhone;
  final String? resourceName; // Il nome del tavolo, se è stato assegnato

  BookingModel({
    required this.id,
    required this.dateTime,
    required this.guests,
    required this.status,
    required this.customerName,
    this.customerPhone,
    this.resourceName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'].toString(),
      dateTime: DateTime.parse(json['dateTime']).toLocal(),
      // Se non c'è, mettiamo 2 di default
      guests: json['guests'] != null ? int.tryParse(json['guests'].toString()) ?? 2 : 2,
      status: json['status']?.toString() ?? 'CONFIRMED',
      // Forziamo sempre a stringa!
      customerName: json['customerName']?.toString() ?? 'Sconosciuto',
      customerPhone: json['customerPhone']?.toString(),
      resourceName: json['resource'] != null ? json['resource']['name']?.toString() : null,
    );
  }
}