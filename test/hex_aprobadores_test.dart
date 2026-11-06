import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/agenda_provider.dart';
import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/data/models/hex_aprobador_model.dart';
import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_aprobador_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_encargado_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_rama_empleado_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_aprobadores_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formulario_aprobador.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_rama_aprobador.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// «Aprobadores» agrupado por jefe de área: los encargados con su rama (D34)
/// bajo el jefe que los aprueba (D35), «Ver rama», cerrar y eliminar el par o
/// el rol, mensajes del SP (D21), permisos, filtros, historial (D22) y anchos.
void main() {
  setUpAll(cargarFuentesHex);

  late HexConfiguracionFalso repo;

  /// 4 empleados en 2 sucursales (D18: la agenda del Dashboard).
  final agenda = [
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(7),
      nombreCompleto: 'Rojas Vargas Luis',
      cargo: 'Encargado de planta',
      codSucursal: 1,
      sucursal: 'Planta El Alto',
    ),
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(8),
      nombreCompleto: 'Paredes Limachi Rosa',
      cargo: 'Jefa de producción',
      codSucursal: 1,
      sucursal: 'Planta El Alto',
    ),
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(9),
      nombreCompleto: 'Quispe Mamani Ana',
      cargo: 'Encargada de almacén',
      codSucursal: 2,
      sucursal: 'Almacén Central',
    ),
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(10),
      nombreCompleto: 'Choque Flores Mario',
      cargo: 'Operario',
      codSucursal: 2,
      sucursal: 'Almacén Central',
    ),
  ];

  /// La bitácora de aprobadores que manda el SP.
  final eventos = [
    HexConfiguracionEventoEntity(
      idEvento: BigInt.from(30),
      entidad: EntidadConfiguracionHex.aprobador,
      entidadTexto: 'Aprobador',
      idRegistro: BigInt.one,
      descripcion: 'Rojas Vargas Luis · Responsable de producción',
      accion: 'I',
      accionTexto: 'Asignación nueva',
      valorNuevo: 'Encargado de su rama desde 01/01/2026',
      audUsuario: BigInt.from(3),
      nombreUsuario: 'Salazar Rivera Jorge',
      audFecha: DateTime(2025, 12, 20, 10),
      totalFilas: 1,
    ),
  ];

  setUp(() {
    repo = HexConfiguracionFalso();
    repo.programar('historial', [(filas: eventos, total: eventos.length)]);
  });

  final hoy = DateUtils.dateOnly(DateTime.now());

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  List<Override> anulaciones({
    Future<List<AgendaEmpleadoEntity>> Function()? leerAgenda,
  }) => [
    hexConfiguracionRepositoryProvider.overrideWithValue(repo),
    agendaEmpleadosProvider.overrideWith(
      (ref) => leerAgenda?.call() ?? Future.value(agenda),
    ),
  ];

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
    Future<List<AgendaEmpleadoEntity>> Function()? leerAgenda,
  }) async {
    await montarHex(
      t,
      const HexAprobadoresScreen(),
      ancho: ancho,
      botones: botones,
      overrides: anulaciones(leerAgenda: leerAgenda),
    );
    await esperar(t);
  }

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  /// Un aviso del kit: se dibuja fuera de la pantalla.
  Finder aviso(String texto) => find.byElementPredicate((e) {
    final w = e.widget;
    return w is Text &&
        w.data == texto &&
        e.findAncestorWidgetOfExactType<HexAprobadoresScreen>() == null;
  });

  bool esVertical(Widget w) =>
      (w is ScrollView && w.scrollDirection == Axis.vertical) ||
      (w is SingleChildScrollView && w.scrollDirection == Axis.vertical);

  bool esLateral(Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;

  Future<void> tocar(WidgetTester t, Finder f, {int fotogramas = 3}) async {
    await t.ensureVisible(f);
    await esperar(t, 1);
    await t.tap(f);
    await esperar(t, fotogramas);
  }

  /// El campo selector con esa etiqueta, en el formulario si está abierto
  /// (la etiqueta flotante no recibe toques: se toca el campo).
  Finder selector(String etiqueta) {
    final campo = find.byWidgetPredicate(
      (w) => w is InputDecorator && w.decoration.labelText == etiqueta,
    );
    final dialogo = find.byType(AlertDialog);
    final alcance =
        dialogo.evaluate().isEmpty
            ? campo
            : find.descendant(of: dialogo, matching: campo);
    return find.ancestor(of: alcance, matching: find.byType(InkWell)).first;
  }

  /// El campo de búsqueda del buscador abierto (el último diálogo).
  Finder buscador() => find.descendant(
    of: find.byType(Dialog).last,
    matching: find.byType(TextField),
  );

  /// Una opción del buscador abierto, a la vista.
  Finder opcion(String texto) =>
      find.widgetWithText(ListTile, texto).hitTestable();

  /// Abre el buscador del campo [etiqueta], escribe [buscar] (si viene) y
  /// elige [texto].
  Future<void> elegir(
    WidgetTester t,
    String etiqueta,
    String texto, {
    String? buscar,
  }) async {
    await tocar(t, selector(etiqueta), fotogramas: 2);
    if (buscar != null) {
      await t.enterText(buscador(), buscar);
      await esperar(t, 2);
    }
    await t.tap(opcion(texto).first);
    await esperar(t, 2);
  }

  /// Elige el día [dia] en el calendario que abre el campo [etiqueta].
  Future<void> elegirDia(WidgetTester t, String etiqueta, String dia) async {
    await tocar(t, selector(etiqueta), fotogramas: 2);
    await t.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text(dia),
      ),
    );
    await t.tap(find.text('Aceptar'));
    await esperar(t, 2);
  }

  /// La fila del árbol (un encargado) que muestra [nombre]; vacío si no está.
  Finder nodo(String nombre) => find.ancestor(
    of: find.text(nombre),
    matching: find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_GuiaArbolHex',
    ),
  );

  /// [accion] del encargado [nombre]: a la vista si está («Ver rama»); si
  /// no, desde su menú.
  Future<void> accionDe(WidgetTester t, String nombre, String accion) async {
    final enLinea = find.descendant(
      of: nodo(nombre),
      matching: find.byTooltip(accion),
    );
    if (enLinea.evaluate().isNotEmpty) {
      await tocar(t, enLinea.first);
      return;
    }
    await tocar(
      t,
      find.descendant(of: nodo(nombre), matching: find.byTooltip('Acciones')),
      fotogramas: 2,
    );
    await t.tap(find.text(accion).last);
    await esperar(t, 3);
  }

  /// Los textos del menú del encargado [nombre]; lo deja cerrado.
  Future<List<String>> menuDe(WidgetTester t, String nombre) async {
    await tocar(
      t,
      find.descendant(of: nodo(nombre), matching: find.byTooltip('Acciones')),
      fotogramas: 2,
    );
    final textos = [
      for (final e
          in find
              .descendant(
                of: find.byType(PopupMenuItem<int>),
                matching: find.byType(Text),
              )
              .evaluate())
        (e.widget as Text).data ?? '',
    ];
    await t.tapAt(const Offset(5, 5));
    await esperar(t, 2);
    return textos;
  }

  /// Paredes aprueba a Quispe y a Rojas; Mendoza es encargado sin jefe.
  List<HexAprobadorEntity> conDosEncargados() => [
    parAprobadorFalso(
      2,
      8,
      'Paredes Limachi Rosa',
      9,
      'Quispe Mamani Ana',
      cargo: 'Supervisora de almacenes',
      rama: 5,
    ),
    parAprobadorFalso(
      5,
      8,
      'Paredes Limachi Rosa',
      7,
      'Rojas Vargas Luis',
      cargo: 'Responsable de producción',
      rama: 2,
    ),
    rolAprobadorFalso(
      6,
      9,
      'Quispe Mamani Ana',
      cargo: 'Supervisora de almacenes',
      rama: 5,
    ),
    rolAprobadorFalso(
      1,
      7,
      'Rojas Vargas Luis',
      cargo: 'Responsable de producción',
      rama: 2,
    ),
    rolAprobadorFalso(3, 11, 'Mendoza Cruz Pedro', cargo: 'Estibador', rama: 3),
  ];

  /// Todos los casos a la vez, con nombres y cargos largos: jefe sin relación
  /// laboral, par sin rol, rol programado, rol cerrado y rol sin cargo.
  List<HexAprobadorEntity> todosLosCasos() => [
    ...conDosEncargados(),
    parAprobadorFalso(
      7,
      12,
      'Villarroel Saavedra de la Fuente María Alejandra',
      10,
      'Choque Flores Mario',
      cargo: 'Responsable regional de almacenes y distribución de Santa Cruz',
      rama: 1,
      desde: DateTime(2026, 2, 1),
      activo: false,
    ),
    rolAprobadorFalso(
      8,
      13,
      'Gutiérrez Mamani Juan Carlos',
      cargo: 'Encargado de mantenimiento',
      rama: 12,
      desde: hoy.add(const Duration(days: 10)),
      vigente: false,
    ),
    rolAprobadorFalso(
      9,
      14,
      'Torrez Quiroga Ana',
      cargo: 'Operaria',
      desde: DateTime(2025, 1, 1),
      hasta: DateTime(2025, 6, 30),
      vigente: false,
    ),
    rolAprobadorFalso(
      10,
      15,
      'Flores Condori Rubén',
      avisoCargo: 'Sin cargo vigente en el organigrama: no cubre a nadie.',
      activo: false,
    ),
  ];

  Future<void> abrirAsignar(WidgetTester t) => tocar(t, find.text('Asignar'));

  /// Elige el nivel en el selector segmentado del diálogo.
  Future<void> nivel(WidgetTester t, String texto) => tocar(
    t,
    find.descendant(
      of: find.byType(SegmentedButton<int>),
      matching: find.text(texto),
    ),
    fotogramas: 2,
  );

  Future<void> aceptar(WidgetTester t, String accion) async {
    await t.tap(enDialogo(accion));
    await esperar(t, 4);
  }

  /// Abre «Encargados que aprueba» (o la [etiqueta] dada), marca [nombres]
  /// (buscando con [buscar] si viene) y toca «Listo».
  Future<void> elegirEncargados(
    WidgetTester t,
    List<String> nombres, {
    String? buscar,
    String etiqueta = etiquetaEncargadosHex,
  }) async {
    await tocar(t, selector(etiqueta), fotogramas: 2);
    if (buscar != null) {
      await t.enterText(buscador(), buscar);
      await esperar(t, 2);
    }
    for (final n in nombres) {
      await t.tap(find.widgetWithText(CheckboxListTile, n));
      await esperar(t, 1);
    }
    await t.tap(find.widgetWithText(FilledButton, 'Listo'));
    await esperar(t, 3);
  }

  HexAprobadorEntity asignado() =>
      repo.argumentosDe('asignarAprobador').single['aprobador']!
          as HexAprobadorEntity;

  FiltroAprobadoresHex ultimoFiltro() {
    final a = repo.argumentosDe('aprobadores').last;
    expect(a.containsKey('codSucursal'), isFalse);
    return (
      codEmpleado: a['codEmpleado'] as BigInt?,
      nivel: a['nivel'] as int?,
    );
  }

  /// Un rol sin cargo vigente: el SP manda el aviso y una rama vacía.
  final sinCargo = HexAprobadorEntity(
    idAprobador: BigInt.from(3),
    codEmpleadoAprobador: BigInt.from(11),
    nombreAprobador: 'Mendoza Cruz Pedro',
    nivel: 1,
    nivelTexto: 'Encargado',
    avisoCargo: 'Sin cargo vigente en el organigrama: no cubre a nadie.',
    vigenteDesde: DateTime(2026, 2, 1),
    esVigente: true,
    aprobadorActivo: true,
  );

  test('la ayuda de cada rol habla de la rama, no de sucursales', () {
    expect(ayudaEncargadoHex, contains('todos los cargos debajo del suyo'));
    expect(ayudaJefeHex, contains('No depende del organigrama'));
    expect(cantidadRamaHex(1), '1 empleado');
    expect(cantidadRamaHex(12), '12 empleados');
  });

  group('lista agrupada por jefe', () {
    for (final ancho in [390.0, 1400.0]) {
      testWidgets('el jefe aparece una sola vez con sus encargados y la suma '
          'de empleados a $ancho px', (t) async {
        repo.programar('aprobadores', [conDosEncargados()]);
        await montar(t, ancho: ancho);
        expect(find.text('Paredes Limachi Rosa'), findsOneWidget);
        expect(find.text('Jefe de área'), findsOneWidget);
        expect(
          find.text('Aprueba a 2 encargados · 7 empleados'),
          findsOneWidget,
        );
        for (final n in [
          'Quispe Mamani Ana',
          'Rojas Vargas Luis',
          'Mendoza Cruz Pedro',
        ]) {
          expect(nodo(n), findsOneWidget, reason: n);
          expect(find.text(n), findsOneWidget, reason: n);
        }
        expect(find.text('Supervisora de almacenes'), findsOneWidget);
        expect(find.text('Sin jefe de área'), findsOneWidget);
        expect(
          find.text('Ningún jefe de área tiene asignados a estos encargados.'),
          findsOneWidget,
        );
        // Encargados por nombre bajo su jefe; los que no tienen, al final.
        double y(String texto) => t.getTopLeft(find.text(texto)).dy;
        expect(y('Paredes Limachi Rosa'), lessThan(y('Quispe Mamani Ana')));
        expect(y('Quispe Mamani Ana'), lessThan(y('Rojas Vargas Luis')));
        expect(y('Rojas Vargas Luis'), lessThan(y('Sin jefe de área')));
        expect(y('Sin jefe de área'), lessThan(y('Mendoza Cruz Pedro')));
        // «Vigente» no se repite en cada fila.
        expect(find.text('Vigente'), findsNothing);
        if (ancho > 1000) {
          for (final c in ['Encargado', 'Rama', 'Vigencia', 'Estado']) {
            expect(find.text(c), findsNWidgets(2), reason: c);
          }
          expect(find.text('5 empleados'), findsOneWidget);
          expect(find.text('Encargado desde 01/01/2026'), findsNWidgets(3));
        } else {
          expect(find.text('Vigencia'), findsNothing);
          expect(
            find.text('Rama: 5 empleados · Encargado desde 01/01/2026'),
            findsOneWidget,
          );
        }
        await cerrar(t);
      });
    }

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('D45: el observador va aparte, con su chip, y no saca al '
          'encargado de «Sin jefe de área» a $ancho px', (t) async {
        final errores = capturarErrores();
        repo.programar('aprobadores', [
          [
            rolAprobadorFalso(
              1,
              7,
              'Rojas Vargas Luis',
              cargo: 'Responsable de producción',
              rama: 2,
            ),
            observadorAprobadorFalso(
              5,
              12,
              'Aguilar Cuenca Alvaro',
              7,
              'Rojas Vargas Luis',
              cargo: 'Responsable de producción',
              rama: 2,
            ),
          ],
        ]);
        await montar(t, ancho: ancho);
        expect(find.text('Aguilar Cuenca Alvaro'), findsOneWidget);
        expect(find.text('Observador'), findsOneWidget);
        expect(
          find.text('Observa a 1 encargado · 2 empleados'),
          findsOneWidget,
        );
        expect(find.textContaining('Aprueba a'), findsNothing);
        // Rojas sigue sin jefe de área: el observador no lo aprueba.
        expect(find.text('Sin jefe de área'), findsOneWidget);
        expect(find.text('Rojas Vargas Luis'), findsNWidgets(2));
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('los encargados que ningún jefe tiene van en «Sin jefe de '
        'área»', (t) async {
      await montar(t);
      Finder tarjeta(String texto) =>
          find
              .ancestor(of: find.text(texto), matching: find.byType(Card))
              .first;
      final sinJefe = tarjeta('Sin jefe de área');
      expect(
        find.descendant(of: sinJefe, matching: find.text('Rojas Vargas Luis')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sinJefe, matching: find.text('Quispe Mamani Ana')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: tarjeta('Paredes Limachi Rosa'),
          matching: find.text('Quispe Mamani Ana'),
        ),
        findsOneWidget,
      );
      expect(find.text('Aprueba a 1 encargado · 5 empleados'), findsOneWidget);
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('un par sin rol de encargado muestra el aviso a $ancho px', (
        t,
      ) async {
        repo.programar('aprobadores', [
          [aprobadoresFalsos[1]],
        ]);
        await montar(t, ancho: ancho);
        final aviso = find.text(
          'No tiene rol de encargado vigente: no firma a su rama.',
        );
        expect(aviso, findsOneWidget);
        final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
        expect(
          t.widget<Text>(aviso).style?.color,
          HexColores.desde(cs).pendiente,
        );
        // El cargo y la rama salen del par.
        expect(find.text('Supervisora de almacenes'), findsOneWidget);
        expect(
          find.text(
            ancho > 1000
                ? 'Con este jefe desde 01/01/2026'
                : 'Rama: 5 empleados · Con este jefe desde 01/01/2026',
          ),
          findsOneWidget,
        );
        expect(find.text('Sin jefe de área'), findsNothing);
        await cerrar(t);
      });
    }

    testWidgets('si el jefe rige desde otra fecha se ve «Con este jefe '
        'desde»', (t) async {
      repo.programar('aprobadores', [
        [
          parAprobadorFalso(
            2,
            8,
            'Paredes Limachi Rosa',
            9,
            'Quispe Mamani Ana',
            rama: 5,
            desde: DateTime(2026, 3, 1),
          ),
          rolAprobadorFalso(6, 9, 'Quispe Mamani Ana', rama: 5),
        ],
      ]);
      await montar(t, ancho: 390);
      expect(
        find.text(
          'Rama: 5 empleados · Encargado desde 01/01/2026 · Con este jefe '
          'desde 01/03/2026',
        ),
        findsOneWidget,
      );
      await cerrar(t);
      await montar(t);
      expect(find.text('Encargado desde 01/01/2026'), findsOneWidget);
      expect(find.text('Con este jefe desde 01/03/2026'), findsOneWidget);
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('un encargado inactivo se marca a $ancho px', (t) async {
        repo.programar('aprobadores', [
          [
            ...aprobadoresFalsos,
            rolAprobadorFalso(
              3,
              11,
              'Mendoza Cruz Pedro',
              cargo: 'Estibador',
              desde: DateTime(2026, 2, 1),
              hasta: DateTime(2026, 12, 31),
              activo: false,
            ),
          ],
        ]);
        await montar(t, ancho: ancho);
        expect(
          find.text('Sin relación laboral activa: no firma'),
          findsOneWidget,
        );
        await t.ensureVisible(find.text('Mendoza Cruz Pedro'));
        expect(find.textContaining('31/12/2026'), findsOneWidget);
        await cerrar(t);
      });
    }

    testWidgets('un jefe inactivo se marca en su encabezado', (t) async {
      repo.programar('aprobadores', [
        [
          parAprobadorFalso(
            2,
            8,
            'Paredes Limachi Rosa',
            9,
            'Quispe Mamani Ana',
            rama: 5,
            activo: false,
          ),
          rolAprobadorFalso(6, 9, 'Quispe Mamani Ana', rama: 5),
        ],
      ]);
      await montar(t);
      final aviso = find.text('Sin relación laboral activa: no firma');
      expect(aviso, findsOneWidget);
      expect(
        t.getTopLeft(aviso).dy,
        lessThan(t.getTopLeft(find.text('Quispe Mamani Ana')).dy),
      );
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('sin cargo vigente se ve el aviso del SP a $ancho px', (
        t,
      ) async {
        repo.programar('aprobadores', [
          [...aprobadoresFalsos, sinCargo],
        ]);
        await montar(t, ancho: ancho);
        final aviso = find.text(
          'Sin cargo vigente en el organigrama: no cubre a nadie.',
        );
        await t.ensureVisible(aviso);
        expect(aviso, findsOneWidget);
        final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
        expect(
          t.widget<Text>(aviso).style?.color,
          HexColores.desde(cs).pendiente,
        );
        await cerrar(t);
      });
    }

    testWidgets('el filtro de empleado se aplica en la app: el jefe con su '
        'grupo y el encargado con el encabezado de su grupo', (t) async {
      repo.programar('aprobadores', [conDosEncargados()]);
      await montar(t);
      final pedidos = repo.vecesDe('aprobadores');
      expect(ultimoFiltro(), (codEmpleado: null, nivel: null));
      // Ya no se filtra por nivel ni por sucursal (D34).
      expect(find.text('Todos los niveles'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is InputDecorator && w.decoration.labelText == 'Sucursal',
        ),
        findsNothing,
      );

      await elegir(t, 'Empleado', 'Paredes Limachi Rosa', buscar: 'Pare');
      expect(nodo('Quispe Mamani Ana'), findsOneWidget);
      expect(nodo('Rojas Vargas Luis'), findsOneWidget);
      expect(nodo('Mendoza Cruz Pedro'), findsNothing);
      expect(find.text('Sin jefe de área'), findsNothing);

      await elegir(t, 'Empleado', 'Rojas Vargas Luis', buscar: 'Rojas');
      expect(find.text('Aprueba a 2 encargados · 7 empleados'), findsOneWidget);
      expect(nodo('Rojas Vargas Luis'), findsOneWidget);
      expect(nodo('Quispe Mamani Ana'), findsNothing);
      expect(nodo('Mendoza Cruz Pedro'), findsNothing);

      await elegir(t, 'Empleado', 'Choque Flores Mario', buscar: 'Choque');
      expect(find.text('Cambia o quita los filtros.'), findsOneWidget);

      // La «x» del campo quita el filtro.
      await tocar(
        t,
        find.descendant(
          of: selector('Empleado'),
          matching: find.byTooltip('Quitar el filtro'),
        ),
      );
      expect(nodo('Mendoza Cruz Pedro'), findsOneWidget);
      expect(nodo('Quispe Mamani Ana'), findsOneWidget);
      // Todo se filtró en la app: no hubo pedidos nuevos.
      expect(repo.vecesDe('aprobadores'), pedidos);
      expect(ultimoFiltro(), (codEmpleado: null, nivel: null));
      await cerrar(t);
    });

    testWidgets('«Mostrar cerradas» suma las cerradas; las programadas se ven '
        'siempre', (t) async {
      repo.programar('aprobadores', [
        [
          ...aprobadoresFalsos,
          rolAprobadorFalso(
            3,
            11,
            'Mendoza Cruz Pedro',
            rama: 3,
            desde: DateTime(2025, 1, 1),
            hasta: DateTime(2025, 6, 30),
            vigente: false,
          ),
          rolAprobadorFalso(
            4,
            10,
            'Choque Flores Mario',
            rama: 1,
            desde: hoy.add(const Duration(days: 30)),
            vigente: false,
          ),
        ],
      ]);
      await montar(t);
      expect(nodo('Mendoza Cruz Pedro'), findsNothing);
      expect(nodo('Choque Flores Mario'), findsOneWidget);
      expect(find.text('Programada'), findsOneWidget);
      expect(find.text('Cerrada'), findsNothing);

      final interruptor = find.widgetWithText(FilterChip, 'Mostrar cerradas');
      await tocar(t, interruptor);
      expect(nodo('Mendoza Cruz Pedro'), findsOneWidget);
      expect(find.text('Cerrada'), findsOneWidget);
      expect(
        find.text('Encargado desde 01/01/2025 hasta 30/06/2025'),
        findsOneWidget,
      );
      await tocar(t, interruptor);
      expect(nodo('Mendoza Cruz Pedro'), findsNothing);
      await cerrar(t);
    });

    testWidgets('sin datos invita a asignar el primero', (t) async {
      repo.programar('aprobadores', [<HexAprobadorEntity>[]]);
      await montar(t);
      expect(find.text('No hay aprobadores'), findsOneWidget);
      expect(find.text('Asigna el primero con «Asignar».'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un 403 en la lista muestra No tienes permiso', (t) async {
      repo.programar('aprobadores', [const SinPermisoHex('Forbidden')]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('asignar', () {
    testWidgets('el diálogo pide rol, persona y vigencia, sin sucursal ni '
        'encargado, con la ayuda de cada rol', (t) async {
      await montar(t);
      await abrirAsignar(t);
      bool campo(String etiqueta) =>
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is InputDecorator && w.decoration.labelText == etiqueta,
                ),
              )
              .evaluate()
              .isNotEmpty;
      for (final rol in ['Encargado', 'Jefe de área']) {
        await nivel(t, rol);
        // Solo el jefe elige los encargados que aprueba (D35).
        expect(campo(etiquetaEncargadosHex), rol == 'Jefe de área');
        expect(campo('Persona'), isTrue);
        expect(campo('Rige desde'), isTrue);
        expect(campo('Rige hasta'), isTrue);
        expect(campo('Sucursal'), isFalse);
        expect(campo('Encargado'), isFalse);
        expect(campo('Aprobador'), isFalse);
        expect(
          enDialogo(rol == 'Encargado' ? ayudaEncargadoHex : ayudaJefeHex),
          findsOneWidget,
        );
      }
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets('asignar encargado manda solo persona, nivel 1 y vigencia', (
      t,
    ) async {
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      await nivel(t, 'Encargado');
      await elegir(t, 'Persona', 'Quispe Mamani Ana', buscar: 'Quis');
      // «Rige hasta» se elige y se quita: no viaja.
      await elegirDia(t, 'Rige hasta', '15');
      await tocar(t, find.byTooltip('Quitar la fecha'), fotogramas: 2);
      await aceptar(t, 'Asignar');

      final a = asignado();
      expect(a.nivel, 1);
      expect(a.codEmpleadoAprobador, BigInt.from(9));
      expect(a.idAprobador, isNull);
      expect(HexAprobadorModel.fromEntity(a).toJson(), {
        'codEmpleadoAprobador': 9,
        'nivel': 1,
        'vigenteDesde': hexDiaJson(hoy),
      });
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });

    testWidgets('asignar jefe manda nivel 2 con los encargados elegidos', (
      t,
    ) async {
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      await elegir(t, 'Persona', 'Paredes Limachi Rosa');
      await elegirEncargados(t, ['Quispe Mamani Ana', 'Rojas Vargas Luis']);
      expect(repo.vecesDe('encargadosParaJefe'), greaterThan(0));
      expect(enDialogo('2 encargados elegidos'), findsOneWidget);
      await elegirDia(t, 'Rige hasta', '15');
      await aceptar(t, 'Asignar');

      final a = asignado();
      expect(HexAprobadorModel.fromEntity(a).toJson(), {
        'codEmpleadoAprobador': 8,
        'nivel': 2,
        // En el orden del SP, no en el de los toques.
        'codEmpleadosAprobados': [7, 9],
        'vigenteDesde': hexDiaJson(hoy),
        'vigenteHasta': hexDiaJson(DateTime(hoy.year, hoy.month, 15)),
      });
      await cerrar(t);
    });

    testWidgets('D45: asignar observador manda nivel 3 con los encargados '
        'elegidos', (t) async {
      final errores = capturarErrores();
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Observador');
      expect(enDialogo(ayudaObservadorHex), findsOneWidget);
      expect(
        enDialogo(
          'El observador ve los reportes y su historial de los encargados que '
          'se le asignan; no firma ni aprueba.',
        ),
        findsOneWidget,
      );
      // Pide encargados, con su propia etiqueta.
      expect(selector(etiquetaEncargadosObservadorHex), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is InputDecorator &&
              w.decoration.labelText == etiquetaEncargadosHex,
        ),
        findsNothing,
      );
      await elegir(t, 'Persona', 'Paredes Limachi Rosa');
      await elegirEncargados(t, [
        'Quispe Mamani Ana',
        'Rojas Vargas Luis',
      ], etiqueta: etiquetaEncargadosObservadorHex);
      expect(enDialogo('2 encargados elegidos'), findsOneWidget);
      await aceptar(t, 'Asignar');

      final cuerpo = HexAprobadorModel.fromEntity(asignado()).toJson();
      expect(cuerpo, {
        'codEmpleadoAprobador': 8,
        'nivel': 3,
        'codEmpleadosAprobados': [7, 9],
        'vigenteDesde': hexDiaJson(hoy),
      });
      // La identidad no viaja: solo la persona elegida y los encargados.
      expect(
        cuerpo.keys.toSet().intersection({
          'audUsuario',
          'codUsuario',
          'codEmpleado',
          'tipoUsuario',
        }),
        isEmpty,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('D45: los tres roles caben en el teléfono y el campo de '
        'encargados cambia con el rol', (t) async {
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await abrirAsignar(t);
      for (final rol in ['Encargado', 'Jefe de área', 'Observador']) {
        expect(
          find.descendant(
            of: find.byType(SegmentedButton<int>),
            matching: find.text(rol),
          ),
          findsOneWidget,
          reason: rol,
        );
      }
      await nivel(t, 'Observador');
      expect(selector(etiquetaEncargadosObservadorHex), findsOneWidget);
      await nivel(t, 'Jefe de área');
      expect(selector(etiquetaEncargadosHex), findsOneWidget);
      await nivel(t, 'Encargado');
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is InputDecorator &&
              (w.decoration.labelText == etiquetaEncargadosHex ||
                  w.decoration.labelText == etiquetaEncargadosObservadorHex),
        ),
        findsNothing,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets('el buscador de encargados muestra cargo, rama y quién ya los '
        'aprueba, busca sin tildes y conserva lo marcado', (t) async {
      final errores = capturarErrores();
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      await tocar(t, selector(etiquetaEncargadosHex), fotogramas: 2);
      Finder enBuscador(Finder f) =>
          find.descendant(of: find.byType(Dialog).last, matching: f);
      expect(
        enBuscador(find.text('Supervisora de almacenes · 5 empleados')),
        findsOneWidget,
      );
      expect(
        enBuscador(find.text('Responsable de producción · 2 empleados')),
        findsOneWidget,
      );
      expect(
        enBuscador(find.text('Ya lo aprueba: Paredes Limachi Rosa')),
        findsOneWidget,
      );
      await t.enterText(buscador(), 'produccion');
      await esperar(t, 2);
      expect(
        find.widgetWithText(CheckboxListTile, 'Quispe Mamani Ana'),
        findsNothing,
      );
      await t.tap(find.widgetWithText(CheckboxListTile, 'Rojas Vargas Luis'));
      await esperar(t, 1);
      expect(enBuscador(find.text('1 elegido')), findsOneWidget);
      // Cancelar no cambia la selección.
      await t.tap(enBuscador(find.text('Cancelar')));
      await esperar(t, 2);
      expect(enDialogo('Elige uno o más'), findsOneWidget);

      await elegirEncargados(t, ['Quispe Mamani Ana']);
      expect(enDialogo('Ya lo aprueba: Paredes Limachi Rosa'), findsOneWidget);
      // Al volver a abrirlo, lo elegido sigue marcado.
      await tocar(t, selector(etiquetaEncargadosHex), fotogramas: 2);
      expect(
        t
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Quispe Mamani Ana'),
            )
            .value,
        isTrue,
      );
      await t.tap(enBuscador(find.text('Cancelar')));
      await esperar(t, 2);
      expect(errores, isEmpty, reason: detalle(errores));
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets('la «x» quita un encargado y «Quitar todos» los quita', (
      t,
    ) async {
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      await elegir(t, 'Persona', 'Paredes Limachi Rosa');
      await elegirEncargados(t, ['Rojas Vargas Luis', 'Quispe Mamani Ana']);
      await tocar(t, find.byTooltip('Quitar a Rojas Vargas Luis'));
      expect(enDialogo('1 encargado elegido'), findsOneWidget);
      await tocar(t, find.byTooltip('Quitar todos'));
      expect(enDialogo('Elige uno o más'), findsOneWidget);
      expect(find.byTooltip('Quitar a Quispe Mamani Ana'), findsNothing);
      await elegirEncargados(t, ['Quispe Mamani Ana']);
      await aceptar(t, 'Asignar');
      expect(asignado().codEmpleadosAprobados, [BigInt.from(9)]);
      await cerrar(t);
    });

    testWidgets('el encargado no manda los encargados elegidos como jefe', (
      t,
    ) async {
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      await elegirEncargados(t, ['Rojas Vargas Luis']);
      await nivel(t, 'Encargado');
      await elegir(t, 'Persona', 'Quispe Mamani Ana');
      await aceptar(t, 'Asignar');
      expect(
        HexAprobadorModel.fromEntity(
          asignado(),
        ).toJson().containsKey('codEmpleadosAprobados'),
        isFalse,
      );
      await cerrar(t);
    });

    testWidgets('si los encargados no cargan se puede reintentar', (t) async {
      repo.programar('encargadosParaJefe', [
        Exception('sin red'),
        encargadosFalsos,
      ]);
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      expect(enDialogo('No se pudieron cargar los encargados'), findsOneWidget);
      await tocar(t, selector(etiquetaEncargadosHex));
      expect(enDialogo('Elige uno o más'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un 403 en los encargados dice No tienes permiso', (t) async {
      repo.programar('encargadosParaJefe', [const SinPermisoHex('Forbidden')]);
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      expect(enDialogo('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin encargados con rol el buscador lo dice', (t) async {
      repo.programar('encargadosParaJefe', [<HexEncargadoOpcionEntity>[]]);
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      await tocar(t, selector(etiquetaEncargadosHex), fotogramas: 2);
      expect(
        find.text('Nadie tiene rol de encargado: asígnalo primero.'),
        findsOneWidget,
      );
      await cerrar(t);
    });

    testWidgets('el mensaje de éxito del SP se muestra tal cual', (t) async {
      const exito =
          'Rojas Vargas Luis es encargado de su rama: 2 empleados activos, '
          'desde el 04/11/2026.';
      repo.programar('asignarAprobador', [
        (id: BigInt.from(9), mensaje: exito),
      ]);
      await montar(t);
      await abrirAsignar(t);
      await elegir(t, 'Persona', 'Rojas Vargas Luis');
      await aceptar(t, 'Asignar');
      expect(aviso(exito), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('el error 40 del SP se muestra tal cual y el diálogo sigue', (
      t,
    ) async {
      const mensaje =
          'No puedes asignar un rol a alguien de quien dependes: esa persona '
          'firmaría tus reportes. Pide a otra persona de RRHH que la registre.';
      repo.programar('asignarAprobador', [const NegocioHex(mensaje)]);
      await montar(t);
      await abrirAsignar(t);
      await elegir(t, 'Persona', 'Rojas Vargas Luis');
      await aceptar(t, 'Asignar');
      expect(aviso(mensaje), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un 403 al asignar dice que no tienes permiso', (t) async {
      repo.programar('asignarAprobador', [const SinPermisoHex('Forbidden')]);
      await montar(t);
      await abrirAsignar(t);
      await aceptar(t, 'Asignar');
      expect(aviso('No tienes permiso para esta acción.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('doble toque en Asignar manda un solo pedido', (t) async {
      final pausa = Completer<void>();
      repo.pausa = pausa;
      await montar(t);
      await abrirAsignar(t);
      await elegir(t, 'Persona', 'Rojas Vargas Luis');
      await t.tap(enDialogo('Asignar'));
      await t.pump();
      await t.tap(enDialogo('Asignar'), warnIfMissed: false);
      await esperar(t, 1);
      // Mientras escribe, el «atrás» no cierra el diálogo.
      await Navigator.of(t.element(find.byType(AlertDialog))).maybePop();
      await esperar(t, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repo.vecesDe('asignarAprobador'), 1);
      pausa.complete();
      await esperar(t, 3);
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });

    testWidgets('tras asignar se recargan la lista y el historial', (t) async {
      await montar(t);
      final lista = repo.vecesDe('aprobadores');
      final historial = repo.vecesDe('historial');
      await abrirAsignar(t);
      await elegir(t, 'Persona', 'Rojas Vargas Luis');
      await aceptar(t, 'Asignar');
      expect(repo.vecesDe('aprobadores'), lista + 1);
      expect(repo.vecesDe('historial'), historial + 1);
      expect(aviso('Listo.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('si la agenda no carga se puede reintentar', (t) async {
      var veces = 0;
      await montar(
        t,
        leerAgenda: () async {
          veces++;
          if (veces == 1) throw Exception('sin red');
          return agenda;
        },
      );
      await abrirAsignar(t);
      // La persona sale de la agenda: es el único campo que la usa.
      expect(enDialogo('No se pudo cargar la agenda'), findsOneWidget);
      await tocar(t, selector('Persona'));
      expect(veces, 2);
      await elegir(t, 'Persona', 'Rojas Vargas Luis');
      expect(enDialogo('Rojas Vargas Luis'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('vista previa de la rama', () {
    const resumen =
        'Cargo: Jefe comercial y de producción · 3 empleados en 2 sucursales';
    const vacia = 'No tiene a nadie en su rama.';

    bool hayPlegable() =>
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(ExpansionTile),
            )
            .evaluate()
            .isNotEmpty;

    testWidgets('en el ancho va a la derecha del formulario, en árbol, y se '
        'recarga al cambiar de persona', (t) async {
      final errores = capturarErrores();
      await montar(t);
      await abrirAsignar(t);
      expect(enDialogo(tituloVistaPreviaRamaHex), findsOneWidget);
      expect(repo.vecesDe('ramaAprobador'), 0);

      await elegir(t, 'Persona', 'Rojas Vargas Luis');
      expect(repo.argumentosDe('ramaAprobador'), [
        {'codEmpleado': BigInt.from(7)},
      ]);
      expect(enDialogo(resumen), findsOneWidget);
      expect(enDialogo(notaVistaPreviaRamaHex), findsOneWidget);
      expect(
        enDialogo('Responsable de distribución › Chofer B › Estibador'),
        findsOneWidget,
      );
      expect(
        enDialogo('Quién firma hoy: Sin aprobador en su rama'),
        findsOneWidget,
      );
      // Orden de árbol del SP, sin reordenar.
      double y(String nombre) => t.getTopLeft(enDialogo(nombre)).dy;
      expect(y('Vargas Ruiz Eva'), lessThan(y('Mamani Cruz Rubén')));
      expect(y('Mamani Cruz Rubén'), lessThan(y('Choque Flores Mario')));
      // Dos columnas: la vista previa empieza a la derecha del campo.
      expect(
        t.getTopLeft(enDialogo(tituloVistaPreviaRamaHex)).dx,
        greaterThan(t.getTopRight(selector('Persona')).dx),
      );
      expect(hayPlegable(), isFalse);

      await elegir(t, 'Persona', 'Paredes Limachi Rosa');
      expect(repo.argumentosDe('ramaAprobador').last, {
        'codEmpleado': BigInt.from(8),
      });
      expect(repo.vecesDe('ramaAprobador'), 2);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await cerrar(t);
    });

    for (final escala in [1.0, 1.5]) {
      testWidgets('en el teléfono va bajo el formulario y se pliega '
          '(letra $escala)', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montar(t, ancho: 390);
        await abrirAsignar(t);
        expect(enDialogo(tituloVistaPreviaRamaHex), findsNothing);

        await elegir(t, 'Persona', 'Quispe Mamani Ana');
        expect(repo.argumentosDe('ramaAprobador').single, {
          'codEmpleado': BigInt.from(9),
        });
        expect(hayPlegable(), isTrue);
        expect(enDialogo(resumen), findsOneWidget);
        expect(
          enDialogo(
            'Quién firma hoy: Visto bueno: Rojas Vargas Luis · Aprueba: '
            'Paredes Limachi Rosa',
          ),
          findsOneWidget,
        );
        expect(find.byWidgetPredicate(esLateral), findsNothing);

        await tocar(t, enDialogo(tituloVistaPreviaRamaHex), fotogramas: 4);
        expect(enDialogo(resumen), findsNothing);
        await tocar(t, enDialogo(tituloVistaPreviaRamaHex), fotogramas: 4);
        expect(enDialogo(resumen), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
        await cerrar(t);
      });
    }

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('sin nadie en la rama lo dice a $ancho px', (t) async {
        repo.programar('ramaAprobador', [<HexRamaEmpleadoEntity>[]]);
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await abrirAsignar(t);
        await elegir(t, 'Persona', 'Choque Flores Mario');
        expect(enDialogo(vacia), findsOneWidget);
        expect(
          enDialogo(
            'Si no tiene un cargo vigente en el organigrama, pide a RRHH que '
            'lo revise.',
          ),
          findsOneWidget,
        );
        expect(enDialogo(notaVistaPreviaRamaHex), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
        await cerrar(t);
      });
    }

    testWidgets('un 403 en la vista previa dice No tienes permiso y Asignar '
        'sigue a mano', (t) async {
      repo.programar('ramaAprobador', [const SinPermisoHex('Forbidden')]);
      await montar(t);
      await abrirAsignar(t);
      await elegir(t, 'Persona', 'Rojas Vargas Luis');
      expect(enDialogo('No tienes permiso'), findsOneWidget);
      await aceptar(t, 'Asignar');
      expect(asignado().codEmpleadoAprobador, BigInt.from(7));
      await cerrar(t);
    });

    /// La sección plegable de la rama de [nombre] en el diálogo.
    Finder seccion(String nombre) => find.ancestor(
      of: enDialogo('Rama de $nombre'),
      matching: find.byType(ExpansionTile),
    );

    testWidgets('jefe en el ancho: a la derecha, una rama por encargado '
        'elegido, sin pedir la del jefe (D35)', (t) async {
      final errores = capturarErrores();
      await montar(t);
      await abrirAsignar(t);
      await nivel(t, 'Jefe de área');
      expect(enDialogo(tituloVistaPreviaRamasJefeHex), findsOneWidget);
      expect(
        enDialogo(
          'Elige uno o más encargados para ver su rama y quién firma hoy a '
          'cada empleado.',
        ),
        findsOneWidget,
      );
      await elegir(t, 'Persona', 'Paredes Limachi Rosa');
      // El jefe no tiene rama: no se pide la suya.
      expect(repo.vecesDe('ramaAprobador'), 0);

      await elegirEncargados(t, ['Rojas Vargas Luis', 'Quispe Mamani Ana']);
      expect(
        repo.argumentosDe('ramaAprobador').map((a) => a['codEmpleado']).toSet(),
        {BigInt.from(7), BigInt.from(9)},
      );
      // La lista de la derecha arma solo lo que está a la vista: se desplaza.
      final lateral =
          find
              .ancestor(
                of: enDialogo('Rama de Rojas Vargas Luis'),
                matching: find.byType(Scrollable),
              )
              .first;
      for (final n in ['Rojas Vargas Luis', 'Quispe Mamani Ana']) {
        await t.scrollUntilVisible(
          enDialogo('Rama de $n'),
          200,
          scrollable: lateral,
        );
        await esperar(t, 2);
        expect(seccion(n), findsOneWidget, reason: n);
        expect(
          find.descendant(of: seccion(n), matching: find.text(resumen)),
          findsOneWidget,
          reason: n,
        );
      }
      expect(
        find.descendant(
          of: seccion('Quispe Mamani Ana'),
          matching: find.text('Supervisora de almacenes · 5 empleados'),
        ),
        findsOneWidget,
      );
      // Dos columnas: las ramas empiezan a la derecha del formulario.
      expect(
        t.getTopLeft(enDialogo(tituloVistaPreviaRamasJefeHex)).dx,
        greaterThan(t.getTopRight(selector('Persona')).dx),
      );
      expect(enDialogo(tituloVistaPreviaRamaHex), findsNothing);

      // Al quitar un encargado se va su rama.
      await tocar(t, find.byTooltip('Quitar a Rojas Vargas Luis'));
      expect(seccion('Rojas Vargas Luis'), findsNothing);
      expect(seccion('Quispe Mamani Ana'), findsOneWidget);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await cerrar(t);
    });

    for (final escala in [1.0, 1.5]) {
      testWidgets('jefe en el teléfono: cada rama bajo el formulario, '
          'plegable (letra $escala)', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montar(t, ancho: 390);
        await abrirAsignar(t);
        await nivel(t, 'Jefe de área');
        expect(enDialogo(tituloVistaPreviaRamasJefeHex), findsNothing);
        await elegirEncargados(t, ['Rojas Vargas Luis', 'Quispe Mamani Ana']);
        expect(enDialogo(tituloVistaPreviaRamasJefeHex), findsOneWidget);
        expect(seccion('Rojas Vargas Luis'), findsOneWidget);
        expect(seccion('Quispe Mamani Ana'), findsOneWidget);
        expect(enDialogo(resumen), findsNWidgets(2));

        // Se pliega una sola: la otra sigue abierta.
        await tocar(t, enDialogo('Rama de Rojas Vargas Luis'), fotogramas: 4);
        expect(
          find.descendant(
            of: seccion('Rojas Vargas Luis'),
            matching: find.text(resumen),
          ),
          findsNothing,
        );
        expect(enDialogo(resumen), findsOneWidget);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
        await cerrar(t);
      });
    }
  });

  group('cerrar y eliminar', () {
    testWidgets('cerrar la aprobación del jefe sin fecha manda el id del par '
        'sin vigenteHasta', (t) async {
      await montar(t);
      await accionDe(t, 'Quispe Mamani Ana', 'Cerrar aprobación del jefe');
      expect(enDialogo('Sin fecha: deja de regir hoy'), findsOneWidget);
      await aceptar(t, 'Cerrar asignación');
      expect(repo.argumentosDe('cerrarAprobador').single, {
        'id': BigInt.two,
        'vigenteHasta': null,
      });
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });

    testWidgets('cerrar el rol de encargado con fecha manda el id del rol y '
        'ese día', (t) async {
      await montar(t);
      await accionDe(t, 'Quispe Mamani Ana', 'Cerrar rol de encargado');
      await elegirDia(t, 'Rige hasta', '15');
      await aceptar(t, 'Cerrar asignación');
      expect(repo.argumentosDe('cerrarAprobador').single, {
        'id': BigInt.from(6),
        'vigenteHasta': DateTime(hoy.year, hoy.month, 15),
      });
      await cerrar(t);
    });

    testWidgets('en el teléfono el menú cierra el rol de un encargado sin '
        'jefe', (t) async {
      await montar(t, ancho: 390);
      await accionDe(t, 'Rojas Vargas Luis', 'Cerrar rol de encargado');
      await aceptar(t, 'Cerrar asignación');
      expect(repo.argumentosDe('cerrarAprobador').single, {
        'id': BigInt.one,
        'vigenteHasta': null,
      });
      await cerrar(t);
    });

    testWidgets('el mensaje del SP al cerrar se muestra tal cual', (t) async {
      const mensaje = 'La asignación ya terminó el 31/12/2025.';
      repo.programar('cerrarAprobador', [const NegocioHex(mensaje)]);
      await montar(t);
      await accionDe(t, 'Quispe Mamani Ana', 'Cerrar aprobación del jefe');
      await aceptar(t, 'Cerrar asignación');
      expect(aviso(mensaje), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('eliminar la aprobación del jefe confirma y manda solo el id '
        'del par; mientras, no se repite', (t) async {
      final pausa = Completer<void>();
      repo.pausa = pausa;
      await montar(t);
      await accionDe(t, 'Quispe Mamani Ana', 'Eliminar aprobación del jefe');
      expect(enDialogo('Eliminar asignación'), findsOneWidget);
      await t.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await esperar(t, 2);
      expect(repo.argumentosDe('eliminarAprobador').single, {'id': BigInt.two});
      // Con la eliminación en curso las acciones quedan deshabilitadas.
      await tocar(
        t,
        find.descendant(
          of: nodo('Quispe Mamani Ana'),
          matching: find.byTooltip('Acciones'),
        ),
        fotogramas: 2,
      );
      for (final accion in [
        'Eliminar aprobación del jefe',
        'Eliminar rol de encargado',
      ]) {
        final item = t.widget<PopupMenuItem<int>>(
          find.ancestor(
            of: find.text(accion).last,
            matching: find.byType(PopupMenuItem<int>),
          ),
        );
        expect(item.enabled, isFalse, reason: accion);
      }
      await t.tapAt(const Offset(5, 5));
      await esperar(t, 2);
      pausa.complete();
      await esperar(t, 3);
      expect(repo.vecesDe('eliminarAprobador'), 1);
      await cerrar(t);
    });

    testWidgets('eliminar el rol de encargado manda el id del rol', (t) async {
      await montar(t);
      await accionDe(t, 'Quispe Mamani Ana', 'Eliminar rol de encargado');
      await t.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await esperar(t, 3);
      expect(repo.argumentosDe('eliminarAprobador').single, {
        'id': BigInt.from(6),
      });
      await cerrar(t);
    });

    testWidgets('el mensaje del SP al eliminar se muestra tal cual', (t) async {
      const mensaje =
          'Solo se elimina una asignación de hoy o futura sin firmas.';
      repo.programar('eliminarAprobador', [const NegocioHex(mensaje)]);
      await montar(t);
      await accionDe(t, 'Rojas Vargas Luis', 'Eliminar rol de encargado');
      await t.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await esperar(t, 3);
      expect(aviso(mensaje), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('el menú ofrece solo las acciones de las filas que hay', (
      t,
    ) async {
      await montar(t);
      expect(await menuDe(t, 'Quispe Mamani Ana'), [
        'Cerrar aprobación del jefe',
        'Eliminar aprobación del jefe',
        'Cerrar rol de encargado',
        'Eliminar rol de encargado',
      ]);
      expect(await menuDe(t, 'Rojas Vargas Luis'), [
        'Cerrar rol de encargado',
        'Eliminar rol de encargado',
      ]);
      await cerrar(t);

      repo.programar('aprobadores', [
        [aprobadoresFalsos[1]],
      ]);
      await montar(t);
      expect(await menuDe(t, 'Quispe Mamani Ana'), [
        'Cerrar aprobación del jefe',
        'Eliminar aprobación del jefe',
      ]);
      await cerrar(t);
    });
  });

  group('ver rama', () {
    Finder enPanel(Finder f) => find.descendant(
      of: find.byWidgetPredicate((w) => w is Dialog || w is BottomSheet),
      matching: f,
    );

    testWidgets('en el ancho es una tabla con Empleado, Cargo, Sucursal y '
        'Quién firma; sale del rol del encargado', (t) async {
      final errores = capturarErrores();
      await montar(t);
      await accionDe(t, 'Quispe Mamani Ana', 'Ver rama');
      expect(repo.argumentosDe('ramaAprobador').single, {
        'codEmpleado': BigInt.from(9),
      });
      expect(find.byType(Dialog), findsOneWidget);
      expect(enPanel(find.text('Rama de Quispe Mamani Ana')), findsOneWidget);
      expect(
        enPanel(
          find.text('Encargado · Supervisora de almacenes · 5 empleados'),
        ),
        findsOneWidget,
      );
      for (final c in ['Empleado', 'Cargo', 'Sucursal', 'Quién firma']) {
        expect(enPanel(find.text(c)), findsOneWidget, reason: c);
      }
      for (final e in ramaFalsa) {
        expect(enPanel(find.text(e.textoFirma)), findsOneWidget);
        expect(enPanel(find.text(e.nombreEmpleado)), findsOneWidget);
      }
      expect(enPanel(find.text('Depende directo')), findsOneWidget);
      expect(enPanel(find.text('Almacén Central')), findsNWidgets(2));
      // Orden de árbol del SP y la ruta de cargos cuando hay cargos en medio.
      expect(
        enPanel(
          find.text('Responsable de distribución › Chofer B › Estibador'),
        ),
        findsOneWidget,
      );
      expect(enPanel(find.text('Ejecutivo comercial')), findsOneWidget);
      double y(String nombre) => t.getTopLeft(enPanel(find.text(nombre))).dy;
      expect(y('Vargas Ruiz Eva'), lessThan(y('Mamani Cruz Rubén')));
      expect(y('Mamani Cruz Rubén'), lessThan(y('Choque Flores Mario')));
      expect(enPanel(find.byType(Card)), findsNothing);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      // Sin aprobador en su rama: en ámbar y con el ícono de aviso.
      final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
      expect(
        t
            .widget<Text>(enPanel(find.text('Sin aprobador en su rama')))
            .style
            ?.color,
        HexColores.desde(cs).pendiente,
      );
      await tocar(t, find.byTooltip('Cerrar'));
      expect(find.byType(Dialog), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('sin rol de encargado la rama sale del par (D35)', (t) async {
      repo.programar('aprobadores', [
        [aprobadoresFalsos[1]],
      ]);
      await montar(t);
      await accionDe(t, 'Quispe Mamani Ana', 'Ver rama');
      expect(repo.argumentosDe('ramaAprobador').single, {
        'codEmpleado': BigInt.from(9),
      });
      expect(
        enPanel(
          find.text(
            'Jefe de área: Paredes Limachi Rosa · Aprueba lo que firma '
            'Quispe Mamani Ana (5 empleados)',
          ),
        ),
        findsOneWidget,
      );
      await cerrar(t);
    });

    for (final escala in [1.0, 1.5]) {
      testWidgets('en el teléfono son tarjetas en una hoja (letra $escala)', (
        t,
      ) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montar(t, ancho: 390);
        await accionDe(t, 'Rojas Vargas Luis', 'Ver rama');
        expect(repo.argumentosDe('ramaAprobador').single, {
          'codEmpleado': BigInt.from(7),
        });
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(enPanel(find.text('Rama de Rojas Vargas Luis')), findsOneWidget);
        expect(enPanel(find.byType(Card)), findsNWidgets(ramaFalsa.length));
        expect(enPanel(find.text('Quién firma')), findsNothing);
        expect(
          enPanel(
            find.text(
              'Responsable de distribución › Chofer B › Estibador · '
              'Almacén Central · A 3 niveles',
            ),
          ),
          findsOneWidget,
        );
        expect(
          enPanel(
            find.text(
              'Visto bueno: Rojas Vargas Luis · Aprueba: Paredes Limachi Rosa',
            ),
          ),
          findsOneWidget,
        );
        expect(
          enPanel(
            find.text(
              'Aprueba directo: Paredes Limachi Rosa (sin encargado en su '
              'rama)',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('sin empleados dice que no tiene a nadie a $ancho px', (
        t,
      ) async {
        repo
          ..programar('aprobadores', [
            [sinCargo],
          ])
          ..programar('ramaAprobador', [<HexRamaEmpleadoEntity>[]]);
        await montar(t, ancho: ancho);
        await accionDe(t, 'Mendoza Cruz Pedro', 'Ver rama');
        expect(
          enPanel(find.text('No tiene a nadie en su rama.')),
          findsOneWidget,
        );
        // El aviso del SP también va en la cabecera del panel.
        expect(
          enPanel(
            find.text('Sin cargo vigente en el organigrama: no cubre a nadie.'),
          ),
          findsOneWidget,
        );
        await cerrar(t);
      });
    }

    testWidgets('un jefe sin encargado no ofrece Ver rama', (t) async {
      repo.programar('aprobadores', [
        [
          HexAprobadorEntity(
            idAprobador: BigInt.from(5),
            codEmpleadoAprobador: BigInt.from(8),
            nombreAprobador: 'Paredes Limachi Rosa',
            nivel: 2,
            nivelTexto: 'Jefe de área',
            vigenteDesde: DateTime(2026, 1, 1),
            esVigente: true,
            aprobadorActivo: true,
          ),
        ],
      ]);
      await montar(t);
      await t.tap(find.byTooltip('Ver rama'), warnIfMissed: false);
      await esperar(t, 3);
      expect(find.byType(Dialog), findsNothing);
      expect(repo.vecesDe('ramaAprobador'), 0);
      await cerrar(t);
    });

    testWidgets('un 403 en la rama dice No tienes permiso', (t) async {
      repo.programar('ramaAprobador', [const SinPermisoHex('Forbidden')]);
      await montar(t);
      await accionDe(t, 'Rojas Vargas Luis', 'Ver rama');
      expect(enPanel(find.text('No tienes permiso')), findsOneWidget);
      await cerrar(t);
    });
  });

  group('permisos', () {
    const escrituras = [
      'Cerrar aprobación del jefe',
      'Eliminar aprobación del jefe',
      'Cerrar rol de encargado',
      'Eliminar rol de encargado',
    ];

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('sin btnHexEditarAprobador no hay cerrar ni eliminar a '
          '$ancho px', (t) async {
        await montar(t, ancho: ancho, botones: {});
        expect(nodo('Rojas Vargas Luis'), findsOneWidget);
        expect(find.text('Asignar'), findsNothing);
        expect(find.byTooltip('Acciones'), findsNothing);
        for (final a in escrituras) {
          expect(find.byTooltip(a), findsNothing, reason: a);
          expect(find.text(a), findsNothing, reason: a);
        }
        // «Ver rama» es lectura: la tiene quien ve la lista.
        expect(find.byTooltip('Ver rama'), findsNWidgets(2));
        await cerrar(t);
      });
    }

    testWidgets('con btnHexEditarAprobador hay menú en cada encargado', (
      t,
    ) async {
      await montar(t, botones: {BotonHex.editarAprobador});
      expect(find.text('Asignar'), findsOneWidget);
      expect(find.byTooltip('Ver rama'), findsNWidgets(2));
      expect(find.byTooltip('Acciones'), findsNWidgets(2));
      await accionDe(t, 'Rojas Vargas Luis', 'Cerrar rol de encargado');
      expect(enDialogo('Fin de la asignación'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('historial de cambios', () {
    testWidgets('pide la entidad APROBADOR y muestra los textos del SP', (
      t,
    ) async {
      await montar(t);
      final f =
          repo.argumentosDe('historial').last['filtro']! as FiltroHistorialHex;
      expect(f.entidad, EntidadConfiguracionHex.aprobador);
      expect(f.pagina, 1);
      expect(find.text('Historial de cambios'), findsOneWidget);
      expect(find.text('Asignación nueva'), findsOneWidget);
      expect(
        find.text('Rojas Vargas Luis · Responsable de producción'),
        findsOneWidget,
      );
      expect(find.text('Salazar Rivera Jorge'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('ficha del jefe de área (R10)', () {
    Color colorDeTexto(WidgetTester t, Finder f) =>
        t.widget<Text>(f).style!.color!;

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('a $ancho px el jefe lleva su ficha con ícono en tertiary', (
        t,
      ) async {
        await montar(t, ancho: ancho);
        final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
        final jefe = find.ancestor(
          of: find.text('Jefe de área'),
          matching: find.byType(ChipHex),
        );
        expect(jefe, findsOneWidget);
        expect(
          find.descendant(
            of: jefe,
            matching: find.byIcon(Icons.supervisor_account_outlined),
          ),
          findsOneWidget,
        );
        expect(
          colorDeTexto(t, find.text('Jefe de área')),
          cs.onTertiaryContainer,
        );
        // La ficha va junto al nombre del jefe, no en cada encargado.
        expect(
          t.getTopLeft(find.text('Jefe de área')).dy,
          lessThan(t.getTopLeft(find.text('Quispe Mamani Ana')).dy),
        );
        await cerrar(t);
      });
    }

    testWidgets('un nivel sin texto no muestra «null»', (t) async {
      repo.programar('aprobadores', [
        [
          HexAprobadorEntity(
            idAprobador: BigInt.from(9),
            codEmpleadoAprobador: BigInt.from(8),
            nombreAprobador: 'Paredes Limachi Rosa',
            nivel: 2,
            nivelTexto: 'null',
            codEmpleadoAprobado: BigInt.from(9),
            nombreAprobado: 'Quispe Mamani Ana',
            vigenteDesde: DateTime(2026, 1, 1),
            esVigente: true,
            aprobadorActivo: true,
          ),
        ],
      ]);
      await montar(t);
      expect(find.text('null'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ChipHex),
          matching: find.byIcon(Icons.supervisor_account_outlined),
        ),
        findsOneWidget,
      );
      await cerrar(t);
    });
  });

  group('barra de estado y vibración', () {
    testWidgets('el desplazamiento es el primario: tocar la barra de estado '
        'en iOS sube al inicio', (t) async {
      await montar(t, ancho: 390);
      verificarControlPrimarioHex(t, HexAprobadoresScreen);
      await cerrar(t);
    });
  });

  group('anchos', () {
    // 964 px: una laptop de 1280 con el menú lateral de 268.
    for (final ancho in [390.0, 800.0, 964.0, 1400.0]) {
      testWidgets('Aprobadores a $ancho px sin desbordes', (t) async {
        final errores = capturarErrores();
        repo.programar('aprobadores', [todosLosCasos()]);
        await montar(t, ancho: ancho);
        final relleno = ancho < 600 ? 12 : 24;
        final columnas = ancho - 2 * relleno >= anchoColumnasAprobadoresHex;
        expect(find.text('Vigencia'), columnas ? findsWidgets : findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        if (!columnas) {
          // Un solo desplazamiento vertical: los grupos cuelgan de él.
          expect(find.byWidgetPredicate(esVertical), findsOneWidget);
          expect(find.text('Filtros'), findsOneWidget);
          await tocar(t, find.text('Filtros'), fotogramas: 2);
        }
        await tocar(t, find.widgetWithText(FilterChip, 'Mostrar cerradas'));
        expect(nodo('Torrez Quiroga Ana'), findsOneWidget);
        expect(find.text('Cerrada'), findsOneWidget);
        expect(find.text('Programada'), findsOneWidget);
        expect(
          find.text('No tiene rol de encargado vigente: no firma a su rama.'),
          findsOneWidget,
        );
        expect(
          find.text('Sin relación laboral activa: no firma'),
          findsNWidgets(2),
        );
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        await abrirAsignar(t);
        await nivel(t, 'Jefe de área');
        await elegirEncargados(t, ['Quispe Mamani Ana']);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('apilados un píxel antes del mínimo y en columnas desde él', (
      t,
    ) async {
      // El relleno de la pantalla es de 24 px por lado desde 600 px.
      final borde = anchoColumnasAprobadoresHex + 2 * 24;
      await montar(t, ancho: borde - 1);
      expect(find.text('Vigencia'), findsNothing);
      await cerrar(t);
      await montar(t, ancho: borde);
      expect(find.text('Vigencia'), findsWidgets);
      await cerrar(t);
    });

    testWidgets('Aprobadores al 150 % en 390 px sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      repo.programar('aprobadores', [todosLosCasos()]);
      await montar(t, ancho: 390);
      await tocar(t, find.text('Filtros'), fotogramas: 2);
      await tocar(t, find.widgetWithText(FilterChip, 'Mostrar cerradas'));
      await abrirAsignar(t);
      await elegirDia(t, 'Rige hasta', '15');
      await nivel(t, 'Jefe de área');
      await elegirEncargados(t, ['Quispe Mamani Ana', 'Rojas Vargas Luis']);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await accionDe(t, 'Quispe Mamani Ana', 'Cerrar aprobación del jefe');
      await elegirDia(t, 'Rige hasta', '15');
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await t.scrollUntilVisible(
        find.text('Historial de cambios'),
        200,
        scrollable:
            find
                .ancestor(
                  of: find.text('Aprobadores'),
                  matching: find.byType(Scrollable),
                )
                .first,
      );
      await esperar(t, 2);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    for (final escala in [1.0, 1.5]) {
      testWidgets('con el teclado abierto en 390x741 y AppBar al $escala', (
        t,
      ) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          Scaffold(
            appBar: AppBar(title: const Text('Bosque')),
            body: const HexAprobadoresScreen(),
          ),
          ancho: 390,
          overrides: anulaciones(),
        );
        t.view.physicalSize = const Size(390, 741);
        await esperar(t);
        const teclado = 336.0;

        // Con el teclado abierto se busca y se elige: la opción queda sobre
        // el teclado y, de vuelta, «Asignar» sigue a la vista.
        Future<void> buscar(
          String etiqueta,
          String buscar,
          String nombre,
        ) async {
          await tocar(t, selector(etiqueta), fotogramas: 2);
          await t.showKeyboard(buscador());
          t.view.viewInsets = const FakeViewPadding(bottom: teclado);
          await esperar(t, 3);
          expect(errores, isEmpty, reason: detalle(errores));
          await t.enterText(buscador(), buscar);
          await esperar(t, 3);
          expect(errores, isEmpty, reason: detalle(errores));
          expect(opcion(nombre), findsOneWidget);
          expect(
            t.getRect(opcion(nombre)).bottom,
            lessThanOrEqualTo(741 - teclado),
          );
          await t.tap(opcion(nombre));
          await esperar(t, 2);
          expect(enDialogo('Asignar').hitTestable(), findsOneWidget);
          t.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await esperar(t, 2);
        }

        await abrirAsignar(t);
        await nivel(t, 'Jefe de área');
        await buscar('Persona', 'Quis', 'Quispe Mamani Ana');
        await aceptar(t, 'Asignar');
        expect(asignado().codEmpleadoAprobador, BigInt.from(9));
        expect(asignado().nivel, 2);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}
