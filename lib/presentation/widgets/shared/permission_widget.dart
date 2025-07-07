import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
/// Un widget que muestra su hijo solo si el usuario tiene permiso para el nombre de botón dado.
class PermissionWidget extends ConsumerWidget {
  final String buttonName;
  final Widget child;
  final Widget? placeholder;

  const PermissionWidget({
    super.key,
    required this.buttonName,
    required this.child,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Primero verificamos si hay un usuario autenticado
    final user = ref.watch(userProvider);
    
    // Si no hay usuario, mostramos el placeholder o nada
    if (user == null) {
      return placeholder ?? const SizedBox.shrink();
    }
    
    // Observar el estado de permisos de botones
    final permissionsState = ref.watch(buttonPermissionsProvider);
    
    return permissionsState.when(
      loading: () {
        // Durante la carga, verificamos si el usuario es administrador
        if (user.tipoUsuario == 'ROLE_ADM') {
          // Los administradores siempre tienen permiso, incluso durante la carga
          return child;
        }
        return placeholder ?? const SizedBox.shrink();
      },
      error: (error, stack) {
        // En caso de error, verificamos si el usuario es administrador
        if (user.tipoUsuario == 'ROLE_ADM') {
          // Los administradores siempre tienen permiso, incluso si hay error
          return child;
        }
        debugPrint('Error al cargar permisos para $buttonName: $error');
        return placeholder ?? const SizedBox.shrink();
      },
      data: (permisos) {
        // Obtener el notificador de permisos
        final permissionsNotifier = ref.read(buttonPermissionsProvider.notifier);
        
        // Verificar si el usuario tiene permiso para este botón
        final hasPermission = permissionsNotifier.tienePermiso(buttonName);
        
        // Si el usuario tiene permiso, mostrar el hijo; de lo contrario, mostrar el placeholder o nada
        if (hasPermission) {
          return child;
        } else {
          return placeholder ?? const SizedBox.shrink();
        }
      },
    );
  }
}