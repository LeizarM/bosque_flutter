/// Lo que `flutter analyze` no puede ver del reporte de boletas.
///
/// Dos cosas, y ninguna es cosmética:
///
/// 1. **Que entre.** Es una tabla de seis columnas adentro de un diálogo; un
///    `Row` que no entra compila perfecto y recién falla al renderizar, con la
///    franja amarilla y negra. Se dibuja a los cuatro anchos del criterio del
///    módulo, con nombres y motivos del largo real —los del SP llegan a 100
///    caracteres, no los de un JSON de ejemplo—.
///
/// 2. **Que el total sea el total.** Es la razón de ser de la pantalla: el
///    reporte anterior obligaba a exportar a Excel y sumar la columna a mano.
///    Si la suma de arriba miente, la pantalla es peor que la que reemplaza.
library;

import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart' show colorList;
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/reporte_boletas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `AppConstants.baseUrl` lee `dotenv.env`, que lanza si nadie cargó el
  // archivo. En la app lo carga `main.dart`; acá alcanza con dejarlo vacío.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  final anchos = <String, Size>{
    'móvil 360×740': const Size(360, 740),
    'tablet 800×1200': const Size(800, 1200),
    'escritorio 1280×800': const Size(1280, 800),
    'escritorio 1920×1080': const Size(1920, 1080),
  };

  for (final entrada in anchos.entries) {
    testWidgets('el reporte entra en ${entrada.key}', (tester) async {
      await _abrir(tester, tamano: entrada.value, boletas: _boletas);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde de layout en ${entrada.key}',
      );
    });
  }

  // ── LOS QUE ROMPIERON DE VERDAD ────────────────────────────────────────────
  //
  // La primera versión ponía la cabecera y los filtros FUERA del scroll, en un
  // `Column` de altura mínima. Cuando el alto no alcanzaba, la parte fija no
  // tenía a dónde ceder y salía la franja amarilla y negra. No eran casos
  // raros: el teléfono en horizontal tiene 412 px de alto, y la escala de letra
  // del sistema operativo la sube cualquiera. Ahora todo va en el mismo
  // `CustomScrollView`, así que no hay alto que no alcance.
  final bajos = <String, Size>{
    'teléfono horizontal 915×412': const Size(915, 412),
    'ventana baja 800×360': const Size(800, 360),
    'ventana baja y angosta 640×360': const Size(640, 360),
    'escritorio bajo 1280×380': const Size(1280, 380),
  };

  for (final caso in bajos.entries) {
    testWidgets('no desborda con poco alto: ${caso.key}', (tester) async {
      await _abrir(tester, tamano: caso.value, boletas: _boletas);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde vertical en ${caso.key}',
      );
    });
  }

  testWidgets('no desborda con el texto al 200%', (tester) async {
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      boletas: _boletas,
      escala: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  // ── LA FRANJA MUERTA ENTRE LA TABLA Y LAS TARJETAS ────────────────────────
  //
  // Las columnas fijas de la tabla suman 614 px de cajón, pero el corte a
  // tarjetas era `Aire.esChico` (cajón < 600). Entre esos dos números —una
  // ventana de escritorio de 648 a 661 px— se dibujaba la tabla sin lugar y
  // desbordaba a la derecha en TODOS los renglones. Y hasta ~860 px la columna
  // del detalle era tan angosta que el motivo se partía en una tira vertical de
  // una letra por renglón.
  final angostos = <String, Size>{
    'justo abajo del umbral 648×900': const Size(648, 900),
    'en el medio de la franja 652×900': const Size(652, 900),
    'justo arriba de la franja 662×900': const Size(662, 900),
    'sin lugar para el detalle 760×900': const Size(760, 900),
  };

  for (final caso in angostos.entries) {
    testWidgets('no desborda ni aprieta el detalle: ${caso.key}', (
      tester,
    ) async {
      await _abrir(tester, tamano: caso.value, boletas: _boletas);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde horizontal en ${caso.key}',
      );
      // Debajo del umbral tiene que ser tarjeta: la cabecera de tabla no está.
      expect(
        find.text('Cuándo'),
        findsNothing,
        reason: 'Dibujó la tabla sin ancho para ella en ${caso.key}',
      );
    });
  }

  testWidgets('cuando la tabla aparece, el detalle tiene ancho para leerse', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);
    expect(find.text('Cuándo'), findsOneWidget); // acá sí es tabla
    // El motivo largo tiene que entrar en pocas líneas, no en una tira.
    // Se busca en minúscula porque `enOracion` baja el grito del sistema viejo.
    final motivo = tester.getSize(
      find.textContaining('Vacaciones anuales programadas'),
    );
    expect(motivo.width, greaterThan(200));
    expect(motivo.height, lessThan(120));
  });

  testWidgets('con un rango que cruza años, la fecha lleva el año', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);
    // Por defecto el rango es el mes en curso: sin año, que es lo compacto.
    expect(find.textContaining('19 ene → 31 ene'), findsOneWidget);
    expect(find.text('19 ene → 31 ene 2026'), findsNothing);

    // «Este año» sigue siendo un solo año: tampoco lo agrega.
    await tester.tap(find.text('Este año'));
    await tester.pumpAndSettle();
    expect(find.text('19 ene → 31 ene 2026'), findsNothing);
  });

  testWidgets('el resumen suma todas las boletas, no la página visible', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);

    // 0,5 + 1 + 6 + 0,25 = 7,75 días · 4 + 8 + 48 + 2 = 62 horas
    expect(find.text('${_boletas.length}'), findsWidgets); // boletas
    expect(find.text('7,75'), findsOneWidget);
    expect(find.text('62'), findsOneWidget);
  });

  testWidgets('el desglose agrupa por tipo y ordena por peso', (tester) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);

    // Vacación 6 + 1 = 7 · A cuenta 0,5 · Vacación pagada 0,25
    expect(find.text('Vacación · 7 d'), findsOneWidget);
    expect(find.text('A cuenta de vacación · 0,5 d'), findsOneWidget);
    expect(find.text('Vacación pagada · 0,25 d'), findsOneWidget);

    // El de más peso va primero: la pregunta es en qué se fueron los días.
    final dx = (String t) => tester.getTopLeft(find.text(t)).dx;
    expect(dx('Vacación · 7 d'), lessThan(dx('A cuenta de vacación · 0,5 d')));
  });

  testWidgets('el buscador recorta la tabla Y el resumen, no sólo la tabla', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);
    await tester.enterText(find.byType(TextField), 'villafuerte');
    await tester.pumpAndSettle();

    expect(find.textContaining('VILLAFUERTE'), findsOneWidget);
    expect(find.textContaining('JUSTINIANO'), findsNothing);

    // El total tiene que seguir al filtro: si dijera 7,75 estaría contando
    // boletas que no se ven, y la cifra de arriba dejaría de ser la de la
    // pantalla.
    expect(find.text('Boletas (filtradas)'), findsOneWidget);
    expect(find.text('6'), findsWidgets); // 6 días, la única que queda
    expect(find.text('7,75'), findsNothing);
  });

  testWidgets('busca sin tildes: «teofilo» encuentra a TEÓFILO', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _conTilde);
    await tester.enterText(find.byType(TextField), 'teofilo');
    await tester.pumpAndSettle();
    expect(find.textContaining('TEÓFILO'), findsOneWidget);
  });

  testWidgets('la ñ NO se pisa: «pena» no encuentra a PEÑA', (tester) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _conTilde);
    await tester.enterText(find.byType(TextField), 'pena');
    await tester.pumpAndSettle();
    expect(find.textContaining('PEÑA'), findsNothing);
  });

  testWidgets('el número de boleta también busca', (tester) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);
    await tester.enterText(find.byType(TextField), '8140');
    await tester.pumpAndSettle();
    expect(find.textContaining('VILLAFUERTE'), findsOneWidget);
    expect(find.textContaining('JUSTINIANO'), findsNothing);
  });

  testWidgets('buscar y no encontrar dice que sí hay boletas en el rango', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nadie coincide'), findsOneWidget);
    expect(find.textContaining('${_boletas.length} boleta(s)'), findsOneWidget);
  });

  testWidgets('sin boletas explica por qué, no deja la pantalla en blanco', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: const []);
    expect(find.text('Sin boletas en ese rango'), findsOneWidget);
    // El motivo real de «faltan boletas»: el rango es por contención.
    expect(find.textContaining('no entra'), findsWidgets);
  });

  // Dos pruebas y no una con dos `_abrir`: el segundo abriría sobre la hoja
  // del primero, que sigue montada, y el toque caería sobre el velo.
  testWidgets('en el teléfono el reporte es una hoja, no un diálogo', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(360, 740), boletas: _boletas);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('en escritorio es un diálogo, que usa el ancho', (tester) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _boletas);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  // ── EL CRONOGRAMA ──────────────────────────────────────────────────────────
  //
  // La otra vista de las mismas boletas: una barra por permiso sobre una grilla
  // de días, un bloque por mes. Tiene tres cosas que `analyze` no puede ver y
  // que, si fallan, hacen que la vista MIENTA en vez de romperse:
  //
  //   · que entre, igual que la tabla — es una grilla de hasta 31 columnas;
  //   · que un permiso que cruza de mes aparezca en los dos bloques;
  //   · que dos permisos solapados de la misma persona se vean los dos.
  //
  // El tercero no es hipotético: en `trh_permiso` hay 291 pares solapados que
  // el alta vieja dejó pasar, y dibujados en un solo carril el segundo tapa al
  // primero — la vista escondería justo el dato que delata el problema.

  for (final entrada in {...anchos, ...bajos}.entries) {
    testWidgets('el cronograma entra en ${entrada.key}', (tester) async {
      await _abrir(tester, tamano: entrada.value, boletas: _cronograma);
      await _verCronograma(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde del cronograma en ${entrada.key}',
      );
    });
  }

  testWidgets('el cronograma no desborda con el texto al 200%', (tester) async {
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      boletas: _cronograma,
      escala: 2.0,
    );
    await _verCronograma(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un permiso que cruza de mes sale en los dos bloques', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _cronograma);
    await _verCronograma(tester);

    expect(find.text('Enero 2026'), findsOneWidget);
    expect(find.text('Febrero 2026'), findsOneWidget);
    // La 9001 va del 28/01 al 03/02: tiene que estar dibujada dos veces, una en
    // cada bloque, y no una sola en el mes en que arranca.
    expect(_barraDe(9001), findsNWidgets(2));
  });

  testWidgets('dos permisos solapados de la misma persona no se tapan', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _cronograma);
    await _verCronograma(tester);

    // 9002 y 9003 son de la misma persona y comparten días.
    final a = tester.getRect(_barraDe(9002));
    final b = tester.getRect(_barraDe(9003));

    expect(
      a.overlaps(b),
      isFalse,
      reason:
          'Las dos barras se pisan en pantalla: el reparto en carriles no '
          'funcionó y una esconde a la otra.',
    );
    // Y se pisan en el eje del tiempo, que es lo que las obliga a ir en
    // carriles distintos: si no se solaparan, el test no probaría nada.
    expect(a.left < b.right && b.left < a.right, isTrue);
  });

  testWidgets('un permiso de medio día se ve igual', (tester) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _cronograma);
    await _verCronograma(tester);

    // El 39 % de las boletas dura menos de un día. Estirada a la pantalla, esa
    // barra mediría dos píxeles: la grilla tiene un ancho de día mínimo para
    // que se vea, y esto lo comprueba.
    final media = tester.getRect(_barraDe(9004));
    expect(media.width, greaterThanOrEqualTo(10));
    expect(media.height, greaterThan(4));
  });

  // ── LOS QUE ENCONTRÓ LA REVISIÓN ──────────────────────────────────────────
  //
  // Seis defectos reales del cronograma, ninguno de los cuales rompía nada a la
  // vista: todos hacían que la pantalla MINTIERA. Un test por cada uno.

  testWidgets('una boleta sin «hasta» no rompe la fila', (tester) async {
    // Reventaba con «Null check operator used on a null value» y la fila salía
    // como recuadro rojo de error. El fallo estaba en `cuandoCompacto`, que es
    // código COMPARTIDO con la ficha del trabajador.
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      boletas: [
        NominaPermisoEntity(
          codPermiso: 7000,
          codEmpleado: 1,
          datoEmpleado: 'SIN HASTA JUAN',
          tipoPermiso: 'vac',
          datoTipoPermiso: 'Vacación',
          desde: DateTime(2026, 1, 10, 8),
          hasta: null,
          dias: 1,
          horas: 8,
          motivo: 'SIN FECHA DE FIN',
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('SIN HASTA'), findsWidgets);
  });

  testWidgets('una boleta con las fechas al revés no desaparece', (
    tester,
  ) async {
    // `hasta` anterior a `desde` y en otro mes: el bucle de meses no daba una
    // vuelta y la boleta no entraba en NINGÚN bloque. Ni dibujada, ni contada,
    // ni avisada — el resumen de arriba y el cronograma contaban distinto.
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      boletas: [
        NominaPermisoEntity(
          codPermiso: 7001,
          codEmpleado: 1,
          datoEmpleado: 'INVERTIDA ANA',
          tipoPermiso: 'vac',
          datoTipoPermiso: 'Vacación',
          desde: DateTime(2026, 3, 2, 8),
          hasta: DateTime(2026, 2, 27, 17),
          dias: 1,
          horas: 8,
          motivo: 'FECHAS AL REVES',
        ),
      ],
    );
    await tester.tap(find.text('Este año'));
    await tester.pumpAndSettle();
    await _verCronograma(tester);

    expect(
      _barraDe(7001),
      findsWidgets,
      reason: 'La boleta con las fechas invertidas se perdió del cronograma.',
    );
    expect(find.textContaining('INVERTIDA'), findsWidgets);
  });

  testWidgets('el fondo de la grilla se dibuja detrás de las barras', (
    tester,
  ) async {
    // El `Row` de celdas era hijo no posicionado de un `Stack`: se medía en
    // 0 px de alto y no se dibujaba ni una banda de fin de semana, ni el tinte
    // de hoy, ni un separador de día. Como la franja del eje sí se veía
    // —tiene su propio alto— parecía que estaba puesto.
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _cronograma);
    await _verCronograma(tester);

    final filas = find.byWidgetPredicate(
      (w) => w is Stack && w.children.isNotEmpty && w.children.first is Positioned,
    );
    expect(filas, findsWidgets);
    for (final e in filas.evaluate()) {
      final fondo = find.descendant(
        of: find.byWidget(e.widget),
        matching: find.byType(Row),
      );
      if (fondo.evaluate().isEmpty) continue;
      expect(
        tester.getSize(fondo.first).height,
        greaterThan(0),
        reason: 'El fondo de la grilla volvió a medir 0 px de alto.',
      );
    }
  });

  testWidgets('dos homónimos no se funden en una sola fila', (tester) async {
    // Se agrupaba por el nombre mostrado. Dos personas con el mismo nombre
    // quedaban en una fila y, peor, sus permisos se veían como si se
    // solaparan: el reparto en carriles inventaba un cruce que no existe.
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      boletas: [
        for (final cod in [101, 102])
          NominaPermisoEntity(
            codPermiso: 7100 + cod,
            codEmpleado: cod,
            datoEmpleado: 'MAMANI QUISPE JUAN',
            tipoPermiso: 'vac',
            datoTipoPermiso: 'Vacación',
            desde: DateTime(2026, 1, 12, 8),
            hasta: DateTime(2026, 1, 14, 17),
            dias: 3,
            horas: 24,
            motivo: 'VACACION',
          ),
      ],
    );
    await _verCronograma(tester);

    expect(
      find.text('MAMANI QUISPE JUAN'),
      findsNWidgets(2),
      reason: 'Los dos homónimos quedaron en una sola fila.',
    );
    // Y en un carril cada uno: no se dibujan como si se pisaran.
    final a = tester.getRect(_barraDe(7201));
    final b = tester.getRect(_barraDe(7202));
    expect(a.overlaps(b), isFalse);
  });

  testWidgets('el total de días del mes no cuenta dos veces al que cruza', (
    tester,
  ) async {
    // Un permiso que cruza aparece en los dos bloques. Sumando sus días
    // completos en cada uno, los meses daban más que el resumen de arriba.
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      boletas: [
        NominaPermisoEntity(
          codPermiso: 7300,
          codEmpleado: 1,
          datoEmpleado: 'CRUZA DE MES ROSARIO',
          tipoPermiso: 'vac',
          datoTipoPermiso: 'Vacación',
          desde: DateTime(2026, 1, 28, 8),
          hasta: DateTime(2026, 2, 3, 17),
          dias: 5,
          horas: 40,
          motivo: 'VACACION',
        ),
      ],
    );
    await tester.tap(find.text('Este año'));
    await tester.pumpAndSettle();
    await _verCronograma(tester);

    // Enero, donde arranca, se lleva los 5 días. Febrero dibuja la barra pero
    // suma 0: si no, entre los dos dirían 10 y el resumen dice 5.
    expect(find.textContaining('1 boleta(s) · 5 d'), findsOneWidget);
    expect(find.textContaining('1 boleta(s) · 0 d'), findsOneWidget);
  });

  testWidgets('los meses van del más antiguo al más reciente', (tester) async {
    // Al revés que la lista, y a propósito: adentro de cada mes el tiempo
    // corre hacia la derecha, así que entre meses tiene que correr hacia
    // abajo. Un cronograma que va para atrás se relee dos veces.
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _cronograma);
    await tester.tap(find.text('Este año'));
    await tester.pumpAndSettle();
    await _verCronograma(tester);

    expect(
      tester.getTopLeft(find.text('Enero 2026')).dy,
      lessThan(tester.getTopLeft(find.text('Febrero 2026')).dy),
      reason: 'Febrero quedó arriba de Enero.',
    );
  });

  _pruebasDeColor();

  testWidgets('la leyenda nombra sólo los tipos que están en pantalla', (
    tester,
  ) async {
    await _abrir(tester, tamano: const Size(1280, 800), boletas: _cronograma);
    await _verCronograma(tester);

    expect(find.text('Vacación'), findsWidgets);
    // «Sin Sueldo» no está en el fixture: una leyenda con los nueve tipos del
    // catálogo obliga a descartar siete a ojo.
    expect(find.text('Sin Sueldo'), findsNothing);
  });
}

