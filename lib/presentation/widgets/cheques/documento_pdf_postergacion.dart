/// El documento PDF de una postergacion: ver o descargar el que esta cargado y
/// cargar uno nuevo (o reemplazar el anterior). Reemplaza a «Cargar PDF» y
/// «Descargar PDF» de la fila de `cheque.xhtml`, que juntaba en un solo dialogo
/// como el del PDF del cheque (`documento_pdf_cheque.dart`, que comparte con este
/// el selector de archivos, las reglas y las piezas de dibujo).
///
/// **Sin permiso de boton**, como el legacy: lo abre cualquiera que vea la
/// postergacion. El servidor exige sesion y rol, que la postergacion exista y que
/// el usuario pueda ver la sucursal de su cheque.
///
/// Una postergacion tiene **un solo PDF** (`<codPostergacion>.pdf` en el
/// servidor, que baja como `Posterg_<cod>_.pdf`): cargar otro lo reemplaza, y por
/// eso se pide confirmacion antes de enviarlo cuando ya hay uno.
///
/// **Valida antes de enviar** lo que el legacy valida (que sea .pdf y que pese
/// menos de 2 MB, `reglas_pdf_cheque.dart`) para dar el motivo sin esperar al
/// servidor, que sigue siendo quien decide: su mensaje se muestra **completo y
/// tal cual**, con el dialogo abierto. Una carpeta de PDF sin montar en el
/// servidor se ve como lo que es, un aviso explicito, y no un fallo mudo.
///
/// El selector de archivos es [selectorPdfChequeProvider] (el mismo del cheque):
/// `file_picker` no corre en las pruebas.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/utils/reglas_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/reportes_cheque.dart';

const String textoSinPdfPostergacion = 'Esta postergación no tiene PDF todavía';
const String textoConPdfPostergacion = 'Hay un PDF cargado';

/// El nombre con el que el servidor ofrece el PDF al descargarlo.
String nombreDescargaPdfPostergacion(BigInt codPostergacion) =>
    'Posterg_${codPostergacion}_.pdf';

/// Abre el dialogo del documento PDF de [postergacion]. [cheque] solo pone el
/// contexto (cual cheque es). Al terminar, el listado de postergaciones se relee
/// (la pastilla «PDF cargado»), haya cargado o no.
Future<void> abrirDocumentoPdfPostergacion(
  BuildContext context, {
  required ChequeFilaEntity cheque,
  required PostergacionEntity postergacion,
}) => abrirPanelCheque<void>(
  context,
  anchoMaximo: 620,
  contenido:
      (_) => _DialogoDocumentoPdfPostergacion(
        cheque: cheque,
        postergacion: postergacion,
      ),
);

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO DEL PDF
// ═══════════════════════════════════════════════════════════════════════════

/// Si la postergacion tiene PDF, leido de [estadoPdfPostergacionProvider], como
/// tarjeta. Mientras consulta dice «Consultando…»; si falla, dice por que (el
/// mensaje del servidor, completo) y ofrece reintentar. Una relectura despues de
/// cargar un PDF no parpadea.
class EstadoPdfPostergacion extends ConsumerWidget {
  const EstadoPdfPostergacion({super.key, required this.codPostergacion});

  final BigInt codPostergacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(estadoPdfPostergacionProvider(codPostergacion));
    final cs = Theme.of(context).colorScheme;

