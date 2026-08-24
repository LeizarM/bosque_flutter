import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

/// Tokens visuales del módulo de Comisiones.
///
/// Existe porque el módulo son nueve pestañas construidas en tandas distintas,
/// y sin un lugar único cada una terminó eligiendo su propio radio, su propio
/// espaciado y su propio gris. El resultado se nota: la misma tabla se ve de
/// dos maneras según por dónde entres.
///
/// Tres reglas que este archivo hace cumplir:
///
///   FORMA     un solo radio por tipo de elemento. Contenedores 12, controles
///             10, chips 6. Nada de cards redondas junto a cards cuadradas.
///   COLOR     todo sale del ColorScheme del tema. Ni un hex suelto, para que
///             el modo oscuro funcione sin una segunda paleta.
///   NÚMEROS   cifras tabulares SIEMPRE. Sin eso las columnas de importes no
///             alinean y una tabla de plata deja de poder leerse en diagonal.
///
/// La densidad es alta a propósito: esto es una herramienta de trabajo donde se
/// comparan importes, no una página de producto. El aire se gana quitando
/// cajas, no agrandando separaciones.
class ComisionesTema {
  const ComisionesTema._();

  // ── Tipografia ───────────────────────────────────────────────────────────
  /// Interfaz. Roboto es la tipografia por defecto de Android: funciona, pero
  /// se lee como pantalla sin disenar. Esta tiene la misma legibilidad a 11px
  /// y caracter propio.
  static const String fuenteUI = 'PlusJakartaSans';

  /// Importes, y solo importes. Ancho fijo de verdad, no cifras tabulares
  /// simuladas: las columnas de plata alinean por construccion. Ademas el cero
  /// va con barra, asi que no se confunde con la O al cantar un numero de nota.
  static const String fuenteMonto = 'JetBrainsMono';

  // ── Espaciado ────────────────────────────────────────────────────────────
  // Escala de 4. Suficientes escalones para jerarquía, pocos para no inventar
  // un valor nuevo en cada pantalla.
  static const double esp1 = 4;
  static const double esp2 = 8;
  static const double esp3 = 12;
  static const double esp4 = 16;
  static const double esp5 = 24;
  static const double esp6 = 32;

  // ── Forma ────────────────────────────────────────────────────────────────
  static const double radioContenedor = 12;
  static const double radioControl = 10;
  static const double radioChip = 6;

  static BorderRadius get brContenedor =>
      BorderRadius.circular(radioContenedor);
  static BorderRadius get brControl => BorderRadius.circular(radioControl);
  static BorderRadius get brChip => BorderRadius.circular(radioChip);

  // ── Densidad de tablas ───────────────────────────────────────────────────
  /// Alto de fila. En móvil no se usan tablas, así que solo hay un valor.
  static const double altoFila = 44;
  static const double altoEncabezado = 40;
  static const double separacionColumnas = 20;

  // ── Números ──────────────────────────────────────────────────────────────
  /// Cifras tabulares: todos los dígitos ocupan lo mismo, así las columnas de
  /// importes quedan alineadas aunque cambie el valor.
  static const List<FontFeature> cifras = [FontFeature.tabularFigures()];

