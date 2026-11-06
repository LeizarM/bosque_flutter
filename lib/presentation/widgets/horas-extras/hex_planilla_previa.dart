/// Vista previa de una planilla de horas extra (RRHH): lo que se ejecutaría,
/// los avisos del SP (los provisionales primero) y el resumen por empleado,
/// con sus líneas a pedido.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_empresas.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_avisos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_firmas.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_lineas.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Ancho mínimo de la tabla por empleado; por debajo, tarjetas.
const double _anchoTablaPrevia = 1000;

/// La combinación de una fila pendiente; nula si al SP le faltó un código.
CombinacionHex? combinacionHex(HexPendienteEntity p) {
  final empresa = p.codEmpresa;
  final sucursal = p.codSucursal;
  if (empresa == null || sucursal == null) return null;
  return (codEmpresa: empresa, codSucursal: sucursal, anio: p.anio, mes: p.mes);
}

// ═══════════════════════════════════════════════════════════════════════════
// RESUMEN DE LO QUE SE EJECUTA
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que se ejecutaría, tal como lo muestra la vista previa: la combinación,
/// sus nombres, las cifras de P y cuántos avisos (y reportes fuera) trae W.
/// Solo suma las filas que mandó el SP para mostrarlas.
class ResumenPreviaHex {
  const ResumenPreviaHex({
    required this.combinacion,
    required this.sucursal,
    required this.empresa,
    required this.empleados,
    required this.reportes,
    required this.montoHoras,
    required this.montoComidas,
    required this.total,
    required this.avisos,
    required this.fuera,
  });

  factory ResumenPreviaHex.de({
    required CombinacionHex combinacion,
    required String sucursal,
    required String empresa,
    required List<HexPrevistaEmpleadoEntity> filas,
    required List<HexAvisoEntity> avisos,
  }) {
    double suma(double Function(HexPrevistaEmpleadoEntity) f) =>
        filas.fold(0, (s, e) => s + f(e));
    return ResumenPreviaHex(
      combinacion: combinacion,
      sucursal: sucursal,
      empresa: empresa,
      empleados: filas.length,
      reportes: filas.fold(0, (s, e) => s + e.cantidadReportes),
      montoHoras: suma((e) => e.montoHoras),
      montoComidas: suma((e) => e.montoComidas),
      total: suma((e) => e.total),
      avisos: avisos.length,
      fuera: reportesFueraHex(avisos),
    );
  }

  final CombinacionHex combinacion;
  final String sucursal;
  final String empresa;
  final int empleados;
  final int reportes;
  final double montoHoras;
  final double montoComidas;
  final double total;
  final int avisos;

  /// Reportes que el SP deja fuera de la planilla (siguen aprobados).
  final int fuera;

  String get periodo => periodoHex(combinacion.anio, combinacion.mes);

  /// Si es el lote del mes (D39): todas las sucursales juntas.
  bool get esLote => esLoteHex(combinacion);

  /// Qué congela «Ejecutar planilla», con los conteos de P (no montos).
  String get detalle =>
      esLote && reportes == 0
          ? 'La vista previa no trae reportes aprobados de $periodo. Al '
              'ejecutar, el sistema te dice si hay algo que liquidar.'
          : 'Se congelarán ${cuentaHex(reportes, 'reporte', 'reportes')} de '
              '${cuentaHex(empleados, 'empleado', 'empleados')} de $sucursal, '
              '$periodo.';

  /// Lo que no se puede deshacer, en una nota de aviso del diálogo.
  static const String advertencia =
      'Después no se modifica; solo se puede anular.';
}

// ═══════════════════════════════════════════════════════════════════════════
// VISTA PREVIA
// ═══════════════════════════════════════════════════════════════════════════

/// La vista previa de [combinacion]: encabezado con «Ejecutar planilla», el
/// pie de cifras, los avisos (los provisionales primero), la tabla o las
/// tarjetas por empleado y la leyenda vigente. Va en el scroll de la pantalla.
class PrevistaHex extends ConsumerStatefulWidget {
  const PrevistaHex({
    super.key,
    required this.combinacion,
    required this.nombreSucursal,
    required this.altoMaximo,
    required this.alVolver,
    required this.alEjecutar,
    this.actualizando = false,
  });

  final CombinacionHex combinacion;
  final String nombreSucursal;

  /// El alto que puede tomar la tabla en el ancho (el de la ventana).
  final double altoMaximo;
  final VoidCallback alVolver;

