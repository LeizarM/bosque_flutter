/// Los tres dialogos «Nuevo» de los paneles del detalle: nota de remision,
/// transaccion bancaria y postergacion. Reemplazan a `notaRemisionModal`,
/// `nroTransacc` y `pdamPostergacionModal` de `cheque.xhtml`.
///
/// **Validan en linea** (mientras se escribe y al guardar) lo que el legacy
/// exige —`reglas_paneles_cheque.dart`— para dar el motivo junto al campo. El
/// servidor repite todas las reglas y su mensaje se muestra **completo y tal
/// cual** arriba del formulario, con el dialogo abierto.
///
/// Los tres exigen `btnNuevoNRCH`; el servidor lo comprueba, la pantalla solo
/// decide si dibuja el boton que los abre.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart'
    show obtenerBancos;
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/domain/utils/reglas_paneles_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

DateTime _hoy() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Abre [dialogo] como panel. Antes borra el error de una escritura anterior:
/// no debe aparecer en un dialogo nuevo.
Future<bool?> _abrir(
  BuildContext context, {
  required WidgetBuilder dialogo,
  double anchoMaximo = 520,
}) {
  ProviderScope.containerOf(
    context,
  ).read(operacionesPanelesChequeProvider.notifier).limpiarError();
  return abrirPanelCheque<bool>(
    context,
    anchoMaximo: anchoMaximo,
    contenido: dialogo,
  );
}

/// El pie comun de los tres: «Cancelar» y el boton de guardar.
List<Widget> _acciones(
  BuildContext context, {
  required bool ocupado,
  required String etiqueta,
  required VoidCallback guardar,
}) => [
  TextButton(
    onPressed: ocupado ? null : () => Navigator.of(context).pop(),
    child: const Text('Cancelar'),
  ),
  BotonGuardarCheque(
    etiqueta: etiqueta,
    ocupado: ocupado,
    onPressed: ocupado ? null : guardar,
  ),
];

String _subtituloDelCheque(ChequeFilaEntity c) =>
    'Cheque ${c.cheque.nrocheque} · ${c.datoCliente}';

// ═══════════════════════════════════════════════════════════════════════════
// NOTA DE REMISION
// ═══════════════════════════════════════════════════════════════════════════

/// Abre el dialogo de una nota de remision nueva para [cheque]. Devuelve true si
/// se guardo.
Future<bool?> abrirNuevaNotaRemision(
  BuildContext context, {
  required ChequeFilaEntity cheque,
}) => _abrir(context, dialogo: (_) => _DialogoNotaRemision(cheque: cheque));

