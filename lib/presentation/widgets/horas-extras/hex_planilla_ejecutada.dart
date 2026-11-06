/// Planillas de horas extra ya ejecutadas (RRHH): la lista (también para
/// «Anular planilla») y una planilla con su resumen por empleado, el anexo de
/// detalle, la leyenda congelada y el PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_empresas.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_anexos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Ancho mínimo de la tabla de planillas; por debajo, tarjetas.
const double anchoTablaPlanillasHex = 1100;

/// Abre el PDF congelado de [p] con el visor del módulo (204 → «sin datos»).
Future<void> verPdfPlanillaHex(
  BuildContext context,
  WidgetRef ref,
  HexPlanillaEntity p,
) async {
  final id = p.idPlanilla;
  if (id == null) return;
  final repo = ref.read(hexPlanillaRepositoryProvider);
  await verPdfHex(
    context,
    generar: () => repo.pdf(id),
    titulo: 'Planilla de horas extra',
    nombreArchivo: 'planilla_horas_extra_$id.pdf',
  );
}

/// D39: el PDF del lote de [p] (una sección por sucursal y el total general).
Future<void> verPdfLoteHex(
  BuildContext context,
  WidgetRef ref,
  HexPlanillaEntity p,
) async {
  final lote = p.idLote;
  if (lote == null) return;
  final repo = ref.read(hexPlanillaRepositoryProvider);
  await verPdfHex(
    context,
    generar: () => repo.pdfLote(lote),
    titulo: 'Lote de planillas de horas extra',
    nombreArchivo: 'lote_horas_extra_$lote.pdf',
  );
}

/// «Lote N» si la planilla se ejecutó con el lote del mes (D39).
class EtiquetaLoteHex extends StatelessWidget {
  const EtiquetaLoteHex(this.planilla, {super.key});

  final HexPlanillaEntity planilla;

  @override
  Widget build(BuildContext context) {
    final lote = planilla.idLote;
    if (lote == null) return const SizedBox.shrink();
    return ChipHex(
      texto: 'Lote $lote',
      icono: Icons.layers_outlined,
      ayuda: 'Se ejecutó junto con las demás sucursales del mes.',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTA DE PLANILLAS
// ═══════════════════════════════════════════════════════════════════════════

/// Los estados de una planilla (`p_list_thex_Planilla` L).
const String _ejecutada = 'EJECUTADA';
const String _anulada = 'ANULADA';

/// Si la planilla está ejecutada y vigente: es la que se puede anular.
bool planillaEjecutadaHex(HexPlanillaEntity p) => p.estado == _ejecutada;

/// Si la planilla fue anulada: ya no se paga.
bool planillaAnuladaHex(HexPlanillaEntity p) => p.estado == _anulada;

/// Quién, cuándo y por qué se anuló, tal como lo guardó el SP.
String textoAnulacionPlanillaHex(HexPlanillaEntity p) =>
    'Anulada por ${oGuionHex(p.nombreAnulador)} el '
    '${fechaHoraHex(p.fechaAnulacion)}. Motivo: ${oGuionHex(p.motivoAnulacion)}';

/// El nombre de la empresa que paga [p], o un guion si el SP no la mandó.
String empresaPlanillaHex(WidgetRef ref, HexPlanillaEntity p) {
  final cod = p.codEmpresa;
  return cod == null ? '—' : nombreEmpresaHex(ref, cod);
}

/// El total de una planilla. Una anulada no se paga: va en tono apagado y lo
/// dice. [alineado] acomoda las dos piezas si no caben en una línea.
class TotalPlanillaHex extends StatelessWidget {
  const TotalPlanillaHex(
    this.planilla, {
    super.key,
    this.alineado = WrapAlignment.start,
  });

  final HexPlanillaEntity planilla;
  final WrapAlignment alineado;

  @override
  Widget build(BuildContext context) {
    final p = planilla;
    if (!planillaAnuladaHex(p)) return MontoHex(p.total);
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      alignment: alineado,
      spacing: Esp.s,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          bsHex(p.total),
          style: estiloCifrasHex(
            Theme.of(context).textTheme.bodyMedium,
          )?.copyWith(color: cs.onSurfaceVariant),
        ),
        const Etiqueta(texto: 'no se paga'),
      ],
    );
  }
}

