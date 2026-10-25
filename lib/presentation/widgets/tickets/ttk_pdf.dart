/// PDF del módulo, armados en el dispositivo con `pdf`: vales recortables al
/// estilo del diseño de Publisher y cartones de bingo (uno por hoja).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_vale_impresion_entity.dart';

class _Fuentes {
  const _Fuentes(this.normal, this.negrita, this.cifras);
  final pw.Font normal;
  final pw.Font negrita;
  final pw.Font cifras;
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
    await cargar('assets/fonts/JetBrainsMono-700.ttf', pw.Font.courierBold()),
  );
}

PdfColor? _color(String? hex) {
  final t = (hex ?? '').replaceFirst('#', '').trim();
  if (t.length != 6 || int.tryParse(t, radix: 16) == null) return null;
  return PdfColor.fromHex('#$t');
}

final _corte = pw.Border.all(
  color: PdfColors.grey600,
  width: 0.6,
  style: pw.BorderStyle.dashed,
);

// ═══════════════════════════════════════════════════════════════════════════
// VALES
// ═══════════════════════════════════════════════════════════════════════════

/// Colores del vale cuando el tipo no trae el suyo. Es material impreso: aquí
/// sí se fija una paleta (rojo, azul, verde, dorado…), no en la interfaz.
const List<String> ttkColoresVale = [
  '#C62828',
  '#1565C0',
  '#2E7D32',
  '#F9A825',
  '#6A1B9A',
  '#EF6C00',
  '#00838F',
  '#AD1457',
];

/// Vales por fila y filas por hoja A4.
const int _valesPorFila = 4;
const int _filasPorHoja = 5;

