import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'web_export_stub.dart';

/// Implementación web que realmente descarga archivos
class WebExportManager implements ExportManager {
  @override
  Future<void> descargarPNG(Uint8List bytes, String nombreArchivo) async {
    try {
      // Crear un Blob con los bytes de la imagen
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Crear elemento anchor para descarga
      final anchor =
          html.AnchorElement()
            ..href = url
            ..download = nombreArchivo
            ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();

      // Limpiar después de un momento
      await Future.delayed(const Duration(milliseconds: 500));
      anchor.remove();
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
