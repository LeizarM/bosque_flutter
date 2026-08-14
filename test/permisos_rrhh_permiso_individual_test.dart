import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/simulacion_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';

import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/nomina_permisos_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que `flutter analyze` no puede ver de las cuatro pantallas del permiso
/// individual, y que además es lo que puede costar plata.
///
/// Tres cosas distintas:
///
/// 1. **Que entre.** Un `Table` de seis columnas compila perfecto y recién
///    falla al renderizar. Acá se dibuja de verdad en teléfono, tablet y
///    escritorio con motivos del largo real de la columna (100 caracteres).
/// 2. **Que el número que se muestra sea el del servidor.** Es la regla que
///    sostiene todo: los tres campos calculados salen de `/permiso/simular`, y
///    si el cálculo no llegó, falló o el rango se cruza con otro permiso, el
///    botón de guardar tiene que estar apagado. Un botón habilitado sobre un
///    número que no vino es exactamente cómo se graban días que nadie revisó.
/// 3. **Que la confirmación diga el impacto real.** «¿Estás seguro?» no es una
///    confirmación: la de vacación tiene que decir cuántos días, a quién y de
///    cuándo a cuándo, y la de vacación pagada además cómo queda el saldo.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  // ── QUE ENTRE ──────────────────────────────────────────────────────────────
  final anchos = <String, Size>{
    'móvil 360×740': const Size(360, 740),
    'tablet 800×1200': const Size(800, 1200),
    'escritorio 1280×800': const Size(1280, 800),
    'escritorio 1920×1080': const Size(1920, 1080),
  };

  for (final entrada in anchos.entries) {
    testWidgets('la nómina de permisos entra en ${entrada.key}', (tester) async {
      await _dibujar(tester, tamano: entrada.value, permisos: _kardex);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde de layout en ${entrada.key}',
      );
      expect(find.text('Nómina de permisos'), findsOneWidget);
    });
  }

  testWidgets('en móvil la nómina es tarjetas, no una tabla', (tester) async {
    await _dibujar(tester, tamano: const Size(360, 740), permisos: _kardex);
    // Seis columnas en 360 px dejan cada una con 55 px y el motivo cortado en
    // la primera palabra.
    expect(find.byType(Table), findsNothing);
    // La fecha manda en la tarjeta, y el permiso de varios días se lee como un
    // tramo en vez de repetir la fecha dos veces.
    expect(find.text('17/08/2026 → 20/08/2026'), findsOneWidget);
  });

  testWidgets('el permiso de un día no repite la fecha', (tester) async {
    await _dibujar(tester, tamano: const Size(1280, 800), permisos: _kardex);
    // La tabla vieja ponía «18/02/2026 08:00» en Desde y «18/02/2026 18:30» en
    // Hasta: la misma fecha dos veces. Ahora va una sola y compacta; el año lo
    // dice el tramo y el horario vive en el tooltip de la barra.
    expect(find.text('18 feb'), findsOneWidget);
    expect(find.text('17 ago → 20 ago'), findsOneWidget);
  });

  testWidgets('la duración se dibuja y la más larga manda la escala', (
    tester,
  ) async {
    await _dibujar(tester, tamano: const Size(1280, 800), permisos: _kardex);
    // Una barra por permiso: es lo que hace saltar la ausencia larga entre
    // cientos de medias jornadas iguales.
    expect(find.byType(FractionallySizedBox), findsNWidgets(_kardex.length));
    // El permiso más largo del fixture (3,25 d) ocupa la barra entera.
    final barras = tester.widgetList<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(barras.map((b) => b.widthFactor).reduce((a, b) => a! > b! ? a : b), 1.0);
  });

  testWidgets('la etiqueta de tipo aparece sólo en lo que no es vacación', (
    tester,
  ) async {
    await _dibujar(tester, tamano: const Size(1280, 800), permisos: _kardex);
    // El 93% de trh_permiso es vacación: marcarlas todas es no marcar ninguna.
    expect(find.text('Vacación anual'), findsNothing);
    expect(find.text('Otros'), findsOneWidget);
    expect(find.text('Sin tipo'), findsOneWidget);
  });

  testWidgets('en escritorio la nómina va por tramos de año', (tester) async {
    await _dibujar(tester, tamano: const Size(1280, 800), permisos: _kardex);
    expect(find.text('Cuándo'), findsOneWidget);
    expect(find.text('Duración'), findsOneWidget);
    expect(find.text('Detalle'), findsOneWidget);
    // El año encabeza su tramo una sola vez, no se repite en cada fila: el
    // fixture tiene dos permisos de 2026 y uno de 2019.
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2019'), findsOneWidget);
  });

  testWidgets('la nómina NO muestra columnas de deuda', (tester) async {
    // `trh_repper` tiene 0 filas y la fórmula del SP es
    // `SUM(cantidadDiasRepuestos) - cantidadDias`: la columna no da cero, da el
    // NEGATIVO de los días. Mostrarla sería publicar un dato malo sobre días
    // pagados.
    await _dibujar(tester, tamano: const Size(1280, 800), permisos: _kardex);
    expect(find.textContaining('Deuda'), findsNothing);
  });

  testWidgets('sin permisos dice por qué y qué hacer', (tester) async {
    await _dibujar(tester, tamano: const Size(1280, 800), permisos: const []);
    expect(find.text('Sin permisos'), findsOneWidget);
  });

  testWidgets('«Buscar vac ganadas» cambia a la otra grilla, con sus columnas', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      permisos: _kardex,
      vacGanadas: _asignadas,
    );

    expect(find.text('Nómina de permisos'), findsOneWidget);
    await tester.tap(find.text('Buscar vac ganadas'));
    await tester.pumpAndSettle();

    // Son dos consultas con columnas distintas: se muestra la última pedida en
    // vez de apilarlas.
    expect(find.text('Nómina de permisos'), findsNothing);
    expect(find.text('Nómina de vacaciones asignadas'), findsOneWidget);
    expect(find.text('Día(s)'), findsOneWidget);
    expect(find.text('15 días'), findsOneWidget);
    // **Y salió por su propio endpoint** (`p_list_vacacionAsignada 'D'`), no de
    // recortar en memoria el historial, que es la ACCION 'B': otra pregunta,
    // con fecha de corte y con filas sintéticas por aniversario.
    expect(_repo.ganadasPedidas, 1);
  });

  // ── EL NÚMERO QUE SE MUESTRA ES EL DEL SERVIDOR ────────────────────────────
  testWidgets('la hoja de vacación muestra los días que calculó el servidor', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      // 3 días para un rango de un día y medio: el número es del servidor, no
      // una cuenta del cliente sobre las fechas.
      simulacion: const SimulacionPermisoEntity(
        dias: 3,
        horas: 24,
        datoSucursal: 'LA PAZ',
      ),
    );
    await _abrir(tester, 'Programar vacación');

    expect(find.text('Total días de vacación'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('Feriados de LA PAZ'), findsOneWidget);
    // La vacación no muestra horas ni reposición: su modal tampoco las tiene.
    expect(find.text('Horas a reponer'), findsNothing);
  });

  testWidgets('si el cálculo falla no se puede guardar', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      simulacion: const SimulacionPermisoEntity(dias: 2, horas: 16),
      falloSimulacion: true,
    );
    await _abrir(tester, 'Programar vacación');

    expect(find.textContaining('No se puede guardar'), findsOneWidget);
    expect(_botonDe(tester, 'Programar la vacación').onPressed, isNull);
  });

  testWidgets('el cruce de permisos bloquea el guardado y dice cuál choca', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      // Es lo que manda `EmpleadoColectivoDto`: `entra` en false y el motivo
      // redactado, con el rango del permiso que choca adentro. El cliente lee
      // eso y no cuatro campos propios que el servidor nunca mandó — con
      // aquéllos, `entra` llegaba siempre en true y el botón quedaba encendido
      // sobre una escritura que el DAO ya iba a rechazar.
      simulacion: const SimulacionPermisoEntity(
        dias: 2,
        horas: 16,
        entra: false,
        detalle:
            'Ya tiene un permiso cargado que se cruza con ese rango (del '
            '17/08/2026 08:00 al 20/08/2026 10:00).',
      ),
    );
    await _abrir(tester, 'Programar vacación');

    // Hay 294 pares solapados en producción y el sistema anterior no chequea
    // nada: sin esto la pantalla nueva agrega filas al mismo pozo.
    expect(find.textContaining('se cruza con ese rango'), findsOneWidget);
    expect(find.textContaining('17/08/2026'), findsOneWidget);
    expect(_botonDe(tester, 'Programar la vacación').onPressed, isNull);
  });

  testWidgets('sin motivo no se puede guardar, con motivo sí', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      simulacion: const SimulacionPermisoEntity(dias: 2, horas: 16),
    );
    await _abrir(tester, 'Programar vacación');

    expect(_botonDe(tester, 'Programar la vacación').onPressed, isNull);

    await tester.enterText(_campo('Motivo'), 'Vacación de agosto');
    await tester.pumpAndSettle();
    expect(_botonDe(tester, 'Programar la vacación').onPressed, isNotNull);
  });

  testWidgets('cambiar el horario vuelve a pedirle el número al servidor', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      simulacion: const SimulacionPermisoEntity(dias: 2, horas: 16),
    );
    await _abrir(tester, 'Programar vacación');
    expect(_repo.simulaciones, hasLength(1));

    // El radio no viaja en el cuerpo —la función SQL deduce el horario de la
    // hora de fin— pero sí mueve la ventana de horas, así que el número puede
    // cambiar: recalcular no es opcional.
    await tester.tap(find.text('Horario continuo'));
    await tester.pumpAndSettle();
    // Todavía no: hay 400 ms de rebote, que es lo que evita un viaje por cada
    // toque del selector.
    expect(_repo.simulaciones, hasLength(1));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(_repo.simulaciones, hasLength(2));
  });

  // ── LA CONFIRMACIÓN DICE EL IMPACTO REAL ───────────────────────────────────
  testWidgets('la vacación confirma diciendo días, persona y fechas', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      simulacion: const SimulacionPermisoEntity(dias: 3, horas: 24),
    );
    await _abrir(tester, 'Programar vacación');
    await tester.enterText(_campo('Motivo'), 'Vacación de agosto');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programar la vacación'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vas a registrar 3 días'), findsOneWidget);
    // «a BALDERRAMA» y no el nombre pelado: el nombre pelado también está en el
    // encabezado de la hoja, y lo que se quiere probar es que la pregunta dice
    // a quién.
    expect(
      find.textContaining('a BALDERRAMA CRISTHIAN ALEJANDRO'),
      findsOneWidget,
    );
    expect(find.textContaining('se le descuentan del saldo'), findsOneWidget);
    // Y todavía no escribió nada: la confirmación es un paso, no un adorno.
    expect(_repo.vacaciones, isEmpty);
  });

  testWidgets('recién al confirmar escribe, y por la ruta de la vacación', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      simulacion: const SimulacionPermisoEntity(dias: 3, horas: 24),
    );
    await _abrir(tester, 'Programar vacación');
    await tester.enterText(_campo('Motivo'), 'Vacación de agosto');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programar la vacación'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Programar'));
    await tester.pumpAndSettle();

    // **Por la ruta de la vacación, no por la del permiso con `'vac'`**: son
    // dos endpoints con dos botones del ACL, y `/permisos/registrar` rechaza
    // 'vac' con un 400.
    expect(_repo.vacaciones, hasLength(1));
    expect(_repo.registrados, isEmpty);
  });

  testWidgets('«Horas a reponer» sólo aparece en el permiso, y avisa que no se '
      'registra', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      simulacion: const SimulacionPermisoEntity(dias: 1, horas: 8),
    );
    await _abrir(tester, 'Programar permiso');

    expect(find.text('Horas a reponer'), findsOneWidget);
    // Sin tipo elegido son 0 horas y no hay aviso: la regla es
    // `tipoPermiso in ('otro','pcr')`, la misma de `verificarTipoPermiso()`.
    expect(find.textContaining('NO quedan registradas'), findsNothing);

    // El combo de la hoja, no el filtro de la pestaña que quedó abajo: el árbol
    // de atrás sigue montado bajo el modal.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otros').last);
    await tester.pumpAndSettle();
    // El número lo calcula el SERVIDOR (`tipo in ('otro','pcr')`), así que
    // cambiar el combo vuelve a preguntar, con el mismo rebote que las fechas.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('NO quedan registradas'), findsOneWidget);
  });

  // ── VACACIÓN PAGADA: LA QUE CUESTA PLATA ───────────────────────────────────
  testWidgets('la vacación pagada muestra el saldo antes y después', (
    tester,
  ) async {
    await _dibujar(tester, tamano: const Size(1280, 900));
    await _abrir(tester, 'Vacación pagada');

    expect(find.text('Saldo hoy'), findsOneWidget);
    expect(find.text('Después de pagar'), findsOneWidget);
    // Sin días tipeados no se inventa un número.
    expect(find.text('…'), findsOneWidget);

    await tester.enterText(_campo('Días a pagar'), '2,5');
    await tester.pumpAndSettle();
    // 12,5 − 2,5 = 10, y sin coma flotante de por medio.
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('la vacación pagada avisa cuando se pagan más días que el saldo', (
    tester,
  ) async {
    await _dibujar(tester, tamano: const Size(1280, 900));
    await _abrir(tester, 'Vacación pagada');
    await tester.enterText(_campo('Días a pagar'), '40');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('más días de los que tiene'),
      findsOneWidget,
    );
  });

  testWidgets('la vacación pagada confirma diciendo cómo queda el saldo', (
    tester,
  ) async {
    await _dibujar(tester, tamano: const Size(1280, 900));
    await _abrir(tester, 'Vacación pagada');
    await tester.enterText(_campo('Días a pagar'), '2,5');
    await tester.enterText(_campo('Motivo'), 'Pago de vacación 2026');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pagar los días'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vas a pagar 2,5 días'), findsOneWidget);
    expect(find.textContaining('Su saldo pasa de'), findsOneWidget);
    expect(find.textContaining('a 10 días'), findsOneWidget);
    expect(_repo.pagados, isEmpty);
  });

  testWidgets('media día es el piso: con menos no se puede pagar', (
    tester,
  ) async {
    await _dibujar(tester, tamano: const Size(1280, 900));
    await _abrir(tester, 'Vacación pagada');
    await tester.enterText(_campo('Motivo'), 'Pago de vacación 2026');
    await tester.enterText(_campo('Días a pagar'), '0,25');
    await tester.pumpAndSettle();
    expect(_botonDe(tester, 'Pagar los días').onPressed, isNull);

    await tester.enterText(_campo('Días a pagar'), '0,5');
    await tester.pumpAndSettle();
    expect(_botonDe(tester, 'Pagar los días').onPressed, isNotNull);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// ANDAMIAJE
// ═══════════════════════════════════════════════════════════════════════════

late _RepoFalso _repo;

/// Abre una de las tres hojas desde el botón real de la pestaña, con su gate de
/// ACL puesto: así se prueba el camino que usa la app y no un atajo.
Future<void> _abrir(WidgetTester tester, String boton) async {
  await tester.tap(find.text(boton));
  await tester.pumpAndSettle();
}

/// El campo de texto que tiene esa etiqueta.
Finder _campo(String etiqueta) =>
    find.widgetWithText(TextField, etiqueta).first;

ButtonStyleButton _botonDe(WidgetTester tester, String texto) =>
    tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(texto),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ).first,
    );

