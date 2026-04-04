// lib/features/bookings/presentation/booking_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/booking_repository.dart';
import '../domain/booking_model.dart';

// Questo provider espone la lista di prenotazioni a tutta l'app
final bookingControllerProvider = AsyncNotifierProvider<BookingController, List<BookingModel>>(() {
  return BookingController();
});

class BookingController extends AsyncNotifier<List<BookingModel>> {
  DateTime _currentMonth = DateTime.now(); // Teniamo traccia del mese che stiamo guardando

  @override
  Future<List<BookingModel>> build() async {
    // Appena apri l'app, scarichiamo le prenotazioni di QUESTO mese
    return _fetchMonthBookings(_currentMonth.year, _currentMonth.month);
  }

  Future<List<BookingModel>> _fetchMonthBookings(int year, int month) async {
    final repository = ref.read(bookingRepositoryProvider);
    return await repository.getBookingsByMonth(year, month);
  }

  // Quando l'utente scorre il calendario al mese successivo, chiamiamo questa!
  Future<void> changeMonth(DateTime newMonth) async {
    _currentMonth = newMonth;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMonthBookings(newMonth.year, newMonth.month));
  }
  
  // Per ricaricare a mano se qualcuno prenota mentre stiamo guardando
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMonthBookings(_currentMonth.year, _currentMonth.month));
  }

  // Aggiunge la prenotazione e ricarica il mese per far apparire il pallino
  Future<bool> addBooking({
    required String customerName,
    String? customerPhone,
    required int guests,
    required DateTime dateTime,
    String? resourceId,
  }) async {
    try {
      final data = {
        'customerName': customerName,
        'customerPhone': customerPhone,
        'guests': guests,
        // Trasformiamo la data e l'ora nel formato ISO string che NestJS si aspetta!
        'dateTime': dateTime.toIso8601String(), 
        'resourceId': resourceId,
      };

      await ref.read(bookingRepositoryProvider).createBooking(data);
      
      // Ricarichiamo i dati di questo mese per aggiornare la UI
      await refresh(); 
      return true;
    } catch (e) {
      print("🚨 Errore durante la creazione della prenotazione: $e");
      return false;
    }
  }
}