/// El documento PDF de un cheque: ver o descargar el que esta cargado y cargar
/// uno nuevo (o reemplazar el anterior). Reemplaza a «Cargar Documento PDF» y
/// «Descargar Documento PDF» de la fila del legacy, que juntaba en un solo
/// dialogo para no sumar dos iconos a cada fila.
///
/// **Sin permiso de boton**, como el legacy: lo abre cualquiera que vea la fila.
/// El servidor exige sesion y rol y nada mas.
///
/// Un cheque tiene **un solo PDF**: cargar otro lo reemplaza, y por eso se pide
/// confirmacion antes de enviarlo cuando ya hay uno.
///
/// **Valida antes de enviar** lo que el legacy valida (que sea .pdf y que pese
/// menos de 2 MB, `reglas_pdf_cheque.dart`) para dar el motivo sin esperar al
/// servidor. El servidor sigue siendo quien decide: su mensaje se muestra
/// **completo y tal cual**, con el dialogo abierto.
///
/// El selector de archivos va detras de [selectorPdfChequeProvider] porque
/// `file_picker` no corre en las pruebas.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/utils/reglas_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_visuales_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/reportes_cheque.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SELECTOR DE ARCHIVOS (INYECTABLE)
// ═══════════════════════════════════════════════════════════════════════════

/// El archivo que eligio el usuario. [bytes] es null si la plataforma no pudo
/// leerlo (el dialogo lo dice en vez de enviar nada).
class ArchivoPdfElegido {
  const ArchivoPdfElegido({required this.nombre, required this.bytes});

  final String nombre;
  final Uint8List? bytes;
}

/// Abre el selector de archivos. Devuelve null si el usuario cancela.
typedef SelectorPdfCheque = Future<ArchivoPdfElegido?> Function();

/// El selector real. Existe como provider para que una prueba lo sustituya:
/// `file_picker` usa plugins que no hay en `flutter test`.
///
/// `withData: true` trae los bytes en memoria: en la web no hay ruta en disco y
/// el repositorio envia los bytes. El filtro `pdf` del selector es una ayuda; la
/// comprobacion que vale es la del dialogo, porque no todas las plataformas lo
/// aplican igual (ni distinguen mayusculas del mismo modo).
final selectorPdfChequeProvider = Provider<SelectorPdfCheque>(
  (ref) => _elegirConFilePicker,
);

Future<ArchivoPdfElegido?> _elegirConFilePicker() async {
  final r = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    allowMultiple: false,
    withData: true,
  );
  if (r == null || r.files.isEmpty) return null;
  final f = r.files.single;
  return ArchivoPdfElegido(nombre: f.name, bytes: f.bytes);
}

// ═══════════════════════════════════════════════════════════════════════════
// TEXTOS
// ═══════════════════════════════════════════════════════════════════════════

const String textoSinPdfCheque = 'Este cheque no tiene PDF todavía';
const String textoConPdfCheque = 'Hay un PDF cargado';

final DateFormat _formatoFechaHora = DateFormat('dd/MM/yyyy HH:mm');

/// «120 KB · 03/10/2026 14:22»: lo que se sabe del archivo cargado. Vacio si el
/// servidor no informo ni tamano ni fecha.
String detallePdfCheque(PdfChequeEstadoEntity e) {
  final partes = [
    if (e.tamanoBytes != null) textoTamanoPdf(e.tamanoBytes!),
    if (e.fechaModificacion != null)
      _formatoFechaHora.format(e.fechaModificacion!),
  ];
  return partes.join(' · ');
}

/// «Hay un PDF cargado · 120 KB · 03/10/2026 14:22» o «Este cheque no tiene PDF
/// todavía».
String textoEstadoPdfCheque(PdfChequeEstadoEntity e) {
  if (!e.existe) return textoSinPdfCheque;
  final detalle = detallePdfCheque(e);
  return detalle.isEmpty ? textoConPdfCheque : '$textoConPdfCheque · $detalle';
}

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO DEL PDF (dialogo y panel del detalle)
// ═══════════════════════════════════════════════════════════════════════════

