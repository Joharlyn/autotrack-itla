import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/data_utils.dart';

class VehiclesService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getVehicles(
    String token, {
    String? marca,
    String? modelo,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _client.get(
      '/vehiculos',
      token: token,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (marca != null && marca.trim().isNotEmpty) 'marca': marca.trim(),
        if (modelo != null && modelo.trim().isNotEmpty) 'modelo': modelo.trim(),
      },
    );

    final success = response['success'] == true;
    if (!success) {
      throw ApiException(
        response['message']?.toString() ??
            'No se pudieron obtener los vehículos.',
      );
    }

    final payload = response['data'] ?? response;
    return DataUtils.extractList(payload, [
      'vehiculos',
      'items',
      'rows',
      'data',
    ]);
  }

  Future<Map<String, dynamic>> getVehicleDetail(String token, int id) async {
    final response = await _client.get(
      '/vehiculos/detalle',
      token: token,
      queryParameters: {'id': id},
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> createVehicle({
    required String token,
    required Map<String, dynamic> data,
    String? photoPath,
  }) async {
    final response = await _client.postMultipart(
      '/vehiculos',
      token: token,
      data: data,
      files: photoPath != null && photoPath.trim().isNotEmpty
          ? {'foto': photoPath}
          : null,
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> editVehicle({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.postForm(
      '/vehiculos/editar',
      token: token,
      data: data,
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> updateVehiclePhoto({
    required String token,
    required int vehicleId,
    required String photoPath,
  }) async {
    final response = await _client.postMultipart(
      '/vehiculos/foto',
      token: token,
      data: {'id': vehicleId, 'vehiculo_id': vehicleId},
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
