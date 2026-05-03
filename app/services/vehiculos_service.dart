import '../config/api.dart';
import '../models/vehiculo.dart';
import 'api_service.dart';

class VehiculosService {
  static Future<List<Vehiculo>> getVehiculos() async {
    final data = await ApiService.get(ApiConfig.vehiculos);
    return (data as List).map((v) => Vehiculo.fromJson(v)).toList();
  }

  static Future<void> crearVehiculo({
    required String marca,
    required String modelo,
    required int anio,
    required double rendimiento,
    required int tipoCombustibleId,
    String? alias,
    bool esPrincipal = false,
  }) async {
    await ApiService.post(ApiConfig.vehiculos, {
      'marca_manual'       : marca,
      'modelo_manual'      : modelo,
      'anio_manual'        : anio,
      'rendimiento_km_l'   : rendimiento,
      'tipo_combustible_id': tipoCombustibleId,
      'alias'              : alias,
      'es_principal'       : esPrincipal,
    });
  }

  static Future<Map<String, dynamic>> calcularCosto({
    required int vehiculoId,
    required int estacionId,
    double distanciaKm = 1,
  }) async {
    return await ApiService.get(
      '${ApiConfig.vehiculos}/costo?vehiculo_id=$vehiculoId&estacion_id=$estacionId&distancia_km=$distanciaKm'
    );
  }

  static Future<void> eliminarVehiculo(int id) async {
    await ApiService.delete('${ApiConfig.vehiculos}/$id');
  }
}