/// Las columnas de la lista de planillas; [acciones] las pone cada pantalla
/// (ver, PDF, anular) y `AccionesHex` las filtra por botón. Con
/// [conAnulacion], el estado de una anulada trae quién, cuándo y por qué.
List<BosqueColumn<HexPlanillaEntity>> columnasPlanillasHex(
  BuildContext context,
  WidgetRef ref, {
  required List<AccionHex> Function(HexPlanillaEntity) acciones,
  bool conAnulacion = false,
}) {
  final t = Theme.of(context).textTheme;
  return [
    BosqueColumn(
      label: 'Período',
      flex: 2,
      cellBuilder:
          (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                oGuionHex(p.periodoTexto),
                style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
              ),
              if (p.idLote != null) ...[
                const SizedBox(height: 2),
                EtiquetaLoteHex(p),
              ],
            ],
          ),
    ),
    BosqueColumn(
      label: 'Sucursal',
      flex: 2,
      cellBuilder: (p) => Text(sucursalHex(p.nombreSucursal, p.codSucursal)),
    ),
    BosqueColumn(
      label: 'Empresa',
      flex: 2,
      cellBuilder: (p) => Text(empresaPlanillaHex(ref, p)),
    ),
    BosqueColumn(
      label: 'Estado',
      flex: conAnulacion ? 5 : 2,
      cellBuilder:
          (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              EtiquetaEstadoHex(p.estado, p.estadoTexto),
              if (conAnulacion && planillaAnuladaHex(p)) ...[
                const SizedBox(height: Esp.xs),
                Text(textoAnulacionPlanillaHex(p), style: context.apagado()),
              ],
            ],
          ),
    ),
    BosqueColumn(
      label: 'Total (Bs)',
      flex: 2,
      alignment: Alignment.centerRight,
      cellBuilder: (p) => TotalPlanillaHex(p, alineado: WrapAlignment.end),
    ),
    BosqueColumn(
      label: 'Empleados',
      flex: 2,
      alignment: Alignment.centerRight,
      cellBuilder:
          (p) => Text(
            enteroHex(p.cantidadEmpleados),
            style: estiloCifrasHex(t.bodyMedium),
          ),
    ),
    BosqueColumn(
      label: 'Reportes',
      flex: 2,
      alignment: Alignment.centerRight,
      cellBuilder:
          (p) => Text(
            enteroHex(p.cantidadReportes),
            style: estiloCifrasHex(t.bodyMedium),
          ),
    ),
    BosqueColumn(
      label: 'Ejecutó',
      flex: 3,
      cellBuilder:
          (p) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(oGuionHex(p.nombreEjecutor)),
              Text(
                fechaHoraHex(p.fechaEjecucion),
                style: estiloCifrasHex(context.apagado()),
              ),
            ],
          ),
    ),
    BosqueColumn(
      label: '',
      flex: 2,
      alignment: Alignment.centerRight,
      cellBuilder: (p) => AccionesHex(acciones: acciones(p)),
    ),
  ];
}

/// Una planilla en el teléfono: período y sucursal, empresa, total, cuántos
/// empleados y reportes, quién la ejecutó y su estado. Con [conAnulacion],
/// una anulada trae quién, cuándo y por qué.
class TarjetaPlanillaHex extends ConsumerWidget {
  const TarjetaPlanillaHex(
    this.planilla, {
    super.key,
    this.acciones = const [],
    this.alTocar,
    this.conAnulacion = false,
    this.principales = const {},
  });

  final HexPlanillaEntity planilla;
  final List<AccionHex> acciones;
  final VoidCallback? alTocar;
  final bool conAnulacion;

