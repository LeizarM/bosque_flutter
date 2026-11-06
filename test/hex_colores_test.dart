import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

import 'fakes/arnes_hex.dart';

/// Color del módulo Horas Extras (D29): verde y ámbar armonizados con la
/// semilla en claro y oscuro, el mapa de estados y las fichas con ícono.
void main() {
  setUpAll(cargarFuentesHex);
  setUp(HexColores.olvidarCache);

  /// Contraste WCAG entre dos colores opacos.
  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (alto, bajo) = la > lb ? (la, lb) : (lb, la);
    return (alto + 0.05) / (bajo + 0.05);
  }

  double matiz(Color c) => HSLColor.fromColor(c).hue;

  group('armonización', () {
    test('acerca la mitad de la distancia, hasta 15°, por el lado corto', () {
      // Semilla verde (122°): el verde gira 9° hacia ella.
      expect(HexColores.matizArmonizado(140, 122), closeTo(131, 1e-9));
      // Semilla roja (4°): verde y ámbar giran 15° hacia el rojo.
      expect(HexColores.matizArmonizado(140, 4), closeTo(125, 1e-9));
      expect(HexColores.matizArmonizado(40, 4), closeTo(25, 1e-9));
      // Por el lado corto del círculo: de 350° a 10° se sube, no se baja.
      expect(HexColores.matizArmonizado(350, 10), closeTo(0, 1e-9));
      // Mismo matiz: no gira.
      expect(HexColores.matizArmonizado(40, 40), closeTo(40, 1e-9));
    });
  });

  // Azul (0) y rojo (3): el rojo es el caso difícil, cerca del error.
  for (final semilla in [0, 3]) {
    for (final oscuro in [false, true]) {
      final nombre = '${colorList[semilla]} ${oscuro ? 'oscuro' : 'claro'}';
      test('verde y ámbar legibles con la semilla $nombre', () {
        final cs =
            AppTheme(
              isDarkMode: oscuro,
              selectedColor: semilla,
            ).getTheme().colorScheme;
        final hc = HexColores.desde(cs);
        // El verde sigue siendo verde y el ámbar, ámbar (con el giro).
        expect(matiz(hc.exitoContenedor), inInclusiveRange(80, 170));
        expect(matiz(hc.exito), inInclusiveRange(80, 170));
        expect(matiz(hc.pendienteContenedor), inInclusiveRange(15, 70));
        expect(matiz(hc.pendiente), inInclusiveRange(15, 70));
        // Cada par fondo/letra se lee (AA de texto normal).
        expect(contraste(hc.exito, hc.alEnExito), greaterThan(4.5));
        expect(
          contraste(hc.exitoContenedor, hc.alEnExitoContenedor),
          greaterThan(4.5),
        );
        expect(contraste(hc.pendiente, hc.alEnPendiente), greaterThan(4.5));
        expect(
          contraste(hc.pendienteContenedor, hc.alEnPendienteContenedor),
          greaterThan(4.5),
        );
        // El color pleno sirve como ícono o texto sobre la superficie.
        expect(contraste(hc.exito, cs.surface), greaterThan(3));
        expect(contraste(hc.pendiente, cs.surface), greaterThan(3));
        // En claro el contenedor es más claro que el pleno; en oscuro, al revés.
        final contenedorMasClaro =
            hc.exitoContenedor.computeLuminance() > hc.exito.computeLuminance();
        expect(contenedorMasClaro, !oscuro);
      });
    }
  }

  test('se arma una vez por primary y brillo', () {
    final claro = AppTheme(selectedColor: 0).getTheme().colorScheme;
    final oscuro =
        AppTheme(isDarkMode: true, selectedColor: 0).getTheme().colorScheme;
    final rojo = AppTheme(selectedColor: 3).getTheme().colorScheme;
    expect(identical(HexColores.desde(claro), HexColores.desde(claro)), isTrue);
    expect(
      HexColores.desde(claro).exito,
      isNot(HexColores.desde(oscuro).exito),
    );
    expect(HexColores.desde(claro).exito, isNot(HexColores.desde(rojo).exito));
  });

  group('mapa de estados', () {
    test('cada estado con su tono, ícono y tachado (contrato D29)', () {
      final esperado = <String, EstadoVisualHex>{
        'REPORTADO': (
          tono: TonoHex.pendiente,
          icono: Icons.hourglass_top,
          tachado: false,
        ),
        'VISTO_BUENO': (
          tono: TonoHex.terciario,
          icono: Icons.task_alt,
          tachado: false,
        ),
        'APROBADO': (
          tono: TonoHex.exito,
          icono: Icons.verified_outlined,
          tachado: false,
        ),
        'LIQUIDADO': (
          tono: TonoHex.exitoSolido,
          icono: Icons.paid_outlined,
          tachado: false,
        ),
        'RECHAZADO': (
          tono: TonoHex.error,
          icono: Icons.cancel_outlined,
          tachado: false,
        ),
        'ANULADO': (tono: TonoHex.neutro, icono: Icons.block, tachado: true),
        'EJECUTADA': (
          tono: TonoHex.exitoSolido,
          icono: Icons.receipt_long,
          tachado: false,
        ),
        'ANULADA': (tono: TonoHex.neutro, icono: Icons.block, tachado: false),
      };
      for (final MapEntry(key: estado, value: v) in esperado.entries) {
        expect(estadoVisualHex(estado), v, reason: estado);
        expect(tonoEstadoHex(estado), v.tono, reason: estado);
      }
      // Aprobado y pagado ya no se confunden; rechazado y anulado tampoco.
      expect(tonoEstadoHex('APROBADO'), isNot(tonoEstadoHex('LIQUIDADO')));
      expect(tonoEstadoHex('RECHAZADO'), isNot(tonoEstadoHex('ANULADO')));
      expect(estadoVisualHex('OTRO').tono, TonoHex.neutro);
      expect(estadoVisualHex(null).tachado, isFalse);
    });

    for (final oscuro in [false, true]) {
      testWidgets(
        'EtiquetaEstadoHex lleva ícono, color y texto en ${oscuro ? 'oscuro' : 'claro'}',
        (t) async {
          await t.pumpWidget(
            MaterialApp(
              theme: AppTheme(isDarkMode: oscuro, selectedColor: 3).getTheme(),
              home: const Scaffold(
                body: Wrap(
                  children: [
                    EtiquetaEstadoHex('REPORTADO', 'Reportado'),
                    EtiquetaEstadoHex('LIQUIDADO', 'Liquidado'),
                    EtiquetaEstadoHex('ANULADO', 'Anulado'),
                    EtiquetaEstadoHex('APROBADO', ''),
                  ],
                ),
              ),
            ),
          );
          final cs = Theme.of(t.element(find.byType(Scaffold))).colorScheme;
          final hc = HexColores.desde(cs);
          expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
          expect(find.byIcon(Icons.paid_outlined), findsOneWidget);
          expect(find.byIcon(Icons.block), findsOneWidget);
          // Sin texto del SP queda el código: nunca una ficha vacía.
          expect(find.text('APROBADO'), findsOneWidget);
          Text texto(String s) => t.widget<Text>(find.text(s));
          expect(texto('Liquidado').style?.color, hc.alEnExito);
          expect(texto('Reportado').style?.color, hc.alEnPendienteContenedor);
          expect(
            texto('Anulado').style?.decoration,
            TextDecoration.lineThrough,
          );
          expect(texto('Reportado').style?.fontSize, 12);
          final icono = t.widget<Icon>(find.byIcon(Icons.paid_outlined));
          expect(icono.size, 16);
          expect(icono.color, hc.alEnExito);
        },
      );
    }
  });

  group('tipos, días, comidas y tramos', () {
    test('íconos del tipo de reporte, del día y de cada comida', () {
      expect(iconoTipoReporteHex('ANTES'), Icons.wb_twilight);
      expect(iconoTipoReporteHex('DESPUES'), Icons.nightlight_outlined);
      expect(
        iconoTipoReporteHex('SIN_HORARIO'),
        Icons.event_available_outlined,
      );
      expect(diaEspecialHex('DOMINGO'), isTrue);
      expect(diaEspecialHex('FERIADO'), isTrue);
      expect(diaEspecialHex('HABIL'), isFalse);
      expect(iconoComidaHex('D'), Icons.free_breakfast_outlined);
      expect(iconoComidaHex('DD'), Icons.free_breakfast_outlined);
      expect(iconoComidaHex('DA'), Icons.lunch_dining_outlined);
      expect(iconoComidaHex('C'), Icons.dinner_dining_outlined);
      expect(iconoComidaHex('DC'), Icons.dinner_dining_outlined);
      expect(iconoComidaHex('X'), Icons.restaurant_outlined);
      expect(comidaDobleHex('DC'), isTrue);
      expect(comidaDobleHex('C'), isFalse);
    });

    testWidgets('los códigos: tramos por factor y comidas, la doble plena', (
      t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme(selectedColor: 0).getTheme(),
          home: const Scaffold(
            body: Wrap(
              children: [
                CodigoHex(
                  'HS',
                  familia: FamiliaCodigoHex.tramo,
                  multiplicador: 1,
                ),
                CodigoHex(
                  'H50',
                  familia: FamiliaCodigoHex.tramo,
                  multiplicador: 1.5,
                ),
                CodigoHex(
                  'H100',
                  familia: FamiliaCodigoHex.tramo,
                  multiplicador: 2,
                ),
                ComidasHex('C,DC'),
                CodigoHex('ZZ'),
              ],
            ),
          ),
        ),
      );
      final cs = Theme.of(t.element(find.byType(Scaffold))).colorScheme;
      Color fondo(String codigo) {
        final caja = t.widget<Container>(
          find
              .ancestor(of: find.text(codigo), matching: find.byType(Container))
              .first,
        );
        return (caja.decoration! as BoxDecoration).color!;
      }

      expect(fondo('H50'), cs.primaryContainer);
      expect(fondo('H100'), cs.primary);
      // ×1 casi neutro: el contenedor a media presencia, distinto del pleno.
      expect(fondo('HS'), isNot(cs.primaryContainer));
      expect(fondo('DC'), cs.tertiaryContainer);
      expect(fondo('C'), isNot(cs.tertiaryContainer));
      expect(fondo('ZZ'), cs.surfaceContainerHighest);
      expect(find.byIcon(Icons.schedule), findsNWidgets(3));
      expect(find.byIcon(Icons.dinner_dining_outlined), findsNWidgets(2));
    });
  });
}