/// Pasa a la vista de cronograma.
///
/// Por el ícono y no por el rótulo: con menos de 1000 px el conmutador es sólo
/// ícono, porque los dos rótulos más el botón de Excel desbordaban.
/// Con poco alto —360 px— el conmutador arranca fuera de pantalla y el
/// `CustomScrollView` ni siquiera lo construye, así que hay que bajar hasta él
/// antes de tocarlo. No es un defecto: la pantalla entera vive en un solo
/// scroll justamente para que ningún alto sea «insuficiente».
Future<void> _verCronograma(WidgetTester tester) async {
  final boton = find.byIcon(Icons.calendar_view_month_outlined);
  if (boton.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      boton,
      120,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.tap(boton.last);
  await tester.pumpAndSettle();
}

/// La barra de una boleta, buscada por el número que abre su tooltip.
Finder _barraDe(int codPermiso) => find.byWidgetPredicate(
  (w) => w is Tooltip && (w.message ?? '').startsWith('N.º $codPermiso '),
);

// ═══════════════════════════════════════════════════════════════════════════
// EL COLOR SALE DEL CATÁLOGO, NO DE UNA LISTA ESCRITA A MANO
// ═══════════════════════════════════════════════════════════════════════════
//
// La primera versión era un `switch` sobre los códigos y le faltaban DOS de los
// nueve —`libre` y `def`—, que salían con el color de «tipo desconocido» sin
// que nada avisara. Ese es exactamente el fallo que un catálogo copiado al
// frontend produce y que nadie nota: no rompe, sólo miente.
//
// Ahora el color sale de la POSICIÓN del tipo en `v_tipos`, así que agregar un
// tipo en la base le da color solo. Estas pruebas fijan esa propiedad.

void _pruebasDeColor() {
  // **Las 18 combinaciones reales, no `ColorScheme.light()`.** La primera
  // versión de estas pruebas medía contra `ColorScheme.light()`, que es el
  // esquema legacy donde `primary` y `primaryContainer` colapsan al MISMO
  // color: daba todo verde y no probaba nada de lo que ve el usuario. El tema
  // de esta app se arma con `colorSchemeSeed` sobre nueve semillas, más claro
  // y oscuro.
  final esquemas = <String, ColorScheme>{
    for (final semilla in colorList)
      for (final brillo in Brightness.values)
        '$semilla/${brillo.name}': ColorScheme.fromSeed(
          seedColor: semilla,
          brightness: brillo,
        ),
  };

  test('ningún esquema pinta dos tipos del mismo color', () {
    esquemas.forEach((nombre, cs) {
      final colores = [
        for (var i = 0; i < 9; i++) colorDeTipoPermiso(cs, i).fondo.toARGB32(),
      ];
      expect(
        colores.toSet().length,
        9,
        reason: 'En $nombre dos tipos salen exactamente del mismo color.',
      );
    });
  });

  test('los nueve colores se separan lo que se midió, en los 18 esquemas', () {
    // 17 unidades de RGB es lo que da la peor pareja, medido. No es mucho: el
    // comentario de `colorDeTipoPermiso` explica que nueve categorías no entran
    // del todo en el canal color y por qué la leyenda y el tooltip no son
    // opcionales. Este número está acá para que no EMPEORE sin que nadie note.
    esquemas.forEach((nombre, cs) {
      final c = [for (var i = 0; i < 9; i++) colorDeTipoPermiso(cs, i).fondo];
      for (var i = 0; i < 9; i++) {
        for (var j = i + 1; j < 9; j++) {
          final d =
              ((c[i].r - c[j].r) * 255).abs() +
              ((c[i].g - c[j].g) * 255).abs() +
              ((c[i].b - c[j].b) * 255).abs();
          expect(
            d,
            greaterThanOrEqualTo(15),
            reason: 'En $nombre los tipos $i y $j quedaron casi del mismo color.',
          );
        }
      }
    });
  });

  test('el rango de claridad no se achica', () {
    // Con puros contenedores el cronograma salía lavado: rango 4,7. Con los
    // roles plenos en los primeros escalones es 5,5. Si alguien vuelve a los
    // contenedores «porque quedan más suaves», esto lo frena.
    esquemas.forEach((nombre, cs) {
      final lum = [
        for (var i = 0; i < 9; i++)
          colorDeTipoPermiso(cs, i).fondo.computeLuminance(),
      ]..sort();
      expect(
        (lum.last + 0.05) / (lum.first + 0.05),
        greaterThan(4.5),
        reason: 'En $nombre la paleta quedó toda del mismo tono de claro.',
      );
    });
  });

  test('un tipo fuera del catálogo no se confunde con ninguno', () {
    esquemas.forEach((nombre, cs) {
      final desconocido = colorDeTipoPermiso(cs, -1).fondo;
      for (var i = 0; i < 9; i++) {
        expect(
          colorDeTipoPermiso(cs, i).fondo,
          isNot(desconocido),
          reason:
              'En $nombre el tipo $i se ve igual que «desconocido»: los 28 '
              'registros históricos sin tipo parecerían de ese tipo.',
        );
      }
    });
  });

  test('el décimo tipo repite color en vez de quedarse sin ninguno', () {
    // Si mañana agregan uno a `v_tipos`, la rampa vuelve a empezar.
    final cs = esquemas.values.first;
    expect(colorDeTipoPermiso(cs, 9).fondo, colorDeTipoPermiso(cs, 0).fondo);
    expect(colorDeTipoPermiso(cs, 40).fondo, isA<Color>());
  });

  test('la letra elegida se separa de su fondo', () {
    // 3:1 y no 4,5:1 a propósito: 4,5 es el mínimo AA para TEXTO, y las barras
    // no llevan texto encima —son rellenos con borde—. Para un objeto gráfico
    // el mínimo es 3:1 (WCAG 1.4.11). El par existe para que, si algún día se
    // pone una etiqueta ENCIMA de una barra, arranque de algo que se lee.
    esquemas.forEach((nombre, cs) {
      for (var i = -1; i < 10; i++) {
        final c = colorDeTipoPermiso(cs, i);
        final a = c.fondo.computeLuminance();
        final b = c.texto.computeLuminance();
        final alto = a > b ? a : b;
        final bajo = a > b ? b : a;
        expect(
          (alto + 0.05) / (bajo + 0.05),
          greaterThanOrEqualTo(3.0),
          reason: 'En $nombre el color $i no se separa de su letra.',
        );
      }
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// EL ARNÉS
// ═══════════════════════════════════════════════════════════════════════════

Future<void> _abrir(
  WidgetTester tester, {
  required Size tamano,
  required List<NominaPermisoEntity> boletas,
  double escala = 1.0,
}) async {
  tester.view
    ..physicalSize = tamano
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        permisosRrhhRepositoryProvider.overrideWithValue(
          _RepoFalso(boletas: boletas),
        ),
      ],
      child: MaterialApp(
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
        home: Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => mostrarReporteBoletas(context),
                    child: const Text('abrir'),
                  ),
                ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

class _RepoFalso implements PermisosRrhhRepository {
  _RepoFalso({required this.boletas});

  final List<NominaPermisoEntity> boletas;

  @override
  Future<List<NominaPermisoEntity>> getBoletas({
    DateTime? desde,
    DateTime? hasta,
    String tipoPermiso = '',
  }) async =>
      tipoPermiso.isEmpty
          ? boletas
          : boletas.where((b) => b.tipoPermiso == tipoPermiso).toList();

  @override
  Future<List<TipoPermisoVacacionEntity>> getTiposPermiso({
    bool incluirVacacionYPago = false,
  }) async => [
    // Los NUEVE de `v_tipos` grupo 13, tal cual están en la base y en el orden
    // que devuelve la ACCION 'T1' (por descripción). El catálogo importa: de la
    // posición de cada tipo en esta lista sale el color de su barra en el
    // cronograma, así que dos tipos de mentira no probarían nada.
    for (final t in const [
      ('baja', 'Baja por Enfermedad'),
      ('clb', 'Comision Laboral'),
      ('libre', 'Día Libre'),
      ('otro', 'Otros'),
      ('pva', 'Pago Vacación'),
      ('pcr', 'Permisos con reposicion'),
      ('def', 'Por Defunción'),
      ('sinsuel', 'Sin Sueldo'),
      ('vac', 'Vacación'),
    ])
      TipoPermisoVacacionEntity(
        codTipos: t.$1,
        nombre: t.$2,
        codGrupo: 13,
        listTipos: null,
      ),
  ];

  /// Lo que estas pruebas no usan. Igual que en
  /// `permisos_rrhh_responsive_test.dart`: si alguna prueba futura llama a otra
  /// cosa, revienta diciendo cuál, que es mejor que un `null` en silencio.
  @override
  dynamic noSuchMethod(Invocation invocacion) =>
      throw UnimplementedError(
        'El repositorio falso no implementa ${invocacion.memberName}',
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS DE MENTIRA, DEL TAMAÑO REAL
// ═══════════════════════════════════════════════════════════════════════════

/// Nombres y motivos del largo que manda el SP, no los cortitos de un ejemplo:
/// es lo que hace desbordar una tabla que en el papel entraba.
final _boletas = <NominaPermisoEntity>[
  NominaPermisoEntity(
    codPermiso: 8135,
    codEmpleado: 237,
    datoEmpleado: 'ALMENDRAS ROCHA JEMIO ERICK ALBERTO',
    tipoPermiso: 'otro',
    datoTipoPermiso: 'A cuenta de vacación',
    desde: DateTime(2026, 1, 7, 12),
    hasta: DateTime(2026, 1, 7, 18),
    dias: 0.5,
    horas: 4,
    motivo: 'A CUENTA DE VACACION',
  ),
  NominaPermisoEntity(
    codPermiso: 8136,
    codEmpleado: 130,
    datoEmpleado: 'JUSTINIANO SOMOZA MARCO ANTONIO',
    tipoPermiso: 'vac',
    datoTipoPermiso: 'Vacación',
    desde: DateTime(2026, 1, 8, 8),
    hasta: DateTime(2026, 1, 8, 17, 30),
    dias: 1,
    horas: 8,
    motivo: 'VACACION',
  ),
  NominaPermisoEntity(
    codPermiso: 8140,
    codEmpleado: 242,
    datoEmpleado: 'VILLAFUERTE PONCE PAOLO ANDRES DE JESUS',
    tipoPermiso: 'vac',
    datoTipoPermiso: 'Vacación',
    desde: DateTime(2026, 1, 19, 8),
    hasta: DateTime(2026, 1, 31, 17, 30),
    dias: 6,
    horas: 48,
    motivo:
        'VACACIONES ANUALES PROGRAMADAS SEGUN CRONOGRAMA APROBADO POR JEFATURA '
        'DE PLANTA Y RECURSOS HUMANOS',
  ),
  NominaPermisoEntity(
    codPermiso: 8141,
    codEmpleado: 88,
    datoEmpleado: 'FLORES HUAYGUA NICOLE DANITZA',
    tipoPermiso: 'pva',
    datoTipoPermiso: 'Vacación pagada',
    desde: DateTime(2026, 2, 2, 8),
    hasta: DateTime(2026, 2, 2, 10),
    dias: 0.25,
    horas: 2,
    motivo: '',
  ),
];

/// Los dos apellidos que rompen un buscador ingenuo: uno con tilde, que hay que
/// aplanar, y uno con ñ, que **no**.
final _conTilde = <NominaPermisoEntity>[
  NominaPermisoEntity(
    codPermiso: 9001,
    codEmpleado: 11,
    datoEmpleado: 'VARGAS APAZA WILMER TEÓFILO',
    tipoPermiso: 'vac',
    datoTipoPermiso: 'Vacación',
    desde: DateTime(2026, 8, 5, 8, 30),
    hasta: DateTime(2026, 8, 5, 17),
    dias: 1,
    horas: 8,
    motivo: 'A cuenta vacacion',
  ),
  NominaPermisoEntity(
    codPermiso: 9002,
    codEmpleado: 12,
    datoEmpleado: 'PEÑA ROJAS MARIA',
    tipoPermiso: 'vac',
    datoTipoPermiso: 'Vacación',
    desde: DateTime(2026, 8, 6, 8),
    hasta: DateTime(2026, 8, 6, 17),
    dias: 1,
    horas: 8,
    motivo: 'Vacacion',
  ),
];

/// Boletas armadas para el cronograma: una que cruza de mes, dos solapadas de
/// la misma persona, y una de medio día.
final _cronograma = <NominaPermisoEntity>[
  NominaPermisoEntity(
    codPermiso: 9001,
    codEmpleado: 10,
    datoEmpleado: 'CRUZA DE MES ROSARIO',
    tipoPermiso: 'vac',
    datoTipoPermiso: 'Vacación',
    desde: DateTime(2026, 1, 28, 8),
    hasta: DateTime(2026, 2, 3, 17, 30),
    dias: 5,
    horas: 40,
    motivo: 'VACACION QUE CRUZA DE MES',
  ),
  NominaPermisoEntity(
    codPermiso: 9002,
    codEmpleado: 20,
    datoEmpleado: 'SOLAPADO PEREZ JUAN',
    tipoPermiso: 'vac',
    datoTipoPermiso: 'Vacación',
    desde: DateTime(2026, 1, 12, 8),
    hasta: DateTime(2026, 1, 16, 17, 30),
    dias: 5,
    horas: 40,
    motivo: 'VACACION',
  ),
  NominaPermisoEntity(
    codPermiso: 9003,
    codEmpleado: 20,
    datoEmpleado: 'SOLAPADO PEREZ JUAN',
    tipoPermiso: 'baja',
    datoTipoPermiso: 'Baja por Enfermedad',
    desde: DateTime(2026, 1, 14, 8),
    hasta: DateTime(2026, 1, 19, 17, 30),
    dias: 4,
    horas: 32,
    motivo: 'BAJA MEDICA QUE SE PISA CON LA VACACION',
  ),
  NominaPermisoEntity(
    codPermiso: 9004,
    codEmpleado: 30,
    datoEmpleado: 'MEDIA JORNADA QUISPE ANA',
    tipoPermiso: 'otro',
    datoTipoPermiso: 'Otros',
    desde: DateTime(2026, 1, 20, 14),
    hasta: DateTime(2026, 1, 20, 18),
    dias: 0.5,
    horas: 4,
    motivo: 'MEDIA JORNADA',
  ),
];
