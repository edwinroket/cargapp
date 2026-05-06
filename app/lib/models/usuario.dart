class Usuario {
  final int id;
  final String email;
  final String? nombre;
  final String? telefono;
  final bool esPremium;
  final int reputacion;
  final int? ciudadId;
  final String? ciudad;
  final int? regionId;
  final String? region;

  Usuario({
    required this.id,
    required this.email,
    this.nombre,
    this.telefono,
    required this.esPremium,
    required this.reputacion,
    this.ciudadId,
    this.ciudad,
    this.regionId,
    this.region,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id        : _parseInt(json['id']),
      email     : json['email']      ?? '',
      nombre    : json['nombre']     ?? json['nombre_completo'],
      telefono  : json['telefono'],
      esPremium : json['premium'] == 1 || json['premium'] == true ||
          json['es_premium'] == 1 || json['es_premium'] == true,
      reputacion: json['reputacion'] ?? json['puntos_reputacion'] ?? 0,
      ciudadId  : json['ciudad_id'],
      ciudad    : json['ciudad'],
      regionId  : json['region_id'],
      region    : json['region'],
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
