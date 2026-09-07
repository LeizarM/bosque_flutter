// Destino final: lib/presentation/screens/tareas-rutinarias/caja_chica_screen.dart
import 'dart:async';

import 'package:bosque_flutter/core/state/caja_chica_flujo_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/data/repositories/caja_chica_flujo_impl.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza dlgCajaChica del legacy. A diferencia de ese diálogo (que
/// borraba la fila en silencio si el saldo corrido quedaba negativo), acá
/// el backend rechaza el egreso ANTES de guardar nada y explica por qué —
/// ver p_cajaChica_registrarEgreso.
class CajaChicaScreen extends ConsumerWidget {
  final int idBitTarea;
  final String nombreTarea;

  const CajaChicaScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  Future<void> _abrirFormularioEgreso(
    BuildContext context,
    WidgetRef ref,
    CajaChicaParams params,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormularioEgreso(params: params),
    );
  }

  /// "Ver Cajas Chicas" del legacy — histórico de lotes de esta sucursal.
  void _abrirHistorialLotes(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _HistorialLotesDialog(idBitTarea: idBitTarea),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (idBitTarea: idBitTarea);
    final state = ref.watch(cajaChicaFlujoProvider(params));
    final notifier = ref.read(cajaChicaFlujoProvider(params).notifier);
    final scheme = Theme.of(context).colorScheme;
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= 700;

    ref.listen(cajaChicaFlujoProvider(params), (previo, actual) {
      if (actual.finalizado && previo?.finalizado != true) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, 'Caja chica finalizada — tarea completada.');
        Navigator.of(context).pop(true);
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreTarea, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver cajas chicas anteriores',
            onPressed: () => _abrirHistorialLotes(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Saldo actual: ${state.saldoActual.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(
                      context,
                    ).appBarTheme.foregroundColor?.withValues(alpha: 0.85) ??
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.cargar,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child:
              state.cargando && state.items.isEmpty
                  ? const Center(
                    key: ValueKey('cargando'),
                    child: CircularProgressIndicator(),
                  )
                  : state.items.isEmpty
                  ? Center(
                    key: const ValueKey('vacio'),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 56,
                            color: scheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Todavía no hay movimientos en este lote.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                  : Align(
                    key: const ValueKey('lista'),
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: esAncho ? 640 : double.infinity,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.items.length,
                        itemBuilder:
                            (context, i) => _FilaAnimada(
                              key: ValueKey(state.items[i].idCC),
                              child: _FilaCajaChica(item: state.items[i]),
                            ),
                      ),
                    ),
                  ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'agregarEgreso',
            onPressed: () => _abrirFormularioEgreso(context, ref, params),
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Registrar egreso'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'finalizar',
            backgroundColor: scheme.tertiary,
            onPressed: state.finalizando ? null : notifier.finalizar,
            icon:
                state.finalizando
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onTertiary,
                      ),
                    )
                    : const Icon(Icons.check),
            label: Text(state.finalizando ? 'Finalizando…' : 'Finalizar'),
          ),
        ],
      ),
    );
  }
}

/// Entrada suave para una fila que recién aparece en el listado (nuevo
/// egreso registrado) — cero costo si ya estaba en pantalla.
class _FilaAnimada extends StatelessWidget {
  final Widget child;

  const _FilaAnimada({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder:
          (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: child,
            ),
          ),
      child: child,
    );
  }
}

class _FilaCajaChica extends StatelessWidget {
  final CajaChicaEntity item;

  const _FilaCajaChica({required this.item});

