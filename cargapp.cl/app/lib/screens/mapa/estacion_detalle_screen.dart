import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Importante para el gráfico

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

  // LÓGICA DEL GRÁFICO (Mantenida pero oculta en la UI)
  void _mostrarHistorial() {
    final historial = (_datos!['historial'] as List?) ?? [];
    
    Map<String, List<FlSpot>> datosGrafico = {};
    List<String> fechasX = [];
    final historialOrdenado = historial.reversed.toList();
    
    for (int i = 0; i < historialOrdenado.length; i++) {
      final h = historialOrdenado[i];
      final nombre = h['combustible']?.toString() ?? '';
      final nombreLower = nombre.toLowerCase();

      bool esValido = nombreLower.contains('93') || 
                      nombreLower.contains('95') || 
                      nombreLower.contains('97') || 
                      nombreLower.contains('diesel');
      
      if (!esValido || nombreLower.contains('kerosen') || nombreLower.contains('parafina')) {
        continue;
      }

      final precio = double.tryParse(h['precio'].toString()) ?? 0;
      final fecha = DateTime.parse(h['fecha_registro'].toString());
      
      fechasX.add(DateFormat('dd/MM').format(fecha));
      
      if (!datosGrafico.containsKey(nombre)) {
        datosGrafico[nombre] = [];
      }
      datosGrafico[nombre]!.add(FlSpot((fechasX.length - 1).toDouble(), precio));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tendencia de Precios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 30),
              
              if (datosGrafico.isEmpty)
                const Expanded(child: Center(child: Text('No hay historial suficiente')))
              else
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < fechasX.length && index % 2 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(fechasX[index], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              return LineTooltipItem(
                                '\$${barSpot.y.round()}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: datosGrafico.entries.map((entry) {
                        Color color = entry.key.contains('93') ? Colors.red : 
                                      (entry.key.contains('95') || entry.key.contains('97')) ? Colors.blue : 
                                      Colors.green;
                        
                        return LineChartBarData(
                          spots: entry.value,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.05)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem("93", Colors.red),
                  const SizedBox(width: 15),
                  _buildLegendItem("95/97", Colors.blue),
                  const SizedBox(width: 15),
                  _buildLegendItem("Diesel", Colors.green),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
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
    String corto = '95';
    if (combustible.contains('93')) {
      corto = '93';
    } else if (combustible.contains('97')) corto = '97';
    else if (combustible.toLowerCase().contains('di')) corto = 'DI';
    else if (combustible.toLowerCase().contains('ker')) corto = 'KE';

    double actual = double.tryParse(precio) ?? 0;
    double? anterior = (precioAnterior != null && precioAnterior != "null") ? double.tryParse(precioAnterior) : null;
    
    IconData tendenciaIcon = Icons.horizontal_rule;
    Color tendenciaColor = Colors.grey;

    if (anterior != null) {
      if (actual > anterior) {
        tendenciaIcon = Icons.arrow_upward;
        tendenciaColor = Colors.red;
      } else if (actual < anterior) {
        tendenciaIcon = Icons.arrow_downward;
        tendenciaColor = Colors.green;
      } else {
        tendenciaIcon = Icons.drag_handle; 
        tendenciaColor = Colors.blueGrey.withValues(alpha: 0.5);
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
                  Text('Ant: \$${anterior.round()}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
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
                  Text("${estacion['comuna']}, ${estacion['region']}", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
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
                  )),
                  const SizedBox(height: 20),
                  
                  // BOTÓN COMENTADO: por insuficientes datos para graficar
                  /*
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _mostrarHistorial, 
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Ver gráfico de tendencia'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF16a34a)),
                    ),
                  ),
                  */
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}