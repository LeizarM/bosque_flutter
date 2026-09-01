import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El punto de entrada del reporte: elegir a quién mirar.
///
/// Usa [ComboBuscable] (la misma pieza que Permisos y Rol de Sábados) sobre el
/// padrón completo de `empleadosBiometricoProvider` — filtrado en el cliente,
/// no en el servidor, porque son ~400 filas y no miles.
class BuscadorEmpleadoBiometrico extends ConsumerWidget {
  const BuscadorEmpleadoBiometrico({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(empleadosBiometricoProvider);
    final elegido = ref.watch(empleadoSeleccionadoBiometricoProvider);

    return async.when(
      loading:
          () => const _CampoDeshabilitado(
            texto: 'Cargando empleados…',
            icono: Icons.hourglass_empty,
          ),
      error:
          (e, _) => _CampoDeshabilitado(
            texto: 'No se pudo cargar la lista de empleados',
            icono: Icons.error_outline,
            esError: true,
          ),
      data: (empleados) {
        if (empleados.isEmpty) {
          return const _CampoDeshabilitado(
            texto: 'No hay empleados enlazados al biométrico',
            icono: Icons.link_off,
          );
        }
        return ComboBuscable<BigInt>(
          etiqueta: 'Empleado',
          pista: 'Escribe un nombre…',
          valor: elegido?.idEmpleado,
          opciones: [
            for (final e in empleados)
              DropdownMenuEntry(value: e.idEmpleado, label: e.datoNombreBosq),
          ],
          onElegir: (id) {
            final e =
                id == null
                    ? null
                    : empleados.firstWhere((e) => e.idEmpleado == id);
            ref.read(empleadoSeleccionadoBiometricoProvider.notifier).state =
                e;
          },
        );
      },
    );
  }
}

/// El mismo molde visual del combo, pero sin poder tocarlo — para cuando
/// todavía no hay opciones que elegir.
class _CampoDeshabilitado extends StatelessWidget {
  const _CampoDeshabilitado({
    required this.texto,
    required this.icono,
    this.esError = false,
  });

  final String texto;
  final IconData icono;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Empleado',
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: Icon(
          icono,
          size: 18,
          color: esError ? cs.error : null,
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(color: esError ? cs.error : Theme.of(context).hintColor),
      ),
    );
  }
}
