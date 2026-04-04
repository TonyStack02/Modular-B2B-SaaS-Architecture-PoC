// lib/features/hr/domain/shift_model.dart

class ShiftModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final String employeeId;
  
  // Questi dati arrivano dalla "include" di Prisma nel backend
  final ShiftEmployeeInfo? employee;

  ShiftModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.employeeId,
    this.employee,
  });

  // Calcoliamo la durata del turno in ore (utile per i costi)
  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  // Calcoliamo il costo di questo singolo turno
  double get totalCost {
    if (employee == null) return 0.0;
    return durationInHours * employee!.hourlyWage;
  }

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'].toString(),
      // Convertiamo le stringhe ISO del DB in oggetti DateTime di Dart
      startTime: DateTime.parse(json['startTime']).toLocal(),
      endTime: DateTime.parse(json['endTime']).toLocal(),
      notes: json['notes']?.toString(),
      employeeId: json['employeeId'].toString(),
      // Se il backend ci ha mandato anche i dati dell'impiegato, li convertiamo
      employee: json['employee'] != null 
          ? ShiftEmployeeInfo.fromJson(json['employee']) 
          : null,
    );
  }
}

// Piccola classe di supporto per i dati "extra" del dipendente dentro il turno
class ShiftEmployeeInfo {
  final String firstName;
  final String lastName;
  final double hourlyWage;
  final String jobRole;

  ShiftEmployeeInfo({
    required this.firstName,
    required this.lastName,
    required this.hourlyWage,
    required this.jobRole,
  });

  factory ShiftEmployeeInfo.fromJson(Map<String, dynamic> json) {
    return ShiftEmployeeInfo(
      firstName: json['firstName'].toString(),
      lastName: json['lastName'].toString(),
      hourlyWage: json['hourlyWage'] != null ? double.parse(json['hourlyWage'].toString()) : 0.0,
      jobRole: json['jobRole'].toString(),
    );
  }
}