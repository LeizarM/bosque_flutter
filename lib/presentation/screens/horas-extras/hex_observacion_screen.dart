import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_grupos_aprobacion.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_lista_reportes.dart';

/// Estados del reporte para el filtro (nulo = todos).
const Map<String?, String> _estadosObservacion = {
  null: 'Todos',
  'REPORTADO': 'Reportado',
  'VISTO_BUENO': 'Visto bueno',
  'APROBADO': 'Aprobado',
  'RECHAZADO': 'Rechazado',
  'LIQUIDADO': 'Liquidado',
  'ANULADO': 'Anulado',
};

/// Una página grande: así cada encargado junta más de lo suyo en su grupo.
const int _tamanoPagina = 50;

/// `thexObservacion/Observar` (D45): los reportes de los encargados que se le
/// asignaron al observador, de todos los estados y agrupados por encargado y
/// mes. Solo lectura: el detalle, los montos y el historial los manda el SP.
class HexObservacionScreen extends ConsumerStatefulWidget {
  const HexObservacionScreen({super.key});

  @override
  ConsumerState<HexObservacionScreen> createState() =>
      _HexObservacionScreenState();
}

class _HexObservacionScreenState extends ConsumerState<HexObservacionScreen>
    with ListaReportesHex {
  final ScrollController _desplazamiento = ScrollController();

  String? _estado;
  DateTime? _desde;
  DateTime? _hasta;

  FiltroReportesHex get _filtro => (
    desde: _desde,
    hasta: _hasta,
    estado: _estado,
    pagina: numeroPagina,
    tamano: _tamanoPagina,
  );

  bool get _hayFiltros => _desde != null || _estado != null;

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  /// Lo único que se puede hacer con un reporte: abrir su detalle.
  List<AccionHex> _acciones(HexReporteEntity r) => [
    AccionHex('Ver detalle', Icons.visibility_outlined, () => verDetalle(r)),
  ];

  /// Un solo desplazamiento para todo: con el teclado abierto nada desborda.
  /// Tabla solo si la lista (sin el relleno) tiene el ancho de la tabla
  /// ([usaTablaHex]); si no, tarjetas en este scroll.
  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(hexMisRolesProvider);
    final esObservador = roles.valueOrNull?.esObservador ?? false;
    // Sin el rol no se escucha: escuchar pediría la bandeja al servidor.
    if (esObservador) {
      ref.listen(hexBandejaObservadorProvider(_filtro), siQuedoVacia);
    }
    return PrimaryScrollController(
      controller: _desplazamiento,
      child: Scaffold(body: _pagina(roles, esObservador: esObservador)),
    );
  }

  Widget _pagina(
    AsyncValue<HexRolesEntity?> roles, {
    required bool esObservador,
  }) => LayoutBuilder(
    builder: (context, c) {
      final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
      final anchoLista = c.maxWidth - 2 * relleno;
      final ancho = usaTablaHex(anchoLista, anchoTablaReportesHex());
      final abajo = MediaQuery.paddingOf(context).bottom;

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
          if (r == null || !r.esObservador) {
            return enCaja(
              const MensajeVacio(
                icono: Icons.visibility_off_outlined,
                titulo: 'No tienes el rol de observador',
                detalle:
                    'Pide a RRHH que te lo asigne en «Horas extra: '
                    'aprobadores»: verás los reportes y el historial de los '
                    'encargados que te asignen, sin firmar.',
              ),
            );
          }
          final lista = _lista(externo: !ancho);
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
            const EncabezadoHex(titulo: 'Observación de reportes'),
            const SizedBox(height: Esp.m),
            if (esObservador) ...[
              const ExplicacionBandejaHex(_explicacion),
              SizedBox(height: ancho ? Esp.l : Esp.m),
            ],
            cuerpo,
            if (esObservador) ...[
              SizedBox(height: ancho ? Esp.l : Esp.m),
              const LeyendaHex(),
            ],
          ],
        ),
      );
    },
  );

  static const String _explicacion =
      'Solo lectura: ves los reportes de los encargados que se te asignaron, '
      'de todos los estados, con su detalle, los montos y el historial. No '
      'puedes firmar, corregir ni aprobar.';

  /// Mientras carga o si el SP rechaza el filtro, los filtros siguen a la
  /// vista; un 403 ocupa todo el lugar.
  Widget _lista({required bool externo}) {
    final filtro = _filtro;
    Widget listado({PaginaHex<HexReporteEntity>? pagina, Widget? vacio}) =>
        _listado(externo: externo, pagina: pagina, vacio: vacio);
    return ref
        .watch(hexBandejaObservadorProvider(filtro))
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
                                hexBandejaObservadorProvider(filtro),
                              ),
                        ),
                      ),
          data:
              (p) => listado(
                pagina: p,
                vacio: _hayFiltros ? null : _vacioSinReportes,
              ),
        );
  }

  static const MensajeVacio _vacioSinReportes = MensajeVacio(
    icono: Icons.visibility_outlined,
    titulo: 'No hay reportes para observar',
    detalle:
        'Aquí aparecen los reportes de los encargados que te asignaron, en '
        'cualquier estado.',
  );

  /// Sin [pagina] no hay filas ni paginador: se ve [vacio] bajo los filtros.
  Widget _listado({
    required bool externo,
    PaginaHex<HexReporteEntity>? pagina,
    Widget? vacio,
  }) {
    final inicios = <int, GrupoAprobacionHex>{};
    final filas = <HexReporteEntity>[];
    // La cabecera de cada grupo va antes de su primera fila.
    for (final g in agruparHex(pagina?.filas ?? const [])) {
      inicios[filas.length] = g;
      filas.addAll(g.reportes);
    }
    return ListadoHex<HexReporteEntity>(
      desplazamientoExterno: externo,
      filas: filas,
      pagina: numeroPagina,
      total: pagina?.total ?? 0,
      tamano: _tamanoPagina,
      alCambiarPagina: pagina == null ? null : cambiarPagina,
      filtros: _filtros(),
      vacio: vacio,
      anchoMinimoTabla: anchoTablaReportesHex(),
      alTocarFila: verDetalle,
      cabeceraAntesDe:
          (i) => switch (inicios[i]) {
            null => null,
            final g => _cabecera(g, enTabla: !externo),
          },
      columnas: columnasReportesHex(
        context,
        acciones: _acciones,
        accionesEnLinea: false,
        principales: const {},
        conMonto: true,
      ),
      tarjeta:
          (r) => TarjetaReporteHex(
            r,
            mostrarSucursal: true,
            acciones: _acciones(r),
            alTocar: () => verDetalle(r),
          ),
    );
  }

  /// La franja del encargado y el mes, sin «Aprobar todo»: aquí nada se firma.
  Widget _cabecera(
    GrupoAprobacionHex g, {
    required bool enTabla,
  }) => FranjaGrupoHex(
    enTabla: enTabla,
    icono: Icons.supervisor_account_outlined,
    titulo: oGuionHex(g.nombreEncargado),
    detalle:
        '${g.periodo} · ${cuentaHex(g.reportes.length, 'reporte', 'reportes')}',
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
      MenuFiltroHex(
        valor: _estado,
        opciones: _estadosObservacion,
        alElegir: (v) => filtrar(() => _estado = v),
      ),
    ],
  );
}
