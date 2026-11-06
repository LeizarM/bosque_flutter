import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_dialogos_revision.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_grupos_aprobacion.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_lista_reportes.dart';

/// Lo que espera la firma del jefe (por defecto del SP J).
const String _vistoBueno = 'VISTO_BUENO';

/// Lo que aún no tiene visto bueno: el jefe aprueba directo si no hay
/// encargado en su rama (D34); lo que puede hacer lo dicen las banderas.
const String _reportado = 'REPORTADO';

/// Las acciones que quedan a la vista en la tarjeta y en la tabla.
const Set<String> _principales = {BotonHex.aprobar, BotonHex.vistoBueno};

/// `thexAprobacion/Area`: los reportes de la rama del jefe con visto bueno,
/// agrupados por encargado y mes, y los que aún no lo tienen (D34).
class HexAprobacionScreen extends ConsumerStatefulWidget {
  const HexAprobacionScreen({super.key});

  @override
  ConsumerState<HexAprobacionScreen> createState() =>
      _HexAprobacionScreenState();
}

class _HexAprobacionScreenState extends ConsumerState<HexAprobacionScreen>
    with ListaReportesHex {
  final ScrollController _desplazamiento = ScrollController();

  final OcupadoHex _ocupado = OcupadoHex();

  /// El grupo que se confirma o se aprueba: mientras tanto ningún «Aprobar
  /// todo» responde (un doble toque no abre dos confirmaciones).
  ClaveGrupoHex? _grupoEnCurso;

  /// Ya confirmado: el pedido va al servidor y su botón muestra la espera.
  bool _aprobando = false;

  String _estado = _vistoBueno;
  DateTime? _desde;
  DateTime? _hasta;

  bool get _agrupado => _estado == _vistoBueno;

  /// Con visto bueno la página es la más grande que admite el SP: así cada
  /// grupo junta más de lo suyo.
  int get _tamano => _agrupado ? 100 : 20;

  FiltroReportesHex get _filtro => (
    desde: _desde,
    hasta: _hasta,
    estado: _estado,
    pagina: numeroPagina,
    tamano: _tamano,
  );

  bool get _hayFiltros => _desde != null;

  @override
  void dispose() {
    _desplazamiento.dispose();
    _ocupado.dispose();
    super.dispose();
  }

  void _recargar() => ref.invalidate(hexBandejaJefeProvider);

  /// Lo que el SP permite (`puede*`) en cualquiera de los dos segmentos; el
  /// botón lo filtra `AccionesHex`. El rechazo siempre es el del jefe.
  List<AccionHex> _acciones(HexReporteEntity r) => [
    AccionHex('Ver detalle', Icons.visibility_outlined, () => verDetalle(r)),
    if (r.puedeEditarHora)
      AccionHex(
        'Corregir hora',
        Icons.schedule,
        () => corregirHoraHex(context, ref, r, refrescar: _recargar),
        boton: BotonHex.editarHora,
      ),
    if (r.puedeVistoBueno)
      AccionHex(
        'Visto bueno',
        Icons.task_alt,
        () => vistoBuenoHex(context, ref, r, refrescar: _recargar),
        boton: BotonHex.vistoBueno,
        textoPrincipal: 'Dar visto bueno',
        tono: TonoHex.terciario,
      ),
    if (r.puedeAprobar)
      AccionHex(
        'Aprobar',
        Icons.verified_outlined,
        () => aprobarHex(context, ref, r, refrescar: _recargar),
        boton: BotonHex.aprobar,
        tono: TonoHex.exito,
      ),
    if (r.puedeRechazar)
      AccionHex(
        'Rechazar',
        Icons.do_not_disturb_on_outlined,
        () =>
            rechazarHex(context, ref, r, comoJefe: true, refrescar: _recargar),
        boton: BotonHex.rechazarJefe,
        destructiva: true,
      ),
  ];

  /// Confirma qué se aprueba (el encargado y el mes, también lo que no se ve)
  /// y manda el grupo, no la lista visible. La bandeja se recarga una vez
  /// salga como salga: aunque el SP no apruebe nada, otro pudo aprobarlos.
  Future<void> _aprobarTodo(GrupoAprobacionHex g) async {
    if (_grupoEnCurso != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _grupoEnCurso = g.clave);
    try {
      final si = await confirmar(
        context,
        titulo: 'Aprobar todo',
        detalle: _alcanceDe(g),
        textoConfirmar: 'Aprobar todo',
      );
      if (!si || !mounted) return;
      setState(() => _aprobando = true);
      final repo = ref.read(hexReporteRepositoryProvider);
      await ejecutarHex(
        context,
        ocupado: _ocupado,
        accion:
            (_) => _conCantidad(
              repo.aprobarGrupo(
                codEncargado: g.codEncargado,
                anio: g.anio,
                mes: g.mes,
              ),
            ),
        refrescar: () {},
      );
      if (mounted) _recargar();
    } finally {
      if (mounted) {
        setState(() {
          _grupoEnCurso = null;
          _aprobando = false;
        });
      }
    }
  }

  /// Qué aprueba «Aprobar todo». El SP G toma todo el mes del encargado: con
  /// filtros activos se dice que no lo limitan.
  String _alcanceDe(GrupoAprobacionHex g) {
    final encargado = oGuionHex(g.nombreEncargado);
    final alcance =
        'Se aprobarán todos los reportes con visto bueno de $encargado de '
        '${g.periodo} que puedes firmar, también los que no se ven en esta '
        'página.';
    if (!_hayFiltros) return alcance;
    return '$alcance\n\nEl filtro de fecha no limita esta acción: se aprueba '
        'todo ${g.periodo} de $encargado.';
  }

  /// El SP dice cuántos aprobó en su mensaje; si llegara vacío, se muestra la
  /// cantidad que devolvió (`data`).
  static Future<HexRespuesta> _conCantidad(
    Future<HexRespuesta> escritura,
  ) async {
    final r = await escritura;
    if (r.mensaje.isNotEmpty) return r;
    return (
      id: r.id,
      mensaje: 'Reportes aprobados: ${enteroHex(r.id.toInt())}.',
    );
  }

  /// Un solo desplazamiento para todo: con el teclado abierto nada desborda.
  /// Tabla solo si la lista (sin el relleno) tiene el ancho de la tabla
  /// ([usaTablaHex]); si no, tarjetas en este scroll.
  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(hexMisRolesProvider);
    final esJefe = roles.valueOrNull?.esJefe ?? false;
    // Sin el rol no se escucha: escuchar pediría la bandeja al servidor.
    if (esJefe) ref.listen(hexBandejaJefeProvider(_filtro), siQuedoVacia);
    return PrimaryScrollController(
      controller: _desplazamiento,
      child: Scaffold(body: _pagina(roles, esJefe: esJefe)),
    );
  }

  Widget _pagina(AsyncValue<HexRolesEntity?> roles, {required bool esJefe}) =>
      LayoutBuilder(
        builder: (context, c) {
          final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
          final anchoLista = c.maxWidth - 2 * relleno;
          final ancho = usaTablaHex(anchoLista, anchoTablaReportesHex());
          final enLinea =
              anchoLista >= anchoTablaReportesHex(accionesEnLinea: true);
          final abajo = MediaQuery.paddingOf(context).bottom;
          // El total que manda el servidor para la bandeja que se ve; la
          // misma consulta que la lista, sin pedir otra.
          final total =
              esJefe
                  ? ref
                      .watch(hexBandejaJefeProvider(_filtro))
                      .valueOrNull
                      ?.total
                  : null;

          Widget enCaja(Widget hijo) =>
              SizedBox(height: hexAltoEstado, child: hijo);
          final cuerpo = roles.when(
            skipLoadingOnReload: true,
            loading: () => enCaja(const EsqueletoLista()),
            error:
                (e, _) => enCaja(
                  vistaErrorHex(
                    e,
                    reintentar: () => ref.invalidate(hexMisRolesProvider),
                  ),
                ),
            data: (r) {
              if (r == null || !r.esJefe) {
                return enCaja(
                  const MensajeVacio(
                    icono: Icons.supervisor_account_outlined,
                    titulo: 'No tienes el rol de jefe de área',
                    detalle:
                        'Pide a RRHH que te lo asigne en «Horas extra: '
                        'aprobadores»: cubre toda tu rama del organigrama.',
                  ),
                );
              }
              final lista = _lista(externo: !ancho, accionesEnLinea: enLinea);
              if (!ancho) return KeyedSubtree(key: claveLista, child: lista);
              return SizedBox(
                height: math.max(c.maxHeight - 2 * relleno, hexAltoMinimoLista),
                child: lista,
              );
            },
          );

          return PaginaDesplazableHex(
            controlador: _desplazamiento,
            relleno: relleno,
            abajo: abajo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EncabezadoHex(titulo: 'Aprobación de área'),
                const SizedBox(height: Esp.m),
                if (esJefe) ...[
                  _segmentos(compacto: !ancho),
                  const SizedBox(height: Esp.s),
                  ExplicacionBandejaHex(_explicacion),
                  if (total != null && total > 0) ...[
                    const SizedBox(height: Esp.s),
                    FranjaPorRevisarHex(
                      total: total,
                      verbo: _agrupado ? 'por aprobar' : 'por revisar',
                      ayuda: _ayudaFranja,
                    ),
                  ],
                  SizedBox(height: ancho ? Esp.l : Esp.m),
                ],
                cuerpo,
                if (esJefe) ...[
                  SizedBox(height: ancho ? Esp.l : Esp.m),
                  const LeyendaHex(),
                ],
              ],
            ),
          );
        },
      );

  /// Qué muestra cada segmento y qué se puede hacer; siempre a la vista.
  String get _explicacion =>
      _agrupado
          ? 'Con visto bueno: los reportes que tus encargados ya revisaron, '
              'por encargado y mes. Apruébalos uno por uno o todo el grupo.'
          : 'Sin visto bueno aún: los reportes de tu rama que todavía no '
              'tienen visto bueno. Si no hay un encargado entre tú y el '
              'empleado, los apruebas directo; también puedes corregir la hora '
              'o rechazarlos.';

  String get _ayudaFranja =>
      _desde != null
          ? 'Solo cuenta las jornadas del rango de fechas elegido.'
          : _agrupado
          ? 'Aprueba cada uno o todo el grupo de un encargado.'
          : 'Los que no tienen encargado en tu rama los apruebas directo.';

  /// Los dos estados de la bandeja, con un texto que se entiende solo. En el
  /// angosto ocupa todo el ancho y los textos pasan a dos líneas si hace falta.
  Widget _segmentos({required bool compacto}) {
    Widget texto(String t) => Text(
      t,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    final selector = SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: _vistoBueno,
          label: texto('Con visto bueno'),
          icon: compacto ? null : const Icon(Icons.task_alt),
        ),
        ButtonSegment(
          value: _reportado,
          label: texto('Sin visto bueno aún'),
          icon: compacto ? null : const Icon(Icons.hourglass_top),
        ),
      ],
      selected: {_estado},
      showSelectedIcon: false,
      expandedInsets: compacto ? EdgeInsets.zero : null,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.standard,
        minimumSize: const Size(0, 48),
      ),
      onSelectionChanged: (s) {
        HapticaHex.seleccion();
        filtrar(() => _estado = s.first);
      },
    );
    if (compacto) return selector;
    return Align(alignment: Alignment.centerLeft, child: selector);
  }

  /// Mientras carga o si el SP rechaza el filtro, los filtros siguen a la
  /// vista; un 403 ocupa todo el lugar.
  Widget _lista({required bool externo, required bool accionesEnLinea}) {
    final filtro = _filtro;
    Widget listado({PaginaHex<HexReporteEntity>? pagina, Widget? vacio}) =>
        _listado(
          externo: externo,
          accionesEnLinea: accionesEnLinea,
          pagina: pagina,
          vacio: vacio,
        );
    return ref
        .watch(hexBandejaJefeProvider(filtro))
        .when(
          skipLoadingOnReload: true,
          loading: () => listado(vacio: const EsqueletoLista()),
          error:
              (e, _) =>
                  e is SinPermisoHex
                      ? const SizedBox(
                        height: hexAltoEstado,
                        child: SinPermisoHexVista(),
                      )
                      : listado(
                        vacio: vistaErrorHex(
                          e,
                          reintentar:
                              () => ref.invalidate(
                                hexBandejaJefeProvider(filtro),
                              ),
                        ),
                      ),
          data:
              (p) => listado(
                pagina: p,
                vacio:
                    _hayFiltros
                        ? null
                        : (_agrupado ? _vacioPorAprobar : _vacioReportados),
              ),
        );
  }

  static const MensajeVacio _vacioPorAprobar = MensajeVacio(
    icono: Icons.verified_outlined,
    titulo: 'No hay reportes por aprobar',
    detalle:
        'Los reportes de tu rama aparecen aquí cuando un encargado les da el '
        'visto bueno.',
  );

  static const MensajeVacio _vacioReportados = MensajeVacio(
    icono: Icons.fact_check_outlined,
    titulo: 'No hay reportes sin visto bueno en tu rama',
    detalle:
        'Aquí aparecen los reportes que aún no tienen visto bueno: los que no '
        'tienen encargado en tu rama los apruebas directo.',
  );

  /// Sin [pagina] no hay filas ni paginador: se ve [vacio] bajo los filtros.
  Widget _listado({
    required bool externo,
    required bool accionesEnLinea,
    PaginaHex<HexReporteEntity>? pagina,
    Widget? vacio,
  }) {
    final servidor = pagina?.filas ?? const <HexReporteEntity>[];
    final inicios = <int, GrupoAprobacionHex>{};
    final filas = <HexReporteEntity>[];
    if (_agrupado) {
      // La cabecera de cada grupo va antes de su primera fila.
      for (final g in agruparHex(servidor)) {
        inicios[filas.length] = g;
        filas.addAll(g.reportes);
      }
    } else {
      filas.addAll(servidor);
    }
    return ListadoHex<HexReporteEntity>(
      desplazamientoExterno: externo,
      filas: filas,
      pagina: numeroPagina,
      total: pagina?.total ?? 0,
      tamano: _tamano,
      alCambiarPagina: pagina == null ? null : cambiarPagina,
      filtros: _filtros(),
      vacio: vacio,
      anchoMinimoTabla: anchoTablaReportesHex(),
      alTocarFila: verDetalle,
      cabeceraAntesDe:
          _agrupado
              ? (i) => switch (inicios[i]) {
                null => null,
                final g => _cabecera(g, enTabla: !externo),
              }
              : null,
      columnas: columnasReportesHex(
        context,
        acciones: _acciones,
        accionesEnLinea: accionesEnLinea,
        principales: _principales,
        conMonto: conMontosHex(filas),
      ),
      tarjeta:
          (r) => TarjetaReporteHex(
            r,
            mostrarSucursal: true,
            acciones: _acciones(r),
            principales: _principales,
            alTocar: () => verDetalle(r),
          ),
    );
  }

  Widget _cabecera(GrupoAprobacionHex g, {required bool enTabla}) =>
      CabeceraGrupoHex(
        g,
        enTabla: enTabla,
        ocupado: _aprobando && _grupoEnCurso == g.clave,
        alAprobarTodo: _grupoEnCurso == null ? () => _aprobarTodo(g) : null,
      );

  Widget _filtros() => Wrap(
    spacing: Esp.s,
    runSpacing: Esp.s,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FiltroRangoHex(
        desde: _desde,
        hasta: _hasta,
        explicacion: 'Los reportes cuya jornada cae entre estas fechas.',
        alCambiar:
            (desde, hasta) => filtrar(() {
              _desde = desde;
              _hasta = hasta;
            }),
      ),
    ],
  );
}
