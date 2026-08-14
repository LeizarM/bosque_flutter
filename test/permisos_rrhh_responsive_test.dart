import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/models/empleado_model.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/desglose_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/tramo_saldo_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:bosque_flutter/presentation/screens/permisos-rrhh/permisos_rrhh_screen.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/calculadora_antiguedad.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/desglose_saldo.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/ficha_saldo.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/pestanas_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Lo que `flutter analyze` no puede ver de este módulo.
///
/// Son dos cosas distintas:
///
/// 1. **Que entre.** Un `Row` que no entra compila perfecto y recién falla al
///    renderizar, con la franja amarilla y negra. Acá se dibuja de verdad a los
///    cuatro anchos del criterio de aceptación (360, 800, 1280 y 1920) más el
///    iPad Pro, **con las etiquetas reales del SP** —que llegan a 95 caracteres,
///    no las del JSON de ejemplo del plan—.
///
/// 2. **Que no diga lo que no debe.** Los tres estados de D0, D1 y D2 son el
///    corazón de la fase: con `desgloseAplicable == false` la pantalla no puede
///    pintar los cinco tramos ni la etiqueta «-1º», y con relaciones anteriores
///    tiene que rotular el alcance. Eso no es cosmética: es la diferencia entre
///    publicar una cifra defendible y una que no.
void main() {
  // `AppConstants.baseUrl` lee `dotenv.env`, que **lanza** si nadie cargó el
  // archivo. En la app lo carga `main.dart`; acá alcanza con dejarlo vacío para
  // que caiga en los valores compilados. Sin esto, cualquier widget que toque
  // el cliente HTTP —`PermissionWidget`, que arma el repositorio de permisos—
  // revienta antes de dibujar nada.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  // ── Los cuatro anchos del criterio #11, más el iPad Pro ────────────────────
  final anchos = <String, Size>{
    'móvil 360×740': const Size(360, 740),
    'tablet 800×1200': const Size(800, 1200),
    'escritorio 1280×800': const Size(1280, 800),
    'escritorio 1920×1080': const Size(1920, 1080),
    'iPad Pro 1024×1366': const Size(1024, 1366),
  };

  for (final entrada in anchos.entries) {
    testWidgets('la pantalla entra en ${entrada.key}', (tester) async {
      await _dibujar(
        tester,
        tamano: entrada.value,
        hijo: const PermisosRrhhScreen(),
        conBreakpoints: true,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde de layout en ${entrada.key}',
      );
    });

    testWidgets('el desglose entra en ${entrada.key}', (tester) async {
      await _dibujar(
        tester,
        tamano: entrada.value,
        hijo: const DesgloseTab(codEmpleado: 130),
        desglose: _desgloseCompleto,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Desborde del desglose en ${entrada.key}',
      );
      // Las etiquetas se muestran literales, con la ortografía del SP incluida:
      // el criterio de aceptación es que sean carácter por carácter iguales a
      // las del modal viejo.
      expect(find.textContaining('Saldo hasta el penultimo'), findsOneWidget);
    });
  }

  // ── El reparto maestro/detalle empieza a los 1000 px, no a los 600 ─────────
  testWidgets('a 800 px el buscador va a pantalla completa, sin panel partido', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(800, 1200),
      hijo: const PermisosRrhhScreen(),
      conBreakpoints: true,
    );
    // El `VerticalDivider` es lo único que delata la decisión: es la línea entre
    // el panel maestro de 400 px y el detalle. A 800 px el detalle quedaría con
    // 399 px, o sea con el layout de móvil adentro de una tablet.
    expect(find.byType(VerticalDivider), findsNothing);
  });

  testWidgets('a 1280 px sí aparece el panel maestro al lado del detalle', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const PermisosRrhhScreen(),
      conBreakpoints: true,
    );
    expect(find.byType(VerticalDivider), findsOneWidget);
  });

  // ── El buscador dibujando una tarjeta de verdad ────────────────────────────
  testWidgets('la tarjeta del buscador muestra nombre, empresa y cargo', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const PermisosRrhhScreen(),
      conBreakpoints: true,
      empleados: [_empleadoDelBuscador],
    );

    // Los tres datos salen de rutas distintas del MISMO JSON, y las tres las
    // llena el row mapper de `EmpleadoDAO.obtenerLstEmpleados`. Leerlas del
    // lugar equivocado no lanza nada: `fromJson` devuelve '' y la tarjeta queda
    // en blanco, que es como estaba antes de este test.
    expect(find.text('BALDERRAMA CRISTHIAN ALEJANDRO'), findsOneWidget);
    expect(find.text('BOSQUE S.R.L. · OPERADOR DE MAQUINA'), findsOneWidget);
  });

  testWidgets('en móvil el desglose es una lista, no una tabla', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(360, 740),
      hijo: const DesgloseTab(codEmpleado: 130),
      desglose: _desgloseCompleto,
    );
    // Una tabla de dos columnas parte la etiqueta de 95 caracteres en cinco
    // renglones y deja el número flotando lejos de su fila.
    expect(find.byType(Table), findsNothing);
  });

  testWidgets('sólo se abren los tres tramos que suman permisos', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const DesgloseTab(codEmpleado: 130),
      desglose: _desgloseCompleto,
    );
    // De los cinco tramos, tres son sumas de filas de `trh_permiso` y se
    // pueden abrir. `ASIGNADA_ANIO` suma `trh_vacacionAsignada` —que tiene su
    // propia pestaña— y `ACUMULADA` es una fórmula: no hay lista que mostrar,
    // y ofrecer el botón ahí sería prometer un detalle que no existe.
    expect(find.text('Ver detalle'), findsNWidgets(3));
  });

  testWidgets('en escritorio el desglose es una tabla', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const DesgloseTab(codEmpleado: 130),
      desglose: _desgloseCompleto,
    );
    expect(find.byType(Table), findsOneWidget);
  });

  // ── D2: el estado que le toca hoy a 57 de 85 ───────────────────────────────
  testWidgets('con desgloseAplicable=false no pinta los 5 tramos ni «-1º»', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const DesgloseTab(codEmpleado: 130),
      desglose: _desgloseDegenerado,
    );

    expect(find.textContaining('-1º'), findsNothing);
    expect(find.textContaining('Saldo hasta el penultimo'), findsNothing);
    expect(find.textContaining('TOTAL VACACION NO UTILIZADO'), findsNothing);

    // Y sí dice por qué, con los tres números que valen.
    expect(find.textContaining('no cumplió dos años'), findsOneWidget);
    expect(find.text('Asignados hasta hoy'), findsOneWidget);
    expect(find.text('Utilizados'), findsOneWidget);
    expect(find.text('Programados'), findsOneWidget);
  });

  // ── D0: el rótulo de alcance por relación laboral ──────────────────────────
  testWidgets('con relaciones anteriores rotula el alcance del saldo', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const SaldoTab(codEmpleado: 130),
      ficha: _fichaConHistoria,
    );

    expect(
      find.textContaining('Saldo de la relación laboral actual'),
      findsOneWidget,
    );
    expect(
      find.textContaining('184 movimientos anteriores no incluidos'),
      findsOneWidget,
    );
  });

  testWidgets('sin relaciones anteriores no muestra el rótulo de alcance', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const SaldoTab(codEmpleado: 130),
      ficha: _fichaSimple,
    );
    expect(
      find.textContaining('Saldo de la relación laboral actual'),
      findsNothing,
    );
  });

  testWidgets('sin fecha de beneficio muestra la advertencia', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const SaldoTab(codEmpleado: 130),
      ficha: _fichaSinFechaBeneficio,
    );
    expect(
      find.textContaining('no tiene fecha de inicio de beneficio'),
      findsOneWidget,
    );
  });

  // ── La calculadora y su caso degenerado ────────────────────────────────────
  testWidgets('la calculadora avisa cuando el cálculo da 0 días', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const CalculadoraTab(),
      // Las dos fechas van a salir iguales (hoy), que es exactamente el caso
      // que la función del SP no sabe calcular: mismo mes → 0 días.
      calculo:
          'Trabajo 0 año(s) 0 mes(es) y 0 dia(s) y le corresponden = 0 dias '
          'por antiguedad, tiene un total de 0.0 Dias acumulados',
    );

    await _elegirFecha(tester);
    await _elegirFecha(tester);
    await tester.tap(find.text('Calcular'));
    await tester.pumpAndSettle();

    expect(find.textContaining('caso límite'), findsOneWidget);
  });

  testWidgets('la calculadora no avisa cuando el cálculo es normal', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const CalculadoraTab(),
      calculo:
          'Trabajo 11 año(s) 5 mes(es) y 10 dia(s) y le corresponden = 30 dias '
          'por antiguedad, tiene un total de 13.75 Dias acumulados',
    );

    await _elegirFecha(tester);
    await _elegirFecha(tester);
    await tester.tap(find.text('Calcular'));
    await tester.pumpAndSettle();

    expect(find.textContaining('caso límite'), findsNothing);
    expect(find.textContaining('30 dias por antiguedad'), findsOneWidget);
  });

  _pruebasDeLaPestanaApagada();
}

