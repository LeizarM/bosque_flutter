import 'dart:io';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';
import 'package:bosque_flutter/domain/repositories/talonarios_repository.dart';
import 'package:bosque_flutter/presentation/screens/talonarios/talonarios_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_depositos.dart';

/// El modo de selección de la grilla de talonarios, para cambiarles la empresa
/// a varios de una vez.
///
/// La grilla tiene dos formas —tabla en ancho, tarjetas en móvil— y la casilla
/// y la columna de empresa viven en las dos; se prueban a los dos anchos porque
/// una cabecera con la casilla mal alineada o una fila que desborda no se ven
/// en el análisis estático.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La fuente de reemplazo de flutter test mide todos los glifos igual y
  // ensancha el texto: la pastilla «Adquirido» desbordaba su columna aunque con
  // una fuente real sobra. Roboto no viene empaquetada (la pone la plataforma),
  // así que se registra PlusJakartaSans con ese nombre: metros de texto
  // parecidos a los reales, y los desbordes que salgan dejan de ser del test.
  setUpAll(() async {
    final cargador = FontLoader('Roboto');
    for (final peso in ['400', '500', '600', '700']) {
      final f = File('assets/fonts/PlusJakartaSans-$peso.ttf');
      if (f.existsSync()) {
        cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await cargador.load();
  });

  TalonarioEntity tal(int id, {String empresa = 'IMPEXPAP', int cod = 1}) =>
      TalonarioEntity(
        codTalonario: BigInt.from(id),
        codTipoRecibo: BigInt.one,
        nroTalonario: 'EC$id',
        costoBs: 13,
        numeracionInicial: (id - 1) * 50 + 1,
        numeracionFinal: id * 50,
        estado: '1',
        codEmpresa: BigInt.from(cod),
        observacion: '',
        audUsuario: BigInt.zero,
        datoTipo: 'Recibo Caja Essp ( EC2 )',
        datoEmpresa: empresa,
        codEstadoActual: 1,
        estadoActual: 'Adquirido',
      );

  Future<void> abrir(WidgetTester tester, {required Size tamano}) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _Repo([
      tal(1),
      tal(2),
      tal(3, empresa: 'ESPPAPEL', cod: 5),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          talonariosRepositoryProvider.overrideWithValue(repo),
          empresasProvider.overrideWith((ref) => EmpresasNotifier(_Rrhh())),
          userProvider.overrideWith(
            (ref) => UserStateNotifier.sinStorage(loginAdminFalso),
          ),
        ],
        child: const MaterialApp(home: TalonariosScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  final alternar = find.byTooltip(
    'Seleccionar varios para cambiarles la empresa',
  );

  // FilledButton.icon crea una subclase, y byType busca el tipo exacto.
  final cambiarEmpresa = find.ancestor(
    of: find.text('Cambiar empresa'),
    matching: find.bySubtype<FilledButton>(),
  );

  for (final caso in <(String, Size)>[
    ('escritorio', const Size(1400, 900)),
    ('móvil', const Size(390, 844)),
  ]) {
    group(caso.$1, () {
      testWidgets('sin modo selección no hay casillas ni barra', (tester) async {
        await abrir(tester, tamano: caso.$2);

        expect(find.byType(Checkbox), findsNothing);
        expect(find.textContaining('seleccionado'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('al entrar aparecen las casillas y la barra en cero', (
        tester,
      ) async {
        await abrir(tester, tamano: caso.$2);

        await tester.tap(alternar);
        await tester.pumpAndSettle();

        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.text('0 seleccionados'), findsOneWidget);
        expect(tester.widget<FilledButton>(cambiarEmpresa).onPressed, isNull);
        expect(tester.takeException(), isNull);
      });

      testWidgets('seleccionar los visibles, quitar uno y cambiar empresa', (
        tester,
      ) async {
        await abrir(tester, tamano: caso.$2);
        await tester.tap(alternar);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Seleccionar los 3 visibles'));
        await tester.pumpAndSettle();
        expect(find.text('3 seleccionados'), findsOneWidget);
        expect(find.text('Quitar selección'), findsOneWidget);

        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(find.text('2 seleccionados'), findsOneWidget);
        expect(find.text('Seleccionar los 3 visibles'), findsOneWidget);

        await tester.tap(cambiarEmpresa);
        await tester.pumpAndSettle();
        expect(find.text('2 talonarios seleccionados'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('salir de la selección limpia lo tildado', (tester) async {
        await abrir(tester, tamano: caso.$2);
        await tester.tap(alternar);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Seleccionar los 3 visibles'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Salir de la selección'));
        await tester.pumpAndSettle();
        expect(find.byType(Checkbox), findsNothing);

        await tester.tap(alternar);
        await tester.pumpAndSettle();
        expect(find.text('0 seleccionados'), findsOneWidget);
      });
    });
  }

  testWidgets('la tabla ancha muestra la columna Empresa', (tester) async {
    await abrir(tester, tamano: const Size(1400, 900));

    expect(find.text('EMPRESA'), findsOneWidget);
    expect(find.text('IMPEXPAP'), findsNWidgets(2));
    expect(find.text('ESPPAPEL'), findsOneWidget);
  });

  testWidgets('la tarjeta del móvil nombra la empresa', (tester) async {
    await abrir(tester, tamano: const Size(390, 844));

    expect(find.textContaining('IMPEXPAP'), findsNWidgets(2));
    expect(find.textContaining('ESPPAPEL'), findsOneWidget);
  });
}

class _Repo extends Fake implements TalonariosRepository {
  _Repo(this.lista);

  final List<TalonarioEntity> lista;

  @override
  Future<List<TalonarioEntity>> listarTalonarios({
    BigInt? codTipoRecibo,
    BigInt? codEmpresa,
    BigInt? codGrupo,
    int? codEstadoActual,
    DateTime? desde,
    DateTime? hasta,
    bool? incluirCerrados,
  }) async => lista;
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
