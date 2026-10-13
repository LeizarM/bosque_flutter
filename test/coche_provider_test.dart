import 'package:bosque_flutter/core/state/coche_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_coches.dart';

/// El catálogo de vehículos: la carga, las escrituras y los filtros del
/// listado, con un repositorio falso. Los filtros son un valor puro y se
/// ejercitan sin Riverpod.
void main() {
  late RepositorioCochesFalso repo;
  late ProviderContainer contenedor;

  setUp(() {
    repo = RepositorioCochesFalso();
    contenedor = ProviderContainer(
      overrides: [cocheRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(contenedor.dispose);
    // El provider es autoDispose: sin un oyente se libera entre una lectura y
    // la siguiente y la prueba perdería el estado.
    contenedor.listen(cocheProvider, (_, __) {});
  });

  group('carga', () {
    test('trae el listado y marca que ya hubo respuesta', () async {
      final notifier = contenedor.read(cocheProvider.notifier);
      await notifier.cargar();

      final estado = contenedor.read(cocheProvider);
      expect(estado.items, hasLength(7));
      expect(estado.cargado, isTrue);
      expect(estado.cargando, isFalse);
      expect(estado.error, isNull);
    });

    test('un fallo en la primera lectura queda en error, sin respuesta', () async {
      // Contenedor propio: el del `setUp` ya hizo su primera lectura sana.
      final falla =
          RepositorioCochesFalso()
            ..falloAlObtener = Exception('Sin conexión con el servidor.');
      final propio = ProviderContainer(
        overrides: [cocheRepositoryProvider.overrideWithValue(falla)],
      );
      addTearDown(propio.dispose);
      propio.listen(cocheProvider, (_, __) {});

      final notifier = propio.read(cocheProvider.notifier);
      await notifier.cargar();

      var estado = propio.read(cocheProvider);
      expect(estado.error, isNotNull);
      expect(estado.cargado, isFalse, reason: 'la pantalla muestra «reintentar»');
      expect(estado.items, isEmpty);

      // Reintentar con el servidor ya sano limpia el error.
      falla.falloAlObtener = null;
      await notifier.cargar();
      estado = propio.read(cocheProvider);
      expect(estado.error, isNull);
      expect(estado.cargado, isTrue);
      expect(estado.items, hasLength(7));
    });

    test('una recarga fallida deja los datos que ya había', () async {
      final notifier = contenedor.read(cocheProvider.notifier);
      await notifier.cargar();

      repo.falloAlObtener = Exception('Sin conexión con el servidor.');
      await notifier.cargar();

      final estado = contenedor.read(cocheProvider);
      expect(estado.items, hasLength(7), reason: 'no se pierde la lista');
      expect(estado.cargado, isTrue);
      expect(estado.error, isNotNull);
    });
  });

  group('escritura', () {
    test('un alta viaja con idCoche 0 y el listado se recarga', () async {
      final notifier = contenedor.read(cocheProvider.notifier);
      await notifier.cargar();

      await notifier.guardar(
        cocheFalso(0, placa: '5555-NEW', marca: 'Foton', sucursal: 23),
      );

      expect(repo.registrados.single.idCoche, 0);
      final items = contenedor.read(cocheProvider).items;
      expect(items, hasLength(8));
      expect(items.any((c) => c.placa == '5555-NEW'), isTrue);
    });

    test('el rechazo del servidor sale tal cual y no recarga', () async {
      final notifier = contenedor.read(cocheProvider.notifier);
      await notifier.cargar();
      final lecturasAntes = repo.lecturas;

      repo.falloAlRegistrar = Exception('Ya existe un vehículo con esa placa.');

      await expectLater(
        notifier.guardar(cocheFalso(0, placa: '917-SKP')),
        throwsA(
          predicate((e) => e.toString().contains('Ya existe un vehículo')),
        ),
      );
      expect(repo.lecturas, lecturasAntes, reason: 'no se recarga si falló');
      expect(contenedor.read(cocheProvider).items, hasLength(7));
    });

    test('eliminar quita la fila; si el servidor rechaza, lanza', () async {
      final notifier = contenedor.read(cocheProvider.notifier);
      await notifier.cargar();

      await notifier.eliminar(7, 34);
      expect(repo.eliminados, [7]);
      expect(contenedor.read(cocheProvider).items, hasLength(6));

      repo.falloAlEliminar = Exception(
        'No se puede eliminar: el vehículo tiene kilometraje registrado.',
      );
      await expectLater(notifier.eliminar(1, 34), throwsA(isA<Exception>()));
      expect(contenedor.read(cocheProvider).items, hasLength(6));
    });
  });

  group('filtros', () {
    final todos = cochesDeEjemplo();

    List<String?> placas(FiltroCoches f) =>
        f.aplicar(todos).map((c) => c.placa).toList();

    test('sin criterios devuelve todos, ordenados por placa', () {
      final r = placas(const FiltroCoches());
      expect(r, hasLength(7));
      expect(r.first, '1053-FKE');
      expect(r.last, '917-SKP');
    });

    test('el texto busca en placa, marca, clase, color y sucursal', () {
      expect(placas(const FiltroCoches(texto: 'ytp')), ['2456-YTP']);
      expect(placas(const FiltroCoches(texto: 'foton')), ['3878-KCK']);
      expect(placas(const FiltroCoches(texto: 'minibus')), [
        '2456-YTP',
        '4744-CEI',
        '4829-RZI',
      ], reason: 'la clase, ordenada por placa');
      expect(placas(const FiltroCoches(texto: 'rojo')), ['1053-FKE']);
      expect(placas(const FiltroCoches(texto: 'cochabamba')), ['4744-CEI']);
    });

    test('con varias palabras cada una tiene que aparecer', () {
      expect(
        placas(const FiltroCoches(texto: 'suzuki santa')),
        ['2456-YTP'],
        reason: 'Suzuki de Santa Cruz: ni los demás Suzuki ni los Nissan',
      );
      expect(placas(const FiltroCoches(texto: 'suzuki  toyota')), isEmpty);
    });

    test('«activo» no trae a los inactivos escribiéndolo en el buscador', () {
      // El estado tiene su propio control: «activo» está dentro de «inactivo».
      expect(placas(const FiltroCoches(texto: 'activo')), isEmpty);
    });

    test('estado: activos, inactivos y todos', () {
      expect(
        FiltroCoches(estado: EstadoFiltroCoche.inactivos).aplicar(todos),
        hasLength(1),
      );
      expect(
        FiltroCoches(estado: EstadoFiltroCoche.activos).aplicar(todos),
        hasLength(6),
      );
      expect(const FiltroCoches().aplicar(todos), hasLength(7));
    });

    test('sucursal y estado se combinan', () {
      final f = FiltroCoches(
        codSucursal: 20,
        estado: EstadoFiltroCoche.activos,
      );
      // Sucursal 20 en el ejemplo: 2313-ZZD, 3878-KCK y el inactivo 1053-FKE.
      expect(f.aplicar(todos).map((c) => c.placa), ['2313-ZZD', '3878-KCK']);
    });

    test('cuenta criterios sin contar el buscador', () {
      expect(const FiltroCoches().criterios, 0);
      expect(const FiltroCoches(texto: 'x').criterios, 0);
      expect(const FiltroCoches(texto: 'x').hayAlgo, isTrue);
      expect(const FiltroCoches().hayAlgo, isFalse);
      expect(
        FiltroCoches(
          codSucursal: 20,
          estado: EstadoFiltroCoche.inactivos,
        ).criterios,
        2,
      );
    });

    test('limpiarSucursal quita el criterio de sucursal', () {
      final f = FiltroCoches(codSucursal: 20).copyWith(limpiarSucursal: true);
      expect(f.codSucursal, isNull);
    });
  });

  group('sucursales para los combos', () {
    test('suma las que usan los coches y el catálogo no trae', () {
      final opciones = opcionesDeSucursal(
        catalogo: [sucursalFalsa(20, 'CENTRAL ')],
        coches: [
          cocheFalso(1, sucursal: 20, nombreSucursal: 'CENTRAL'),
          cocheFalso(2, sucursal: 21, nombreSucursal: 'SUCURSAL AMERICA'),
          cocheFalso(3, sucursal: 99, nombreSucursal: ''),
        ],
      );

      expect(opciones.map((o) => o.codSucursal), [20, 99, 21]);
      expect(opciones.first.nombre, 'CENTRAL', reason: 'sin el espacio final');
      expect(opciones[1].nombre, 'Sucursal 99', reason: 'sin nombre: el código');
    });

    test('descarta la fila de relleno «Defina Nueva Sucursal» (código -1)', () {
      final opciones = opcionesDeSucursal(
        catalogo: [
          sucursalFalsa(-1, '-- Defina Nueva Sucursal --'),
          sucursalFalsa(0, 'SIN CODIGO'),
          sucursalFalsa(20, 'CENTRAL'),
        ],
      );

      expect(opciones.map((o) => o.codSucursal), [20]);
      expect(opciones.map((o) => o.nombre), ['CENTRAL']);
    });

    test('sin catálogo (aún no llegó) arma las opciones de los coches', () {
      final opciones = opcionesDeSucursal(
        catalogo: null,
        coches: cochesDeEjemplo(),
      );
      expect(opciones.map((o) => o.nombre), [
        'CENTRAL',
        'COCHABAMBA',
        'GALPON EL ALTO',
        'SANTA CRUZ',
      ]);
    });
  });
}
