import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PdfService {
  // Método para generar y previsualizar/descargar PDF
  static Future<void> generateAndViewDepositosPdf({
    required BuildContext context,
    required String title,
    required List<DepositoChequeEntity> depositos,
    required Map<String, dynamic> filtros,
  }) async {
    final pdf = await _generateDepositosPdf(
      title: title,
      depositos: depositos,
      filtros: filtros,
    );

    // En web, descarga directamente
    if (kIsWeb) {
      _downloadWebPdf(pdf, 'depositos_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } else {
      // En móvil, muestra la previsualización
      await Printing.layoutPdf(
        onLayout: (format) async => pdf,
        name: 'Depósitos - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      );
    }
  }

  // Método para generar el PDF
  static Future<Uint8List> _generateDepositosPdf({
    required String title,
    required List<DepositoChequeEntity> depositos,
    required Map<String, dynamic> filtros,
  }) async {
    // Crear documento PDF sin especificar fuente personalizada
    final pdf = pw.Document(
      creator: 'Sistema Bosque',
      author: 'Bosque App',
      title: title,
    );

    // Añadir página con contenido
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        // Ya no usamos tema con fuente personalizada
        header: (context) => _buildHeader(title),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Sección de filtros aplicados
          _buildFiltrosSection(filtros),
          pw.SizedBox(height: 20),
          // Tabla de resultados
          _buildDepositosTable(depositos),
        ],
      ),
    );

    return pdf.save();
  }

  // Construir encabezado del PDF
  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Construir pie de página
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Sistema Bosque',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Construir sección de filtros aplicados
  static pw.Widget _buildFiltrosSection(Map<String, dynamic> filtros) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Filtros aplicados:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 20,
            runSpacing: 8,
            children: filtros.entries.map((entry) {
              // Formatear fechas si es necesario
              String valueText = '';
              if (entry.value is DateTime) {
                valueText = DateFormat('dd/MM/yyyy').format(entry.value);
              } else {
                valueText = entry.value?.toString() ?? 'Todos';
              }
              
              return pw.Text(
                '${entry.key}: $valueText',
                style: const pw.TextStyle(fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Construir tabla de depósitos
  static pw.Widget _buildDepositosTable(List<DepositoChequeEntity> depositos) {
    // Definir columnas de la tabla (excluye "Acciones")
    final columns = [
      'ID', 'Cliente', 'Banco', 'Empresa', 'Importe', 
      'Moneda', 'Fecha Ingreso', 'Num. Transaccion', 'Estado'
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(1), // ID
        1: const pw.FlexColumnWidth(3), // Cliente
        2: const pw.FlexColumnWidth(2.5), // Banco
        3: const pw.FlexColumnWidth(2), // Empresa
        4: const pw.FlexColumnWidth(1.5), // Importe
        5: const pw.FlexColumnWidth(1), // Moneda
        6: const pw.FlexColumnWidth(1.5), // Fecha Ingreso
        7: const pw.FlexColumnWidth(2), // Num. Transaccion
        8: const pw.FlexColumnWidth(1.5), // Estado
      },
      children: [
        // Encabezados
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: columns.map((column) => pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              column,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          )).toList(),
        ),
        // Datos de depósitos
        ...depositos.map((deposito) => pw.TableRow(
          children: [
            _cellText(deposito.idDeposito.toString()),
            _cellText(deposito.codCliente),
            _cellText(deposito.nombreBanco),
            _cellText(deposito.nombreEmpresa),
            _cellText(deposito.importe.toStringAsFixed(2), alignment: pw.TextAlign.right),
            _cellText(deposito.moneda, alignment: pw.TextAlign.center),
            _cellText(deposito.fechaI != null ? "${deposito.fechaI!.day.toString().padLeft(2, '0')}/${deposito.fechaI!.month.toString().padLeft(2, '0')}/${deposito.fechaI!.year}" : ''),
            _cellText(deposito.nroTransaccion),
            _cellText(deposito.esPendiente, alignment: pw.TextAlign.center),
          ],
        )),
      ],
    );
  }

  // Helper para crear celdas de texto en la tabla
  static pw.Widget _cellText(String text, {pw.TextAlign alignment = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: alignment,
      ),
    );
  }

  // Método para descargar PDF en web
  static void _downloadWebPdf(Uint8List pdfBytes, String fileName) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    
    // Simular click para iniciar descarga
    anchor.click();
    
    // Limpiar
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}