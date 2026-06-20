import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart'; // Asegúrate de que la ruta a tu ApiConfig sea la correcta

class ApiService {
  // Configuración de tiempos de espera para las conexiones
  static const Duration _localTimeout = Duration(seconds: 3); // Rápido para saltar si no estás en casa
  static const Duration _tailscaleTimeout = Duration(seconds: 6); // Más holgado para la VPN

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

  // 🚀 Helper Genérico Inteligente con Mecanismo de Fallback
  static Future<http.Response> _executeWithFallback(
    Future<http.Response> Function(String finalUrl, Map<String, String> finalHeaders) httpRequest,
    String url,
  ) async {
    final headers = await getHeaders();
    
    try {
      // 1. Intenta la petición con la IP activa (Por defecto localBaseUrl)
      final timeoutActual = ApiConfig.baseUrl == ApiConfig.localBaseUrl ? _localTimeout : _tailscaleTimeout;
      return await httpRequest(url, headers).timeout(timeoutActual);
    } catch (e) {
      // 2. Si falla y estábamos usando la IP local de casa, mutamos en caliente a Tailscale
      if (ApiConfig.baseUrl == ApiConfig.localBaseUrl) {
        print("🏠 IP Local inalcanzable (${url}). Conmutando automáticamente a Tailscale 🚀");
        
        // Cambiamos la variable global de configuración
        ApiConfig.baseUrl = ApiConfig.tailscaleBaseUrl;
        
        // Re-armamos la URL sustituyendo la IP local vieja por la de la VPN
        final nuevaUrl = url.replaceAll(ApiConfig.localBaseUrl, ApiConfig.tailscaleBaseUrl);
        
        // 3. Reintentamos la petición original usando la red de Tailscale
        return await httpRequest(nuevaUrl, headers).timeout(_tailscaleTimeout);
      }
      
      // Si ya estábamos en Tailscale y volvió a fallar, el servidor está apagado o no hay internet
      rethrow;
    }
  }

  // GET
  static Future<dynamic> get(String url) async {
    final response = await _executeWithFallback(
      (finalUrl, finalHeaders) => http.get(Uri.parse(finalUrl), headers: finalHeaders),
      url,
    );
    return _handleResponse(response);
  }

  // POST
  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await _executeWithFallback(
      (finalUrl, finalHeaders) => http.post(
        Uri.parse(finalUrl),
        headers: finalHeaders,
        body   : jsonEncode(body),
      ),
      url,
    );
    return _handleResponse(response);
  }

  // PUT
  static Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final response = await _executeWithFallback(
      (finalUrl, finalHeaders) => http.put(
        Uri.parse(finalUrl),
        headers: finalHeaders,
        body   : jsonEncode(body),
      ),
      url,
    );
    return _handleResponse(response);
  }

  // DELETE
  static Future<dynamic> delete(String url) async {
    final response = await _executeWithFallback(
      (finalUrl, finalHeaders) => http.delete(Uri.parse(finalUrl), headers: finalHeaders),
      url,
    );
    return _handleResponse(response);
  }

  // Manejar respuesta
  static dynamic _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        throw Exception(body['error'] ?? 'Error desconocido');
      }
    } catch (e) {
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