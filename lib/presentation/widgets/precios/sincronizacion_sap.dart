/// La sincronizacion de grupos de familia y proveedores con SAP
/// (`p_abm_producto 'H'`), vista desde dos lugares:
///
/// * la ficha de una familia, que la dispara sola la primera vez que se abre en
///   la sesion -el sistema anterior la corria al abrir la pantalla de precios-
///   y muestra una linea con el estado, para que un grupo recien creado en SAP
///   no parezca faltar mientras se consulta;
/// * Catalogos, en las pestanias de grupos y proveedores, con un boton para
///   traerlos a pedido.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

const _textoAlDia = 'Grupos y proveedores al día con SAP';

/// La linea de estado de la ficha. No dibuja nada mientras no corrio.
class LineaSincronizacionSap extends ConsumerWidget {
  const LineaSincronizacionSap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sincronizacionSapProvider);
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    final (Widget icono, String texto, Widget? accion) = switch (estado.fase) {
      FaseSincronizacionSap.sinCorrer => (const SizedBox.shrink(), '', null),
      FaseSincronizacionSap.corriendo => (
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        'Buscando grupos y proveedores nuevos en SAP…',
        null,
      ),
      FaseSincronizacionSap.lista => (
        Icon(Icons.cloud_done_outlined, size: 16, color: cs.primary),
        _textoAlDia,
        null,
      ),
      FaseSincronizacionSap.fallo => (
        Icon(Icons.cloud_off_outlined, size: 16, color: cs.error),
        'No se pudo consultar SAP: se muestran los grupos y proveedores '
            'guardados.',
        TextButton(
          onPressed:
              () => ref.read(sincronizacionSapProvider.notifier).correr(),
          child: const Text('Reintentar'),
        ),
      ),
    };
    if (estado.fase == FaseSincronizacionSap.sinCorrer) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Esp.s),
      child: Row(
        children: [
          icono,
          const SizedBox(width: Esp.s),
          Expanded(child: Text(texto, style: estilo)),
          if (accion != null) accion,
        ],
      ),
    );
  }
}

/// El boton de Catalogos. En un cajon angosto es solo el icono.
class BotonSincronizarSap extends ConsumerWidget {
  const BotonSincronizarSap({super.key, required this.compacto});

  final bool compacto;

  Future<void> _traer(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(sincronizacionSapProvider.notifier);
    final ok = await notifier.correr();
    if (!context.mounted) return;
    if (ok) {
      mostrarAviso(context, '$_textoAlDia.');
    } else {
      final error = ref.read(sincronizacionSapProvider).error;
      if (error != null) {
        mostrarAviso(context, textoParaUsuario(error), tono: TonoAviso.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corriendo =
        ref.watch(sincronizacionSapProvider).fase ==
        FaseSincronizacionSap.corriendo;
    const espera = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    final onPressed = corriendo ? null : () => _traer(context, ref);

    if (compacto) {
      return IconButton(
        onPressed: onPressed,
        tooltip: 'Traer grupos y proveedores nuevos de SAP',
        icon: corriendo ? espera : const Icon(Icons.cloud_sync_outlined),
      );
    }
    return Tooltip(
      message: 'Trae de SAP los grupos de familia y proveedores nuevos',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon:
            corriendo
                ? espera
                : const Icon(Icons.cloud_sync_outlined, size: 18),
        label: Text(corriendo ? 'Consultando SAP…' : 'Traer de SAP'),
      ),
    );
  }
}
