import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class ProfileService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await _client.get('/perfil', token: token);

    return _extractData(response);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required String photoPath,
  }) async {
    final response = await _client.postMultipart(
      '/perfil/foto',
      token: token,
      files: {'foto': photoPath},
    );

    return _extractData(response);
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    final success = response['success'] == true;
    final message =
        response['message']?.toString() ?? 'No se pudo completar la operación.';
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
