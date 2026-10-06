/// Los dialogos de las acciones del cheque: nueva fecha de cobro, devolver y
/// cerrar (con o sin verificacion). Los cuatro mandan un `AccionChequeRequest`
/// y comparten el mismo formulario; cambia que campos lleva cada uno.
///
/// Que accion esta habilitada la decide el servidor (rama K, `botones` del
/// detalle) y las vuelve a comprobar al ejecutarlas: aqui no se calcula. Si el
/// usuario llega a un dialogo que el servidor rechaza (la fila de la grilla abre
/// «Fecha de cobro» sin consultar el detalle), su mensaje se muestra tal cual.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/catalogos_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/reglas_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

/// Las cuatro acciones del detalle, en el orden de los botones de la rama K.
enum TipoAccionCheque {
  fechaCobro('Fecha de cobro', Icons.event_repeat_outlined),
  devolver('Devolver', Icons.undo_outlined),
  cerrarConVerificacion('Cerrar con verificación', Icons.verified_outlined),
  cerrarSinVerificacion('Cerrar sin verificación', Icons.lock_outline);

  const TipoAccionCheque(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;

  bool get cierra =>
      this == cerrarConVerificacion || this == cerrarSinVerificacion;
}

/// Abre el dialogo de [tipo] para [cheque]. Devuelve true si se guardo.
Future<bool?> abrirAccionCheque(
  BuildContext context, {
  required ChequeFilaEntity cheque,
  required TipoAccionCheque tipo,
}) {
  // El error de una escritura anterior no debe aparecer en un dialogo nuevo.
  ProviderScope.containerOf(
    context,
  ).read(operacionesChequesProvider.notifier).limpiarError();
  return abrirPanelCheque<bool>(
    context,
    anchoMaximo: 560,
    contenido: (_) => _DialogoAccionCheque(cheque: cheque, tipo: tipo),
  );
}

class _DialogoAccionCheque extends ConsumerStatefulWidget {
  const _DialogoAccionCheque({required this.cheque, required this.tipo});

  final ChequeFilaEntity cheque;
  final TipoAccionCheque tipo;

  @override
  ConsumerState<_DialogoAccionCheque> createState() =>
      _DialogoAccionChequeState();
}

class _DialogoAccionChequeState extends ConsumerState<_DialogoAccionCheque> {
  final _form = GlobalKey<FormState>();
  final _nroSap = TextEditingController();
  final _observacion = TextEditingController();

  late final DateTime _hoy = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }();

  late DateTime? _fecha = _hoy;
  DateTime? _nuevaFechaCobro;
  String? _estado;
  bool _intentado = false;

  TipoAccionCheque get _tipo => widget.tipo;

  @override
  void dispose() {
    _nroSap.dispose();
    _observacion.dispose();
    super.dispose();
  }

  /// Los estados entre los que se elige, o null si el estado es fijo.
  List<OpcionChequeEntity>? _opciones(CatalogosChequeEntity c) => switch (_tipo) {
    TipoAccionCheque.fechaCobro => c.accionesFechaCobro,
    TipoAccionCheque.cerrarSinVerificacion => c.accionesCierreSinVerificacion,
    _ => null,
  };

  /// El estado que fija el propio boton: DEV al devolver, COB al cerrar con
  /// verificacion.
  String? get _estadoFijo => switch (_tipo) {
    TipoAccionCheque.devolver => AccionChequeEntity.devuelto,
    TipoAccionCheque.cerrarConVerificacion => AccionChequeEntity.cobrado,
    _ => null,
  };

  /// La nueva fecha de cobro no tiene tope con `btnEditar3CH` o siendo
  /// administrador; sin eso, +-28 dias de la fecha del cheque.
  bool get _sinLimite =>
      ref.read(permisosChequeProvider).fechaCobroSinLimite ||
      widget.cheque.cheque.fechaCheque == null;

  ({DateTime desde, DateTime hasta})? get _rango =>
      _sinLimite
          ? null
          : ReglasCheque.rangoCobro(widget.cheque.cheque.fechaCheque!);

