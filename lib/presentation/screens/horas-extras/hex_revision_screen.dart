import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_asignacion.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_dialogos_revision.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_lista_reportes.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_reporte_pasado.dart';

/// El estado que el SP muestra si no se elige otro: lo que falta revisar.
const String _reportado = 'REPORTADO';

/// Estados de la bandeja para el filtro.
const Map<String?, String> _estadosRevision = {
  _reportado: 'Reportados',
  'VISTO_BUENO': 'Con visto bueno',
  'APROBADO': 'Aprobados',
  'LIQUIDADO': 'Liquidados',
  'RECHAZADO': 'Rechazados',
};

/// `thexRevision/Encargado`: los reportes de la rama del encargado (D34),
/// con la corrección de hora, el visto bueno y el rechazo que permite el SP.
class HexRevisionScreen extends ConsumerStatefulWidget {
  const HexRevisionScreen({super.key});

  @override
  ConsumerState<HexRevisionScreen> createState() => _HexRevisionScreenState();
}

class _HexRevisionScreenState extends ConsumerState<HexRevisionScreen>
    with ListaReportesHex {
  static const int _tamano = 20;

  /// A la vista en la tarjeta y en la tabla; lo demás va al menú de la fila.
  static const Set<String> _principales = {BotonHex.vistoBueno};

  final ScrollController _desplazamiento = ScrollController();

  String _estado = _reportado;
  DateTime? _desde;
  DateTime? _hasta;

  FiltroReportesHex get _filtro => (
    desde: _desde,
    hasta: _hasta,
    estado: _estado,
    pagina: numeroPagina,
    tamano: _tamano,
  );

  bool get _hayFiltros => _estado != _reportado || _desde != null;

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  void _recargar() => ref.invalidate(hexBandejaEncargadoProvider);

  /// Lo que el SP permite (`puede*`); el botón lo filtra `AccionesHex`.
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
    if (r.puedeRechazar)
      AccionHex(
        'Rechazar',
        Icons.do_not_disturb_on_outlined,
        () =>
            rechazarHex(context, ref, r, comoJefe: false, refrescar: _recargar),
        boton: BotonHex.rechazar,
        destructiva: true,
      ),
  ];

  bool _tieneRoles(HexRolesEntity? r) =>
      r != null && (r.esEncargado || r.esJefe);

  /// Un solo desplazamiento para todo: con el teclado abierto nada desborda.
  /// Tabla solo si la lista (sin el relleno) tiene el ancho de la tabla
  /// ([usaTablaHex], la regla del listado); si no, tarjetas en este scroll.
  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(hexMisRolesProvider);
    final conBandeja = _tieneRoles(roles.valueOrNull);
    // Sin roles no se escucha: escuchar pediría la bandeja al servidor.
    if (conBandeja) {
      ref.listen(hexBandejaEncargadoProvider(_filtro), siQuedoVacia);
    }
    return PrimaryScrollController(
      controller: _desplazamiento,
      child: Scaffold(body: _pagina(roles, conBandeja: conBandeja)),
    );
  }

  Widget _pagina(
    AsyncValue<HexRolesEntity?> roles, {
    required bool conBandeja,
  }) => LayoutBuilder(
    builder: (context, c) {
      final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
      final anchoLista = c.maxWidth - 2 * relleno;
      final ancho = usaTablaHex(anchoLista, anchoTablaReportesHex());
      final abajo = MediaQuery.paddingOf(context).bottom;
      // El total que manda el servidor para la bandeja que se ve; la misma
      // consulta que la lista, sin pedir otra.
      final total =
          conBandeja && _estado == _reportado
              ? ref
                  .watch(hexBandejaEncargadoProvider(_filtro))
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
          if (r == null || !_tieneRoles(r)) {
            return enCaja(
              const MensajeVacio(
                icono: Icons.account_tree_outlined,
                titulo: 'No tienes el rol de encargado',
                detalle:
                    'Pide a RRHH que te lo asigne en «Horas extra: '
                    'aprobadores»: cubre toda tu rama del organigrama.',
              ),
            );
          }
          final soloJefe = !r.esEncargado;
          if (!ancho) {
            return KeyedSubtree(
              key: claveLista,
              child: _lista(
                externo: true,
                accionesEnLinea: false,
                soloJefe: soloJefe,
              ),
            );
          }
          return SizedBox(
            height: math.max(c.maxHeight - 2 * relleno, hexAltoMinimoLista),
            child: _lista(
              externo: false,
              accionesEnLinea:
                  anchoLista >= anchoTablaReportesHex(accionesEnLinea: true),
              soloJefe: soloJefe,
            ),
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
            const EncabezadoHex(
              titulo: 'Revisión de encargado',
              detalle:
                  'Los reportes de tu rama del organigrama: revisa las '
                  'horas, corrígelas si hace falta y da el visto bueno.',
            ),
            const SizedBox(height: Esp.m),
            if (conBandeja) _faltas(),
            // D43: solo con jornadas del servidor y el botón de corregir hora.
            if (conBandeja) FranjaReportePasadoHex(refrescar: _recargar),
            if (total != null && total > 0) ...[
              FranjaPorRevisarHex(
                total: total,
                ayuda:
                    _desde == null
                        ? 'Revisa cada uno y da tu visto bueno: pasa a tu '
                            'jefe de área.'
                        : 'Solo cuenta las jornadas del rango de fechas '
                            'elegido.',
              ),
              const SizedBox(height: Esp.m),
            ],
            cuerpo,
            if (conBandeja) ...[
              SizedBox(height: ancho ? Esp.l : Esp.m),
              const LeyendaHex(),
            ],
          ],
        ),
      );
    },
  );

  /// Adenda D37: las faltas de lo que asignó, con el texto del SP. Sin nada
  /// (204), mientras carga o con error (por ejemplo, sin la pantalla de
  /// asignar), no ocupa lugar: es un aviso, no la bandeja.
  Widget _faltas() {
    final faltas =
        ref.watch(hexFaltasAsignacionProvider).valueOrNull ?? const [];
    if (faltas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.m),
      child: AvisoFaltasHex(faltas),
    );
  }

  /// Mientras carga o si el SP rechaza el filtro, los filtros siguen a la
  /// vista; un 403 ocupa todo el lugar. [soloJefe]: el vacío lo manda a
  /// «Aprobación de área», donde están los reportes de sus encargados.
  Widget _lista({
    required bool externo,
    required bool accionesEnLinea,
    required bool soloJefe,
  }) {
    final filtro = _filtro;
    Widget listado({PaginaHex<HexReporteEntity>? pagina, Widget? vacio}) =>
        _listado(
          externo: externo,
          accionesEnLinea: accionesEnLinea,
          pagina: pagina,
          vacio: vacio,
        );
    return ref
        .watch(hexBandejaEncargadoProvider(filtro))
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
                                hexBandejaEncargadoProvider(filtro),
                              ),
                        ),
                      ),
          data:
              (p) => listado(
                pagina: p,
                vacio:
                    soloJefe
                        ? _vacioSoloJefe
                        : (_hayFiltros ? null : _vacioSinReportes),
              ),
        );
  }

  static const MensajeVacio _vacioSinReportes = MensajeVacio(
    icono: Icons.fact_check_outlined,
    titulo: 'No hay reportes por revisar',
    detalle:
        'Los reportes de horas extra de tu rama aparecen aquí apenas se '
        'registran.',
  );

  static const MensajeVacio _vacioSoloJefe = MensajeVacio(
    icono: Icons.supervisor_account_outlined,
    titulo: 'No tienes el rol de encargado',
    detalle:
        'Como jefe de área, los reportes de tu rama están en «Aprobación de '
        'área»: ahí apruebas los que firmó un encargado y, si no hay '
        'encargado, apruebas directo.',
  );

  /// Sin [pagina] no hay filas ni paginador: se ve [vacio] bajo los filtros.
  Widget _listado({
    required bool externo,
    required bool accionesEnLinea,
    PaginaHex<HexReporteEntity>? pagina,
    Widget? vacio,
  }) {
    return ListadoHex<HexReporteEntity>(
      desplazamientoExterno: externo,
      filas: pagina?.filas ?? const <HexReporteEntity>[],
      pagina: numeroPagina,
      total: pagina?.total ?? 0,
      tamano: _tamano,
      alCambiarPagina: pagina == null ? null : cambiarPagina,
      filtros: _filtros(),
      vacio: vacio,
      anchoMinimoTabla: anchoTablaReportesHex(),
      alTocarFila: verDetalle,
      columnas: columnasReportesHex(
        context,
        acciones: _acciones,
        accionesEnLinea: accionesEnLinea,
        principales: _principales,
        conMonto: conMontosHex(pagina?.filas ?? const []),
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

  Widget _filtros() => Wrap(
    spacing: Esp.s,
    runSpacing: Esp.s,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      MenuFiltroHex(
        valor: _estado,
        opciones: _estadosRevision,
        alElegir: (v) => filtrar(() => _estado = v ?? _reportado),
      ),
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