// ═══════════════════════════════════════════════════════════════════════════
// ANDAMIAJE
// ═══════════════════════════════════════════════════════════════════════════

/// Abre el calendario del primer campo sin fecha y acepta la que propone.
///
/// Siempre el primero: en cuanto uno queda con fecha deja de decir «Elegir
/// fecha», así que el que sigue pasa a ser el primero.
Future<void> _elegirFecha(WidgetTester tester) async {
  await tester.tap(find.text('Elegir fecha').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

// ═══════════════════════════════════════════════════════════════════════════
// EL INTERRUPTOR DE LA PESTAÑA «PERMISOS»
// ═══════════════════════════════════════════════════════════════════════════

/// Lo que se rompe al apagar o encender una pestaña del medio.
///
/// El índice de una pestaña es posicional: la calculadora se abre por número
/// desde la barra de la pantalla, así que mover una pestaña de la izquierda la
/// corre. Estas dos pruebas valen para las dos posiciones de
/// `mostrarPestanaPermisos`, así que siguen sirviendo el día que se encienda.
void _pruebasDeLaPestanaApagada() {
  testWidgets('la pestaña «Permisos» aparece sólo si el interruptor está en '
      'true', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const PestanasDelEmpleado(),
    );
    expect(
      find.widgetWithText(Tab, 'Permisos'),
      mostrarPestanaPermisos ? findsOneWidget : findsNothing,
    );
    // La calculadora no se va nunca: es la que se abre por índice.
    expect(find.widgetWithText(Tab, 'Calculadora'), findsOneWidget);
  });

  testWidgets('el índice de la calculadora sigue apuntando a la calculadora', (
    tester,
  ) async {
    // Si `indiceCalculadora` quedara desfasado de `cantidad`, el
    // `DefaultTabController` lanzaría acá con un `initialIndex` fuera de rango
    // — que es exactamente el modo en que esto se rompe.
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const PestanasDelEmpleado(
        pestanaInicial: PestanasDelEmpleado.indiceCalculadora,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CalculadoraTab), findsOneWidget);
    expect(
      PestanasDelEmpleado.indiceCalculadora,
      lessThan(PestanasDelEmpleado.cantidad),
    );
  });
}

