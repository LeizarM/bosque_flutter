/// Exportar UN sábado a PDF: el camino a WhatsApp.
///
/// **Por qué vive en su propio archivo.** Lo usan las dos vistas de la grilla —
/// la matriz del escritorio y la agenda del teléfono— y `matriz_grilla.dart` ya
/// importa `agenda_sabado.dart`, así que poner esto en cualquiera de los dos
/// arma un ciclo o esconde el reporte adentro de un archivo que habla de otra
/// cosa. Acá el nombre dice qué hace y los dos lo importan igual.
///
/// **Qué NO hace: el estado de ocupado.** Ese lo lleva cada botón, porque cada
/// uno lo dibuja distinto —un ítem de menú deshabilitado en la matriz, una
/// ruedita en el ícono de la agenda— y porque tiene que sobrevivir a que el
/// menú se cierre: si el ocupado viviera acá, el segundo toque no encontraría
/// nada que lo frene y saldrían dos PDF.
library;

import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El nombre con el que el PDF llega al chat.
///
/// **Se ve, y es lo único que se ve** hasta que alguien lo abre: en WhatsApp el
/// archivo aparece como una tarjeta con el nombre y el peso. `reporte.pdf` no
/// dice de qué sábado es, y en un grupo donde cada semana llega uno, eso obliga
/// a abrir los cuatro para encontrar el de esta semana.
///
/// Formato `aaaa-mm-dd` y no `dd/MM/yyyy` por dos motivos: la barra no es un
/// carácter válido en un nombre de archivo en ningún sistema, y así los PDF se
/// ordenan solos por fecha en la carpeta de descargas.
String nombreArchivoSabado(SabadoEntity sabado) {
  final f = sabado.fecha;
  if (f == null) return 'rol-sabado-${sabado.idSabado}.pdf';
  final mes = f.month.toString().padLeft(2, '0');
  final dia = f.day.toString().padLeft(2, '0');
  return 'rol-sabado-${f.year}-$mes-$dia.pdf';
}

/// Baja el PDF de [sabado] y abre la hoja de compartir del sistema.
///
/// En el teléfono esa hoja es la que tiene WhatsApp, que es todo el motivo de
/// este reporte; en el escritorio y en la web se descarga.
///
/// **Por qué se bajan los bytes acá y no adentro de `mostrarReportePdf`.** Ese
/// helper es de toda la app y atrapa cualquier error con un `ScaffoldMessenger`
/// —un SnackBar que el `Scaffold` de la pantalla dibuja DEBAJO de los diálogos y
/// de sus velos, que es el problema que `shared/aviso.dart` existe para
/// resolver—. Bajando los bytes primero, los errores que de verdad pasan
/// —el 500 de Jasper, el token vencido, la conexión— caen en este `catch` y se
/// avisan como todo el módulo. A `mostrarReportePdf` le queda lo suyo:
/// compartir.
Future<void> exportarSabadoPdf({
  required BuildContext context,
  required WidgetRef ref,
  required SabadoEntity sabado,
}) async {
  try {
    final bytes = await ref
        .read(rolSabadosRepositoryProvider)
        .getReporteSabadoPdf(sabado.idSabado);

    if (!context.mounted) return;
    await mostrarReportePdf(
      context: context,
      // Ya está bajado: esto sólo se lo entrega.
      downloadFunction: () async => bytes,
      filename: nombreArchivoSabado(sabado),
    );
  } catch (e) {
    // El detalle al log y no a la pantalla: los tres modos de falla de un
    // reporte —el SP, el .jasper que falta, la red— son todos cosas que quien
    // usa la app no puede arreglar, y el texto crudo de Dio está en inglés.
    console('⚠️ Falló el PDF del sábado ${sabado.idSabado}: $e');
    if (!context.mounted) return;
    avisar(
      context,
      'No se pudo generar el PDF de ese sábado. Vuelve a intentar; si sigue '
      'pasando, avisa a Sistemas.',
      esError: true,
    );
  }
}
