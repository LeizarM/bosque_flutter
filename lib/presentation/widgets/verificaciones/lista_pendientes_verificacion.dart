/// La lista del modal «Cheques pendientes sin regularizar»: los cheques que
/// todavia no tienen una verificacion valida. Tabla en un dialogo ancho y tarjetas
/// en uno angosto o a pantalla completa. Cada cheque abierto lleva un
/// «Seleccionar»; uno cerrado se lista pero no se puede elegir (el legacy no
/// ofrecia el boton y el servidor tampoco lo acepta).
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_pendiente_verificacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/piezas_verificacion.dart';
import 'package:bosque_flutter/presentation/widgets/verificaciones/tabla_verificaciones.dart';

typedef AlSeleccionarPendiente = void Function(ChequePendienteVerificacionEntity cheque);

/// Lo que explica por que un cheque cerrado no se puede elegir.
const String textoChequeCerrado =
    'Un cheque cerrado no se puede verificar: ya está resuelto.';

/// Ancho de la celda del boton «Seleccionar».
const double _anchoSeleccionar = 136;

const List<ColumnaTabla> _columnas = [
  ColumnaTabla('num', '#', ancho: 40, descarte: 3),
  ColumnaTabla('nro', 'Nro. cheque', ancho: 104),
  ColumnaTabla('monto', 'Monto', ancho: 132, derecha: true),
  ColumnaTabla('bancoCheque', 'Banco del cheque', flex: 2),
  ColumnaTabla('fcobranza', 'F. cobranza', ancho: 96, descarte: 1),
  ColumnaTabla('estadoCheque', 'Estado cheque', ancho: 112, descarte: 2),
  ColumnaTabla('verificacion', 'Verificación', ancho: 116),
];

class ListaPendientesVerificacion extends StatelessWidget {
  const ListaPendientesVerificacion({
    super.key,
    required this.filas,
    required this.onSeleccionar,
    required this.pie,
    this.ocupado = false,
  });

  final List<ChequePendienteVerificacionEntity> filas;
  final AlSeleccionarPendiente onSeleccionar;
  final Widget pie;

