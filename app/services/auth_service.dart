import 'dart:convert';
import '../config/api.dart';
import 'api_service.dart';
import '../models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiService.post(
      '${ApiConfig.usuarios}/login',
      {'email': email, 'contrasena': password},
    );
    await ApiService.saveToken(data['token']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(data['usuario']));
    return data;
  }

  static Future<Map<String, dynamic>> registro(
      String email, String password, String nombre) async {
    final data = await ApiService.post(
      '${ApiConfig.usuarios}/registro',
      {'email': email, 'contrasena': password, 'nombre_completo': nombre},
    );
    await ApiService.saveToken(data['token']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(data['usuario']));
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
} 