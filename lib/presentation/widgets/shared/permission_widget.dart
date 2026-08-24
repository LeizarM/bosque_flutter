import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';

/// ¿Este usuario tiene el botón `nombreBtn`?
///
/// Es la MISMA regla que aplica [PermissionWidget]; existe aparte porque hay
/// lugares donde hace falta el booleano y no el widget. El módulo de Comisiones
/// arma su lista de pestañas con un `if` por pestaña, y un `TabController`
/// necesita que la cantidad de pestañas y la de vistas coincidan: envolver cada
/// una en un widget que a veces devuelve `SizedBox.shrink()` las contaría igual.
///
/// Antes ese módulo tenía su propia copia de la regla y no decía lo mismo:
/// mientras los permisos viajaban por red, [PermissionWidget] ya dejaba pasar al
/// administrador y aquella copia le devolvía `false`. Resultado: el admin veía
/// el módulo sin pestañas hasta que llegaba la respuesta.
///
/// El fallback de administrador replica el de `Loggin.autorizarBtn()` del ERP
/// viejo: un `adm` entra aunque el ACL no lo mencione.
bool tienePermisoDeBoton(WidgetRef ref, String nombreBtn) {
  final user = ref.watch(userProvider);
  if (user == null) return false;

  // Vale incluso mientras cargan o si la carga falló: es lo que hace el ERP
  // viejo, y no depende de una respuesta que puede no llegar.
  if (user.tipoUsuario == 'ROLE_ADM') return true;

  return ref.watch(buttonPermissionsProvider).maybeWhen(
    data: (_) =>
        ref.read(buttonPermissionsProvider.notifier).tienePermiso(nombreBtn),
    orElse: () => false,
  );
}

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
    return tienePermisoDeBoton(ref, buttonName)
        ? child
        : (placeholder ?? const SizedBox.shrink());
  }
}
