import '../config/api.dart';
import '../models/estacion.dart';
import 'api_service.dart';

class EstacionesService {
  static Future<List<Estacion>> getCercanas({
    required double lat,
    required double lng,
    double radio = 5,
    int? combustibleId,
  }) async {
    String url = '${ApiConfig.estaciones}?lat=$lat&lng=$lng&radio=$radio';
    if (combustibleId != null) url += '&combustible=$combustibleId';

    final data = await ApiService.get(url);
    return (data['estaciones'] as List)
        .map((e) => Estacion.fromJson(e))
        .toList();
  }

  static Future<Map<String, dynamic>> getDetalle(int id) async {
    return await ApiService.get('${ApiConfig.estaciones}/$id');
  }

  static Future<List<Map<String, dynamic>>> getCombustibles() async {
    final data = await ApiService.get('${ApiConfig.estaciones}/combustibles');
    return List<Map<String, dynamic>>.from(data);
  }
}