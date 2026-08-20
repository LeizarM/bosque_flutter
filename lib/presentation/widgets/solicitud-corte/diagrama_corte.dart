/// El corte, dibujado.
///
/// Una solicitud de corte convierte un rectangulo grande en muchos chicos. El
/// sistema anterior decia eso con un texto —`21.5 * 33.0`— entre dos columnas
/// de numeros, y quien lo leia tenia que imaginarse el resto.
///
/// Aqui se dibuja a escala: la hoja base, el formato de salida embaldosado
/// adentro, y lo que sobra. De un vistazo se ve cuantas hojas entran y cuanta
/// hoja se tira, que es la pregunta que nadie podia contestar sin hacer la
/// cuenta a mano.
///
/// **El color no decora.** El aprovechamiento se dibuja con la familia
/// principal del tema y el desperdicio con un neutro, siguiendo la doctrina de
/// `tokens_bosque`: la app deja elegir entre nueve semillas y una paleta propia
/// se veria rota en cuanto alguien la pase a violeta.
library;

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:flutter/material.dart';

/// Cuantas hojas de [anchoSalida] x [largoSalida] entran en la hoja base, y
/// cuanto de la base queda sin usar.
class Aprovechamiento {
  /// Cuantas entran a lo ancho y a lo largo.
  final int columnas;
  final int filas;

  /// Fraccion de la hoja base que se aprovecha, de 0 a 1.
  final double fraccion;

  const Aprovechamiento({
    required this.columnas,
    required this.filas,
    required this.fraccion,
  });

  int get total => columnas * filas;

  /// El formato de salida no entra en la hoja base.
  bool get noEntra => total == 0;

  static Aprovechamiento calcular({
    required double anchoBase,
    required double largoBase,
    required double anchoSalida,
    required double largoSalida,
  }) {
    if (anchoBase <= 0 ||
        largoBase <= 0 ||
        anchoSalida <= 0 ||
        largoSalida <= 0) {
      return const Aprovechamiento(columnas: 0, filas: 0, fraccion: 0);
    }
    final columnas = (anchoBase / anchoSalida).floor();
    final filas = (largoBase / largoSalida).floor();
    final usada = columnas * anchoSalida * filas * largoSalida;
    return Aprovechamiento(
      columnas: columnas,
      filas: filas,
      fraccion: (usada / (anchoBase * largoBase)).clamp(0.0, 1.0),
    );
  }
}

/// El diagrama con su lectura al lado.
class DiagramaCorte extends StatelessWidget {
  const DiagramaCorte({
    super.key,
    required this.anchoBase,
    required this.largoBase,
    required this.anchoSalida,
    required this.largoSalida,
    this.compacto = false,
  });

  final double anchoBase;
  final double largoBase;
  final double anchoSalida;
  final double largoSalida;

  /// Solo el dibujo, sin la lectura. Para cuando ya hay texto alrededor.
  final bool compacto;

  /// El diagrama de un item ya guardado.
  ///
  /// El formato de salida sale de los campos `*SalidaEsp` cuando estan
  /// cargados y de los `*SAPSalida` cuando no. **Sin esta bifurcacion las 335
  /// solicitudes STD historicas se dibujarian todas en rojo**: ese tipo no usa
  /// los campos Esp, que quedaron en null, y el diagrama concluia que el
  /// formato no entraba en la hoja.
  factory DiagramaCorte.deItem({
    Key? key,
    required double anchoBase,
    required double largoBase,
    required double anchoSalidaEsp,
    required double largoSalidaEsp,
    required double anchoSAPSalida,
    required double largoSAPSalida,
    bool compacto = false,
  }) {
    return DiagramaCorte(
      key: key,
      anchoBase: anchoBase,
      largoBase: largoBase,
      anchoSalida: anchoSalidaEsp > 0 ? anchoSalidaEsp : anchoSAPSalida,
      largoSalida: largoSalidaEsp > 0 ? largoSalidaEsp : largoSAPSalida,
      compacto: compacto,
    );
  }