  /// Importe dentro de una celda de tabla. El tamanio de cuerpo del modulo.
  static TextStyle? numeroCelda(BuildContext context, {bool fuerte = false}) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamily: fuenteMonto,
        fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400,
        // La mono ya es de ancho fijo; el feature queda por si algun dia se
        // cambia de familia.
        fontFeatures: cifras,
        fontSize: 13,
        letterSpacing: 0,
      );

  /// Importe que cierra un bloque: total de tabla, total de tarjeta.
  ///
  /// Se queda en titleSmall a proposito. Bajarlo al tamanio de celda seria
  /// unificar por lo bajo justo donde hace falta que el ojo se detenga.
  static TextStyle? numeroTotal(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
        fontFamily: fuenteMonto,
        fontWeight: FontWeight.w700,
        fontFeatures: cifras,
        // 14 clavado, no heredado: los titulos de seccion suben a 15 y los
        // importes no tienen por que seguirlos. Uno rotula, el otro es el dato.
        fontSize: 14,
        letterSpacing: 0,
      );

  /// Importe secundario: desgloses, subtotales de apoyo, cifras de contexto.
  static TextStyle? numeroApoyo(BuildContext context, {bool fuerte = false}) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFamily: fuenteMonto,
        fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400,
        fontFeatures: cifras,
        fontSize: 12,
        letterSpacing: 0,
      );

  static TextStyle? numeroGrande(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: fuenteMonto,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        fontFeatures: cifras,
      );

  // ── Superficies ──────────────────────────────────────────────────────────
  /// Contenedor de datos: borde fino, sin sombra.
  ///
  /// Las sombras separan planos; acá no hay planos, hay una tabla sobre un
  /// fondo. Un borde de 1px hace el trabajo sin ensuciar.
  static BoxDecoration contenedor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      border: Border.all(color: cs.outlineVariant),
      borderRadius: brContenedor,
    );
  }

  /// Franja de apoyo: filtros, barras de acción, resúmenes.
  static BoxDecoration franja(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surfaceContainer,
      borderRadius: brContenedor,
    );
  }

  /// Fondo del encabezado de una tabla.
  ///
  /// Token pleno y no un alpha: mezclar surfaceContainerHighest al 50% contra
  /// la tarjeta daba 1,06:1, que a ojo es el mismo color. El token entero da
  /// 1,28:1 y ademas se mueve solo cuando cambia el modo.
  static WidgetStateProperty<Color?> encabezadoTabla(BuildContext context) =>
      WidgetStatePropertyAll(
        Theme.of(context).colorScheme.surfaceContainerHighest,
      );

  // ── Layout ───────────────────────────────────────────────────────────────
  /// Ancho máximo del contenido.
  ///
  /// Sin tope, en un monitor ancho las filas se estiran y el ojo pierde el
  /// renglón entre el nombre y el importe. Las tablas anchas lo ignoran y usan
  /// su propio scroll horizontal.
  static const double anchoMaximo = 1600;

  /// Tope de las paginas de tabla: la tarjeta y la barra que la encabeza.
  ///
  /// Mas angosto que [anchoMaximo] porque una fila de cuatro columnas estirada
  /// a 1600 px deja al nombre y al importe tan lejos que el ojo pierde el
  /// renglon. Los dos -barra y tarjeta- tienen que usar el MISMO valor: con la
  /// barra suelta, el boton de accion queda cientos de pixeles a la derecha del
  /// borde de la tabla que encabeza.
  static const double anchoTabla = 1100;

  static EdgeInsets margenPagina(BuildContext context) => EdgeInsets.symmetric(
    horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
  );

  static bool esMovil(BuildContext context) =>
      ResponsiveUtilsBosque.isMobile(context);

  // ── Tema del modulo ──────────────────────────────────────────────────────
  /// Theme propio para las pestanas de Comisiones.
  ///
  /// Se deriva del tema de la app en vez de definir uno nuevo: el color de
  /// acento lo elige el usuario en ajustes y el modo oscuro tiene su toggle, y
  /// ambos tienen que seguir mandando. Lo que este tema fija es lo que la app
  /// nunca decidio: tipografia, jerarquia y densidad.
  static ThemeData temaModulo(BuildContext context) {
    final base = Theme.of(context);
    final csApp = base.colorScheme;
    final oscuro = base.brightness == Brightness.dark;

    // Las superficies se neutralizan; el acento NO se toca.
    //
    // El tema de la app sale de colorSchemeSeed, asi que Material tinie TODA la
    // escala de grises con el color elegido: con verde, la pagina, la tarjeta y
    // el encabezado de tabla salen verdes. Sumado a un acento tambien verde, no
    // queda nada que resalte.
    //
    // Y los tres niveles ademas quedaban pegados: la pagina contra la tarjeta
    // median 1,05:1 y la tarjeta contra el encabezado 1,06:1, o sea que el ojo
    // no separaba las capas. Parte de eso venia de pedirle tres alfas distintas
    // -0,35, 0,40 y 0,50- al MISMO token contra el MISMO fondo, que da tres
    // colores casi identicos.
    //
    // Con grises reales: 1,17:1 y 1,28:1 en claro, 1,12:1 y 1,32:1 en oscuro,
    // y en los dos modos la tarjeta va hacia el mismo lado. El acento sigue
    // siendo el que el usuario elige en ajustes, y ahora sí se despega.
    final cs = csApp.copyWith(
      surface: oscuro ? const Color(0xFF121212) : const Color(0xFFEDEDED),
      surfaceContainerLowest:
          oscuro ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF),
      // El default de Card en Material 3. Redefinirlo alcanza para las once
      // tarjetas del modulo, incluidas las tres de la vista movil.
      surfaceContainerLow:
          oscuro ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
      surfaceContainer:
          oscuro ? const Color(0xFF232323) : const Color(0xFFF7F7F7),
      surfaceContainerHigh:
          oscuro ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
      surfaceContainerHighest:
          oscuro ? const Color(0xFF333333) : const Color(0xFFE3E3E3),
      onSurface: oscuro ? const Color(0xFFE3E3E3) : const Color(0xFF1B1B1B),
      onSurfaceVariant:
          oscuro ? const Color(0xFFC4C4C4) : const Color(0xFF474747),
      outline: oscuro ? const Color(0xFF8F8F8F) : const Color(0xFF757575),
      outlineVariant:
          oscuro ? const Color(0xFF474747) : const Color(0xFFC4C4C4),
    );

    // Toda la escala pasa a la fuente de interfaz de una vez; abajo se
    // reajustan solo los estilos que cargan jerarquia.
    final t = base.textTheme.apply(
      fontFamily: fuenteUI,
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return base.copyWith(
      colorScheme: cs,
      textTheme: t.copyWith(
        // Titulos: tracking negativo y peso alto. Un titular con el tracking
        // por defecto se lee como texto corrido, no como titulo.
        headlineSmall: t.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyMedium: t.bodyMedium?.copyWith(fontSize: 13, height: 1.45),
        bodySmall: t.bodySmall?.copyWith(fontSize: 12, height: 1.4),
        // Rotulos chicos con tracking ABIERTO: al reves que los titulos. A 11px
        // las letras se empastan y el tracking es lo que las separa.
        labelSmall: t.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
        labelMedium: t.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      // Los separadores tenian el mismo peso visual que los datos y la pantalla
      // se leia como una reja. Bajan a un tono de apoyo.
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: oscuro ? 0.35 : 0.6),
        thickness: 1,
        space: 1,
      ),

      dataTableTheme: DataTableThemeData(
        headingRowHeight: altoEncabezado,
        dataRowMinHeight: altoFila,
        // Alto fijo en escritorio, donde sobra ancho y la fila nunca parte.
        // En un telefono un nombre largo se parte en dos lineas y con el alto
        // clavado queda recortado, asi que ahi la fila crece.
        dataRowMaxHeight: esMovil(context) ? double.infinity : altoFila,
        columnSpacing: separacionColumnas,
        horizontalMargin: esp4,
        dividerThickness: 1,
        headingTextStyle: t.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: cs.onSurfaceVariant,
        ),
        dataTextStyle: t.bodyMedium?.copyWith(fontSize: 13),
        // Realce de la fila bajo el cursor. Sin esto, en una tabla ancha de
        // importes se pierde el renglon entre el nombre y el monto: el ojo
        // salta de linea a mitad de camino.
        dataRowColor: WidgetStateProperty.resolveWith((estados) {
          // Selected primero: una fila marcada sigue marcada aunque el cursor
          // este encima. Al reves, pasar por arriba la desmarcaba a la vista.
          if (estados.contains(WidgetState.selected)) {
            return cs.primary.withValues(alpha: oscuro ? 0.20 : 0.12);
          }
          // Canal distinto a proposito: la marca lleva matiz (es del usuario),
          // el hover es neutro (es solo "estoy leyendo este renglon").
          if (estados.contains(WidgetState.hovered)) {
            return cs.onSurface.withValues(alpha: oscuro ? 0.08 : 0.06);
          }
          return null;
        }),
      ),

      // Filtros y formularios: relleno suave en vez de caja con borde. El borde
      // solo aparece al enfocar, que es cuando dice algo.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: esp3,
          vertical: esp3,
        ),
        border: OutlineInputBorder(
          borderRadius: brControl,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: brControl,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: brControl,
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: brControl,
          borderSide: BorderSide(color: cs.error, width: 1.2),
        ),
        labelStyle: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        hintStyle: t.bodySmall?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: brControl),
          padding: const EdgeInsets.symmetric(horizontal: esp4, vertical: esp3),
          textStyle: t.labelLarge?.copyWith(
            fontFamily: fuenteUI,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: brControl),
          padding: const EdgeInsets.symmetric(horizontal: esp4, vertical: esp3),
          side: BorderSide(color: cs.outlineVariant),
          textStyle: t.labelLarge?.copyWith(
            fontFamily: fuenteUI,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: brControl),
          textStyle: t.labelLarge?.copyWith(
            fontFamily: fuenteUI,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: brChip,
        ),
        textStyle: t.bodySmall?.copyWith(color: cs.onInverseSurface),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

