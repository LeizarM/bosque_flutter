/// El detalle de un resmado: quien resmo, que resmo y a que orden de
/// fabricacion se imputa.
///
/// Solo dos datos se corrigen aqui —la orden y la empresa—, que son los que
/// vinculan el resmado con SAP y los unicos que no siempre se saben en el
/// momento de resmar. El resto se captura en planta y no se toca.
library;

import 'package:bosque_flutter/core/state/ver_resmado_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/resmado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/lote-produccion/balance_lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre el detalle de [resmado].
Future<void> abrirDetalleResmado(
  BuildContext context, {
  required ResmadoEntity resmado,
  required int audUsuario,
}) => showDialog<void>(
  context: context,
  builder: (_) =>
      DetalleResmadoDialog(resmado: resmado, audUsuario: audUsuario),
);

class DetalleResmadoDialog extends ConsumerStatefulWidget {
  const DetalleResmadoDialog({
    super.key,
    required this.resmado,
    required this.audUsuario,
  });

  final ResmadoEntity resmado;
  final int audUsuario;

  @override
  ConsumerState<DetalleResmadoDialog> createState() =>
      _DetalleResmadoDialogState();
}

class _DetalleResmadoDialogState extends ConsumerState<DetalleResmadoDialog> {
  late final TextEditingController _ordenCtrl = TextEditingController(
    text: widget.resmado.docNumOrdFab == 0
        ? ''
        : widget.resmado.docNumOrdFab.toString(),
  );
  late int? _codEmpresa = widget.resmado.codEmpresa == 0
      ? null
      : widget.resmado.codEmpresa;

  bool _guardando = false;

  @override
  void dispose() {
    _ordenCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final orden = int.tryParse(_ordenCtrl.text.trim()) ?? 0;

    if (orden <= 0) {
      avisar(context, 'Ingrese el numero de orden de fabricacion.',
          esError: true);
      return;
    }
    if (_codEmpresa == null) {
      avisar(context, 'Seleccione la empresa.', esError: true);
      return;
    }

    setState(() => _guardando = true);
    final error = await ref
        .read(verResmadosProvider.notifier)
        .guardarOrden(
          resmado: widget.resmado,
          docNumOrdFab: orden,
          codEmpresa: _codEmpresa!,
          audUsuario: widget.audUsuario,
        );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      avisar(context, error, esError: true);
      return;
    }
    avisar(context, 'Orden de fabricacion guardada.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estado = ref.watch(verResmadosProvider);
    final detalle = ref.watch(detalleResmadoProvider(widget.resmado.idRes));
    final r = widget.resmado;

    return LayoutBuilder(
      builder: (context, restricciones) {
        final aire = Aire.de(restricciones.maxWidth);

        return Dialog(
          insetPadding: EdgeInsets.all(aire.esChico ? Esp.s : Esp.xxl),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Cabecera ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(Esp.xl, Esp.l, Esp.m, Esp.l),
                  color: cs.surfaceContainerHigh,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resmado', style: context.apagado()),
                            SizedBox(height: Esp.xs),
                            Text(
                              r.descripcion.isEmpty ? 'Sin grupo' : r.descripcion,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: Peso.titulo),
                            ),
                            Text(
                              '${r.nombreCompleto}  ·  ${fechaCorta(r.fecha)}',
                              style: context.apagado(),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: ListView(
                    padding: EdgeInsets.all(aire.esChico ? Esp.m : Esp.xl),
                    children: [
                      _Resumen(resmado: r, aire: aire),
                      SizedBox(height: Esp.xl),

                      // ── Lo unico editable ─────────────────────────────
                      Text(
                        'Imputacion a SAP',
                        style: context.tituloSeccion(),
                      ),
                      SizedBox(height: Esp.xs),
                      Text(
                        'Es lo unico que se corrige desde aqui. El resto del '
                        'resmado se registra en planta.',
                        style: context.apagado(),
                      ),
                      SizedBox(height: Esp.m),
                      _CamposImputacion(
                        aire: aire,
                        orden: TextField(
                          controller: _ordenCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: context.numero(fuerte: true),
                          decoration: const InputDecoration(
                            labelText: 'Orden de fabricacion',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        empresa: DropdownButtonFormField<int>(
                          value:
                              estado.empresas.any(
                                (e) => e.codEmpresa == _codEmpresa,
                              )
                              ? _codEmpresa
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Empresa',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            for (final e in estado.empresas)
                              DropdownMenuItem(
                                value: e.codEmpresa,
                                child: Text(e.nombre),
                              ),
                          ],
                          onChanged: (v) => setState(() => _codEmpresa = v),
                        ),
                      ),

                      SizedBox(height: Esp.xl),

                      // ── Que se resmo ──────────────────────────────────
                      Text('Articulos resmados', style: context.tituloSeccion()),
                      SizedBox(height: Esp.m),
                      detalle.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => Text(
                          'No se pudo cargar el detalle del resmado.',
                          style: context.apagado(),
                        ),
                        data: (lista) => lista.isEmpty
                            ? Text(
                                'Este resmado no tiene articulos cargados.',
                                style: context.apagado(),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: cs.outlineVariant),
                                  borderRadius: BorderRadius.circular(
                                    Esquina.chica,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    for (var i = 0; i < lista.length; i++)
                                      Container(
                                        color: i.isEven
                                            ? null
                                            : cs.surfaceContainerLow,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Esp.m,
                                          vertical: Esp.s,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 92,
                                              child: Text(
                                                lista[i].codArticulo,
                                                style: context.numero(),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                lista[i].descripcion,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: Esp.m),
                                            Text(
                                              fmtEntero.format(
                                                lista[i].cantResma,
                                              ),
                                              style: context.numero(
                                                fuerte: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // ── Acciones ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Esp.l),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _guardando
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      SizedBox(width: Esp.s),
                      FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          _guardando ? 'Guardando…' : 'Guardar cambios',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Los dos campos editables, uno al lado del otro o apilados segun el ancho.
class _CamposImputacion extends StatelessWidget {
  const _CamposImputacion({
    required this.aire,
    required this.orden,
    required this.empresa,
  });

  final Aire aire;
  final Widget orden;
  final Widget empresa;

  @override
  Widget build(BuildContext context) => aire.esChico
      ? Column(children: [orden, SizedBox(height: Esp.m), empresa])
      : Row(
          children: [
            Expanded(child: orden),
            SizedBox(width: Esp.m),
            Expanded(child: empresa),
          ],
        );
}

/// Los datos que se registraron en planta: se muestran, no se editan.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.resmado, required this.aire});

  final ResmadoEntity resmado;
  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final datos = <(String, String)>[
      ('Total resmado', fmtNumero.format(resmado.total)),
      ('Hora inicio', resmado.hraInicio.isEmpty ? '--' : resmado.hraInicio),
      ('Hora fin', resmado.hraFin.isEmpty ? '--' : resmado.hraFin),
      ('Empresa', resmado.empresa.isEmpty ? 'Sin asignar' : resmado.empresa),
    ];

    return Container(
      padding: EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Wrap(
        spacing: Esp.xxl,
        runSpacing: Esp.m,
        children: [
          for (final (etiqueta, valor) in datos)
            SizedBox(
              width: aire.esChico ? 130 : 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: context.apagado()),
                  Text(
                    valor,
                    style: context.numero(fuerte: true),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
