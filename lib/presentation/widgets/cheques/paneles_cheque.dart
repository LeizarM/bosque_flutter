/// Los tres paneles del detalle del cheque: notas de remision, transacciones
/// bancarias y postergaciones. Reemplazan a los tres `p:dataTable` de
/// `cheque.xhtml` que se veian al entrar con «Completar».
///
/// **Lo que se conserva del legacy.** «Nuevo» (en los tres) lo gobierna
/// `btnNuevoNRCH`; eliminar una nota, `btnEliminarNRCH`; eliminar una
/// transaccion o una postergacion y todo el PDF de la postergacion **no tienen
/// boton**, asi que se dibujan siempre. Ninguna depende del estado del cheque:
/// se puede anotar una nota o una transaccion en un cheque cerrado. Eliminar
/// siempre pide confirmacion. El servidor repite cada regla.
///
/// **Cada panel se pide por separado** (`notasRemisionChequeProvider` y
/// compania): uno que falla o tarda no deja a los otros sin dibujar.
///
/// El color solo sale de `ChequesColores` y del `ColorScheme`; lo que importa
/// lleva ademas texto e icono, nunca solo color.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/dialogos_paneles_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_postergacion.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

/// Ancho desde el cual los tres paneles van en columnas.
const double anchoTresColumnasPaneles = 1000;

/// Ancho desde el cual van en dos columnas (notas y transacciones a un lado,
/// postergaciones al otro).
const double anchoDosColumnasPaneles = 640;

// ═══════════════════════════════════════════════════════════════════════════
// DISPOSICION
// ═══════════════════════════════════════════════════════════════════════════

/// Los tres paneles. Con ancho se reparten en columnas **sin sumar altura**: la
/// fila mide lo que el mas alto, no la suma de los tres. Con poco ancho van uno
/// sobre otro.
class PanelesSatelitesCheque extends StatelessWidget {
  const PanelesSatelitesCheque({super.key, required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  Widget build(BuildContext context) {
    final notas = PanelNotasRemisionCheque(cheque: cheque);
    final transacciones = PanelTransaccionesCheque(cheque: cheque);
    final postergaciones = PanelPostergacionesCheque(cheque: cheque);
    const hueco = SizedBox(height: Esp.l);

    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth >= anchoTresColumnasPaneles) {
          return Row(
            // start: cada panel mide lo suyo, sin estirar al mas corto.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 10, child: notas),
              const SizedBox(width: Esp.l),
              Expanded(flex: 10, child: transacciones),
              const SizedBox(width: Esp.l),
              Expanded(flex: 12, child: postergaciones),
            ],
          );
        }
        if (box.maxWidth >= anchoDosColumnasPaneles) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [notas, hueco, transacciones],
                ),
              ),
              const SizedBox(width: Esp.l),
              Expanded(child: postergaciones),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [notas, hueco, transacciones, hueco, postergaciones],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS COMUNES
// ═══════════════════════════════════════════════════════════════════════════

/// La tarjeta de un panel: icono con el color de su tema, titulo, contador y el
/// boton «Nuevo» (solo si [alNuevo] no es null, es decir, con permiso).
class _PanelSatelite extends StatelessWidget {
  const _PanelSatelite({
    super.key,
    required this.titulo,
    required this.icono,
    required this.tono,
    required this.cuenta,
    required this.hijo,
    this.alNuevo,
    this.tooltipNuevo,
    this.claveNuevo,
  });

  final String titulo;
  final IconData icono;
  final SemanticaCheque tono;

  /// Cuantos hay; null mientras se carga o si fallo la carga.
  final int? cuenta;
  final Widget hijo;
  final VoidCallback? alNuevo;
  final String? tooltipNuevo;
  final Key? claveNuevo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IconoDePanel(icono: icono, tono: tono),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(titulo, style: context.tituloSeccion()),
                ),
                if (cuenta != null) ...[
                  const SizedBox(width: Esp.s),
                  _Contador(cuenta!, tono: tono),
                ],
                if (alNuevo != null) ...[
                  const SizedBox(width: Esp.s),
                  Tooltip(
                    message: tooltipNuevo ?? 'Nuevo',
                    child: FilledButton.tonalIcon(
                      key: claveNuevo,
                      onPressed: alNuevo,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Esp.m),
            hijo,
          ],
        ),
      ),
    );
  }
}

/// El icono del panel en un cuadro con el fondo suave de su tema.
class _IconoDePanel extends StatelessWidget {
  const _IconoDePanel({required this.icono, required this.tono});