Future<void> _dibujar(
  WidgetTester tester, {
  required Size tamano,
  List<NominaPermisoEntity> permisos = const [],
  List<VacacionAsignadaEntity> vacGanadas = const [],
  SimulacionPermisoEntity? simulacion,
  bool falloSimulacion = false,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _repo = _RepoFalso(
    permisos: permisos,
    vacGanadas: vacGanadas,
    simulacion: simulacion,
    falloSimulacion: falloSimulacion,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(_admin)),
        permisosRrhhRepositoryProvider.overrideWithValue(_repo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: NominaPermisosTab(codEmpleado: 130)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Los temporizadores del ACL, que sale a una red que acá no existe.
  await tester.pump(const Duration(minutes: 2));
}

final _admin = LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
});

class _RepoFalso implements PermisosRrhhRepository {
  _RepoFalso({
    required this.permisos,
    this.vacGanadas = const [],
    this.simulacion,
    this.falloSimulacion = false,
  });

  final List<NominaPermisoEntity> permisos;
  final List<VacacionAsignadaEntity> vacGanadas;
  final SimulacionPermisoEntity? simulacion;
  final bool falloSimulacion;

  /// Los `tipoPermiso` que se mandaron a grabar. **Vacío no es un detalle**: es
  /// la prueba de que la confirmación es un paso de verdad y no un cartel.
  final List<String> registrados = [];

