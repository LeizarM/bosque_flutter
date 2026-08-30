import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

/// Un error que se puede reintentar, con el texto ya traducido.
///
/// **Por qué no basta con un `Text('$e')`.** Interpolar la excepción cruda le
/// muestra a la persona un `DioException [connection error]` o el nombre de un
/// stored procedure, y encima la deja sin salida: si el catálogo de empleados
/// falló, el formulario queda inservible y lo único que se puede hacer es el
/// back. [textoParaUsuario] ya traduce eso; acá se le suma el reintento.
///
/// Con [compacto] queda del alto de un campo de formulario, para cuando lo que
/// falló es un combo y no la pantalla entera.
class MensajeError extends StatelessWidget {
  const MensajeError({
    super.key,
    required this.error,
    this.onReintentar,
    this.compacto = false,
  });

  final Object? error;
  final VoidCallback? onReintentar;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texto = textoParaUsuario(error);

    if (compacto) {
      return Container(
        padding: const EdgeInsets.all(Esp.m),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onErrorContainer),
              ),
            ),
            if (onReintentar != null)
              TextButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Esp.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: cs.error),
            const SizedBox(height: Esp.m),
            Text(
              'No se pudo cargar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Esp.xs + 2),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: Esp.l),
              FilledButton.tonalIcon(
                onPressed: onReintentar,
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

/// Filas grises del alto real de las que van a llegar.
///
/// **Por qué no un spinner.** Un `CircularProgressIndicator` centrado borra la
/// lista que había, y al llegar los datos el contenido salta desde el centro
/// hacia arriba. El esqueleto reserva el lugar, así la página no se mueve.
///
/// Solo para la **primera** carga. En una recarga con datos ya en pantalla, lo
/// correcto es dejar la lista quieta y contar la espera con una barra de 2 px:
/// reemplazarla por bloques grises hace parecer que se perdió lo que había.
class EsqueletoLista extends StatelessWidget {
  const EsqueletoLista({super.key, this.filas = 6, this.altoFila = 72});

  final int filas;
  final double altoFila;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(Esp.m),
      itemCount: filas,
      separatorBuilder: (_, __) => const SizedBox(height: Esp.s),
      itemBuilder:
          (_, i) => _Bloque(
            alto: altoFila,
            color: cs.surfaceContainerHighest,
            // Se van apagando hacia abajo: insinúa que la lista sigue y evita
            // el bloque macizo de seis rectángulos iguales.
            opacidad: 1 - (i * 0.12).clamp(0.0, 0.6),
          ),
    );
  }
}

class _Bloque extends StatefulWidget {
  const _Bloque({
    required this.alto,
    required this.color,
    required this.opacidad,
  });

  final double alto;
  final Color color;
  final double opacidad;

  @override
  State<_Bloque> createState() => _BloqueState();
}

class _BloqueState extends State<_Bloque> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    // 1200ms: un latido lento dice "esperá" sin pedir atención. Más rápido
    // parpadea y compite con el contenido que está por llegar.
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: 0.45 * widget.opacidad,
      end: 0.95 * widget.opacidad,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: Container(
      height: widget.alto,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
    ),
  );
}

/// Un aviso pegado al dato que lo provoca, no un toast que se va.
///
/// El toast sirve para confirmar que algo pasó. Para una advertencia que el
/// usuario tiene que tener a la vista mientras decide —"esta sigla nunca se usó
/// en esta empresa"— hace falta algo que se quede junto al campo.
class NotaDelDato extends StatelessWidget {
  const NotaDelDato({
    super.key,
    required this.texto,
    this.tono = TonoNota.info,
    this.icono,
    this.accion,
  });

  final String texto;
  final TonoNota tono;
  final IconData? icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Del ColorScheme y no de Colors.*: el usuario elige entre nueve semillas
    // y hay modo oscuro. Un naranja fijo se ve de otra app en ocho de ellas.
    final (fondo, letra, iconoPorDefecto) = switch (tono) {
      TonoNota.info => (
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
        Icons.info_outline,
      ),
      TonoNota.exito => (
        cs.primaryContainer,
        cs.onPrimaryContainer,
        Icons.check_circle_outline,
      ),
      TonoNota.aviso => (
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
        Icons.warning_amber_rounded,
      ),
      TonoNota.error => (
        cs.errorContainer,
        cs.onErrorContainer,
        Icons.report_problem_outlined,
      ),
    };

    return Container(
      margin: const EdgeInsets.only(top: Esp.s),
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono ?? iconoPorDefecto, size: 18, color: letra),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: letra),
            ),
          ),
          if (accion != null) ...[const SizedBox(width: Esp.s), accion!],
        ],
      ),
    );
  }
}

enum TonoNota { info, exito, aviso, error }
