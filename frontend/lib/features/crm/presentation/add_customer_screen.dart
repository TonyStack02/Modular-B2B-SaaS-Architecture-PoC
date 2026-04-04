// lib/features/crm/presentation/add_customer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'customer_controller.dart'; // Importiamo il "cervello" dei clienti

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // I controller per i campi di testo
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  void _saveCustomer() {
    // Se il form è valido (ha almeno il nome)
    if (_formKey.currentState!.validate()) {
      // Impacchettiamo i dati
      final customerData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text.isEmpty ? null : _lastNameController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      // Chiamiamo il controller per inviare tutto a NestJS
      ref.read(customerControllerProvider.notifier).addCustomer(customerData);
      
      // Chiudiamo la pagina e torniamo indietro
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuovo Cliente")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("Anagrafica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            
            // Il Nome è l'unica cosa obbligatoria
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "Nome *", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? "Campo obbligatorio" : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Cognome", prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Telefono (Per WhatsApp/Fedeltà)", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Note (es. Allergie, Preferenze)", prefixIcon: Icon(Icons.note), border: OutlineInputBorder()),
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: _saveCustomer,
              child: const Text("SALVA IN RUBRICA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}