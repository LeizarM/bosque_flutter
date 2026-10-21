// Cambio de contraseña en el Dashboard: sin desbordes a 390/800/1400 px, el
// rechazo del servidor se muestra tal cual y el éxito limpia los campos.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cuenta_provider.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/repositories/cuenta_repository.dart';
import 'package:bosque_flutter/presentation/screens/cambio-clave/cambio_clave_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

class _Repo implements CuentaRepository {
  Object? error;
  final pedidos = <(String, String, String)>[];

  @override
  Future<ResultadoEscrituraEntity> cambiarClave({
    required String actual,
    required String nueva,
    required String confirmacion,
  }) async {
    pedidos.add((actual, nueva, confirmacion));
    if (error != null) throw error!;
    return ResultadoEscrituraEntity(
      id: BigInt.from(34),
      mensaje: 'Contraseña actualizada.',
    );
  }
}

void main() {
  setUpAll(cargarRoboto);

  late _Repo repo;
  setUp(() => repo = _Repo());

  Widget app() => appCheques(
    hijo: const CambioClaveScreen(),
    repo: RepositorioChequesFalso(total: 0),
    extra: [cuentaRepositoryProvider.overrideWithValue(repo)],
  );

  Future<void> llenar(WidgetTester tester) async {
    await tester.enterText(find.byKey(const ValueKey('clave-actual')), 'vieja1');
    await tester.enterText(find.byKey(const ValueKey('clave-nueva')), 'nueva123');
    await tester.enterText(
      find.byKey(const ValueKey('clave-repetida')),
      'nueva123',
    );
    await tester.tap(find.text('Guardar contraseña'));
    await esperar(tester);
  }

  for (final ancho in [390.0, 800.0, 1400.0]) {
    for (final escala in [1.0, 1.5]) {
      testWidgets(
        'no desborda a ${ancho.toInt()} px al ${(escala * 100).toInt()} %',
        (tester) async {
          if (escala != 1.0) conTexto(tester, escala);
          repo.error = 'La contraseña actual no es correcta. Después de 3 '
              'intentos fallidos en una hora el usuario se bloquea.';
          final errores = await capturandoErrores(() async {
            await montar(tester, app(), ancho: ancho);
            await llenar(tester);
          });
          expect(errores, isEmpty, reason: 'a $ancho');
          expect(
            find.textContaining('La contraseña actual no es correcta'),
            findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets('manda las tres claves y limpia los campos al salir bien', (
    tester,
  ) async {
    await montar(tester, app());
    await llenar(tester);
    expect(repo.pedidos.single, ('vieja1', 'nueva123', 'nueva123'));
    final actual = tester.widget<TextField>(
      find.byKey(const ValueKey('clave-actual')),
    );
    expect(actual.controller!.text, isEmpty);
    expect(find.text('Contraseña actualizada.'), findsOneWidget);
  });
}
