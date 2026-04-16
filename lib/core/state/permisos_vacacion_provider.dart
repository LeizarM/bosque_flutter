import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/permisos_vacacion_impl.dart';
import 'package:bosque_flutter/domain/entities/permiso_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_vacacion_repository.dart';

/// Provider para la implementación del repositorio.
final permisosVacacionRepositoryProvider = Provider<PermisosVacacionRepository>(
  (ref) {
    return PermisosVacacionImpl();
  },
);

/// Provider que obtiene el resumen de vacaciones (días disponibles, asignados, abonados)
/// para un empleado específico utilizando la Acción 'H1'
final vacacionResumenProvider = FutureProvider.family<PermisoEntity?, int>((
  ref,
  codEmpleado,
) async {
  final repo = ref.watch(permisosVacacionRepositoryProvider);
  return await repo.getResumenVacaciones(codEmpleado);
});
