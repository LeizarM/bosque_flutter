import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_provider.dart';

class PermissionVerificationService {
  final Ref ref;  // Cambiamos a Ref en lugar de ProviderRef

  PermissionVerificationService(this.ref);

  Future<bool> verificarPermisosEdicion(int codEmpleado) async {
    try {
        // Obtener tipo de usuario
      final tipoUsuario = await ref.read(userProvider.notifier).getTipoUsuario();
      if (tipoUsuario.toString().toUpperCase() == 'ROLE_ADM') {
        return true;
      }
      final codEmpleadoLocal = await ref.read(userProvider.notifier).getCodEmpleado();

      if (codEmpleadoLocal == 0) {
        return false;
      }

      //print('codEmpleadoLocal: $codEmpleadoLocal');
      //print('codEmpleado: $codEmpleado');
      //print('tipoUsuario: $tipoUsuario');

      return codEmpleado == codEmpleadoLocal;
    } catch (e) {
      print('Error al verificar permisos de edición: $e');
      return false;
    }
  }
}