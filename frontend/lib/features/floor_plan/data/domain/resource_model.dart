// lib/features/floor_plan/domain/resource_model.dart

class ResourceModel {
  final String id;
  final String name;
  final String areaId;
  final double positionX;
  final double positionY;

  ResourceModel({
    required this.id,
    required this.name,
    required this.areaId,
    required this.positionX,
    required this.positionY,
  });

  factory ResourceModel.fromJson(Map<String,dynamic> json) {
    return ResourceModel(
      id: json['id'],
      name: json['name'],
      areaId: json['areaId'],
      positionX: json['positionX'] != null ? (json['positionX'] as num).toDouble() : 0.0,
      positionY: json['positionY'] != null ? (json['positionY'] as num).toDouble() : 0.0,
    );
  }
}