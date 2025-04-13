import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Componente que muestra el contenido principal del dashboard cuando no hay otra vista activa
class DashboardHomeContent extends ConsumerWidget {
  const DashboardHomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

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
                Text(
                  'Cargo: ${user.cargo}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'Tipo de Usuario: ${user.tipoUsuario}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            )
          : const Text('No hay datos de usuario disponibles'),
    );
  }
}