Future<void> _dibujar(
  WidgetTester tester, {
  required Size tamano,
  required Widget hijo,
  FichaSaldoEntity? ficha,
  DesgloseSaldoEntity? desglose,
  String calculo = '',
  bool conBreakpoints = false,
  List<EmpleadoEntity> empleados = const [],
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Widget app = MaterialApp(home: Scaffold(body: hijo));
  if (conBreakpoints) {
    // La pantalla usa `ResponsiveUtilsBosque` para el padding del banner, y esa
    // clase lanza si no hay un `ResponsiveBreakpoints` arriba. En la app real
    // lo pone `main.dart` sobre TODO el árbol.
    app = MaterialApp(
      home: hijo,
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: ResponsiveUtilsBosque.breakpoints,
          ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(_admin),
        ),
        permisosRrhhRepositoryProvider.overrideWithValue(
          _RepoFalso(
            ficha: ficha,
            desglose: desglose,
            calculo: calculo,
            empleados: empleados,
          ),
        ),
      ],
      child: app,
    ),
  );
  await tester.pumpAndSettle();

  // `PermissionWidget` dispara la carga real del ACL: arma el cliente HTTP, le
  // pide el token a `SecureStorage` (3 s de vencimiento) y sale a la red (que
  // acá no existe). Esos temporizadores quedan colgados y el banco de pruebas
  // lo denuncia al desmontar el árbol. El tiempo es simulado, así que dejarlos
  // vencer no cuesta nada: dos minutos cubren toda la cadena.
  await tester.pump(const Duration(minutes: 2));
}

