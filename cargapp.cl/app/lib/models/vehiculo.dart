class Vehiculo {
  final int id;
  final String? alias;
  final String? marcaManual;
  final String? modeloManual;
  final int? anioManual;
  final double rendimientoKml;
  final String combustible;
  final bool esPrincipal;

  Vehiculo({
    required this.id,
    this.alias,
    this.marcaManual,
    this.modeloManual,
    this.anioManual,
    required this.rendimientoKml,
    required this.combustible,
    required this.esPrincipal,
  });

  String get nombre => alias ?? '$marcaManual $modeloManual ${anioManual ?? ''}';

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id             : json['id'],
      alias          : json['alias'],
      marcaManual    : json['marca_manual'],
      modeloManual   : json['modelo_manual'],
      anioManual     : json['anio_manual'],
      rendimientoKml : double.tryParse(json['rendimiento_km_l'].toString()) ?? 0,
      combustible    : json['combustible'] ?? '',
      esPrincipal    : json['es_principal'] == 1,
    );
  }
}