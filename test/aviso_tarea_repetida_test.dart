// El aviso al crear una tarea que ya existe o que se parece a una que existe.
//
// 2026-09-10: Marcelo pidió el selector del catálogo para no duplicar, y
// después el aviso para el caso que el selector no cubre: escribir a mano un
// nombre que ya existe. Así llegó el catálogo real a tener 7 descripciones
// repetidas, entre ellas "Arqueo de Caja" dos veces.
//
// 2026-09-11: "solo funciona si es exacto, ¿qué pasa si alguien anota 'Arqueo
// Caja' o 'Caja Arqueo' o 'Arqueo Cajah'? Es lo mismo, pero no lo es al mismo
// tiempo".
import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/core/utils/nombres_parecidos.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/tarea_rutinaria_repository.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/crear_tarea_por_cargo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoFalso implements TareaRutinariaRepository {
  _RepoFalso(this.catalogo);

  final List<TareaRutinariaEntity> catalogo;

  @override
  Future<List<TareaRutinariaEntity>> obtener() async => catalogo;

  @override
  Future<BigInt> registrar(TareaRutinariaEntity item) =>
      throw UnimplementedError('Este test no guarda tareas.');

  @override
  Future<void> eliminar(int idTarRuti, int audUsuario) =>
      throw UnimplementedError('Este test no elimina tareas.');
}

TareaRutinariaEntity _tarea(int id, String descripcion, {int idFrec = 6}) =>
    TareaRutinariaEntity(
      idTarRuti: id,
      descripcion: descripcion,
      idFrec: idFrec,
      audUsuario: 34,
    );

/// Filas con el texto tal como está en BOSQUE2PRUEBA.
final _catalogo = [
  _tarea(1, 'Arqueo de Caja'),
  _tarea(38, 'Arqueo de Caja', idFrec: 1),
  _tarea(3, 'Verficar Arqueo de Caja'),
  // Con doble espacio, como está escrita de verdad en la base.
  _tarea(101, 'Realizar  los  registros  de  importaciones'),
  _tarea(40, 'Caja Fuerte'),
  _tarea(42, 'Caja Chica'),
  // El molde de Sistemas: las tareas son iguales salvo por el servicio.
  _tarea(
    216,
    'Administrar el firewall velando por su correcto funcionamiento en todo momento.',
  ),
  _tarea(
    218,
    'Administrar el NAT, velando por su correcto funcionamiento en todo momento.',
  ),
  _tarea(
    220,
    'Administrar el Tomcat, velando por su correcto funcionamiento en todo momento.',
  ),
];

List<TareaParecida> _buscar(String texto) =>
    CatalogoComparable(_catalogo).parecidasA(texto);

List<int> _ids(List<TareaParecida> r, NivelParecido nivel) => [
  for (final p in r)
    if (p.nivel == nivel) p.tarea.idTarRuti,
];

