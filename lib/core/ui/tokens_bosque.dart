/// Los tokens visuales compartidos de Bosque: espaciado, pesos, cifras
/// tabulares, aire disponible y el color de un estado.
///
/// **La restricción que define todo esto:** los módulos viven adentro del tema
/// de Bosque, que es Material 3 con una semilla de color que el usuario elige
/// entre nueve, más modo claro y oscuro. Una paleta propia se vería rota en
/// cuanto alguien pase el tema a violeta.
///
/// Así que la identidad no puede venir del color. Viene de lo que el módulo es:
/// **la planilla que reemplaza**. Su personalidad es la precisión tabular —
/// números alineados, ritmo de fila constante— y el color se reserva para
/// codificar estado, nunca para decorar.
///
/// **Por qué está en `core/ui/` y ya no en el módulo de sábados.** Estos tokens
/// se venían copiando de módulo en módulo; con `permisos-rrhh` iba a ser la
/// cuarta copia y la cuarta divergencia. Se movieron acá tal cual estaban —sin
/// cambiar una constante— y `rol-sabados/estilo_modulo.dart` quedó como
/// re-export para que sus 15 importadores no se enteren.
library;

import 'package:flutter/material.dart';

/// Escala de espaciado de 4.
///
/// Antes había 3, 5, 6, 10 y 14 sueltos por ahí. Con números arbitrarios cada
/// bloque respira distinto y la pantalla se lee inquieta sin que se sepa por qué.
abstract final class Esp {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Los tres pesos, cada uno con un significado.
///
/// Si todo lo importante está en negrita, nada lo está.
abstract final class Peso {
  /// Un dato que se compara: un total, una cobertura, una letra de celda.
  static const FontWeight dato = FontWeight.w700;

  /// El título de una sección o de una columna.
  static const FontWeight titulo = FontWeight.w600;

  /// Todo lo demás.
  static const FontWeight normal = FontWeight.w400;
}

/// Un unico radio de esquina para toda la app.
///
/// Tres escalones y una regla: la superficie que contiene usa [media], lo que
/// vive adentro usa [chica], y lo que es una pastilla usa [pastilla].
///
/// Nacio en `cartas-cite` y se movio aqui cuando el modulo de produccion iba a
/// ser la segunda copia. `identidad_cite.dart` lo re-exporta.
abstract final class Esquina {
  static const double chica = 8;
  static const double media = 12;
  static const double pastilla = 999;
}

/// Cifras de ancho fijo.
///
/// Sin esto, `43` y `11` ocupan distinto y una columna de números queda con los
/// dígitos bailando. En una planilla de 52 columnas se nota en cada scroll.
const List<FontFeature> cifrasTabulares = [FontFeature.tabularFigures()];

/// Estilos del módulo, derivados del tema y no inventados.
extension EstiloModulo on BuildContext {
  TextTheme get _t => Theme.of(this).textTheme;
  ColorScheme get cs => Theme.of(this).colorScheme;

  /// Un número que se compara con otros de su columna.
  TextStyle? numero({bool fuerte = false, Color? color}) =>
      _t.labelMedium?.copyWith(
        fontWeight: fuerte ? Peso.dato : Peso.normal,
        fontFeatures: cifrasTabulares,
        color: color,
        height: 1.1,
      );

  /// El título de una sección.
  TextStyle? tituloSeccion() =>
      _t.titleSmall?.copyWith(fontWeight: Peso.titulo);

