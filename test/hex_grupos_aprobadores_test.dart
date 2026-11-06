import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_grupos_aprobadores.dart';

import 'fakes/repositorio_hex.dart';

/// El agrupado de «Aprobadores» por jefe de área: grupos, nodos, cuentas,
/// elección del rol, cerradas y el filtro de empleado. Sin widgets.
void main() {
  final hoy = DateTime(2026, 11, 5);
  final b = BigInt.from;

  List<String> nombres(GrupoAprobadoresHex g) => [
    for (final n in g.nodos) n.nombre,
  ];
  List<String?> jefes(List<GrupoAprobadoresHex> g) => [
    for (final x in g) x.jefe?.nombreAprobador,
  ];
  List<GrupoAprobadoresHex> agrupar(
    List<HexAprobadorEntity> filas, {
    bool conCerradas = false,
    int? cod,
  }) => agruparAprobadoresHex(
    filas,
    hoy: hoy,
    conCerradas: conCerradas,
    codEmpleado: cod == null ? null : b(cod),
  );

  group('estado y visibilidad', () {
    test('vigente si el SP lo dice, cerrada si su fin pasó, si no '
        'programada', () {
      final vigente = rolAprobadorFalso(1, 1, 'A');
      final cerrada = rolAprobadorFalso(
        2,
        1,
        'A',
        desde: DateTime(2025),
        hasta: DateTime(2026, 11, 4),
        vigente: false,
      );
      final programada = rolAprobadorFalso(
        3,
        1,
        'A',
        desde: DateTime(2026, 12),
        vigente: false,
      );
      expect(estadoAprobadorHex(vigente, hoy), EstadoAprobadorHex.vigente);
      expect(estadoAprobadorHex(cerrada, hoy), EstadoAprobadorHex.cerrada);
      expect(
        estadoAprobadorHex(programada, hoy),
        EstadoAprobadorHex.programada,
      );
      expect(visibleAprobadorHex(cerrada, hoy), isFalse);
      expect(visibleAprobadorHex(programada, hoy), isTrue);
      expect(visibleAprobadorHex(vigente, hoy), isTrue);
    });
  });

  group('agrupado', () {
    final datos = [
      parAprobadorFalso(
        2,
        8,
        'Paredes Limachi Rosa',
        9,
        'Quispe Mamani Ana',
        rama: 5,
      ),
      parAprobadorFalso(
        5,
        8,
        'Paredes Limachi Rosa',
        7,
        'Rojas Vargas Luis',
        rama: 2,
      ),
      parAprobadorFalso(
        10,
        20,
        'Aguilar Cuenca Alvaro',
        9,
        'Quispe Mamani Ana',
        rama: 5,
      ),
      rolAprobadorFalso(6, 9, 'Quispe Mamani Ana', rama: 5),
      rolAprobadorFalso(1, 7, 'Rojas Vargas Luis', rama: 2),
      rolAprobadorFalso(3, 11, 'Mendoza Cruz Pedro', rama: 3),
      rolAprobadorFalso(4, 10, 'Choque Flores Mario', rama: 1),
    ];

    test('sin filas no hay grupos', () {
      expect(agrupar(const []), isEmpty);
    });

    test('un grupo por jefe, por nombre, y al final los encargados sin '
        'jefe', () {
      final g = agrupar(datos);
      expect(jefes(g), ['Aguilar Cuenca Alvaro', 'Paredes Limachi Rosa', null]);
      expect(g.last.sinJefe, isTrue);
      expect(nombres(g[0]), ['Quispe Mamani Ana']);
      expect(nombres(g[1]), ['Quispe Mamani Ana', 'Rojas Vargas Luis']);
      // Quispe y Rojas tienen jefe: no van en «Sin jefe de área».
      expect(nombres(g.last), ['Choque Flores Mario', 'Mendoza Cruz Pedro']);
    });

    test('cada nodo bajo un jefe lleva su par y el rol del encargado', () {
      final quispe = agrupar(datos)[1].nodos.first;
      expect(quispe.par!.idAprobador, b(2));
      expect(quispe.rol!.idAprobador, b(6));
      expect(quispe.codEncargado, b(9));
      expect(quispe.datos, same(quispe.rol));
      final suelto = agrupar(datos).last.nodos.first;
      expect(suelto.par, isNull);
      expect(suelto.rol!.idAprobador, b(4));
    });

    test('el jefe cuenta sus encargados y la suma de sus ramas', () {
      final g = agrupar(datos);
      expect((g[1].encargados, g[1].empleados), (2, 7));
      expect((g[0].encargados, g[0].empleados), (1, 5));
    });

    test('un par sin rol de encargado toma los datos del par', () {
      final g = agrupar([
        parAprobadorFalso(
          2,
          8,
          'Paredes Limachi Rosa',
          9,
          'Quispe Mamani Ana',
          cargo: 'Supervisora de almacenes',
          rama: 5,
        ),
      ]);
      final n = g.single.nodos.single;
      expect(n.rol, isNull);
      expect(n.nombre, 'Quispe Mamani Ana');
      expect(n.datos.cargo, 'Supervisora de almacenes');
      expect(n.codEncargado, b(9));
      expect((g.single.encargados, g.single.empleados), (1, 5));
    });

    test('el rol elegido: el vigente, si no el programado más próximo, si '
        'no el más reciente', () {
      final cerrado = rolAprobadorFalso(
        11,
        9,
        'Quispe Mamani Ana',
        desde: DateTime(2025, 1, 1),
        hasta: DateTime(2025, 6, 30),
        vigente: false,
      );
      final vigente = rolAprobadorFalso(12, 9, 'Quispe Mamani Ana');
      final lejano = rolAprobadorFalso(
        13,
        9,
        'Quispe Mamani Ana',
        desde: DateTime(2027, 3, 1),
        vigente: false,
      );
      final proximo = rolAprobadorFalso(
        14,
        9,
        'Quispe Mamani Ana',
        desde: DateTime(2027, 1, 1),
        vigente: false,
      );
      final reciente = rolAprobadorFalso(
        15,
        9,
        'Quispe Mamani Ana',
        desde: DateTime(2025, 7, 1),
        hasta: DateTime(2025, 12, 31),
        vigente: false,
      );
      BigInt? elegido(List<HexAprobadorEntity> filas) =>
          agrupar(
            filas,
            conCerradas: true,
          ).single.nodos.single.rol!.idAprobador;
      expect(elegido([cerrado, lejano, vigente]), b(12));
      expect(elegido([cerrado, lejano, proximo]), b(14));
      expect(elegido([cerrado, reciente]), b(15));
      // Bajo un jefe se elige igual.
      final bajoJefe = agrupar([
        parAprobadorFalso(2, 8, 'Paredes Limachi Rosa', 9, 'Quispe Mamani Ana'),
        lejano,
        proximo,
      ]);
      expect(bajoJefe.single.nodos.single.rol!.idAprobador, b(14));
    });

    test('sin «Mostrar cerradas» se omiten las cerradas; con ellas se ven '
        'pero no cuentan', () {
      final filas = [
        parAprobadorFalso(
          2,
          8,
          'Paredes Limachi Rosa',
          9,
          'Quispe Mamani Ana',
          rama: 5,
        ),
        parAprobadorFalso(
          5,
          8,
          'Paredes Limachi Rosa',
          7,
          'Rojas Vargas Luis',
          rama: 2,
          desde: DateTime(2025, 1, 1),
          hasta: DateTime(2025, 6, 30),
          vigente: false,
        ),
        rolAprobadorFalso(1, 7, 'Rojas Vargas Luis', rama: 2),
      ];
      final sin = agrupar(filas);
      expect(nombres(sin.first), ['Quispe Mamani Ana']);
      // Su par cerró: Rojas queda sin jefe.
      expect(sin.last.sinJefe, isTrue);
      expect(nombres(sin.last), ['Rojas Vargas Luis']);

      final con = agrupar(filas, conCerradas: true);
      expect(con, hasLength(1));
      expect(nombres(con.single), ['Quispe Mamani Ana', 'Rojas Vargas Luis']);
      expect((con.single.encargados, con.single.empleados), (1, 5));
    });

    test('dos pares del mismo jefe y encargado: dos nodos, el más reciente '
        'primero, y cuenta una vez', () {
      final g = agrupar([
        parAprobadorFalso(
          2,
          8,
          'Paredes Limachi Rosa',
          9,
          'Quispe Mamani Ana',
          rama: 5,
          desde: DateTime(2025, 1, 1),
          hasta: DateTime(2025, 6, 30),
          vigente: false,
        ),
        parAprobadorFalso(
          3,
          8,
          'Paredes Limachi Rosa',
          9,
          'Quispe Mamani Ana',
          rama: 5,
          desde: DateTime(2025, 7, 1),
        ),
      ], conCerradas: true);
      expect(
        [for (final n in g.single.nodos) n.par!.idAprobador],
        [b(3), b(2)],
      );
      expect((g.single.encargados, g.single.empleados), (1, 5));
    });

    test('filtrar por un jefe deja su grupo entero', () {
      final g = agrupar(datos, cod: 8);
      expect(jefes(g), ['Paredes Limachi Rosa']);
      expect(nombres(g.single), ['Quispe Mamani Ana', 'Rojas Vargas Luis']);
    });

    test('filtrar por un encargado deja sus nodos con el encabezado y las '
        'cuentas del grupo', () {
      final g = agrupar(datos, cod: 7);
      expect(jefes(g), ['Paredes Limachi Rosa']);
      expect(nombres(g.single), ['Rojas Vargas Luis']);
      expect((g.single.encargados, g.single.empleados), (2, 7));
      // Un encargado de dos jefes aparece bajo los dos.
      expect(jefes(agrupar(datos, cod: 9)), [
        'Aguilar Cuenca Alvaro',
        'Paredes Limachi Rosa',
      ]);
    });

    test('D45: el observador forma su propio grupo y no saca al encargado '
        'de «Sin jefe de área»', () {
      final g = agrupar([
        rolAprobadorFalso(1, 7, 'Rojas Vargas Luis', rama: 2),
        rolAprobadorFalso(2, 9, 'Quispe Mamani Ana', rama: 5),
        parAprobadorFalso(
          3,
          8,
          'Paredes Limachi Rosa',
          9,
          'Quispe Mamani Ana',
          rama: 5,
        ),
        observadorAprobadorFalso(
          4,
          12,
          'Aguilar Cuenca Alvaro',
          7,
          'Rojas Vargas Luis',
          rama: 2,
        ),
        observadorAprobadorFalso(
          5,
          12,
          'Aguilar Cuenca Alvaro',
          9,
          'Quispe Mamani Ana',
          rama: 5,
        ),
      ]);
      // Primero los jefes, luego los observadores y al final «sin jefe».
      expect(jefes(g), ['Paredes Limachi Rosa', 'Aguilar Cuenca Alvaro', null]);
      expect([for (final x in g) x.esObservador], [false, true, false]);
      final observador = g[1];
      expect(nombres(observador), ['Quispe Mamani Ana', 'Rojas Vargas Luis']);
      expect((observador.encargados, observador.empleados), (2, 7));
      // Rojas no tiene jefe: el observador no lo cubre.
      expect(g.last.sinJefe, isTrue);
      expect(nombres(g.last), ['Rojas Vargas Luis']);
    });

    test('D45: filtrar por el observador deja su grupo; por un encargado, '
        'sus nodos bajo cada grupo', () {
      final filas = [
        rolAprobadorFalso(1, 7, 'Rojas Vargas Luis', rama: 2),
        observadorAprobadorFalso(
          4,
          12,
          'Aguilar Cuenca Alvaro',
          7,
          'Rojas Vargas Luis',
          rama: 2,
        ),
      ];
      final porObservador = agrupar(filas, cod: 12);
      expect(jefes(porObservador), ['Aguilar Cuenca Alvaro']);
      expect(porObservador.single.esObservador, isTrue);
      final porEncargado = agrupar(filas, cod: 7);
      expect(jefes(porEncargado), ['Aguilar Cuenca Alvaro', null]);
    });

    test('filtrar por un encargado sin jefe o por quien no está', () {
      final g = agrupar(datos, cod: 11);
      expect(g.single.sinJefe, isTrue);
      expect(nombres(g.single), ['Mendoza Cruz Pedro']);
      expect(agrupar(datos, cod: 99), isEmpty);
    });
  });
}
