import '../config/api.dart';
import '../models/modelo_vehiculo.dart';
import '../models/vehiculo.dart';
import 'api_service.dart';

class VehiculosService {
  static Future<List<Vehiculo>> getVehiculos() async {
    final data = await ApiService.get(ApiConfig.vehiculos);
    return (data as List).map((v) => Vehiculo.fromJson(v)).toList();
  }

  static Future<void> crearVehiculo({
    int? modeloId,
    required String marca,
    required String modelo,
    required int anio,
    required double rendimiento,
    required int tipoCombustibleId,
    String? alias,
    bool esPrincipal = false,
  }) async {
    await ApiService.post(ApiConfig.vehiculos, {
      'modelo_id'          : modeloId,
      'marca_manual'       : marca,
      'modelo_manual'      : modelo,
      'anio_manual'        : anio,
      'rendimiento_km_l'   : rendimiento,
      'tipo_combustible_id': tipoCombustibleId,
      'alias'              : alias,
      'es_principal'       : esPrincipal,
    });
  }

  static Future<List<ModeloVehiculo>> getModelos({
    String? marca,
    String? modelo,
    int? anio,
  }) async {
    var query = ApiConfig.vehiculosModelos;
    final params = <String>[];
    if (marca != null && marca.isNotEmpty) params.add('marca=${Uri.encodeComponent(marca)}');
    if (modelo != null && modelo.isNotEmpty) params.add('modelo=${Uri.encodeComponent(modelo)}');
    if (anio != null) params.add('anio=$anio');
    if (params.isNotEmpty) query += '?${params.join('&')}';

    final data = await ApiService.get(query);
    return (data as List).map((item) => ModeloVehiculo.fromJson(item)).toList();
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