  Future<void> _guardar() async {
    setState(() => _intentado = true);
    if (!(_form.currentState?.validate() ?? false)) {
      avisar(context, 'Revisa los campos marcados en rojo.', esError: true);
      return;
    }

    final obs = _observacion.text.trim();
    final pedido = AccionChequeRequestEntity(
      codCheque: widget.cheque.codCheque,
      fecha: _fecha,
      estado: _estadoFijo ?? _estado,
      nroSap: _tipo.cierra ? _nroSap.text.trim() : null,
      observacion: obs.isEmpty ? null : obs,
      conVerificacion: _tipo.cierra
          ? _tipo == TipoAccionCheque.cerrarConVerificacion
          : null,
      nuevaFechaCobro: _tipo == TipoAccionCheque.fechaCobro ? _nuevaFechaCobro : null,
    );

    final ops = ref.read(operacionesChequesProvider.notifier);
    final id = switch (_tipo) {
      TipoAccionCheque.fechaCobro => await ops.cambiarFechaCobro(pedido),
      TipoAccionCheque.devolver => await ops.devolver(pedido),
      TipoAccionCheque.cerrarConVerificacion ||
      TipoAccionCheque.cerrarSinVerificacion => await ops.cerrar(pedido),
    };
    // El error, si lo hubo, queda en el estado y se dibuja en el dialogo.
    if (id == null || !mounted) return;
    avisar(
      context,
      switch (_tipo) {
        TipoAccionCheque.fechaCobro => 'Fecha de cobro actualizada.',
        TipoAccionCheque.devolver => 'Devolución registrada.',
        _ => 'Cheque cerrado.',
      },
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesChequesProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesChequesProvider.select((s) => s.error),
    );
    final catalogos =
        ref.watch(catalogosChequeProvider).valueOrNull ??
        CatalogosChequeEntity.vacio;
    final c = widget.cheque;
    final opciones = _opciones(catalogos);
    final rango = _rango;

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        Text(switch (_tipo) {
          TipoAccionCheque.fechaCobro =>
            'Cambia la fecha de cobro del cheque y deja constancia en el '
                'historial. Fecha de cobro actual: '
                '${textoFecha(c.cheque.fechaCobrar)}.',
          TipoAccionCheque.devolver =>
            'Registra que el cheque volvió de cobranza.',
          TipoAccionCheque.cerrarConVerificacion =>
            'Cierra el cheque como cobrado. Pide el nro. de SAP.',
          TipoAccionCheque.cerrarSinVerificacion =>
            'Cierra el cheque sin verificación de depósito: elige cómo se '
                'resolvió. Pide el nro. de SAP.',
        }, style: context.apagado()),
        const SizedBox(height: Esp.l),
        CampoFechaCheque(
          etiqueta: 'Fecha de la acción',
          valor: _fecha,
          primera: _hoy,
          ultima: DateTime(_hoy.year + 2),
          onCambio: (f) => setState(() => _fecha = f),
          validar:
              (f) =>
                  f != null && f.isBefore(_hoy)
                      ? 'La fecha no puede ser anterior a hoy.'
                      : null,
        ),
        const SizedBox(height: Esp.l),
        if (opciones != null)
          DropdownButtonFormField<String>(
            key: ValueKey('estado-accion-$_estado-${opciones.length}'),
            value: opciones.any((o) => o.codigo == _estado) ? _estado : null,
            isExpanded: true,
            items: [
              for (final o in opciones)
                DropdownMenuItem(
                  value: o.codigo,
                  child: Text(o.nombre, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged:
                opciones.isEmpty ? null : (v) => setState(() => _estado = v),
            decoration: const InputDecoration(
              labelText: 'Estado de la acción',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null ? 'Elige el estado.' : null,
          )
        else
          InputDecorator(
            isEmpty: false,
            decoration: const InputDecoration(
              labelText: 'Estado de la acción',
              enabled: false,
              isDense: true,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.lock_outline, size: 16),
            ),
            child: Text(
              catalogos.nombreEstadoAccion(_estadoFijo!),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (_tipo == TipoAccionCheque.fechaCobro) ...[
          const SizedBox(height: Esp.l),
          CampoFechaCheque(
            etiqueta: 'Nueva fecha de cobro',
            valor: _nuevaFechaCobro,
            primera: rango?.desde,
            ultima: rango?.hasta,
            ayuda:
                rango == null
                    ? null
                    : 'Entre ${textoFecha(rango.desde)} y '
                        '${textoFecha(rango.hasta)}: '
                        '${ReglasCheque.diasToleranciaCobro} días a cada lado '
                        'de la fecha del cheque.',
            onCambio: (f) => setState(() => _nuevaFechaCobro = f),
            validar: (f) {
              final cheque = c.cheque.fechaCheque;
              if (f == null || rango == null || cheque == null) return null;
              return ReglasCheque.cobroEnRango(f, cheque)
                  ? null
                  : 'La fecha de cobro debe estar a '
                      '${ReglasCheque.diasToleranciaCobro} días o menos de la '
                      'fecha del cheque.';
            },
          ),
        ],
        if (_tipo.cierra) ...[
          const SizedBox(height: Esp.l),
          TextFormField(
            key: const ValueKey('campo-nro-sap'),
            controller: _nroSap,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nro. de SAP',
              helperText: 'Obligatorio para finalizar el cheque.',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            validator: (t) {
              final v = (t ?? '').trim();
              if (v.isEmpty) {
                return 'Ingresa el nro. de SAP para finalizar el cheque.';
              }
              return ReglasCheque.errorNroSap(v);
            },
          ),
        ],
        const SizedBox(height: Esp.l),
        TextFormField(
          key: const ValueKey('campo-observacion-accion'),
          controller: _observacion,
          maxLength: 200,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Observación',
            helperText: 'Opcional.',
            border: OutlineInputBorder(),
          ),
          validator: (t) => ReglasCheque.errorObservacion(t?.trim()),
        ),
      ],
    );

    return Form(
      key: _form,
      autovalidateMode:
          _intentado ? AutovalidateMode.always : AutovalidateMode.disabled,
      child: MarcoPanelCheque(
        titulo: _tipo.etiqueta,
        subtitulo: 'Cheque ${c.cheque.nrocheque} · ${c.datoCliente}',
        onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: cuerpo,
        acciones: [
          TextButton(
            onPressed: ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BotonGuardarCheque(
            etiqueta: switch (_tipo) {
              TipoAccionCheque.fechaCobro => 'Guardar fecha de cobro',
              TipoAccionCheque.devolver => 'Devolver cheque',
              _ => 'Finalizar cheque',
            },
            icono: _tipo.cierra ? Icons.lock_outline : Icons.save_outlined,
            ocupado: ocupado,
            onPressed: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }
}
