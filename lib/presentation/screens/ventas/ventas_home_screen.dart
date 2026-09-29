import 'package:bosque_flutter/core/state/ventas_ciudades_provider.dart';
import 'package:bosque_flutter/presentation/widgets/ventas/venta_articulos_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

/// Catálogo de Ventas. Qué ciudades puede ver el usuario lo decide el backend
/// (`/paginaXApp/ciudadesPermitidas`), no la ciudad guardada en el login.
class VentasHomeScreen extends ConsumerWidget {
  const VentasHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permitidas = ref.watch(ciudadesPermitidasProvider);

    return Scaffold(
      body: ResponsiveBreakpoints(
        breakpoints: ResponsiveUtilsBosque.breakpoints,
        child: permitidas.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => _Aviso(
                icono: Icons.cloud_off_rounded,
                titulo: 'No se pudieron cargar sus ciudades',
                detalle: e.toString().replaceFirst('Exception: ', ''),
                onReintentar: () => ref.invalidate(ciudadesPermitidasProvider),
              ),
          data: (p) {
            if (p.ciudades.isEmpty) {
              return const _Aviso(
                icono: Icons.location_off_rounded,
                titulo: 'No tiene ciudades asignadas',
                detalle:
                    'Pida a un administrador que le asigne las ciudades cuyos '
                    'precios y stock debe ver.',
              );
            }
            return VentasArticulosView(permitidas: p);
          },
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback? onReintentar;

  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
