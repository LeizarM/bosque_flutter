import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_lista_reportes.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_marcacion.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Estados del reporte para el filtro (nulo = todos).
const Map<String?, String> _estadosHex = {
  null: 'Todos los estados',
  'REPORTADO': 'Reportados',
  'VISTO_BUENO': 'Con visto bueno',
  'APROBADO': 'Aprobados',
  'LIQUIDADO': 'Liquidados',
  'RECHAZADO': 'Rechazados',
  'ANULADO': 'Anulados',
};

// Cada `flex` es la mitad de los px que pide su columna; las demás son las
// compartidas con las bandejas, sin Comidas ni Monto (D41).
const int _flexTipo = 48;

/// El ancho de lista desde el que Mis horas va en tabla (con el relleno de la
/// fila); por debajo, tarjetas ([usaTablaHex]).
const double anchoTablaMisHorasHex =
    2.0 * (flexJornadaHex + _flexTipo + flexDatosReporteOperarioHex) +
    2 * Esp.m;

/// `thexMisHoras/MisHoras`: el operario ve quién le asignó horas extra y el
/// motivo, marca en la app y sigue sus reportes, sin dinero, detalle ni
/// leyenda de códigos (D38, D41). Sin asignación para hoy (D37) se bloquea.
class HexMisHorasScreen extends ConsumerStatefulWidget {
  const HexMisHorasScreen({super.key});

  @override
  ConsumerState<HexMisHorasScreen> createState() => _HexMisHorasScreenState();
}

