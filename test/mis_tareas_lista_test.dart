// Qué ocurrencias entran en "Mis tareas rutinarias" (2026-09-14).
//
// Marcelo, con la pantalla abierta: "las tareas pendientes siguen apareciendo
// ya que esas justamente ya no son diarias". Eran Caja Chica, Caja Fuerte y
// Revisar Autos del día: flujos que se abren desde el menú, cuya ocurrencia se
// crea recién al entrar al submódulo. La lista las mostraba igual, y tocarlas
// solo avisaba que ya no se marcan desde aquí.
//
// Mirando por qué, apareció el otro hueco: el listado trae las ocurrencias de
// toda la empresa y nada miraba `estado`. Lo que la base desactiva sin borrar
// —duplicados por renombre de cargo (SQL 52), lo generado después de una baja
// (38), las diarias de domingo (67)— seguía en pantalla como vencido.
import 'package:bosque_flutter/core/constants/tareas_a_requerimiento.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/mis_tareas_rutinarias_screen.dart';
import 'package:flutter_test/flutter_test.dart';

const _yo = 180;

BitTareaRutiEntity _ocurrencia({
  int codEmpleado = _yo,
  int? idTarRuti = 1,
  int? estado = 1,
}) => BitTareaRutiEntity(
  idBitTarea: 1,
  idTarRuti: idTarRuti,
  codEmpleado: codEmpleado,
  estado: estado,
  fueRealizado: 12,
  audUsuario: -1,
);

void main() {
  test('una tarea rutinaria mía y activa entra', () {
    expect(perteneceAMiLista(_ocurrencia(), _yo), isTrue);
  });

  test('la de otra persona no entra', () {
    expect(perteneceAMiLista(_ocurrencia(codEmpleado: 117), _yo), isFalse);
  });

  test('sin saber todavía quién soy no entra ninguna', () {
    // Falla cerrado mientras userProvider carga: mostrar la lista de toda la
    // empresa unos segundos sería peor que un vacío que se corrige solo.
    expect(perteneceAMiLista(_ocurrencia(), null), isFalse);
  });

  group('lo que la base desactivó sin borrar', () {
    test('con estado 0 no entra', () {
      expect(perteneceAMiLista(_ocurrencia(estado: 0), _yo), isFalse);
    });

    test('sin estado entra: no se esconde una tarea por un dato que falta', () {
      expect(perteneceAMiLista(_ocurrencia(estado: null), _yo), isTrue);
    });
  });

  group('los flujos que se abren desde el menú', () {
    for (final id in TareasARequerimiento.todas) {
      test('el idTarRuti $id no entra aunque esté pendiente y sea mío', () {
        expect(perteneceAMiLista(_ocurrencia(idTarRuti: id), _yo), isFalse);
      });
    }

    test('las que comparten tipo con esos flujos siguen entrando', () {
      // El corte es por idTarRuti y no por idATR. "Verficar Arqueo de Caja"
      // (3) comparte el idATR 3 con Cierre de Operaciones, y "Verificar Cierre
      // de Operaciones" (39) es la que abre la revisión del día.
      expect(perteneceAMiLista(_ocurrencia(idTarRuti: 3), _yo), isTrue);
      expect(perteneceAMiLista(_ocurrencia(idTarRuti: 39), _yo), isTrue);
    });
  });

  group('las vencidas no se muestran', () {
    // Marcelo, 2026-10-05: "estas tareas que ya vencieron que no se muestren,
    // en reporte se verá que no cumplió". La bitácora las sigue contando como
    // no realizadas; aquí solo se deja de ofrecerlas.
    final hoy = DateTime(2026, 10, 5, 15, 30);

    BitTareaRutiEntity vence(DateTime? dia, {int? fueRealizado = 12}) =>
        BitTareaRutiEntity(
          idBitTarea: 1,
          idTarRuti: 1,
          codEmpleado: _yo,
          estado: 1,
          fechaPresentacion: dia,
          fechaLimite: dia,
          fueRealizado: fueRealizado,
          audUsuario: -1,
        );

    test('la que vence hoy se muestra, hasta el final del día', () {
      expect(porResponder(vence(DateTime(2026, 10, 5)), hoy), isTrue);
    });

    test('la que venció ayer ya no', () {
      expect(porResponder(vence(DateTime(2026, 10, 4)), hoy), isFalse);
    });

    test('con plazo hasta mañana se sigue mostrando', () {
      expect(porResponder(vence(DateTime(2026, 10, 6)), hoy), isTrue);
    });

    test('una respondida no se muestra, esté o no en plazo', () {
      expect(
        porResponder(vence(DateTime(2026, 10, 5), fueRealizado: 13), hoy),
        isFalse,
      );
      // "No" también es responder.
      expect(
        porResponder(vence(DateTime(2026, 10, 5), fueRealizado: 0), hoy),
        isFalse,
      );
    });

    test('sin fecha se muestra: no se esconde por un dato que falta', () {
      expect(porResponder(vence(null), hoy), isTrue);
    });
  });

  group('las hechas de pantalla propia', () {
    // Marcelo, 2026-10-05: "una vez que realiza esas tareas que ya no la
    // vuelva hacer. Máximo agregar una observación y en arqueo de caja que
    // pueda imprimir el pdf". Siguen a la vista, en "Hechas", para eso.
    final hoy = DateTime(2026, 10, 5, 15, 30);

    BitTareaRutiEntity hecha({
      int? idATR = 2,
      int? fueRealizado = 13,
      DateTime? dia,
    }) => BitTareaRutiEntity(
      idBitTarea: 1,
      idTarRuti: 1,
      codEmpleado: _yo,
      estado: 1,
      idATR: idATR,
      fechaPresentacion: dia ?? DateTime(2026, 10, 5),
      fechaLimite: dia ?? DateTime(2026, 10, 5),
      fueRealizado: fueRealizado,
      audUsuario: -1,
    );

    test('el arqueo hecho hoy se muestra', () {
      expect(hechaEnPlazo(hecha(), hoy), isTrue);
    });

    test('también los traspasos y la revisión del cierre', () {
      expect(hechaEnPlazo(hecha(idATR: 12), hoy), isTrue);
      expect(hechaEnPlazo(hecha(idATR: 5), hoy), isTrue);
    });

    test('una pendiente no es hecha: sigue en Pendientes', () {
      expect(hechaEnPlazo(hecha(fueRealizado: 12), hoy), isFalse);
      expect(porResponder(hecha(fueRealizado: 12), hoy), isTrue);
    });

    test('una simple respondida no entra: ya mostró su respuesta', () {
      expect(hechaEnPlazo(hecha(idATR: 1), hoy), isFalse);
      expect(hechaEnPlazo(hecha(idATR: null), hoy), isFalse);
    });

    test('pasado su plazo ya no se muestra', () {
      expect(hechaEnPlazo(hecha(dia: DateTime(2026, 10, 4)), hoy), isFalse);
    });
  });
}
