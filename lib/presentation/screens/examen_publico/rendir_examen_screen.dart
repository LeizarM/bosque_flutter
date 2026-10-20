/// `/examen/rendir/:codExamen`: el postulante rinde con la misma pantalla que
/// el empleado, con su propio token.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/presentation/screens/examen_publico/ingreso_examen_screen.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/marco_publico.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/rendicion_examen.dart';

class RendirExamenScreen extends StatelessWidget {
  const RendirExamenScreen({super.key, required this.codExamen});

  /// Tal como llega en la URL.
  final String codExamen;

  @override
  Widget build(BuildContext context) {
    final cod = BigInt.tryParse(codExamen);
    if (cod == null) {
      return MarcoPublicoExamen(
        child: MensajeError(
          error: 'El enlace del examen no es válido.',
          onReintentar: () => context.go(AppConstants.rutaTcpeIngreso),
        ),
      );
    }
    return MarcoPublicoExamen(
      centrado: false,
      child: RendicionExamen(
        clave: ClaveRendicion(OrigenRendicion.postulante, cod),
        onSalir: () => context.go(AppConstants.rutaTcpeIngreso),
        onEntregado: (_) => context.go(rutaResultado(cod)),
      ),
    );
  }
}
