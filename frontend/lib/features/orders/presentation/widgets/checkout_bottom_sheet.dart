// lib/features/orders/presentation/widgets/checkout_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../crm/presentation/customer_controller.dart';
import '../../../orders/data/order_repository.dart';
import '../../../orders/domain/order_model.dart'; 

class CheckoutBottomSheet extends ConsumerStatefulWidget {
  final OrderModel order; // Passiamo l'ordine intero per leggere il totale

  const CheckoutBottomSheet({super.key, required this.order});

  // Una funzione statica per richiamare questo popup facilmente da qualsiasi schermata!
  static void show(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CheckoutBottomSheet(order: order),
    );
  }

  @override
  ConsumerState<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends ConsumerState<CheckoutBottomSheet> {
  String? _selectedCustomerId;
  bool _isCreatingNew = false; // Interruttore: Ricerca vs Creazione Veloce

  // Controller per il "Nuovo Cliente Rapido"
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _processPayment() async {
    String? finalCustomerId = _selectedCustomerId;

    // Se l'Owner ha scelto "Nuovo Cliente", lo creiamo in background un attimo prima di pagare!
    if (_isCreatingNew && _nameController.text.isNotEmpty) {
      final newCust = await ref.read(customerControllerProvider.notifier).addCustomer({
        'firstName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      finalCustomerId = newCust?.id; // Rubiamo il suo nuovo ID!
    }

    try {
      // 💸 CHIUDIAMO IL CONTO SUL BACKEND!
      await ref.read(orderRepositoryProvider).updateOrderStatus(
        widget.order.id, 
        'PAID', 
        customerId: finalCustomerId
      );

      if (mounted) {
        Navigator.pop(context); // Chiude il popup
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Conto Pagato!"), backgroundColor: Colors.green));
        
        // TODO: In futuro qui potrai richiamare un ref.read(dashboardController.notifier).refresh() per aggiornare l'incasso!
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Errore chiusura conto"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customerControllerProvider);
    final customers = customersState.value ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Pagamento", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          
          // Mostriamo l'importo gigante
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text("Totale da incassare", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text("€${widget.order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // TOGGLE: Cliente Esistente o Nuovo?
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text("Cerca in Rubrica"),
                  selected: !_isCreatingNew,
                  onSelected: (val) => setState(() => _isCreatingNew = false),
                  selectedColor: Colors.orange.shade100,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text("+ Crea Nuovo"),
                  selected: _isCreatingNew,
                  onSelected: (val) => setState(() {
                    _isCreatingNew = true;
                    _selectedCustomerId = null; // Resetta l'altro
                  }),
                  selectedColor: Colors.orange.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // MOSTRA IL MENU A TENDINA O IL FORM A SECONDA DELLA SCELTA
          if (!_isCreatingNew)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Nessuno (Cliente Anonimo)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.star, color: Colors.orange)),
              value: _selectedCustomerId,
              items: [
                const DropdownMenuItem(value: null, child: Text("Nessuno (Cliente Anonimo)")),
                ...customers.map((c) => DropdownMenuItem(value: c.id, child: Text("${c.firstName} ${c.lastName ?? ''}"))),
              ],
              onChanged: (val) => setState(() => _selectedCustomerId = val),
            )
          else
            Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nome Cliente", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Telefono (per promozioni)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              ],
            ),

          const SizedBox(height: 32),

          // IL TASTO CASSA
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _processPayment,
            icon: const Icon(Icons.point_of_sale, color: Colors.white),
            label: Text(
              _isCreatingNew || _selectedCustomerId != null ? "INCASSA E ASSEGNA PUNTI" : "INCASSA (ANONIMO)", 
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}