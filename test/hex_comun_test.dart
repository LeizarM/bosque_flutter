import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_evento_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_planilla_ejecutada.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// Kit de UI del módulo Horas Extras: listado tabla/tarjetas, 403, escrituras
/// con confirmación, 409 y doble toque, leyenda de códigos y detalle del
/// reporte.
void main() {
  setUpAll(cargarFuentesHex);

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  // El domingo con inicio por la app, fin corregido, monto provisional y aviso.
  final reporteDomingo = reportesFalsos.firstWhere(
    (r) => r.idReporte == BigInt.from(102),
  );

  List<BosqueColumn<HexReporteEntity>> columnasReporte() => [
    BosqueColumn(
      label: 'Empleado',
      flex: 3,
      cellBuilder: (r) => Text(r.nombreEmpleado),
    ),
    BosqueColumn(
      label: 'Inicio',
      flex: 2,
      cellBuilder:
          (r) =>
              HoraOrigenHex(r.inicio, r.origenInicio, jornada: r.fechaJornada),
    ),
    BosqueColumn(
      label: 'Fin',
      flex: 2,
      cellBuilder:
          (r) => HoraOrigenHex(r.fin, r.origenFin, jornada: r.fechaJornada),
    ),
    BosqueColumn(
      label: 'Monto',
      flex: 2,
      alignment: Alignment.centerRight,
      cellBuilder: (r) => MontoHex(r.montoTotal, provisional: r.esProvisional),
    ),
    BosqueColumn(
      label: 'Estado',
      flex: 2,
      cellBuilder: (r) => EtiquetaEstadoHex(r.estado, r.estadoTexto),
    ),
  ];

  Widget tarjeta(HexReporteEntity r) => TarjetaReporteHex(
    r,
    acciones: [
      AccionHex('Ver detalle', Icons.visibility_outlined, () {}),
      AccionHex(
        'Anular',
        Icons.block,
        () {},
        boton: BotonHex.anular,
        destructiva: true,
      ),
    ],
  );

  /// Un listado de reportes como el de las pantallas: 45 filas en total.
  ListadoHex<HexReporteEntity> listadoHex({
    ValueChanged<int>? alCambiarPagina,
    int total = 45,
    List<BosqueColumn<HexReporteEntity>>? columnas,
    bool externo = false,
    List<HexReporteEntity>? filas,
    Widget? vacio,
  }) => ListadoHex<HexReporteEntity>(
    desplazamientoExterno: externo,
    vacio: vacio,
    filas: filas ?? reportesFalsos,
    pagina: 1,
    total: total,
    tamano: 20,
    alCambiarPagina: alCambiarPagina ?? (_) {},
    filtros: const Wrap(
      spacing: Esp.s,
      children: [Chip(label: Text('Reportados')), Chip(label: Text('Mes'))],
    ),
    columnas: columnas ?? columnasReporte(),
    tarjeta: tarjeta,
  );

  Widget listado({ValueChanged<int>? alCambiarPagina}) => Padding(
    padding: const EdgeInsets.all(Esp.m),
    child: listadoHex(alCambiarPagina: alCambiarPagina),
  );

  bool esLateral(Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;

  bool esVertical(Widget w) =>
      (w is ScrollView && w.scrollDirection == Axis.vertical) ||
      (w is SingleChildScrollView && w.scrollDirection == Axis.vertical);

  group('ListadoHex', () {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets(
        'ListadoHex a $ancho px: tabla desde 720 y tarjetas debajo, sin desbordes',
        (t) async {
          final errores = capturarErrores();
          await montarHex(t, listado(), ancho: ancho);
          await esperar(t);
          final tabla = ancho >= hexAnchoTabla;
          expect(errores, isEmpty, reason: detalle(errores));
          expect(find.text('Empleado'), tabla ? findsOneWidget : findsNothing);
          expect(find.text('Filtros'), tabla ? findsNothing : findsOneWidget);
          expect(
            find.text('Reportados'),
            tabla ? findsOneWidget : findsNothing,
          );
          expect(
            find.byIcon(Icons.more_vert),
            tabla ? findsNothing : findsWidgets,
          );
          // 45 filas de a 20: tres páginas, también en el teléfono.
          expect(find.text('Página 1 de 3'), findsOneWidget);
          expect(find.textContaining('vacaci'), findsNothing);
          // Cinco columnas entran: sin desplazamiento lateral.
          expect(find.byWidgetPredicate(esLateral), findsNothing);
          await cerrar(t);
        },
      );
    }

    for (final ancho in [390.0, 800.0]) {
      testWidgets(
        'con 12 columnas a $ancho px: lateral en la tabla, nunca en el teléfono',
        (t) async {
          final errores = capturarErrores();
          final doce = [
            ...columnasReporte(),
            for (var i = 1; i <= 7; i++)
              BosqueColumn<HexReporteEntity>(
                label: 'Extra $i',
                cellBuilder: (r) => Text(horasHex(r.horasPagables)),
              ),
          ];
          await montarHex(
            t,
            Padding(
              padding: const EdgeInsets.all(Esp.m),
              child: listadoHex(columnas: doce),
            ),
            ancho: ancho,
          );
          await esperar(t);
          expect(errores, isEmpty, reason: detalle(errores));
          if (ancho < hexAnchoTabla) {
            expect(find.byWidgetPredicate(esLateral), findsNothing);
            await cerrar(t);
            return;
          }
          final lateral = find.byWidgetPredicate(esLateral);
          expect(lateral, findsOneWidget);
          ScrollPosition posicion() =>
              t
                  .state<ScrollableState>(
                    find
                        .descendant(
                          of: lateral,
                          matching: find.byType(Scrollable),
                        )
                        .first,
                  )
                  .position;
          expect(posicion().maxScrollExtent, greaterThan(0));
          await t.drag(find.text('Empleado'), const Offset(-300, 0));
          await esperar(t, 2);
          expect(posicion().pixels, greaterThan(0));
          // La paginación queda fuera del desplazamiento.
          expect(
            find.descendant(
              of: lateral,
              matching: find.byType(BosquePaginator),
            ),
            findsNothing,
          );
          expect(errores, isEmpty, reason: detalle(errores));
          await cerrar(t);
        },
      );
    }

    testWidgets('el paginador pide la página siguiente al servidor', (t) async {
      final pedidas = <int>[];
      await montarHex(t, listado(alCambiarPagina: pedidas.add));
      await esperar(t, 2);
      await t.tap(find.byIcon(Icons.chevron_right));
      await t.pump();
      expect(pedidas, [2]);
      await cerrar(t);
    });

    testWidgets('al cambiar de página la lista vuelve al inicio', (t) async {
      var pagina = 1;
      final muchas = [for (var i = 0; i < 20; i++) reportesFalsos[i % 4]];
      await montarHex(
        t,
        StatefulBuilder(
          builder:
              (_, cambiar) => ListadoHex<HexReporteEntity>(
                filas: muchas,
                pagina: pagina,
                total: 60,
                columnas: columnasReporte(),
                tarjeta: tarjeta,
                alCambiarPagina: (p) => cambiar(() => pagina = p),
              ),
        ),
        ancho: 390,
      );
      await esperar(t, 2);
      double desplazado() =>
          t
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .pixels;
      await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await esperar(t, 2);
      expect(desplazado(), greaterThan(0));
      await t.tap(find.byIcon(Icons.chevron_right));
      await esperar(t, 2);
      expect(pagina, 2);
      expect(desplazado(), 0);
      await cerrar(t);
    });

    testWidgets('sin alCambiarPagina no hay botones de paginación', (t) async {
      await montarHex(
        t,
        ListadoHex<HexReporteEntity>(
          filas: reportesFalsos,
          total: 45,
          columnas: columnasReporte(),
          tarjeta: tarjeta,
        ),
      );
      await esperar(t, 2);
      expect(find.byType(BosquePaginator), findsNothing);
      await cerrar(t);
    });

    testWidgets('con una sola página el paginador no aparece en el teléfono', (
      t,
    ) async {
      await montarHex(t, listadoHex(total: reportesFalsos.length), ancho: 390);
      await esperar(t, 2);
      expect(find.byType(BosquePaginator), findsNothing);
      await cerrar(t);
    });

    testWidgets('en el angosto los filtros se pliegan y se despliegan', (
      t,
    ) async {
      await montarHex(t, listado(), ancho: 390);
      await esperar(t, 2);
      expect(find.text('Reportados'), findsNothing);
      await t.tap(find.text('Filtros'));
      await esperar(t, 2);
      expect(find.text('Reportados'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin el botón la acción no aparece en el menú', (t) async {
      await montarHex(t, listado(), ancho: 390, botones: {BotonHex.marcar});
      await esperar(t, 2);
      await t.tap(find.byIcon(Icons.more_vert).first);
      await esperar(t, 2);
      expect(find.text('Ver detalle'), findsOneWidget);
      expect(find.text('Anular'), findsNothing);
      await cerrar(t);
    });

    testWidgets(
      'las acciones en línea tienen 48 px aun con densidad compacta',
      (t) async {
        await montarHex(
          t,
          Builder(
            builder:
                (c) => Theme(
                  data: Theme.of(
                    c,
                  ).copyWith(visualDensity: VisualDensity.compact),
                  child: Center(
                    child: AccionesHex(
                      acciones: [
                        AccionHex(
                          'Ver detalle',
                          Icons.visibility_outlined,
                          () {},
                        ),
                      ],
                    ),
                  ),
                ),
          ),
        );
        await esperar(t, 2);
        final tam = t.getSize(find.byType(IconButton));
        expect(tam.width, greaterThanOrEqualTo(48));
        expect(tam.height, greaterThanOrEqualTo(48));
        await cerrar(t);
      },
    );

    testWidgets('sin filas muestra el estado vacío', (t) async {
      await montarHex(
        t,
        ListadoHex<HexReporteEntity>(
          filas: const [],
          columnas: [
            BosqueColumn(label: 'Empleado', cellBuilder: (r) => const Text('')),
          ],
          tarjeta: (r) => const SizedBox(),
        ),
      );
      await esperar(t, 2);
      expect(find.text('No hay registros'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets(
      'desplazamientoExterno a 390 px: las tarjetas van en el scroll de afuera',
      (t) async {
        final errores = capturarErrores();
        await montarHex(
          t,
          SingleChildScrollView(
            padding: const EdgeInsets.all(Esp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 300, child: Text('Panel de marcación')),
                listadoHex(externo: true),
              ],
            ),
          ),
          ancho: 390,
        );
        await esperar(t);
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.byWidgetPredicate(esVertical), findsOneWidget);
        expect(find.text('Filtros'), findsOneWidget);
        // Sin perezosidad: la última tarjeta también existe.
        expect(find.text('Pendiente de biométrico'), findsOneWidget);
        await t.scrollUntilVisible(
          find.text('Página 1 de 3'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Página 1 de 3').hitTestable(), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      },
    );

    testWidgets(
      'desplazamientoExterno sin filas: la espera tiene alto propio',
      (t) async {
        final errores = capturarErrores();
        await montarHex(
          t,
          SingleChildScrollView(
            child: listadoHex(
              externo: true,
              filas: const [],
              total: 0,
              vacio: const EsqueletoLista(),
            ),
          ),
          ancho: 390,
        );
        await esperar(t);
        expect(find.byType(EsqueletoLista), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      },
    );

    testWidgets('desplazamientoExterno no cambia la tabla del ancho', (
      t,
    ) async {
      await montarHex(
        t,
        Padding(
          padding: const EdgeInsets.all(Esp.m),
          child: listadoHex(externo: true),
        ),
      );
      await esperar(t);
      expect(find.text('Empleado'), findsOneWidget);
      expect(find.text('Filtros'), findsNothing);
      await cerrar(t);
    });
  });

  group('errores', () {
    testWidgets('un 403 en la lista muestra No tienes permiso', (t) async {
      await montarHex(
        t,
        vistaErrorHex(
          const SinPermisoHex(
            'No tienes los permisos necesarios para realizar esta acción.',
          ),
        ),
      );
      await esperar(t, 2);
      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un error de negocio en la lista se muestra tal cual', (
      t,
    ) async {
      var reintentos = 0;
      await montarHex(
        t,
        vistaErrorHex(
          const NegocioHex('El dato es obligatorio: faltan tramos vigentes.'),
          reintentar: () => reintentos++,
        ),
      );
      await esperar(t, 2);
      expect(
        find.text('El dato es obligatorio: faltan tramos vigentes.'),
        findsOneWidget,
      );
      await t.tap(find.text('Reintentar'));
      expect(reintentos, 1);
      await cerrar(t);
    });

    test(
      'textoErrorHex: 403 del módulo, SP tal cual, lo técnico traducido',
      () {
        expect(
          textoErrorHex(
            const SinPermisoHex('No tienes los permisos necesarios.'),
          ),
          'No tienes permiso para esta acción.',
        );
        expect(
          textoErrorHex(const ConflictoHex('Ya lo aprobó otro.')),
          'Ya lo aprobó otro.',
        );
        expect(
          textoErrorHex(Exception('Error interno del servidor.')),
          contains('Sistemas'),
        );
      },
    );
  });

  group('ejecutarHex', () {
    late BuildContext ctx;
    late OcupadoHex ocupado;
    late int refrescos;

    Future<void> montar(WidgetTester t) async {
      ocupado = OcupadoHex();
      addTearDown(() {
        if (!ocupado.descartado) ocupado.dispose();
      });
      refrescos = 0;
      await montarHex(
        t,
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.expand();
          },
        ),
      );
    }

    Future<bool> ejecutar(Future<HexRespuesta> Function(bool) accion) =>
        ejecutarHex(
          ctx,
          ocupado: ocupado,
          accion: accion,
          refrescar: () => refrescos++,
        );

    testWidgets(
      'confirmable muestra el mensaje del SP y reenvía con confirmado',
      (t) async {
        await montar(t);
        final llamadas = <bool>[];
        const pregunta =
            'Tu salida está a 2 km de la que ya marcaste. ¿Registrar igual?';
        final r = ejecutar((c) async {
          llamadas.add(c);
          if (!c) throw const ConfirmacionHex(pregunta);
          return (
            id: BigInt.from(9),
            mensaje: 'Salida registrada a las 19:40.',
          );
        });
        await esperar(t, 2);
        expect(find.text('Confirma antes de seguir'), findsOneWidget);
        expect(find.text(pregunta), findsOneWidget);
        await t.tap(find.text('Confirmar'));
        await esperar(t, 2);
        expect(await r, isTrue);
        expect(llamadas, [false, true]);
        expect(find.text('Salida registrada a las 19:40.'), findsOneWidget);
        expect(refrescos, 1);
        expect(ocupado.value, isFalse);
        await cerrar(t);
      },
    );

    testWidgets('si no confirma no reenvía', (t) async {
      await montar(t);
      final llamadas = <bool>[];
      final r = ejecutar((c) async {
        llamadas.add(c);
        throw const ConfirmacionHex('¿Seguro?');
      });
      await esperar(t, 2);
      await t.tap(find.text('Cancelar'));
      await esperar(t, 2);
      expect(await r, isFalse);
      expect(llamadas, [false]);
      expect(refrescos, 0);
      await cerrar(t);
    });

    testWidgets('409 muestra el mensaje y recarga sin reintentar', (t) async {
      await montar(t);
      var veces = 0;
      const texto = 'El reporte cambió: otra persona ya le dio el visto bueno.';
      final r = ejecutar((c) async {
        veces++;
        throw const ConflictoHex(texto);
      });
      await esperar(t, 2);
      expect(await r, isFalse);
      expect(veces, 1);
      expect(refrescos, 1);
      expect(find.text(texto), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
      await cerrar(t);
    });

    testWidgets('400 de negocio se muestra tal cual', (t) async {
      await montar(t);
      const texto = 'La observación es obligatoria para rechazar el reporte.';
      final r = ejecutar((c) async => throw const NegocioHex(texto));
      await esperar(t, 2);
      expect(await r, isFalse);
      expect(find.text(texto), findsOneWidget);
      expect(refrescos, 0);
      await cerrar(t);
    });

    testWidgets('un 403 al escribir avisa que no tienes permiso', (t) async {
      await montar(t);
      final r = ejecutar((c) async => throw const SinPermisoHex('403'));
      await esperar(t, 2);
      expect(await r, isFalse);
      expect(find.text('No tienes permiso para esta acción.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('ejecutarHex ignora el segundo toque mientras está ocupado', (
      t,
    ) async {
      await montar(t);
      final respuesta = Completer<HexRespuesta>();
      var veces = 0;
      Future<HexRespuesta> accion(bool c) {
        veces++;
        return respuesta.future;
      }

      final primero = ejecutar(accion);
      final segundo = ejecutar(accion);
      expect(veces, 1);
      expect(ocupado.value, isTrue);
      expect(await segundo, isFalse);
      respuesta.complete((id: BigInt.one, mensaje: 'Aprobado.'));
      expect(await primero, isTrue);
      expect(veces, 1);
      expect(ocupado.value, isFalse);
      await esperar(t, 2);
      await cerrar(t);
    });

    testWidgets(
      'si la pantalla se cerró a mitad, no toca el ocupado descartado',
      (t) async {
        await montar(t);
        final respuesta = Completer<HexRespuesta>();
        final r = ejecutar((_) => respuesta.future);
        await cerrar(t);
        ocupado.dispose();
        respuesta.complete((id: BigInt.one, mensaje: 'Listo.'));
        expect(await r, isTrue);
        expect(ocupado.descartado, isTrue);
        expect(refrescos, 0);
      },
    );
  });

  group('confirmaciones y PDF', () {
    testWidgets('verPdfHex sin bytes avisa que no hay datos', (t) async {
      late BuildContext ctx;
      await montarHex(
        t,
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.expand();
          },
        ),
      );
      final r = verPdfHex(
        ctx,
        generar: () async => null,
        titulo: 'Planilla',
        nombreArchivo: 'planilla.pdf',
      );
      await esperar(t, 2);
      await r;
      expect(find.text('Generando el PDF…'), findsNothing);
      expect(find.text('No hay datos para el PDF.'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('piezas', () {
    testWidgets('el arnés atrapa un desborde (las pruebas de ancho sirven)', (
      t,
    ) async {
      final errores = capturarErrores();
      await montarHex(
        t,
        const Row(children: [SizedBox(width: 2000, height: 10)]),
        ancho: 390,
      );
      expect(errores, isNotEmpty);
      // Se esperaba: se vacía para que el arnés no haga fallar la prueba.
      errores.clear();
      await cerrar(t);
    });

    test('formatos con coma decimal y punto de miles', () {
      expect(bsHex(1234.5), 'Bs 1.234,50');
      expect(horasHex(2.5), '2,50 h');
      expect(numeroHex(1.5), '1,5');
      expect(bsHex(null), '—');
      expect(oGuionHex('null'), '—');
    });

    test('decimalHex: valores de pago con hasta 4 decimales', () {
      expect(decimalHex(240.125), '240,125');
      expect(decimalHex(1.125), '1,125');
      expect(decimalHex(1.33333), '1,3333');
      expect(decimalHex(1500), '1.500');
      expect(decimalHex(null), '—');
    });

    test('decimalSinDudaHex: al menos 2 decimales, nunca «1.500» a secas', () {
      expect(decimalSinDudaHex(1500), '1.500,00');
      expect(decimalSinDudaHex(1.5), '1,50');
      expect(decimalSinDudaHex(1.125), '1,125');
      expect(decimalSinDudaHex(1.33333), '1,3333');
      expect(decimalSinDudaHex(null), '—');
    });

    test('horas TIME, día y mes con ceros a la izquierda', () {
      expect(horaTimeHex(const TimeOfDay(hour: 8, minute: 5)), '08:05:00');
      expect(horaTimeHex(const TimeOfDay(hour: 0, minute: 0)), '00:00:00');
      expect(horaDeTimeHex('22:30:00'), const TimeOfDay(hour: 22, minute: 30));
      expect(horaDeTimeHex(null), const TimeOfDay(hour: 0, minute: 0));
      expect(diaMesHex(DateTime(2026, 11, 3)), '03/11');
    });

    test('numeroEscritoHex lee números como en Bolivia', () {
      const casos = <String, double?>{
        '1.234,50': 1234.5,
        '1.500': 1500,
        '12.345.678': 12345678,
        '15,5': 15.5,
        '1.5': 1.5,
        '240,125': 240.125,
        '1234.5': 1234.5,
        '15': 15,
        ' 30,50 ': 30.5,
        '15,': 15,
        ',5': 0.5,
        '': null,
        'abc': null,
        '1,2,3': null,
        '1.2.3': null,
        'NaN': null,
        'Infinity': null,
        '-5': null,
        // Sin cifras no hay número (antes «,» se leía 0).
        ',': null,
        '.': null,
        '.,': null,
        // Un grupo de miles no empieza con 0: «0.125» es un decimal.
        '0.500': 0.5,
        '0.125': 0.125,
        '00.500': 0.5,
        // Con coma, la parte entera va sin puntos o con miles bien puestos.
        '1.5,5': null,
        '12.34,5': null,
        '1..5,0': null,
        '1.234.567,8': 1234567.8,
        '0.500,5': null,
        '00.500,5': null,
        '0.000,5': null,
      };
      for (final MapEntry(key: texto, value: esperado) in casos.entries) {
        expect(numeroEscritoHex(texto), esperado, reason: '«$texto»');
      }
    });

    test('periodoHex: mes en letras y año; un mes que no existe, guion', () {
      expect(periodoHex(2026, 10), 'octubre de 2026');
      expect(periodoHex(2026, 1), 'enero de 2026');
      expect(periodoHex(2026, 12), 'diciembre de 2026');
      expect(periodoHex(0, 0), '—');
      expect(periodoHex(2026, 13), '—');
    });

    test('los 13 botones son los del contrato', () {
      expect(
        {
          BotonHex.marcar,
          BotonHex.anular,
          BotonHex.editarHora,
          BotonHex.vistoBueno,
          BotonHex.rechazar,
          BotonHex.aprobar,
          BotonHex.aprobarGrupo,
          BotonHex.rechazarJefe,
          BotonHex.ejecutarPlanilla,
          BotonHex.pdfPlanilla,
          BotonHex.anularPlanilla,
          BotonHex.editarParametro,
          BotonHex.editarAprobador,
        },
        {
          'btnHexMarcar',
          'btnHexAnular',
          'btnHexEditarHora',
          'btnHexVistoBueno',
          'btnHexRechazar',
          'btnHexAprobar',
          'btnHexAprobarGrupo',
          'btnHexRechazarJefe',
          'btnHexEjecutarPlanilla',
          'btnHexPdfPlanilla',
          'btnHexAnularPlanilla',
          'btnHexEditarParametro',
          'btnHexEditarAprobador',
        },
      );
    });

    testWidgets('PanelHex desplaza con el control de la hoja o, sin él, con '
        'uno propio', (t) async {
      final errores = capturarErrores();
      final hoja = ScrollController();
      addTearDown(hoja.dispose);
      Widget panel(ScrollController? control) => SizedBox(
        height: 300,
        child: PanelHex(
          control: control,
          cabecera: const Text('Cabecera'),
          hijos: [for (var i = 0; i < 30; i++) Text('Fila $i')],
        ),
      );
      await montarHex(t, panel(hoja), ancho: 390);
      await esperar(t, 1);
      expect(hoja.hasClients, isTrue);
      await t.drag(find.byType(ListView), const Offset(0, -200));
      await esperar(t, 1);
      expect(hoja.offset, greaterThan(0));
      await cerrar(t);

      await montarHex(t, panel(null), ancho: 390);
      await esperar(t, 1);
      final lista = t.state<ScrollableState>(find.byType(Scrollable).first);
      await t.drag(find.byType(ListView), const Offset(0, -200));
      await esperar(t, 1);
      expect(lista.position.pixels, greaterThan(0));
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('origen de la hora con su ícono y su rótulo', (t) async {
      await montarHex(
        t,
        const Column(
          children: [
            OrigenHoraHex('HORARIO'),
            OrigenHoraHex('BIOMETRICO'),
            OrigenHoraHex('APP'),
            OrigenHoraHex('EDITADO'),
            OrigenHoraHex(null),
          ],
        ),
      );
      await esperar(t, 2);
      // Rótulos que entiende quien no conoce el sistema (contrato D29).
      for (final texto in [
        'Del horario',
        'Biométrico',
        'App · con ubicación',
        'Corregida por el encargado',
        'Pendiente de biométrico',
      ]) {
        expect(find.text(texto), findsOneWidget, reason: texto);
      }
      for (final icono in [
        Icons.schedule,
        Icons.fingerprint,
        Icons.location_on,
        Icons.edit_outlined,
        Icons.hourglass_empty,
      ]) {
        expect(find.byIcon(icono), findsOneWidget, reason: '$icono');
      }
      await cerrar(t);
    });

    testWidgets(
      'el origen no falla sin ancho límite (desplazamiento lateral)',
      (t) async {
        final errores = capturarErrores();
        final r = reportesFalsos.last;
        await montarHex(
          t,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const OrigenHoraHex(null),
                HoraOrigenHex(r.fin, r.origenFin, jornada: r.fechaJornada),
                MontoHex(r.montoTotal, provisional: true),
              ],
            ),
          ),
          ancho: 390,
        );
        await esperar(t, 2);
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('Pendiente de biométrico'), findsNWidgets(2));
        await cerrar(t);
      },
    );

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('la leyenda de códigos a $ancho px', (t) async {
        final errores = capturarErrores();
        await montarHex(
          t,
          const Align(alignment: Alignment.bottomCenter, child: LeyendaHex()),
          ancho: ancho,
          overrides: [
            hexReporteRepositoryProvider.overrideWithValue(HexReporteFalso()),
          ],
        );
        await esperar(t);
        if (ancho < hexAnchoTabla) {
          // Una fila que abre la hoja: el contenido no ocupa la pantalla.
          expect(find.text('H50'), findsNothing);
          await t.tap(find.text('Leyenda de códigos'));
          await esperar(t, 3);
          expect(find.byType(BottomSheet), findsOneWidget);
        }
        expect(errores, isEmpty, reason: detalle(errores));
        expect(find.text('H50'), findsOneWidget);
        expect(find.text('×1,5 · 20:00–24:00'), findsOneWidget);
        expect(find.text('DC'), findsOneWidget);
        expect(find.text('Almuerzo (inactiva)'), findsOneWidget);
        expect(find.byType(Opacity), findsNothing);
        await cerrar(t);
      });
    }

    testWidgets(
      'encabezado, lista y leyenda al pie a 390 px y 150 %, sin desbordes',
      (t) async {
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          Padding(
            padding: const EdgeInsets.all(Esp.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EncabezadoHex(
                  titulo: 'Mis horas extra',
                  detalle: 'Tus reportes del mes y de dónde salió cada hora.',
                  acciones: [
                    FilledButton(onPressed: null, child: Text('Reportar')),
                  ],
                ),
                const SizedBox(height: Esp.m),
                Expanded(child: listadoHex()),
                const SizedBox(height: Esp.s),
                const LeyendaHex(),
              ],
            ),
          ),
          ancho: 390,
          overrides: [
            hexReporteRepositoryProvider.overrideWithValue(HexReporteFalso()),
          ],
        );
        await esperar(t);
        expect(find.text('Leyenda de códigos'), findsOneWidget);
        await t.tap(find.text('Leyenda de códigos'));
        await esperar(t, 3);
        expect(find.text('H50'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      },
    );

    testWidgets('tarjeta de reporte al 150 % en 390 px sin desbordes', (
      t,
    ) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montarHex(t, listado(), ancho: 390);
      await esperar(t);
      // Se recorre la lista hasta la última tarjeta: así se dibujan todas.
      await t.scrollUntilVisible(
        find.text('Pendiente de biométrico'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await esperar(t, 2);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });

  group('piezas de pantallas y diálogos', () {
    testWidgets('ComidasHex y MenuFiltroHex eligen una opción', (t) async {
      String? elegido = 'sin elegir';
      await montarHex(
        t,
        Column(
          children: [
            const ComidasHex('C, DC'),
            const ComidasHex(null),
            MenuFiltroHex(
              valor: null,
              opciones: const {
                null: 'Todos los estados',
                'REPORTADO': 'Reportados',
              },
              alElegir: (v) => elegido = v,
            ),
          ],
        ),
        ancho: 390,
      );
      expect(find.byType(CodigoHex), findsNWidgets(2));
      expect(find.text('—'), findsOneWidget);
      await t.tap(find.text('Todos los estados'));
      await esperar(t, 2);
      await t.tap(find.text('Reportados').last);
      await esperar(t, 2);
      expect(elegido, 'REPORTADO');
      await cerrar(t);
    });

    testWidgets(
      'FiltroRangoHex muestra el rango, se quita y abre el selector',
      (t) async {
        DateTime? desde = DateTime(2026, 10, 1);
        DateTime? hasta = DateTime(2026, 10, 31);
        var cambios = 0;
        await montarHex(
          t,
          StatefulBuilder(
            builder:
                (_, cambiar) => Center(
                  child: FiltroRangoHex(
                    desde: desde,
                    hasta: hasta,
                    explicacion: 'Las jornadas entre estas fechas.',
                    alCambiar:
                        (d, h) => cambiar(() {
                          desde = d;
                          hasta = h;
                          cambios++;
                        }),
                  ),
                ),
          ),
          ancho: 390,
        );
        expect(find.text('01/10/2026 – 31/10/2026'), findsOneWidget);
        await t.tap(find.byTooltip('Quitar el rango'));
        await esperar(t, 1);
        expect(cambios, 1);
        expect(desde, isNull);
        expect(hasta, isNull);
        await t.tap(find.text('Todas las fechas'));
        await esperar(t, 2);
        expect(find.text('Jornadas a mostrar'), findsOneWidget);
        expect(find.text('Las jornadas entre estas fechas.'), findsOneWidget);
        await cerrar(t);
      },
    );

    testWidgets('TarjetaReporteHex lleva la sucursal solo si se pide', (
      t,
    ) async {
      final r = reportesFalsos.first;
      await montarHex(
        t,
        ListView(
          children: [
            TarjetaReporteHex(r, mostrarSucursal: true),
            TarjetaReporteHex(r),
          ],
        ),
        ancho: 390,
      );
      expect(find.text('23/10/2026 · Planta El Alto'), findsOneWidget);
      expect(find.text('23/10/2026'), findsOneWidget);
      // El tipo y el día van en fichas con ícono, no en la línea de apoyo.
      expect(find.text('Después del horario'), findsNWidgets(2));
      expect(find.text('Hábil'), findsNWidgets(2));
      expect(find.byIcon(Icons.nightlight_outlined), findsNWidgets(2));
      await cerrar(t);
    });

    test('usaTablaHex: tabla solo con el ancho mínimo de su tabla', () {
      expect(usaTablaHex(719, null), isFalse);
      expect(usaTablaHex(720, null), isTrue);
      expect(usaTablaHex(900, 1040), isFalse);
      expect(usaTablaHex(1040, 1040), isTrue);
      expect(usaTablaHex(800, 600), isTrue);
    });

    for (final ancho in [800.0, 1100.0]) {
      final tabla = ancho >= 1040;
      testWidgets('con anchoMinimoTabla 1040 a $ancho px: '
          '${tabla ? 'tabla' : 'tarjetas'}, nunca de lado', (t) async {
        final errores = capturarErrores();
        await montarHex(
          t,
          ListadoHex<HexReporteEntity>(
            filas: reportesFalsos,
            total: 4,
            alCambiarPagina: (_) {},
            anchoMinimoTabla: 1040,
            columnas: columnasReporte(),
            tarjeta: tarjeta,
          ),
          ancho: ancho,
        );
        await esperar(t);
        expect(find.text('Empleado'), tabla ? findsOneWidget : findsNothing);
        expect(
          find.byIcon(Icons.more_vert),
          tabla ? findsNothing : findsWidgets,
        );
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    test('anchoTablaReportesHex: 1040 compacta y 1248 en línea', () {
      expect(anchoTablaReportesHex(), 1040);
      expect(anchoTablaReportesHex(accionesEnLinea: true), 1248);
    });

    // La cabecera va antes de las filas 0 y 2: en la tabla, en las tarjetas
    // con su propio scroll y en las del scroll de la pantalla.
    for (final (ancho, externo) in [
      (1400.0, false),
      (390.0, false),
      (390.0, true),
    ]) {
      testWidgets('cabeceraAntesDe agrupa filas a $ancho px'
          '${externo ? ' en el scroll de afuera' : ''}', (t) async {
        final errores = capturarErrores();
        Widget listado(BuildContext context) => ListadoHex<HexReporteEntity>(
          desplazamientoExterno: externo,
          filas: reportesFalsos,
          total: 4,
          anchoMinimoTabla: anchoTablaReportesHex(),
          cabeceraAntesDe:
              (i) => switch (i) {
                0 => const Text('Grupo A'),
                2 => const Text('Grupo B'),
                _ => null,
              },
          columnas: columnasReportesHex(
            context,
            acciones: (_) => const [],
            accionesEnLinea: false,
            principales: const {},
          ),
          tarjeta: tarjeta,
        );
        await montarHex(
          t,
          Builder(
            builder:
                (c) =>
                    externo
                        ? SingleChildScrollView(child: listado(c))
                        : listado(c),
          ),
          ancho: ancho,
        );
        await esperar(t);
        expect(
          find.text('Empleado'),
          ancho > 1100 ? findsOneWidget : findsNothing,
        );
        // Cada cabecera queda encima de su fila.
        double arriba(String texto) => t.getTopLeft(find.text(texto).first).dy;
        expect(
          arriba('Grupo A'),
          lessThan(arriba('Mamani Quispe Juan Carlos')),
        );
        expect(
          arriba('Grupo B'),
          greaterThan(arriba('Condori Huanca María Fernanda de los Ángeles')),
        );
        expect(arriba('Grupo B'), lessThan(arriba('Choque Flores Pedro')));
        expect(find.text('Grupo A'), findsOneWidget);
        expect(find.text('Grupo B'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('InicioFinHex con rótulos y la etiqueta del biométrico', (
      t,
    ) async {
      final r = reportesFalsos.first;
      await montarHex(
        t,
        Column(
          children: [
            InicioFinHex(r),
            InicioFinHex(r, rotulos: true),
            const EtiquetaAvisoBiometricoHex(),
          ],
        ),
        ancho: 390,
      );
      // La salida pasada la medianoche lleva su día en las dos.
      expect(find.text('24/10'), findsNWidgets(2));
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Fin'), findsOneWidget);
      expect(find.text('Aviso de biométrico'), findsOneWidget);
      await cerrar(t);
    });

    // En el escritorio el tema compacta los botones a 40 px.
    testWidgets(
      'el menú de acciones tiene 48 px de área táctil',
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
      (t) async {
        await montarHex(
          t,
          Center(
            child: AccionesHex(
              enMenu: true,
              acciones: [
                AccionHex('Ver detalle', Icons.visibility_outlined, () {}),
              ],
            ),
          ),
          ancho: 1400,
        );
        final boton = t.getSize(
          find.ancestor(
            of: find.byIcon(Icons.more_vert),
            matching: find.byType(IconButton),
          ),
        );
        expect(boton.width, greaterThanOrEqualTo(48));
        expect(boton.height, greaterThanOrEqualTo(48));
        await cerrar(t);
      },
    );

    testWidgets(
      'DialogoHex: en curso no se cierra con atrás; al salir bien recarga y cierra',
      (t) async {
        final respuesta = Completer<HexRespuesta>();
        var recargas = 0;
        await montarHex(
          t,
          Builder(
            builder:
                (c) => Center(
                  child: FilledButton(
                    onPressed:
                        () => showDialog<void>(
                          context: c,
                          builder:
                              (_) => _DialogoDePrueba(
                                accion: (_) => respuesta.future,
                                alRecargar: () => recargas++,
                              ),
                        ),
                    child: const Text('Abrir'),
                  ),
                ),
          ),
          ancho: 390,
        );
        await t.tap(find.text('Abrir'));
        await esperar(t, 2);
        await t.tap(find.text('Guardar'));
        await esperar(t, 1);
        final cancelar = t.widget<TextButton>(
          find.widgetWithText(TextButton, 'Cancelar'),
        );
        expect(cancelar.onPressed, isNull);
        await Navigator.of(t.element(find.byType(AlertDialog))).maybePop();
        await esperar(t, 1);
        expect(find.byType(AlertDialog), findsOneWidget);
        respuesta.complete((id: BigInt.one, mensaje: 'Guardado.'));
        await esperar(t, 3);
        expect(find.byType(AlertDialog), findsNothing);
        expect(recargas, 1);
        expect(find.text('Guardado.'), findsOneWidget);
        await cerrar(t);
      },
    );

    testWidgets('DialogoHex: un 400 deja el diálogo abierto con el texto', (
      t,
    ) async {
      var recargas = 0;
      await montarHex(
        t,
        Builder(
          builder:
              (c) => Center(
                child: FilledButton(
                  onPressed:
                      () => showDialog<void>(
                        context: c,
                        builder:
                            (_) => _DialogoDePrueba(
                              accion:
                                  (_) async =>
                                      throw const NegocioHex(
                                        'La observación es obligatoria.',
                                      ),
                              alRecargar: () => recargas++,
                            ),
                      ),
                  child: const Text('Abrir'),
                ),
              ),
        ),
        ancho: 390,
      );
      await t.tap(find.text('Abrir'));
      await esperar(t, 2);
      await t.tap(find.text('Guardar'));
      await esperar(t, 2);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('La observación es obligatoria.'), findsOneWidget);
      expect(find.text('Opcional.'), findsOneWidget);
      expect(recargas, 0);
      await cerrar(t);
    });

    testWidgets(
      'pedirOpcionHex filtra por texto y apoyo; CampoSelectorHex se quita',
      (t) async {
        const opciones = <OpcionHex<int>>[
          (valor: 1, texto: 'Rojas Vargas Luis', apoyo: 'Planta El Alto'),
          (valor: 2, texto: 'Quispe Mamani Ana', apoyo: 'Almacén Central'),
          (valor: 3, texto: 'Choque Flores Mario', apoyo: null),
        ];
        int? elegido;
        var quitado = 0;
        await montarHex(
          t,
          Builder(
            builder:
                (context) => Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        elegido = await pedirOpcionHex<int>(
                          context,
                          titulo: 'Aprobador',
                          opciones: opciones,
                          actual: 1,
                        );
                      },
                      child: const Text('Buscar'),
                    ),
                    CampoSelectorHex(
                      etiqueta: 'Empleado',
                      valor: 'Rojas Vargas Luis',
                      icono: Icons.search,
                      alTocar: () {},
                      alQuitar: () => quitado++,
                      textoQuitar: 'Quitar el filtro',
                    ),
                    const CampoSelectorHex(
                      etiqueta: 'Sucursal',
                      valor: null,
                      icono: Icons.search,
                      alTocar: null,
                      alQuitar: null,
                    ),
                  ],
                ),
          ),
          ancho: 390,
        );
        // Sin valor no hay «x»; con valor y alQuitar, la «x» lo quita.
        expect(find.byTooltip('Quitar el filtro'), findsOneWidget);
        await t.tap(find.byTooltip('Quitar el filtro'));
        expect(quitado, 1);

        Finder campo() => find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await t.tap(find.text('Buscar'));
        await esperar(t, 2);
        expect(find.widgetWithText(ListTile, 'Choque Flores Mario'), findsOne);
        // También busca en el apoyo (la sucursal) y sin mayúsculas.
        await t.enterText(campo(), 'almacén');
        await esperar(t, 1);
        expect(find.byType(ListTile), findsOneWidget);
        // Sin tildes y con las palabras en cualquier orden.
        await t.enterText(campo(), 'ALMACEN');
        await esperar(t, 1);
        expect(find.widgetWithText(ListTile, 'Quispe Mamani Ana'), findsOne);
        await t.enterText(campo(), ' luis  rojas ');
        await esperar(t, 1);
        expect(find.byType(ListTile), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Rojas Vargas Luis'), findsOne);
        await t.enterText(campo(), 'luis alto');
        await esperar(t, 1);
        expect(find.widgetWithText(ListTile, 'Rojas Vargas Luis'), findsOne);
        await t.enterText(campo(), 'zzz');
        await esperar(t, 1);
        expect(find.text('Nada coincide con «zzz».'), findsOneWidget);
        // Con una sola coincidencia, «Buscar» del teclado la elige.
        await t.enterText(campo(), 'quis');
        await esperar(t, 1);
        await t.testTextInput.receiveAction(TextInputAction.search);
        await esperar(t, 2);
        expect(elegido, 2);
        expect(find.byType(Dialog), findsNothing);

        // Cancelar devuelve nulo.
        await t.tap(find.text('Buscar'));
        await esperar(t, 2);
        await t.tap(find.text('Cancelar'));
        await esperar(t, 2);
        expect(elegido, isNull);
        await cerrar(t);
      },
    );
  });

  group('avance del reporte (R5)', () {
    HexReporteEntity enEstado(
      String estado, {
      String? pendiente,
      String? motivo,
    }) => HexReporteEntity(
      idReporte: BigInt.from(900),
      estado: estado,
      estadoTexto: estado,
      textoPendiente: pendiente,
      motivoRechazo: motivo,
    );

    /// Los colores de los cuatro tramos de la barra compacta, en orden.
    List<Color?> tramos(WidgetTester t) => [
      for (final c in t.widgetList<Container>(
        find.descendant(
          of: find.byType(AvanceReporteHex),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.constraints?.maxHeight == 6,
          ),
        ),
      ))
        (c.decoration! as BoxDecoration).color,
    ];

    for (final (estado, hechos) in [
      ('REPORTADO', 1),
      ('VISTO_BUENO', 2),
      ('APROBADO', 3),
      ('LIQUIDADO', 4),
    ]) {
      testWidgets('$estado: $hechos en verde, el actual en ámbar', (t) async {
        await montarHex(
          t,
          AvanceReporteHex(
            enEstado(estado, pendiente: 'Texto del SP para $estado'),
            compacto: true,
          ),
          ancho: 390,
        );
        final cs =
            Theme.of(t.element(find.byType(AvanceReporteHex))).colorScheme;
        final hc = HexColores.desde(cs);
        expect(tramos(t), [
          for (var i = 0; i < 4; i++)
            i < hechos
                ? hc.exito
                : i == hechos
                ? hc.pendiente
                : cs.outlineVariant,
        ]);
        expect(find.text('Texto del SP para $estado'), findsOneWidget);
        expect(
          find.byIcon(hechos == 4 ? Icons.paid_outlined : Icons.hourglass_top),
          findsOneWidget,
        );
        await cerrar(t);
      });
    }

    testWidgets('sin texto del SP dice el paso que sigue', (t) async {
      await montarHex(
        t,
        Column(
          children: [
            AvanceReporteHex(enEstado('REPORTADO'), compacto: true),
            AvanceReporteHex(enEstado('LIQUIDADO'), compacto: true),
          ],
        ),
        ancho: 390,
      );
      expect(find.text('Siguiente paso: Visto bueno'), findsOneWidget);
      expect(find.text('Pagado'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('rechazado o anulado: aviso con quién y el motivo', (t) async {
      await montarHex(
        t,
        Column(
          children: [
            AvanceReporteHex(
              enEstado(
                'RECHAZADO',
                pendiente: 'Rechazado por Rojas Vargas Luis',
                motivo: 'La salida real fue a las 18:05.',
              ),
              compacto: true,
            ),
            AvanceReporteHex(enEstado('ANULADO', pendiente: 'Anulado')),
            AvanceReporteHex(enEstado('OTRO')),
          ],
        ),
        ancho: 390,
      );
      expect(tramos(t), isEmpty, reason: 'sin barra');
      expect(find.text('Rechazado por Rojas Vargas Luis'), findsOneWidget);
      expect(
        find.text('Motivo: La salida real fue a las 18:05.'),
        findsOneWidget,
      );
      expect(find.text('Anulado'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
      for (final a in t.widgetList<AvisoHex>(find.byType(AvisoHex))) {
        expect(a.tono, TonoHex.error);
      }
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('los pasos con su nombre al 150 % a $ancho px', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          Padding(
            padding: const EdgeInsets.all(Esp.l),
            child: AvanceReporteHex(enEstado('VISTO_BUENO')),
          ),
          ancho: ancho,
        );
        for (final paso in pasosReporteHex) {
          expect(find.text(paso), findsOneWidget, reason: paso);
        }
        expect(find.byIcon(Icons.check), findsNWidgets(2));
        expect(find.text('Siguiente paso: Aprobado'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('el detalle de un rechazado pone el motivo arriba de todo', (
      t,
    ) async {
      final repo = HexReporteFalso();
      final rechazado = HexReporteEntity(
        idReporte: BigInt.from(105),
        nombreEmpleado: 'Mamani Quispe Juan Carlos',
        fechaJornada: DateTime(2026, 10, 20),
        estado: 'RECHAZADO',
        estadoTexto: 'Rechazado',
        textoPendiente: 'Rechazado por Rojas Vargas Luis',
        motivoRechazo: 'La salida real fue a las 18:05.',
      );
      repo.programar('detalle', [rechazado]);
      await montarHex(
        t,
        Builder(
          builder:
              (c) => Center(
                child: FilledButton(
                  onPressed:
                      () => mostrarDetalleReporteHex(c, BigInt.from(105)),
                  child: const Text('Abrir'),
                ),
              ),
        ),
        ancho: 390,
        overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
      );
      await t.tap(find.text('Abrir'));
      await esperar(t);
      final aviso = find.text('Rechazado por Rojas Vargas Luis');
      expect(aviso, findsOneWidget);
      expect(
        t.getTopLeft(aviso).dy,
        lessThan(t.getTopLeft(find.text(rechazado.nombreEmpleado)).dy),
      );
      expect(find.text('Visto bueno'), findsNothing, reason: 'sin pasos');
      await cerrar(t);
    });
  });

  group('códigos que se explican (R9)', () {
    testWidgets('un código que hoy no está vigente lo dice', (t) async {
      final errores = capturarErrores();
      await montarHex(
        t,
        const Center(child: CodigoHex('ZZ', explicar: true)),
        ancho: 390,
        overrides: [
          hexReporteRepositoryProvider.overrideWithValue(HexReporteFalso()),
        ],
      );
      await t.tap(find.text('ZZ'));
      await esperar(t, 3);
      expect(
        find.textContaining('El código ZZ no está entre los vigentes hoy'),
        findsOneWidget,
      );
      expect(find.text('Ver todos los códigos'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('un tramo explica su factor, horario y tipo de día', (t) async {
      await montarHex(
        t,
        const Center(
          child: CodigoHex(
            'H50',
            familia: FamiliaCodigoHex.tramo,
            multiplicador: 1.5,
            explicar: true,
          ),
        ),
        ancho: 390,
        overrides: [
          hexReporteRepositoryProvider.overrideWithValue(HexReporteFalso()),
        ],
      );
      await t.tap(find.text('H50'));
      await esperar(t, 3);
      expect(find.text('Hora extra con recargo del 50 %'), findsOneWidget);
      expect(find.text('Día hábil · ×1,5 · 20:00–24:00'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin explicar, el código no responde al toque', (t) async {
      final repo = HexReporteFalso();
      await montarHex(
        t,
        const Center(child: CodigoHex('C', familia: FamiliaCodigoHex.comida)),
        ancho: 390,
        overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
      );
      await t.tap(find.text('C'), warnIfMissed: false);
      await esperar(t, 2);
      expect(find.byType(BottomSheet), findsNothing);
      expect(repo.vecesDe('leyendaCodigos'), 0);
      await cerrar(t);
    });
  });

  group('detalle del reporte', () {
    Widget abridor(BigInt id) => Builder(
      builder:
          (c) => Center(
            child: FilledButton(
              onPressed: () => mostrarDetalleReporteHex(c, id),
              child: const Text('Abrir'),
            ),
          ),
    );

    for (final ancho in [390.0, 1400.0]) {
      testWidgets(
        'detalle muestra el origen de cada hora, provisional y aviso de biométrico a $ancho px',
        (t) async {
          final repo = HexReporteFalso();
          final errores = capturarErrores();
          await montarHex(
            t,
            abridor(reporteDomingo.idReporte!),
            ancho: ancho,
            overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
          );
          await t.tap(find.text('Abrir'));
          await esperar(t);
          expect(errores, isEmpty, reason: detalle(errores));
          // Hoja inferior en el teléfono, diálogo en el escritorio.
          expect(
            find.byType(BottomSheet),
            ancho < hexAnchoTabla ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(Dialog),
            ancho < hexAnchoTabla ? findsNothing : findsOneWidget,
          );
          // El nombre está en la cabecera y en el historial (marcó ella misma).
          expect(find.text(reporteDomingo.nombreEmpleado), findsWidgets);
          // Inicio por la app y fin corregido: el origen y la marca del reporte.
          expect(find.text('App · con ubicación'), findsOneWidget);
          expect(find.text('Corregida por el encargado'), findsOneWidget);
          expect(find.text('Editado'), findsOneWidget);
          // En el detalle cada origen dice además qué significa.
          expect(
            find.text('Marcada en la app; se guardó dónde estabas.'),
            findsOneWidget,
          );
          expect(find.text('Monto provisional'), findsOneWidget);
          expect(
            find.text(
              'El biométrico registra otra hora; revisa antes de pagar.',
            ),
            findsOneWidget,
          );
          expect(find.textContaining('vacaci'), findsNothing);
          // Líneas e historial vienen del repositorio con el mismo id. D36
          // puso «Por tramos» antes: en el teléfono hay que bajar.
          await t.scrollUntilVisible(
            find.text('HD'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.text('HD'), findsOneWidget);
          await t.scrollUntilVisible(
            find.text('Edición de hora'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(
            find.text('Fin: sin hora → Fin: 25/10/2026 11:00 (EDITADO)'),
            findsOneWidget,
          );
          expect(
            repo.argumentosDe('detalle').single['idReporte'],
            reporteDomingo.idReporte,
          );
          expect(
            repo.argumentosDe('historial').single['idReporte'],
            reporteDomingo.idReporte,
          );
          await cerrar(t);
        },
      );
    }

    testWidgets('un evento con solo el valor anterior se rotula «antes»', (
      t,
    ) async {
      final repo =
          HexReporteFalso()..programar('historial', [
            [
              HexReporteEventoEntity(
                idEvento: BigInt.from(9),
                tipo: 'MOTIVO',
                tipoTexto: 'Cambio de motivo',
                valorAnterior: 'Descarga del contenedor 12',
                fecha: DateTime(2026, 10, 26, 10),
              ),
            ],
          ]);
      await montarHex(
        t,
        abridor(reporteDomingo.idReporte!),
        overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
      );
      await t.tap(find.text('Abrir'));
      await esperar(t);
      await t.scrollUntilVisible(
        find.text('Cambio de motivo'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('antes: Descarga del contenedor 12'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un reporte que no llega dice que no se encontró', (t) async {
      final repo = HexReporteFalso()..programar('detalle', [null]);
      await montarHex(
        t,
        abridor(BigInt.from(999)),
        overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
      );
      await t.tap(find.text('Abrir'));
      await esperar(t);
      expect(find.text('No se encontró el reporte'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('falsos', () {
    final filtro = (
      desde: null,
      hasta: null,
      estado: null,
      pagina: 1,
      tamano: 20,
    );

    test('una respuesta programada que no sirve da un error claro', () async {
      final repo = HexReporteFalso()..programar('misReportes', [null]);
      await expectLater(
        repo.misReportes(filtro),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'mensaje',
            contains('programar("misReportes")'),
          ),
        ),
      );
    });

    test('el historial respeta el reporte pedido', () async {
      final repo = HexReporteFalso();
      expect(await repo.historial(BigInt.from(101)), isEmpty);
      expect(await repo.historial(BigInt.from(102)), hasLength(2));
    });
  });

  group('piezas de la planilla', () {
    test('cuentaHex, sucursalHex y altoTablaHex', () {
      expect(cuentaHex(1, 'reporte', 'reportes'), '1 reporte');
      expect(cuentaHex(3, 'reporte', 'reportes'), '3 reportes');
      expect(sucursalHex(' Planta El Alto ', BigInt.one), 'Planta El Alto');
      expect(sucursalHex(null, BigInt.from(3)), 'Sucursal 3');
      // Lo que piden las filas, entre el mínimo del vacío y el máximo.
      expect(altoTablaHex(0, maximo: 900), 280);
      expect(altoTablaHex(6, maximo: 900), 49 + 6 * 64 + 8);
      expect(altoTablaHex(6, maximo: 900, conPaginador: true), 505);
      expect(altoTablaHex(50, maximo: 900), 900);
    });

    testWidgets('el origen en palabras del SP reemplaza al rótulo fijo', (
      t,
    ) async {
      await montarHex(
        t,
        Column(
          children: [
            const OrigenHoraHex('BIOMETRICO', texto: 'Marca del biométrico'),
            const OrigenHoraHex('APP', texto: '  '),
            HoraOrigenHex(
              DateTime(2026, 9, 12, 21, 30),
              'EDITADO',
              textoOrigen: 'Editada por el encargado',
            ),
          ],
        ),
      );
      expect(find.text('Marca del biométrico'), findsOneWidget);
      expect(find.text('Biométrico'), findsNothing);
      expect(find.text('App · con ubicación'), findsOneWidget);
      expect(find.text('Editada por el encargado'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('el pie de cifras a $ancho px sin desbordes', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          const SingleChildScrollView(
            child: CifrasHex(
              principal: (rotulo: 'Total en dinero', valor: 'Bs 123.456,50'),
              cifras: [
                (rotulo: 'Horas', valor: 'Bs 120.000,00'),
                (rotulo: 'Comidas', valor: 'Bs 3.456,50'),
                (rotulo: 'Empleados', valor: '140'),
              ],
            ),
          ),
          ancho: ancho,
        );
        expect(find.text('Bs 123.456,50'), findsOneWidget);
        expect(find.text('Empleados'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('sin su ancho mínimo, una grilla va en tarjetas y no de lado', (
      t,
    ) async {
      final errores = capturarErrores();
      await montarHex(
        t,
        SizedBox(
          height: 400,
          child: ListadoHex<HexReporteEntity>(
            filas: reportesFalsos,
            anchoMinimoTabla: 1500,
            columnas: [
              BosqueColumn(
                label: 'Empleado',
                cellBuilder: (r) => Text(r.nombreEmpleado),
              ),
            ],
            tarjeta: (r) => TarjetaReporteHex(r),
          ),
        ),
        ancho: 900,
      );
      expect(find.text('Empleado'), findsNothing);
      expect(find.byType(TarjetaReporteHex), findsWidgets);
      bool lateral(Widget w) =>
          w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;
      expect(find.byWidgetPredicate(lateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    test('gruposHex y cabeceraPorGrupoHex siguen las filas seguidas', () {
      final filas = ['Producción', 'Producción', 'Almacén', 'Producción'];
      expect(gruposHex(filas, (f) => f), 3);
      expect(gruposHex(<String>[], (f) => f), 0);
      final cabecera = cabeceraPorGrupoHex(filas, (f) => f, (f) => Text(f));
      expect(
        [for (var i = 0; i < 4; i++) cabecera(i) != null],
        [true, false, true, true],
      );
    });

    for (final enTabla in [true, false]) {
      testWidgets('la franja de un grupo (en tabla: $enTabla)', (t) async {
        final errores = capturarErrores();
        await montarHex(
          t,
          SizedBox(
            width: 600,
            child: FranjaGrupoHex(
              titulo: 'Producción',
              detalle: '3 empleados',
              enTabla: enTabla,
              icono: Icons.groups_outlined,
              accion: TextButton(onPressed: () {}, child: const Text('Ver')),
            ),
          ),
          ancho: 700,
        );
        expect(find.text('Producción — 3 empleados'), findsOneWidget);
        expect(find.text('Ver'), findsOneWidget);
        expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('cajaTablaHex: caja con su alto solo en tabla', (t) async {
      const lista = Placeholder();
      await montarHex(
        t,
        Column(
          children: [
            cajaTablaHex(tabla: true, filas: 2, maximo: 900, lista: lista),
            cajaTablaHex(tabla: false, filas: 2, maximo: 900, lista: lista),
          ],
        ),
      );
      final cajas = t.widgetList<SizedBox>(
        find.ancestor(
          of: find.byType(Placeholder),
          matching: find.byType(SizedBox),
        ),
      );
      expect(cajas.where((c) => c.height == 280), hasLength(1));
      await cerrar(t);
    });

    testWidgets('la caja de una tabla usa el alto por fila que se le dé', (
      t,
    ) async {
      await montarHex(
        t,
        cajaTablaHex(
          tabla: true,
          filas: 4,
          maximo: 900,
          porFila: 112,
          lista: const Placeholder(),
        ),
      );
      final caja = t.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(Placeholder),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(caja.height, altoTablaHex(4, maximo: 900, porFila: 112));
      expect(caja.height, 49 + 4 * 112 + 8);
      await cerrar(t);
    });

    testWidgets('el total de una anulada no se paga y lo dice', (t) async {
      await montarHex(
        t,
        Column(
          children: [
            TotalPlanillaHex(planillasFalsas[0]),
            TotalPlanillaHex(planillasFalsas[1]),
          ],
        ),
      );
      expect(planillaEjecutadaHex(planillasFalsas[0]), isTrue);
      expect(planillaAnuladaHex(planillasFalsas[1]), isTrue);
      expect(find.text('Bs 9.035,50'), findsOneWidget);
      expect(find.text('Bs 7.580,00'), findsOneWidget);
      // Solo la anulada lleva la leyenda.
      expect(find.text('no se paga'), findsOneWidget);
      expect(
        textoAnulacionPlanillaHex(planillasFalsas[1]),
        'Anulada por Salazar Rivera Jorge el 03/09/2026 16:45. Motivo: Se '
        'ejecutó con el haber básico anterior.',
      );
      await cerrar(t);
    });

    testWidgets('el total no contable va sin la doble raya', (t) async {
      await montarHex(
        t,
        const Column(
          children: [
            CifrasHex(principal: (rotulo: 'Total en dinero', valor: 'Bs 1,00')),
            CifrasHex(
              contable: false,
              principal: (
                rotulo: 'Total (anulada, no se paga)',
                valor: 'Bs 2,00',
              ),
            ),
          ],
        ),
      );
      // Dos rayas en el total contable; ninguna en el otro.
      expect(find.byType(Divider), findsNWidgets(2));
      expect(find.text('Total (anulada, no se paga)'), findsOneWidget);
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('la leyenda congelada a $ancho px', (t) async {
        final errores = capturarErrores();
        await montarHex(
          t,
          const SingleChildScrollView(
            child: LeyendaPlanillaHex([
              HexCodigoLeyendaEntity(
                concepto: 'TRAMO',
                codigo: 'H50',
                leyenda: 'Horas al 50 %',
                multiplicador: 1.5,
              ),
              HexCodigoLeyendaEntity(
                concepto: 'COMIDA',
                codigo: 'C',
                leyenda: 'Cena',
                valorUnitario: 15,
              ),
            ]),
          ),
          ancho: ancho,
        );
        expect(find.text('como se pagó en esta planilla'), findsOneWidget);
        expect(find.text('Horas extra'), findsOneWidget);
        expect(find.text('Comidas'), findsOneWidget);
        expect(find.text('×1,5'), findsOneWidget);
        expect(find.text('Bs 15,00'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}

/// Un diálogo del kit armado como lo hacen las pantallas.
class _DialogoDePrueba extends StatefulWidget {
  const _DialogoDePrueba({required this.accion, required this.alRecargar});

  final Future<HexRespuesta> Function(bool confirmado) accion;
  final VoidCallback alRecargar;

  @override
  State<_DialogoDePrueba> createState() => _DialogoDePruebaState();
}

class _DialogoDePruebaState extends State<_DialogoDePrueba>
    with EscrituraEnDialogoHex {
  final TextEditingController _texto = TextEditingController();

  @override
  VoidCallback get refrescarLista => widget.alRecargar;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DialogoHex(
    titulo: 'Prueba',
    icono: Icons.edit_note,
    ocupado: ocupado,
    accion: 'Guardar',
    alAceptar: () => escribir(widget.accion),
    contenido:
        (enCurso) => [
          TextoLargoHex(
            control: _texto,
            etiqueta: 'Observación',
            ayuda: 'Opcional.',
            habilitado: !enCurso,
          ),
        ],
  );
}
