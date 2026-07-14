import 'dart:math' as math;

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Mensaje mostrado cuando el dispositivo no puede persistir la sesión
/// (Keystore que no escribe en ciertos Android). Evita el bucle de login.
const String _msgErrorPersistencia =
    'No se pudo guardar tu sesión en este dispositivo. '
    'Cierra otras apps o reinicia el teléfono e inténtalo de nuevo.';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  late AnimationController _entryController;
  late AnimationController _orbController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  bool _isLoading = false;
  String? _message;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _entryController.forward();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _orbController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Login logic ──────────────────────────────────────────────────────────

  void _login() async {
    if (_userController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _message = 'Completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final (loginEntity, message) = await _authRepository.login(
        _userController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (loginEntity != null) {
        if (loginEntity.versionApp != AppConstants.APP_VERSION) {
          setState(
            () =>
                _message =
                    'Tu versión de la app (${AppConstants.APP_VERSION}) está desactualizada. '
                    'Por favor actualiza a la versión ${loginEntity.versionApp} para continuar.',
          );
          return;
        } else if (_passwordController.text == '123456789') {
          // Contraseña por defecto, obligar cambio
          final ok = await ref.read(userProvider.notifier).setUser(loginEntity);
          if (!mounted) return;
          if (!ok) {
            setState(() => _message = _msgErrorPersistencia);
            return;
          }
          context.go('/change-password', extra: loginEntity);
        } else {
          // await: la escritura de user_data/token debe completarse ANTES de
          // navegar, o el redirect del router puede leer storage vacío y rebotar.
          final ok = await ref.read(userProvider.notifier).setUser(loginEntity);
          if (!mounted) return;
          if (!ok) {
            // El dispositivo no pudo guardar la sesión (Keystore). Evita el
            // bucle de login silencioso mostrando un mensaje claro.
            setState(() => _message = _msgErrorPersistencia);
            return;
          }
          context.go('/dashboard');
        }
      } else {
        setState(() => _message = message);
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'Error de conexión');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appTheme = ref.watch(themeNotifierProvider);
    final isDark = appTheme.isDarkMode;
    final accent = cs.primary;
    final onAccent = cs.onPrimary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    final textPrimary = isDark ? Colors.white : const Color(0xFF111111);
    final textMuted =
        isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF888888);
    final inputBg =
        isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF4F4F5);
    final inputBorder =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE4E4E7);
    final borderCol =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Background(isDark: isDark, accent: accent),
          _FloatingOrbs(
            controller: _orbController,
            accent: accent,
            isDark: isDark,
          ),
          SafeArea(
            child:
                isWide
                    ? Row(
                      children: [
                        // ── Panel izquierdo: Branding ──
                        Expanded(
                          flex: 5,
                          child: _buildBrandingPanel(
                            isDark,
                            accent,
                            textPrimary,
                            textMuted,
                          ),
                        ),
                        // Divider sutil
                        Container(width: 1, color: borderCol),
                        // ── Panel derecho: Form ──
                        Expanded(
                          flex: 4,
                          child: FadeTransition(
                            opacity: _fadeIn,
                            child: SlideTransition(
                              position: _slideUp,
                              child: _buildFormPanel(
                                isDark,
                                accent,
                                onAccent,
                                appTheme,
                                textPrimary,
                                textMuted,
                                inputBg,
                                inputBorder,
                                borderCol,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    : FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: _buildMobileLayout(
                          isDark,
                          accent,
                          onAccent,
                          appTheme,
                          textPrimary,
                          textMuted,
                          inputBg,
                          inputBorder,
                          borderCol,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // ── Panel de branding (izquierdo en desktop) ─────────────────────────────

  Widget _buildBrandingPanel(
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textMuted,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo grande con entrada elástica
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: _AnimatedLogo(
                accent: accent,
                isDark: isDark,
                size: 110,
                iconSize: 60,
              ),
            ),

            const SizedBox(height: 36),

            Text(
              'Bosque',
              style: TextStyle(
                color: textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'powered by Esppapel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 15,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Panel de formulario (derecho en desktop) ─────────────────────────────

  Widget _buildFormPanel(
    bool isDark,
    Color accent,
    Color onAccent,
    AppTheme appTheme,
    Color textPrimary,
    Color textMuted,
    Color inputBg,
    Color inputBorder,
    Color borderCol,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + theme controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _ThemeChip(
                        onTap:
                            () => _showColorPicker(
                              context,
                              ref,
                              appTheme.selectedColor,
                            ),
                        isDark: isDark,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ThemeChip(
                        onTap:
                            () =>
                                ref
                                    .read(themeNotifierProvider.notifier)
                                    .toggleDarkMode(),
                        isDark: isDark,
                        child: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 16,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 36),

              _buildFormFields(
                isDark,
                accent,
                onAccent,
                textPrimary,
                textMuted,
                inputBg,
                inputBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Layout mobile (card centrado) ────────────────────────────────────────

  Widget _buildMobileLayout(
    bool isDark,
    Color accent,
    Color onAccent,
    AppTheme appTheme,
    Color textPrimary,
    Color textMuted,
    Color inputBg,
    Color inputBorder,
    Color borderCol,
  ) {
    final cardBg =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.85);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Logo compacto
          _AnimatedLogo(accent: accent, isDark: isDark),

          const SizedBox(height: 20),

          Text(
            'Bosque',
            style: TextStyle(
              color: textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'powered by Esppapel',
            style: TextStyle(
              color: textMuted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 32),

          // Form card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con controles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        _ThemeChip(
                          onTap:
                              () => _showColorPicker(
                                context,
                                ref,
                                appTheme.selectedColor,
                              ),
                          isDark: isDark,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ThemeChip(
                          onTap:
                              () =>
                                  ref
                                      .read(themeNotifierProvider.notifier)
                                      .toggleDarkMode(),
                          isDark: isDark,
                          child: Icon(
                            isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            size: 15,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildFormFields(
                  isDark,
                  accent,
                  onAccent,
                  textPrimary,
                  textMuted,
                  inputBg,
                  inputBorder,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'v${AppConstants.APP_VERSION}',
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Campos de formulario (compartidos) ───────────────────────────────────

  Widget _buildFormFields(
    bool isDark,
    Color accent,
    Color onAccent,
    Color textPrimary,
    Color textMuted,
    Color inputBg,
    Color inputBorder,
  ) {
    return Column(
      children: [
        _InputField(
          controller: _userController,
          focusNode: _userFocus,
          hint: 'Usuario',
          icon: Icons.person_outline_rounded,
          onSubmit: () => _passwordFocus.requestFocus(),
          isDark: isDark,
          accent: accent,
          bgColor: inputBg,
          borderColor: inputBorder,
          textColor: textPrimary,
          hintColor: textMuted,
        ),
        const SizedBox(height: 14),

        _InputField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          hint: 'Contraseña',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: _obscurePassword,
          onToggleObscure:
              () => setState(() => _obscurePassword = !_obscurePassword),
          onSubmit: _login,
          isDark: isDark,
          accent: accent,
          bgColor: inputBg,
          borderColor: inputBorder,
          textColor: textPrimary,
          hintColor: textMuted,
        ),

        // Error
        if (_message != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? const Color(0xFFDC2626).withValues(alpha: 0.25)
                      : const Color(0xFFDC2626).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark
                        ? const Color(0xFFFF6B6B).withValues(alpha: 0.5)
                        : const Color(0xFFDC2626).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color:
                      isDark
                          ? const Color(0xFFFFAAAA)
                          : const Color(0xFFDC2626),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color:
                          isDark
                              ? const Color(0xFFFFCCCC)
                              : const Color(0xFFDC2626),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: onAccent,
              disabledBackgroundColor: accent.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: onAccent,
                      ),
                    )
                    : const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
          ),
        ),

        const SizedBox(height: 24),

        // Footer
        Center(
          child: Text(
            'ESPPAPEL  •  v${AppConstants.APP_VERSION}',
            style: TextStyle(
              color: textMuted.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  // ── Color Picker ─────────────────────────────────────────────────────────

  void _showColorPicker(BuildContext context, WidgetRef ref, int currentIndex) {
    final isDark = ref.read(themeNotifierProvider).isDarkMode;
    final accent = colorList[currentIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.palette_rounded, color: accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Color del tema',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Elige tu color favorito',
                        style: TextStyle(
                          color:
                              isDark
                                  ? const Color(0xFF888888)
                                  : const Color(0xFF666666),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List.generate(
                  colorList.length,
                  (index) => GestureDetector(
                    onTap: () {
                      ref
                          .read(themeNotifierProvider.notifier)
                          .changeColorIndex(index);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorList[index],
                        borderRadius: BorderRadius.circular(16),
                        border:
                            currentIndex == index
                                ? Border.all(
                                  color: isDark ? Colors.white : Colors.black,
                                  width: 3,
                                )
                                : null,
                        boxShadow: [
                          BoxShadow(
                            color: colorList[index].withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child:
                          currentIndex == index
                              ? Icon(
                                Icons.check_rounded,
                                color:
                                    ThemeData.estimateBrightnessForColor(
                                              colorList[index],
                                            ) ==
                                            Brightness.light
                                        ? Colors.black
                                        : Colors.white,
                                size: 26,
                              )
                              : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS PRIVADOS
// ═══════════════════════════════════════════════════════════════════════════════

/// Fondo con gradiente adaptativo
class _Background extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _Background({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF111118),
                    accent.withValues(alpha: 0.08),
                  ]
                  : [
                    const Color(0xFFF8F9FC),
                    const Color(0xFFEEF0F7),
                    accent.withValues(alpha: 0.06),
                  ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Orbes flotantes animados (decoración sutil)
class _FloatingOrbs extends StatelessWidget {
  final AnimationController controller;
  final Color accent;
  final bool isDark;

  const _FloatingOrbs({
    required this.controller,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value * 2 * math.pi;
          return Stack(
            children: [
              Positioned(
                top: 80 + 30 * math.sin(t),
                right: 40 + 20 * math.cos(t),
                child: _orb(
                  120,
                  accent.withValues(alpha: isDark ? 0.06 : 0.08),
                ),
              ),
              Positioned(
                bottom: 100 + 20 * math.cos(t + 1),
                left: 30 + 25 * math.sin(t + 2),
                child: _orb(90, accent.withValues(alpha: isDark ? 0.04 : 0.06)),
              ),
              Positioned(
                top: size.height * 0.4 + 15 * math.sin(t + 3),
                left: size.width * 0.7 + 18 * math.cos(t + 1),
                child: _orb(60, accent.withValues(alpha: isDark ? 0.05 : 0.07)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Logo SVG animado con pulso sutil
class _AnimatedLogo extends StatefulWidget {
  final Color accent;
  final bool isDark;
  final double size;
  final double iconSize;

  const _AnimatedLogo({
    required this.accent,
    required this.isDark,
    this.size = 80,
    this.iconSize = 44,
  });

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 1.0 + 0.04 * math.sin(_ctrl.value * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.accent, widget.accent.withValues(alpha: 0.75)],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(widget.size * 0.25),
            child: SvgPicture.asset(
              'assets/icon/bosque_logo.svg',
              fit: BoxFit.contain,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de control de tema
class _ThemeChip extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final Widget child;

  const _ThemeChip({
    required this.onTap,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Campo de input limpio
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final VoidCallback onSubmit;
  final bool isDark;
  final Color accent;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color hintColor;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscure = true,
    this.onToggleObscure,
    required this.onSubmit,
    required this.isDark,
    required this.accent,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword ? obscure : false,
        onSubmitted: (_) => onSubmit(),
        style: TextStyle(color: textColor, fontSize: 14),
        cursorColor: accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 14),
          prefixIcon: Icon(icon, color: hintColor, size: 20),
          suffixIcon:
              isPassword
                  ? GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: hintColor,
                      size: 20,
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
