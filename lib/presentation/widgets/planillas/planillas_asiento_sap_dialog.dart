import 'package:bosque_flutter/core/state/asiento_sap_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final NumberFormat _fmt = NumberFormat('#,##0.00');

/// Vista previa del asiento contable de la planilla y envío a SAP.
///
/// El backend corre el SP de la empresa, arma el asiento, comprueba que cuadre y lo
/// crea por el Service Layer: aquí solo se elige la empresa, se revisa y se confirma.
/// Las empresas salen de la configuración del backend, así que una nueva aparece sola.
class PlanillasAsientoSapDialog extends ConsumerStatefulWidget {
  final int mes;
  final int anio;
  final String nombreMes;

  const PlanillasAsientoSapDialog({
    super.key,
    required this.mes,
    required this.anio,
    required this.nombreMes,
  });

  @override
  ConsumerState<PlanillasAsientoSapDialog> createState() =>
      _PlanillasAsientoSapDialogState();
}

class _PlanillasAsientoSapDialogState
    extends ConsumerState<PlanillasAsientoSapDialog> {
  int? _elegida;
  bool _enviando = false;

  ({int anio, int mes, int codEmpresa}) _clave(int codEmpresa) =>
      (anio: widget.anio, mes: widget.mes, codEmpresa: codEmpresa);

  Future<void> _enviar(AsientoSapEntity asiento) async {
    final ok = await confirmar(
      context,
      titulo: 'Enviar asiento a SAP',
      detalle:
          'Se creará en ${asiento.baseSap} el asiento «${asiento.memo}», '
          'con ${asiento.lineas.length} líneas por '
          '${_fmt.format(asiento.totalDebito)}.\n\n'
          'Un asiento creado en SAP no se puede borrar desde aquí.',
      textoConfirmar: 'Sí, enviar',
    );
    if (!ok || !mounted) return;

    setState(() => _enviando = true);
    try {
      final mensaje = await ref
          .read(asientoSapRepoProvider)
          .enviar(
            anio: widget.anio,
            mes: widget.mes,
            codEmpresa: asiento.codEmpresa,
          );
      if (!mounted) return;
      avisar(context, mensaje);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      avisar(context, mensajeAsientoSap(e), esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compacto = ResponsiveUtilsBosque.isMobile(context);
    final empresas = ref.watch(asientoSapEmpresasProvider);
    final lista = empresas.valueOrNull ?? const <AsientoSapEmpresaEntity>[];
    // Con una sola empresa configurada no hay nada que elegir.
    final codEmpresa = _elegida ?? (lista.length == 1 ? lista.first.codEmpresa : null);
    final previa =
        codEmpresa == null
            ? null
            : ref.watch(asientoSapVistaPreviaProvider(_clave(codEmpresa)));
    final asiento = previa?.valueOrNull;
    final margen = compacto ? Esp.l : Esp.xl;

    return Dialog(
      insetPadding:
          compacto
              ? const EdgeInsets.all(Esp.m)
              : const EdgeInsets.symmetric(horizontal: Esp.xxl, vertical: Esp.xl),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 920,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cabecera(
              periodo: '${widget.nombreMes} ${widget.anio}',
              margen: margen,
              onCerrar: _enviando ? null : () => Navigator.pop(context),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(margen, Esp.l, margen, Esp.s),
              child: empresas.when(
                loading: () => const LinearProgressIndicator(),
                error:
                    (e, _) => NotaDelDato(
                      tono: TonoNota.error,
                      texto: mensajeAsientoSap(e),
                      accion: TextButton(
                        onPressed: () => ref.invalidate(asientoSapEmpresasProvider),
                        child: const Text('Reintentar'),
                      ),
                    ),
                data:
                    (lista) =>
                        lista.isEmpty
                            ? const NotaDelDato(
                              tono: TonoNota.aviso,
                              texto:
                                  'Ninguna empresa tiene el asiento en SAP listo para enviar. '
                                  'Se configura en Planillas > Asiento SAP: configuración '
                                  '(habilitada y con la contraseña del Service Layer cargada).',
                            )
                            : DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Empresa',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              isExpanded: true,
                              value: codEmpresa,
                              hint: const Text('Elige la empresa'),
                              items: [
                                for (final e in lista)
                                  DropdownMenuItem(
                                    value: e.codEmpresa,
                                    child: Text(e.empresa),
                                  ),
                              ],
                              onChanged:
                                  _enviando ? null : (v) => setState(() => _elegida = v),
                            ),
              ),
            ),
            if (previa != null)
              Flexible(
                child: previa.when(
                  loading:
                      () => Padding(
                        padding: const EdgeInsets.all(Esp.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: Esp.m),
                            Text('Armando el asiento…', style: context.apagado()),
                          ],
                        ),
                      ),
                  error:
                      (e, _) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: margen),
                        child: NotaDelDato(
                          tono: TonoNota.error,
                          texto: mensajeAsientoSap(e),
                          accion: TextButton(
                            onPressed:
                                () => ref.invalidate(
                                  asientoSapVistaPreviaProvider(_clave(codEmpresa!)),
                                ),
                            child: const Text('Reintentar'),
                          ),
                        ),
                      ),
                  data:
                      (a) =>
                          a == null
                              ? Padding(
                                padding: EdgeInsets.symmetric(horizontal: margen),
                                child: const NotaDelDato(
                                  texto: 'El servidor no devolvió el asiento.',
                                ),
                              )
                              : _Asiento(asiento: a, compacto: compacto, margen: margen),
                ),
              ),
            const SizedBox(height: Esp.m),
            const Divider(height: 1),
            _Pie(
              asiento: asiento,
              enviando: _enviando,
              compacto: compacto,
              margen: margen,
              onCerrar: _enviando ? null : () => Navigator.pop(context),
              onEnviar:
                  asiento != null && asiento.cuadra && !_enviando
                      ? () => _enviar(asiento)
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.periodo,
    required this.margen,
    required this.onCerrar,
  });

  final String periodo;
  final double margen;
  final VoidCallback? onCerrar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      color: cs.primaryContainer,
      padding: EdgeInsets.fromLTRB(margen, Esp.l, Esp.s, Esp.l),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Esp.s),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(Esquina.chica),
            ),
            child: Icon(Icons.receipt_long, color: cs.onPrimary),
          ),
          const SizedBox(width: Esp.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asiento contable en SAP',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: Peso.dato,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Planilla de $periodo',
                  style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onCerrar,
            icon: Icon(Icons.close, color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _Asiento extends StatelessWidget {
  const _Asiento({
    required this.asiento,
    required this.compacto,
    required this.margen,
  });

  final AsientoSapEntity asiento;
  final bool compacto;
  final double margen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colorDiferencia = asiento.cuadra ? cs.primary : cs.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: margen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(asiento.memo, style: context.tituloSeccion()),
              const SizedBox(height: Esp.xs),
              Wrap(
                spacing: Esp.l,
                runSpacing: Esp.xs,
                children: [
                  _Dato(icono: Icons.event_outlined, texto: asiento.fecha),
                  _Dato(icono: Icons.tag, texto: asiento.referencia),
                  _Dato(icono: Icons.storage_outlined, texto: asiento.baseSap),
                  _Dato(
                    icono: Icons.format_list_numbered,
                    texto: '${asiento.lineas.length} líneas',
                  ),
                ],
              ),
              const SizedBox(height: Esp.m),
              Wrap(
                spacing: Esp.s,
                runSpacing: Esp.s,
                children: [
                  _Total(etiqueta: 'Débito', monto: asiento.totalDebito, compacto: compacto),
                  _Total(etiqueta: 'Crédito', monto: asiento.totalCredito, compacto: compacto),
                  _Total(
                    etiqueta: 'Diferencia',
                    monto: asiento.diferencia,
                    compacto: compacto,
                    color: colorDiferencia,
                  ),
                ],
              ),
              const SizedBox(height: Esp.m),
            ],
          ),
        ),
        // La tabla es lo único que hace scroll: los totales y el botón quedan a la vista.
        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: margen),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(shape: contornoSuperficie(cs)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: cs.surfaceContainerHighest,
                  child: _Linea(
                    codigo: 'Código',
                    nombre: 'Cuenta / socio de negocio',
                    debito: 'Débito',
                    credito: 'Crédito',
                    compacto: compacto,
                    estilo: context.apagado()?.copyWith(fontWeight: Peso.titulo),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < asiento.lineas.length; i++)
                          Container(
                            color:
                                i.isOdd
                                    ? cs.surfaceContainerLow.withValues(alpha: 0.6)
                                    : null,
                            child: _filaDe(context, asiento.lineas[i]),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filaDe(BuildContext context, AsientoSapLineaEntity l) => _Linea(
    codigo: l.codigo,
    nombre: l.nombre,
    detalle: l.socio == null || l.cuenta.isEmpty ? null : 'Socio · cta. ${l.cuenta}',
    debito: l.debito == 0 ? '' : _fmt.format(l.debito),
    credito: l.credito == 0 ? '' : _fmt.format(l.credito),
    compacto: compacto,
    estilo: context.numero(),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: Esp.xs),
      Text(texto, style: context.apagado()),
    ],
  );
}

