import '../../../../core/network/api_client.dart';
import '../../../../shared/utils/data_utils.dart';

class NewsService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getNews({
    String? token,
    int page = 1,
  }) async {
    final response = await _client.get(
      '/noticias',
      queryParameters: {'page': page},
      token: token,
    );

    final payload = response['data'] ?? response;
    return DataUtils.extractList(payload, [
      'noticias',
      'items',
      'rows',
      'data',
    ]);
  }

  Future<Map<String, dynamic>> getNewsDetail({
    required int id,
    String? token,
  }) async {
    final response = await _client.get(
      '/noticias/detalle',
      queryParameters: {'id': id},
      token: token,
    );

    final payload = response['data'] ?? response;
    return DataUtils.extractMap(payload, [
      'noticia',
      'detalle',
      'item',
      'data',
    ]);
  }
}
