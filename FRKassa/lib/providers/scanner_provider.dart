import 'package:flutter/foundation.dart';

class ScannerProvider extends ChangeNotifier {
  String _scannedData = '';
  bool _isProcessing = false;
  String? _error;

  String get scannedData => _scannedData;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  void setScannedData(String data) {
    _scannedData = data;
    _error = null;
    notifyListeners();
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearScannedData() {
    _scannedData = '';
    _error = null;
    notifyListeners();
  }
}
