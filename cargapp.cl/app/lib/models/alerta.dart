class Alerta {
  final int id;
  final double precioUmbral;
  final int radioKm;
  final bool activa;
  final String combustible;
  final String? estacion;
  final DateTime creadoEn;

  Alerta({
    required this.id,
    required this.precioUmbral,
    required this.radioKm,
    required this.activa,
    required this.combustible,
    this.estacion,
    required this.creadoEn,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id           : json['id'],
      precioUmbral : double.tryParse(json['precio_umbral'].toString()) ?? 0,
      radioKm      : json['radio_km'] ?? 5,
      activa       : json['activa'] == 1,
      combustible  : json['combustible'] ?? '',
      estacion     : json['estacion'],
      creadoEn     : DateTime.parse(json['creado_en']),
    );
  }
}