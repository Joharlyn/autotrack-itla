import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      receiveDataWhenStatusError: true,
    ),
  );

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(token: token),
      );

      return _mapResponse(response.data);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    } catch (_) {
      throw ApiException('No se pudo completar la petición GET.');
    }
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    required Map<String, dynamic> data,
    String? token,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: {'datax': jsonEncode(data)},
        options: _buildOptions(
          token: token,
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      return _mapResponse(response.data);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    } catch (_) {
      throw ApiException('No se pudo completar la petición POST.');
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? files,
    String? token,
  }) async {
    try {
      final formData = FormData();

      if (data != null && data.isNotEmpty) {
        formData.fields.add(MapEntry('datax', jsonEncode(data)));
      }

      if (files != null && files.isNotEmpty) {
        for (final entry in files.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is String) {
            final filePath = value.trim();
            if (filePath.isEmpty) continue;

            formData.files.add(
              MapEntry(key, await MultipartFile.fromFile(filePath)),
            );
          } else if (value is List) {
            for (final item in value) {
              final filePath = item.toString().trim();
              if (filePath.isEmpty) continue;

              formData.files.add(
                MapEntry(key, await MultipartFile.fromFile(filePath)),
              );
            }
          }
        }
      }

      final response = await _dio.post(
        path,
        data: formData,
        options: _buildOptions(token: token),
      );

      return _mapResponse(response.data);
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    } catch (_) {
      throw ApiException('No se pudo completar la petición multipart.');
    }
  }

  Options _buildOptions({String? token, String? contentType}) {
    final headers = <String, dynamic>{};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Options(headers: headers, contentType: contentType);
  }

  Map<String, dynamic> _mapResponse(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('La respuesta del servidor no tiene un formato válido.');
  }

  String _extractError(DioException e) {
    final responseData = e.response?.data;

    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }

    if (e.message != null && e.message!.trim().isNotEmpty) {
      return e.message!;
    }

    return 'Ocurrió un error de red.';
  }
}