  /// Las vacaciones individuales, que van por su propia ruta.
  final List<String> vacaciones = [];
  final List<double> pagados = [];

  @override
  Future<FichaSaldoEntity?> getFichaSaldo(int codEmpleado) async => _ficha;

  @override
  Future<List<NominaPermisoEntity>> getNominaPermisos(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    String tipoPermiso = '',
    DateTime? desde,
    DateTime? hasta,
    DateTime? fecRango,
  }) async => permisos;

  /// Cuántas veces se pidió «Buscar vac ganadas» **por su propio endpoint**.
  /// Si el botón volviera a servirse del historial (ACCION 'B'), esto queda en
  /// 0 y la prueba de abajo se cae.
  int ganadasPedidas = 0;

  @override
  Future<List<VacacionAsignadaEntity>> getVacacionesGanadas(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    ganadasPedidas++;
    return vacGanadas;
  }

  /// Cada rango que se mandó a calcular. Es lo que prueba que el número no lo
  /// inventa el cliente y que el rebote no se come el recálculo.
  final List<String> simulaciones = [];

  @override
  Future<SimulacionPermisoEntity?> simularPermiso({
    required int codEmpleado,
    required DateTime desde,
    required DateTime hasta,
    String tipoPermiso = '',
  }) async {
    simulaciones.add('$desde→$hasta');
    if (falloSimulacion) throw Exception('El servidor no contestó');
    final s = simulacion;
    if (s == null) return null;
    // Las horas a reponer las calcula el SERVIDOR con `tipo in ('otro','pcr')`
    // (`PermisoDao.horasAReponer`). El falso hace lo mismo: si la pantalla
    // volviera a calcularlas por su cuenta, este eco dejaría de importar y la
    // prueba del aviso pasaría igual estando roto.
    return SimulacionPermisoEntity(
      dias: s.dias,
      horas: s.horas,
      horasAReponer:
          (tipoPermiso == 'otro' || tipoPermiso == 'pcr') ? s.horas : 0,
      codSucursal: s.codSucursal,
      datoSucursal: s.datoSucursal,
      entra: s.entra,
      detalle: s.detalle,
    );
  }

  @override
  Future<List<TipoPermisoVacacionEntity>> getTiposPermiso({
    bool incluirVacacionYPago = false,
  }) async => [
    TipoPermisoVacacionEntity(
      codTipos: 'otro',
      nombre: 'Otros',
      codGrupo: 13,
      listTipos: null,
    ),
    TipoPermisoVacacionEntity(
      codTipos: 'libre',
      nombre: 'Dia Libre',
      codGrupo: 13,
      listTipos: null,
    ),
  ];

  @override
  Future<String> registrarPermiso({
    required int codEmpleado,
    required String tipoPermiso,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    registrados.add(tipoPermiso);
    return 'Se registró el permiso.';
  }

  /// **Método aparte y no `registrarPermiso('vac')`**: del otro lado son dos
  /// rutas con dos botones del ACL. Si la hoja de vacación volviera a pegarle a
  /// la del permiso, `registrados` guardaría `'vac'` y la prueba lo canta.
  @override
  Future<String> registrarVacacion({
    required int codEmpleado,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    vacaciones.add('$desde→$hasta');
    return 'Se registró la vacación.';
  }

  @override
  Future<String> registrarVacacionPagada({
    required int codEmpleado,
    required DateTime fecha,
    required double dias,
    required String motivo,
    bool confirmado = false,
  }) async {
    pagados.add(dias);
    return 'Se pagaron $dias días.';
  }

  /// Lo que estas pruebas no usan: si alguna futura llama a otra cosa, revienta
  /// diciendo cuál, que es mejor que un `null` en silencio.
  @override
  dynamic noSuchMethod(Invocation invocacion) => throw UnimplementedError(
    'El repositorio falso no implementa ${invocacion.memberName}',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS DE MENTIRA, DEL TAMAÑO REAL
// ═══════════════════════════════════════════════════════════════════════════

const _ficha = FichaSaldoEntity(
  codEmpleado: 130,
  datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
  datoEmpresa: 'INDUSTRIAS DE PAPEL IMPEXPAP S.A.',
  datoCargo: 'OPERADOR DE MAQUINA CONVERTIDORA',
  datoFechaBeneficio: '01/03/2015',
  datoAntiguedad: '11 Años y 5 Meses',
  diasNoUsados: 12.5,
  diasAbonados: 0,
  totalDias: 12.5,
  diasNoUsadosTxt: '12,5 días',
  diasAbonadosTxt: '0 días',
  totalDiasTxt: '12,5 días',
  datoRelEmplEmprVigente: 411,
  tieneRelacionesAnteriores: false,
  movimientosFueraDeRelacionVigente: 0,
);

/// Lo que devuelve «Buscar vac ganadas» (`p_list_vacacionAsignada 'D'`): filas
/// **reales** de `trh_vacacionAsignada`, recortadas por el SP.
///
/// Sin sintéticas (`codVacacionAsignada = 0`): ésas las inventa la ACCION 'B'
/// del historial para ofrecer el «Nuevo» de su grilla, y por eso este botón va a
/// otro endpoint en vez de recortar aquella lista en memoria.
final _asignadas = [
  VacacionAsignadaEntity(
    codVacacionAsignada: 3120,
    codEmpleado: 130,
    codRelEmplEmpr: 411,
    diasAsignados: 15,
    diasAsignadosTxt: '15 días',
    motivo: 'Asignación automática por aniversario',
    fecha: DateTime(2026, 3, 1, 7),
  ),
];

/// Filas como las manda `p_list_Permiso 'Q'`: días en fracciones —el `float`
/// que un truncado convertiría en cero— y un motivo del largo real de la
/// columna.
final _kardex = [
  NominaPermisoEntity(
    codPermiso: 8462,
    tipoPermiso: 'vac',
    datoTipoPermiso: 'Vacación anual',
    desde: DateTime(2026, 8, 17, 8),
    hasta: DateTime(2026, 8, 20, 10),
    dias: 3.25,
    horas: 26,
    motivo:
        'Vacación programada por el área de recursos humanos según el rol '
        'anual acordado con jefatura de planta',
  ),
  NominaPermisoEntity(
    codPermiso: 8473,
    tipoPermiso: 'otro',
    datoTipoPermiso: 'Otros',
    desde: DateTime(2026, 2, 18, 8),
    hasta: DateTime(2026, 2, 18, 18, 30),
    dias: 1.125,
    horas: 9,
    motivo: 'Trámite personal',
  ),
  NominaPermisoEntity(
    codPermiso: 8100,
    // Las 28 filas históricas sin tipo, residuo del flujo de boletas que el
    // sistema anterior dejó muerto.
    tipoPermiso: '',
    desde: DateTime(2019, 5, 6, 8),
    hasta: DateTime(2019, 5, 6, 12),
    dias: 0.5,
    horas: 4,
    motivo: '',
  ),
];
