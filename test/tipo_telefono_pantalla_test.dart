// Pantalla de Tipos de teléfono y, con ella, el kit de catálogos de
// parámetros: sin desbordes a 390/800/1400 px, tabla o tarjetas según el
// ancho, búsqueda, paginación y los textos del servidor tal cual.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/tipo_telefono_provider.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/domain/repositories/tipo_telefono_repository.dart';
import 'package:bosque_flutter/presentation/screens/tipo-telefono/tipo_telefono_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

class _RepoFalso implements TipoTelefonoRepository {
  List<TipoTelefonoEntity> tipos = [];
  Object? errorEscritura;
  final escritos = <TipoTelefonoEntity>[];

  @override
  Future<List<TipoTelefonoEntity>> listar() async => tipos;

  @override
  Future<ResultadoEscrituraEntity> registrar(TipoTelefonoEntity tipo) async {
    if (errorEscritura != null) throw errorEscritura!;
    escritos.add(tipo);
    return ResultadoEscrituraEntity(
      id: BigInt.from(99),
      mensaje: 'Tipo de teléfono «${tipo.tipo}» registrado.',
    );
  }

  @override
  Future<ResultadoEscrituraEntity> eliminar(int codTipoTel) async {
    if (errorEscritura != null) throw errorEscritura!;
    return ResultadoEscrituraEntity(
      id: BigInt.from(codTipoTel),
      mensaje: 'Tipo de teléfono eliminado.',
    );
  }
}

List<TipoTelefonoEntity> _tipos(int n) => [
  TipoTelefonoEntity(codTipoTel: 1, tipo: 'CELULAR', audUsuario: 0, usos: 219),
  TipoTelefonoEntity(codTipoTel: 2, tipo: 'DOMICILIO', audUsuario: 0, usos: 60),
  TipoTelefonoEntity(
    codTipoTel: 3,
    tipo: 'CORPORATIVO',
    audUsuario: 0,
    usos: 104,
  ),
  for (var i = 4; i <= n; i++)
    TipoTelefonoEntity(
      codTipoTel: i,
      tipo: 'TIPO DE PRUEBA CON UN NOMBRE BASTANTE LARGO NUMERO $i',
      audUsuario: 0,
    ),
];

void main() {
  setUpAll(cargarRoboto);

  late _RepoFalso repo;
  setUp(() => repo = _RepoFalso()..tipos = _tipos(3));

  Widget app() => appCheques(
    hijo: const TipoTelefonoScreen(),
    repo: RepositorioChequesFalso(total: 0),
    login: loginCheques(tipo: 'ROLE_ADM'),
    extra: [tipoTelefonoRepositoryProvider.overrideWithValue(repo)],
  );

  final modoPorAncho = {390.0: 'tarjeta-1', 800.0: 'fila-1', 1400.0: 'fila-1'};

  for (final escala in [1.0, 1.5]) {
    modoPorAncho.forEach((ancho, clave) {
      testWidgets(
        'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} %',
        (tester) async {
          repo.tipos = _tipos(14);
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(
            () => montar(tester, app(), ancho: ancho),
          );
          expect(errores, isEmpty, reason: 'a $ancho');
          expect(find.byKey(ValueKey(clave)), findsOneWidget);
          // 14 tipos: diez por página y el paginador a la vista.
          expect(find.textContaining('14 tipos'), findsOneWidget);
        },
      );
    });
  }

  testWidgets('el buscador ignora acentos y mayúsculas', (tester) async {
    await montar(tester, app());
    await tester.enterText(find.byType(TextField).first, 'corpo');
    await esperar(tester);
    expect(find.byKey(const ValueKey('fila-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('fila-1')), findsNothing);
    expect(find.textContaining('1 tipo de 3'), findsOneWidget);
  });

  testWidgets('el rechazo del servidor se ve en el formulario, tal cual', (
    tester,
  ) async {
    repo.errorEscritura = 'Ya existe el tipo de teléfono «CELULAR».';
    final errores = await capturandoErrores(() async {
      await montar(tester, app(), ancho: 390);
      await tester.tap(find.byTooltip('Nuevo tipo'));
      await esperar(tester);
      await tester.enterText(
        find.byKey(const ValueKey('campo-tipo-telefono')),
        'celular',
      );
      await tester.tap(find.text('Registrar'));
      await esperar(tester);
    });
    expect(errores, isEmpty);
    expect(find.text('Ya existe el tipo de teléfono «CELULAR».'), findsOneWidget);
  });

  testWidgets('alta correcta: manda código 0 y cierra el formulario', (
    tester,
  ) async {
    await montar(tester, app());
    await tester.tap(find.text('Nuevo tipo'));
    await esperar(tester);
    await tester.enterText(
      find.byKey(const ValueKey('campo-tipo-telefono')),
      'fax',
    );
    await tester.tap(find.text('Registrar'));
    await esperar(tester);
    expect(repo.escritos.single.codTipoTel, 0);
    expect(find.byKey(const ValueKey('campo-tipo-telefono')), findsNothing);
  });

  testWidgets('una baja rechazada muestra el motivo completo', (tester) async {
    repo.errorEscritura =
        'No se puede eliminar «CELULAR»: lo usan 219 teléfonos registrados.';
    final errores = await capturandoErrores(() async {
      await montar(tester, app());
      await tester.tap(find.byTooltip('Eliminar').first);
      await esperar(tester);
      await tester.tap(find.text('Eliminar tipo'));
      await esperar(tester);
    });
    expect(errores, isEmpty);
    expect(find.text('No se pudo eliminar'), findsOneWidget);
    expect(
      find.text(
        'No se puede eliminar «CELULAR»: lo usan 219 teléfonos registrados.',
      ),
      findsOneWidget,
    );
  });
}
