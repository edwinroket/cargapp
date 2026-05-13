import '../config/api.dart';
import '../models/alerta.dart';
import 'api_service.dart';

class AlertasService {
  static Future<List<Alerta>> getAlertas() async {
    final data = await ApiService.get(ApiConfig.alertas);
    return (data as List).map((a) => Alerta.fromJson(a)).toList();
  }

  static Future<void> crearAlerta({
    required int tipoCombustibleId,
    required double precioUmbral,
    required int radioKm,
    required double lat,
    required double lng,
    int? estacionId,
  }) async {
    await ApiService.post(ApiConfig.alertas, {
      'tipo_combustible_id': tipoCombustibleId,
      'precio_umbral': precioUmbral,
      'radio_km': radioKm,
      'latitud_usuario': lat,
      'longitud_usuario': lng,
      if (estacionId != null) 'estacion_id': estacionId,
    });
  }

  // Este método dispara la eliminación lógica en tu controller de Node
  static Future<void> eliminarAlerta(int id) async {
    await ApiService.delete('${ApiConfig.alertas}/$id');
  }

  static Future<void> toggleEstado(int id, bool activa) async {
    await ApiService.put('${ApiConfig.alertas}/$id', {'activa': activa ? 1 : 0});
  }
}