Future<pw.MemoryImage?> _imagen(String ruta) async {
  try {
    final datos = await rootBundle.load(ruta);
    return pw.MemoryImage(datos.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

/// Una fila por participante con sus vales uno al lado del otro (cuatro por
/// fila; si tiene más, siguen abajo), al estilo del diseño de Publisher.
Future<Uint8List> ttkPdfVales(List<TtkValeImpresionEntity> vales) async {
  final f = await _fuentes();
  final logo = await _imagen('assets/logos/logoEmpresaEPP.jpg');
  final llama = await _imagen('assets/icon/logo.png');
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: f.normal, bold: f.negrita),
    title: vales.isEmpty ? 'Vales' : 'Vales ${vales.first.nombreEvento}',
  );

  // Color por tipo: el de la base o, si no tiene, uno de la paleta por orden.
  final colores = <BigInt?, PdfColor>{};
  for (final v in vales) {
    colores.putIfAbsent(
      v.codTipoTicket,
      () =>
          _color(v.colorHex) ??
          PdfColor.fromHex(
            ttkColoresVale[colores.length % ttkColoresVale.length],
          ),
    );
  }

  // Filas: los vales de cada participante juntos, partidos de a cuatro.
  final porPersona = <BigInt?, List<TtkValeImpresionEntity>>{};
  for (final v in vales) {
    (porPersona[v.codParticipante] ??= []).add(v);
  }
  final filas = <List<TtkValeImpresionEntity>>[
    for (final propios in porPersona.values)
      for (var i = 0; i < propios.length; i += _valesPorFila)
        propios.sublist(i, math.min(i + _valesPorFila, propios.length)),
  ];

  const margen = 8 * PdfPageFormat.mm;
  const hueco = 3 * PdfPageFormat.mm;
  final ancho =
      (PdfPageFormat.a4.width - 2 * margen - (_valesPorFila - 1) * hueco) /
      _valesPorFila;
  final alto =
      (PdfPageFormat.a4.height - 2 * margen - (_filasPorHoja - 1) * hueco) /
      _filasPorHoja;

  for (var i = 0; i < filas.length; i += _filasPorHoja) {
    final hoja = filas.sublist(i, math.min(i + _filasPorHoja, filas.length));
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(margen),
        build:
            (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var r = 0; r < hoja.length; r++)
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: r == 0 ? 0 : hueco),
                    child: pw.Row(
                      children: [
                        for (var c = 0; c < hoja[r].length; c++)
                          pw.Padding(
                            padding: pw.EdgeInsets.only(
                              left: c == 0 ? 0 : hueco,
                            ),
                            child: pw.SizedBox(
                              width: ancho,
                              height: alto,
                              child: _vale(
                                hoja[r][c],
                                colores[hoja[r][c].codTipoTicket]!,
                                f,
                                logo,
                                llama,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
      ),
    );
  }
  return doc.save();
}

/// Un vale: degradado diagonal del color del tipo hacia blanco, banda negra
/// con el tipo, recuadro blanco con el nombre, logos y el número abajo.
pw.Widget _vale(
  TtkValeImpresionEntity v,
  PdfColor color,
  _Fuentes f,
  pw.MemoryImage? logo,
  pw.MemoryImage? llama,
) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      gradient: pw.LinearGradient(
        begin: pw.Alignment.topLeft,
        end: pw.Alignment.bottomRight,
        colors: [color, PdfColors.white],
      ),
      border: _corte,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Banda negra: el tipo en blanco, negrita y apretado como en el original.
        pw.Container(
          height: 9 * PdfPageFormat.mm,
          color: PdfColors.black,
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 5),
          child: pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            child: pw.Text(
              v.nombreTipo.toUpperCase(),
              style: pw.TextStyle(
                font: f.negrita,
                fontSize: 17,
                letterSpacing: -0.6,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(6, 3, 6, 0),
          child: pw.Text(
            v.nombreEvento,
            maxLines: 1,
            style: pw.TextStyle(
              font: f.negrita,
              fontSize: 6.5,
              color: PdfColors.grey900,
            ),
          ),
        ),
        pw.Spacer(),
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 6),
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          color: PdfColors.white,
          alignment: pw.Alignment.center,
          child: pw.Text(
            v.nombreParticipante,
            maxLines: 2,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: f.negrita, fontSize: 8),
          ),
        ),
        if ((v.leyenda ?? '').isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(6, 2, 6, 0),
            child: pw.Text(
              v.leyenda!,
              maxLines: 1,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 5.5,
                color: PdfColors.grey800,
              ),
            ),
          ),
        pw.Spacer(),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(5, 0, 5, 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (logo != null)
                pw.Container(
                  color: PdfColors.white,
                  padding: const pw.EdgeInsets.all(1.5),
                  child: pw.Image(logo, height: 3.6 * PdfPageFormat.mm),
                ),
              pw.Spacer(),
              pw.Text(
                'N° ${v.nroTicketTexto}',
                style: pw.TextStyle(
                  font: f.cifras,
                  fontSize: 6.5,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(width: 4),
              if (llama != null) pw.Image(llama, height: 7 * PdfPageFormat.mm),
            ],
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CARTONES
// ═══════════════════════════════════════════════════════════════════════════

/// Un cartón por hoja: número, dueño (si tiene) y sus juegos como grillas con
/// las letras, el comodín y las casillas de la figura sombreadas.
Future<Uint8List> ttkPdfCartones(
  List<TtkBingoCeldaEntity> celdas, {
  required String nombreEvento,
  String? letras,
}) async {
  final f = await _fuentes();
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: f.normal, bold: f.negrita),
    title: 'Cartones $nombreEvento',
  );
  final cartones = <int, List<TtkBingoCeldaEntity>>{};
  for (final c in celdas) {
    (cartones[c.nroCarton] ??= []).add(c);
  }
  final numeros = cartones.keys.toList()..sort();
  for (final nro in numeros) {
    final propias = cartones[nro]!;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
        build: (_) => _carton(nro, propias, nombreEvento, letras, f),
      ),
    );
  }
  return doc.save();
}

