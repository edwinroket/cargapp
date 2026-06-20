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

  // Getter inteligente: Si trae apodo lo usa, si no, junta marca y modelo con respaldos anti-null
  String get nombre {
    if (alias != null && alias!.trim().isNotEmpty) return alias!;
    
    final String marcaDisplay = marcaManual ?? 'Vehículo';
    final String modeloDisplay = modeloManual ?? '';
    final String anioDisplay = anioManual != null ? '($anioManual)' : '';
    
    final String resultado = '$marcaDisplay $modeloDisplay $anioDisplay'.trim();
    return resultado.contains('null') ? 'Vehículo sin nombre' : resultado;
  }

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'],
      modeloId: json['modelo_id'],
      alias: json['alias'],
      // ⚡ Agregamos respaldo para json['marca'] y json['modelo'] a secas
      marcaManual: json['marca_manual'] ?? json['marca_oficial'] ?? json['marca'],
      modeloManual: json['modelo_manual'] ?? json['modelo_oficial'] ?? json['modelo'],
      anioManual: json['anio_manual'] ?? json['anio'],
      rendimientoKml: double.tryParse(json['rendimiento_km_l']?.toString() ?? 
                       json['rendimiento_oficial']?.toString() ?? 
                       json['rendimiento']?.toString() ?? '0') ?? 0.0,
      combustible: json['tipo_combustible'] ?? json['combustible'] ?? 'Gasolina 95',
      esPrincipal: json['es_principal'] == 1 || json['es_principal'] == true,
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }
}