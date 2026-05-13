class Alerta {
  final int id;
  final double precioUmbral;
  final int radioKm;
  final bool activa;
  final String combustible;
  final int? estacionId; // Añadido para navegación
  final String? estacionNombre;
  final DateTime creadoEn;
  final DateTime? ultimaNotificacion;

  Alerta({
    required this.id,
    required this.precioUmbral,
    required this.radioKm,
    required this.activa,
    required this.combustible,
    this.estacionId,
    this.estacionNombre,
    required this.creadoEn,
    this.ultimaNotificacion,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      precioUmbral: double.tryParse(json['precio_umbral'].toString()) ?? 0,
      radioKm: json['radio_km'] ?? 5,
      activa: json['activa'] == 1,
      combustible: json['combustible'] ?? '',
      estacionId: json['estacion_id'], // Mapeo del ID para el click
      estacionNombre: json['estacion'],
      creadoEn: DateTime.parse(json['creado_en']),
      ultimaNotificacion: json['ultima_notificacion'] != null 
          ? DateTime.parse(json['ultima_notificacion']) 
          : null,
    );
  }
}