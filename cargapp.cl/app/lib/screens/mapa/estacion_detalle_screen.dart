import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';
import 'package:intl/intl.dart'; 

class EstacionDetalleScreen extends StatefulWidget {
  final int estacionId;
  const EstacionDetalleScreen({super.key, required this.estacionId});

  @override
  State<EstacionDetalleScreen> createState() => _EstacionDetalleScreenState();
}

class _EstacionDetalleScreenState extends State<EstacionDetalleScreen> {
  Map<String, dynamic>? _datos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _obtenerDetalle();
  }

  Future<void> _obtenerDetalle() async {
    try {
      final response = await ApiService.get('${ApiConfig.estaciones}/${widget.estacionId}');
      setState(() {
        _datos = response;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      debugPrint('Error: $e');
    }
  }

  void _mostrarHistorial() {
    final historial = (_datos!['historial'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Historial de cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 5),
                  const Text('Registros de precios detectados', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const Divider(),
                  Expanded(
                    child: historial.isEmpty 
                      ? const Center(child: Text('No hay registros antiguos aún'))
                      : ListView.builder(
                        controller: scrollController,
                        itemCount: historial.length,
                        itemBuilder: (context, index) {
                          final h = historial[index];
                          DateTime fecha = h['fecha_registro'] != null 
                              ? DateTime.parse(h['fecha_registro'].toString()) 
                              : DateTime.now();
                          String fechaString = DateFormat('dd MMM, HH:mm').format(fecha);

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFf0fdf4),
                              child: Icon(Icons.history, color: Color(0xFF16a34a), size: 20),
                            ),
                            title: Text('${h['combustible']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Fecha: $fechaString'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${double.parse(h['precio'].toString()).round()}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16a34a))),
                                Text(h['fuente']?.toString().toUpperCase() ?? 'CNE', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildServicioIcon(IconData icon, String label, int activo) {
    return Column(
      children: [
        Icon(icon, color: activo == 1 ? const Color(0xFF16a34a) : Colors.grey[300], size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: activo == 1 ? Colors.black : Colors.grey)),
      ],
    );
  }

  Widget _buildOctanajeBadge(String combustible, String precio, String? precioAnterior) {
    // Manejo de octanaje para el avatar circular
    String corto = '95';
    if (combustible.contains('93')) corto = '93';
    else if (combustible.contains('97')) corto = '97';
    else if (combustible.toLowerCase().contains('di')) corto = 'DI';
    else if (combustible.toLowerCase().contains('ker')) corto = 'KE';

    double actual = double.tryParse(precio) ?? 0;
    // Limpiamos el valor anterior por si viene como string "null" de la API
    double? anterior = (precioAnterior != null && precioAnterior != "null") 
        ? double.tryParse(precioAnterior) 
        : null;
    
    IconData tendenciaIcon = Icons.horizontal_rule; // Símbolo "=" por defecto
    Color tendenciaColor = Colors.grey;

    // Lógica de comparación
    if (anterior != null) {
      if (actual > anterior) {
        tendenciaIcon = Icons.arrow_upward;
        tendenciaColor = Colors.red;
      } else if (actual < anterior) {
        tendenciaIcon = Icons.arrow_downward;
        tendenciaColor = Colors.green;
      } else {
        // Si son iguales, mantenemos el símbolo neutro
        tendenciaIcon = Icons.drag_handle; 
        tendenciaColor = Colors.blueGrey.withOpacity(0.5);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF16a34a),
            radius: 18,
            child: Text(corto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(combustible, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (anterior != null && actual != anterior)
                  Text(
                    'Ant: \$${anterior.round()}', 
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])
                  ),
              ],
            ),
          ),
          // Icono de tendencia (Solo si tenemos un precio anterior real para comparar)
          if (anterior != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(tendenciaIcon, color: tendenciaColor, size: 20),
            ),
          Text(
            '\$${actual.round()}', 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 20, 
              color: (anterior != null && actual > anterior) ? Colors.red : const Color(0xFF16a34a)
            )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_datos == null) return const Scaffold(body: Center(child: Text('Error al cargar datos')));

    final estacion = _datos!['estacion'] ?? {};
    final precios = (_datos!['precios_actuales'] as List?) ?? [];
    
    String titulo = estacion['marca']?.toString().toUpperCase() ?? estacion['nombre'].toString();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text(titulo), backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF16a34a),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(estacion['direccion']?.toString().trim() ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  Text("${estacion['comuna']}, ${estacion['region']}", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Servicios disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildServicioIcon(Icons.wc, 'Baños', estacion['tiene_bano'] ?? 0),
                      _buildServicioIcon(Icons.shopping_cart, 'Tienda', estacion['tiene_tienda'] ?? 0),
                      _buildServicioIcon(Icons.build, 'Lubricentro', estacion['tiene_lubricentro'] ?? 0),
                      _buildServicioIcon(Icons.atm, 'Cajero', estacion['tiene_cajero'] ?? 0),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text('Precios actuales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  ...precios.map((p) => _buildOctanajeBadge(
                    p['combustible'], 
                    p['precio'].toString(), 
                    p['precio_anterior']?.toString()
                  )).toList(),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _mostrarHistorial, 
                      icon: const Icon(Icons.history),
                      label: const Text('Ver historial de cambios'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF16a34a)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}