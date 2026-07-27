import 'package:bosque_flutter/core/utils/bancos_export_service.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanillasExportBancoDialog extends ConsumerStatefulWidget {
  final int mes;
  final int anio;
  final String nombreMes;

  const PlanillasExportBancoDialog({
    super.key,
    required this.mes,
    required this.anio,
    required this.nombreMes,
  });

  @override
  ConsumerState<PlanillasExportBancoDialog> createState() =>
      _PlanillasExportBancoDialogState();
}

class _PlanillasExportBancoDialogState
    extends ConsumerState<PlanillasExportBancoDialog> {
  final BancosExportService _exportService = BancosExportService();

  int _codBancoSeleccionado = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _datosActuales = [];
  double _totalActual = 0;
  String _nombreBancoActual = 'Todos los Bancos (Global)';

  @override
  void initState() {
    super.initState();
    _fetchDatosBanco();
  }

  Future<void> _fetchDatosBanco() async {
    setState(() {
      _isLoading = true;
      _datosActuales = [];
      _totalActual = 0;
    });
    try {
      final datos = await _exportService.obtenerDatosBanco(
        mes: widget.mes,
        anio: widget.anio,
        codBanco: _codBancoSeleccionado,
      );

      double sum = 0;
      if (datos.isNotEmpty && datos.first['_totalLiquido'] != null) {
        sum = double.tryParse(datos.first['_totalLiquido'].toString()) ?? 0;
      }

      if (mounted) {
        setState(() {
          _datosActuales = datos;
          _totalActual = sum;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _getBancoMeta(int codBanco, String nombreBanco) {
    if (codBanco == 0) {
      return {
        'id': 0,
        'nombre': 'Todos los Bancos (Global)',
        'formato': 'EXCEL',
        'icon': Icons.table_chart,
      };
    }
    if (codBanco == 3) {
      return {
        'id': 3,
        'nombre': nombreBanco,
        'formato': 'TXT',
        'icon': Icons.description,
      };
    }
    if (codBanco == 9) {
      return {
        'id': 9,
        'nombre': nombreBanco,
        'formato': 'EXCEL',
        'icon': Icons.table_chart_rounded,
      };
    }
    return {
      'id': codBanco,
      'nombre': nombreBanco,
      'formato': 'EXCEL',
      'icon': Icons.table_chart,
    };
  }

  Future<void> _exportar() async {
    if (_datosActuales.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos bancarios para este periodo y banco.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _exportService.exportar(
        codBanco: _codBancoSeleccionado,
        datos: _datosActuales,
        mes: widget.nombreMes,
        anio: widget.anio.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Archivo "$_nombreBancoActual" generado correctamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final banco = _getBancoMeta(_codBancoSeleccionado, _nombreBancoActual);
    final bancosAsync = ref.watch(obtenerBancosPlanilla);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.account_balance, color: cs.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Exportar Archivos')),
        ],
      ),
      content: SizedBox(
        width: ResponsiveUtilsBosque.isMobile(context) ? double.maxFinite : 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Periodo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Periodo: ${widget.nombreMes} ${widget.anio}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Selector de banco
            bancosAsync.when(
              data: (bancos) {
                final allOptions = [
                  BancoEntity(
                    codBanco: 0,
                    nombre: 'Todos los Bancos (Global)',
                    audUsuario: 0,
                    fila: 0,
                  ),
                  ...bancos,
                ];

                // Asegurar que el valor seleccionado existe en la lista
                if (!allOptions.any(
                  (b) => b.codBanco == _codBancoSeleccionado,
                )) {
                  _codBancoSeleccionado = 0;
                  _nombreBancoActual = 'Todos los Bancos (Global)';
                }

                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Banco',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  isExpanded: true,
                  value: _codBancoSeleccionado,
                  items:
                      allOptions.map((b) {
                        return DropdownMenuItem<int>(
                          value: b.codBanco,
                          child: Text(b.nombre),
                        );
                      }).toList(),
                  onChanged:
                      _isLoading
                          ? null
                          : (val) {
                            if (val != null && val != _codBancoSeleccionado) {
                              final nombre =
                                  allOptions
                                      .firstWhere((b) => b.codBanco == val)
                                      .nombre;
                              setState(() {
                                _codBancoSeleccionado = val;
                                _nombreBancoActual = nombre;
                              });
                              _fetchDatosBanco();
                            }
                          },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (err, stack) => Text(
                    'Error al cargar bancos: $err',
                    style: TextStyle(color: cs.error),
                  ),
            ),
            const SizedBox(height: 16),

            // Chip informativo del formato (automático, no editable)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(_codBancoSeleccionado),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.secondaryContainer, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      banco['icon'] as IconData,
                      color: cs.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Formato de salida',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.secondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            banco['formato'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL LÍQUIDO',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _isLoading
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                            : Text(
                              '${_totalActual.toStringAsFixed(2)} Bs.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: cs.primary,
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon:
              _isLoading
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                  : const Icon(Icons.download),
          label: Text(_isLoading ? 'Generando...' : 'Descargar'),
          onPressed: _isLoading ? null : _exportar,
        ),
      ],
    );
  }
}
