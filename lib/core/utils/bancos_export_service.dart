import 'dart:convert';
import 'dart:typed_data';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;

/// Servicio de exportación de planillas bancarias.
/// El FORMATO de salida es fijo por banco (igual que el sistema antiguo):
///   - BCP       → TXT con comas (.txt)
///   - Ganadero  → Excel/CSV (.csv) cabeceras en fila 1
///   - Mercantil → Excel/CSV (.csv) cabeceras en fila 1
///   - Económico → Excel/CSV (.csv) con encabezado especial + datos desde fila 9
///   - Global    → Excel/CSV (.csv) cabeceras en fila 1
class BancosExportService extends BaseApiRepository {
  // ─── Constantes de cuenta origen del Económico (igual que el sistema antiguo) ──
  static const String _econCuentaOrigen = '2101062761';
  static const String _econTipoCuenta = 'CA: Caja de ahorro';
  static const String _econMoneda = 'BOB';

  /// Obtiene los datos del endpoint genérico de pagos bancarios.
  Future<List<Map<String, dynamic>>> obtenerDatosBanco({
    required int mes,
    required int anio,
    required int codBanco,
    int? codEmpresa,
  }) async {
    return await postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.planillaPagosBancarios,
      data: {
        'mes': mes,
        'anio': anio,
        'codBanco': codBanco,
        'codEmpresa': codEmpresa,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Exporta los datos según el banco seleccionado.
  /// El formato es determinado internamente — el usuario solo elige el banco.
  Future<void> exportar({
    required int codBanco,
    required List<Map<String, dynamic>> datos,
    required String mes,
    required String anio,
  }) async {
    // Agrupar por empresa usando la nueva columna oculta _nombreEmpresa
    final Map<String, List<Map<String, dynamic>>> grupos = {};
    for (final row in datos) {
      final empresa = _v(row, '_nombreEmpresa').trim();
      final key =
          empresa.isNotEmpty
              ? empresa.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
              : 'General';
      grupos.putIfAbsent(key, () => []).add(row);
    }

    for (final entry in grupos.entries) {
      final empresaKey = entry.key;
      final datosEmpresa = entry.value;

      switch (codBanco) {
        case 3: // BCP → TXT con comas
          _exportarBCP(datosEmpresa, mes, anio, empresaKey);
          break;
        case 5: // Ganadero → Excel (CSV sin encabezado especial)
          _exportarExcelSimple(
            datosEmpresa,
            'PlanillaGanadero',
            mes,
            anio,
            'BancoGanadero',
            empresaKey,
          );
          break;
        case 2: // Mercantil → Excel (CSV sin encabezado especial)
          _exportarExcelSimple(
            datosEmpresa,
            'PlanillaMercantil',
            mes,
            anio,
            'BancoMercantil',
            empresaKey,
          );
          break;
        case 9: // Económico → Excel con encabezado especial
          _exportarEconomico(datosEmpresa, mes, anio, empresaKey);
          break;
        default: // 0 = Global → Excel simple
          _exportarExcelSimple(
            datosEmpresa,
            'PlanillaGlobal',
            mes,
            anio,
            'PlanillaBancos',
            empresaKey,
          );
          break;
      }
      // Pequeña pausa para evitar que el navegador bloquee múltiples descargas
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BCP: TXT con comas, SIN cabecera
  // Columnas: Nro,numCuenta,liquido,Comentario,TipoDocID,DocID,ExtensionDocID,,
  // ─────────────────────────────────────────────────────────────────────────────
  void _exportarBCP(
    List<Map<String, dynamic>> datos,
    String mes,
    String anio, [
    String empresa = '',
  ]) {
    final sb = StringBuffer();
    int nro = 1;
    for (final row in datos) {
      sb.write(nro.toString());
      sb.write(',');
      sb.write(_v(row, 'numCuenta'));
      sb.write(',');
      sb.write(_v(row, 'liquido'));
      sb.write(',');
      sb.write(_v(row, 'Comentario'));
      sb.write(',');
      sb.write(_v(row, 'TipoDocID'));
      sb.write(',');
      sb.write(_v(row, 'DocID'));
      sb.write(',');
      sb.write(_v(row, 'ExtensionDocID'));
      sb.write(',,'); // dos comas finales exactas como el sistema antiguo
      sb.writeln();
      nro++;
    }

    final sufijo = empresa.isNotEmpty ? '-$empresa' : '';
    _descargar(
      sb.toString(),
      'PlanillaBCP-$mes-$anio$sufijo.txt',
      'text/plain',
      bom: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Ganadero y Mercantil: Excel/CSV simple, cabeceras en fila 1
  // ─────────────────────────────────────────────────────────────────────────────
  void _exportarExcelSimple(
    List<Map<String, dynamic>> datos,
    String prefijo,
    String mes,
    String anio,
    String nombreHoja, [
    String empresa = '',
  ]) {
    if (datos.isEmpty) return;
    final sb = StringBuffer();
    // Fila 1: cabeceras
    final cols =
        datos.first.keys
            .where((k) => !k.startsWith('_') && k != '_liquidoInterno')
            .toList();
    sb.writeln(cols.map(_escaparCsv).join(';'));
    // Datos desde fila 2
    for (final row in datos) {
      sb.writeln(
        cols.map((c) => _escaparCsv(row[c]?.toString() ?? '')).join(';'),
      );
    }

    final sufijo = empresa.isNotEmpty ? '-$empresa' : '';
    _descargar(
      sb.toString(),
      '$prefijo-$mes-$anio$sufijo.csv',
      'text/csv;charset=utf-8',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Económico: Excel con encabezado especial (idéntico al sistema antiguo)
  //   Fila 1: "Banco Económico"  (A1:D1 merged → simulamos con texto simple)
  //   Fila 2: descripción
  //   Fila 4: Cuenta Origen / valor
  //   Fila 5: Tipo de Cuenta / valor
  //   Fila 6: Moneda / valor
  //   Fila 7: Descripción (Opcional) / vacío
  //   Fila 9: CABECERAS DE DATOS
  //   Fila 10+: filas de datos
  // ─────────────────────────────────────────────────────────────────────────────
  void _exportarEconomico(
    List<Map<String, dynamic>> datos,
    String mes,
    String anio, [
    String empresa = '',
  ]) {
    if (datos.isEmpty) return;

    var excel = Excel.createExcel();
    Sheet sheet = excel['BancoEconomico'];
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // A1: Banco Económico
    sheet.merge(CellIndex.indexByString("A1"), CellIndex.indexByString("D1"));
    var cellA1 = sheet.cell(CellIndex.indexByString("A1"));
    cellA1.value = TextCellValue("Banco Económico");
    cellA1.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );

    // A2: Subtítulo
    sheet.merge(CellIndex.indexByString("A2"), CellIndex.indexByString("D2"));
    var cellA2 = sheet.cell(CellIndex.indexByString("A2"));
    cellA2.value = TextCellValue(
      "Archivo simplificado para pago a proveedores o pago de nómina (Transferencias mismo banco)",
    );
    cellA2.cellStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Datos generales (filas 4 a 7)
    final boldStyle = CellStyle(bold: true);

    _setCell(sheet, 'A4', 'Cuenta Origen:', boldStyle);
    _setCell(sheet, 'B4', _econCuentaOrigen, null);

    _setCell(sheet, 'A5', 'Tipo de Cuenta:', boldStyle);
    _setCell(sheet, 'B5', _econTipoCuenta, null);

    _setCell(sheet, 'A6', 'Moneda de todos los pagos:', boldStyle);
    _setCell(sheet, 'B6', _econMoneda, null);

    _setCell(sheet, 'A7', 'Descripción (Opcional):', boldStyle);

    // Ancho de columnas exacto al sistema antiguo
    sheet.setColumnWidth(0, 18.0); // A
    sheet.setColumnWidth(1, 35.0); // B
    sheet.setColumnWidth(2, 15.0); // C
    sheet.setColumnWidth(3, 30.0); // D

    // Cabeceras de datos (fila 9)
    final cols = datos.first.keys.where((k) => !k.startsWith('_')).toList();
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString("#D3D3D3"),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    for (int c = 0; c < cols.length; c++) {
      var cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 8),
      );
      cell.value = TextCellValue(cols[c]);
      cell.cellStyle = headerStyle;
    }

    // Filas de datos (desde fila 10)
    final dataStyle = CellStyle(
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    for (int r = 0; r < datos.length; r++) {
      final row = datos[r];
      for (int c = 0; c < cols.length; c++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 9 + r),
        );
        var val = row[cols[c]]?.toString() ?? '';
        cell.value = TextCellValue(val);
        cell.cellStyle = dataStyle;
      }
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final sufijo = empresa.isNotEmpty ? '-$empresa' : '';
      _descargarBytes(
        bytes,
        'PlanillaEconomico-$mes-$anio$sufijo.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  void _setCell(Sheet sheet, String cellRef, String val, CellStyle? style) {
    var cell = sheet.cell(CellIndex.indexByString(cellRef));
    cell.value = TextCellValue(val);
    if (style != null) cell.cellStyle = style;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Utilidades
  // ─────────────────────────────────────────────────────────────────────────────

  /// Obtiene el valor de una columna como String (insensible a mayúsculas).
  String _v(Map<String, dynamic> row, String key) {
    final found = row.entries.firstWhere(
      (e) => e.key.toLowerCase() == key.toLowerCase(),
      orElse: () => const MapEntry('', ''),
    );
    return found.value?.toString() ?? '';
  }

  String _escaparCsv(String? val) {
    final s = val ?? '';
    if (s.contains(';') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  void _descargar(
    String contenido,
    String nombreArchivo,
    String mimeType, {
    bool bom = true,
  }) {
    final bytes = utf8.encode(contenido);
    final data = bom ? [0xEF, 0xBB, 0xBF, ...bytes] : bytes;
    _descargarBytes(data, nombreArchivo, mimeType);
  }

  void _descargarBytes(List<int> bytes, String nombreArchivo, String mimeType) {
    final uint8List = Uint8List.fromList(bytes);
    final blob = html.Blob([uint8List], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', nombreArchivo)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
