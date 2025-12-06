import 'package:flutter/foundation.dart';
import '../models/scanned_product.dart';

class CloudCartProvider extends ChangeNotifier {
  final List<ScannedProduct> _products = [];

  List<ScannedProduct> get products => List.unmodifiable(_products);

  int get productCount => _products.length;

  bool get isEmpty => _products.isEmpty;

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
    notifyListeners();
  }

  // Check if any products are expired
  bool hasExpiredProducts() {
    final now = DateTime.now();
    return _products.any((product) => product.bestBeforeDate.isBefore(now));
  }

  // Get expired products
  List<ScannedProduct> getExpiredProducts() {
    final now = DateTime.now();
    return _products.where((product) => product.bestBeforeDate.isBefore(now)).toList();
  }

  // Get products expiring today
  List<ScannedProduct> getExpiringToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _products.where((product) {
      final productDate = DateTime(
        product.bestBeforeDate.year,
        product.bestBeforeDate.month,
        product.bestBeforeDate.day,
      );
      return productDate.isAtSameMomentAs(today);
    }).toList();
  }
}
