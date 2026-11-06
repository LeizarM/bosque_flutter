/// Anular una planilla de horas extra o su lote entero (D39): la confirmación
/// dice qué se anula y pide el motivo. Las reglas y los mensajes (motivo
/// obligatorio, ya anulada, qué pasa con los reportes) son del SP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_ejecutada.dart';

/// Lo que pasa con los reportes de lo anulado (D39): no se vuelven a pagar.
const String _efectoAnulacion =
    'Sus reportes quedan anulados para siempre: no vuelven a ninguna planilla '
    'ni se pueden volver a ejecutar.';

/// Abre la confirmación de [planilla]. [refrescar] corre si se anuló o si ya
/// estaba anulada (409), y solo con la pantalla que lo abrió montada.
Future<void> anularPlanillaHex(
  BuildContext context,
  WidgetRef ref,
  HexPlanillaEntity planilla, {
  required VoidCallback refrescar,
}) async {
  final id = planilla.idPlanilla;
  if (id == null) return;
  final repo = ref.read(hexPlanillaRepositoryProvider);
  final p = planilla;
  await abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _DialogoAnularHex(
          titulo: 'Anular planilla',
          detalle:
              'Se anulará la planilla de '
              '${sucursalHex(p.nombreSucursal, p.codSucursal)}, '
              '${oGuionHex(p.periodoTexto)}, por ${bsHex(p.total)}. '
              '$_efectoAnulacion',
          apoyo:
              (ref) =>
                  'Paga ${empresaPlanillaHex(ref, p)} · '
                  '${cuentaHex(p.cantidadEmpleados, 'empleado', 'empleados')} · '
                  '${cuentaHex(p.cantidadReportes, 'reporte', 'reportes')}',
          refrescar: recargar,
          anular: (motivo) => repo.anular(id, motivo),
        ),
  );
}

/// D39: anula todas las planillas del lote de [planilla]. [delLote] son las
/// que la lista ya trae de ese lote, solo para decir cuáles se anulan.
Future<void> anularLoteHex(
  BuildContext context,
  WidgetRef ref,
  HexPlanillaEntity planilla, {
  required List<HexPlanillaEntity> delLote,
  required VoidCallback refrescar,
}) async {
  final lote = planilla.idLote;
  if (lote == null) return;
  final repo = ref.read(hexPlanillaRepositoryProvider);
  final sucursales = [
    for (final p in delLote) sucursalHex(p.nombreSucursal, p.codSucursal),
  ].join(', ');
  await abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _DialogoAnularHex(
          titulo: 'Anular lote',
          detalle:
              'Se anulará el lote $lote de '
              '${oGuionHex(planilla.periodoTexto)}: '
              '${cuentaHex(delLote.length, 'planilla', 'planillas')}'
              '${sucursales.isEmpty ? '' : ' ($sucursales)'}. '
              '$_efectoAnulacion',
          refrescar: recargar,
          anular: (motivo) => repo.anularLote(lote, motivo),
        ),
  );
}

class _DialogoAnularHex extends ConsumerStatefulWidget {
  const _DialogoAnularHex({
    required this.titulo,
    required this.detalle,
    required this.refrescar,
    required this.anular,
    this.apoyo,
  });

  final String titulo;
  final String detalle;

  /// Una línea apagada bajo el detalle (necesita `ref`: nombra la empresa).
  final String Function(WidgetRef ref)? apoyo;
  final VoidCallback refrescar;
  final Future<HexRespuesta> Function(String motivo) anular;

  @override
  ConsumerState<_DialogoAnularHex> createState() => _DialogoAnularHexState();
}

class _DialogoAnularHexState extends ConsumerState<_DialogoAnularHex>
    with EscrituraEnDialogoHex {
  final TextEditingController _motivo = TextEditingController();

  @override
  VoidCallback get refrescarLista => widget.refrescar;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  // Sin motivo viaja vacío y el SP responde con su mensaje (400).
  void _anular() {
    FocusManager.instance.primaryFocus?.unfocus();
    final motivo = _motivo.text.trim();
    escribir((_) => widget.anular(motivo));
  }

  @override
  Widget build(BuildContext context) {
    final apoyo = widget.apoyo?.call(ref);
    return DialogoHex(
      titulo: widget.titulo,
      icono: Icons.warning_amber_rounded,
      destructiva: true,
      ocupado: ocupado,
      accion: widget.titulo,
      alAceptar: _anular,
      contenido:
          (enCurso) => [
            Text(widget.detalle, style: Theme.of(context).textTheme.bodyMedium),
            if (apoyo != null) ...[
              const SizedBox(height: Esp.s),
              Text(apoyo, style: context.apagado()),
            ],
            const SizedBox(height: Esp.l),
            TextoLargoHex(
              control: _motivo,
              etiqueta: 'Motivo de la anulación',
              ayuda: 'Obligatorio.',
              autofocus: true,
              habilitado: !enCurso,
            ),
          ],
    );
  }
}
