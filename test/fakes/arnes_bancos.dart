// Arnes de las pruebas de la pantalla de Bancos. Reutiliza la app de prueba de
// cheques (tema real, localizacion, breakpoints, Roboto y el montaje un
// fotograma despues) y le suma el repositorio y los permisos de bancos.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';

import 'arnes_cheques.dart';
import 'repositorio_bancos.dart';
import 'repositorio_cheques.dart';

/// Administrador: ve los tres botones.
const permisosBancoAdmin = PermisosBanco(botones: <String>{}, esAdmin: true);

/// Sin ningun boton de la vista 43.
const permisosBancoNinguno = PermisosBanco.ninguno;

PermisosBanco permisosBancoCon(Iterable<String> botones) =>
    PermisosBanco(botones: botones.toSet(), esAdmin: false);

/// La pantalla de Bancos con su repositorio falso y los permisos elegidos.
Widget appBancos({
  required Widget hijo,
  required RepositorioBancosFalso repo,
  PermisosBanco permisos = permisosBancoAdmin,
  List<Override> extra = const [],
}) => appCheques(
  hijo: hijo,
  // Bancos no usa el repositorio de cheques; solo hace falta uno valido.
  repo: RepositorioChequesFalso(total: 0),
  extra: [
    bancosRepositoryProvider.overrideWithValue(repo),
    permisosBancoProvider.overrideWithValue(permisos),
    ...extra,
  ],
);
