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
  
  // Controladores de Texto para el Registro Manual / Confirmación
  final _aliasCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController(text: '2026'); 
  final _rendimientoCtrl = TextEditingController();
  final _distanciaViajeCtrl = TextEditingController(text: '100');

  // Variables de control de la calculadora de gasto
  double _costoViajeCalculado = 0;
  Vehiculo? _vehiculoParaCalculo;

  // Estados para los selectores en cascada del Catálogo Oficial
  List<String> _marcasCatalogo = [];
  List<String> _modelosFiltrados = [];
  List<ModeloVehiculo> _versionesDisponibles = [];

  String? _marcaSeleccionada;
  String? _modeloSeleccionadoTxt;
  ModeloVehiculo? _versionFinalSeleccionada;

  bool _cargandoMarcas = false;
  bool _cargandoModelos = false;
  bool _cargandoVersiones = false;
  
  bool _esPrincipal = false;
  String _combustibleSeleccionado = '95'; 

  final Color _greenCorporate = const Color(0xFF22c55e);

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
    _cargarMarcasIniciales();
  }

  void _loadVehiculos() {
    _vehiculosFuture = VehiculosService.getVehiculos();
    _vehiculosFuture.then((list) {
      if (list.isNotEmpty) {
        setState(() {
          _vehiculoParaCalculo = list.any((v) => v.esPrincipal) 
              ? list.firstWhere((v) => v.esPrincipal) 
              : list.first;
          _calcularGastoViaje();
        });
      }
    });
  }

  // Carga inicial del listado único de marcas homologadas
  Future<void> _cargarMarcasIniciales() async {
    try {
      setState(() => _cargandoMarcas = true);
      final marcasBase = ['Alfa Romeo', 'Aston Martin', 'Audi', 'Baic', 'Bentley', 'BMW', 'Borgward', 'Brilliance', 'Chevrolet', 'Citroen', 'Ford', 'Honda', 'Hyundai', 'Kia', 'Mazda', 'Nissan', 'Peugeot', 'Suzuki', 'Toyota', 'Volkswagen'];
      setState(() {
        _marcasCatalogo = marcasBase;
        _cargandoMarcas = false;
      });
    } catch (e) {
      setState(() => _cargandoMarcas = false);
    }
  }

  // Carga los modelos específicos asociados a la marca seleccionada
  Future<void> _onMarcaChanged(String? nuevaMarca) async {
    if (nuevaMarca == null) return;
    setState(() {
      _marcaSeleccionada = nuevaMarca;
      _modeloSeleccionadoTxt = null;
      _versionFinalSeleccionada = null;
      _modelosFiltrados = [];
      _versionesDisponibles = [];
      _cargandoModelos = true;
    });

    final resultados = await VehiculosService.getModelos(marca: nuevaMarca, modelo: '');
    
    setState(() {
      _modelosFiltrados = resultados.map((m) => m.modelo).toSet().toList();
      _cargandoModelos = false;
    });
  }

  // Carga las versiones/motorizaciones específicas asociadas al modelo (Paso final de cascada)
  Future<void> _onModeloChanged(String? nuevoModelo) async {
    if (nuevoModelo == null || _marcaSeleccionada == null) return;
    setState(() {
      _modeloSeleccionadoTxt = nuevoModelo;
      _versionFinalSeleccionada = null;
      _versionesDisponibles = [];
      _cargandoVersiones = true;
    });

    final resultados = await VehiculosService.getModelos(marca: _marcaSeleccionada!, modelo: nuevoModelo);
    
    setState(() {
      _versionesDisponibles = resultados;
      _cargandoVersiones = false;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("¿Remover vehículo?"),
        content: const Text("El vehículo ya no aparecerá en tu garage."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remover", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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
      appBar: AppBar(
        title: const Text('Mi Garage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
        backgroundColor: _greenCorporate, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Vehiculo>>(
        future: _vehiculosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _greenCorporate));
          }
          final vehiculos = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            color: _greenCorporate,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vehiculos.isNotEmpty) _buildCalculadoraViaje(vehiculos),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.garage_rounded, color: Colors.grey.shade700, size: 22),
                    const SizedBox(width: 8),
                    const Text("Mis Vehículos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 12),
                if (vehiculos.isEmpty) _buildEmptyState() else ...vehiculos.map((v) => _buildVehicleCard(v)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioAgregar,
        backgroundColor: _greenCorporate,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Agregar Auto", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCalculadoraViaje(List<Vehiculo> vehiculos) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.calculate_rounded, color: _greenCorporate), const SizedBox(width: 8), const Text("Calculadora de Viaje", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))]),
            const SizedBox(height: 16),
            DropdownButtonFormField<Vehiculo>(
              value: _vehiculoParaCalculo,
              isExpanded: true,
              decoration: _inputDecoration(label: "Vehículo Seleccionado", icon: Icons.directions_car_rounded),
              items: vehiculos.map((v) => DropdownMenuItem(value: v, child: Text(v.nombre, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (val) => setState(() { _vehiculoParaCalculo = val; _calcularGastoViaje(); }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _distanciaViajeCtrl, 
              keyboardType: TextInputType.number, 
              decoration: _inputDecoration(label: "Distancia del Viaje", icon: Icons.add_location_alt_rounded).copyWith(suffixText: "km"), 
              onChanged: (_) => _calcularGastoViaje()
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFDCFCE7))),
                child: Column(
                  children: [
                    const Text("COSTO ESTIMADO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D), letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      "\$${_costoViajeCalculado.toStringAsFixed(0)} CLP", 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehiculo vehiculo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: vehiculo.esPrincipal ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
            shape: BoxShape.circle
          ),
          child: Icon(Icons.directions_car_filled_rounded, color: vehiculo.esPrincipal ? _greenCorporate : Colors.grey.shade600),
        ),
        title: Row(
          children: [
            Expanded(child: Text(vehiculo.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16))),
            if (vehiculo.esPrincipal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF22c55e), borderRadius: BorderRadius.circular(8)),
                child: const Text("Principal", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text("${vehiculo.marcaManual ?? 'Catálogo'} | ${vehiculo.combustible} | ${vehiculo.rendimientoKml} Km/L", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), 
          onPressed: () => _eliminarVehiculo(vehiculo.id)
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text("Tu garage está vacío", style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // FORMULARIO QUE INICIA DE INMEDIATO EN EL TAB DEL CATÁLOGO EN CASCADA
  void _abrirFormularioAgregar() {
    _marcaCtrl.clear(); _modeloCtrl.clear(); _rendimientoCtrl.clear(); _aliasCtrl.clear();
    _marcaSeleccionada = null; _modeloSeleccionadoTxt = null; _versionFinalSeleccionada = null;
    _modelosFiltrados = []; _versionesDisponibles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: DefaultTabController(
          length: 2,
          initialIndex: 0, 
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              centerTitle: true,
              bottom: TabBar(
                indicatorColor: _greenCorporate,
                labelColor: _greenCorporate,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.stars_rounded), text: "Catálogo Oficial"), 
                  Tab(icon: Icon(Icons.edit_note_rounded), text: "Registro Manual"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildTabCatalogoCascada(),
                _buildTabManualForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // DROPDOWNS EN CASCADA COMO EL PORTAL MTT (image_927465.png)
  Widget _buildTabCatalogoCascada() {
    return StatefulBuilder(
      builder: (context, setStateTab) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_outlined, color: Colors.blue, size: 18),
                SizedBox(width: 6),
                Text("Búsqueda Homologada Homologación MTT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 20),

            // Dropdown 1: Selección de Marca (image_927407.png)
            DropdownButtonFormField<String>(
              value: _marcaSeleccionada,
              isExpanded: true,
              decoration: _inputDecoration(label: "1. Selecciona la Marca", icon: Icons.branding_watermark_rounded),
              items: _marcasCatalogo.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) async {
                await _onMarcaChanged(val);
                setStateTab(() {}); 
              },
            ),
            const SizedBox(height: 16),

            // Dropdown 2: Selección de Modelo (Filtra de acuerdo a la Marca) (image_9273d0.png)
            DropdownButtonFormField<String>(
              value: _modeloSeleccionadoTxt,
              isExpanded: true,
              disabledHint: const Text("Elige una marca primero"),
              decoration: _inputDecoration(label: "2. Selecciona el Modelo", icon: Icons.model_training_rounded),
              items: _modelosFiltrados.map((mod) => DropdownMenuItem(value: mod, child: Text(mod))).toList(),
              onChanged: _marcaSeleccionada == null ? null : (val) async {
                await _onModeloChanged(val);
                setStateTab(() {});
              },
            ),
            const SizedBox(height: 16),

            // Dropdown 3: Motorización / Propulsión final (image_9273ad.png)
            DropdownButtonFormField<ModeloVehiculo>(
              value: _versionFinalSeleccionada,
              isExpanded: true,
              disabledHint: const Text("Elige marca y modelo primero"),
              decoration: _inputDecoration(label: "3. Versión / Propulsión", icon: Icons.local_gas_station_rounded),
              items: _versionesDisponibles.map((ver) => DropdownMenuItem(value: ver, child: Text("${ver.nombre} (${ver.rendimientoOficial} Km/L)", overflow: TextOverflow.ellipsis))).toList(),
              onChanged: _modeloSeleccionadoTxt == null ? null : (val) {
                setStateTab(() => _versionFinalSeleccionada = val);
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _versionFinalSeleccionada != null ? _greenCorporate : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: _versionFinalSeleccionada == null ? null : () {
                setState(() {
                  _marcaCtrl.text = _versionFinalSeleccionada!.marca;
                  _modeloCtrl.text = _versionFinalSeleccionada!.modelo;
                  _rendimientoCtrl.text = _versionFinalSeleccionada!.rendimientoOficial.toString();
                });
                DefaultTabController.of(context).animateTo(1);
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text("CONFIRMAR SELECCIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Vista 2: Formulario de Confirmación / Ingreso Manual
  Widget _buildTabManualForm() {
    return StatefulBuilder(
      builder: (context, setStateForm) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_versionFinalSeleccionada != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFDBFE))),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text("Cargado desde el Catálogo Oficial: ${_versionFinalSeleccionada!.nombre}", style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w600, fontSize: 13))),
                      ],
                    ),
                  ),
                TextFormField(controller: _aliasCtrl, decoration: _inputDecoration(label: 'Apodo del Auto (Ej: Mi Joyita)', icon: Icons.badge_rounded)),
                const SizedBox(height: 12),
                TextFormField(controller: _marcaCtrl, decoration: _inputDecoration(label: 'Marca', icon: Icons.text_fields_rounded)),
                const SizedBox(height: 12),
                TextFormField(controller: _modeloCtrl, decoration: _inputDecoration(label: 'Modelo', icon: Icons.text_fields_rounded)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _anioCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration(label: 'Año', icon: Icons.calendar_today_rounded))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _rendimientoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration(label: 'Rendimiento Km/L', icon: Icons.speed_rounded))),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _combustibleSeleccionado,
                  decoration: _inputDecoration(label: "Tipo Combustible", icon: Icons.local_gas_station_rounded),
                  items: ['93', '95', '97', 'Diésel', 'Kerosene'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setStateForm(() => _combustibleSeleccionado = val!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("Establecer como Vehículo Principal", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: _greenCorporate,
                  value: _esPrincipal,
                  onChanged: (val) => setStateForm(() => _esPrincipal = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _greenCorporate, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (_marcaCtrl.text.isEmpty || _modeloCtrl.text.isEmpty || _rendimientoCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor rellena los campos mandatorios")));
                      return;
                    }
                    
                    int fuelId = 1;
                    if (_combustibleSeleccionado == '95') fuelId = 2;
                    if (_combustibleSeleccionado == '97') fuelId = 3;
                    if (_combustibleSeleccionado == 'Diésel') fuelId = 4;
                    if (_combustibleSeleccionado == 'Kerosene') fuelId = 5;

                    await VehiculosService.crearVehiculo(
                    modeloId: _versionFinalSeleccionada?.id,
                    // 🚀 AGREGA ESTA LÍNEA AQUÍ PARA ENLAZAR TU CONTROLADOR DE ALIAS:
                    alias: _aliasCtrl.text.trim().isEmpty ? null : _aliasCtrl.text.trim(),
                    marca: _marcaCtrl.text,
                    modelo: _modeloCtrl.text,
                    anio: int.tryParse(_anioCtrl.text) ?? 2026, 
                    rendimiento: double.tryParse(_rendimientoCtrl.text) ?? 10.0,
                    tipoCombustibleId: fuelId,
                  );

                  Navigator.pop(context);
                  _refresh();
                  },
                  child: const Text("GUARDAR EN GARAGE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      floatingLabelStyle: TextStyle(color: _greenCorporate),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _greenCorporate, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}