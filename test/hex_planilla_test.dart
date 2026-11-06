import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_planilla_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_resumen.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// «Planilla de horas extra» (RRHH): combinaciones por ejecutar, vista previa
/// con avisos y líneas, ejecutar (confirmación, 400, 409, doble toque, PDF),
/// planillas ejecutadas con sus anexos, permisos por botón, anchos y teclado.
void main() {
  setUpAll(cargarFuentesHex);

  late HexPlanillaFalso repo;
  late HexReporteFalso reportes;
  late List<EmpresaEntity> empresas;

  setUp(() {
    repo =
        HexPlanillaFalso()
          ..programar('pendientes', [_pendientes])
          ..programar('vistaPrevia', [_previa])
          ..programar('avisos', [_avisos])
          ..programar('vistaPreviaLineas', [_lineas])
          ..programar('empleados', [_resumen])
          ..programar('detalle', [_anexo])
          ..programar('leyenda', [_leyenda]);
    reportes = HexReporteFalso();
    empresas = [
      EmpresaEntity(
        codEmpresa: 2,
        nombre: 'Impexpap',
        codPadre: 0,
        sigla: 'IPX',
        audUsuario: 0,
      ),
    ];
  });

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  List<Override> anulaciones() => [
    hexPlanillaRepositoryProvider.overrideWithValue(repo),
    hexReporteRepositoryProvider.overrideWithValue(reportes),
    empresasProvider.overrideWith((ref) => EmpresasNotifier(_Rrhh(empresas))),
  ];

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
  }) async {
    await montarHex(
      t,
      const HexPlanillaScreen(),
      ancho: ancho,
      botones: botones,
      overrides: anulaciones(),
    );
    await esperar(t);
  }

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  Finder botonDelDialogo(String texto) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, texto),
  );

  /// Con avisos, «Ejecutar planilla» espera la casilla «Revisé los avisos».
  Future<void> revisarAvisos(WidgetTester t) async {
    final casilla = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Revisé los avisos'),
    );
    if (casilla.evaluate().isEmpty) return;
    await t.tap(casilla);
    await esperar(t, 2);
  }

  Finder ejecutarEnPagina() =>
      find.widgetWithText(FilledButton, 'Ejecutar planilla').first;

  /// Un aviso del kit: se dibuja en la capa superior, fuera de la pantalla
  /// (así no se confunde con el mismo texto en una vista de error).
  Finder aviso(String texto) => find.byElementPredicate((e) {
    final w = e.widget;
    return w is Text &&
        w.data == texto &&
        e.findAncestorWidgetOfExactType<HexPlanillaScreen>() == null;
  });

  /// El desplazamiento de la pantalla (el único vertical en el angosto).
  Finder pagina() =>
      find
          .ancestor(
            of: find.text('Planilla de horas extra'),
            matching: find.byType(Scrollable),
          )
          .first;

  bool esVertical(Widget w) =>
      (w is ScrollView && w.scrollDirection == Axis.vertical) ||
      (w is SingleChildScrollView && w.scrollDirection == Axis.vertical);

  bool esLateral(Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;

  Future<void> tocar(WidgetTester t, Finder f, {int fotogramas = 4}) async {
    await t.ensureVisible(f);
    await esperar(t, 1);
    await t.tap(f);
    await esperar(t, fotogramas);
  }

  Future<void> abrirPrevia(WidgetTester t) =>
      tocar(t, find.text('Planta El Alto').first);

  Future<void> irAEjecutadas(WidgetTester t) =>
      tocar(t, find.text('Ejecutadas'));

  Future<void> abrirPlanilla(WidgetTester t, String periodo) async {
    await irAEjecutadas(t);
    await tocar(t, find.textContaining(periodo).first);
  }

  Future<void> abrirConfirmacion(WidgetTester t) async {
    await tocar(t, ejecutarEnPagina(), fotogramas: 3);
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  Finder seccion(String texto) => find.widgetWithText(ChoiceChip, texto);

  group('por ejecutar', () {
    testWidgets('lista las combinaciones con empresa, sucursal y período', (
      t,
    ) async {
      await montar(t);
      // D39: el selector del lote también nombra los meses; se mira la lista.
      Finder enLista(String texto) => find.descendant(
        of: find.byWidgetPredicate((w) => w is ListadoHex<HexPendienteEntity>),
        matching: find.text(texto),
      );
      expect(enLista('Planta El Alto'), findsOneWidget);
      expect(enLista('Almacén Central'), findsOneWidget);
      expect(enLista('Impexpap'), findsNWidgets(2));
      expect(enLista('Octubre de 2026'), findsOneWidget);
      expect(enLista('Septiembre de 2026'), findsOneWidget);
      expect(find.text('Reportes aprobados'), findsOneWidget);
      expect(find.text('Lote del mes'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('empresa sin nombre usa el código', (t) async {
      empresas = [];
      await montar(t);
      expect(find.text('Empresa 2'), findsNWidgets(2));
      await abrirPrevia(t);
      expect(find.text('Paga Empresa 2'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin pendientes lo dice', (t) async {
      repo.programar('pendientes', [<HexPendienteEntity>[]]);
      await montar(t);
      expect(find.text('No hay planillas por ejecutar'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un 403 dice No tienes permiso', (t) async {
      repo.programar('pendientes', [const SinPermisoHex('Sin acceso.')]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('los avisos de la vista previa se ven antes de ejecutar', (
      t,
    ) async {
      await montar(t);
      await abrirPrevia(t);
      final c = repo.argumentosDe('vistaPrevia').single['combinacion'];
      expect(c, _combinacion);
      expect(repo.argumentosDe('avisos').single['combinacion'], _combinacion);
      final provisional = find.text(_detalleProvisional);
      final biometrico = find.text(_detalleBiometrico);
      expect(provisional, findsOneWidget);
      expect(biometrico, findsOneWidget);
      expect(find.text('Monto provisional'), findsOneWidget);
      expect(find.text('El biométrico registra otra hora'), findsOneWidget);
      // El SP manda primero el biométrico; lo provisional se ve arriba.
      expect(
        t.getTopLeft(provisional).dy,
        lessThan(t.getTopLeft(biometrico).dy),
      );
      expect(
        t.getTopLeft(biometrico).dy,
        lessThan(t.getTopLeft(find.text('Marcas')).dy),
      );
      // Las líneas se piden solo al abrirlas.
      expect(repo.vecesDe('vistaPreviaLineas'), 0);
      await cerrar(t);
    });

    testWidgets('tocar un aviso abre su reporte', (t) async {
      await montar(t);
      await abrirPrevia(t);
      await tocar(t, find.text(_detalleProvisional));
      expect(
        reportes.argumentosDe('detalle').single['idReporte'],
        BigInt.from(102),
      );
      await cerrar(t);
    });

    testWidgets('sin avisos lo dice', (t) async {
      repo.programar('avisos', [<HexAvisoEntity>[]]);
      await montar(t);
      await abrirPrevia(t);
      expect(
        find.text('Sin avisos: ningún reporte necesita revisión.'),
        findsOneWidget,
      );
      await cerrar(t);
    });

    testWidgets('la vista previa muestra los montos y marcas del SP', (
      t,
    ) async {
      await montar(t);
      await abrirPrevia(t);
      expect(find.text('Planta El Alto · octubre de 2026'), findsOneWidget);
      expect(find.text('Paga Impexpap'), findsOneWidget);
      expect(find.text('Bs 275,50'), findsOneWidget);
      expect(find.text('Bs 15,00'), findsWidgets);
      expect(find.text('provisional'), findsOneWidget);
      expect(find.text('Aviso de biométrico'), findsOneWidget);
      expect(find.text('De período anterior'), findsOneWidget);
      // El pie: las filas de P, tal cual.
      expect(find.text('Bs 290,50'), findsOneWidget);
      expect(find.textContaining('vacaci'), findsNothing);
      expect(find.textContaining('Compensa'), findsNothing);
      expect(find.text('Leyenda de códigos'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('Ver líneas pide las líneas y muestra solo las del empleado', (
      t,
    ) async {
      await montar(t);
      await abrirPrevia(t);
      await tocar(t, find.text('Mamani Quispe Juan'));
      expect(repo.vecesDe('vistaPreviaLineas'), 1);
      expect(find.text('Líneas de Mamani Quispe Juan'), findsOneWidget);
      Finder enLineas(String texto) =>
          find.descendant(of: find.byType(Dialog), matching: find.text(texto));
      expect(enLineas('Horas al 50 %'), findsOneWidget);
      expect(enLineas('Cena'), findsOneWidget);
      // La línea de otro empleado (Choque) no aparece.
      expect(enLineas('Desayuno'), findsNothing);
      // Un bloque por reporte, cada uno con el haber con que se valuó.
      expect(enLineas('Jornada 05/10/2026'), findsOneWidget);
      expect(enLineas('Jornada 28/09/2026'), findsOneWidget);
      expect(
        enLineas('Haber Bs 3.000,00 · divisor 240 · costo hora Bs 12,50'),
        findsNWidgets(2),
      );
      await tocar(t, find.text('Ver reporte').first);
      expect(
        reportes.argumentosDe('detalle').single['idReporte'],
        BigInt.from(101),
      );
      await cerrar(t);
    });

    testWidgets('volver a pendientes muestra la lista otra vez', (t) async {
      await montar(t);
      await abrirPrevia(t);
      await tocar(t, find.text('Volver a pendientes'));
      expect(find.text('Almacén Central'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('ejecutar', () {
    testWidgets('ejecutar confirma con el resumen y ofrece el PDF', (t) async {
      repo
        ..programar('ejecutar', [
          (id: BigInt.from(12), mensaje: 'Planilla 12 ejecutada: 3 reportes.'),
        ])
        ..programar('pdf', [const SinDatosHex('No se encontró la planilla.')]);
      await montar(t);
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      expect(
        enDialogo(
          'Se congelarán 3 reportes de 2 empleados de Planta El Alto, octubre '
          'de 2026.',
        ),
        findsOneWidget,
      );
      expect(
        enDialogo('Después no se modifica; solo se puede anular.'),
        findsOneWidget,
      );
      expect(enDialogo('Impexpap'), findsOneWidget);
      expect(enDialogo('Bs 290,50'), findsOneWidget);
      expect(find.textContaining('vacaci'), findsNothing);
      expect(
        enDialogo(
          'La vista previa tiene 2 avisos: revísalos antes de ejecutar.',
        ),
        findsOneWidget,
      );
      expect(repo.vecesDe('ejecutar'), 0);

      await revisarAvisos(t);
      await t.tap(botonDelDialogo('Ejecutar planilla'));
      await esperar(t, 4);
      final args = repo.argumentosDe('ejecutar').single;
      expect(args['combinacion'], _combinacion);
      expect(args['observacion'], isNull);
      // El mensaje del SP va en el diálogo del PDF, una sola vez.
      expect(enDialogo('Planilla ejecutada'), findsOneWidget);
      expect(find.text('Planilla 12 ejecutada: 3 reportes.'), findsOneWidget);
      expect(find.text('Ver PDF'), findsOneWidget);
      // Las listas se recargan y se vuelve a las pendientes.
      expect(repo.vecesDe('pendientes'), 2);
      expect(repo.vecesDe('pdf'), 0);

      await t.tap(find.text('Ver PDF'));
      await esperar(t, 3);
      expect(repo.argumentosDe('pdf').single['idPlanilla'], BigInt.from(12));
      await t.tap(find.text('Ahora no'));
      await esperar(t, 3);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Almacén Central'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('la observación llega al pedido', (t) async {
      await montar(t);
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      await t.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '  Horas extra de octubre ',
      );
      await revisarAvisos(t);
      await t.tap(botonDelDialogo('Ejecutar planilla'));
      await esperar(t, 4);
      expect(
        repo.argumentosDe('ejecutar').single['observacion'],
        'Horas extra de octubre',
      );
      await cerrar(t);
    });

    testWidgets('ejecutar con 409 recarga los pendientes', (t) async {
      repo.programar('ejecutar', [
        const ConflictoHex('Ya hay una planilla ejecutada para octubre.'),
      ]);
      await montar(t);
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      await revisarAvisos(t);
      await t.tap(botonDelDialogo('Ejecutar planilla'));
      await esperar(t, 4);
      expect(repo.vecesDe('ejecutar'), 1);
      expect(
        find.text('Ya hay una planilla ejecutada para octubre.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.vecesDe('pendientes'), 2);
      expect(find.text('Almacén Central'), findsOneWidget);
      expect(find.text('Ver PDF'), findsNothing);
      await cerrar(t);
    });

    testWidgets('la confirmación vuelve a pedir P y W y muestra las cifras '
        'nuevas', (t) async {
      repo
        ..programar('vistaPrevia', [_previa, _previaNueva])
        ..programar('avisos', [_avisos, _avisosNuevos]);
      await montar(t);
      await abrirPrevia(t);
      expect(repo.vecesDe('vistaPrevia'), 1);
      expect(repo.vecesDe('avisos'), 1);
      expect(find.text('Bs 290,50'), findsOneWidget);
      await abrirConfirmacion(t);
      expect(repo.vecesDe('vistaPrevia'), 2);
      expect(repo.vecesDe('avisos'), 2);
      expect(
        enDialogo(
          'Se congelarán 4 reportes de 2 empleados de Planta El Alto, octubre '
          'de 2026.',
        ),
        findsOneWidget,
      );
      expect(enDialogo('Bs 390,50'), findsOneWidget);
      expect(enDialogo('Bs 290,50'), findsNothing);
      expect(
        enDialogo('1 reporte queda fuera de la planilla; ver avisos.'),
        findsOneWidget,
      );
      expect(
        enDialogo(
          'La vista previa tiene 3 avisos: revísalos antes de ejecutar.',
        ),
        findsOneWidget,
      );
      // La página también muestra lo nuevo detrás del diálogo.
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      expect(find.text('Bs 390,50'), findsOneWidget);
      expect(
        find.text('Fuera de la planilla: sin haber básico'),
        findsOneWidget,
      );
      await cerrar(t);
    });

    testWidgets('sin reportes fuera la confirmación no lo menciona', (t) async {
      await montar(t);
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      expect(find.textContaining('fuera de la planilla'), findsNothing);
      await cerrar(t);
    });

    for (final (falla, metodo, otro) in [
      ('P', 'vistaPrevia', 'avisos'),
      ('W', 'avisos', 'vistaPrevia'),
    ]) {
      testWidgets('si la recarga de $falla falla avisa, no confirma y suelta '
          'la guarda', (t) async {
        const fallo = 'La combinación ya no tiene reportes aprobados.';
        repo.programar(metodo, [
          metodo == 'vistaPrevia' ? _previa : _avisos,
          const NegocioHex(fallo),
        ]);
        await montar(t);
        await abrirPrevia(t);
        await tocar(t, ejecutarEnPagina(), fotogramas: 3);
        // Las dos se pidieron otra vez (en paralelo).
        expect(repo.vecesDe(metodo), 2);
        expect(repo.vecesDe(otro), 2);
        expect(find.byType(AlertDialog), findsNothing);
        expect(aviso(fallo), findsOneWidget);
        expect(repo.vecesDe('ejecutar'), 0);
        // La guarda se libera: el botón vuelve a responder.
        final boton = t.widget<FilledButton>(ejecutarEnPagina());
        expect(boton.onPressed, isNotNull);
        expect(find.text('Actualizando…'), findsNothing);
        await cerrar(t);
      });
    }

    testWidgets('mientras recarga, el botón muestra la espera', (t) async {
      repo = _PlanillaLenta(repo);
      await montar(t);
      await abrirPrevia(t);
      final lenta = repo as _PlanillaLenta;
      lenta.espera = Completer<void>();
      await t.ensureVisible(ejecutarEnPagina());
      await esperar(t, 1);
      await t.tap(ejecutarEnPagina());
      await esperar(t, 2);
      final ocupado = find.widgetWithText(FilledButton, 'Actualizando…');
      expect(ocupado, findsOneWidget);
      expect(t.widget<FilledButton>(ocupado).onPressed, isNull);
      expect(find.byType(AlertDialog), findsNothing);
      lenta.espera!.complete();
      await esperar(t, 3);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Actualizando…'), findsNothing);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets('un 400 deja la confirmación abierta con el texto del SP', (
      t,
    ) async {
      const regla =
          'La empresa 2 no tiene ejecutada la planilla de sueldos de octubre.';
      repo.programar('ejecutar', [const NegocioHex(regla)]);
      await montar(t);
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      await revisarAvisos(t);
      await t.tap(botonDelDialogo('Ejecutar planilla'));
      await esperar(t, 4);
      expect(find.text(regla), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repo.vecesDe('pendientes'), 1);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      expect(find.text('Planta El Alto · octubre de 2026'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('doble toque: una confirmación y un solo pedido', (t) async {
      await montar(t);
      await abrirPrevia(t);
      final boton = ejecutarEnPagina();
      await t.ensureVisible(boton);
      await esperar(t, 1);
      await t.tap(boton);
      await t.tap(boton, warnIfMissed: false);
      await esperar(t, 3);
      expect(find.byType(AlertDialog), findsOneWidget);

      repo.pausa = Completer<void>();
      await revisarAvisos(t);
      await t.tap(botonDelDialogo('Ejecutar planilla'));
      await t.pump();
      await t.tap(botonDelDialogo('Ejecutar planilla'), warnIfMissed: false);
      await t.pump();
      expect(repo.vecesDe('ejecutar'), 1);
      repo.pausa!.complete();
      await esperar(t, 4);
      expect(repo.vecesDe('ejecutar'), 1);
      await t.tap(find.text('Ahora no'));
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets('sin btnHexEjecutarPlanilla no aparece Ejecutar', (t) async {
      await montar(t, botones: {BotonHex.pdfPlanilla});
      await abrirPrevia(t);
      expect(find.text(_detalleProvisional), findsOneWidget);
      expect(find.text('Ejecutar planilla'), findsNothing);
      await cerrar(t);
    });

    testWidgets('sin btnHexPdfPlanilla no ofrece el PDF y avisa el mensaje', (
      t,
    ) async {
      repo.programar('ejecutar', [
        (id: BigInt.from(12), mensaje: 'Planilla 12 ejecutada.'),
      ]);
      await montar(t, botones: {BotonHex.ejecutarPlanilla});
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      await revisarAvisos(t);
      await t.tap(botonDelDialogo('Ejecutar planilla'));
      await esperar(t, 4);
      expect(repo.vecesDe('ejecutar'), 1);
      expect(find.text('Planilla 12 ejecutada.'), findsOneWidget);
      expect(find.text('Ver PDF'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });
  });

  group('ejecutadas', () {
    testWidgets('la planilla ejecutada muestra los códigos y los montos', (
      t,
    ) async {
      // La grilla R completa: con menos ancho va en tarjetas.
      await montar(t, ancho: 1800);
      await abrirPlanilla(t, 'Septiembre de 2026');
      expect(
        repo.argumentosDe('empleados').single['idPlanilla'],
        BigInt.from(5),
      );
      for (final codigo in ['HS', 'H50', 'H100', 'HD', 'HF', 'D', 'DC']) {
        expect(find.text(codigo), findsWidgets, reason: codigo);
      }
      expect(find.text('2,00 h'), findsOneWidget);
      expect(find.text('Bs 25,00'), findsOneWidget);
      expect(find.textContaining('vacaci'), findsNothing);
      // D39: R se agrupa por sucursal, no por área.
      expect(find.text('Producción'), findsNothing);
      expect(find.text('Planta Senkata'), findsOneWidget);
      // Como en el PDF: Bs por código + Comidas (Bs) + Otros = Total.
      for (final rotulo in ['Otros (Bs)', 'Total (Bs)']) {
        expect(find.text(rotulo), findsOneWidget, reason: rotulo);
      }
      // «Comidas (Bs)» va en el pie (L) y en la grilla.
      expect(find.text('Comidas (Bs)'), findsNWidgets(2));
      // «Horas (Bs)» solo en el pie (L): en R duplicaría Otros (totalHoras
      // del SP ya lo incluye).
      expect(find.text('Horas (Bs)'), findsOneWidget);
      expect(find.text('Bs 53,13'), findsNothing);
      expect(find.text('Bs 83,13'), findsOneWidget);
      // Rojas cobra un tramo fuera de los fijos (Otros): su fila cuadra.
      final rojas = _resumen.last;
      expect(
        rojas.mH100 + rojas.mHF + rojas.mOtros + rojas.totalComidas,
        rojas.total,
      );
      expect(rojas.totalHoras, rojas.mH100 + rojas.mHF + rojas.mOtros);
      final filaRojas = find.ancestor(
        of: find.text('Rojas Vargas Luis'),
        matching: find.byType(InkWell),
      );
      for (final monto in ['Bs 100,00', 'Bs 30,00', 'Bs 10,00', 'Bs 140,00']) {
        expect(
          find.descendant(of: filaRojas.first, matching: find.text(monto)),
          findsOneWidget,
          reason: monto,
        );
      }
      // El pie es el de la planilla congelada (L), no una suma de la app.
      expect(find.text('Bs 9.035,50'), findsOneWidget);
      expect(find.text('Paga Impexpap'), findsOneWidget);
      // La leyenda congelada, al pie.
      expect(find.text('como se pagó en esta planilla'), findsOneWidget);
      expect(find.text('×1,5'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets(
      'la tabla compacta del resumen: fichas distintas de 0, cargo bajo '
      'el nombre y cada fila cuadra',
      (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: 1400);
        await abrirPlanilla(t, 'Septiembre de 2026');
        for (final rotulo in [
          'Empleado',
          'Costo hora (Bs)',
          'Horas por código',
          'Comidas',
          'Comidas (Bs)',
          'Otros (Bs)',
          'Total (Bs)',
        ]) {
          expect(find.text(rotulo), findsWidgets, reason: rotulo);
        }
        // Los códigos sueltos de la grilla (HS, H50…) no son columnas aquí.
        expect(find.text('Cargo'), findsNothing);

        List<String> textos(String nombre) => [
          for (final w in t.widgetList<Text>(
            find.descendant(
              of:
                  find
                      .ancestor(
                        of: find.text(nombre),
                        matching: find.byType(InkWell),
                      )
                      .first,
              matching: find.byType(Text),
            ),
          ))
            w.data ?? '',
        ];
        expect(textos('Mamani Quispe Juan'), [
          'Mamani Quispe Juan',
          'Operador de máquina',
          'Bs 12,50',
          'HS',
          '2,00 h · Bs 25,00',
          'H50',
          '1,50 h · Bs 28,13',
          'C',
          '×1',
          'DC',
          '×1',
          'Bs 30,00',
          '—',
          'Bs 83,13',
        ]);
        expect(textos('Choque Flores Pedro'), [
          'Choque Flores Pedro',
          'Ayudante',
          'Bs 10,00',
          '—',
          'D',
          '×1',
          'Bs 15,00',
          '—',
          'Bs 15,00',
        ]);
        // Con los números del SP, sin sumar nada en la app: Bs por código +
        // Comidas (Bs) + Otros = Total. Los tres últimos textos de la fila.
        double bs(String s) =>
            s == '—'
                ? 0
                : double.parse(
                  s
                      .replaceAll('Bs ', '')
                      .replaceAll('.', '')
                      .replaceAll(',', '.'),
                );
        for (final nombre in [
          'Mamani Quispe Juan',
          'Choque Flores Pedro',
          'Rojas Vargas Luis',
        ]) {
          final fila = textos(nombre);
          final porCodigo = fila
              .where((x) => x.contains(' · Bs '))
              .map((x) => bs(x.split(' · ').last))
              .fold<double>(0, (a, b) => a + b);
          final [comidas, otros, total] = fila.sublist(fila.length - 3);
          expect(
            porCodigo + bs(comidas) + bs(otros),
            closeTo(bs(total), 0.001),
            reason: nombre,
          );
        }
        final rojas = textos('Rojas Vargas Luis');
        expect(rojas.sublist(rojas.length - 3), ['—', 'Bs 10,00', 'Bs 140,00']);
        // Solo los códigos distintos de 0, con las mismas fichas de la tarjeta.
        final filaMamani =
            find
                .ancestor(
                  of: find.text('Mamani Quispe Juan'),
                  matching: find.byType(InkWell),
                )
                .first;
        expect(
          find.descendant(of: filaMamani, matching: find.byType(CodigoHex)),
          findsNWidgets(4),
        );
        // El cargo va bajo el nombre, en la misma columna.
        final nombre = t.getTopLeft(find.text('Mamani Quispe Juan'));
        final cargo = t.getTopLeft(find.text('Operador de máquina'));
        expect(cargo.dx, nombre.dx);
        expect(cargo.dy, greaterThan(nombre.dy));
        expect(find.textContaining('vacaci'), findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      },
    );

    testWidgets('a 390 px el resumen muestra solo los códigos distintos de 0', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await abrirPlanilla(t, 'Septiembre de 2026');
      final mamani = find.ancestor(
        of: find.text('Mamani Quispe Juan'),
        matching: find.byType(Card),
      );
      Finder enMamani(String texto) =>
          find.descendant(of: mamani, matching: find.text(texto));
      for (final codigo in ['HS', 'H50', 'C', 'DC']) {
        expect(enMamani(codigo), findsOneWidget, reason: codigo);
      }
      for (final codigo in ['H100', 'HD', 'HF', 'D', 'DD', 'A', 'DA']) {
        expect(enMamani(codigo), findsNothing, reason: codigo);
      }
      expect(enMamani('2,00 h · Bs 25,00'), findsOneWidget);
      expect(enMamani('Comidas (Bs)'), findsOneWidget);
      // Como la grilla: sin «Horas (Bs)», que ya incluye Otros.
      expect(enMamani('Horas (Bs)'), findsNothing);
      expect(enMamani('Bs 30,00'), findsOneWidget);
      final choque = find.ancestor(
        of: find.text('Choque Flores Pedro'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: choque, matching: find.text('HD')),
        findsNothing,
      );
      expect(find.textContaining('vacaci'), findsNothing);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('el anexo muestra el origen en palabras del SP, sin '
        'compensación', (t) async {
      await montar(t);
      await abrirPlanilla(t, 'Septiembre de 2026');
      await tocar(t, seccion('Anexo de detalle'));
      expect(repo.argumentosDe('detalle').single['idPlanilla'], BigInt.from(5));
      expect(find.text('Marca del biométrico'), findsOneWidget);
      expect(find.text('Editada por el encargado'), findsOneWidget);
      expect(find.text('Mamani Quispe Juan'), findsOneWidget);
      expect(find.text('Choque Flores Pedro'), findsOneWidget);
      expect(find.text('Compensación'), findsNothing);
      expect(find.text('Forma de compensación'), findsNothing);
      expect(find.textContaining('vacaci'), findsNothing);
      await tocar(t, find.byTooltip('Ver reporte').last);
      expect(
        reportes.argumentosDe('detalle').single['idReporte'],
        BigInt.from(102),
      );
      await cerrar(t);
    });

    testWidgets('la planilla ejecutada solo ofrece Resumen y Anexo', (t) async {
      await montar(t);
      await abrirPlanilla(t, 'Septiembre de 2026');
      expect(seccion('Resumen'), findsOneWidget);
      expect(seccion('Anexo de detalle'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(find.textContaining('vacaci'), findsNothing);
      await cerrar(t);
    });

    testWidgets('una planilla anulada se marca Anulada', (t) async {
      await montar(t);
      await irAEjecutadas(t);
      final anulada = find.byWidgetPredicate(
        (w) =>
            w is ChipHex &&
            w.texto == 'Anulada' &&
            w.tono == TonoHex.neutro &&
            w.icono == Icons.block,
      );
      expect(anulada, findsOneWidget);
      await tocar(t, find.text('Agosto de 2026'));
      expect(anulada, findsOneWidget);
      expect(
        find.text(
          'Anulada por Salazar Rivera Jorge el 03/09/2026 16:45. Motivo: Se '
          'ejecutó con el haber básico anterior.',
        ),
        findsOneWidget,
      );
      // No se paga: el total va sin la doble raya contable.
      expect(find.text('Total (anulada, no se paga)'), findsOneWidget);
      expect(find.text('Total en dinero'), findsNothing);
      expect(t.widget<CifrasHex>(find.byType(CifrasHex)).contable, isFalse);
      await cerrar(t);
    });

    testWidgets('una planilla ejecutada lleva el total contable', (t) async {
      await montar(t);
      await abrirPlanilla(t, 'Septiembre de 2026');
      expect(find.text('Total en dinero'), findsOneWidget);
      expect(t.widget<CifrasHex>(find.byType(CifrasHex)).contable, isTrue);
      await cerrar(t);
    });

    testWidgets('PDF sin datos avisa', (t) async {
      repo.programar('pdf', [
        const SinDatosHex('No se encontró la planilla para imprimir.'),
        Uint8List(0),
      ]);
      await montar(t);
      await abrirPlanilla(t, 'Septiembre de 2026');
      await tocar(t, find.widgetWithText(FilledButton, 'Imprimir / PDF'));
      expect(repo.argumentosDe('pdf').single['idPlanilla'], BigInt.from(5));
      expect(
        find.text('No se encontró la planilla para imprimir.'),
        findsOneWidget,
      );
      await esperar(t, 30);
      await tocar(t, find.widgetWithText(FilledButton, 'Imprimir / PDF'));
      expect(find.text('No hay datos para el PDF.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('Ver PDF desde la lista pide el de esa planilla', (t) async {
      repo.programar('pdf', [const SinDatosHex('Sin datos.')]);
      await montar(t);
      await irAEjecutadas(t);
      await tocar(t, find.byTooltip('Imprimir / PDF').last);
      expect(repo.argumentosDe('pdf').single['idPlanilla'], BigInt.from(4));
      await cerrar(t);
    });

    testWidgets('sin btnHexPdfPlanilla no hay PDF', (t) async {
      await montar(t, botones: {BotonHex.ejecutarPlanilla});
      await irAEjecutadas(t);
      expect(find.byTooltip('Imprimir / PDF'), findsNothing);
      await tocar(t, find.text('Septiembre de 2026'));
      expect(find.widgetWithText(FilledButton, 'Imprimir / PDF'), findsNothing);
      await cerrar(t);
    });
  });

  group('rediseño de la planilla (R8)', () {
    /// El chip tocable del semáforo que dice [texto].
    Finder fichaDeAviso(String texto) =>
        find.ancestor(of: find.text(texto), matching: find.byType(InkWell));

    Color colorDelTexto(WidgetTester tester, Finder f) =>
        tester.widget<Text>(f).style!.color!;

    testWidgets('las pestañas llevan ícono y cuántas hay', (t) async {
      await montar(t);
      final barra = find.byType(TabBar);
      expect(
        find.descendant(
          of: barra,
          matching: find.byIcon(Icons.pending_actions),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: barra, matching: find.byIcon(Icons.receipt_long)),
        findsOneWidget,
      );
      // Dos combinaciones por ejecutar y dos planillas en la lista.
      expect(
        find.descendant(of: barra, matching: find.text('2')),
        findsNWidgets(2),
      );
      await cerrar(t);
    });

    testWidgets('el semáforo cuenta los avisos y lleva a su sección', (
      t,
    ) async {
      repo.programar('avisos', [_avisosNuevos]);
      await montar(t, ancho: 390);
      await abrirPrevia(t);
      expect(find.text('1 provisional'), findsOneWidget);
      expect(find.text('1 fuera de la planilla'), findsOneWidget);
      expect(find.text('1 con aviso de biométrico'), findsOneWidget);
      // Cada chip lleva el ícono de su tipo de aviso.
      expect(find.byIcon(Icons.hourglass_top), findsWidgets);
      expect(find.byIcon(Icons.block), findsWidgets);
      expect(find.byIcon(Icons.fingerprint), findsWidgets);

      final alto = t.view.physicalSize.height;
      final grupo = find.text('El biométrico registra otra hora');
      expect(
        t.getTopLeft(grupo).dy,
        greaterThan(alto),
        reason: 'el grupo empieza fuera de la vista',
      );
      await t.tap(fichaDeAviso('1 con aviso de biométrico'));
      await esperar(t, 5);
      expect(t.getTopLeft(grupo).dy, lessThan(alto));
      expect(t.getTopLeft(grupo).dy, greaterThanOrEqualTo(0));
      await cerrar(t);
    });

    testWidgets('el semáforo usa error para lo provisional y ámbar para el '
        'resto', (t) async {
      repo.programar('avisos', [_avisosNuevos]);
      await montar(t);
      await abrirPrevia(t);
      final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
      final hc = HexColores.desde(cs);
      expect(colorDelTexto(t, find.text('1 provisional')), cs.onErrorContainer);
      expect(
        colorDelTexto(t, find.text('1 fuera de la planilla')),
        hc.alEnPendienteContenedor,
      );
      expect(
        colorDelTexto(t, find.text('1 con aviso de biométrico')),
        hc.alEnPendienteContenedor,
      );
      await cerrar(t);
    });

    testWidgets('sin avisos el semáforo está en verde y no hay casilla', (
      t,
    ) async {
      repo.programar('avisos', [<HexAvisoEntity>[]]);
      await montar(t);
      await abrirPrevia(t);
      expect(find.text('Sin avisos'), findsOneWidget);
      await abrirConfirmacion(t);
      expect(enDialogo('Revisé los avisos'), findsNothing);
      expect(
        t.widget<FilledButton>(botonDelDialogo('Ejecutar planilla')).onPressed,
        isNotNull,
      );
      await cerrar(t);
    });

    testWidgets('con avisos, Ejecutar espera la casilla «Revisé los avisos»', (
      t,
    ) async {
      await montar(t);
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      FilledButton ejecutar() =>
          t.widget<FilledButton>(botonDelDialogo('Ejecutar planilla'));
      expect(enDialogo('Revisé los avisos'), findsOneWidget);
      expect(ejecutar().onPressed, isNull);
      // Tocar el botón apagado no escribe nada.
      await t.tap(botonDelDialogo('Ejecutar planilla'), warnIfMissed: false);
      await esperar(t, 2);
      expect(repo.vecesDe('ejecutar'), 0);

      await t.tap(enDialogo('Revisé los avisos'));
      await esperar(t, 2);
      expect(ejecutar().onPressed, isNotNull);
      await t.tap(enDialogo('Revisé los avisos'));
      await esperar(t, 2);
      expect(ejecutar().onPressed, isNull);
      await cerrar(t);
    });

    testWidgets('el total va grande y en verde y la advertencia en un aviso', (
      t,
    ) async {
      await montar(t);
      await abrirPrevia(t);
      await abrirConfirmacion(t);
      final cs = Theme.of(t.element(find.byType(AlertDialog))).colorScheme;
      final hc = HexColores.desde(cs);
      final total = enDialogo('Bs 290,50');
      expect(total, findsOneWidget);
      final estilo = t.widget<Text>(total).style!;
      expect(estilo.color, hc.exito);
      expect(estilo.fontSize, greaterThanOrEqualTo(24));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(CifrasHex),
        ),
        findsOneWidget,
      );
      // La advertencia es una nota de aviso, no parte de la frase de arriba.
      final advertencia = find.ancestor(
        of: enDialogo('Después no se modifica; solo se puede anular.'),
        matching: find.byType(AvisoHex),
      );
      expect(advertencia, findsOneWidget);
      await cerrar(t);
    });

    testWidgets('«Imprimir / PDF» rotula el ícono del PDF en la lista y el '
        'encabezado', (t) async {
      await montar(t);
      await irAEjecutadas(t);
      expect(find.byTooltip('Imprimir / PDF'), findsWidgets);
      await tocar(t, find.text('Septiembre de 2026').first);
      expect(find.text('Imprimir / PDF'), findsOneWidget);
      expect(find.text('PDF'), findsNothing);
      await cerrar(t);
    });

    testWidgets(
      'en el teléfono imprimir es un botón a la vista de la tarjeta',
      (t) async {
        await montar(t, ancho: 390);
        await irAEjecutadas(t);
        final tarjeta = find.ancestor(
          of: find.textContaining('Septiembre de 2026').first,
          matching: find.byType(Card),
        );
        expect(
          find.descendant(of: tarjeta, matching: find.text('Imprimir / PDF')),
          findsOneWidget,
        );
        // Y no se repite dentro del menú de esa tarjeta.
        final botones = find.text('Imprimir / PDF').evaluate().length;
        await t.tap(
          find.descendant(of: tarjeta, matching: find.byIcon(Icons.more_vert)),
        );
        await esperar(t, 2);
        expect(find.text('Imprimir / PDF'), findsNWidgets(botones));
        expect(find.text('Ver planilla'), findsOneWidget);
        await t.tapAt(const Offset(5, 5));
        await esperar(t, 2);
        await cerrar(t);
      },
    );

    testWidgets('los conteos llevan separador de miles a la boliviana', (
      t,
    ) async {
      repo.programar('pendientes', [
        [
          HexPendienteEntity(
            codEmpresa: BigInt.two,
            codSucursal: BigInt.from(3),
            nombreSucursal: 'Planta El Alto',
            anio: 2026,
            mes: 10,
            cantidadReportes: 1234,
          ),
        ],
      ]);
      await montar(t);
      expect(find.text('1.234'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('barra de estado y vibración', () {
    testWidgets('el desplazamiento es el primario: tocar la barra de estado '
        'en iOS sube al inicio', (t) async {
      await montar(t, ancho: 390);
      verificarControlPrimarioHex(t, HexPlanillaScreen);
      await cerrar(t);
    });

    testWidgets('las pestañas, el chip del semáforo y la casilla vibran', (
      t,
    ) async {
      final vibraciones = capturarVibracionesHex();
      await montar(t, ancho: 390);
      await irAEjecutadas(t);
      expect(vibraciones, contains('selectionClick'));
      await tocar(t, find.text('Por ejecutar'));
      await abrirPrevia(t);
      vibraciones.clear();
      await t.tap(find.text('1 con aviso de biométrico'));
      await esperar(t, 3);
      expect(vibraciones, contains('lightImpact'));
      await abrirConfirmacion(t);
      vibraciones.clear();
      await t.tap(enDialogo('Revisé los avisos'));
      await esperar(t, 2);
      expect(vibraciones, contains('selectionClick'));
      await cerrar(t);
    });
  });

  group('anchos', () {
    /// Recorre las dos pestañas, la vista previa y las tres secciones.
    Future<void> recorrer(WidgetTester t) async {
      await abrirPrevia(t);
      await t.scrollUntilVisible(
        find.text('Leyenda de códigos'),
        200,
        scrollable: pagina(),
      );
      await esperar(t, 1);
      await t.scrollUntilVisible(
        find.text('Volver a pendientes'),
        -200,
        scrollable: pagina(),
      );
      await abrirConfirmacion(t);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await abrirPlanilla(t, 'Septiembre de 2026');
      await tocar(t, seccion('Anexo de detalle'));
      await t.scrollUntilVisible(
        find.text('como se pagó en esta planilla'),
        200,
        scrollable: pagina(),
      );
    }

    for (final ancho in [390.0, 800.0, 964.0, 1400.0]) {
      testWidgets('Planilla a $ancho px sin desbordes', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await recorrer(t);
        // Ninguna tabla va de lado: por debajo de su ancho, tarjetas.
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        if (ancho < 768) {
          expect(find.byWidgetPredicate(esVertical), findsOneWidget);
        }
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    // La lista mide la ventana menos 2 × 24 de relleno.
    for (final (ancho, tabla) in [(767.0, false), (768.0, true)]) {
      testWidgets('pendientes en el borde de 720 ($ancho px)', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        expect(
          find.text('Reportes aprobados'),
          tabla ? findsOneWidget : findsNothing,
        );
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    // Tres niveles del resumen sobre el ancho de la lista (ventana − 48):
    // tarjetas, tabla compacta desde 1040 y grilla completa desde 1680.
    for (final (ancho, nivel) in [
      (1087.0, 'tarjetas'),
      (1088.0, 'compacta'),
      (1098.0, 'compacta'), // 1366 con el menú abierto: lista de 1050
      (1652.0, 'compacta'), // 1920 con el menú abierto: lista de 1604
      (1727.0, 'compacta'),
      (1728.0, 'grilla'),
    ]) {
      testWidgets('resumen en $nivel a $ancho px', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await abrirPlanilla(t, 'Septiembre de 2026');
        expect(
          find.text('Costo hora (Bs)'),
          nivel == 'tarjetas' ? findsNothing : findsOneWidget,
        );
        expect(
          find.text('Horas por código'),
          nivel == 'compacta' ? findsOneWidget : findsNothing,
        );
        // «Cargo» es una columna solo de la grilla completa.
        expect(
          find.text('Cargo'),
          nivel == 'grilla' ? findsOneWidget : findsNothing,
        );
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('el resumen compacto aguanta el caso más cargado en su mínimo', (
      t,
    ) async {
      final errores = capturarErrores();
      // La suma de los `flex` de la tabla compacta, con el relleno de la fila.
      expect(anchoTablaResumenCompactoHex, 2.0 * 508 + 24);
      repo.programar('empleados', [_resumenCargado]);
      await montar(t, ancho: 1088);
      await abrirPlanilla(t, 'Septiembre de 2026');
      expect(find.text('Horas por código'), findsOneWidget);
      // Los montos más anchos caben en una línea, sin partirse.
      for (final monto in ['Bs 12.345,67', 'Bs 4.055,64', 'Bs 123,45']) {
        expect(find.text(monto), findsOneWidget, reason: monto);
        expect(t.getSize(find.text(monto)).height, lessThan(24), reason: monto);
      }
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    for (final (ancho, tabla) in [(1047.0, false), (1048.0, true)]) {
      testWidgets('vista previa en el borde de su tabla ($ancho px)', (
        t,
      ) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await abrirPrevia(t);
        expect(find.text('Marcas'), tabla ? findsOneWidget : findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    for (final (ancho, tabla) in [(1147.0, false), (1148.0, true)]) {
      testWidgets('ejecutadas en el borde de su tabla ($ancho px)', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await irAEjecutadas(t);
        expect(find.text('Ejecutó'), tabla ? findsOneWidget : findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    for (final (ancho, tabla) in [(1167.0, false), (1168.0, true)]) {
      testWidgets('anexo en el borde de su tabla ($ancho px)', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await abrirPlanilla(t, 'Septiembre de 2026');
        await tocar(t, seccion('Anexo de detalle'));
        expect(find.text('Total (Bs)'), tabla ? findsOneWidget : findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('a 390 px hay un solo desplazamiento vertical', (t) async {
      await montar(t, ancho: 390);
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      await abrirPrevia(t);
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Mamani Quispe Juan'),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      await abrirPlanilla(t, 'Septiembre de 2026');
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      await cerrar(t);
    });

    testWidgets(
      'los controles miden 48 px también en el escritorio',
      (t) async {
        await montar(t);
        double alto(Finder f) => t.getSize(f).height;
        expect(alto(find.byType(Tab).first), greaterThanOrEqualTo(48));
        await abrirPrevia(t);
        expect(alto(ejecutarEnPagina()), greaterThanOrEqualTo(48));
        expect(
          alto(
            find
                .ancestor(
                  of: find.text('Volver a pendientes'),
                  matching: find.byWidgetPredicate((w) => w is TextButton),
                )
                .first,
          ),
          greaterThanOrEqualTo(48),
        );
        await abrirPlanilla(t, 'Septiembre de 2026');
        expect(
          alto(find.widgetWithText(FilledButton, 'Imprimir / PDF')),
          greaterThanOrEqualTo(48),
        );
        expect(alto(seccion('Resumen')), greaterThanOrEqualTo(48));
        await cerrar(t);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    testWidgets('Planilla al 150 % en 390 px sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await abrirPrevia(t);
      await t.scrollUntilVisible(
        find.text('Mamani Quispe Juan'),
        150,
        scrollable: pagina(),
      );
      await tocar(t, find.text('Mamani Quispe Juan'));
      expect(find.text('Líneas de Mamani Quispe Juan'), findsOneWidget);
      await t.tapAt(const Offset(195, 20));
      await esperar(t, 3);
      await t.scrollUntilVisible(
        find.text('Volver a pendientes'),
        -150,
        scrollable: pagina(),
      );
      await abrirConfirmacion(t);
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await abrirPlanilla(t, 'Septiembre de 2026');
      await tocar(t, seccion('Anexo de detalle'));
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
            body: const HexPlanillaScreen(),
          ),
          ancho: 390,
          overrides: anulaciones(),
        );
        t.view.physicalSize = const Size(390, 741);
        await esperar(t);
        await abrirPrevia(t);
        await abrirConfirmacion(t);
        final campo = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        await t.showKeyboard(campo);
        t.view.viewInsets = const FakeViewPadding(bottom: 336);
        await esperar(t, 3);
        await t.enterText(campo, 'Horas extra de octubre');
        await esperar(t, 1);
        expect(errores, isEmpty, reason: detalle(errores));
        expect(
          botonDelDialogo('Ejecutar planilla').hitTestable(),
          findsOneWidget,
        );
        t.view.resetViewInsets();
        FocusManager.instance.primaryFocus?.unfocus();
        await esperar(t, 2);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}

/// La vista previa que se pide al confirmar tarda hasta que la prueba suelta
/// [espera]: deja ver el botón ocupado mientras recarga.
class _PlanillaLenta extends HexPlanillaFalso {
  _PlanillaLenta(HexPlanillaFalso base) {
    programar('pendientes', [_pendientes]);
    programar('vistaPrevia', [_previa]);
    programar('avisos', [_avisos]);
    base.llamadas.clear();
  }

  Completer<void>? espera;

  @override
  Future<List<HexPrevistaEmpleadoEntity>> vistaPrevia(CombinacionHex c) async {
    final pausa = espera;
    if (pausa != null) await pausa.future;
    return super.vistaPrevia(c);
  }
}

/// Empresas de `/rrhh/lst-empresas` sin red.
class _Rrhh extends Fake implements RRHHRepositoryImpl {
  _Rrhh(this.empresas);

  final List<EmpresaEntity> empresas;

  @override
  Future<List<EmpresaEntity>> lstEmpresas() async => empresas;
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS (como los devuelven los SP C, P, Q, W, R, A y G)
// ═══════════════════════════════════════════════════════════════════════════

final CombinacionHex _combinacion = (
  codEmpresa: BigInt.two,
  codSucursal: BigInt.from(3),
  anio: 2026,
  mes: 10,
);

final List<HexPendienteEntity> _pendientes = [
  HexPendienteEntity(
    codEmpresa: BigInt.two,
    codSucursal: BigInt.from(3),
    nombreSucursal: 'Planta El Alto',
    anio: 2026,
    mes: 10,
    cantidadReportes: 5,
  ),
  HexPendienteEntity(
    codEmpresa: BigInt.two,
    codSucursal: BigInt.from(4),
    nombreSucursal: 'Almacén Central',
    anio: 2026,
    mes: 9,
    cantidadReportes: 2,
  ),
];

final List<HexPrevistaEmpleadoEntity> _previa = [
  HexPrevistaEmpleadoEntity(
    codEmpleado: BigInt.from(41),
    nombreEmpleado: 'Choque Flores Pedro',
    nombreArea: 'Producción',
    montoComidas: 15,
    total: 15,
    esProvisional: true,
    cantidadReportes: 1,
  ),
  HexPrevistaEmpleadoEntity(
    codEmpleado: BigInt.from(40),
    nombreEmpleado: 'Mamani Quispe Juan',
    nombreArea: 'Producción',
    montoHoras: 245.5,
    montoComidas: 30,
    total: 275.5,
    cantidadReportes: 2,
    tieneAvisoBiometrico: true,
    tienePeriodoAnterior: true,
  ),
];

const String _detalleProvisional =
    'La empresa 2 no tiene ejecutada la planilla de sueldos de octubre de '
    '2026: el monto es provisional (usa el haber de la planilla de sueldos 15) '
    'y esta planilla no se puede ejecutar hasta que se ejecute la de sueldos.';

const String _detalleBiometrico =
    'El biométrico registra una salida el 05/10/2026 a las 21:40, pero las '
    'horas congeladas son de 05/10/2026 18:00 (HORARIO) a 05/10/2026 22:30 '
    '(APP). Revise el reporte antes de ejecutar la planilla.';

/// La vista previa que llega al confirmar: un reporte más de Mamani.
final List<HexPrevistaEmpleadoEntity> _previaNueva = [
  _previa.first,
  HexPrevistaEmpleadoEntity(
    codEmpleado: BigInt.from(40),
    nombreEmpleado: 'Mamani Quispe Juan',
    nombreArea: 'Producción',
    montoHoras: 345.5,
    montoComidas: 30,
    total: 375.5,
    cantidadReportes: 3,
    tieneAvisoBiometrico: true,
    tienePeriodoAnterior: true,
  ),
];

/// Los avisos al confirmar: además, un reporte que queda fuera.
final List<HexAvisoEntity> _avisosNuevos = [
  ..._avisos,
  HexAvisoEntity(
    idReporte: BigInt.from(104),
    codEmpleado: BigInt.from(43),
    nombreEmpleado: 'Quispe Limachi Rosa',
    fechaJornada: DateTime(2026, 10, 20),
    tipoAviso: 'SIN_HABER',
    detalle:
        'El empleado no figura en la planilla de sueldos ejecutada de octubre '
        'de 2026 de la empresa 2: el reporte no se liquida y sigue aprobado '
        'hasta que figure.',
  ),
];

final List<HexAvisoEntity> _avisos = [
  HexAvisoEntity(
    idReporte: BigInt.from(101),
    codEmpleado: BigInt.from(40),
    nombreEmpleado: 'Mamani Quispe Juan',
    fechaJornada: DateTime(2026, 10, 5),
    tipoAviso: 'BIOMETRICO',
    detalle: _detalleBiometrico,
  ),
  HexAvisoEntity(
    idReporte: BigInt.from(102),
    codEmpleado: BigInt.from(41),
    nombreEmpleado: 'Choque Flores Pedro',
    fechaJornada: DateTime(2026, 10, 12),
    tipoAviso: 'PROVISIONAL',
    detalle: _detalleProvisional,
  ),
];

HexPrevistaLineaEntity _linea(
  int idReporte,
  int empleado,
  DateTime jornada,
  String codigo,
  String leyenda,
  double cantidad,
  double? multiplicador,
  double valor,
  double monto,
) => HexPrevistaLineaEntity(
  idReporte: BigInt.from(idReporte),
  codEmpleado: BigInt.from(empleado),
  fechaJornada: jornada,
  tipo: 'DESPUES',
  tipoDia: 'HABIL',
  inicio: jornada.add(const Duration(hours: 18)),
  fin: jornada.add(const Duration(hours: 22, minutes: 30)),
  origenInicio: 'HORARIO',
  origenFin: 'APP',
  haberBasico: 3000,
  divisor: 240,
  costoHora: 12.5,
  concepto: multiplicador == null ? 'COMIDA' : 'TRAMO',
  codigo: codigo,
  leyenda: leyenda,
  cantidad: cantidad,
  multiplicador: multiplicador,
  valorUnitario: valor,
  monto: monto,
);

final List<HexPrevistaLineaEntity> _lineas = [
  _linea(102, 41, DateTime(2026, 10, 12), 'D', 'Desayuno', 1, null, 15, 15),
  _linea(101, 40, DateTime(2026, 10, 5), 'HS', 'Horas simples', 2, 1, 12.5, 25),
  _linea(
    101,
    40,
    DateTime(2026, 10, 5),
    'H50',
    'Horas al 50 %',
    2.5,
    1.5,
    18.75,
    46.88,
  ),
  _linea(103, 40, DateTime(2026, 9, 28), 'C', 'Cena', 1, null, 15, 15),
];

final List<HexPlanillaEmpleadoEntity> _resumen = [
  HexPlanillaEmpleadoEntity(
    nombreArea: 'Producción',
    ordenArea: 1,
    codEmpleado: BigInt.from(40),
    nombreEmpleado: 'Mamani Quispe Juan',
    cargo: 'Operador de máquina',
    costoHora: 12.5,
    hHS: 2,
    mHS: 25,
    hH50: 1.5,
    mH50: 28.13,
    cC: 1,
    cDC: 1,
    totalHoras: 53.13,
    totalComidas: 30,
    total: 83.13,
  ),
  HexPlanillaEmpleadoEntity(
    nombreArea: 'Producción',
    ordenArea: 1,
    codEmpleado: BigInt.from(41),
    nombreEmpleado: 'Choque Flores Pedro',
    cargo: 'Ayudante',
    costoHora: 10,
    cD: 1,
    totalComidas: 15,
    total: 15,
  ),
  HexPlanillaEmpleadoEntity(
    nombreArea: 'Almacén',
    ordenArea: 2,
    codSucursal: BigInt.from(3),
    nombreSucursal: 'Planta Senkata',
    ordenSucursal: 2,
    codEmpleado: BigInt.from(42),
    nombreEmpleado: 'Rojas Vargas Luis',
    cargo: 'Almacenero',
    costoHora: 12.5,
    hH100: 4,
    mH100: 100,
    hHF: 1,
    mHF: 30,
    mOtros: 10,
    // Como lo devuelve el SP: totalHoras ya incluye mOtros.
    totalHoras: 140,
    total: 140,
  ),
];

/// El empleado más cargado: nombre y cargo largos, todos los códigos y los
/// montos más anchos que se esperan.
final List<HexPlanillaEmpleadoEntity> _resumenCargado = [
  HexPlanillaEmpleadoEntity(
    nombreArea: 'Producción',
    ordenArea: 1,
    codEmpleado: BigInt.from(50),
    nombreEmpleado: 'Quispe Mamani de la Fuente Carlos Alberto',
    cargo: 'Jefe de turno de producción',
    costoHora: 123.45,
    hHS: 12,
    mHS: 1500,
    hH50: 8.5,
    mH50: 1234.56,
    hH100: 6.5,
    mH100: 2876.54,
    hHD: 8,
    mHD: 1234.5,
    hHF: 4,
    mHF: 987.65,
    cD: 1,
    cDD: 1,
    cA: 1,
    cDA: 1,
    cC: 1,
    cDC: 1,
    mOtros: 456.78,
    totalHoras: 8290.03,
    totalComidas: 4055.64,
    total: 12345.67,
  ),
];

final List<HexPlanillaDetalleEntity> _anexo = [
  HexPlanillaDetalleEntity(
    codEmpleado: BigInt.from(40),
    nombreEmpleado: 'Mamani Quispe Juan',
    nombreArea: 'Producción',
    idReporte: BigInt.from(101),
    fechaJornada: DateTime(2026, 9, 12),
    tipo: 'DESPUES',
    tipoTexto: 'Después del horario',
    tipoDia: 'HABIL',
    inicio: DateTime(2026, 9, 12, 18),
    fin: DateTime(2026, 9, 12, 21, 30),
    origenInicio: 'HORARIO',
    origenFin: 'BIOMETRICO',
    origenInicioTexto: 'Horario asignado',
    origenFinTexto: 'Marca del biométrico',
    haberBasico: 3000,
    divisor: 240,
    costoHora: 12.5,
    hHS: 2,
    hH50: 1.5,
    comidas: 'C,DC',
    montoHoras: 53.13,
    montoComidas: 30,
    total: 83.13,
  ),
  HexPlanillaDetalleEntity(
    codEmpleado: BigInt.from(41),
    nombreEmpleado: 'Choque Flores Pedro',
    nombreArea: 'Producción',
    idReporte: BigInt.from(102),
    fechaJornada: DateTime(2026, 9, 13),
    tipo: 'SIN_HORARIO',
    tipoTexto: 'Sin horario',
    tipoDia: 'DOMINGO',
    motivo: 'Inventario de fin de mes.',
    inicio: DateTime(2026, 9, 13, 8),
    fin: DateTime(2026, 9, 13, 11),
    origenInicio: 'APP',
    origenFin: 'EDITADO',
    origenInicioTexto: 'Marcada en la app',
    origenFinTexto: 'Editada por el encargado',
    haberBasico: 2400,
    divisor: 240,
    costoHora: 10,
    hHD: 3,
    comidas: 'D',
    montoComidas: 15,
    total: 15,
  ),
];

final List<HexCodigoLeyendaEntity> _leyenda = [
  const HexCodigoLeyendaEntity(
    concepto: 'TRAMO',
    codigo: 'HS',
    leyenda: 'Horas simples',
    multiplicador: 1,
  ),
  const HexCodigoLeyendaEntity(
    concepto: 'TRAMO',
    codigo: 'H50',
    leyenda: 'Horas al 50 %',
    multiplicador: 1.5,
  ),
  const HexCodigoLeyendaEntity(
    concepto: 'TRAMO',
    codigo: 'HD',
    leyenda: 'Horas en domingo',
    multiplicador: 2,
  ),
  const HexCodigoLeyendaEntity(
    concepto: 'COMIDA',
    codigo: 'C',
    leyenda: 'Cena',
    valorUnitario: 15,
  ),
  const HexCodigoLeyendaEntity(
    concepto: 'COMIDA',
    codigo: 'DC',
    leyenda: 'Doble cena',
    valorUnitario: 15,
  ),
];
