import '../../../../core/network/api_client.dart';
import '../../../../shared/utils/data_utils.dart';

class PublicForumService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getTopics() async {
    final response = await _client.get('/publico/foro');

    final payload = response['data'] ?? response;
    return DataUtils.extractList(payload, ['temas', 'items', 'rows', 'data']);
  }

  Future<Map<String, dynamic>> getTopicDetail(int id) async {
    final response = await _client.get(
      '/publico/foro/detalle',
      queryParameters: {'id': id},
    );

    final payload = response['data'] ?? response;
    return DataUtils.extractMap(payload, ['tema', 'detalle', 'item', 'data']);
  }
}
