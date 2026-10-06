import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';

/// Contraste de los colores del modulo de cheques con las nueve semillas del
/// tema, en claro y en oscuro: 18 combinaciones que ningun ojo va a revisar a
/// mano. Texto sobre su fondo: 4,5:1 (WCAG AA). Franjas, puntos e iconos sueltos
/// sobre la superficie: 3:1.
void main() {
  const textoMinimo = 4.5;
  const graficoMinimo = 3.0;

  double contraste(Color a, Color b) => ChequesColores.contraste(a, b);

  /// Aplana un color con opacidad contra el fondo sobre el que cae.
  Color sobre(Color encima, Color debajo) => Color.alphaBlend(encima, debajo);

  for (var semilla = 0; semilla < colorList.length; semilla++) {
    for (final oscuro in [false, true]) {
      final modo = oscuro ? 'oscuro' : 'claro';

      testWidgets('colores del modulo · semilla $semilla · modo $modo', (
        tester,
      ) async {
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme(isDarkMode: oscuro, selectedColor: semilla).getTheme(),
            home: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        );
        final cs = Theme.of(ctx).colorScheme;
        final etiqueta = 'semilla $semilla ($modo)';
        final falla = <String>[];

        void texto(String que, Color letra, Color fondo, [double min = textoMinimo]) {
          final r = contraste(letra, fondo);
          if (r < min) falla.add('$que: ${r.toStringAsFixed(2)}:1 (< $min)');
        }

        // ── Pastillas de estado: suaves y llenas ──────────────────────────
        for (final s in SemanticaCheque.values) {
          texto(
            'pastilla suave ${s.name}',
            ChequesColores.texto(ctx, s),
            ChequesColores.fondo(ctx, s),
          );
          texto(
            'pastilla llena ${s.name}',
            ChequesColores.textoFuerte(ctx, s),
            ChequesColores.fondoFuerte(ctx, s),
          );
          // El tono pleno se ve sobre la superficie de la tarjeta (franja,
          // punto, borde): 3:1.
          texto(
            'tono pleno ${s.name} sobre la superficie',
            ChequesColores.pleno(ctx, s),
            cs.surfaceContainerLow,
            graficoMinimo,
          );
        }

        // ── Texto de situacion bajo la fecha, sobre la fila (con cebrado y
        // con el mouse encima) ───────────────────────────────────────────────
        final filas = <String, Color>{
          'fila': cs.surfaceContainerLow,
          'fila cebrada': sobre(
            cs.onSurface.withValues(alpha: 0.03),
            cs.surfaceContainerLow,
          ),
          'fila con mouse': sobre(
            cs.primary.withValues(alpha: 0.08),
            sobre(cs.onSurface.withValues(alpha: 0.03), cs.surfaceContainerLow),
          ),
        };
        filas.forEach((nombre, fondo) {
          for (final s in SemanticaCheque.values) {
            texto('texto ${s.name} sobre $nombre', ChequesColores.texto(ctx, s), fondo);
          }
          texto('texto atenuado sobre $nombre', cs.onSurfaceVariant, fondo);
          texto('texto de dato sobre $nombre', cs.onSurface, fondo);
        });

        // ── Cabecera de la tabla: tinte del primario ──────────────────────
        final cabecera = sobre(
          cs.primary.withValues(alpha: 0.10),
          cs.surfaceContainerLow,
        );
        texto('rotulo de la tabla', cs.onSurface, cabecera);

        // ── Superficies tintadas: filtros, cabecera de la pantalla ────────
        final filtros = sobre(
          cs.primary.withValues(alpha: 0.04),
          cs.surfaceContainerLow,
        );
        texto('texto de los filtros', cs.onSurface, filtros);
        texto('rotulo atenuado de los filtros', cs.onSurfaceVariant, filtros);
        texto(
          'subtitulo de la cabecera',
          cs.onSurfaceVariant,
          sobre(cs.primary.withValues(alpha: 0.05), cs.surfaceContainerLow),
        );
        texto('icono de la insignia', cs.onPrimaryContainer, cs.primaryContainer);

        // ── Recuadros del resumen ──────────────────────────────────────────
        final recuadroMarca = sobre(
          cs.primary.withValues(alpha: 0.10),
          cs.surfaceContainerLow,
        );
        texto('rotulo del recuadro «Cheques»', cs.primary, recuadroMarca);
        texto('pie del recuadro «Cheques»', cs.onSurfaceVariant, recuadroMarca);
        texto('cifra del recuadro «Cheques»', cs.onSurface, recuadroMarca);
        for (final s in [
          SemanticaCheque.aviso,
          SemanticaCheque.peligro,
          SemanticaCheque.exito,
          SemanticaCheque.info,
        ]) {
          final fondo = ChequesColores.fondo(ctx, s);
          texto('rotulo del recuadro ${s.name}', ChequesColores.texto(ctx, s), fondo);
          texto('pie del recuadro ${s.name}', cs.onSurfaceVariant, fondo);
          texto('cifra del recuadro ${s.name}', cs.onSurface, fondo);
        }

        // ── Moneda: colores de marca ───────────────────────────────────────
        texto('Bs', cs.onPrimaryContainer, cs.primaryContainer);
        texto('\$us', cs.onTertiaryContainer, cs.tertiaryContainer);
        texto('otra moneda', cs.onSurfaceVariant, cs.surfaceContainerHighest);

        // ── Monograma del banco: las nueve posiciones de la rampa ─────────
        for (var i = 0; i < 9; i++) {
          final fondo = colorDeCatalogo(cs, i).fondo;
          texto('monograma $i', letraSobre(fondo), fondo);
        }

        expect(
          falla,
          isEmpty,
          reason: 'Contraste insuficiente con $etiqueta:\n${falla.join('\n')}',
        );
      });
    }
  }

  test('el negro o el blanco del monograma llegan a 4,5:1 en cualquier fondo', () {
    // El peor caso es la luminancia media (~0,18): ahi blanco y negro dan 4,58.
    var peor = double.infinity;
    for (var g = 0; g <= 255; g += 5) {
      final fondo = Color.fromARGB(255, g, g, g);
      peor = peor < contraste(letraSobre(fondo), fondo)
          ? peor
          : contraste(letraSobre(fondo), fondo);
    }
    expect(peor, greaterThanOrEqualTo(textoMinimo));
  });

  testWidgets('los colores con significado no cambian con la semilla', (
    tester,
  ) async {
    // Mismo matiz con cualquier semilla y modo: lo que dice «atrasado» no se
    // vuelve celeste porque el usuario eligio el tema verde.
    final matices = <SemanticaCheque, List<double>>{};
    for (final oscuro in [false, true]) {
      for (var semilla = 0; semilla < colorList.length; semilla++) {
        late BuildContext ctx;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme(isDarkMode: oscuro, selectedColor: semilla).getTheme(),
            home: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        );
        for (final s in [
          SemanticaCheque.exito,
          SemanticaCheque.aviso,
          SemanticaCheque.peligro,
          SemanticaCheque.info,
        ]) {
          matices
              .putIfAbsent(s, () => [])
              .add(HSLColor.fromColor(ChequesColores.fondo(ctx, s)).hue);
        }
      }
    }
    matices.forEach((s, horas) {
      final min = horas.reduce((a, b) => a < b ? a : b);
      final max = horas.reduce((a, b) => a > b ? a : b);
      expect(max - min, lessThan(1.5), reason: '${s.name} cambia de matiz');
    });
    // Y los cuatro son distintos entre si.
    final medios = {
      for (final e in matices.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };
    final valores = medios.values.toList()..sort();
    for (var i = 1; i < valores.length; i++) {
      expect(valores[i] - valores[i - 1], greaterThan(25));
    }
  });
}
