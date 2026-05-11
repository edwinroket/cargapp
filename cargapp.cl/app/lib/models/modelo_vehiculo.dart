class ModeloVehiculo {
  final int id;
  final String marca;
  final String modelo;
  final int anio;
  final double rendimientoOficial;
  final String? combustibleLabel;

  ModeloVehiculo({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.rendimientoOficial,
    this.combustibleLabel,
  });

  String get nombre => '$marca $modelo $anio';

  factory ModeloVehiculo.fromJson(Map<String, dynamic> json) {
    return ModeloVehiculo(
      id: json['id'],
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      anio: json['anio'] ?? 0,
      rendimientoOficial: double.tryParse(json['rendimiento_mixto']?.toString() ?? '0') ?? 0,
      combustibleLabel: json['combustible_label'],
    );
  }
}