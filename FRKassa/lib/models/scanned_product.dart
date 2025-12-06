class ScannedProduct {
  final String name;
  final DateTime expirationDate;
  final String? category;

  ScannedProduct({
    required this.name,
    required this.expirationDate,
    this.category,
  });

  /// Parse QR code format: ProductName|YYYY-MM-DD|Category
  factory ScannedProduct.fromQRCode(String qrData) {
    final parts = qrData.split('|');
    if (parts.length < 2) {
      throw FormatException('Invalid QR code format. Expected: ProductName|YYYY-MM-DD|Category');
    }

    final name = parts[0].trim();
    final datePart = parts[1].trim();
    final category = parts.length > 2 ? parts[2].trim() : 'Sonstiges';

    // Parse date format: YYYY-MM-DD
    final expirationDate = DateTime.parse(datePart);

    return ScannedProduct(
      name: name,
      expirationDate: expirationDate,
      category: category,
    );
  }

  /// Convert to JSON format for backend submission
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category ?? 'Sonstiges',
      'expiration_date': expirationDate.toIso8601String().split('T')[0], // YYYY-MM-DD
    };
  }

  @override
  String toString() {
    return 'ScannedProduct(name: $name, expirationDate: $expirationDate, category: $category)';
  }
}
