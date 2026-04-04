// lib/features/hr/domain/employee_model.dart

class EmployeeModel {
  // Dichiariamo tutte le variabili che ci arrivano dal backend.
  // Usiamo il punto interrogativo (?) per le variabili che potrebbero essere vuote (null)
  final String id;
  final String firstName;
  final String lastName;
  final String jobRole;
  final String? email;
  final String? phone;
  final String? taxCode; // Codice Fiscale
  
  // Date importanti (usiamo DateTime per poterci fare i calcoli, tipo "quanti giorni mancano")
  final DateTime? hireDate;
  final DateTime? contractEndDate;
  final DateTime? haccpExpiry;
  final DateTime? medicalCheckExpiry;

  // Numeri per costi e ferie (usiamo double per gestire i decimali)
  final double hourlyWage;
  final int weeklyContractHours;
  final double vacationDaysTotal;
  final double sickDaysTotal;

  final String? emergencyContact;
  final String? pinCode;
  final String? notes;
  final String status; // 'ACTIVE', 'ON_LEAVE', 'TERMINATED'

  // Il costruttore: qui obblighiamo a passare i dati fondamentali (required) 
  // e lasciamo opzionali gli altri
  EmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.jobRole,
    this.email,
    this.phone,
    this.taxCode,
    this.hireDate,
    this.contractEndDate,
    this.haccpExpiry,
    this.medicalCheckExpiry,
    this.hourlyWage = 0.0,
    this.weeklyContractHours = 40,
    this.vacationDaysTotal = 0.0,
    this.sickDaysTotal = 0.0,
    this.emergencyContact,
    this.pinCode,
    this.notes,
    required this.status,
  });

  // Questa è la nostra "Fabbrica". Prende il JSON "grezzo" che arriva da NestJS
  // e lo trasforma in un oggetto Flutter pulito e tipizzato.
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'].toString(),
      firstName: json['firstName'].toString(),
      lastName: json['lastName'].toString(),
      jobRole: json['jobRole'].toString(),
      
      // Se il dato c'è, lo convertiamo in stringa, altrimenti lo lasciamo null
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      taxCode: json['taxCode']?.toString(),
      
      // Convertiamo le stringhe delle date (es. "2026-06-30") in oggetti DateTime veri e propri
      hireDate: json['hireDate'] != null ? DateTime.parse(json['hireDate'].toString()) : null,
      contractEndDate: json['contractEndDate'] != null ? DateTime.parse(json['contractEndDate'].toString()) : null,
      haccpExpiry: json['haccpExpiry'] != null ? DateTime.parse(json['haccpExpiry'].toString()) : null,
      medicalCheckExpiry: json['medicalCheckExpiry'] != null ? DateTime.parse(json['medicalCheckExpiry'].toString()) : null,
      
      // I numeri vanno sempre convertiti con cura per evitare crash se arrivano come interi o decimali
      hourlyWage: json['hourlyWage'] != null ? double.parse(json['hourlyWage'].toString()) : 0.0,
      weeklyContractHours: json['weeklyContractHours'] != null ? int.parse(json['weeklyContractHours'].toString()) : 40,
      vacationDaysTotal: json['vacationDaysTotal'] != null ? double.parse(json['vacationDaysTotal'].toString()) : 0.0,
      sickDaysTotal: json['sickDaysTotal'] != null ? double.parse(json['sickDaysTotal'].toString()) : 0.0,
      
      emergencyContact: json['emergencyContact']?.toString(),
      pinCode: json['pinCode']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status'].toString(),
    );
  }
}