/// `ROLE_ADM` para que `PermissionWidget` deje pasar: el ACL de verdad se
/// resuelve en el servidor y acá no hay servidor.
final _admin = LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
});

class _RepoFalso implements PermisosRrhhRepository {
  _RepoFalso({
    this.ficha,
    this.desglose,
    this.calculo = '',
    this.empleados = const [],
  });

  final FichaSaldoEntity? ficha;
  final DesgloseSaldoEntity? desglose;
  final String calculo;

  /// **Con una lista vacía el buscador nunca dibuja una tarjeta**, y era por eso
  /// que el módulo llegó a la revisión con las tarjetas en blanco sin que
  /// ninguna prueba lo notara.
  final List<EmpleadoEntity> empleados;

  @override
  Future<List<EmpleadoEntity>> buscarEmpleados(
    String texto, {
    bool soloActivos = true,
    int codEmpresa = 0,
    int pagina = 1,
    int porPagina = 50,
  }) async => empleados;

  @override
  Future<FichaSaldoEntity?> getFichaSaldo(int codEmpleado) async => ficha;

  @override
  Future<DesgloseSaldoEntity?> getDesgloseSaldo(int codEmpleado) async =>
      desglose;

  @override
  Future<String> calcularAntiguedad({
    required DateTime desde,
    required DateTime hasta,
  }) async => calculo;

