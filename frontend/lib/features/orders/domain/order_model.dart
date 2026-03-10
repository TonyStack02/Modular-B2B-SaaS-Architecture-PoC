// lib/features/orders/domain/order_model.dart

class OrderItemModel {
  final int quantity;
  final String productName;
  final double price;

  OrderItemModel({
    required this.quantity, 
    required this.productName, 
    required this.price
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // 1. Estrazione sicura del prodotto (se il backend si dimentica di includerlo)
    final product = json['product'] ?? {};
    
    // 2. Parsiamo il prezzo in modo corazzato (trasformiamo la stringa in numero)
    final priceString = product['price']?.toString() ?? '0';
    final parsedPrice = double.tryParse(priceString) ?? 0.0;

    return OrderItemModel(
      quantity: json['quantity'] ?? 1,
      productName: product['name'] ?? 'Prodotto sconosciuto',
      price: parsedPrice,
    );
  }
}

class OrderModel {
  final String id;
  final String status;
  final double totalAmount;
  final String resourceId;
  final String resourceName; 
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.resourceId,
    required this.resourceName,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // 1. Parsiamo il totale corazzato (da Stringa di Prisma a Double di Dart)
    final totalString = json['totalAmount']?.toString() ?? '0';
    final parsedTotal = double.tryParse(totalString) ?? 0.0;

    // 2. Estrazione sicura della lista degli item
    final itemsList = json['items'] as List? ?? [];

    return OrderModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      totalAmount: parsedTotal,
      resourceId: json['resourceId']?.toString() ?? '',
      resourceName: json['resource']?['name'] ?? 'Tavolo Sconosciuto',
      items: itemsList.map((i) => OrderItemModel.fromJson(i)).toList(),
    );
  }
}