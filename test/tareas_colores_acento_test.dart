import 'dart:math' as math;

import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los acentos del módulo Tareas Rutinarias, después de subirles la saturación
/// (2026-09-08: "que se vean esos pequeños detalles más vívidos").
///
/// Subir saturación es justo el cambio que puede empeorar la lectura sin que se
/// note mirando: un color más vivo puede acercarse en luminancia a su fondo. Lo
/// que sigue mide eso, en los dos modos, contra la superficie real.
void main() {
  /// Contraste WCAG entre dos colores: (L1 + 0.05) / (L2 + 0.05).
  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// Monta un contexto en el modo pedido y devuelve lo que la función de color
  /// resuelve ahí.
  Future<T> enModo<T>(
    WidgetTester tester,
    Brightness brillo,
    T Function(BuildContext) leer,
  ) async {
    late T valor;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brillo),
        home: Builder(
          builder: (context) {
            valor = leer(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return valor;
  }

  // Los acentos de primer plano del módulo. Todos salen del mismo helper
  // interno, así que si la saturación rompe uno los rompe a todos — pero se
  // listan por nombre para que el fallo diga cuál.
  final acentos = <String, Color Function(BuildContext)>{
    'pendiente': TareasColors.pendienteTexto,
    'vencido': TareasColors.vencidoTexto,
    'realizado': TareasColors.realizadoTexto,
    'documentación': TareasColors.documentacionTexto,
    'vales': TareasColors.valesTexto,
    'caja fuerte': TareasColors.cajaFuerteTexto,
    'SAP': TareasColors.sapMovimientoTexto,
    'tipo de cambio': TareasColors.tipoCambioTexto,
    'eliminar': TareasColors.eliminar,
  };

  for (final modo in [Brightness.light, Brightness.dark]) {
    final fondo = modo == Brightness.light ? Colors.white : const Color(0xFF121212);

    group('modo ${modo.name}', () {
      for (final entrada in acentos.entries) {
        testWidgets('el acento "${entrada.key}" se lee sobre la superficie', (
          tester,
        ) async {
          final color = await enModo(tester, modo, entrada.value);
          // 3:1 es el mínimo WCAG para elementos gráficos e iconografía —
          // que es lo que estos colores pintan: iconos de 18px, franjas y
          // texto de píldora en negrita.
          expect(
            contraste(color, fondo),
            greaterThanOrEqualTo(3.0),
            reason:
                'El acento "${entrada.key}" quedó demasiado cerca del fondo '
                'en modo ${modo.name}. Subir saturación sin bajar luminancia '
                'es lo que produce esto.',
          );
        });
      }
    });
  }

  testWidgets('el rojo de borrar se distingue del rojo de "vencido"', (
    tester,
  ) async {
    // Son dos cosas distintas y comparten familia de tono: "vencido" es un
    // ESTADO que tiñe fondos, "eliminar" es una ACCIÓN destructiva. Si
    // terminaran idénticos, el ícono de borrar se leería como un estado.
    final borrar = await enModo(
      tester,
      Brightness.light,
      TareasColors.eliminar,
    );
    final vencido = await enModo(
      tester,
      Brightness.light,
      TareasColors.vencidoTexto,
    );
    expect(borrar, isNot(vencido));
  });

  testWidgets('los fondos siguen siendo suaves', (tester) async {
    // La contracara del cambio: los acentos subieron de saturación, los FONDOS
    // no. Un fondo de tarjeta con contraste alto contra la superficie
    // convierte la pantalla en un semáforo, que es lo que se evitó.
    for (final leer in <Color Function(BuildContext)>[
      TareasColors.pendiente,
      TareasColors.vencido,
      TareasColors.realizado,
    ]) {
      final fondo = await enModo(tester, Brightness.light, leer);
      expect(
        contraste(fondo, Colors.white),
        lessThan(1.6),
        reason:
            'Este color tiñe tarjetas y filas enteras: tiene que quedar cerca '
            'del blanco, no competir con el texto que lleva encima.',
      );
    }
  });
}
