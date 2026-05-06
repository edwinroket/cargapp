import 'dart:convert';
import '../config/api.dart';
import 'api_service.dart';
import '../models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiService.post(
      '${ApiConfig.auth}/login',
      {'email': email, 'password': password},
    );
    final token = data['access_token'] ?? data['token'];
    final usuario = data['user'] ?? data['usuario'];
    await ApiService.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(usuario));
    return {'token': token, 'usuario': usuario};
  }

  static Future<Map<String, dynamic>> registro(
      String email, String password, String nombre) async {
    final data = await ApiService.post(
      '${ApiConfig.auth}/register',
      {
        'email': email,
        'password': password,
        'role': 'usuario',
        'nombre_completo': nombre,
      },
    );
    final token = data['access_token'] ?? data['token'];
    final usuario = data['user'] ?? data['usuario'];
    await ApiService.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(usuario));
    return {'token': token, 'usuario': usuario};
  }

  static Future<Map<String, dynamic>> actualizarPerfil(
      String nombre, String telefono, {int? ciudadId}) async {
    final body = {
      'nombre_completo': nombre,
      'telefono': telefono,
      if (ciudadId != null) 'ciudad_id': ciudadId,
    };
    final data = await ApiService.put(
      '${ApiConfig.usuarios}/perfil',
      body,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(data));
    return data;
  }

  static Future<Usuario?> getUsuarioGuardado() async {
    final prefs   = await SharedPreferences.getInstance();
    final usuarioStr = prefs.getString('usuario');
    if (usuarioStr == null) return null;
    return Usuario.fromJson(jsonDecode(usuarioStr));
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
  }

  static Future<List<Map<String, dynamic>>> getRegiones() async {
    final data = await ApiService.get('${ApiConfig.usuarios}/regiones');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getCiudadesPorRegion(int regionId) async {
    final data = await ApiService.get('${ApiConfig.usuarios}/regiones/$regionId/ciudades');
    return List<Map<String, dynamic>>.from(data);
  }
} 
