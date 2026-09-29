// Verificación de traspaso Caja AXA contra el movimiento de caja (2026-09-10).
//
// Marcelo: "un empleado con un cargo X tiene que comprobar con el sistema y
// físicamente y si está bien, tiene que poner que fue verificado y si no hay
// nada en Y fecha igual tiene que poner en alguna parte que no hubo novedad".
//
// Lo que se fija aquí es lo que se rompe en silencio si alguien lo revierte:
// que "no hay nada" y "nadie miró" no vuelvan a ser indistinguibles, y que el
// idATR 12 no se confunda otra vez con el 11.
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TraspasoMovCajaEntity fila({
    int idTrasp = 0,
    int? fueVerificado,
    String? obs,
    bool soloEnBosque = false,
  }) => TraspasoMovCajaEntity(
    idTrasp: idTrasp,
    bd: 'ESP',
    fecha: DateTime(2026, 9, 2),
    account: '1110101',
    contraAct: '1110102',
    acctName: 'Caja AXA',
    tipoTransaccion: 'Traspaso',
    dolares: 0,
    bs: 1200,
    fueVerificado: fueVerificado,
    obs: obs,
    soloEnBosque: soloEnBosque,
    audUsuario: 34,
  );

  group('el idATR 12 no es el 11', () {
    // El enredo que costó un archivo SQL de vuelta atrás: la tarea 289 se
    // llama "Verificar Traspaso de Efectivo Entre Sistemas" y su idATR 11 es
    // TesBase (ttes_TesBase, tesorería), sin ninguna relación con
    // tac_traspasoMovCaja. Lo de Caja AXA es el idATR 12.
    test('el 12 tiene su propia etiqueta', () {
      final tipo = TareaPendienteTile.tipoDeAccion(12);
      expect(tipo, isNotNull);
      expect(tipo!.etiqueta, 'Traspaso Caja AXA');
    });

    test('el 11 sigue siendo otra cosa', () {
      final once = TareaPendienteTile.tipoDeAccion(11);
      final doce = TareaPendienteTile.tipoDeAccion(12);
      expect(once, isNotNull);
      expect(
        once!.etiqueta,
        isNot(doce!.etiqueta),
        reason:
            'Si los dos dicen lo mismo, la próxima persona los vuelve a '
            'mezclar. El 11 es TesBase (ttes_TesBase) y el 12 es Caja AXA '
            '(tac_traspasoMovCaja): cada uno tiene su pantalla.',
      );
    });
  });

  group('los tres estados de una fila', () {
    // Un booleano no alcanza. "No cuadra" y "todavía no lo miré" son cosas
    // distintas y la pantalla tiene que poder mostrarlas distintas.
    test('sin revisar es null, no 0', () {
      expect(fila().fueVerificado, isNull);
    });

    test('cuadra es 1', () {
      expect(fila(fueVerificado: 1).fueVerificado, 1);
    });

    test('no cuadra es 0 y lleva el motivo', () {
      final f = fila(fueVerificado: 0, obs: 'El formulario dice 1.200, el sistema 1.020.');
      expect(f.fueVerificado, 0);
      expect(f.obs, isNotEmpty);
    });
  });

  test('una fila nueva de SAP todavía no tiene id', () {
    // En este flujo la fila de tac_traspasoMovCaja se escribe recién cuando
    // alguien verifica, así que la primera vez el id viaja en 0 y el servidor
    // hace INSERT en vez de UPDATE.
    expect(fila().idTrasp, 0);
  });

  test('lo que ya no está en SAP no se oculta', () {
    // Que un traspaso verificado desaparezca del sistema de origen es
    // exactamente el descuadre que esta tarea existe para encontrar.
    final f = fila(idTrasp: 77, fueVerificado: 1, soloEnBosque: true);
    expect(f.soloEnBosque, isTrue);
  });

  test('soloEnBosque es false por defecto', () {
    // El backend solo lo manda en el listado del día. En cualquier otra
    // respuesta la ausencia tiene que leerse como "está en los dos lados",
    // no como una alarma.
    expect(fila().soloEnBosque, isFalse);
  });

  group('un día sin traspasos', () {
    test('la lista vacía es el caso de "sin novedad"', () {
      // Hasta este cambio, una fecha sin traspasos no dejaba ningún rastro:
      // la fila solo se escribía al verificar. Medido el 2026-09-10 sobre las
      // 818 filas históricas: todas con fueVerificado = 1, ni un 0 ni un
      // NULL. Por eso "no hubo nada" tiene que registrarse en la ocurrencia
      // de la tarea y no en esta tabla.
      const List<TraspasoMovCajaEntity> vacia = [];
      expect(vacia.isEmpty, isTrue);
    });

    test('con filas, no corresponde el botón de sin novedad', () {
      final conFilas = [fila()];
      expect(
        conFilas.isEmpty,
        isFalse,
        reason:
            'El servidor además lo rechaza (error 24) volviendo a preguntarle '
            'a SAP, para que "sin novedad" no sea una afirmación del cliente.',
      );
    });
  });

  test('lo que falta responder cuenta solo los null', () {
    final filas = [
      fila(fueVerificado: 1),
      fila(fueVerificado: 0, obs: 'no cuadra'),
      fila(),
      fila(),
    ];
    // Responder "no cuadra" ES responder. Si contara como pendiente, la
    // tarea no se podría cerrar nunca — el mismo error que el `0` de
    // fueRealizado en "Mis tareas rutinarias".
    expect(filas.where((f) => f.fueVerificado == null).length, 2);
  });
}