  /// Nulo (botón deshabilitado) desde el primer toque hasta cerrar la
  /// confirmación o el PDF: un doble toque no abre dos confirmaciones.
  final ValueChanged<ResumenPreviaHex>? alEjecutar;

  /// Se recargan P y W antes de confirmar: el botón muestra la espera.
  final bool actualizando;

  @override
  ConsumerState<PrevistaHex> createState() => _PrevistaHexState();
}

class _PrevistaHexState extends ConsumerState<PrevistaHex> {
  /// Una clave por tipo de aviso: el semáforo lleva a su grupo.
  final Map<String, GlobalKey> _claves = {};

  GlobalKey _clave(String tipo) => _claves.putIfAbsent(tipo, GlobalKey.new);

  /// Lleva la pantalla al grupo de avisos de [tipo].
  void _irAlAviso(String tipo) {
    final contexto = _claves[tipo]?.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      alignment: 0.05,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.combinacion;
    final lote = esLoteHex(c);
    final nombreSucursal = widget.nombreSucursal;
    final altoMaximo = widget.altoMaximo;
    final codEmpresa = c.codEmpresa;
    final empresa =
        codEmpresa == null
            ? 'Cada sucursal con su empresa'
            : nombreEmpresaHex(ref, codEmpresa);
    final previa = ref.watch(hexVistaPreviaProvider(c));
    final avisos = ref.watch(hexAvisosProvider(c));
    final firmas = ref.watch(hexPendientesFirmaProvider(c));
    final filas = previa.valueOrNull;
    final listaAvisos = avisos.valueOrNull;
    // D39: mientras falte firmar algo del mes no se ejecuta (el SP lo
    // vuelve a validar). Si la lista falla, no bloquea.
    final faltaFirmar = firmas.valueOrNull?.isNotEmpty ?? false;
    // Sin P y W a la vista no se puede decir qué se congela: no se ejecuta.
    // El lote vacío sí: el SP responde con su texto de mes sin horas extra.
    final resumen =
        (filas == null ||
                (filas.isEmpty && !lote) ||
                listaAvisos == null ||
                faltaFirmar)
            ? null
            : ResumenPreviaHex.de(
              combinacion: c,
              sucursal: nombreSucursal,
              empresa: empresa,
              filas: filas,
              avisos: listaAvisos,
            );
    final ejecutar = widget.alEjecutar;
    final tiposConAviso = {
      for (final a in listaAvisos ?? const []) a.tipoAviso,
    };

    return LayoutBuilder(
      builder: (context, cons) {
        final ancho = usaTablaHex(cons.maxWidth, _anchoTablaPrevia);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CabeceraPreviaHex(
              titulo:
                  lote
                      ? 'Lote de ${periodoHex(c.anio, c.mes)}'
                      : '$nombreSucursal · ${periodoHex(c.anio, c.mes)}',
              empresa: lote ? nombreSucursal : 'Paga $empresa',
              alVolver: widget.alVolver,
              compacto: cons.maxWidth < hexAnchoTabla,
              ejecutar: PermissionWidget(
                buttonName: BotonHex.ejecutarPlanilla,
                child: SizedBox(
                  height: 48,
                  child: BotonAccion(
                    etiqueta: lote ? 'Ejecutar lote' : 'Ejecutar planilla',
                    etiquetaOcupado: 'Actualizando…',
                    icono: Icons.lock_outline,
                    ocupado: widget.actualizando,
                    onPressed:
                        resumen == null || ejecutar == null
                            ? null
                            : () => ejecutar(resumen),
                  ),
                ),
              ),
            ),
            if (listaAvisos != null) ...[
              const SizedBox(height: Esp.s),
              SemaforoAvisosHex(avisos: listaAvisos, alIr: _irAlAviso),
            ],
            if (resumen != null && resumen.reportes > 0) ...[
              const SizedBox(height: Esp.m),
              _CifrasPreviaHex(resumen),
            ],
            const SizedBox(height: Esp.l),
            SeccionFirmasHex(
              firmas: firmas,
              altoMaximo: altoMaximo,
              reintentar: () => ref.invalidate(hexPendientesFirmaProvider(c)),
            ),
            if (faltaFirmar) const SizedBox(height: Esp.l),
            SeccionAvisosHex(
              avisos: avisos,
              reintentar: () => ref.invalidate(hexAvisosProvider(c)),
              claves: {for (final t in tiposConAviso) t: _clave(t)},
            ),
            const SizedBox(height: Esp.l),
            Text('Por empleado', style: context.tituloSeccion()),
            const SizedBox(height: Esp.s),
            previa.when(
              skipLoadingOnReload: true,
              loading:
                  () => const SizedBox(
                    height: hexAltoEstado,
                    child: EsqueletoLista(),
                  ),
              error:
                  (e, _) => SizedBox(
                    height: hexAltoEstado,
                    child: vistaErrorHex(
                      e,
                      reintentar:
                          () => ref.invalidate(hexVistaPreviaProvider(c)),
                    ),
                  ),
              data: (f) {
                final lista = _ListaPreviaHex(
                  filas: f,
                  combinacion: c,
                  ancho: ancho,
                );
                // Con varias sucursales, cada franja ocupa una fila más.
                final grupos = gruposHex(f, (e) => e.codSucursal);
                return cajaTablaHex(
                  tabla: ancho,
                  filas: f.length + (grupos > 1 ? grupos : 0),
                  maximo: altoMaximo,
                  lista: lista,
                );
              },
            ),
            const SizedBox(height: Esp.l),
            const LeyendaHex(),
          ],
        );
      },
    );
  }
}

