import 'package:flutter/material.dart';
import '../../models/gas_precio.dart';
import '../../services/gas_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GasScreen extends StatefulWidget {
  const GasScreen({super.key});

  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GasService _gasService = GasService();
  List<GasPrecio> _locales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final data = await _gasService.getPreciosGas(comunaId: '07101'); 
    setState(() {
      _locales = data;
      _loading = false;
    });
  }

  // Método asíncrono para despachar la llamada al marcador nativo
  Future<void> _hacerLlamada(String? numero) async {
    if (numero == null || numero.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este distribuidor no tiene un teléfono válido registrado.')),
      );
      return;
    }

    // Filtramos espacios, guiones y paréntesis molestos de la API
    final String numeroLimpio = numero.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    final Uri telUri = Uri.parse('tel:$numeroLimpio');

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        throw 'No se pudo abrir la aplicación de llamadas';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al intentar llamar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas GLP Cercano'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Mapa Distribución'),
            Tab(icon: Icon(Icons.phone), text: 'Lista / Callcenters'),
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildMapaConDisclaimer(),
              _buildListaCallcenters(),
            ],
          ),
    );
  }

  Widget _buildMapaConDisclaimer() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(-35.4264, -71.6554), // Talca
            zoom: 13,
          ),
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapToolbarEnabled: true,
          zoomControlsEnabled: true,
          markers: _locales.where((p) => p.latitud != 0).map((p) {
            final stringFormatos = p.formatos.map((f) => '${f.formato}: \$${f.precio}').join(' | ');
            return Marker(
              markerId: MarkerId('gas-pv-${p.id}'),
              position: LatLng(p.latitud, p.longitud),
              infoWindow: InfoWindow(
                title: p.local,
                snippet: stringFormatos,
              ),
            );
          }).toSet(),
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Card(
            color: Colors.amber.shade50.withOpacity(0.95),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aviso: Los puntos muestran las ubicaciones/oficinas de los proveedores registrados por la CNE, no necesariamente camiones distribuidores.',
                      style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListaCallcenters() {
    return ListView.builder(
      itemCount: _locales.length,
      itemBuilder: (context, index) {
        final item = _locales[index];
        final esCallcenter = item.latitud == 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          elevation: 2,
          child: ExpansionTile(
            key: PageStorageKey('gas-tile-${item.id}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            leading: Icon(
              esCallcenter ? Icons.phone_forwarded : Icons.storefront, 
              color: esCallcenter ? Colors.blue : Colors.orange
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.marca,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: esCallcenter ? Colors.blue.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    esCallcenter ? 'Despacho' : 'Local',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: esCallcenter ? Colors.blue.shade700 : Colors.orange.shade700
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                item.local,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
              ),
            ),
            children: [
              const Divider(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  esCallcenter ? '${item.direccion} (Venta en Regiones / Despacho)' : item.direccion,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              if (item.formatos.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Precios de Cilindros:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: item.formatos.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${f.formato}: \$${f.precio}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.phone, size: 18),
                label: Text('Llamar: ${item.telefono ?? "No informado"}'),
                onPressed: () => _hacerLlamada(item.telefono), // Ejecución limpia conectada
              ),
            ],
          ),
        );
      },
    );
  }
}