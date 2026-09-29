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
}
