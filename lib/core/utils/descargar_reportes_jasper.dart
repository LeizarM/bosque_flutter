import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

// Función General para Mostrar/Compartir CUALQUIER PDF
Future<void> mostrarReportePdf({
  required BuildContext context,
  required Future<Uint8List> Function() downloadFunction,
  required String filename,
}) async {
  try {
    final pdfBytes = await downloadFunction();

    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al descargar el reporte $filename.')),
    );
    console('Error de descarga detallado: $e');
  }
}

// Función General para Descargar Archivos (ej. Excel)
Future<void> descargarArchivo({
  required BuildContext context,
  required Future<Uint8List> Function() downloadFunction,
  required String filename,
  required String mimeType,
}) async {
  try {
    final bytes = await downloadFunction();
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Descarga nativa (Android/iOS)
      final tempDir = await getTemporaryDirectory();
      final tempFile = io.File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(bytes);

      final params = SaveFileDialogParams(
        sourceFilePath: tempFile.path,
        fileName: filename,
        mimeTypesFilter: [mimeType],
      );
      final savedFilePath = await FlutterFileDialog.saveFile(params: params);

      if (savedFilePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo guardado exitosamente')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar el archivo $filename.')),
      );
    }
    console('Error de descarga detallado: $e');
  }
}
