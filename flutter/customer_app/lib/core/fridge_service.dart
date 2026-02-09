import 'api_client.dart';
import 'auth_service.dart';

class FridgeService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getFridgeItems() async {
    final token = AuthService.instance.token;
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
    final resp = await _client.get('/fridge/', headers: headers);
    if (resp.statusCode == 200) {
      final data = resp.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      return items;
    }
    return [];
  }
}
