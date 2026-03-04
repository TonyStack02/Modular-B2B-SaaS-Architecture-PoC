// lib/features/catalog/domain/product_model.dart


class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String categoryId;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.categoryId
  });

  // IL TRADUTTORE: Da JSON (NestJS) a Dart (Flutter)
  factory ProductModel.fromJson(Map<String,dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'], 
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      categoryId: json['categoryId']
    );
  }

  // IL TRADUTTORE INVERSO: Da Dart (Flutter) a JSON (se dobbiamo inviare dati al backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId
    };
  }
}