/// Si el cheque tiene PDF, leido de [estadoPdfChequeProvider]. [tarjeta] lo
/// dibuja como la tarjeta del dialogo (titulo y detalle en dos lineas, con
/// borde); sin ella es una linea para el panel del detalle.
///
/// Mientras consulta dice «Consultando…»; si falla, dice por que (el mensaje del
/// servidor, completo) y ofrece reintentar. Una relectura despues de cargar un
/// PDF no parpadea: se sigue viendo el estado anterior hasta que llega el nuevo.
class EstadoPdfCheque extends ConsumerWidget {
  const EstadoPdfCheque({
    super.key,
    required this.codCheque,
    this.tarjeta = false,
  });

  final BigInt codCheque;
  final bool tarjeta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(estadoPdfChequeProvider(codCheque));
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    void reintentar() => ref.invalidate(estadoPdfChequeProvider(codCheque));

    return async.when(
      skipLoadingOnRefresh: true,
      loading:
          () => MarcoEstadoPdfCheque(
            tarjeta: tarjeta,
            icono: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            titulo: 'Consultando el PDF del cheque…',
          ),
      error: (e, _) {
        final motivo = mensajeDeErrorCheque(e);
        if (tarjeta) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorServidorCheque(motivo),
              const SizedBox(height: Esp.s),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: reintentar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          );
        }
        return Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 20, color: cs.error),
            Text(
              'No se pudo consultar el PDF: $motivo',
              style: t.bodyMedium?.copyWith(color: cs.error),
            ),
            TextButton(onPressed: reintentar, child: const Text('Reintentar')),
          ],
        );
      },
      data: (e) {
        final tono = e.existe ? SemanticaCheque.exito : SemanticaCheque.neutro;
        final colorIcono =
            e.existe ? ChequesColores.texto(context, tono) : cs.onSurfaceVariant;
        final icono = Icon(
          e.existe ? Icons.picture_as_pdf : Icons.picture_as_pdf_outlined,
          size: tarjeta ? 28 : 20,
          color: colorIcono,
        );
        if (!tarjeta) {
          return MarcoEstadoPdfCheque(
            tarjeta: false,
            icono: icono,
            titulo: textoEstadoPdfCheque(e),
          );
        }
        final detalle = detallePdfCheque(e);
        return MarcoEstadoPdfCheque(
          tarjeta: true,
          tono: tono,
          icono: icono,
          titulo: e.existe ? textoConPdfCheque : textoSinPdfCheque,
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

/// El cuerpo comun del estado de un PDF (el del cheque y el de una postergacion):
/// un icono y un texto, con o sin tarjeta.
class MarcoEstadoPdfCheque extends StatelessWidget {
  const MarcoEstadoPdfCheque({
    super.key,
    required this.tarjeta,
    required this.icono,
    required this.titulo,
    this.tono = SemanticaCheque.neutro,
    this.tituloColor,
    this.detalle,
    this.extra,
  });

  final bool tarjeta;
  final Widget icono;
  final String titulo;
  final SemanticaCheque tono;
  final Color? tituloColor;
  final String? detalle;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          style: (tarjeta ? t.titleSmall : t.bodyMedium)?.copyWith(
            fontWeight: tarjeta ? Peso.dato : null,
            color: tituloColor,
          ),
        ),
        if (detalle != null) ...[
          const SizedBox(height: 2),
          Text(detalle!, style: context.cifraCheque(tam: 13)),
        ],
        if (extra != null) ...[const SizedBox(height: 2), extra!],
      ],
    );

    final fila = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: tarjeta ? 32 : 24, child: Center(child: icono)),
        SizedBox(width: tarjeta ? Esp.m : Esp.s),
        Expanded(child: texto),
      ],
    );
    if (!tarjeta) return fila;

    final suave = tono != SemanticaCheque.neutro;
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            suave
                ? ChequesColores.fondo(context, tono)
                : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(
          color:
              suave
                  ? ChequesColores.pleno(context, tono).withValues(alpha: 0.35)
                  : cs.outlineVariant,
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(Esp.l), child: fila),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIALOGO
// ═══════════════════════════════════════════════════════════════════════════