/// Volver, la combinación con la empresa que paga y la acción de ejecutar.
class _CabeceraPreviaHex extends StatelessWidget {
  const _CabeceraPreviaHex({
    required this.titulo,
    required this.empresa,
    required this.alVolver,
    required this.compacto,
    required this.ejecutar,
  });

  final String titulo;
  final String empresa;
  final VoidCallback alVolver;
  final bool compacto;
  final Widget ejecutar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: (compacto ? t.titleMedium : t.titleLarge)?.copyWith(
            fontWeight: Peso.titulo,
          ),
        ),
        const SizedBox(height: Esp.xs),
        Text(empresa, style: t.bodyMedium),
        const SizedBox(height: 2),
        Text(
          'Vista previa: los montos se calculan ahora y se congelan al '
          'ejecutar.',
          style: context.apagado(),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              visualDensity: VisualDensity.standard,
            ),
            onPressed: alVolver,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Volver a pendientes'),
          ),
        ),
        const SizedBox(height: Esp.xs),
        if (compacto) ...[
          textos,
          const SizedBox(height: Esp.m),
          ejecutar,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: textos),
              const SizedBox(width: Esp.l),
              ejecutar,
            ],
          ),
      ],
    );
  }
}

/// El pie de la vista previa: total en dinero, horas, comidas, empleados y
/// reportes.
class _CifrasPreviaHex extends StatelessWidget {
  const _CifrasPreviaHex(this.r);

  final ResumenPreviaHex r;

