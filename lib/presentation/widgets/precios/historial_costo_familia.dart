/// El historial del costo de una familia: cada aprobacion que le cambio la
/// propuesta y, si cambio, el costo. Es el dialogo "Bitacora de costo /
/// propuesta" del sistema anterior, en simple: una lista, la mas reciente
/// arriba, con la variacion de cada cambio.
///
/// Sale de tb_bitacora, que registra esos cambios desde el 24/06/2025: lo
/// anterior no figura, y el dialogo lo dice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/historial_costo_familia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';
import 'package:bosque_flutter/presentation/widgets/precios/vista_preliminar_reporte.dart';

final DateFormat _fmtFecha = DateFormat('dd/MM/yyyy HH:mm');

const _notaOrigen =
    'Cada aprobación que cambió la propuesta de la familia. Se registra desde '
    'el 24/06/2025.';

/// Dialogo en escritorio, hoja en el telefono.
Future<void> mostrarHistorialCosto(BuildContext context, FamiliaVista familia) {
  final pantalla = MediaQuery.sizeOf(context);
  final compacto = pantalla.width < 600;
  final contenido = _PanelHistorial(familia: familia, compacto: compacto);

  if (compacto) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: pantalla.height * 0.85),
            child: contenido,
          ),
    );
  }
  // El alto lo da el contenido, con tope: casi ninguna familia tiene mas de
  // siete aprobaciones y un dialogo alto con dos renglones es todo hueco.
  return showDialog<void>(
    context: context,
    builder:
        (_) => Dialog(
          insetPadding: const EdgeInsets.all(Esp.xl),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: pantalla.width < 860 ? pantalla.width : 780,
              maxHeight: pantalla.height * 0.8,
            ),
            child: contenido,
          ),
        ),
  );
}

class _PanelHistorial extends ConsumerWidget {
  const _PanelHistorial({required this.familia, required this.compacto});

  final FamiliaVista familia;
  final bool compacto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final historial = ref.watch(
      historialCostoFamiliaProvider(familia.codigoFamilia),
    );

    return Material(
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.s, Esp.s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial del costo · familia ${familia.codigoLegible}',
                        style: tt.titleMedium?.copyWith(fontWeight: Peso.dato),
                      ),
                      if (familia.grupoFamiliaSap.trim().isNotEmpty)
                        Text(familia.grupoFamiliaSap, style: context.apagado()),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.m),
            child: Wrap(
              spacing: Esp.m,
              runSpacing: Esp.m,
              children: [
                _Vigente(
                  rotulo: 'Costo vigente',
                  valor:
                      familia.sinCosto
                          ? 'Sin costo'
                          : '${familia.costoTmLegible} USD/TM',
                  matiz: matizAzul,
                ),
                _Vigente(
                  rotulo: 'Propuesta aprobada',
                  valor:
                      familia.tienePropuestaAprobada
                          ? 'N.º ${familia.idPropuestaAprobada}'
                          : 'Todavía ninguna',
                  matiz: matizVioleta,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: historial.when(
              loading:
                  () => const SizedBox(
                    height: 240,
                    child: EsqueletoLista(filas: 4),
                  ),
              error:
                  (e, _) => SizedBox(
                    height: 280,
                    child: MensajeError(
                      error: e,
                      onReintentar:
                          () => ref.invalidate(
                            historialCostoFamiliaProvider(
                              familia.codigoFamilia,
                            ),
                          ),
                    ),
                  ),
              data:
                  (filas) =>
                      filas.isEmpty
                          ? const SizedBox(
                            height: 280,
                            child: MensajeVacio(
                              icono: Icons.history_toggle_off,
                              titulo: 'Sin cambios registrados',
                              detalle:
                                  'Esta familia no tiene aprobaciones desde el '
                                  '24/06/2025, que es desde cuando se '
                                  'registran.',
                            ),
                          )
                          : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(Esp.l),
                            itemCount: filas.length + 1,
                            separatorBuilder:
                                (_, i) =>
                                    i == filas.length - 1
                                        ? const SizedBox(height: Esp.m)
                                        : const SizedBox(height: Esp.s),
                            itemBuilder:
                                (context, i) =>
                                    i == filas.length
                                        ? Text(
                                          _notaOrigen,
                                          style: context.apagado(),
                                        )
                                        : _Cambio(
                                          cambio: filas[i],
                                          compacto: compacto,
                                        ),
                          ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Vigente extends StatelessWidget {
  const _Vigente({
    required this.rotulo,
    required this.valor,
    required this.matiz,
  });

  final String rotulo;
  final String valor;
  final Color matiz;

  @override
  Widget build(BuildContext context) {
    final t = tonosDeMatiz(matiz, Theme.of(context).colorScheme);
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rotulo, style: tt.labelSmall?.copyWith(color: t.icono)),
          Text(valor, style: context.numero(fuerte: true)),
        ],
      ),
    );
  }
}

/// Una aprobacion. En escritorio va en un renglon; en el telefono, en dos.
class _Cambio extends StatelessWidget {
  const _Cambio({required this.cambio, required this.compacto});

  final HistorialCostoFamiliaEntity cambio;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = cambio;

    final fecha = Text(
      c.fecha == null ? 'Sin fecha' : _fmtFecha.format(c.fecha!),
      style: tt.bodySmall?.copyWith(fontWeight: Peso.titulo),
    );
    final propuesta = Text(
      c.propuestaAnterior > BigInt.zero
          ? 'Propuesta ${c.propuestaNueva} (antes ${c.propuestaAnterior})'
          : 'Propuesta ${c.propuestaNueva}',
      style: context.apagado(),
    );
    // La flecha es un icono y no el caracter: no todas las fuentes lo traen.
    final costo =
        c.cambioElCosto
            ? Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Esp.xs,
              children: [
                if (c.costoAnterior != null) ...[
                  Text(
                    fmtComoPdf.format(c.costoAnterior),
                    style: context.numero(color: cs.onSurfaceVariant),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ],
                Text(
                  '${fmtComoPdf.format(c.costoNuevo)} USD/TM',
                  style: context.numero(fuerte: true),
                ),
              ],
            )
            : Text('El costo no cambió', style: context.apagado());
    final quien = Text(
      c.usuario.isEmpty ? 'Usuario ${c.audUsuario}' : c.usuario,
      overflow: TextOverflow.ellipsis,
      style: context.apagado(),
    );
    final variacion = _Variacion(porcentaje: c.variacion);

    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Expanded(child: fecha), variacion]),
                  const SizedBox(height: Esp.xs),
                  costo,
                  const SizedBox(height: Esp.xs),
                  propuesta,
                  quien,
                ],
              )
              : Row(
                children: [
                  SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [fecha, propuesta],
                    ),
                  ),
                  Expanded(child: costo),
                  SizedBox(width: 96, child: Center(child: variacion)),
                  SizedBox(width: 170, child: quien),
                ],
              ),
    );
  }
}

/// Subida en naranja, bajada en verde: para un costo, bajar es la buena
/// noticia. Sin variacion (el costo no cambio o antes estaba en cero) no se
/// dibuja nada.
class _Variacion extends StatelessWidget {
  const _Variacion({required this.porcentaje});

  final double? porcentaje;

  @override
  Widget build(BuildContext context) {
    final p = porcentaje;
    if (p == null) return const SizedBox.shrink();
    final sube = p > 0;
    final t = tonosDeMatiz(
      sube ? matizNaranja : matizVerde,
      Theme.of(context).colorScheme,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 2),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sube ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: t.icono,
          ),
          const SizedBox(width: 2),
          Text(
            '${fmtComoPdf.format(p.abs())} %',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: t.icono,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
