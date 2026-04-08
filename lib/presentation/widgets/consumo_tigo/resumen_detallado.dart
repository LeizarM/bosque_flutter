
import 'dart:typed_data';



import 'package:bosque_flutter/core/state/consumo_tigo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/tigo_ejecutado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/consumo_tigo/cambios_linea_tigo.dart';
import 'package:bosque_flutter/presentation/widgets/consumo_tigo/chips_tigo.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class ResumenDetalladoScreen extends ConsumerStatefulWidget {
  final String periodoCobrado;
  const ResumenDetalladoScreen({super.key, required this.periodoCobrado});

  @override
  ConsumerState<ResumenDetalladoScreen> createState() => _ResumenDetalladoScreenState();
}

class _ResumenDetalladoScreenState extends ConsumerState<ResumenDetalladoScreen> {
  final TextEditingController _buscadorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buscadorController.clear(); 
    // Verificamos si ya está ejecutado al entrar a la pantalla para setear el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final facturas = ref.read(facturasTigoProvider).asData?.value ?? [];
      final isEjecutado = facturas.any((f) => f.periodoCobrado == widget.periodoCobrado && f.estado?.toUpperCase() == 'EJECUTADO');
      if (isEjecutado) {
        ref.read(resumenDetalladoProvider(widget.periodoCobrado).notifier).setMostrarEjecutado(true);
      }
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // LÓGICA DE NAVEGACIÓN Y REPORTES
  // ═══════════════════════════════════════════════════════════════════

  void _navegarCambiosLinea() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CambiosLineaScreen(periodoCobrado: widget.periodoCobrado),
    ));
  }

  void _navegarChipsTigo() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ChipTigoScreen(),
    ));
  }

