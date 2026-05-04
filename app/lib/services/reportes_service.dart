import '../config/api.dart';
import '../models/reporte.dart';
import 'api_service.dart';

class ReportesService {
  static Future<List<Reporte>> getReportesEstacion(int estacionId) async {
    final data = await ApiService.get(
      '${ApiConfig.reportes}/estacion/$estacionId'
    );
    return (data as List).map((r) => Reporte.fromJson(r)).toList();
  }

  static Future<void> crearReporte({
    required int estacionId,
    required int tipoCombustibleId,
    required double precio,
  }) async {
    await ApiService.post(ApiConfig.reportes, {
      'estacion_id'        : estacionId,
      'tipo_combustible_id': tipoCombustibleId,
      'precio_reportado'   : precio,
    });
  }

  static Future<void> votar(int reporteId, String voto) async {
    await ApiService.post(
      '${ApiConfig.reportes}/$reporteId/votar',
      {'voto': voto},
    );
  }
}