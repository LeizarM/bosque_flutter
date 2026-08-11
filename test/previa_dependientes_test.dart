import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fakes/repositorio_previa.dart';

/// Qué llega al backend cuando se previsualiza un permiso.
///
/// **Por qué esto merece un test.** `codSucursal` cambió de significado a mitad
/// de camino: cuando el 0 quería decir «no sé cuál es su sucursal», el provider
/// cortaba antes de salir a la red y devolvía lista vacía. Desde que el 0
/// significa **todas las sucursales**, ese mismo corte dejaba a la opción
/// «Todas» mostrando «el organigrama no le da NINGÚN dependiente» — lo contrario
/// exacto de la verdad, y sin una sola petición en la pestaña de red.
///
/// Ese es el tipo de bug que no falla, no tira excepción y no aparece en el
/// análisis estático: sólo miente. Lo único que lo agarra es afirmar qué se
/// pidió y con qué argumentos.
void main() {
  ProviderContainer contenedor(RepositorioPrevia fake) => ProviderContainer(
    overrides: [rolSabadosRepositoryProvider.overrideWithValue(fake)],
  );

  test('codSucursal 0 significa TODAS y SÍ sale al backend', () async {
    final fake = RepositorioPrevia();
    final c = contenedor(fake);
    addTearDown(c.dispose);

    final r = await c.read(
      previaDependientesProvider((
        codEmpleado: 65,
        codSucursal: 0, // «Todas»
        alcance: 'SUBARBOL',
        idRol: 1,
      )).future,
    );

    expect(fake.llamadas, hasLength(1), reason: 'tiene que pedirlo, no cortar');
    expect(fake.llamadas.single.codSucursal, 0);
    expect(fake.llamadas.single.alcance, 'SUBARBOL');
    expect(r, isNotEmpty);
  });

  test('una sucursal concreta también sale, con su número', () async {
    final fake = RepositorioPrevia();
    final c = contenedor(fake);
    addTearDown(c.dispose);

    await c.read(
      previaDependientesProvider((
        codEmpleado: 65,
        codSucursal: 20,
        alcance: 'DIRECTOS',
        idRol: 1,
      )).future,
    );

    expect(fake.llamadas.single.codSucursal, 20);
    expect(fake.llamadas.single.alcance, 'DIRECTOS');
  });

  test('sin persona elegida no se le pregunta nada al servidor', () async {
    final fake = RepositorioPrevia();
    final c = contenedor(fake);
    addTearDown(c.dispose);

    final r = await c.read(
      previaDependientesProvider((
        codEmpleado: 0,
        codSucursal: 20,
        alcance: 'DIRECTOS',
        idRol: 1,
      )).future,
    );

    expect(fake.llamadas, isEmpty);
    expect(r, isEmpty);
  });

  test('cambiar el alcance vuelve a preguntar', () async {
    final fake = RepositorioPrevia();
    final c = contenedor(fake);
    addTearDown(c.dispose);

    const base = (codEmpleado: 65, codSucursal: 0, idRol: 1);
    await c.read(
      previaDependientesProvider((
        codEmpleado: base.codEmpleado,
        codSucursal: base.codSucursal,
        alcance: 'DIRECTOS',
        idRol: base.idRol,
      )).future,
    );
    await c.read(
      previaDependientesProvider((
        codEmpleado: base.codEmpleado,
        codSucursal: base.codSucursal,
        alcance: 'SUBARBOL',
        idRol: base.idRol,
      )).future,
    );

    // Dos claves distintas, dos consultas: es lo que hace que tocar el
    // SegmentedButton actualice la lista sin que nadie invalide nada a mano.
    expect(fake.llamadas.map((l) => l.alcance), ['DIRECTOS', 'SUBARBOL']);
  });

  test('el nombre y el «fuera del rol» llegan hasta la entidad', () async {
    final fake = RepositorioPrevia();
    final c = contenedor(fake);
    addTearDown(c.dispose);

    final r = await c.read(
      previaDependientesProvider((
        codEmpleado: 65,
        codSucursal: 0,
        alcance: 'SUBARBOL',
        idRol: 1,
      )).future,
    );

    final fuera = r.where((d) => !d.participaDelRol).toList();
    expect(fuera, hasLength(1));
    expect(fuera.single.nombreDependiente, 'HOWARD ROGER');
    expect(
      r.firstWhere((ProgramadorDependienteEntity d) => d.esDirecto).sucursal,
      'CENTRAL',
    );
  });
}
