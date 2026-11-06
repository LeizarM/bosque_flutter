import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_anular_planilla_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// «Anular planilla» (RRHH): las ejecutadas con «Anular», la confirmación con
/// lo que se anula y el motivo, 400, 409 y 403, doble toque, las anuladas con
/// su motivo, permisos por botón, anchos y teclado.
void main() {
  setUpAll(cargarFuentesHex);

  late HexPlanillaFalso repo;

  setUp(() => repo = HexPlanillaFalso());

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  List<Override> anulaciones() => [
    hexPlanillaRepositoryProvider.overrideWithValue(repo),
    empresasProvider.overrideWith(
      (ref) => EmpresasNotifier(
        _Rrhh([
          EmpresaEntity(
            codEmpresa: 2,
            nombre: 'Impexpap',
            codPadre: 0,
            sigla: 'IPX',
            audUsuario: 0,
          ),
        ]),
      ),
    ),
  ];

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
  }) async {
    await montarHex(
      t,
      const HexAnularPlanillaScreen(),
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

  Finder campoDelDialogo() => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  /// Un aviso del kit: se dibuja en la capa superior, fuera de la pantalla.
  Finder aviso(String texto) => find.byElementPredicate((e) {
    final w = e.widget;
    return w is Text &&
        w.data == texto &&
        e.findAncestorWidgetOfExactType<HexAnularPlanillaScreen>() == null;
  });

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

  /// «Anular» de la fila ejecutada: en la tabla es un icono con ayuda; en
  /// tarjetas, un elemento del menú de la tarjeta.
  Future<void> abrirAnular(WidgetTester t) async {
    final enLinea = find.byTooltip('Anular');
    if (enLinea.evaluate().isNotEmpty) {
      await tocar(t, enLinea, fotogramas: 3);
    } else {
      await tocar(t, find.byTooltip('Acciones'), fotogramas: 2);
      await t.tap(find.text('Anular'));
      await esperar(t, 3);
    }
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  Future<void> verAnuladas(WidgetTester t) =>
      tocar(t, find.text('Ver anuladas'));

  group('lista', () {
    testWidgets('por defecto solo muestra las ejecutadas', (t) async {
      await montar(t);
      expect(find.textContaining('Septiembre de 2026'), findsOneWidget);
      expect(find.textContaining('Agosto de 2026'), findsNothing);
      expect(find.text('Ejecutada'), findsOneWidget);
      expect(find.text('Impexpap'), findsOneWidget);
      expect(t.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(repo.vecesDe('planillas'), 1);
      expect(repo.argumentosDe('planillas').single['idPlanilla'], isNull);
      await cerrar(t);
    });

    testWidgets('Ver anuladas muestra quién, cuándo y por qué', (t) async {
      await montar(t);
      await verAnuladas(t);
      expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.textContaining('Agosto de 2026'), findsOneWidget);
      expect(
        find.text(
          'Anulada por Salazar Rivera Jorge el 03/09/2026 16:45. Motivo: Se '
          'ejecutó con el haber básico anterior.',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ChipHex &&
              w.texto == 'Anulada' &&
              w.tono == TonoHex.neutro &&
              w.icono == Icons.block,
        ),
        findsOneWidget,
      );
      // La anulada no se paga: su total lo dice.
      expect(find.text('Bs 7.580,00'), findsOneWidget);
      expect(find.text('no se paga'), findsOneWidget);
      // Solo la ejecutada se puede anular.
      expect(find.byTooltip('Anular'), findsOneWidget);
      // Volver a apagarlo oculta la anulada.
      await verAnuladas(t);
      expect(find.textContaining('Agosto de 2026'), findsNothing);
      expect(repo.vecesDe('planillas'), 1);
      await cerrar(t);
    });

    testWidgets('no ofrece ver el reporte, la planilla ni el PDF', (t) async {
      await montar(t);
      await verAnuladas(t);
      for (final accion in ['Ver reporte', 'Ver planilla', 'Ver PDF']) {
        expect(find.byTooltip(accion), findsNothing);
        expect(find.text(accion), findsNothing);
      }
      await cerrar(t);
    });

    testWidgets('sin ejecutadas dice que las anuladas están ocultas', (
      t,
    ) async {
      repo.programar('planillas', [
        [planillasFalsas[1]],
      ]);
      await montar(t);
      expect(find.text('No hay planillas ejecutadas'), findsOneWidget);
      expect(
        find.text(
          'Las planillas anuladas están ocultas: activa «Ver anuladas» para '
          'verlas.',
        ),
        findsOneWidget,
      );
      await verAnuladas(t);
      expect(find.textContaining('Agosto de 2026'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin ninguna planilla explica para qué sirve', (t) async {
      repo.programar('planillas', [<HexPlanillaEntity>[]]);
      await montar(t);
      expect(find.text('No hay planillas ejecutadas'), findsOneWidget);
      expect(
        find.text(
          'Las planillas que RRHH ejecute aparecen aquí para poder anularlas.',
        ),
        findsOneWidget,
      );
      await cerrar(t);
    });

    testWidgets('un 403 al listar muestra No tienes permiso', (t) async {
      repo.programar('planillas', [const SinPermisoHex('Sin permiso.')]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.byTooltip('Anular'), findsNothing);
      await cerrar(t);
    });

    testWidgets('un error del SP al listar se muestra tal cual', (t) async {
      repo.programar('planillas', [
        const NegocioHex('Pantalla no habilitada.'),
      ]);
      await montar(t);
      expect(find.text('Pantalla no habilitada.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('con más de 20 planillas se pagina', (t) async {
      repo.programar('planillas', [
        [for (var i = 1; i <= 25; i++) _ejecutada(i)],
      ]);
      await montar(t, ancho: 390);
      expect(find.byType(BosquePaginator), findsOneWidget);
      await cerrar(t);
    });
  });

  group('anular', () {
    testWidgets('anular manda el motivo y recarga', (t) async {
      repo
        ..programar('planillas', [
          planillasFalsas,
          [_anulada5, planillasFalsas[1]],
        ])
        ..programar('anular', [
          (id: BigInt.from(5), mensaje: 'Planilla anulada.'),
        ]);
      await montar(t);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), '  Se cargó dos veces  ');
      await t.tap(botonDelDialogo('Anular planilla'));
      await esperar(t, 4);
      final args = repo.argumentosDe('anular').single;
      expect(args['idPlanilla'], BigInt.from(5));
      expect(args['observacion'], 'Se cargó dos veces');
      expect(args.keys.toSet(), {'idPlanilla', 'observacion'});
      expect(find.byType(AlertDialog), findsNothing);
      expect(aviso('Planilla anulada.'), findsOneWidget);
      // La lista se pidió otra vez y ya no tiene la planilla anulada.
      expect(repo.vecesDe('planillas'), 2);
      expect(find.textContaining('Septiembre de 2026'), findsNothing);
      expect(find.text('No hay planillas ejecutadas'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('anular también recarga lo pendiente de ejecutar', (t) async {
      await montar(t);
      final container = ProviderScope.containerOf(
        t.element(find.byType(HexAnularPlanillaScreen)),
      );
      final escucha = container.listen(hexPendientesProvider, (_, __) {});
      addTearDown(escucha.close);
      await esperar(t, 2);
      expect(repo.vecesDe('pendientes'), 1);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), 'Error de carga');
      await t.tap(botonDelDialogo('Anular planilla'));
      await esperar(t, 4);
      expect(repo.vecesDe('pendientes'), 2);
      await cerrar(t);
    });

    testWidgets('la confirmación dice exactamente qué se anula', (t) async {
      await montar(t);
      await abrirAnular(t);
      expect(
        enDialogo(
          'Se anulará la planilla de Planta El Alto, Septiembre de 2026, por '
          'Bs 9.035,50. Sus reportes quedan anulados para siempre: no vuelven '
          'a ninguna planilla ni se pueden volver a ejecutar.',
        ),
        findsOneWidget,
      );
      expect(
        enDialogo('Paga Impexpap · 14 empleados · 37 reportes'),
        findsOneWidget,
      );
      expect(enDialogo('Anular planilla'), findsNWidgets(2));
      expect(enDialogo('Motivo de la anulación'), findsOneWidget);
      expect(enDialogo('Obligatorio.'), findsOneWidget);
      // Destructiva: el botón va en el color de error del tema.
      final boton = t.widget<FilledButton>(botonDelDialogo('Anular planilla'));
      expect(
        boton.style?.backgroundColor?.resolve({}),
        Theme.of(
          t.element(botonDelDialogo('Anular planilla')),
        ).colorScheme.error,
      );
      // Nada se manda hasta confirmar.
      expect(repo.vecesDe('anular'), 0);
      await cerrar(t);
    });

    testWidgets('cancelar no manda nada y cierra', (t) async {
      await montar(t);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), 'Lo pienso');
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 3);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.vecesDe('anular'), 0);
      expect(repo.vecesDe('planillas'), 1);
      await cerrar(t);
    });

    testWidgets('ya anulada (409) muestra el mensaje y recarga', (t) async {
      repo
        ..programar('planillas', [
          planillasFalsas,
          [_anulada5, planillasFalsas[1]],
        ])
        ..programar('anular', [
          const ConflictoHex('La planilla ya está anulada.'),
        ]);
      await montar(t);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), 'Error de carga');
      await t.tap(botonDelDialogo('Anular planilla'));
      await esperar(t, 4);
      expect(repo.vecesDe('anular'), 1);
      expect(aviso('La planilla ya está anulada.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.vecesDe('planillas'), 2);
      expect(find.textContaining('Septiembre de 2026'), findsNothing);
      await cerrar(t);
    });

    testWidgets('sin motivo el SP responde 400 y el diálogo sigue abierto', (
      t,
    ) async {
      const regla = 'El motivo de la anulación es obligatorio.';
      repo.programar('anular', [const NegocioHex(regla)]);
      await montar(t);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), '   ');
      await t.tap(botonDelDialogo('Anular planilla'));
      await esperar(t, 4);
      // La app no valida: manda el motivo vacío y muestra la regla tal cual.
      expect(repo.argumentosDe('anular').single['observacion'], '');
      expect(aviso(regla), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repo.vecesDe('planillas'), 1);
      // El botón se libera para corregir y reintentar.
      expect(
        t.widget<FilledButton>(botonDelDialogo('Anular planilla')).onPressed,
        isNotNull,
      );
      await t.enterText(campoDelDialogo(), 'Error de carga');
      repo.programar('anular', [(id: BigInt.from(5), mensaje: 'Listo.')]);
      await t.tap(botonDelDialogo('Anular planilla'));
      await esperar(t, 4);
      expect(repo.argumentosDe('anular').last['observacion'], 'Error de carga');
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });

    testWidgets('un 403 al anular dice que no tiene permiso', (t) async {
      repo.programar('anular', [const SinPermisoHex('Sin permiso.')]);
      await montar(t);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), 'Error de carga');
      await t.tap(botonDelDialogo('Anular planilla'));
      await esperar(t, 4);
      expect(aviso('No tienes permiso para esta acción.'), findsOneWidget);
      expect(repo.vecesDe('planillas'), 1);
      await cerrar(t);
    });

    testWidgets('doble toque: un solo pedido y el botón queda ocupado', (
      t,
    ) async {
      repo.pausa = Completer<void>();
      await montar(t);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), 'Error de carga');
      // Dos activaciones antes de redibujar, como un doble toque rápido.
      final alTocar =
          t.widget<FilledButton>(botonDelDialogo('Anular planilla')).onPressed!;
      alTocar();
      alTocar();
      await esperar(t, 1);
      expect(
        t.widget<FilledButton>(botonDelDialogo('Anular planilla')).onPressed,
        isNull,
      );
      expect(repo.vecesDe('anular'), 1);
      repo.pausa!.complete();
      await esperar(t, 4);
      expect(repo.vecesDe('anular'), 1);
      expect(repo.vecesDe('planillas'), 2);
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });

    testWidgets('mientras anula no se cierra ni se edita', (t) async {
      repo.pausa = Completer<void>();
      await montar(t);
      await abrirAnular(t);
      await t.enterText(campoDelDialogo(), 'Error de carga');
      await t.tap(botonDelDialogo('Anular planilla'));
      await esperar(t, 1);
      // El «atrás» del sistema no lo cierra y los controles se deshabilitan.
      await TestWidgetsFlutterBinding.instance.handlePopRoute();
      await esperar(t, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        t
            .widget<TextButton>(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.widgetWithText(TextButton, 'Cancelar'),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(t.widget<TextField>(campoDelDialogo()).enabled, isFalse);
      repo.pausa!.complete();
      await esperar(t, 4);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.vecesDe('anular'), 1);
      await cerrar(t);
    });
  });

  group('permisos', () {
    testWidgets('sin btnHexAnularPlanilla no hay Anular', (t) async {
      await montar(t, botones: {BotonHex.pdfPlanilla});
      expect(find.textContaining('Septiembre de 2026'), findsOneWidget);
      expect(find.byTooltip('Anular'), findsNothing);
      await cerrar(t);
    });

    testWidgets('sin btnHexAnularPlanilla tampoco en tarjetas', (t) async {
      await montar(t, ancho: 390, botones: {BotonHex.pdfPlanilla});
      expect(find.textContaining('Septiembre de 2026'), findsOneWidget);
      expect(find.byTooltip('Acciones'), findsNothing);
      await cerrar(t);
    });

    testWidgets('con btnHexAnularPlanilla hay Anular', (t) async {
      await montar(t, botones: {BotonHex.anularPlanilla});
      expect(find.byTooltip('Anular'), findsOneWidget);
      await abrirAnular(t);
      await cerrar(t);
    });
  });

  group('barra de estado y vibración', () {
    testWidgets('el desplazamiento es el primario: tocar la barra de estado '
        'en iOS sube al inicio', (t) async {
      await montar(t, ancho: 390);
      verificarControlPrimarioHex(t, HexAnularPlanillaScreen);
      await cerrar(t);
    });

    testWidgets('el interruptor «Ver anuladas» vibra al activarse', (t) async {
      final vibraciones = capturarVibracionesHex();
      await montar(t, ancho: 390);
      await t.tap(find.text('Ver anuladas'));
      await esperar(t, 2);
      expect(vibraciones, contains('lightImpact'));
      await cerrar(t);
    });
  });

  group('anchos', () {
    for (final ancho in [390.0, 800.0, 964.0, 1400.0]) {
      testWidgets('Anular planilla a $ancho px sin desbordes', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await verAnuladas(t);
        expect(find.textContaining('Agosto de 2026'), findsOneWidget);
        await abrirAnular(t);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);
        if (ancho < 768) {
          expect(find.byWidgetPredicate(esLateral), findsNothing);
          expect(find.byWidgetPredicate(esVertical), findsOneWidget);
        }
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    // La lista mide la ventana menos 2 × 24 de relleno.
    for (final (ancho, tabla) in [(1327.0, false), (1328.0, true)]) {
      testWidgets('tabla o tarjetas en el borde de 1280 ($ancho px)', (
        t,
      ) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        await verAnuladas(t);
        expect(find.text('Ejecutó'), tabla ? findsOneWidget : findsNothing);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(find.byTooltip('Anular'), tabla ? findsOneWidget : findsNothing);
        expect(
          find.byTooltip('Acciones'),
          tabla ? findsNothing : findsOneWidget,
        );
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('en la tabla el motivo de la anulada está en su fila', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t);
      await verAnuladas(t);
      for (final cabecera in ['Período', 'Estado', 'Total (Bs)', 'Ejecutó']) {
        expect(find.text(cabecera), findsOneWidget);
      }
      expect(
        find.textContaining('Motivo: Se ejecutó con el haber básico anterior.'),
        findsOneWidget,
      );
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('a 390 px hay un solo desplazamiento vertical', (t) async {
      await montar(t, ancho: 390);
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      await verAnuladas(t);
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      await cerrar(t);
    });

    testWidgets(
      'los controles miden 48 px también en el escritorio',
      (t) async {
        await montar(t);
        double alto(Finder f) => t.getSize(f).height;
        expect(alto(find.byType(SwitchListTile)), greaterThanOrEqualTo(48));
        final anular = t.getSize(find.byTooltip('Anular'));
        expect(anular.height, greaterThanOrEqualTo(48));
        expect(anular.width, greaterThanOrEqualTo(48));
        await cerrar(t);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    testWidgets('en el teléfono los botones del diálogo miden 48 px', (
      t,
    ) async {
      await montar(t, ancho: 390);
      await abrirAnular(t);
      for (final f in [
        botonDelDialogo('Anular planilla'),
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Cancelar'),
        ),
      ]) {
        expect(t.getSize(f).height, greaterThanOrEqualTo(48));
      }
      await cerrar(t);
    });

    testWidgets('al 150 % en 390 px sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await verAnuladas(t);
      expect(find.textContaining('Agosto de 2026'), findsOneWidget);
      await abrirAnular(t);
      await t.tap(enDialogo('Cancelar'));
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
            body: const HexAnularPlanillaScreen(),
          ),
          ancho: 390,
          overrides: anulaciones(),
        );
        t.view.physicalSize = const Size(390, 741);
        await esperar(t);
        await abrirAnular(t);
        await t.showKeyboard(campoDelDialogo());
        t.view.viewInsets = const FakeViewPadding(bottom: 336);
        await esperar(t, 3);
        await t.enterText(
          campoDelDialogo(),
          'Se ejecutó con el haber básico anterior y hay que volver a '
          'ejecutarla con el nuevo.',
        );
        await esperar(t, 1);
        expect(errores, isEmpty, reason: detalle(errores));
        expect(
          botonDelDialogo('Anular planilla').hitTestable(),
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

/// Empresas de `/rrhh/lst-empresas` sin red.
class _Rrhh extends Fake implements RRHHRepositoryImpl {
  _Rrhh(this.empresas);

  final List<EmpresaEntity> empresas;

  @override
  Future<List<EmpresaEntity>> lstEmpresas() async => empresas;
}

/// La planilla 5 de los datos de ejemplo, ya anulada.
final HexPlanillaEntity _anulada5 = HexPlanillaEntity(
  idPlanilla: BigInt.from(5),
  codEmpresa: BigInt.from(2),
  anio: 2026,
  mes: 9,
  periodoTexto: 'Septiembre de 2026',
  codSucursal: planillasFalsas[0].codSucursal,
  nombreSucursal: 'Planta El Alto',
  estado: 'ANULADA',
  estadoTexto: 'Anulada',
  fechaEjecucion: DateTime(2026, 10, 3, 10, 20),
  nombreEjecutor: 'Gutiérrez Paz Ana',
  total: 9035.5,
  cantidadEmpleados: 14,
  cantidadReportes: 37,
  motivoAnulacion: 'Se cargó dos veces.',
  fechaAnulacion: DateTime(2026, 10, 31, 9),
  nombreAnulador: 'Salazar Rivera Jorge',
);

/// Una planilla ejecutada más, para llenar una página.
HexPlanillaEntity _ejecutada(int n) => HexPlanillaEntity(
  idPlanilla: BigInt.from(100 + n),
  codEmpresa: BigInt.from(2),
  anio: 2026,
  mes: 1 + n % 12,
  periodoTexto: 'Planilla $n',
  codSucursal: BigInt.from(3),
  nombreSucursal: 'Planta El Alto',
  estado: 'EJECUTADA',
  estadoTexto: 'Ejecutada',
  fechaEjecucion: DateTime(2026, 10, 3, 10, 20),
  nombreEjecutor: 'Gutiérrez Paz Ana',
  total: 100.0 * n,
  cantidadEmpleados: 2,
  cantidadReportes: 4,
);
