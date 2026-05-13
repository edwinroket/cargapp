class Combustible {
  final String nombre;
  final String categoria;
  final double precio;
  final DateTime fechaRegistro;

  Combustible({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.fechaRegistro,
  });

  factory Combustible.fromJson(Map<String, dynamic> json) {
    return Combustible(
      nombre: json['combustible'] ?? '',
      categoria: json['categoria'] ?? '',
      precio: double.tryParse(json['precio'].toString()) ?? 0,
      fechaRegistro: json['fecha_registro'] != null 
          ? DateTime.parse(json['fecha_registro']) 
          : (json['fecha_actualizacion'] != null 
              ? DateTime.parse(json['fecha_actualizacion']) 
              : DateTime.now()),
    );
  }
}

class Estacion {
  final int id;
  final String nombre;
  final String marca;
  final String direccion;
  final String comuna;
  final String region;
  final double latitud;
  final double longitud;
  final double distanciaKm;
  final List<Combustible> combustibles;

  Estacion({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.direccion,
    required this.comuna,
    required this.region,
    required this.latitud,
    required this.longitud,
    required this.distanciaKm,
    required this.combustibles,
  });

  factory Estacion.fromJson(Map<String, dynamic> json) {
    return Estacion(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      marca: json['marca'] ?? '',
      direccion: json['direccion'] ?? '',
      comuna: json['comuna'] ?? '',
      region: json['region'] ?? '',
      latitud: double.tryParse(json['latitud'].toString()) ?? 0,
      longitud: double.tryParse(json['longitud'].toString()) ?? 0,
      // Usamos 'distancia' ya que así lo nombramos en el SQL (distanciaKm en el modelo)
      distanciaKm: double.tryParse(json['distancia']?.toString() ?? '0') ?? 0,
      combustibles: (json['combustibles'] as List? ?? [])
          .map((c) => Combustible.fromJson(c))
          .toList(),
    );
  }

  double? getPrecio(String nombreCombustible) {
    try {
      return combustibles
          .firstWhere((c) => c.nombre.toLowerCase().contains(nombreCombustible.toLowerCase()))
          .precio;
    } catch (_) {
      return null;
    }
  }
}