import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/utils/resumen_verificaciones.dart';

import 'fakes/repositorio_verificaciones.dart';

/// El resumen sobre la lista: solo lo cargado, una suma por moneda, y las
/// anuladas no suman.
void main() {
  test('una pagina vacia da ceros', () {
    final r = resumirPaginaVerificaciones(const []);
    expect(r.filas, 0);
    expect(r.validas, 0);
    expect(r.anuladas, 0);
    expect(r.montos, isEmpty);
    expect(r.sinMoneda, 0);
  });

  test('cuenta validas y anuladas y suma por moneda sin mezclarlas', () {
    final r = resumirPaginaVerificaciones([
      verificacionFalsa(1, monto: 1000),
      verificacionFalsa(2, monto: 500.5),
      verificacionFalsa(3, monto: 800, moneda: 'SUS'),
      verificacionFalsa(4, monto: 7777, estado: 'N'),
    ]);
    expect(r.filas, 4);
    expect(r.validas, 3);
    expect(r.anuladas, 1);
    expect(r.montos, {'Bs': 1500.5, r'$us': 800});
  });

  test('una anulada no suma su monto: su deposito no quedo verificado', () {
    final r = resumirPaginaVerificaciones([
      verificacionFalsa(1, monto: 100, estado: 'N'),
    ]);
    expect(r.montos, isEmpty);
    expect(r.anuladas, 1);
    expect(r.validas, 0);
  });

  test('Bs va siempre primero y \$us despues, aunque lleguen al reves', () {
    final r = resumirPaginaVerificaciones([
      verificacionFalsa(1, monto: 5, moneda: 'SUS'),
      verificacionFalsa(2, monto: 9),
    ]);
    expect(r.montos.keys.toList(), ['Bs', r'$us']);
  });

  test('sin moneda conocida el monto no se suma a nadie y se cuenta aparte', () {
    final r = resumirPaginaVerificaciones([
      verificacionFalsa(1, monto: 300, moneda: null),
      verificacionFalsa(2, monto: 400, moneda: null),
      verificacionFalsa(3, monto: 10),
    ]);
    expect(r.montos, {'Bs': 10});
    expect(r.sinMoneda, 2);
    expect(r.validas, 3, reason: 'igual cuentan como validas');
  });

  test('un cheque sin monto no suma ni cuenta como sin moneda', () {
    final r = resumirPaginaVerificaciones([
      verificacionFalsa(1, monto: null, moneda: null),
    ]);
    expect(r.montos, isEmpty);
    expect(r.sinMoneda, 0);
    expect(r.validas, 1);
  });

  test('otra moneda (codigo desconocido) se suma aparte, despues de Bs y \$us', () {
    final r = resumirPaginaVerificaciones([
      verificacionFalsa(1, monto: 3, moneda: 'EUR'),
      verificacionFalsa(2, monto: 4, moneda: 'SUS'),
    ]);
    expect(r.montos.keys.toList(), [r'$us', 'EUR']);
  });
}
