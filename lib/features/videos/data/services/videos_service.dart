import '../../../../core/network/api_client.dart';
import '../../../../shared/utils/data_utils.dart';

class VideosService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getVideos({String? token}) async {
    final response = await _client.get('/videos', token: token);

    final payload = response['data'] ?? response;
    return DataUtils.extractList(payload, ['videos', 'items', 'rows', 'data']);
  }
}
