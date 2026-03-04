// lib/features/catalog/domain/category_model.dart

import 'product_model.dart';

class CategoryModel {
  final String id;
  final String name;
  final List<ProductModel> products;

  CategoryModel({
    required this.id,
    required this.name,
    required this.products
  });

  factory CategoryModel.fromJson(Map<String,dynamic> json) {
    final productList = json['products'] as List ?? [];
    final parsedProducts = productList.map((p) => ProductModel.fromJson(p)).toList();

    return CategoryModel(
      id: json['id'],
      name: json['name'],
      products: parsedProducts
    );
  }
}
