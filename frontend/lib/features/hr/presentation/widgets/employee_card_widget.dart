// lib/features/hr/presentation/widgets/employee_card_widget.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 👈 Ricordati di aggiungere 'url_launcher' nel pubspec.yaml se non lo hai!
import '../../domain/employee_model.dart';

class EmployeeCardWidget extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EmployeeCardWidget({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  // Funzione magica per aprire WhatsApp direttamente dal telefono
  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    
    // Rimuoviamo eventuali spazi dal numero
    final cleanPhone = phone.replaceAll(' ', '');
    // Creiamo il link per WhatsApp. (Se i numeri sono italiani, conviene aggiungere +39 in fase di salvataggio)
    final url = Uri.parse('https://wa.me/$cleanPhone');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("Impossibile aprire WhatsApp per $cleanPhone");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scegliamo un colore per il badge dello stato (Verde = Attivo, Grigio = Licenziato, Arancione = In Ferie)
    Color statusColor = Colors.green;
    String statusText = "Attivo";
    if (employee.status == 'TERMINATED') {
      statusColor = Colors.grey;
      statusText = "Ex-Dipendente";
    } else if (employee.status == 'ON_LEAVE') {
      statusColor = Colors.orange;
      statusText = "In Ferie/Malattia";
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INTESTAZIONE: Nome, Ruolo e Stato ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${employee.firstName} ${employee.lastName}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        employee.jobRole.toUpperCase(),
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Badge dello stato
                Chip(
                  label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            
            const Divider(height: 24),

            // --- DETTAGLI CONTRATTO E COSTI ---
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(Icons.euro, "Paga oraria", "€${employee.hourlyWage.toStringAsFixed(2)}"),
                ),
                Expanded(
                  child: _buildInfoRow(Icons.schedule, "Ore previste", "${employee.weeklyContractHours}h / sett."),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(Icons.beach_access, "Ferie residue", "${employee.vacationDaysTotal} gg"),
                ),
                Expanded(
                  child: _buildInfoRow(Icons.medical_services, "Giorni Malattia", "${employee.sickDaysTotal} gg"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- NOTE E CONTATTI ---
            if (employee.notes != null && employee.notes!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Note: ${employee.notes!}", style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- BOTTONIERA AZIONI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tasto WhatsApp (Appare solo se c'è un numero)
                if (employee.phone != null && employee.phone!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(employee.phone),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text("WhatsApp"),
                  )
                else
                  const SizedBox.shrink(),

                // Modifica ed Elimina
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      tooltip: "Modifica",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: "Elimina Dipendente",
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Funzioncina per disegnare velocemente le righine con icona e testo
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}