import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/cumpleanios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Componente que muestra el contenido principal del dashboard cuando no hay otra vista activa
class DashboardHomeContent extends ConsumerWidget {
  const DashboardHomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     ref.watch(cumpleMensajesInitProvider);
    final user = ref.watch(userProvider);
    final cumpleMensajes = ref.watch(cumpleMensajesProvider);

    return Center(
      child: user != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bienvenido, ${user.nombreCompleto}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                CumpleanosBanner(
                  cumpleMensajes: cumpleMensajes,
                  onClose: () => ref.read(cumpleMensajesProvider.notifier).state = [],
                ),
              ],
            )
          : const Text('No hay datos de usuario disponibles'),
    );
  }
}