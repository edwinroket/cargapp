import '../models/gas_precio.dart';
import 'api_service.dart';
import '../config/api.dart'; // Importante para acceder a la URL base

class GasService {
  // Ya no creamos instancia de ApiService porque sus métodos son estáticos
  
  Future<List<GasPrecio>> getPreciosGas({String? comunaId}) async {
    try {
      // Construimos la URL completa usando la base de tu config
      final endpoint = comunaId != null ? '/gas?comunaId=$comunaId' : '/gas';
      final String fullUrl = '${ApiConfig.baseUrl}$endpoint';

      // Llamamos al método estático directamente
      final dynamic responseData = await ApiService.get(fullUrl);

      // Como ApiService ya devuelve la data decodificada (List o Map)
      if (responseData is List) {
        return responseData.map((json) => GasPrecio.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error en GasService: $e');
      return [];
    }
  }
}