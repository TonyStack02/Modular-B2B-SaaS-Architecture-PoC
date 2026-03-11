// lib/features/bookings/data/booking_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/booking_model.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(dioProvider));
});

class BookingRepository {
  final Dio _dio;
  BookingRepository(this._dio);

  // Scarica tutte le prenotazioni di un mese specifico
  Future<List<BookingModel>> getBookingsByMonth(int year, int month) async {
    final response = await _dio.get('/booking/month/$year/$month');
    
    // 🚨 IL NOSTRO RADAR:
    print("📦 DATI RICEVUTI DA NESTJS PER IL MESE $month: ${response.data}");

    final List<dynamic> data = response.data;
    return data.map((json) => BookingModel.fromJson(json)).toList();
  }

  // Crea una nuova prenotazione
  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    await _dio.post('/booking', data: bookingData);
  }
}