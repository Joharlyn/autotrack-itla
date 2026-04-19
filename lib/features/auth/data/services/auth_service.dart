import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> register(String matricula) async {
    final response = await _client.postForm(
      '/auth/registro',
      data: {'matricula': matricula.trim()},
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> activate({
    required String token,
    required String contrasena,
  }) async {
    final response = await _client.postForm(
      '/auth/activar',
      data: {'token': token.trim(), 'contrasena': contrasena.trim()},
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> login({
    required String matricula,
    required String contrasena,
  }) async {
    final response = await _client.postForm(
      '/auth/login',
      data: {'matricula': matricula.trim(), 'contrasena': contrasena.trim()},
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> forgotPassword(String matricula) async {
    final response = await _client.postForm(
      '/auth/olvidar',
      data: {'matricula': matricula.trim()},
    );

    return _extractData(response);
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    final success = response['success'] == true;
    final message =
        response['message']?.toString() ?? 'Operación no completada.';
    final rawData = response['data'];

    if (!success) {
      throw ApiException(message);
    }

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    return {};
  }
}
