import 'package:flutter/material.dart';
import '../../models/modelo_vehiculo.dart';
import '../../models/vehiculo.dart';
import '../../services/vehiculos_service.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  late Future<List<Vehiculo>> _vehiculosFuture;
  final _formKey = GlobalKey<FormState>();
  
  final _aliasCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _rendimientoCtrl = TextEditingController();
  final _combustibleIdCtrl = TextEditingController();
  final _marcaBusquedaCtrl = TextEditingController();
  final _modeloBusquedaCtrl = TextEditingController();
  final _distanciaViajeCtrl = TextEditingController(text: '100');

  double _costoViajeCalculado = 0;
  Vehiculo? _vehiculoParaCalculo;
  ModeloVehiculo? _modeloSeleccionado;
  List<ModeloVehiculo> _modelos = [];
  bool _cargandoModelos = false;
  bool _esPrincipal = false;

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
  }

  void _loadVehiculos() {
    _vehiculosFuture = VehiculosService.getVehiculos();
    _vehiculosFuture.then((list) {
      if (list.isNotEmpty) {
        setState(() {
          _vehiculoParaCalculo = list.firstWhere((v) => v.esPrincipal, orElse: () => list.first);
          _calcularGastoViaje();
        });
      }
    });
  }

  Future<void> _refresh() async => setState(_loadVehiculos);

  void _calcularGastoViaje() {
    if (_vehiculoParaCalculo == null) return;
    double dist = double.tryParse(_distanciaViajeCtrl.text) ?? 0;
    double rend = _vehiculoParaCalculo!.rendimientoKml;
    setState(() => _costoViajeCalculado = (dist / rend) * 1350.0);
  }

  Future<void> _eliminarVehiculo(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Remover vehículo?"),
        content: const Text("El vehículo ya no aparecerá en tu garage."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remover", style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirmar != true) return;
    await VehiculosService.eliminarVehiculo(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(title: const Text('Mi Garage'), backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white),
      body: FutureBuilder<List<Vehiculo>>(
        future: _vehiculosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final vehiculos = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vehiculos.isNotEmpty) _buildCalculadoraViaje(vehiculos),
                const SizedBox(height: 20),
                const Text("Mis Vehículos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (vehiculos.isEmpty) _buildEmptyState() else ...vehiculos.map((v) => _buildVehicleCard(v)).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioAgregar,
        backgroundColor: const Color(0xFF16a34a),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Agregar Auto"),
      ),
    );
  }

  Widget _buildCalculadoraViaje(List<Vehiculo> vehiculos) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Row(children: [Icon(Icons.calculate, color: Color(0xFF16a34a)), SizedBox(width: 8), Text("Calculadora de Viaje", style: TextStyle(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            DropdownButtonFormField<Vehiculo>(
              value: _vehiculoParaCalculo,
              isExpanded: true,
              items: vehiculos.map((v) => DropdownMenuItem(value: v, child: Text(v.nombre, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() { _vehiculoParaCalculo = val; _calcularGastoViaje(); }),
            ),
            const SizedBox(height: 12),
            TextField(controller: _distanciaViajeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Distancia (km)", suffixText: "km"), onChanged: (_) => _calcularGastoViaje()),
            const SizedBox(height: 16),
            Text("Costo estimado: \$${_costoViajeCalculado.toStringAsFixed(0)} CLP", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehiculo vehiculo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(Icons.directions_car, color: vehiculo.esPrincipal ? Colors.green : Colors.grey),
        title: Text(vehiculo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${vehiculo.marcaManual ?? 'Oficial'} | ${vehiculo.combustible}"),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _eliminarVehiculo(vehiculo.id)),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("Garage vacío"));

  void _abrirFormularioAgregar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(onPressed: _abrirSelectorModelo, icon: const Icon(Icons.search), label: const Text('Catálogo Oficial')),
                TextFormField(controller: _marcaCtrl, decoration: const InputDecoration(labelText: 'Marca')),
                TextFormField(controller: _modeloCtrl, decoration: const InputDecoration(labelText: 'Modelo')),
                TextFormField(controller: _rendimientoCtrl, decoration: const InputDecoration(labelText: 'Km/L')),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await VehiculosService.crearVehiculo(
                      modeloId: _modeloSeleccionado?.id,
                      marca: _marcaCtrl.text,
                      modelo: _modeloCtrl.text,
                      anio: 2024,
                      rendimiento: double.parse(_rendimientoCtrl.text),
                      tipoCombustibleId: 1,
                    );
                    Navigator.pop(context);
                    _refresh();
                  },
                  child: const Text("Guardar"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirSelectorModelo() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Buscador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _marcaBusquedaCtrl, decoration: const InputDecoration(hintText: "Marca")),
              TextField(controller: _modeloBusquedaCtrl, decoration: const InputDecoration(hintText: "Modelo")),
              ElevatedButton(
                onPressed: () async {
                  setStateDialog(() => _cargandoModelos = true);
                  final res = await VehiculosService.getModelos(marca: _marcaBusquedaCtrl.text, modelo: _modeloBusquedaCtrl.text);
                  setStateDialog(() { _modelos = res; _cargandoModelos = false; });
                },
                child: const Text("Buscar"),
              ),
              if (_cargandoModelos) const CircularProgressIndicator(),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: _modelos.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_modelos[i].nombre),
                    onTap: () {
                      setState(() {
                        _modeloSeleccionado = _modelos[i];
                        _marcaCtrl.text = _modelos[i].marca;
                        _modeloCtrl.text = _modelos[i].modelo;
                        _rendimientoCtrl.text = _modelos[i].rendimientoOficial.toString();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}