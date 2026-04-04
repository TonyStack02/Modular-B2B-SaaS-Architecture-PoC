// lib/features/crm/presentation/widgets/customer_card_widget.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Ci serve sempre per WhatsApp
import '../../domain/customer_model.dart';

class CustomerCardWidget extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onDelete; // Funzione per quando premiamo il cestino

  const CustomerCardWidget({
    super.key, 
    required this.customer, 
    required this.onDelete
  });

  // Funzione per aprire WhatsApp (uguale a quella dei dipendenti)
  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(' ', '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INTESTAZIONE: Nome e Cestino ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Un bel cerchio con l'iniziale del cliente
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        customer.firstName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${customer.firstName} ${customer.lastName ?? ''}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        // Mostriamo il telefono se c'è
                        if (customer.phone != null)
                          Text(customer.phone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                // Tasto Elimina
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            
            const Divider(height: 24),

            // --- LE STATISTICHE VITALI (Il vero valore del CRM) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(Icons.restaurant, "Ordini", customer.totalOrders.toString()),
                _buildStatColumn(Icons.calendar_month, "Prenotazioni", customer.totalBookings.toString()),
                // Questo è il numero più importante: il LTV (Life Time Value)
                _buildStatColumn(Icons.euro, "Spesa Totale", "€${customer.totalSpent.toStringAsFixed(2)}", color: Colors.green),
              ],
            ),

            // --- BOTTONIERA (Appare solo se abbiamo il telefono) ---
            if (customer.phone != null && customer.phone!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(customer.phone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero, // Toglie lo spazio vuoto extra
                  ),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text("WhatsApp"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  // Mini-widget per impaginare bene le tre statistiche
  Widget _buildStatColumn(IconData icon, String label, String value, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}