List<_ReporteItem> get _reportes => [
    _ReporteItem(
      label: 'Reporte General', icon: Icons.picture_as_pdf, color: Colors.deepPurple,
      permissionName: null, pdfName: 'RptConsumoTigo',
      getFuture: () {
        ref.invalidate(jasperPdfFacturasTigoProvider(widget.periodoCobrado));
        return ref.read(jasperPdfFacturasTigoProvider(widget.periodoCobrado).future);
      },
    ),
    _ReporteItem(
      label: 'Líneas Corporativas', icon: Icons.description, color: Colors.teal.shade700,
      permissionName: 'btnReporteCambiosTigo', pdfName: 'RptCambiosTigo',
      getFuture: () {
        ref.invalidate(rptCambiosTigo(widget.periodoCobrado));
        return ref.read(rptCambiosTigo(widget.periodoCobrado).future);
      },
    ),
    _ReporteItem(
      label: 'Corporativos Personal', icon: Icons.people_outline, color: Colors.indigo,
      permissionName: 'btnRptCorporativosPersonal', pdfName: 'RptCorporativosPersonal',
      getFuture: () {
        ref.invalidate(rptCorporativosPersonal(widget.periodoCobrado));
        return ref.read(rptCorporativosPersonal(widget.periodoCobrado).future);
      },
    ),
    _ReporteItem(
      label: 'Comparación Empresas', icon: Icons.business_center_outlined, color: Colors.orange.shade800,
      permissionName: 'btnRptComparacionEmpresas', pdfName: 'RptComparacionEmpresas',
      getFuture: () {
        ref.invalidate(rptComparacionEmpresas);
        return ref.read(rptComparacionEmpresas.future);
      },
    ),
    // TODO: reemplaza label, icon, color, permissionName, pdfName y getFuture
    // _ReporteItem(
    //   label: 'Reporte Pendiente', icon: Icons.insert_chart_outlined, color: Colors.blueGrey,
    //   permissionName: 'btnRptPlantilla', pdfName: 'RptPlantilla',
    //   getFuture: () => Future.error('Reporte en construcción'),
    // ),
  ];

  // Método genérico único — reemplaza todos los _generarRptXxx()
  Future<void> _abrirReporte(_ReporteItem item) async {
    try {
      final bytes = await item.getFuture();
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: item.pdfName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.label}: $e')),
      );
      }
    }
  }

  // Helper: tile con PermissionWidget opcional
  Widget _buildReporteTile(_ReporteItem item, {VoidCallback? beforeOpen}) {
    final tile = _ReporteTile(
      icon: item.icon, label: item.label, color: item.color,
      onTap: () { beforeOpen?.call(); _abrirReporte(item); },
    );
    return item.permissionName == null
        ? tile
        : PermissionWidget(buttonName: item.permissionName!, child: tile);
  }

  // Mobile: BottomSheet
  void _mostrarMenuReportesMobile() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(children: [
                Icon(Icons.assessment, color: Colors.deepPurple),
                SizedBox(width: 10),
                Text('Reportes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(height: 1),
            ..._reportes.map((item) => _buildReporteTile(item, beforeOpen: () => Navigator.pop(context))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EJECUCIÓN DEL PERIODO (NUEVO PROVIDER)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _ejecutarProceso(ResumenDetalladoState state, ResumenDetalladoNotifier notifier) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar ejecución'),
        content: const Text('Una vez ejecutado no se podrá volver a ejecutar esta operación.\n¿Desea continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ejecutar')),
        ],
      ),
    );

    if (confirmar == true) {
      // // 1. Validar que no haya números "SIN ASIGNAR"
      // final dataList = state.mostrarEjecutado 
      //     ? ref.read(obtenerTigoEjecutado((state.empresaFiltro, widget.periodoCobrado))).asData?.value ?? []
      //     : ref.read(tigoArbolDetallado((state.empresaFiltro, widget.periodoCobrado))).asData?.value ?? [];

      // final tieneSinAsignar = dataList.any((r) => r.nombreCompleto.toUpperCase() == 'SIN ASIGNAR');
      // if (tieneSinAsignar) {
      //   AppSnackbarCustom.showError(context, 'No se puede ejecutar: Hay números sin asignar.');
      //   return;
      // }
      
      // 2. Llamar al nuevo método unificado del provider
      final audUsuario = await ref.read(userProvider.notifier).getCodUsuario();
      await notifier.ejecutarPeriodo(widget.periodoCobrado, audUsuario);
      ref.invalidate(facturasTigoProvider); // Para actualizar el estado global de facturas y reflejar el cambio en el botón ejecutar
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    // NUEVO ESTADO GLOBAL DE LA PANTALLA
    final state = ref.watch(resumenDetalladoProvider(widget.periodoCobrado));
    final notifier = ref.read(resumenDetalladoProvider(widget.periodoCobrado).notifier);

    // Listener para mostrar Snackbars basados en el nuevo provider
    ref.listen<ResumenDetalladoState>(resumenDetalladoProvider(widget.periodoCobrado), (previous, next) {
      if (next.mensajeError != null) {
        AppSnackbarCustom.showError(context, 'Error: ${next.mensajeError}');
        notifier.limpiarMensajes();
      }
      if (next.mensajeExito != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.mensajeExito!), backgroundColor: Colors.green),
        );
        notifier.limpiarMensajes();
      }
    });

    // Peticiones de datos
    final ejecutadoAsync = ref.watch(obtenerTigoEjecutado((state.empresaFiltro, widget.periodoCobrado)));
    final previewAsync = ref.watch(tigoArbolDetallado((state.empresaFiltro, widget.periodoCobrado)));
    final resumenDetalladoAsync = ref.watch(tigoResumenDetallado(widget.periodoCobrado));

    // Variable que decide qué árbol renderizar según el estado
    final asyncArbolData = state.mostrarEjecutado ? ejecutadoAsync : previewAsync;

    // Validación del botón ejecutar a nivel global (Si facturas dice que ya está)
    final facturasAsync = ref.watch(facturasTigoProvider);
    final bool yaEjecutadoGlobal = facturasAsync.maybeWhen(
      data: (facturas) => facturas.any((f) => f.periodoCobrado == widget.periodoCobrado && f.estado?.toUpperCase() == 'EJECUTADO'),
      orElse: () => false,
    );

    // ═══════════════════════════════════════════════════════════════════
    // --- LAYOUT MOBILE ---
    // ═══════════════════════════════════════════════════════════════════
    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Detalle de Facturas', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.blue[800],
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            _buildRefreshButtonResumen(
              onRefresh: () {
                ref.invalidate(tigoArbolDetallado((state.empresaFiltro, widget.periodoCobrado)));
                ref.invalidate(tigoResumenDetallado(widget.periodoCobrado));
              },
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionButton(icon: Icons.swap_horiz, label: 'Cambios', color: Colors.blueGrey[700]!, onPressed: _navegarCambiosLinea),
                  const SizedBox(width: 8),
                  _ActionButton(icon: Icons.sim_card_alert_outlined, label: 'Chips', color: Colors.orange[800]!, onPressed: _navegarChipsTigo),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.assessment,
                    label: 'Reportes',
                    color: Colors.deepPurple,
                    onPressed: _mostrarMenuReportesMobile,
                  ),
                  const SizedBox(width: 8),
                  PermissionWidget(
                    buttonName: 'btnEjecutarTigo',
                    child: _ActionButton(
                      icon: state.ejecutando ? Icons.hourglass_empty : Icons.play_circle_fill,
                      label: state.ejecutando ? 'PROCESANDO...' : 'EJECUTAR',
                      color: yaEjecutadoGlobal || state.ejecutando ? Colors.grey : Colors.red[700]!,
                      isPrimary: true,
                      onPressed: yaEjecutadoGlobal || state.ejecutando ? null : () => _ejecutarProceso(state, notifier),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              resumenDetalladoAsync.when(
                loading: () => const SizedBox(),
                error: (err, _) => const SizedBox(),
                data: (resumen) {
                  final empresas = resumen.map((e) => e.empresa ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
                  return empresas.isEmpty ? const SizedBox() : _buildEmpresaFiltro(empresas, state.empresaFiltro, (val) => notifier.setEmpresa(val));
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _buscadorController,
                decoration: InputDecoration(
                  hintText: 'Buscar nombre, teléfono...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) => notifier.setBuscador(val),
              ),
              const SizedBox(height: 10),
              if (state.mostrarEjecutado)
                Builder(
                  builder: (_) {
                    final lista = ejecutadoAsync.asData?.value ?? [];
                    final estadoStr = lista.isNotEmpty ? lista.first.estado : null;
                    return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: _buildEstadoPeriodo(estadoStr));
                  },
                ),
              resumenDetalladoAsync.when(
                loading: () => const SizedBox(),
                error: (err, _) => const SizedBox(),
                data: (resumen) {
                  if (resumen.isEmpty) return const SizedBox();
                  return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: _buildPeriodoCobradoPanel(resumen.first.periodoCobrado));
                },
              ),
              Expanded(
                child: asyncArbolData.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error al cargar datos: $err', style: const TextStyle(color: Colors.red))),
                  data: (arbol) {
                    final arbolFiltrado = filtrarArbolPorBuscador(arbol, state.buscadorTexto); // Empresa filtrada por provider
                    if (arbolFiltrado.isEmpty) return const Center(child: Text('No hay datos detallados.'));
                    return ListView.builder(
                      itemCount: arbolFiltrado.length,
                      itemBuilder: (context, index) => _buildMobileTreeNode(arbolFiltrado[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════════
    // --- LAYOUT DESKTOP/TABLET ---
    // ═══════════════════════════════════════════════════════════════════
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop() ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()) : null,
        title: const Text('Detalle de Facturas Tigo'),
        backgroundColor: Colors.blue[800],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _buildRefreshButtonResumen(
            onRefresh: () {
              ref.invalidate(tigoArbolDetallado((state.empresaFiltro, widget.periodoCobrado)));
              ref.invalidate(obtenerTigoEjecutado((state.empresaFiltro, widget.periodoCobrado)));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    resumenDetalladoAsync.when(
                      loading: () => const SizedBox(),
                      error: (err, _) => const SizedBox(),
                      data: (resumen) {
                        if (resumen.isEmpty) return const SizedBox();
                        return _buildPeriodoCobradoPanel(resumen.first.periodoCobrado);
                      },
                    ),
                    const SizedBox(width: 20),
                    if (state.mostrarEjecutado)
                      Builder(
                        builder: (_) {
                          final lista = ejecutadoAsync.asData?.value ?? [];
                          return _buildEstadoPeriodo(lista.isNotEmpty ? lista.first.estado : null);
                        },
                      ),
                    const Spacer(),
                    resumenDetalladoAsync.when(
                      loading: () => const SizedBox(),
                      error: (err, _) => const SizedBox(),
                      data: (resumen) {
                        final empresas = resumen.map((e) => e.empresa ?? '').where((e) => e.isNotEmpty).toSet().toList()..sort();
                        return empresas.isEmpty ? const SizedBox() : _buildEmpresaFiltro(empresas, state.empresaFiltro, (val) => notifier.setEmpresa(val));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // NUEVA BARRA HORIZONTAL
            _buildHorizontalActionsBar(state: state, yaEjecutadoGlobal: yaEjecutadoGlobal, notifier: notifier),
            
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _buscadorController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, teléfono o empresa...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (val) => notifier.setBuscador(val),
                      ),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: asyncArbolData.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Error al cargar datos: $err')),
                          data: (arbol) {
                            final arbolFiltrado = filtrarArbolPorBuscador(arbol, state.buscadorTexto); // Empresa filtrada por provider

                            return BosqueTreeTable<TigoEjecutadoEntity>(
                              items: arbolFiltrado,
                              idMapper: (e) => e.codEmpleado.toString(),
                              childrenMapper: (e) => e.items,
                              rowDecorationBuilder: _getTreeDecoration,
                              columns: _getDesktopColumns(mostrarEstado: state.mostrarEjecutado), // Renderizado dinámico
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WIDGETS AUXILIARES COMUNES Y LÓGICA DE FILTRADO
  // ═══════════════════════════════════════════════════════════════════

  BoxDecoration _getTreeDecoration(TigoEjecutadoEntity e, int index, int nivel) {
    final esSinAsignar = e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR';
    final isChild = nivel > 0;
    return BoxDecoration(
      color: esSinAsignar ? Colors.red[100] : isChild ? Colors.blue[50] : (index % 2 == 0 ? Colors.white : Colors.grey[200]),
      border: Border(
        left: (isChild && !esSinAsignar) ? BorderSide(color: Colors.blue[300]!, width: 4) : BorderSide.none,
        bottom: const BorderSide(color: Colors.grey, width: 0.5),
      ),
    );
  }

  List<BosqueTreeColumn<TigoEjecutadoEntity>> _getDesktopColumns({required bool mostrarEstado}) {
    return [
      BosqueTreeColumn(
        label: 'TELÉFONO', flex: 2,
        cellBuilder: (e, nivel) => Text(e.corporativo ?? '', style: TextStyle(color: e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR' ? Colors.red[700] : null)),
      ),
      BosqueTreeColumn(
        label: 'NOMBRE', flex: 4,
        cellBuilder: (e, nivel) {
          final nombre = e.nombreCompleto.startsWith('ZZZ') ? e.nombreCompleto.replaceFirst(RegExp(r'^ZZZ\s*'), '').trim() : e.nombreCompleto;
          final esSin = e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR';
          return Row(
            children: [
              if (esSin) const Icon(Icons.warning, color: Colors.red, size: 16),
              if (esSin) const SizedBox(width: 4),
              Expanded(child: Text(nombre, style: TextStyle(fontWeight: nivel == 0 ? FontWeight.bold : FontWeight.normal, color: esSin ? Colors.red[700] : Colors.black))),
            ],
          );
        },
      ),
      BosqueTreeColumn(
        label: 'DESCRIPCIÓN', flex: 3,
        cellBuilder: (e, nivel) => Text(e.descripcion, style: TextStyle(fontWeight: nivel == 0 ? FontWeight.bold : FontWeight.normal, color: e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR' ? Colors.red[700] : Colors.black)),
      ),
      BosqueTreeColumn(
        label: 'EMPRESA', flex: 2,
        cellBuilder: (e, nivel) => Text(e.empresa ?? '', style: TextStyle(color: e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR' ? Colors.red[700] : Colors.black)),
      ),
      if (mostrarEstado)
        BosqueTreeColumn(
          label: 'ESTADO', flex: 2,
          cellBuilder: (e, nivel) => Text(e.estado, style: TextStyle(color: e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR' ? Colors.red[700] : Colors.black)),
        ),
      BosqueTreeColumn(
        label: 'TOTAL', flex: 2, alignment: Alignment.centerRight,
        cellBuilder: (e, nivel) => Text(e.totalCobradoXCuenta.toStringAsFixed(2), style: TextStyle(color: e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR' ? Colors.red[700] : Colors.black)),
      ),
      BosqueTreeColumn(
        label: 'EMPRESA', flex: 2, alignment: Alignment.centerRight,
        cellBuilder: (e, nivel) => Text(e.montoCubiertoXEmpresa.toStringAsFixed(2), style: TextStyle(color: e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR' ? Colors.red[700] : Colors.black)),
      ),
      BosqueTreeColumn(
        label: 'EMPLEADO', flex: 2, alignment: Alignment.centerRight,
        cellBuilder: (e, nivel) => Text(e.montoEmpleado.toStringAsFixed(2), style: TextStyle(color: e.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR' ? Colors.red[700] : Colors.black)),
      ),
    ];
  }

  Widget _buildMobileTreeNode(TigoEjecutadoEntity nodo, {int nivel = 0}) {
    final esSinAsignar = nodo.nombreCompleto.trim().toUpperCase() == 'SIN ASIGNAR';
    final isTotal = nodo.nombreCompleto.trim().startsWith('ZZZ TOTAL');
    final nombre = nodo.nombreCompleto.replaceFirst(RegExp(r'^ZZZ\s*'), '').trim();

    if (nodo.items.isEmpty) {
      return Container(
        margin: EdgeInsets.only(left: nivel > 0 ? 16.0 : 0.0, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: esSinAsignar ? Colors.red[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: esSinAsignar ? Colors.red[200]! : Colors.grey[300]!),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          dense: true,
          title: Text(nombre, style: TextStyle(color: esSinAsignar ? Colors.red[800] : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nodo.corporativo != null && nodo.corporativo!.isNotEmpty) Text('Cel: ${nodo.corporativo}', style: const TextStyle(fontSize: 13)),
              Text('Desc: ${nodo.descripcion}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                'Tot: Bs ${nodo.totalCobradoXCuenta.toStringAsFixed(2)}  |  Emp: Bs ${nodo.montoCubiertoXEmpresa.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.indigo),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.only(left: nivel > 0 ? 16.0 : 0.0, top: 4, bottom: 4),
      elevation: nivel == 0 ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: esSinAsignar ? Colors.red[100] : (isTotal ? Colors.blue[100] : Colors.blue[50]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          title: Row(
            children: [
              if (esSinAsignar) const Icon(Icons.warning, color: Colors.red, size: 18),
              if (esSinAsignar) const SizedBox(width: 6),
              Expanded(child: Text(nombre, style: TextStyle(color: esSinAsignar ? Colors.red[900] : Colors.black, fontWeight: FontWeight.bold, fontSize: 15))),
            ],
          ),
          subtitle: Text(
            '${nodo.corporativo ?? ''} | Tot: Bs ${nodo.totalCobradoXCuenta.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[800]),
          ),
          children: nodo.items.map((hijo) => _buildMobileTreeNode(hijo, nivel: nivel + 1)).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpresaFiltro(List<String> empresas, String? empresaSeleccionada, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        value: empresaSeleccionada,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Filtrar por empresa',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todas las empresas')),
          ...empresas.map((empresa) => DropdownMenuItem(value: empresa, child: Text(empresa))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPeriodoCobradoPanel(String periodo) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
      decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month, color: Colors.blue),
          const SizedBox(width: 10),
          Text('Período cobrado: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 16)),
          Text(periodo, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEstadoPeriodo(String? estado) {
    if (estado == null) return const SizedBox();
    return Row(
      children: [
        const Icon(Icons.info, color: Colors.blue),
        const SizedBox(width: 8),
        Text('Estado del periodo: $estado', style: TextStyle(color: estado.toUpperCase() == 'EJECUTADO' ? Colors.green : Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildHorizontalActionsBar({required ResumenDetalladoState state, required bool yaEjecutadoGlobal, required ResumenDetalladoNotifier notifier}) {
    return Wrap(
      spacing: 12, runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ActionButton(icon: Icons.swap_horiz, label: 'Cambios de Línea', color: Colors.blueGrey[700]!, onPressed: _navegarCambiosLinea),
        PermissionWidget(
          buttonName: 'btnVistaChipsTigo',
          child: _ActionButton(icon: Icons.sim_card_alert_outlined, label: 'Chips Tigo', color: Colors.orange[800]!, onPressed: _navegarChipsTigo),
        ),
        Container(width: 1, height: 30, color: Colors.grey[300]),

        // ── Dropdown de reportes (desktop/web) ──
        MenuAnchor(
          menuChildren: _reportes.map((item) => _buildReporteTile(item)).toList(),
          builder: (ctx, controller, _) => _ActionButton(
            icon: Icons.assessment,
            label: 'Reportes',
            color: Colors.deepPurple,
            onPressed: () => controller.isOpen ? controller.close() : controller.open(),
          ),
        ),

        Container(width: 1, height: 30, color: Colors.grey[300]),
        PermissionWidget(
          buttonName: 'btnEjecutarTigo',
          child: _ActionButton(
            icon: state.ejecutando ? Icons.hourglass_empty : Icons.play_circle_fill,
            label: state.ejecutando ? 'PROCESANDO...' : 'EJECUTAR',
            color: yaEjecutadoGlobal || state.ejecutando ? Colors.grey : Colors.red[700]!,
            isPrimary: true,
            onPressed: yaEjecutadoGlobal || state.ejecutando ? null : () => _ejecutarProceso(state, notifier),
          ),
        ),
        if (yaEjecutadoGlobal || state.mostrarEjecutado)
          Padding(padding: const EdgeInsets.only(left: 12.0), child: Text('Este periodo ya fue ejecutado.', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildRefreshButtonResumen({required VoidCallback onRefresh, String tooltip = 'Refrescar datos'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: IconButton(icon: const Icon(Icons.refresh, color: Colors.white, size: 28), tooltip: tooltip, onPressed: onRefresh),
    );
  }

  List<TigoEjecutadoEntity> filtrarArbolPorEmpresa(List<TigoEjecutadoEntity> arbol, String? empresa) {
    List<TigoEjecutadoEntity> resultado = [];
    for (final nodo in arbol) {
      if (nodo.nombreCompleto.trim().startsWith('ZZZ TOTAL')) {
        resultado.add(nodo);
        continue;
      }
      if (empresa == null || empresa.trim().isEmpty || (nodo.empresa ?? '').trim() == empresa.trim()) {
        resultado.add(nodo.copyWith(items: filtrarArbolPorEmpresa(nodo.items, empresa)));
      } else {
        final hijosFiltrados = filtrarArbolPorEmpresa(nodo.items, empresa);
        if (hijosFiltrados.isNotEmpty) resultado.add(nodo.copyWith(items: hijosFiltrados));
      }
    }
    return resultado;
  }

  List<TigoEjecutadoEntity> filtrarArbolPorBuscador(List<TigoEjecutadoEntity> arbol, String textoBuscador) {
    if (textoBuscador.isEmpty) return arbol;
    List<TigoEjecutadoEntity> resultado = [];
    for (final nodo in arbol) {
      final coincide = nodo.nombreCompleto.toLowerCase().contains(textoBuscador) || (nodo.corporativo ?? '').toLowerCase().contains(textoBuscador) || (nodo.empresa ?? '').toLowerCase().contains(textoBuscador) || nodo.descripcion.toLowerCase().contains(textoBuscador);
      final hijosFiltrados = filtrarArbolPorBuscador(nodo.items, textoBuscador);
      if (coincide || hijosFiltrados.isNotEmpty) resultado.add(nodo.copyWith(items: hijosFiltrados));
    }
    return resultado;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({required this.icon, required this.label, required this.color, this.onPressed, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.white,
        foregroundColor: isPrimary ? Colors.white : color,
        side: BorderSide(color: color, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: isPrimary ? 3 : 0,
      ),
      onPressed: onPressed,
    );
  }
}
class _ReporteItem {
  final String label;
  final IconData icon;
  final Color color;
  final String? permissionName; // null = sin PermissionWidget
  final String pdfName;
  final Future<Uint8List> Function() getFuture;

  const _ReporteItem({
    required this.label, required this.icon, required this.color,
    required this.permissionName, required this.pdfName, required this.getFuture,
  });
}

// Tile reutilizado en BottomSheet y MenuAnchor
class _ReporteTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ReporteTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      trailing: Icon(Icons.picture_as_pdf, color: Colors.grey[400], size: 18),
      onTap: onTap,
    );
  }
}