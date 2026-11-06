import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/models/hex_json.dart';

/// Lectura y escritura de los campos de Horas Extras con los formatos del
/// contrato: fechas de reloj de La Paz sin zona, horas `HH:mm:ss` y BIT.
void main() {
  test('hexBool acepta true, 1 y "1"', () {
    expect(hexBool(true) && hexBool(1) && hexBool('1'), isTrue);
    expect(hexBool(0), isFalse);
  });

  test('hexBool acepta "true" y rechaza null y texto', () {
    expect(hexBool('true'), isTrue);
    expect([hexBool(null), hexBool('0'), hexBool('no')], [false, false, false]);
  });

  test('hexFecha lee "2026-10-23 18:30:00" sin moverla', () {
    final f = hexFecha('2026-10-23 18:30:00')!;
    expect(
      [f.year, f.month, f.day, f.hour, f.minute, f.isUtc],
      [2026, 10, 23, 18, 30, false],
    );
  });

  test('hexFecha lee ISO sin zona como hora local', () {
    final f = hexFecha('2026-10-24T01:30:00.000')!;
    expect([f.day, f.hour, f.minute, f.isUtc], [24, 1, 30, false]);
    expect(hexFecha(''), isNull);
    expect(hexFecha(null), isNull);
  });

  test('fecha DATE ida y vuelta sin cambiar el día', () {
    expect(hexDiaJson(hexFecha('2026-10-23')), '2026-10-23');
    expect(hexDiaJson(null), isNull);
  });

  test('hexFechaHoraJson no lleva zona ni cambia la hora', () {
    expect(
      hexFechaHoraJson(DateTime(2026, 10, 24, 1, 30)),
      '2026-10-24T01:30:00.000',
    );
    expect(hexFechaHoraJson(null), isNull);
  });

  test('hexHoraN normaliza', () {
    expect(hexHoraN('18:00:00.0000000'), '18:00:00');
    expect(hexHoraN('18:00'), '18:00:00');
  });

  test('hexHoraN descarta lo que no es una hora', () {
    expect(
      [hexHoraN(null), hexHoraN(''), hexHoraN('mañana')],
      [null, null, null],
    );
  });

  test('hexCuerpo quita null y pasa BigInt a int', () {
    expect(hexCuerpo({'a': null, 'b': BigInt.from(5)}), {'b': 5});
  });

  test('hexDecimal lee número y texto', () {
    expect(
      [hexDecimal(15), hexDecimal(15.5), hexDecimal('15.50')],
      [15.0, 15.5, 15.5],
    );
    expect([hexDecimalN(null), hexDecimalN('abc')], [null, null]);
  });

  test('ids y enteros tolerantes', () {
    expect(hexBigInt(12), BigInt.from(12));
    expect(hexBigInt('12'), BigInt.from(12));
    expect(hexBigInt(null), isNull);
    expect([hexIntN('7'), hexIntN(7.0), hexInt(null)], [7, 7, 0]);
  });

  test('texto en blanco es null', () {
    expect(
      [hexTextoN('  '), hexTextoN(null), hexTexto(null), hexTexto('Hola')],
      [null, null, '', 'Hola'],
    );
  });

  test('hexFilas devuelve solo los mapas de una lista', () {
    expect(
      hexFilas([
        {'a': 1},
        'x',
        null,
      ]),
      [
        {'a': 1},
      ],
    );
    expect(hexFilas(null), isEmpty);
  });
}