class _Total extends StatelessWidget {
  const _Total({
    required this.etiqueta,
    required this.monto,
    required this.compacto,
    this.color,
  });

  final String etiqueta;
  final double monto;
  final bool compacto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: compacto ? 150 : 200,
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      decoration: ShapeDecoration(shape: contornoSuperficie(cs)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta.toUpperCase(), style: context.apagado()?.copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(
            _fmt.format(monto),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila de la tabla. En pantallas chicas el monto se marca con D o C, para
/// que el nombre no quede sin espacio.
class _Linea extends StatelessWidget {
  const _Linea({
    required this.codigo,
    required this.nombre,
    required this.debito,
    required this.credito,
    required this.compacto,
    required this.estilo,
    this.detalle,
  });

  final String codigo;
  final String nombre;
  final String? detalle;
  final String debito;
  final String credito;
  final bool compacto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final nombreYDetalle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nombre, style: estilo, overflow: TextOverflow.ellipsis),
        if (detalle != null) Text(detalle!, style: context.apagado()),
      ],
    );

    if (compacto) {
      final monto =
          debito.isNotEmpty && credito.isNotEmpty
              ? '$debito\n$credito'
              : debito.isNotEmpty
              ? 'D $debito'
              : credito.isNotEmpty
              ? 'C $credito'
              : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (codigo.isNotEmpty) Text(codigo, style: context.apagado()),
                  nombreYDetalle,
                ],
              ),
            ),
            const SizedBox(width: Esp.s),
            Text(monto, style: estilo, textAlign: TextAlign.right),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Esp.m, vertical: Esp.s),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(codigo, style: estilo)),
          Expanded(child: nombreYDetalle),
          SizedBox(
            width: 130,
            child: Text(debito, style: estilo, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 130,
            child: Text(credito, style: estilo, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({
    required this.asiento,
    required this.enviando,
    required this.compacto,
    required this.margen,
    required this.onCerrar,
    required this.onEnviar,
  });

  final AsientoSapEntity? asiento;
  final bool enviando;
  final bool compacto;
  final double margen;
  final VoidCallback? onCerrar;
  final VoidCallback? onEnviar;

  @override
  Widget build(BuildContext context) {
    final a = asiento;
    final estado =
        a == null
            ? const SizedBox.shrink()
            : a.cuadra
            ? const Etiqueta(texto: 'Cuadra', tono: TonoEtiqueta.exito)
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Etiqueta(texto: 'No cuadra', tono: TonoEtiqueta.error),
                const SizedBox(width: Esp.s),
                Flexible(
                  child: Text(
                    'No se puede enviar',
                    style: context.apagado(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
    // OverflowBar: si en un teléfono angosto no entran lado a lado, se apilan en vez de desbordar.
    final botones = OverflowBar(
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      spacing: Esp.s,
      overflowSpacing: Esp.xs,
      children: [
        TextButton(onPressed: onCerrar, child: const Text('Cerrar')),
        BotonAccion(
          etiqueta: 'Enviar a SAP',
          etiquetaOcupado: 'Enviando',
          icono: Icons.cloud_upload_outlined,
          ocupado: enviando,
          onPressed: onEnviar,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(margen, Esp.m, margen, Esp.m),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: estado),
                  const SizedBox(height: Esp.s),
                  Align(alignment: Alignment.centerRight, child: botones),
                ],
              )
              : Row(
                children: [
                  Expanded(child: Align(alignment: Alignment.centerLeft, child: estado)),
                  Flexible(child: botones),
                ],
              ),
    );
  }
}
