/// Exportar UN sábado a PDF: el camino a WhatsApp.
///
/// Archivo propio: lo usan la matriz y la agenda (`matriz_grilla.dart` ya
/// importa `agenda_sabado.dart`; en uno de los dos armaría un ciclo). **No
/// maneja el estado de ocupado**: lo lleva cada botón y debe sobrevivir al cierre
/// del menú, o un segundo toque generaría dos PDF.
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
/// En WhatsApp es lo único visible hasta abrirlo: `reporte.pdf` no dice de qué
/// sábado es. Formato `aaaa-mm-dd` (la `/` no es válida en nombres de archivo y
/// ordena por fecha).
String nombreArchivoSabado(SabadoEntity sabado) {
  final f = sabado.fecha;
  if (f == null) return 'rol-sabado-${sabado.idSabado}.pdf';
  final mes = f.month.toString().padLeft(2, '0');
  final dia = f.day.toString().padLeft(2, '0');
  return 'rol-sabado-${f.year}-$mes-$dia.pdf';
}

/// Baja el PDF de [sabado] y abre la hoja de compartir del sistema (WhatsApp en
/// el teléfono; en escritorio y web se descarga).
///
/// Los bytes se bajan aquí y no en `mostrarReportePdf`, cuyo `ScaffoldMessenger`
/// dibuja el SnackBar DEBAJO de los diálogos (ver `shared/aviso.dart`): así los
/// errores (500 de Jasper, token vencido, red) caen en este `catch`.
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
    // Detalle al log y no a la pantalla: el SP, el .jasper faltante o la red no
    // los arregla quien usa la app, y el texto crudo de Dio está en inglés.
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
