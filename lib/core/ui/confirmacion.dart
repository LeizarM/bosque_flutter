import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Pide confirmación antes de una escritura que el usuario no puede deshacer
/// o que cuesta cara rehacer.
///
/// **Cuándo usarla.** No para todo: un diálogo que aparece siempre deja de
/// leerse y se contesta con el pulgar. Sirve para dos casos:
///
/// - lo **irreversible** (`destructiva: true`): cerrar un talonario no se
///   deshace, y hoy se dispara con un toque en un menú;
/// - lo **masivo**: entregar 60 talonarios escribe 60 filas de una, y conviene
///   que el resumen de a quién y con qué fecha se lea antes y no después.
///
/// Devuelve `true` solo si la persona confirmó. El `barrierDismissible` queda
/// en falso a propósito: tocar fuera no puede contar como un sí.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String detalle,
  String textoConfirmar = 'Confirmar',
  String textoCancelar = 'Cancelar',
  bool destructiva = false,
}) async {
  final cs = Theme.of(context).colorScheme;

  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => AlertDialog(
          icon: Icon(
            destructiva ? Icons.warning_amber_rounded : Icons.help_outline,
            color: destructiva ? cs.error : cs.primary,
          ),
          title: Text(titulo),
          // Scrollea: el detalle puede ser un resumen de varias líneas y en un
          // teléfono con el teclado abierto el hueco es chico.
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(detalle),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(textoCancelar),
            ),
            FilledButton(
              style:
                  destructiva
                      ? FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                      )
                      : null,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(textoConfirmar),
            ),
          ],
        ),
  );
  return r ?? false;
}

/// Evita que un back se lleve puesto el trabajo a medio hacer.
///
/// Un formulario de alta masiva son ocho campos más una previsualización de
/// sesenta talonarios; una entrega masiva pueden ser trescientos tildes. Un
/// toque en el back —o el gesto del sistema, que ni siquiera es un toque— los
/// borra sin preguntar.
///
/// Solo pregunta si [hayCambios]. Si no hay nada que perder, sale derecho: una
/// confirmación sobre un formulario vacío es ruido.
class GuardiaDeSalida extends StatelessWidget {
  const GuardiaDeSalida({
    super.key,
    required this.hayCambios,
    required this.child,
    this.mensaje = 'Si salís ahora se pierde lo que cargaste.',
  });

  final bool hayCambios;
  final Widget child;
  final String mensaje;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !hayCambios,
    onPopInvokedWithResult: (yaSalio, _) async {
      if (yaSalio || !hayCambios) return;
      final salir = await confirmar(
        context,
        titulo: '¿Descartar los cambios?',
        detalle: mensaje,
        textoConfirmar: 'Descartar',
        textoCancelar: 'Seguir editando',
        destructiva: true,
      );
      if (salir && context.mounted) Navigator.of(context).pop();
    },
    child: child,
  );
}

/// El botón de una acción que escribe, con su estado de "en curso".
///
/// **Por qué existe.** Sin esto, guardar un lote de sesenta talonarios deja el
/// botón idéntico mientras el request viaja: la persona no sabe si el toque
/// entró, y vuelve a tocar. En una operación todo-o-nada eso es un segundo
/// lote, o un segundo cierre sobre algo que ya está cerrado.
///
/// Mientras [ocupado] el botón queda deshabilitado —no es solo cosmético— y
/// muestra un spinner del tamaño del texto para que la fila no salte.
class BotonAccion extends StatelessWidget {
  const BotonAccion({
    super.key,
    required this.etiqueta,
    required this.onPressed,
    this.etiquetaOcupado,
    this.icono,
    this.ocupado = false,
    this.tonal = false,
    this.destructiva = false,
  });

  final String etiqueta;

  /// Qué dice mientras escribe. Si no se da, repite [etiqueta].
  final String? etiquetaOcupado;

  final IconData? icono;
  final VoidCallback? onPressed;
  final bool ocupado;

  /// Acción secundaria: previsualizar, recalcular. No escribe.
  final bool tonal;

  final bool destructiva;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hijo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ocupado)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tonal ? cs.onSecondaryContainer : cs.onPrimary,
            ),
          )
        else if (icono != null)
          Icon(icono, size: 18),
        if (ocupado || icono != null) const SizedBox(width: Esp.s),
        // Flexible: la etiqueta lleva el conteo ("Entregar 300 talonarios") y
        // en un teléfono angosto no entra.
        Flexible(
          child: Text(
            ocupado ? (etiquetaOcupado ?? etiqueta) : etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final alTocar = ocupado ? null : onPressed;

    if (tonal) {
      return FilledButton.tonal(onPressed: alTocar, child: hijo);
    }
    return FilledButton(
      style:
          destructiva
              ? FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              )
              : null,
      onPressed: alTocar,
      child: hijo,
    );
  }
}
