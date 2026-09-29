/// Las piezas de la carga en lote del paso de familias: el estado de cada
/// fila, la celda con el resultado, el campo que pone un costo a todas las
/// marcadas y la barra con Calcular y Guardar.
///
/// **Para que existe.** Lo pidio el usuario para el trabajo operativo: con un
/// costo nuevo de importacion hay que repreciar decenas de familias, y abrir el
/// editor de cada una para escribir un numero era lo que mas tiempo llevaba.
/// En lote se marcan las familias, se escribe UN costo y se pone a todas las
/// marcadas (y se calculan en el acto); tambien se puede escribir fila por
/// fila. "Guardar" graba las que estan bien.
///
/// Hubo una version con un dialogo de tres modos (mismo costo, porcentaje
/// sobre el actual o sobre el propuesto) y otra con "Pegar desde Excel": el
/// usuario pidio solo esto, un costo para las marcadas.
///
/// **Las listas y los porcentajes de cada familia se respetan.** El servidor
/// calcula cada familia igual que en el editor: sus listas activas, el
/// porcentaje de cada lista, IVA, IT y el flete de cada sucursal. Lo unico que
/// cambia es que el costo se escribe en la tabla. Para cambiar un porcentaje
/// hay que abrir la familia en el editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_detalle_dialogos.dart';

/// En que esta una familia de la tabla en lote.
enum EstadoLote {
  /// No se le escribio costo.
  sinCosto,

  /// Lo escrito no es un costo mayor a cero.
  invalido,

  /// Ya no esta entre las activas: no se reprecia.
  inactiva,

  /// El costo escrito es el que ya tiene guardado en la propuesta.
  igualAlGuardado,

  /// Tiene un costo nuevo que todavia no se calculo (o se cambio despues).
  sinCalcular,

  /// Calculada con el costo escrito y se puede guardar.
  lista,

  /// Calculada con el costo escrito, pero no se podria guardar.
  conProblema;

  /// Entra en "Calcular".
  bool get seCalcula => this == sinCalcular || this == conProblema;
}

/// Que estado tiene la familia, desde lo escrito y la ultima vista previa.
EstadoLote estadoLote({
  required bool activa,
  required String escrito,
  required double? costoGuardado,
  required CalculoFamiliaEntity? previa,
}) {
  if (!activa) return EstadoLote.inactiva;
  final texto = escrito.trim();
  if (texto.isEmpty) return EstadoLote.sinCosto;
  final costo = importeDesdeTexto(texto);
  if (costo == null || costo <= 0) return EstadoLote.invalido;
  final calculado = previa?.costo;
  if (previa != null &&
      calculado != null &&
      (calculado - costo).abs() < 0.00005) {
    return previa.sePuedeGuardar ? EstadoLote.lista : EstadoLote.conProblema;
  }
  if (costoGuardado != null && (costoGuardado - costo).abs() < 0.005) {
    return EstadoLote.igualAlGuardado;
  }
  return EstadoLote.sinCalcular;
}

final NumberFormat _fmtVariacion = NumberFormat('#,##0.0', 'es');

String variacionLegible(double v) {
  final signo = v > 0.05 ? '+' : '';
  return '$signo${_fmtVariacion.format(v)} %';
}