  /// Lo que estas pruebas no usan.
  ///
  /// Son pruebas de **layout**: ninguna escribe ni pide el historial, así que
  /// declarar `noSuchMethod` evita diez stubs vacíos que habría que mantener
  /// cada vez que el contrato crece. Y si alguna prueba futura llama a una de
  /// esas, revienta diciendo cuál — que es mejor que un `null` en silencio.
  @override
  dynamic noSuchMethod(Invocation invocacion) =>
      throw UnimplementedError(
        'El repositorio falso no implementa ${invocacion.memberName}',
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS DE MENTIRA, DEL TAMAÑO REAL
// ═══════════════════════════════════════════════════════════════════════════

/// Un empleado **como lo manda `/rrhh/obtenerLstEmpleados`**, armado desde el
/// JSON crudo y no a mano.
///
/// Es la parte que ningún test cubría: ese endpoint devuelve `List<Empleado>`
/// serializado por Jackson, y su row mapper (`EmpleadoDAO.obtenerLstEmpleados`,
/// `p_list_Empleado @ACCION='Y'`) sólo escribe **10 columnas**, colgadas de
/// `persona` y de `empleadoCargo.cargoSucursal.cargo`. El `datoPersona` de nivel
/// raíz existe porque `Empleado extends Persona` y llega **null**; el `empresa`
/// de nivel raíz es un objeto vacío. Leer de ahí no lanza nada —`fromJson` los
/// convierte en cadena vacía— y la tarjeta sale en blanco.
final _empleadoDelBuscador =
    EmpleadoModel.fromJson(<String, dynamic>{
      'fila': 1,
      'codEmpleado': 130,
      'codPersona': 88,
      // Null a propósito: es lo que manda el servidor.
      'datoPersona': null,
      'persona': <String, dynamic>{
        'datoPersona': 'BALDERRAMA CRISTHIAN ALEJANDRO',
        'zona': <String, dynamic>{},
        'pais': <String, dynamic>{},
        'ciudad': <String, dynamic>{},
      },
      'relEmpEmpr': <String, dynamic>{'esActivo': 1},
      'empleadoCargo': <String, dynamic>{
        'cargoSucursal': <String, dynamic>{
          'cargo': <String, dynamic>{
            // Cargo real y cargo de planilla son columnas distintas del SP y
            // este endpoint muestra el de PLANILLA (§6.2).
            'descripcion': 'OPERADOR DE MAQUINA CONVERTIDORA',
            'descripcionPlanilla': 'OPERADOR DE MAQUINA',
            'nombreEmpresa': 'INDUSTRIAS DE PAPEL IMPEXPAP S.A.',
            'codEmpresaPlanilla': 2,
            'nombreEmpresaPlanilla': 'BOSQUE S.R.L.',
          },
        },
      },
      // Todo lo que el SP no trae: Jackson lo serializa como objeto vacío.
      'zona': <String, dynamic>{},
      'pais': <String, dynamic>{},
      'ciudad': <String, dynamic>{},
      'dependiente': <String, dynamic>{},
      'telefono': <String, dynamic>{},
      'empresa': <String, dynamic>{},
      'sucursal': <String, dynamic>{},
      'email': <String, dynamic>{},
      'formacion': <String, dynamic>{},
      'experienciaLaboral': <String, dynamic>{},
      'garanteReferencia': <String, dynamic>{},
    }).toEntity();

const _fichaSimple = FichaSaldoEntity(
  codEmpleado: 130,
  datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
  datoEmpresa: 'INDUSTRIAS DE PAPEL IMPEXPAP S.A.',
  datoCargo: 'OPERADOR DE MAQUINA CONVERTIDORA',
  datoFechaBeneficio: '01/03/2015',
  datoAntiguedad: '11 Años y 5 Meses',
  diasNoUsados: 12.5,
  diasAbonados: 2,
  totalDias: 14.5,
  diasNoUsadosTxt: '12,5 días',
  diasAbonadosTxt: '2 días',
  totalDiasTxt: '14,5 días',
  datoRelEmplEmprVigente: 411,
  tieneRelacionesAnteriores: false,
  movimientosFueraDeRelacionVigente: 0,
);

final _fichaConHistoria = FichaSaldoEntity(
  codEmpleado: 130,
  datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
  datoEmpresa: 'INDUSTRIAS DE PAPEL IMPEXPAP S.A.',
  datoCargo: 'OPERADOR DE MAQUINA CONVERTIDORA',
  datoFechaBeneficio: '01/03/2015',
  datoAntiguedad: '11 Años y 5 Meses',
  // Saldo negativo: 45 empleados lo tienen con esta acción. Se pinta con
  // `colorScheme.error`, y sobre todo NO tiene que reventar el layout.
  diasNoUsados: -220.75,
  diasAbonados: 0,
  totalDias: -220.75,
  diasNoUsadosTxt: '-220,75 días',
  diasAbonadosTxt: '0 días',
  totalDiasTxt: '-220,75 días',
  datoRelEmplEmprVigente: 411,
  relacionVigenteDesde: DateTime(2019, 4),
  tieneRelacionesAnteriores: true,
  movimientosFueraDeRelacionVigente: 184,
);

const _fichaSinFechaBeneficio = FichaSaldoEntity(
  codEmpleado: 130,
  datoEmpleado: 'PEREZ GOMEZ JUAN CARLOS',
  datoEmpresa: 'IMPEXPAP',
  datoCargo: 'OPERADOR',
  // El literal lo escribe el SP; no es un nulo disfrazado.
  datoFechaBeneficio: 'Sin Asignar',
  datoAntiguedad: '2 Años',
  diasNoUsados: 0,
  diasAbonados: 0,
  totalDias: 0,
  diasNoUsadosTxt: '0 días',
  diasAbonadosTxt: '0 días',
  totalDiasTxt: '0 días',
  datoRelEmplEmprVigente: 411,
  tieneRelacionesAnteriores: false,
  movimientosFueraDeRelacionVigente: 0,
);

/// Las cinco etiquetas **como las escribe el SP**: con sus fechas adentro, su
/// ortografía y sus 95 caracteres. Es el fixture que pide §6.5; el JSON de
/// ejemplo del plan tiene etiquetas cortas y no probaría nada.
final _desgloseCompleto = DesgloseSaldoEntity(
  codEmpleado: 130,
  datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
  datoEmpresa: 'INDUSTRIAS DE PAPEL IMPEXPAP S.A.',
  datoCargo: 'OPERADOR DE MAQUINA CONVERTIDORA',
  datoAntiguedad: '15 Años y 5 Meses',
  datoFecIniBenef: '01/03/2010',
  datoAnios: 15,
  fecIniPenUl: DateTime(2025, 2, 28),
  fecIniUlt: DateTime(2026, 3),
  codRelEmplEmpr: 411,
  tieneFechaBeneficio: true,
  desgloseAplicable: true,
  tramos: const [
    TramoSaldoEntity(
      clave: 'SALDO_PENULTIMO',
      etiqueta: 'Saldo hasta el penultimo año cumplido (28/02/2025)',
      monto: 220,
      montoTxt: '220 días',
      signo: 'DEBE',
      tieneDetalle: true,
    ),
    TramoSaldoEntity(
      clave: 'ASIGNADA_ANIO',
      etiqueta:
          'Vacacion correspondiente a su 15º año cumplido  '
          '(01/03/2025 al 28/02/2026)',
      monto: 30,
      montoTxt: '30 días',
      signo: 'DEBE',
      tieneDetalle: false,
    ),
    TramoSaldoEntity(
      clave: 'ACUMULADA',
      etiqueta:
          'Vacación acumulada desde su ultimo año cumplido (01/03/2026) '
          'hasta hoy ',
      monto: 12.9,
      montoTxt: '12,9 días',
      signo: 'INFO',
      tieneDetalle: false,
    ),
    TramoSaldoEntity(
      clave: 'UTILIZADA',
      etiqueta: 'Vacación utilizada desde el (28/02/2025) hasta hoy ',
      monto: 22,
      montoTxt: '22 días',
      signo: 'HABER',
      tieneDetalle: true,
    ),
    TramoSaldoEntity(
      clave: 'PROGRAMADA',
      etiqueta: 'Vacación programada a partir de hoy 11/08/2026',
      monto: 3.5,
      montoTxt: '3,5 días',
      signo: 'HABER',
      tieneDetalle: true,
    ),
  ],
  montoTotalDebe: 250,
  montoTotalHaber: 25.5,
  montoTotal: 224.5,
  montoTotalTxt: '224,5 días',
  etiquetaTotal: 'TOTAL VACACION NO UTILIZADO',
);

/// El caso mayoritario: `datoAnios < 2`, la rama degenerada del tramo 2. El
/// backend manda los tramos igual —con la etiqueta absurda incluida— y la
/// pantalla tiene que NO pintarlos.
final _desgloseDegenerado = DesgloseSaldoEntity(
  codEmpleado: 139,
  datoEmpleado: 'RAMOS RODRIGO',
  datoEmpresa: 'IMPEXPAP',
  datoCargo: 'AUXILIAR',
  datoAntiguedad: '1 Año y 2 Meses',
  datoFecIniBenef: '01/06/2025',
  datoAnios: 1,
  fecIniPenUl: DateTime(2025, 5, 31),
  fecIniUlt: DateTime(2026, 6),
  codRelEmplEmpr: 520,
  tieneFechaBeneficio: true,
  desgloseAplicable: false,
  tramos: const [
    TramoSaldoEntity(
      clave: 'SALDO_PENULTIMO',
      etiqueta: 'Saldo hasta el penultimo año cumplido (31/05/2025)',
      monto: 0,
      montoTxt: '0 días',
      signo: 'DEBE',
      tieneDetalle: false,
    ),
    TramoSaldoEntity(
      clave: 'ASIGNADA_ANIO',
      etiqueta:
          'Vacacion correspondiente a su -1º año cumplido  '
          '(01/06/2024 al 31/05/2025)',
      monto: 15,
      montoTxt: '15 días',
      signo: 'DEBE',
      tieneDetalle: false,
    ),
    TramoSaldoEntity(
      clave: 'ACUMULADA',
      etiqueta:
          'Vacación acumulada desde su ultimo año cumplido (01/06/2026) '
          'hasta hoy ',
      monto: 2.5,
      montoTxt: '2,5 días',
      signo: 'INFO',
      tieneDetalle: false,
    ),
    TramoSaldoEntity(
      clave: 'UTILIZADA',
      etiqueta: 'Vacación utilizada desde el (31/05/2025) hasta hoy ',
      monto: 5,
      montoTxt: '5 días',
      signo: 'HABER',
      tieneDetalle: false,
    ),
    TramoSaldoEntity(
      clave: 'PROGRAMADA',
      etiqueta: 'Vacación programada a partir de hoy 11/08/2026',
      monto: 0,
      montoTxt: '0 días',
      signo: 'HABER',
      tieneDetalle: false,
    ),
  ],
  montoTotalDebe: 15,
  montoTotalHaber: 5,
  montoTotal: 10,
  montoTotalTxt: '10 días',
  etiquetaTotal: 'TOTAL VACACION NO UTILIZADO',
);
