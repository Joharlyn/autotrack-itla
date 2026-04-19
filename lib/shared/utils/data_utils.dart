import 'package:intl/intl.dart';

class DataUtils {
  static String firstString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  static int firstInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;

      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static double firstDouble(
    Map<String, dynamic> map,
    List<String> keys, {
    double fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;

      if (value is double) return value;
      if (value is int) return value.toDouble();

      final normalized = value.toString().replaceAll(',', '');
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static List<Map<String, dynamic>> extractList(
    dynamic payload,
    List<String> candidateKeys,
  ) {
    final result = _extractListRecursive(payload, candidateKeys);
    return result;
  }

  static List<Map<String, dynamic>> _extractListRecursive(
    dynamic payload,
    List<String> candidateKeys,
  ) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);

      for (final key in candidateKeys) {
        if (map.containsKey(key)) {
          final nested = _extractListRecursive(map[key], candidateKeys);
          if (nested.isNotEmpty) return nested;
        }
      }

      for (final value in map.values) {
        final nested = _extractListRecursive(value, candidateKeys);
        if (nested.isNotEmpty) return nested;
      }
    }

    return [];
  }

  static Map<String, dynamic> extractMap(
    dynamic payload,
    List<String> candidateKeys,
  ) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);

    if (payload is List && payload.isNotEmpty) {
      final first = payload.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }

    return {};
  }

  static List<String> extractStringList(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value is List) {
        return value
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .map((e) => e.toString().trim())
            .toList();
      }
    }

    return [];
  }

  static String firstImage(Map<String, dynamic> map) {
    return firstString(map, [
      'imagen',
      'image',
      'foto',
      'fotoUrl',
      'thumbnail',
      'thumb',
      'portada',
      'banner',
      'url',
      'imagenUrl',
    ]);
  }

  static String formatDate(String raw) {
    if (raw.trim().isEmpty) return '';

    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  static String formatMoney(dynamic value) {
    if (value == null) return 'RD\$ 0';
    final number = double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'es_DO',
      symbol: 'RD\$ ',
      decimalDigits: 2,
    );
    return formatter.format(number);
  }
}