class _HexMisHorasScreenState extends ConsumerState<HexMisHorasScreen>
    with ListaReportesHex {
  static const int _tamano = 20;

  final ScrollController _desplazamiento = ScrollController();

  DateTime? _desde;
  DateTime? _hasta;
  String? _estado;

  FiltroReportesHex get _filtro => (
    desde: _desde,
    hasta: _hasta,
    estado: _estado,
    pagina: numeroPagina,
    tamano: _tamano,
  );

  bool get _hayFiltros => _desde != null || _estado != null;

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  /// Un solo desplazamiento para todo: con el teclado abierto nada desborda.
  /// Con tabla ([usaTablaHex] sobre el ancho de la lista, sin el relleno) esta
  /// tiene alto propio; con tarjetas, van en este mismo scroll.
  @override
  Widget build(BuildContext context) {
    final hoy = ref.watch(hexReporteHoyProvider);
    final vista = hoy.valueOrNull;
    final habilitada = vista?.vistaHabilitada ?? false;
    return PrimaryScrollController(
      controller: _desplazamiento,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, c) {
            final relleno = Aire.de(c.maxWidth).esChico ? Esp.m : Esp.xl;
            final ancho = usaTablaHex(
              c.maxWidth - 2 * relleno,
              anchoTablaMisHorasHex,
            );
            final abajo = MediaQuery.paddingOf(context).bottom;
            return PaginaDesplazableHex(
              controlador: _desplazamiento,
              relleno: relleno,
              abajo: abajo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EncabezadoHex(
                    titulo: 'Mis horas extra',
                    detalle:
                        ancho
                            ? 'Quién te asignó horas extra, marcar y tus '
                                'reportes.'
                            : null,
                  ),
                  const SizedBox(height: Esp.m),
                  if (!habilitada)
                    _bloqueo(hoy)
                  else ...[
                    // D41: quién asignó y el motivo, solo para leer.
                    if (vista != null && vista.textoVista.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Esp.m),
                        child: AsignacionHoyHex(vista),
                      ),
                    // Sin el botón no hay panel: no se pide la ubicación a
                    // quien no marca.
                    const PermissionWidget(
                      buttonName: BotonHex.marcar,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: Esp.m),
                        child: PanelMarcacionHex(),
                      ),
                    ),
                  ],
                  // La ayuda va después de lo que se usa a diario: no empuja
                  // las teclas hacia abajo.
                  if (!habilitada) const SizedBox(height: Esp.m),
                  // Con clave: al llegar `reporte/hoy` cambia de lugar y no
                  // pierde si estaba abierta.
                  const ComoFuncionaHex(key: ValueKey('hexComoFunciona')),
                  const SizedBox(height: Esp.m),
                  if (!habilitada)
                    const SizedBox.shrink()
                  else if (ancho)
                    SizedBox(
                      height: math.max(
                        c.maxHeight - 2 * relleno,
                        hexAltoMinimoLista,
                      ),
                      child: _lista(externo: false),
                    )
                  else
                    KeyedSubtree(key: claveLista, child: _lista(externo: true)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Mientras llega `reporte/hoy`, si falla o si no hay asignación: la vista
  /// queda bloqueada con el texto del SP y se puede volver a consultar.
  Widget _bloqueo(AsyncValue<HexVistaMarcacionEntity?> hoy) {
    void actualizar() => ref.invalidate(hexReporteHoyProvider);
    if (hoy.hasError && !hoy.isLoading) {
      return SizedBox(
        height: hexAltoEstado,
        child: vistaErrorHex(hoy.error!, reintentar: actualizar),
      );
    }
    if (!hoy.hasValue) {
      return const SizedBox(height: hexAltoEstado, child: EsqueletoLista());
    }
    final texto = hoy.value?.textoVista.trim() ?? '';
    return VistaBloqueadaHex(
      texto:
          texto.isNotEmpty
              ? texto
              : 'No se pudo saber si tienes horas extra asignadas para hoy.',
      actualizando: hoy.isLoading,
      alActualizar: actualizar,
    );
  }

  /// Mientras carga o si el SP rechaza el filtro, los filtros siguen a la
  /// vista; un 403 ocupa todo el lugar.
  Widget _lista({required bool externo}) {
    final filtro = _filtro;
    Widget listado({PaginaHex<HexReporteEntity>? pagina, Widget? vacio}) =>
        _listado(externo: externo, pagina: pagina, vacio: vacio);
    return ref
        .watch(hexMisReportesProvider(filtro))
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
                                hexMisReportesProvider(filtro),
                              ),
                        ),
                      ),
          data:
              (p) => listado(
                pagina: p,
                vacio:
                    _hayFiltros
                        ? null
                        : const MensajeVacio(
                          icono: Icons.more_time,
                          titulo: 'Todavía no tienes horas extra reportadas',
                          detalle:
                              'Las horas extra que marcas en el biométrico '
                              'aparecen solas cuando llegan las marcas. Si no '
                              'alcanzaste a marcar allí, usa «Marcar entrada» '
                              'o «Marcar salida».',
                        ),
              ),
        );
  }

  /// Sin [pagina] no hay filas ni paginador: se ve [vacio] bajo los filtros.
  /// D38 y D41: sin acciones ni detalle, sin dinero ni códigos de comida.
  Widget _listado({
    required bool externo,
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
      anchoMinimoTabla: anchoTablaMisHorasHex,
      columnas: _columnas(),
      tarjeta:
          (r) => TarjetaReporteHex(
            r,
            mostrarEmpleado: false,
            mostrarComidas: false,
          ),
    );
  }

  Widget _filtros() => Wrap(
    spacing: Esp.s,
    runSpacing: Esp.s,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FiltroRangoHex(
        desde: _desde,
        hasta: _hasta,
        explicacion: 'Tus reportes cuya jornada cae entre estas fechas.',
        alCambiar:
            (desde, hasta) => filtrar(() {
              _desde = desde;
              _hasta = hasta;
            }),
      ),
      MenuFiltroHex(
        valor: _estado,
        opciones: _estadosHex,
        alElegir: (v) => filtrar(() => _estado = v),
      ),
    ],
  );

  /// Jornada y tipo, y las columnas compartidas con las bandejas sin Comidas
  /// ni Monto: el operario no ve dinero ni la leyenda de códigos.
  List<BosqueColumn<HexReporteEntity>> _columnas() => [
    BosqueColumn(
      label: 'Jornada',
      flex: flexJornadaHex,
      cellBuilder:
          (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                fechaHex(r.fechaJornada),
                style: estiloCifrasHex(
                  Theme.of(context).textTheme.bodyMedium,
                  fuerte: true,
                ),
              ),
              if (r.tipoDia.isNotEmpty || r.tipoDiaTexto.isNotEmpty)
                TipoDiaHex(r.tipoDia, r.tipoDiaTexto, plano: true),
            ],
          ),
    ),
    BosqueColumn(
      label: 'Tipo',
      flex: _flexTipo,
      cellBuilder: (r) => TipoReporteHex(r.tipo, r.tipoTexto, plano: true),
    ),
    ...columnasDatosReporteHex(context, conMonto: false, conComidas: false),
  ];
}
