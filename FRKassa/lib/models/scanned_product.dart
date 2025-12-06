class ScannedProduct {
  final String name;
  final DateTime bestBeforeDate;
  final String? additionalInfo;

  ScannedProduct({
    required this.name,
    required this.bestBeforeDate,
    this.additionalInfo,
  });

  factory ScannedProduct.fromQRCode(String qrData) {
    final parts = qrData.split('|');
    if (parts.length < 2) {
      throw FormatException('Invalid QR code format');
    }

    final name = parts[0].trim();
    final datePart = parts[1].trim();
    final additionalInfo = parts.length > 2 ? parts.sublist(2).join('|') : null;

    // Parse date format: YYYY-MM-DD
    final bestBeforeDate = DateTime.parse(datePart);

    return ScannedProduct(
      name: name,
      bestBeforeDate: bestBeforeDate,
      additionalInfo: additionalInfo,
    );
  }

  @override
  String toString() {
    return 'ScannedProduct(name: $name, bestBeforeDate: $bestBeforeDate, additionalInfo: $additionalInfo)';
  }
}
