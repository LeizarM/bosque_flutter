import 'package:excel/excel.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/descargar_archivo.dart';
import 'package:bosque_flutter/domain/entities/preliminar_comision_entity.dart';

/// Exportacion a Excel del preliminar de comisiones.
///
/// Los importes van como numero, no como texto: quien recibe la planilla suele
/// sumar columnas y verificar contra SAP, y un numero guardado como texto no se
/// deja sumar. El formato de miles y decimales lo pone Excel segun la
/// configuracion de cada equipo.
class PreliminarExportService {
  const PreliminarExportService._();

  static const _mimeExcel =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static const _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  /// Genera y entrega el archivo. Devuelve false si el usuario cancelo.
  static Future<bool> exportar({
    required List<PreliminarComisionEntity> filas,
    required FiltroPreliminar filtro,
  }) async {
    final excel = Excel.createExcel();
    final hoja = excel[excel.getDefaultSheet() ?? 'Sheet1'];

    final titulo = CellStyle(
      bold: true,
      fontSize: 13,
      horizontalAlign: HorizontalAlign.Left,
    );
    final subtitulo = CellStyle(italic: true, fontSize: 9);
    final cabecera = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1F3864'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
    final normal = CellStyle(
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
    final total = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#DCE6F1'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );

    // Encabezado: el archivo debe poder leerse fuera de la app, asi que dice
    // que modalidad, que periodo y con que tipo de cambio se calculo.
    _texto(hoja, 0, 0, filtro.modalidad.etiqueta, titulo);
    _texto(
      hoja,
      0,
      1,
      'Periodo ${_meses[filtro.mes - 1]} ${filtro.anio}'
      '   ·   Tipo de cambio ${filtro.tc}'
      '   ·   Generado el ${_hoy()}',
      subtitulo,
    );

    const encabezados = [
      'Vendedor',
      'Grupo / Tipo',
      'Periodo',
      'Comision %',
      'Monto base (Bs)',
      'A pagar (Bs)',
      'A pagar (USD)',
      'Observacion',
    ];
    for (var c = 0; c < encabezados.length; c++) {
      _texto(hoja, c, 3, encabezados[c], cabecera);
    }

    var fila = 4;
    for (final f in filas) {
      final estilo = f.esTotal ? total : normal;
      _texto(hoja, 0, fila, f.nombreVen.isEmpty ? '—' : f.nombreVen, estilo);
      _texto(hoja, 1, fila, f.etiqueta, estilo);
      _texto(hoja, 2, fila, f.periodo, estilo);
      _numero(hoja, 3, fila, f.comisionVisual, estilo);
      _numero(hoja, 4, fila, f.montoBase, estilo);
      _numero(hoja, 5, fila, f.bsAPagar, estilo);
      _numero(hoja, 6, fila, f.usdAPagar, estilo);
      _texto(hoja, 7, fila, f.ignora ? 'No comisiona' : '', estilo);
      fila++;
    }

    // Anchos pensados para que nada quede cortado al abrir.
    const anchos = [34.0, 28.0, 11.0, 12.0, 18.0, 16.0, 16.0, 16.0];
    for (var c = 0; c < anchos.length; c++) {
      hoja.setColumnWidth(c, anchos[c]);
    }

    final bytes = excel.encode();
    if (bytes == null) return false;

    final nombre =
        'Preliminar-${_archivo(filtro.modalidad)}-'
        '${filtro.anio}${filtro.mes.toString().padLeft(2, '0')}.xlsx';
    return descargarBytes(bytes, nombre, _mimeExcel);
  }

  static void _texto(Sheet h, int col, int fil, String v, CellStyle e) {
    final celda = h.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: fil),
    );
    celda.value = TextCellValue(v);
    celda.cellStyle = e;
  }

  static void _numero(Sheet h, int col, int fil, double v, CellStyle e) {
    final celda = h.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: fil),
    );
    celda.value = DoubleCellValue(double.parse(v.toStringAsFixed(2)));
    celda.cellStyle = e;
  }

  static String _hoy() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _archivo(ModalidadPreliminar m) {
    switch (m) {
      case ModalidadPreliminar.interno:
        return 'Interno';
      case ModalidadPreliminar.externo:
        return 'Externo';
      case ModalidadPreliminar.dinamicaAnterior:
        return 'DinamicaAnterior';
      case ModalidadPreliminar.dinamicaVigente:
        return 'DinamicaVigente';
    }
  }
}
