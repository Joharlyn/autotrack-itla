import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/data_utils.dart';

class FinanceService {
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> getExpenseCategories(String token) async {
    final response = await _client.get('/gastos/categorias', token: token);

    final success = response['success'] == true;
    if (!success) {
      throw ApiException(
        response['message']?.toString() ??
            'No se pudieron obtener las categorías.',
      );
    }

    final payload = response['data'] ?? response;

    if (payload is List) return payload;
    if (payload is Map) {
      for (final value in payload.values) {
        if (value is List) return value;
      }
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> getExpenses(
    String token,
    int vehiculoId,
  ) async {
    final response = await _client.get(
      '/gastos',
      token: token,
      queryParameters: {'vehiculo_id': vehiculoId},
    );

    return _extractList(response, ['gastos', 'items', 'rows', 'data']);
  }

  Future<Map<String, dynamic>> createExpense({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.postForm(
      '/gastos',
      token: token,
      data: data,
    );

    return _extractData(response);
  }

  Future<List<Map<String, dynamic>>> getIncomes(
    String token,
    int vehiculoId,
  ) async {
    final response = await _client.get(
      '/ingresos',
      token: token,
      queryParameters: {'vehiculo_id': vehiculoId},
    );

    return _extractList(response, ['ingresos', 'items', 'rows', 'data']);
  }

  Future<Map<String, dynamic>> createIncome({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.postForm(
      '/ingresos',
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
