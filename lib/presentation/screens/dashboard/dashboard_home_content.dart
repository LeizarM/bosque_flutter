import 'dart:math' as math;

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/widgets/shared/confetti_widget.dart';
import 'package:bosque_flutter/presentation/widgets/shared/docs_vencidos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dashboard home con diseño moderno y confeti en cumpleaños
class DashboardHomeContent extends ConsumerStatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  ConsumerState<DashboardHomeContent> createState() =>
      _DashboardHomeContentState();
}

class _DashboardHomeContentState extends ConsumerState<DashboardHomeContent>
    with SingleTickerProviderStateMixin {
  bool _showConfetti = false;
  bool _confettiChecked = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  IconData get _greetingIcon {
    final h = DateTime.now().hour;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 18) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  String get _formattedDate {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${now.day} de ${_months[now.month - 1]}';
  }

  Future<void> _checkAndShowConfetti(List<String> msgs) async {
    if (_confettiChecked || msgs.isEmpty) return;
    _confettiChecked = true;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = 'confetti_bday_${now.year}_${now.month}_${now.day}';

    if (!(prefs.getBool(key) ?? false)) {
      await prefs.setBool(key, true);
      if (mounted) setState(() => _showConfetti = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cumpleMensajesInitProvider);
    final user = ref.watch(userProvider);
    final cumpleMensajes = ref.watch(cumpleMensajesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 700;
    // 1. ¿Hay datos de documentos para mostrar?
    final docsState = ref.watch(docsVencidosProvider);
    final tieneDatosDocs =
        docsState.cargando ||
        docsState.mensajeError != null ||
        docsState.items.isNotEmpty;

    // 2. ¿El usuario tiene permiso? (Misma lógica de PermissionWidget)
    ref.watch(
      buttonPermissionsProvider,
    ); // Escuchamos el estado para que se redibuje si cargan los permisos

    final tienePermisoDocs =
        (user != null && user.tipoUsuario == 'ROLE_ADM') ||
        ref
            .read(buttonPermissionsProvider.notifier)
            .tienePermiso('btnDocsVencidos');

    // Si tiene ambas cosas, lo mostramos.
    final mostrarDocs = tieneDatosDocs && tienePermisoDocs;
    if (cumpleMensajes.isNotEmpty && !_confettiChecked) {
      _checkAndShowConfetti(cumpleMensajes);
    }

    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text('No hay datos de usuario disponibles'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // ─── Fondo decorativo con formas sutiles ───
        Positioned.fill(
          child: CustomPaint(
            painter: _BackgroundPatternPainter(
              color: primary.withValues(alpha: isDark ? 0.03 : 0.02),
            ),
          ),
        ),

        // ─── Contenido principal ───
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 40 : 20,
            vertical: isWide ? 32 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Hero Card ───
              _buildHeroCard(context, user, primary, isDark, isWide),

              const SizedBox(height: 10),

              // ─── Cumpleaños celebración ───
              if (isWide && cumpleMensajes.isNotEmpty && mostrarDocs)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Docs ocupa 3/5 del ancho
                    const Expanded(
                      flex: 3,
                      child: DocsVencidosDashboardWidget(),
                    ),
                    const SizedBox(width: 16),
                    // Cumpleaños ocupa 2/5
                    Expanded(
                      flex: 2,
                      child: _buildBirthdaySection(
                        context,
                        cumpleMensajes,
                        primary,
                        isDark,
                        isWide,
                      ),
                    ),
                  ],
                )
              else ...[
                // Si la pantalla es pequeña, o si falta alguno de los widgets, caen aquí en formato columna:
                if (mostrarDocs) const DocsVencidosDashboardWidget(),

                // Solo ponemos el separador si AMBOS widgets se van a dibujar apilados
                if (mostrarDocs && cumpleMensajes.isNotEmpty)
                  const SizedBox(height: 20),

                if (cumpleMensajes.isNotEmpty)
                  _buildBirthdaySection(
                    context,
                    cumpleMensajes,
                    primary,
                    isDark,
                    isWide,
                  ),
              ],
            ],
          ),
        ),

        // ─── Confeti overlay ───
        if (_showConfetti)
          Positioned.fill(
            child: ConfettiOverlay(
              play: true,
              onComplete: () {
                if (mounted) setState(() => _showConfetti = false);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    dynamic user,
    Color primary,
    bool isDark,
    bool isWide,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors:
              isDark
                  ? [
                    primary.withValues(alpha: 0.2),
                    primary.withValues(alpha: 0.06),
                  ]
                  : [
                    primary.withValues(alpha: 0.1),
                    primary.withValues(alpha: 0.02),
                  ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decoración: círculos del fondo
            Positioned(
              right: -30,
              top: -30,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale =
                      1.0 + 0.06 * math.sin(_pulseController.value * math.pi);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: isDark ? 0.08 : 0.05),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 60,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: isDark ? 0.06 : 0.03),
                ),
              ),
            ),

            // Contenido
            Padding(
              padding: EdgeInsets.all(isWide ? 32 : 24),
              child:
                  isWide
                      ? Row(
                        children: [
                          Expanded(
                            child: _buildHeroText(
                              context,
                              user,
                              primary,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 24),
                          _buildHeroLogo(primary, isDark, 72),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildGreetingChip(primary, isDark),
                                    const SizedBox(height: 12),
                                    Text(
                                      user.nombreCompleto,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildHeroLogo(primary, isDark, 56),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDateChip(primary, isDark),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroText(
    BuildContext context,
    dynamic user,
    Color primary,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGreetingChip(primary, isDark),
        const SizedBox(height: 14),
        Text(
          user.nombreCompleto,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        _buildDateChip(primary, isDark),
      ],
    );
  }

  Widget _buildGreetingChip(Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_greetingIcon, size: 16, color: primary),
          const SizedBox(width: 6),
          Text(
            _greeting,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(Color primary, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 14,
          color: isDark ? Colors.white54 : Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        Text(
          _formattedDate,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroLogo(Color primary, bool isDark, double size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = 0.2 + 0.1 * math.sin(_pulseController.value * math.pi);
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: glow),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/icon/bosque_logo.svg',
            fit: BoxFit.contain,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
        );
      },
    );
  }

  // ─── Sección de cumpleaños ───
  Widget _buildBirthdaySection(
    BuildContext context,
    List<String> mensajes,
    Color primary,
    bool isDark,
    bool isWide,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors:
              isDark
                  ? [const Color(0xFF2D1B4E), const Color(0xFF1A2636)]
                  : [const Color(0xFFFFF3E0), const Color(0xFFFCE4EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color:
              isDark
                  ? const Color(0xFF6C3483).withValues(alpha: 0.3)
                  : const Color(0xFF6C3483).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF6C3483,
            ).withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decoración festiva
            Positioned(
              right: -10,
              top: -10,
              child: Text(
                '🎂',
                style: TextStyle(
                  fontSize: isWide ? 80 : 56,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: isWide ? 300 : 150,
              bottom: -5,
              child: Text(
                '🎉',
                style: TextStyle(
                  fontSize: isWide ? 48 : 32,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(isWide ? 28 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6C3483,
                          ).withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🎂', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hoy celebramos cumpleaños!',
                              style: TextStyle(
                                fontSize: isWide ? 20 : 17,
                                fontWeight: FontWeight.w700,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF4A148C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${mensajes.length} ${mensajes.length == 1 ? 'persona celebra' : 'personas celebran'} hoy',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark
                                        ? Colors.white60
                                        : const Color(
                                          0xFF6C3483,
                                        ).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            () =>
                                ref
                                    .read(cumpleMensajesProvider.notifier)
                                    .state = [],
                        icon: Icon(
                          Icons.close_rounded,
                          color:
                              isDark
                                  ? Colors.white54
                                  : const Color(
                                    0xFF6C3483,
                                  ).withValues(alpha: 0.5),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Lista de cumpleañeros
                  ...mensajes.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final msg = entry.value;
                    // Limpiar el emoji del inicio si lo tiene
                    final cleanMsg =
                        msg.startsWith('🎉 ') ? msg.substring(3) : msg;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: idx < mensajes.length - 1 ? 10 : 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(
                                      0xFF6C3483,
                                    ).withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF6C3483,
                                    ).withValues(alpha: 0.15),
                                    const Color(
                                      0xFFE91E63,
                                    ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cleanMsg,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : const Color(0xFF37474F),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),
                  // Felicidades footer
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(
                              0xFF6C3483,
                            ).withValues(alpha: isDark ? 0.2 : 0.1),
                            const Color(
                              0xFFE91E63,
                            ).withValues(alpha: isDark ? 0.15 : 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🥳', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            '¡Felicidades!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? Colors.white70
                                      : const Color(0xFF6C3483),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🎊', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinta un patrón sutil de puntos en el fondo del dashboard
class _BackgroundPatternPainter extends CustomPainter {
  final Color color;
  _BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter old) =>
      old.color != color;
}
