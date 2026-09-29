/// Garantias de cobranza: la pantalla principal del modulo (tablas tcbr_).
///
/// Reemplaza a `tcbrGarantia/garantia.xhtml` (tb_vista codVista 45). La grilla
/// es la misma idea que la del sistema anterior —una fila por cliente con sus
/// montos vigentes contra la linea de SAP— con tres cambios:
///
/// - **La fila que no cuadra con SAP dice por que.** El legacy la pintaba de
///   rojo sin explicacion; aca se marca con el color de aviso, la linea de SAP
///   lleva un icono y el tooltip da las dos cifras.
/// - **El vencimiento se lee como plazo**, no como fecha: «Faltan 12 días» en
///   vez de una fecha y dos iconos que habia que interpretar.
/// - **Se puede filtrar** por lo que importa en cobranza: clientes con
///   vigentes, los que vencen en 30 dias y los que no cuadran con SAP.
///
/// Todo lo que escribe vive en los paneles de `widgets/garantias/`; esta
/// pantalla solo lista, filtra y abre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/detalle_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/dialogos_garantias.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/formularios_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/garantias_cliente.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/vista_por_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO LOCAL DE LA PANTALLA
//
// autoDispose y aqui, no en garantias_provider.dart: son de esta grilla. Al
// salir del modulo se reinician y una visita no le deja la pagina 4 a la otra.
// ═══════════════════════════════════════════════════════════════════════════

/// Como se lista: una fila por cliente (sus garantias vigentes sumadas) o una
/// por garantia (con filtro entre fechas, ver VistaPorGarantia).
enum _Modo { porCliente, porGarantia }

final _modoProvider = StateProvider.autoDispose<_Modo>(
  (ref) => _Modo.porCliente,
);

/// Que clientes se muestran.
enum _Vista { todos, conVigentes, porVencer, distintaDeSap }

final _vistaProvider = StateProvider.autoDispose<_Vista>((ref) => _Vista.todos);
final _busquedaProvider = StateProvider.autoDispose<String>((ref) => '');
final _paginaProvider = StateProvider.autoDispose<int>((ref) => 0);
final _filasPorPaginaProvider = StateProvider.autoDispose<int>((ref) => 25);

bool _pasaVista(GarantiaResumenClienteEntity c, _Vista v) => switch (v) {
  _Vista.todos => true,
  _Vista.conVigentes => !c.sinVigentes,
  _Vista.porVencer => c.porVencer,
  _Vista.distintaDeSap => c.difiereDeSap,
};

// ═══════════════════════════════════════════════════════════════════════════
// LA PANTALLA
// ═══════════════════════════════════════════════════════════════════════════

class GarantiasScreen extends ConsumerStatefulWidget {
  const GarantiasScreen({super.key});

  @override
  ConsumerState<GarantiasScreen> createState() => _GarantiasScreenState();
}

class _GarantiasScreenState extends ConsumerState<GarantiasScreen> {
  final _buscarCtrl = TextEditingController();

  /// En el telefono los filtros de vista van plegados.
  bool _filtrosAbiertos = false;

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _recargar() {
    ref.invalidate(resumenClientesProvider);
    ref.invalidate(traspasosPendientesProvider);
  }

  void _limpiarFiltros() {
    _buscarCtrl.clear();
    ref.read(_busquedaProvider.notifier).state = '';
    ref.read(_vistaProvider.notifier).state = _Vista.todos;
    ref.read(_paginaProvider.notifier).state = 0;
  }

