import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';

class NuevaAlertaScreen extends StatefulWidget {
  const NuevaAlertaScreen({super.key});

  @override
  State<NuevaAlertaScreen> createState() => _NuevaAlertaScreenState();
}

class _NuevaAlertaScreenState extends State<NuevaAlertaScreen> {
  final _precioController = TextEditingController();
  int? _combustibleSeleccionado;
  double _radioKm = 5.0;
  bool _enviando = false;

  final List<Map<String, dynamic>> _tipos = [
    {'id': 1, 'nombre': 'Gasolina 93'},
    {'id': 2, 'nombre': 'Gasolina 95'},
    {'id': 3, 'nombre': 'Gasolina 97'},
    {'id': 4, 'nombre': 'Diésel'},
    {'id': 5, 'nombre': 'Kerosene'},
    {'id': 6, 'nombre': 'GLP'},
  ];

  Future<void> _guardarAlerta() async {
    if (_combustibleSeleccionado == null || _precioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
      return;
    }

    setState(() => _enviando = true);

    try {
      // Obtenemos ubicación actual para el radio de búsqueda
      Position pos = await Geolocator.getCurrentPosition();

      final data = {
        'tipo_combustible_id': _combustibleSeleccionado,
        'precio_umbral': double.parse(_precioController.text),
        'radio_km': _radioKm.toInt(),
        'latitud_usuario': pos.latitude,
        'longitud_usuario': pos.longitude,
      };

      await ApiService.post(ApiConfig.alertas, data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Alerta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Qué combustible buscas?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _tipos.map((t) {
                return ChoiceChip(
                  label: Text(t['nombre']),
                  selected: _combustibleSeleccionado == t['id'],
                  selectedColor: const Color(0xFF16a34a).withValues(alpha: 0.2),
                  onSelected: (val) => setState(() => _combustibleSeleccionado = t['id']),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text('Precio máximo a pagar (\$)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ej: 1350', suffixIcon: Icon(Icons.attach_money)),
            ),
            const SizedBox(height: 30),
            Text('Radio de búsqueda: ${_radioKm.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Slider(
              value: _radioKm,
              min: 1,
              max: 20,
              activeColor: const Color(0xFF16a34a),
              onChanged: (val) => setState(() => _radioKm = val),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _guardarAlerta,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white),
                child: _enviando ? const CircularProgressIndicator(color: Colors.white) : const Text('CREAR ALERTA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}