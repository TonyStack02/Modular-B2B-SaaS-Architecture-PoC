// lib/features/auth/domain/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String tenantId;
  final String role;
  // Ho tolto il token, lo gestiamo già col tokenProvider!

  UserModel({
    required this.id,
    required this.email,
    required this.tenantId,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      // Usiamo ?.toString() per assicurarci che diventi testo.
      // E usiamo ?? '' (oppure ?? 'OWNER') per dare un piano B se il dato è null!
      id: json['id'].toString(),
      email: json['email'].toString(),
      tenantId: json['tenantId'].toString(), 
      role: json['role']?.toString() ?? 'OWNER', 
    );
  }
}