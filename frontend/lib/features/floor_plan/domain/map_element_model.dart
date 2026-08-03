// lib/features/floor_plan/domain/map_element_model.dart

class MapElementModel {
  final String id;
  
  // Il tipo di elemento: 'WALL' (Muro), 'DOOR' (Porta) o 'TEXT' (Testo libero)
  final String type;
  
  // Il testo da mostrare (es. "Bagni"). Sarà 'null' se l'elemento è un muro.
  final String? text;
  
  // Coordinate e dimensioni
  final double positionX;
  final double positionY;
  final double width;
  final double height;
  final double rotation;

  MapElementModel({
    required this.id,
    required this.type,
    this.text,
    required this.positionX,
    required this.positionY,
    required this.width,
    required this.height,
    this.rotation = 0.0,
  });

  // La nostra classica fabbrica per tradurre il JSON del backend in un oggetto Dart
  factory MapElementModel.fromJson(Map<String, dynamic> json) {
    return MapElementModel(
      id: json['id'].toString(),
      type: json['type'].toString(),
      text: json['text']?.toString(),
      // Usiamo semre .toDouble() per evitare crash con i numeri decimali
      positionX: json['positionX'] != null ? (json['positionX'] as num).toDouble() : 0.0,
      positionY: json['positionY'] != null ? (json['positionY'] as num).toDouble() : 0.0,
      width: json['width'] != null ? (json['width'] as num).toDouble() : 100.0,
      height: json['height'] != null ? (json['height'] as num).toDouble() : 20.0,
      rotation: json['rotation'] != null ? (json['rotation'] as num).toDouble() : 0.0,
    );
  }
}