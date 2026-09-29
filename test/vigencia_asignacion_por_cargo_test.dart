// El "Desde" de la lista de tareas por cargo (2026-09-10).
//
// La pantalla mostraba `fechaPartida` —desde cuándo existe la TAREA— bajo el
// rótulo "Desde:", cuando lo que corresponde es `fechaInicio`, desde cuándo la
// tiene ESE cargo. Medido contra la base: difieren en 534 de las 541
// asignaciones. En el cargo de la captura decía 2020 cuando la asignación es
// de 2026.
//
// Importa más ahora que la fecha se elige a mano al asignar: si el usuario
// elige una y la lista muestra otra, el campo parece no haber guardado.
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/tareas_rutinarias_por_cargo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> fila({
    String? fechaInicio,
    String? fechaFin,
    String fechaPartida = '2020-07-28',
  }) => {
    'fechaInicio': fechaInicio,
    'fechaFin': fechaFin,
    // Siempre presente y siempre distinta, para que un test no pase por
    // casualidad si alguien vuelve a leer la columna equivocada.
    'fechaPartida': fechaPartida,
  };

  test('muestra la fecha de la ASIGNACIÓN, no la de la tarea', () {
    final t = textoVigenciaAsignacion(fila(fechaInicio: '2026-09-02'));
    expect(t, contains('02/09/2026'));
    expect(
      t,
      isNot(contains('2020')),
      reason: 'Si aparece 2020 está leyendo fechaPartida otra vez.',
    );
  });

  test('sin fecha de fin dice solo "Desde"', () {
    expect(textoVigenciaAsignacion(fila(fechaInicio: '2026-09-02')),
        'Desde: 02/09/2026');
  });

  test('con fecha de fin muestra el rango', () {
    expect(
      textoVigenciaAsignacion(
        fila(fechaInicio: '2026-09-02', fechaFin: '2026-12-31'),
      ),
      'Del 02/09/2026 al 31/12/2026',
    );
  });

  test('sin fecha de inicio no inventa una', () {
    // fechaInicio es NOT NULL en la tabla, así que esto solo pasa si el
    // backend deja de mandar la columna. Mejor un guion que una fecha falsa.
    expect(textoVigenciaAsignacion(fila()), 'Desde: —');
  });

  test('una fecha ilegible tampoco revienta la fila', () {
    expect(textoVigenciaAsignacion(fila(fechaInicio: 'ayer')), 'Desde: —');
  });
}
