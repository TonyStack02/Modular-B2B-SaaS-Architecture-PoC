// lib/features/bookings/presentation/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Ci serve per formattare l'orario (es. "20:30")
import 'booking_controller.dart';
import '../domain/booking_model.dart';

// Usiamo ConsumerStatefulWidget perché ci serve sia Riverpod (per i dati del backend)
// sia lo State locale (per ricordarci su quale giorno abbiamo cliccato)
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // Teniamo in memoria il giorno selezionato e il mese attualmente in vista
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // 1. ASCOLTIAMO IL CERVELLO DELLE PRENOTAZIONI
    final bookingsState = ref.watch(bookingControllerProvider);

    // Se ci sono dati li prendiamo, altrimenti lista vuota per non far crashare nulla
    final bookings = bookingsState.value ?? [];

    // 2. FILTRIAMO: Prendiamo solo le prenotazioni del giorno su cui abbiamo cliccato
    final selectedDayBookings = bookings.where((b) {
      if (_selectedDay == null) return false;
      return b.dateTime.year == _selectedDay!.year &&
             b.dateTime.month == _selectedDay!.month &&
             b.dateTime.day == _selectedDay!.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario 📅', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(bookingControllerProvider.notifier).refresh(),
          )
        ],
      ),
      body: Column(
        children: [
          // --- IL CALENDARIO INTERATTIVO ---
          TableCalendar<BookingModel>(
            locale: 'it_IT', // Mettiamo il calendario in italiano (Lunedì, Martedì...)
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            
            // Quando l'utente clicca su un giorno:
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // Aggiorniamo anche il focus
              });
            },
            
            // 🚨 LA MAGIA: Quando scorri a destra/sinistra per cambiare mese:
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              // Diciamo a NestJS: "Ehi, scaricami i dati di questo nuovo mese!"
              ref.read(bookingControllerProvider.notifier).changeMonth(focusedDay);
            },
            
            // LA MAGIA VISIVA: Mette il pallino sotto i giorni che hanno prenotazioni
            eventLoader: (day) {
              return bookings.where((b) {
                return b.dateTime.year == day.year &&
                       b.dateTime.month == day.month &&
                       b.dateTime.day == day.day;
              }).toList();
            },
            
            // Un po' di stile per farlo sembrare un'app premium
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
          ),
          
          const SizedBox(height: 8),
          const Divider(thickness: 2),
          
          // --- LA LISTA DELLE PRENOTAZIONI SOTTO AL CALENDARIO ---
          Expanded(
            child: bookingsState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : selectedDayBookings.isEmpty
                    ? Center(
                        child: Text(
                          "Nessuna prenotazione per il ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedDayBookings.length,
                        itemBuilder: (context, index) {
                          final booking = selectedDayBookings[index];
                          // Formattiamo l'ora per renderla leggibile (es. "20:30")
                          final timeString = DateFormat('HH:mm').format(booking.dateTime);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.shade100,
                                child: const Icon(Icons.person, color: Colors.orange),
                              ),
                              title: Text(
                                "${booking.customerName} - $timeString", 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                              ),
                              subtitle: Text(
                                "${booking.guests} Persone" + 
                                (booking.resourceName != null ? " • ${booking.resourceName}" : ""),
                                style: const TextStyle(fontSize: 15),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // In futuro qui potremo cliccare per modificare o cancellare la prenotazione!
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      
      // IL TASTO PER AGGIUNGERE UNA PRENOTAZIONE A MANO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookingBottomSheet(context, ref), // <-- ECCOLO!
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Prenotazione", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- IL FORM PER AGGIUNGERE LA PRENOTAZIONE ---
  void _showAddBookingBottomSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    // Di default, proponiamo il giorno che l'Owner sta già guardando sul calendario!
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    // Di default proponiamo l'orario classico della cena
    TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 30);
    int guests = 2; // Partiamo da 2 persone

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // FONDAMENTALE per far salire la tendina quando si apre la tastiera!
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // Usiamo StatefulBuilder per far funzionare i tastini + e - e l'orologio dentro il popup
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              // Questo padding magico alza il form quando si apre la tastiera del telefono
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Nuova Prenotazione", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  // 1. NOME CLIENTE
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nome Cliente (es. Marco Rossi)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // 2. TELEFONO (Opzionale)
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Telefono (Opzionale)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 20),

                  // 3. NUMERO PERSONE E ORARIO
                  // 3. SELETTORE DATA E ORA SULLA STESSA RIGA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // SELETTORE DATA
                      TextButton.icon(
                        onPressed: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 1000)),
                          );
                          if (pickedDate != null) {
                            setModalState(() => selectedDate = pickedDate);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                        // Mostriamo la data bella chiara!
                        label: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ),
                      
                      // SELETTORE ORA
                      TextButton.icon(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) => MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // Formato 24h
                              child: child!,
                            ),
                          );
                          if (time != null) {
                            setModalState(() => selectedTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time, color: Colors.blueAccent),
                        label: Text(selectedTime.format(context), style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. SELETTORE PERSONE (Spostato giù)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text("Ospiti:", style: TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                        onPressed: () {
                          if (guests > 1) setModalState(() => guests--);
                        },
                      ),
                      Text("$guests", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                        onPressed: () => setModalState(() => guests++),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // BOTTONE SALVA
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci almeno il nome!"), backgroundColor: Colors.red));
                        return;
                      }

                      // Uniamo la data scelta col calendario e l'ora scelta col bottoncino
                      final finalDateTime = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime.hour, selectedTime.minute,
                      );

                      // Invia tutto al backend!
                      final success = await ref.read(bookingControllerProvider.notifier).addBooking(
                        customerName: name,
                        customerPhone: phoneController.text.trim(),
                        guests: guests,
                        dateTime: finalDateTime,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context); // Chiude la tendina
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Prenotazione aggiunta!"), backgroundColor: Colors.green));
                      }
                    },
                    child: const Text("CONFERMA PRENOTAZIONE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }
}