import 'dart:async';
import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_shared_sheet_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHARED MANUAL WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class TipoMontoRow extends StatelessWidget {
  final String tipo;
  final TextEditingController montoController;
  final void Function(String, double) onUpdate;
  const TipoMontoRow({
    super.key,
    required this.tipo,
    required this.montoController,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final brd = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          SizedBox(
            height: 28,
            width: 112,
            child: DropdownButtonFormField<String>(
              value: tipo,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                filled: true,
                fillColor: cs.surface,
                border: brd,
                enabledBorder: brd,
              ),
              style: TextStyle(fontSize: 11, color: cs.onSurface),
              items: const [
                DropdownMenuItem(value: 'A', child: Text('Automático')),
                DropdownMenuItem(value: 'F', child: Text('Fijo')),
              ],
              onChanged: (v) {
                if (v != null) onUpdate(v, double.tryParse(montoController.text) ?? 0);
              },
            ),
          ),
          if (tipo == 'F') ...[
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Monto Bs.',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
                    ),
                  ),
                  onChanged: (v) => onUpdate('F', double.tryParse(v) ?? 0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tile para empleados YA seleccionados — usa ícono de basurero en lugar de checkbox
class EmpleadoSeleccionadoTile extends StatelessWidget {
  final EmpleadoAsignacion asig;
  final TextEditingController montoController;
  final VoidCallback onDelete;
  final void Function(String, double) onUpdate;

  const EmpleadoSeleccionadoTile({
    super.key,
    required this.asig,
    required this.montoController,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Quitar de la selección',
            child: InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline_rounded, size: 20, color: cs.error),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asig.nombreCompleto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TipoMontoRow(tipo: asig.tipo, montoController: montoController, onUpdate: onUpdate),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (asig.montoCalculadoPrev > 0)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('A recibir', style: TextStyle(fontSize: 9, color: cs.onSurface.withOpacity(0.45))),
                Text(
                  'Bs. ${fmtAnticipo.format(asig.montoCalculadoPrev)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.greenAccent.shade200 : const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHEET MANUAL
// ══════════════════════════════════════════════════════════════════════════════
class AsignacionManualSheet extends ConsumerStatefulWidget {
  final AnticipoEntity cabecera;
  final int audUsuarioI;
  final bool esEdicion;
  const AsignacionManualSheet({
    super.key,
    required this.cabecera,
    required this.audUsuarioI,
    this.esEdicion = false,
  });
  @override
  ConsumerState<AsignacionManualSheet> createState() => _AsignacionManualSheetState();
}

class _AsignacionManualSheetState extends ConsumerState<AsignacionManualSheet> {
  final Set<int> _sel = {};
  final _searchCtrl = TextEditingController();
  Timer? _searchDeb;
  Timer? _calcDeb;
  final Map<int, TextEditingController> _montoCtrls = {};

  void _setAllTipo(String tipo) {
    ref.read(asignacionManualProvider.notifier).setAllTipo(tipo);
    if (tipo == 'A') {
      for (final ctrl in _montoCtrls.values) ctrl.clear();
    }
    _debCalc();
  }

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) {
      Future.microtask(() {
        if (mounted)
          ref.read(asignacionManualProvider.notifier).cargarParaEdicion(widget.cabecera);
      });
    }
  }

  @override
  void dispose() {
    _searchDeb?.cancel();
    _calcDeb?.cancel();
    _searchCtrl.dispose();
    for (final c in _montoCtrls.values) c.dispose();
    super.dispose();
  }

  TextEditingController _montoCtrl(int id) =>
      _montoCtrls.putIfAbsent(id, () => TextEditingController());

  void _onSearch(String q) {
    if (_searchDeb?.isActive ?? false) _searchDeb!.cancel();
    _searchDeb = Timer(
      const Duration(milliseconds: 450),
      () => ref.read(searchEmpleadoTextProvider.notifier).state = q,
    );
  }

  void _debCalc() {
    if (_calcDeb?.isActive ?? false) _calcDeb!.cancel();
    _calcDeb = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final st = ref.read(asignacionManualProvider);
      if (st.empleados.isEmpty) return;
      ref.read(asignacionManualProvider.notifier).previsualizar(widget.cabecera);
    });
  }

  void _toggle(EmpleadoEntity emp, bool sel) {
    final ntf = ref.read(asignacionManualProvider.notifier);
    if (sel) {
      _sel.add(emp.codEmpleado);
      ntf.agregarEmpleado(emp);
    } else {
      _sel.remove(emp.codEmpleado);
      _montoCtrls.remove(emp.codEmpleado)?.dispose();
      ntf.removerEmpleado(emp.codEmpleado);
    }
    _debCalc();
    setState(() {});
  }

  void _toggleTodos(List<EmpleadoEntity> empleados, bool sel) {
    final ntf = ref.read(asignacionManualProvider.notifier);
    setState(() {
      for (final emp in empleados) {
        if (sel && !_sel.contains(emp.codEmpleado)) {
          _sel.add(emp.codEmpleado);
          ntf.agregarEmpleado(emp);
        } else if (!sel) {
          _sel.remove(emp.codEmpleado);
          _montoCtrls.remove(emp.codEmpleado)?.dispose();
          ntf.removerEmpleado(emp.codEmpleado);
        }
      }
    });
    _debCalc();
  }

  void _onUpdate(int id, String tipo, double monto) {
    ref.read(asignacionManualProvider.notifier).actualizarTipoYMonto(id, tipo, monto);
    _debCalc();
  }

  Widget _buildSel(EmpleadoAsignacion asig) => EmpleadoSeleccionadoTile(
    asig: asig,
    montoController: _montoCtrl(asig.codEmpleado),
    onDelete: () {
      _sel.remove(asig.codEmpleado);
      _montoCtrls.remove(asig.codEmpleado)?.dispose();
      ref.read(asignacionManualProvider.notifier).removerEmpleado(asig.codEmpleado);
      _debCalc();
      setState(() {});
    },
    onUpdate: (tipo, monto) => _onUpdate(asig.codEmpleado, tipo, monto),
  );

  Widget _buildBuscar(EmpleadoEntity emp) {
    final cs = Theme.of(context).colorScheme;
    return CheckboxListTile(
      dense: true,
      value: false,
      activeColor: cs.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onChanged: (_) => _toggle(emp, true),
      title: Text(emp.persona.datoPersona ?? '', style: const TextStyle(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final cab = widget.cabecera;
    final cs = Theme.of(ctx).colorScheme;
    final st = ref.watch(asignacionManualProvider);
    final ntf = ref.read(asignacionManualProvider.notifier);
    final term = ref.watch(searchEmpleadoTextProvider);
    final empAsync = ref.watch(
      getListaEmpleados((
        term.trim().isEmpty ? null : term.trim(),
        1, 1, 200,
        cab.codEmpresa,
      )),
    );

    ref.listen<AsignacionManualState>(asignacionManualProvider, (prev, next) {
      if (!context.mounted) return;
      if (widget.esEdicion && next.empleados.isNotEmpty && prev?.empleados.isEmpty == true) {
        setState(() {
          for (final e in next.empleados) {
            _sel.add(e.codEmpleado);
            if (e.tipo == 'F') _montoCtrl(e.codEmpleado).text = e.monto.toString();
          }
        });
      }
      if (next.mensajeExito != null && prev?.mensajeExito != next.mensajeExito) {
        final m = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        m.showSnackBar(SnackBar(content: Text(next.mensajeExito!), backgroundColor: Colors.green.shade700));
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: cs.error, duration: const Duration(seconds: 4)),
        );
      }
    });

    final sumaLocal = st.empleados.fold(0.0, (sum, e) => sum + (e.tipo == 'F' ? e.monto : 0.0));

    final double montoCal;
    final bool hayDif;
    if (st.preview.isNotEmpty) {
      montoCal = st.preview.first.sumaTotalCalculada;
      hayDif = !st.preview.first.esValido;
    } else if (st.empleados.isNotEmpty) {
      montoCal = sumaLocal;
      hayDif = (cab.debe - sumaLocal).abs() > 0.005;
    } else {
      montoCal = 0;
      hayDif = false;
    }

    final puedeConfirmar = st.preview.isNotEmpty && !hayDif && !st.cargando && st.empleados.isNotEmpty;
    final titulo = widget.esEdicion ? 'Editar distribución' : 'Asignación Manual';
    final labelBtn =
        st.cargando ? 'Calculando…'
        : st.empleados.isEmpty ? 'Selecciona al menos un empleado'
        : !puedeConfirmar ? 'La suma debe cuadrar exactamente'
        : widget.esEdicion ? 'Guardar cambios'
        : 'Confirmar Asignación';

    return AnticipoBaseSheet(
      initialChildSize: 0.88,
      builder: (_, ctrl) => Column(
        children: [
          const AnticipoSheetHandle(),
          AnticipoSheetCabecera(cabecera: cab, titulo: titulo, icon: Icons.group_add_rounded),
          AnticipoMontoProgress(
            montoTotal: cab.debe, montoAsignado: montoCal,
            cargando: st.cargando, hayItems: st.empleados.isNotEmpty, prefixLabel: 'Calculado',
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: AnticipoSheetSearchField(controller: _searchCtrl, hint: 'Buscar empleado…', onChanged: _onSearch)),
                const SizedBox(width: 10),
                empAsync.when(
                  data: (emps) {
                    final all = emps.isNotEmpty && emps.every((e) => _sel.contains(e.codEmpleado));
                    return AnticipoSelectAllButton(allSelected: all, enabled: emps.isNotEmpty, onTap: () => _toggleTodos(emps, !all));
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${_sel.length} seleccionado(s)',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
            ),
          ),
          if (st.empleados.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Text('Distribución rápida:', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.55))),
                  const SizedBox(width: 8),
                  AnticipoQuickTipoBtn(
                    label: 'Todos Auto', icon: Icons.tune_rounded,
                    active: st.empleados.isNotEmpty && st.empleados.every((e) => e.tipo == 'A'),
                    onTap: () => _setAllTipo('A'),
                  ),
                  const SizedBox(width: 6),
                  AnticipoQuickTipoBtn(
                    label: 'Todos Fijo', icon: Icons.attach_money_rounded,
                    active: st.empleados.isNotEmpty && st.empleados.every((e) => e.tipo == 'F'),
                    onTap: () => _setAllTipo('F'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: empAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (emps) {
                final noSel = emps.where((e) => !_sel.contains(e.codEmpleado)).toList();
                final hasSel = st.empleados.isNotEmpty;
                if (!hasSel && noSel.isEmpty)
                  return const AnticipoEmptyState(mensaje: 'No se encontraron empleados\ncon ese criterio.', icon: Icons.search_off_rounded);
                return CustomScrollView(
                  controller: ctrl,
                  slivers: [
                    if (hasSel) ...[
                      SliverToBoxAdapter(child: AnticipoSectionHeader(label: 'SELECCIONADOS (${st.empleados.length})')),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Column(mainAxisSize: MainAxisSize.min, children: [_buildSel(st.empleados[i]), const Divider(height: 1)]),
                          childCount: st.empleados.length,
                        ),
                      ),
                    ],
                    if (noSel.isNotEmpty) ...[
                      if (hasSel) SliverToBoxAdapter(child: AnticipoSectionHeader(label: 'RESULTADOS DE BÚSQUEDA')),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Column(mainAxisSize: MainAxisSize.min, children: [_buildBuscar(noSel[i]), if (i < noSel.length - 1) const Divider(height: 1)]),
                          childCount: noSel.length,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          AnticipoConfirmButton(
            enabled: puedeConfirmar, loading: st.cargando, label: labelBtn,
            icon: widget.esEdicion ? Icons.save_rounded : Icons.check_circle_rounded,
            onPressed: () => widget.esEdicion
                ? ntf.confirmarEdicion(cab, widget.audUsuarioI)
                : ntf.confirmarAsignacion(cab, widget.audUsuarioI),
          ),
        ],
      ),
    );
  }
}
