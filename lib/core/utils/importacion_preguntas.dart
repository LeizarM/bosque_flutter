/// Lectura de la plantilla de carga en lote del banco de preguntas: texto
/// pegado desde Excel (tabulación) o un CSV con punto y coma. Solo interpreta
/// el formato; las reglas y sus mensajes los da `p_list_tcpe_BancoLote` V.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_importar_entity.dart';

/// Las letras de las columnas de opciones de la plantilla (A a F).
const List<String> kLetrasOpcion = ['A', 'B', 'C', 'D', 'E', 'F'];

/// Encabezados de la plantilla, en el orden del contrato (sección 9.5).
const List<String> kColumnasPlantilla = [
  'Pregunta',
  'Tipo (Abierta|Cerrada)',
  'Respuesta modelo',
  'Opción A',
  'Opción B',
  'Opción C',
  'Opción D',
  'Opción E',
  'Opción F',
  'Correctas (letras, por ejemplo A,C)',
];

const String kNombrePlantilla = 'plantilla_preguntas.csv';

/// Una pregunta leída y la línea del texto donde empieza (para los avisos).
class FilaPlantilla {
  const FilaPlantilla({required this.linea, required this.pregunta});

  final int linea;
  final TcpePreguntaImportarEntity pregunta;
}

/// Lo leído: las preguntas que se mandan a validar y los avisos de formato
/// (filas sin tipo reconocible, letras que no apuntan a ninguna opción).
class LecturaPlantilla {
  const LecturaPlantilla({this.filas = const [], this.avisos = const []});

  final List<FilaPlantilla> filas;
  final List<String> avisos;

  List<TcpePreguntaImportarEntity> get preguntas => [for (final f in filas) f.pregunta];
  bool get vacia => filas.isEmpty;
}

/// La plantilla vacía, con BOM para que Excel respete las tildes y `;` como
/// separador (el de Excel en español).
String plantillaPreguntasCsv() => '﻿${kColumnasPlantilla.join(';')}\r\n';

