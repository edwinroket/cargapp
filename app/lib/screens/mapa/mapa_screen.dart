import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';
import 'estacion_detalle_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _determinarPosicion();
  }

  Future<void> _determinarPosicion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _loading = false;
      });
      _cargarEstaciones();
    }
  }

  Future<void> _cargarEstaciones() async {
    if (_currentPosition == null) return;

    try {
      final url = '${ApiConfig.estaciones}?lat=${_currentPosition!.latitude}&lng=${_currentPosition!.longitude}&radio=10';
      final response = await ApiService.get(url);
      final List estaciones = response['estaciones'];

      setState(() {
        _markers = estaciones.map((e) {
          return Marker(
            markerId: MarkerId(e['id'].toString()),
            position: LatLng(
              double.parse(e['latitud'].toString()), 
              double.parse(e['longitud'].toString())
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              // CAMBIO AQUÍ: Usamos 'marca' en lugar de 'nombre'
              title: e['marca'].toString().toUpperCase().trim(), 
              snippet: 'Toca para ver precios',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EstacionDetalleScreen(estacionId: e['id'])
                  ),
                );
              },
            ),
          );
        }).toSet();
      });
    } catch (e) {
      debugPrint('Error cargando estaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true, // Reactivamos controles para facilitar pruebas
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF16a34a),
        child: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _cargarEstaciones,
      ),
    );
  }
}