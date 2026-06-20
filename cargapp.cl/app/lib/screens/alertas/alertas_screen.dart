import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';
import 'nueva_alerta_screen.dart';
import 'package:intl/intl.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List _alertas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  Future<void> _cargarAlertas() async {
    try {
      final response = await ApiService.get(ApiConfig.alertas);
      setState(() {
        _alertas = response;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminarAlerta(int id) async {
    try {
      await ApiService.delete('${ApiConfig.alertas}/$id');
      setState(() {
        _alertas.removeWhere((a) => a['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Alerta eliminada'),
            backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error al eliminar')));
    }
  }

  Future<void> _toggleAlerta(int id, bool activar) async {
    int valorParaBD = activar ? 1 : 0;
    try {
      await ApiService.put('${ApiConfig.alertas}/$id', {'activa': valorParaBD});
      setState(() {
        final index = _alertas.indexWhere((a) => a['id'] == id);
        if (index != -1) _alertas[index]['activa'] = valorParaBD;
      });
    } catch (e) {
      _cargarAlertas(); // Revertir si falla
    }
  }

  // MÉTODO PARA MOSTRAR LA INFORMACIÓN DE LA ESTACIÓN (EL QUE FALTABA)
  void _mostrarInfoEstacion(BuildContext context, Map alerta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Icon(Icons.location_on, color: Colors.red, size: 45),
              const SizedBox(height: 15),
              Text(
                alerta['estacion'] ?? "Bencinera cercana",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                alerta['estacion_direccion'] ??
                    "Alerta configurada en un radio de ${alerta['radio_km']} km",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (alerta['estacion_id'] != null) {
                    Navigator.pushNamed(
                      context,
                      '/detalle_estacion',
                      arguments: alerta['estacion_id'],
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("VER DETALLE Y MAPA",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alertas'),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) =>
                      _buildAlertaCard(_alertas[index]),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF16a34a),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NuevaAlertaScreen()));
          _cargarAlertas();
        },
      ),
    );
  }

  Widget _buildAlertaCard(Map alerta) {
    bool estaActiva = alerta['activa'] == 1;
    DateTime? ultima = alerta['ultima_notificacion'] != null
        ? DateTime.parse(alerta['ultima_notificacion'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarInfoEstacion(context, alerta),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        estaActiva ? const Color(0xFFf0fdf4) : Colors.grey[100],
                    child: Icon(Icons.notifications_active,
                        color: estaActiva
                            ? const Color(0xFF16a34a)
                            : Colors.grey),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alerta['combustible'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17)),
                        Text(
                          'Avisar si baja de \$${alerta['precio_umbral']}',
                          style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600),
                        ),
                        if (alerta['estacion'] != null)
                          Text(
                            'En: ${alerta['estacion']}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                                overflow: TextOverflow.ellipsis),
                          )
                        else
                          Text(
                            'Radio: ${alerta['radio_km']} km a la redonda',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: estaActiva,
                    activeThumbColor: const Color(0xFF16a34a),
                    onChanged: (val) => _toggleAlerta(alerta['id'], val),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.redAccent, size: 22),
                    onPressed: () => _confirmarEliminar(alerta['id']),
                  ),
                ],
              ),
              const Divider(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Historial',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Text(
                    ultima != null
                        ? 'Último aviso: ${DateFormat('dd/MM HH:mm').format(ultima)}'
                        : 'Sin avisos aún',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar alerta?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _eliminarAlerta(id);
              },
              child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No tienes alertas activas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('¡Crea una para ahorrar!',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}