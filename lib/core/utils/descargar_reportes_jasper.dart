import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';


// Función General para Mostrar/Compartir CUALQUIER PDF
Future<void> mostrarReportePdf({
  required BuildContext context,
  required Future<Uint8List> Function() downloadFunction,
  required String filename,
}) async {
  try {
    final pdfBytes = await downloadFunction();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al descargar el reporte $filename.')),
    );
    debugPrint('Error de descarga detallado: $e');
  }
}