/// Abre el dialogo del documento PDF de [cheque]. Lo abren el icono de la fila
/// (tabla, menu ⋮ y tarjeta) y el panel del detalle.
Future<void> abrirDocumentoPdfCheque(
  BuildContext context, {
  required ChequeFilaEntity cheque,
}) => abrirPanelCheque<void>(
  context,
  anchoMaximo: 620,
  contenido: (_) => _DialogoDocumentoPdf(cheque: cheque),
);

class _DialogoDocumentoPdf extends ConsumerStatefulWidget {
  const _DialogoDocumentoPdf({required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  ConsumerState<_DialogoDocumentoPdf> createState() =>
      _DialogoDocumentoPdfState();
}

class _DialogoDocumentoPdfState extends ConsumerState<_DialogoDocumentoPdf>
    with GeneradorPdfCheque<_DialogoDocumentoPdf> {
  bool _subiendo = false;

  /// Lo enviado, de 0 a 1; null si el total no se conoce todavia.
  double? _progreso;

  /// El nombre del archivo que se esta subiendo, para decirlo en el progreso.
  String _nombreSubiendo = '';

  /// El motivo de un fallo al cargar: lo que rechazo la validacion previa o lo
  /// que contesto el servidor, tal cual.
  String? _errorCarga;

  BigInt get _cod => widget.cheque.codCheque;

  /// Lo que se hace con el archivo en curso: bloquea el cierre y los botones.
  bool get _ocupado => generando || _subiendo;

  // ── Ver / descargar ──────────────────────────────────────────────────────

  Future<void> _ver() async {
    setState(() => _errorCarga = null);
    await generarPdf(
      generar: (repo) => repo.descargarPdf(_cod),
      titulo: 'Cheque ${widget.cheque.cheque.nrocheque} · Documento PDF',
      // El nombre con el que el servidor lo ofrece al descargar.
      nombreArchivo: '${_cod}_.pdf',
    );
    // Si no se pudo bajar, quiza el archivo ya no esta: se vuelve a consultar
    // para que el dialogo diga la verdad.
    if (mounted && errorDelPdf != null) {
      ref.invalidate(estadoPdfChequeProvider(_cod));
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
        titulo: '¿Reemplazar el PDF del cheque?',
        detalle:
            'Este cheque ya tiene un PDF'
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
          .subirPdf(
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
    // se ve el PDF nuevo, no antes (con un instante de «sin PDF» en medio).
    if (!mounted) return;
    try {
      await ref.refresh(estadoPdfChequeProvider(_cod).future);
    } catch (_) {
      // El fallo de la consulta lo dibuja EstadoPdfCheque con su «Reintentar»:
      // el PDF quedo guardado igual.
    }
    if (!mounted) return;
    setState(() => _subiendo = false);
    avisar(context, reemplazo ? 'PDF reemplazado.' : 'PDF cargado.');
  }

  // ── Dibujo ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(estadoPdfChequeProvider(_cod));
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
        _CabeceraChequePdf(cheque: widget.cheque),
        const SizedBox(height: Esp.l),
        EstadoPdfCheque(codCheque: _cod, tarjeta: true),
        if (_subiendo) ...[
          const SizedBox(height: Esp.l),
          ProgresoSubidaPdfCheque(nombre: _nombreSubiendo, progreso: _progreso),
        ],
        const SizedBox(height: Esp.l),
        Text(
          'Solo archivos PDF de hasta 2 MB. Un cheque tiene un solo PDF: '
          'si cargas otro, reemplaza al anterior.',
          style: context.apagado(),
        ),
      ],
    );

    return PopScope(
      // Mientras sube o baja el archivo, el «atras» del telefono no cierra.
      canPop: !_ocupado,
      child: MarcoPanelCheque(
        titulo: 'Documento PDF',
        onCerrar: _ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: cuerpo,
        acciones: [
          TextButton(
            onPressed: _ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (existe)
            BotonPdfCheque(
              key: const ValueKey('boton-ver-pdf'),
              icono: Icons.picture_as_pdf_outlined,
              etiqueta: 'Ver / Descargar',
              etiquetaOcupado: 'Descargando…',
              ocupado: generando,
              destacado: true,
              onPressed: puedeActuar ? _ver : null,
            ),
          BotonPdfCheque(
            key: const ValueKey('boton-cargar-pdf'),
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

/// El cheque sobre el que se trabaja: banco, numero, cliente, estado y monto.
/// Con poco ancho el monto baja debajo.
class _CabeceraChequePdf extends StatelessWidget {
  const _CabeceraChequePdf({required this.cheque});

  final ChequeFilaEntity cheque;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final c = cheque;

    final datos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Esp.s,
          runSpacing: Esp.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Cheque ${c.cheque.nrocheque}',
              style: context.cifraCheque(fuerte: true, tam: 15),
            ),
            EtiquetaEstadoCheque(estado: c.cheque.estado, texto: c.descEstado),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          textoODash(c.datoCliente),
          style: t.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          textoODash(c.nombreBanco),
          style: context.apagado(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return DecoratedBox(
      key: const ValueKey('cabecera-cheque-pdf'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: LayoutBuilder(
          builder: (context, box) {
            final ancho = box.maxWidth >= 440;
            final importe = ImporteCheque(
              cheque: c,
              tam: 20,
              alineacion: ancho ? Alignment.centerRight : Alignment.centerLeft,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonogramaBanco(c.nombreBanco, tam: 40),
                const SizedBox(width: Esp.m),
                Expanded(
                  child:
                      ancho
                          ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: datos),
                              const SizedBox(width: Esp.m),
                              // Sin flex: lo que sobra es del texto, y el monto
                              // queda en el borde derecho. Un importe enorme se
                              // achica en vez de desbordar.
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: importe,
                              ),
                            ],
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              datos,
                              const SizedBox(height: Esp.s),
                              importe,
                            ],
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// «Subiendo "x.pdf"» con su barra: de 0 a 100 % cuando el servidor informa el
/// avance y sin valor (en movimiento) cuando no.
class ProgresoSubidaPdfCheque extends StatelessWidget {
  const ProgresoSubidaPdfCheque({
    super.key,
    required this.nombre,
    required this.progreso,
  });

  final String nombre;
  final double? progreso;

  @override
  Widget build(BuildContext context) {
    final porcentaje = progreso == null ? null : (progreso! * 100).round();
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Subiendo el PDF${porcentaje == null ? '' : ', $porcentaje %'}',
      child: Column(
        key: const ValueKey('progreso-subida-pdf'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            porcentaje == null
                ? 'Subiendo «$nombre»…'
                : 'Subiendo «$nombre» · $porcentaje %',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Esp.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(Esquina.pastilla),
            child: LinearProgressIndicator(value: progreso, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

/// Un boton del pie del dialogo: lleno si es lo principal y con borde si no, con
/// su progreso mientras trabaja. Si el texto no entra se corta con puntos y no
/// desborda.
class BotonPdfCheque extends StatelessWidget {
  const BotonPdfCheque({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.etiquetaOcupado,
    required this.ocupado,
    required this.destacado,
    required this.onPressed,
  });

  final IconData icono;
  final String etiqueta;
  final String etiquetaOcupado;
  final bool ocupado;
  final bool destacado;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Sin color propio: el boton apagado (mientras trabaja) no tiene el fondo
    // del primario y un giro en `onPrimary` se perderia sobre el.
    final contenido = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ocupado)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icono, size: 18),
        const SizedBox(width: Esp.s),
        Flexible(
          child: Text(
            ocupado ? etiquetaOcupado : etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return destacado
        ? FilledButton(onPressed: ocupado ? null : onPressed, child: contenido)
        : OutlinedButton(
          onPressed: ocupado ? null : onPressed,
          child: contenido,
        );
  }
}
