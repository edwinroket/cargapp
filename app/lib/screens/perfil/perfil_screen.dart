import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  List<Map<String, dynamic>> _regiones = [];
  List<Map<String, dynamic>> _ciudades = [];
  int? _regionSeleccionada;
  int? _ciudadSeleccionada;
  bool _cargandoRegiones = false;
  bool _cargandoCiudades = false;
  String? _errorRegiones;

  Future<void> _cargarRegiones(Function(VoidCallback) setModalState) async {
    if (_cargandoRegiones) return;
    _cargandoRegiones = true;
    _errorRegiones = null;
    
    try {
      final regiones = await AuthService.getRegiones();
      setModalState(() {
        _regiones = regiones;
        _cargandoRegiones = false;
      });
    } catch (e) {
      setModalState(() {
        _errorRegiones = e.toString().replaceAll('Exception: ', '');
        _cargandoRegiones = false;
      });
    }
  }

  Future<void> _cargarCiudades(int regionId, Function(VoidCallback) setModalState) async {
    if (_cargandoCiudades) return;
    _cargandoCiudades = true;

    try {
      final ciudades = await AuthService.getCiudadesPorRegion(regionId);
      setModalState(() {
        _ciudades = ciudades;
        _cargandoCiudades = false;
      });
    } catch (e) {
      setModalState(() {
        _ciudades = [];
        _cargandoCiudades = false;
      });
    }
  }

  void _abrirEditor(AuthProvider auth) {
      final usuario = auth.usuario!;
      _nombreCtrl.text = usuario.nombre ?? '';
      _telefonoCtrl.text = usuario.telefono ?? '';
      _regionSeleccionada = usuario.regionId;
      _ciudadSeleccionada = usuario.ciudadId;
      _regiones = [];
      _ciudades = [];
      _errorRegiones = null;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) { // Usamos el context del builder
          return StatefulBuilder(
            builder: (context, setModalState) {
              if (_regiones.isEmpty && !_cargandoRegiones && _errorRegiones == null) {
                _cargarRegiones(setModalState);
              }

              return Padding(
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Editar perfil',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu teléfono' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Dropdown de Región con solución al Overflow
                        if (_cargandoRegiones)
                          const Center(child: CircularProgressIndicator())
                        else
                          DropdownButtonFormField<int>(
                            isExpanded: true, // SOLUCIÓN AL OVERFLOW: Evita que el texto se salga
                            value: _regionSeleccionada,
                            decoration: const InputDecoration(labelText: 'Región', border: OutlineInputBorder()),
                            items: _regiones.map((region) {
                              return DropdownMenuItem<int>(
                                value: region['id'],
                                child: Text(region['nombre'], overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                _regionSeleccionada = value;
                                _ciudadSeleccionada = null;
                                _ciudades = [];
                              });
                              if (value != null) _cargarCiudades(value, setModalState);
                            },
                          ),
                        
                        const SizedBox(height: 16),
                        
                        if (_regionSeleccionada != null)
                          _cargandoCiudades 
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<int>(
                                isExpanded: true, // SOLUCIÓN AL OVERFLOW
                                value: _ciudadSeleccionada,
                                decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
                                items: _ciudades.map((ciudad) {
                                  return DropdownMenuItem<int>(
                                    value: ciudad['id'],
                                    child: Text(ciudad['nombre'], overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (value) => setModalState(() => _ciudadSeleccionada = value),
                              ),

                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            
                            // 1. Guardamos una referencia al ScaffoldMessenger ANTES del pop
                            final messenger = ScaffoldMessenger.of(this.context);
                            
                            // 2. Cerramos el modal
                            Navigator.pop(context);
                            
                            // 3. Ejecutamos la actualización
                            final ok = await auth.actualizarPerfil(
                              _nombreCtrl.text.trim(),
                              _telefonoCtrl.text.trim(),
                              ciudadId: _ciudadSeleccionada,
                            );

                            // 4. Usamos la referencia guardada para mostrar el mensaje
                            if (!ok) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(auth.error ?? 'Error al actualizar'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Perfil actualizado con éxito'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16a34a),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Guardar cambios'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;

    if (usuario == null) {
      return const Scaffold(body: Center(child: Text('No se encontró sesión activa.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: const Color(0xFF16a34a),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _abrirEditor(auth))
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView( // CORRECCIÓN: Permite scroll para evitar Overflow
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFdcfce7),
                    child: Text(
                      (usuario.nombre != null && usuario.nombre!.isNotEmpty)
                          ? usuario.nombre![0].toUpperCase()
                          : (usuario.email.isNotEmpty ? usuario.email[0].toUpperCase() : '?'),
                      style: const TextStyle(fontSize: 36, color: Color(0xFF16a34a), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(usuario.nombre ?? 'Usuario', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(usuario.email, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(usuario.telefono ?? 'Sin teléfono registrado', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  usuario.ciudad != null ? '${usuario.ciudad}, ${usuario.region ?? ""}' : 'Sin ciudad registrada',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.star, 'Reputación', usuario.reputacion.toString()),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium, color: Color(0xFF16a34a)),
                            const SizedBox(width: 12),
                            const Text('Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Chip(
                              label: Text(usuario.esPremium ? 'Activo' : 'Básico', style: const TextStyle(color: Colors.white)),
                              backgroundColor: usuario.esPremium ? const Color(0xFF16a34a) : Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFdc2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF16a34a)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value),
      ],
    );
  }
}