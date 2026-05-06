class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  
  static const String estaciones        = '$baseUrl/estaciones';
  static const String usuarios          = '$baseUrl/usuarios';
  static const String auth              = '$baseUrl/auth';
  static const String alertas           = '$baseUrl/alertas';
  static const String reportes          = '$baseUrl/reportes';
  static const String vehiculos         = '$baseUrl/vehiculos';
  static const String descuentos        = '$baseUrl/descuentos';
  static const String vehiculosModelos  = '$vehiculos/modelos';
}
