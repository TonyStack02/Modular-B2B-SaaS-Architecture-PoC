// lib/features/bookings/presentation/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; 
import 'booking_controller.dart';
import '../domain/booking_model.dart';
import '../../floor_plan/presentation/floor_plan_controller.dart';
import '../../floor_plan/domain/resource_model.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // 1. ASCOLTIAMO LE PRENOTAZIONI
    final bookingsState = ref.watch(bookingControllerProvider);
    final bookings = bookingsState.value ?? [];

    // 2. 🚨 ASCOLTIAMO LA MAPPA PER AVERE I TAVOLI REALI
    final floorPlanState = ref.watch(floorPlanControllerProvider);
    
    final List<ResourceModel> resources = floorPlanState.value?.resources ?? [];

    // Filtriamo le prenotazioni del giorno
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
          TableCalendar<BookingModel>(
            locale: 'it_IT',
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              ref.read(bookingControllerProvider.notifier).changeMonth(focusedDay);
            },
            eventLoader: (day) {
              return bookings.where((b) {
                return b.dateTime.year == day.year &&
                       b.dateTime.month == day.month &&
                       b.dateTime.day == day.day;
              }).toList();
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
          ),
          
          const SizedBox(height: 8),
          const Divider(thickness: 2),
          
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
                                "${booking.guests} Persone${booking.resourceName != null ? " • ${booking.resourceName}" : ""}",
                                style: const TextStyle(fontSize: 15),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      
      // PASSAGGIO DELLA LISTA TAVOLI AL POPUP
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookingBottomSheet(context, ref, resources), 
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Prenotazione", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- IL FORM RICEVE LA LISTA TAVOLI COME PARAMETRO (resourcesList) ---
  // --- IL FORM RICEVE LA LISTA TAVOLI COME PARAMETRO (resourcesList) ---
  void _showAddBookingBottomSheet(BuildContext context, WidgetRef ref, List<ResourceModel> resourcesList) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedResourceId;
    
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 20, minute: 30);
    int guests = 2; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nome Cliente (es. Marco Rossi)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Telefono (Opzionale ma CONSIGLIATO per Rubrica)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                        label: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ),
                      
                      TextButton.icon(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (context, child) => MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), 
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
                  const SizedBox(height: 16),
                  
                  // 🚨 IL MENU A TENDINA "VERO" LEGATO AL DATABASE DEI TAVOLI!
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assegna Tavolo (Opzionale)", 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_restaurant),
                    ),
                    value: selectedResourceId,
                    // Se ci sono tavoli, creiamo le voci. Se no, lasciamo il menu vuoto.
                    items: resourcesList.map((res) {
                      return DropdownMenuItem<String>(
                        value: res.id, // L'ID vero del DB
                        child: Text(res.name), // Il nome che gli hai dato (es. Tavolo 4)
                      );
                    }).toList(),
                    onChanged: (value) => setModalState(() => selectedResourceId = value),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci almeno il nome!"), backgroundColor: Colors.red));
                        return;
                      }

                      final finalDateTime = DateTime(
                        selectedDate.year, selectedDate.month, selectedDate.day,
                        selectedTime.hour, selectedTime.minute,
                      );

                      final success = await ref.read(bookingControllerProvider.notifier).addBooking(
                        customerName: name,
                        customerPhone: phoneController.text.trim(),
                        guests: guests,
                        dateTime: finalDateTime,
                        resourceId: selectedResourceId,
                      );

                      if (success && context.mounted) {
                        Navigator.pop(context); 
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