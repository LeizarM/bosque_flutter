/// Las piezas de interfaz que ya no son de un módulo: el estado vacío, la
/// etiqueta de estado, el combo con buscador y la fecha corta.
///
/// **Por qué están acá y no copiadas otra vez.** Las cuatro nacieron en el Rol
/// de Sábados, y `permisos-rrhh` iba a ser la segunda copia de cada una — que es
/// como empiezan las divergencias que después nadie unifica: el mismo estado
/// vacío con dos textos distintos, la misma etiqueta con dos verdes. Se movieron
/// tal cual estaban —sin cambiar un pixel— y `rol-sabados/rol_sabados_comunes.dart`
/// quedó como re-export, así que sus importadores no se enteran.
///
/// Es la misma operación que ya se hizo con `Esp`, `Peso`, `Aire` y `avisar`
/// (ver `tokens_bosque.dart` y `aviso.dart`).
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Deja arrastrar con el mouse un scroll horizontal.
///
/// En web y escritorio Flutter saca el mouse de `dragDevices` a proposito: en
/// una pagina vertical, arrastrar con el boton izquierdo selecciona texto. El
/// efecto colateral es que una tabla ancha queda inalcanzable, porque la rueda
/// del mouse va al eje vertical y el arrastre no hace nada.
///
/// Se aplica solo a los scrolls horizontales, nunca al cuerpo de la pagina.
class ArrastreLateral extends MaterialScrollBehavior {
  const ArrastreLateral();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

/// `dd/MM/yyyy`, o `--` si no hay fecha. Sin `intl` para no arrastrar locale
/// por tres usos.
String fechaCorta(DateTime? f) =>
    f == null
        ? '--'
        : '${f.day.toString().padLeft(2, '0')}/'
            '${f.month.toString().padLeft(2, '0')}/${f.year}';

/// Estado vacío o de error, con una explicación de qué significa.
///
/// **Siempre dice dos cosas: por qué no hay nada y qué hacer.** Una pantalla en
/// blanco —o un «Sin datos» pelado— deja a quien la mira sin saber si el sistema
/// falló, si buscó mal o si de verdad no hay nada.
class MensajeVacio extends StatelessWidget {
  const MensajeVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) => Center(
    // **Scrollea si no entra.** Es un mensaje de tres líneas y un icono, pero
    // en un teléfono de 740 px de alto —con una cabecera arriba y el teclado
    // abierto— el hueco que le queda puede ser de 116 px. Un `Column` que no
    // entra no se acomoda: pinta la franja amarilla y negra justo donde había
    // que explicar por qué no hay datos. Con el `Center` afuera sigue centrado
    // cuando sí entra, porque el viewport se encoge hasta su hijo.
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 44, color: Theme.of(context).hintColor),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

/// Etiqueta de estado. El color viene del significado, no del texto.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    this.tono = TonoEtiqueta.neutro,
  });

  final String texto;
  final TonoEtiqueta tono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, letra) = switch (tono) {
      TonoEtiqueta.exito => (cs.primaryContainer, cs.onPrimaryContainer),
      TonoEtiqueta.aviso => (cs.tertiaryContainer, cs.onTertiaryContainer),
      TonoEtiqueta.error => (cs.errorContainer, cs.onErrorContainer),
      TonoEtiqueta.neutro => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: letra,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum TonoEtiqueta { neutro, exito, aviso, error }

/// Un combo con buscador, para listas de gente.
///
/// **Por qué no un `DropdownButtonFormField`.** Con 85 personas, el desplegable
/// común obliga a recorrer una lista larguísima en el orden en que vinieron de
/// la base —que es el del organigrama, no uno que ayude a buscar— y sin forma de
/// escribir. Encontrar a alguien es scroll y suerte.
///
/// Acá las opciones vienen **ordenadas alfabéticamente** y se filtran a medida
/// que se escribe.
class ComboBuscable<T> extends StatelessWidget {
  const ComboBuscable({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.onElegir,
    this.ayuda,
    this.pista,
  });

  final String etiqueta;
  final T? valor;

  /// Ya ordenadas por quien las arma: el orden depende de qué son.
  final List<DropdownMenuEntry<T>> opciones;

  final ValueChanged<T?> onElegir;
  final String? ayuda;
  final String? pista;

  @override
  Widget build(BuildContext context) => DropdownMenu<T>(
    // La clave incluye el valor para que el campo de texto se limpie solo
    // cuando el valor lo resetea alguien de afuera — al cambiar de sábado, por
    // ejemplo, donde las dos listas de personas dejan de servir.
    key: ValueKey('$etiqueta-$valor-${opciones.length}'),
    initialSelection: valor,
    label: Text(etiqueta),
    helperText: ayuda,
    hintText: pista ?? 'Escribe para buscar…',
    enableFilter: true,
    requestFocusOnTap: true,
    expandedInsets: EdgeInsets.zero,
    menuHeight: 320,
    leadingIcon: const Icon(Icons.search, size: 18),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    dropdownMenuEntries: opciones,
    onSelected: opciones.isEmpty ? null : onElegir,
  );
}