class _DialogoNotaRemision extends ConsumerStatefulWidget {
  const _DialogoNotaRemision({required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  ConsumerState<_DialogoNotaRemision> createState() =>
      _DialogoNotaRemisionState();
}

class _DialogoNotaRemisionState extends ConsumerState<_DialogoNotaRemision> {
  final _form = GlobalKey<FormState>();
  final _nota = TextEditingController();
  final _factura = TextEditingController();
  DateTime? _fecha;

  @override
  void dispose() {
    _nota.dispose();
    _factura.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final fechaError = ReglasPanelesCheque.errorFechaRequerida(
      _fecha,
      campo: 'la fecha de la factura',
    );
    final ok = (_form.currentState?.validate() ?? false) && fechaError == null;
    if (!ok) {
      avisar(context, 'Revisa los campos marcados en rojo.', esError: true);
      return;
    }
    final guardada = await ref
        .read(operacionesPanelesChequeProvider.notifier)
        .registrarNotaRemision(
          NotaRemisionChequeEntity(
            codCheque: widget.cheque.codCheque,
            notaRemision: _nota.text.trim(),
            nroFactura: int.parse(_factura.text.trim()),
            fechaFactura: _fecha,
          ),
        );
    // El error, si lo hubo, queda en el estado y se dibuja en el dialogo.
    if (!guardada || !mounted) return;
    avisar(context, 'Nota de remisión registrada.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesPanelesChequeProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesPanelesChequeProvider.select((s) => s.error),
    );

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        Text(
          'Registra la nota de remisión que acompaña a la factura de este '
          'cheque.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.l),
        TextFormField(
          key: const ValueKey('campo-nota-remision'),
          controller: _nota,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              ReglasPanelesCheque.notaRemisionMax,
            ),
          ],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            // El motivo del error va completo: los mensajes son largos a proposito.
            errorMaxLines: 6,
            helperMaxLines: 2,
            labelText: 'Nota de remisión',
            helperText: 'De 5 a 10 dígitos.',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          validator: ReglasPanelesCheque.errorNotaRemision,
        ),
        const SizedBox(height: Esp.l),
        TextFormField(
          key: const ValueKey('campo-nro-factura'),
          controller: _factura,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              ReglasPanelesCheque.nroFacturaMaxDigitos,
            ),
          ],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            // El motivo del error va completo: los mensajes son largos a proposito.
            errorMaxLines: 6,
            helperMaxLines: 2,
            labelText: 'Nro. de factura',
            helperText: 'El de la factura SAP: de 1 a 999999.',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          validator: ReglasPanelesCheque.errorNroFactura,
        ),
        const SizedBox(height: Esp.l),
        CampoFechaCheque(
          etiqueta: 'Fecha de la factura',
          valor: _fecha,
          onCambio: (f) => setState(() => _fecha = f),
          // Su mensaje explicito (el generico del campo dice solo «Indica la fecha»).
          obligatorio: false,
          validar:
              (f) => ReglasPanelesCheque.errorFechaRequerida(
                f,
                campo: 'la fecha de la factura',
              ),
        ),
      ],
    );

    return Form(
      key: _form,
      child: MarcoPanelCheque(
        titulo: 'Nueva nota de remisión',
        subtitulo: _subtituloDelCheque(widget.cheque),
        onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: cuerpo,
        acciones: _acciones(
          context,
          ocupado: ocupado,
          etiqueta: 'Guardar nota',
          guardar: _guardar,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRANSACCION BANCARIA
// ═══════════════════════════════════════════════════════════════════════════

/// Abre el dialogo de una transaccion bancaria nueva para [cheque]. Devuelve
/// true si se guardo.
Future<bool?> abrirNuevaTransaccion(
  BuildContext context, {
  required ChequeFilaEntity cheque,
}) => _abrir(context, dialogo: (_) => _DialogoTransaccion(cheque: cheque));

class _DialogoTransaccion extends ConsumerStatefulWidget {
  const _DialogoTransaccion({required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  ConsumerState<_DialogoTransaccion> createState() =>
      _DialogoTransaccionState();
}

class _DialogoTransaccionState extends ConsumerState<_DialogoTransaccion> {
  final _form = GlobalKey<FormState>();
  final _nro = TextEditingController();

  /// Como el legacy, la fecha arranca en hoy.
  DateTime? _fecha = _hoy();
  int? _codBanco;

  @override
  void dispose() {
    _nro.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final fechaError = ReglasPanelesCheque.errorFechaRequerida(
      _fecha,
      campo: 'la fecha de la transacción',
    );
    final ok = (_form.currentState?.validate() ?? false) && fechaError == null;
    if (!ok) {
      avisar(context, 'Revisa los campos marcados en rojo.', esError: true);
      return;
    }
    final guardada = await ref
        .read(operacionesPanelesChequeProvider.notifier)
        .registrarTransaccion(
          TransaccionBancariaEntity(
            codCheque: widget.cheque.codCheque,
            nroTransaccion: _nro.text.trim(),
            codBanco: _codBanco!,
            fechaTransaccion: _fecha,
          ),
        );
    if (!guardada || !mounted) return;
    avisar(context, 'Transacción bancaria registrada.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesPanelesChequeProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesPanelesChequeProvider.select((s) => s.error),
    );
    final bancosAsync = ref.watch(obtenerBancos);
    final bancos = bancosAsync.valueOrNull ?? const <BancoEntity>[];

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        Text(
          'Anota el número de transacción que da el banco cuando el cheque se '
          'deposita o se transfiere.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.l),
        TextFormField(
          key: const ValueKey('campo-nro-transaccion'),
          controller: _nro,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              ReglasPanelesCheque.nroTransaccionMax,
            ),
          ],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            // El motivo del error va completo: los mensajes son largos a proposito.
            errorMaxLines: 6,
            helperMaxLines: 2,
            labelText: 'Nro. de transacción',
            helperText: 'Tal como lo da el banco: de 5 a 30 caracteres.',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          validator: ReglasPanelesCheque.errorNroTransaccion,
        ),
        const SizedBox(height: Esp.l),
        DropdownButtonFormField<int>(
          key: ValueKey('banco-transaccion-$_codBanco-${bancos.length}'),
          value: bancos.any((b) => b.codBanco == _codBanco) ? _codBanco : null,
          isExpanded: true,
          items: [
            for (final b in bancos)
              DropdownMenuItem(
                value: b.codBanco,
                child: Text(b.nombre, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: bancos.isEmpty ? null : (v) => setState(() => _codBanco = v),
          decoration: const InputDecoration(
            // El motivo del error va completo: los mensajes son largos a proposito.
            errorMaxLines: 6,
            helperMaxLines: 2,
            labelText: 'Banco',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          validator: (v) => v == null ? 'Falta elegir el banco.' : null,
        ),
        if (bancosAsync.hasError)
          NotaDelDato(
            tono: TonoNota.aviso,
            texto: 'No se pudo cargar la lista de bancos.',
            accion: TextButton(
              onPressed: () => ref.invalidate(obtenerBancos),
              child: const Text('Reintentar'),
            ),
          ),
        const SizedBox(height: Esp.l),
        CampoFechaCheque(
          etiqueta: 'Fecha de la transacción',
          valor: _fecha,
          onCambio: (f) => setState(() => _fecha = f),
          // Su mensaje explicito (el generico del campo dice solo «Indica la fecha»).
          obligatorio: false,
          validar:
              (f) => ReglasPanelesCheque.errorFechaRequerida(
                f,
                campo: 'la fecha de la transacción',
              ),
        ),
      ],
    );

    return Form(
      key: _form,
      child: MarcoPanelCheque(
        titulo: 'Nueva transacción bancaria',
        subtitulo: _subtituloDelCheque(widget.cheque),
        onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: cuerpo,
        acciones: _acciones(
          context,
          ocupado: ocupado,
          etiqueta: 'Guardar transacción',
          guardar: _guardar,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POSTERGACION
// ═══════════════════════════════════════════════════════════════════════════

/// Abre el dialogo de una postergacion nueva para [cheque]. Devuelve true si se
/// guardo. El PDF se carga despues, desde la fila (es otro paso, como en el
/// legacy: el alta no lo recibe).
Future<bool?> abrirNuevaPostergacion(
  BuildContext context, {
  required ChequeFilaEntity cheque,
}) => _abrir(context, dialogo: (_) => _DialogoPostergacion(cheque: cheque));

class _DialogoPostergacion extends ConsumerStatefulWidget {
  const _DialogoPostergacion({required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  ConsumerState<_DialogoPostergacion> createState() =>
      _DialogoPostergacionState();
}

class _DialogoPostergacionState extends ConsumerState<_DialogoPostergacion> {
  final _form = GlobalKey<FormState>();
  final _motivo = TextEditingController();

  /// Sin valor de entrada, como el legacy: la fecha se elige a conciencia.
  DateTime? _fecha;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final fechaError = ReglasPanelesCheque.errorFechaRequerida(
      _fecha,
      campo: 'la fecha de la postergación',
    );
    final ok = (_form.currentState?.validate() ?? false) && fechaError == null;
    if (!ok) {
      avisar(context, 'Revisa los campos marcados en rojo.', esError: true);
      return;
    }
    final cod = await ref
        .read(operacionesPanelesChequeProvider.notifier)
        .registrarPostergacion(
          PostergacionEntity(
            codPostergacion: BigInt.zero,
            codCheque: widget.cheque.codCheque,
            fecha: _fecha,
            observacion: _motivo.text.trim(),
          ),
        );
    if (cod == null || !mounted) return;
    avisar(context, 'Postergación registrada.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesPanelesChequeProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesPanelesChequeProvider.select((s) => s.error),
    );

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorServidor != null) ...[
          ErrorServidorCheque(errorServidor),
          const SizedBox(height: Esp.l),
        ],
        Text(
          'Deja constancia de que el cobro se movió: la fecha y por qué. El '
          'PDF de la carta del cliente, si la hay, se carga después desde la '
          'postergación.',
          style: context.apagado(),
        ),
        const SizedBox(height: Esp.l),
        CampoFechaCheque(
          etiqueta: 'Fecha de la postergación',
          valor: _fecha,
          onCambio: (f) => setState(() => _fecha = f),
          // Su mensaje explicito (el generico del campo dice solo «Indica la fecha»).
          obligatorio: false,
          validar:
              (f) => ReglasPanelesCheque.errorFechaRequerida(
                f,
                campo: 'la fecha de la postergación',
              ),
        ),
        const SizedBox(height: Esp.l),
        TextFormField(
          key: const ValueKey('campo-observacion-postergacion'),
          controller: _motivo,
          maxLength: ReglasPanelesCheque.observacionMax,
          minLines: 3,
          maxLines: 6,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            // El motivo del error va completo: los mensajes son largos a proposito.
            errorMaxLines: 6,
            helperMaxLines: 2,
            labelText: 'Motivo',
            alignLabelWithHint: true,
            helperText: 'Por qué se posterga el cobro. Mínimo 3 caracteres.',
            border: OutlineInputBorder(),
          ),
          validator: ReglasPanelesCheque.errorObservacionPostergacion,
        ),
      ],
    );

    return Form(
      key: _form,
      child: MarcoPanelCheque(
        titulo: 'Nueva postergación',
        subtitulo: _subtituloDelCheque(widget.cheque),
        onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: cuerpo,
        acciones: _acciones(
          context,
          ocupado: ocupado,
          etiqueta: 'Guardar postergación',
          guardar: _guardar,
        ),
      ),
    );
  }
}
