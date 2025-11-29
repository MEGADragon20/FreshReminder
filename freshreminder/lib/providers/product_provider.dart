import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load products from backend
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _products = await _apiService.getProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _products = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Add product to backend and local list
  Future<void> addProduct(Product product) async {
    try {
      final addedProduct = await _apiService.addProduct(product);
      _products.add(addedProduct);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Delete product from backend and local list
  Future<void> deleteProduct(int productId) async {
    try {
      await _apiService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Import products from QR code
  Future<void> importFromQR(String qrCode) async {
    try {
      final newProducts = await _apiService.importFromQR(qrCode);
      _products.addAll(newProducts);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Clear products (e.g., on logout)
  void clearProducts() {
    _products = [];
    _error = null;
    notifyListeners();
  }
}
