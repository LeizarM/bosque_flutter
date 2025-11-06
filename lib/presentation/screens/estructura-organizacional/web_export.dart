// Implementación web usando dart:html
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:typed_data';
import 'dart:html' as html;
import 'web_export_stub.dart';

/// Implementación web que realmente descarga archivos
class WebExportManager implements ExportManager {
  @override
  Future<void> descargarPNG(Uint8List bytes, String nombreArchivo) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor =
          html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..download = nombreArchivo
            ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();

      // Limpiar después de un momento
      await Future.delayed(const Duration(milliseconds: 500));
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      rethrow;
    }
  }
}

/// Factory que retorna la implementación web
ExportManager createExportManager() {
  return WebExportManager();
}
