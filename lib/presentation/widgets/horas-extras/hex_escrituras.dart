/// Escrituras y errores del módulo Horas Extras: una sola escritura a la vez,
/// confirmable con reenvío, 409 con recarga, 403 como «No tienes permiso»
/// y el PDF.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/ui/visor_pdf.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_haptica.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ERRORES Y 403
// ═══════════════════════════════════════════════════════════════════════════

const String _sinPermiso = 'No tienes permiso para esta acción.';

/// El texto de un error, de una sola fuente: 403 con el texto del módulo, la
/// regla del SP tal cual (400 y 409) y lo técnico traducido.
String textoErrorHex(Object e) => switch (e) {
  SinPermisoHex() => _sinPermiso,
  ErrorHex(:final mensaje) => mensaje,
  _ => textoParaUsuario(e),
};

/// Lo que ve quien no tiene la pantalla o el botón (403).
class SinPermisoHexVista extends StatelessWidget {
  const SinPermisoHexVista({super.key});

  @override
  Widget build(BuildContext context) => const MensajeVacio(
    icono: Icons.lock_outline,
    titulo: 'No tienes permiso',
    detalle: 'Pide a tu administrador que te habilite esta pantalla.',
  );
}

/// La vista de error de una lectura: 403 como «No tienes permiso», la regla
/// del SP con su texto intacto y lo técnico con `MensajeError`.
Widget vistaErrorHex(Object error, {VoidCallback? reintentar}) =>
    switch (error) {
      SinPermisoHex() => const SinPermisoHexVista(),
      ErrorHex() => _ErrorDelServidorHex(
        mensaje: textoErrorHex(error),
        reintentar: reintentar,
      ),
      _ => MensajeError(error: error, onReintentar: reintentar),
    };

/// `MensajeError` pasa el texto por `humanizar`, que reescribe frases como
/// «es obligatorio»; la regla del SP tiene que llegar sin tocar.
class _ErrorDelServidorHex extends StatelessWidget {
  const _ErrorDelServidorHex({required this.mensaje, this.reintentar});

