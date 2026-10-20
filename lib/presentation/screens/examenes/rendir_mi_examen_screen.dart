/// `/tcpeExamenes/rendir/:codExamen`: el empleado rinde a pantalla completa,
/// fuera del shell y sin menú lateral. Con el examen en curso no se sale de
/// aquí (ver `GuardiaSalidaExamen`); al recargar se retoma donde iba.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/marco_publico.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/rendicion_examen.dart';

/// La ruta de rendición del empleado para un examen.
String rutaRendirMiExamen(BigInt codExamen) =>
    AppConstants.rutaTcpeRendirMiExamen.replaceFirst(':codExamen', '$codExamen');

class RendirMiExamenScreen extends StatelessWidget {
  const RendirMiExamenScreen({super.key, required this.codExamen});

  /// Tal como llega en la URL.
  final String codExamen;

  @override
  Widget build(BuildContext context) {
    void volver() => context.go('/dashboard/${AppConstants.rutaTcpeMisExamenes}');
    final cod = BigInt.tryParse(codExamen);
    if (cod == null) {
      return MarcoPublicoExamen(child: MensajeError(error: 'El enlace del examen no es válido.', onReintentar: volver));
    }
    return MarcoPublicoExamen(
      centrado: false,
      child: RendicionExamen(clave: ClaveRendicion(OrigenRendicion.empleado, cod), onSalir: volver),
    );
  }
}
