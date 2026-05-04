class Descuento {
  final int id;
  final String origen;
  final String convenio;
  final String tipo;
  final String dia;
  final double? descuentoNum;
  final String? descuentoTexto;
  final String? condicion;
  final String? topeMensual;
  final String? notas;

  Descuento({
    required this.id,
    required this.origen,
    required this.convenio,
    required this.tipo,
    required this.dia,
    this.descuentoNum,
    this.descuentoTexto,
    this.condicion,
    this.topeMensual,
    this.notas,
  });

  factory Descuento.fromJson(Map<String, dynamic> json) {
    return Descuento(
      id             : json['id'],
      origen         : json['origen']          ?? '',
      convenio       : json['convenio']        ?? '',
      tipo           : json['tipo']            ?? '',
      dia            : json['dia']             ?? '',
      descuentoNum   : double.tryParse(json['descuento_num']?.toString() ?? ''),
      descuentoTexto : json['descuento_texto'],
      condicion      : json['condicion'],
      topeMensual    : json['tope_mensual'],
      notas          : json['notas'],
    );
  }
}