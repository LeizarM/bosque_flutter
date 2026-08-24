import 'dart:math' as math;

import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Fija los tres escalones de superficie del módulo de Comisiones.
///
/// El tema de la app sale de `colorSchemeSeed`, así que Material tiñe **toda**
/// la escala de grises con el acento que el usuario eligió. Con la semilla
/// verde, la página, la tarjeta y el encabezado de tabla salían los tres del
/// mismo verde y separados por 1,05:1 — a ojo, un plano único. Ese es el
/// defecto que `ComisionesTema.temaModulo` corrige neutralizando las
/// superficies sin tocar el acento.
///
/// Este archivo existe porque ese arreglo es un `copyWith` y nada impide que el
/// próximo lo pise. La suite responsive no sirve de aval: no lee un solo color.
///
/// Se barren **las nueve semillas** y **los dos modos**, porque el usuario
/// cambia ambas cosas desde ajustes: 18 combinaciones que nadie va a revisar a
/// mano.
void main() {
  /// Contraste WCAG entre dos colores: (L1 + 0.05) / (L2 + 0.05).
  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Umbrales deliberadamente bajos: no se persigue legibilidad de texto acá,
  /// sino que las capas **se distingan como capas**. Los valores medidos con la
  /// paleta actual son 1,171 y 1,283 en claro, 1,124 y 1,319 en oscuro; los
  /// pisos dejan margen para un ajuste fino de la paleta pero no para volver al
  /// plano único de 1,05.
  const minPaginaTarjeta = 1.10;
  const minTarjetaEncabezado = 1.20;

  // Texto sobre la tarjeta: acá sí manda WCAG AA para texto chico.
  const minTexto = 4.5;

  /// Monta el tema del módulo. `temaModulo` toma un BuildContext porque lee el
  /// tema de la app, así que hace falta un árbol; se saca el ThemeData desde
  /// adentro de un Builder.
  Future<ThemeData> temaDelModulo(WidgetTester tester, ThemeData app) async {
    late ThemeData capturado;
    await tester.pumpWidget(
      MaterialApp(
        theme: app,
        // ResponsiveBreakpoints es obligatorio: temaModulo consulta
        // ResponsiveUtilsBosque.esMovil para la densidad, y sin ancestro eso
        // lanza dentro del Builder. El sintoma que llega es un
        // LateInitializationError sobre `capturado`, que no dice nada.
        builder:
            (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: ResponsiveUtilsBosque.breakpoints,
            ),
        home: Builder(
          builder: (context) {
            capturado = ComisionesTema.temaModulo(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return capturado;
  }

  for (var semilla = 0; semilla < colorList.length; semilla++) {
    for (final oscuro in [false, true]) {
      final modo = oscuro ? 'oscuro' : 'claro';

      testWidgets(
        'las superficies se escalonan · semilla $semilla · modo $modo',
        (tester) async {
          final app =
              AppTheme(isDarkMode: oscuro, selectedColor: semilla).getTheme();
          final cs = (await temaDelModulo(tester, app)).colorScheme;

          final pagina = cs.surface;
          final tarjeta = cs.surfaceContainerLow; // default de Card en M3
          final encabezado = cs.surfaceContainerHighest;

          final a = contraste(pagina, tarjeta);
          final b = contraste(tarjeta, encabezado);

          expect(
            a,
            greaterThan(minPaginaTarjeta),
            reason:
                'La tarjeta no se despega de la página: '
                '${a.toStringAsFixed(3)}:1 en modo $modo con la semilla '
                '$semilla. Mínimo $minPaginaTarjeta:1.',
          );
          expect(
            b,
            greaterThan(minTarjetaEncabezado),
            reason:
                'El encabezado de tabla no se despega de la tarjeta: '
                '${b.toStringAsFixed(3)}:1 en modo $modo con la semilla '
                '$semilla. Mínimo $minTarjetaEncabezado:1.',
          );

          // Además de separarse, las capas tienen que separarse *hacia donde
          // corresponde*. Un escalón del tamaño correcto pero al revés pasa
          // los dos expect de arriba y se ve mal igual.
          //
          // La tarjeta va SIEMPRE por encima de la página, en los dos modos:
          // es la superficie que sostiene el contenido y tiene que adelantarse.
          expect(
            tarjeta.computeLuminance(),
            greaterThan(pagina.computeLuminance()),
            reason:
                'En modo $modo la tarjeta quedó más oscura que la página: se '
                'hunde en vez de adelantarse.',
          );

          // El encabezado NO sigue esa regla, y no es un descuido: en Material
          // los contenedores altos se oscurecen en claro y se aclaran en
          // oscuro, porque en los dos casos se alejan del blanco de la tarjeta.
          // Exigir "siempre más claro" haría fallar los nueve casos claros con
          // la paleta correcta puesta.
          if (oscuro) {
            expect(
              encabezado.computeLuminance(),
              greaterThan(tarjeta.computeLuminance()),
              reason:
                  'En oscuro el encabezado de tabla tiene que aclararse '
                  'respecto de la tarjeta.',
            );
          } else {
            expect(
              encabezado.computeLuminance(),
              lessThan(tarjeta.computeLuminance()),
              reason:
                  'En claro el encabezado de tabla tiene que oscurecerse '
                  'respecto de la tarjeta.',
            );
          }

          // Y que sobre esas superficies se lea el texto.
          expect(
            contraste(cs.onSurface, tarjeta),
            greaterThanOrEqualTo(minTexto),
            reason: 'onSurface no se lee sobre la tarjeta en modo $modo.',
          );
          expect(
            contraste(cs.onSurfaceVariant, encabezado),
            greaterThanOrEqualTo(minTexto),
            reason:
                'El rótulo de columna no se lee sobre el encabezado en modo '
                '$modo.',
          );
        },
      );
    }
  }

  // Control negativo: sin el módulo de por medio, el tema crudo de la app SÍ
  // aplana las capas. Si este caso empieza a fallar es que Material cambió su
  // escala de superficies, y entonces los pisos de arriba hay que releerlos.
  testWidgets('control negativo: el tema crudo de la app aplana', (
    tester,
  ) async {
    final cs =
        AppTheme(isDarkMode: false, selectedColor: 0).getTheme().colorScheme;
    expect(
      contraste(cs.surfaceContainerLow, cs.surfaceContainerHighest),
      lessThan(minTarjetaEncabezado),
      reason:
          'El tema crudo dejó de aplanar. Este test ya no prueba nada: '
          'revisar si el módulo sigue haciendo falta.',
    );
  });
}
