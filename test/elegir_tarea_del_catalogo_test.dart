// El selector de tareas existentes para un cargo (2026-09-10).
//
// Marcelo: "no me gustaría repetir o duplicar la misma tarea rutinaria a un
// cargo o cargos".
//
// El botón de la pantalla de un cargo creaba SIEMPRE una tarea nueva, así que
// quien quería reusar una existente terminaba duplicándola en el catálogo. Se
// ve en los datos: 7 descripciones repetidas, y "Tarea 1" asignada dos veces
// al mismo cargo por dos idTarRuti distintos — que el índice único no puede
// impedir, porque para la base son dos tareas diferentes.
//
// Lo que se fija aquí es la regla que evita eso.
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/elegir_tarea_del_catalogo_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TareaRutinariaEntity tarea(int id, String descripcion, {int idFrec = 6}) =>
      TareaRutinariaEntity(
        idTarRuti: id,
        descripcion: descripcion,
        idFrec: idFrec,
        audUsuario: 34,
      );

  final catalogo = [
    tarea(1, 'Arqueo de Caja'),
    tarea(38, 'Arqueo de Caja'), // el duplicado real del catálogo
    tarea(40, 'Caja Fuerte'),
    tarea(295, 'Verificar traspaso Caja AXA contra movimiento de caja'),
  ];

  test('una tarea que el cargo ya tiene activa no se ofrece', () {
    final r = separarCatalogo(catalogo: catalogo, yaAsignadas: {40: true});
    expect(r.disponibles.map((t) => t.idTarRuti), isNot(contains(40)));
    expect(
      r.inactivas,
      isEmpty,
      reason: 'Una asignación activa no va a ninguna de las dos listas.',
    );
  });

  test('una inactiva no se ofrece para agregar, pero sí se muestra', () {
    // Insertarla de nuevo dejaría DOS filas para el mismo par tarea/cargo: el
    // índice único es filtrado (WHERE estado = 1) y no ve la inactiva. Lo
    // correcto es reactivar la que ya está.
    final r = separarCatalogo(catalogo: catalogo, yaAsignadas: {40: false});
    expect(r.disponibles.map((t) => t.idTarRuti), isNot(contains(40)));
    expect(r.inactivas.map((t) => t.idTarRuti), contains(40));
  });

  test('lo que el cargo no tiene sí se ofrece', () {
    final r = separarCatalogo(catalogo: catalogo, yaAsignadas: {40: true});
    expect(r.disponibles.map((t) => t.idTarRuti), containsAll([1, 38, 295]));
  });

  test('sin asignaciones previas se ofrece todo el catálogo', () {
    final r = separarCatalogo(catalogo: catalogo, yaAsignadas: const {});
    expect(r.disponibles.length, catalogo.length);
    expect(r.inactivas, isEmpty);
  });

  test('las dos "Arqueo de Caja" del catálogo se ofrecen por separado', () {
    // No se deduplican por texto a propósito. Son dos filas distintas de
    // tac_tareaRutinaria y engancharse a la equivocada no es lo mismo: cada
    // una tiene su propia frecuencia y su propio idATR. Que se vean las dos
    // es lo que permite elegir bien; esconder una sería adivinar por el
    // usuario.
    final r = separarCatalogo(catalogo: catalogo, yaAsignadas: {1: true});
    expect(r.disponibles.map((t) => t.idTarRuti), contains(38));
    expect(r.disponibles.map((t) => t.idTarRuti), isNot(contains(1)));
  });

  group('la búsqueda', () {
    test('filtra por texto, sin distinguir mayúsculas', () {
      final r = separarCatalogo(
        catalogo: catalogo,
        yaAsignadas: const {},
        busqueda: 'CAJA fuerte',
      );
      expect(r.disponibles.length, 1);
      expect(r.disponibles.single.idTarRuti, 40);
    });

    test('no rompe la exclusión', () {
      // Buscar no puede hacer aparecer algo que el cargo ya tiene: sería la
      // forma más fácil de saltarse la regla sin darse cuenta.
      final r = separarCatalogo(
        catalogo: catalogo,
        yaAsignadas: {40: true},
        busqueda: 'caja fuerte',
      );
      expect(r.disponibles, isEmpty);
    });

    test('los espacios de más no cuentan', () {
      final r = separarCatalogo(
        catalogo: catalogo,
        yaAsignadas: const {},
        busqueda: '   ',
      );
      expect(r.disponibles.length, catalogo.length);
    });
  });

  test('lo disponible viene ordenado por descripción', () {
    final r = separarCatalogo(catalogo: catalogo, yaAsignadas: const {});
    final textos = r.disponibles.map((t) => t.descripcion).toList();
    final ordenados = [...textos]..sort();
    expect(textos, ordenados);
  });
}