  final IconData icono;
  final SemanticaCheque tono;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ChequesColores.fondo(context, tono),
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(
          color: ChequesColores.pleno(context, tono).withValues(alpha: 0.30),
        ),
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Icon(icono, size: 18, color: ChequesColores.texto(context, tono)),
      ),
    );
  }
}

/// «3»: cuantos hay, en una pastilla chica.
class _Contador extends StatelessWidget {
  const _Contador(this.cuenta, {required this.tono});

  final int cuenta;
  final SemanticaCheque tono;

  @override
  Widget build(BuildContext context) {
    final vacio = cuenta == 0;
    return Semantics(
      label: '$cuenta',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              vacio
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : ChequesColores.fondo(context, tono),
          borderRadius: BorderRadius.circular(Esquina.pastilla),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Text(
            '$cuenta',
            key: const ValueKey('contador-panel'),
            style: context.cifraCheque(
              fuerte: true,
              tam: 12,
              color:
                  vacio
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : ChequesColores.texto(context, tono),
            ),
          ),
        ),
      ),
    );
  }
}

/// El cuerpo de un panel segun lo que diga la lectura: esqueleto mientras llega
/// la primera vez, el motivo del error con «Reintentar», el estado vacio
/// explicado o las filas. Una relectura (despues de escribir) no parpadea.
class _CuerpoPanel<T> extends StatelessWidget {
  const _CuerpoPanel({
    required this.lectura,
    required this.alReintentar,
    required this.vacio,
    required this.filas,
  });

  final AsyncValue<List<T>> lectura;
  final VoidCallback alReintentar;
  final Widget vacio;
  final Widget Function(List<T> datos) filas;

  @override
  Widget build(BuildContext context) {
    return lectura.when(
      skipLoadingOnRefresh: true,
      loading: () => const _Esqueleto(),
      error:
          (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorServidorCheque(mensajeDeErrorCheque(e)),
              const SizedBox(height: Esp.s),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: alReintentar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ),
      data: (datos) => datos.isEmpty ? vacio : filas(datos),
    );
  }
}

/// Dos barras grises que reservan el lugar de las filas mientras llegan.
class _Esqueleto extends StatelessWidget {
  const _Esqueleto();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget barra(double alto, double opacidad) => DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacidad),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: SizedBox(height: alto, width: double.infinity),
    );
    return Semantics(
      label: 'Cargando',
      child: Column(
        key: const ValueKey('esqueleto-panel'),
        children: [
          barra(52, 1),
          const SizedBox(height: Esp.s),
          barra(52, 0.6),
        ],
      ),
    );
  }
}

/// Un panel sin filas: dice que es y, si el usuario puede, que hacer.
class _Vacio extends StatelessWidget {
  const _Vacio({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const ValueKey('vacio-panel'),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.chica),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 22, color: cs.onSurfaceVariant),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
                  ),
                  const SizedBox(height: 2),
                  Text(detalle, style: context.apagado()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una fila de nota o de transaccion: franja de color a la izquierda, cebrado
/// suave (las filas pares algo mas oscuras) y un resalte al pasar el mouse.
class _FilaPanel extends StatefulWidget {
  const _FilaPanel({
    super.key,
    required this.franja,
    required this.cebra,
    required this.child,
  });

  final Color franja;
  final bool cebra;
  final Widget child;

  @override
  State<_FilaPanel> createState() => _FilaPanelState();
}

class _FilaPanelState extends State<_FilaPanel> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = widget.cebra ? cs.surfaceContainerLow : Colors.transparent;
    final fondo =
        _encima
            ? Color.alphaBlend(cs.primary.withValues(alpha: 0.06), base)
            : base;
    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(Esquina.chica),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Esquina.chica),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Esp.m + 3, Esp.s, Esp.xs, Esp.s),
                child: widget.child,
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: FranjaCheque(ancho: 3, color: widget.franja),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un par etiqueta / valor chico, para la factura y la fecha de una nota.
class _MiniDato extends StatelessWidget {
  const _MiniDato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text(valor, style: context.cifraCheque(fuerte: true, tam: 13)),
      ],
    );
  }
}

