/// Dialogos cortos del modulo de garantias: documento, accion, extension,
/// firmas y protesta, traspaso y reporte.
///
/// Todos escriben a traves de [OperacionesGarantiasNotifier], que al salir
/// bien invalida las lecturas afectadas: la pantalla de atras se refresca sola.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ESCRIBIR Y AVISAR
// ═══════════════════════════════════════════════════════════════════════════

/// Corre una escritura del notifier y cuenta como salio. Devuelve si salio
/// bien. El mensaje de error es el del backend, que viene listo para mostrar.
Future<bool> escribirConAviso<T>(
  BuildContext context,
  WidgetRef ref,
  Future<T?> Function(OperacionesGarantiasNotifier n) escritura, {
  required String exito,
}) async {
  final notifier = ref.read(operacionesGarantiasProvider.notifier);
  final r = await escritura(notifier);
  if (!context.mounted) return r != null;
  if (r == null) {
    avisar(
      context,
      ref.read(operacionesGarantiasProvider).error ??
          'No se pudo completar la operación.',
      esError: true,
    );
    notifier.limpiarError();
    return false;
  }
  HapticFeedback.mediumImpact();
  avisar(context, exito);
  return true;
}

/// Genera un PDF y lo muestra en el visor. El error del reporte, si lo hay,
/// llega con el mensaje del backend.
Future<void> verPdf(
  BuildContext context, {
  required Future<Uint8List> Function() generar,
  required String titulo,
  required String nombreArchivo,
}) async {
  final cerrarEspera = _mostrarEspera(context, 'Generando el PDF…');
  try {
    final bytes = await generar();
    cerrarEspera();
    if (!context.mounted) return;
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: titulo,
      nombreArchivo: nombreArchivo,
    );
  } catch (e) {
    cerrarEspera();
    if (!context.mounted) return;
    avisar(context, textoParaUsuario(e), esError: true);
  }
}

