import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/desglose_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo único que puede fallar en `PermisosRrhhAcciones` es el refresco, y falla
/// callado: la fila nueva aparece en la grilla, el saldo de arriba sigue siendo
/// el de antes, y el que mira concluye que no se guardó y lo carga otra vez. En
/// una tabla donde una fila vale 15 a 30 días pagados, eso es plata.
///
/// Además el SP de escritura **no devuelve el id generado**, así que releer no
/// es una mejora: es la única forma de saber qué quedó. Y un proceso automático
/// escribe en la misma tabla el día 1 de cada mes, así que ni siquiera alcanza
/// con retocar el estado local.
void main() {
  ProviderContainer contenedor(_RepoContador repo) {
    final c = ProviderContainer(
      overrides: [permisosRrhhRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('una escritura obliga a releer la ficha y el desglose del empleado', () async {
    final repo = _RepoContador();
    final c = contenedor(repo);

    // Los providers son `autoDispose`: sin alguien escuchando se apagan solos y
    // la invalidación no probaría nada. Esto es lo que hace la pantalla.
    c.listen(fichaSaldoProvider(130), (_, _) {});
    c.listen(desgloseSaldoProvider(130), (_, _) {});
    await c.read(fichaSaldoProvider(130).future);
    await c.read(desgloseSaldoProvider(130).future);
    expect(repo.fichas, 1);
    expect(repo.desgloses, 1);

    await c
        .read(permisosRrhhAccionesProvider)
        .registrarVacacionAsignada(_vacacion);

    await c.read(fichaSaldoProvider(130).future);
    await c.read(desgloseSaldoProvider(130).future);
    expect(repo.fichas, 2, reason: 'el saldo de arriba quedó viejo');
    expect(repo.desgloses, 2, reason: 'el desglose quedó viejo');
  });

  test('una carga colectiva refresca a todos, no al último tocado', () async {
    final repo = _RepoContador();
    final c = contenedor(repo);

    c.listen(fichaSaldoProvider(130), (_, _) {});
    c.listen(fichaSaldoProvider(48), (_, _) {});
    await c.read(fichaSaldoProvider(130).future);
    await c.read(fichaSaldoProvider(48).future);
    expect(repo.fichas, 2);

    await c
        .read(permisosRrhhAccionesProvider)
        .aplicarAbonoColectivo(
          codEmpleados: const [130, 48],
          dias: 1,
          motivo: 'Inventario',
          fecha: DateTime(2026, 8, 12),
        );

    await c.read(fichaSaldoProvider(130).future);
    await c.read(fichaSaldoProvider(48).future);
    expect(repo.fichas, 4, reason: 'los N tocados no se enteraron');
  });

  test('el error del servidor sube: no se lo come la acción', () async {
    final repo = _RepoContador(falla: true);
    final c = contenedor(repo);

    expect(
      () => c
          .read(permisosRrhhAccionesProvider)
          .registrarVacacionAsignada(_vacacion),
      throwsA(isA<Exception>()),
    );
  });
}

const _vacacion = VacacionAsignadaEntity(
  codVacacionAsignada: 0,
  codEmpleado: 130,
  codRelEmplEmpr: 500,
  diasAsignados: 15,
  motivo: 'Aniversario 2026',
);

/// Cuenta cuántas veces le preguntaron. Lo que se mide es el refresco, no el
/// dato: el dato lo prueban los modelos.
class _RepoContador implements PermisosRrhhRepository {
  _RepoContador({this.falla = false});

  final bool falla;
  int fichas = 0;
  int desgloses = 0;

  @override
  Future<FichaSaldoEntity?> getFichaSaldo(int codEmpleado) async {
    fichas++;
    return null;
  }

  @override
  Future<DesgloseSaldoEntity?> getDesgloseSaldo(int codEmpleado) async {
    desgloses++;
    return null;
  }

  /// Devuelve **la fila releída**, que es lo que contesta el controller
  /// (`respuestaEscritura(fila, creado)`): un objeto, no un id.
  @override
  Future<VacacionAsignadaEntity> registrarVacacionAsignada(
    VacacionAsignadaEntity vacacion, {
    bool confirmado = false,
  }) async {
    if (falla) throw Exception('No se pudo registrar');
    return vacacion;
  }

  @override
  Future<String> aplicarAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  }) async => 'Se acreditaron días a ${codEmpleados.length} personas';

  /// El resto del contrato, que estas pruebas no tocan. Ver la nota del
  /// `_RepoFalso` de `permisos_rrhh_responsive_test.dart`.
  @override
  dynamic noSuchMethod(Invocation invocacion) => throw UnimplementedError(
    'El repositorio de prueba no implementa ${invocacion.memberName}',
  );
}