  Future<void> _nueva({GarantiaResumenClienteEntity? cliente}) async {
    final id = await abrirAltaGarantia(
      context,
      cliente:
          cliente == null
              ? null
              : ClienteSapEntity(
                codClienteSAP: cliente.codClienteSAP,
                datoCliente: cliente.datoCliente,
              ),
    );
    // Recien creada: se abre su detalle, que es donde se sigue trabajando
    // (acciones, recibo). La grilla ya se refresco con la escritura.
    if (id != null && mounted) await abrirDetalleGarantia(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final resumen = ref.watch(resumenClientesProvider);
    final busqueda = ref.watch(_busquedaProvider);
    final vista = ref.watch(_vistaProvider);

    // Los permisos llegan por red despues del primer dibujo: se observan para
    // que los botones aparezcan cuando llegan.
    ref.watch(buttonPermissionsProvider);
    final permisos = _Permisos(
      nueva: tienePermisoDeBoton(ref, BtnGarantias.nueva),
      traspaso: tienePermisoDeBoton(ref, BtnGarantias.traspaso),
      reporte: tienePermisoDeBoton(ref, BtnGarantias.reporte),
      verCliente: tienePermisoDeBoton(ref, BtnGarantias.verCliente),
    );

    // Se observa para mantener vivo el notifier de escrituras mientras la
    // pantalla existe: los paneles lo leen y su error no debe perderse entre
    // un dialogo y otro.
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((e) => e.ocupado),
    );
    final pendientes =
        permisos.traspaso
            ? ref.watch(traspasosPendientesProvider).valueOrNull
            : null;

    final modo = ref.watch(_modoProvider);

    // GarantiasScope: tipografia y colores de estado del modulo (ver
    // GarantiasTema). Los paneles lo reciben tambien, desde abrirPanel.
    return GarantiasScope(
      child: Scaffold(
        body: LayoutBuilder(
          // El ancho del cajon, no el de la ventana: el menu lateral se come su
          // parte y MediaQuery lo contaria como disponible.
          builder: (context, restricciones) {
            final aire = Aire.de(restricciones.maxWidth);

            Widget cabecera(List<GarantiaResumenClienteEntity> todos) =>
                _Cabecera(
                  aire: aire,
                  clientes: todos,
                  permisos: permisos,
                  pendientesTraspaso: pendientes,
                  cargando: resumen.isLoading,
                  onRecargar: _recargar,
                  onNueva: () => _nueva(),
                  onTraspaso: () => abrirTraspaso(context),
                  onReporte: () => abrirReporte(context, todos),
                );

            return resumen.when(
              skipLoadingOnRefresh: true,
              loading:
                  () => Column(
                    children: [
                      cabecera(const []),
                      const Expanded(child: EsqueletoLista(altoFila: 64)),
                    ],
                  ),
              error:
                  (e, _) => Column(
                    children: [
                      cabecera(const []),
                      Expanded(
                        child: MensajeError(error: e, onReintentar: _recargar),
                      ),
                    ],
                  ),
              data: (todos) {
                final visibles =
                    todos
                        .where((c) => c.coincideCon(busqueda))
                        .where((c) => _pasaVista(c, vista))
                        .toList();

                // «Por garantía» lee /garantias/listar, que exige el mismo boton
                // que ver las garantias de un cliente.
                final porGarantia =
                    modo == _Modo.porGarantia && permisos.verCliente;

                return Column(
                  children: [
                    cabecera(todos),
                    if (permisos.verCliente)
                      _SelectorModo(
                        aire: aire,
                        modo: modo,
                        clientes: todos.length,
                        garantias: todos.fold<int>(
                          0,
                          (s, c) => s + c.cantGarantias,
                        ),
                        onModo:
                            (m) => ref.read(_modoProvider.notifier).state = m,
                      ),
                    if (porGarantia)
                      Expanded(child: VistaPorGarantia(aire: aire))
                    else ...[
                      _BarraFiltros(
                        aire: aire,
                        buscarCtrl: _buscarCtrl,
                        vista: vista,
                        todos: todos,
                        abiertos: _filtrosAbiertos,
                        onAbrir:
                            () => setState(
                              () => _filtrosAbiertos = !_filtrosAbiertos,
                            ),
                        onBuscar: (t) {
                          ref.read(_busquedaProvider.notifier).state = t;
                          ref.read(_paginaProvider.notifier).state = 0;
                        },
                        onVista: (v) {
                          ref.read(_vistaProvider.notifier).state = v;
                          ref.read(_paginaProvider.notifier).state = 0;
                        },
                      ),
                      SizedBox(
                        height: 2,
                        child:
                            ocupado
                                ? const LinearProgressIndicator(minHeight: 2)
                                : null,
                      ),
                      Expanded(
                        child: _Listado(
                          aire: aire,
                          filas: visibles,
                          totalSinFiltrar: todos.length,
                          hayFiltro:
                              busqueda.trim().isNotEmpty ||
                              vista != _Vista.todos,
                          permisos: permisos,
                          onVer: (c) => abrirGarantiasCliente(context, c),
                          onNueva: (c) => _nueva(cliente: c),
                          onLimpiarFiltros: _limpiarFiltros,
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Lo que el usuario puede hacer en esta pantalla, resuelto una vez por
/// dibujo con los botones de la vista 45.
@immutable
class _Permisos {
  const _Permisos({
    required this.nueva,
    required this.traspaso,
    required this.reporte,
    required this.verCliente,
  });

  final bool nueva;
  final bool traspaso;
  final bool reporte;
  final bool verCliente;
}

/// Selector de vista. Cada opcion dice cuantas filas trae, asi se sabe que se
/// va a mirar antes de cambiar.
class _SelectorModo extends StatelessWidget {
  const _SelectorModo({
    required this.aire,
    required this.modo,
    required this.clientes,
    required this.garantias,
    required this.onModo,
  });

  final Aire aire;
  final _Modo modo;
  final int clientes;
  final int garantias;
  final ValueChanged<_Modo> onModo;

  @override
  Widget build(BuildContext context) {
    final chico = aire == Aire.justo;
    final selector = SegmentedButton<_Modo>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: _Modo.porCliente,
          icon: chico ? null : const Icon(Icons.groups_2_outlined, size: 18),
          label: Text(chico ? 'Por cliente' : 'Por cliente · $clientes'),
        ),
        ButtonSegment(
          value: _Modo.porGarantia,
          icon: chico ? null : const Icon(Icons.description_outlined, size: 18),
          label: Text(chico ? 'Por garantía' : 'Por garantía · $garantias'),
        ),
      ],
      selected: {modo},
      onSelectionChanged: (s) => onModo(s.first),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        chico ? Esp.m : Esp.xl,
        Esp.m,
        chico ? Esp.m : Esp.xl,
        0,
      ),
      child:
          chico
              ? SizedBox(width: double.infinity, child: selector)
              : Align(alignment: Alignment.centerLeft, child: selector),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA
// ═══════════════════════════════════════════════════════════════════════════

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.aire,
    required this.clientes,
    required this.permisos,
    required this.pendientesTraspaso,
    required this.cargando,
    required this.onRecargar,
    required this.onNueva,
    required this.onTraspaso,
    required this.onReporte,
  });

  final Aire aire;
  final List<GarantiaResumenClienteEntity> clientes;
  final _Permisos permisos;

  /// Garantias que esperan el traspaso; null si no se consulto.
  final int? pendientesTraspaso;

  final bool cargando;
  final VoidCallback onRecargar;
  final VoidCallback onNueva;
  final VoidCallback onTraspaso;
  final VoidCallback onReporte;

  String _resumen() {
    if (clientes.isEmpty) return 'Garantías de los clientes, con su plazo';
    final vigentes = clientes.fold<int>(0, (s, c) => s + c.cantVigentes);
    final porVencer = clientes.where((c) => c.porVencer).length;
    final partes = [
      '${clientes.length} ${clientes.length == 1 ? "cliente" : "clientes"}',
      '$vigentes ${vigentes == 1 ? "garantía vigente" : "garantías vigentes"}',
      if (porVencer > 0)
        '$porVencer ${porVencer == 1 ? "vence" : "vencen"} en 30 días o menos',
    ];
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chico = aire == Aire.justo;
    final n = pendientesTraspaso ?? 0;

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Garantías de cobranza',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: Esp.xs),
        Text(_resumen(), style: context.apagado()),
      ],
    );

    final progreso =
        cargando
            ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: Esp.m),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
            : null;

    final recargar = IconButton(
      onPressed: onRecargar,
      icon: const Icon(Icons.refresh),
      tooltip: 'Actualizar',
    );

    final List<Widget> acciones;
    if (chico) {
      // Telefono: la accion principal a la vista y lo demas en el menu.
      acciones = [
        if (progreso != null) progreso,
        recargar,
        // Siempre presente: aunque no tenga Traspaso ni Reporte, la guia
        // tiene que estar a mano en el telefono.
        MenuAcciones(
          aviso: permisos.traspaso && n > 0,
          opciones: [
            OpcionMenu(
              '¿Cómo funciona?',
              Icons.help_outline,
              () => mostrarGuiaGarantias(context),
            ),
            if (permisos.traspaso)
              OpcionMenu(
                'Traspaso a custodia',
                Icons.move_to_inbox_outlined,
                onTraspaso,
                detalle: n > 0 ? '$n pendientes' : null,
              ),
            if (permisos.reporte)
              OpcionMenu(
                'Reporte en PDF',
                Icons.picture_as_pdf_outlined,
                onReporte,
              ),
          ],
        ),
        if (permisos.nueva)
          IconButton.filled(
            onPressed: onNueva,
            icon: const Icon(Icons.add),
            tooltip: 'Nueva garantía',
          ),
      ];
    } else {
      acciones = [
        if (progreso != null) progreso,
        // Con texto en escritorio amplio; solo el icono en tablet, donde el
        // texto no entraba junto a los otros botones.
        if (aire == Aire.amplio)
          const BotonGuia()
        else
          IconButton(
            onPressed: () => mostrarGuiaGarantias(context),
            icon: const Icon(Icons.help_outline),
            tooltip: '¿Cómo funciona?',
          ),
        recargar,
        const SizedBox(width: Esp.s),
        if (permisos.traspaso)
          Padding(
            padding: const EdgeInsets.only(right: Esp.s),
            child: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: OutlinedButton.icon(
                onPressed: onTraspaso,
                icon: const Icon(Icons.move_to_inbox_outlined, size: 18),
                label: const Text('Traspaso'),
              ),
            ),
          ),
        if (permisos.reporte)
          Padding(
            padding: const EdgeInsets.only(right: Esp.s),
            child: OutlinedButton.icon(
              onPressed: onReporte,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Reporte'),
            ),
          ),
        if (permisos.nueva)
          FilledButton.icon(
            onPressed: onNueva,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva garantía'),
          ),
      ];
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        chico ? Esp.m : Esp.xl,
        Esp.l,
        chico ? Esp.s : Esp.xl,
        Esp.m,
      ),
      color: cs.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titulo),
          if (chico)
            Row(mainAxisSize: MainAxisSize.min, children: acciones)
          else ...[
            const SizedBox(width: Esp.m),
            // Wrap y no Row: si los botones no entran en una linea bajan a la
            // siguiente. Con Row desbordaban y aplastaban el titulo hasta
            // dejarlo en una letra por linea.
            Flexible(
              flex: 2,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: Esp.s,
                children: acciones,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTROS
// ═══════════════════════════════════════════════════════════════════════════

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.aire,
    required this.buscarCtrl,
    required this.vista,
    required this.todos,
    required this.abiertos,
    required this.onAbrir,
    required this.onBuscar,
    required this.onVista,
  });

  final Aire aire;
  final TextEditingController buscarCtrl;
  final _Vista vista;
  final List<GarantiaResumenClienteEntity> todos;
  final bool abiertos;
  final VoidCallback onAbrir;
  final ValueChanged<String> onBuscar;
  final ValueChanged<_Vista> onVista;

  @override
  Widget build(BuildContext context) {
    final chico = aire == Aire.justo;

    final buscador = TextField(
      controller: buscarCtrl,
      onChanged: onBuscar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Código o nombre del cliente',
        prefixIcon: const Icon(Icons.search, size: 20),
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon:
            buscarCtrl.text.isEmpty
                ? null
                : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Limpiar',
                  onPressed: () {
                    buscarCtrl.clear();
                    onBuscar('');
                  },
                ),
      ),
    );

    int cuantos(_Vista v) => todos.where((c) => _pasaVista(c, v)).length;
    final chips = Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        for (final (v, texto, ayuda) in const [
          (_Vista.todos, 'Todos', 'Todos los clientes con garantías.'),
          (
            _Vista.conVigentes,
            'Con vigentes',
            'Clientes con al menos una garantía dentro de su plazo.',
          ),
          (
            _Vista.porVencer,
            'Vencen en 30 días',
            'Clientes con una garantía vigente que vence en 30 días o menos: '
                'las que hay que renovar o extender.',
          ),
          (
            _Vista.distintaDeSap,
            'Distinta de SAP',
            'Clientes cuya línea aprobada por garantías no coincide con la '
                'línea de crédito en SAP. En la lista aparecen resaltados.',
          ),
        ])
          ChoiceChip(
            label: Text('$texto (${cuantos(v)})'),
            tooltip: ayuda,
            selected: vista == v,
            onSelected: (_) => onVista(v),
          ),
      ],
    );

    final margen = EdgeInsets.fromLTRB(
      chico ? Esp.m : Esp.xl,
      Esp.m,
      chico ? Esp.m : Esp.xl,
      Esp.m,
    );

    if (chico) {
      // Telefono: el buscador siempre a mano y la vista plegada detras de un
      // boton que avisa si hay una elegida.
      return Padding(
        padding: margen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: buscador),
                const SizedBox(width: Esp.s),
                IconButton(
                  tooltip: abiertos ? 'Ocultar filtros' : 'Mostrar filtros',
                  onPressed: onAbrir,
                  isSelected: abiertos,
                  icon: Badge(
                    isLabelVisible: vista != _Vista.todos,
                    child: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child:
                  abiertos
                      ? Padding(
                        padding: const EdgeInsets.only(top: Esp.m),
                        child: chips,
                      )
                      : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: margen,
      child:
          aire == Aire.amplio
              ? Row(
                children: [
                  SizedBox(width: 360, child: buscador),
                  const SizedBox(width: Esp.l),
                  Expanded(child: chips),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [buscador, const SizedBox(height: Esp.m), chips],
              ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTADO
// ═══════════════════════════════════════════════════════════════════════════

class _Listado extends ConsumerWidget {
  const _Listado({
    required this.aire,
    required this.filas,
    required this.totalSinFiltrar,
    required this.hayFiltro,
    required this.permisos,
    required this.onVer,
    required this.onNueva,
    required this.onLimpiarFiltros,
  });

  final Aire aire;
  final List<GarantiaResumenClienteEntity> filas;
  final int totalSinFiltrar;
  final bool hayFiltro;
  final _Permisos permisos;
  final ValueChanged<GarantiaResumenClienteEntity> onVer;
  final ValueChanged<GarantiaResumenClienteEntity> onNueva;
  final VoidCallback onLimpiarFiltros;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filas.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: MensajeVacio(
              icono: hayFiltro ? Icons.filter_alt_off : Icons.inbox_outlined,
              titulo:
                  hayFiltro
                      ? 'Ningún cliente coincide con el filtro'
                      : 'Todavía no hay garantías registradas',
              detalle:
                  hayFiltro
                      ? 'Hay $totalSinFiltrar clientes con garantías, pero '
                          'ninguno coincide. Pruebe con otro código o nombre, '
                          'o quite el filtro.'
                      : 'Registre la primera con «Nueva garantía».',
            ),
          ),
          if (hayFiltro)
            Padding(
              padding: const EdgeInsets.only(bottom: Esp.xxl),
              child: TextButton.icon(
                onPressed: onLimpiarFiltros,
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Quitar filtros'),
              ),
            ),
        ],
      );
    }

    final padding = EdgeInsets.symmetric(
      horizontal: aire == Aire.justo ? Esp.m : Esp.xl,
    );

    // Tarjetas mientras no entre la planilla: la tabla de ocho columnas pide
    // unos mil pixeles de cajon.
    if (aire != Aire.amplio) {
      return ListView.separated(
        padding: padding.copyWith(top: Esp.xs, bottom: Esp.xxl),
        itemCount: filas.length,
        separatorBuilder: (_, _) => const SizedBox(height: Esp.s),
        itemBuilder:
            (context, i) => _TarjetaCliente(
              n: i + 1,
              c: filas[i],
              permisos: permisos,
              onVer: onVer,
              onNueva: onNueva,
            ),
      );
    }

    final porPagina = ref.watch(_filasPorPaginaProvider);
    final totalPaginas = (filas.length / porPagina).ceil();
    // Se ajusta en vez de reventar: al filtrar, la pagina mirada puede dejar
    // de existir.
    final elegida = ref.watch(_paginaProvider);
    final pagina = elegida.clamp(0, totalPaginas - 1);
    final desde = pagina * porPagina;
    final hasta =
        desde + porPagina > filas.length ? filas.length : desde + porPagina;

    return Column(
      children: [
        Expanded(
          child: _TablaClientes(
            filas: filas.sublist(desde, hasta),
            primerNumero: desde + 1,
            permisos: permisos,
            padding: padding,
            onVer: onVer,
          ),
        ),
        PaginadorTabla(
          padding: padding,
          sustantivo: filas.length == 1 ? 'cliente' : 'clientes',
          primera: desde + 1,
          ultima: hasta,
          total: filas.length,
          pagina: pagina,
          totalPaginas: totalPaginas,
          porPagina: porPagina,
          onPagina: (p) => ref.read(_paginaProvider.notifier).state = p,
          onPorPagina: (n) {
            ref.read(_filasPorPaginaProvider.notifier).state = n;
            ref.read(_paginaProvider.notifier).state = 0;
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ESCRITORIO: PLANILLA
// ═══════════════════════════════════════════════════════════════════════════

/// Columnas de la planilla: termino del [Glosario], flex y alineacion. Las
/// cifras van a la derecha, con digitos tabulares, para que se comparen de un
/// vistazo. Cada encabezado lleva su ⓘ con la explicacion; «Cliente» no la
/// necesita.
const List<(Termino, int, bool)> _columnas = [
  ((nombre: 'Cliente', ayuda: ''), 6, false),
  (Glosario.vigentes, 2, false),
  (Glosario.valorVigente, 3, true),
  (Glosario.lineaVigente, 3, true),
  (Glosario.lineaSap, 3, true),
  (Glosario.saldoSap, 3, true),
  (Glosario.proximoVencimiento, 3, false),
];

/// Solo la flecha: «Nueva garantía para este cliente» vive en su panel. Antes
/// cada fila repetia un «+» y una flecha, ruido en veinte filas iguales.
const double _anchoAcciones = 40;

const double _anchoNumero = 40;

class _TablaClientes extends StatelessWidget {
  const _TablaClientes({
    required this.filas,
    required this.primerNumero,
    required this.permisos,
    required this.padding,
    required this.onVer,
  });

  final List<GarantiaResumenClienteEntity> filas;

  /// Numero de la primera fila de la pagina en la lista filtrada.
  final int primerNumero;
  final _Permisos permisos;
  final EdgeInsets padding;
  final ValueChanged<GarantiaResumenClienteEntity> onVer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estiloEncabezado = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final cabecera = Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _anchoNumero,
            child: Text('#', style: estiloEncabezado),
          ),
          for (final (termino, flex, derecha) in _columnas)
            Expanded(
              flex: flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
                child:
                    termino.ayuda.isEmpty
                        ? Text(
                          termino.nombre,
                          textAlign: derecha ? TextAlign.end : TextAlign.start,
                          style: estiloEncabezado,
                        )
                        : Align(
                          alignment:
                              derecha
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: EtiquetaConAyuda(
                            termino,
                            estilo: estiloEncabezado,
                            alDerecha: derecha,
                          ),
                        ),
              ),
            ),
          const SizedBox(width: _anchoAcciones),
        ],
      ),
    );

    return Padding(
      padding: padding,
      child: Column(
        children: [
          cabecera,
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: Esp.s),
              itemCount: filas.length,
              itemBuilder:
                  (context, i) => _FilaCliente(
                    n: primerNumero + i,
                    c: filas[i],
                    permisos: permisos,
                    onVer: onVer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCliente extends StatelessWidget {
  const _FilaCliente({
    required this.n,
    required this.c,
    required this.permisos,
    required this.onVer,
  });

  final int n;
  final GarantiaResumenClienteEntity c;
  final _Permisos permisos;
  final ValueChanged<GarantiaResumenClienteEntity> onVer;

  Widget _celda(int flex, Widget hijo, {bool derecha = false}) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.xs),
      child: Align(
        alignment: derecha ? Alignment.centerRight : Alignment.centerLeft,
        child: hijo,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final marcada = c.difiereDeSap;
    // Sin vigentes, las sumas son 0 por definicion: «—» dice «no hay» sin
    // llenar la fila de ceros que compiten con las cifras reales.
    final sinVig = c.sinVigentes;

    return Container(
      decoration: BoxDecoration(
        // La fila que no cuadra con SAP: una franja ambar a la izquierda. Antes
        // tenia ademas un fondo celeste que se leia como «fila seleccionada».
        border: Border(
          left: BorderSide(
            color:
                marcada
                    ? GarantiasColores.pleno(context, Semantica.aviso)
                    : Colors.transparent,
            width: 3,
          ),
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      child: InkWell(
        onTap: permisos.verCliente ? () => onVer(c) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.m - 3,
            vertical: Esp.s,
          ),
          child: Row(
            children: [
              NumeroFila(n, ancho: _anchoNumero),
              _celda(
                _columnas[0].$2,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.datoCliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      c.codClienteSAP,
                      style: context.cifra(color: cs.onSurfaceVariant, tam: 11),
                    ),
                  ],
                ),
              ),
              _celda(
                _columnas[1].$2,
                Text(
                  '${c.cantVigentes} de ${c.cantGarantias}',
                  style: context.cifra(
                    color: sinVig ? cs.onSurfaceVariant : null,
                  ),
                ),
              ),
              _celda(
                _columnas[2].$2,
                Text(
                  sinVig ? '—' : monto(c.montoGarantia),
                  style: context.cifra(
                    color: sinVig ? cs.onSurfaceVariant : null,
                  ),
                ),
                derecha: true,
              ),
              _celda(
                _columnas[3].$2,
                Text(
                  sinVig ? '—' : monto(c.montoCredito),
                  style: context.cifra(
                    fuerte: !sinVig,
                    color: sinVig ? cs.onSurfaceVariant : null,
                  ),
                ),
                derecha: true,
              ),
              _celda(
                _columnas[4].$2,
                ComparacionSap(aprobada: c.montoCredito, sap: c.creditLine),
                derecha: true,
              ),
              _celda(
                _columnas[5].$2,
                Text(monto(c.balance), style: context.cifra()),
                derecha: true,
              ),
              _celda(
                _columnas[6].$2,
                CuentaRegresiva(
                  dias: c.diasParaVencer,
                  fecha: c.proximoVencimiento,
                ),
              ),
              SizedBox(
                width: _anchoAcciones,
                child:
                    permisos.verCliente
                        ? Tooltip(
                          message: 'Ver sus garantías',
                          child: Icon(
                            Icons.chevron_right,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TELEFONO Y TABLET: TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

class _TarjetaCliente extends StatelessWidget {
  const _TarjetaCliente({
    required this.n,
    required this.c,
    required this.permisos,
    required this.onVer,
    required this.onNueva,
  });

  final int n;
  final GarantiaResumenClienteEntity c;
  final _Permisos permisos;
  final ValueChanged<GarantiaResumenClienteEntity> onVer;
  final ValueChanged<GarantiaResumenClienteEntity> onNueva;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final marcada = c.difiereDeSap;
    final sinVig = c.sinVigentes;

    // Mismos terminos y explicaciones que los encabezados de la planilla.
    Widget cifra(Termino termino, Widget valor) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [EtiquetaConAyuda(termino), const SizedBox(height: 2), valor],
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(
          color:
              marcada
                  ? GarantiasColores.pleno(context, Semantica.aviso)
                  : cs.outlineVariant,
          width: marcada ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: permisos.verCliente ? () => onVer(c) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.datoCliente,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '#$n · ${c.codClienteSAP}',
                          style: context.cifra(
                            color: cs.onSurfaceVariant,
                            tam: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (permisos.verCliente || permisos.nueva)
                    MenuAcciones(
                      tooltip: 'Acciones',
                      opciones: [
                        if (permisos.verCliente)
                          OpcionMenu(
                            'Ver sus garantías',
                            Icons.list_alt_outlined,
                            () => onVer(c),
                          ),
                        if (permisos.nueva)
                          OpcionMenu(
                            'Nueva garantía',
                            Icons.add,
                            () => onNueva(c),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: Esp.s),
              Padding(
                padding: const EdgeInsets.only(right: Esp.s),
                // Wrap y no Row con Spacer: a 360 px la etiqueta y la cuenta
                // regresiva no entran en una linea (desbordaba 52 px). Asi van
                // a los extremos cuando caben y la cuenta baja cuando no.
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Esp.s,
                  runSpacing: Esp.xs,
                  children: [
                    Tooltip(
                      message: Glosario.vigentes.ayuda,
                      triggerMode: TooltipTriggerMode.tap,
                      child: EtiquetaGarantia(
                        texto:
                            '${c.cantVigentes} de ${c.cantGarantias} '
                            '${c.cantGarantias == 1 ? "vigente" : "vigentes"}',
                        tono:
                            c.sinVigentes
                                ? TonoEtiqueta.neutro
                                : TonoEtiqueta.exito,
                      ),
                    ),
                    Tooltip(
                      message: Glosario.proximoVencimiento.ayuda,
                      triggerMode: TooltipTriggerMode.tap,
                      child: CuentaRegresiva(
                        dias: c.diasParaVencer,
                        fecha: c.proximoVencimiento,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Esp.m),
              Padding(
                padding: const EdgeInsets.only(right: Esp.s),
                child: Wrap(
                  spacing: Esp.xl,
                  runSpacing: Esp.m,
                  children: [
                    cifra(
                      Glosario.valorVigente,
                      Text(
                        sinVig ? '—' : monto(c.montoGarantia),
                        style: context.cifra(),
                      ),
                    ),
                    cifra(
                      Glosario.lineaVigente,
                      Text(
                        sinVig ? '—' : monto(c.montoCredito),
                        style: context.cifra(fuerte: !sinVig),
                      ),
                    ),
                    cifra(
                      Glosario.lineaSap,
                      ComparacionSap(
                        aprobada: c.montoCredito,
                        sap: c.creditLine,
                        alinearDerecha: false,
                      ),
                    ),
                    cifra(
                      Glosario.saldoSap,
                      Text(monto(c.balance), style: context.cifra()),
                    ),
                  ],
                ),
              ),
              if (marcada) ...[
                const SizedBox(height: Esp.m),
                Padding(
                  padding: const EdgeInsets.only(right: Esp.s),
                  child: NotaGarantia(
                    tono: TonoNota.aviso,
                    icono: Icons.compare_arrows,
                    texto:
                        'La línea aprobada por garantías no coincide con la '
                        'línea de crédito en SAP.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
