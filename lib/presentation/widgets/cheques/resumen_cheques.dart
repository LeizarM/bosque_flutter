/// El resumen sobre la tabla: cuantos cheques hay, cuantos estan pendientes,
/// cuantos con el cobro atrasado y cuanto suman. Es de solo lectura: cuatro
/// recuadros tintados que no se tocan (sin ripple, sin flecha), para que nadie
/// los tome por botones.
///
/// **Que numeros son de toda la busqueda y cuales solo de la pagina.** La
/// paginacion es del servidor y no hay totales globales: «Cheques» es el total
/// que da el servidor, pero «Pendientes», «Cobro atrasado» y «Monto» se calculan
/// con las filas que estan cargadas. Cuando hay mas de una pagina se rotulan «en
/// esta pagina» para que nadie los lea como el total. El monto va **una suma por
/// moneda** (Bs y $us), nunca sumadas entre si.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/resumen_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

/// Ancho desde el cual los cuatro recuadros van en una sola fila; debajo, de a
/// dos.
const double _anchoCuatroEnFila = 640;

/// Ancho maximo de un recuadro: en una pantalla ancha no se estiran.
const double _anchoMaximoRecuadro = 300;

class ResumenCheques extends StatelessWidget {
  const ResumenCheques({
    super.key,
    required this.filas,
    required this.total,
    required this.totalPaginas,
    required this.hoy,
  });

  /// Las filas de la pagina cargada.
  final List<ChequeFilaEntity> filas;

  /// El total de la busqueda, segun el servidor.
  final int total;
  final int totalPaginas;

  /// El dia con el que se mide el atraso (el reloj de la pantalla).
  final DateTime hoy;

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) return const SizedBox.shrink();

    final r = resumirPaginaCheques(filas, hoy);
    final cs = Theme.of(context).colorScheme;
    final variasPaginas = totalPaginas > 1;
    const enPagina = 'en esta página';

    final recuadros = <Widget>[
      _Recuadro(
        key: const ValueKey('resumen-total'),
        icono: Icons.receipt_long_outlined,
        rotulo: 'Cheques',
        fondo: Color.alphaBlend(
          cs.primary.withValues(alpha: 0.10),
          cs.surfaceContainerLow,
        ),
        borde: cs.primary,
        colorRotulo: cs.primary,
        valor: _Cifra(FormatoMoneda.entero.format(total)),
        pie: 'en total',
      ),
      _Recuadro(
        key: const ValueKey('resumen-pendientes'),
        icono: Icons.pending_actions_outlined,
        rotulo: 'Pendientes',
        tono: SemanticaCheque.aviso,
        valor: _Cifra('${r.pendientes}'),
        pie: variasPaginas ? enPagina : 'sin cerrar',
        // Lo que se cobra hoy es lo primero que mira quien abre la pantalla.
        destacado: r.cobranHoy > 0 ? _textoCobranHoy(r.cobranHoy) : null,
      ),
      _Recuadro(
        key: const ValueKey('resumen-atrasados'),
        icono:
            r.atrasados > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
        rotulo: 'Cobro atrasado',
        // Cero atrasados es una buena noticia, y se pinta como tal.
        tono: r.atrasados > 0 ? SemanticaCheque.peligro : SemanticaCheque.exito,
        valor: _Cifra('${r.atrasados}'),
        pie:
            r.atrasados == 0
                ? (variasPaginas ? 'ninguno en esta página' : 'ninguno')
                : (variasPaginas ? enPagina : 'pasados de fecha'),
      ),
      _Recuadro(
        key: const ValueKey('resumen-monto'),
        icono: Icons.payments_outlined,
        rotulo: 'Monto',
        tono: SemanticaCheque.info,
        valor: _Montos(r.montos),
        pie: variasPaginas ? enPagina : 'de estos cheques',
      ),
    ];

    return LayoutBuilder(
      key: const ValueKey('resumen-cheques'),
      builder: (context, c) {
        final columnas = c.maxWidth >= _anchoCuatroEnFila ? 4 : 2;
        final filasDeRecuadros = <List<Widget>>[
          for (var i = 0; i < recuadros.length; i += columnas)
            recuadros.sublist(i, math.min(i + columnas, recuadros.length)),
        ];
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _anchoMaximoRecuadro * columnas + Esp.m * (columnas - 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < filasDeRecuadros.length; i++) ...[
                  if (i > 0) const SizedBox(height: Esp.m),
                  // Todos los de una fila miden lo mismo, tambien con texto
                  // grande.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var j = 0; j < columnas; j++) ...[
                          if (j > 0) const SizedBox(width: Esp.m),
                          Expanded(
                            child:
                                j < filasDeRecuadros[i].length
                                    ? filasDeRecuadros[i][j]
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _textoCobranHoy(int n) => n == 1 ? '1 cobra hoy' : '$n cobran hoy';
}

/// Un recuadro: icono y rotulo arriba, el valor grande y una linea de contexto.
/// Con [tono] se tine del color de su significado; sin el, usa los colores
/// dados.
class _Recuadro extends StatelessWidget {
  const _Recuadro({
    super.key,
    required this.icono,
    required this.rotulo,
    required this.valor,
    required this.pie,
    this.tono,
    this.fondo,
    this.borde,
    this.colorRotulo,
    this.destacado,
  });

  final IconData icono;
  final String rotulo;
  final Widget valor;
  final String pie;
  final SemanticaCheque? tono;

  /// Colores de marca para el recuadro sin [tono].
  final Color? fondo;
  final Color? borde;
  final Color? colorRotulo;

  /// Una segunda linea que resalta (en el color de aviso): «2 cobran hoy».
  final String? destacado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fondoFinal =
        tono != null ? ChequesColores.fondo(context, tono!) : fondo!;
    final bordeFinal =
        tono != null ? ChequesColores.pleno(context, tono!) : borde!;
    final rotuloColor =
        tono != null ? ChequesColores.texto(context, tono!) : colorRotulo!;

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fondoFinal,
          borderRadius: BorderRadius.circular(Esquina.media),
          border: Border.all(color: bordeFinal.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icono, size: 16, color: rotuloColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rotulo,
                      // Con texto grande «Cobro atrasado» pasa a dos lineas en
                      // vez de cortarse.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium?.copyWith(
                        color: rotuloColor,
                        fontWeight: Peso.dato,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Esp.xs),
              valor,
              const SizedBox(height: 2),
              Text(
                pie,
                style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (destacado != null) ...[
                const SizedBox(height: 2),
                Text(
                  destacado!,
                  style: t.labelMedium?.copyWith(
                    color: ChequesColores.texto(context, SemanticaCheque.aviso),
                    fontWeight: Peso.dato,
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

/// El numero grande de un recuadro, en la monoespaciada del modulo.
class _Cifra extends StatelessWidget {
  const _Cifra(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(texto, style: context.cifraCheque(fuerte: true, tam: 24)),
  );
}

/// El monto de la pagina, una linea por moneda: «Bs 12,500.00» y «$us 800.00».
/// Nunca las suma. Sin ningun importe, un guion.
class _Montos extends StatelessWidget {
  const _Montos(this.montos);

  final Map<String, double> montos;

  @override
  Widget build(BuildContext context) {
    if (montos.isEmpty) return const _Cifra('—');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in montos.entries)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Semantics(
              container: true,
              label: '${e.key} ${FormatoMoneda.monto.format(e.value)}',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PastillaMonedaCheque(e.key),
                    const SizedBox(width: 6),
                    Text(
                      FormatoMoneda.monto.format(e.value),
                      style: context.cifraCheque(fuerte: true, tam: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
