import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// El rango de recepcion de la grilla de cheques: abre con los ultimos tres
/// meses, se puede cambiar o quitar, y la pantalla dice cual esta activo. El
/// reloj va fijo en el 03/10/2026 (`relojFijoCheques`): el rango por defecto es
/// del 03/07/2026 al 03/10/2026.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  setUp(() => repo = RepositorioChequesFalso());

  Widget pantalla({
    PermisosCheque permisos = permisosAdmin,
    List<Override> extra = const [],
  }) => appCheques(
    hijo: const ChequesScreen(),
    repo: repo,
    permisos: permisos,
    extra: extra,
  );

  List<ChequeFilaEntity> filas() => [
    for (var i = 1; i <= 12; i++) chequeFalso(i, descTipo: 'PAGO'),
  ];

  // ── Piezas de las pruebas ────────────────────────────────────────────────

  final campoDesde = find.byKey(const ValueKey('filtro-recibido-desde'));
  final campoHasta = find.byKey(const ValueKey('filtro-recibido-hasta'));
  final botonBuscar = find.ancestor(
    of: find.text('Buscar'),
    matching: find.bySubtype<FilledButton>(),
  );

  bool buscarHabilitado(WidgetTester t) =>
      t.widget<FilledButton>(botonBuscar).onPressed != null;

  /// En movil los filtros estan plegados: se abre el panel si hace falta.
  Future<void> verFiltros(WidgetTester t) async {
    final plegado = find.byTooltip('Mostrar filtros');
    if (plegado.evaluate().isNotEmpty) {
      await t.tap(plegado);
      await esperar(t);
    }
  }

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    await esperar(t);
  }

  /// Abre el calendario del [campo], retrocede [mesesAtras] meses (adelanta si
  /// es negativo), elige el [dia] y acepta. El calendario abre en la fecha que ya
  /// tiene el campo.
  Future<void> elegirDia(
    WidgetTester t,
    Finder campo, {
    required int dia,
    int mesesAtras = 0,
  }) async {
    await tocar(t, campo);
    for (var i = 0; i < mesesAtras.abs(); i++) {
      await t.tap(find.byTooltip(mesesAtras > 0 ? 'Mes anterior' : 'Mes siguiente'));
      await esperar(t);
    }
    await t.tap(find.text('$dia').last);
    await esperar(t);
    await t.tap(find.text('ACEPTAR'));
    await esperar(t);
  }

  /// Deja «hasta» (01/07/2026) antes que «desde» (03/07/2026).
  Future<void> provocarErrorDeRango(WidgetTester t) =>
      elegirDia(t, campoHasta, dia: 1, mesesAtras: 3);

  Finder dentroDe(Finder campo, String texto) =>
      find.descendant(of: campo, matching: find.text(texto));

  const textoRangoPorDefecto =
      'Mostrando cheques recibidos del 03/07/2026 al 03/10/2026';
  const textoError = 'No puede ser anterior a «Recibido desde».';

  // ── Al abrir ─────────────────────────────────────────────────────────────

  group('al abrir', () {
    testWidgets('pide del 03/07/2026 al 03/10/2026, sin hora y sin la clave antigua', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      final f = repo.filtros.single;
      expect(f.fechaRecepcionDesde, DateTime(2026, 7, 3));
      expect(f.fechaRecepcionHasta, DateTime(2026, 10, 3));

      final cuerpo = repo.cuerposListar.single;
      expect(cuerpo['fechaRecepcionDesde'], '2026-07-03');
      expect(cuerpo['fechaRecepcionHasta'], '2026-10-03');
      expect(cuerpo.containsKey('fechaRecepcion'), isFalse);
      expect(cuerpo.containsKey('audUsuario'), isFalse);
    });

    testWidgets('los dos campos traen las fechas y se pueden quitar', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      expect(find.text('Recibido desde'), findsOneWidget);
      expect(find.text('Recibido hasta'), findsOneWidget);
      expect(find.text('Fecha de recepción'), findsNothing);
      expect(dentroDe(campoDesde, '03/07/2026'), findsOneWidget);
      expect(dentroDe(campoHasta, '03/10/2026'), findsOneWidget);
      expect(find.byTooltip('Quitar Recibido desde'), findsOneWidget);
      expect(find.byTooltip('Quitar Recibido hasta'), findsOneWidget);
    });

    testWidgets('en movil los campos estan dentro de los filtros plegables', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 390);

      expect(campoDesde, findsNothing);
      await verFiltros(tester);
      expect(dentroDe(campoDesde, '03/07/2026'), findsOneWidget);
      expect(dentroDe(campoHasta, '03/10/2026'), findsOneWidget);
      // Uno sobre otro, a todo el ancho.
      expect(
        tester.getTopLeft(campoDesde).dy,
        lessThan(tester.getTopLeft(campoHasta).dy),
      );
      expect(
        tester.getSize(campoDesde).width,
        tester.getSize(campoHasta).width,
      );
    });

    testWidgets('en escritorio van juntos, en el mismo renglon', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      expect(
        tester.getTopLeft(campoDesde).dy,
        tester.getTopLeft(campoHasta).dy,
      );
      expect(
        tester.getTopLeft(campoDesde).dx,
        lessThan(tester.getTopLeft(campoHasta).dx),
      );
    });

    testWidgets('el rango por defecto no cuenta como filtro aplicado en movil', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 390);

      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    });
  });

  // ── Texto del rango activo ───────────────────────────────────────────────

  group('el texto del rango activo', () {
    testWidgets('con rango, bajo los filtros y sobre el listado', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      final texto = find.text(textoRangoPorDefecto);
      expect(texto, findsOneWidget);
      expect(find.byKey(const ValueKey('rango-activo')), findsOneWidget);
      expect(
        tester.getTopLeft(texto).dy,
        greaterThan(tester.getBottomLeft(campoDesde).dy),
      );
      expect(
        tester.getBottomLeft(texto).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('lista-tabla'))).dy),
      );
    });

    testWidgets('habla de lo aplicado: no cambia hasta pulsar Buscar', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      expect(find.text(textoRangoPorDefecto), findsOneWidget);

      await tocar(tester, find.text('Buscar'));
      expect(find.text(textoRangoPorDefecto), findsNothing);
      expect(
        find.text('Mostrando cheques recibidos hasta el 03/10/2026'),
        findsOneWidget,
      );
    });

    testWidgets('con una sola fecha: solo desde y solo hasta', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      await tocar(tester, find.byTooltip('Quitar Recibido hasta'));
      await tocar(tester, find.text('Buscar'));
      expect(
        find.text('Mostrando cheques recibidos desde el 03/07/2026'),
        findsOneWidget,
      );

      await tocar(tester, find.text('Limpiar'));
      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tocar(tester, find.text('Buscar'));
      expect(
        find.text('Mostrando cheques recibidos hasta el 03/10/2026'),
        findsOneWidget,
      );
    });

    testWidgets('sin fechas dice que se muestran todos', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tocar(tester, find.byTooltip('Quitar Recibido hasta'));
      await tocar(tester, find.text('Buscar'));

      expect(
        find.text('Mostrando todos los cheques recibidos'),
        findsOneWidget,
      );
    });

    testWidgets('sin sucursal no se dibuja', (tester) async {
      repo.sucursalInicial = 0;
      await montar(tester, pantalla(), ancho: 1400);

      expect(find.byKey(const ValueKey('rango-activo')), findsNothing);
    });

    testWidgets('en movil tambien se ve, con los filtros plegados', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 390);

      expect(find.text(textoRangoPorDefecto), findsOneWidget);
    });
  });

  // ── Buscar con el rango ──────────────────────────────────────────────────

  group('buscar', () {
    testWidgets('quitar las dos fechas y buscar no manda ninguna de las dos claves', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tocar(tester, find.byTooltip('Quitar Recibido hasta'));
      await tocar(tester, find.text('Buscar'));

      final cuerpo = repo.cuerposListar.last;
      expect(cuerpo.containsKey('fechaRecepcionDesde'), isFalse);
      expect(cuerpo.containsKey('fechaRecepcionHasta'), isFalse);
      expect(cuerpo.containsKey('fechaRecepcion'), isFalse);
      expect(repo.filtros.last.pagina, 1);
    });

    testWidgets('quitar solo una manda solo la otra', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tocar(tester, find.text('Buscar'));
      var cuerpo = repo.cuerposListar.last;
      expect(cuerpo.containsKey('fechaRecepcionDesde'), isFalse);
      expect(cuerpo['fechaRecepcionHasta'], '2026-10-03');

      await tocar(tester, find.text('Limpiar'));
      await tocar(tester, find.byTooltip('Quitar Recibido hasta'));
      await tocar(tester, find.text('Buscar'));
      cuerpo = repo.cuerposListar.last;
      expect(cuerpo['fechaRecepcionDesde'], '2026-07-03');
      expect(cuerpo.containsKey('fechaRecepcionHasta'), isFalse);
    });

    testWidgets('un rango elegido en el calendario viaja tal cual', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      // «Desde» abre en julio de 2026; «hasta», en octubre.
      await elegirDia(tester, campoDesde, dia: 15);
      await elegirDia(tester, campoHasta, dia: 20, mesesAtras: 1);
      expect(dentroDe(campoDesde, '15/07/2026'), findsOneWidget);
      expect(dentroDe(campoHasta, '20/09/2026'), findsOneWidget);
      // Elegir no consulta: eso lo hace Buscar.
      expect(repo.contar('listar'), 1);

      await tocar(tester, find.text('Buscar'));
      expect(repo.cuerposListar.last['fechaRecepcionDesde'], '2026-07-15');
      expect(repo.cuerposListar.last['fechaRecepcionHasta'], '2026-09-20');
      expect(
        find.text('Mostrando cheques recibidos del 15/07/2026 al 20/09/2026'),
        findsOneWidget,
      );
    });

    testWidgets('el mismo dia en las dos fechas es un solo dia y es valido', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      // «Desde» abre en julio; llevarlo al 03/10 iguala las dos fechas.
      await elegirDia(tester, campoDesde, dia: 3, mesesAtras: -3);

      expect(dentroDe(campoDesde, '03/10/2026'), findsOneWidget);
      expect(find.text(textoError), findsNothing);
      expect(buscarHabilitado(tester), isTrue);
      await tocar(tester, find.text('Buscar'));
      expect(
        find.text('Mostrando cheques recibidos el 03/10/2026'),
        findsOneWidget,
      );
    });
  });

  // ── Rango invertido ──────────────────────────────────────────────────────

  group('desde posterior a hasta', () {
    testWidgets('muestra el error junto al campo y apaga Buscar', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);
      expect(buscarHabilitado(tester), isTrue);
      expect(find.text(textoError), findsNothing);

      await provocarErrorDeRango(tester);

      expect(dentroDe(campoHasta, '01/07/2026'), findsOneWidget);
      expect(find.text(textoError), findsOneWidget);
      expect(
        find.descendant(of: campoHasta, matching: find.text(textoError)),
        findsOneWidget,
        reason: 'el error va en el campo «hasta»',
      );
      expect(buscarHabilitado(tester), isFalse);

      final consultas = repo.contar('listar');
      await tester.tap(botonBuscar, warnIfMissed: false);
      await esperar(tester);
      expect(repo.contar('listar'), consultas);
    });

    testWidgets('Enter en un campo de texto tampoco busca', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);
      await provocarErrorDeRango(tester);

      final consultas = repo.contar('listar');
      await tester.enterText(find.byKey(const ValueKey('filtro-nro')), '100002');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await esperar(tester);

      expect(repo.contar('listar'), consultas);
    });

    testWidgets('al corregirlo, el error se va y Buscar vuelve', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);
      await provocarErrorDeRango(tester);
      expect(buscarHabilitado(tester), isFalse);

      // Quitar «hasta» deja un rango abierto, que es valido.
      await tocar(tester, find.byTooltip('Quitar Recibido hasta'));

      expect(find.text(textoError), findsNothing);
      expect(buscarHabilitado(tester), isTrue);
    });

    testWidgets('Limpiar tambien lo corrige', (tester) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);
      await provocarErrorDeRango(tester);

      await tocar(tester, find.text('Limpiar'));

      expect(find.text(textoError), findsNothing);
      expect(buscarHabilitado(tester), isTrue);
      expect(dentroDe(campoHasta, '03/10/2026'), findsOneWidget);
    });

    testWidgets('en movil el error tambien sale y Buscar queda apagado', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 390);
      await verFiltros(tester);

      await provocarErrorDeRango(tester);

      expect(find.text(textoError), findsOneWidget);
      await tester.ensureVisible(botonBuscar);
      expect(buscarHabilitado(tester), isFalse);
    });
  });

  // ── Limpiar ──────────────────────────────────────────────────────────────

  group('limpiar', () {
    testWidgets('vuelve al rango por defecto y vacia los demas criterios', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      // Todo distinto: sin fechas y con un nro de cheque.
      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tocar(tester, find.byTooltip('Quitar Recibido hasta'));
      await tester.enterText(find.byKey(const ValueKey('filtro-nro')), '100005');
      await tocar(tester, find.text('Buscar'));
      expect(repo.filtros.last.nroCheque, '100005');
      expect(repo.filtros.last.tieneRangoRecepcion, isFalse);

      await tocar(tester, find.text('Limpiar'));

      final f = repo.filtros.last;
      expect(f.tieneCriteriosSalvoRecepcion, isFalse);
      expect(f.fechaRecepcionDesde, DateTime(2026, 7, 3));
      expect(f.fechaRecepcionHasta, DateTime(2026, 10, 3));
      expect(f.pagina, 1);
      expect(repo.cuerposListar.last['fechaRecepcionDesde'], '2026-07-03');
      // Los campos lo reflejan, y no quedan en «todos».
      expect(dentroDe(campoDesde, '03/07/2026'), findsOneWidget);
      expect(dentroDe(campoHasta, '03/10/2026'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('filtro-nro')))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text(textoRangoPorDefecto), findsOneWidget);
    });

    testWidgets('con lo escrito sin aplicar, tambien deja los campos limpios', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);

      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tester.enterText(find.byKey(const ValueKey('filtro-nro')), '999');
      await tocar(tester, find.text('Limpiar'));

      expect(dentroDe(campoDesde, '03/07/2026'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('filtro-nro')))
            .controller!
            .text,
        isEmpty,
      );
    });
  });

  // ── Empresa y sucursal ───────────────────────────────────────────────────

  group('empresa y sucursal', () {
    Future<void> elegir(WidgetTester t, Finder combo, String nombre) async {
      await t.ensureVisible(combo);
      await t.tap(combo);
      await esperar(t);
      await t.tap(find.text(nombre).last);
      await esperar(t);
    }

    testWidgets('cambiar de empresa o de sucursal conserva el rango elegido', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(
        tester,
        pantalla(permisos: permisosCon([PermisosCheque.btnSucursales])),
        ancho: 1400,
      );
      await elegirDia(tester, campoDesde, dia: 15);
      await elegirDia(tester, campoHasta, dia: 20, mesesAtras: 1);
      await tocar(tester, find.text('Buscar'));

      await elegir(tester, comboEmpresa(), 'ESPPAPEL');
      expect(repo.filtros.last.codSucursal, 7);
      expect(repo.cuerposListar.last['fechaRecepcionDesde'], '2026-07-15');
      expect(repo.cuerposListar.last['fechaRecepcionHasta'], '2026-09-20');

      await elegir(tester, comboSucursal(), 'COCHABAMBA');
      expect(repo.filtros.last.codSucursal, 8);
      expect(repo.cuerposListar.last['fechaRecepcionDesde'], '2026-07-15');
      expect(repo.cuerposListar.last['fechaRecepcionHasta'], '2026-09-20');

      // Y los campos y el texto siguen diciendo lo mismo.
      expect(dentroDe(campoDesde, '15/07/2026'), findsOneWidget);
      expect(dentroDe(campoHasta, '20/09/2026'), findsOneWidget);
      expect(
        find.text('Mostrando cheques recibidos del 15/07/2026 al 20/09/2026'),
        findsOneWidget,
      );
    });

    testWidgets('si se quitaron las fechas, cambiar de empresa no las repone', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);
      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tocar(tester, find.byTooltip('Quitar Recibido hasta'));
      await tocar(tester, find.text('Buscar'));

      await elegir(tester, comboEmpresa(), 'ESPPAPEL');

      expect(repo.filtros.last.codSucursal, 7);
      expect(repo.filtros.last.tieneRangoRecepcion, isFalse);
      expect(find.text('Mostrando todos los cheques recibidos'), findsOneWidget);
    });
  });

  // ── Listado vacio ────────────────────────────────────────────────────────

  group('listado vacio', () {
    /// Cheques de agosto de 2026 con el reloj en marzo de 2027: el rango por
    /// defecto (01/12/2026 al 01/03/2027) no los alcanza.
    List<Override> relojDeMarzo() => [
      relojChequesProvider.overrideWithValue(() => DateTime(2027, 3, 1)),
    ];

    testWidgets('solo con el rango: dice que no hay en esas fechas y ofrece ver todos', (
      tester,
    ) async {
      repo
        ..filtrarPorRecepcion = true
        ..cheques = filas();
      await montar(tester, pantalla(extra: relojDeMarzo()), ancho: 1400);

      expect(
        find.text(
          'Mostrando cheques recibidos del 01/12/2026 al 01/03/2027',
        ),
        findsOneWidget,
      );
      expect(
        find.text('No hay cheques recibidos en esas fechas'),
        findsOneWidget,
      );
      expect(find.textContaining('Todavía no hay cheques'), findsNothing);
      expect(find.text('Ningún cheque coincide con la búsqueda'), findsNothing);

      await tocar(tester, find.text('Ver todos los cheques'));

      expect(repo.cuerposListar.last.containsKey('fechaRecepcionDesde'), isFalse);
      expect(repo.cuerposListar.last.containsKey('fechaRecepcionHasta'), isFalse);
      expect(find.byKey(const ValueKey('lista-tabla')), findsOneWidget);
      expect(find.text('Mostrando todos los cheques recibidos'), findsOneWidget);
      // Los campos siguen lo aplicado: ya no tienen fechas.
      expect(find.byTooltip('Quitar Recibido desde'), findsNothing);
      expect(find.byTooltip('Quitar Recibido hasta'), findsNothing);
    });

    testWidgets('sin ningun cheque y sin fechas: todavia no hay cheques', (
      tester,
    ) async {
      repo.cheques = [];
      await montar(tester, pantalla(), ancho: 1400);
      expect(
        find.text('No hay cheques recibidos en esas fechas'),
        findsOneWidget,
      );

      await tocar(tester, find.text('Ver todos los cheques'));

      expect(
        find.text('Todavía no hay cheques en esta sucursal'),
        findsOneWidget,
      );
      expect(find.text('Ver todos los cheques'), findsNothing);
    });

    testWidgets('con otros criterios la busqueda sin resultados manda: Quitar filtros vuelve al rango', (
      tester,
    ) async {
      repo.cheques = filas();
      await montar(tester, pantalla(), ancho: 1400);
      await tocar(tester, find.byTooltip('Quitar Recibido desde'));
      await tester.enterText(
        find.byKey(const ValueKey('filtro-nro')),
        '999999999',
      );
      await tocar(tester, find.text('Buscar'));
      expect(find.text('Ningún cheque coincide con la búsqueda'), findsOneWidget);
      expect(find.text('Ver todos los cheques'), findsNothing);

      await tocar(tester, find.text('Quitar filtros'));

      expect(repo.filtros.last.nroCheque, isNull);
      expect(repo.filtros.last.fechaRecepcionDesde, DateTime(2026, 7, 3));
      expect(repo.filtros.last.fechaRecepcionHasta, DateTime(2026, 10, 3));
      // El panel de filtros siguio lo aplicado desde fuera.
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('filtro-nro')))
            .controller!
            .text,
        isEmpty,
      );
      expect(dentroDe(campoDesde, '03/07/2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('lista-tabla')), findsOneWidget);
    });
  });

  // ── Sin desbordes ────────────────────────────────────────────────────────

  for (final escala in [1.0, 1.5]) {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets(
        'los filtros con los dos campos de fecha no desbordan a ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %',
        (tester) async {
          repo.cheques = filas();
          if (escala != 1.0) conTexto(tester, escala);

          final errores = await capturandoErrores(() async {
            await montar(tester, pantalla(), ancho: ancho);
            await verFiltros(tester);
          });

          expect(errores, isEmpty, reason: 'a $ancho');
          expect(campoDesde, findsOneWidget);
          expect(campoHasta, findsOneWidget);
          expect(find.text(textoRangoPorDefecto), findsOneWidget);
          for (final campo in [campoDesde, campoHasta]) {
            final r = tester.getRect(campo);
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(ancho), reason: 'a $ancho');
          }
        },
      );
    }
  }

  for (final ancho in [390.0, 800.0, 1400.0]) {
    testWidgets(
      'con el error de rango tampoco desbordan a ${ancho.toInt()} px, texto al 150 %',
      (tester) async {
        repo.cheques = filas();
        await montar(tester, pantalla(), ancho: ancho);
        await verFiltros(tester);
        // El calendario se maneja con el texto normal; el 150 % va despues.
        await provocarErrorDeRango(tester);

        final errores = await capturandoErrores(() async {
          conTexto(tester, 1.5);
          await esperar(tester);
        });

        expect(errores, isEmpty, reason: 'a $ancho');
        expect(find.text(textoError), findsOneWidget);
        expect(buscarHabilitado(tester), isFalse);
        for (final campo in [campoDesde, campoHasta]) {
          expect(tester.getRect(campo).right, lessThanOrEqualTo(ancho));
        }
      },
    );
  }
}
