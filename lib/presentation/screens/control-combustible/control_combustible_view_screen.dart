import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
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

  Future<void> _showIdCMReportDialog(int idCM) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 500,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_gas_station,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detalles del Bidón',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final asyncBidonDetalle = ref.watch(listDetalleBidonProvider(idCM));
                      
                      return asyncBidonDetalle.when(
                        loading: () => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Cargando información del bidón...'),
                            ],
                          ),
                        ),
                        error: (error, stackTrace) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red[400],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '¡Ups! Algo salió mal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  constraints: const BoxConstraints(maxWidth: 280),
                                  child: Text(
                                    'No pudimos cargar la información del bidón en este momento. Por favor, inténtelo nuevamente.',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cierre y vuelva a abrir para reintentar',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (bidones) {
                          if (bidones.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.search_off_outlined,
                                        size: 48,
                                        color: Colors.orange[400],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Información no disponible',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 280),
                                      child: Text(
                                        'No se encontraron detalles para este bidón. Es posible que haya sido eliminado o que no tenga permisos para verlo.',
                                        style: TextStyle(
                                          color: Colors.orange[600],
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'ID del bidón: $idCM',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          final bidon = bidones.first;
                          
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue.shade700,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Información detallada del bidón utilizado para justificar bajo consumo',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                Text(
                                  'Datos del Bidón:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                _buildReportInfo('Código Destino', bidon.codigoDestino.isEmpty ? 'N/A' : bidon.codigoDestino),
                                _buildReportInfo('Fecha', _formatDate(bidon.fecha.toString())),
                                _buildReportInfo('Litros de Ingreso', '${bidon.litrosIngreso.toStringAsFixed(2)} L'),
                                _buildReportInfo('Máquina de Origen', bidon.nombreMaquinaOrigen.isEmpty ? 'N/A' : bidon.nombreMaquinaOrigen),
                                _buildReportInfo('Sucursal', bidon.nombreSucursal.isEmpty ? 'N/A' : bidon.nombreSucursal),
                                
                                if (bidon.obs.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildReportInfo('Observaciones', bidon.obs),
                                ],
                                
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Este bidón fue utilizado para justificar el bajo consumo de combustible en el registro asociado.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Cerrar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            )
          );
        },
      );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildReportInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Combustible')),
      body: SingleChildScrollView(
        child: Card(
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
                                            Expanded(
                                              child: Text(
                                                '#${index + 1}  ${c.coche}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                              ),
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
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.route, size: 18, color: colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text('Recorrido: ${c.diferencia.toStringAsFixed(2)} km', style: TextStyle(color: colorScheme.onSurface)),
                                          ],
                                        ),
                                        if ((c.obs ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Observaciones:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: colorScheme.onSurface.withOpacity(0.8),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  c.obs!,
                                                  style: TextStyle(
                                                    color: colorScheme.onSurface.withOpacity(0.7),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (c.idCM > 0) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showIdCMReportDialog(c.idCM),
                                              icon: const Icon(Icons.assessment, size: 16),
                                              label: Text('Ver Reporte Bidón'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: colorScheme.secondary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }
                          // Tabla mejorada para desktop/tablet
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
                                      columnSpacing: 24,
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
                                        DataColumn(label: Text('Recorrido', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                            DataCell(Text(c.diferencia.toStringAsFixed(2), style: TextStyle(color: colorScheme.onSurface))),
                                            DataCell(Text(c.tipoCombustible, style: TextStyle(color: colorScheme.primary))),
                                            DataCell(
                                              Container(
                                                constraints: const BoxConstraints(maxWidth: 150),
                                                child: Text(
                                                  c.obs ?? 'Sin observaciones',
                                                  style: TextStyle(
                                                    color: (c.obs ?? '').isEmpty 
                                                      ? colorScheme.onSurface.withOpacity(0.5)
                                                      : colorScheme.onSurface.withOpacity(0.7),
                                                    fontStyle: (c.obs ?? '').isEmpty ? FontStyle.italic : FontStyle.normal,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              c.idCM > 0
                                                ? ElevatedButton.icon(
                                                    onPressed: () => _showIdCMReportDialog(c.idCM),
                                                    icon: const Icon(Icons.assessment, size: 14),
                                                    label: Text('Bidón'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: colorScheme.secondary,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      textStyle: const TextStyle(fontSize: 12),
                                                    ),
                                                  )
                                                : Text(
                                                    'N/A',
                                                    style: TextStyle(
                                                      color: colorScheme.onSurface.withOpacity(0.5),
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                            ),
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
      ),
    );
  }
}