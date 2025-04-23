import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_provider.dart';

class ControlCombustibleViewScreen extends ConsumerStatefulWidget {
  const ControlCombustibleViewScreen({super.key});

  @override
  ConsumerState<ControlCombustibleViewScreen> createState() => _ControlCombustibleViewScreenState();
}

class _ControlCombustibleViewScreenState extends ConsumerState<ControlCombustibleViewScreen> {
  int? _selectedCocheId;
  List<Map<String, dynamic>> _coches = [];
  bool _loadingCoches = true;

  @override
  void initState() {
    super.initState();
    _fetchCoches();
  }

  Future<void> _fetchCoches() async {
    setState(() => _loadingCoches = true);
    try {
      final repo = ref.read(controlCombustibleRepositoryProvider);
      final coches = await repo.getCoches();
      final ids = <int>{};
      final cochesList = coches
          .where((e) => ids.add(e.idCoche))
          .map((e) => {'id': e.idCoche, 'label': e.coche})
          .toList();
      setState(() {
        _coches = cochesList;
        _selectedCocheId = _coches.isNotEmpty ? _coches.first['id'] : null;
        _loadingCoches = false;
      });
    } catch (_) {
      setState(() => _loadingCoches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Combustible')),
      body: Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          elevation: 4,
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccione un vehículo:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _loadingCoches
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'Seleccione un vehículo',
                          filled: true,
                          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).scaffoldBackgroundColor,
                        ),
                        value: _selectedCocheId,
                        items: _coches
                            .map((c) => DropdownMenuItem<int>(
                                  value: c['id'],
                                  child: Text(c['label'] ?? ''),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCocheId = v),
                      ),
                if (_selectedCocheId == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(width: 16),
                        Text(
                          'Seleccione un vehículo para ver sus detalles',
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (_selectedCocheId != null)
                  Consumer(
                    builder: (context, ref, _) {
                      final asyncCombustibles = ref.watch(combustiblesPorCocheProvider(_selectedCocheId!));
                      final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
                      final isMobile = ResponsiveUtilsBosque.isMobile(context);
                      final colorScheme = Theme.of(context).colorScheme;
                      return asyncCombustibles.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => const SizedBox.shrink(),
                        data: (combustibles) {
                          if (combustibles.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('No hay registros de combustible para este vehículo.',
                                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                              ),
                            );
                          }
                          if (isMobile) {
                            // Tarjetas apiladas para móvil
                            return Column(
                              children: combustibles.asMap().entries.map((entry) {
                                final index = entry.key;
                                final c = entry.value;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 2,
                                  color: Theme.of(context).cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '#${index + 1}  ${c.coche}',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                            ),
                                            Text(
                                              c.fecha != null
                                                ? "${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year}"
                                                : '',
                                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.local_gas_station, size: 18, color: colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text('${c.litros.toStringAsFixed(2)} L', style: TextStyle(color: colorScheme.onSurface)),
                                            const SizedBox(width: 16),
                                            Icon(Icons.speed, size: 18, color: colorScheme.secondary),
                                            const SizedBox(width: 4),
                                            Text('${c.kilometraje.toStringAsFixed(0)} km', style: TextStyle(color: colorScheme.onSurface)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.attach_money, size: 18, color: colorScheme.tertiary),
                                            const SizedBox(width: 4),
                                            Text(c.importe.toStringAsFixed(2), style: TextStyle(color: colorScheme.onSurface)),
                                            const SizedBox(width: 16),
                                            Chip(
                                              label: Text(c.tipoCombustible, style: TextStyle(color: colorScheme.primary)),
                                              backgroundColor: colorScheme.primary.withOpacity(0.08),
                                            ),
                                          ],
                                        ),
                                        if ((c.obs ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text('Obs: ${c.obs}', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                                        ]
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }
                          // Tabla mejorada para desktop/tablet, ocupa todo el ancho
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                width: constraints.maxWidth,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      columnSpacing: 32,
                                      headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                                        (states) => colorScheme.primaryContainer,
                                      ),
                                      border: TableBorder.symmetric(inside: BorderSide(color: colorScheme.outline)),
                                      columns: const [
                                        DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Importe', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Kilometraje', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Litros', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Obs.', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: List.generate(combustibles.length, (index) {
                                        final c = combustibles[index];
                                        return DataRow(
                                          color: MaterialStateProperty.resolveWith<Color?>(
                                            (states) => index % 2 == 0
                                              ? colorScheme.surfaceVariant
                                              : colorScheme.surface,
                                          ),
                                          cells: [
                                            DataCell(Text((index + 1).toString(), style: TextStyle(color: colorScheme.onSurface))),
                                            DataCell(Text(
                                              c.fecha != null
                                                ? "${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year}"
                                                : '',
                                              style: TextStyle(color: colorScheme.onSurface),
                                            )),
                                            DataCell(Text(c.importe.toStringAsFixed(2), style: TextStyle(color: colorScheme.onSurface))),
                                            DataCell(Text(c.kilometraje.toStringAsFixed(0), style: TextStyle(color: colorScheme.onSurface))),
                                            DataCell(Text(c.litros.toStringAsFixed(2), style: TextStyle(color: colorScheme.onSurface))),
                                            DataCell(Text(c.tipoCombustible, style: TextStyle(color: colorScheme.primary))),
                                            DataCell(Text(c.obs ?? '', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)))),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      
    );
  }
}