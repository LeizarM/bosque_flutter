/// Las credenciales para recortar, armadas en el dispositivo con `pdf`: las
/// claves temporales solo existen en la respuesta de generar o regenerar. El
/// examen escrito y el solucionario los arma el backend (Jasper).
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';

class _Fuentes {
  const _Fuentes(this.normal, this.negrita, this.fija);
  final pw.Font normal;
  final pw.Font negrita;
  final pw.Font fija;
}

Future<_Fuentes> _fuentes() async {
  Future<pw.Font> cargar(String ruta, pw.Font respaldo) async {
    try {
      return pw.Font.ttf(await rootBundle.load(ruta));
    } catch (_) {
      return respaldo;
    }
  }

  return _Fuentes(
    await cargar('assets/fonts/Roboto-Regular.ttf', pw.Font.helvetica()),
    await cargar('assets/fonts/Roboto-Bold.ttf', pw.Font.helveticaBold()),
    await cargar('assets/fonts/JetBrainsMono-500.ttf', pw.Font.courier()),
  );
}

pw.ThemeData _tema(_Fuentes f) => pw.ThemeData.withFont(base: f.normal, bold: f.negrita);

/// Dónde entra el postulante: en web, la misma dirección de esta app.
String? _direccionIngreso() =>
    kIsWeb ? '${Uri.base.origin}${AppConstants.rutaTcpeIngreso}' : null;

/// Primero la lista de control (usuario, nombre, CI y clave) para el
/// evaluador; después una tarjeta por credencial, de a dos por fila, para
/// recortar y entregar.
Future<Uint8List> pdfCredenciales({
  required String tituloLote,
  required List<TcpeCredencialEntity> credenciales,
  DateTime? fecha,
}) async {
  final f = await _fuentes();
  final doc = pw.Document(theme: _tema(f), title: 'Credenciales $tituloLote');
  final direccion = _direccionIngreso();
  final conClave = credenciales.where((c) => c.tieneClave).toList();
  const gris = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);

  pw.Widget dato(String rotulo, String valor, {bool fija = false}) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(width: 44, child: pw.Text(rotulo, style: const pw.TextStyle(fontSize: 9))),
      pw.Expanded(
        child: pw.Text(
          valor,
          style: fija ? pw.TextStyle(font: f.fija, fontSize: 13) : const pw.TextStyle(fontSize: 10),
          maxLines: 2,
        ),
      ),
    ],
  );

  pw.Widget celda(String texto, {bool encabezado = false, bool fija = false, String? nota}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          texto,
          style:
              encabezado
                  ? pw.TextStyle(font: f.negrita, fontSize: 9)
                  : fija
                  ? pw.TextStyle(font: f.fija, fontSize: 10)
                  : const pw.TextStyle(fontSize: 9),
        ),
        if (nota != null) pw.Text(nota, style: gris),
      ],
    ),
  );

  final control = pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(2),
      1: pw.FlexColumnWidth(5),
      2: pw.FlexColumnWidth(2),
      3: pw.FlexColumnWidth(3),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          celda('Usuario', encabezado: true),
          celda('Nombre', encabezado: true),
          celda('CI', encabezado: true),
          celda('Clave', encabezado: true),
        ],
      ),
      for (final c in conClave)
        pw.TableRow(
          children: [
            celda(c.login ?? '', fija: true),
            celda(c.nombreCompleto ?? '--'),
            celda(c.ci ?? '--'),
            celda(c.password ?? '', fija: true),
          ],
        ),
    ],
  );

  pw.Widget tarjeta(TcpeCredencialEntity c) => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey600, width: 0.8, style: pw.BorderStyle.dashed),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(tituloLote, style: pw.TextStyle(font: f.negrita, fontSize: 10), maxLines: 2),
        if (fecha != null)
          pw.Text('Fecha: ${fechaCorta(fecha)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        if ((c.nombreCompleto ?? '').isNotEmpty) ...[dato('Nombre', c.nombreCompleto!), pw.SizedBox(height: 2)],
        if ((c.ci ?? '').isNotEmpty) ...[dato('CI', c.ci!), pw.SizedBox(height: 4)],
        dato('Usuario', c.login ?? '', fija: true),
        pw.SizedBox(height: 4),
        dato('Clave', c.password ?? '', fija: true),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 44),
          child: pw.Text('Clave temporal: deja de funcionar al entregar el examen.', style: gris),
        ),
        if (direccion != null) ...[
          pw.SizedBox(height: 8),
          pw.Text('Ingresa en $direccion', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ],
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(32),
      header:
          (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(
              'Credenciales de examen · ${conClave.length} postulantes',
              style: pw.TextStyle(font: f.negrita, fontSize: 12),
            ),
          ),
      build:
          (_) => [
            control,
            pw.NewPage(),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in conClave) pw.SizedBox(width: 262, child: tarjeta(c)),
              ],
            ),
          ],
    ),
  );
  return doc.save();
}
