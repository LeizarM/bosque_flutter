/// Detalle de una garantia: sus datos, los documentos que la respaldan y el
/// historial de acciones.
///
/// Reemplaza al dialogo `detalleModal` del legacy y a los tres que colgaban de
/// el (firmas, protesta, accion). Todo lo que escribe se oculta si la garantia
/// esta cerrada —igual que el legacy— y ademas el backend lo rechaza.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/dialogos_garantias.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/formularios_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

Future<void> abrirDetalleGarantia(BuildContext context, BigInt codGarantia) =>
    abrirPanel<void>(
      context,
      anchoMaximo: 980,
      contenido: (_) => _DetalleGarantia(codGarantia: codGarantia),
    );

class _DetalleGarantia extends ConsumerWidget {
  const _DetalleGarantia({required this.codGarantia});

  final BigInt codGarantia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garantia = ref.watch(garantiaProvider(codGarantia));

    return garantia.when(
      loading:
          () => const MarcoPanel(
            titulo: 'Garantía',
            cuerpo: EsperaEnPanel(filas: 4),
          ),
      error:
          (e, _) => MarcoPanel(
            titulo: 'Garantía N° $codGarantia',
            // Alto fijo: el cuerpo del panel ya scrollea (ver MarcoPanel).
            cuerpo: SizedBox(
              height: 300,
              child: MensajeError(
                error: e,
                onReintentar:
                    () => ref.invalidate(garantiaProvider(codGarantia)),
              ),
            ),
          ),
      data: (g) {
        if (g == null) {
          return MarcoPanel(
            titulo: 'Garantía N° $codGarantia',
            cuerpo: const SizedBox(
              height: 260,
              child: MensajeVacio(
                icono: Icons.search_off,
                titulo: 'La garantía ya no existe',
                detalle: 'Cierre este panel y actualice el listado.',
              ),
            ),
          );
        }
        return _Contenido(g: g);
      },
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.g});

  final GarantiaVistaEntity g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puedeRecibo = tienePermisoDeBoton(ref, BtnGarantias.recibo);
    final puedeExtender =
        tienePermisoDeBoton(ref, BtnGarantias.extension) &&
        g.admiteCambios &&
        g.traspasada;
    final puedeAdm =
        tienePermisoDeBoton(ref, BtnGarantias.editarAdm) && g.admiteCambios;
    // Siempre visible si tiene el boton y la garantia esta abierta, aunque falte
    // el traspaso: el dialogo explica por que no se puede todavia, en vez de
    // que el boton desaparezca sin explicacion.
    final puedeCerrar =
        tienePermisoDeBoton(ref, BtnGarantias.nuevaAccion) && g.admiteCambios;

    return MarcoPanel(
      titulo: 'Garantía N° ${g.codGarantia}',
      subtitulo: '${g.datoCliente} · ${g.garantia.codClienteSAP}',
      encabezadoExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Esp.s,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChipEstadoGarantia(garantia: g),
              Tooltip(
                message:
                    (g.traspasada ? Glosario.enCustodia : Glosario.sinTraspaso)
                        .ayuda,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 8),
                child: EtiquetaGarantia(
                  texto: g.traspasada ? 'En custodia' : 'Sin traspaso',
                  tono: g.traspasada ? TonoEtiqueta.neutro : TonoEtiqueta.aviso,
                ),
              ),
              if (g.garantia.difiereDeDetalles)
                Tooltip(
                  message:
                      'Sus documentos suman '
                      '${monto(g.garantia.montoGarantiaCalc ?? 0)} y el valor '
                      'de la garantía es ${monto(g.garantia.montoGarantia)}. '
                      'Revise los montos de los documentos.',
                  triggerMode: TooltipTriggerMode.tap,
                  showDuration: const Duration(seconds: 8),
                  child: const EtiquetaGarantia(
                    texto: 'Documentos no suman el valor',
                    tono: TonoEtiqueta.aviso,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Esp.m),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: BarraVigencia(garantia: g),
          ),
        ],
      ),
      // El recorrido y la guia van en el cuerpo, que scrollea: en el
      // encabezado fijo, a 320 px, lo dejaban mas alto que la pantalla.
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Recorrido(g: g),
          const SizedBox(height: Esp.l),
          _AvisoEstado(g: g),
          _Cifras(g: g),
          const SizedBox(height: Esp.xl),
          _Datos(g: g),
          const SizedBox(height: Esp.xl),
          _Documentos(g: g),
          const SizedBox(height: Esp.xl),
          _Acciones(g: g),
        ],
      ),
      acciones: [
        if (puedeRecibo)
          TextButton.icon(
            onPressed:
                () => verPdf(
                  context,
                  generar:
                      () => ref
                          .read(operacionesGarantiasProvider.notifier)
                          .reporteRecibo(g.codGarantia),
                  titulo: 'Recibo de garantía N° ${g.codGarantia}',
                  nombreArchivo: 'recibo-garantia-${g.codGarantia}.pdf',
                ),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Recibo PDF'),
          ),
        if (puedeAdm)
          OutlinedButton.icon(
            onPressed: () => abrirEdicionAdministrativa(context, g),
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: const Text('Edición administrativa'),
          ),
        if (puedeCerrar)
          OutlinedButton.icon(
            onPressed: () => abrirCierre(context, g),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text('Cerrar garantía'),
          ),
        if (puedeExtender)
          FilledButton.tonalIcon(
            onPressed: () => abrirExtension(context, g),
            icon: const Icon(Icons.update, size: 18),
            label: const Text('Extender'),
          ),
      ],
    );
  }
}

