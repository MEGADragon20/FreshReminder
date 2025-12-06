import 'package:flutter/foundation.dart';
import '../models/scanned_product.dart';

class CloudCartProvider extends ChangeNotifier {
  final List<ScannedProduct> _products = [];
  String? _currentToken;
  DateTime? _expiresAt;

  List<ScannedProduct> get products => List.unmodifiable(_products);
  String? get currentToken => _currentToken;
  DateTime? get expiresAt => _expiresAt;

  int get productCount => _products.length;

  bool get isEmpty => _products.isEmpty;

  void setToken(String token, {DateTime? expiresAt}) {
    _currentToken = token;
    _expiresAt = expiresAt;
    notifyListeners();
  }

  void addProduct(ScannedProduct product) {
    _products.add(product);
    notifyListeners();
  }

  void removeProductAt(int index) {
    if (index >= 0 && index < _products.length) {
      _products.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _products.clear();
    _currentToken = null;
    _expiresAt = null;
    notifyListeners();
  }

  // Check if any products are expired
  bool hasExpiredProducts() {
    final now = DateTime.now();
    return _products.any((product) => product.expirationDate.isBefore(now));
  }

  // Get expired products
  List<ScannedProduct> getExpiredProducts() {
    final now = DateTime.now();
    return _products.where((product) => product.expirationDate.isBefore(now)).toList();
  }

  // Get products expiring today
  List<ScannedProduct> getExpiringToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _products.where((product) {
      final productDate = DateTime(
        product.expirationDate.year,
        product.expirationDate.month,
        product.expirationDate.day,
      );
      return productDate.isAtSameMomentAs(today);
    }).toList();
  }
}