Widget _botonEliminar(
  BuildContext context, {
  required Key clave,
  required String tooltip,
  required VoidCallback alPulsar,
}) {
  return IconButton(
    key: clave,
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    onPressed: alPulsar,
    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTAS DE REMISION
// ═══════════════════════════════════════════════════════════════════════════

class PanelNotasRemisionCheque extends ConsumerWidget {
  const PanelNotasRemisionCheque({super.key, required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(notasRemisionChequeProvider(cheque.codCheque));
    final permisos = ref.watch(permisosChequeProvider);
    final puedeNuevo = permisos.puedeRegistrarEnPaneles;
    final puedeEliminar = permisos.puedeEliminarNotaRemision;

    return _PanelSatelite(
      key: const ValueKey('panel-notas-remision'),
      titulo: 'Notas de remisión',
      icono: Icons.description_outlined,
      tono: SemanticaCheque.info,
      cuenta: lectura.valueOrNull?.length,
      alNuevo:
          puedeNuevo
              ? () => abrirNuevaNotaRemision(context, cheque: cheque)
              : null,
      tooltipNuevo: 'Registrar una nota de remisión',
      claveNuevo: const ValueKey('nuevo-nota-remision'),
      hijo: _CuerpoPanel<NotaRemisionChequeEntity>(
        lectura: lectura,
        alReintentar:
            () => ref.invalidate(notasRemisionChequeProvider(cheque.codCheque)),
        vacio: _Vacio(
          icono: Icons.description_outlined,
          titulo: 'Sin notas de remisión',
          detalle:
              puedeNuevo
                  ? 'Registra la nota que acompaña a la factura de este '
                      'cheque.'
                  : 'Todavía no se registró ninguna para este cheque.',
        ),
        filas: (notas) {
          final cuentas = <String, int>{};
          for (final n in notas) {
            cuentas[n.notaRemision] = (cuentas[n.notaRemision] ?? 0) + 1;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, n) in notas.indexed) ...[
                if (i > 0) const SizedBox(height: Esp.xs),
                _FilaNotaRemision(
                  nota: n,
                  indice: i,
                  repetida: (cuentas[n.notaRemision] ?? 1) > 1,
                  vecesRepetida: cuentas[n.notaRemision] ?? 1,
                  puedeEliminar: puedeEliminar,
                  alEliminar:
                      () => eliminarNotaRemisionCheque(
                        context,
                        ref,
                        nota: n,
                        veces: cuentas[n.notaRemision] ?? 1,
                      ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FilaNotaRemision extends StatelessWidget {
  const _FilaNotaRemision({
    required this.nota,
    required this.indice,
    required this.repetida,
    required this.vecesRepetida,
    required this.puedeEliminar,
    required this.alEliminar,
  });

  final NotaRemisionChequeEntity nota;
  final int indice;
  final bool repetida;
  final int vecesRepetida;
  final bool puedeEliminar;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    return _FilaPanel(
      key: ValueKey('nota-${nota.notaRemision}-$indice'),
      franja: ChequesColores.pleno(context, SemanticaCheque.info),
      cebra: indice.isOdd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Esp.s,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Nota ${nota.notaRemision.trim()}',
                      style: context.cifraCheque(fuerte: true, tam: 15),
                    ),
                    if (repetida)
                      Tooltip(
                        message:
                            'Esta nota está registrada $vecesRepetida veces en '
                            'este cheque. Si la eliminas, se eliminan todas.',
                        child: PastillaCheque(
                          key: const ValueKey('pastilla-repetida'),
                          texto: 'Repetida ×$vecesRepetida',
                          tono: SemanticaCheque.aviso,
                          icono: Icons.content_copy_outlined,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: Esp.l,
                  runSpacing: Esp.xs,
                  children: [
                    _MiniDato('Factura', '${nota.nroFactura}'),
                    _MiniDato('Fecha de la factura', textoFecha(nota.fechaFactura)),
                  ],
                ),
              ],
            ),
          ),
          if (puedeEliminar)
            _botonEliminar(
              context,
              clave: ValueKey('eliminar-nota-${nota.notaRemision}-$indice'),
              tooltip: 'Eliminar la nota ${nota.notaRemision.trim()}',
              alPulsar: alEliminar,
            )
          else
            const SizedBox(width: Esp.xs),
        ],
      ),
    );
  }
}

/// Pide confirmacion y elimina la nota. Si estaba repetida en el cheque el
/// servidor elimina **todas**, como el legacy: se avisa antes y despues.
Future<void> eliminarNotaRemisionCheque(
  BuildContext context,
  WidgetRef ref, {
  required NotaRemisionChequeEntity nota,
  required int veces,
}) async {
  final repetida =
      veces > 1
          ? ' Está registrada $veces veces en este cheque: se eliminarán '
              'las $veces.'
          : '';
  final seguro = await confirmar(
    context,
    titulo: '¿Eliminar la nota de remisión?',
    detalle:
        'Nota ${nota.notaRemision.trim()}, factura ${nota.nroFactura} del '
        '${textoFecha(nota.fechaFactura)}.$repetida Esta acción no se puede '
        'deshacer.',
    textoConfirmar: 'Eliminar nota',
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;

  final ops = ref.read(operacionesPanelesChequeProvider.notifier);
  final filas = await ops.eliminarNotaRemision(
    codCheque: nota.codCheque,
    notaRemision: nota.notaRemision,
  );
  if (!context.mounted) return;
  if (filas == null) {
    avisar(
      context,
      ref.read(operacionesPanelesChequeProvider).error ??
          'No se pudo eliminar la nota de remisión.',
      esError: true,
    );
    ops.limpiarError();
    return;
  }
  avisar(
    context,
    filas > 1
        ? 'Se eliminaron las $filas notas de remisión ${nota.notaRemision.trim()}.'
        : 'Nota de remisión eliminada.',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TRANSACCIONES BANCARIAS
// ═══════════════════════════════════════════════════════════════════════════

class PanelTransaccionesCheque extends ConsumerWidget {
  const PanelTransaccionesCheque({super.key, required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(transaccionesChequeProvider(cheque.codCheque));
    final puedeNuevo = ref.watch(permisosChequeProvider).puedeRegistrarEnPaneles;

    return _PanelSatelite(
      key: const ValueKey('panel-transacciones'),
      titulo: 'Transacciones bancarias',
      icono: Icons.account_balance_outlined,
      tono: SemanticaCheque.exito,
      cuenta: lectura.valueOrNull?.length,
      alNuevo:
          puedeNuevo
              ? () => abrirNuevaTransaccion(context, cheque: cheque)
              : null,
      tooltipNuevo: 'Registrar una transacción bancaria',
      claveNuevo: const ValueKey('nuevo-transaccion'),
      hijo: _CuerpoPanel<TransaccionBancariaEntity>(
        lectura: lectura,
        alReintentar:
            () => ref.invalidate(transaccionesChequeProvider(cheque.codCheque)),
        vacio: _Vacio(
          icono: Icons.account_balance_outlined,
          titulo: 'Sin transacciones bancarias',
          detalle:
              puedeNuevo
                  ? 'Anota el número de transacción del banco cuando el '
                      'cheque se deposite o se transfiera.'
                  : 'Todavía no se registró ninguna para este cheque.',
        ),
        filas:
            (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, t) in items.indexed) ...[
                  if (i > 0) const SizedBox(height: Esp.xs),
                  _FilaTransaccion(
                    transaccion: t,
                    indice: i,
                    alEliminar:
                        () => eliminarTransaccionCheque(
                          context,
                          ref,
                          transaccion: t,
                        ),
                  ),
                ],
              ],
            ),
      ),
    );
  }
}

class _FilaTransaccion extends StatelessWidget {
  const _FilaTransaccion({
    required this.transaccion,
    required this.indice,
    required this.alEliminar,
  });

  final TransaccionBancariaEntity transaccion;
  final int indice;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    final t = transaccion;
    final banco = t.datoBanco.trim();
    return _FilaPanel(
      key: ValueKey('transaccion-${t.nroTransaccion}-$indice'),
      franja: ChequesColores.pleno(context, SemanticaCheque.exito),
      cebra: indice.isOdd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MonogramaBanco(banco.isEmpty ? '?' : banco, tam: 34),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.nroTransaccion.trim(),
                  style: context.cifraCheque(fuerte: true, tam: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  banco.isEmpty ? 'Banco sin nombre' : banco,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  textoFecha(t.fechaTransaccion),
                  style: context.cifraCheque(
                    tam: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Sin boton de ACL, como el legacy: se dibuja siempre.
          _botonEliminar(
            context,
            clave: ValueKey('eliminar-transaccion-${t.nroTransaccion}-$indice'),
            tooltip: 'Eliminar la transacción ${t.nroTransaccion.trim()}',
            alPulsar: alEliminar,
          ),
        ],
      ),
    );
  }
}

Future<void> eliminarTransaccionCheque(
  BuildContext context,
  WidgetRef ref, {
  required TransaccionBancariaEntity transaccion,
}) async {
  final banco = transaccion.datoBanco.trim();
  final seguro = await confirmar(
    context,
    titulo: '¿Eliminar la transacción bancaria?',
    detalle:
        'Transacción ${transaccion.nroTransaccion.trim()}'
        '${banco.isEmpty ? '' : ' de $banco'} del '
        '${textoFecha(transaccion.fechaTransaccion)}. Esta acción no se puede '
        'deshacer.',
    textoConfirmar: 'Eliminar transacción',
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;

  final ops = ref.read(operacionesPanelesChequeProvider.notifier);
  final filas = await ops.eliminarTransaccion(
    codCheque: transaccion.codCheque,
    nroTransaccion: transaccion.nroTransaccion,
  );
  if (!context.mounted) return;
  if (filas == null) {
    avisar(
      context,
      ref.read(operacionesPanelesChequeProvider).error ??
          'No se pudo eliminar la transacción bancaria.',
      esError: true,
    );
    ops.limpiarError();
    return;
  }
  avisar(context, 'Transacción bancaria eliminada.');
}

// ═══════════════════════════════════════════════════════════════════════════
// POSTERGACIONES (LINEA DE TIEMPO)
// ═══════════════════════════════════════════════════════════════════════════

class PanelPostergacionesCheque extends ConsumerWidget {
  const PanelPostergacionesCheque({super.key, required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(postergacionesChequeProvider(cheque.codCheque));
    final puedeNuevo = ref.watch(permisosChequeProvider).puedeRegistrarEnPaneles;

    return _PanelSatelite(
      key: const ValueKey('panel-postergaciones'),
      titulo: 'Postergaciones',
      icono: Icons.event_repeat_outlined,
      tono: SemanticaCheque.aviso,
      cuenta: lectura.valueOrNull?.length,
      alNuevo:
          puedeNuevo
              ? () => abrirNuevaPostergacion(context, cheque: cheque)
              : null,
      tooltipNuevo: 'Registrar una postergación',
      claveNuevo: const ValueKey('nuevo-postergacion'),
      hijo: _CuerpoPanel<PostergacionEntity>(
        lectura: lectura,
        alReintentar:
            () => ref.invalidate(postergacionesChequeProvider(cheque.codCheque)),
        vacio: _Vacio(
          icono: Icons.event_repeat_outlined,
          titulo: 'Sin postergaciones',
          detalle:
              puedeNuevo
                  ? 'Queda constancia aquí cuando el cliente pide mover la '
                      'fecha de cobro, con su carta en PDF si la hay.'
                  : 'Este cheque no se postergó.',
        ),
        filas:
            (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, p) in items.indexed)
                  _ItemPostergacion(
                    postergacion: p,
                    ultimo: i == items.length - 1,
                    alAbrirPdf:
                        () => abrirDocumentoPdfPostergacion(
                          context,
                          cheque: cheque,
                          postergacion: p,
                        ),
                    alEliminar:
                        () => eliminarPostergacionCheque(
                          context,
                          ref,
                          postergacion: p,
                        ),
                  ),
              ],
            ),
      ),
    );
  }
}

/// Un paso de la linea de tiempo: el numero en un punto, un hilo que lo une con
/// el siguiente, la fecha, el motivo y lo que se puede hacer con su PDF.
class _ItemPostergacion extends StatelessWidget {
  const _ItemPostergacion({
    required this.postergacion,
    required this.ultimo,
    required this.alAbrirPdf,
    required this.alEliminar,
  });

  final PostergacionEntity postergacion;
  final bool ultimo;
  final VoidCallback alAbrirPdf;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    final p = postergacion;
    final cod = p.codPostergacion;
    final tienePdf = p.tienePdf == true;

    final riel = Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ChequesColores.fondo(context, SemanticaCheque.aviso),
            border: Border.all(
              color: ChequesColores.pleno(context, SemanticaCheque.aviso),
              width: 1.5,
            ),
          ),
          child: SizedBox.square(
            dimension: 26,
            child: Center(
              child: Text(
                '${p.fila}',
                style: context.cifraCheque(
                  fuerte: true,
                  tam: 11.5,
                  color: ChequesColores.texto(context, SemanticaCheque.aviso),
                ),
              ),
            ),
          ),
        ),
        if (!ultimo)
          Expanded(
            child: SizedBox(
              width: 2,
              child: ColoredBox(
                color: ChequesColores.pleno(
                  context,
                  SemanticaCheque.aviso,
                ).withValues(alpha: 0.45),
              ),
            ),
          ),
      ],
    );

    final contenido = Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Esp.s,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                textoFecha(p.fecha),
                key: ValueKey('fecha-postergacion-$cod'),
                style: context.cifraCheque(fuerte: true, tam: 14),
              ),
              _PastillaPdf(tienePdf: p.tienePdf, codPostergacion: cod),
            ],
          ),
          const SizedBox(height: Esp.xs),
          Text(
            textoODash(p.observacion),
            key: ValueKey('motivo-postergacion-$cod'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Esp.s),
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Un solo boton por fila: abre el dialogo del documento, donde se
              // descarga, se carga o se reemplaza. Sin boton de ACL.
              tienePdf
                  ? FilledButton.tonalIcon(
                    key: ValueKey('pdf-postergacion-$cod'),
                    onPressed: alAbrirPdf,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Descargar PDF'),
                  )
                  : OutlinedButton.icon(
                    key: ValueKey('pdf-postergacion-$cod'),
                    onPressed: alAbrirPdf,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Cargar PDF'),
                  ),
              _botonEliminar(
                context,
                clave: ValueKey('eliminar-postergacion-$cod'),
                tooltip: 'Eliminar la postergación del ${textoFecha(p.fecha)}',
                alPulsar: alEliminar,
              ),
            ],
          ),
        ],
      ),
    );

    return IntrinsicHeight(
      key: ValueKey('postergacion-$cod'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 26, child: riel),
          const SizedBox(width: Esp.m),
          Expanded(child: contenido),
        ],
      ),
    );
  }
}