/// Lo primero que se lee en el detalle: en que estado esta la garantia y que se
/// puede hacer con ella. Existe porque la duda mas comun es si una garantia
/// vencida esta cerrada (no lo esta: solo se cierra a mano).
class _AvisoEstado extends ConsumerWidget {
  const _AvisoEstado({required this.g});

  final GarantiaVistaEntity g;

  static String _dias(int n) => n == 1 ? '1 día' : '$n días';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fin = fechaCorta(g.garantia.fechaExpiracion);
    final dias = g.diasParaVencer;

    final Widget? aviso = switch (tonoDe(g)) {
      TonoGarantia.cerrada => () {
        // El cierre es la accion CER; la lista viene de la mas nueva a la mas
        // vieja. Si todavia carga, el aviso sale sin fecha ni motivo.
        final cierre =
            ref
                .watch(accionesGarantiaProvider(g.codGarantia))
                .valueOrNull
                ?.where((a) => a.estado == AccionCbrEntity.cierre)
                .firstOrNull;
        final cuando =
            cierre?.fecha != null ? ' el ${fechaCorta(cierre!.fecha)}' : '';
        final motivo = (cierre?.observacion ?? '').trim();
        return NotaGarantia(
          tono: TonoNota.info,
          icono: Icons.lock_outline,
          texto:
              'Garantía cerrada$cuando.'
              '${motivo.isEmpty ? '' : ' Motivo: $motivo'} '
              'Ya no admite cambios. Si se cerró por error, pida a Sistemas '
              'que lo corrija.',
        );
      }(),
      TonoGarantia.caducada => NotaGarantia(
        tono: TonoNota.aviso,
        icono: Icons.event_busy_outlined,
        texto:
            'Venció el $fin'
            '${dias != null && dias < 0 ? ' (hace ${_dias(-dias)})' : ''}, '
            'pero sigue abierta: vencerse no la cierra. '
            '${g.traspasada ? 'Puede extender su plazo con «Extender» o '
                    'cerrarla con «Cerrar garantía».' : 'Para extenderla o cerrarla, primero hay que '
                    'traspasarla a custodia.'}',
      ),
      TonoGarantia.porVencer => NotaGarantia(
        tono: TonoNota.aviso,
        icono: Icons.schedule,
        texto:
            'Vence el $fin '
            '(${dias == 0 ? 'hoy' : 'en ${_dias(dias ?? 0)}'}). '
            'Si se renueva, use «Extender».',
      ),
      TonoGarantia.vigente => null,
    };

    if (aviso == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: Esp.l), child: aviso);
  }
}

/// Las tres etapas de una garantia con su fecha —registrada, en custodia,
/// cerrada— y el paso que sigue. Responde de un vistazo «¿en qué anda?» y
/// «¿qué falta?», que es lo que antes habia que deducir del historial.
///
/// Las fechas de traspaso y cierre salen del historial de acciones (TRASP y
/// CER); mientras carga, las etapas se muestran sin fecha.
class _Recorrido extends ConsumerWidget {
  const _Recorrido({required this.g});

