import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';
import 'nueva_reporte_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List _reportes = [];
  bool _cargando = true;
  bool _mostrarTutorial = true;

  @override
  void initState() {
    super.initState();
    _fetchReportes();
  }

  // Obtenemos los reportes cercanos (Radio 10km)
  Future<void> _fetchReportes() async {
    try {
      // Coordenadas de prueba (Talca)
      final response = await ApiService.get(
        '${ApiConfig.reportes}/cercanos?lat=-35.4264&lng=-71.6559&radio=10'
      );
      
      setState(() {
        if (response is Map && response.containsKey('reportes')) {
          _reportes = response['reportes'];
        } else if (response is List) {
          _reportes = response;
        } else {
          _reportes = [];
        }
        _cargando = false;
      });
    } catch (e) {
      print("Error en fetch reportes: $e");
      setState(() => _cargando = false);
    }
  }

  // Función para votar (Reddit Style con Sombreado)
  Future<void> _votar(int reporteId, String tipo) async {
    try {
      await ApiService.post('${ApiConfig.reportes}/$reporteId/votar', {'voto': tipo});
      _fetchReportes(); // Refrescar para ver cambios y sombreado
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes votar tu propio reporte o error de conexión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad CargApp'),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReportes,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_mostrarTutorial) _buildTutorialCard(),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Reportes de precios cerca de ti', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),

                  if (_reportes.isEmpty && !_mostrarTutorial)
                    _buildEmptyState()
                  else
                    ..._reportes.map((r) => _buildReporteCard(r)).toList(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF16a34a),
        child: const Icon(Icons.add_comment, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevaReporteScreen()),
          );
          _fetchReportes();
        },
      ),
    );
  }

  Widget _buildTutorialCard() {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('¡Gana Reputación!', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirma precios para ganar Karma. Las flechas iluminadas indican tu voto actual.',
                  style: TextStyle(fontSize: 13),
                ),
                const Divider(),
                const Text('Ejemplo visual:', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                _buildReporteCard({
                  'id': 0,
                  'estacion_formateada': 'Av. Principal 123 (COPEC)',
                  'distancia_km': 0.5,
                  'combustible': 'Gasolina 95',
                  'precio_reportado': '1250.0',
                  'usuario': 'Admin',
                  'reputacion_usuario': 99,
                  'votos_positivos': 10,
                  'votos_negativos': 2,
                  'mi_voto': 'positivo', // Simula que ya votamos
                }, esEjemplo: true),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
              onPressed: () => setState(() => _mostrarTutorial = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporteCard(Map reporte, {bool esEjemplo = false}) {
    int score = (reporte['votos_positivos'] ?? 0) - (reporte['votos_negativos'] ?? 0);
    String? miVoto = reporte['mi_voto']; // 'positivo', 'negativo' o null
    
    String nombreEstacion = reporte['estacion_formateada'] ?? 
                            reporte['estacion_nombre'] ?? 
                            'Estación desconocida';

    return Card(
      elevation: esEjemplo ? 0 : 2,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // SECCIÓN DE VOTOS SOMBREADA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04), // Sombreado gris suave
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_upward, 
                      color: miVoto == 'positivo' ? Colors.orange : Colors.grey,
                      size: miVoto == 'positivo' ? 28 : 24,
                    ),
                    onPressed: esEjemplo ? null : () => _votar(reporte['id'], 'positivo'),
                  ),
                  Text('$score', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: miVoto == 'positivo' ? Colors.orange : 
                          (miVoto == 'negativo' ? Colors.blue : Colors.black),
                  )),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_downward, 
                      color: miVoto == 'negativo' ? Colors.blue : Colors.grey,
                      size: miVoto == 'negativo' ? 28 : 24,
                    ),
                    onPressed: esEjemplo ? null : () => _votar(reporte['id'], 'negativo'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombreEstacion,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Text(reporte['combustible'] ?? 'Desconocido', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('\$${reporte['precio_reportado']}', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16a34a))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(reporte['distancia_km'] ?? 0.0).toStringAsFixed(1)} km', 
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person, size: 10, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text('${reporte['usuario'] ?? 'Anónimo'} (★${reporte['reputacion_usuario'] ?? 0})', 
                      style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.location_off_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No hay reportes recientes en tu zona'),
          const Text('¡Sé el primero en informar un precio!', 
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}