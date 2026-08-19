import 'dart:typed_data';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Muestra un PDF ya generado, con opción de imprimir o compartir.
///
/// Se usa `PdfPreview` del paquete `printing`, que es el mismo visor que usan
/// el voucher de pagos al exterior y la factura de Tigo: en escritorio abre el
/// diálogo de impresión del sistema y en Android/iOS el de compartir, sin que
/// haya que resolver descargas a mano en cada plataforma.
Future<void> mostrarPdfCite(
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
                padding: EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.m),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: cs.onPrimaryContainer),
                    SizedBox(width: Esp.s),
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
