import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/data_utils.dart';

class ForumPrivateService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getTopics(String token) async {
    final response = await _client.get('/foro/temas', token: token);

    return _extractList(response, ['temas', 'items', 'rows', 'data']);
  }

  Future<List<Map<String, dynamic>>> getMyTopics(String token) async {
    final response = await _client.get('/foro/mis-temas', token: token);

    return _extractList(response, ['temas', 'items', 'rows', 'data']);
  }

  Future<Map<String, dynamic>> getTopicDetail(String token, int id) async {
    final response = await _client.get(
      '/foro/detalle',
      token: token,
      queryParameters: {'id': id},
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> createTopic({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.postForm(
      '/foro/crear',
      token: token,
      data: data,
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> replyTopic({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.postForm(
      '/foro/responder',
      token: token,
      data: data,
    );

    return _extractData(response);
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response,
    List<String> candidateKeys,
  ) {
    final success = response['success'] == true;
    if (!success) {
      throw ApiException(
        response['message']?.toString() ?? 'No se pudo completar la operación.',
      );
    }

    final payload = response['data'] ?? response;
    return DataUtils.extractList(payload, candidateKeys);
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
