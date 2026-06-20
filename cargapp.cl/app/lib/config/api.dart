class ApiConfig {
  // IP local de tu casa (red Wi-Fi interna)
  static const String localBaseUrl = 'http://192.168.1.200:3000/api';
  
  // IP de Tailscale (VPN segura para usar en la calle con datos)
  static const String tailscaleBaseUrl = 'http://100.84.5.45:3000/api';
  
  // Variable mutable que el ApiService modificará en caliente si hay timeout
  static String baseUrl = localBaseUrl;
  
  // ⚡ Getters dinámicos (imprescindibles para que lean el cambio de baseUrl)
  static String get estaciones       => '$baseUrl/estaciones';
  static String get usuarios         => '$baseUrl/usuarios';
  static String get alertas          => '$baseUrl/alertas';
  static String get reportes         => '$baseUrl/reportes';
  static String get vehiculos        => '$baseUrl/vehiculos';
  static String get descuentos       => '$baseUrl/descuentos';
  static String get vehiculosModelos => '$vehiculos/modelos';
}