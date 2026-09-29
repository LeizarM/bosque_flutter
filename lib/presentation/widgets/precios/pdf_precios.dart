/// Los PDF del modulo de precios: la propuesta, los precios por tonelada y el
/// catalogo de familias activas. Los arma Jasper en el backend
/// (`ReportesPreciosService`); aca solo se piden y se muestran.
///
/// Reemplazan a los reportes del JSF (rptPropuArt, RptArtPropuPorArticulo,
/// RptPrecioActFam, RptTodoPrecioFam y RptFamiliasActivas).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/precios_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/presentation/widgets/precios/propuesta_en_autorizacion.dart';

/// Genera un PDF y lo muestra en el visor, con un aviso de espera mientras
/// tanto. Si el backend lo rechaza -la propuesta no tiene precios, el grupo no
/// tiene familias- se muestra su mensaje.
Future<void> verPdfDePrecios(
  BuildContext context, {
  required Future<Uint8List> Function() generar,
  required String titulo,
  required String nombreArchivo,
  String espera = 'Generando el PDF…',
}) async {
  final cerrarEspera = mostrarEsperaDePrecios(context, espera);
  try {
    final bytes = await generar();
    cerrarEspera();
    if (!context.mounted) return;
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: titulo,
      nombreArchivo: nombreArchivo,
    );
  } catch (e) {
    cerrarEspera();
    if (!context.mounted) return;
    avisar(context, textoParaUsuario(e), esError: true);
  }
}

/// El PDF de una propuesta. Tarda mas que los otros: el servidor consulta en
/// otro servidor los articulos que faltan crear en las otras empresas.
Future<void> verPdfDePropuesta(
  BuildContext context,
  WidgetRef ref,
  PropuestaEnAutorizacion fila,
) => verPdfDePrecios(
  context,
  generar:
      () => ref
          .read(preciosRepositoryProvider)
          .reportePropuesta(fila.idPropuesta),
  titulo: 'Propuesta ${fila.numero}',
  nombreArchivo: 'propuesta-precios-${fila.idPropuesta}.pdf',
  espera:
      'Generando el PDF de la propuesta ${fila.numero}. Puede tardar: se '
      'consultan los artículos que faltan crear en las otras empresas.',
);

/// Un aviso modal de espera, sin boton de cerrar: lo cierra la funcion que
/// devuelve. Lo usan los PDF y la generacion de la propuesta, que tambien
/// espera al servidor.
VoidCallback mostrarEsperaDePrecios(BuildContext context, String texto) {
  var cerrado = false;
  final navegador = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder:
        (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: Esp.l),
                Expanded(child: Text(texto)),
              ],
            ),
          ),
        ),
  );
  return () {
    if (cerrado) return;
    cerrado = true;
    navegador.pop();
  };
}
