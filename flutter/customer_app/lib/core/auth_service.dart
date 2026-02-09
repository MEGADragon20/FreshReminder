import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const _kLoggedInKey = 'logged_in';
  static const _kTokenKey = 'auth_token';

  String? _token;
  final ApiClient _client = ApiClient();

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final logged = prefs.getBool(_kLoggedInKey) ?? false;
    if (logged) {
      _token = prefs.getString(_kTokenKey);
    }
    return logged;
  }

  Future<bool> login(String email, String password) async {
    try {
      final resp = await _client.post('/auth/login', {'email': email, 'password': password});
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kLoggedInKey, true);
        await prefs.setString(_kTokenKey, _token ?? '');
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<bool> register(String email, String password) async {
    try {
      final resp = await _client.post('/auth/register', {'email': email, 'password': password});
      if (resp.statusCode == 201) {
        final data = resp.data as Map<String, dynamic>;
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kLoggedInKey, true);
        await prefs.setString(_kTokenKey, _token ?? '');
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedInKey);
    await prefs.remove(_kTokenKey);
  }

  String? get token => _token;
}
