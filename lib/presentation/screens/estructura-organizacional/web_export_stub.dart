// Stub para exportación en web
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:typed_data';

/// Interfaz para descargar archivos en diferentes plataformas
abstract class ExportManager {
  /// Descarga un archivo PNG
  Future<void> descargarPNG(Uint8List bytes, String nombreArchivo);
}

/// Implementación stub (se usa en mobile/desktop)
class ExportManagerStub implements ExportManager {
  @override
  Future<void> descargarPNG(Uint8List bytes, String nombreArchivo) async {
    // Por ahora solo registramos que se generó exitosamente
    print('Organigrama generado: $nombreArchivo (${bytes.length} bytes)');
  }
}

/// Implementación web (solo disponible en web)
ExportManager createExportManager() {
  return ExportManagerStub();
}
