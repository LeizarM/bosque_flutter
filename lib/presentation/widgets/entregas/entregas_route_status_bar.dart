import 'package:flutter/material.dart';

import 'package:bosque_flutter/presentation/widgets/entregas/entregas_ui.dart';

/// Cabecera de la ruta: en qué estado está y la única acción que corresponde.
///
/// <h3>Qué cambió y por qué</h3>
/// Antes era una franja de color a todo lo ancho (`primaryContainer`, un rosa
/// fuerte) con el texto también teñido del color primario. Tres problemas:
/// el bloque de color pesaba más que la tabla, que es el contenido real; el
/// texto coloreado sobre fondo coloreado bajaba el contraste; y "ruta iniciada"
/// y "ruta no iniciada" se distinguían solo por la palabra, no por la forma.
///
/// Ahora el fondo es neutro y el estado se comunica con un punto de color y el
/// peso de la tipografía. El color quedó reservado para el botón, que es lo
/// único accionable de la barra.
class EntregasRouteStatusBar extends StatelessWidget {
  final bool rutaIniciada;
  final DateTime? fechaInicio;
  final bool isLocationEnabled;
  final bool isProcessing;
  final bool entregasVacias;
  final VoidCallback onIniciarRuta;
  final VoidCallback onFinalizarRuta;

  const EntregasRouteStatusBar({
    super.key,
    required this.rutaIniciada,
    this.fechaInicio,
    required this.isLocationEnabled,
    required this.isProcessing,
    required this.entregasVacias,
    required this.onIniciarRuta,
    required this.onFinalizarRuta,
  });

  String _fechaLegible(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}'
      ' · ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activa = rutaIniciada;
    final angosto = EntregasUI.esAngosto(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: EntregasUI.hairline(cs))),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: EntregasUI.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: EntregasUI.padH(context),
              vertical: EntregasUI.padV(context),
            ),
            child: Row(
              children: [
                // Punto de estado: verde late cuando la ruta corre, gris cuando no.
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: EntregasUI.s3, top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activa
                        ? const Color(0xFF2E9E63)
                        : cs.outline.withValues(alpha: 0.6),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activa ? 'Ruta iniciada' : 'Ruta no iniciada',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.1,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fechaInicio != null
                            ? 'Desde ${_fechaLegible(fechaInicio!)}'
                            : (angosto
                                ? 'Iniciá la ruta para marcar'
                                : 'Iniciá la ruta para poder marcar entregas'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: EntregasUI.muted(cs),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: angosto ? EntregasUI.s2 : EntregasUI.s4),
                if (isProcessing)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: EntregasUI.s4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  _BotonRuta(
                    activa: activa,
                    angosto: angosto,
                    habilitado: activa
                        ? isLocationEnabled
                        : (!entregasVacias && isLocationEnabled),
                    onPressed: activa ? onFinalizarRuta : onIniciarRuta,
                    // Sin ubicación el botón está gris y nadie sabe por qué.
                    // El tooltip lo dice sin ocupar espacio permanente.
                    motivoBloqueo: !isLocationEnabled
                        ? 'Activá la ubicación para continuar'
                        : (entregasVacias && !activa
                            ? 'No hay entregas para iniciar'
                            : null),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonRuta extends StatelessWidget {
  final bool activa;
  final bool habilitado;
  final bool angosto;
  final VoidCallback onPressed;
  final String? motivoBloqueo;

  const _BotonRuta({
    required this.activa,
    required this.habilitado,
    required this.angosto,
    required this.onPressed,
    this.motivoBloqueo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Finalizar es destructivo-ish (cierra el día), pero no es un error: va como
    // botón de contorno y no como bloque rojo lleno, que gritaba desde la
    // esquina de la pantalla todo el día.
    // En angosto se cae el icono y se acorta el texto. Con "Finalizar entregas"
    // + icono el boton pide ~190 px, que en un telefono de 360 deja al titulo
    // sin lugar y lo parte en tres renglones.
    final String etiqueta = activa
        ? (angosto ? 'Finalizar' : 'Finalizar entregas')
        : (angosto ? 'Iniciar' : 'Iniciar entregas');

    final Widget boton = activa
        ? OutlinedButton.icon(
            onPressed: habilitado ? onPressed : null,
            icon: angosto
                ? const SizedBox.shrink()
                : const Icon(Icons.flag_outlined, size: 18),
            label: Text(etiqueta),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
              padding: EdgeInsets.symmetric(
                horizontal: angosto ? EntregasUI.s3 : EntregasUI.s4,
                vertical: EntregasUI.s3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EntregasUI.rInner),
              ),
            ),
          )
        : FilledButton.icon(
            onPressed: habilitado ? onPressed : null,
            icon: angosto
                ? const SizedBox.shrink()
                : const Icon(Icons.local_shipping_outlined, size: 18),
            label: Text(etiqueta),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: angosto ? EntregasUI.s3 : EntregasUI.s4,
                vertical: EntregasUI.s3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EntregasUI.rInner),
              ),
            ),
          );

    if (!habilitado && motivoBloqueo != null) {
      return Tooltip(message: motivoBloqueo!, child: boton);
    }
    return boton;
  }
}
