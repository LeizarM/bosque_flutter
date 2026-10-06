/// Las garantias de un cliente: el paso entre la grilla principal y el detalle.
///
/// Reemplaza al dialogo `clienteModal` de `tcbrGarantia/garantia.xhtml`, que
/// era una tabla de siete columnas con cuatro botones por fila que aparecian y
/// desaparecian segun el `rendered`. Aca cada garantia es un renglon con su
/// plazo dibujado ([BarraVigencia]) y las acciones que corresponden: las que el
/// usuario no tiene no se muestran, y la extension sin traspaso aparece
/// deshabilitada diciendo por que, en vez de esconderse sin explicacion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/detalle_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/dialogos_garantias.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/formularios_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Abre el panel con las garantias de [cliente] (boton btnSCGarCbr).
///
/// [estado] (VIGENTE, CADUCADO o CERRADO) lo abre ya filtrado: desde «Con
/// cerradas» de la pantalla principal se ven primero sus cerradas.
Future<void> abrirGarantiasCliente(
  BuildContext context,
  GarantiaResumenClienteEntity cliente, {
  String? estado,
}) => abrirPanel<void>(
  context,
  anchoMaximo: 1080,
  contenido: (_) => _GarantiasCliente(cliente: cliente, estadoInicial: estado),
);

class _GarantiasCliente extends ConsumerStatefulWidget {
  const _GarantiasCliente({required this.cliente, this.estadoInicial});

  final GarantiaResumenClienteEntity cliente;
  final String? estadoInicial;

  @override
  ConsumerState<_GarantiasCliente> createState() => _GarantiasClienteState();
}

class _GarantiasClienteState extends ConsumerState<_GarantiasCliente> {
  /// VIGENTE, CADUCADO, CERRADO o null (todas).
  late String? _estado = widget.estadoInicial;

  GarantiaResumenClienteEntity get _c => widget.cliente;

  Future<void> _nuevaParaEsteCliente() async {
    final id = await abrirAltaGarantia(
      context,
      cliente: ClienteSapEntity(
        codClienteSAP: _c.codClienteSAP,
        datoCliente: _c.datoCliente,
      ),
    );
    // La lista se refresca sola: la escritura invalida garantiasClienteProvider.
    if (id != null && mounted) {
      await abrirDetalleGarantia(context, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = ref.watch(garantiasClienteProvider(_c.codClienteSAP));
    ref.watch(buttonPermissionsProvider);
    final puedeNueva = tienePermisoDeBoton(ref, BtnGarantias.nueva);

    return MarcoPanel(
      titulo: _c.datoCliente,
      subtitulo: 'Código SAP ${_c.codClienteSAP}',
      encabezadoExtra: Wrap(
        spacing: Esp.s,
        runSpacing: Esp.xs,
        children: [
          EtiquetaGarantia(
            texto:
                '${_c.cantVigentes} de ${_c.cantGarantias} '
                '${_c.cantGarantias == 1 ? "vigente" : "vigentes"}',
            tono: _c.sinVigentes ? TonoEtiqueta.neutro : TonoEtiqueta.exito,
          ),
          if (_c.difiereDeSap)
            const EtiquetaGarantia(
              texto: 'Línea aprobada distinta de SAP',
              tono: TonoEtiqueta.aviso,
            ),
          const BotonGuia(texto: '¿Qué significa esto?'),
        ],
      ),
      acciones: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cerrar'),
        ),
        if (puedeNueva)
          FilledButton.icon(
            onPressed: _nuevaParaEsteCliente,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva garantía para este cliente'),
          ),
      ],
      cuerpo: lista.when(
        // El cuerpo del panel ya tiene scroll: la espera y el error van en una
        // altura fija para no pedirle altura infinita a una lista.
        loading: () => const EsperaEnPanel(filas: 3, altoFila: 96),
        error:
            (e, _) => SizedBox(
              height: 300,
              child: MensajeError(
                error: e,
                onReintentar:
                    () => ref.invalidate(
                      garantiasClienteProvider(_c.codClienteSAP),
                    ),
              ),
            ),
        data: (garantias) => _cuerpo(garantias),
      ),
    );
  }

