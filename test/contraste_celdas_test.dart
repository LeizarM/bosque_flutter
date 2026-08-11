import 'dart:math' as math;

import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica que la letra de cada celda se lea sobre su fondo.
///
/// Esto es lo que la paleta anterior no cumplía. Los hex venían del Excel
/// (`#C6EFCE`, `#FFEB9C`…), pensados para papel blanco: en modo oscuro quedaban
/// pastel pálido con la letra clara del tema encima.
///
/// Se prueba contra **las nueve semillas** del tema y **los dos modos**, porque
/// el usuario puede cambiar las dos cosas desde la app: 9 × 2 × 9 letras = 162
/// combinaciones que ningún ojo va a revisar a mano.
void main() {
  /// Contraste WCAG entre dos colores: (L1 + 0.05) / (L2 + 0.05).
  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Los colores del tema llevan opacidad; sobre el fondo real quedan en otro
  /// tono. Se aplana contra la superficie antes de medir, que es lo que el ojo
  /// ve de verdad.
  Color aplanar(Color encima, Color debajo) =>
      Color.alphaBlend(encima, debajo);

  const letras = ['1', 'V', 'P', 'A', 'C', 'E', 'X', 'B', 'L'];

  // WCAG AA para texto chico. La letra de la celda es labelMedium en negrita,
  // así que se le exige el umbral estricto y no el de texto grande (3.0).
  const minimo = 4.5;

  for (var semilla = 0; semilla < colorList.length; semilla++) {
    for (final oscuro in [false, true]) {
      final modo = oscuro ? 'oscuro' : 'claro';
      final nombre = colorList[semilla].toString();

      test('las 9 letras se leen · semilla $semilla · modo $modo', () {
        final tema =
            AppTheme(isDarkMode: oscuro, selectedColor: semilla).getTheme();
        final cs = tema.colorScheme;

        for (final letra in letras) {
          final c = colorDeEstado(cs, letra);
          final fondoReal = aplanar(c.fondo, cs.surface);
          final r = contraste(c.texto, fondoReal);

          expect(
            r,
            greaterThanOrEqualTo(minimo),
            reason:
                'La letra "$letra" queda con contraste '
                '${r.toStringAsFixed(2)}:1 en modo $modo con la semilla '
                '$nombre. El mínimo legible es $minimo:1.',
          );
        }
      });
    }
  }

  /// Distancia perceptual aproximada entre dos colores (0 = identicos).
  ///
  /// El contraste WCAG no sirve para esto: mide SOLO luminancia, y dos colores
  /// que se diferencian por el tono la comparten. Un verde claro y un cian claro
  /// dan contraste 1.00 y sin embargo se distinguen perfectamente.
  double distancia(Color a, Color b) {
    final r1 = (a.r * 255).round(), g1 = (a.g * 255).round(), b1 = (a.b * 255).round();
    final r2 = (b.r * 255).round(), g2 = (b.g * 255).round(), b2 = (b.b * 255).round();
    final rMedio = (r1 + r2) / 2;
    final dr = (r1 - r2).toDouble();
    final dg = (g1 - g2).toDouble();
    final db = (b1 - b2).toDouble();
    return math.sqrt(
      (2 + rMedio / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rMedio) / 256) * db * db,
    );
  }

  test('cada estado se pinta distinto de los demas', () {
    // Dos estados que significan cosas distintas no pueden verse iguales.
    //
    // Igual el color NO es el unico canal: cada celda muestra su letra, y esa
    // es la que informa. El color acompania. Por eso alcanza con que se noten
    // distintos y no hace falta forzar una separacion de luminancia, que es lo
    // que haria falta si el color fuera lo unico.
    for (var semilla = 0; semilla < colorList.length; semilla++) {
      for (final oscuro in [false, true]) {
        final cs =
            AppTheme(isDarkMode: oscuro, selectedColor: semilla)
                .getTheme()
                .colorScheme;
        final vistos = <String, Color>{};

        for (final letra in ['1', 'V', 'C', 'X', 'B']) {
          final fondo = aplanar(colorDeEstado(cs, letra).fondo, cs.surface);
          for (final otro in vistos.entries) {
            expect(
              distancia(fondo, otro.value),
              greaterThan(25),
              reason:
                  'Los estados "$letra" y "${otro.key}" se ven casi iguales '
                  'con la semilla $semilla en modo '
                  '${oscuro ? 'oscuro' : 'claro'}.',
            );
          }
          vistos[letra] = fondo;
        }
      }
    }
  });
}