  /// Texto de apoyo: explica, no compite.
  TextStyle? apagado() =>
      _t.bodySmall?.copyWith(color: Theme.of(this).hintColor);
}

// ═══════════════════════════════════════════════════════════════════════════
// EL COLOR DE UNA CELDA
// ═══════════════════════════════════════════════════════════════════════════

/// El par fondo/texto de una celda, garantizado legible.
class ColorDeEstado {
  final Color fondo;
  final Color texto;
  const ColorDeEstado(this.fondo, this.texto);
}

/// Traduce la letra de una celda a un par de colores del tema.
///
/// **Por qué no se usa `trs_EstadoTurno.color`.** Esos hex vienen del Excel
/// original: `#C6EFCE` es el verde «bueno» de Excel, `#FFEB9C` el amarillo
/// «neutro», `#FFC7CE` el rojo «malo». Están pensados para papel blanco. En modo
/// oscuro quedaban aplicados con opacidad sobre una superficie oscura y con el
/// texto claro del tema encima: pastel pálido con letra clara, ilegible.
///
/// **Por qué familia + tono y no un rol por estado.** Los roles de Material no
/// son independientes entre sí: con la semilla azul `secondaryContainer` queda
/// casi idéntico a `primaryContainer`, y con la roja `errorContainer` queda
/// igual que el principal. Probando las nueve semillas, los únicos que se
/// separan siempre son **primary**, **tertiary** y los **neutros**.
///
/// Así que cada estado se ubica por **familia** —qué tipo de cosa es— y por
/// **tono**, o sea cuánto se acerca al fondo. El tono separa aun dentro de una
/// misma familia, y de paso ayuda a quien no distingue bien los colores: dos
/// estados de la misma familia se diferencian por claridad, no sólo por matiz.
///
/// El tono además ayuda a quien no distingue bien los colores: dos estados de la
/// misma familia se diferencian por claridad, no sólo por matiz.
///
/// El hex de la base no se borra: sigue ahí para quien exporte a Excel y espere
/// los colores de siempre.
ColorDeEstado colorDeEstado(ColorScheme cs, String codigoExcel) {
  // (familia, tono) — tono 0 = el color pleno; 1 = se funde con el fondo.
  final (Color familia, double tono) = switch (codigoExcel) {
    // VIENE. Es el 95% de la grilla, así que lleva la familia principal en su
    // tono más presente: contarlo de un vistazo es media función de la planilla.
    '1' => (cs.primaryContainer, 0.0),

    // NO VIENE, lo decidió RR.HH. Familia terciaria, separados por tono según
    // cuánto se aleja de una vacación común.
    'V' => (cs.tertiaryContainer, 0.0),
    'P' => (cs.tertiaryContainer, 0.40),
    'A' => (cs.tertiaryContainer, 0.70),

    // NO VIENE, y no por RR.HH. Los cuatro van en una rampa de grises: cuanto
    // mas ausente esta la persona, mas oscuro.
    //
    // El feriado NO usa el rol de error, aunque parezca el candidato obvio. Un
    // feriado no es un problema: es un dia que no existe. Y ademas con la
    // semilla roja el rol de error es la misma familia que el principal, asi
    // que 'Trabaja' y 'Feriado' se veian iguales.
    'C' => (cs.onSurface, 0.90), // alguien lo cubrio
    'E' => (cs.onSurface, 0.82), // lo liberaron del evento
    'B' => (cs.onSurface, 0.70), // fuera del rol
    'X' => (cs.onSurface, 0.30), // el dia no existe para su sucursal
    // 'L' y cualquier letra que agreguen al catálogo mañana.
    _ => (cs.surfaceContainerHigh, 0.0),
  };

  // Se aplana contra la superficie: el resultado es el color que el ojo ve, y
  // sobre ese se decide la letra.
  final fondo = Color.alphaBlend(
    familia.withValues(alpha: 1 - tono),
    cs.surface,
  );

  return ColorDeEstado(fondo, _letraSobre(fondo));
}

/// El color de una barra del cronograma, por la **posición del tipo de permiso
/// en el catálogo**.
///
/// ## Por qué un índice y no el código
///
/// Los tipos viven en la vista `v_tipos`, grupo 13: hoy son nueve y mañana
/// pueden ser diez. La primera versión de esta función era un `switch` sobre
/// los códigos escritos a mano —y le faltaban dos, `libre` y `def`, que se
/// dibujaban con el color de «tipo desconocido» sin que nada avisara—. Un
/// catálogo que vive en la base no se copia al frontend: se lee.
///
/// Así que acá entra la **posición** que el tipo ocupa en la lista que devuelve
/// `p_list_Permiso @ACCION='T1'`, y agregar un tipo en la base le da color solo,
/// sin tocar Dart.
///
/// El precio es que qué color le toca a cada tipo ya no lo decide nadie: sale
/// del orden del catálogo. Es estable —el orden no cambia entre consultas— pero
/// arbitrario. Si algún día hace falta que la vacación sea siempre de un color
/// concreto, **el lugar es una columna en la base**, no un `switch` acá.
///
/// ## Por qué estas familias y no nueve roles del tema
///
/// Misma doctrina que [colorDeEstado] y por el mismo motivo: familia + tono, y
/// sólo las familias que se separan con las nueve semillas —principal,
/// terciaria y los neutros—. Un `switch` sobre nueve roles distintos se ve
/// perfecto con la semilla azul y se derrumba con la roja.
///
/// ## El límite, dicho de frente
///
/// **Nueve categorías no entran del todo en el canal color.** Se midieron las
/// 18 combinaciones reales (nueve semillas × claro y oscuro): no hay dos
/// colores idénticos en ninguna, pero la pareja más cercana queda a 17 unidades
/// de RGB, que a simple vista es poco. Con algunas semillas dos tipos van a
/// parecerse.
///
/// No es un defecto que se arregle eligiendo mejor los tonos: es lo que hay
/// cuando el tema lo elige el usuario entre nueve semillas y la marca más chica
/// del gráfico mide 11 px. Por eso el color **no es el único canal**: la
/// leyenda está pegada arriba, el tooltip dice el tipo, y el combo de arriba
/// filtra por tipo, que es la forma confiable de aislar uno.
///
/// El tono además separa para quien no distingue bien los colores: dos barras
/// de distinto nivel se diferencian por claridad, no sólo por matiz.
ColorDeEstado colorDeTipoPermiso(ColorScheme cs, int indiceEnCatalogo) =>
    colorDeCatalogo(cs, indiceEnCatalogo);

/// El color de una categoria por su **posicion en un catalogo**.
///
/// Es la implementacion que estaba dentro de [colorDeTipoPermiso], sin cambiar
/// una constante: toda la doctrina y las mediciones de ese comentario valen
/// igual aqui. Se le puso un nombre generico cuando el modulo de produccion
/// necesito colorear grupos de resmado — el segundo catalogo que pedia lo
/// mismo—, para que el tercero no vuelva a copiar la rampa.
ColorDeEstado colorDeCatalogo(ColorScheme cs, int indiceEnCatalogo) {
  // Fuera del catálogo: los 28 registros históricos con el tipo vacío, un
  // código que ya no está en la vista, o el catálogo todavía viajando. Va a un
  // color que NO está en la rampa, para que «no sé qué es» no se confunda con
  // un tipo de verdad.
  if (indiceEnCatalogo < 0) {
    final fondo = Color.alphaBlend(
      cs.outlineVariant.withValues(alpha: 0.55),
      cs.surface,
    );
    return ColorDeEstado(fondo, _letraSobre(fondo));
  }

  // Nueve escalones: tres familias por tres niveles de presencia. Los primeros
  // usan los roles PLENOS (`primary`, `tertiary`) y no sólo los contenedores,
  // que en Material 3 son pálidos por diseño: con puros contenedores el
  // cronograma salía todo lavado y el rango de claridad era 4,7; con los plenos
  // es 5,5 y la distancia mínima entre dos colores pasa de 8 a 17 unidades RGB.
  // Medido sobre las 18 combinaciones reales (nueve semillas × claro/oscuro).
  final pasos = <(Color, double)>[
    (cs.primary, 0.0),
    (cs.tertiary, 0.0),
    (cs.onSurface, 0.30),
    (cs.primaryContainer, 0.0),
    (cs.tertiaryContainer, 0.0),
    (cs.onSurface, 0.55),
    (cs.primaryContainer, 0.45),
    (cs.tertiaryContainer, 0.45),
    // **NO `surfaceContainerHighest`.** Con tono 0 el escalón queda siendo ese
    // rol tal cual, que es EXACTAMENTE el token con el que el cronograma tiñe
    // sábados y domingos: medido, el mismo color en las 18 combinaciones. Una
    // barra de ese tipo caída en fin de semana desaparecía dentro de la
    // columna. Este gris queda a 73 unidades RGB del tinte de finde, a 173 del
    // fondo normal y a 34 del escalón más cercano de la rampa.
    (cs.onSurface, 0.72),
  ];

  // Si mañana agregan el décimo tipo a `v_tipos`, vuelve a empezar: repetir un
  // color es feo, quedarse sin ninguno es peor.
  final (familia, tono) = pasos[indiceEnCatalogo % pasos.length];

  final fondo = Color.alphaBlend(
    familia.withValues(alpha: 1 - tono),
    cs.surface,
  );
  return ColorDeEstado(fondo, _letraSobre(fondo));
}

/// Negro o blanco sobre [fondo]: el que dé más contraste.
///
/// No se usan los pares `on*` del tema porque acá el fondo ya no es un rol puro,
/// se le aplicó un tono. Y no se usa un umbral fijo de luminancia porque un
/// umbral hay que elegirlo bien: con 0.42 el gris del feriado quedaba justo del
/// lado equivocado y la letra salía clara sobre un fondo medio, a 2.89:1.
/// Comparar los dos y quedarse con el mejor no necesita acertar ningún número.
Color _letraSobre(Color fondo) {
  const oscuro = Color(0xFF1A1A1A);
  const claro = Color(0xFFF2F2F2);
  return _contraste(fondo, oscuro) >= _contraste(fondo, claro) ? oscuro : claro;
}

/// Contraste WCAG entre dos colores opacos.
double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final alto = la > lb ? la : lb;
  final bajo = la > lb ? lb : la;
  return (alto + 0.05) / (bajo + 0.05);
}