  Widget _cuerpo(List<GarantiaVistaEntity> garantias) {
    if (garantias.isEmpty) {
      return const SizedBox(
        height: 260,
        child: MensajeVacio(
          icono: Icons.inbox_outlined,
          titulo: 'Este cliente no tiene garantías',
          detalle:
              'Puede registrar la primera con «Nueva garantía para este '
              'cliente».',
        ),
      );
    }

    int cuantas(String estado) =>
        garantias.where((g) => g.datoEstado == estado).length;
    final visibles =
        _estado == null
            ? garantias
            : garantias.where((g) => g.datoEstado == _estado).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filtro por estado con la cuenta de cada uno: el legacy mostraba todo
        // junto y habia que leer la columna Estado fila por fila.
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [
            ChoiceChip(
              label: Text('Todas (${garantias.length})'),
              selected: _estado == null,
              onSelected: (_) => setState(() => _estado = null),
            ),
            for (final (estado, texto) in const [
              (GarantiaVistaEntity.vigente, 'Vigentes'),
              (GarantiaVistaEntity.caducado, 'Caducadas'),
              (GarantiaVistaEntity.cerrado, 'Cerradas'),
            ])
              if (cuantas(estado) > 0)
                ChoiceChip(
                  label: Text('$texto (${cuantas(estado)})'),
                  selected: _estado == estado,
                  onSelected:
                      (sel) => setState(() => _estado = sel ? estado : null),
                ),
          ],
        ),
        const SizedBox(height: Esp.l),
        if (visibles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Esp.xl),
            child: Text(
              'Ninguna garantía de este cliente está en ese estado.',
              style: context.apagado(),
              textAlign: TextAlign.center,
            ),
          )
        else
          for (var i = 0; i < visibles.length; i++) ...[
            _RenglonGarantia(n: i + 1, g: visibles[i]),
            const SizedBox(height: Esp.s),
          ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UN RENGLON
// ═══════════════════════════════════════════════════════════════════════════

class _RenglonGarantia extends ConsumerWidget {
  const _RenglonGarantia({required this.n, required this.g});

  /// Numero de la garantia en la lista filtrada del cliente.
  final int n;
  final GarantiaVistaEntity g;

  /// Las acciones que el usuario puede ver sobre esta garantia, en el orden en
  /// que se usan: mirar, corregir, renovar, imprimir.
  List<OpcionMenu> _acciones(BuildContext context, WidgetRef ref) {
    final editable = g.admiteCambios;
    return [
      OpcionMenu(
        'Ver detalle',
        Icons.visibility_outlined,
        () => abrirDetalleGarantia(context, g.codGarantia),
      ),
      if (editable && tienePermisoDeBoton(ref, BtnGarantias.editar))
        OpcionMenu(
          'Editar firmas y documentos',
          Icons.edit_outlined,
          () => abrirEdicionGarantia(context, g),
        ),
      if (editable && tienePermisoDeBoton(ref, BtnGarantias.editarAdm))
        OpcionMenu(
          'Edición administrativa',
          Icons.admin_panel_settings_outlined,
          () => abrirEdicionAdministrativa(context, g),
        ),
      if (editable && tienePermisoDeBoton(ref, BtnGarantias.extension))
        OpcionMenu(
          'Extender plazo',
          Icons.update,
          () => abrirExtension(context, g),
          motivo:
              g.traspasada
                  ? null
                  : 'Para extenderla, primero debe hacerse el traspaso a '
                      'custodia.',
        ),
      if (tienePermisoDeBoton(ref, BtnGarantias.recibo))
        OpcionMenu(
          'Recibo en PDF',
          Icons.receipt_long_outlined,
          () => verPdf(
            context,
            generar:
                () => ref
                    .read(garantiasRepositoryProvider)
                    .reporteRecibo(g.codGarantia),
            titulo: 'Recibo de la garantía N° ${g.codGarantia}',
            nombreArchivo: 'recibo_garantia_${g.codGarantia}.pdf',
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final acciones = _acciones(context, ref);
    final gar = g.garantia;

    final identidad = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '#$n',
              style: context.cifra(color: cs.onSurfaceVariant, tam: 11),
            ),
            Text('N° ${g.codGarantia}', style: context.cifra(fuerte: true)),
            ChipEstadoGarantia(garantia: g),
            if (!g.traspasada && g.admiteCambios)
              Tooltip(
                message: Glosario.sinTraspaso.ayuda,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 8),
                child: const EtiquetaGarantia(texto: 'Sin traspaso'),
              ),
          ],
        ),
        const SizedBox(height: Esp.xs),
        Text(
          (g.tiposGarantia ?? '').trim().isEmpty
              ? 'Sin documentos cargados'
              : g.tiposGarantia!,
          style: context.apagado(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    final montos = Wrap(
      spacing: Esp.l,
      runSpacing: Esp.s,
      children: [
        // Los mismos nombres que en el detalle y el formulario (Glosario):
        // antes aca decia «Garantía» y «Pago a».
        DatoFicha.termino(
          Glosario.valor,
          valor: monto(gar.montoGarantia),
          cifra: true,
          ancho: 150,
        ),
        DatoFicha.termino(
          Glosario.lineaAprobada,
          valor: monto(gar.montoCredito),
          cifra: true,
          ancho: 130,
        ),
        DatoFicha.termino(
          Glosario.plazoPago,
          valor: '${gar.tiempoPago} días',
          ancho: 110,
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(Esp.m),
      child: LayoutBuilder(
        builder: (context, r) {
          // Ancho: todo en una fila y las acciones como iconos a la vista.
          if (r.maxWidth >= 820) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: identidad),
                const SizedBox(width: Esp.l),
                Expanded(flex: 4, child: BarraVigencia(garantia: g)),
                const SizedBox(width: Esp.l),
                Expanded(flex: 4, child: montos),
                _AccionesEnLinea(acciones: acciones),
              ],
            );
          }
          // Angosto: apilado, y las acciones en un menu para no romper la fila.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identidad),
                  MenuAcciones(opciones: acciones),
                ],
              ),
              const SizedBox(height: Esp.m),
              BarraVigencia(garantia: g),
              const SizedBox(height: Esp.m),
              montos,
            ],
          );
        },
      ),
    );
  }
}

/// En ancho: la accion principal («Ver detalle») con su nombre a la vista y el
/// resto en un menu con nombres. Antes eran cinco iconos sueltos —ojo, lapiz,
/// escudo, flecha circular, recibo— que obligaban a pasar el mouse por cada
/// uno para saber que hacia.
class _AccionesEnLinea extends StatelessWidget {
  const _AccionesEnLinea({required this.acciones});

  final List<OpcionMenu> acciones;

  @override
  Widget build(BuildContext context) {
    final principal = acciones.first;
    final resto = acciones.skip(1).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: principal.habilitada ? principal.alElegir : null,
          icon: Icon(principal.icono, size: 18),
          label: Text(principal.etiqueta),
        ),
        if (resto.isNotEmpty) MenuAcciones(opciones: resto),
      ],
    );
  }
}
