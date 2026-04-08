import 'package:bosque_flutter/core/network/connectivity_service.dart';
import 'package:bosque_flutter/core/network/web_version_checker.dart';
import 'package:bosque_flutter/core/utils/web_reload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper que envuelve toda la app y muestra banners de conectividad
/// cuando la conexión es inestable o se pierde.
class ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  ConsumerState<ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  ConnectionStatus? _lastStatus;
  bool _bannerDismissedManually = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);

    // Cuando cambia el estado, resetear el dismiss manual
    if (_lastStatus != connectivity.status) {
      _bannerDismissedManually = false;
      _lastStatus = connectivity.status;
    }

    final showBanner =
        !_bannerDismissedManually &&
        (connectivity.status == ConnectionStatus.disconnected ||
            connectivity.status == ConnectionStatus.unstable);

    if (showBanner) {
      _animController.forward();
    } else {
      _animController.reverse();
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          // Banner de conectividad animado
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: _ConnectivityBanner(
                status: connectivity.status,
                message: connectivity.message,
                onRetry: () => ref.read(connectivityProvider.notifier).retry(),
                onDismiss: () {
                  setState(() => _bannerDismissedManually = true);
                },
              ),
            ),
          ),
          // Banner de nueva versión (solo web)
          if (kIsWeb) _UpdateBanner(),
        ],
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  final ConnectionStatus status;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _ConnectivityBanner({
    required this.status,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, textColor) = switch (status) {
      ConnectionStatus.disconnected => (
        Colors.red.shade700,
        Icons.wifi_off_rounded,
        Colors.white,
      ),
      ConnectionStatus.unstable => (
        Colors.orange.shade700,
        Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
        Colors.white,
      ),
      _ => (Colors.green.shade700, Icons.wifi_rounded, Colors.white),
    };

    return SafeArea(
      bottom: false,
      child: Material(
        elevation: 4,
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.refresh, color: textColor, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close, color: textColor, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner que aparece cuando se detecta una nueva versión en web.
/// Se posiciona en la parte inferior de la pantalla.
class _UpdateBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUpdate = ref.watch(webVersionProvider);
    if (!hasUpdate) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Material(
          elevation: 6,
          color: Colors.blue.shade700,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.system_update, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Nueva versión disponible',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: hardReloadWeb,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Actualizar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
