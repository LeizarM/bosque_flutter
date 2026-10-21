import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/agenda_impl.dart';
import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';
import 'package:bosque_flutter/domain/repositories/agenda_repository.dart';

/// Agenda de empleados del Dashboard. Perezoso y tipado contra la interfaz.
final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaImpl(),
);

/// Se pide al abrir la agenda y se descarta al cerrarla.
final agendaEmpleadosProvider =
    FutureProvider.autoDispose<List<AgendaEmpleadoEntity>>(
      (ref) => ref.watch(agendaRepositoryProvider).empleados(),
    );

/// Si el usuario puede abrir la ficha completa: la misma regla del menú que la
/// pantalla de empleados (tb_vista 104). El administrador siempre puede.
final puedeVerFichaProvider = Provider<bool>((ref) {
  if (ref.watch(userProvider)?.tipoUsuario == 'ROLE_ADM') return true;
  ref.watch(menuProvider);
  return ref
          .read(menuProvider.notifier)
          .getMenuItemByPath(AppConstants.rutaEmpleadosDependientes) !=
      null;
});
