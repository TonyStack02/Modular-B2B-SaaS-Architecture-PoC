// lib/features/hr/presentation/widgets/shift_card_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Per formattare l'ora (es. 18:30)
import '../../domain/shift_model.dart';

class ShiftCardWidget extends StatelessWidget {
  final ShiftModel shift;
  final VoidCallback onDelete;

  const ShiftCardWidget({super.key, required this.shift, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Calcoliamo il costo del turno (Ore * Paga Oraria)
    final double cost = shift.totalCost;
    final String startTime = DateFormat('HH:mm').format(shift.startTime);
    final String endTime = DateFormat('HH:mm').format(shift.endTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.access_time, color: Colors.blue),
        ),
        title: Text(
          "${shift.employee?.firstName ?? 'Dipendente'} ${shift.employee?.lastName ?? ''}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("$startTime - $endTime (${shift.durationInHours.toStringAsFixed(1)} ore)"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mostriamo il costo di questo turno in verde
            Text(
              "€${cost.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}