/// «PDF cargado» (exito, con icono) o «Sin PDF» (neutro). Si el servidor no pudo
/// comprobarlo (null) se dice asi, y no «Sin PDF»: no es lo mismo.
class _PastillaPdf extends StatelessWidget {
  const _PastillaPdf({required this.tienePdf, required this.codPostergacion});

  final bool? tienePdf;
  final BigInt codPostergacion;

  @override
  Widget build(BuildContext context) {
    final (texto, tono, icono, ayuda) = switch (tienePdf) {
      true => (
        'PDF cargado',
        SemanticaCheque.exito,
        Icons.picture_as_pdf,
        'Esta postergación tiene su documento PDF.',
      ),
      false => (
        'Sin PDF',
        SemanticaCheque.neutro,
        Icons.picture_as_pdf_outlined,
        'Todavía no se cargó el PDF de esta postergación.',
      ),
      null => (
        'PDF sin comprobar',
        SemanticaCheque.neutro,
        Icons.help_outline,
        'El servidor no pudo comprobar si hay PDF (la carpeta de documentos '
            'no está disponible). Abre «Cargar PDF» para ver el motivo.',
      ),
    };
    return Tooltip(
      message: ayuda,
      child: PastillaCheque(
        key: ValueKey('pastilla-pdf-$codPostergacion'),
        texto: texto,
        tono: tono,
        icono: icono,
      ),
    );
  }
}

