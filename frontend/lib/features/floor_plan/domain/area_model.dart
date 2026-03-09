// lib/features/floor_plan/domain/area_model.dart

class AreaModel {
  final String id;
  final String name;

  AreaModel({
    required this.id,
    required this.name
  });

  factory AreaModel.fromJson(Map<String,dynamic> json) {
    return AreaModel(
      id: json['id'],
      name: json['name']
    );
  }
}