import 'dart:async';

import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_controller.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

Future<bool?> showPrestamoAsignacionDialog(
  BuildContext context, {
  required PrestamoDialogModo modo,
  required int audUsuarioI,
  PrestamoEntity? cabecera,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder:
        (_, __, ___) => _PrestamoAsignacionDialog(
          modo: modo,
          audUsuarioI: audUsuarioI,
          cabecera: cabecera,
        ),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

class _PrestamoAsignacionDialog extends ConsumerStatefulWidget {
  final PrestamoDialogModo modo;
  final int audUsuarioI;
  final PrestamoEntity? cabecera;

  const _PrestamoAsignacionDialog({
    required this.modo,
    required this.audUsuarioI,
    this.cabecera,
  });

  @override
  ConsumerState<_PrestamoAsignacionDialog> createState() =>
      _PrestamoAsignacionDialogState();
}

class _PrestamoAsignacionDialogState
    extends ConsumerState<_PrestamoAsignacionDialog> {
  late final PrestamosAsignacionController _ctrl;
  final _searchCtrl = TextEditingController();
  Timer? _searchDeb;

  final Map<int, TextEditingController> _montoCtrls = {};
  final _numCuotasCtrl = TextEditingController(text: '1');
  final _montoManualCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();

  int _mobileTab = 0;

  @override
  void initState() {
    super.initState();
    final totalCabecera =
        widget.cabecera != null
            ? (widget.cabecera!.debe > 0
                ? widget.cabecera!.debe
                : widget.cabecera!.haber)
            : 0.0;

    _ctrl = PrestamosAsignacionController(
      modo: widget.modo,
      montoCabecera: totalCabecera,
    );
    if (widget.cabecera != null) {
      _ctrl.cargarDatosEdicion(ref, widget.cabecera!).then((_) {
        // Inicializar campos UI con los datos cargados
        if (mounted) {
          _numCuotasCtrl.text = _ctrl.numCuotas.toStringAsFixed(0);
          _montoManualCtrl.text = _ctrl.montoManual.toString();
          _conceptoCtrl.text = _ctrl.concepto;
          for (final entry in _ctrl.seleccionados.entries) {
            _getMontoCtrl(entry.key).text = entry.value.monto.toString();
          }
        }
      });
    }
    _ctrl.addListener(_onControllerUpdate);
  }

  Timer? _previewDeb;
  String _lastPreviewHash = '';

  void _triggerPreview() {
    final selList = _ctrl.seleccionados.values.toList();
    if (selList.length == 1 &&
        _ctrl.fecIniPago != null &&
        _ctrl.esValido &&
        _ctrl.totalMonto > 0) {
      final asig = selList.first;
      final currentHash =
          '${asig.montoCalculado}-${_ctrl.getActualCuotas(asig.montoCalculado)}-${_ctrl.fecIniPago}-${_ctrl.tipoPagoGlobal}';

      if (currentHash == _lastPreviewHash) return;

      if (_previewDeb?.isActive ?? false) _previewDeb!.cancel();
      _previewDeb = Timer(const Duration(milliseconds: 600), () async {
        if (!mounted) return;

        _lastPreviewHash = currentHash;

        _ctrl.isLoadingPreview = true;
        _ctrl.notifyListeners();

        final empId =
            widget.modo == PrestamoDialogModo.manual
                ? _ctrl.codEmpresa ?? 0
                : widget.cabecera?.codEmpresa ?? 0;

        try {
          if (empId == 0) throw Exception('No hay empresa seleccionada');
          final asig = selList.first;
          final repo = ref.read(prestamoProvider(empId).notifier).repo;
          final result = await repo.previsualizarCuotas(
            montoPrestamo: asig.montoCalculado,
            numCuotas: _ctrl.getActualCuotas(asig.montoCalculado),
            fecIniPago: DateFormat('yyyy-MM-dd').format(_ctrl.fecIniPago!),
            tipoPago: _ctrl.tipoPagoGlobal,
          );
          if (mounted) _ctrl.cuotasPreview = result;
        } catch (e) {
          if (mounted) _ctrl.cuotasPreview = null;
        } finally {
          if (mounted) {
            _ctrl.isLoadingPreview = false;
            _ctrl.notifyListeners();
          }
        }
      });
    } else {
      _lastPreviewHash = '';
      if (_ctrl.cuotasPreview != null) {
        _ctrl.cuotasPreview = null;
        // _ctrl.notifyListeners();
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
    _triggerPreview();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _previewDeb?.cancel();
    _searchDeb?.cancel();
    _searchCtrl.dispose();
    _numCuotasCtrl.dispose();
    _montoManualCtrl.dispose();
    _conceptoCtrl.dispose();
    for (final c in _montoCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getMontoCtrl(int id) =>
      _montoCtrls.putIfAbsent(id, () => TextEditingController());

  void _onSearch(String q) {
    if (_searchDeb?.isActive ?? false) _searchDeb!.cancel();
    _searchDeb = Timer(
      const Duration(milliseconds: 450),
      () => ref.read(searchEmpleadoPrestamoProvider.notifier).state = q,
    );
  }

  Future<void> _hacerPeticion(int forzar) async {
    final empId =
        widget.modo == PrestamoDialogModo.manual
            ? _ctrl.codEmpresa!
            : widget.cabecera!.codEmpresa;

    final ntf = ref.read(prestamoProvider(empId).notifier);
    final xml = _ctrl.generarXml();
    final fechaStr =
        _ctrl.fecIniPago != null
            ? DateFormat('yyyy-MM-dd').format(_ctrl.fecIniPago!)
            : '';

    Future<String> requestCall(int f) async {
      if (widget.modo == PrestamoDialogModo.manual) {
        final empresas = ref.read(empresasProvider).value ?? [];
        final empSeleccionada =
            empresas.where((e) => e.codEmpresa == _ctrl.codEmpresa).firstOrNull;
        final dbSigla = empSeleccionada?.sigla ?? '';

        return ntf.crearManualMasivo(
          codEmpresa: _ctrl.codEmpresa!,
          db: dbSigla,
          montoPrestamo: _ctrl.montoManual,
          descripcion: _ctrl.concepto,
          fechaDesembolso: _ctrl.fechaDesembolso!,
          xmlEmpleados: xml,
          fecIniPago: fechaStr,
          numCuotas: _ctrl.getActualCuotas(_ctrl.montoManual),
          audUsuarioI: widget.audUsuarioI,
          tipoPago: _ctrl.tipoPagoGlobal,
          forzar: f,
        );
      } else if (widget.modo == PrestamoDialogModo.asignacionSap) {
        return ntf.asignarMasivo(
          sapRecord: widget.cabecera!,
          xmlEmpleados: xml,
          fecIniPago: fechaStr,
          numCuotas: _ctrl.getActualCuotas(_ctrl.totalMonto),
          audUsuarioI: widget.audUsuarioI,
          tipoPago: _ctrl.tipoPagoGlobal,
          forzar: f,
        );
      } else {
        return ntf.editarPrestamoMasivo(
          codEmpresa: widget.cabecera!.codEmpresa,
          db: widget.cabecera!.db,
          transIdSAP: int.tryParse(widget.cabecera!.numAsiento) ?? 0,
          xmlEmpleados: xml,
          audUsuarioI: widget.audUsuarioI,
          montoPrestamo:
              widget.cabecera!.debe > 0
                  ? widget.cabecera!.debe
                  : widget.cabecera!.haber,
          descripcion: widget.cabecera!.concepto,
          fechaDesembolso: widget.cabecera!.fechaAsiento,
          forzar: f,
        );
      }
    }

    await PrestamosAsignacionController.ejecutarConManejoDuplicado(
      context: context,
      request: requestCall,
      onSuccess: () => Navigator.of(context).pop(true),
    );
  }

  Future<void> _confirmarAsignacion() async {
    if (_ctrl.fecIniPago == null &&
        widget.modo != PrestamoDialogModo.edicionSap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione la fecha de inicio de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Edición no valida numCuotas general porque ya está en el XML
    if (widget.modo != PrestamoDialogModo.edicionSap) {
      final cuotas = double.tryParse(_numCuotasCtrl.text) ?? 0.0;
      if (cuotas <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Número de cuotas inválido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    await _hacerPeticion(0);
  }

  ({String titulo, String subtitulo, IconData icon, String labelConfirmar})
  get _cfg {
    switch (widget.modo) {
      case PrestamoDialogModo.asignacionSap:
        return (
          titulo: 'Asignación de Préstamo',
          subtitulo:
              'SAP: ${widget.cabecera?.numAsiento} · ${widget.cabecera?.concepto}',
          icon: Icons.account_balance_wallet_rounded,
          labelConfirmar: 'Confirmar Asignación',
        );
      case PrestamoDialogModo.edicionSap:
        return (
          titulo: 'Editar Préstamo',
          subtitulo:
              'Asiento: ${widget.cabecera?.numAsiento} · ${widget.cabecera?.concepto}',
          icon: Icons.edit_note_rounded,
          labelConfirmar: 'Guardar Cambios',
        );
      case PrestamoDialogModo.manual:
        return (
          titulo: 'Nuevo Préstamo Manual',
          subtitulo: 'Registro manual · Fuera de SAP',
          icon: Icons.add_card_rounded,
          labelConfirmar: 'Crear Préstamo',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isManual = widget.modo == PrestamoDialogModo.manual;
    final isEdicion = widget.modo == PrestamoDialogModo.edicionSap;

    final dialogWidth = isDesktop ? 1220.0 : size.width * 0.95;
    final dialogHeight = isDesktop ? 800.0 : size.height * 0.9;

    final term = ref.watch(searchEmpleadoPrestamoProvider);
    final empId = isManual ? _ctrl.codEmpresa : widget.cabecera?.codEmpresa;

    final prestamoState =
        empId != null ? ref.watch(prestamoProvider(empId)) : null;
    final cargando = prestamoState?.cargando ?? false;

    final empAsync = ref.watch(
      getListaEmpleados((
        term.trim().isEmpty ? null : term.trim(),
        1,
        1,
        200,
        empId,
      )),
    );

    final selList = _ctrl.seleccionados.values.toList();
    final excede = _ctrl.montoCalculadoTotal > _ctrl.totalMonto + 0.01;

    final puedeConfirmar = !cargando && _ctrl.esValido && !excede;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 44,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Column(
            children: [
              PrestamoDialogHeader(
                titulo: _cfg.titulo,
                subtitulo: _cfg.subtitulo,
                icon: _cfg.icon,
              ),
              if (isEdicion && _ctrl.swapCodEmpleado != null)
                _buildSwapBanner(cs),
              Expanded(
                child:
                    isDesktop
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 38,
                              child: _buildEmpleadosPanel(
                                cs,
                                empAsync,
                                selList,
                                isEdicion,
                              ),
                            ),
                            Container(
                              width: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.4),
                            ),
                            Expanded(
                              flex: 62,
                              child: _buildDetallePanel(
                                cs,
                                selList,
                                excede,
                                isManual,
                              ),
                            ),
                          ],
                        )
                        : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                              child: SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<int>(
                                  segments: [
                                    const ButtonSegment(
                                      value: 0,
                                      label: Text('Empleados'),
                                      icon: Icon(Icons.people_rounded),
                                    ),
                                    ButtonSegment(
                                      value: 1,
                                      label: Text(
                                        'Detalles${excede ? ' ⚠' : ''}',
                                      ),
                                      icon: const Icon(Icons.tune_rounded),
                                    ),
                                  ],
                                  selected: {_mobileTab},
                                  onSelectionChanged:
                                      (s) =>
                                          setState(() => _mobileTab = s.first),
                                  style: SegmentedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child:
                                  _mobileTab == 0
                                      ? _buildEmpleadosPanel(
                                        cs,
                                        empAsync,
                                        selList,
                                        isEdicion,
                                      )
                                      : _buildDetallePanel(
                                        cs,
                                        selList,
                                        excede,
                                        isManual,
                                      ),
                            ),
                          ],
                        ),
              ),
              PrestamoFooterActions(
                puedeConfirmar: puedeConfirmar,
                isCargando: cargando,
                labelConfirmar: _cfg.labelConfirmar,
                onConfirmar: _confirmarAsignacion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwapBanner(ColorScheme cs) {
    final target = _ctrl.seleccionados[_ctrl.swapCodEmpleado];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
      color: cs.tertiaryContainer.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(Icons.swap_horiz_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selecciona el reemplazo para "${target?.datoPersona}"',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          InkWell(
            onTap: () => _ctrl.setSwapCodEmpleado(null),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpleadosPanel(
    ColorScheme cs,
    AsyncValue<List<EmpleadoEntity>> empAsync,
    List<PrestamoEmpleadoData> selList,
    bool isEdicion,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchCtrl,
                  builder:
                      (_, val, __) => SearchBar(
                        controller: _searchCtrl,
                        hintText:
                            _ctrl.swapCodEmpleado != null
                                ? 'Buscar reemplazo…'
                                : 'Buscar empleado…',
                        leading: const Icon(Icons.search, size: 18),
                        trailing: [
                          if (val.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 15),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearch('');
                              },
                            ),
                        ],
                        onChanged: _onSearch,
                        elevation: const WidgetStatePropertyAll(0),
                        constraints: const BoxConstraints(
                          minHeight: 38,
                          maxHeight: 38,
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                          cs.surfaceContainerLowest,
                        ),
                        side: WidgetStatePropertyAll(
                          BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 10),
                        ),
                        textStyle: const WidgetStatePropertyAll(
                          TextStyle(fontSize: 12.5),
                        ),
                      ),
                ),
              ),
              if (_ctrl.swapCodEmpleado == null) ...[
                const SizedBox(width: 6),
                empAsync.when(
                  data: (emps) {
                    final allSel =
                        emps.isNotEmpty &&
                        emps.every(
                          (e) => _ctrl.seleccionados.containsKey(e.codEmpleado),
                        );
                    return Tooltip(
                      message:
                          allSel ? 'Deseleccionar todos' : 'Seleccionar todos',
                      child: InkWell(
                        onTap:
                            emps.isEmpty
                                ? null
                                : () => _ctrl.toggleTodos(emps, !allSel),
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                allSel ? cs.primary : cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color:
                                  allSel
                                      ? cs.primary
                                      : cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            allSel
                                ? Icons.deselect_rounded
                                : Icons.select_all_rounded,
                            size: 17,
                            color: allSel ? cs.onPrimary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                  loading:
                      () => const SizedBox(
                        width: 38,
                        height: 38,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error: (_, __) => const SizedBox(width: 38, height: 38),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          child: Row(
            children: [
              // Text(
              //   '${selList.length} seleccionado (s).',
              //   style: TextStyle(
              //     fontSize: 13,
              //     fontWeight: FontWeight.w700,
              //     color: cs.primary,
              //   ),
              // ),
              const Spacer(),
              if (selList.isNotEmpty && _ctrl.swapCodEmpleado == null) ...[
                _quickChip(
                  cs,
                  'Automático',
                  Icons.tune_rounded,
                  selList.every((e) => e.tipo == 'A'),
                  () => _ctrl.setAllTipo('A'),
                ),
                const SizedBox(width: 4),
                _quickChip(
                  cs,
                  'Fijo',
                  Icons.attach_money_rounded,
                  selList.every((e) => e.tipo == 'F'),
                  () => _ctrl.setAllTipo('F'),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child:
              (widget.modo == PrestamoDialogModo.manual &&
                      _ctrl.codEmpresa == null)
                  ? Center(
                    child: Text(
                      'Selecciona una empresa primero',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  )
                  : empAsync.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (emps) {
                      final noSel =
                          emps
                              .where(
                                (e) =>
                                    !_ctrl.seleccionados.containsKey(
                                      e.codEmpleado,
                                    ),
                              )
                              .toList();

                      if (selList.isEmpty && noSel.isEmpty) {
                        return Center(
                          child: Text(
                            'Sin resultados',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12.5,
                            ),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        children: [
                          if (selList.isNotEmpty &&
                              _ctrl.swapCodEmpleado == null) ...[
                            _sectionLabel(
                              cs,
                              'SELECCIONADOS (${selList.length})',
                            ),
                            ...selList.map(
                              (e) => PrestamoEmpleadoSeleccionadoTile(
                                asig: e,
                                montoController: _getMontoCtrl(e.codEmpleado),
                                numCuotas: _ctrl.getActualCuotas(
                                  e.montoCalculado,
                                ),
                                onDelete: () {
                                  _ctrl.seleccionados.remove(e.codEmpleado);
                                  _montoCtrls.remove(e.codEmpleado)?.dispose();
                                  _ctrl.recalcular();
                                },
                                onUpdate:
                                    (t, m) =>
                                        _ctrl.onUpdate(e.codEmpleado, t, m),
                                isSwapping:
                                    _ctrl.swapCodEmpleado == e.codEmpleado,
                                onSwap:
                                    isEdicion
                                        ? () => _ctrl.setSwapCodEmpleado(
                                          e.codEmpleado,
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (noSel.isNotEmpty) ...[
                            _sectionLabel(
                              cs,
                              selList.isNotEmpty &&
                                      _ctrl.swapCodEmpleado == null
                                  ? 'RESULTADOS'
                                  : 'EMPLEADOS',
                            ),
                            ...noSel.map((e) => _resultRow(cs, e)),
                          ],
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _sectionLabel(ColorScheme cs, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 3),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
        color: cs.onSurfaceVariant,
      ),
    ),
  );

  Widget _quickChip(
    ColorScheme cs,
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: active ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(ColorScheme cs, EmpleadoEntity e) {
    return InkWell(
      onTap: () {
        final swapped = _ctrl.onEmployeeTap(e);
        if (swapped) {
          _montoCtrls[e.codEmpleado] = TextEditingController(
            text: _ctrl.seleccionados[e.codEmpleado]?.monto.toStringAsFixed(2),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(
                Icons.person_rounded,
                size: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                e.persona.datoPersona ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: cs.onSurface),
              ),
            ),
            if (_ctrl.swapCodEmpleado != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ELEGIR',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                  ),
                ),
              )
            else
              Icon(Icons.add_rounded, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallePanel(
    ColorScheme cs,
    List<PrestamoEmpleadoData> selList,
    bool excede,
    bool isManual,
  ) {
    return Container(
      color: cs.surfaceContainerLowest.withValues(alpha: 0.5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: PrestamoMontoProgress(
              montoTotal: _ctrl.totalMonto,
              montoAsignado: _ctrl.montoCalculadoTotal,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (isManual) ...[
                  _buildManualFields(cs),
                  const SizedBox(height: 16),
                ],
                _buildGlobalConfig(cs),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'PREVISUALIZACIÓN DE CUOTAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                _buildPlanDePagos(cs, selList),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualFields(ColorScheme cs) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    final empresaWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Empresa',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ref
            .watch(empresasProvider)
            .when(
              data: (todasEmpresas) {
                final empresas =
                    todasEmpresas.where((e) => e.codEmpresa != 0).toList();
                return Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _ctrl.codEmpresa,
                      isDense: true,
                      hint: const Text(
                        'Seleccionar...',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      items:
                          empresas
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.codEmpresa,
                                  child: Text(
                                    e.nombre,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        _ctrl.codEmpresa = val;
                        _ctrl.seleccionados.clear();
                        _ctrl.recalcular();
                      },
                    ),
                  ),
                );
              },
              loading:
                  () => const SizedBox(
                    height: 36,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error: (_, __) => const SizedBox(),
            ),
      ],
    );

    final fechaDesembolsoWidget = PrestamoFechaPickerField(
      label: 'Fec. Desembolso',
      fecha: _ctrl.fechaDesembolso,
      onChanged: (d) {
        _ctrl.fechaDesembolso = d;
        _ctrl.recalcular();
      },
    );

    final montoWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monto (Bs.)',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: _montoManualCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            onChanged: (v) {
              _ctrl.montoManual = double.tryParse(v) ?? 0.0;
              _ctrl.recalcular();
            },
          ),
        ),
      ],
    );

    final conceptoWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Concepto',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: TextField(
            controller: _conceptoCtrl,
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            onChanged: (v) {
              _ctrl.concepto = v;
              _ctrl.recalcular();
            },
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos del Préstamo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  empresaWidget,
                  const SizedBox(height: 12),
                  fechaDesembolsoWidget,
                ],
              )
              : Row(
                children: [
                  Expanded(child: empresaWidget),
                  const SizedBox(width: 12),
                  Expanded(child: fechaDesembolsoWidget),
                ],
              ),
          const SizedBox(height: 12),
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  montoWidget,
                  const SizedBox(height: 12),
                  conceptoWidget,
                ],
              )
              : Row(
                children: [
                  Expanded(flex: 2, child: montoWidget),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: conceptoWidget),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildGlobalConfig(ColorScheme cs) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    final tipoPago = PrestamoTipoPagoField(
      value: _ctrl.tipoPagoGlobal,
      onChanged: (v) {
        _ctrl.tipoPagoGlobal = v;
        _ctrl.recalcular();
      },
    );

    final fechaPago = PrestamoFechaPickerField(
      label: 'Inicio de Pago',
      fecha: _ctrl.fecIniPago,
      onChanged: (d) {
        _ctrl.fecIniPago = d;
        _ctrl.recalcular();
      },
    );

    final nroCuotas = _buildNroCuotasMockup(cs);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tipoPago,
                  const SizedBox(height: 12),
                  fechaPago,
                  const SizedBox(height: 12),
                  nroCuotas,
                ],
              )
              : Row(
                children: [
                  Expanded(child: tipoPago),
                  const SizedBox(width: 12),
                  Expanded(child: fechaPago),
                  const SizedBox(width: 12),
                  Expanded(child: nroCuotas),
                ],
              ),
    );
  }

  Widget _buildNroCuotasMockup(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _ctrl.isMontoFijo ? 'Monto/Cuota' : 'N° Cuotas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  _ctrl.isMontoFijo
                      ? 'MONTO/CUOTA:\n\nFija un descuento exacto por mes. El sistema calculará la cantidad de cuotas necesarias y el saldo restante irá a una cuota final.\n\nEj: Préstamo de 7000 a 300/mes = 23 cuotas de 300 + 1 cuota final de 100.'
                      : 'N° CUOTAS:\n\nEl préstamo se dividirá equitativamente según la cantidad de meses ingresada.\n\nEj: Préstamo de 7000 en 23 cuotas = 22 cuotas de 304.35 + 1 cuota final de 304.30.',
              padding: const EdgeInsets.all(12),
              textStyle: TextStyle(fontSize: 12, color: cs.onInverseSurface),
              decoration: BoxDecoration(
                color: cs.inverseSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 2),
                  Text(
                    'Info',
                    style: TextStyle(fontSize: 10, color: cs.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numCuotasCtrl,
                  keyboardType:
                      _ctrl.isMontoFijo
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.number,
                  inputFormatters: [
                    _ctrl.isMontoFijo
                        ? FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        )
                        : FilteringTextInputFormatter.digitsOnly,
                    if (!_ctrl.isMontoFijo) LengthLimitingTextInputFormatter(3),
                  ],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) {
                    _ctrl.numCuotas = double.tryParse(v) ?? 0;
                    _ctrl.recalcular();
                  },
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: Icon(
                  _ctrl.isMontoFijo
                      ? Icons.attach_money_rounded
                      : Icons.repeat_rounded,
                  size: 15,
                  color: cs.primary,
                ),
                onPressed: () {
                  _ctrl.isMontoFijo = !_ctrl.isMontoFijo;
                  _numCuotasCtrl.text = '1';
                  _ctrl.numCuotas = 1;
                  _ctrl.recalcular();
                },
                tooltip:
                    _ctrl.isMontoFijo
                        ? 'Modo: monto fijo por cuota'
                        : 'Modo: número de cuotas',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDePagos(ColorScheme cs, List<PrestamoEmpleadoData> selList) {
    if (selList.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 40,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Selecciona empleados para ver el resumen',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (selList.length > 1) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 19,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'El detalle de cuotas se muestra al seleccionar un solo empleado. Con ${selList.length} empleados se usan estos parámetros para todos.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_ctrl.isLoadingPreview) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_ctrl.cuotasPreview == null || _ctrl.cuotasPreview!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          'Ingrese los datos para previsualizar las cuotas.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    final cuotas = _ctrl.cuotasPreview!;
    final mostrarResumen = cuotas.length > 12;
    final cuotasVisibles = mostrarResumen ? 12 : cuotas.length;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        itemCount: cuotasVisibles,
        itemBuilder: (context, i) {
          if (mostrarResumen && i == 10) {
            final omitidas = cuotas.length - 12;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                '... y $omitidas cuotas más ...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            );
          }

          final idxCuota = (mostrarResumen && i == 11) ? cuotas.length - 1 : i;
          final c = cuotas[idxCuota];
          final fecha = c.fechaPago ?? DateTime.now();

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color:
                  idxCuota.isEven
                      ? cs.surfaceContainerLowest.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${c.numeroCuota}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(fecha),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Bs. ${c.haber.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
