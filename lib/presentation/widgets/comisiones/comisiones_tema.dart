import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

/// Tokens visuales del módulo de Comisiones: un lugar único para que las nueve
/// pestañas no elijan cada una su radio, espaciado y gris. Reglas:
///   FORMA    un solo radio por tipo: contenedores 12, controles 10, chips 6.
///   COLOR    todo sale del ColorScheme, ni un hex suelto (modo oscuro sin 2ª paleta).
///   NÚMEROS  cifras tabulares SIEMPRE, o las columnas de importes no alinean.
/// Densidad alta a propósito (herramienta de trabajo): el aire se gana quitando cajas.
class ComisionesTema {
  const ComisionesTema._();

  /// Interfaz. Roboto (default de Android) se lee como pantalla sin diseñar; esta
  /// tiene la misma legibilidad a 11px y carácter propio.
  static const String fuenteUI = 'PlusJakartaSans';

  /// Importes, y solo importes. Ancho fijo real (no cifras tabulares simuladas) y
  /// cero con barra, para no confundirlo con la O al cantar un número de nota.
  static const String fuenteMonto = 'JetBrainsMono';

  // Espaciado: escala de 4. Suficientes escalones para jerarquía, pocos para no
  // inventar un valor nuevo en cada pantalla.
  static const double esp1 = 4;
  static const double esp2 = 8;
  static const double esp3 = 12;
  static const double esp4 = 16;
  static const double esp5 = 24;
  static const double esp6 = 32;

  static const double radioContenedor = 12;
  static const double radioControl = 10;
  static const double radioChip = 6;

  static BorderRadius get brContenedor =>
      BorderRadius.circular(radioContenedor);
  static BorderRadius get brControl => BorderRadius.circular(radioControl);
  static BorderRadius get brChip => BorderRadius.circular(radioChip);

  /// Alto de fila. En móvil no se usan tablas, así que solo hay un valor.
  static const double altoFila = 44;
  static const double altoEncabezado = 40;
  static const double separacionColumnas = 20;

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

  /// Importe que cierra un bloque (total de tabla o de tarjeta). Se queda en
  /// titleSmall a propósito: bajarlo al tamaño de celda unifica por lo bajo justo
  /// donde el ojo debe detenerse.
  static TextStyle? numeroTotal(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
        fontFamily: fuenteMonto,
        fontWeight: FontWeight.w700,
        fontFeatures: cifras,
        // 14 clavado, no heredado: los títulos de sección suben a 15 y el importe es el
        // dato, no el rótulo.
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

  /// Contenedor de datos: borde fino, sin sombra (no hay planos que separar, hay
  /// una tabla sobre un fondo).
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

  /// Fondo del encabezado de una tabla. Token pleno y no un alpha: al 50% contra
  /// la tarjeta daba 1,06:1; el token entero da 1,28:1 y sigue solo el cambio de modo.
  static WidgetStateProperty<Color?> encabezadoTabla(BuildContext context) =>
      WidgetStatePropertyAll(
        Theme.of(context).colorScheme.surfaceContainerHighest,
      );

  /// Ancho máximo del contenido: sin tope, en un monitor ancho el ojo pierde el
  /// renglón entre nombre e importe. Las tablas anchas usan su propio scroll
  /// horizontal.
  static const double anchoMaximo = 1600;

  /// Tope de las páginas de tabla (tarjeta y barra que la encabeza). Más angosto
  /// que [anchoMaximo]: a 1600px el nombre y el importe quedan demasiado lejos.
  /// Barra y tarjeta deben usar el MISMO valor, o el botón de acción queda cientos
  /// de píxeles a la derecha del borde de la tabla.
  static const double anchoTabla = 1100;

  static EdgeInsets margenPagina(BuildContext context) => EdgeInsets.symmetric(
    horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
  );

  static bool esMovil(BuildContext context) =>
      ResponsiveUtilsBosque.isMobile(context);

  /// Theme propio para las pestañas de Comisiones, derivado del de la app: el
  /// acento y el modo oscuro los sigue eligiendo el usuario. Fija lo que la app
  /// nunca decidió: tipografía, jerarquía y densidad.
  static ThemeData temaModulo(BuildContext context) {
    final base = Theme.of(context);
    final csApp = base.colorScheme;
    final oscuro = base.brightness == Brightness.dark;

    // Superficies neutralizadas; el acento NO se toca. El tema de la app sale de
    // colorSchemeSeed y Material tiñe toda la escala de grises con el acento, y los
    // niveles quedaban pegados (página/tarjeta 1,05:1, tarjeta/encabezado 1,06:1).
    // Con grises reales: 1,17:1 y 1,28:1 en claro, 1,12:1 y 1,32:1 en oscuro.
    final cs = csApp.copyWith(
      surface: oscuro ? const Color(0xFF121212) : const Color(0xFFEDEDED),
      surfaceContainerLowest:
          oscuro ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF),
      // Default de Card en Material 3: redefinirlo cubre las once tarjetas del módulo,
      // incluidas las tres de la vista móvil.
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

    // Toda la escala pasa a la fuente de interfaz; abajo se reajustan solo los
    // estilos que cargan jerarquía.
    final t = base.textTheme.apply(
      fontFamily: fuenteUI,
      bodyColor: cs.onSurface,
      displayColor: cs.onSurface,
    );

    return base.copyWith(
      colorScheme: cs,
      textTheme: t.copyWith(
        // Títulos: tracking negativo y peso alto; con el tracking por defecto se leen
        // como texto corrido.
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
        // Rótulos chicos con tracking ABIERTO (al revés que los títulos): a 11px las
        // letras se empastan.
        labelSmall: t.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
        labelMedium: t.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      // Los separadores pesaban lo mismo que los datos y la pantalla se leía como una
      // reja: bajan a un tono de apoyo.
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: oscuro ? 0.35 : 0.6),
        thickness: 1,
        space: 1,
      ),

      dataTableTheme: DataTableThemeData(
        headingRowHeight: altoEncabezado,
        dataRowMinHeight: altoFila,
        // Alto fijo en escritorio, donde sobra ancho. En teléfono un nombre largo parte
        // en dos líneas y con alto clavado se recortaría, así que ahí la fila crece.
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
        // Realce de la fila bajo el cursor: en una tabla ancha de importes evita que el
        // ojo salte de línea entre el nombre y el monto.
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
    // Los tres tonos se separan por PESO (sin relleno, relleno lleno, relleno
    // suave), no por matiz: cs.primary y cs.error son ambos tono 40 en claro y 80 en
    // oscuro, así que rellenar los dos da 1.001:1 entre sí; rellenar solo el acento
    // abre la diferencia a ~5:1.
    final (fondo, tinta, borde) = switch (tono) {
      TonoChip.neutro => (Colors.transparent, cs.onSurfaceVariant, cs.outline),
      TonoChip.acento => (cs.primary, cs.onPrimary, cs.primary),
      TonoChip.alerta => (cs.errorContainer, cs.onErrorContainer, cs.error),
    };

    // La alerta lleva icono aunque no se pida: es el único tono que quiere frenar el
    // ojo, y el color solo no alcanza para quien no lo distingue.
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

/// Aviso de error dentro de un formulario, compartido por los diálogos del
/// módulo. El mensaje es el del SP, ya redactado para el usuario: no se
/// reescribe ni se reemplaza por uno genérico, porque es el único que dice qué
/// falló.
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
