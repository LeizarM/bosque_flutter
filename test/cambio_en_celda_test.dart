import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Con quién se hizo el cambio, visto desde la celda.
///
/// **Por qué esto merece un test propio.** La dirección de la frase —«lo cubre»
/// contra «cubre a»— no se puede deducir de la letra de la celda ni de quién es
/// el titular en `trs_Cambio`: en una PERMUTA los papeles se dan vuelta el
/// sábado de reposición. Es un `CASE` en el SP que cruza persona CON sábado, y
/// si alguna vez se simplifica a mirar sólo la persona, la mitad de las celdas
/// de toda permuta queda diciendo exactamente lo contrario de lo que pasó, sin
/// que nada falle ni avise.
///
/// Los cuatro casos de abajo son una permuta real de la base: el 08/08 falta
/// MARCELO y lo cubre ALMENDRAS; el 15/08 se devuelve el día y falta ALMENDRAS.
CeldaTurnoEntity _celda({
  required String codigoExcel,
  String cambioCon = '',
  String cambioRol = '',
  String cambioTipo = '',
}) => CeldaTurnoEntity(
  idAsignacion: 1,
  idRol: 1,
  idParticipante: 1,
  idSabado: 1,
  codigoExcel: codigoExcel,
  estadoNombre: 'x',
  origen: 'M',
  observacion: '',
  nombreRol: 'QUIEN SEA',
  cambioCon: cambioCon,
  cambioRol: cambioRol,
  cambioTipo: cambioTipo,
);

void main() {
  group('la celda dice con quién se hizo el cambio', () {
    test('permuta: los cuatro renglones, con los papeles dados vuelta', () {
      // 08/08 — el día que se cubre.
      expect(
        _celda(
          codigoExcel: 'C',
          cambioCon: 'ALMENDRAS ROCHA ERICK',
          cambioRol: 'T',
          cambioTipo: 'PERMUTA',
        ).cambioTexto,
        'Permuta · Lo cubre ALMENDRAS ROCHA ERICK',
      );
      expect(
        _celda(
          codigoExcel: '1',
          cambioCon: 'MARCELO JAVIER',
          cambioRol: 'R',
          cambioTipo: 'PERMUTA',
        ).cambioTexto,
        'Permuta · Cubre a MARCELO JAVIER',
      );

      // 15/08 — el día que se devuelve. Las mismas dos personas, la frase al
      // revés: acá el que faltó es el que había cubierto.
      expect(
        _celda(
          codigoExcel: 'C',
          cambioCon: 'MARCELO JAVIER',
          cambioRol: 'T',
          cambioTipo: 'PERMUTA',
        ).cambioTexto,
        'Permuta · Lo cubre MARCELO JAVIER',
      );
      expect(
        _celda(
          codigoExcel: '1',
          cambioCon: 'ALMENDRAS ROCHA ERICK',
          cambioRol: 'R',
          cambioTipo: 'PERMUTA',
        ).cambioTexto,
        'Permuta · Cubre a ALMENDRAS ROCHA ERICK',
      );
    });

    test('cobertura: sin devolución, no se anuncia como permuta', () {
      expect(
        _celda(
          codigoExcel: 'C',
          cambioCon: 'PEREZ PEDRO',
          cambioRol: 'T',
          cambioTipo: 'COBERTURA',
        ).cambioTexto,
        'Lo cubre PEREZ PEDRO',
      );
    });

    test('una celda común no tiene nada que decir', () {
      final c = _celda(codigoExcel: '1');
      expect(c.hayCambio, isFalse);
      expect(c.cambioTexto, isEmpty);
    });

    test('cobertura aprobada sin reemplazo asignado: calla, no miente', () {
      // El SP deja `cambioCon` vacío cuando codEmpleadoReemplazo es NULL.
      // Anunciar «Lo cubre » con el nombre en blanco sería peor que no decir
      // nada, así que se mira el nombre y no el papel.
      final c = _celda(
        codigoExcel: 'C',
        cambioRol: 'T',
        cambioTipo: 'COBERTURA',
      );
      expect(c.hayCambio, isFalse);
      expect(c.cambioTexto, isEmpty);
    });
  });
}
