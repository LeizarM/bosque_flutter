/// El cuadre de un lote: si lo que entro se explica con lo que salio.
///
/// La planilla anterior mostraba diecisiete columnas de numeros sin decir cual
/// importa. La pregunta que se le hace a un lote es una sola —si cuadra— y de
/// eso hablan dos cifras que ya existen en la base:
///
/// - `diferenciaProduccion`: kilos que entraron menos material de salida y
///   merma. Lo que no aparece en ningun lado.
/// - `diferenciaProdResma`: resmas contadas menos resmas estimadas por balanza.
///
/// Aqui se traducen a un estado legible y, en el detalle, a una barra que
/// muestra a escala en que se convirtieron los kilos que entraron.
library;

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formato de todas las cifras del modulo, el mismo del sistema anterior.
final NumberFormat fmtNumero = NumberFormat('#,##0.00', 'en_US');
final NumberFormat fmtEntero = NumberFormat('#,##0', 'en_US');

/// Que tan lejos del cuadre esta un lote.
enum EstadoCuadre { cuadrado, desvio, desviado }

/// Clasifica la diferencia de kilos contra lo que entro.
///
/// El umbral es relativo y no absoluto: 20 kg sobre un lote de 500 es un
/// problema y sobre uno de 20.000 es ruido de balanza. Debajo del 1% se toma
/// por cuadrado, hasta el 3% es un desvio a mirar, y de ahi para arriba hay
/// algo que revisar.
EstadoCuadre cuadreDe({
  required double diferenciaKilos,
  required double kilosIngreso,
}) {
  if (kilosIngreso <= 0) return EstadoCuadre.cuadrado;
  final desvio = (diferenciaKilos.abs() / kilosIngreso) * 100;
  if (desvio < 1) return EstadoCuadre.cuadrado;
  if (desvio <= 3) return EstadoCuadre.desvio;
  return EstadoCuadre.desviado;
}

/// La etiqueta de cuadre que acompana a cada lote en la lista.
class EtiquetaCuadre extends StatelessWidget {
  const EtiquetaCuadre({
    super.key,
    required this.diferenciaKilos,
    required this.kilosIngreso,
  });

  final double diferenciaKilos;
  final double kilosIngreso;

  @override
  Widget build(BuildContext context) {
    final estado = cuadreDe(
      diferenciaKilos: diferenciaKilos,
      kilosIngreso: kilosIngreso,
    );

    final (texto, tono) = switch (estado) {
      EstadoCuadre.cuadrado => ('Cuadra', TonoEtiqueta.exito),
      EstadoCuadre.desvio => (
        '${fmtNumero.format(diferenciaKilos)} kg',
        TonoEtiqueta.aviso,
      ),
      EstadoCuadre.desviado => (
        '${fmtNumero.format(diferenciaKilos)} kg',
        TonoEtiqueta.error,
      ),
    };

    return Tooltip(
      message: switch (estado) {
        EstadoCuadre.cuadrado => 'Los kilos que entraron se explican con la '
            'salida y la merma.',
        EstadoCuadre.desvio => 'Quedan ${fmtNumero.format(diferenciaKilos)} kg '
            'sin explicar. Revise pesos y merma.',
        EstadoCuadre.desviado =>
          'Quedan ${fmtNumero.format(diferenciaKilos)} kg sin explicar sobre '
              '${fmtNumero.format(kilosIngreso)} kg de ingreso.',
      },
      child: Etiqueta(texto: texto, tono: tono),
    );
  }
}

/// En que se convirtieron los kilos que entraron al lote.
///
/// Tres tramos a escala real —material de salida, merma y la diferencia sin
/// explicar— sobre el total de ingreso. Un lote sano es casi todo el primer
/// tramo; uno con problema muestra el tercero de inmediato, sin leer un numero.
class BarraDeBalance extends StatelessWidget {
  const BarraDeBalance({
    super.key,
    required this.kilosIngreso,
    required this.kilosSalida,
    required this.kilosMerma,
    required this.diferencia,
    required this.resmasContadas,
    required this.resmasEstimadas,
  });