VoidCallback _mostrarEspera(BuildContext context, String texto) {
  var cerrado = false;
  final navegador = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder:
        (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Esp.l),
                Expanded(child: Text(texto)),
              ],
            ),
          ),
        ),
  );
  return () {
    if (cerrado) return;
    cerrado = true;
    navegador.pop();
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// DOCUMENTO: ALTA Y CAMBIO DE MONTO
// ═══════════════════════════════════════════════════════════════════════════

/// Agrega un documento a una garantia guardada, o cambia el monto de uno
/// existente (lo unico editable: el procedimiento ignora tipo y texto).
Future<bool?> abrirDocumento(
  BuildContext context, {
  required BigInt codGarantia,
  CbrDetalleEntity? existente,
}) => abrirPanel<bool>(
  context,
  anchoMaximo: 520,
  contenido:
      (_) => _DialogoDocumento(codGarantia: codGarantia, existente: existente),
);

class _DialogoDocumento extends ConsumerStatefulWidget {
  const _DialogoDocumento({required this.codGarantia, this.existente});

  final BigInt codGarantia;
  final CbrDetalleEntity? existente;

  @override
  ConsumerState<_DialogoDocumento> createState() => _DialogoDocumentoState();
}

class _DialogoDocumentoState extends ConsumerState<_DialogoDocumento> {
  final _form = GlobalKey<FormState>();
  late final _monto = TextEditingController(
    text: textoMonto(widget.existente?.montoGarantiaParc),
  );
  final _detalle = TextEditingController();
  String? _tipo;

  bool get _esAlta => widget.existente == null;

  @override
  void dispose() {
    _monto.dispose();
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final detalle =
        _esAlta
            ? CbrDetalleEntity.nuevo(
              codGarantia: widget.codGarantia,
              tipoGarantia: _tipo!,
              detalle:
                  _detalle.text.trim().isEmpty ? null : _detalle.text.trim(),
              montoGarantiaParc: leerMonto(_monto.text),
            )
            : widget.existente!.copyWith(
              montoGarantiaParc: leerMonto(_monto.text),
            );
    final ok = await escribirConAviso(
      context,
      ref,
      (n) => n.registrarDetalle(detalle),
      exito: _esAlta ? 'Documento agregado.' : 'Monto actualizado.',
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((s) => s.ocupado),
    );
    final catalogo = ref.watch(tiposGarantiaProvider).valueOrNull;
    final e = widget.existente;

    return Form(
      key: _form,
      child: MarcoPanel(
        titulo: _esAlta ? 'Agregar documento' : 'Cambiar monto',
        subtitulo:
            _esAlta
                ? 'La suma de documentos de la garantía se recalcula al guardar.'
                : '${nombreDeTipo(catalogo, e!.tipoGarantia)}'
                    '${(e.detalle ?? '').isEmpty ? '' : ' · ${e.detalle}'}',
        onCerrar: ocupado ? () {} : null,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_esAlta) ...[
              DropdownButtonFormField<String>(
                value: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final TipoCbrEntity t in catalogo ?? const [])
                    DropdownMenuItem(value: t.codTipos, child: Text(t.nombre)),
                ],
                onChanged: (v) => setState(() => _tipo = v),
                validator: (v) => v == null ? 'Elija el tipo' : null,
              ),
              const SizedBox(height: Esp.l),
            ],
            CampoMonto(
              etiqueta: 'Monto',
              controlador: _monto,
              permitirCero: false,
            ),
            if (_esAlta) ...[
              const SizedBox(height: Esp.l),
              TextFormField(
                controller: _detalle,
                maxLength: 299,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Detalle',
                  hintText: 'N° de documento, ubicación del bien…',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        acciones: [
          TextButton(
            onPressed: ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BotonAccion(
            etiqueta: _esAlta ? 'Agregar documento' : 'Guardar monto',
            etiquetaOcupado: 'Guardando…',
            icono: Icons.save_outlined,
            ocupado: ocupado,
            onPressed: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

/// Pide confirmacion y da de baja un documento.
Future<void> eliminarDocumento(
  BuildContext context,
  WidgetRef ref,
  CbrDetalleEntity detalle,
  String nombreTipo,
) async {
  final seguro = await confirmar(
    context,
    titulo: '¿Eliminar este documento?',
    detalle:
        '$nombreTipo por ${monto(detalle.monto)}. La suma de documentos de la '
        'garantía se recalcula al eliminarlo.',
    textoConfirmar: 'Eliminar documento',
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;
  await escribirConAviso(
    context,
    ref,
    (n) => n.eliminarDetalle(detalle.codDetalle),
    exito: 'Documento eliminado.',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ACCION: ALTA Y EDICION DE OBSERVACION
// ═══════════════════════════════════════════════════════════════════════════

/// Alta de una nota o edicion de la observacion de una accion existente.
///
/// El cierre NO se elige aqui junto con la nota: tiene su propia entrada,
/// [abrirCierre], porque es definitivo y el usuario tiene que saber que lo es
/// antes de empezar a escribir.
Future<bool?> abrirAccion(
  BuildContext context, {
  required GarantiaVistaEntity garantia,
  AccionCbrEntity? existente,
}) => abrirPanel<bool>(
  context,
  anchoMaximo: 520,
  contenido: (_) => _DialogoAccion(garantia: garantia, existente: existente),
);

/// Cierre de una garantia (accion CER). Explica que se pierde, pide el motivo
/// y exige confirmar que se entiende que es definitivo. Sin traspaso previo no
/// deja confirmar: el backend lo rechazaria igual.
Future<bool?> abrirCierre(BuildContext context, GarantiaVistaEntity garantia) =>
    abrirPanel<bool>(
      context,
      anchoMaximo: 560,
      contenido: (_) => _DialogoAccion(garantia: garantia, cierre: true),
    );

class _DialogoAccion extends ConsumerStatefulWidget {
  const _DialogoAccion({
    required this.garantia,
    this.existente,
    this.cierre = false,
  });

  final GarantiaVistaEntity garantia;
  final AccionCbrEntity? existente;
  final bool cierre;

  @override
  ConsumerState<_DialogoAccion> createState() => _DialogoAccionState();
}

class _DialogoAccionState extends ConsumerState<_DialogoAccion> {
  final _form = GlobalKey<FormState>();
  late final _observacion = TextEditingController(
    text: widget.existente?.observacion ?? '',
  );
  late final String _estado =
      widget.cierre ? AccionCbrEntity.cierre : AccionCbrEntity.nota;
  DateTime? _fecha = DateTime.now();

  /// Casilla "Entiendo que el cierre es definitivo".
  bool _entiende = false;

  bool get _esAlta => widget.existente == null;
  bool get _esCierre => _esAlta && widget.cierre;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final obs = _observacion.text.trim();

    final accion =
        _esAlta
            ? AccionCbrEntity(
              codAccion: BigInt.zero,
              codGarantia: widget.garantia.codGarantia,
              fecha: _fecha,
              estado: _estado,
              observacion: obs.isEmpty ? null : obs,
              audUsuario: 0,
              audFecha: null,
            )
            : widget.existente!.copyWith(observacion: obs);

    if (!mounted) return;
    final ok = await escribirConAviso(
      context,
      ref,
      (n) => n.registrarAccion(accion),
      exito:
          !_esAlta
              ? 'Observación actualizada.'
              : _esCierre
              ? 'Garantía N° ${widget.garantia.codGarantia} cerrada. Ya no '
                  'admite cambios.'
              : 'Nota registrada.',
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((s) => s.ocupado),
    );
    final estados = ref.watch(estadosAccionProvider).valueOrNull;
    final e = widget.existente;
    final g = widget.garantia;
    final sinTraspaso = !g.traspasada;
    // El cierre solo se habilita con traspaso y con la casilla marcada.
    final puedeConfirmar = !_esCierre || (!sinTraspaso && _entiende);

    return Form(
      key: _form,
      child: MarcoPanel(
        titulo:
            !_esAlta
                ? 'Editar observación'
                : _esCierre
                ? 'Cerrar garantía N° ${g.codGarantia}'
                : 'Nueva nota',
        subtitulo:
            _esAlta
                ? '${g.datoCliente} · Garantía N° ${g.codGarantia}'
                : '${nombreDeTipo(estados, e!.estado)} · ${fechaCorta(e.fecha)}',
        onCerrar: ocupado ? () {} : null,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_esCierre) ...[
              if (sinTraspaso) ...[
                const NotaGarantia(
                  tono: TonoNota.error,
                  icono: Icons.block,
                  texto:
                      'Todavía no se puede cerrar: la garantía no fue '
                      'traspasada a custodia. Primero genere el traspaso desde '
                      '«Traspaso» en la pantalla principal.',
                ),
                const SizedBox(height: Esp.m),
              ],
              const NotaGarantia(
                tono: TonoNota.aviso,
                icono: Icons.lock_outline,
                texto:
                    'Al cerrarla, la garantía pasa a «Cerrada» y ya no se '
                    'podrá editar sus datos, agregar ni quitar documentos, '
                    'registrar notas ni extender su plazo. El cierre no se '
                    'puede deshacer desde el sistema.',
              ),
              const SizedBox(height: Esp.l),
            ],
            if (_esAlta) ...[
              CampoFecha(
                etiqueta: _esCierre ? 'Fecha del cierre' : 'Fecha',
                valor: _fecha,
                onCambio: (f) => setState(() => _fecha = f),
              ),
              const SizedBox(height: Esp.l),
            ],
            TextFormField(
              controller: _observacion,
              maxLength: 299,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText:
                    _esCierre
                        ? 'Motivo del cierre'
                        : _esAlta
                        ? 'Nota'
                        : 'Observación',
                helperText:
                    _esCierre
                        ? 'Queda en el historial como el motivo del cierre.'
                        : null,
                border: const OutlineInputBorder(),
              ),
              validator:
                  (t) =>
                      (t ?? '').trim().isEmpty
                          ? (_esCierre
                              ? 'Escriba el motivo del cierre'
                              : 'Escriba la observación')
                          : null,
            ),
            if (_esCierre && !sinTraspaso)
              CheckboxListTile(
                value: _entiende,
                onChanged:
                    ocupado
                        ? null
                        : (v) => setState(() => _entiende = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Entiendo que el cierre es definitivo.'),
              ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BotonAccion(
            etiqueta:
                !_esAlta
                    ? 'Guardar observación'
                    : _esCierre
                    ? 'Cerrar garantía'
                    : 'Registrar nota',
            etiquetaOcupado: 'Guardando…',
            icono: _esCierre ? Icons.lock_outline : Icons.save_outlined,
            destructiva: _esCierre,
            ocupado: ocupado,
            onPressed: ocupado || !puedeConfirmar ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

/// Pide confirmacion y da de baja una accion.
Future<void> eliminarAccion(
  BuildContext context,
  WidgetRef ref,
  AccionCbrEntity accion,
  String nombreEstado,
) async {
  final seguro = await confirmar(
    context,
    titulo: '¿Eliminar esta acción?',
    detalle:
        accion.esBase
            ? '$nombreEstado del ${fechaCorta(accion.fecha)}. Es una '
                'acción base del circuito: eliminarla deja a la garantía '
                'como si no se hubiera registrado o traspasado.'
            : '$nombreEstado del ${fechaCorta(accion.fecha)}.',
    textoConfirmar: 'Eliminar acción',
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;
  await escribirConAviso(
    context,
    ref,
    (n) => n.eliminarAccion(accion.codAccion),
    exito: 'Acción eliminada.',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENSION
// ═══════════════════════════════════════════════════════════════════════════

Future<bool?> abrirExtension(
  BuildContext context,
  GarantiaVistaEntity garantia,
) => abrirPanel<bool>(
  context,
  anchoMaximo: 520,
  contenido: (_) => _DialogoExtension(garantia: garantia),
);

class _DialogoExtension extends ConsumerStatefulWidget {
  const _DialogoExtension({required this.garantia});

  final GarantiaVistaEntity garantia;

  @override
  ConsumerState<_DialogoExtension> createState() => _DialogoExtensionState();
}

class _DialogoExtensionState extends ConsumerState<_DialogoExtension> {
  final _form = GlobalKey<FormState>();
  final _observacion = TextEditingController();
  DateTime? _fecha = DateTime.now();
  DateTime? _nuevaExpiracion;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await escribirConAviso(
      context,
      ref,
      (n) => n.registrarExtension(
        codGarantia: widget.garantia.codGarantia,
        fecha: _fecha!,
        observacion: _observacion.text,
        fechaExpiracion: _nuevaExpiracion!,
      ),
      exito: 'Garantía extendida al ${fechaCorta(_nuevaExpiracion)}.',
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((s) => s.ocupado),
    );
    final actual = widget.garantia.garantia.fechaExpiracion;

    return Form(
      key: _form,
      child: MarcoPanel(
        titulo: 'Extender garantía',
        subtitulo:
            'N° ${widget.garantia.codGarantia} · vence el '
            '${fechaCorta(actual)}',
        onCerrar: ocupado ? () {} : null,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NotaGarantia(
              icono: Icons.update,
              texto:
                  'Extender mueve la fecha de expiración hacia adelante, por '
                  'ejemplo cuando se renueva la garantía. Queda registrado en '
                  'el historial como «Extensión», con el motivo. El valor y '
                  'la línea aprobada no cambian.',
            ),
            const SizedBox(height: Esp.l),
            CampoFecha(
              etiqueta: 'Nueva fecha de expiración',
              valor: _nuevaExpiracion,
              primera: actual?.add(const Duration(days: 1)),
              onCambio: (f) => setState(() => _nuevaExpiracion = f),
              validar:
                  (f) =>
                      f != null && actual != null && !f.isAfter(actual)
                          ? 'Debe ser posterior al ${fechaCorta(actual)}'
                          : null,
            ),
            const SizedBox(height: Esp.l),
            CampoFecha(
              etiqueta: 'Fecha de la extensión',
              valor: _fecha,
              onCambio: (f) => setState(() => _fecha = f),
            ),
            const SizedBox(height: Esp.l),
            TextFormField(
              controller: _observacion,
              maxLength: 299,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Motivo de la extensión',
                border: OutlineInputBorder(),
              ),
              validator:
                  (t) => (t ?? '').trim().isEmpty ? 'Escriba el motivo' : null,
            ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BotonAccion(
            etiqueta: 'Extender garantía',
            etiquetaOcupado: 'Guardando…',
            icono: Icons.update,
            ocupado: ocupado,
            onPressed: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FIRMAS Y PROTESTA
// ═══════════════════════════════════════════════════════════════════════════

/// Edita reconocimiento de firmas y protesta de una garantia guardada. Va por
/// `/registrar` con el codGarantia, que es la edicion del contrato.
Future<bool?> abrirFirmasYProtesta(
  BuildContext context,
  GarantiaVistaEntity garantia,
) => abrirPanel<bool>(
  context,
  anchoMaximo: 520,
  contenido: (_) => _DialogoFirmas(garantia: garantia),
);

class _DialogoFirmas extends ConsumerStatefulWidget {
  const _DialogoFirmas({required this.garantia});

  final GarantiaVistaEntity garantia;

  @override
  ConsumerState<_DialogoFirmas> createState() => _DialogoFirmasState();
}

class _DialogoFirmasState extends ConsumerState<_DialogoFirmas> {
  late final _recFirmas = TextEditingController(
    text: widget.garantia.garantia.recFirmas ?? '',
  );
  late final _nroProtesta = TextEditingController(
    text: widget.garantia.garantia.nroProtesta ?? '',
  );

  @override
  void dispose() {
    _recFirmas.dispose();
    _nroProtesta.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final g = widget.garantia.garantia;
    final registro = GarantiaRegistroEntity(
      codGarantia: g.codGarantia,
      codClienteSAP: g.codClienteSAP,
      montoGarantia: g.montoGarantia,
      montoCredito: g.montoCredito,
      tiempoPago: g.tiempoPago,
      fechaInicio: g.fechaInicio,
      fechaExpiracion: g.fechaExpiracion,
      recFirmas: _recFirmas.text,
      nroProtesta: _nroProtesta.text,
      observacion: null,
      detalles: const [],
    );
    final ok = await escribirConAviso(
      context,
      ref,
      (n) => n.registrarGarantia(registro),
      exito: 'Firmas y protesta actualizadas.',
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((s) => s.ocupado),
    );
    return MarcoPanel(
      titulo: 'Firmas y protesta',
      subtitulo: 'Garantía N° ${widget.garantia.codGarantia}',
      onCerrar: ocupado ? () {} : null,
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _recFirmas,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'Reconocimiento de firmas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Esp.m),
          TextField(
            controller: _nroProtesta,
            maxLength: 30,
            decoration: const InputDecoration(
              labelText: 'N° de protesta',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      acciones: [
        TextButton(
          onPressed: ocupado ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Guardar',
          etiquetaOcupado: 'Guardando…',
          icono: Icons.save_outlined,
          ocupado: ocupado,
          onPressed: ocupado ? null : _guardar,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRASPASO A CUSTODIA
// ═══════════════════════════════════════════════════════════════════════════

/// Traspasa todas las garantias pendientes y ofrece la nomina en PDF.
///
/// En el legacy era un dialogo con el total y dos botones que aparecian y
/// desaparecian segun una bandera. Aca es un paso y su resultado, y la nomina
/// del ultimo traspaso se puede volver a bajar aunque hoy no haya pendientes.
Future<void> abrirTraspaso(BuildContext context) => abrirPanel<void>(
  context,
  anchoMaximo: 520,
  contenido: (_) => const _DialogoTraspaso(),
);

class _DialogoTraspaso extends ConsumerStatefulWidget {
  const _DialogoTraspaso();

  @override
  ConsumerState<_DialogoTraspaso> createState() => _DialogoTraspasoState();
}

class _DialogoTraspasoState extends ConsumerState<_DialogoTraspaso> {
  /// Cuantas se traspasaron en esta visita; null mientras no se genero.
  int? _traspasadas;

  Future<void> _generar(int pendientes) async {
    final seguro = await confirmar(
      context,
      titulo: '¿Traspasar $pendientes garantías a custodia?',
      detalle:
          'Se registra la entrega al custodio de los documentos de las '
          '$pendientes garantías pendientes. Después imprima la nómina para '
          'firmarla. El traspaso no se puede deshacer desde el sistema.',
      textoConfirmar: 'Generar traspaso',
    );
    if (!seguro || !mounted) return;
    final notifier = ref.read(operacionesGarantiasProvider.notifier);
    final n = await notifier.generarTraspaso();
    if (!mounted) return;
    if (n == null) {
      avisar(
        context,
        ref.read(operacionesGarantiasProvider).error ??
            'No se pudo generar el traspaso.',
        esError: true,
      );
      notifier.limpiarError();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _traspasadas = n);
  }

  Future<void> _pdf() => verPdf(
    context,
    generar: ref.read(operacionesGarantiasProvider.notifier).reporteTraspaso,
    titulo: 'Nómina de garantías entregadas a custodia',
    nombreArchivo: 'traspaso-garantias.pdf',
  );

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesGarantiasProvider.select((s) => s.ocupado),
    );
    final pendientes = ref.watch(traspasosPendientesProvider);
    final cs = Theme.of(context).colorScheme;

    final Widget cuerpo;
    if (_traspasadas != null) {
      cuerpo = NotaGarantia(
        tono: _traspasadas! > 0 ? TonoNota.exito : TonoNota.info,
        texto:
            _traspasadas! > 0
                ? 'Se traspasaron $_traspasadas garantías: ya figuran «En '
                    'custodia». Imprima la nómina en PDF para firmarla y '
                    'archivarla.'
                : 'No había garantías pendientes: no se traspasó ninguna.',
      );
    } else {
      cuerpo = pendientes.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error:
            (e, _) => MensajeError(
              error: e,
              compacto: true,
              onReintentar: () => ref.invalidate(traspasosPendientesProvider),
            ),
        data:
            (n) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$n',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: Peso.dato,
                    fontFeatures: cifrasTabulares,
                    color: n > 0 ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  n == 1
                      ? 'garantía espera el traspaso a custodia'
                      : 'garantías esperan el traspaso a custodia',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: Esp.m),
                const NotaGarantia(
                  icono: Icons.info_outline,
                  texto:
                      'El traspaso registra la entrega de los documentos '
                      'originales al custodio. Incluye todas las garantías '
                      'registradas hasta este momento que todavía no se '
                      'entregaron.',
                ),
                const SizedBox(height: Esp.m),
                Text(
                  'Después de generarlo, imprima la nómina: trae espacio para '
                  'la firma del encargado de cobranza y del de recepción. Sin '
                  'traspaso, una garantía no se puede extender ni cerrar.',
                  style: context.apagado(),
                ),
              ],
            ),
      );
    }

    final n = pendientes.valueOrNull ?? 0;
    return MarcoPanel(
      titulo: 'Traspaso a custodia',
      onCerrar: ocupado ? () {} : null,
      cuerpo: cuerpo,
      acciones: [
        TextButton.icon(
          onPressed: ocupado ? null : _pdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(
            _traspasadas != null && _traspasadas! > 0
                ? 'Ver nómina en PDF'
                : 'Nómina del último traspaso',
          ),
        ),
        if (_traspasadas == null)
          BotonAccion(
            etiqueta: 'Generar traspaso',
            etiquetaOcupado: 'Generando…',
            icono: Icons.move_to_inbox_outlined,
            ocupado: ocupado,
            onPressed: ocupado || n == 0 ? null : () => _generar(n),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Listo'),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REPORTE DE BUSQUEDA
// ═══════════════════════════════════════════════════════════════════════════

/// Filtros del reporte PDF. [clientes] es la grilla principal ya cargada: el
/// reporte solo tiene sentido para clientes con garantias.
Future<void> abrirReporte(
  BuildContext context,
  List<GarantiaResumenClienteEntity> clientes,
) => abrirPanel<void>(
  context,
  anchoMaximo: 620,
  contenido: (_) => _DialogoReporte(clientes: clientes),
);

class _DialogoReporte extends ConsumerStatefulWidget {
  const _DialogoReporte({required this.clientes});

  final List<GarantiaResumenClienteEntity> clientes;

  @override
  ConsumerState<_DialogoReporte> createState() => _DialogoReporteState();
}

class _DialogoReporteState extends ConsumerState<_DialogoReporte> {
  final _form = GlobalKey<FormState>();
  String? _cliente;
  String? _estado;
  String? _tipo;
  DateTime? _vencDesde;
  DateTime? _vencHasta;
  DateTime? _regDesde;
  DateTime? _regHasta;

  static const _estados = [
    (GarantiaVistaEntity.vigente, 'Vigentes'),
    (GarantiaVistaEntity.caducado, 'Caducadas'),
    (GarantiaVistaEntity.cerrado, 'Cerradas'),
  ];

  Future<void> _generar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final filtro = FiltroGarantias(
      codClienteSAP: _cliente,
      estado: _estado,
      tipoGarantia: _tipo,
      vencDesde: _vencDesde,
      vencHasta: _vencHasta,
      regDesde: _regDesde,
      regHasta: _regHasta,
    );
    await verPdf(
      context,
      generar:
          () => ref
              .read(operacionesGarantiasProvider.notifier)
              .reporteBusqueda(filtro),
      titulo: 'Reporte de garantías',
      nombreArchivo: 'reporte-garantias.pdf',
    );
  }

  String? _orden(DateTime? desde, DateTime? hasta) =>
      desde != null && hasta != null && hasta.isBefore(desde)
          ? 'Debe ser igual o posterior a «desde»'
          : null;

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(tiposGarantiaProvider).valueOrNull;
    final clientes = [...widget.clientes]
      ..sort((a, b) => a.datoCliente.compareTo(b.datoCliente));

    Widget par(Widget a, Widget b) => LayoutBuilder(
      builder:
          (context, r) =>
              r.maxWidth < 440
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [a, const SizedBox(height: Esp.m), b],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: a),
                      const SizedBox(width: Esp.m),
                      Expanded(child: b),
                    ],
                  ),
    );

    return Form(
      key: _form,
      child: MarcoPanel(
        titulo: 'Reporte de garantías',
        subtitulo: 'Deje un filtro vacío para no filtrar por él.',
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String?>(
              value: _cliente,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Cliente',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final c in clientes)
                  DropdownMenuItem(
                    value: c.codClienteSAP,
                    child: Text(
                      '${c.datoCliente} · ${c.codClienteSAP}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _cliente = v),
            ),
            const SizedBox(height: Esp.m),
            par(
              DropdownButtonFormField<String?>(
                value: _estado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final (c, t) in _estados)
                    DropdownMenuItem(value: c, child: Text(t)),
                ],
                onChanged: (v) => setState(() => _estado = v),
              ),
              DropdownButtonFormField<String?>(
                value: _tipo,
                isExpanded: true,
                // Era «Garantía en» (etiqueta del legacy): lo que filtra es el
                // tipo de sus documentos.
                decoration: const InputDecoration(
                  labelText: 'Tipo de documento',
                  helperText: 'Las que tengan al menos uno de este tipo.',
                  helperMaxLines: 2,
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final TipoCbrEntity t in catalogo ?? const [])
                    DropdownMenuItem(value: t.codTipos, child: Text(t.nombre)),
                ],
                onChanged: (v) => setState(() => _tipo = v),
              ),
            ),
            const SizedBox(height: Esp.l),
            Text('Fecha de expiración', style: context.tituloSeccion()),
            const SizedBox(height: Esp.xs),
            Text(
              'Las garantías que vencen dentro de este rango.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.s),
            par(
              CampoFecha(
                etiqueta: 'Desde',
                valor: _vencDesde,
                obligatorio: false,
                onCambio: (f) => setState(() => _vencDesde = f),
              ),
              CampoFecha(
                etiqueta: 'Hasta',
                valor: _vencHasta,
                obligatorio: false,
                onCambio: (f) => setState(() => _vencHasta = f),
                validar: (f) => _orden(_vencDesde, f),
              ),
            ),
            const SizedBox(height: Esp.l),
            Text('Fecha de registro', style: context.tituloSeccion()),
            const SizedBox(height: Esp.xs),
            Text(
              'Las garantías que se registraron dentro de este rango.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.s),
            par(
              CampoFecha(
                etiqueta: 'Desde',
                valor: _regDesde,
                obligatorio: false,
                onCambio: (f) => setState(() => _regDesde = f),
              ),
              CampoFecha(
                etiqueta: 'Hasta',
                valor: _regHasta,
                obligatorio: false,
                onCambio: (f) => setState(() => _regHasta = f),
                validar: (f) => _orden(_regDesde, f),
              ),
            ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: _generar,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Generar PDF'),
          ),
        ],
      ),
    );
  }
}