/// Bytes de un CSV: UTF-8 si es válido; si no, Latin-1 (el «CSV» de Excel en
/// Windows sin BOM).
String decodificarCsv(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

/// Lee el texto de la plantilla. Separa por tabulación si la primera línea con
/// datos la tiene; si no, por punto y coma. Respeta comillas de Excel (celdas
/// con separadores o saltos de línea), salta el encabezado y las filas vacías.
LecturaPlantilla leerPlantillaPreguntas(String texto) {
  var t = texto.startsWith('﻿') ? texto.substring(1) : texto;
  String primeraLinea() => t.split(RegExp(r'\r\n|\r|\n')).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  var primera = primeraLinea();
  String? sepExplicito;
  // `sep=;` es la pista que algunos Excel escriben al exportar: se respeta y se salta.
  if (primera.trim().toLowerCase().startsWith('sep=')) {
    final v = primera.trim().substring(4);
    sepExplicito = v.isEmpty ? null : v[0];
    t = t.substring(t.indexOf(primera) + primera.length);
    primera = primeraLinea();
  }
  final sep = sepExplicito ?? (primera.contains('\t') ? '\t' : ';');
  final filas = <FilaPlantilla>[];
  final avisos = <String>[];
  var primeraConDatos = true;

  for (final (linea, celdas) in _registros(t, sep)) {
    final c = [for (final x in celdas) x.trim()];
    if (c.every((x) => x.isEmpty)) continue;
    if (primeraConDatos) {
      primeraConDatos = false;
      if (_normal(c.first).startsWith('pregunta')) continue;
    }
    String en(int i) => i < c.length ? c[i] : '';
    final pregunta = en(0);
    final tipo = _normal(en(1));
    final bool esCerrada;
    if (tipo.startsWith('cerrad')) {
      esCerrada = true;
    } else if (tipo.startsWith('abiert')) {
      esCerrada = false;
    } else {
      avisos.add(
        en(1).isEmpty
            ? 'Línea $linea: falta el tipo (Abierta o Cerrada); no se incluyó.'
            : 'Línea $linea: el tipo «${en(1)}» no es Abierta ni Cerrada; no se incluyó.',
      );
      continue;
    }
    if (!esCerrada) {
      filas.add(
        FilaPlantilla(
          linea: linea,
          pregunta: TcpePreguntaImportarEntity(pregunta: pregunta, esCerrada: false, respuesta: en(2)),
        ),
      );
      continue;
    }
    final textos = [for (var k = 0; k < kLetrasOpcion.length; k++) en(3 + k)];
    final (letras, desconocidas) = _letrasCorrectas(en(9));
    for (final d in desconocidas) {
      avisos.add('Línea $linea: «$d» en Correctas no es una letra de la A a la F; se ignoró.');
    }
    for (final l in letras) {
      if (textos[l].isEmpty) {
        avisos.add('Línea $linea: la letra ${kLetrasOpcion[l]} de Correctas no tiene opción escrita; se ignoró.');
      }
    }
    filas.add(
      FilaPlantilla(
        linea: linea,
        pregunta: TcpePreguntaImportarEntity(
          pregunta: pregunta,
          esCerrada: true,
          opciones: [
            for (var k = 0; k < textos.length; k++)
              if (textos[k].isNotEmpty)
                TcpeBancoOpcionEntity(codRsptaOp: BigInt.zero, opcionRspta: textos[k], esValido: letras.contains(k)),
          ],
        ),
      ),
    );
  }
  return LecturaPlantilla(filas: filas, avisos: avisos);
}

/// `A,C`, `a; c`, `A C` o `AC` → {0, 2}. Lo que no es una letra A-F se devuelve aparte.
(Set<int>, List<String>) _letrasCorrectas(String texto) {
  final letras = <int>{};
  final desconocidas = <String>[];
  for (final token in texto.toUpperCase().split(RegExp(r'[\s,;/|+-]+'))) {
    if (token.isEmpty) continue;
    if (RegExp(r'^[A-F]+$').hasMatch(token)) {
      for (final ch in token.split('')) {
        letras.add(kLetrasOpcion.indexOf(ch));
      }
    } else {
      desconocidas.add(token);
    }
  }
  return (letras, desconocidas);
}

/// Minúsculas y sin tildes, para reconocer «Cerrada», «CERRADA» o «cérrada».
String _normal(String s) {
  const con = 'áéíóúüàèìòù';
  const sin = 'aeiouuaeiou';
  final b = StringBuffer();
  for (final ch in s.trim().toLowerCase().split('')) {
    final i = con.indexOf(ch);
    b.write(i < 0 ? ch : sin[i]);
  }
  return b.toString();
}

/// Registros CSV con su línea de inicio. Las comillas permiten separadores y
/// saltos de línea dentro de una celda; `""` es una comilla literal.
Iterable<(int, List<String>)> _registros(String texto, String sep) sync* {
  var linea = 1;
  var inicio = 1;
  var celda = StringBuffer();
  var celdas = <String>[];
  var entreComillas = false;
  var i = 0;
  while (i < texto.length) {
    final ch = texto[i];
    if (entreComillas) {
      if (ch == '"') {
        if (i + 1 < texto.length && texto[i + 1] == '"') {
          celda.write('"');
          i += 2;
          continue;
        }
        entreComillas = false;
      } else {
        if (ch == '\n') linea++;
        celda.write(ch);
      }
      i++;
      continue;
    }
    if (ch == '"' && celda.toString().trim().isEmpty) {
      entreComillas = true;
      celda = StringBuffer();
    } else if (ch == sep) {
      celdas.add(celda.toString());
      celda = StringBuffer();
    } else if (ch == '\r' || ch == '\n') {
      if (ch == '\r' && i + 1 < texto.length && texto[i + 1] == '\n') i++;
      celdas.add(celda.toString());
      yield (inicio, celdas);
      celdas = <String>[];
      celda = StringBuffer();
      linea++;
      inicio = linea;
    } else {
      celda.write(ch);
    }
    i++;
  }
  if (celda.isNotEmpty || celdas.isNotEmpty) {
    celdas.add(celda.toString());
    yield (inicio, celdas);
  }
}
