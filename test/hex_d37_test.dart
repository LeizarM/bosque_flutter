import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/core/state/hex_planilla_provider.dart';
import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_previa_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_linea_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_vista_marcacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_planilla_repository.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_anular_planilla_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_asignacion_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_mis_horas_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_parametros_screen.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_planilla_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_detalle_reporte.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';
import 'fakes/ubicacion_hex_falsa.dart';

/// D37 a D40 en la app: la asignación del encargado, «Mis horas extras»
/// bloqueada y sus teclas según el SP, lo que deja ver cada rol (D38), el
/// lote de planillas con lo que falta firmar (D39) y la comida por período.
void main() {
  setUpAll(cargarFuentesHex);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'hex_como_funciona_plegada': true,
    }),
  );

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  Finder botonDelDialogo(String texto) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(FilledButton, texto),
  );

  ButtonStyleButton boton(WidgetTester t, String texto) =>
      t.widget<ButtonStyleButton>(
        find
            .ancestor(
              of: find.text(texto),
              matching: find.bySubtype<ButtonStyleButton>(),
            )
            .first,
      );

  Future<void> tocar(WidgetTester t, Finder f, {int fotogramas = 4}) async {
    await t.ensureVisible(f);
    await esperar(t, 1);
    await t.tap(f);
    await esperar(t, fotogramas);
  }

  // Anchos y letras que pide el módulo: teléfono y escritorio, 1.0 y 1.5.
  const casos = <(double, double)>[
    (390, 1.0),
    (390, 1.5),
    (1400, 1.0),
    (1400, 1.5),
  ];

  // ═════════════════════════════════════════════════════════════════════════
  // D37: MIS HORAS EXTRAS
  // ═════════════════════════════════════════════════════════════════════════

  group('Mis horas extras (D37)', () {
    late HexReporteFalso repo;

    setUp(() => repo = HexReporteFalso());

    Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
      await montarHex(
        t,
        const HexMisHorasScreen(),
        ancho: ancho,
        overrides: [
          hexReporteRepositoryProvider.overrideWithValue(repo),
          hexUbicacionProvider.overrideWithValue(UbicacionHexFalsa()),
        ],
      );
      await esperar(t);
    }

    const sinAsignacion = HexVistaMarcacionEntity(
      textoVista: 'Tu encargado no te asignó horas extra para hoy.',
      textoMarcarEntrada: 'Sin asignación.',
      textoMarcarSalida: 'Sin asignación.',
    );

    for (final (ancho, escala) in casos) {
      testWidgets('sin asignación queda bloqueada a $ancho px y $escala', (
        t,
      ) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        repo.programar('hoy', [sinAsignacion]);
        final errores = capturarErrores();
        await montar(t, ancho: ancho);

        expect(find.text(sinAsignacion.textoVista), findsOneWidget);
        expect(find.text('Marcar salida'), findsNothing);
        expect(repo.vecesDe('misReportes'), 0);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('«Volver a consultar» pide reporte/hoy de nuevo', (t) async {
      repo.programar('hoy', [sinAsignacion, vistaMarcacionFalsa]);
      await montar(t);
      expect(repo.vecesDe('hoy'), 1);
      await tocar(t, find.text('Volver a consultar'));
      expect(repo.vecesDe('hoy'), 2);
      expect(find.text('Marcar salida'), findsOneWidget);
      expect(find.text(vistaMarcacionFalsa.textoVista), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un 403 de reporte/hoy se ve como «No tienes permiso»', (
      t,
    ) async {
      repo.programar('hoy', [const SinPermisoHex('No tienes los permisos.')]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.text('Marcar salida'), findsNothing);
      await cerrar(t);
    });

    testWidgets('la salida ya registrada deja su tecla apagada con el texto', (
      t,
    ) async {
      const salidaHecha = 'Ya registraste tu salida de esta jornada.';
      repo.programar('hoy', [
        HexVistaMarcacionEntity(
          vistaHabilitada: true,
          textoVista: vistaMarcacionFalsa.textoVista,
          puedeMarcarEntrada: true,
          textoMarcarEntrada: 'Puedes marcar tu entrada.',
          textoMarcarSalida: salidaHecha,
        ),
      ]);
      await montar(t, ancho: 390);
      // D41: la tecla que no vale no se dibuja; queda su texto del SP.
      expect(find.text(salidaHecha), findsOneWidget);
      expect(find.text('Marcar salida'), findsNothing);
      expect(boton(t, 'Marcar entrada').onPressed, isNotNull);
      await cerrar(t);
    });

    testWidgets('sin verMontos no hay columna Monto ni Bs en la lista', (
      t,
    ) async {
      final sinDinero = [
        for (final r in reportesFalsos)
          HexReporteEntity(
            idReporte: r.idReporte,
            nombreEmpleado: r.nombreEmpleado,
            fechaJornada: r.fechaJornada,
            inicio: r.inicio,
            fin: r.fin,
            horasPagables: r.horasPagables,
            estado: r.estado,
            estadoTexto: r.estadoTexto,
            totalFilas: r.totalFilas,
          ),
      ];
      repo.programar('misReportes', [
        (filas: sinDinero, total: sinDinero.length),
      ]);
      await montar(t);
      expect(find.text('Monto'), findsNothing);
      expect(find.byType(MontoHex), findsNothing);
      expect(find.text('Anular'), findsNothing);
      await cerrar(t);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // D38: EL DETALLE SEGÚN EL ROL
  // ═════════════════════════════════════════════════════════════════════════

  group('detalle según lo que deja ver el SP (D38)', () {
    Future<void> abrir(WidgetTester t, HexReporteFalso repo) async {
      await montarHex(
        t,
        Builder(
          builder:
              (c) => Center(
                child: FilledButton(
                  onPressed: () => mostrarDetalleReporteHex(c, BigInt.one),
                  child: const Text('Abrir'),
                ),
              ),
        ),
        ancho: 390,
        overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
      );
      await t.tap(find.text('Abrir'));
      await esperar(t);
    }

    testWidgets('el dueño no ve dinero, ni tramos, ni desglose, ni historial', (
      t,
    ) async {
      final repo =
          HexReporteFalso()..programar('detalle', [
            HexReporteEntity(
              idReporte: BigInt.one,
              nombreEmpleado: 'Apaza Mamani Pedro',
              fechaJornada: DateTime(2026, 11, 5),
              horasPagables: 2,
              estado: 'REPORTADO',
              estadoTexto: 'Reportado',
            ),
          ]);
      final errores = capturarErrores();
      await abrir(t, repo);
      expect(find.text('Apaza Mamani Pedro'), findsOneWidget);
      expect(find.text('Total'), findsNothing);
      expect(find.text('Por tramos'), findsNothing);
      expect(find.text('Desglose'), findsNothing);
      expect(find.text('Historial'), findsNothing);
      expect(repo.vecesDe('tramos'), 0);
      expect(repo.vecesDe('lineas'), 0);
      expect(repo.vecesDe('historial'), 0);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('el encargado ve el desglose sin montos (nulos)', (t) async {
      final repo =
          HexReporteFalso()
            ..programar('detalle', [
              HexReporteEntity(
                idReporte: BigInt.one,
                nombreEmpleado: 'Apaza Mamani Pedro',
                estado: 'REPORTADO',
                estadoTexto: 'Reportado',
                puedeVerDetalle: true,
              ),
            ])
            ..programar('lineas', [
              [
                HexReporteLineaEntity(
                  idReporte: BigInt.one,
                  concepto: 'TRAMO',
                  codigo: 'H50',
                  leyenda: 'Hora extra 50 %',
                  cantidad: 1.5,
                  multiplicador: 1.5,
                ),
              ],
            ]);
      final errores = capturarErrores();
      await abrir(t, repo);
      await t.scrollUntilVisible(
        find.text('Desglose'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await esperar(t, 2);
      expect(repo.vecesDe('lineas'), 1);
      expect(find.textContaining('Bs '), findsNothing);
      expect(repo.vecesDe('historial'), 0);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // D37: ASIGNAR HORAS EXTRA
  // ═════════════════════════════════════════════════════════════════════════

  group('Asignar horas extra (D37)', () {
    late HexAsignacionFalso repo;

    setUp(() => repo = HexAsignacionFalso());

    Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
      await montarHex(
        t,
        const HexAsignacionScreen(),
        ancho: ancho,
        overrides: [hexAsignacionRepositoryProvider.overrideWithValue(repo)],
      );
      await esperar(t);
    }

    Finder casillaDe(String nombre) =>
        find.bySemanticsLabel('Elegir a $nombre');

    for (final (ancho, escala) in casos) {
      testWidgets('asignables con su aviso a $ancho px y $escala', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        expect(find.text('Asignar horas extra'), findsWidgets);
        expect(find.text('Apaza Mamani Pedro'), findsOneWidget);
        expect(
          find.text('MAMANI SOSSA está de vacaciones el 05/11/2026'),
          findsOneWidget,
        );
        expect(find.text('Asignado por Rojas Vargas Luis'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));

        await tocar(t, find.text('Historial').first);
        expect(find.text('Quitada'), findsOneWidget);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('asignar con aviso confirma y reenvía el mismo cuerpo', (
      t,
    ) async {
      const pregunta =
          'MAMANI SOSSA está de vacaciones el 05/11/2026; ¿Confirmas que '
          'igual le asignas horas extra?';
      repo.programar('asignar', [
        const ConfirmacionHex(pregunta),
        (id: BigInt.from(40), mensaje: 'Horas extra asignadas a A, B.'),
      ]);
      await montar(t);
      expect(boton(t, 'Asignar horas extra').onPressed, isNull);
      await tocar(t, casillaDe('Apaza Mamani Pedro'), fotogramas: 1);
      await tocar(t, casillaDe('Mamani Sossa Rosa'), fotogramas: 1);
      expect(find.text('2 personas elegidas'), findsOneWidget);
      await tocar(t, find.widgetWithText(FilledButton, 'Asignar horas extra'));
      expect(enDialogo(pregunta), findsOneWidget);
      await t.tap(botonDelDialogo('Confirmar'));
      await esperar(t, 4);

      final envios = repo.argumentosDe('asignar');
      expect(envios, hasLength(2));
      expect(envios.first['codEmpleados'], [
        BigInt.from(191),
        BigInt.from(203),
      ]);
      expect(envios.last['codEmpleados'], envios.first['codEmpleados']);
      expect([for (final e in envios) e['confirmado']], [false, true]);
      expect(find.text('Horas extra asignadas a A, B.'), findsOneWidget);
      // Asignó: la selección se limpia y la lista se vuelve a pedir.
      expect(find.text('2 personas elegidas'), findsNothing);
      expect(repo.vecesDe('asignables'), greaterThan(1));
      await cerrar(t);
    });

    testWidgets('quien ya está asignado no se elige; quitar manda el id', (
      t,
    ) async {
      await montar(t);
      // Tres casillas y solo la de Quispe (ya asignado) va apagada.
      final casillas = t.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(casillas, hasLength(3));
      expect(casillas.where((c) => c.onChanged == null), hasLength(1));

      await tocar(t, find.text('Historial').first);
      await tocar(t, find.byTooltip('Quitar asignación').first);
      expect(find.text('Quitar asignación'), findsOneWidget);
      await t.tap(botonDelDialogo('Quitar'));
      await esperar(t, 4);
      expect(
        repo.argumentosDe('quitar').single['idAsignacion'],
        BigInt.from(31),
      );
      await cerrar(t);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // D39: LOTE DE PLANILLAS
  // ═════════════════════════════════════════════════════════════════════════

  group('lote de planillas (D39)', () {
    late HexPlanillaFalso repo;

    setUp(() => repo = HexPlanillaFalso());

    List<Override> anulaciones() => [
      hexPlanillaRepositoryProvider.overrideWithValue(repo),
      hexReporteRepositoryProvider.overrideWithValue(HexReporteFalso()),
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

    Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
      await montarHex(
        t,
        const HexPlanillaScreen(),
        ancho: ancho,
        overrides: anulaciones(),
      );
      await esperar(t);
    }

    final firmas = <HexPlanillaFirmaEntity>[
      HexPlanillaFirmaEntity(
        idReporte: BigInt.from(5),
        nombreEmpleado: 'Santos Rojas Ana',
        fechaJornada: DateTime(2026, 10, 30),
        estado: 'REPORTADO',
        estadoTexto: 'Reportado',
        codSucursal: BigInt.from(23),
        nombreSucursal: 'Central',
        debeFirmar: 'Rojas Vargas Luis',
        textoPendiente: 'Espera el visto bueno de Rojas Vargas Luis',
      ),
    ];

    for (final (ancho, escala) in casos) {
      testWidgets('falta firmar bloquea el lote a $ancho px y $escala', (
        t,
      ) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        repo.programar('pendientesFirma', [firmas]);
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        expect(find.text('Lote del mes'), findsOneWidget);
        await tocar(t, find.text('Ver lote del mes'));

        final c =
            repo.argumentosDe('vistaPrevia').last['combinacion']!
                as CombinacionHex;
        expect(esLoteHex(c), isTrue);
        expect(find.text('Falta firmar'), findsOneWidget);
        expect(
          find.text('Espera el visto bueno de Rojas Vargas Luis'),
          findsOneWidget,
        );
        expect(boton(t, 'Ejecutar lote').onPressed, isNull);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('mes sin horas extra: el texto del SP como aviso', (t) async {
      const sinNada =
          'No hubo horas extra aprobadas en octubre de 2026: no hay planilla '
          'que ejecutar.';
      repo.programar('ejecutarLote', [const NegocioHex(sinNada)]);
      await montar(t);
      await tocar(t, find.text('Ver lote del mes'));
      expect(boton(t, 'Ejecutar lote').onPressed, isNotNull);
      await tocar(t, find.widgetWithText(FilledButton, 'Ejecutar lote').first);
      expect(find.byType(AlertDialog), findsOneWidget);
      await t.tap(botonDelDialogo('Ejecutar lote'));
      await esperar(t, 4);
      expect(repo.vecesDe('ejecutarLote'), 1);
      expect(repo.vecesDe('ejecutar'), 0);
      expect(find.text(sinNada), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('una planilla de lote ofrece el PDF del lote', (t) async {
      repo.programar('planillas', [
        [
          HexPlanillaEntity(
            idPlanilla: BigInt.from(9),
            codEmpresa: BigInt.from(2),
            anio: 2026,
            mes: 10,
            periodoTexto: 'Octubre de 2026',
            codSucursal: BigInt.from(23),
            nombreSucursal: 'Central',
            estado: 'EJECUTADA',
            estadoTexto: 'Ejecutada',
            total: 170.63,
            idLote: BigInt.from(7),
          ),
        ],
      ]);
      await montar(t);
      await tocar(t, find.text('Ejecutadas'));
      expect(find.text('Lote 7'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('anular lote (D39)', () {
    testWidgets('anular lote manda el lote y el motivo', (t) async {
      final repo =
          HexPlanillaFalso()..programar('planillas', [
            [
              for (final s in [23, 24])
                HexPlanillaEntity(
                  idPlanilla: BigInt.from(s),
                  codEmpresa: BigInt.from(2),
                  anio: 2026,
                  mes: 10,
                  periodoTexto: 'Octubre de 2026',
                  codSucursal: BigInt.from(s),
                  nombreSucursal: 'Sucursal $s',
                  estado: 'EJECUTADA',
                  estadoTexto: 'Ejecutada',
                  idLote: BigInt.from(7),
                ),
            ],
          ]);
      await montarHex(
        t,
        const HexAnularPlanillaScreen(),
        ancho: 390,
        overrides: [
          hexPlanillaRepositoryProvider.overrideWithValue(repo),
          empresasProvider.overrideWith((ref) => EmpresasNotifier(_Rrhh([]))),
        ],
      );
      await esperar(t);
      await tocar(t, find.byTooltip('Acciones').first, fotogramas: 2);
      await t.tap(find.text('Anular lote').last);
      await esperar(t, 3);
      expect(
        find.textContaining('2 planillas (Sucursal 23, Sucursal 24)'),
        findsOneWidget,
      );
      await t.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Haber equivocado',
      );
      await t.tap(botonDelDialogo('Anular lote'));
      await esperar(t, 4);
      expect(repo.argumentosDe('anularLote').single, {
        'idLote': BigInt.from(7),
        'observacion': 'Haber equivocado',
      });
      await cerrar(t);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // D40: COMIDA POR PERÍODO
  // ═════════════════════════════════════════════════════════════════════════

  group('comida por período (D40)', () {
    for (final (ancho, escala) in [(390.0, 1.5), (1400.0, 1.0)]) {
      testWidgets('sin doble en un período a $ancho px y $escala', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final repo = HexConfiguracionFalso();
        final errores = capturarErrores();
        await montarHex(
          t,
          const HexParametrosScreen(),
          ancho: ancho,
          overrides: [
            hexConfiguracionRepositoryProvider.overrideWithValue(repo),
          ],
        );
        await esperar(t);
        await tocar(
          t,
          find.descendant(
            of: find.byType(TabBar),
            matching: find.text('Comidas'),
          ),
        );
        final fila =
            find
                .ancestor(
                  of: find.text('Cena').first,
                  matching: find.byType(InkWell),
                )
                .first;
        final enLinea = find.descendant(
          of: fila,
          matching: find.byTooltip('Nueva vigencia'),
        );
        if (enLinea.evaluate().isNotEmpty) {
          await tocar(t, enLinea);
        } else {
          await tocar(
            t,
            find.descendant(of: fila, matching: find.byTooltip('Acciones')),
            fotogramas: 2,
          );
          await t.tap(find.text('Nueva vigencia').last);
          await esperar(t, 3);
        }
        await tocar(t, enDialogo('Un período'), fotogramas: 2);
        expect(enDialogo('Configuración por período'), findsOneWidget);
        await tocar(
          t,
          find.descendant(
            of: find.widgetWithText(SwitchListTile, 'Paga la comida doble'),
            matching: find.byType(Switch),
          ),
          fotogramas: 1,
        );
        await t.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(
              TextField,
              'Minutos para ganar la comida',
            ),
          ),
          '90',
        );
        await tocar(
          t,
          find
              .ancestor(
                of: enDialogo('Primer día del período'),
                matching: find.byType(InkWell),
              )
              .first,
          fotogramas: 2,
        );
        await t.tap(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('1'),
          ),
        );
        await t.tap(find.text('Aceptar'));
        await esperar(t, 2);
        await t.tap(enDialogo('Guardar'));
        await esperar(t, 4);

        expect(repo.vecesDe('nuevaVigenciaComida'), 0);
        final args = repo.argumentosDe('periodoComida').single;
        final c = args['comida']! as HexComidaEntity;
        expect(c.codigo, 'C');
        expect(c.conDoble, isFalse);
        expect(c.minutosSimple, 90);
        expect(c.vigenteDesde?.day, 1);
        expect(args['hasta'], isNull);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });
}

class _Rrhh extends Fake implements RRHHRepositoryImpl {
  _Rrhh(this.empresas);

  final List<EmpresaEntity> empresas;

  @override
  Future<List<EmpresaEntity>> lstEmpresas() async => empresas;
}
