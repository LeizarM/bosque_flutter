// Arnes de las pruebas de pantalla de «Verificar Cheques»: monta la app con el
// repositorio falso de verificaciones, el reloj del modulo fijo (3/10/2026) y la
// tipografia real. Reusa el arnes de cheques (tema, localizacion, breakpoints,
// `montar`, `esperar`, `conTexto`, `capturandoErrores`): no se repite.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';

import 'arnes_cheques.dart';
import 'repositorio_cheques.dart';
import 'repositorio_verificaciones.dart';

export 'arnes_cheques.dart'
    show
        bancosFalsos,
        cargarRoboto,
        capturandoErrores,
        conTexto,
        esperar,
        isoDia,
        montar,
        relojFijoCheques;

/// La app de prueba con [hijo] y los providers de verificaciones sustituidos.
Widget appVerificaciones({
  required Widget hijo,
  required RepositorioVerificacionesFalso repo,
  List<BancoEntity>? bancos,
  Future<List<BancoEntity>> Function()? listaDeBancos,
  List<Override> extra = const [],
}) {
  return appCheques(
    hijo: hijo,
    repo: RepositorioChequesFalso(),
    extra: [
      verificacionesRepositoryProvider.overrideWithValue(repo),
      listaBancosProvider.overrideWith(
        (ref) async => listaDeBancos != null ? listaDeBancos() : (bancos ?? bancosFalsos),
      ),
      ...extra,
    ],
  );
}

/// El texto de un [Finder] de un solo `Text`.
String textoDe(WidgetTester tester, Finder f) => tester.widget<Text>(f).data ?? '';
