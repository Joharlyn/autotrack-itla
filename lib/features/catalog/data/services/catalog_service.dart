import '../../../../core/network/api_client.dart';
import '../../../../shared/utils/data_utils.dart';

class CatalogService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getCatalog({
    String? token,
    String? marca,
    String? modelo,
    String? anio,
    String? precioMin,
    String? precioMax,
  }) async {
    final query = <String, dynamic>{};

    if (marca != null && marca.trim().isNotEmpty) query['marca'] = marca.trim();
    if (modelo != null && modelo.trim().isNotEmpty)
      query['modelo'] = modelo.trim();
    if (anio != null && anio.trim().isNotEmpty) query['anio'] = anio.trim();
    if (precioMin != null && precioMin.trim().isNotEmpty)
      query['precioMin'] = precioMin.trim();
    if (precioMax != null && precioMax.trim().isNotEmpty)
      query['precioMax'] = precioMax.trim();

    final response = await _client.get(
      '/catalogo',
      queryParameters: query,
      token: token,
    );

    final payload = response['data'] ?? response;
    return DataUtils.extractList(payload, [
      'catalogo',
      'vehiculos',
      'items',
      'rows',
      'data',
    ]);
  }

  Future<Map<String, dynamic>> getCatalogDetail({
    required int id,
    String? token,
  }) async {
    final response = await _client.get(
      '/catalogo/detalle',
      queryParameters: {'id': id},
      token: token,
    );

    final payload = response['data'] ?? response;
    return DataUtils.extractMap(payload, [
      'vehiculo',
      'detalle',
      'item',
      'data',
    ]);
  }
}
