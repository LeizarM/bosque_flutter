import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final LoginEntity user;
  const ChangePasswordScreen({super.key, required this.user});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _success = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _passwordController.text.length >= 6;
  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text &&
      _confirmController.text.isNotEmpty;
  bool get _isNotDefault => _passwordController.text != '123456789';

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final user = widget.user;
    user.npassword = _passwordController.text;
    final success = await ref
        .read(userProvider.notifier)
        .changePasswordDefault(user);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      setState(() => _success = true);
      await ref.read(userProvider.notifier).setUser(user);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.go('/dashboard');
    } else {
      setState(
        () => _error = 'No se pudo cambiar la contraseña. Intenta de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = cs.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final cardWidth = isWide ? 460.0 : screenWidth * 0.92;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [const Color(0xFF0F0F1A), const Color(0xFF1A1A2E)]
                    : [accent.withValues(alpha: 0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: SizedBox(
                    width: cardWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono de seguridad
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _success
                                ? Icons.check_rounded
                                : Icons.lock_reset_rounded,
                            size: 40,
                            color: _success ? Colors.green : accent,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Título
                        Text(
                          _success
                              ? '¡Contraseña actualizada!'
                              : 'Cambiar contraseña',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Subtítulo
                        Text(
                          _success
                              ? 'Redirigiendo al panel principal...'
                              : 'Tu contraseña actual es la predeterminada.\nPor seguridad, debes cambiarla para continuar.',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (!_success) ...[
                          // Card del formulario
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.grey.shade200,
                              ),
                              boxShadow:
                                  isDark
                                      ? null
                                      : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.06,
                                          ),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Usuario actual (info)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 20,
                                          color: accent,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            widget.user.nombreCompleto,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: accent,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Nueva contraseña
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      labelText: 'Nueva contraseña',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  _obscurePassword =
                                                      !_obscurePassword,
                                            ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                              : Colors.grey.shade50,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.length < 6) {
                                        return 'Mínimo 6 caracteres';
                                      }
                                      if (v == '123456789') {
                                        return 'No puedes usar la contraseña por defecto';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Confirmar contraseña
                                  TextFormField(
                                    controller: _confirmController,
                                    obscureText: _obscureConfirm,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      labelText: 'Confirmar contraseña',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  _obscureConfirm =
                                                      !_obscureConfirm,
                                            ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.04,
                                              )
                                              : Colors.grey.shade50,
                                    ),
                                    validator:
                                        (v) =>
                                            v != _passwordController.text
                                                ? 'Las contraseñas no coinciden'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Indicadores de validación
                                  _buildValidationRow(
                                    'Mínimo 6 caracteres',
                                    _hasMinLength,
                                    _passwordController.text.isNotEmpty,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildValidationRow(
                                    'No es la contraseña por defecto',
                                    _isNotDefault,
                                    _passwordController.text.isNotEmpty,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildValidationRow(
                                    'Las contraseñas coinciden',
                                    _passwordsMatch,
                                    _confirmController.text.isNotEmpty,
                                  ),

                                  // Error
                                  if (_error != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),

                                  // Botón
                                  SizedBox(
                                    height: 50,
                                    child:
                                        _isLoading
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : FilledButton.icon(
                                              onPressed: _changePassword,
                                              icon: const Icon(
                                                Icons.security_rounded,
                                              ),
                                              label: const Text(
                                                'Actualizar contraseña',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: FilledButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationRow(String text, bool isValid, bool hasInput) {
    final color =
        !hasInput
            ? Colors.grey
            : isValid
            ? Colors.green
            : Colors.red.shade400;
    final icon =
        !hasInput
            ? Icons.circle_outlined
            : isValid
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