  /// Hay una preparacion en vuelo: los botones se apagan para no abrir dos.
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= anchoMinimoTablaVerificacion) {
          return TablaVerificaciones(
            key: const ValueKey('pendientes-tabla'),
            columnas: _columnas,
            anchoAcciones: _anchoSeleccionar,
            tituloAcciones: 'Acción',
            cantidad: filas.length,
            pie: pie,
            filaDe:
                (plan, i) => _FilaPendiente(
                  key: ValueKey('pendiente-${filas[i].codCheque}'),
                  indice: i,
                  cheque: filas[i],
                  plan: plan,
                  onSeleccionar: ocupado ? null : onSeleccionar,
                ),
          );
        }
        final diseno = disenoDeTarjetas(constraints.maxWidth);
        return Column(
          key: const ValueKey('pendientes-tarjetas'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: Esp.m,
              runSpacing: Esp.m,
              children: [
                for (final f in filas)
                  SizedBox(
                    key: ValueKey('pendiente-${f.codCheque}'),
                    width: diseno.ancho,
                    child: _TarjetaPendiente(
                      cheque: f,
                      onSeleccionar: ocupado ? null : onSeleccionar,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Esp.m),
            pie,
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLA
// ═══════════════════════════════════════════════════════════════════════════

class _FilaPendiente extends StatelessWidget {
  const _FilaPendiente({
    super.key,
    required this.indice,
    required this.cheque,
    required this.plan,
    required this.onSeleccionar,
  });

  final int indice;
  final ChequePendienteVerificacionEntity cheque;
  final PlanTabla plan;
  final AlSeleccionarPendiente? onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cifras = context.cifraCheque();
    final c = cheque.cheque;

    Widget celda(ColumnaTabla col) => switch (col.id) {
      'num' => Text(
        '${cheque.fila}',
        style: cifras.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
      ),
      'nro' => TextoCelda(
        textoODash(c.nroCheque),
        estilo: context.cifraCheque(fuerte: true),
      ),
      'monto' => ImporteVerificacion(cheque: c),
      'bancoCheque' => BancoCheque(c.datoBancoCheque),
      'fcobranza' => Text(
        textoFecha(c.fechaCobrarCheque),
        style: cifras,
        maxLines: 1,
      ),
      'estadoCheque' => EtiquetaEstadoCheque(
        estado: c.chequeCerrado ? 'CER' : 'PEN',
        texto: c.datoEstadoCheque,
      ),
      'verificacion' => const PastillaSinVerificar(),
      _ => const SizedBox.shrink(),
    };

    return FilaTablaVerificacion(
      indice: indice,
      // Lo que falta verificar va en aviso; un cheque cerrado, apagado: no hay
      // nada que hacer con el.
      franja:
          cheque.seleccionable
              ? ChequesColores.pleno(context, SemanticaCheque.aviso)
              : cs.outlineVariant,
      plan: plan,
      celda: celda,
      acciones: (_) => AccionSeleccionar(cheque: cheque, onSeleccionar: onSeleccionar),
    );
  }
}

/// «Seleccionar», o la explicacion de por que no se puede (cheque cerrado).
class AccionSeleccionar extends StatelessWidget {
  const AccionSeleccionar({
    super.key,
    required this.cheque,
    required this.onSeleccionar,
    this.ancho = false,
  });

  final ChequePendienteVerificacionEntity cheque;
  final AlSeleccionarPendiente? onSeleccionar;

  /// El boton ocupa todo el ancho (en una tarjeta).
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!cheque.seleccionable) {
      return Tooltip(
        message: textoChequeCerrado,
        child: Row(
          mainAxisSize: ancho ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              ancho ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: Esp.xs),
            Flexible(
              child: Text(
                'Cerrado',
                style: context.apagado(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    final boton = FilledButton.tonalIcon(
      key: ValueKey('seleccionar-${cheque.codCheque}'),
      onPressed: onSeleccionar == null ? null : () => onSeleccionar!(cheque),
      icon: const Icon(Icons.fact_check_outlined, size: 18),
      label: const Text('Seleccionar'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: Esp.m),
      ),
    );
    return ancho ? SizedBox(width: double.infinity, child: boton) : boton;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

class _TarjetaPendiente extends StatelessWidget {
  const _TarjetaPendiente({required this.cheque, required this.onSeleccionar});

  final ChequePendienteVerificacionEntity cheque;
  final AlSeleccionarPendiente? onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final c = cheque.cheque;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l + 4, Esp.m, Esp.m, Esp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Esp.s,
                  runSpacing: Esp.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InsigniaFila('#${cheque.fila}'),
                    const PastillaSinVerificar(),
                    EtiquetaEstadoCheque(
                      estado: c.chequeCerrado ? 'CER' : 'PEN',
                      texto: c.datoEstadoCheque,
                    ),
                  ],
                ),
                const SizedBox(height: Esp.s),
                Text(
                  'Cheque ${textoODash(c.nroCheque)}',
                  style: context.cifraCheque(fuerte: true, tam: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Esp.s),
                Row(
                  children: [
                    MonogramaBanco(c.datoBancoCheque),
                    const SizedBox(width: Esp.s),
                    Expanded(
                      child: Text(
                        textoODash(c.datoBancoCheque),
                        style: t.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.m),
                ImporteVerificacion(
                  cheque: c,
                  tam: 22,
                  alineacion: Alignment.centerLeft,
                ),
                const SizedBox(height: Esp.s),
                Text('Fecha de cobranza', style: context.apagado()),
                const SizedBox(height: 2),
                Text(
                  textoFecha(c.fechaCobrarCheque),
                  style: context.cifraCheque(),
                ),
                const SizedBox(height: Esp.m),
                AccionSeleccionar(
                  cheque: cheque,
                  onSeleccionar: onSeleccionar,
                  ancho: true,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: FranjaCheque(
              color:
                  cheque.seleccionable
                      ? ChequesColores.pleno(context, SemanticaCheque.aviso)
                      : cs.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}
