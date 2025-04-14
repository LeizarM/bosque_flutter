import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Widget que verifica si el usuario está autenticado antes de mostrar contenido protegido
/// Útil para rutas o widgets que requieren autenticación pero no son parte del árbol principal
class AuthGuard extends ConsumerStatefulWidget {
  final Widget child;
  final String redirectRoute;
  
  const AuthGuard({
    Key? key,
    required this.child,
    this.redirectRoute = '/login',
  }) : super(key: key);

  @override
  ConsumerState<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends ConsumerState<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final secureStorage = SecureStorage();
    final isTokenExpired = await secureStorage.isTokenExpired();

    if (mounted) {
      setState(() {
        _isAuthenticated = !isTokenExpired;
        _isLoading = false;
      });
      
      // Si el token expiró y estamos montados, redirigir al login
      if (isTokenExpired && mounted) {
        // Small delay to let the UI render first
        Future.delayed(const Duration(milliseconds: 100), () {
          context.go(widget.redirectRoute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mientras verificamos, mostrar un indicador de carga
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verificando sesión...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }
    
    // Si no está autenticado, mostrar mensaje de redirección
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Sesión expirada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Redirigiendo al login...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }
    
    // Si está autenticado, mostrar el contenido protegido
    return widget.child;
  }
}