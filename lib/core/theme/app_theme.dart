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

class AppTheme {
  final int selectedColor;
  final bool isDarkMode;

  AppTheme({this.isDarkMode = false , this.selectedColor = 2})
    : assert(
        selectedColor >= 0,
        'selectedColor must be greater than or equal to 0',
      ),
      assert(
        selectedColor < colorList.length,
        'selectedColor must be less or equal to ${colorList.length - 1}',
      );

  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorSchemeSeed: colorList[selectedColor],
      appBarTheme: const AppBarTheme(centerTitle: false),
      // Add proper mouse cursor hover effects for desktop
      visualDensity: VisualDensity.adaptivePlatformDensity,
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
          color: (isDarkMode ? ThemeData.dark() : ThemeData.light())
              .colorScheme
              .onSurfaceVariant,
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

  AppTheme copyWith(
    {
      bool? isDarkMode,
      int? selectedColor,
    }
  ) => AppTheme(
      isDarkMode: isDarkMode?? this.isDarkMode,
      selectedColor: selectedColor?? this.selectedColor,
  );
}