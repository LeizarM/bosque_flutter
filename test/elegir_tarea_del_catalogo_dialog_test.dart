// El diálogo "Agregar tarea existente" con un catálogo del tamaño real.
//
// Marcelo (2026-09-10), con una captura del cargo JEFE DE SISTEMAS Y
// OPERACIONES: "en esta vista al scrollear hacia abajo, se colgó y/o congeló,
// optimiza bien eso".
//
// Lo que había: las ~300 filas del catálogo se armaban todas en cada
// reconstrucción, y al fondo estaban las 19 asignaciones inactivas del cargo
// 144 como filas deshabilitadas que no respondían al clic, con la línea que lo
// explicaba ya fuera de la vista.
import 'dart:async';

import 'package:bosque_flutter/core/state/tarea_rutinaria_provider.dart';
import 'package:bosque_flutter/domain/entities/tarea_rutinaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/tarea_rutinaria_repository.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/elegir_tarea_del_catalogo_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoFalso implements TareaRutinariaRepository {
  _RepoFalso(this.catalogo, {this.falla = false});

  final List<TareaRutinariaEntity> catalogo;
  bool falla;
  int pedidos = 0;

  @override
  Future<List<TareaRutinariaEntity>> obtener() async {
    pedidos++;
    if (falla) throw Exception('sin conexión');
    return catalogo;
  }

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

/// 292 tareas, como el catálogo de BOSQUE2PRUEBA, con el formato que trae del
/// sistema anterior: dos espacios entre palabras y un salto de línea.
final _catalogo = [
  for (var n = 1; n <= 292; n++)
    _tarea(n, 'Tarea ${n.toString().padLeft(3, '0')}  del  catálogo\r\nde prueba'),
];

String _texto(int id) => textoDeTarea(_catalogo[id - 1].descripcion);

/// Las 19 inactivas del cargo 144 (idTarRuti 239 a 257) y dos activas.
final _asignacionesCargo144 = <int, bool>{
  1: true,
  289: true,
  for (var id = 239; id <= 257; id++) id: false,
};