  /// Los botones cuya acción va a la vista en la tarjeta (imprimir es el paso
  /// final); el resto queda en el menú.
  final Set<String> principales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = planilla;
    final principal = accionPrincipalHex(acciones, principales);
    return TarjetaHex(
      titulo:
          '${sucursalHex(p.nombreSucursal, p.codSucursal)} · '
          '${oGuionHex(p.periodoTexto)}',
      subtitulo: empresaPlanillaHex(ref, p),
      accionPrincipal: principal,
      acciones: [
        for (final a in acciones)
          if (a != principal) a,
      ],
      alTocar: alTocar,
      contenido: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TotalPlanillaHex(p),
          const SizedBox(height: 2),
          Text(
            '${cuentaHex(p.cantidadEmpleados, 'empleado', 'empleados')} · '
            '${cuentaHex(p.cantidadReportes, 'reporte', 'reportes')}',
            style: context.apagado(),
          ),
          Text(
            'Ejecutó ${oGuionHex(p.nombreEjecutor)} · '
            '${fechaHoraHex(p.fechaEjecucion)}',
            style: context.apagado(),
          ),
          if (conAnulacion && planillaAnuladaHex(p))
            NotaDelDato(
              tono: TonoNota.error,
              icono: Icons.block,
              texto: textoAnulacionPlanillaHex(p),
            ),
        ],
      ),
      etiquetas: [
        EtiquetaEstadoHex(p.estado, p.estadoTexto),
        if (p.idLote != null) EtiquetaLoteHex(p),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UNA PLANILLA EJECUTADA
// ═══════════════════════════════════════════════════════════════════════════

enum _SeccionHex { resumen, anexo }

/// Una planilla ejecutada: encabezado con su estado y el PDF, el pie de
/// cifras congeladas (las del SP), una sección a la vez y la leyenda
/// congelada al final. Va en el scroll de la pantalla.
class EjecutadaHex extends ConsumerStatefulWidget {
  const EjecutadaHex({
    super.key,
    required this.planilla,
    required this.altoMaximo,
    required this.alVolver,
  });

  final HexPlanillaEntity planilla;

  /// El alto que puede tomar una tabla en el ancho (el de la ventana).
  final double altoMaximo;
  final VoidCallback alVolver;

  @override
  ConsumerState<EjecutadaHex> createState() => _EjecutadaHexState();
}

class _EjecutadaHexState extends ConsumerState<EjecutadaHex> {
  _SeccionHex _seccion = _SeccionHex.resumen;

  @override
  Widget build(BuildContext context) {
    final p = widget.planilla;
    final id = p.idPlanilla;
    if (id == null) {
      return const SizedBox(
        height: hexAltoEstado,
        child: MensajeVacio(
          icono: Icons.search_off,
          titulo: 'No se encontró la planilla',
          detalle: 'Vuelve a la lista y elígela otra vez.',
        ),
      );
    }
    final anulada = planillaAnuladaHex(p);
    return LayoutBuilder(
      builder: (context, c) {
        final compacto = c.maxWidth < hexAnchoTabla;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CabeceraEjecutadaHex(
              planilla: p,
              empresa: empresaPlanillaHex(ref, p),
              compacto: compacto,
              alVolver: widget.alVolver,
              alPdf: () => verPdfPlanillaHex(context, ref, p),
            ),
            if (anulada)
              NotaDelDato(
                tono: TonoNota.error,
                icono: Icons.block,
                texto: textoAnulacionPlanillaHex(p),
              ),
            const SizedBox(height: Esp.l),
            // Anulada no se paga: el total va sin la doble raya contable.
            CifrasHex(
              contable: !anulada,
              tonoTotal: TonoHex.exito,
              principal: (
                rotulo:
                    anulada ? 'Total (anulada, no se paga)' : 'Total en dinero',
                valor: bsHex(p.total),
              ),
              cifras: [
                (rotulo: 'Horas (Bs)', valor: bsHex(p.totalHoras)),
                (rotulo: 'Comidas (Bs)', valor: bsHex(p.totalComidas)),
                (rotulo: 'Empleados', valor: enteroHex(p.cantidadEmpleados)),
                (rotulo: 'Reportes', valor: enteroHex(p.cantidadReportes)),
              ],
            ),
            const SizedBox(height: Esp.l),
            _selector(),
            const SizedBox(height: Esp.m),
            switch (_seccion) {
              _SeccionHex.resumen => _resumen(id),
              _SeccionHex.anexo => _anexo(id),
            },
            const SizedBox(height: Esp.l),
            _leyenda(id),
          ],
        );
      },
    );
  }

  /// Una sección a la vez; las fichas envuelven con letra grande.
  Widget _selector() => Wrap(
    spacing: Esp.s,
    runSpacing: Esp.s,
    children: [
      for (final (s, texto) in const [
        (_SeccionHex.resumen, 'Resumen'),
        (_SeccionHex.anexo, 'Anexo de detalle'),
      ])
        ChoiceChip(
          label: Text(texto),
          selected: _seccion == s,
          // 48 px de área táctil también con la densidad del escritorio.
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          onSelected: (_) {
            HapticaHex.seleccion();
            setState(() => _seccion = s);
          },
        ),
    ],
  );

  /// La espera, el error o el contenido de una sección.
  Widget _seccionDe<T>(
    AsyncValue<T> valor,
    VoidCallback reintentar,
    Widget Function(T datos) contenido,
  ) => valor.when(
    skipLoadingOnReload: true,
    loading:
        () => const SizedBox(height: hexAltoEstado, child: EsqueletoLista()),
    error:
        (e, _) => SizedBox(
          height: hexAltoEstado,
          child: vistaErrorHex(e, reintentar: reintentar),
        ),
    data: contenido,
  );

  Widget _resumen(BigInt id) => _seccionDe(
    ref.watch(hexResumenPlanillaProvider(id)),
    () => ref.invalidate(hexResumenPlanillaProvider(id)),
    (filas) => ResumenPlanillaHex(filas, altoMaximo: widget.altoMaximo),
  );

  Widget _anexo(BigInt id) => _seccionDe(
    ref.watch(hexAnexoPlanillaProvider(id)),
    () => ref.invalidate(hexAnexoPlanillaProvider(id)),
    (filas) => AnexoPlanillaHex(filas, altoMaximo: widget.altoMaximo),
  );

  Widget _leyenda(BigInt id) => ref
      .watch(hexLeyendaPlanillaProvider(id))
      .when(
        skipLoadingOnReload: true,
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error:
            (e, _) => NotaDelDato(
              texto: textoErrorHex(e),
              tono: TonoNota.error,
              accion: TextButton(
                onPressed: () => ref.invalidate(hexLeyendaPlanillaProvider(id)),
                child: const Text('Reintentar'),
              ),
            ),
        data: LeyendaPlanillaHex.new,
      );
}