    return async.when(
      skipLoadingOnRefresh: true,
      loading:
          () => const MarcoEstadoPdfCheque(
            tarjeta: true,
            icono: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            titulo: 'Consultando el PDF de la postergación…',
          ),
      error:
          (e, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorServidorCheque(mensajeDeErrorCheque(e)),
              const SizedBox(height: Esp.s),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed:
                      () => ref.invalidate(
                        estadoPdfPostergacionProvider(codPostergacion),
                      ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ),
      data: (e) {
        final tono = e.existe ? SemanticaCheque.exito : SemanticaCheque.neutro;
        final detalle = detallePdfCheque(e);
        return MarcoEstadoPdfCheque(
          tarjeta: true,
          tono: tono,
          icono: Icon(
            e.existe ? Icons.picture_as_pdf : Icons.picture_as_pdf_outlined,
            size: 28,
            color:
                e.existe
                    ? ChequesColores.texto(context, tono)
                    : cs.onSurfaceVariant,
          ),
          titulo: e.existe ? textoConPdfPostergacion : textoSinPdfPostergacion,
          tituloColor: e.existe ? ChequesColores.texto(context, tono) : null,
          detalle: e.existe && detalle.isNotEmpty ? detalle : null,
          extra:
              e.existe && e.nombreArchivo.isNotEmpty
                  ? Text(
                    e.nombreArchivo,
                    style: context.cifraCheque(
                      color: cs.onSurfaceVariant,
                      tam: 11.5,
                    ),
                  )
                  : null,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIALOGO
// ═══════════════════════════════════════════════════════════════════════════

class _DialogoDocumentoPdfPostergacion extends ConsumerStatefulWidget {
  const _DialogoDocumentoPdfPostergacion({
    required this.cheque,
    required this.postergacion,
  });

  final ChequeFilaEntity cheque;
  final PostergacionEntity postergacion;

  @override
  ConsumerState<_DialogoDocumentoPdfPostergacion> createState() =>
      _DialogoDocumentoPdfPostergacionState();
}

class _DialogoDocumentoPdfPostergacionState
    extends ConsumerState<_DialogoDocumentoPdfPostergacion>
    with GeneradorPdfCheque<_DialogoDocumentoPdfPostergacion> {
  bool _subiendo = false;

  /// Lo enviado, de 0 a 1; null si el total no se conoce todavia.
  double? _progreso;

  /// El nombre del archivo que se esta subiendo, para decirlo en el progreso.
  String _nombreSubiendo = '';

  /// El motivo de un fallo al cargar: lo que rechazo la validacion previa o lo
  /// que contesto el servidor, tal cual.
  String? _errorCarga;

  BigInt get _cod => widget.postergacion.codPostergacion;

  /// Lo que se hace con el archivo en curso: bloquea el cierre y los botones.
  bool get _ocupado => generando || _subiendo;

  void _relerListado() =>
      ref.invalidate(postergacionesChequeProvider(widget.cheque.codCheque));

  // ── Ver / descargar ──────────────────────────────────────────────────────

  Future<void> _ver() async {
    setState(() => _errorCarga = null);
    await generarPdf(
      generar: (repo) => repo.descargarPdfPostergacion(_cod),
      titulo:
          'Postergación del ${textoFecha(widget.postergacion.fecha)} · '
          'Documento PDF',
      nombreArchivo: nombreDescargaPdfPostergacion(_cod),
    );
    // Si no se pudo bajar, quiza el archivo ya no esta: se vuelve a consultar
    // para que el dialogo diga la verdad.
    if (mounted && errorDelPdf != null) {
      ref.invalidate(estadoPdfPostergacionProvider(_cod));
    }
  }

  // ── Cargar / reemplazar ──────────────────────────────────────────────────

  Future<void> _cargar(PdfChequeEstadoEntity estado) async {
    if (_ocupado) return;
    setState(() {
      _errorCarga = null;
      errorDelPdf = null;
    });

    final ArchivoPdfElegido? archivo;
    try {
      archivo = await ref.read(selectorPdfChequeProvider)();
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _errorCarga =
                'No se pudo abrir el selector de archivos. Inténtalo de nuevo.',
      );
      return;
    }
    // El usuario cancelo: no hay nada que decir.
    if (archivo == null || !mounted) return;

    final bytes = archivo.bytes;
    final motivo =
        bytes == null
            ? 'No se pudo leer el archivo «${archivo.nombre}». '
                'Inténtalo de nuevo o elige otro PDF.'
            : errorDeArchivoPdfCheque(
              nombre: archivo.nombre,
              tamanoBytes: bytes.length,
            );
    if (motivo != null || bytes == null) {
      setState(() => _errorCarga = motivo);
      return;
    }

    if (estado.existe) {
      final detalle = detallePdfCheque(estado);
      final seguro = await confirmar(
        context,
        titulo: '¿Reemplazar el PDF de la postergación?',
        detalle:
            'Esta postergación ya tiene un PDF'
            '${detalle.isEmpty ? '' : ' ($detalle)'}. '
            'Si cargas «${archivo.nombre}» (${textoTamanoPdf(bytes.length)}), '
            'el anterior se borra y no se puede recuperar.',
        textoConfirmar: 'Reemplazar PDF',
        destructiva: true,
      );
      if (!seguro || !mounted) return;
    }

    await _subir(bytes, archivo.nombre.trim());
  }

  Future<void> _subir(Uint8List bytes, String nombre) async {
    setState(() {
      _subiendo = true;
      _progreso = null;
      _nombreSubiendo = nombre;
      _errorCarga = null;
    });

    final bool reemplazo;
    try {
      final r = await ref
          .read(chequesRepositoryProvider)
          .subirPdfPostergacion(
            _cod,
            bytes,
            nombre,
            alProgreso: (enviados, total) {
              if (!mounted) return;
              setState(
                () =>
                    _progreso =
                        total > 0 ? (enviados / total).clamp(0.0, 1.0) : null,
              );
            },
          );
      reemplazo = r.reemplazo;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subiendo = false;
        _errorCarga = mensajeDeErrorCheque(e);
      });
      return;
    }

    // Se vuelve a consultar el estado y se espera: asi la barra se va cuando ya
    // se ve el PDF nuevo, no antes (con un instante de «sin PDF» en medio). La
    // pastilla de la fila tambien se actualiza.
    _relerListado();
    if (!mounted) return;
    try {
      await ref.refresh(estadoPdfPostergacionProvider(_cod).future);
    } catch (_) {
      // El fallo de la consulta lo dibuja EstadoPdfPostergacion con su
      // «Reintentar»: el PDF quedo guardado igual.
    }
    if (!mounted) return;
    setState(() => _subiendo = false);
    avisar(context, reemplazo ? 'PDF reemplazado.' : 'PDF cargado.');
  }

  // ── Dibujo ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(estadoPdfPostergacionProvider(_cod));
    // null mientras no se sabe (primera consulta o consulta fallida): los botones
    // no actuan a ciegas, porque no se podria avisar del reemplazo.
    final estado = async.hasError ? null : async.valueOrNull;
    final puedeActuar = estado != null && !_ocupado;
    final existe = estado?.existe ?? false;
    final error = errorDelPdf ?? _errorCarga;

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          ErrorServidorCheque(error),
          const SizedBox(height: Esp.l),
        ],
        _CabeceraPostergacionPdf(
          cheque: widget.cheque,
          postergacion: widget.postergacion,
        ),
        const SizedBox(height: Esp.l),
        EstadoPdfPostergacion(codPostergacion: _cod),
        if (_subiendo) ...[
          const SizedBox(height: Esp.l),
          ProgresoSubidaPdfCheque(nombre: _nombreSubiendo, progreso: _progreso),
        ],
        const SizedBox(height: Esp.l),
        Text(
          'Solo archivos PDF de hasta 2 MB. Una postergación tiene un solo '
          'PDF: si cargas otro, reemplaza al anterior.',
          style: context.apagado(),
        ),
      ],
    );

    return PopScope(
      // Mientras sube o baja el archivo, el «atras» del telefono no cierra.
      canPop: !_ocupado,
      child: MarcoPanelCheque(
        titulo: 'PDF de la postergación',
        onCerrar: _ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: cuerpo,
        acciones: [
          TextButton(
            onPressed: _ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (existe)
            BotonPdfCheque(
              key: const ValueKey('boton-ver-pdf-postergacion'),
              icono: Icons.picture_as_pdf_outlined,
              etiqueta: 'Descargar PDF',
              etiquetaOcupado: 'Descargando…',
              ocupado: generando,
              destacado: true,
              onPressed: puedeActuar ? _ver : null,
            ),
          BotonPdfCheque(
            key: const ValueKey('boton-cargar-pdf-postergacion'),
            icono: Icons.upload_file_outlined,
            etiqueta: existe ? 'Reemplazar PDF' : 'Cargar PDF',
            etiquetaOcupado: 'Subiendo…',
            ocupado: _subiendo,
            // Con un PDF cargado lo principal es verlo; cargar uno pasa a
            // segundo plano.
            destacado: !existe,
            onPressed: puedeActuar ? () => _cargar(estado) : null,
          ),
        ],
      ),
    );
  }
}

/// La postergacion sobre la que se trabaja: su fecha, el cheque y el motivo.
class _CabeceraPostergacionPdf extends StatelessWidget {
  const _CabeceraPostergacionPdf({
    required this.cheque,
    required this.postergacion,
  });

  final ChequeFilaEntity cheque;
  final PostergacionEntity postergacion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final motivo = postergacion.observacion.trim();
    return DecoratedBox(
      key: const ValueKey('cabecera-postergacion-pdf'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const PastillaCheque(
                  texto: 'Postergación',
                  tono: SemanticaCheque.aviso,
                  icono: Icons.event_repeat_outlined,
                ),
                Text(
                  textoFecha(postergacion.fecha),
                  style: context.cifraCheque(fuerte: true, tam: 14),
                ),
              ],
            ),
            const SizedBox(height: Esp.xs),
            Text(
              'Cheque ${cheque.cheque.nrocheque} · ${textoODash(cheque.datoCliente)}',
              style: t.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (motivo.isNotEmpty) ...[
              const SizedBox(height: Esp.xs),
              Text(
                motivo,
                style: context.apagado(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
