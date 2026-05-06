import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Obtener token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Guardar token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Borrar token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  // Headers con token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type' : 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET
  static Future<dynamic> get(String url) async {
    final headers  = await getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  // POST
  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final headers  = await getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body   : jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // PUT
  static Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final headers  = await getHeaders();
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body   : jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // DELETE
  static Future<dynamic> delete(String url) async {
    final headers  = await getHeaders();
    final response = await http.delete(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  // Manejar respuesta
  static dynamic _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        throw Exception(body['detail'] ?? body['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      // Si no es JSON válido, probablemente es un error del servidor
      if (response.statusCode >= 500) {
        throw Exception('Error del servidor (${response.statusCode})');
      } else if (response.statusCode >= 400) {
        throw Exception('Error en la solicitud (${response.statusCode})');
      } else {
        throw Exception('Error al procesar la respuesta: $e');
      }
    }
  }
}
