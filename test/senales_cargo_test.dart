// Cargos por revisar (archivo SQL 82).
//
// Lo que estas pruebas cuidan (Marcelo, 2026-10-07):
// - Qué es una señal y su motivo lo decide el servidor; la app agrupa por
//   persona y pone primero a quien no hace ninguna de sus tareas.
// - "Está bien así" muestra el mensaje del servidor; si no lo acepta, su
//   texto vuelve al diálogo.
import 'package:bosque_flutter/core/state/senales_cargo_provider.dart';
import 'package:bosque_flutter/data/models/senal_cargo_model.dart';
import 'package:bosque_flutter/domain/entities/senal_cargo_entity.dart';
import 'package:bosque_flutter/domain/repositories/senal_cargo_repository.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/cargos_por_revisar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements SenalCargoRepository {
  List<SenalCargo> filas;
  String? rechazo;
  final pedidos = <String>[];

  _Repo(this.filas);

  @override
  Future<List<SenalCargo>> lista({bool verCalladas = false}) async {
    pedidos.add('lista verCalladas=$verCalladas');
    return filas;
  }

  @override
  Future<List<SenalCargo>> deMiEquipo() async {
    pedidos.add('equipo');
    return filas;
  }

  @override
  Future<String> estaBien(SenalCargo senal, {String? obs}) async {
    if (rechazo != null) throw rechazo!;
    pedidos.add('estaBien ${senal.clave} obs=$obs');
    filas = filas.where((s) => s.clave != senal.clave).toList();
    return 'Listo: no se vuelve a mostrar hasta el 06/11/2026.';
  }

  @override
  Future<String> volverAMostrar(SenalCargo senal) async =>
      'La señal vuelve a mostrarse.';
}

SenalCargo _s(
  int emp,
  String persona,
  int tarea, {
  int deSusTareas = 5,
  int? idSC,
}) => SenalCargo(
  codEmpleado: emp,
  persona: persona,
  cargo: 'RESPONSABLE DE ALMACEN',
  nombreSucursal: 'ACHOCALLA',
  idTarRuti: tarea,
  tarea: 'Tarea $tarea',
  ocurrencias: 10,
  tareasDeLaPersona: deSusTareas,
  motivo: 'Nunca la hizo.',
  idSC: idSC,
);

Future<void> _dejarCargar() => Future<void>.delayed(Duration.zero);

void main() {
  test('el modelo junta los espacios de la descripción y lee las fechas', () {
    final s = SenalCargoModel.senal({
      'codEmpleado': 211,
      'persona': 'DIEGO SANDRO RUCK TORRICO',
      'idTarRuti': 161,
      'tarea': 'Ejecutar  los  pagos\r\npor  diferentes conceptos',
      'ocurrencias': 10,
      'tareasDeLaPersona': 20,
      'motivo': 'Nunca la hizo.',
      'cargoDesde': '2022-07-01 00:00:00',
      'idSC': null,
    });

    expect(s.tarea, 'Ejecutar los pagos por diferentes conceptos');
    expect(s.cargoDesde, DateTime(2022, 7, 1));
    expect(s.callada, isFalse);
  });

  group('por persona', () {
    test('primero quien no hace ninguna; las calladas no cuentan', () {
      final st = SenalesCargoState().copyWith(
        senales: SenalesCargoState().senales.conFilas([
          _s(1, 'ANA', 10),
          _s(2, 'TOMAS', 20, deSusTareas: 2),
          _s(2, 'TOMAS', 21, deSusTareas: 2),
          _s(1, 'ANA', 11, idSC: 9),
        ]),
      );

      final p = st.porPersona;
      expect(p.map((x) => x.persona), ['TOMAS', 'ANA']);
      expect(p.first.ninguna, isTrue);
      expect(p.last.sinHacer, 1);
      expect(st.tareas, 3);
    });

    test('la búsqueda mira persona, cargo y sucursal', () {
      final st = SenalesCargoState()
          .copyWith(
            senales: SenalesCargoState().senales.conFilas([
              _s(1, 'ANA', 10),
              _s(2, 'TOMAS', 20),
            ]),
          )
          .copyWith(busqueda: 'tom');

      expect(st.porPersona.map((x) => x.persona), ['TOMAS']);
    });
  });

  group('está bien así', () {
    test('vuelve a leer y avisa con el mensaje del servidor', () async {
      final repo = _Repo([_s(1, 'ANA', 10), _s(1, 'ANA', 11)]);
      final n = SenalesCargoNotifier(repo, deMiEquipo: false);
      await _dejarCargar();

      final motivo = await n.estaBien(
        n.state.senales.filas.first,
        obs: 'La cubre otro',
      );

      expect(motivo, isNull);
      expect(n.state.senales.filas, hasLength(1));
      expect(n.state.aviso, contains('06/11/2026'));
      expect(repo.pedidos, contains('estaBien 1|10 obs=La cubre otro'));
    });

    test('si el servidor no lo acepta, devuelve su mensaje', () async {
      final repo = _Repo([_s(1, 'ANA', 10)])
        ..rechazo = 'La explicación no puede pasar de 300 caracteres.';
      final n = SenalesCargoNotifier(repo, deMiEquipo: false);
      await _dejarCargar();

      final motivo = await n.estaBien(n.state.senales.filas.first);

      expect(motivo, 'La explicación no puede pasar de 300 caracteres.');
      expect(n.state.guardando, isEmpty);
    });

    test('Mi equipo pide solo las de su equipo', () async {
      final repo = _Repo([]);
      SenalesCargoNotifier(repo, deMiEquipo: true);
      await _dejarCargar();

      expect(repo.pedidos, ['equipo']);
    });
  });

  group('en pantalla', () {
    testWidgets('sin señales lo dice', (t) async {
      await t.pumpWidget(_app(_Repo([])));
      await t.pumpAndSettle();

      expect(find.text('Nadie dejó de hacer sus tareas'), findsOneWidget);
    });

    testWidgets('cada persona dice cuántas de sus tareas no hace', (t) async {
      await t.pumpWidget(
        _app(
          _Repo([
            _s(2, 'TOMAS JARANDILLA', 20, deSusTareas: 2),
            _s(2, 'TOMAS JARANDILLA', 21, deSusTareas: 2),
          ]),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('TOMAS JARANDILLA'), findsOneWidget);
      expect(find.text('No hace ninguna de sus 2 tareas'), findsOneWidget);
    });

    testWidgets('en Mi equipo no está el filtro de "Está bien así"', (t) async {
      await t.pumpWidget(_app(_Repo([_s(1, 'ANA', 10)]), deMiEquipo: true));
      await t.pumpAndSettle();

      expect(find.byType(FilterChip), findsNothing);
      expect(find.text('Tareas que tu equipo no hace'), findsOneWidget);
    });
  });
}

Widget _app(_Repo repo, {bool deMiEquipo = false}) => ProviderScope(
  overrides: [senalCargoRepoProvider.overrideWithValue(repo)],
  child: MaterialApp(home: CargosPorRevisarScreen(deMiEquipo: deMiEquipo)),
);
