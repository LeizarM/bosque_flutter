import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ofrece el comprobante en PDF justo después de cerrar o completar un flujo.
///
/// En el sistema legacy el PDF no era un extra: era el paso con el que el
/// movimiento **entraba a archivo**. Al cerrar un arqueo o una caja chica se
/// generaba el reporte ahí mismo y se imprimía para la carpeta (Marcelo,
/// 2026-09-07: "cuando se cerraba o se completaba se podía generar su reporte
/// para que entre a archivo"). Dejar el reporte solamente en una pantalla de
/// histórico rompe eso: hay que acordarse de volver a buscarlo, y el momento
/// en que la persona lo tiene fresco ya pasó.
///
/// Se ofrece, no se impone: el diálogo tiene salida ("Ahora no"), porque el
/// flujo ya quedó cerrado en el servidor y no imprimir no lo invalida.
///
/// [generar] se llama recién si la persona acepta — no se descarga un PDF que
/// nadie pidió. Mientras viaja, los dos botones quedan inertes para que un
/// doble click no dispare dos veces la generación.
Future<void> ofrecerPdf(
  BuildContext context, {
  required String titulo,
  required String nombreArchivo,
  required String mensaje,
  required Future<Uint8List> Function() generar,
  String tituloDialogo = 'Listo',
}) async {
  var generando = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, setDialogState) => AlertDialog(
                title: Text(tituloDialogo),
                content: Text(mensaje),
                actions: [
                  TextButton(
                    onPressed: generando ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('Ahora no'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        generando
                            ? null
                            : () async {
                              setDialogState(() => generando = true);
                              HapticFeedback.selectionClick();
                              try {
                                final bytes = await generar();
                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();
                                await mostrarPdf(
                                  context,
                                  bytes: bytes,
                                  titulo: titulo,
                                  nombreArchivo: nombreArchivo,
                                );
                              } catch (_) {
                                if (!ctx.mounted) return;
                                setDialogState(() => generando = false);
                                HapticFeedback.lightImpact();
                                mostrarAviso(
                                  ctx,
                                  'No se pudo generar el PDF. El movimiento igual quedó guardado.',
                                  tono: TonoAviso.error,
                                );
                              }
                            },
                    icon:
                        generando
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Ver PDF'),
                  ),
                ],
              ),
        ),
  );
}