  @override
  Widget build(BuildContext context) {
    final esIngreso = (item.montoIng ?? 0) > 0;
    final scheme = Theme.of(context).colorScheme;
    final fondoTint = (esIngreso
            ? TareasColors.realizado(context)
            : TareasColors.vencido(context))
        .withValues(alpha: 0.35);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: fondoTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(
          esIngreso ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color:
              esIngreso
                  ? TareasColors.realizadoTexto(context)
                  : TareasColors.vencidoTexto(context),
        ),
        title: Text(
          item.descripcion ?? (esIngreso ? 'Saldo inicial' : 'Egreso'),
        ),
        subtitle: Text(
          'Saldo tras el movimiento: ${(item.saldo ?? 0).toStringAsFixed(2)}',
        ),
        trailing: Text(
          esIngreso
              ? '+${item.montoIng!.toStringAsFixed(2)}'
              : '-${(item.montoEg ?? 0).toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color:
                esIngreso
                    ? TareasColors.realizadoTexto(context)
                    : TareasColors.vencidoTexto(context),
          ),
        ),
      ),
    );
  }
}

class _FormularioEgreso extends ConsumerStatefulWidget {
  final CajaChicaParams params;

  const _FormularioEgreso({required this.params});

  @override
  ConsumerState<_FormularioEgreso> createState() => _FormularioEgresoState();
}

