import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// =============================================================================
/// LOGIN SCREEN - Estilo "Workspace Pro"
/// =============================================================================
/// Diseño inspirado en Notion/Slack con split-screen en desktop,
/// gradientes sutiles y animaciones fluidas.
/// =============================================================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isLoading = false;
  String? _message;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

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
        _userController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (loginEntity != null) {
        if (loginEntity.versionApp != AppConstants.APP_VERSION) {
          context.go('/change-password', extra: loginEntity);
        } else {
          ref.read(userProvider.notifier).setUser(loginEntity);
          context.go('/dashboard');
        }
      } else {
        setState(() => _message = message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Error de conexión');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = ref.watch(themeNotifierProvider);
    final isDark = appTheme.isDarkMode;
    final selectedColorIndex = appTheme.selectedColor;
    final accentColor = colorScheme.primary;
    final onAccent = colorScheme.onPrimary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    // Colores del tema
    final bgPrimary =
        isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF);
    final bgSecondary =
        isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF191919);
    final textSecondary =
        isDark ? const Color(0xFF8A8A8A) : const Color(0xFF6B6B6B);
    final borderColor =
        isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE8E8E8);

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child:
            isWide
                ? Row(
                  children: [
                    // Panel izquierdo - Branding
                    Expanded(
                      flex: 5,
                      child: _buildBrandingPanel(
                        isDark,
                        accentColor,
                        onAccent,
                        textPrimary,
                        textSecondary,
                      ),
                    ),
                    // Divider sutil
                    Container(width: 1, color: borderColor),
                    // Panel derecho - Form
                    Expanded(
                      flex: 4,
                      child: _buildFormPanel(
                        isDark,
                        accentColor,
                        onAccent,
                        bgPrimary,
                        bgSecondary,
                        textPrimary,
                        textSecondary,
                        borderColor,
                        selectedColorIndex,
                      ),
                    ),
                  ],
                )
                : _buildMobileLayout(
                  isDark,
                  accentColor,
                  onAccent,
                  bgPrimary,
                  bgSecondary,
                  textPrimary,
                  textSecondary,
                  borderColor,
                  selectedColorIndex,
                ),
      ),
    );
  }

  Widget _buildBrandingPanel(
    bool isDark,
    Color accentColor,
    Color onAccent,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    const Color(0xFF0D0D0D),
                    accentColor.withValues(alpha: 0.08),
                  ]
                  : [
                    const Color(0xFFFAFAFA),
                    accentColor.withValues(alpha: 0.05),
                  ],
        ),
      ),
      child: Stack(
        children: [
          // Patrón de fondo
          Positioned.fill(child: _buildGridPattern(accentColor, isDark)),

          // Contenido centrado
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono animado
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.forest_rounded,
                            color: onAccent,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Bosque',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Sistema integral de gestión empresarial',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Feature pills
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFeaturePill(
                        'Logística',
                        Icons.local_shipping_rounded,
                        accentColor,
                        isDark,
                      ),
                      _buildFeaturePill(
                        'RRHH',
                        Icons.people_rounded,
                        accentColor,
                        isDark,
                      ),
                      _buildFeaturePill(
                        'Finanzas',
                        Icons.account_balance_wallet_rounded,
                        accentColor,
                        isDark,
                      ),
                      _buildFeaturePill(
                        'Combustible',
                        Icons.local_gas_station_rounded,
                        accentColor,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(
    String label,
    IconData icon,
    Color accent,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE8E8E8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF4A4A4A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridPattern(Color accent, bool isDark) {
    return CustomPaint(
      painter: _GridPatternPainter(
        color: accent.withValues(alpha: isDark ? 0.03 : 0.04),
      ),
    );
  }

  Widget _buildFormPanel(
    bool isDark,
    Color accentColor,
    Color onAccent,
    Color bgPrimary,
    Color bgSecondary,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    int selectedColorIndex,
  ) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con controles de tema
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido!',
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
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Theme controls
                      Row(
                        children: [
                          _buildThemeButton(
                            onTap:
                                () => _showColorPicker(
                                  context,
                                  ref,
                                  selectedColorIndex,
                                ),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                          const SizedBox(width: 8),
                          _buildThemeButton(
                            onTap:
                                () =>
                                    ref
                                        .read(themeNotifierProvider.notifier)
                                        .toggleDarkMode(),
                            child: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              size: 18,
                              color: textSecondary,
                            ),
                            isDark: isDark,
                            borderColor: borderColor,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Input Usuario
                  _buildInputField(
                    controller: _userController,
                    focusNode: _userFocus,
                    label: 'Usuario',
                    hint: 'tu.usuario',
                    icon: Icons.alternate_email_rounded,
                    onSubmit: () => _passwordFocus.requestFocus(),
                    isDark: isDark,
                    accentColor: accentColor,
                    bgSecondary: bgSecondary,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),

                  const SizedBox(height: 20),

                  // Input Contraseña
                  _buildInputField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    label: 'Contraseña',
                    hint: '••••••••',
                    icon: Icons.lock_rounded,
                    isPassword: true,
                    onSubmit: _login,
                    isDark: isDark,
                    accentColor: accentColor,
                    bgSecondary: bgSecondary,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),

                  // Error message
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: onAccent,
                        disabledBackgroundColor: accentColor.withValues(
                          alpha: 0.6,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: onAccent,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Center(
                    child: Text(
                      'ESPPAPEL • v${AppConstants.APP_VERSION}',
                      style: TextStyle(
                        color: textSecondary.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
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

  Widget _buildMobileLayout(
    bool isDark,
    Color accentColor,
    Color onAccent,
    Color bgPrimary,
    Color bgSecondary,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    int selectedColorIndex,
  ) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Logo compacto
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.forest_rounded, color: onAccent, size: 36),
              ),

              const SizedBox(height: 20),

              Text(
                'Bosque',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Gestión empresarial',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151515) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                            _buildThemeButton(
                              onTap:
                                  () => _showColorPicker(
                                    context,
                                    ref,
                                    selectedColorIndex,
                                  ),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              isDark: isDark,
                              borderColor: borderColor,
                              size: 36,
                            ),
                            const SizedBox(width: 8),
                            _buildThemeButton(
                              onTap:
                                  () =>
                                      ref
                                          .read(themeNotifierProvider.notifier)
                                          .toggleDarkMode(),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                size: 16,
                                color: textSecondary,
                              ),
                              isDark: isDark,
                              borderColor: borderColor,
                              size: 36,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Input Usuario
                    _buildInputField(
                      controller: _userController,
                      focusNode: _userFocus,
                      label: 'Usuario',
                      hint: 'tu.usuario',
                      icon: Icons.alternate_email_rounded,
                      onSubmit: () => _passwordFocus.requestFocus(),
                      isDark: isDark,
                      accentColor: accentColor,
                      bgSecondary: bgSecondary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 16),

                    // Input Contraseña
                    _buildInputField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: 'Contraseña',
                      hint: '••••••••',
                      icon: Icons.lock_rounded,
                      isPassword: true,
                      onSubmit: _login,
                      isDark: isDark,
                      accentColor: accentColor,
                      bgSecondary: bgSecondary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      borderColor: borderColor,
                    ),

                    // Error message
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _message!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: onAccent,
                          disabledBackgroundColor: accentColor.withValues(
                            alpha: 0.6,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                  'Continuar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'v${AppConstants.APP_VERSION}',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeButton({
    required VoidCallback onTap,
    required Widget child,
    required bool isDark,
    required Color borderColor,
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onSubmit,
    required bool isDark,
    required Color accentColor,
    required Color bgSecondary,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword ? _obscurePassword : false,
            onSubmitted: (_) => onSubmit(),
            style: TextStyle(color: textPrimary, fontSize: 14),
            cursorColor: accentColor,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: textSecondary, size: 20),
              suffixIcon:
                  isPassword
                      ? GestureDetector(
                        onTap:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textSecondary,
                          size: 20,
                        ),
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, int currentIndex) {
    final isDark = ref.read(themeNotifierProvider).isDarkMode;
    final accentColor = colorList[currentIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
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
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: accentColor,
                      size: 22,
                    ),
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

/// Painter para el patrón de grilla del panel de branding
class _GridPatternPainter extends CustomPainter {
  final Color color;

  _GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
