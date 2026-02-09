import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({String? baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl ?? Config.apiBaseUrl));

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    return _dio.get(path,
        queryParameters: queryParameters,
        options: Options(headers: headers));
  }

  Future<Response> post(String path, dynamic data, {Map<String, String>? headers}) async {
    return _dio.post(path, data: data, options: Options(headers: headers));
  }
}
