import 'dart:async';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/repositories/prestamo_impl.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_shared_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

Future<String?> showPagosAsignacionDialog(
  BuildContext context, {
  required PrestamoEntity sapRecord,
  required int audUsuarioI,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Asignar Pago',
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) {
      return _PagosAsignacionDialogView(
        sapRecord: sapRecord,
        audUsuarioI: audUsuarioI,
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final isDesktop = ResponsiveUtilsBosque.isDesktop(ctx);
      return SlideTransition(
        position: Tween<Offset>(
          begin: isDesktop ? const Offset(0, -0.05) : const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

class PagosAsignacionController extends ChangeNotifier {
  final PrestamoEntity sapRecord;
  final int audUsuarioI;
  final int codEmpresa;

  bool isLoading = false;
  String errorMsg = '';

  // Empleados seleccionados en el panel izquierdo
  final Set<int> empSeleccionados = {};

  // Préstamos seleccionados en el panel derecho (key = codPrestamo)
  final Map<int, PrestamoEmpleadoData> prestamosSeleccionados = {};

  double montoCalculadoTotal = 0;
  bool esValido = false;

  // ─── Estado para grupos expandibles (modo Por Préstamo) ────────────────────────────
  final Set<String> _gruposExpandidos = {};
  final Set<String> _gruposCargando = {};
  final Map<String, List<PrestamoEntity>> _empleadosPorGrupo = {};

  bool grupoExpandido(String key) => _gruposExpandidos.contains(key);
  bool grupoCargando(String key) => _gruposCargando.contains(key);
  List<PrestamoEntity>? empleadosDeGrupo(String key) => _empleadosPorGrupo[key];

  /// Para grupos con 1 sola persona (L3 ya devuelve nombre real), no hay que expandir.
  bool grupoEsIndividual(List<PrestamoEntity> loans) {
    final nombre = loans.first.nombreEmpleadoAsignado ?? '';
    return !nombre.toUpperCase().startsWith('VARIOS');
  }

  /// Expande un grupo cargando sus empleados individuales via L1.
  Future<void> expandirGrupo(
    String grupoKey,
    String numAsiento,
    String db,
  ) async {
    // Toggle collapse
    if (_gruposExpandidos.contains(grupoKey)) {
      _gruposExpandidos.remove(grupoKey);
      if (!_disposed) notifyListeners();
      return;
    }
    // Ya cargados: solo expandir
    if (_empleadosPorGrupo.containsKey(grupoKey)) {
      _gruposExpandidos.add(grupoKey);
      if (!_disposed) notifyListeners();
      return;
    }
    // Cargar via L1
    _gruposCargando.add(grupoKey);
    if (!_disposed) notifyListeners();
    try {
      final transId = int.tryParse(numAsiento) ?? 0;
      if (transId > 0) {
        final repo = PrestamoImpl();
        final lista = await repo.listarEmpleadosAsignados(
          codEmpresa: codEmpresa,
          db: db,
          transIdSAP: transId,
        );
        _empleadosPorGrupo[grupoKey] =
            lista.where((e) => (e.saldoPendiente ?? 0) > 0).toList();
      }
    } catch (_) {
      // Si falla, el grupo se expande vacío (se muestra error al usuario)
    }
    _gruposCargando.remove(grupoKey);
    _gruposExpandidos.add(grupoKey);
    if (!_disposed) notifyListeners();
  }

  PagosAsignacionController({
    required this.sapRecord,
    required this.audUsuarioI,
  }) : codEmpresa = sapRecord.codEmpresa;

  /// Selecciona o deselecciona todos los préstamos de un grupo de cabecera.
  void toggleGrupo(List<PrestamoEntity> loans) {
    final allSel = loans.every(
      (p) =>
          p.codPrestamo != null &&
          prestamosSeleccionados.containsKey(p.codPrestamo),
    );
    for (final p in loans) {
      togglePrestamo(p, !allSel);
    }
  }

  void toggleEmpleado(
    int codEmpleado,
    String datoPersona,
    List<PrestamoEntity> vigentesAll,
  ) {
    if (empSeleccionados.contains(codEmpleado)) {
      empSeleccionados.remove(codEmpleado);
      prestamosSeleccionados.removeWhere(
        (k, v) => v.codEmpleado == codEmpleado,
      );
    } else {
      empSeleccionados.add(codEmpleado);
    }
    recalcular();
  }

  void toggleTodosEmpleados(
    List<PrestamoEmpleadoData> emps,
    bool sel,
    List<PrestamoEntity> vigentesAll,
  ) {
    for (final emp in emps) {
      if (sel && !empSeleccionados.contains(emp.codEmpleado)) {
        toggleEmpleado(emp.codEmpleado, emp.datoPersona, vigentesAll);
      } else if (!sel && empSeleccionados.contains(emp.codEmpleado)) {
        toggleEmpleado(emp.codEmpleado, emp.datoPersona, vigentesAll);
      }
    }
  }

  void togglePrestamo(PrestamoEntity p, bool sel) {
    if (p.codPrestamo == null) return;
    if (sel) {
      prestamosSeleccionados[p.codPrestamo!] = PrestamoEmpleadoData(
        codPrestamo: p.codPrestamo!,
        codEmpleado: p.codEmpleado!,
        datoPersona: p.nombreEmpleadoAsignado ?? '',
        tipo: 'A',
        monto: 0.0,
        montoCalculado: 0.0,
        saldoPendiente: p.saldoPendiente ?? 0.0,
        concepto: p.concepto,
        numAsiento: p.numAsiento,
      );
    } else {
      prestamosSeleccionados.remove(p.codPrestamo);
    }

    if (prestamosSeleccionados.length == 1) {
      for (final asig in prestamosSeleccionados.values) {
        asig.tipo = 'A';
      }
    } else if (prestamosSeleccionados.length > 1) {
      for (final asig in prestamosSeleccionados.values) {
        if (asig.tipo == 'A') {
          asig.monto = 0.0;
        }
        asig.tipo = 'F';
      }
    }
    recalcular();
  }

  void onUpdatePrestamo(int codPrestamo, String tipo, double monto) {
    final asig = prestamosSeleccionados[codPrestamo];
    if (asig != null) {
      if (asig.tipo == 'A' && tipo == 'F') {
        asig.monto = 0.0;
      } else {
        asig.monto = monto;
      }
      asig.tipo = tipo;
      recalcular();
    }
  }

  void setAllTipo(String tipo) {
    for (final asig in prestamosSeleccionados.values) {
      asig.tipo = tipo;
    }
    recalcular();
  }

  void recalcular() {
    double sumaFijos = 0;
    for (final e in prestamosSeleccionados.values) {
      if (e.tipo == 'F') {
        sumaFijos += e.monto;
        e.montoCalculado = e.monto;
      }
    }

    final montoRestante = sapRecord.haber - sumaFijos;
    final autoLoans =
        prestamosSeleccionados.values.where((l) => l.tipo == 'A').toList();
    for (final l in autoLoans) {
      l.montoCalculado = 0;
    }

    double remaining = montoRestante > 0 ? montoRestante : 0;
    bool changed = true;
    while (remaining > 0.01 && autoLoans.isNotEmpty && changed) {
      changed = false;
      final activeAutos =
          autoLoans
              .where((l) => l.montoCalculado < (l.saldoPendiente ?? 0))
              .toList();
      if (activeAutos.isEmpty) break;

      final share = remaining / activeAutos.length;
      for (final l in activeAutos) {
        final space = (l.saldoPendiente ?? 0) - l.montoCalculado;
        final add = share < space ? share : space;
        l.montoCalculado += add;
        remaining -= add;
        changed = true;
      }
    }

    double totalCalc = 0;
    bool hasNegativeOrOver = false;
    for (final e in prestamosSeleccionados.values) {
      totalCalc += e.montoCalculado;
      final s = e.saldoPendiente ?? 0;
      if (e.montoCalculado < 0 || e.montoCalculado > s + 0.01) {
        hasNegativeOrOver = true;
      }
    }

    montoCalculadoTotal = totalCalc;
    esValido =
        prestamosSeleccionados.isNotEmpty &&
        !hasNegativeOrOver &&
        (sapRecord.haber - totalCalc).abs() < 0.001;

    if (totalCalc > sapRecord.haber + 0.001) {
      esValido = false;
    }

    if (!_disposed) notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String generarXml() {
    final sb = StringBuffer();
    sb.writeln('<prestamos>');
    for (final e in prestamosSeleccionados.values) {
      if (e.montoCalculado > 0) {
        sb.writeln(
          '  <prestamo codPrestamo="${e.codPrestamo}" '
          'montoPago="${e.montoCalculado}" transIdSAP_pago="${sapRecord.numAsiento}" '
          'concepto="${sapRecord.concepto.replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}" />',
        );
      }
    }
    sb.writeln('</prestamos>');
    return sb.toString();
  }

  Future<String?> confirmarAsignacion(WidgetRef ref) async {
    if (!esValido) return null;
    isLoading = true;
    errorMsg = '';
    if (!_disposed) notifyListeners();

    try {
      final repo = PrestamoImpl();
      final xml = generarXml();

      final response = await repo.asignarPagosMasivo(
        xmlPagos: xml,
        audUsuario: audUsuarioI,
      );

      isLoading = false;
      return response.message;
    } catch (e) {
      isLoading = false;
      errorMsg = e.toString().replaceAll('Exception: ', '');
      if (!_disposed) notifyListeners();
      return null;
    }
  }
}

final _searchPagosProvider = StateProvider.autoDispose<String>((ref) => '');

enum _VistaPanel { porEmpleado, porGrupo }

class _PagosAsignacionDialogView extends ConsumerStatefulWidget {
  final PrestamoEntity sapRecord;
  final int audUsuarioI;

  const _PagosAsignacionDialogView({
    required this.sapRecord,
    required this.audUsuarioI,
  });

  @override
  ConsumerState<_PagosAsignacionDialogView> createState() =>
      _PagosAsignacionDialogViewState();
}

class _PagosAsignacionDialogViewState
    extends ConsumerState<_PagosAsignacionDialogView> {
  final _searchCtrl = TextEditingController();
  final NumberFormat _fmt = NumberFormat('#,##0.00', 'en_US');
  Timer? _searchDeb;
  int _mobileTab = 0;
  final Map<int, TextEditingController> _montoCtrls = {};

  late PagosAsignacionController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PagosAsignacionController(
      sapRecord: widget.sapRecord,
      audUsuarioI: widget.audUsuarioI,
    );
    _ctrl.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _searchDeb?.cancel();
    _searchCtrl.dispose();
    for (final c in _montoCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getMontoCtrl(int id) =>
      _montoCtrls.putIfAbsent(id, () => TextEditingController());

  void _onSearch(String q) {
    if (_searchDeb?.isActive ?? false) _searchDeb!.cancel();
    _searchDeb = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref.read(_searchPagosProvider.notifier).state = q;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final dialogWidth = isDesktop ? 1100.0 : size.width * 0.95;
    final dialogHeight = isDesktop ? 750.0 : size.height * 0.9;

    final term = ref.watch(_searchPagosProvider);

    // Observamos los vigentes. El provider inicia su carga automáticamente.
    final prestamoStateAsync = ref.watch(
      prestamoVigentesPorEmpleadoProvider(_ctrl.codEmpresa),
    );
    final vigentesAll =
        prestamoStateAsync.valueOrNull
            ?.where((p) => p.codEmpleado != null && (p.saldoPendiente ?? 0) > 0)
            .toList() ??
        [];
    final cargandoVigentes = prestamoStateAsync.isLoading;

    // Derivar lista única de empleados con préstamos vigentes, filtrada por búsqueda
    final empUniqueMap = <int, PrestamoEmpleadoData>{};
    final lowerTerm = term.trim().toLowerCase();
    for (final p in vigentesAll) {
      if (!empUniqueMap.containsKey(p.codEmpleado!)) {
        final nombre = p.nombreEmpleadoAsignado ?? '';
        if (lowerTerm.isEmpty || nombre.toLowerCase().contains(lowerTerm)) {
          empUniqueMap[p.codEmpleado!] = PrestamoEmpleadoData(
            codEmpleado: p.codEmpleado!,
            datoPersona: nombre.isEmpty ? 'Empleado ${p.codEmpleado}' : nombre,
          );
        }
      }
    }
    final emps = empUniqueMap.values.toList();

    final selectedEmployeesLoans =
        vigentesAll
            .where(
              (p) =>
                  p.codEmpleado != null &&
                  _ctrl.empSeleccionados.contains(p.codEmpleado),
            )
            .toList();

    final selList = _ctrl.prestamosSeleccionados.values.toList();
    final excede = _ctrl.montoCalculadoTotal > _ctrl.sapRecord.haber + 0.01;
    final puedeConfirmar = !cargandoVigentes && _ctrl.esValido && !excede;

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
                titulo: 'Asignar Pago',
                subtitulo:
                    'SAP: ${_ctrl.sapRecord.numAsiento} · ${_ctrl.sapRecord.concepto}',
                icon: Icons.payments_rounded,
              ),
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
                                emps,
                                vigentesAll,
                                cargandoVigentes,
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
                                selectedEmployeesLoans,
                                excede,
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
                                        'Préstamos${excede ? ' ⚠' : ''}',
                                      ),
                                      icon: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                      ),
                                    ),
                                  ],
                                  selected: {_mobileTab},
                                  onSelectionChanged:
                                      (s) =>
                                          setState(() => _mobileTab = s.first),
                                ),
                              ),
                            ),
                            Expanded(
                              child:
                                  _mobileTab == 0
                                      ? _buildEmpleadosPanel(
                                        cs,
                                        emps,
                                        vigentesAll,
                                        cargandoVigentes,
                                      )
                                      : _buildDetallePanel(
                                        cs,
                                        selectedEmployeesLoans,
                                        excede,
                                      ),
                            ),
                          ],
                        ),
              ),
              if (_ctrl.errorMsg.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  color: cs.errorContainer,
                  width: double.infinity,
                  child: Text(
                    _ctrl.errorMsg,
                    style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                  ),
                ),
              PrestamoFooterActions(
                puedeConfirmar: puedeConfirmar,
                isCargando: _ctrl.isLoading,
                labelConfirmar: 'Confirmar Pagos',
                onConfirmar: () async {
                  final msg = await _ctrl.confirmarAsignacion(ref);
                  if (msg != null) {
                    if (mounted) Navigator.pop(context, msg);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpleadosPanel(
    ColorScheme cs,
    List<PrestamoEmpleadoData> emps,
    List<PrestamoEntity> vigentesAll,
    bool isLoading,
  ) {
    final allSel =
        emps.isNotEmpty &&
        emps.every((e) => _ctrl.empSeleccionados.contains(e.codEmpleado));

    return Column(
      children: [
        EmpleadosSeleccionHeader(
          searchCtrl: _searchCtrl,
          onSearch: _onSearch,
          isLoading: isLoading,
          isAllSelected: allSel,
          onToggleAll: () {
            if (emps.isEmpty) return;
            _ctrl.toggleTodosEmpleados(emps, !allSel, vigentesAll);
          },
        ),
        if (!isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${emps.length} empleado(s) con préstamos vigentes',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                if (_ctrl.prestamosSeleccionados.isNotEmpty)
                  Text(
                    '${_ctrl.prestamosSeleccionados.length} préstamo(s) sel.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildEmpleadosList(cs, emps, vigentesAll),
        ),
      ],
    );
  }

  Widget _buildEmpleadosList(
    ColorScheme cs,
    List<PrestamoEmpleadoData> emps,
    List<PrestamoEntity> vigentesAll,
  ) {
    if (emps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay empleados con\npréstamos vigentes',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: emps.length,
      itemBuilder: (ctx, i) {
        final emp = emps[i];
        final isSel = _ctrl.empSeleccionados.contains(emp.codEmpleado);
        final empLoansCount =
            vigentesAll.where((p) => p.codEmpleado == emp.codEmpleado).length;
        final inicial =
            emp.datoPersona.isNotEmpty ? emp.datoPersona[0].toUpperCase() : '?';

        return InkWell(
          onTap:
              () => _ctrl.toggleEmpleado(
                emp.codEmpleado,
                emp.datoPersona,
                vigentesAll,
              ),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSel
                      ? cs.primaryContainer.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel ? cs.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSel ? cs.primary : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      inicial,
                      style: TextStyle(
                        color: isSel ? cs.onPrimary : cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.datoPersona,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? cs.onPrimaryContainer : cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 11,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$empLoansCount préstamo(s)',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSel
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isSel ? cs.primary : cs.outlineVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Panel Derecho: Detalle de Préstamos a Pagar ────────────────────────────
  Widget _buildDetallePanel(
    ColorScheme cs,
    List<PrestamoEntity> selectedEmployeesLoans,
    bool excede,
  ) {
    if (selectedEmployeesLoans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 48,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona empleados para ver\nsus préstamos vigentes',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13.5),
            ),
          ],
        ),
      );
    }

    // Group by codEmpleado
    final Map<int, List<PrestamoEntity>> grouped = {};
    for (final p in selectedEmployeesLoans) {
      grouped.putIfAbsent(p.codEmpleado!, () => []).add(p);
    }
    final keys = grouped.keys.toList();
    final selList = _ctrl.prestamosSeleccionados.values.toList();

    return Column(
      children: [
        // Barra de progreso de monto
        PrestamoMontoProgress(
          montoTotal: _ctrl.sapRecord.haber,
          montoAsignado: _ctrl.montoCalculadoTotal,
        ),
        const Divider(height: 1),
        // Toolbar: tipo global
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: cs.surfaceContainerLowest,
          child: Row(
            children: [
              Text(
                'TIPO DE DISTRIBUCION',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _tipoChip(
                cs,
                label: 'Automático',
                icon: Icons.tune_rounded,
                isSelected:
                    selList.isNotEmpty && selList.every((e) => e.tipo == 'A'),
                onTap: () => _ctrl.setAllTipo('A'),
              ),
              const SizedBox(width: 6),
              _tipoChip(
                cs,
                label: 'Fijo',
                icon: Icons.attach_money_rounded,
                isSelected:
                    selList.isNotEmpty && selList.every((e) => e.tipo == 'F'),
                onTap: () => _ctrl.setAllTipo('F'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lista agrupada de empleados
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final employeeLoans = grouped[keys[i]]!;
              return _buildEmployeeGroup(cs, employeeLoans);
            },
          ),
        ),
      ],
    );
  }

  Widget _tipoChip(
    ColorScheme cs, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildEmployeeGroup(
    ColorScheme cs,
    List<PrestamoEntity> employeeLoans,
  ) {
    final first = employeeLoans.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(cs, (first.nombreEmpleadoAsignado ?? '').toUpperCase()),
        ...employeeLoans.map((p) => _buildLoanItem(cs, p)),
      ],
    );
  }

  Widget _buildLoanItem(ColorScheme cs, PrestamoEntity p) {
    final isSel = _ctrl.prestamosSeleccionados.containsKey(p.codPrestamo);
    final e = _ctrl.prestamosSeleccionados[p.codPrestamo];

    final tCtrl = _getMontoCtrl(p.codPrestamo!);
    if (isSel) {
      if (e!.tipo == 'A') {
        final formatted = _fmt.format(e.montoCalculado);
        if (tCtrl.text != formatted) tCtrl.text = formatted;
      } else {
        final currentTextVal =
            double.tryParse(tCtrl.text.replaceAll(',', '')) ?? 0.0;
        if ((currentTextVal - e.monto).abs() > 0.001) {
          tCtrl.text = e.monto == 0 ? '' : _fmt.format(e.monto);
        }
      }
    }

    final mCalculado = isSel ? e!.montoCalculado : 0.0;
    final exceedsLimit = mCalculado > (p.saldoPendiente ?? 0) + 0.01;
    final nuevoSaldo = (p.saldoPendiente ?? 0) - mCalculado;

    return Container(
      decoration: BoxDecoration(
        color:
            isSel
                ? cs.primaryContainer.withValues(alpha: 0.18)
                : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Checkbox(
              value: isSel,
              onChanged: (v) => _ctrl.togglePrestamo(p, v ?? false),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.concepto ?? 'Préstamo #${p.codPrestamo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
                if (p.numAsiento != null && p.numAsiento!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child:
                        (p.numAsiento == '0' || p.numAsiento == 'MANUAL')
                            ? Text(
                              'Observación: ${p.observacion ?? ''}',
                              style: TextStyle(fontSize: 10, color: cs.outline),
                            )
                            : Text(
                              'Asiento: ${p.numAsiento}',
                              style: TextStyle(fontSize: 10, color: cs.outline),
                            ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _InfoDato(
                      label: 'Saldo Total',
                      value: 'Bs. ${_fmt.format(p.debe)}',
                      color: cs.onSurfaceVariant,
                    ),
                    _InfoDato(
                      label: 'Saldo Actual',
                      value: 'Bs. ${_fmt.format(p.saldoPendiente ?? 0)}',
                      color: cs.onSurface,
                    ),
                    if (isSel)
                      _InfoDato(
                        label: 'Nuevo Saldo',
                        value: 'Bs. ${_fmt.format(nuevoSaldo)}',
                        color:
                            nuevoSaldo < 0
                                ? cs.error
                                : (nuevoSaldo == 0 ? cs.primary : cs.onSurface),
                        isBold: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isSel) ...[
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            _ctrl.onUpdatePrestamo(
                              p.codPrestamo!,
                              'A',
                              e!.monto,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  e!.tipo == 'A'
                                      ? cs.primary
                                      : cs.surfaceContainerHighest,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Auto',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    e.tipo == 'A'
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _ctrl.onUpdatePrestamo(p.codPrestamo!, 'F', 0.0);
                            tCtrl.clear();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  e.tipo == 'F'
                                      ? cs.primary
                                      : cs.surfaceContainerHighest,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Fijo',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    e.tipo == 'F'
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 75,
                      height: 28,
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (hasFocus) {
                            tCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: tCtrl.text.length,
                            );
                          }
                        },
                        child: TextFormField(
                          controller: tCtrl,
                          readOnly: e.tipo == 'A',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            TextInputFormatter.withFunction((
                              oldValue,
                              newValue,
                            ) {
                              if (newValue.text.isEmpty) return newValue;
                              final regex = RegExp(r'^\d*\.?\d{0,2}$');
                              return regex.hasMatch(newValue.text)
                                  ? newValue
                                  : oldValue;
                            }),
                          ],
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                e.tipo == 'A'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: exceedsLimit ? cs.error : null,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                            filled: e.tipo == 'A',
                            fillColor:
                                e.tipo == 'A'
                                    ? cs.surfaceContainerHighest.withValues(
                                      alpha: 0.5,
                                    )
                                    : null,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color:
                                    exceedsLimit ? cs.error : cs.outlineVariant,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: exceedsLimit ? cs.error : cs.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (v) {
                            if (e.tipo == 'F') {
                              final val =
                                  double.tryParse(v.replaceAll(',', '')) ?? 0.0;
                              _ctrl.onUpdatePrestamo(p.codPrestamo!, 'F', val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (exceedsLimit)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Excede saldo',
                      style: TextStyle(color: cs.error, fontSize: 9),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoDato extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _InfoDato({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
