import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_vigencias.dart';

import 'fakes/arnes_hex.dart';

/// Rediseño de Horas Extras, parte 2: formatos de números y fechas, vibración,
/// pestañas, botón principal, lista que se nota desplazable, diálogo con
/// efecto y vigencias. Las pantallas se prueban en sus propios archivos.
void main() {
  setUpAll(cargarFuentesHex);

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  group('formatos locales', () {
    test('los conteos llevan separador de miles a la boliviana', () {
      expect(enteroHex(7), '7');
      expect(enteroHex(1234), '1.234');
      expect(enteroHex(1234567), '1.234.567');
      expect(enteroHex(null), '—');
      expect(cuentaHex(1, 'reporte', 'reportes'), '1 reporte');
      expect(cuentaHex(1234, 'reporte', 'reportes'), '1.234 reportes');
    });

    test('las fechas salen de DateFormat como dd/MM/aaaa', () {
      final f = DateTime(2026, 10, 5, 7, 5);
      expect(fechaHex(f), '05/10/2026');
      expect(fechaHex(null), '—');
      expect(relojHex(f), '07:05');
      expect(relojHex(null), '—');
      expect(diaMesHex(f), '05/10');
      expect(fechaHoraHex(f), '05/10/2026 07:05');
      expect(fechaHoraHex(null), '—');
    });

    test('el período lleva el mes en español y el año sin separador', () {
      expect(periodoHex(2026, 10), 'octubre de 2026');
      expect(periodoHex(2026, 1), 'enero de 2026');
      expect(periodoHex(2026, 12), 'diciembre de 2026');
      expect(periodoHex(2026, 0), '—');
      expect(periodoHex(2026, 13), '—');
    });

    test('nunca se muestra «null», un vacío ni un texto con solo espacios', () {
      expect(oGuionHex(null), '—');
      expect(oGuionHex(''), '—');
      expect(oGuionHex('   '), '—');
      expect(oGuionHex('null'), '—');
      expect(oGuionHex('  Planta El Alto '), 'Planta El Alto');
      expect(textoUsableHex(null), isNull);
      expect(textoUsableHex('null'), isNull);
      expect(textoUsableHex(' '), isNull);
      expect(
        textoUsableHex(' Rige desde el 01/01/2026 '),
        'Rige desde el 01/01/2026',
      );
    });
  });

  group('vibración', () {
    testWidgets('cada momento usa su toque y un fallo del sistema no rompe', (
      t,
    ) async {
      final vibraciones = capturarVibracionesHex();
      HapticaHex.seleccion();
      HapticaHex.toque();
      HapticaHex.exito();
      HapticaHex.aviso();
      await t.pump();
      expect(vibraciones, [
        'selectionClick',
        'lightImpact',
        'lightImpact',
        'mediumImpact',
      ]);
      await t.pump();
    });

    testWidgets('sin canal de plataforma no lanza', (t) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async {
            throw PlatformException(code: 'sin-vibrador');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final errores = capturarErrores();
      HapticaHex.toque();
      await t.pump();
      expect(errores, isEmpty, reason: detalle(errores));
    });
  });

  group('pestañas con ícono y contador', () {
    Widget barra(TabController c, {int? cuenta}) => Column(
      children: [
        BarraPestanasHex(
          controlador: c,
          anchoMaximo: 520,
          pestanas: [
            pestanaHex(icono: Icons.tune, texto: 'Parámetros'),
            pestanaHex(
              icono: Icons.pending_actions,
              texto: 'Por ejecutar',
              cuenta: cuenta,
              tonoCuenta: TonoHex.pendiente,
            ),
            pestanaHex(icono: Icons.restaurant_outlined, texto: 'Comidas'),
          ],
        ),
      ],
    );

    testWidgets('cada pestaña lleva su ícono; el contador va formateado', (
      t,
    ) async {
      late TabController control;
      await montarHex(
        t,
        _ConPestanas(
          armar: (c) {
            control = c;
            return barra(c, cuenta: 1234);
          },
        ),
        ancho: 600,
      );
      await esperar(t, 2);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.pending_actions), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
      expect(find.text('1.234'), findsOneWidget);
      expect(control.length, 3);
      await cerrar(t);
    });

    testWidgets('sin contador no se dibuja ficha', (t) async {
      await montarHex(t, _ConPestanas(armar: (c) => barra(c)), ancho: 600);
      await esperar(t, 2);
      expect(find.byType(ChipHex), findsNothing);
      await cerrar(t);
    });

    for (final ancho in [320.0, 390.0]) {
      testWidgets('a $ancho px y letra al 150 % el texto se acorta, no '
          'desborda', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          _ConPestanas(armar: (c) => barra(c, cuenta: 12)),
          ancho: ancho,
        );
        await esperar(t, 2);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('tocar una pestaña vibra con un toque de selección', (t) async {
      final vibraciones = capturarVibracionesHex();
      await montarHex(t, _ConPestanas(armar: (c) => barra(c)), ancho: 600);
      await esperar(t, 2);
      await t.tap(find.text('Comidas'));
      await esperar(t, 2);
      expect(vibraciones, ['selectionClick']);
      await cerrar(t);
    });
  });

  group('botón principal de una acción', () {
    const principales = {BotonHex.vistoBueno};

    test('es la primera acción con un botón principal; si no hay, ninguna', () {
      final ver = AccionHex('Ver detalle', Icons.visibility_outlined, () {});
      final visto = AccionHex(
        'Visto bueno',
        Icons.task_alt,
        () {},
        boton: BotonHex.vistoBueno,
      );
      final rechazar = AccionHex(
        'Rechazar',
        Icons.block,
        () {},
        boton: BotonHex.rechazar,
      );
      expect(accionPrincipalHex([ver, visto, rechazar], principales), visto);
      expect(accionPrincipalHex([ver, rechazar], principales), isNull);
      expect(accionPrincipalHex([], principales), isNull);
      expect(accionPrincipalHex([ver, visto], const {}), isNull);
    });

    testWidgets('con texto: 48 px de alto y el texto del botón', (t) async {
      var toques = 0;
      await montarHex(
        t,
        Center(
          child: BotonPrincipalHex(
            AccionHex(
              'Visto bueno',
              Icons.task_alt,
              () => toques++,
              boton: BotonHex.vistoBueno,
              textoPrincipal: 'Dar visto bueno',
              tono: TonoHex.terciario,
            ),
          ),
        ),
        ancho: 600,
      );
      expect(find.text('Dar visto bueno'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(
        t.getSize(find.bySubtype<FilledButton>()).height,
        greaterThanOrEqualTo(48),
      );
      await t.tap(find.text('Dar visto bueno'));
      expect(toques, 1);
      await cerrar(t);
    });

    testWidgets('solo ícono: 48 px de área táctil y su ayuda', (t) async {
      await montarHex(
        t,
        Center(
          child: BotonPrincipalHex(
            AccionHex(
              'Aprobar',
              Icons.verified_outlined,
              () {},
              boton: BotonHex.aprobar,
              tono: TonoHex.exito,
            ),
            conTexto: false,
          ),
        ),
        ancho: 600,
      );
      expect(find.byTooltip('Aprobar'), findsOneWidget);
      expect(find.text('Aprobar'), findsNothing);
      final tamano = t.getSize(find.byType(IconButton));
      expect(tamano.width, greaterThanOrEqualTo(48));
      expect(tamano.height, greaterThanOrEqualTo(48));
      await cerrar(t);
    });

    testWidgets('sin el botón del usuario no se dibuja nada', (t) async {
      await montarHex(
        t,
        Center(
          child: BotonPrincipalHex(
            AccionHex(
              'Aprobar',
              Icons.verified_outlined,
              () {},
              boton: BotonHex.aprobar,
            ),
            expandido: true,
          ),
        ),
        ancho: 600,
        botones: {BotonHex.rechazar},
      );
      expect(find.text('Aprobar'), findsNothing);
      expect(find.bySubtype<FilledButton>(), findsNothing);
      await cerrar(t);
    });

    testWidgets('la tarjeta lo pone al pie, a todo el ancho, y lo saca del '
        'menú', (t) async {
      final r = _reporte();
      await montarHex(
        t,
        TarjetaReporteHex(
          r,
          principales: principales,
          acciones: [
            AccionHex('Ver detalle', Icons.visibility_outlined, () {}),
            AccionHex(
              'Visto bueno',
              Icons.task_alt,
              () {},
              boton: BotonHex.vistoBueno,
              textoPrincipal: 'Dar visto bueno',
            ),
            AccionHex(
              'Rechazar',
              Icons.block,
              () {},
              boton: BotonHex.rechazar,
              destructiva: true,
            ),
          ],
        ),
        ancho: 390,
      );
      await esperar(t, 2);
      final tarjeta = find.byType(Card);
      final boton = find.descendant(
        of: tarjeta,
        matching: find.text('Dar visto bueno'),
      );
      expect(boton, findsOneWidget);
      // Al pie: debajo del avance y del contenido.
      expect(
        t.getTopLeft(boton).dy,
        greaterThan(t.getTopLeft(find.text('Ana Mamani Quispe')).dy),
      );
      await t.tap(find.byIcon(Icons.more_vert));
      await esperar(t, 2);
      expect(find.text('Visto bueno'), findsNothing);
      expect(find.text('Ver detalle'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('en el menú abrir quita el foco del campo que se escribía', (
      t,
    ) async {
      final foco = FocusNode();
      addTearDown(foco.dispose);
      await montarHex(
        t,
        Column(
          children: [
            TextField(focusNode: foco),
            AccionesHex(
              enMenu: true,
              acciones: [AccionHex('Ver detalle', Icons.visibility, () {})],
            ),
          ],
        ),
        ancho: 390,
      );
      foco.requestFocus();
      await esperar(t, 1);
      expect(foco.hasFocus, isTrue);
      await t.tap(find.byIcon(Icons.more_vert));
      await esperar(t, 2);
      expect(foco.hasFocus, isFalse);
      await cerrar(t);
    });
  });

  group('lista que se desplaza de lado', () {
    Widget lista() => ListadoHex<int>(
      filas: const [1, 2, 3],
      columnas: [
        for (var i = 1; i <= 12; i++)
          BosqueColumn<int>(
            label: 'Columna $i',
            cellBuilder: (f) => Text('$f-$i'),
          ),
      ],
      tarjeta: (f) => Text('Tarjeta $f'),
    );

    Finder lateral() => find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );

    testWidgets('el borde que sigue con tabla se desvanece', (t) async {
      final errores = capturarErrores();
      await montarHex(
        t,
        Padding(padding: const EdgeInsets.all(16), child: lista()),
        ancho: 800,
      );
      await esperar(t, 2);
      // Un ShaderMask con el desvanecido envuelve al desplazamiento lateral.
      expect(
        find.ancestor(of: lateral(), matching: find.byType(ShaderMask)),
        findsOneWidget,
      );
      final pos =
          t
              .state<ScrollableState>(
                find
                    .descendant(
                      of: lateral(),
                      matching: find.byType(Scrollable),
                    )
                    .first,
              )
              .position;
      expect(pos.maxScrollExtent, greaterThan(0));
      // Al final de la tabla el desvanecido sigue construido y sin errores.
      await t.drag(lateral(), const Offset(-4000, 0));
      await esperar(t, 3);
      expect(pos.pixels, pos.maxScrollExtent);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('sin sangría se corta en el relleno de la página', (t) async {
      await montarHex(
        t,
        Padding(padding: const EdgeInsets.all(16), child: lista()),
        ancho: 800,
      );
      await esperar(t, 2);
      final r = t.getRect(lateral());
      expect(r.left, 16);
      expect(r.right, 784);
      await cerrar(t);
    });

    testWidgets('con la sangría de la página llega hasta el borde', (t) async {
      final errores = capturarErrores();
      await montarHex(
        t,
        SangriaHex(
          valor: 16,
          child: Padding(padding: const EdgeInsets.all(16), child: lista()),
        ),
        ancho: 800,
      );
      await esperar(t, 2);
      final r = t.getRect(lateral());
      expect(r.left, 0);
      expect(r.right, 800);
      // Al reposo, la primera columna sigue alineada con el relleno.
      expect(t.getTopLeft(find.text('Columna 1')).dx, greaterThanOrEqualTo(16));
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });

  group('diálogo con efecto', () {
    Future<void> abrir(
      WidgetTester t, {
      String? subtitulo,
      bool aceptar = true,
      OcupadoHex? ocupado,
    }) async {
      await montarHex(
        t,
        Builder(
          builder:
              (context) => Center(
                child: FilledButton(
                  onPressed:
                      () => showDialog<void>(
                        context: context,
                        builder:
                            (_) => DialogoHex(
                              titulo: 'Firmar',
                              subtitulo: subtitulo,
                              icono: Icons.task_alt,
                              ocupado: ocupado ?? OcupadoHex(),
                              accion: 'Aceptar',
                              aceptarHabilitado: aceptar,
                              alAceptar: () {},
                              contenido:
                                  (enCurso) => [
                                    TextoLargoHex(
                                      control: TextEditingController(),
                                      etiqueta: 'Observación',
                                      ayuda: 'Obligatorio.',
                                      habilitado: !enCurso,
                                    ),
                                  ],
                            ),
                      ),
                  child: const Text('Abrir'),
                ),
              ),
        ),
        ancho: 390,
      );
      await t.tap(find.text('Abrir'));
      await esperar(t, 3);
    }

    testWidgets('el subtítulo va bajo el título, siempre a la vista', (
      t,
    ) async {
      await abrir(t, subtitulo: 'Queda listo para la planilla de RRHH');
      expect(find.text('Firmar'), findsOneWidget);
      final efecto = find.text('Queda listo para la planilla de RRHH');
      expect(efecto, findsOneWidget);
      expect(
        t.getTopLeft(efecto).dy,
        greaterThan(t.getTopLeft(find.text('Firmar')).dy),
      );
      expect(find.text('Obligatorio.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin subtítulo solo está el título', (t) async {
      await abrir(t);
      expect(find.text('Firmar'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('la acción se apaga con aceptarHabilitado en falso', (t) async {
      await abrir(t, aceptar: false);
      final boton = t.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Aceptar'),
      );
      expect(boton.onPressed, isNull);
      await cerrar(t);
    });

    testWidgets('arrastrar el contenido cierra el teclado', (t) async {
      await abrir(t, subtitulo: 'Efecto');
      final desplazable = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(SingleChildScrollView),
      );
      final contexto = t.element(desplazable);
      expect(
        ScrollConfiguration.of(contexto).getKeyboardDismissBehavior(contexto),
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
      await cerrar(t);
    });
  });

  group('vigencia', () {
    testWidgets('PROGRAMADA, VENCIDA y VIGENTE llevan ícono y texto propios', (
      t,
    ) async {
      Future<void> ver(String? estado, bool vigente) async {
        await montarHex(
          t,
          Center(
            child: Wrap(
              children: etiquetasVigenciaHex(vigente: vigente, estado: estado),
            ),
          ),
          ancho: 390,
        );
      }

      await ver('PROGRAMADA', false);
      expect(find.text('Programada'), findsOneWidget);
      expect(find.byIcon(Icons.update), findsOneWidget);
      await ver('VENCIDA', false);
      expect(find.text('Vencida'), findsOneWidget);
      await ver('VIGENTE', true);
      expect(find.text('Vigente'), findsOneWidget);
      // El estado del SP manda aunque esVigente diga otra cosa.
      await ver('PROGRAMADA', true);
      expect(find.text('Vigente'), findsNothing);
      expect(find.text('Programada'), findsOneWidget);
      // Sin estado, la lógica de siempre: vigente marca, el resto no.
      await ver(null, true);
      expect(find.text('Vigente'), findsOneWidget);
      await ver(null, false);
      expect(find.byType(ChipHex), findsNothing);
      await ver('DESCONOCIDO', true);
      expect(find.text('Vigente'), findsOneWidget);
      await cerrar(t);
    });

    test('la leyenda del grupo es la vigente y nunca queda vacía', () {
      final grupo = [
        (leyenda: 'Divisor anterior', vigente: false),
        (leyenda: 'Divisor actual', vigente: true),
      ];
      String titulo(List<({String leyenda, bool vigente})> g) =>
          leyendaGrupoHex(
            g,
            leyenda: (f) => f.leyenda,
            vigente: (f) => f.vigente,
            clave: 'DIVISOR',
          );
      expect(titulo(grupo), 'Divisor actual');
      expect(titulo([grupo.first]), 'Divisor anterior');
      expect(titulo([(leyenda: 'null', vigente: true)]), 'DIVISOR');
      expect(titulo([(leyenda: '  ', vigente: false)]), 'DIVISOR');
    });

    testWidgets('la franja pone la clave como ficha pequeña', (t) async {
      await montarHex(
        t,
        const FranjaGrupoHex(
          titulo: 'Divisor del costo hora',
          detalle: '2 vigencias',
          codigo: 'DIVISOR_COSTO_HORA',
          enTabla: false,
        ),
        ancho: 390,
      );
      expect(find.text('Divisor del costo hora — 2 vigencias'), findsOneWidget);
      expect(
        t.widget<CodigoHex>(find.byType(CodigoHex)).codigo,
        'DIVISOR_COSTO_HORA',
      );
      await cerrar(t);
    });
  });
}

/// Un `TabController` para armar una barra de pestañas de prueba.
class _ConPestanas extends StatefulWidget {
  const _ConPestanas({required this.armar});

  final Widget Function(TabController c) armar;

  @override
  State<_ConPestanas> createState() => _ConPestanasState();
}

class _ConPestanasState extends State<_ConPestanas>
    with SingleTickerProviderStateMixin {
  late final TabController _control = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.armar(_control);
}

HexReporteEntity _reporte() => HexReporteEntity(
  idReporte: BigInt.one,
  nombreEmpleado: 'Ana Mamani Quispe',
  fechaJornada: DateTime(2026, 10, 23),
  tipo: 'DESPUES',
  tipoTexto: 'Después del horario',
  tipoDia: 'HABIL',
  tipoDiaTexto: 'Hábil',
  inicio: DateTime(2026, 10, 23, 18),
  fin: DateTime(2026, 10, 23, 23),
  estado: 'REPORTADO',
  estadoTexto: 'Reportado',
  puedeVistoBueno: true,
);