Future<_RepoFalso> _abrir(
  WidgetTester tester, {
  Map<int, bool>? yaAsignadas,
  List<TareaRutinariaEntity>? catalogo,
  Future<bool> Function(int)? onReactivar,
  void Function(List<int>, DateTime)? onElegidas,
  bool falla = false,
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repo = _RepoFalso(catalogo ?? _catalogo, falla: falla);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tareaRutinariaProvider.overrideWith(
          (ref) => TareaRutinariaNotifier(repo),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: FilledButton(
                    onPressed:
                        () => showDialog<void>(
                          context: context,
                          builder:
                              (_) => ElegirTareaDelCatalogoDialog(
                                yaAsignadas:
                                    yaAsignadas ?? _asignacionesCargo144,
                                nombreCargo: 'JEFE DE SISTEMAS Y OPERACIONES',
                                onElegidas: onElegidas ?? (_, __) {},
                                onReactivar: onReactivar,
                              ),
                        ),
                    child: const Text('abrir'),
                  ),
                ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pump(); // abre el diálogo y crea el provider
  await tester.pump(); // corre la carga
  await tester.pump(const Duration(milliseconds: 300)); // termina la animación
  return repo;
}

Finder get _lista => find.descendant(
  of: find.byType(ListView),
  matching: find.byType(Scrollable),
);

void main() {
  group('el texto del catálogo', () {
    test('se muestra con los espacios y saltos colapsados', () {
      expect(
        textoDeTarea('  Aplicar  o  supervisar\r\nla aplicación\t '),
        'Aplicar o supervisar la aplicación',
      );
    });

    test('se busca sin mayúsculas ni tildes', () {
      expect(
        claveDeBusqueda('Administrar el CORREO  electrónico'),
        'administrar el correo electronico',
      );
    });

    test('una búsqueda sin tildes y con un espacio encuentra el texto '
        'con tildes y dos espacios', () {
      final r = separarCatalogo(
        catalogo: [
          _tarea(243, 'Administrar el correo electrónico  que maneja la empresa'),
          _tarea(40, 'Caja Fuerte'),
        ],
        yaAsignadas: const {},
        busqueda: 'correo electronico que',
      );
      expect(r.disponibles.map((t) => t.idTarRuti), [243]);
    });

    test('encuentra la tarea con las palabras en otro orden o con un error '
        'de tipeo', () {
      // Marcelo (2026-09-11): "¿qué pasa si alguien anota 'Arqueo Caja' o
      // 'Caja Arqueo' o 'Arqueo Cajah'?". Si el buscador no la encuentra,
      // quien la busca termina creándola de nuevo.
      final catalogo = [
        _tarea(1, 'Arqueo de Caja'),
        _tarea(40, 'Caja Fuerte'),
        _tarea(42, 'Caja Chica'),
      ];
      for (final busqueda in ['Arqueo Caja', 'caja arqueo', 'Arqueo Cajah']) {
        final r = separarCatalogo(
          catalogo: catalogo,
          yaAsignadas: const {},
          busqueda: busqueda,
        );
        expect(r.disponibles.map((t) => t.idTarRuti), [1], reason: busqueda);
      }
      // Y lo de siempre sigue igual: un pedazo de texto encuentra todas.
      expect(
        separarCatalogo(
          catalogo: catalogo,
          yaAsignadas: const {},
          busqueda: 'caja',
        ).disponibles.length,
        3,
      );
    });

    test('ordena sin mirar mayúsculas ni tildes, y a igual texto por id', () {
      final r = separarCatalogo(
        catalogo: [
          _tarea(9, 'zeta'),
          _tarea(38, 'Arqueo de Caja'),
          _tarea(5, 'Área de caja'),
          _tarea(1, 'Arqueo de Caja'),
          _tarea(7, 'bajo'),
        ],
        yaAsignadas: const {},
      );
      // Por código de carácter "Área" y las minúsculas iban después de "Z".
      expect(r.disponibles.map((t) => t.idTarRuti), [5, 1, 38, 7, 9]);
    });
  });

  group('el diálogo con 292 tareas', () {
    testWidgets('no construye todas las filas', (tester) async {
      await _abrir(tester);
      // Una lista perezosa solo tiene las filas visibles y las de su margen.
      // Si alguien la envuelve en algo que la obligue a medirse entera
      // (shrinkWrap, una Column con scroll), aquí aparecen las 271.
      expect(
        find.byType(Checkbox, skipOffstage: false).evaluate().length,
        lessThan(60),
      );
    });

    testWidgets('al fondo hay una tarea que se puede elegir, no una fila '
        'muerta', (tester) async {
      await _abrir(tester);
      final ultima = find.text(_texto(292));
      await tester.scrollUntilVisible(ultima, 400, scrollable: _lista);
      await tester.tap(ultima);
      await tester.pump();
      expect(find.text('Agregar 1'), findsOneWidget);
    });

    testWidgets('las inactivas van arriba, plegadas y con cuántas son', (
      tester,
    ) async {
      await _abrir(tester, onReactivar: (_) async => true);
      expect(
        find.text('19 tareas de este cargo están inactivas'),
        findsOneWidget,
      );
      expect(find.text(_texto(239)), findsNothing);

      await tester.tap(find.text('19 tareas de este cargo están inactivas'));
      await tester.pump();
      expect(find.text(_texto(239)), findsOneWidget);
      expect(find.text('Reactivar'), findsWidgets);
    });

    testWidgets('se reactiva sin salir del diálogo y la tarea sale de la '
        'lista', (tester) async {
      final pedido = Completer<bool>();
      final reactivadas = <int>[];
      await _abrir(
        tester,
        onReactivar: (id) {
          reactivadas.add(id);
          return pedido.future;
        },
      );
      await tester.tap(find.text('19 tareas de este cargo están inactivas'));
      await tester.pump();

      await tester.tap(find.text('Reactivar').first);
      await tester.pump();
      expect(reactivadas, [239]);
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Mientras el servidor contesta, la fila lo muestra.',
      );

      pedido.complete(true);
      await tester.pump();
      expect(
        find.text('18 tareas de este cargo están inactivas'),
        findsOneWidget,
      );
      expect(find.text(_texto(239)), findsNothing);
      expect(find.text('Reactivada: ${_texto(239)}'), findsOneWidget);
    });

    testWidgets('si no se pudo reactivar, la fila queda y lo dice', (
      tester,
    ) async {
      await _abrir(tester, onReactivar: (_) async => false);
      await tester.tap(find.text('19 tareas de este cargo están inactivas'));
      await tester.pump();

      await tester.tap(find.text('Reactivar').first);
      await tester.pump();
      await tester.pump();
      expect(
        find.text('No se pudo reactivar. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(
        find.text('19 tareas de este cargo están inactivas'),
        findsOneWidget,
      );
    });

    testWidgets('la búsqueda espera a que dejes de escribir', (tester) async {
      await _abrir(tester);
      expect(find.text(_texto(2)), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'tarea 150');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text(_texto(2)),
        findsOneWidget,
        reason: 'A los 100 ms todavía no se filtró.',
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_texto(2)), findsNothing);
      expect(find.text(_texto(150)), findsOneWidget);
    });

    testWidgets('con búsqueda, las inactivas que coinciden se ven sin '
        'desplegar', (tester) async {
      await _abrir(tester);
      await tester.enterText(find.byType(TextField), 'tarea 245');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_texto(245)), findsOneWidget);
      expect(find.text('Reactivar'), findsNothing,
          reason: 'Sin onReactivar no hay botón, pero la fila se ve.');
    });
  });

  testWidgets('una falla al cargar no se confunde con "el cargo ya tiene '
      'todo"', (tester) async {
    final repo = await _abrir(tester, falla: true);
    expect(find.text('No se pudo cargar el catálogo de tareas.'), findsOneWidget);
    expect(
      find.text('Este cargo ya tiene todas las tareas del catálogo.'),
      findsNothing,
    );

    repo.falla = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();
    expect(find.text(_texto(1)), findsNothing, reason: 'La 1 está activa.');
    expect(find.text(_texto(2)), findsOneWidget);
    expect(repo.pedidos, 2);
  });
}
