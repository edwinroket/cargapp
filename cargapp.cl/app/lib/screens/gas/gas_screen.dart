import 'package:flutter/material.dart';
import '../../models/gas_precio.dart';
import '../../services/gas_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GasScreen extends StatefulWidget {
  const GasScreen({super.key});

  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GasService _gasService = GasService();
  List<GasPrecio> _precios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final data = await _gasService.getPreciosGas();
    setState(() {
      _precios = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas GLP'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Mapa Locales'),
            Tab(icon: Icon(Icons.phone), text: 'Callcenters'),
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildMapa(),
              _buildListaCallcenters(),
            ],
          ),
    );
  }

  Widget _buildMapa() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(-35.4264, -71.6554), // Talca por defecto
        zoom: 12,
      ),
      markers: _precios.where((p) => p.latitud != 0).map((p) {
        return Marker(
          markerId: MarkerId('${p.local}-${p.formato}'),
          position: LatLng(p.latitud, p.longitud),
          infoWindow: InfoWindow(
            title: p.local,
            snippet: '${p.formato}: \$${p.precio}',
          ),
        );
      }).toSet(),
    );
  }

  Widget _buildListaCallcenters() {
    // Filtramos los que tengan "(Callcenter)" en el nombre
    final calls = _precios.where((p) => p.local.contains('(Callcenter)')).toList();

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final item = calls[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.local_fire_department, color: Colors.orange),
            title: Text(item.local),
            subtitle: Text('Formato: ${item.formato}\nTel: ${item.telefono ?? 'No disp.'}'),
            trailing: Text('\$${item.precio}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
          ),
        );
      },
    );
  }
}