// Pantalla de Niveles jerárquicos: sin desbordes a 390/800/1400 px, filtro de
// vigencia, acciones solo en la escala vigente (salvo administrador) y la
// nueva vigencia que manda código 0 con el mismo nivel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/nivel_jerarquico_provider.dart';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/repositories/nivel_jerarquico_repository.dart';
import 'package:bosque_flutter/presentation/screens/nivel-jerarquico/nivel_jerarquico_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

class _RepoFalso implements NivelJerarquicoRepository {
  List<NivelJerarquicoEntity> escalas = [];
  Object? errorEscritura;
  final escritas = <NivelJerarquicoEntity>[];

  @override
  Future<List<NivelJerarquicoEntity>> getNivelesJerarquicos() async =>
      escalas.where((e) => e.esVigente).toList();

  @override
  Future<List<NivelJerarquicoEntity>> listarEscalas() async => escalas;

  @override
  Future<ResultadoEscrituraEntity> registrar(
    NivelJerarquicoEntity escala,
  ) async {
    if (errorEscritura != null) throw errorEscritura!;
    escritas.add(escala);
    return ResultadoEscrituraEntity(
      id: BigInt.from(50),
      mensaje: 'Escala del nivel ${escala.nivel} registrada.',
    );
  }

  @override
  Future<ResultadoEscrituraEntity> eliminar(int codNivel) async {
    if (errorEscritura != null) throw errorEscritura!;
    return ResultadoEscrituraEntity(
      id: BigInt.from(codNivel),
      mensaje: 'Escala eliminada.',
    );
  }
}

NivelJerarquicoEntity _escala(int cod, int nivel, {bool vigente = true}) =>
    NivelJerarquicoEntity(
      codNivel: cod,
      nivel: nivel,
      haberBasico: 8400.5 - nivel * 100,
      bonoProduccion: 550,
      fecha: vigente ? DateTime(2014, 10, 1) : DateTime(2013, 1, 1),
      audUsuario: 0,
      activo: vigente ? 1 : 0,
      cargos: nivel * 3,
    );

void main() {
  setUpAll(cargarRoboto);

  late _RepoFalso repo;
  setUp(
    () =>
        repo =
            _RepoFalso()
              ..escalas = [
                for (var n = 1; n <= 12; n++) _escala(n, n),
                _escala(99, 1, vigente: false),
              ],
  );

  Widget app({String tipo = 'ROLE_ADM'}) => appCheques(
    hijo: const NivelJerarquicoScreen(),
    repo: RepositorioChequesFalso(total: 0),
    login: loginCheques(tipo: tipo),
    extra: [nivelJerarquicoRepoProvider.overrideWithValue(repo)],
  );

  final modoPorAncho = {390.0: 'tarjeta-1', 800.0: 'fila-1', 1400.0: 'fila-1'};
  for (final escala in [1.0, 1.5]) {
    modoPorAncho.forEach((ancho, clave) {
      testWidgets(
        'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} %',
        (tester) async {
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(
            () => montar(tester, app(), ancho: ancho),
          );
          expect(errores, isEmpty, reason: 'a $ancho');
          expect(find.byKey(ValueKey(clave)), findsOneWidget);
          expect(find.textContaining('12 escalas'), findsOneWidget);
        },
      );
    });
  }

  testWidgets('el filtro Anteriores muestra solo la escala vencida', (
    tester,
  ) async {
    await montar(tester, app());
    await tester.tap(find.text('Anteriores'));
    await esperar(tester);
    expect(find.byKey(const ValueKey('fila-99')), findsOneWidget);
    expect(find.byKey(const ValueKey('fila-1')), findsNothing);
    expect(find.textContaining('1 escala'), findsOneWidget);
  });

  testWidgets('nueva vigencia: código 0, mismo nivel y montos copiados', (
    tester,
  ) async {
    await montar(tester, app());
    await tester.tap(find.byTooltip('Nueva vigencia').first);
    await esperar(tester);
    await tester.enterText(find.byKey(const ValueKey('campo-haber')), '9000,5');
    await tester.tap(find.text('Registrar'));
    await esperar(tester);
    final e = repo.escritas.single;
    expect(e.codNivel, 0);
    expect(e.nivel, 1);
    expect(e.haberBasico, 9000.5);
    expect(e.bonoProduccion, 550);
  });

  testWidgets('el rechazo del servidor queda en el formulario', (tester) async {
    repo.errorEscritura = 'Ya existe una escala del nivel 1 que rige desde el 01/10/2014.';
    final errores = await capturandoErrores(() async {
      await montar(tester, app(), ancho: 390);
      await tester.tap(find.byTooltip('Nueva escala'));
      await esperar(tester);
      await tester.enterText(find.byKey(const ValueKey('campo-nivel')), '1');
      await tester.tap(find.text('Registrar'));
      await esperar(tester);
    });
    expect(errores, isEmpty);
    expect(
      find.text('Ya existe una escala del nivel 1 que rige desde el 01/10/2014.'),
      findsOneWidget,
    );
  });
}