pw.Widget _carton(
  int nro,
  List<TtkBingoCeldaEntity> celdas,
  String nombreEvento,
  String? letras,
  _Fuentes f,
) {
  final filas = celdas.map((c) => c.fila).reduce(math.max) + 1;
  final columnas = celdas.map((c) => c.columna).reduce(math.max) + 1;
  final juegos = <int, List<TtkBingoCeldaEntity>>{};
  for (final c in celdas) {
    (juegos[c.nroJuego] ??= []).add(c);
  }
  final orden = juegos.keys.toList()..sort();
  final porFila =
      orden.length <= 2
          ? orden.length
          : (orden.length <= 6 ? 2 : (orden.length <= 12 ? 3 : 4));
  final dueno = celdas.first.nombreEmpleado;
  final filasJuegos = <List<int>>[
    for (var i = 0; i < orden.length; i += porFila)
      orden.sublist(i, math.min(i + porFila, orden.length)),
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BINGO · $nombreEvento',
                  style: pw.TextStyle(font: f.negrita, fontSize: 13),
                ),
                if ((dueno ?? '').isNotEmpty)
                  pw.Text(dueno!, style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),
          pw.Text('Cartón N° ', style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            nro.toString().padLeft(4, '0'),
            style: pw.TextStyle(font: f.cifras, fontSize: 26),
          ),
        ],
      ),
      pw.Divider(color: PdfColors.grey500, thickness: 0.6),
      pw.SizedBox(height: 4),
      for (final fila in filasJuegos)
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var k = 0; k < porFila; k++)
                pw.Expanded(
                  child:
                      k < fila.length
                          ? pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: _juego(
                              juegos[fila[k]]!,
                              filas,
                              columnas,
                              letras,
                              f,
                            ),
                          )
                          : pw.SizedBox(),
                ),
            ],
          ),
        ),
      pw.Text(
        'Las casillas sombreadas forman la figura de cada juego.',
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
      ),
    ],
  );
}

pw.Widget _juego(
  List<TtkBingoCeldaEntity> celdas,
  int filas,
  int columnas,
  String? letras,
  _Fuentes f,
) {
  final porPosicion = {for (final c in celdas) c.posicion: c};
  final tieneLetras = (letras ?? '').isNotEmpty;
  pw.Widget casilla(pw.Widget hijo, {PdfColor? fondo, PdfColor? borde}) =>
      pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.all(0.8),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: fondo,
            border: pw.Border.all(
              color: borde ?? PdfColors.grey500,
              width: 0.6,
            ),
          ),
          child: pw.FittedBox(
            child: pw.Padding(padding: const pw.EdgeInsets.all(2), child: hijo),
          ),
        ),
      );
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        'Juego ${celdas.first.nroJuego} · ${celdas.first.nombreJuego}',
        maxLines: 1,
        style: pw.TextStyle(font: f.negrita, fontSize: 9),
      ),
      pw.SizedBox(height: 2),
      pw.Expanded(
        child: pw.Column(
          children: [
            if (tieneLetras)
              pw.Expanded(
                child: pw.Row(
                  children: [
                    for (var c = 0; c < columnas; c++)
                      casilla(
                        pw.Text(
                          c < letras!.length ? letras[c] : '',
                          style: pw.TextStyle(
                            font: f.cifras,
                            fontSize: 14,
                            color: PdfColors.white,
                          ),
                        ),
                        fondo: PdfColors.grey800,
                        borde: PdfColors.grey800,
                      ),
                  ],
                ),
              ),
            for (var fila = 0; fila < filas; fila++)
              pw.Expanded(
                child: pw.Row(
                  children: [
                    for (var c = 0; c < columnas; c++)
                      _casillaPdf(porPosicion[fila * columnas + c], f, casilla),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _casillaPdf(
  TtkBingoCeldaEntity? d,
  _Fuentes f,
  pw.Widget Function(pw.Widget, {PdfColor? fondo, PdfColor? borde}) casilla,
) {
  if (d == null) return casilla(pw.Text(''));
  final fondo = d.enFigura ? PdfColors.grey300 : null;
  if (d.esComodin) {
    return casilla(
      pw.Text('LIBRE', style: pw.TextStyle(font: f.negrita, fontSize: 8)),
      fondo: fondo,
    );
  }
  return casilla(
    pw.Text('${d.numero}', style: pw.TextStyle(font: f.cifras, fontSize: 14)),
    fondo: fondo,
  );
}