  final GarantiaVistaEntity g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final acciones =
        ref.watch(accionesGarantiaProvider(g.codGarantia)).valueOrNull ??
        const <AccionCbrEntity>[];
    String fechaDe(String estado) {
      final f = acciones.where((a) => a.estado == estado).firstOrNull?.fecha;
      return f == null ? '' : fechaCorta(f);
    }

    final etapas = <(String, bool, String)>[
      ('Registrada', true, fechaCorta(g.fechaRegistro)),
      (
        'En custodia',
        g.traspasada,
        g.traspasada ? fechaDe(AccionCbrEntity.traspaso) : 'pendiente',
      ),
      (
        'Cerrada',
        g.estaCerrada,
        g.estaCerrada ? fechaDe(AccionCbrEntity.cierre) : '',
      ),
    ];

    final siguiente =
        g.estaCerrada
            ? null
            : !g.traspasada
            ? 'Siguiente paso: traspasarla a custodia desde «Traspaso» en la '
                'pantalla principal.'
            : 'En custodia: puede registrar notas, extenderla o cerrarla.';

    Widget etapa((String, bool, String) e) {
      final (titulo, hecha, cuando) = e;
      // Texto con Flexible: con zoom o en un telefono chico, la fecha baja a
      // la linea siguiente en vez de desbordar.
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hecha ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: hecha ? cs.primary : cs.outline,
          ),
          const SizedBox(width: Esp.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: titulo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: hecha ? Peso.titulo : null,
                      color: hecha ? null : cs.onSurfaceVariant,
                    ),
                  ),
                  if (cuando.isNotEmpty)
                    TextSpan(
                      text: '  $cuando',
                      style: context.apagado()?.copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: 'Recorrido de la garantía',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap: a 320 px las tres etapas no entran en una linea.
          Wrap(
            spacing: Esp.xs,
            runSpacing: Esp.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < etapas.length; i++) ...[
                if (i > 0)
                  Icon(Icons.chevron_right, size: 18, color: cs.outline),
                etapa(etapas[i]),
              ],
            ],
          ),
          if (siguiente != null) ...[
            const SizedBox(height: Esp.xs),
            Text(siguiente, style: context.apagado()),
          ],
          const Align(
            alignment: Alignment.centerLeft,
            child: BotonGuia(texto: '¿Qué significa cada dato y estado?'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CIFRAS
// ═══════════════════════════════════════════════════════════════════════════

class _Cifras extends StatelessWidget {
  const _Cifras({required this.g});

  final GarantiaVistaEntity g;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final calc = g.garantia.montoGarantiaCalc;

    Widget cifra(Termino termino, Widget valor, {String? nota}) => Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EtiquetaConAyuda(termino),
          const SizedBox(height: Esp.xs),
          valor,
          if (nota != null)
            Text(nota, style: context.apagado()?.copyWith(fontSize: 11)),
        ],
      ),
    );

    TextStyle? grande({Color? color}) =>
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: Peso.dato,
          fontFeatures: cifrasTabulares,
          color: color,
        );

    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.m,
      children: [
        cifra(
          Glosario.valor,
          Text(monto(g.garantia.montoGarantia), style: grande()),
        ),
        cifra(
          Glosario.sumaDocumentos,
          Text(
            monto(calc ?? 0),
            style: grande(
              color: g.garantia.difiereDeDetalles ? colorAviso(context) : null,
            ),
          ),
          nota: '${g.cantDetalles} documento${g.cantDetalles == 1 ? '' : 's'}',
        ),
        cifra(
          Glosario.lineaAprobada,
          Text(monto(g.garantia.montoCredito), style: grande()),
          nota: 'Plazo de pago: ${g.garantia.tiempoPago} días',
        ),
        cifra(
          Glosario.lineaSap,
          Text(
            monto(g.creditLine),
            style: grande(color: g.difiereDeSap ? colorAviso(context) : null),
          ),
          nota:
              g.difiereDeSap
                  ? 'No coincide con la aprobada'
                  : 'Saldo ${monto(g.balance)}',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS
// ═══════════════════════════════════════════════════════════════════════════

class _Datos extends ConsumerWidget {
  const _Datos({required this.g});

  final GarantiaVistaEntity g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puedeEditar =
        tienePermisoDeBoton(ref, BtnGarantias.editar) && g.admiteCambios;
    final x = g.garantia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSeccion(
          texto: 'Datos del registro',
          accion:
              puedeEditar
                  ? TextButton.icon(
                    onPressed: () => abrirFirmasYProtesta(context, g),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Firmas y protesta'),
                  )
                  : null,
        ),
        Wrap(
          spacing: Esp.xl,
          runSpacing: Esp.m,
          children: [
            DatoFicha.termino(
              Glosario.inicio,
              valor: fechaCorta(x.fechaInicio),
            ),
            DatoFicha.termino(
              Glosario.expiracion,
              valor: fechaCorta(x.fechaExpiracion),
            ),
            DatoFicha(
              etiqueta: 'Registrada',
              valor:
                  '${fechaCorta(g.fechaRegistro)}'
                  '${(g.realizoEmp ?? '').isEmpty ? '' : ' · ${g.realizoEmp}'}',
              ancho: 280,
            ),
            DatoFicha.termino(Glosario.recFirmas, valor: x.recFirmas ?? ''),
            DatoFicha.termino(Glosario.nroProtesta, valor: x.nroProtesta ?? ''),
          ],
        ),
        if ((g.observacionRegistro ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: Esp.m),
          Text('Observación del registro', style: context.apagado()),
          const SizedBox(height: 2),
          Text(g.observacionRegistro!.trim()),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DOCUMENTOS
// ═══════════════════════════════════════════════════════════════════════════

class _Documentos extends ConsumerWidget {
  const _Documentos({required this.g});

  final GarantiaVistaEntity g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalles = ref.watch(detallesGarantiaProvider(g.codGarantia));
    final catalogo = ref.watch(tiposGarantiaProvider).valueOrNull;
    final puedeEditar =
        tienePermisoDeBoton(ref, BtnGarantias.editar) && g.admiteCambios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSeccion(
          texto: 'Documentos que la respaldan',
          accion:
              puedeEditar
                  ? TextButton.icon(
                    onPressed:
                        () =>
                            abrirDocumento(context, codGarantia: g.codGarantia),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar documento'),
                  )
                  : null,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.s),
          child: Text(
            'Lo que el cliente entregó como garantía. La suma de sus montos '
            'debería ser igual al valor de la garantía.',
            style: context.apagado(),
          ),
        ),
        detalles.when(
          // El cuerpo del panel ya scrollea: EsqueletoLista suelto pedia altura
          // infinita y congelaba la pantalla. EsperaEnPanel va con alto fijo.
          loading: () => const EsperaEnPanel(filas: 2, altoFila: 52),
          error:
              (e, _) => MensajeError(
                error: e,
                compacto: true,
                onReintentar:
                    () =>
                        ref.invalidate(detallesGarantiaProvider(g.codGarantia)),
              ),
          data:
              (lista) =>
                  lista.isEmpty
                      ? Text(
                        'Esta garantía no tiene documentos cargados.',
                        style: context.apagado(),
                      )
                      : _Lista(
                        hijos: [
                          for (final d in lista)
                            _FilaDocumento(
                              d: d,
                              nombreTipo: nombreDeTipo(
                                catalogo,
                                d.tipoGarantia,
                              ),
                              puedeEditar: puedeEditar,
                              codGarantia: g.codGarantia,
                            ),
                        ],
                      ),
        ),
      ],
    );
  }
}