/// Chip de estado. Un solo componente para todos los rótulos del módulo.
///
/// Antes cada pestaña armaba su propio Container con padding y radio a mano, y
/// no coincidían entre sí.
class ChipEstado extends StatelessWidget {
  const ChipEstado({
    super.key,
    required this.texto,
    this.tono = TonoChip.neutro,
    this.icono,
  });

  final String texto;
  final TonoChip tono;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Los tres tonos se separan por PESO -sin relleno, relleno lleno, relleno
    // suave-, no por matiz.
    //
    // Antes los tres eran un contenedor pastel y acento contra alerta median
    // 1.001:1 entre si: cs.primary y cs.error son ambos tono 40 en claro y 80
    // en oscuro, asi que rellenar los dos los deja sobre la misma linea de
    // luminancia en las nueve semillas. Rellenar solo el acento es lo que abre
    // la diferencia a ~5:1.
    final (fondo, tinta, borde) = switch (tono) {
      TonoChip.neutro => (Colors.transparent, cs.onSurfaceVariant, cs.outline),
      TonoChip.acento => (cs.primary, cs.onPrimary, cs.primary),
      TonoChip.alerta => (cs.errorContainer, cs.onErrorContainer, cs.error),
    };

    // La alerta lleva icono aunque no se lo pidan: es el unico tono que quiere
    // que el ojo se detenga, y el color solo no alcanza para quien no lo
    // distingue.
    final ic = icono ?? (tono == TonoChip.alerta ? Icons.error_outline : null);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ComisionesTema.esp3,
        vertical: ComisionesTema.esp1 + 1,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: ComisionesTema.brChip,
        border: Border.all(color: borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ic != null) ...[
            Icon(ic, size: 13, color: tinta),
            const SizedBox(width: ComisionesTema.esp1 + 2),
          ],
          Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tinta,
              fontWeight: FontWeight.w600,
              fontFeatures: ComisionesTema.cifras,
            ),
          ),
        ],
      ),
    );
  }
}

enum TonoChip { neutro, acento, alerta }

/// Aviso de error dentro de un formulario.
///
/// Estaba copiado identico en los cinco dialogos del modulo. Cinco copias de la
/// misma caja roja significan que un cambio de estilo hay que hacerlo cinco
/// veces, y en la practica se hace en una sola.
///
/// El mensaje que llega aca es el del SP, ya redactado para el usuario: no se
/// lo reescribe ni se lo reemplaza por uno generico, porque el del SP es el
/// unico que dice que fue lo que fallo.
class AvisoError extends StatelessWidget {
  const AvisoError({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(ComisionesTema.esp3),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: ComisionesTema.brControl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
          const SizedBox(width: ComisionesTema.esp2),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