/// El color de un día del reporte de asistencia biométrica, por su
/// `AsistenciaDiaEntity.estado` (TRABAJADO | FALTA | FERIADO | SABADO_LIBRE |
/// PERMISO | VACACION | SIN_HORARIO).
///
/// Misma doctrina que [colorDeEstado]: familia + tono, y sólo con `primary`,
/// `tertiary` y la rampa neutra — las tres familias que se separan con las
/// nueve semillas.
///
/// **FALTA es la única excepción a "no usar `error`" de este archivo.** A
/// diferencia de un feriado, una falta sin justificar SÍ es lo que el rol de
/// error de Material existe para señalar — es el estado que este reporte se
/// reescribió para poder afirmar con confianza (antes un feriado o un sábado
/// libre también salían acá). Límite conocido, igual al que ya acepta
/// [colorDeEstado]: con semilla roja, `error` se acerca a `primary`; por eso
/// TRABAJADO usa el contenedor pálido y no el rol pleno, para dejar más
/// distancia entre los dos estados que más importa distinguir.
ColorDeEstado colorDeAsistencia(ColorScheme cs, String estado) {
  final (Color familia, double tono) = switch (estado) {
    // Lo esperado: tenía horario y marcó.
    'TRABAJADO' => (cs.primaryContainer, 0.0),

    // El único problema real: tenía horario, no hay marcación ni excusa.
    'FALTA' => (cs.error, 0.0),

    // Ausencias legítimas e institucionales — familia terciaria, por tono
    // según qué tan "de la empresa" contra "de la persona" es el motivo.
    'FERIADO' => (cs.tertiaryContainer, 0.0),
    'VACACION' => (cs.tertiaryContainer, 0.35),
    'PERMISO' => (cs.tertiaryContainer, 0.65),

    // No le tocaba — ni feriado ni permiso, simplemente el rol de sábados
    // dice que ese día no era suyo. No es ni bueno ni malo: neutro.
    'SABADO_LIBRE' => (cs.surfaceContainerHighest, 0.0),

    // No había horario cargado ese día (domingo, o antes de su primera
    // asignación): no hay nada que contar. El más apagado de todos.
    'SIN_HORARIO' => (cs.onSurface, 0.88),

    _ => (cs.surfaceContainerHigh, 0.0),
  };

  final fondo = Color.alphaBlend(
    familia.withValues(alpha: 1 - tono),
    cs.surface,
  );
  return ColorDeEstado(fondo, _letraSobre(fondo));
}

