/// Entregarle un archivo a quien está usando la app, en web y en el teléfono.
///
/// **Por qué existe este archivo.** La misma función vivía como método privado
/// dentro de `BancosExportService` (`_descargarBytes`). Al aparecer el segundo
/// exportador —el reporte de boletas de RR.HH.— había que copiarla o abrirla;
/// copiarla es como empiezan las divergencias que después nadie unifica: dos
/// descargas, dos comportamientos en móvil, un solo bug arreglado.
///
/// La diferencia entre las dos plataformas no es de estilo: en web el navegador
/// **no** deja elegir carpeta y hay que fabricar un `<a download>` sobre un
/// Blob; en el teléfono hay que escribir primero a un archivo temporal porque el
/// diálogo nativo de guardado recibe una ruta, no bytes.
library;

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

/// Guarda [bytes] como [nombreArchivo]. Devuelve `false` si no se guardó.
///
/// En web dispara la descarga del navegador; en móvil abre el diálogo nativo
/// para elegir dónde guardar.
///
/// **Devuelve si se guardó, y no `void`, por el botón «atrás».** En el teléfono
/// el diálogo nativo se puede cancelar, y ahí `saveFile` devuelve `null`. Sin
/// este dato, quien llama avisa «archivo generado» igual y la persona se pasa
/// un rato buscando en Descargas algo que nunca se guardó.
///
/// En web no hay forma de saberlo —el navegador se lleva el Blob y no cuenta
/// qué hizo con él—, así que ahí siempre es `true`: no se puede prometer más de
/// lo que la plataforma informa.
Future<bool> descargarBytes(
  List<int> bytes,
  String nombreArchivo,
  String mimeType,
) async {
  final datos = Uint8List.fromList(bytes);

  if (kIsWeb) {
    final blob = html.Blob([datos], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', nombreArchivo)
      ..click();
    html.Url.revokeObjectUrl(url);
    return true;
  }

  // El diálogo nativo recibe una RUTA, no bytes, así que primero hay que
  // escribir. Es una copia del archivo que el usuario todavía no aceptó.
  final temporal = await getTemporaryDirectory();
  final archivo = io.File('${temporal.path}/$nombreArchivo');
  await archivo.writeAsBytes(datos);

  try {
    final guardado = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: archivo.path,
        fileName: nombreArchivo,
        mimeTypesFilter: [mimeType],
      ),
    );
    return guardado != null;
  } finally {
    // **La copia temporal se borra pase lo que pase.** Nadie más la va a
    // limpiar: el sistema vacía esa carpeta cuando se le antoja, y mientras
    // tanto cada exportación deja atrás un archivo con nombres y motivos de
    // permisos de toda la empresa. Que el diálogo ya la haya copiado a destino
    // no la hace menos copia.
    try {
      if (await archivo.exists()) await archivo.delete();
    } catch (_) {
      // Si no se puede borrar no hay nada que hacer, y menos hacer fallar una
      // exportación que sí salió bien.
    }
  }
}

/// Guarda [contenido] de texto.
///
/// [bom] agrega la marca de orden de bytes UTF-8. **Va en `true` para todo lo
/// que abra Excel**: sin ella, Excel lee el archivo en la codificación del
/// sistema y «Vacación» sale «VacaciÃ³n».
Future<bool> descargarTexto(
  String contenido,
  String nombreArchivo,
  String mimeType, {
  bool bom = true,
}) {
  final bytes = utf8.encode(contenido);
  return descargarBytes(
    bom ? [0xEF, 0xBB, 0xBF, ...bytes] : bytes,
    nombreArchivo,
    mimeType,
  );
}
