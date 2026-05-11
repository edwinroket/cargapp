class Vehiculo {
  final int id;
  final int? modeloId; 
  final String? alias;
  final String? marcaManual;
  final String? modeloManual;
  final int? anioManual;
  final double rendimientoKml;
  final String combustible;
  final bool esPrincipal;
  final bool activo; 

  Vehiculo({
    required this.id,
    this.modeloId,
    this.alias,
    this.marcaManual,
    this.modeloManual,
    this.anioManual,
    required this.rendimientoKml,
    required this.combustible,
    required this.esPrincipal,
    required this.activo,
  });

  String get nombre => alias ?? '$marcaManual $modeloManual ${anioManual ?? ''}'.trim();

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'],
      modeloId: json['modelo_id'],
      alias: json['alias'],
      marcaManual: json['marca_manual'] ?? json['marca_oficial'],
      modeloManual: json['modelo_manual'] ?? json['modelo_oficial'],
      anioManual: json['anio_manual'],
      rendimientoKml: double.tryParse(json['rendimiento_km_l']?.toString() ?? 
                       json['rendimiento_oficial']?.toString() ?? '0') ?? 0.0,
      combustible: json['tipo_combustible'] ?? json['combustible'] ?? 'Gasolina',
      esPrincipal: json['es_principal'] == 1,
      activo: json['activo'] == 1,
    );
  }
}