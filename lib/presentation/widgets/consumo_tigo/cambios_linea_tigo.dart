import 'dart:async';

import 'package:bosque_flutter/core/state/consumo_tigo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/cambio_tigo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/consumo_tigo/form_cambios_linea_tigo.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CambiosLineaScreen extends ConsumerStatefulWidget {
  final String periodoCobrado;
  const CambiosLineaScreen({super.key, required this.periodoCobrado});

  @override
  ConsumerState<CambiosLineaScreen> createState() => _CambiosLineaScreenState();
}

class _CambiosLineaScreenState extends ConsumerState<CambiosLineaScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _buscadorController = TextEditingController();
  final TextEditingController _buscadorCambiosController =
      TextEditingController();
  Timer? _debounce;
  Timer? _debounceCambios;
  String? _tipoSocioFiltro; // null=TODOS, 'EMPLEADO', 'EXTERNO'
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _buscadorController.clear();
    _buscadorCambiosController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(cambiosTigoProvider.notifier);
      //notifier.setPeriodoCobrado(widget.periodoCobrado);
      notifier.cargarNumerosAsignados();
      //notifier.cargarCambiosRegistrados(periodoCobrado: widget.periodoCobrado);
      notifier.cargarPeriodos(widget.periodoCobrado);
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    _buscadorCambiosController.dispose();
    _debounce?.cancel();
    _debounceCambios?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<int> _getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  // ── Búsqueda con debounce — resetea a página 1 ──────────────────────
  void _onSearchChanged(String valor) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // setSearch ya resetea pagina: 1 y llama cargarNumerosAsignados
      ref.read(cambiosTigoProvider.notifier).setSearch(valor);
    });
  }

  // ── Búsqueda Historial con debounce — resetea a página 1 ──────────────────────
  void _onSearchCambiosChanged(String valor) {
    _debounceCambios?.cancel();
    _debounceCambios = Timer(const Duration(milliseconds: 500), () {
      ref.read(cambiosTigoProvider.notifier).setSearchCambios(valor);
    });
  }

  // ── Cambio de página Numeros─────────────────────────────────────────────────
  void _irAPaginaNumeros(int pagina) {
    ref.read(cambiosTigoProvider.notifier).setPaginaNumeros(pagina);
  }

  // ── Cambio de página Cambios─────────────────────────────────────────────────
  void _irAPaginaCambios(int pagina) {
    ref.read(cambiosTigoProvider.notifier).setPaginaCambios(pagina);
  }

  // ── Cambio de tamaño de página Numeros ──
  void _cambiarTamanoPaginaNumeros(int nuevo) {
    ref.read(cambiosTigoProvider.notifier).setTamanoPaginaNumeros(nuevo);
  }

  // ── Cambio de tamaño de página Cambios ──
  void _cambiarTamanoPaginaCambios(int nuevo) {
    ref.read(cambiosTigoProvider.notifier).setTamanoPaginaCambios(nuevo);
  }

  // ── Cambio de filtro tipoSocio — setTipoSocio ya llama cargarNumerosAsignados ──
  void _cambiarTipoSocio(String? valor) {
    setState(() => _tipoSocioFiltro = valor);
    ref.read(cambiosTigoProvider.notifier).setTipoSocio(valor);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cambiosTigoProvider);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final hPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final vPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    final pendientes =
        state.cambiosRegistrados.where((c) => c.estado == 'P').length;

    // Mostrar mensajes del SP
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mensajeExito != null) {
        AppSnackbarCustom.showAdd(context, state.mensajeExito!);
        ref.read(cambiosTigoProvider.notifier).limpiarMensajes();
      }
      if (state.mensajeError != null) {
        AppSnackbar.showError(context, state.mensajeError!);
        ref.read(cambiosTigoProvider.notifier).limpiarMensajes();
      }
      if (state.mensajeAdvertencia != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(state.mensajeAdvertencia!)),
              ],
            ),
            backgroundColor: Colors.orange[700],
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(cambiosTigoProvider.notifier).limpiarMensajes();
      }
    });

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text('Cambios de Líneas Corporativas'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () {
              ref.read(cambiosTigoProvider.notifier).cargarNumerosAsignados();
              ref.read(cambiosTigoProvider.notifier).cargarCambiosRegistrados();

              // Invalida el reporte para que la próxima vez que se abra, esté fresco
              if (state.periodoCobrado != null) {
                ref.invalidate(
                  rptCambioLineaTigoProvider(state.periodoCobrado!),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
            ),
            onPressed:
                (state.periodoCobrado == null)
                    ? null
                    : () async {
                      // 1. Limpiamos cualquier rastro del reporte para este periodo específico
                      ref.invalidate(
                        rptCambioLineaTigoProvider(state.periodoCobrado!),
                      );

                      await mostrarReportePdf(
                        context: context,
                        filename: 'RptCambios_${state.periodoCobrado}.pdf',
                        downloadFunction: () async {
                          // 2. Ejecutamos la petición fresca
                          return await ref.read(
                            rptCambioLineaTigoProvider(
                              state.periodoCobrado!,
                            ).future,
                          );
                        },
                      );
                    },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(icon: Icon(Icons.phone_android), text: 'Números'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 6),
                  const Text('Cambios'),
                  if (pendientes > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendientes',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   icon: const Icon(Icons.swap_horiz),
      //   label: Text(isMobile ? 'Nuevo' : 'Nuevo'), // Texto reducido
      //   backgroundColor: Colors.blue[700],
      //   onPressed: () => _mostrarFormulario(context),
      // ),
      // Solo se muestra si estamos en el Tab 0 (Números) y hay datos
      // bottomNavigationBar: (_tabController.index == 0 && !state.cargandoNumeros && state.numerosAsignados.isNotEmpty)
      //     ? SafeArea(
      //         child: _buildPaginador(state, hPadding, isMobile),
      //       )
      //     : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Lista unificada de números ──
          _buildTabNumeros(state, isMobile, hPadding, vPadding),
          // ── TAB 2: Historial de cambios ──
          _buildTabCambios(state, isMobile, hPadding, vPadding),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: NUMEROS ASIGNADOS
  // ═══════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: NUMEROS ASIGNADOS (REFACTORIZADO CON BOSQUE_FLAT_TABLE)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTabNumeros(
    CambiosTigoState state,
    bool isMobile,
    double hPadding,
    double vPadding,
  ) {
    //final notifier = ref.read(cambiosTigoProvider.notifier);

    return BosqueFlatTable<CambiosTigoEntity>(
      items: state.numerosAsignados,
      cargando: state.cargandoNumeros,
      searchHint: 'Buscar por nombre o teléfono...',
      searchController: _buscadorController,
      onSearch: _onSearchChanged,

      // -- PAGINACIÓN AUTOMÁTICA --
      currentPage:
          (!state.cargandoNumeros && state.numerosAsignados.isNotEmpty)
              ? state.paginaNumeros
              : null,
      totalPages:
          (!state.cargandoNumeros && state.numerosAsignados.isNotEmpty)
              ? (state.numerosAsignados.first.totalPaginas > 0
                  ? state.numerosAsignados.first.totalPaginas
                  : 1)
              : null,
      firstRow:
          (!state.cargandoNumeros && state.numerosAsignados.isNotEmpty)
              ? state.numerosAsignados.first.fila
              : null,
      lastRow:
          (!state.cargandoNumeros && state.numerosAsignados.isNotEmpty)
              ? state.numerosAsignados.last.fila
              : null,
      onPageChanged: _irAPaginaNumeros,
      currentPageSize: state.tamanoPaginaNumeros,
      onPageSizeChanged: _cambiarTamanoPaginaNumeros,

      // Filtros limpios sin Expanded ni ScrollView innecesarios
      extraFilters: [
        SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChipFiltro('TODOS', null),
                const SizedBox(width: 4),
                _buildChipFiltro('EMPLEADOS', 'EMPLEADO'),
                const SizedBox(width: 4),
                _buildChipFiltro('EXTERNOS', 'EXTERNO'),
                const SizedBox(width: 4),
                _buildChipFiltro('SIN ASIGNAR', 'SIN ASIGNAR'),
              ],
            ),
          ),
        ),
      ],

      // Columnas con anchos fijos donde es necesario para mantener la alineación
      columns: [
        BosqueColumn(
          label: '#',
          flex: 0,
          alignment: Alignment.center,
          cellBuilder:
              (e) => Text(
                e.fila > 0 ? '${e.fila}' : '-',
                style: TextStyle(color: Colors.blueGrey[400], fontSize: 12),
              ),
        ),
        BosqueColumn(
          label: 'Tipo',
          flex: 1,
          alignment: Alignment.center,
          cellBuilder: (e) => _buildChipTipoSocio(e.tipoSocio),
        ),
        BosqueColumn(
          label: 'Nombre',
          flex: 2,
          cellBuilder:
              (e) => Text(
                e.nombreCompleto.trim(),
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
        ),
        BosqueColumn(
          label: 'Teléfono',
          flex: 1,
          cellBuilder: (e) => Text(e.telefono),
        ),
        BosqueColumn(
          label: 'Descripción',
          flex: 1,
          cellBuilder:
              (e) => Text(
                e.descripcion.isNotEmpty ? e.descripcion : '-',
                overflow: TextOverflow.ellipsis,
              ),
        ),
        BosqueColumn(
          label: 'Estado',
          flex: 1,
          alignment: Alignment.center,
          cellBuilder:
              (e) =>
                  e.estado == 'P'
                      ? _buildChipPendiente(e.periodoCobrado)
                      : const Text('-'),
        ),
        BosqueColumn(
          label: 'Acciones',
          flex: 1,
          alignment: Alignment.center,
          cellBuilder: (e) {
            final esSinAsignar = e.tipoSocio == 'SIN ASIGNAR';
            return IconButton(
              icon: Icon(
                esSinAsignar ? Icons.person_add : Icons.swap_horiz,
                color: esSinAsignar ? Colors.orange[700] : Colors.blue[700],
              ),
              onPressed: () => _mostrarFormulario(context, item: e),
            );
          },
        ),
      ],
      mobileCardBuilder: (e) {
        final tienePendiente = e.estado == 'P';
        final esSinAsignar = e.tipoSocio == 'SIN ASIGNAR';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                tienePendiente
                    ? BorderSide(color: Colors.orange[300]!, width: 1.5)
                    : BorderSide.none,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  esSinAsignar
                      ? Colors.grey[200]
                      : (e.tipoSocio == 'EMPLEADO'
                          ? Colors.blue[100]
                          : Colors.green[100]),
              child: Icon(
                esSinAsignar
                    ? Icons.phone_disabled
                    : (e.tipoSocio == 'EMPLEADO'
                        ? Icons.person
                        : Icons.person_outline),
                color:
                    esSinAsignar
                        ? Colors.grey[600]
                        : (e.tipoSocio == 'EMPLEADO'
                            ? Colors.blue[800]
                            : Colors.green[800]),
              ),
            ),
            title: Text(
              e.nombreCompleto.trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📞 ${e.telefono}'),
                Text(e.descripcion.isNotEmpty ? e.descripcion : '-'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildChipTipoSocio(e.tipoSocio),
                    if (tienePendiente) _buildChipPendiente(e.periodoCobrado),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                esSinAsignar ? Icons.person_add : Icons.swap_horiz,
                color: esSinAsignar ? Colors.orange[700] : Colors.blue[700],
              ),
              onPressed: () => _mostrarFormulario(context, item: e),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipFiltro(String label, String? valor) {
    final seleccionado = _tipoSocioFiltro == valor;
    return FilterChip(
      label: Text(label),
      selected: seleccionado,
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[800],
      onSelected: (_) => _cambiarTipoSocio(valor),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: HISTORIAL DE CAMBIOS
  // ═══════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: HISTORIAL DE CAMBIOS (REFACTORIZADO CON BOSQUE_FLAT_TABLE)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTabCambios(
    CambiosTigoState state,
    bool isMobile,
    double hPadding,
    double vPadding,
  ) {
    return BosqueFlatTable<CambiosTigoEntity>(
      items: state.cambiosRegistrados,
      cargando: state.cargandoCambios,
      searchHint: 'Buscar por destino o teléfono...',
      searchController: _buscadorCambiosController,
      onSearch: _onSearchCambiosChanged,

      // -- PAGINACIÓN AUTOMÁTICA --
      currentPage:
          (!state.cargandoCambios && state.cambiosRegistrados.isNotEmpty)
              ? state.paginaCambios
              : null,
      totalPages:
          (!state.cargandoCambios && state.cambiosRegistrados.isNotEmpty)
              ? (state.cambiosRegistrados.first.totalPaginas > 0
                  ? state.cambiosRegistrados.first.totalPaginas
                  : 1)
              : null,
      firstRow:
          (!state.cargandoCambios && state.cambiosRegistrados.isNotEmpty)
              ? state.cambiosRegistrados.first.fila
              : null,
      lastRow:
          (!state.cargandoCambios && state.cambiosRegistrados.isNotEmpty)
              ? state.cambiosRegistrados.last.fila
              : null,
      onPageChanged: _irAPaginaCambios,
      currentPageSize: state.tamanoPaginaCambios,
      onPageSizeChanged: _cambiarTamanoPaginaCambios,

      extraFilters: [
        // --- 1. NUEVO: Dropdown de Período ---
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            value:
                state.periodosDisponibles.contains(state.periodoCobrado)
                    ? state.periodoCobrado
                    : (state.periodosDisponibles.isNotEmpty
                        ? state.periodosDisponibles.first
                        : null),
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Período',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items:
                state.periodosDisponibles
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
            onChanged: (nuevoPeriodo) {
              if (nuevoPeriodo != null) {
                ref
                    .read(cambiosTigoProvider.notifier)
                    .setPeriodoCobrado(nuevoPeriodo);
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // --- 2. MODIFICADO: Dropdown de Estado ---
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String?>(
            value: state.estadoFiltro,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'P', child: Text('Pendiente')),
              DropdownMenuItem(value: 'A', child: Text('Aplicado')),
            ],
            onChanged: (valor) {
              ref.read(cambiosTigoProvider.notifier).setEstadoFiltro(valor);
              // ELIMINADO: ref.read(...).cargarCambiosRegistrados(periodoCobrado: widget.periodoCobrado);
              // (Ya no es necesario, setEstadoFiltro lo llama automáticamente)
            },
          ),
        ),
        const SizedBox(width: 8),
        // Botón Aplicar
        state.aplicando
            ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
              label: const Text('Aplicar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Validación: No permitir aplicar si está seleccionado 'TODOS'
                if (state.periodoCobrado == 'TODOS' ||
                    state.periodoCobrado == null) {
                  AppSnackbar.showError(
                    context,
                    'Debe seleccionar un periodo específico (Ej: ${widget.periodoCobrado}) para aplicar cambios.',
                  );
                } else {
                  _confirmarAplicarCambios(context);
                }
              },
            ),
      ],

      columns: [
        BosqueColumn(
          label: '#',
          flex: 0,
          cellBuilder:
              (e) => Text(
                e.fila.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
        ),
        BosqueColumn(
          label: 'Período',
          flex: 1,
          alignment: Alignment.center,
          cellBuilder: (e) => Text(e.periodoCobrado),
        ),
        BosqueColumn(
          label: 'Teléfono',
          flex: 2,
          cellBuilder: (e) => Text(e.telefono),
        ),
        BosqueColumn(
          label: 'De (Origen)',
          flex: 3,
          cellBuilder:
              (e) => Text(
                e.nombreOrigen.isNotEmpty ? e.nombreOrigen : '-',
                overflow: TextOverflow.ellipsis,
              ),
        ),
        BosqueColumn(
          label: 'Destino',
          flex: 3,
          cellBuilder:
              (e) => Text(e.nombreCompleto, overflow: TextOverflow.ellipsis),
        ),
        BosqueColumn(
          label: 'Estado',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (e) {
            final esPendiente = e.estado == 'P';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: esPendiente ? Colors.orange[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                esPendiente ? 'Pendiente' : 'Aplicado',
                style: TextStyle(
                  color: esPendiente ? Colors.orange[800] : Colors.green[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            );
          },
        ),
        BosqueColumn(
          label: 'Acciones',
          flex: 2,
          alignment: Alignment.center,
          cellBuilder: (e) {
            if (e.estado != 'P') return const Text('-');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _mostrarFormulario(context, cambio: e),
                ),
                PermissionWidget(
                  buttonName:
                      'btnEliminarCambioTigo', // El nombre del botón en tu BD de permisos
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _confirmarEliminar(context, e),
                  ),
                ),
              ],
            );
          },
        ),
      ],

      mobileCardBuilder: (e) {
        final esPendiente = e.estado == 'P';
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: esPendiente ? Colors.orange : Colors.green,
              width: 1.5,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  esPendiente ? Colors.orange[100] : Colors.green[100],
              child: Icon(
                esPendiente ? Icons.pending : Icons.check_circle,
                color: esPendiente ? Colors.orange[800] : Colors.green[800],
              ),
            ),
            title: Text(
              e.nombreCompleto.trim(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📞 ${e.telefono} | Período: ${e.periodoCobrado}'),
                Text(e.descripcion.isNotEmpty ? e.descripcion : '-'),
                if (e.nombreOrigen.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Origen: ${e.nombreOrigen}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            trailing:
                esPendiente
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed:
                              () => _mostrarFormulario(context, cambio: e),
                        ),
                        PermissionWidget(
                          buttonName:
                              'btnEliminarCambioTigo', // El nombre del botón en tu BD de permisos
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => _confirmarEliminar(context, e),
                          ),
                        ),
                      ],
                    )
                    : null,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WIDGETS AUXILIARES
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildChipTipoSocio(String tipo) {
    final esEmpleado = tipo == 'EMPLEADO';
    final esSinAsignar = tipo == 'SIN ASIGNAR';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            esSinAsignar
                ? Colors.grey[100]
                : esEmpleado
                ? Colors.blue[50]
                : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              esSinAsignar
                  ? Colors.grey[400]!
                  : esEmpleado
                  ? Colors.blue[300]!
                  : Colors.green[300]!,
        ),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 11,
          color:
              esSinAsignar
                  ? Colors.grey[700]
                  : esEmpleado
                  ? Colors.blue[800]
                  : Colors.green[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChipPendiente(String periodo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pending, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            'P | $periodo',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════════════

  void _mostrarFormulario(
    BuildContext context, {
    CambiosTigoEntity? item,
    CambiosTigoEntity? cambio,
  }) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 650),
              child: SingleChildScrollView(
                child: FormularioCambioLinea(
                  // Usamos el periodo del state, pero si es 'TODOS', usamos el del widget como respaldo
                  periodoCobrado:
                      (ref.read(cambiosTigoProvider).periodoCobrado == 'TODOS')
                          ? widget.periodoCobrado
                          : (ref.read(cambiosTigoProvider).periodoCobrado ??
                              widget.periodoCobrado),
                  origenItem: item,
                  cambioEditar: cambio,
                  onSave: (entity) async {
                    final audUsuario = await _getCodUsuario();
                    bool ok;
                    if (item?.tipoSocio == 'SIN ASIGNAR') {
                      // Asignacion inmediata sin pendiente
                      ok = await ref
                          .read(cambiosTigoProvider.notifier)
                          .asignarNumeroSinAsignar(entity, audUsuario);
                    } else {
                      // Cambio pendiente normal
                      ok = await ref
                          .read(cambiosTigoProvider.notifier)
                          .registrarCambio(entity, audUsuario);
                    }
                    if (ok && ctx.mounted) Navigator.of(ctx).pop();
                  },
                  onCancel: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ),
    );
  }

  void _confirmarEliminar(
    BuildContext context,
    CambiosTigoEntity cambio,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Eliminar Cambio'),
              ],
            ),
            content: Text(
              '¿Eliminar el cambio del número ${cambio.telefono} '
              'programado para ${cambio.periodoCobrado}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      final audUsuario = await _getCodUsuario();
      if (!mounted) return;
      await ref
          .read(cambiosTigoProvider.notifier)
          .eliminarCambio(cambio.codCambio, audUsuario);
    }
  }

  void _confirmarAplicarCambios(BuildContext context) async {
    final state = ref.read(cambiosTigoProvider);

    // 1. DETERMINAR EL PERIODO ACTIVO
    // Priorizamos el del state (el del dropdown). Si es 'TODOS', no permitimos aplicar.
    final periodoActivo = state.periodoCobrado;

    if (periodoActivo == 'TODOS' || periodoActivo == null) {
      AppSnackbar.showError(
        context,
        'Seleccione un período específico en el filtro para poder aplicar los cambios.',
      );
      return;
    }

    final pendientes =
        state.cambiosRegistrados.where((c) => c.estado == 'P').length;

    if (pendientes == 0) {
      AppSnackbar.showError(
        context,
        'No hay cambios pendientes para aplicar en el período $periodoActivo.',
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.play_arrow, color: Colors.green),
                SizedBox(width: 8),
                Text('Aplicar Cambios'),
              ],
            ),
            content: Text(
              'Se aplicarán $pendientes cambio(s) pendiente(s) '
              'para el período $periodoActivo.\n\n' // <-- USAMOS EL ACTIVO
              'Esta acción actualizará los titulares de las líneas corporativas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Aplicar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      final audUsuario = await _getCodUsuario();
      if (!mounted) return;

      // 2. ENVIAMOS EL PERIODO DEL STATE AL NOTIFIER
      await ref
          .read(cambiosTigoProvider.notifier)
          .aplicarCambios(periodoActivo, audUsuario);
    }
  }
}
