import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api.dart';
import '../../services/api_service.dart';

class DescuentosScreen extends StatefulWidget {
  const DescuentosScreen({super.key});

  @override
  State<DescuentosScreen> createState() => _DescuentosScreenState();
}

class _DescuentosScreenState extends State<DescuentosScreen> {
  double _montoCarga = 50000;
  String _bencina = '95';
  String _dia = 'Semana';
  String _origen = 'Todas';
  String _tipoSeleccionado = 'Todos';

  final List<String> _tiposFiltro = [
    'Todos', 'Tarjetas Bancarias', 'App / Digital', 'Tarjetas Retail', 
    'RUT / Municipal', 'Cajas de Compensación', 'Otro'
  ];

  final List<String> _bencineras = ['Todas', 'Copec', 'Shell', 'Aramco'];

  final List<String> _todosConvenios = [
    'Banco BCI', 'Lider BCI', 'MACH', 'Scotiabank', 'Cencosud Scotiabank', 
    'Coopeuch', 'Jumbo Prime', 'Santander', 'Banco Internacional', 'Tenpo', 
    'SBPay', 'Spin', 'Mercado Pago', 'Banco Consorcio', 'Banco Ripley', 
    'ABC', 'Banco BICE', 'Banco Security', 'Banco de Chile', 'Automóvil Club',
  ];
  
  late Set<String> _conveniosSeleccionados;
  late Future<List<dynamic>> _futureDescuentos;

  @override
  void initState() {
    super.initState();
    _conveniosSeleccionados = Set.from(_todosConvenios);
    _futureDescuentos = _fetchDescuentos();
  }

  Future<List<dynamic>> _fetchDescuentos() async {
    final data = await ApiService.get(ApiConfig.descuentos);
    if (data is List) return data;
    return [];
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  List<dynamic> _filtrar(List<dynamic> lista) {
    return lista.where((d) {
      // FILTRO: Ocultar si el descuento es 0 o nulo
      final double descNum = double.tryParse(d['descuento_num']?.toString() ?? '0') ?? 0;
      if (descNum <= 0) return false;

      final convenio = (d['convenio'] ?? '').toString();
      final origen = (d['origen'] ?? '').toString();
      final dia = (d['dia'] ?? '').toString().toLowerCase();
      final tipo = (d['tipo'] ?? '').toString();

      final matchConvenio = _conveniosSeleccionados.any(
          (c) => convenio.toLowerCase().contains(c.toLowerCase()));
      final matchOrigen = _origen == 'Todas' || origen.toLowerCase() == _origen.toLowerCase();
      final matchDia = _dia == 'Semana' || dia.contains(_dia.toLowerCase()) || dia.contains('todos');
      final matchTipo = _tipoSeleccionado == 'Todos' || tipo == _tipoSeleccionado;

      return matchConvenio && matchOrigen && matchDia && matchTipo;
    }).toList();
  }

  double _calcularAhorro(dynamic d) {
    const precioReferencia = 1350.0; 
    final litros = _montoCarga / precioReferencia;
    final descNum = double.tryParse(d['descuento_num']?.toString() ?? '') ?? 0;
    return descNum * litros;
  }

  void _mostrarDetalle(BuildContext context, dynamic d) {
    final ahorro = _calcularAhorro(d);
    final descLitro = d['descuento_num']?.toString() ?? '0';
    final origen = (d['origen'] ?? '').toString().toUpperCase();
    final convenio = d['convenio'] ?? 'Convenio';
    final tope = d['tope_mensual'] ?? '';
    final condicion = d['condicion'] ?? '';
    final notas = d['notas'] ?? '';
    final vigencia = d['vigencia_hasta'] ?? '';
    final url = d['fuente_url'] ?? '';
    final dia = d['dia'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildMarcaBadge(origen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text("$origen: $convenio", 
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AHORRO ESTIMADO', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('\$${ahorro.toInt()}', 
                          style: const TextStyle(color: Color(0xFF22c55e), fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('POR LITRO', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('\$$descLitro', 
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              _buildSectionTitle('📅 DÍA DE APLICACIÓN'),
              _buildSectionContent(dia),
              
              if (tope.isNotEmpty) ...[
                _buildSectionTitle('🛑 TOPE MÁXIMO'),
                _buildSectionContent(tope),
              ],

              _buildSectionTitle('📜 CONDICIONES (TEXTO OFICIAL)'),
              _buildSectionContent(condicion),

              if (notas.isNotEmpty) ...[
                _buildSectionTitle('💡 NOTAS ADICIONALES'),
                _buildSectionContent(notas),
              ],

              if (vigencia.isNotEmpty) ...[
                _buildSectionTitle('⌛ VIGENCIA'),
                _buildSectionContent(vigencia),
              ],
              
              const SizedBox(height: 20),

              if (url.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(url),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('VER FUENTE OFICIAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: const Text('Descuentos en Bencina',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0f172a),
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureDescuentos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF22c55e)));
          }

          final lista = snapshot.data ?? [];
          final filtrada = _filtrar(lista);
          filtrada.sort((a, b) => _calcularAhorro(b).compareTo(_calcularAhorro(a)));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildConfigPanel(),
              const SizedBox(height: 20),
              ...filtrada.map((d) => _buildDescuentoCard(d)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescuentoCard(dynamic d) {
    final ahorroTotal = _calcularAhorro(d);
    final descPorLitro = d['descuento_num']?.toString() ?? '0';
    final origen = (d['origen'] ?? '').toString().toUpperCase();
    final convenio = d['convenio'] ?? 'Convenio';
    final dia = d['dia'] ?? '';

    return GestureDetector(
      onTap: () => _mostrarDetalle(context, d),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildMarcaBadge(origen),
                      const SizedBox(width: 8),
                      Text(origen, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(dia, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hasta \$$descPorLitro/lt',
                          style: const TextStyle(color: Color(0xFF22c55e), fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(convenio, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF0f172a), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('AHORRO TOTAL', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                        Text('\$${ahorroTotal.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const Divider(color: Color(0xFF334155), height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(d['tipo'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('¿CUÁNTO CARGAS?', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text('\$ ${_montoCarga.toInt()}', style: const TextStyle(color: Color(0xFF22c55e), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Slider(
            value: _montoCarga,
            min: 5000,
            max: 100000,
            divisions: 19,
            activeColor: const Color(0xFF22c55e),
            onChanged: (value) => setState(() => _montoCarga = value),
          ),
          const Text('BENCINERA', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _bencineras.map((o) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(o, style: const TextStyle(fontSize: 12)),
                  selected: _origen == o,
                  onSelected: (val) => setState(() => _origen = o),
                  selectedColor: const Color(0xFF16a34a),
                  backgroundColor: const Color(0xFF0f172a),
                  labelStyle: TextStyle(color: _origen == o ? Colors.white : Colors.white70),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _dropdownDark(value: _bencina, items: ['93', '95', '97', 'Diésel'], onChanged: (v) => setState(() => _bencina = v!))),
            const SizedBox(width: 10),
            Expanded(child: _dropdownDark(value: _dia, items: ['Semana', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'], onChanged: (v) => setState(() => _dia = v!))),
          ]),
        ],
      ),
    );
  }

  Widget _buildMarcaBadge(String origen) {
    Color color = Colors.grey;
    if (origen.contains('COPEC')) color = Colors.blue;
    if (origen.contains('SHELL')) color = Colors.red;
    if (origen.contains('ARAMCO')) color = Colors.green;
    return Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _dropdownDark({required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF0f172a), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF334155))),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(), onChanged: onChanged, dropdownColor: const Color(0xFF1e293b), isExpanded: true)),
    );
  }
}