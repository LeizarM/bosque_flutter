import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Muestra un PDF ya generado, con opción de imprimir o compartir.
///
/// Usa `PdfPreview` del paquete `printing`, que resuelve solo las tres
/// plataformas: en escritorio y web abre el diálogo de impresión del navegador
/// o del sistema, y en Android/iOS el de compartir. No hace falta ninguna rama
/// por `kIsWeb`.
///
/// **Por qué ver y no bajar directo.** La alternativa que usa medio proyecto es
/// `Printing.sharePdf`, que dispara la descarga sin mostrar nada: si el reporte
/// salió con los filtros equivocados uno se entera después de abrir el archivo.
/// Acá se ve primero y se imprime si sirve.
///
/// Nota: `presentation/widgets/cartas-cite/visor_pdf_cite.dart` es un gemelo de
/// esta función, anterior y atado por nombre a ese módulo. Cuando haya que
/// tocarlo, conviene que delegue acá en vez de mantener dos.
Future<void> mostrarPdf(
  BuildContext context, {
  required Uint8List bytes,
  required String titulo,
  required String nombreArchivo,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final tam = MediaQuery.of(ctx).size;

      return Dialog(
        insetPadding: EdgeInsets.all(tam.width < 600 ? Esp.s : Esp.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: tam.height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Esp.l,
                  vertical: Esp.m,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: cs.onPrimaryContainer),
                    const SizedBox(width: Esp.s),
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          fontWeight: Peso.titulo,
                          color: cs.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: cs.onPrimaryContainer,
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (_) async => bytes,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: true,
                  pdfFileName: nombreArchivo,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
