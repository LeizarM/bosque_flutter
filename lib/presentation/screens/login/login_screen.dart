import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepositoryImpl();
  bool _isLoading = false;
  String? _message;
  bool _obscurePassword = true;

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _message = 'El usuario y contraseña son obligatorios';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      // Si el repositorio devuelve directamente un LoginEntity
      final (loginEntity, message) = await _authRepository.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (mounted) {
        if (loginEntity != null) {
          // Verificar la versión de la aplicación
          final currentAppVersion = AppConstants.APP_VERSION;
          final serverAppVersion = loginEntity.versionApp;
          if (currentAppVersion != serverAppVersion) {
            setState(() {
              _isLoading = false;
            });
            _showUpdateDialog(context, serverAppVersion);
            return; // Salir sin guardar usuario ni navegar
          }
          // Guardar los datos del usuario en el provider y en almacenamiento
          await ref.read(userProvider.notifier).setUser(loginEntity);
          context.go('/dashboard');
        } else {
          setState(() {
            _message = message;
          });
        }
      }
    } catch (e) {
      setState(() {
        _message = 'Error inesperado: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
// Método para mostrar el diálogo de actualización
void _showUpdateDialog(BuildContext context, String serverVersion) {
  showDialog(
    context: context,
    barrierDismissible: false, // El usuario no puede cerrar el diálogo tocando fuera
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Actualización necesaria'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La versión actual de la aplicación (${AppConstants.APP_VERSION}) está desactualizada.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Para continuar utilizando BOSQUE, por favor actualice a la versión $serverVersion.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          
          TextButton(
            onPressed: () {
              // Cerrar la aplicación
              Navigator.of(dialogContext).pop();
              // En una aplicación real, podrías usar SystemNavigator.pop() para cerrar la app
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
    final appTheme = ref.watch(themeNotifierProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ResponsiveRowColumn(
                rowMainAxisAlignment: MainAxisAlignment.center,
                columnMainAxisAlignment: MainAxisAlignment.center,
                layout: isSmallScreen
                    ? ResponsiveRowColumnType.COLUMN
                    : ResponsiveRowColumnType.ROW,
                children: [
                  ResponsiveRowColumnItem(
                    rowFlex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forest_rounded,
                            size: isSmallScreen ? 80 : 120,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'BOSQUE',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ResponsiveRowColumnItem(
                    rowFlex: 1,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? screenSize.width * 0.85 : 400,
                      ),
                      margin: const EdgeInsets.all(24.0),
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: appTheme.isDarkMode
                                ? Colors.black.withAlpha(70)
                                : Colors.black.withAlpha(51),
                            blurRadius: 10.0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Iniciar Sesión',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: colorScheme.secondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24.0),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                          ),
                          const SizedBox(height: 8.0),
                          
                          if (_message != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                _message!,
                                style: TextStyle(color: colorScheme.onErrorContainer),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                          const SizedBox(height: 8.0),
                          SizedBox(
                            height: 50,
                            child: _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: colorScheme.primary))
                                : ElevatedButton(
                                    onPressed: _login,
                                    child: const Text('INICIAR SESIÓN'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}