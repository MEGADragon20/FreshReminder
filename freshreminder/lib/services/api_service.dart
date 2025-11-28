import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../models/product.dart';

export '../models/product.dart';

// Wrapper to handle platform differences
class _SharedPreferencesProxy {
  static String? _memoryToken;
  
  String? getString(String key) {
    if (Platform.isLinux) {
      if (key == 'auth_token') return _memoryToken;
      return null;
    }
    // For other platforms, we'd use the actual shared_preferences
    return null;
  }
  
  Future<void> setString(String key, String value) async {
    if (Platform.isLinux) {
      if (key == 'auth_token') _memoryToken = value;
      return;
    }
  }
  
  Future<void> remove(String key) async {
    if (Platform.isLinux) {
      if (key == 'auth_token') _memoryToken = null;
      return;
    }
  }
}

class ApiService {
  // WICHTIG: Ersetze mit deiner Backend-URL
  // Lokal: 'http://localhost:5000/api'
  // Production: 'https://api.freshreminder.de/api'
  static const String baseUrl = 'http://localhost:5000/api';
  
  // In-memory token storage for Linux (since SharedPreferences doesn't support it)
  static String? _memoryToken;
  
  // Token aus SharedPreferences/Memory holen
  Future<String?> _getToken() async {
    if (Platform.isLinux) {
      return _memoryToken;
    }
    // For other platforms, use the proxy
    final prefs = _SharedPreferencesProxy();
    return prefs.getString('auth_token');
  }
  
  // Token speichern
  Future<void> _saveToken(String token) async {
    if (Platform.isLinux) {
      _memoryToken = token;
      return;
    }
    final prefs = _SharedPreferencesProxy();
    await prefs.setString('auth_token', token);
  }
  
  // Headers mit Authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ====================
  
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Registrierung fehlgeschlagen');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login fehlgeschlagen');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  Future<void> logout() async {
    if (Platform.isLinux) {
      _memoryToken = null;
      return;
    }
    final prefs = _SharedPreferencesProxy();
    await prefs.remove('auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // ==================== PRODUCTS ====================

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Nicht angemeldet');
      } else {
        throw Exception('Fehler beim Laden der Produkte');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  Future<Product> addProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/'),
        headers: await _getHeaders(),
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Backend gibt die ID zurück
        return Product(
          id: data['id'],
          name: product.name,
          expirationDate: product.expirationDate,
          category: product.category,
        );
      } else {
        throw Exception('Fehler beim Hinzufügen');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Fehler beim Löschen');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  // ==================== QR IMPORT ====================

  Future<List<Product>> importFromQR(String qrCode) async {
    try {
      // Extrahiere Token aus QR-Code URL
      // z.B. "https://api.freshreminder.de/import/ABCD1234"
      final uri = Uri.parse(qrCode);
      final token = uri.pathSegments.last;

      final response = await http.get(
        Uri.parse('$baseUrl/import/$token'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['products'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw Exception('QR-Code ungültig');
      } else if (response.statusCode == 410) {
        throw Exception('QR-Code abgelaufen (älter als 24h)');
      } else if (response.statusCode == 409) {
        throw Exception('QR-Code bereits verwendet');
      } else {
        throw Exception('Import fehlgeschlagen');
      }
    } catch (e) {
      throw Exception('Fehler: $e');
    }
  }

  // ==================== USER PROFILE ====================

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Profil laden fehlgeschlagen');
      }
    } catch (e) {
      throw Exception('Netzwerkfehler: $e');
    }
  }

  Future<void> updatePushToken(String pushToken) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/users/push-token'),
        headers: await _getHeaders(),
        body: jsonEncode({'token': pushToken}),
      );
    } catch (e) {
      print('Push Token Update fehlgeschlagen: $e');
    }
  }
}