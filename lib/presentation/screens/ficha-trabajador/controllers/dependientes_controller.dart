import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';

class DependienteController {
  static Future<void> eliminarDependiente({
    required BuildContext context,
    required WidgetRef ref,
    required DependienteEntity dependiente,
    required int codEmpleado,
  }) async {
    final confirmar = await ConfirmDialog.show(
      context,
      title: 'Confirmar eliminación',
      content: '¿Está seguro de eliminar este dependiente?',
      confirmText: 'Eliminar',
    );

    if (confirmar ?? false) {
      try {
        final success = await ref
            .read(dependientesNotifierProvider.notifier)
            .eliminarDependiente(dependiente.codDependiente);

        if (context.mounted) {
          if (success) {
            ref.invalidate(dependientesProvider(codEmpleado));
            AppSnackbarCustom.showDelete(
              context,
              'Dependiente eliminado correctamente',
            );
          } else {
            AppSnackbarCustom.showError(
              context,
              'Error al eliminar dependiente',
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbarCustom.showError(context, 'Error: $e');
        }
      }
    }
  }

  // Manejo de edición de dependientes
  static Future<void> editarDependiente({
    required BuildContext context,
    required WidgetRef ref,
    required DependienteEntity dependiente,
    required int codEmpleado,
  }) async {
    try {
      final dependientesActualizados = await ref
          .read(dependientesNotifierProvider.notifier)
          .editarDependiente(dependiente);

      if (!context.mounted) return;

      if (dependientesActualizados.isNotEmpty) {
        // Refrescar la lista de dependientes
        ref.invalidate(dependientesProvider(codEmpleado));

        AppSnackbar.showSuccess(
          context,
          'Dependiente actualizado correctamente',
        );
      } else {
        AppSnackbar.showError(context, 'No se pudo actualizar el dependiente');
      }
    } catch (e) {
      console('⚠️ Controller: Error en edición: $e');
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Error: $e');
    }
  }
}
