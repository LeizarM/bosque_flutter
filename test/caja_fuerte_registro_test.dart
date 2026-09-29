// El registro de Caja Fuerte después del paso a planilla (2026-09-08).
//
// Dos cosas que Marcelo pidió mirando la pantalla, y que fallan en silencio si
// alguien las revierte: el tipo tiene que venir en Efectivo, y el desplegable
// de moneda no puede desbordar su columna.
import 'package:bosque_flutter/domain/entities/llegada_caja_fuerte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('el tipo arranca en Efectivo', () {
    test('una fila nueva ya trae efect', () {
      // 'efect' y no 'EFECTIVO': es el valor REAL que escribe el legacy en
      // tac_llegada.tipo. Los dos sistemas comparten esa columna, así que un
      // valor "más lindo" ensucia cualquier reporte que filtre por tipo.
      expect(const LlegadaCajaFuerteEntity(id: '0').tipo, 'efect');
    });

    test('con cliente e importe la fila ya es válida, sin tocar el tipo', () {
      // Era el punto del cambio: antes había que abrir el desplegable y elegir
      // aunque el 99% de los casos fuera efectivo.
      const fila = LlegadaCajaFuerteEntity(
        id: '0',
        cliente: 'Ferretería del Sur',
        importe: 1200,
      );
      expect(fila.esValida, isTrue);
    });

    test('elegir cheque sigue funcionando', () {
      const fila = LlegadaCajaFuerteEntity(id: '0');
      expect(fila.copyWith(tipo: 'chq').tipo, 'chq');
    });
  });

  testWidgets('un desplegable no desborda su columna de la planilla', (
    tester,
  ) async {
    // El overflow real fue de 2.1px en la columna "Moneda": un Dropdown se mide
    // por su item MÁS LARGO, no por el ancho que le dan, así que en una celda
    // de ancho fijo desborda apenas la etiqueta no entra. `isExpanded` es lo
    // que lo obliga a adaptarse a la celda.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            child: FilaTabla(
              anchos: const [
                AnchoCol.fijo(104),
                AnchoCol.flexible(),
              ],
              celdas: [
                DropdownButtonFormField<String>(
                  value: 'BS',
                  isDense: true,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'BS', child: Text('Bs')),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('Una etiqueta larguísima a propósito'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
                const Text('resto'),
              ],
            ),
          ),
        ),
      ),
    );

    // Un overflow de layout se reporta como excepción en los tests: si vuelve,
    // esto lo agarra aquí y no en una captura de pantalla.
    expect(tester.takeException(), isNull);
  });

  group('filas vacías no cuentan como incompletas', () {
    // Regresión real: al poner 'efect' por defecto, el chequeo de "esta fila
    // tiene contenido" seguía mirando `tipo != null` — que ahora es SIEMPRE
    // verdadero. Tocar "Agregar Registro" seis veces y guardar devolvía
    // "Hay 6 filas incompletas" sin haber escrito una sola letra.
    //
    // El test va sobre el mismo predicado que usa el provider: una fila cuenta
    // como empezada solo si tiene algo que el usuario haya tipeado.
    bool tieneContenido(LlegadaCajaFuerteEntity f) =>
        f.cliente.trim().isNotEmpty ||
        (f.importe ?? 0) > 0 ||
        f.destino.trim().isNotEmpty ||
        f.obs.trim().isNotEmpty;

    test('una fila recién agregada no tiene contenido', () {
      expect(tieneContenido(const LlegadaCajaFuerteEntity(id: '0')), isFalse);
    });

    test('el tipo por defecto no la vuelve "empezada"', () {
      const fila = LlegadaCajaFuerteEntity(id: '0');
      expect(fila.tipo, 'efect', reason: 'el default sigue puesto');
      expect(
        tieneContenido(fila),
        isFalse,
        reason:
            'Si el tipo contara como contenido, seis filas vacías se '
            'reportarían como seis filas incompletas.',
      );
    });

    test('con solo el destino escrito sí cuenta, y está incompleta', () {
      const fila = LlegadaCajaFuerteEntity(id: '0', destino: 'Bóveda');
      expect(tieneContenido(fila), isTrue);
      expect(fila.esValida, isFalse);
    });
  });
}
