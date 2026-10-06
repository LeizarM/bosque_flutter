import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/domain/repositories/talonarios_repository.dart';
import 'package:bosque_flutter/presentation/widgets/talonarios/dialogo_cambio_empresa.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_depositos.dart';

/// El cambio de empresa de talonarios, de uno o de muchos.
///
/// Lo que se fija: que solo viajen los que de verdad cambian (los que ya están
/// en la empresa destino se omiten y se dice cuántos), que el aviso de SAP
/// aparezca solo cuando hay talonarios que ya circularon, y que una falla deje
/// el diálogo abierto para reintentar en vez de perder la selección.
void main() {
  const impexpap = 1;
  const esppapel = 5;

  TalonarioEntity tal(
    int id, {
    required int empresa,
    required String nombre,
    int entregas = 0,
  }) => TalonarioEntity(
    codTalonario: BigInt.from(id),
    codTipoRecibo: BigInt.one,
    nroTalonario: 'EC$id',
    costoBs: 13,
    numeracionInicial: 1,
    numeracionFinal: 50,
    estado: '1',
    codEmpresa: BigInt.from(empresa),
    observacion: '',
    audUsuario: BigInt.zero,
    datoEmpresa: nombre,
    entregas: entregas,
  );

  group('talonariosAMover', () {
    test('deja afuera los que ya están en la empresa destino', () {
      final todos = [
        tal(1, empresa: impexpap, nombre: 'IMPEXPAP'),
        tal(2, empresa: esppapel, nombre: 'ESPPAPEL'),
        tal(3, empresa: impexpap, nombre: 'IMPEXPAP'),
      ];

      final aMover = talonariosAMover(todos, BigInt.from(esppapel));

      expect(aMover.map((t) => t.codTalonario.toInt()), [1, 3]);
    });

    test('si todos ya están ahí no queda ninguno', () {
      final todos = [tal(1, empresa: esppapel, nombre: 'ESPPAPEL')];

      expect(talonariosAMover(todos, BigInt.from(esppapel)), isEmpty);
    });
  });

  test('conteoPorEmpresa cuenta por nombre y nombra a los sin empresa', () {
    final cuenta = conteoPorEmpresa([
      tal(1, empresa: impexpap, nombre: 'IMPEXPAP'),
      tal(2, empresa: impexpap, nombre: 'IMPEXPAP'),
      tal(3, empresa: 0, nombre: ''),
    ]);

    expect(cuenta, {'IMPEXPAP': 2, 'Sin empresa': 1});
  });

  group('diálogo', () {
    late _RepoTalonarios repo;
    int? resultado;
    var cerrado = false;

    setUp(() {
      repo = _RepoTalonarios();
      resultado = null;
      cerrado = false;
    });

    Future<void> abrir(
      WidgetTester tester,
      List<TalonarioEntity> talonarios,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            talonariosRepositoryProvider.overrideWithValue(repo),
            empresasProvider.overrideWith((ref) => EmpresasNotifier(_Rrhh())),
            userProvider.overrideWith(
              (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => TextButton(
                      onPressed: () async {
                        resultado = await mostrarCambioEmpresa(
                          context,
                          talonarios: talonarios,
                        );
                        cerrado = true;
                      },
                      child: const Text('abrir'),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    Future<void> elegirEmpresa(WidgetTester tester, String nombre) async {
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.text(nombre).last);
      await tester.pumpAndSettle();
    }

    Finder boton(String texto) => find.widgetWithText(FilledButton, texto);

    testWidgets('sin empresa elegida no deja confirmar y muestra el reparto', (
      tester,
    ) async {
      await abrir(tester, [
        tal(1, empresa: impexpap, nombre: 'IMPEXPAP'),
        tal(2, empresa: impexpap, nombre: 'IMPEXPAP'),
        tal(3, empresa: esppapel, nombre: 'ESPPAPEL'),
      ]);

      expect(find.text('3 talonarios seleccionados'), findsOneWidget);
      expect(find.text('Hoy: IMPEXPAP 2  ·  ESPPAPEL 1'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(boton('Cambiar empresa')).onPressed,
        isNull,
      );
    });

    testWidgets('manda solo los que cambian y dice cuántos se omiten', (
      tester,
    ) async {
      await abrir(tester, [
        tal(1, empresa: impexpap, nombre: 'IMPEXPAP'),
        tal(2, empresa: impexpap, nombre: 'IMPEXPAP'),
        tal(3, empresa: esppapel, nombre: 'ESPPAPEL'),
      ]);

      await elegirEmpresa(tester, 'ESPPAPEL');

      expect(
        find.text('Se cambian 2; 1 ya están en ESPPAPEL y se omiten.'),
        findsOneWidget,
      );
      await tester.tap(boton('Cambiar 2 talonarios'));
      await tester.pumpAndSettle();

      expect(repo.llamadas.single.map((e) => e.toInt()), [1, 2]);
      expect(repo.empresa, BigInt.from(esppapel));
      expect(repo.usuario, BigInt.from(34));
      expect(cerrado, isTrue);
      expect(resultado, 2);
    });

    testWidgets('si todos ya están en esa empresa no hay nada que confirmar', (
      tester,
    ) async {
      await abrir(tester, [tal(3, empresa: esppapel, nombre: 'ESPPAPEL')]);

      await elegirEmpresa(tester, 'ESPPAPEL');

      expect(
        find.text('Todos ya están en ESPPAPEL: no hay nada que cambiar.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(boton('Cambiar empresa')).onPressed,
        isNull,
      );
    });

    testWidgets('avisa de SAP solo si alguno ya circuló', (tester) async {
      await abrir(tester, [
        tal(1, empresa: impexpap, nombre: 'IMPEXPAP'),
        tal(2, empresa: impexpap, nombre: 'IMPEXPAP', entregas: 1),
      ]);

      await elegirEmpresa(tester, 'ESPPAPEL');

      expect(find.textContaining('1 ya circuló'), findsOneWidget);
      expect(find.textContaining('conciliación con SAP'), findsOneWidget);
    });

    testWidgets('sin talonarios circulados no hay aviso de SAP', (tester) async {
      await abrir(tester, [tal(1, empresa: impexpap, nombre: 'IMPEXPAP')]);

      await elegirEmpresa(tester, 'ESPPAPEL');

      expect(find.textContaining('conciliación con SAP'), findsNothing);
    });

    testWidgets('una falla deja el diálogo abierto y se puede reintentar', (
      tester,
    ) async {
      repo.falla = 'No se cambió la empresa de ningún talonario.';
      await abrir(tester, [tal(1, empresa: impexpap, nombre: 'IMPEXPAP')]);

      await elegirEmpresa(tester, 'ESPPAPEL');
      await tester.tap(boton('Cambiar 1 talonario'));
      await tester.pumpAndSettle();

      expect(cerrado, isFalse);
      expect(find.textContaining('No se cambió la empresa'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(boton('Cambiar 1 talonario')).onPressed,
        isNotNull,
      );

      repo.falla = null;
      await tester.tap(boton('Cambiar 1 talonario'));
      await tester.pumpAndSettle();

      expect(cerrado, isTrue);
      expect(resultado, 1);
    });

    testWidgets('Cancelar cierra sin escribir nada', (tester) async {
      await abrir(tester, [tal(1, empresa: impexpap, nombre: 'IMPEXPAP')]);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.llamadas, isEmpty);
      expect(cerrado, isTrue);
      expect(resultado, isNull);
    });
  });
}

class _RepoTalonarios extends Fake implements TalonariosRepository {
  final List<List<BigInt>> llamadas = [];
  BigInt? empresa;
  BigInt? usuario;
  Object? falla;

  @override
  Future<List<BigInt>> cambiarEmpresaLote({
    required List<BigInt> codTalonarios,
    required BigInt codEmpresa,
    required BigInt audUsuario,
  }) async {
    if (falla != null) throw falla!;
    llamadas.add(codTalonarios);
    empresa = codEmpresa;
    usuario = audUsuario;
    return codTalonarios;
  }
}

class _Rrhh extends Fake implements RRHHRepositoryImpl {
  @override
  Future<List<EmpresaEntity>> lstEmpresas() async => [
    EmpresaEntity(
      codEmpresa: 1,
      nombre: 'IMPEXPAP',
      codPadre: 0,
      sigla: 'IPX',
      audUsuario: 0,
    ),
    EmpresaEntity(
      codEmpresa: 5,
      nombre: 'ESPPAPEL',
      codPadre: 0,
      sigla: 'ESP',
      audUsuario: 0,
    ),
  ];
}