class _FilaDocumento extends ConsumerWidget {
  const _FilaDocumento({
    required this.d,
    required this.nombreTipo,
    required this.puedeEditar,
    required this.codGarantia,
  });

  final CbrDetalleEntity d;
  final String nombreTipo;
  final bool puedeEditar;
  final BigInt codGarantia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreTipo,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                ),
                if ((d.detalle ?? '').trim().isNotEmpty)
                  Text(
                    d.detalle!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.apagado(),
                  ),
                Text(
                  'Cargado el ${fechaCorta(d.fecha)}',
                  style: context.apagado()?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: Esp.s),
          Text(monto(d.monto), style: context.cifra(fuerte: true)),
          if (puedeEditar)
            MenuAcciones(
              tooltip: 'Opciones del documento',
              tamIcono: 20,
              opciones: [
                OpcionMenu(
                  'Cambiar monto',
                  Icons.edit_outlined,
                  () => abrirDocumento(
                    context,
                    codGarantia: codGarantia,
                    existente: d,
                  ),
                ),
                OpcionMenu(
                  'Eliminar',
                  Icons.delete_outline,
                  () => eliminarDocumento(context, ref, d, nombreTipo),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HISTORIAL DE ACCIONES
// ═══════════════════════════════════════════════════════════════════════════

class _Acciones extends ConsumerWidget {
  const _Acciones({required this.g});

  final GarantiaVistaEntity g;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acciones = ref.watch(accionesGarantiaProvider(g.codGarantia));
    final estados = ref.watch(estadosAccionProvider).valueOrNull;
    final puedeNueva =
        tienePermisoDeBoton(ref, BtnGarantias.nuevaAccion) && g.admiteCambios;
    final puedeEditar =
        tienePermisoDeBoton(ref, BtnGarantias.editarAccion) && g.admiteCambios;
    final puedeBorrar =
        tienePermisoDeBoton(ref, BtnGarantias.eliminarAccion) &&
        g.admiteCambios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloSeccion(
          texto: 'Historial de acciones',
          accion:
              puedeNueva
                  ? TextButton.icon(
                    onPressed: () => abrirAccion(context, garantia: g),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nueva nota'),
                  )
                  : null,
        ),
        if (!g.traspasada && g.admiteCambios)
          const Padding(
            padding: EdgeInsets.only(bottom: Esp.s),
            child: NotaGarantia(
              tono: TonoNota.aviso,
              texto:
                  'Todavía no se traspasó a custodia. Se pueden registrar '
                  'notas; para cerrarla o extenderla, primero hay que '
                  'traspasarla («Traspaso» en la pantalla principal).',
            ),
          ),
        acciones.when(
          loading: () => const EsperaEnPanel(filas: 2, altoFila: 52),
          error:
              (e, _) => MensajeError(
                error: e,
                compacto: true,
                onReintentar:
                    () =>
                        ref.invalidate(accionesGarantiaProvider(g.codGarantia)),
              ),
          data:
              (lista) =>
                  lista.isEmpty
                      ? Text('Sin acciones.', style: context.apagado())
                      : _Lista(
                        hijos: [
                          for (final a in lista)
                            _FilaAccion(
                              a: a,
                              estados: estados,
                              puedeEditar: puedeEditar,
                              puedeBorrar: puedeBorrar,
                              garantia: g,
                            ),
                        ],
                      ),
        ),
      ],
    );
  }
}

