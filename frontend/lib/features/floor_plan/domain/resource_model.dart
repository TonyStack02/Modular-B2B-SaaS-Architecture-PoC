// lib/features/floor_plan/domain/resource_model.dart

class ResourceModel {
  final String id;
  final String name;
  final String areaId;

  ResourceModel({
    required this.id,
    required this.name,
    required this.areaId
  });

  factory ResourceModel.fromJson(Map<String,dynamic> json) {
    return ResourceModel(
      id: json['id'],
      name: json['name'],
      areaId: json['areaId']
    );
  }
}