class _FormularioEgresoState extends ConsumerState<_FormularioEgreso> {
  final _formKey = GlobalKey<FormState>();
  double? _monto;
  final _descripcionCtrl = TextEditingController();
  int? _codEmpDestino;
  int? _numFactura;
  int? _numVale;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cajaChicaFlujoProvider(widget.params));
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registrar egreso',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Saldo disponible: ${state.saldoActual.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) => _monto = double.tryParse(v),
                validator:
                    (v) =>
                        (double.tryParse(v ?? '') ?? 0) > 0
                            ? null
                            : 'Ingresa un monto válido.',
              ),
              const SizedBox(height: 4),
              // El legacy avisa esto mismo junto al formulario — el backend
              // ya rechaza montoEg<=0 (p_abm_tac_CajaChica ACCION='R'), acá
              // solo se hace visible la regla ANTES de que la persona
              // intente guardar.
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Los montos iguales o menores a cero no se guardan.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Describe el gasto.'
                            : null,
              ),
              const SizedBox(height: 12),
              _EmpleadoDestinoField(
                onSeleccionado:
                    (codEmpleado) =>
                        setState(() => _codEmpDestino = codEmpleado),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'N° factura (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _numFactura = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'N° vale (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _numVale = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      state.guardando
                          ? null
                          : () async {
                            if (!_formKey.currentState!.validate()) {
                              HapticFeedback.lightImpact();
                              return;
                            }
                            if (_codEmpDestino == null) {
                              HapticFeedback.lightImpact();
                              mostrarAviso(
                                context,
                                'Indica a quién se entregó el dinero.',
                                tono: TonoAviso.aviso,
                              );
                              return;
                            }
                            final ok = await ref
                                .read(
                                  cajaChicaFlujoProvider(
                                    widget.params,
                                  ).notifier,
                                )
                                .registrarEgreso(
                                  montoEg: _monto!,
                                  descripcion: _descripcionCtrl.text.trim(),
                                  codEmpDestino: _codEmpDestino!,
                                  numFactura: _numFactura,
                                  numVale: _numVale,
                                );
                            if (ok && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                  child:
                      state.guardando
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                          : const Text('Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picker "Empleado Destino" — el legacy usa un `<p:selectOneMenu
/// filter="true">` con nombre+cargo, no un id numérico tipeado a mano.
/// Búsqueda remota con debounce (no dispara en cada tecla), resultados en
/// una lista corta debajo del campo, y una vez elegido muestra el nombre
/// en vez del número — la persona nunca ve ni escribe un código crudo.
class _EmpleadoDestinoField extends StatefulWidget {
  final ValueChanged<int?> onSeleccionado;

  const _EmpleadoDestinoField({required this.onSeleccionado});

  @override
  State<_EmpleadoDestinoField> createState() => _EmpleadoDestinoFieldState();
}

class _EmpleadoDestinoFieldState extends State<_EmpleadoDestinoField> {
  final _ctrl = TextEditingController();
  final _repo = CajaChicaFlujoImpl();
  Timer? _debounce;
  bool _buscando = false;
  List<Map<String, dynamic>> _resultados = [];
  String? _labelSeleccionado;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  String _label(Map<String, dynamic> emp) {
    final persona = emp['persona'] as Map<String, dynamic>?;
    final cargo = emp['cargo'] as Map<String, dynamic>?;
    final nombre = [
      persona?['nombres'],
      persona?['apPaterno'],
    ].where((p) => p != null && (p as String).isNotEmpty).join(' ');
    final cargoDesc = cargo?['descripcion'] as String?;
    if (nombre.isEmpty) return 'Empleado ${emp['codEmpleado']}';
    return cargoDesc != null && cargoDesc.isNotEmpty
        ? '$nombre - $cargoDesc'
        : nombre;
  }

  void _buscar(String texto) {
    _debounce?.cancel();
    if (texto.trim().length < 2) {
      setState(() => _resultados = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _buscando = true);
      try {
        final resultados = await _repo.buscarEmpleados(texto.trim());
        if (mounted) {
          setState(() {
            _resultados = resultados;
            _buscando = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _resultados = [];
            _buscando = false;
          });
        }
      }
    });
  }

  void _elegir(Map<String, dynamic> emp) {
    final codEmpleado = (emp['codEmpleado'] as num?)?.toInt();
    setState(() {
      _labelSeleccionado = _label(emp);
      _resultados = [];
      _ctrl.clear();
    });
    HapticFeedback.selectionClick();
    widget.onSeleccionado(codEmpleado);
  }

  @override
  Widget build(BuildContext context) {
    if (_labelSeleccionado != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'Entregado a',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cambiar',
            onPressed: () {
              setState(() => _labelSeleccionado = null);
              widget.onSeleccionado(null);
            },
          ),
        ),
        child: Text(_labelSeleccionado!, overflow: TextOverflow.ellipsis),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            labelText: 'Entregado a — buscar por nombre',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                _buscando
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : null,
          ),
          onChanged: _buscar,
        ),
        if (_resultados.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _resultados.length,
              itemBuilder: (context, i) {
                final emp = _resultados[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    _label(emp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => _elegir(emp),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// "Ver Cajas Chicas" del legacy — histórico de lotes de esta sucursal.
class _HistorialLotesDialog extends StatefulWidget {
  final int idBitTarea;

  const _HistorialLotesDialog({required this.idBitTarea});

  @override
  State<_HistorialLotesDialog> createState() => _HistorialLotesDialogState();
}

class _HistorialLotesDialogState extends State<_HistorialLotesDialog> {
  final _repo = CajaChicaFlujoImpl();
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _lotes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lotes = await _repo.obtenerHistorialLotes(widget.idBitTarea);
      if (mounted) {
        setState(() {
          _lotes = lotes;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  String _fmt(dynamic raw) {
    final d = raw is String ? DateTime.tryParse(raw) : null;
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final altoDisponible = MediaQuery.sizeOf(context).height;
    return AlertDialog(
      title: const Text('Cajas chicas anteriores'),
      content: SizedBox(
        width: (anchoDisponible - 80).clamp(240, 420),
        height: (altoDisponible * 0.5).clamp(220, 420),
        child:
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('No se pudo cargar: $_error'))
                : _lotes.isEmpty
                ? const Center(
                  child: Text('No hay lotes anteriores para esta sucursal.'),
                )
                : ListView.builder(
                  itemCount: _lotes.length,
                  itemBuilder: (context, i) {
                    final lote = _lotes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        title: Text('Lote ${lote['lote']}'),
                        subtitle: Text(
                          '${_fmt(lote['desde'])} – ${_fmt(lote['hasta'])} · ${lote['nombreSucursal'] ?? ''}',
                        ),
                        trailing: Text(
                          'Bs ${((lote['totalEgresos'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
