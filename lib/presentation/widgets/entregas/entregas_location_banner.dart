import 'package:flutter/material.dart';

import 'package:bosque_flutter/presentation/widgets/entregas/entregas_ui.dart';

/// Aviso de que falta la ubicación.
///
/// <h3>Qué cambió y por qué</h3>
/// Antes era un bloque rojo a todo lo ancho, centrado, pegado abajo de la
/// pantalla. Pesaba como un error crítico cuando en realidad es una condición
/// que el usuario puede resolver en diez segundos, y estaba tan lejos del botón
/// que bloqueaba ("Iniciar entregas", arriba a la derecha) que no se leía como
/// causa de nada.
///
/// Ahora es una tira ámbar de aviso, alineada a la izquierda como el resto del
/// contenido, con el texto explicando la consecuencia concreta en vez de
/// repetir el título. El rojo queda libre para los errores de verdad.
class EntregasLocationBanner extends StatelessWidget {
  final bool isLocationEnabled;
  final VoidCallback onVerifyPermissions;

  const EntregasLocationBanner({
    super.key,
    required this.isLocationEnabled,
    required this.onVerifyPermissions,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocationEnabled) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = oscuro ? const Color(0xFF3A3320) : const Color(0xFFFBF1DC);
    final texto = oscuro ? const Color(0xFFE0BE72) : const Color(0xFF7A5A14);

    final angosto = EntregasUI.esAngosto(context);

    final icono = Icon(Icons.location_off_outlined, size: 18, color: texto);
    final mensaje = Text(
      angosto
          ? 'Ubicación desactivada. Sin ella no se puede marcar entregas.'
          : 'La ubicación está desactivada. Sin ella no se puede iniciar '
              'la ruta ni marcar entregas.',
      style: TextStyle(fontSize: 13, height: 1.35, color: texto),
    );
    final accion = TextButton(
      onPressed: onVerifyPermissions,
      style: TextButton.styleFrom(
        foregroundColor: texto,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: EntregasUI.s3),
      ),
      child: const Text('Verificar permisos'),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fondo,
        border: Border(top: BorderSide(color: EntregasUI.hairline(cs))),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: EntregasUI.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: EntregasUI.padH(context),
              vertical: EntregasUI.s3,
            ),
            // En un telefono, "texto largo + boton" en una sola fila deja al
            // texto en una columna de ~130 px. Se apila: el mensaje arriba y la
            // accion abajo alineada a la izquierda, donde cae el pulgar.
            child: angosto
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: icono,
                          ),
                          const SizedBox(width: EntregasUI.s2),
                          Expanded(child: mensaje),
                        ],
                      ),
                      Align(alignment: Alignment.centerLeft, child: accion),
                    ],
                  )
                : Row(
                    children: [
                      icono,
                      const SizedBox(width: EntregasUI.s3),
                      Expanded(child: mensaje),
                      const SizedBox(width: EntregasUI.s3),
                      accion,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
