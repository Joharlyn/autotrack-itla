import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider extends ChangeNotifier {
  String? _token;
  String? _refreshToken;

  String? _userId;
  String? _nombre;
  String? _apellido;
  String? _correo;
  String? _fotoUrl;

  bool _initialized = false;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get nombre => _nombre;
  String? get apellido => _apellido;
  String? get correo => _correo;
  String? get fotoUrl => _fotoUrl;

  bool get initialized => _initialized;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  String get fullName {
    final n = (_nombre ?? '').trim();
    final a = (_apellido ?? '').trim();
    return '$n $a'.trim();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _userId = prefs.getString('userId');
    _nombre = prefs.getString('nombre');
    _apellido = prefs.getString('apellido');
    _correo = prefs.getString('correo');
    _fotoUrl = prefs.getString('fotoUrl');

    _initialized = true;
    notifyListeners();
  }

  Future<void> saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    _token = _safeString(data['token']);
    _refreshToken = _safeString(data['refreshToken']);
    _userId = _safeString(data['id']);
    _nombre = _safeString(data['nombre']);
    _apellido = _safeString(data['apellido']);
    _correo = _safeString(data['correo']);
    _fotoUrl = _safeString(data['fotoUrl']);

    await prefs.setString('token', _token ?? '');
    await prefs.setString('refreshToken', _refreshToken ?? '');
    await prefs.setString('userId', _userId ?? '');
    await prefs.setString('nombre', _nombre ?? '');
    await prefs.setString('apellido', _apellido ?? '');
    await prefs.setString('correo', _correo ?? '');
    await prefs.setString('fotoUrl', _fotoUrl ?? '');

    notifyListeners();
  }

  Future<void> saveProfileData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    _userId = _safeString(data['id']) ?? _userId;
    _nombre = _safeString(data['nombre']) ?? _nombre;
    _apellido = _safeString(data['apellido']) ?? _apellido;
    _correo = _safeString(data['correo']) ?? _correo;
    _fotoUrl = _safeString(data['fotoUrl']) ?? _fotoUrl;

    await prefs.setString('userId', _userId ?? '');
    await prefs.setString('nombre', _nombre ?? '');
    await prefs.setString('apellido', _apellido ?? '');
    await prefs.setString('correo', _correo ?? '');
    await prefs.setString('fotoUrl', _fotoUrl ?? '');

    notifyListeners();
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('nombre');
    await prefs.remove('apellido');
    await prefs.remove('correo');
    await prefs.remove('fotoUrl');

    _token = null;
    _refreshToken = null;
    _userId = null;
    _nombre = null;
    _apellido = null;
    _correo = null;
    _fotoUrl = null;

    notifyListeners();
  }

  String? _safeString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }
}
