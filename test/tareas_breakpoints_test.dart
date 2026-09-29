// Los umbrales de ancho del módulo Tareas Rutinarias.
//
// Se prueban porque son la única razón por la que una pantalla decide entre
// "una columna" y "dos columnas", y equivocarse aquí no rompe nada: solo
// devuelve una pantalla que se ve mal, que es justo lo que nadie nota hasta
// que el dueño del producto manda una captura (2026-09-07: en un monitor de
// 1920 el contenido se clavaba en 700px y sobraban ~980 sin usar).
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('columnasLista', () {
    test('en teléfono va una sola columna', () {
      expect(TareasBreakpoints.columnasLista(360), 1);
      expect(TareasBreakpoints.columnasLista(768), 1);
    });

    test('justo debajo del umbral de split sigue en una', () {
      expect(TareasBreakpoints.columnasLista(TareasBreakpoints.splitMin - 1), 1);
    });

    test('desde el umbral de split pasa a dos', () {
      expect(TareasBreakpoints.columnasLista(TareasBreakpoints.splitMin), 2);
      expect(TareasBreakpoints.columnasLista(1439), 2);
    });

    test('en un monitor ancho llega a tres', () {
      expect(TareasBreakpoints.columnasLista(1440), 3);
      // El caso real de Marcelo: 1920 de pantalla menos ~244 de sidebar.
      expect(TareasBreakpoints.columnasLista(1676), 3);
    });

    test('nunca devuelve cero ni negativo, ni con anchos absurdos', () {
      for (final ancho in [0.0, 1.0, 99999.0]) {
        expect(TareasBreakpoints.columnasLista(ancho), greaterThanOrEqualTo(1));
      }
    });
  });

  group('coherencia entre umbrales', () {
    test('splitMin está por encima de los umbrales de una columna', () {
      // Si splitMin cayera por debajo de mediumMax, habría anchos donde una
      // pantalla se cree "angosta" (se centra en 700) y otra se cree "ancha"
      // (abre dos columnas) al mismo tiempo.
      expect(
        TareasBreakpoints.splitMin,
        greaterThan(TareasBreakpoints.mediumMax),
      );
      expect(
        TareasBreakpoints.splitMin,
        greaterThan(TareasBreakpoints.compactMax),
      );
    });

    test('el tope de dos columnas deja lugar real a cada lado', () {
      // 5:7 sobre el tope, menos el gap: ningún lado puede quedar más angosto
      // que la columna única de 700 que reemplaza, o el cambio empeoraría la
      // pantalla en vez de mejorarla.
      const ancho = TareasBreakpoints.contentMaxWidthSplit - 16;
      expect(ancho * 7 / 12, greaterThan(TareasBreakpoints.contentMaxWidth700));
    });

    test('en el umbral mínimo cada lado sigue siendo usable', () {
      const ancho = TareasBreakpoints.splitMin - 16;
      // El lado angosto (5/12) no puede caer por debajo de ~420px: abajo de
      // eso los campos del formulario se apilan de a uno y las dos columnas
      // dejan de aportar.
      expect(ancho * 5 / 12, greaterThan(420));
    });
  });
}