class _FilaAccion extends ConsumerWidget {
  const _FilaAccion({
    required this.a,
    required this.estados,
    required this.puedeEditar,
    required this.puedeBorrar,
    required this.garantia,
  });

  final AccionCbrEntity a;
  final List<TipoCbrEntity>? estados;
  final bool puedeEditar;
  final bool puedeBorrar;
  final GarantiaVistaEntity garantia;

  TonoEtiqueta get _tono => switch (a.estado) {
    AccionCbrEntity.cierre => TonoEtiqueta.error,
    AccionCbrEntity.extension => TonoEtiqueta.aviso,
    AccionCbrEntity.registro || AccionCbrEntity.traspaso => TonoEtiqueta.exito,
    _ => TonoEtiqueta.neutro,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = nombreDeTipo(estados, a.estado);
    final hayMenu = puedeEditar || puedeBorrar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(fechaCorta(a.fecha), style: context.cifra()),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EtiquetaGarantia(texto: nombre, tono: _tono),
                if ((a.observacion ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: Esp.xs),
                  Text(a.observacion!.trim()),
                ],
              ],
            ),
          ),
          if (hayMenu)
            MenuAcciones(
              tooltip: 'Opciones de la acción',
              tamIcono: 20,
              opciones: [
                if (puedeEditar)
                  OpcionMenu(
                    'Editar observación',
                    Icons.edit_outlined,
                    () =>
                        abrirAccion(context, garantia: garantia, existente: a),
                  ),
                if (puedeBorrar)
                  OpcionMenu(
                    'Eliminar',
                    Icons.delete_outline,
                    () => eliminarAccion(context, ref, a, nombre),
                  ),
              ],
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// Filas separadas por una linea, dentro de un marco.
class _Lista extends StatelessWidget {
  const _Lista({required this.hijos});

  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Column(
        children: [
          for (final (i, h) in hijos.indexed) ...[
            if (i > 0) Divider(height: 1, color: cs.outlineVariant),
            h,
          ],
        ],
      ),
    );
  }
}