  /// La hoja base no tiene medidas en SAP: no hay nada que dibujar y decirlo
  /// es mas util que dibujar un cuadro vacio.
  bool get _sinMedidas => anchoBase <= 0 || largoBase <= 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_sinMedidas) {
      if (compacto) return SizedBox(width: 72, height: 72);
      return Text('El item no tiene medidas en SAP.', style: context.apagado());
    }

    final ap = Aprovechamiento.calcular(
      anchoBase: anchoBase,
      largoBase: largoBase,
      anchoSalida: anchoSalida,
      largoSalida: largoSalida,
    );

    final dibujo = SizedBox(
      width: compacto ? 72 : 104,
      height: compacto ? 72 : 104,
      child: CustomPaint(
        painter: _PintorCorte(
          anchoBase: anchoBase,
          largoBase: largoBase,
          anchoSalida: anchoSalida,
          largoSalida: largoSalida,
          aprovechado: cs.primary,
          sobrante: cs.surfaceContainerHighest,
          borde: cs.outline,
          linea: cs.surface,
        ),
      ),
    );

    if (compacto) return dibujo;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dibujo,
        SizedBox(width: Esp.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fmtNumero.format(anchoBase)} × '
                '${fmtNumero.format(largoBase)} cm',
                style: context.apagado(),
              ),
              SizedBox(height: Esp.xs),
              if (anchoSalida <= 0 || largoSalida <= 0)
                Text('Sin formato de salida', style: context.apagado())
              else if (ap.noEntra)
                const Etiqueta(
                  texto: 'El formato no entra en la hoja',
                  tono: TonoEtiqueta.error,
                )
              else ...[
                Text(
                  '${ap.columnas} × ${ap.filas} = ${ap.total} hojas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: Peso.dato,
                    fontFeatures: cifrasTabulares,
                  ),
                ),
                SizedBox(height: Esp.xs),
                Etiqueta(
                  texto: 'Aprovecha ${(ap.fraccion * 100).round()}%',
                  tono: switch (ap.fraccion) {
                    >= 0.85 => TonoEtiqueta.exito,
                    >= 0.70 => TonoEtiqueta.aviso,
                    _ => TonoEtiqueta.error,
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Dibuja la hoja base y las hojas de salida que entran adentro.
///
/// Se dibujan hasta 400 celdas: mas alla de eso la grilla es una textura y no
/// se distingue una celda de otra, asi que no vale lo que cuesta pintarla.
class _PintorCorte extends CustomPainter {
  _PintorCorte({
    required this.anchoBase,
    required this.largoBase,
    required this.anchoSalida,
    required this.largoSalida,
    required this.aprovechado,
    required this.sobrante,
    required this.borde,
    required this.linea,
  });

  final double anchoBase;
  final double largoBase;
  final double anchoSalida;
  final double largoSalida;
  final Color aprovechado;
  final Color sobrante;
  final Color borde;
  final Color linea;

  static const int _maxCeldas = 400;

  @override
  void paint(Canvas canvas, Size size) {
    if (anchoBase <= 0 || largoBase <= 0) return;

    // La hoja base, a escala y centrada, conservando su proporcion real: si el
    // papel es apaisado el dibujo tambien lo es.
    final escala = (size.width / anchoBase) < (size.height / largoBase)
        ? size.width / anchoBase
        : size.height / largoBase;
    final w = anchoBase * escala;
    final h = largoBase * escala;
    final origen = Offset((size.width - w) / 2, (size.height - h) / 2);
    final hoja = origen & Size(w, h);

    canvas.drawRect(hoja, Paint()..color = sobrante);

    final ap = Aprovechamiento.calcular(
      anchoBase: anchoBase,
      largoBase: largoBase,
      anchoSalida: anchoSalida,
      largoSalida: largoSalida,
    );

    if (!ap.noEntra) {
      final cw = anchoSalida * escala;
      final ch = largoSalida * escala;

      // El area aprovechada, de una sola pieza.
      canvas.drawRect(
        origen & Size(cw * ap.columnas, ch * ap.filas),
        Paint()..color = aprovechado,
      );

      // Las lineas de corte, solo si se van a distinguir.
      if (ap.total <= _maxCeldas && cw > 2 && ch > 2) {
        final trazo = Paint()
          ..color = linea
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7;
        for (var c = 1; c < ap.columnas; c++) {
          final x = origen.dx + cw * c;
          canvas.drawLine(
            Offset(x, origen.dy),
            Offset(x, origen.dy + ch * ap.filas),
            trazo,
          );
        }
        for (var f = 1; f < ap.filas; f++) {
          final y = origen.dy + ch * f;
          canvas.drawLine(
            Offset(origen.dx, y),
            Offset(origen.dx + cw * ap.columnas, y),
            trazo,
          );
        }
      }
    }

    canvas.drawRect(
      hoja,
      Paint()
        ..color = borde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PintorCorte v) =>
      v.anchoBase != anchoBase ||
      v.largoBase != largoBase ||
      v.anchoSalida != anchoSalida ||
      v.largoSalida != largoSalida ||
      v.aprovechado != aprovechado;
}

// ═══════════════════════════════════════════════════════════════════════════
// URGENCIA DE LA ENTREGA
// ═══════════════════════════════════════════════════════════════════════════

/// Que tan cerca esta la fecha de entrega comprometida.
enum Urgencia { vencida, estaSemana, masAdelante }

Urgencia urgenciaDe(DateTime? entrega) {
  if (entrega == null) return Urgencia.masAdelante;
  final hoy = DateTime.now();
  final dias = DateTime(
    entrega.year,
    entrega.month,
    entrega.day,
  ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
  if (dias < 0) return Urgencia.vencida;
  if (dias <= 7) return Urgencia.estaSemana;
  return Urgencia.masAdelante;
}

/// La fecha de entrega con su urgencia.
///
/// Una entrega para pasado manana y una para dentro de dos meses no son la
/// misma cosa, y en la pantalla anterior se leian igual.
class EtiquetaEntrega extends StatelessWidget {
  const EtiquetaEntrega({super.key, required this.entrega, this.texto});

  final DateTime? entrega;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final u = urgenciaDe(entrega);
    final cuando = texto?.isNotEmpty == true ? texto! : fechaCorta(entrega);

    return Etiqueta(
      texto: switch (u) {
        Urgencia.vencida => 'Vencida  $cuando',
        Urgencia.estaSemana => 'Esta semana  $cuando',
        Urgencia.masAdelante => cuando,
      },
      tono: switch (u) {
        Urgencia.vencida => TonoEtiqueta.error,
        Urgencia.estaSemana => TonoEtiqueta.aviso,
        Urgencia.masAdelante => TonoEtiqueta.neutro,
      },
    );
  }
}
