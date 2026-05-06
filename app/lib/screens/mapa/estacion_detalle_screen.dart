import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';

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

  // Widget auxiliar para los servicios (Baño, Tienda, etc.)
  Widget _buildServicioIcon(IconData icon, String label, int activo) {
    return Column(
      children: [
        Icon(icon, color: activo == 1 ? const Color(0xFF16a34a) : Colors.grey[300], size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: activo == 1 ? Colors.black : Colors.grey)),
      ],
    );
  }

  // Widget para el círculo de octanaje (93, 95, 97)
  Widget _buildOctanajeBadge(String combustible, String precio) {
    String corto = combustible.contains('93') ? '93' : combustible.contains('95') ? '95' : '97';
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
            child: Text(corto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(combustible, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(
            '\$${double.parse(precio).round()}', 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF16a34a))
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
    
    // Si la marca es un número, usamos el nombre de la calle como título
    String titulo = (estacion['marca'] == "5" || estacion['marca'] == null) 
        ? estacion['nombre'].toString().trim() 
        : estacion['marca'].toString().toUpperCase();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con dirección
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF16a34a),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(estacion['direccion']?.toString().trim() ?? '', 
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text("${estacion['comuna']}, ${estacion['region']}", 
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Servicios
                  const Text('Servicios disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildServicioIcon(Icons.wc, 'Baños', estacion['tiene_bano'] ?? 0),
                      _buildServicioIcon(Icons.shopping_cart, 'Tienda', estacion['tiene_tienda'] ?? 0),
                      _buildServicioIcon(Icons.build, 'Lubricentro', estacion['tiene_lubricentro'] ?? 0),
                      _buildServicioIcon(Icons.payments, 'Efectivo', 1), // Por defecto activo
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  /*
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(),
                  ),

                  // SECCIÓN DE DESCUENTOS
                  const Text('Beneficios y Convenios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  
                  // Tarjeta de Descuento
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0fdf4), // Un verde muy claro
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF16a34a).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.orange, size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Descuento Municipal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('-\$15 por litro con tarjeta de vecino.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),*/

                  // Listado de precios estilo "Bencina en Línea"
                  const Text('Precios por litro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  ...precios.map((p) => _buildOctanajeBadge(p['combustible'], p['precio'].toString())).toList(),

                  const SizedBox(height: 20),
                  
                  // Botón de historial (Placeholder para el gráfico)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {}, // Aquí iría la lógica para abrir el gráfico
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Ver historial de precios'),
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