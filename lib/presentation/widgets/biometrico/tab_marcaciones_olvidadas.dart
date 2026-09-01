import 'package:bosque_flutter/core/state/biometrico_provider.dart';
import 'package:bosque_flutter/domain/entities/bio_check_in_out_adicional_entity.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/biometrico_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/biometrico/buscador_empleado_biometrico.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pestaña "Marcaciones olvidadas": el "Marcaciones Olvidadas Por Empleado"
/// del legacy — registrar a mano una entrada/salida que el reloj no captó.
class TabMarcacionesOlvidadas extends ConsumerWidget {
  const TabMarcacionesOlvidadas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elegido = ref.watch(empleadoSeleccionadoBiometricoProvider);

    return Padding(
      padding: const EdgeInsets.all(Esp.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const BuscadorEmpleadoBiometrico(),
          ),
          const SizedBox(height: Esp.xl),
          if (elegido == null)
            const MensajeVacio(
              icono: Icons.badge_outlined,
              titulo: 'Elegí un empleado',
              detalle: 'Buscá por nombre arriba para ver o registrar marcaciones olvidadas.',
            )
          else
            Expanded(
              child: _Marcaciones(
                userId: elegido.idEmpleadBio.toInt(),
                codEmpleado: elegido.idEmpleado.toInt(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Marcaciones extends ConsumerWidget {
  const _Marcaciones({required this.userId, required this.codEmpleado});
  final int userId;
  final int codEmpleado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bioCheckInOutAdicionalListProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Marcaciones registradas a mano', style: context.tituloSeccion()),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Registrar'),
              onPressed: () => _registrar(context, ref),
            ),
          ],
        ),
        const SizedBox(height: Esp.m),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => MensajeVacio(
                  icono: Icons.error_outline,
                  titulo: 'No se pudieron cargar las marcaciones',
                  detalle: textoDeError(e),
                ),
            data: (lista) {
              if (lista.isEmpty) {
                return const MensajeVacio(
                  icono: Icons.edit_calendar_outlined,
                  titulo: 'Sin marcaciones olvidadas',
                  detalle: 'No hay ninguna registrada a mano para este empleado.',
                );
              }
              return ListView.separated(
                itemCount: lista.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final m = lista[i];
                  return ListTile(
                    leading: const Icon(Icons.edit_calendar_outlined),
                    title: Text(
                      '${fechaCorta(m.checkTime)}  ·  ${horaCorta(m.checkTime)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Ver historial',
                          icon: const Icon(Icons.history),
                          onPressed:
                              () => mostrarHistorialBitacora(
                                context,
                                tabla: 'BioCHECKINOUTAdicinal',
                                idRegistro:
                                    '$userId|${fechaStringBiometrico(m.checkTime)}',
                                titulo: 'Historial de esta marcación',
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _eliminar(context, ref, m),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    BioCheckInOutAdicionalEntity m,
  ) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar marcación',
      mensaje: '¿Eliminar la marcación del ${fechaCorta(m.checkTime)} a las ${horaCorta(m.checkTime)}?',
      accion: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(biometricoRepositoryProvider).registrarMarcacionAdicional({
        'USERID': userId,
        'fechaString': fechaStringBiometrico(m.checkTime),
      }, 'D');
      ref.invalidate(bioCheckInOutAdicionalListProvider(userId));
      if (context.mounted) avisar(context, 'Marcación eliminada.');
    } catch (e) {
      if (context.mounted) avisarError(context, e);
    }
  }

  Future<void> _registrar(BuildContext context, WidgetRef ref) =>
      registrarMarcacionOlvidada(
        context,
        ref,
        userId: userId,
        codEmpleado: codEmpleado,
      );
}
