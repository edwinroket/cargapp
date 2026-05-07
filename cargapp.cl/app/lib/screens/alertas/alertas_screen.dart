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

  // FUNCIÓN CORREGIDA PARA EL SWITCH
  Future<void> _toggleAlerta(int id, bool activar) async {
    // 1 para activa, 0 para inactiva (MariaDB tinyint)
    int valorParaBD = activar ? 1 : 0;

    try {
      final endpoint = '${ApiConfig.alertas}/$id';
      
      // Enviamos el PUT al backend de Node
      await ApiService.put(endpoint, {'activa': valorParaBD});
      
      // Actualizamos solo el item en la lista local para que sea instantáneo
      setState(() {
        final index = _alertas.indexWhere((a) => a['id'] == id);
        if (index != -1) {
          _alertas[index]['activa'] = valorParaBD;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(activar ? 'Alerta activada' : 'Alerta desactivada'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al conectar con el servidor')),
      );
      // Opcional: recargar para revertir el switch si falló la red
      _cargarAlertas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alertas de Precios'),
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
                  itemBuilder: (context, index) {
                    final alerta = _alertas[index];
                    return _buildAlertaCard(alerta);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF16a34a),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const NuevaAlertaScreen())
          );
          _cargarAlertas();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No tienes alertas configuradas', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('¡Crea una para ahorrar en combustible!', 
            style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAlertaCard(Map alerta) {
    // MariaDB devuelve 1 o 0, lo pasamos a bool para el Switch
    bool estaActiva = alerta['activa'] == 1;
    DateTime? ultima = alerta['ultima_notificacion'] != null 
        ? DateTime.parse(alerta['ultima_notificacion']) 
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: estaActiva ? const Color(0xFFf0fdf4) : Colors.grey[100],
                  child: Icon(Icons.local_gas_station, 
                    color: estaActiva ? const Color(0xFF16a34a) : Colors.grey),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alerta['combustible'], 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Avisar si baja de \$${alerta['precio_umbral']}', 
                        style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
                Switch(
                  value: estaActiva,
                  activeColor: const Color(0xFF16a34a),
                  onChanged: (bool newValue) {
                    _toggleAlerta(alerta['id'], newValue);
                  },
                )
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    Text(' Radio: ${alerta['radio_km']} km', 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  ultima != null 
                      ? 'Último aviso: ${DateFormat('dd/MM HH:mm').format(ultima)}' 
                      : 'Sin avisos aún',
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}