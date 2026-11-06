/// Nombre de la empresa que paga una planilla de horas extra (D18): sale de
/// `/rrhh/lst-empresas`, que ya existe. Aparte del barril del kit, para que
/// las demás pantallas del módulo no dependan del provider de RRHH.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/rrhh_provider.dart';

/// El nombre de [codEmpresa]; mientras carga, si falla o si no la encuentra,
/// «Empresa 2» (su código). Se llama desde `build`: al llegar, se redibuja.
String nombreEmpresaHex(WidgetRef ref, BigInt codEmpresa) {
  final empresas = ref.watch(empresasProvider).valueOrNull ?? const [];
  for (final e in empresas) {
    // `EmpresaEntity.codEmpresa` es `int`: se convierte aquí, en el borde.
    if (BigInt.from(e.codEmpresa) == codEmpresa && e.nombre.trim().isNotEmpty) {
      return e.nombre.trim();
    }
  }
  return 'Empresa $codEmpresa';
}
