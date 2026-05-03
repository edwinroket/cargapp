class Usuario {
  final int id;
  final String email;
  final String? nombre;
  final bool esPremium;
  final int reputacion;

  Usuario({
    required this.id,
    required this.email,
    this.nombre,
    required this.esPremium,
    required this.reputacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id        : json['id'],
      email     : json['email']      ?? '',
      nombre    : json['nombre']     ?? json['nombre_completo'],
      esPremium : json['premium'] == 1 || json['es_premium'] == 1,
      reputacion: json['reputacion'] ?? json['puntos_reputacion'] ?? 0,
    );
  }
}