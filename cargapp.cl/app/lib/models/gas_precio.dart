class GasFormato {
  final String formato;
  final int precio;

  GasFormato({required this.formato, required this.precio});

  factory GasFormato.fromJson(Map<String, dynamic> json) {
    return GasFormato(
      // Usamos un mapeo tolerante por si las llaves varían en mayúsculas
      formato: (json['formato'] ?? json['Formato'] ?? 'Desconocido').toString(),
      precio: int.tryParse((json['precio'] ?? json['Precio'] ?? '0').toString()) ?? 0,
    );
  }
}

class GasPrecio {
  final int id;
  final String marca;
  final String? logoUrl;
  final String local;
  final String direccion;
  final String? telefono;
  final double latitud;
  final double longitud;
  final double? distancia;
  final List<GasFormato> formatos;

  GasPrecio({
    required this.id,
    required this.marca,
    this.logoUrl,
    required this.local,
    required this.direccion,
    this.telefono,
    required this.latitud,
    required this.longitud,
    this.distancia,
    required this.formatos,
  });

  factory GasPrecio.fromJson(Map<String, dynamic> json) {
    var list = json['formatos'];
    List<GasFormato> formatoList = [];

    if (list != null) {
      if (list is List) {
        formatoList = list.map((i) => GasFormato.fromJson(Map<String, dynamic>.from(i))).toList();
      }
    }

    return GasPrecio(
      id: json['id'] ?? 0,
      marca: json['marca'] ?? 'S/M',
      logoUrl: json['logo_url'],
      local: json['local'] ?? 'Sin nombre',
      direccion: json['direccion'] ?? 'Dirección no informada',
      telefono: json['telefono'],
      latitud: double.parse((json['latitud'] ?? 0).toString()),
      longitud: double.parse((json['longitud'] ?? 0).toString()),
      distancia: json['distancia'] != null ? double.parse(json['distancia'].toString()) : null,
      formatos: formatoList,
    );
  }
}