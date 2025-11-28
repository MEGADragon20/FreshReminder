class Product {
  final int? id;
  final String name;
  final DateTime expirationDate;
  final String category;
  
  Product({
    this.id,
    required this.name,
    required this.expirationDate,
    required this.category,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      expirationDate: DateTime.parse(json['expiration_date']),
      category: json['category'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'expiration_date': expirationDate.toIso8601String(),
      'category': category,
    };
  }
}
