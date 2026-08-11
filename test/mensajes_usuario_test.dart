import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los textos de entrada están copiados **literalmente** de los procedimientos
/// almacenados (`06_sp_abmList_trs.sql`, `02_sp_generarRol.sql`). Si mañana
/// alguien cambia un mensaje en SQL y acá deja de coincidir, este test lo
/// señala antes que un usuario.
///
/// **Lo que más se prueba acá es el envoltorio del `CATCH`.** Los `p_abm_`
/// devuelven `'Error al programar: ' + ERROR_MESSAGE() + ' | Linea: 991'` sin
/// mirar qué falló, así que por ese mismo caño salen las dos cosas: el error
/// del motor —que no es culpa de nadie que esté usando la app— y el rechazo
/// del negocio, que sí tiene que leerse entero. Los dos grupos de abajo son
/// las dos mitades de esa distinción, y van juntos a propósito: si alguien
/// vuelve a clasificar por el `| Linea:`, uno de los dos se cae.
void main() {
  group('errores de programación: no se muestran crudos', () {
    const tecnicos = [
      'El campo idParticipante es obligatorio.',
      'El campo idRol es obligatorio.',
      'ACCION no reconocida: use I, U o D.',
      'Error de conexión o sintaxis en la base de datos.',
    ];

    for (final t in tecnicos) {
      test('«$t»', () {
        final m = humanizar(t);
        expect(m.esFalloTecnico, isTrue);
        expect(m.texto, contains('Sistemas'));
        // Nada de nombres de columnas ni de líneas de código en pantalla.
        expect(m.texto, isNot(contains('idParticipante')));
        expect(m.texto, isNot(contains('Linea')));
        expect(m.texto, isNot(contains('ACCION')));
      });
    }
  });

  group('lo del motor sigue siendo técnico aunque venga envuelto', () {
    // El primero vivía en el grupo de arriba y pasaba por el motivo
    // equivocado: alcanzaba con que trajera un `| Linea:`. Sigue siendo
    // técnico, pero ahora por lo único que lo prueba de verdad — el texto de
    // adentro: claves duplicadas, sintaxis, tipos, restricciones. Eso lo
    // escribió SQL Server, no nosotros.
    const tecnicos = [
      'Error al insertar: Cannot insert duplicate key | Linea: 118',
      'Error al actualizar: Incorrect syntax near FROM | Linea: 992',
      'Error al aprobar: The DELETE statement conflicted with the REFERENCE '
          'constraint | Linea: 2432',
      // El envoltorio propio de los trs_sp_, adentro del envoltorio del p_abm_.
      'Error al programar: Err 8152 (linea 1030): String or binary data would '
          'be truncated | Linea: 1722',
    ];

    for (final t in tecnicos) {
      test('«${t.substring(0, 40)}…»', () {
        final m = humanizar(t);
        expect(m.esFalloTecnico, isTrue);
        expect(m.texto, contains('Sistemas'));
        expect(m.texto, isNot(contains('Linea')));
      });
    }

    test('un mensaje envuelto que nadie reconoce va al aviso corto', () {
      // Por el CATCH sólo pasan reglas conocidas y excepciones. Si el texto no
      // está en la tabla es una de dos: excepción, o mensaje nuevo del SQL que
      // el front todavía no conoce. Mostrarlo crudo sería mandarle a un jefe un
      // texto con número de línea; el original queda en el log.
      final m = humanizar(
        'Error al programar: Algo que este archivo todavia no conoce. '
        '| Linea: 991',
      );
      expect(m.esFalloTecnico, isTrue);
      expect(m.texto, isNot(contains('Linea')));
    });
  });

  group('los rechazos del negocio se leen aunque vengan envueltos', () {
    // ANTES ESTO NO PASABA: `| Linea:` alcanzaba para declararlo fallo técnico,
    // así que un jefe al que el organigrama le rebotaba una programación leía
    // «problema del sistema, avisá a Sistemas» y llamaba a la persona
    // equivocada. El envoltorio se pela antes de clasificar; el rechazo es el
    // mismo con o sin disfraz.
    final casos = <String, String>{
      'Error al programar: El empleado 54 no es dependiente del programador. '
          '| Linea: 991': 'a tu cargo',
      'Error al programar: El dependiente no es participante activo del rol. '
          '| Linea: 991': 'rol de este año',
      'Error al programar: Sabado inexistente. | Linea: 991':
          'ya no está en el rol',
      'Error al programar: Ese sabado ya paso; no se programa hacia atras. '
          '| Linea: 991': 'ya pasó',
      'Error al programar: Ese sabado esta desactivado (activo=0). '
          '| Linea: 991': 'desactivado',
      'Error al programar: Esa celda la hizo otro jefe. | Linea: 991':
          'otro jefe',
      'Error al programar: RR.HH. ya cargo una vacacion para esa persona ese '
          'dia; la celda no se pisa. | Linea: 991': 'RR.HH.',
      'Error al programar: Solo se puede marcar 1 (viene) o L (no viene). '
          '| Linea: 991': 'viene',
      'Error al programar: El empleado 65 no es programador activo ni '
          'reemplazo. | Linea: 991': 'programar a otros',
      // No es del circuito de Su Equipo, pero sale por el mismo caño: la
      // corrección de una celda también delega en un trs_sp_ adentro de un TRY.
      'Error al escribir la celda: El rol esta CERRADO; no admite '
          'correcciones. | Linea: 2038': 'cerrado',
    };

    casos.forEach((crudo, esperado) {
      test('«${crudo.substring(0, 45)}…»', () {
        final m = humanizar(crudo);
        expect(
          m.esFalloTecnico,
          isFalse,
          reason: 'Es una regla del negocio: el jefe tiene que poder leerla.',
        );
        expect(m.texto, contains(esperado));
        expect(m.texto, isNot(contains('Linea')));
        expect(m.texto, isNot(contains('Error al')));
      });
    });
  });

  group('reglas del negocio: se explican en castellano', () {
    final casos = <String, String>{
      'El rol esta CERRADO.': 'cerrado',
      'El rol esta CERRADO; no admite correcciones.': 'cerrado',
      'El empleado ya es participante de ese rol.': 'ya está en el rol',
      'El titular no es participante activo de ese rol.': 'ya no figura activa',
      'El reemplazo no puede ser el mismo titular.': 'otra persona',
      'El sabado no pertenece a ese rol.': 'no es de este rol',
      'El cambio ya esta APROBADO y sus celdas aplicadas; no se modifica.':
          'ya fue aprobado',
      'Una PERMUTA necesita idSabadoReposicion: es el sabado que se devuelve.':
          'sábado que se le devuelve',
      'Ya existe el rol 2026 para ese alcance.': 'Regenerar',
      'El empleado 65 no esta registrado como programador activo, asi que no '
          'se puede expandir su subarbol.': 'no tiene permiso para programar',
    };

    casos.forEach((crudo, esperado) {
      test('«$crudo»', () {
        final m = humanizar(crudo);
        expect(m.esFalloTecnico, isFalse);
        expect(m.texto, contains(esperado));
      });
    });
  });

  test('el aviso de "sin evento" dice qué hacer, no sólo qué falló', () {
    final m = humanizar(
      "Ese sabado no tiene evento. Declarelo primero con "
      "p_abm_trs_Sabado @ACCION='U'.",
    );
    expect(m.texto, contains('TOTAL'));
    expect(m.texto, contains('SELECTIVA'));
    expect(m.texto, isNot(contains('p_abm_')));
  });

  group('limpieza de lo que no está en la tabla', () {
    test('borra el nombre del procedimiento', () {
      final m = humanizar(
        'Participante agregado en el grupo A. Corra trs_sp_generarRol para '
        'generarle sus celdas.',
      );
      expect(m.texto, isNot(contains('trs_sp_')));
      expect(m.texto, contains('grupo A'));
    });

    test('borra el @ACCION suelto', () {
      final m = humanizar("Cambio registrado. Use @ACCION='A' para aprobarlo.");
      expect(m.texto, isNot(contains('ACCION')));
      expect(m.texto, contains('Cambio registrado'));
    });
  });

  group('problemas de red y de sesión', () {
    test('sin conexión', () {
      final m = humanizar('DioException: Connection timeout');
      expect(m.texto, contains('conectar con el servidor'));
    });

    test('sesión vencida', () {
      expect(humanizar('401 Unauthorized').texto, contains('sesión'));
    });

    test('sin permiso', () {
      final m = humanizar('403 Forbidden');
      expect(m.texto, contains('permiso'));
    });

    test('el código de un empleado no es un código HTTP', () {
      // Los mensajes del SQL nombran a la gente por su codEmpleado. Cuando el
      // 403 era cualquier «403» en el texto, al empleado 403 le contestaban
      // «no tenés permiso para hacer este cambio».
      final m = humanizar('El empleado 403 no es dependiente del programador.');
      expect(m.texto, contains('a tu cargo'));
      expect(m.texto, isNot(contains('No tenés permiso')));
    });

    test('la palabra "permisos" no convierte todo en un rechazo de acceso', () {
      // El módulo tiene una acción que se llama «refrescar permisos» y un
      // estado 'P' de permiso de RR.HH.: hablar de permisos acá es hablar de
      // vacaciones, no de accesos.
      final m = humanizar(
        'Permisos aplicados. Celdas marcadas: 12 | devueltas a trabajar: 3.',
      );
      expect(m.esFalloTecnico, isFalse);
      expect(m.texto, contains('Permisos aplicados'));
      expect(m.texto, isNot(contains('No tenés permiso')));
    });
  });

  group('bordes', () {
    test('saca el prefijo Exception que agrega Dart', () {
      final m = humanizar('Exception: El rol esta CERRADO.');
      expect(m.texto, isNot(contains('Exception')));
    });

    test('un mensaje vacío no deja la pantalla muda', () {
      expect(humanizar('').texto, isNotEmpty);
      expect(humanizar(null).texto, isNotEmpty);
    });

    test('un mensaje de éxito común pasa entero', () {
      final m = humanizar('Celda corregida a V con origen M.');
      expect(m.esFalloTecnico, isFalse);
      expect(m.texto, contains('Celda corregida'));
    });
  });
}
