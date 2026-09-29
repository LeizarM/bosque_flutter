// ignore_for_file: file_names

import 'package:flutter/material.dart';

const colorList = <Color>[
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.red,
  Colors.purple,
  Colors.yellow,
  Colors.orange,
  Colors.deepPurple,
  Colors.pink,
];

/// Radios de esquina de la app, en dos familias nada más.
///
/// Antes no había ninguno declarado: Card salía a 12 (default M3), Dialog y
/// BottomSheet a 28 (default M3, mucho más redondeados que la Card) y los
/// TextField a un simple subrayado sin esquina (default M3 sin
/// InputDecorationTheme) — tres lenguajes de forma distintos conviviendo por
/// accidente de versión de Flutter, no por diseño. De hecho ~150 pantallas ya
/// venían poniendo su propio OutlineInputBorder campo por campo (8, 10, 12,
/// 16, hasta 20 según el archivo) para escapar de ese subrayado; 8 es el
/// valor que más se repite ahí, así que de ahí sale.
///
/// - _kRadiusControl (8): controles chicos que se llenan — inputs.
/// - _kRadiusSurface (16): superficies flotantes — card, dialog, bottom
///   sheet. Mismo radio en las tres para que se sientan de la misma familia.
/// - Botones: ya salen en pastilla completa (StadiumBorder) por default en
///   M3 para los 4 tipos (elevated/filled/outlined/text) — es lo único de
///   esta lista que YA era consistente, así que no se tocan.
const double _kRadiusControl = 8;
const double _kRadiusSurface = 16;

class AppTheme {
  final int selectedColor;
  final bool isDarkMode;

  AppTheme({this.isDarkMode = false, this.selectedColor = 2})
    : assert(
        selectedColor >= 0,
        'selectedColor must be greater than or equal to 0',
      ),
      assert(
        selectedColor < colorList.length,
        'selectedColor must be less or equal to ${colorList.length - 1}',
      );

  ThemeData getTheme() {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    // Misma llamada que hace ThemeData por dentro cuando se le pasa
    // colorSchemeSeed (ver theme_data.dart de Flutter): se calcula aquí,
    // aparte, para poder reusar colorScheme.primary más abajo (selección de
    // texto, bordes de input) en vez de adivinar o inventar un color nuevo.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colorList[selectedColor],
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(centerTitle: false),
      // Add proper mouse cursor hover effects for desktop
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Color de selección de texto.
      //
      // Sin esto, seleccionar texto en un TextField usaba el celeste
      // default de Material, que no tiene nada que ver con el acento que
      // el usuario eligió en "Color del tema". Usa el mismo colorScheme
      // recién calculado arriba, no un color nuevo.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.32),
        selectionHandleColor: colorScheme.primary,
      ),
      // Transiciones de página: nada de deslizar/hacer zoom "como en un
      // celular" en una herramienta de oficina que se usa con mouse.
      //
      // PageTransitionsTheme, si no se lo pisa, resuelve la transición por
      // Theme.of(context).platform (que en la práctica es
      // defaultTargetPlatform): en Windows y Linux usa
      // ZoomPageTransitionsBuilder (el efecto de "acercamiento" de Android)
      // y en macOS usa CupertinoPageTransitionsBuilder (deslizar como en
      // iPhone) — inclusive corriendo como app web en un navegador de
      // escritorio, porque ahí defaultTargetPlatform refleja el sistema
      // operativo real, no si es "web" o no.
      //
      // Se pisan sólo las 4 plataformas de escritorio (windows/macOS/
      // linux/fuchsia) con una transición nula. android/iOS se dejan
      // explícitos con su transición táctil de siempre — tanto para la app
      // nativa real (carpetas android/ e ios/) como para el caso raro de
      // abrir la versión web desde el navegador de un celular. Van
      // explícitos y no por default: si sólo se pisan las 4 de escritorio,
      // cualquier plataforma sin entrada en el mapa cae a
      // ZoomPageTransitionsBuilder — inclusive iOS, que perdería su
      // transición nativa.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: _InstantPageTransitionsBuilder(),
          TargetPlatform.macOS: _InstantPageTransitionsBuilder(),
          TargetPlatform.linux: _InstantPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _InstantPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // Escala de esquinas — ver el comentario de _kRadiusControl/
      // _kRadiusSurface arriba del todo del archivo.
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusSurface),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kRadiusSurface),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_kRadiusSurface),
          ),
        ),
      ),
      // Esto es sólo el DEFAULT para el TextField que no pone su propio
      // border (la mayoría hoy ya trae el suyo, campo por campo). No pisa
      // a esos ~150 archivos: un border explícito en un TextField siempre
      // gana sobre el del theme.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusControl),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusControl),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusControl),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusControl),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusControl),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadiusControl),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ),
      // Encabezados de tabla.
      //
      // Antes: `color: colorList[selectedColor]`, o sea el color CRUDO y
      // saturado de la paleta Material (el magenta que se veia en Entregas).
      // Un encabezado pintado con el acento a full compite con los datos y
      // ademas ignora el ColorScheme: en modo oscuro quedaba ilegible.
      //
      // Ahora es un rotulo gris, chico y con tracking abierto. El acento queda
      // libre para lo accionable. Aplica a todas las tablas de la app.
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          // Antes usaba (isDarkMode ? ThemeData.dark() : ThemeData.light())
          // .colorScheme.onSurfaceVariant: el onSurfaceVariant del esquema
          // AZUL default de Flutter, no el del acento que el usuario eligió.
          // Con seeds distintos casi no se nota (onSurfaceVariant es un gris
          // neutro en las dos paletas) pero es el mismo colorScheme calculado
          // arriba, así que usarlo directo es lo correcto y evita fabricar
          // dos ThemeData completos sólo para leer un color.
          color: colorScheme.onSurfaceVariant,
        ),
        dividerThickness: 1,
      ),
    );
  }

  // Get a MaterialApp theme configuration that properly handles desktop mouse events
  MaterialApp getMaterialAppTheme({
    required Widget home,
    String? title,
    List<NavigatorObserver>? navigatorObservers,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      title: title ?? 'Bosque App',
      debugShowCheckedModeBanner: false,
      theme: getTheme(),
      home: _wrapWithMouseRegion(home),
      routes: routes ?? {},
      navigatorObservers: navigatorObservers ?? [],
    );
  }

  // Private helper method to wrap app with global mouse region
  Widget _wrapWithMouseRegion(Widget child) {
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      child: child,
    );
  }

  AppTheme copyWith({bool? isDarkMode, int? selectedColor}) => AppTheme(
    isDarkMode: isDarkMode ?? this.isDarkMode,
    selectedColor: selectedColor ?? this.selectedColor,
  );
}

/// Transición de página "nula": la pantalla nueva reemplaza a la anterior
/// sin animar. Ver el comentario largo junto a `pageTransitionsTheme` en
/// [AppTheme.getTheme] para el motivo.
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
