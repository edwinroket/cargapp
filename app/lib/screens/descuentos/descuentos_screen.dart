import 'package:flutter/material.dart';
import '../../config/api.dart';
import '../../services/api_service.dart';

class DescuentosScreen extends StatefulWidget {
  const DescuentosScreen({super.key});

  @override
  State<DescuentosScreen> createState() => _DescuentosScreenState();
}

class _DescuentosScreenState extends State<DescuentosScreen> {
  static const List<String> dias = [
    'Todos los días',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const List<String> origenes = [
    'Todas',
    'Copec',
    'Aramco',
    'Shell',
  ];

  static const List<String> tipos = [
    'Todos',
    'Tarjetas Bancarias',
    'Tarjetas Retail',
    'RUT / Municipal',
    'App transporte',
    'App / Digital',
    'Cajas de Compensación',
    'Otro',
  ];

  String _selectedDia = dias[0];
  String _selectedOrigen = origenes[0];
  String _selectedTipo = tipos[0];
  late Future<List<dynamic>> _futureDescuentos;

  @override
  void initState() {
    super.initState();
    _futureDescuentos = _fetchDescuentos();
  }

  Future<List<dynamic>> _fetchDescuentos() async {
    final queryParameters = <String, String>{};

    if (_selectedDia != dias[0]) {
      queryParameters['dia'] = _selectedDia;
    }
    if (_selectedOrigen != origenes[0]) {
      queryParameters['origen'] = _selectedOrigen;
    }
    if (_selectedTipo != tipos[0]) {
      queryParameters['tipo'] = _selectedTipo;
    }

    final uri = Uri.parse(ApiConfig.descuentos).replace(queryParameters: queryParameters);
    final data = await ApiService.get(uri.toString());
    if (data is List) return data;
    return [];
  }

  void _applyFilter({String? dia, String? origen, String? tipo}) {
    setState(() {
      if (dia != null) _selectedDia = dia;
      if (origen != null) _selectedOrigen = origen;
      if (tipo != null) _selectedTipo = tipo;
      _futureDescuentos = _fetchDescuentos();
    });
  }

  Widget _buildChoiceChips(List<String> options, String selectedValue, void Function(String) onSelected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return ChoiceChip(
          label: Text(option),
          selected: selectedValue == option,
          onSelected: (_) => onSelected(option),
          selectedColor: const Color(0xFF164e13),
          backgroundColor: const Color(0xFF0f172a),
          labelStyle: TextStyle(
            color: selectedValue == option ? Colors.white : Colors.white70,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Descuentos en Bencina'),
        backgroundColor: const Color(0xFF16a34a),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureDescuentos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar descuentos'));
          }

          final lista = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildFilterSection(
                'Día de Descuento',
                _buildChoiceChips(dias, _selectedDia, (value) => _applyFilter(dia: value)),
              ),
              _buildFilterSection(
                'Bencinera',
                _buildChoiceChips(origenes, _selectedOrigen, (value) => _applyFilter(origen: value)),
              ),
              _buildFilterSection(
                'Tipo de Descuento',
                _buildChoiceChips(tipos, _selectedTipo, (value) => _applyFilter(tipo: value)),
              ),
              const SizedBox(height: 4),
              Text(
                '${lista.length} resultados',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              ...lista.map((d) {
                final descuento = d['descuento_num']?.toString() ?? d['descuento_texto']?.toString() ?? '';
                final origen = d['origen'] ?? 'Descuento';
                final tipo = d['tipo'] ?? 'General';
                final condicion = d['condicion'] ?? '';
                final notas = d['notas'] ?? '';
                final fuente = d['fuente_url'] ?? '';
                final vigencia = d['vigencia_hasta'] ?? '';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(origen.toString().toUpperCase()),
                              backgroundColor: const Color(0xFF0f172a),
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(tipo.toString()),
                              backgroundColor: const Color(0xFF111827),
                              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                d['convenio'] ?? 'Convenio desconocido',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              descuento.isNotEmpty ? 'Hasta \$${descuento}/lt' : '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22c55e),
                              ),
                            ),
                          ],
                        ),
                        if (condicion.isNotEmpty || notas.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          if (condicion.isNotEmpty)
                            Text(
                              condicion,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          if (notas.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                notas,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Vigencia hasta: $vigencia',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        if (fuente.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              fuente,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}