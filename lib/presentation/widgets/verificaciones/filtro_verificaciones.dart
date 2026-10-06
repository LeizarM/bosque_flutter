/// El filtro de la lista principal de «Verificar Cheques»: el dia de la
/// verificacion (hoy al abrir, como en el legacy) y «Buscar». Quitar la fecha
/// pide todas las verificaciones. [AvisoSinVerificar] dice cuantos cheques
/// esperan una verificacion y abre el modal para elegirlos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

/// Desde este ancho el campo, «Buscar» y «Hoy» van en una sola fila.
const double _anchoEnFila = 560;

class FiltroVerificaciones extends ConsumerStatefulWidget {
  const FiltroVerificaciones({super.key});

  @override
  ConsumerState<FiltroVerificaciones> createState() =>
      _FiltroVerificacionesState();
}

class _FiltroVerificacionesState extends ConsumerState<FiltroVerificaciones> {
  /// Lo que se esta escribiendo; solo se aplica con «Buscar».
  DateTime? _fecha;

  @override
  void initState() {
    super.initState();
    // Al volver a la pantalla (o si el estado ya tenia un dia) el campo lo sigue.
    _fecha = ref.read(grillaVerificacionesProvider).fechaBanco;
  }

  GrillaVerificacionesNotifier get _grilla =>
      ref.read(grillaVerificacionesProvider.notifier);

  void _buscar() => _grilla.buscarPorFecha(_fecha);

  void _hoy() {
    final hoy = _grilla.hoy;
    setState(() => _fecha = hoy);
    _grilla.buscarPorFecha(hoy);
  }

  @override
  Widget build(BuildContext context) {
    // El dia aplicado cambio por fuera de este panel («Ver todas» del listado
    // vacio): el campo lo sigue.
    ref.listen<DateTime?>(
      grillaVerificacionesProvider.select((s) => s.fechaBanco),
      (previo, nuevo) {
        if (previo != nuevo && _fecha != nuevo) setState(() => _fecha = nuevo);
      },
    );
    final cs = Theme.of(context).colorScheme;

    final campo = CampoFechaCheque(
      etiqueta: 'Fecha de verificación',
      valor: _fecha,
      obligatorio: false,
      permiteQuitar: true,
      ayuda: 'Sin fecha se piden todas.',
      onCambio: (f) => setState(() => _fecha = f),
    );
    final buscar = FilledButton.tonalIcon(
      key: const ValueKey('boton-buscar'),
      onPressed: _buscar,
      icon: const Icon(Icons.search, size: 18),
      label: const Text('Buscar'),
    );
    final hoy = TextButton.icon(
      key: const ValueKey('boton-hoy'),
      onPressed: _hoy,
      icon: const Icon(Icons.today_outlined, size: 18),
      label: const Text('Hoy'),
    );

    return LayoutBuilder(
      builder: (context, c) {
        final enFila = c.maxWidth >= _anchoEnFila;
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Color.alphaBlend(
            cs.primary.withValues(alpha: 0.04),
            cs.surfaceContainerLow,
          ),
          shape: contornoSuperficie(cs),
          child: Padding(
            padding: const EdgeInsets.all(Esp.m),
            child:
                enFila
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 260, child: campo),
                        const SizedBox(width: Esp.m),
                        // Alineado con el campo, no con su texto de ayuda.
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: buscar,
                        ),
                        const SizedBox(width: Esp.s),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: hoy,
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        campo,
                        const SizedBox(height: Esp.s),
                        Wrap(
                          spacing: Esp.s,
                          runSpacing: Esp.s,
                          children: [buscar, hoy],
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }
}

/// «Mostrando las verificaciones del 03/10/2026»: el dia que se esta viendo, para
/// que nadie confunda una lista vacia de hoy con «no hay verificaciones».
class RangoActivoVerificaciones extends ConsumerWidget {
  const RangoActivoVerificaciones({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = ref.watch(grillaVerificacionesProvider.select((s) => s.fechaBanco));
    final texto =
        fecha == null
            ? 'Mostrando todas las verificaciones, de cualquier fecha.'
            : 'Mostrando las verificaciones del ${textoFecha(fecha)}.';
    return Padding(
      key: const ValueKey('rango-activo'),
      padding: const EdgeInsets.fromLTRB(Esp.xs, Esp.s, Esp.xs, 0),
      child: Row(
        children: [
          Icon(
            fecha == null ? Icons.all_inbox_outlined : Icons.event_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Esp.s),
          Expanded(child: Text(texto, style: context.apagado())),
        ],
      ),
    );
  }
}

/// Cuantos cheques esperan una verificacion, con el boton que abre el modal para
/// elegirlos. En aviso si hay pendientes; en exito si no queda ninguno. Si la
/// consulta falla o todavia no llego, no se dibuja nada: el modal tiene su
/// propio listado y su propio error.
class AvisoSinVerificar extends ConsumerWidget {
  const AvisoSinVerificar({super.key, required this.onVerificar});

  final VoidCallback onVerificar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(chequesSinVerificarProvider).valueOrNull;
    if (n == null) return const SizedBox.shrink();

    final hay = n > 0;
    final tono = hay ? SemanticaCheque.aviso : SemanticaCheque.exito;
    final letra = ChequesColores.texto(context, tono);
    final t = Theme.of(context).textTheme;

    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hay
              ? (n == 1
                  ? '1 cheque pendiente sin verificar'
                  : '$n cheques pendientes sin verificar')
              : 'No hay cheques pendientes sin verificar',
          style: t.titleSmall?.copyWith(color: letra, fontWeight: Peso.dato),
        ),
        const SizedBox(height: 2),
        Text(
          hay
              ? 'Tienen la fecha de cobranza de hoy o anterior y ninguna verificación válida.'
              : 'Todo cheque pendiente con cobranza hasta hoy ya tiene su verificación.',
          style: t.bodySmall?.copyWith(color: letra),
        ),
      ],
    );

    return Container(
      key: const ValueKey('aviso-sin-verificar'),
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: ChequesColores.fondo(context, tono),
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(
          color: ChequesColores.pleno(context, tono).withValues(alpha: 0.35),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final icono = Icon(
            hay ? Icons.pending_actions_outlined : Icons.check_circle_outline,
            color: letra,
          );
          final boton =
              hay
                  ? FilledButton.tonalIcon(
                    key: const ValueKey('boton-verificar-pendientes'),
                    onPressed: onVerificar,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: const Text('Verificar'),
                  )
                  : null;
          // Con poco ancho el boton baja bajo el texto en vez de apretarlo.
          if (c.maxWidth < 480 && boton != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icono,
                    const SizedBox(width: Esp.m),
                    Expanded(child: texto),
                  ],
                ),
                const SizedBox(height: Esp.s),
                boton,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icono,
              const SizedBox(width: Esp.m),
              Expanded(child: texto),
              if (boton != null) ...[const SizedBox(width: Esp.m), boton],
            ],
          );
        },
      ),
    );
  }
}
