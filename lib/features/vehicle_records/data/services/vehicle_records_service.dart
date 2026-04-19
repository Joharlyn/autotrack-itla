import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/data_utils.dart';

class VehicleRecordsService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getMaintenances(
    String token,
    int vehiculoId,
  ) async {
    final response = await _client.get(
      '/mantenimientos',
      token: token,
      queryParameters: {'vehiculo_id': vehiculoId},
    );

    return _extractList(response, ['mantenimientos', 'items', 'rows', 'data']);
  }

  Future<Map<String, dynamic>> createMaintenance({
    required String token,
    required Map<String, dynamic> data,
    List<String> photoPaths = const [],
  }) async {
    final response = await _client.postMultipart(
      '/mantenimientos',
      token: token,
      data: data,
      files: photoPaths.isNotEmpty ? {'fotos[]': photoPaths} : null,
    );

    return _extractData(response);
  }

  Future<List<Map<String, dynamic>>> getFuelOilEntries(
    String token,
    int vehiculoId,
  ) async {
    final response = await _client.get(
      '/combustibles',
      token: token,
      queryParameters: {'vehiculo_id': vehiculoId},
    );

    return _extractList(response, ['combustibles', 'items', 'rows', 'data']);
  }

  Future<Map<String, dynamic>> createFuelOilEntry({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.postForm(
      '/combustibles',
      token: token,
      data: data,
    );

    return _extractData(response);
  }

  Future<List<Map<String, dynamic>>> getTires(
    String token,
    int vehiculoId,
  ) async {
    final response = await _client.get(
      '/gomas',
      token: token,
      queryParameters: {'vehiculo_id': vehiculoId},
    );

    return _extractList(response, ['gomas', 'items', 'rows', 'data']);
  }

  Future<Map<String, dynamic>> updateTireStatus({
    required String token,
    required int gomaId,
    required String estado,
  }) async {
    final response = await _client.postForm(
      '/gomas/actualizar',
      token: token,
      data: {'goma_id': gomaId, 'estado': estado},
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> createPuncture({
    required String token,
    required int gomaId,
    required String descripcion,
    String? fecha,
  }) async {
    final body = <String, dynamic>{
      'goma_id': gomaId,
      'descripcion': descripcion,
    };

    if (fecha != null && fecha.trim().isNotEmpty) {
      body['fecha'] = fecha.trim();
    }

    final response = await _client.postForm(
      '/gomas/pinchazos',
      token: token,
      data: body,
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
