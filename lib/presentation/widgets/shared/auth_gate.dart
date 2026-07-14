import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';

class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(asyncUserProvider);
    return asyncUser.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo validar tu sesión. Inicia sesión nuevamente.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          // Redirige al login si no hay usuario válido
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Usuario válido y versión correcta
        return child;
      },
    );
  }
}