  final String mensaje;
  final VoidCallback? reintentar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rule_outlined, size: 44, color: cs.tertiary),
            const SizedBox(height: Esp.m),
            Text(
              'No se pudo cargar',
              textAlign: TextAlign.center,
              style: t.titleMedium,
            ),
            const SizedBox(height: Esp.xs + 2),
            Text(mensaje, textAlign: TextAlign.center, style: t.bodyMedium),
            if (reintentar != null) ...[
              const SizedBox(height: Esp.l),
              FilledButton.tonalIcon(
                onPressed: reintentar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ESCRITURAS
// ═══════════════════════════════════════════════════════════════════════════

/// Si hay una escritura en curso; deshabilita su botón mientras vale `true`.
/// Sabe si ya se descartó, para no tocarlo cuando la pantalla se cerró.
class OcupadoHex extends ValueNotifier<bool> {
  OcupadoHex([super.value = false]);

  bool _descartado = false;

  bool get descartado => _descartado;

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}

/// Lo que dejó una escritura: si salió bien y el texto del SP o del error.
typedef ResultadoHex = ({bool exito, String mensaje});

/// Corre una escritura una sola vez aunque se toque dos veces: mensaje del SP,
/// confirmable con reenvío y recarga ante un 409. Devuelve si salió bien. Con
/// [alResultado] el resultado va ahí y no a un aviso (no se llama si cancela).
Future<bool> ejecutarHex(
  BuildContext context, {
  required OcupadoHex ocupado,
  required Future<HexRespuesta> Function(bool confirmado) accion,
  required VoidCallback refrescar,
  ValueChanged<ResultadoHex>? alResultado,
}) async {
  if (ocupado.value) return false;
  ocupado.value = true;
  try {
    return await _escribirHex(
      context,
      accion: accion,
      refrescar: refrescar,
      alResultado: alResultado,
    );
  } finally {
    if (!ocupado.descartado) ocupado.value = false;
  }
}

/// Una vuelta de la escritura. `refrescar` solo con la pantalla montada: su
/// `ref` muere con ella.
Future<bool> _escribirHex(
  BuildContext context, {
  required Future<HexRespuesta> Function(bool confirmado) accion,
  required VoidCallback refrescar,
  ValueChanged<ResultadoHex>? alResultado,
  bool confirmado = false,
}) async {
  try {
    final r = await accion(confirmado);
    if (!context.mounted) return true;
    if (alResultado != null) {
      alResultado((exito: true, mensaje: r.mensaje));
    } else if (r.mensaje.isNotEmpty) {
      mostrarAviso(context, r.mensaje);
    }
    HapticaHex.exito();
    refrescar();
    return true;
  } on ConfirmacionHex catch (e) {
    // Un segundo pedido de confirmación no se vuelve a preguntar: se avisa.
    if (!context.mounted) return false;
    if (confirmado) {
      _avisarFalloHex(context, e, refrescar, alResultado);
      return false;
    }
    if (!await confirmarHex(context, e.mensaje) || !context.mounted) {
      return false;
    }
    return _escribirHex(
      context,
      accion: accion,
      refrescar: refrescar,
      alResultado: alResultado,
      confirmado: true,
    );
  } catch (e) {
    if (context.mounted) _avisarFalloHex(context, e, refrescar, alResultado);
    return false;
  }
}

/// Avisa el fallo con el texto de [textoErrorHex]. El `switch` sobre el error
/// sellado lo revisa el compilador: un subtipo nuevo obliga a decidir aquí.
void _avisarFalloHex(
  BuildContext context,
  Object e,
  VoidCallback refrescar,
  ValueChanged<ResultadoHex>? alResultado,
) {
  HapticaHex.aviso();
  if (e is ConflictoHex) refrescar();
  if (alResultado != null) {
    alResultado((exito: false, mensaje: textoErrorHex(e)));
    return;
  }
  if (e is! ErrorHex) {
    mostrarAviso(context, textoErrorHex(e), tono: TonoAviso.error);
    return;
  }
  final tono = switch (e) {
    SinDatosHex() => TonoAviso.aviso,
    ConflictoHex() ||
    SinPermisoHex() ||
    NegocioHex() ||
    ConfirmacionHex() => TonoAviso.error,
  };
  mostrarAviso(context, textoErrorHex(e), tono: tono);
}

/// Diálogo del 400 confirmable: el mensaje del SP y la decisión.
Future<bool> confirmarHex(BuildContext context, String mensajeSp) {
  FocusManager.instance.primaryFocus?.unfocus();
  return confirmar(
    context,
    titulo: 'Confirma antes de seguir',
    detalle: mensajeSp,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PDF
// ═══════════════════════════════════════════════════════════════════════════

/// Genera un PDF con espera visible y lo abre en el visor. Sin bytes avisa
/// que no hay datos; un error llega con el texto de [textoErrorHex].
Future<void> verPdfHex(
  BuildContext context, {
  required Future<Uint8List?> Function() generar,
  required String titulo,
  required String nombreArchivo,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final cerrarEspera = _mostrarEsperaHex(context, 'Generando el PDF…');
  try {
    final bytes = await generar();
    cerrarEspera();
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      mostrarAviso(context, 'No hay datos para el PDF.', tono: TonoAviso.aviso);
      return;
    }
    await mostrarPdf(
      context,
      bytes: bytes,
      titulo: titulo,
      nombreArchivo: nombreArchivo,
    );
  } catch (e) {
    cerrarEspera();
    if (!context.mounted) return;
    mostrarAviso(
      context,
      textoErrorHex(e),
      tono: e is SinDatosHex ? TonoAviso.aviso : TonoAviso.error,
    );
  }
}

/// Diálogo de espera que no se cierra con el back; devuelve cómo cerrarlo,
/// a prueba de llamarlo dos veces.
VoidCallback _mostrarEsperaHex(BuildContext context, String texto) {
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
