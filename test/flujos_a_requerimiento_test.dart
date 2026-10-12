// Los flujos que se abren desde el menú, a demanda (archivos SQL 40, 41 y 63).
//
// Eran cuatro. Desde el 2026-09-11 son tres: Cierre de Operaciones salió del
// menú (archivo SQL 63) y su pantalla —la revisión del día— se abre desde "Mis
// tareas rutinarias" con la ocurrencia de "Verificar Cierre de Operaciones",
// que genera el Job.
//
// Hay dos cosas aquí que, si se rompen, se rompen EN SILENCIO — nadie ve un
// error, simplemente el sistema hace algo distinto de lo acordado:
//
//  1. El corte va por `idTarRuti` y NO por `idATR`. El idATR 3 tiene DOS tareas
//     ("Cierre de Operaciones" y "Verficar Arqueo de Caja") y hoy ninguna de
//     las dos se abre a demanda. Si alguien "simplifica" esto a idATR, se
//     llevaría puestas tareas de otro tipo sin que nadie se entere.
//
//  2. Desde el archivo SQL 96 estos flujos no tienen ocurrencia: la lista de
//     autos es una por sucursal y día, y cada auto dice quién lo marcó.
import 'package:bosque_flutter/core/constants/tareas_a_requerimiento.dart';
import 'package:bosque_flutter/data/models/coche_del_dia_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('qué salió y qué se quedó', () {
    test('los tres flujos que se abren desde el menú están, y son tres', () {
      expect(TareasARequerimiento.todas, hasLength(3));
      expect(
        TareasARequerimiento.todas,
        containsAll(<int>[
          TareasARequerimiento.cajaFuerte,
          TareasARequerimiento.coches,
          TareasARequerimiento.cajaChica,
        ]),
      );
    });

    test('los ids son los que marca el archivo SQL 40', () {
      // Si estos números cambian sin cambiar el UPDATE de la Parte B del 40, el
      // Job sigue generando la tarea Y además aparece el submódulo: el trabajo
      // se haría dos veces.
      expect(TareasARequerimiento.cajaFuerte, 40);
      expect(TareasARequerimiento.coches, 41);
      expect(TareasARequerimiento.cajaChica, 42);
      // Se queda como registro: es el id que el archivo SQL 41 le dio a la hoja
      // del menú que borró el 63.
      expect(TareasARequerimiento.cierreOperaciones, 2);
    });

    test(
      'las dos tareas de idATR 3 se abren desde "Mis tareas", no a demanda',
      () {
        // "Verficar Arqueo de Caja" (3) porque nunca salió del generador, y
        // "Cierre de Operaciones" (2) porque el archivo SQL 63 le sacó el ítem
        // del menú: su pantalla ahora se abre con la ocurrencia de la tarea.
        expect(TareasARequerimiento.contiene(3), isFalse);
        expect(TareasARequerimiento.contiene(2), isFalse);
      },
    );

    test('el arqueo de caja y verificar cierre siguen siendo rutinarias', () {
      // Arqueo: idTarRuti 1 y 38 (97% y 88% de cumplimiento medido).
      expect(TareasARequerimiento.contiene(1), isFalse);
      expect(TareasARequerimiento.contiene(38), isFalse);
      // Verificar Cierre de Operaciones: idTarRuti 39.
      expect(TareasARequerimiento.contiene(39), isFalse);
    });

    test('un idTarRuti nulo o desconocido no se toma por movido', () {
      expect(TareasARequerimiento.contiene(null), isFalse);
      expect(TareasARequerimiento.contiene(9999), isFalse);
    });
  });

  group('Revisar Autos sin ocurrencia (archivo SQL 96)', () {
    test('cada auto marcado dice quién lo marcó', () {
      final auto =
          CocheDelDiaModel.fromJson({
            'idCo': 7,
            'idCoche': 11,
            'llego': 1,
            'fecha': '2026-10-12T09:14:00',
            'quienMarco': 'QUISPE MAMANI RONALDO',
          }).toEntity();

      expect(auto.yaMarcado, isTrue);
      expect(auto.quienMarco, 'QUISPE MAMANI RONALDO');
    });

    test('marcar no borra quién marcó antes de releer la lista', () {
      final auto =
          CocheDelDiaModel.fromJson({
            'idCo': 7,
            'llego': 1,
            'quienMarco': 'QUISPE MAMANI RONALDO',
          }).toEntity();

      final otraVez = auto.copyWith(llego: 0, obs: 'En taller');
      expect(otraVez.llego, 0);
      expect(otraVez.quienMarco, 'QUISPE MAMANI RONALDO');
    });

    test('un auto sin marcar no tiene quién', () {
      final auto = CocheDelDiaModel.fromJson({'idCo': 8}).toEntity();
      expect(auto.yaMarcado, isFalse);
      expect(auto.quienMarco, isNull);
    });
  });
}
