class ApiConfig {
  static const String baseUrl = 'http://192.168.1.200:3000/api';
  
  static const String estaciones        = '$baseUrl/estaciones';
  static const String usuarios          = '$baseUrl/usuarios';
  static const String alertas           = '$baseUrl/alertas';
  static const String reportes          = '$baseUrl/reportes';
  static const String vehiculos         = '$baseUrl/vehiculos';
  static const String descuentos        = '$baseUrl/descuentos';
  static const String vehiculosModelos  = '$vehiculos/modelos';
}