// ═══════════════════════════════════════════════════════════════════════════
// CUÁNTO ESPACIO HAY
// ═══════════════════════════════════════════════════════════════════════════

/// Cuánto espacio hay, medido en lo que el contenido necesita.
///
/// No se usa `ResponsiveUtilsBosque` directamente en los widgets porque acá el
/// corte no es "es un teléfono": es **cuánto entra**. Una tablet en vertical y
/// un teléfono en horizontal necesitan tratos distintos aunque el paquete los
/// clasifique igual.
///
/// Y sobre todo: se mide el ancho del **cajón** (`LayoutBuilder`), no el de la
/// ventana. Adentro del dashboard el sidebar se come su parte, así que
/// `MediaQuery` miente. Nació en la matriz del Rol de Sábados —de ahí los
/// nombres de los cortes— y vive acá desde que el segundo módulo la necesitó.
enum Aire {
  /// Menos de ~7 columnas visibles: la matriz no se puede leer.
  justo,

  /// Entra la matriz, pero apretada.
  medio,

  /// Entra cómoda.
  amplio;

  static Aire de(double ancho) {
    if (ancho < 600) return Aire.justo;
    if (ancho < 1000) return Aire.medio;
    return Aire.amplio;
  }

  bool get esChico => this == Aire.justo;
}