/// Sube en el color de error, baja en el principal: lo que se mira dos veces
/// antes de aprobar es cuanto SUBE.
Color colorVariacion(ColorScheme cs, double v) {
  if (v.abs() < 0.05) return cs.onSurfaceVariant;
  return v > 0 ? cs.error : cs.primary;
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPO Y RESULTADO
// ═══════════════════════════════════════════════════════════════════════════

/// El costo de una familia, escrito en la misma fila.
class CampoCostoLote extends StatelessWidget {
  const CampoCostoLote({
    super.key,
    required this.controlador,
    required this.habilitado,
    required this.invalido,
    required this.cambiado,
    this.etiqueta,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final bool invalido;

  /// Distinto del guardado: es lo que se va a calcular y guardar.
  final bool cambiado;

  /// Solo en la tarjeta del telefono; en la tabla lo dice la cabecera.
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borde =
        invalido ? cs.error : (cambiado ? cs.tertiary : cs.outlineVariant);
    return SizedBox(
      height: etiqueta == null ? 36 : 48,
      child: TextField(
        controller: controlador,
        enabled: habilitado,
        textAlign: TextAlign.end,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        textInputAction: TextInputAction.next,
        style: context.numero(
          fuerte: cambiado,
          color: invalido ? cs.error : null,
        ),
        decoration: InputDecoration(
          isDense: true,
          labelText: etiqueta,
          hintText: '--',
          filled: true,
          fillColor:
              invalido
                  ? cs.errorContainer.withValues(alpha: 0.5)
                  : (cambiado
                      ? cs.tertiaryContainer
                      : cs.surfaceContainerLowest),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Esp.s,
            vertical: Esp.s,
          ),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borde,
              width: invalido || cambiado ? 1.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: invalido ? cs.error : cs.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Que pasaria con la familia al guardar, segun la ultima vista previa.
class ResultadoLote extends StatelessWidget {
  const ResultadoLote({
    super.key,
    required this.estado,
    this.previa,
    this.conDetalle = false,
  });

  final EstadoLote estado;
  final CalculoFamiliaEntity? previa;

  /// En el telefono el motivo de un problema se escribe debajo: no hay
  /// tooltip que alcanzar con el dedo.
  final bool conDetalle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (estado) {
      case EstadoLote.sinCosto:
        return Text('--', style: context.apagado());
      case EstadoLote.inactiva:
        return Text('Inactiva: no se reprecia', style: context.apagado());
      case EstadoLote.invalido:
        return const Etiqueta(
          texto: 'Costo inválido',
          tono: TonoEtiqueta.error,
        );
      case EstadoLote.igualAlGuardado:
        return Text('Igual al guardado', style: context.apagado());
      case EstadoLote.sinCalcular:
        return const Etiqueta(texto: 'Sin calcular');
      case EstadoLote.lista:
        final p = previa!;
        final n = p.lineasAEscribir;
        final v = p.variacionMedia;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Etiqueta(
              texto:
                  n == 0 ? 'Solo el costo' : (n == 1 ? '1 lista' : '$n listas'),
              tono: TonoEtiqueta.exito,
            ),
            if (v != null) ...[
              const SizedBox(width: Esp.s),
              // "precios" para que no se lea como la variacion del costo, que
              // esta en la columna de al lado.
              Flexible(
                child: Tooltip(
                  message:
                      'Cuánto cambian en promedio los precios por tonelada '
                      'contra los vigentes',
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'precios ', style: context.apagado()),
                        TextSpan(
                          text: variacionLegible(v),
                          style: context.numero(
                            fuerte: true,
                            color: colorVariacion(cs, v),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        );
      case EstadoLote.conProblema:
        final motivo = motivoDelProblema(previa);
        final etiqueta = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Etiqueta(
              texto: 'No se puede guardar',
              tono: TonoEtiqueta.error,
            ),
            if (!conDetalle) ...[
              const SizedBox(width: Esp.xs),
              Icon(Icons.info_outline, size: 16, color: cs.error),
            ],
          ],
        );
        if (conDetalle) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              etiqueta,
              const SizedBox(height: Esp.xs),
              Text(
                motivo,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ],
          );
        }
        return Tooltip(message: motivo, child: etiqueta);
    }
  }
}

/// Por que no se puede guardar, en una frase.
String motivoDelProblema(CalculoFamiliaEntity? previa) {
  if (previa == null) return 'No se pudo calcular.';
  if (previa.impedimento != null) return previa.impedimento!;
  if (previa.errores.isNotEmpty) return previa.errores.first;
  return 'No hay nada que guardar con ese costo.';
}

// ═══════════════════════════════════════════════════════════════════════════
// UN COSTO PARA LAS MARCADAS
// ═══════════════════════════════════════════════════════════════════════════

/// El costo que se pone a todas las familias marcadas, con su boton.
///
/// El campo es de este widget y no de la pantalla: vive y se libera con el.
class CostoParaMarcadas extends StatefulWidget {
  const CostoParaMarcadas({
    super.key,
    required this.marcadas,
    required this.habilitado,
    required this.compacto,
    required this.onPoner,
  });

  final int marcadas;
  final bool habilitado;
  final bool compacto;

  /// Recibe el costo por tonelada, ya leido y mayor a cero.
  final ValueChanged<double> onPoner;

  @override
  State<CostoParaMarcadas> createState() => _CostoParaMarcadasState();
}

class _CostoParaMarcadasState extends State<CostoParaMarcadas> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _costo {
    final c = importeDesdeTexto(_ctrl.text);
    return c != null && c > 0 ? c : null;
  }

  bool get _puede => widget.habilitado && widget.marcadas > 0 && _costo != null;

  void _poner() {
    final c = _costo;
    if (!_puede || c == null) return;
    widget.onPoner(c);
  }

  @override
  Widget build(BuildContext context) {
    final escrito = _ctrl.text.trim().isNotEmpty;
    final campo = TextField(
      controller: _ctrl,
      enabled: widget.habilitado,
      textAlign: TextAlign.end,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _poner(),
      style: context.numero(fuerte: true),
      decoration: InputDecoration(
        labelText: 'Costo propuesto',
        prefixText: 'USD ',
        suffixText: '/t',
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: escrito && _costo == null ? 'Mayor a cero' : null,
      ),
    );
    final String rotulo;
    if (widget.marcadas == 0) {
      rotulo = widget.compacto ? 'Marque familias' : 'Marque las familias';
    } else if (widget.compacto) {
      rotulo = 'Poner (${widget.marcadas})';
    } else {
      rotulo =
          widget.marcadas == 1
              ? 'Poner a la marcada'
              : 'Poner a las ${widget.marcadas} marcadas';
    }
    final boton = FilledButton.icon(
      onPressed: _puede ? _poner : null,
      icon: const Icon(Icons.done_all_rounded, size: 18),
      label: Text(rotulo),
    );

    if (widget.compacto) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: campo),
          const SizedBox(width: Esp.s),
          Padding(padding: const EdgeInsets.only(top: 2), child: boton),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 210, child: campo),
        const SizedBox(width: Esp.s),
        Padding(padding: const EdgeInsets.only(top: 2), child: boton),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BARRA DEL LOTE
// ═══════════════════════════════════════════════════════════════════════════

/// Cuantas familias hay en cada estado, para la barra.
@immutable
class CuentaLote {
  const CuentaLote({
    required this.sinCalcular,
    required this.listas,
    required this.conProblema,
    required this.invalidos,
    required this.lineas,
  });

  final int sinCalcular;
  final int listas;
  final int conProblema;
  final int invalidos;

  /// Listas de precio que se escribirian con las familias listas.
  final int lineas;

  int get aCalcular => sinCalcular + conProblema;
  bool get hayAlgo => sinCalcular + listas + conProblema + invalidos > 0;
}

/// Abajo del paso en lote: que hay para calcular y guardar, y los dos botones.
class BarraLote extends StatelessWidget {
  const BarraLote({
    super.key,
    required this.cuenta,
    required this.margen,
    required this.compacto,
    required this.avance,
    required this.onCalcular,
    required this.onGuardar,
  });

  final CuentaLote cuenta;
  final double margen;
  final bool compacto;

  /// Mientras calcula o guarda.
  final ({int hechas, int total, bool guardando})? avance;
  final VoidCallback? onCalcular;
  final VoidCallback? onGuardar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = avance;

    final Widget estado;
    if (a != null) {
      estado = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${a.guardando ? 'Guardando' : 'Calculando'} ${a.hechas} de '
            '${a.total} familias…',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.xs),
          LinearProgressIndicator(
            value: a.total == 0 ? null : a.hechas / a.total,
            minHeight: 4,
          ),
        ],
      );
    } else if (!cuenta.hayAlgo) {
      estado = Text(
        compacto
            ? 'Escriba costos para calcular.'
            : 'Escriba el costo de las familias que quiere repreciar.',
        style: context.apagado(),
      );
    } else {
      estado = Wrap(
        spacing: Esp.s,
        runSpacing: Esp.xs,
        children: [
          if (cuenta.sinCalcular > 0)
            Etiqueta(
              texto:
                  cuenta.sinCalcular == 1
                      ? '1 familia sin calcular'
                      : '${cuenta.sinCalcular} familias sin calcular',
            ),
          if (cuenta.listas > 0)
            Etiqueta(
              texto:
                  cuenta.listas == 1
                      ? '1 familia lista para guardar'
                      : '${cuenta.listas} familias listas para guardar',
              tono: TonoEtiqueta.exito,
            ),
          if (cuenta.conProblema > 0)
            Etiqueta(
              texto:
                  cuenta.conProblema == 1
                      ? '1 familia con problemas'
                      : '${cuenta.conProblema} familias con problemas',
              tono: TonoEtiqueta.error,
            ),
          if (cuenta.invalidos > 0)
            Etiqueta(
              texto:
                  cuenta.invalidos == 1
                      ? '1 costo inválido'
                      : '${cuenta.invalidos} costos inválidos',
              tono: TonoEtiqueta.error,
            ),
        ],
      );
    }

    final calcular = BotonAccion(
      etiqueta:
          cuenta.aCalcular == 0 ? 'Calcular' : 'Calcular ${cuenta.aCalcular}',
      etiquetaOcupado: 'Calculando',
      icono: Icons.calculate_outlined,
      tonal: true,
      ocupado: a != null && !a.guardando,
      onPressed: onCalcular,
    );
    final guardar = BotonAccion(
      etiqueta: cuenta.listas == 0 ? 'Guardar' : 'Guardar ${cuenta.listas}',
      etiquetaOcupado: 'Guardando',
      icono: Icons.save_outlined,
      ocupado: a != null && a.guardando,
      onPressed: onGuardar,
    );

    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          cs.tertiary.withValues(alpha: 0.06),
          cs.surfaceContainerLow,
        ),
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(margen, Esp.s, margen, Esp.s),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  estado,
                  const SizedBox(height: Esp.s),
                  Row(
                    children: [
                      Expanded(child: calcular),
                      const SizedBox(width: Esp.s),
                      Expanded(child: guardar),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(child: estado),
                  const SizedBox(width: Esp.m),
                  calcular,
                  const SizedBox(width: Esp.s),
                  guardar,
                ],
              ),
    );
  }
}
