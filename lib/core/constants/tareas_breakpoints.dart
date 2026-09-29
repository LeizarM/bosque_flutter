/// Breakpoints de ancho para las pantallas de Tareas Rutinarias
/// (`presentation/screens/tareas-rutinarias/` y las pantallas de
/// `estructura-organizacional` que le pertenecen al modulo).
///
/// Cada pantalla decide su propio umbral segun su layout: no todas
/// necesitan el mismo. Esta clase solo le pone nombre a los numeros que ya
/// estaban en uso, para que la eleccion de cada pantalla se lea como
/// intencional y no como un numero magico repetido a mano.
class TareasBreakpoints {
  const TareasBreakpoints._();

  /// Umbral bajo: por debajo va todo en una columna apilada; a partir de
  /// aca el formulario se centra con [contentMaxWidth640].
  ///
  /// En uso: caja_chica_screen.dart, caja_fuerte_screen.dart,
  /// coches_screen.dart.
  static const double compactMax = 700;

  /// Umbral medio: por debajo va apilado; a partir de aca el contenido se
  /// centra (con [contentMaxWidth700] en arqueo/cierre) o se distribuye en
  /// columnas.
  ///
  /// En uso: mis_tareas_rutinarias_screen.dart, dependientes_jefe_screen.dart,
  /// arqueo_caja_screen.dart, cierre_operaciones_screen.dart,
  /// tareas_rutinarias_por_cargo_screen.dart,
  /// tareas_rutinarias_catalogo_screen.dart.
  static const double mediumMax = 900;

  /// Umbral alto: por debajo los paneles van apilados; a partir de aca van
  /// lado a lado.
  ///
  /// En uso: el panel de tareas del dia de cierre_operaciones_screen.dart.
  static const double wideMax = 1000;

  /// Ancho maximo de contenido centrado para formularios angostos.
  ///
  /// En uso: caja_chica_screen.dart, caja_fuerte_screen.dart,
  /// coches_screen.dart (junto con [compactMax]).
  static const double contentMaxWidth640 = 640;

  /// Ancho maximo de contenido centrado para las pantallas de
  /// arqueo/cierre.
  ///
  /// En uso: arqueo_caja_screen.dart, cierre_operaciones_screen.dart (junto
  /// con [mediumMax]).
  static const double contentMaxWidth700 = 700;

  // ── Ancho real de escritorio ────────────────────────────────────────────
  //
  // Los umbrales de arriba solo distinguen "angosto" de "centrado y angosto":
  // arriba de 900px el contenido se clavaba en 700 y el resto de la pantalla
  // quedaba vacio. En un monitor de 1920 con el sidebar abierto son ~1676px
  // utiles y ~980 desperdiciados (Marcelo, 2026-09-07: "no me quites espacio
  // de la pantalla"). Estos dos reconocen el caso que faltaba.

  /// A partir de aca hay ancho para poner cosas LADO A LADO en vez de
  /// apiladas: el arqueo abre sus dos lados (sistema / conteo) y las listas
  /// pasan a grilla.
  ///
  /// 1100 y no 900: abajo de eso dos columnas dejan cada lado en ~520px, mas
  /// angosto que la columna unica que reemplazan — se veria peor, no mejor.
  static const double splitMin = 1100;

  /// Tope del layout de dos columnas. Sin tope, en un ultrawide las dos
  /// columnas se estiran hasta que la fila "etiqueta ......... monto" queda
  /// con medio metro de vacio en el medio y deja de leerse como una fila.
  static const double contentMaxWidthSplit = 1560;

  /// Columnas para listas de tarjetas (Mis tareas rutinarias). La tarjeta
  /// necesita ~460px para que el titulo de una tarea entre sin cortarse en
  /// la primera palabra, asi que se agrega una columna recien cuando entran
  /// enteras, no repartiendo el ancho a la fuerza.
  static int columnasLista(double ancho) {
    if (ancho >= 1440) return 3;
    if (ancho >= splitMin) return 2;
    return 1;
  }
}