void main() {
  // La hoja crea su repositorio al construirse y eso lee `AppConstants.baseUrl`
  // -> `dotenv.env`, que lanza si nadie cargó el archivo. Mismo arranque que
  // vigencia_asignacion_test.dart.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('igual', () {
    test('un nombre nuevo no dispara nada', () {
      expect(_buscar('Revisar el generador'), isEmpty);
    });

    test('un nombre que ya existe devuelve las dos que lo usan', () {
      expect(_ids(_buscar('Arqueo de Caja'), NivelParecido.igual), [1, 38]);
    });

    test('no importan mayúsculas, tildes, signos ni espacios de los bordes', () {
      expect(_ids(_buscar('ARQUEO DE CAJA'), NivelParecido.igual), [1, 38]);
      expect(_ids(_buscar('Árqueo de Caja.'), NivelParecido.igual), [1, 38]);
      expect(_ids(_buscar('  Caja Fuerte  '), NivelParecido.igual), [40]);
    });

    test('tampoco los espacios de adentro', () {
      // Este es el que se escapa de una comparación literal: la fila real
      // está guardada con doble espacio, y nadie la va a tipear así.
      expect(
        _ids(
          _buscar('Realizar los registros de importaciones'),
          NivelParecido.igual,
        ),
        [101],
      );
    });

    test('un campo vacío no avisa', () {
      expect(_buscar(''), isEmpty);
      expect(_buscar('   '), isEmpty);
    });
  });

  group('parecido: lo que preguntó Marcelo', () {
    for (final escrito in ['Arqueo Caja', 'Caja Arqueo', 'Arqueo Cajah']) {
      test('"$escrito" avisa por las dos "Arqueo de Caja"', () {
        final r = _buscar(escrito);
        expect(_ids(r, NivelParecido.parecido), containsAll([1, 38]));
        expect(
          _ids(r, NivelParecido.igual),
          isEmpty,
          reason:
              'No es el mismo texto: se avisa como parecida, para que se lea '
              'y se decida, no como repetida.',
        );
      });
    }

    test('encuentra la del catálogo que está mal escrita', () {
      expect(
        _ids(_buscar('Verificar arqueo de caja'), NivelParecido.parecido),
        contains(3),
      );
    });

    test('las iguales van primero', () {
      final r = _buscar('Arqueo de Caja');
      expect(r.first.nivel, NivelParecido.igual);
    });
  });

  group('cuándo NO avisa', () {
    test('una palabra suelta no alcanza', () {
      // Si avisara por cualquier coincidencia, "Arqueo" saltaría todo el
      // tiempo y el aviso se volvería ruido que nadie lee.
      expect(_buscar('Arqueo'), isEmpty);
    });

    test('otra tarea que comparte palabras no es parecida', () {
      expect(
        _buscar('Arqueo de Caja Chica').map((p) => p.tarea.idTarRuti),
        isNot(contains(1)),
      );
      expect(
        _buscar('Caja Chica').map((p) => p.tarea.idTarRuti),
        isNot(contains(40)),
      );
    });

    test('en el molde de Sistemas, cambiar el servicio es otra tarea', () {
      // Comparten 6 de 7 palabras y la distinta es la única que importa. Sin
      // pesar las palabras por lo que distinguen, este aviso salía siempre.
      expect(
        _buscar(
          'Administrar el Apache, velando por su correcto funcionamiento en '
          'todo momento.',
        ),
        isEmpty,
      );
    });
  });

  group('las palabras', () {
    test('un error de tipeo o una letra invertida es la misma palabra', () {
      expect(mismaPalabra('caja', 'cajah'), isTrue);
      expect(mismaPalabra('arqueo', 'arqeuo'), isTrue);
      expect(mismaPalabra('sucursal', 'sucursales'), isTrue);
      expect(mismaPalabra('verificar', 'verificacion'), isTrue);
    });

    test('las cortas y los números tienen que ser idénticos', () {
      expect(mismaPalabra('mes', 'mas'), isFalse);
      expect(mismaPalabra('2025', '2026'), isFalse);
    });

    test('la clave queda sin mayúsculas, tildes ni signos', () {
      expect(claveDeNombre('  Arqueo   DE  Caja. '), 'arqueo de caja');
      expect(claveDeNombre('Caja\nFuerte'), 'caja fuerte');
      expect(claveDeNombre('Gestión, año'), 'gestion año');
    });
  });

  testWidgets('el aviso aparece mientras se escribe y dice cuáles son', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tareaRutinariaProvider.overrideWith(
            (ref) => TareaRutinariaNotifier(_RepoFalso(_catalogo)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CrearTareaPorCargoSheet(codCargos: const [7]),
            ),
          ),
        ),
      ),
    );
    // pumpAndSettle y no pump: la hoja pide las frecuencias al backend, y sin
    // backend el cliente deja un timer vivo (ver vigencia_asignacion_test).
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Caja Arqueo');
    await tester.pump();

    expect(find.text('Hay 2 tareas con nombres parecidos'), findsOneWidget);
    expect(find.textContaining('· Arqueo de Caja ·'), findsNWidgets(2));
  });
}
