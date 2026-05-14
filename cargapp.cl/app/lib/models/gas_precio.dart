class GasPrecio {
  final String marca;
  final String? logoUrl;
  final String local;
  final String direccion;
  final String? telefono;
  final double latitud;
  final double longitud;
  final String formato;
  final int precio;
  final DateTime fechaActualizacion;

  GasPrecio({
    required this.marca,
    this.logoUrl,
    required this.local,
    required this.direccion,
    this.telefono,
    required this.latitud,
    required this.longitud,
    required this.formato,
    required this.precio,
    required this.fechaActualizacion,
  });

  factory GasPrecio.fromJson(Map<String, dynamic> json) {
    return GasPrecio(
      marca: json['marca'],
      logoUrl: json['logo_url'],
      local: json['local'],
      direccion: json['direccion'],
      telefono: json['telefono'],
      latitud: double.parse(json['latitud'].toString()),
      longitud: double.parse(json['longitud'].toString()),
      formato: json['formato'],
      precio: json['precio'],
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion']),
    );
  }
}