Future<void> eliminarPostergacionCheque(
  BuildContext context,
  WidgetRef ref, {
  required PostergacionEntity postergacion,
}) async {
  final motivo = postergacion.observacion.trim();
  final resumen = motivo.length > 80 ? '${motivo.substring(0, 80)}…' : motivo;
  final conPdf =
      postergacion.tienePdf == true
          ? ' Su PDF queda guardado en el servidor, pero ya no se podrá abrir '
              'desde aquí.'
          : '';
  final seguro = await confirmar(
    context,
    titulo: '¿Eliminar la postergación?',
    detalle:
        'Postergación del ${textoFecha(postergacion.fecha)}'
        '${resumen.isEmpty ? '' : ': «$resumen»'}.$conPdf Esta acción no se '
        'puede deshacer.',
    textoConfirmar: 'Eliminar postergación',
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;

  final ops = ref.read(operacionesPanelesChequeProvider.notifier);
  final cod = await ops.eliminarPostergacion(
    codCheque: postergacion.codCheque,
    codPostergacion: postergacion.codPostergacion,
  );
  if (!context.mounted) return;
  if (cod == null) {
    avisar(
      context,
      ref.read(operacionesPanelesChequeProvider).error ??
          'No se pudo eliminar la postergación.',
      esError: true,
    );
    ops.limpiarError();
    return;
  }
  avisar(context, 'Postergación eliminada.');
}
