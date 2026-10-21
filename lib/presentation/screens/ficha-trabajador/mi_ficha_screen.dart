/// «Mi ficha»: la ficha del trabajador de quien inició sesión, a un toque desde
/// el sidebar. Reusa [InfoEmpleadoScreen] con el codEmpleado de la sesión.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/presentation/screens/ficha-trabajador/empleado_informacion_screen.dart';

class MiFichaScreen extends ConsumerWidget {
  const MiFichaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codEmpleado = ref.watch(userProvider)?.codEmpleado ?? 0;
    // Un usuario sin empleado vinculado (cuentas de sistema) no tiene ficha.
    if (codEmpleado <= 0) {
      return const Scaffold(
        body: MensajeVacio(
          icono: Icons.badge_outlined,
          titulo: 'Tu usuario no tiene ficha',
          detalle: 'No está vinculado a un empleado.',
        ),
      );
    }
    return InfoEmpleadoScreen(
      key: ValueKey(codEmpleado),
      codEmpleado: codEmpleado,
    );
  }
}