  @override
  Widget build(BuildContext context) => CifrasHex(
    tonoTotal: TonoHex.exito,
    principal: (rotulo: 'Total en dinero', valor: bsHex(r.total)),
    cifras: [
      (rotulo: 'Horas (Bs)', valor: bsHex(r.montoHoras)),
      (rotulo: 'Comidas (Bs)', valor: bsHex(r.montoComidas)),
      (rotulo: 'Empleados', valor: enteroHex(r.empleados)),
      (rotulo: 'Reportes', valor: enteroHex(r.reportes)),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// POR EMPLEADO (P)
// ═══════════════════════════════════════════════════════════════════════════

/// La tabla (ancho) o las tarjetas (angosto, en el scroll de la pantalla).
class _ListaPreviaHex extends StatelessWidget {
  const _ListaPreviaHex({
    required this.filas,
    required this.combinacion,
    required this.ancho,
  });

  final List<HexPrevistaEmpleadoEntity> filas;
  final CombinacionHex combinacion;
  final bool ancho;

  void _verLineas(BuildContext context, HexPrevistaEmpleadoEntity e) =>
      mostrarLineasPreviaHex(context, combinacion, e);

  /// D39: el lote junta sucursales; cada una lleva su franja, como el PDF.
  bool get _agrupar => gruposHex(filas, (e) => e.codSucursal) > 1;

  List<AccionHex> _acciones(
    BuildContext context,
    HexPrevistaEmpleadoEntity e,
  ) => [AccionHex('Ver líneas', Icons.list_alt, () => _verLineas(context, e))];

  @override
  Widget build(BuildContext context) {
    final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodyMedium);
    Widget monto(double v) => Text(bsHex(v), style: cifras);
    return ListadoHex<HexPrevistaEmpleadoEntity>(
      filas: filas,
      anchoMinimoTabla: _anchoTablaPrevia,
      desplazamientoExterno: !ancho,
      alTocarFila: (e) => _verLineas(context, e),
      vacio: const MensajeVacio(
        icono: Icons.inbox_outlined,
        titulo: 'No hay reportes para liquidar',
        detalle:
            'Revisa los avisos: explican qué reportes quedan fuera y por qué.',
      ),
      cabeceraAntesDe:
          _agrupar
              ? cabeceraPorGrupoHex(
                filas,
                (e) => e.codSucursal,
                (e) => FranjaGrupoHex(
                  titulo: sucursalHex(e.nombreSucursal, e.codSucursal),
                  enTabla: ancho,
                ),
              )
              : null,
      columnas: [
        BosqueColumn(
          label: 'Empleado',
          flex: 4,
          cellBuilder:
              (e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    oGuionHex(e.nombreEmpleado),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  Text(
                    cuentaHex(e.cantidadReportes, 'reporte', 'reportes'),
                    style: context.apagado(),
                  ),
                ],
              ),
        ),
        // D39: por sucursal, no por área.
        BosqueColumn(
          label: 'Sucursal',
          flex: 2,
          cellBuilder:
              (e) => Text(sucursalHex(e.nombreSucursal, e.codSucursal)),
        ),
        BosqueColumn(
          label: 'Horas (Bs)',
          flex: 2,
          alignment: Alignment.centerRight,
          cellBuilder: (e) => monto(e.montoHoras),
        ),
        BosqueColumn(
          label: 'Comidas (Bs)',
          flex: 2,
          alignment: Alignment.centerRight,
          cellBuilder: (e) => monto(e.montoComidas),
        ),
        BosqueColumn(
          label: 'Total (Bs)',
          flex: 2,
          alignment: Alignment.centerRight,
          cellBuilder: (e) => MontoHex(e.total, provisional: e.esProvisional),
        ),
        BosqueColumn(
          label: 'Marcas',
          flex: 4,
          cellBuilder:
              (e) => Wrap(
                spacing: Esp.xs,
                runSpacing: Esp.xs,
                children: _marcas(e),
              ),
        ),
        BosqueColumn(
          label: '',
          flex: 1,
          alignment: Alignment.centerRight,
          cellBuilder: (e) => AccionesHex(acciones: _acciones(context, e)),
        ),
      ],
      tarjeta:
          (e) => TarjetaHex(
            titulo: oGuionHex(e.nombreEmpleado),
            subtitulo: [
              if (e.codSucursal != null || e.nombreSucursal != null)
                sucursalHex(e.nombreSucursal, e.codSucursal),
              cuentaHex(e.cantidadReportes, 'reporte', 'reportes'),
            ].join(' · '),
            alTocar: () => _verLineas(context, e),
            acciones: _acciones(context, e),
            contenido: _MontosTarjetaHex(e),
            etiquetas: _marcas(e),
          ),
    );
  }

  /// Lo que hay que mirar de un empleado. «provisional» va junto al monto.
  static List<Widget> _marcas(HexPrevistaEmpleadoEntity e) => [
    if (e.tieneAvisoBiometrico) const EtiquetaAvisoBiometricoHex(),
    if (e.tienePeriodoAnterior)
      const ChipHex(
        texto: 'De período anterior',
        icono: Icons.history,
        tono: TonoHex.pendiente,
        ayuda: 'Incluye reportes de meses anteriores que no se habían pagado.',
      ),
  ];
}

/// Horas, comidas y total de un empleado en la tarjeta del teléfono.
class _MontosTarjetaHex extends StatelessWidget {
  const _MontosTarjetaHex(this.e);

  final HexPrevistaEmpleadoEntity e;

  @override
  Widget build(BuildContext context) {
    final cifras = estiloCifrasHex(Theme.of(context).textTheme.bodyMedium);
    Widget fila(String rotulo, Widget valor) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(rotulo, style: context.apagado())),
          const SizedBox(width: Esp.s),
          Flexible(flex: 2, child: valor),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fila('Horas (Bs)', Text(bsHex(e.montoHoras), style: cifras)),
        fila('Comidas (Bs)', Text(bsHex(e.montoComidas), style: cifras)),
        fila('Total (Bs)', MontoHex(e.total, provisional: e.esProvisional)),
      ],
    );
  }
}
