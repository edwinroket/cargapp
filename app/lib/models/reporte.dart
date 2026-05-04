class Reporte {
  final int id;
  final double precioReportado;
  final int votosPositivos;
  final int votosNegativos;
  final String estado;
  final String combustible;
  final String usuario;
  final int reputacionUsuario;
  final DateTime creadoEn;

  Reporte({
    required this.id,
    required this.precioReportado,
    required this.votosPositivos,
    required this.votosNegativos,
    required this.estado,
    required this.combustible,
    required this.usuario,
    required this.reputacionUsuario,
    required this.creadoEn,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id                : json['id'],
      precioReportado   : double.tryParse(json['precio_reportado'].toString()) ?? 0,
      votosPositivos    : json['votos_positivos']   ?? 0,
      votosNegativos    : json['votos_negativos']   ?? 0,
      estado            : json['estado']            ?? 'pendiente',
      combustible       : json['combustible']       ?? '',
      usuario           : json['usuario']           ?? 'Anónimo',
      reputacionUsuario : json['reputacion_usuario'] ?? 0,
      creadoEn          : DateTime.parse(json['creado_en']),
    );
  }
}