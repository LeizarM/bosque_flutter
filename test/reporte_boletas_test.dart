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
    TipoPermisoVacacionEntity(
      codTipos: 'vac',
      nombre: 'Vacación',
      codGrupo: 13,
      listTipos: null,
    ),
    TipoPermisoVacacionEntity(
      codTipos: 'pva',
      nombre: 'Vacación pagada',
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
