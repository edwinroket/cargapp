import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/api.dart';

class NuevaReporteScreen extends StatefulWidget {
  const NuevaReporteScreen({super.key});

  @override
  State<NuevaReporteScreen> createState() => _NuevaReporteScreenState();
}

class _NuevaReporteScreenState extends State<NuevaReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  
  List _estacionesCercanas = [];
  int? _estacionSeleccionada;
  int? _combustibleSeleccionado;
  bool _enviando = false;
  bool _cargandoEstaciones = true;

  @override
  void initState() {
    super.initState();
    _cargarEstacionesCercanas();
  }

  Future<void> _cargarEstacionesCercanas() async {
    try {
      final String url = '${ApiConfig.baseUrl}/estaciones/cercanas?lat=-35.4264&lng=-71.6559&radio=5';
      final response = await ApiService.get(url);
      
      setState(() {
        _estacionesCercanas = response['estaciones'] ?? []; 
        _cargandoEstaciones = false;
      });
    } catch (e) {
      setState(() => _cargandoEstaciones = false);
      print("Error cargando estaciones: $e"); 
    }
  }

  Future<void> _enviarReporte() async {
    if (!_formKey.currentState!.validate() || _estacionSeleccionada == null || _combustibleSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona estación y combustible')));
      return;
    }

    setState(() => _enviando = true);

    try {
      await ApiService.post(ApiConfig.reportes, {
        'estacion_id': _estacionSeleccionada,
        'tipo_combustible_id': _combustibleSeleccionado,
        'precio_reportado': double.parse(_precioController.text),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Reporte enviado! Karma ganado ★')));
      }
    } catch (e) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar reporte')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Precio'),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
      ),
      body: _cargandoEstaciones 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text('¿Dónde estás?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    isExpanded: true, // Evita el error de overflow (rayas amarillas)
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), 
                      hintText: 'Selecciona la bencinera',
                      prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    ),
                    items: _estacionesCercanas.map<DropdownMenuItem<int>>((est) {
                      return DropdownMenuItem<int>(
                        value: est['id'],
                        child: Text(
                          "${est['direccion']} (${est['marca']})", 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _estacionSeleccionada = val),
                  ),
                  const SizedBox(height: 20),
                  const Text('Combustible', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), 
                      hintText: 'Tipo de combustible',
                      prefixIcon: Icon(Icons.local_gas_station, color: Colors.blue),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Gasolina 93')),
                      DropdownMenuItem(value: 2, child: Text('Gasolina 95')),
                      DropdownMenuItem(value: 3, child: Text('Gasolina 97')),
                      DropdownMenuItem(value: 4, child: Text('Diesel')),
                      DropdownMenuItem(value: 5, child: Text('Kerosene')),
                    ],
                    onChanged: (val) => setState(() => _combustibleSeleccionado = val),
                  ),
                  const SizedBox(height: 20),
                  const Text('Precio Actual', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _precioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), 
                      prefixText: '\$ ',
                      helperText: 'Ingresa el precio que ves en el tótem',
                    ),
                    validator: (value) => value!.isEmpty ? 'Falta el precio' : null,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _enviando ? null : _enviarReporte,
                    child: _enviando 
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) 
                      : const Text('SUBIR REPORTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}