  final double kilosIngreso;
  final double kilosSalida;
  final double kilosMerma;
  final double diferencia;
  final int resmasContadas;
  final double resmasEstimadas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = kilosIngreso <= 0 ? 1.0 : kilosIngreso;

    // La diferencia puede ser negativa (salio mas de lo que entro). En la barra
    // interesa el tamano del hueco, no su signo.
    final tramos = <(String, double, Color)>[
      ('Material de salida', kilosSalida.clamp(0, total), cs.primary),
      ('Merma', kilosMerma.clamp(0, total), cs.tertiary),
      (
        'Sin explicar',
        diferencia.abs().clamp(0, total),
        Color.alphaBlend(cs.onSurface.withValues(alpha: 0.45), cs.surface),
      ),
    ];

    return Container(
      padding: EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Balance del lote',
                  style: context.tituloSeccion(),
                ),
              ),
              EtiquetaCuadre(
                diferenciaKilos: diferencia,
                kilosIngreso: kilosIngreso,
              ),
            ],
          ),
          SizedBox(height: Esp.xs),
          Text(
            'Entraron ${fmtNumero.format(kilosIngreso)} kg',
            style: context.apagado(),
          ),
          SizedBox(height: Esp.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(Esquina.chica),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final (_, valor, color) in tramos)
                    if (valor > 0)
                      Expanded(
                        flex: (valor / total * 1000).round().clamp(1, 1000),
                        child: ColoredBox(color: color),
                      ),
                  // Cuando los tramos no llegan al total, el resto queda vacio
                  // en lugar de estirarse: la escala tiene que ser honesta.
                  if (_restante(total, tramos) > 0)
                    Expanded(
                      flex: (_restante(total, tramos) / total * 1000)
                          .round()
                          .clamp(1, 1000),
                      child: ColoredBox(color: cs.surfaceContainerHighest),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: Esp.m),
          Wrap(
            spacing: Esp.l,
            runSpacing: Esp.s,
            children: [
              for (final (nombre, valor, color) in tramos)
                _Referencia(
                  color: color,
                  nombre: nombre,
                  valor: '${fmtNumero.format(valor)} kg',
                ),
            ],
          ),
          Divider(height: Esp.xl),
          _FilaResmas(
            contadas: resmasContadas,
            estimadas: resmasEstimadas,
          ),
        ],
      ),
    );
  }

  double _restante(double total, List<(String, double, Color)> tramos) {
    final usado = tramos.fold(0.0, (s, t) => s + t.$2);
    return (total - usado).clamp(0, total);
  }
}

class _Referencia extends StatelessWidget {
  const _Referencia({
    required this.color,
    required this.nombre,
    required this.valor,
  });

  final Color color;
  final String nombre;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: Esp.s),
      Text(nombre, style: context.apagado()),
      SizedBox(width: Esp.xs),
      Text(valor, style: context.numero(fuerte: true)),
    ],
  );
}

/// Resmas contadas contra resmas estimadas por balanza.
class _FilaResmas extends StatelessWidget {
  const _FilaResmas({required this.contadas, required this.estimadas});

  final int contadas;
  final double estimadas;

  @override
  Widget build(BuildContext context) {
    final diferencia = contadas - estimadas;
    final sinEstimacion = estimadas <= 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resmas contadas', style: context.apagado()),
              Text(
                fmtEntero.format(contadas),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: Peso.dato,
                  fontFeatures: cifrasTabulares,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimadas por balanza', style: context.apagado()),
              Text(
                sinEstimacion ? '--' : fmtNumero.format(estimadas),
                style: context.numero(fuerte: true),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Diferencia', style: context.apagado()),
              Text(
                sinEstimacion ? '--' : fmtNumero.format(diferencia),
                style: context.numero(fuerte: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El artículo de salida no tiene UTM cargada, así que no se puede estimar.
class AvisoSinUtm extends StatelessWidget {
  const AvisoSinUtm({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: cs.onTertiaryContainer),
          SizedBox(width: Esp.s),
          Flexible(
            child: Text(
              'El articulo de salida no tiene UTM cargada: no se puede estimar '
              'la cantidad de resmas.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
