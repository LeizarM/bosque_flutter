import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quién puede escribir una celda.
///
/// **Por qué merece un test propio.** Esto decide si la app le ofrece a alguien
/// el editor de una celda ajena, y equivocarse tiene dos costos muy distintos:
/// de más, la app promete algo que el servidor rechaza; de menos, alguien no
/// puede hacer su trabajo y no entiende por qué. El servidor decide igual
/// —`p_abm_trs_Asignacion` corta con el error 29—, pero esta clase es la que
/// evita el camino de abrir la hoja, elegir una letra y recién ahí enterarse.
ProgramadorDependienteEntity _dep(int cod) => ProgramadorDependienteEntity(
  idProgramador: 1,
  codProgramador: 65,
  profundidad: 1,
  codDependiente: cod,
  nombreDependiente: 'PERSONA $cod',
  sucDependiente: 20,
);

void main() {
  group('quién puede escribir una celda', () {
    test('RR.HH. y los admin pueden con cualquiera', () {
      const todo = PermisoDeCelda(todas: true, miGente: {});
      expect(todo.puedeCon(1), isTrue);
      expect(todo.puedeCon(99999), isTrue);
    });

    test('un jefe, sólo con su gente', () {
      final jefe = PermisoDeCelda(
        todas: false,
        miGente: MiEquipoEntity(
          esProgramador: 1,
          equipo: [_dep(223), _dep(245)],
        ).codigosDeMiGente,
      );
      expect(jefe.puedeCon(223), isTrue);
      expect(jefe.puedeCon(245), isTrue);
      // El de al lado en la grilla, que no es suyo.
      expect(jefe.puedeCon(54), isFalse);
      // Y tampoco con él mismo: el organigrama nunca se devuelve a sí mismo.
      expect(jefe.puedeCon(65), isFalse);
    });

    test('un usuario común no puede con nadie, ni consigo mismo', () {
      const nadie = PermisoDeCelda.nadie;
      expect(nadie.puedeCon(1), isFalse);
      expect(nadie.puedeCon(0), isFalse);
    });

    test('ser programador NO alcanza si el equipo llegó vacío', () {
      // Pasa de verdad: el permiso existe pero el organigrama no le cuelga a
      // nadie. Si esto devolviera true, la app le abriría el editor de toda la
      // grilla a alguien que el servidor va a rechazar en cada celda.
      final sinGente = PermisoDeCelda(
        todas: false,
        miGente: const MiEquipoEntity(esProgramador: 1).codigosDeMiGente,
      );
      expect(sinGente.puedeCon(223), isFalse);
    });

    test('esRrhh abre todo sin necesidad de ser programador', () {
      const soloRrhh = MiEquipoEntity(esRrhh: 1);
      expect(soloRrhh.soyRrhh, isTrue);
      expect(soloRrhh.puedoProgramar, isFalse);

      final permiso = PermisoDeCelda(
        todas: soloRrhh.soyRrhh,
        miGente: soloRrhh.codigosDeMiGente,
      );
      expect(permiso.puedeCon(54), isTrue);
    });
  });
}
