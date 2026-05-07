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
  final _anioBusquedaCtrl = TextEditingController();
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
  }

  Future<void> _refresh() async {
    setState(_loadVehiculos);
    await _vehiculosFuture;
  }

  Future<void> _eliminarVehiculo(int id) async {
    try {
      await VehiculosService.eliminarVehiculo(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo eliminado')),
      );
      await _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar vehículo: $e')),
      );
    }
  }

  Future<void> _buscarModelos() async {
    setState(() {
      _cargandoModelos = true;
      _modelos = [];
    });

    try {
      final modelos = await VehiculosService.getModelos(
        marca: _marcaBusquedaCtrl.text.trim().isEmpty ? null : _marcaBusquedaCtrl.text.trim(),
        modelo: _modeloBusquedaCtrl.text.trim().isEmpty ? null : _modeloBusquedaCtrl.text.trim(),
        anio: int.tryParse(_anioBusquedaCtrl.text.trim()),
      );
      setState(() {
        _modelos = modelos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar modelos: $e')),
        );
      }
    } finally {
      setState(() {
        _cargandoModelos = false;
      });
    }
  }

  Future<void> _abrirSelectorModelo() async {
    _marcaBusquedaCtrl.clear();
    _modeloBusquedaCtrl.clear();
    _anioBusquedaCtrl.clear();
    _modelos = [];
    _cargandoModelos = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Buscar modelo de vehículo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _marcaBusquedaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _modeloBusquedaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _anioBusquedaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      setStateDialog(() {
                        _cargandoModelos = true;
                        _modelos = [];
                      });
                      await _buscarModelos();
                      setStateDialog(() {});
                    },
                    child: const Text('Buscar modelos'),
                  ),
                  const SizedBox(height: 16),
                  if (_cargandoModelos)
                    const Center(child: CircularProgressIndicator())
                  else if (_modelos.isEmpty)
                    const Text('No hay modelos. Ajusta la búsqueda.')
                  else
                    SizedBox(
                      height: 240,
                      child: ListView.separated(
                        itemCount: _modelos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final modelo = _modelos[index];
                          return ListTile(
                            title: Text(modelo.nombre),
                            subtitle: Text('Rendimiento oficial: ${modelo.rendimientoOficial.toStringAsFixed(1)} km/l'),
                            onTap: () {
                              setState(() {
                                _modeloSeleccionado = modelo;
                                _marcaCtrl.text = modelo.marca;
                                _modeloCtrl.text = modelo.modelo;
                                _anioCtrl.text = modelo.anio.toString();
                                _rendimientoCtrl.text = modelo.rendimientoOficial.toStringAsFixed(1);
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirFormularioAgregar() {
    _aliasCtrl.clear();
    _marcaCtrl.clear();
    _modeloCtrl.clear();
    _anioCtrl.clear();
    _rendimientoCtrl.clear();
    _combustibleIdCtrl.clear();
    _modeloSeleccionado = null;
    _esPrincipal = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Agregar vehículo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aliasCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alias (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _abrirSelectorModelo,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar modelo oficial'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_modeloSeleccionado != null)
                      Card(
                        color: const Color(0xFFE0F2FE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Seleccionado: ${_modeloSeleccionado!.nombre} · ${_modeloSeleccionado!.rendimientoOficial.toStringAsFixed(1)} km/l',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _marcaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa la marca';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modeloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el modelo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _anioCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el año';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Año inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rendimientoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rendimiento (km/l)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el rendimiento';
                        }
                        if (double.tryParse(value.replaceAll(',', '.')) == null) {
                          return 'Rendimiento inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _combustibleIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ID tipo de combustible',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el ID del combustible';
                        }
                        if (int.tryParse(value) == null) {
                          return 'ID inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _esPrincipal,
                      onChanged: (value) {
                        setState(() {
                          _esPrincipal = value;
                        });
                      },
                      title: const Text('Vehículo principal'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.pop(context);
                        try {
                          await VehiculosService.crearVehiculo(
                            modeloId: _modeloSeleccionado?.id,
                            marca: _marcaCtrl.text.trim(),
                            modelo: _modeloCtrl.text.trim(),
                            anio: int.parse(_anioCtrl.text.trim()),
                            rendimiento: double.parse(_rendimientoCtrl.text.trim().replaceAll(',', '.')),
                            tipoCombustibleId: int.parse(_combustibleIdCtrl.text.trim()),
                            alias: _aliasCtrl.text.trim().isEmpty ? null : _aliasCtrl.text.trim(),
                            esPrincipal: _esPrincipal,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehículo agregado correctamente')),
                          );
                          await _refresh();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al agregar vehículo: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16a34a),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar vehículo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _rendimientoCtrl.dispose();
    _combustibleIdCtrl.dispose();
    _marcaBusquedaCtrl.dispose();
    _modeloBusquedaCtrl.dispose();
    _anioBusquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Vehiculo>>(
        future: _vehiculosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error al cargar vehículos', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final vehiculos = snapshot.data ?? [];
          if (vehiculos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No tienes vehículos registrados aún.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _abrirFormularioAgregar,
                      child: const Text('Agregar vehículo'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vehiculos.length + 1,
              separatorBuilder: (context, index) {
                if (index == 0) return const SizedBox(height: 16);
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Consumo vehicular',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Plataforma del Ministerio de Energía con datos oficiales de rendimiento por marca y modelo de vehículo. Permite calcular el costo real por kilómetro según el auto específico del usuario.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Funciones disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Perfil de usuario · Registro del vehículo (marca, modelo, rendimiento). Registro de tarjetas bancarias para cálculo de descuentos. Estaciones favoritas con seguimiento directo. Historial de cargas registradas y gasto mensual estimado.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final vehiculo = vehiculos[index - 1];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(vehiculo.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (vehiculo.combustible.isNotEmpty) ...[
                          Text('Combustible: ${vehiculo.combustible}'),
                        ],
                        Text('Rendimiento: ${vehiculo.rendimientoKml.toStringAsFixed(1)} km/l'),
                        if (vehiculo.esPrincipal)
                          const Text('Vehículo principal', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarVehiculo(vehiculo.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioAgregar,
        backgroundColor: const Color(0xFF16a34a),
        child: const Icon(Icons.add),
      ),
    );
  }
}
