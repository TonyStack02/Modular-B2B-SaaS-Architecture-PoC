// lib/features/hr/presentation/add_employee_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // 👈 Serve per formattare le date (es. 20/05/2026)
import 'hr_controller.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  // La "Chiave" del form per convalidare che i campi obbligatori siano pieni
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLER DEI CAMPI DI TESTO ---
  // Anagrafica
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxCodeController = TextEditingController();
  
  // Contrattualistica
  final _wageController = TextEditingController(text: "0.0");
  final _hoursController = TextEditingController(text: "40");
  final _emergencyController = TextEditingController();
  final _notesController = TextEditingController();

  // --- GESTIONE DATE ---
  DateTime? _hireDate = DateTime.now(); // Data assunzione (default oggi)
  DateTime? _contractEnd;
  DateTime? _haccpExpiry;
  DateTime? _medicalExpiry;

  // Funzione per aprire il calendario e scegliere una data
  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (type == 'hire') _hireDate = picked;
        if (type == 'end') _contractEnd = picked;
        if (type == 'haccp') _haccpExpiry = picked;
        if (type == 'medical') _medicalExpiry = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuova Assunzione")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle("Anagrafica Base"),
            _buildTextField(_nameController, "Nome *", Icons.person, isRequired: true),
            _buildTextField(_surnameController, "Cognome *", Icons.person_outline, isRequired: true),
            _buildTextField(_roleController, "Ruolo / Mansione *", Icons.work, isRequired: true, hint: "es. Cameriere, Pizzaiolo"),
            _buildTextField(_emailController, "Email", Icons.email, keyboardType: TextInputType.emailAddress),
            _buildTextField(_phoneController, "Telefono", Icons.phone, keyboardType: TextInputType.phone, hint: "Per tasto WhatsApp"),
            _buildTextField(_taxCodeController, "Codice Fiscale", Icons.badge),

            const Divider(height: 40),
            _buildSectionTitle("Contratto e Scadenze"),
            
            // Selettore Data Assunzione
            _buildDatePickerTile("Data Assunzione", _hireDate, () => _selectDate(context, 'hire')),
            _buildDatePickerTile("Scadenza Contratto (opz.)", _contractEnd, () => _selectDate(context, 'end')),
            _buildDatePickerTile("Scadenza HACCP", _haccpExpiry, () => _selectDate(context, 'haccp')),
            _buildDatePickerTile("Scadenza Visita Medica", _medicalExpiry, () => _selectDate(context, 'medical')),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField(_wageController, "Paga Oraria (€)", Icons.euro, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_hoursController, "Ore Settimanali", Icons.timer, keyboardType: TextInputType.number)),
              ],
            ),

            const Divider(height: 40),
            _buildSectionTitle("Note e Emergenze"),
            _buildTextField(_emergencyController, "Contatto Emergenza", Icons.contact_emergency, hint: "Nome e numero"),
            _buildTextField(_notesController, "Note aggiuntive", Icons.note, maxLines: 3),

            const SizedBox(height: 32),
            
            // BOTTONE SALVA
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: _submitForm,
              child: const Text("SALVA IN ANAGRAFICA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Funzione che raccoglie i dati e li manda al Controller Riverpod
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Creiamo la mappa con i nomi dei campi UGUALI a quelli del backend (DTO)
      final employeeData = {
        'firstName': _nameController.text,
        'lastName': _surnameController.text,
        'jobRole': _roleController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'taxCode': _taxCodeController.text.isEmpty ? null : _taxCodeController.text,
        'hourlyWage': double.tryParse(_wageController.text) ?? 0.0,
        'weeklyContractHours': int.tryParse(_hoursController.text) ?? 40,
        'emergencyContact': _emergencyController.text,
        'notes': _notesController.text,
        // Convertiamo le date in formato stringa ISO per il backend
        'hireDate': _hireDate?.toUtc().toIso8601String(),
        'contractEndDate': _contractEnd?.toUtc().toIso8601String(),
        'haccpExpiry': _haccpExpiry?.toUtc().toIso8601String(),
        'medicalCheckExpiry': _medicalExpiry?.toUtc().toIso8601String(),
        'status': 'ACTIVE',
      };

      // Chiamiamo il controller!
      ref.read(hrControllerProvider.notifier).addEmployee(employeeData);
      
      // Torniamo indietro alla lista
      Navigator.pop(context);
    }
  }

  // --- WIDGETS DI SUPPORTO PER IL CODICE PULITO ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {
    bool isRequired = false, 
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) return "Campo obbligatorio";
          return null;
        },
      ),
    );
  }

  Widget _buildDatePickerTile(String label, DateTime? date, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today, color: Colors.blue),
      title: Text(label),
      subtitle: Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : "Non impostata"),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: onTap,
    );
  }
}