/// Volver, sucursal y período, el estado, la empresa, quién la ejecutó y
/// el botón del PDF.
class _CabeceraEjecutadaHex extends StatelessWidget {
  const _CabeceraEjecutadaHex({
    required this.planilla,
    required this.empresa,
    required this.compacto,
    required this.alVolver,
    required this.alPdf,
  });

  final HexPlanillaEntity planilla;
  final String empresa;
  final bool compacto;
  final VoidCallback alVolver;
  final VoidCallback alPdf;

  @override
  Widget build(BuildContext context) {
    final p = planilla;
    final t = Theme.of(context).textTheme;
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${sucursalHex(p.nombreSucursal, p.codSucursal)} · '
              '${oGuionHex(p.periodoTexto)}',
              style: (compacto ? t.titleMedium : t.titleLarge)?.copyWith(
                fontWeight: Peso.titulo,
              ),
            ),
            EtiquetaEstadoHex(p.estado, p.estadoTexto),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text('Paga $empresa', style: t.bodyMedium),
        const SizedBox(height: 2),
        Text(
          'Planilla N.º ${p.idPlanilla} · ejecutó ${oGuionHex(p.nombreEjecutor)}'
          ' el ${fechaHoraHex(p.fechaEjecucion)}',
          style: context.apagado(),
        ),
      ],
    );
    final pdf = PermissionWidget(
      buttonName: BotonHex.pdfPlanilla,
      child: SizedBox(
        height: 48,
        child: BotonAccion(
          etiqueta: 'Imprimir / PDF',
          icono: Icons.print_outlined,
          tonal: true,
          onPressed: alPdf,
        ),
      ),
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
            label: const Text('Volver a ejecutadas'),
          ),
        ),
        const SizedBox(height: Esp.xs),
        if (compacto) ...[
          textos,
          const SizedBox(height: Esp.m),
          Align(alignment: Alignment.centerLeft, child: pdf),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: textos),
              const SizedBox(width: Esp.l),
              pdf,
            ],
          ),
      ],
    );
  }
}
