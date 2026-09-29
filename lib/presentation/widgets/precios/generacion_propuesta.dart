/// "Generar" una propuesta aprobada: CambioDePrecios-N.xlsx (N = número) con el
/// precio unitario de cada artículo en cada lista de precios de SAP. El servidor
/// arma el archivo y deja la constancia en la misma llamada
/// (`GeneracionPropuestaService`). Solo con btnGen (el servidor lo vuelve a exigir).
library;

import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/utils/descargar_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/precios/pdf_precios.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';

const String mimeXlsx =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// El nombre del sistema anterior, con el numero de la propuesta para que dos
/// generaciones no se pisen en la carpeta de descargas.
String nombreArchivoGeneracion(PropuestaEnAutorizacion fila) =>
    'CambioDePrecios-${fila.idPropuesta}.xlsx';

/// Pide el archivo, lo guarda y avisa. La confirmacion va antes, en
/// `confirmarGeneracion`.
Future<void> generarPropuesta(
  BuildContext context,
  WidgetRef ref,
  PropuestaEnAutorizacion fila,
) async {
  final notifier = ref.read(propuestaProvider.notifier);
  final cerrarEspera = mostrarEsperaDePrecios(
    context,
    'Generando el archivo de la propuesta ${fila.numero}…',
  );
  final archivo = await notifier.generar(fila.idPropuesta);
  cerrarEspera();
  if (!context.mounted) return;

  if (archivo == null) {
    avisar(
      context,
      ref.read(propuestaProvider).error ??
          'No se pudo generar la propuesta. Intente de nuevo.',
      esError: true,
    );
    notifier.limpiarError();
    return;
  }

  final nombre = nombreArchivoGeneracion(fila);
  var guardado = false;
  try {
    guardado = await guardarXlsx(archivo, nombre);
  } catch (_) {
    guardado = false;
  }
  if (!context.mounted) return;

  // La constancia ya quedo en el servidor aunque el archivo no se haya
  // guardado: se dice, para que no parezca que no paso nada.
  avisar(
    context,
    guardado
        ? 'Propuesta ${fila.numero} generada: se descargó $nombre.'
        : 'La propuesta ${fila.numero} quedó registrada como generada, pero '
            'el archivo no se guardó. Puede volver a generarla.',
    esError: !guardado,
  );
}

/// Guarda el .xlsx donde la persona elija. Devuelve `false` si no se guardó.
///
/// En escritorio `file_picker` solo devuelve la ruta (no escribe), así que se
/// escribe aquí; en web y teléfono lo resuelve [descargarBytes], que en Windows
/// no sirve (su diálogo nativo es de Android e iOS).
Future<bool> guardarXlsx(Uint8List bytes, String nombre) async {
  final esEscritorio =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
  if (!esEscritorio) return descargarBytes(bytes, nombre, mimeXlsx);

  final ruta = await FilePicker.platform.saveFile(
    dialogTitle: 'Guardar $nombre',
    fileName: nombre,
    type: FileType.custom,
    allowedExtensions: const ['xlsx'],
    lockParentWindow: true,
  );
  if (ruta == null) return false;
  final destino = ruta.toLowerCase().endsWith('.xlsx') ? ruta : '$ruta.xlsx';
  await io.File(destino).writeAsBytes(bytes, flush: true);
  return true;
}
