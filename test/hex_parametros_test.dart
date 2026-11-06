import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/agenda_provider.dart';
import 'package:bosque_flutter/core/state/hex_configuracion_provider.dart';
import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_configuracion_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_clave_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_parametro_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_configuracion_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_parametros_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_mapa_tramos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_tramos_reporte.dart'
    show BarraTramosHex;
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_vigencias.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// «Parámetros»: vigencias agrupadas con su leyenda, vigencia nueva prellenada
/// (fila completa), leyendas por separado, eliminar, mensajes del SP, permisos
/// por botón, historial de cambios (D22), anchos y teclado abierto.
void main() {
  setUpAll(cargarFuentesHex);

  late HexConfiguracionFalso repo;

  setUp(() => repo = HexConfiguracionFalso());

  final hoy = DateTime.now();

  /// El día 15 del mes en que abre el calendario de «Rige desde» (hoy).
  final dia15 = DateTime(hoy.year, hoy.month, 15);

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  /// La agenda del simulador: Manuel (155) y una compañera.
  final agenda = [
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(155),
      nombreCompleto: 'Quispe Mamani Manuel',
      cargo: 'Operario',
      codSucursal: 1,
      sucursal: 'Santa Cruz',
    ),
    AgendaEmpleadoEntity(
      codEmpleado: BigInt.from(156),
      nombreCompleto: 'Rojas Vargas Ana',
      cargo: 'Operaria',
      codSucursal: 1,
      sucursal: 'Santa Cruz',
    ),
  ];

  List<Override> anulaciones() => [
    hexConfiguracionRepositoryProvider.overrideWithValue(repo),
    agendaEmpleadosProvider.overrideWith((ref) => Future.value(agenda)),
  ];

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
  }) async {
    await montarHex(
      t,
      const HexParametrosScreen(),
      ancho: ancho,
      botones: botones,
      overrides: anulaciones(),
    );
    await esperar(t);
  }

  Finder enDialogo(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

  /// El campo de texto del diálogo con esa etiqueta.
  Finder campo(String etiqueta) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(TextField, etiqueta),
  );

  String textoDe(WidgetTester t, String etiqueta) =>
      t.widget<TextField>(campo(etiqueta)).controller!.text;

  /// Un aviso del kit: se dibuja fuera de la pantalla.
  Finder aviso(String texto) => find.byElementPredicate((e) {
    final w = e.widget;
    return w is Text &&
        w.data == texto &&
        e.findAncestorWidgetOfExactType<HexParametrosScreen>() == null;
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

  Future<void> pestana(WidgetTester t, String nombre) => tocar(
    t,
    find.descendant(of: find.byType(TabBar), matching: find.text(nombre)),
  );

  /// [accion] de la fila (o tarjeta) que muestra [texto]: en línea si está
  /// a la vista; si no, desde su menú.
  Future<void> accionDe(WidgetTester t, String texto, String accion) async {
    final fila =
        find
            .ancestor(of: find.text(texto), matching: find.byType(InkWell))
            .first;
    final enLinea = find.descendant(of: fila, matching: find.byTooltip(accion));
    if (enLinea.evaluate().isNotEmpty) {
      await tocar(t, enLinea);
    } else {
      await tocar(
        t,
        find.descendant(of: fila, matching: find.byTooltip('Acciones')),
        fotogramas: 2,
      );
      await t.tap(find.text(accion).last);
      await esperar(t, 3);
    }
  }

  /// El campo selector con esa etiqueta (la etiqueta flotante no recibe
  /// toques: se toca el campo).
  Finder selector(String etiqueta) =>
      find
          .ancestor(of: enDialogo(etiqueta), matching: find.byType(InkWell))
          .first;

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

  /// Escribe [hora]:[minuto] en el reloj que abre el campo [etiqueta].
  Future<void> elegirHora(
    WidgetTester t,
    String etiqueta, {
    required String hora,
    required String minuto,
  }) async {
    await tocar(t, selector(etiqueta), fotogramas: 2);
    await t.tap(find.byIcon(Icons.keyboard_outlined));
    await esperar(t, 1);
    final campos = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await t.enterText(campos.at(0), hora);
    await t.enterText(campos.at(1), minuto);
    await t.tap(find.text('Aceptar'));
    await esperar(t, 2);
  }

  Future<void> guardar(WidgetTester t) async {
    await t.tap(enDialogo('Guardar'));
    await esperar(t, 4);
  }

  FiltroHistorialHex ultimoHistorial() =>
      repo.argumentosDe('historial').last['filtro']! as FiltroHistorialHex;

  group('lista', () {
    testWidgets('las leyendas se ven en la lista', (t) async {
      await montar(t);
      // Parámetros: agrupados por clave, cada vigencia con su leyenda.
      // La franja muestra la leyenda vigente; la clave va como ficha.
      expect(
        find.text('Divisor del costo hora (30 días × 8 h) — 2 vigencias'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FranjaGrupoHex),
          matching: find.text('DIVISOR_COSTO_HORA'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Divisor del costo hora (30 días × 8 h)'),
        findsOneWidget,
      );
      expect(find.text('Divisor anterior'), findsOneWidget);
      expect(find.text('240'), findsOneWidget);
      expect(find.text('230'), findsOneWidget);
      expect(find.text('01/11/2026'), findsOneWidget);
      expect(find.text('Vigente'), findsNWidgets(3));
      expect(find.text('Hasta 31/12/2025'), findsOneWidget);

      await pestana(t, 'Tramos');
      expect(find.text('Hora extra con recargo del 50 %'), findsOneWidget);
      expect(find.text('Hora al 50 %'), findsOneWidget);
      // El fin 00:00 de un tramo son las 24:00.
      expect(find.text('20:00 – 24:00'), findsNWidgets(2));
      expect(find.text('×1,5'), findsOneWidget);
      expect(find.text('×1,25'), findsOneWidget);
      expect(find.text('Domingo'), findsOneWidget);
      // El grupo es código y tipo de día, como la clave del SP: la franja
      // dice la leyenda y el tipo de día; el código va como ficha.
      expect(
        find.text('Hora extra con recargo del 50 % — Día hábil · 2 vigencias'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FranjaGrupoHex),
          matching: find.text('H50'),
        ),
        findsOneWidget,
      );

      await pestana(t, 'Comidas');
      expect(find.text('Cena'), findsOneWidget);
      expect(find.text('Doble cena'), findsOneWidget);
      expect(find.text('Bs 30,00'), findsNWidgets(2));
      expect(find.text('Sin horario'), findsOneWidget);
      expect(find.text('Inactiva'), findsOneWidget);
      expect(find.text('18:00 – 20:00'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('mismo código en dos tipos de día son dos grupos', (t) async {
      HexTramoEntity tramo(int id, String tipoDia) => HexTramoEntity(
        idTramo: BigInt.from(id),
        codigo: 'HX',
        leyenda: 'Hora especial $tipoDia',
        tipoDia: tipoDia,
        horaDesde: '18:00:00',
        horaHasta: '22:00:00',
        multiplicador: 1.5,
        vigenteDesde: DateTime(2026, 1, 1),
        esVigente: true,
      );
      repo.programar('tramos', [
        [tramo(1, 'HABIL'), tramo(2, 'DOMINGO')],
      ]);
      await montar(t);
      await pestana(t, 'Tramos');
      expect(
        find.text('Hora especial HABIL — Día hábil · 1 vigencia'),
        findsOneWidget,
      );
      expect(
        find.text('Hora especial DOMINGO — Domingo · 1 vigencia'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FranjaGrupoHex),
          matching: find.text('HX'),
        ),
        findsNWidgets(2),
      );
      expect(find.text('Vigente'), findsNWidgets(2));
      await cerrar(t);
    });

    testWidgets('valor y factor con hasta 4 decimales', (t) async {
      repo
        ..programar('parametros', [
          [
            HexParametroEntity(
              idParametro: BigInt.one,
              clave: 'DIVISOR_COSTO_HORA',
              valorNumero: 240.125,
              leyenda: 'Divisor',
              vigenteDesde: DateTime(2026, 1, 1),
              esVigente: true,
            ),
          ],
        ])
        ..programar('tramos', [
          [
            HexTramoEntity(
              idTramo: BigInt.one,
              codigo: 'H50',
              leyenda: 'Recargo',
              tipoDia: 'HABIL',
              horaDesde: '20:00:00',
              horaHasta: '00:00:00',
              multiplicador: 1.125,
              vigenteDesde: DateTime(2026, 1, 1),
              esVigente: true,
            ),
          ],
        ]);
      await montar(t);
      expect(find.text('240,125'), findsOneWidget);
      await pestana(t, 'Tramos');
      expect(find.text('×1,125'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un 403 en la lista muestra No tienes permiso', (t) async {
      repo.programar('parametros', [const SinPermisoHex('Forbidden')]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('formularios', () {
    testWidgets(
      'nueva vigencia de tramo va prellenada y manda la fila completa',
      (t) async {
        await montar(t);
        await pestana(t, 'Tramos');
        final antes = repo.vecesDe('tramos');
        final historialAntes = repo.vecesDe('historial');
        await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(textoDe(t, 'Leyenda'), 'Hora extra con recargo del 50 %');
        expect(textoDe(t, 'Factor'), '1,5');
        expect(enDialogo('20:00'), findsOneWidget);
        expect(enDialogo('00:00'), findsOneWidget);
        expect(enDialogo('Día hábil'), findsOneWidget);
        await elegirDia(t, 'Rige desde', '15');
        await guardar(t);

        final e =
            repo.argumentosDe('nuevaVigenciaTramo').single['tramo']!
                as HexTramoEntity;
        expect(e.idTramo, isNull);
        expect(e.codigo, 'H50');
        expect(e.leyenda, 'Hora extra con recargo del 50 %');
        expect(e.tipoDia, 'HABIL');
        expect(e.horaDesde, '20:00:00');
        expect(e.horaHasta, '00:00:00');
        expect(e.multiplicador, 1.5);
        expect(e.orden, 2);
        expect(e.vigenteDesde, dia15);
        // Cierra, recarga la lista y el historial.
        expect(find.byType(AlertDialog), findsNothing);
        expect(repo.vecesDe('tramos'), greaterThan(antes));
        expect(repo.vecesDe('historial'), greaterThan(historialAntes));
        await cerrar(t);
      },
    );

    testWidgets('nuevo tramo: formulario vacío y horas como HH:mm:ss', (
      t,
    ) async {
      await montar(t);
      await pestana(t, 'Tramos');
      await tocar(t, find.text('Nuevo tramo'));
      expect(textoDe(t, 'Código'), isEmpty);
      expect(textoDe(t, 'Leyenda'), isEmpty);
      expect(textoDe(t, 'Factor'), isEmpty);

      await t.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      await esperar(t, 2);
      await t.tap(find.text('Domingo').last);
      await esperar(t, 2);
      await t.enterText(campo('Código'), 'HDN');
      await t.enterText(campo('Leyenda'), 'Hora nocturna de domingo');
      await elegirHora(t, 'Hora desde', hora: '22', minuto: '30');
      await elegirHora(t, 'Hora hasta', hora: '06', minuto: '00');
      await t.enterText(campo('Factor'), '2,5');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);

      final e =
          repo.argumentosDe('nuevaVigenciaTramo').single['tramo']!
              as HexTramoEntity;
      expect(e.codigo, 'HDN');
      expect(e.tipoDia, 'DOMINGO');
      expect(e.horaDesde, '22:30:00');
      expect(e.horaHasta, '06:00:00');
      expect(e.multiplicador, 2.5);
      expect(e.orden, isNull);
      expect(e.vigenteDesde, dia15);
      await cerrar(t);
    });

    testWidgets('nuevo parámetro: parte de la obligatoria que falta y el '
        'campo sigue el tipo de la clave', (t) async {
      repo.programar('catalogoParametros', [
        [
          for (final k in catalogoFalso)
            k.clave == 'FECHA_INICIO_MODULO'
                ? HexParametroClaveEntity(
                  clave: k.clave,
                  nombre: k.nombre,
                  tipoValor: k.tipoValor,
                  obligatorio: true,
                  descripcion: 'Primera jornada que se puede reportar.',
                  aviso: 'Falta «Inicio del módulo».',
                )
                : k,
        ],
      ]);
      await montar(t);
      await tocar(t, find.text('Nuevo parámetro'));
      expect(
        enDialogo('Primera jornada que se puede reportar.'),
        findsOneWidget,
      );
      expect(textoDe(t, 'Leyenda'), 'Inicio del módulo');
      expect(enDialogo('Fecha'), findsOneWidget);
      expect(campo('Valor'), findsNothing);
      await elegirDia(t, 'Fecha', '15');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);
      var p =
          repo.argumentosDe('nuevaVigenciaParametro').last['parametro']!
              as HexParametroEntity;
      expect(p.idParametro, isNull);
      expect(p.clave, 'FECHA_INICIO_MODULO');
      expect(p.valorFecha, dia15);
      expect(p.valorNumero, isNull);
      expect(p.vigenteDesde, dia15);

      // Otra clave: pide número y la leyenda sigue al nombre.
      await tocar(t, find.text('Nuevo parámetro'));
      await t.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      await esperar(t, 2);
      await t.tap(find.text('Divisor del costo hora').last);
      await esperar(t, 2);
      expect(textoDe(t, 'Leyenda'), 'Divisor del costo hora');
      expect(enDialogo('Fecha'), findsNothing);
      await t.enterText(campo('Valor'), '240');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);
      p =
          repo.argumentosDe('nuevaVigenciaParametro').last['parametro']!
              as HexParametroEntity;
      expect(p.clave, 'DIVISOR_COSTO_HORA');
      expect(p.valorNumero, 240);
      expect(p.valorFecha, isNull);
      await cerrar(t);
    });

    testWidgets('la empresa del organigrama se elige por su nombre y viaja su '
        'código', (t) async {
      repo.programar('catalogoParametros', [
        [
          ...catalogoFalso,
          const HexParametroClaveEntity(
            clave: 'EMPRESA_ORGANIGRAMA',
            nombre: 'Empresa del organigrama',
            tipoValor: 'NUMERO',
            obligatorio: true,
            aviso: 'Falta «Empresa del organigrama».',
            conOpciones: true,
          ),
        ],
      ]);
      await montar(t);
      await tocar(t, find.text('Nuevo parámetro'));
      expect(repo.argumentosDe('opcionesParametro').single, {
        'clave': 'EMPRESA_ORGANIGRAMA',
      });
      expect(campo('Valor'), findsNothing);
      await t.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(DropdownButtonFormField<double>),
        ),
      );
      await esperar(t, 2);
      await t.tap(find.text('GENERAL').last);
      await esperar(t, 2);
      expect(
        enDialogo('Código 6 · 65 cargos en su organigrama'),
        findsOneWidget,
      );
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);
      final p =
          repo.argumentosDe('nuevaVigenciaParametro').single['parametro']!
              as HexParametroEntity;
      expect(p.clave, 'EMPRESA_ORGANIGRAMA');
      expect(p.valorNumero, 6);
      await cerrar(t);
    });

    testWidgets('si la lista no carga, el valor se escribe como número', (
      t,
    ) async {
      repo.programar('catalogoParametros', [
        [
          const HexParametroClaveEntity(
            clave: 'EMPRESA_ORGANIGRAMA',
            nombre: 'Empresa del organigrama',
            tipoValor: 'NUMERO',
            conOpciones: true,
          ),
        ],
      ]);
      repo.programar('opcionesParametro', [const <HexParametroOpcionEntity>[]]);
      await montar(t);
      await tocar(t, find.text('Nuevo parámetro'));
      expect(campo('Valor'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('nueva comida: formulario vacío, con código y sin período', (
      t,
    ) async {
      await montar(t);
      await pestana(t, 'Comidas');
      await tocar(t, find.text('Nueva comida'));
      expect(enDialogo('Un período'), findsNothing);
      expect(textoDe(t, 'Código'), isEmpty);
      expect(textoDe(t, 'Monto'), isEmpty);
      expect(enDialogo('Vacío: 60 min.'), findsNWidgets(2));
      await t.enterText(campo('Código'), 'd');
      await t.enterText(campo('Leyenda'), 'Desayuno');
      await t.enterText(campo('Monto'), '10');
      await t.enterText(campo('Código doble'), 'dd');
      await t.enterText(campo('Leyenda doble'), 'Doble desayuno');
      await t.enterText(campo('Monto doble'), '10');
      await elegirHora(t, 'Desde', hora: '06', minuto: '00');
      await elegirHora(t, 'Hasta', hora: '08', minuto: '00');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);

      final c =
          repo.argumentosDe('nuevaVigenciaComida').single['comida']!
              as HexComidaEntity;
      expect(c.codigo, 'd');
      expect(c.codigoDoble, 'dd');
      expect(c.monto, 10);
      expect(c.activo, isTrue);
      expect(c.conDoble, isTrue);
      expect(c.orden, isNull);
      expect(c.minutosSimple, isNull);
      expect(c.horaDesde, '06:00:00');
      expect(c.vigenteDesde, dia15);
      expect(repo.argumentosDe('periodoComida'), isEmpty);
      await cerrar(t);
    });

    testWidgets('sin doble no se piden sus datos y viajan vacíos', (t) async {
      await montar(t);
      await pestana(t, 'Comidas');
      await tocar(t, find.text('Nueva comida'));
      await t.enterText(campo('Código doble'), 'da');
      await tocar(
        t,
        find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Paga la comida doble'),
          matching: find.byType(Switch),
        ),
        fotogramas: 1,
      );
      expect(campo('Código doble'), findsNothing);
      expect(campo('Monto doble'), findsNothing);
      expect(enDialogo('Horario de la comida'), findsOneWidget);
      await t.enterText(campo('Código'), 'a');
      await t.enterText(campo('Leyenda'), 'Almuerzo');
      await t.enterText(campo('Monto'), '10');
      await elegirHora(t, 'Desde', hora: '12', minuto: '00');
      await elegirHora(t, 'Hasta', hora: '14', minuto: '00');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);

      final c =
          repo.argumentosDe('nuevaVigenciaComida').single['comida']!
              as HexComidaEntity;
      expect(c.conDoble, isFalse);
      expect(c.codigoDoble, isEmpty);
      expect(c.leyendaDoble, isEmpty);
      expect(c.montoDoble, isNull);
      expect(c.minutosDoble, isNull);
      await cerrar(t);
    });

    testWidgets('un parámetro de fecha pide fecha y no número', (t) async {
      await montar(t);
      await accionDe(
        t,
        'Primer día que se reporta con el módulo',
        'Nueva vigencia',
      );
      expect(enDialogo('Fecha'), findsOneWidget);
      expect(campo('Valor'), findsNothing);
      expect(enDialogo('01/11/2026'), findsOneWidget);
      await elegirDia(t, 'Fecha', '15');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);

      final p =
          repo.argumentosDe('nuevaVigenciaParametro').single['parametro']!
              as HexParametroEntity;
      expect(p.clave, 'FECHA_INICIO_MODULO');
      expect(p.valorFecha, DateTime(2026, 11, 15));
      expect(p.valorNumero, isNull);
      expect(p.leyenda, 'Primer día que se reporta con el módulo');
      expect(p.vigenteDesde, dia15);
      await cerrar(t);
    });

    testWidgets('un parámetro numérico lee la coma y vacío viaja nulo', (
      t,
    ) async {
      await montar(t);
      await accionDe(
        t,
        'Divisor del costo hora (30 días × 8 h)',
        'Nueva vigencia',
      );
      expect(textoDe(t, 'Valor'), '240');
      expect(enDialogo('Fecha'), findsNothing);
      await t.enterText(campo('Valor'), '240,125');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);
      var p =
          repo.argumentosDe('nuevaVigenciaParametro').last['parametro']!
              as HexParametroEntity;
      expect(p.valorNumero, 240.125);
      expect(p.valorFecha, isNull);

      // Sin valor: viaja nulo y el SP responde con su mensaje.
      repo.programar('nuevaVigenciaParametro', [
        const NegocioHex('Escriba el valor del parámetro.'),
      ]);
      await accionDe(
        t,
        'Divisor del costo hora (30 días × 8 h)',
        'Nueva vigencia',
      );
      await t.enterText(campo('Valor'), '');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);
      p =
          repo.argumentosDe('nuevaVigenciaParametro').last['parametro']!
              as HexParametroEntity;
      expect(p.valorNumero, isNull);
      expect(aviso('Escriba el valor del parámetro.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin elegir «Rige desde» no se manda la fecha anterior', (
      t,
    ) async {
      await montar(t);
      await accionDe(
        t,
        'Divisor del costo hora (30 días × 8 h)',
        'Nueva vigencia',
      );
      await guardar(t);
      final p =
          repo.argumentosDe('nuevaVigenciaParametro').single['parametro']!
              as HexParametroEntity;
      expect(p.vigenteDesde, isNull);
      await cerrar(t);
    });

    testWidgets('comida: montos vacíos viajan nulos y activo siempre viaja', (
      t,
    ) async {
      await montar(t);
      await pestana(t, 'Comidas');
      await accionDe(t, 'Cena', 'Nueva vigencia');
      expect(textoDe(t, 'Monto'), '15');
      expect(textoDe(t, 'Monto doble'), '30');
      expect(textoDe(t, 'Código doble'), 'DC');
      await t.enterText(campo('Monto'), '');
      await t.enterText(campo('Monto doble'), '30,50');
      await tocar(t, enDialogo('Sin horario'), fotogramas: 1);
      // D40: hay dos interruptores (la doble y «Activa»); se apaga «Activa».
      await tocar(
        t,
        find.descendant(
          of: find.widgetWithText(SwitchListTile, 'Activa'),
          matching: find.byType(Switch),
        ),
        fotogramas: 1,
      );
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);

      final c =
          repo.argumentosDe('nuevaVigenciaComida').single['comida']!
              as HexComidaEntity;
      expect(c.idComida, isNull);
      expect(c.codigo, 'C');
      expect(c.codigoDoble, 'DC');
      expect(c.leyenda, 'Cena');
      expect(c.leyendaDoble, 'Doble cena');
      expect(c.monto, isNull);
      expect(c.montoDoble, 30.5);
      expect(c.horaDesde, isNull);
      expect(c.horaHasta, isNull);
      expect(c.activo, isFalse);
      expect(c.orden, 3);
      expect(c.vigenteDesde, dia15);
      await cerrar(t);
    });

    testWidgets(
      'los números se leen como en Bolivia y se ve lo que se guarda',
      (t) async {
        Finder lectura(String texto) => find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining(texto),
        );
        await montar(t);
        await accionDe(
          t,
          'Divisor del costo hora (30 días × 8 h)',
          'Nueva vigencia',
        );
        // Al menos 2 decimales: «1.500» no se confunde con 1,5.
        expect(lectura('Se guardará: 240,00\n'), findsOneWidget);
        await t.enterText(campo('Valor'), '15,5');
        await esperar(t, 1);
        expect(lectura('Se guardará: 15,50\n'), findsOneWidget);
        await t.enterText(campo('Valor'), '1.500');
        await esperar(t, 1);
        expect(lectura('Se guardará: 1.500,00\n'), findsOneWidget);
        await t.enterText(campo('Valor'), '1,2,3');
        await esperar(t, 1);
        expect(lectura('No se entiende el número'), findsOneWidget);
        // Solo entran cifras, punto y coma: «abc» no llega al campo.
        await t.enterText(campo('Valor'), 'abc');
        await esperar(t, 1);
        expect(textoDe(t, 'Valor'), isEmpty);
        expect(lectura('No se entiende el número'), findsNothing);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);

        await pestana(t, 'Tramos');
        await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
        expect(lectura('Se guardará: 1,50\n'), findsOneWidget);
        await t.enterText(campo('Factor'), '1.500');
        await esperar(t, 1);
        expect(lectura('Se guardará: 1.500,00\n'), findsOneWidget);
        await t.tap(enDialogo('Cancelar'));
        await esperar(t, 2);

        await pestana(t, 'Comidas');
        await accionDe(t, 'Cena', 'Nueva vigencia');
        await t.enterText(campo('Monto'), '1.234,50');
        await t.enterText(campo('Monto doble'), '1.500');
        await esperar(t, 1);
        // Los montos se ven con 2 decimales, como los guarda el SP.
        expect(lectura('Se guardará: Bs 1.234,50\n'), findsOneWidget);
        expect(lectura('Se guardará: Bs 1.500,00\n'), findsOneWidget);
        await elegirDia(t, 'Rige desde', '15');
        await guardar(t);
        final c =
            repo.argumentosDe('nuevaVigenciaComida').single['comida']!
                as HexComidaEntity;
        expect(c.monto, 1234.5);
        expect(c.montoDoble, 1500);
        await cerrar(t);
      },
    );

    testWidgets('editar la leyenda doble de una comida no manda la simple', (
      t,
    ) async {
      await montar(t);
      await pestana(t, 'Comidas');
      await accionDe(t, 'Cena', 'Editar leyenda doble');
      expect(textoDe(t, 'Leyenda doble'), 'Doble cena');
      await guardar(t);
      expect(repo.argumentosDe('editarLeyendaComida').single, {
        'id': BigInt.from(3),
        'leyenda': null,
        'leyendaDoble': 'Doble cena',
      });
      await cerrar(t);
    });

    testWidgets('editar la leyenda de un tramo manda el id y el texto', (
      t,
    ) async {
      await montar(t);
      await pestana(t, 'Tramos');
      await accionDe(t, 'Hora al 50 %', 'Editar leyenda');
      await t.enterText(campo('Leyenda'), 'Hora con recargo (2025)');
      await guardar(t);
      expect(repo.argumentosDe('editarLeyendaTramo').single, {
        'id': BigInt.from(6),
        'leyenda': 'Hora con recargo (2025)',
      });
      await cerrar(t);
    });

    testWidgets('el error de vigencia del SP se muestra tal cual', (t) async {
      const mensaje =
          'La última vigencia del tramo «H50» empieza el 01/01/2026; la nueva '
          'debe empezar después.';
      repo.programar('nuevaVigenciaTramo', [const NegocioHex(mensaje)]);
      await montar(t);
      await pestana(t, 'Tramos');
      await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);
      expect(aviso(mensaje), findsOneWidget);
      // El diálogo queda abierto para corregir.
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('un 403 al guardar dice que no tienes permiso', (t) async {
      repo.programar('editarLeyendaParametro', [
        const SinPermisoHex('Forbidden'),
      ]);
      await montar(t);
      await accionDe(t, 'Divisor anterior', 'Editar leyenda');
      await guardar(t);
      expect(aviso('No tienes permiso para esta acción.'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('doble toque en Guardar manda un solo pedido', (t) async {
      final pausa = Completer<void>();
      repo.pausa = pausa;
      await montar(t);
      await pestana(t, 'Tramos');
      await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
      await elegirDia(t, 'Rige desde', '15');
      await t.tap(enDialogo('Guardar'));
      await t.pump();
      await t.tap(enDialogo('Guardar'), warnIfMissed: false);
      await esperar(t, 1);
      // Mientras escribe, el «atrás» no cierra el diálogo.
      await Navigator.of(t.element(find.byType(AlertDialog))).maybePop();
      await esperar(t, 1);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repo.vecesDe('nuevaVigenciaTramo'), 1);
      pausa.complete();
      await esperar(t, 3);
      expect(find.byType(AlertDialog), findsNothing);
      await cerrar(t);
    });

    testWidgets(
      'eliminar confirma y manda solo el id; mientras, no se repite',
      (t) async {
        final pausa = Completer<void>();
        repo.pausa = pausa;
        await montar(t);
        await accionDe(t, 'Divisor anterior', 'Eliminar');
        expect(enDialogo('Eliminar vigencia'), findsOneWidget);
        await t.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await esperar(t, 2);
        expect(repo.argumentosDe('eliminarParametro').single, {
          'id': BigInt.from(4),
        });
        // Con la eliminación en curso la acción queda deshabilitada.
        final fila =
            find
                .ancestor(
                  of: find.text('Divisor anterior'),
                  matching: find.byType(InkWell),
                )
                .first;
        await tocar(
          t,
          find.descendant(of: fila, matching: find.byTooltip('Acciones')),
          fotogramas: 2,
        );
        final item = t.widget<PopupMenuItem<int>>(
          find.ancestor(
            of: find.text('Eliminar').last,
            matching: find.byType(PopupMenuItem<int>),
          ),
        );
        expect(item.enabled, isFalse);
        await t.tapAt(const Offset(5, 5));
        await esperar(t, 2);
        pausa.complete();
        await esperar(t, 3);
        expect(repo.vecesDe('eliminarParametro'), 1);
        await cerrar(t);
      },
    );

    testWidgets(
      'Eliminar se ofrece también en la vigencia actual (lo decide el SP)',
      (t) async {
        repo.programar('eliminarTramo', [
          const NegocioHex('Solo se elimina una vigencia que aún no empezó.'),
        ]);
        await montar(t);
        await pestana(t, 'Tramos');
        await accionDe(t, 'Hora extra con recargo del 50 %', 'Eliminar');
        await t.tap(find.widgetWithText(FilledButton, 'Eliminar'));
        await esperar(t, 3);
        expect(repo.argumentosDe('eliminarTramo').single, {'id': BigInt.two});
        expect(
          aviso('Solo se elimina una vigencia que aún no empezó.'),
          findsOneWidget,
        );
        await cerrar(t);
      },
    );
  });

  group('permisos', () {
    for (final ancho in [390.0, 1400.0]) {
      testWidgets('sin btnHexEditarParametro no hay acciones a $ancho px', (
        t,
      ) async {
        await montar(t, ancho: ancho, botones: {});
        for (final p in ['Parámetros', 'Tramos', 'Comidas']) {
          await pestana(t, p);
          expect(find.byTooltip('Nueva vigencia'), findsNothing);
          expect(find.byTooltip('Acciones'), findsNothing);
          expect(find.text('Nuevo tramo'), findsNothing);
          expect(find.text('Nuevo parámetro'), findsNothing);
          expect(find.text('Nueva comida'), findsNothing);
        }
        await cerrar(t);
      });
    }

    testWidgets('con btnHexEditarParametro hay acciones en cada vigencia', (
      t,
    ) async {
      await montar(t, botones: {BotonHex.editarParametro});
      expect(find.byTooltip('Nueva vigencia'), findsNWidgets(4));
      expect(find.text('Nuevo parámetro'), findsOneWidget);
      await pestana(t, 'Tramos');
      expect(find.byTooltip('Nueva vigencia'), findsNWidgets(6));
      expect(find.text('Nuevo tramo'), findsOneWidget);
      await pestana(t, 'Comidas');
      expect(find.text('Nueva comida'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('historial de cambios', () {
    testWidgets('cada pestaña pide su entidad y muestra los textos del SP', (
      t,
    ) async {
      await montar(t);
      expect(find.text('Historial de cambios'), findsOneWidget);
      expect(ultimoHistorial().entidad, EntidadConfiguracionHex.parametro);
      expect(ultimoHistorial().pagina, 1);
      expect(find.text('Vigencia eliminada'), findsOneWidget);
      expect(find.text('antes: 250 desde 01/12/2026'), findsOneWidget);
      expect(find.text('Salazar Rivera Jorge'), findsOneWidget);
      expect(find.text('15/10/2026 11:00'), findsOneWidget);

      await pestana(t, 'Tramos');
      expect(ultimoHistorial().entidad, EntidadConfiguracionHex.tramo);
      expect(
        find.text('Hora al 50 % → Hora extra con recargo del 50 %'),
        findsOneWidget,
      );
      expect(find.text('Leyenda editada'), findsOneWidget);
      expect(find.text('Leyenda'), findsWidgets);

      await pestana(t, 'Comidas');
      expect(ultimoHistorial().entidad, EntidadConfiguracionHex.comida);
      expect(find.text('Cena doble → Doble cena'), findsOneWidget);
      expect(find.text('Leyenda doble'), findsOneWidget);
      expect(find.text('C · Cena'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('el historial pagina en el servidor', (t) async {
      final pagina = [
        for (var i = 0; i < 20; i++)
          HexConfiguracionEventoEntity(
            idEvento: BigInt.from(100 + i),
            entidad: 'PARAMETRO',
            entidadTexto: 'Parámetro',
            descripcion: 'DIVISOR_COSTO_HORA',
            accion: 'U',
            accionTexto: 'Leyenda editada $i',
            audFecha: DateTime(2026, 10, 1, 8, i),
            totalFilas: 45,
          ),
      ];
      repo.programar('historial', [(filas: pagina, total: 45)]);
      await montar(t);
      expect(find.text('Leyenda editada 0'), findsOneWidget);
      await tocar(t, find.byIcon(Icons.chevron_right).last);
      expect(ultimoHistorial().pagina, 2);
      expect(ultimoHistorial().tamano, 20);
      expect(ultimoHistorial().entidad, 'PARAMETRO');
      await cerrar(t);
    });

    testWidgets('sin cambios muestra el vacío; un 403 dice No tienes permiso', (
      t,
    ) async {
      repo.programar('historial', [
        (filas: <HexConfiguracionEventoEntity>[], total: 0),
        const SinPermisoHex('Forbidden'),
      ]);
      await montar(t);
      expect(find.text('Sin cambios registrados'), findsOneWidget);
      await pestana(t, 'Tramos');
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('rediseño de la configuración (R10)', () {
    HexParametroEntity param(
      int id, {
      required String estado,
      String? texto,
      bool vigente = false,
      DateTime? hasta,
    }) => HexParametroEntity(
      idParametro: BigInt.from(id),
      clave: 'DIVISOR_COSTO_HORA',
      valorNumero: 240,
      leyenda: 'Divisor del costo hora',
      vigenteDesde: DateTime(2026, 1, 1),
      vigenteHasta: hasta,
      esVigente: vigente,
      estadoVigencia: estado,
      textoVigencia: texto,
    );

    Color colorDeTexto(WidgetTester t, Finder f) =>
        t.widget<Text>(f).style!.color!;

    testWidgets('el chip de vigencia sale de estadoVigencia del SP', (t) async {
      repo.programar('parametros', [
        [
          param(
            1,
            estado: 'VIGENTE',
            texto: 'Rige desde el 01/01/2026',
            vigente: true,
          ),
          param(
            2,
            estado: 'PROGRAMADA',
            texto: 'Empieza a regir el 01/03/2027',
          ),
          param(
            3,
            estado: 'VENCIDA',
            texto: 'Rigió hasta el 31/12/2025',
            hasta: DateTime(2025, 12, 31),
          ),
        ],
      ]);
      await montar(t);
      final cs = Theme.of(t.element(find.byType(Scaffold).first)).colorScheme;
      final hc = HexColores.desde(cs);
      expect(colorDeTexto(t, find.text('Vigente')), hc.alEnExitoContenedor);
      expect(
        colorDeTexto(t, find.text('Programada')),
        hc.alEnPendienteContenedor,
      );
      expect(colorDeTexto(t, find.text('Vencida')), cs.onSurfaceVariant);
      // Cada estado lleva además su ícono: el color nunca va solo.
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.update), findsOneWidget);
      expect(find.byIcon(Icons.history), findsWidgets);
      // El texto del SP reemplaza a las fechas armadas en la app.
      expect(find.text('Rige desde el 01/01/2026'), findsOneWidget);
      expect(find.text('Empieza a regir el 01/03/2027'), findsOneWidget);
      expect(find.text('Rigió hasta el 31/12/2025'), findsOneWidget);
      expect(find.text('Hasta 31/12/2025'), findsNothing);
      await cerrar(t);
    });

    testWidgets('en el teléfono el texto de vigencia va de subtítulo', (
      t,
    ) async {
      repo.programar('parametros', [
        [
          param(
            1,
            estado: 'PROGRAMADA',
            texto: 'Empieza a regir el 01/03/2027',
          ),
        ],
      ]);
      await montar(t, ancho: 390);
      expect(find.text('Programada'), findsOneWidget);
      expect(find.text('Empieza a regir el 01/03/2027'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('sin estadoVigencia se usa esVigente como antes', (t) async {
      repo.programar('parametros', [
        [
          HexParametroEntity(
            idParametro: BigInt.one,
            clave: 'DIVISOR_COSTO_HORA',
            valorNumero: 240,
            leyenda: 'Divisor',
            vigenteDesde: DateTime(2026, 1, 1),
            esVigente: true,
          ),
          HexParametroEntity(
            idParametro: BigInt.two,
            clave: 'DIVISOR_COSTO_HORA',
            valorNumero: 230,
            leyenda: 'Divisor anterior',
            vigenteDesde: DateTime(2025, 1, 1),
            vigenteHasta: DateTime(2025, 12, 31),
          ),
        ],
      ]);
      await montar(t);
      expect(find.text('Vigente'), findsOneWidget);
      expect(find.text('Programada'), findsNothing);
      expect(find.text('Vencida'), findsNothing);
      expect(find.text('Desde 01/01/2026'), findsOneWidget);
      expect(find.text('Hasta 31/12/2025'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('la franja dice la leyenda y la clave va como ficha pequeña', (
      t,
    ) async {
      await montar(t);
      final franja = find.byType(FranjaGrupoHex).first;
      expect(
        find.descendant(
          of: franja,
          matching: find.text(
            'Divisor del costo hora (30 días × 8 h) — 2 vigencias',
          ),
        ),
        findsOneWidget,
      );
      final clave = find.descendant(
        of: franja,
        matching: find.byType(CodigoHex),
      );
      expect(clave, findsOneWidget);
      expect(t.widget<CodigoHex>(clave).codigo, 'DIVISOR_COSTO_HORA');
      // La clave técnica ya no es el título de la franja.
      expect(find.text('DIVISOR_COSTO_HORA — 2 vigencias'), findsNothing);
      await cerrar(t);
    });

    testWidgets('una leyenda vacía no deja la franja sin título', (t) async {
      repo.programar('parametros', [
        [
          HexParametroEntity(
            idParametro: BigInt.one,
            clave: 'DIVISOR_COSTO_HORA',
            valorNumero: 240,
            leyenda: 'null',
            vigenteDesde: DateTime(2026, 1, 1),
            esVigente: true,
          ),
        ],
      ]);
      await montar(t);
      expect(find.text('DIVISOR_COSTO_HORA — 1 vigencia'), findsOneWidget);
      expect(find.textContaining('null'), findsNothing);
      await cerrar(t);
    });

    testWidgets('las pestañas llevan su ícono', (t) async {
      await montar(t, ancho: 390);
      final barra = find.byType(TabBar);
      for (final icono in [
        Icons.tune,
        Icons.schedule,
        Icons.restaurant_outlined,
      ]) {
        expect(
          find.descendant(of: barra, matching: find.byIcon(icono)),
          findsOneWidget,
        );
      }
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('a $ancho px la explicación de vigencia está a la vista', (
        t,
      ) async {
        await montar(t, ancho: ancho);
        expect(find.text('¿Qué es una vigencia?'), findsOneWidget);
        expect(
          find.textContaining('Es el período en el que un valor se usa'),
          findsOneWidget,
        );
        await cerrar(t);
      });
    }

    testWidgets('los estados vacíos dicen el paso que sigue', (t) async {
      repo.programar('parametros', [<HexParametroEntity>[]]);
      await montar(t, ancho: 390);
      expect(
        find.text('Agrega el primero con «Nuevo parámetro».'),
        findsOneWidget,
      );
      await cerrar(t);
    });
  });

  group('parámetros explícitos y dejar de usar (D33)', () {
    const siFaltaAlerta =
        'Sin este valor no se comparan la app y el biométrico: no hay avisos '
        'de diferencia ni se pide confirmación al cambiar la salida.';
    const ejemploDivisor =
        'Con 240, un haber básico de 3.000 Bs da un costo hora de 12,50 Bs.';
    const ejemploAlerta =
        'Con 15: si la app y el biométrico difieren en más de 15 minutos, el '
        'encargado ve un aviso para revisarlo.';

    final explicitos = <HexParametroEntity>[
      HexParametroEntity(
        idParametro: BigInt.one,
        clave: 'DIVISOR_COSTO_HORA',
        valorNumero: 240,
        leyenda: 'Divisor del costo hora (30 días × 8 h)',
        vigenteDesde: DateTime(2026, 1, 1),
        esVigente: true,
        estadoVigencia: 'VIGENTE',
        textoVigencia: 'Rige desde el 01/01/2026',
        nombre: 'Divisor del costo hora',
        descripcion:
            'Convierte el haber básico mensual en el valor de una hora.',
        siFalta: 'Sin divisor vigente, el costo hora queda en 0.',
        valorTexto: '240 horas al mes',
        ejemplo: ejemploDivisor,
        obligatorio: true,
      ),
      HexParametroEntity(
        idParametro: BigInt.from(5),
        clave: 'MINUTOS_ALERTA_BIOMETRICO',
        valorNumero: 15,
        leyenda: 'Alerta',
        vigenteDesde: DateTime(2026, 1, 1),
        esVigente: true,
        estadoVigencia: 'VIGENTE',
        textoVigencia: 'Rige desde el 01/01/2026',
        nombre: 'Tolerancia entre la app y el biométrico',
        descripcion: 'Diferencia máxima aceptada entre la app y el biométrico.',
        siFalta: siFaltaAlerta,
        valorTexto: '15 minutos',
        ejemplo: ejemploAlerta,
        obligatorio: false,
        puedeDejarDeUsar: true,
      ),
      HexParametroEntity(
        idParametro: BigInt.two,
        clave: 'MINUTOS_MINIMOS_EXTRA',
        valorNumero: 30,
        leyenda: 'Mínimos',
        vigenteDesde: DateTime(2026, 1, 1),
        vigenteHasta: DateTime(2026, 11, 9),
        estadoVigencia: 'SIN_USO',
        textoVigencia: 'Sin uso desde el 10/11/2026',
        nombre: 'Minutos mínimos para el reporte automático',
        valorTexto: '30 minutos',
        ejemplo: 'Con 30: si marca 30 minutos o más, se le crea el reporte.',
        obligatorio: false,
      ),
    ];

    setUp(() => repo.programar('parametros', [explicitos]));

    /// La franja (cabecera del grupo) que muestra [titulo].
    Finder franja(String titulo) => find.ancestor(
      of: find.text(titulo),
      matching: find.byType(FranjaGrupoHex),
    );

    /// Abre el menú ⋮ de la fila que muestra [texto].
    Future<void> abrirMenu(WidgetTester t, String texto) async {
      final fila =
          find
              .ancestor(of: find.text(texto), matching: find.byType(InkWell))
              .first;
      await tocar(
        t,
        find.descendant(of: fila, matching: find.byTooltip('Acciones')),
        fotogramas: 2,
      );
    }

    testWidgets('la franja dice nombre, obligatorio u opcional, para qué '
        'sirve y qué pasa si falta', (t) async {
      await montar(t);
      final divisor = franja('Divisor del costo hora — 1 vigencia');
      expect(divisor, findsOneWidget);
      expect(
        find.descendant(of: divisor, matching: find.text('Obligatorio')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: divisor, matching: find.text('DIVISOR_COSTO_HORA')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: divisor,
          matching: find.text(
            'Convierte el haber básico mensual en el valor de una hora.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: divisor,
          matching: find.text(
            'Si falta: Sin divisor vigente, el costo hora queda en 0.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: divisor, matching: find.byIcon(Icons.info_outline)),
        findsOneWidget,
      );
      final alerta = franja(
        'Tolerancia entre la app y el biométrico — 1 vigencia',
      );
      expect(
        find.descendant(of: alerta, matching: find.text('Opcional')),
        findsOneWidget,
      );
      // La fila: el valor con su unidad y qué significa; la leyenda ya no se
      // repite en la franja ni en la fila.
      expect(find.text('Qué significa'), findsOneWidget);
      expect(find.text('240 horas al mes'), findsOneWidget);
      expect(find.text(ejemploDivisor), findsOneWidget);
      expect(find.text('15 minutos'), findsOneWidget);
      expect(find.text(ejemploAlerta), findsOneWidget);
      expect(find.text('Divisor del costo hora (30 días × 8 h)'), findsNothing);
      await cerrar(t);
    });

    testWidgets('en el teléfono las tarjetas llevan lo mismo', (t) async {
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      expect(find.text('Divisor del costo hora — 1 vigencia'), findsOneWidget);
      expect(find.text('Obligatorio'), findsOneWidget);
      expect(find.text('Opcional'), findsNWidgets(2));
      expect(find.text('Si falta: $siFaltaAlerta'), findsOneWidget);
      expect(find.text('240 horas al mes'), findsOneWidget);
      expect(find.text(ejemploDivisor), findsOneWidget);
      expect(find.text('Sin uso'), findsOneWidget);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('SIN_USO es una ficha neutra con contorno «Sin uso»', (
      t,
    ) async {
      await montar(t);
      final ficha = t.widget<ChipHex>(
        find.ancestor(of: find.text('Sin uso'), matching: find.byType(ChipHex)),
      );
      expect(ficha.contorno, isTrue);
      expect(ficha.tono, TonoHex.neutro);
      expect(find.text('Sin uso desde el 10/11/2026'), findsOneWidget);
      expect(
        chipVigenciaHex(vigente: false, estado: 'SIN_USO'),
        isA<ChipHex>(),
      );
      await cerrar(t);
    });

    testWidgets('el aviso de obligatorios sale del catálogo, en rojo', (
      t,
    ) async {
      const aviso =
          'Falta «Inicio del módulo»: Sin fecha de inicio, nadie puede '
          'reportar horas extra y no hay planilla que ejecutar. Registre su '
          'valor.';
      repo.programar('catalogoParametros', [
        [
          ...catalogoFalso,
          const HexParametroClaveEntity(
            clave: 'FECHA_INICIO_MODULO',
            nombre: 'Inicio del módulo',
            obligatorio: true,
            aviso: aviso,
          ),
        ],
      ]);
      await montar(t);
      expect(find.text('Falta un parámetro obligatorio'), findsOneWidget);
      expect(find.text(aviso), findsOneWidget);
      final caja = t.widget<AvisoHex>(
        find.ancestor(of: find.text(aviso), matching: find.byType(AvisoHex)),
      );
      expect(caja.tono, TonoHex.error);
      // En otra pestaña no se muestra.
      await pestana(t, 'Tramos');
      expect(find.text(aviso), findsNothing);
      await cerrar(t);
    });

    testWidgets('sin avisos o si el catálogo falla no hay banner', (t) async {
      await montar(t);
      expect(find.text('Falta un parámetro obligatorio'), findsNothing);
      await cerrar(t);
      repo.programar('catalogoParametros', [const SinPermisoHex('Forbidden')]);
      await montar(t);
      expect(find.text('Falta un parámetro obligatorio'), findsNothing);
      expect(find.text('240 horas al mes'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('«Dejar de usar desde…» solo con puedeDejarDeUsar', (t) async {
      await montar(t, botones: {BotonHex.editarParametro});
      await abrirMenu(t, '15 minutos');
      expect(find.text('Dejar de usar desde…'), findsOneWidget);
      await t.tapAt(const Offset(4, 4));
      await esperar(t, 2);
      for (final fila in ['240 horas al mes', '30 minutos']) {
        await abrirMenu(t, fila);
        expect(find.text('Eliminar'), findsOneWidget);
        expect(find.text('Dejar de usar desde…'), findsNothing);
        await t.tapAt(const Offset(4, 4));
        await esperar(t, 2);
      }
      await cerrar(t);
    });

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('sin btnHexEditarParametro no hay «Dejar de usar» a $ancho', (
        t,
      ) async {
        await montar(t, ancho: ancho, botones: {});
        expect(find.byTooltip('Acciones'), findsNothing);
        expect(find.text('Dejar de usar desde…'), findsNothing);
        await cerrar(t);
      });
    }

    testWidgets('dejar de usar: hoy por defecto, qué pasa, id y fecha, '
        'mensaje del servidor y recarga', (t) async {
      const mensaje =
          '«Tolerancia entre la app y el biométrico» deja de usarse desde el '
          'día elegido. Para volver a usarlo, registre una vigencia nueva.';
      repo.programar('dejarDeUsarParametro', [
        (id: BigInt.from(5), mensaje: mensaje),
      ]);
      await montar(t);
      final antes = repo.vecesDe('parametros');
      final catalogoAntes = repo.vecesDe('catalogoParametros');
      await accionDe(t, '15 minutos', 'Dejar de usar desde…');

      expect(enDialogo('Dejar de usar un parámetro'), findsOneWidget);
      final hoyDia = DateUtils.dateOnly(DateTime.now());
      expect(enDialogo(fechaHex(hoyDia)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(
            'Desde esa fecha el sistema actuará como si este parámetro no '
            'existiera: $siFaltaAlerta',
          ),
        ),
        findsOneWidget,
      );
      // El último día del mes nunca es anterior a hoy.
      final ultimo = DateTime(hoyDia.year, hoyDia.month + 1, 0);
      await elegirDia(t, 'Deja de usarse desde', '${ultimo.day}');
      expect(enDialogo(fechaHex(ultimo)), findsOneWidget);
      await t.tap(enDialogo('Dejar de usar'));
      await esperar(t, 4);

      final args = repo.argumentosDe('dejarDeUsarParametro').single;
      expect(args['idParametro'], BigInt.from(5));
      expect(args['sinUsoDesde'], ultimo);
      expect(find.byType(AlertDialog), findsNothing);
      expect(aviso(mensaje), findsOneWidget);
      expect(repo.vecesDe('parametros'), greaterThan(antes));
      expect(repo.vecesDe('catalogoParametros'), greaterThan(catalogoAntes));
      await cerrar(t);
    });

    testWidgets('dejar de usar: el error del SP deja el diálogo abierto', (
      t,
    ) async {
      const error =
          'Ya hay una vigencia posterior de «Tolerancia entre la app y el '
          'biométrico»: deje de usar esa.';
      repo.programar('dejarDeUsarParametro', [const NegocioHex(error)]);
      await montar(t, ancho: 390);
      await accionDe(t, '15 minutos', 'Dejar de usar desde…');
      await t.tap(enDialogo('Dejar de usar'));
      await esperar(t, 4);
      expect(
        repo.argumentosDe('dejarDeUsarParametro').single['sinUsoDesde'],
        DateUtils.dateOnly(DateTime.now()),
      );
      expect(aviso(error), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await cerrar(t);
    });
  });

  group('teclado y foco de los formularios', () {
    testWidgets('editar una leyenda enfoca su único campo y «listo» guarda', (
      t,
    ) async {
      await montar(t, ancho: 390);
      await accionDe(t, 'Divisor anterior', 'Editar leyenda');
      final campoLeyenda = t.widget<TextField>(campo('Leyenda'));
      expect(campoLeyenda.autofocus, isTrue);
      expect(campoLeyenda.textInputAction, TextInputAction.done);
      await t.enterText(campo('Leyenda'), 'Divisor corregido');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await esperar(t, 4);
      expect(repo.vecesDe('editarLeyendaParametro'), 1);
      await cerrar(t);
    });

    testWidgets('la nueva vigencia de un parámetro pasa del valor a la leyenda '
        'con «siguiente»', (t) async {
      await montar(t, ancho: 390);
      await accionDe(
        t,
        'Divisor del costo hora (30 días × 8 h)',
        'Nueva vigencia',
      );
      expect(
        t.widget<TextField>(campo('Valor')).textInputAction,
        TextInputAction.next,
      );
      expect(
        t.widget<TextField>(campo('Leyenda')).textInputAction,
        TextInputAction.done,
      );
      expect(t.widget<TextField>(campo('Valor')).autofocus, isFalse);
      await cerrar(t);
    });

    testWidgets('la comida: «siguiente» en cada campo y «listo» en el último', (
      t,
    ) async {
      await montar(t, ancho: 390);
      await pestana(t, 'Comidas');
      await accionDe(t, 'Cena', 'Nueva vigencia');
      for (final e in ['Leyenda', 'Monto', 'Código doble', 'Leyenda doble']) {
        expect(
          t.widget<TextField>(campo(e)).textInputAction,
          TextInputAction.next,
          reason: e,
        );
      }
      expect(
        t.widget<TextField>(campo('Monto doble')).textInputAction,
        TextInputAction.done,
      );
      await cerrar(t);
    });

    testWidgets('el tramo nuevo: código y leyenda con «siguiente», el factor '
        'con «listo»', (t) async {
      await montar(t, ancho: 390);
      await pestana(t, 'Tramos');
      await tocar(t, find.text('Nuevo tramo'));
      expect(
        t.widget<TextField>(campo('Código')).textInputAction,
        TextInputAction.next,
      );
      expect(
        t.widget<TextField>(campo('Leyenda')).textInputAction,
        TextInputAction.next,
      );
      expect(
        t.widget<TextField>(campo('Factor')).textInputAction,
        TextInputAction.done,
      );
      await cerrar(t);
    });
  });

  group('barra de estado y vibración', () {
    testWidgets('el desplazamiento es el primario: tocar la barra de estado '
        'en iOS sube al inicio', (t) async {
      await montar(t, ancho: 390);
      verificarControlPrimarioHex(t, HexParametrosScreen);
      await cerrar(t);
    });

    testWidgets('cambiar de pestaña vibra con un toque de selección', (
      t,
    ) async {
      final vibraciones = capturarVibracionesHex();
      await montar(t, ancho: 390);
      await pestana(t, 'Tramos');
      expect(vibraciones, contains('selectionClick'));
      await cerrar(t);
    });
  });

  group('anchos', () {
    // 964 px: una laptop de 1280 con el menú lateral de 268.
    for (final ancho in [390.0, 800.0, 964.0, 1400.0]) {
      testWidgets('Parámetros a $ancho px sin desbordes', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        final tabla = ancho >= 964;
        final cabeceras = {
          'Parámetros': 'Valor',
          'Tramos': 'Horario',
          'Comidas': 'Montos',
        };
        for (final MapEntry(key: p, value: cabecera) in cabeceras.entries) {
          await pestana(t, p);
          expect(find.text(cabecera), tabla ? findsOneWidget : findsNothing);
          expect(find.text('Cuándo'), tabla ? findsOneWidget : findsNothing);
          expect(find.byWidgetPredicate(esLateral), findsNothing);
          expect(errores, isEmpty, reason: detalle(errores));
        }
        if (!tabla) {
          // Un solo desplazamiento vertical: las tarjetas cuelgan de él.
          expect(find.byWidgetPredicate(esVertical), findsOneWidget);
        }
        await cerrar(t);
      });
    }

    final bordes = {
      'Parámetros': (anchoTablaParametrosHex, 'Valor'),
      'Tramos': (anchoTablaTramosHex, 'Horario'),
      'Comidas': (anchoTablaComidasHex, 'Montos'),
    };
    for (final MapEntry(key: p, value: (minimo, cabecera)) in bordes.entries) {
      // El relleno de la pantalla es de 24 px por lado desde 600 px.
      final borde = minimo + 2 * 24;
      testWidgets('$p: tarjetas a ${borde - 1} px y tabla a $borde px', (
        t,
      ) async {
        await montar(t, ancho: borde - 1);
        await pestana(t, p);
        expect(find.text(cabecera), findsNothing);
        await cerrar(t);
        await montar(t, ancho: borde);
        await pestana(t, p);
        expect(find.text(cabecera), findsOneWidget);
        await cerrar(t);
      });
    }

    testWidgets('historial: tarjetas bajo su ancho mínimo y tabla desde él', (
      t,
    ) async {
      final borde = anchoTablaHistorialHex + 2 * 24;
      await montar(t, ancho: borde - 1);
      expect(find.text('Cuándo'), findsNothing);
      await cerrar(t);
      await montar(t, ancho: borde);
      expect(find.text('Cuándo'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('Parámetros al 150 % en 390 px sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await accionDe(
        t,
        'Divisor del costo hora (30 días × 8 h)',
        'Nueva vigencia',
      );
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await pestana(t, 'Tramos');
      await tocar(t, find.text('Nuevo tramo'));
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await pestana(t, 'Comidas');
      await accionDe(t, 'Cena', 'Nueva vigencia');
      await t.tap(enDialogo('Cancelar'));
      await esperar(t, 2);
      await t.scrollUntilVisible(
        find.text('Historial de cambios'),
        200,
        scrollable:
            find
                .ancestor(
                  of: find.text('Parámetros del cálculo'),
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
            body: const HexParametrosScreen(),
          ),
          ancho: 390,
          overrides: anulaciones(),
        );
        t.view.physicalSize = const Size(390, 741);
        await esperar(t);

        Future<void> teclado(String etiqueta) async {
          final f = campo(etiqueta);
          await t.ensureVisible(f);
          await t.showKeyboard(f);
          t.view.viewInsets = const FakeViewPadding(bottom: 336);
          await esperar(t, 3);
          expect(errores, isEmpty, reason: detalle(errores));
          expect(enDialogo('Guardar').hitTestable(), findsOneWidget);
          t.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await esperar(t, 2);
        }

        Future<void> cancelar() async {
          await t.tap(enDialogo('Cancelar'));
          await esperar(t, 2);
        }

        // Parámetro: valor y leyenda.
        await accionDe(
          t,
          'Divisor del costo hora (30 días × 8 h)',
          'Nueva vigencia',
        );
        await teclado('Valor');
        await teclado('Leyenda');
        await cancelar();
        await accionDe(t, 'Divisor anterior', 'Editar leyenda');
        await teclado('Leyenda');
        await cancelar();

        // Tramo nuevo y vigencia de tramo.
        await pestana(t, 'Tramos');
        await tocar(t, find.text('Nuevo tramo'));
        await teclado('Código');
        await teclado('Factor');
        await cancelar();
        await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
        await teclado('Leyenda');
        await cancelar();

        // Comida: leyendas y montos (el último campo del formulario).
        await pestana(t, 'Comidas');
        await accionDe(t, 'Cena', 'Nueva vigencia');
        await teclado('Leyenda doble');
        await teclado('Monto doble');
        await cancelar();
        await accionDe(t, 'Cena', 'Editar leyenda doble');
        await teclado('Leyenda doble');
        await cancelar();
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });

  group('mapa de tramos y simulador', () {
    String dosCifras(int n) => '$n'.padLeft(2, '0');
    final rige15 =
        '${dosCifras(dia15.day)}/${dosCifras(dia15.month)}/${dia15.year}';

    /// Los pedidos del mapa de un tipo de día (null: el de la pestaña).
    List<Map<String, Object?>> pedidosMapa(String? tipoDia) => [
      for (final a in repo.argumentosDe('mapaTramos'))
        if (a['tipoDia'] == tipoDia) a,
    ];

    testWidgets('Tramos: cuatro pestañas y el mapa con el hueco y su texto', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t);
      for (final p in ['Parámetros', 'Tramos', 'Comidas', 'Simulador']) {
        expect(
          find.descendant(of: find.byType(TabBar), matching: find.text(p)),
          findsOneWidget,
        );
      }
      await pestana(t, 'Tramos');
      expect(find.byType(MapaTramosHex), findsOneWidget);
      expect(find.byType(BarraDiaHex), findsNWidgets(3));
      for (final dia in ['Días hábiles', 'Domingos', 'Feriados']) {
        expect(find.text(dia), findsOneWidget);
      }
      // El texto del SP dice qué pasa y cómo arreglarlo.
      expect(find.text(textoHuecoFalso), findsOneWidget);
      // La pestaña pide el mapa de hoy, sin propuesta.
      expect(pedidosMapa(null).single, {
        'tipoDia': null,
        'fecha': null,
        'codigo': null,
        'horaDesde': null,
        'horaHasta': null,
      });
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('la vista previa pide el día sin y con el cambio', (t) async {
      await montar(t);
      await pestana(t, 'Tramos');
      await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
      await esperar(t, 3);
      expect(
        pedidosMapa('HABIL'),
        containsAll([
          {
            'tipoDia': 'HABIL',
            'fecha': null,
            'codigo': null,
            'horaDesde': null,
            'horaHasta': null,
          },
          {
            'tipoDia': 'HABIL',
            'fecha': null,
            'codigo': 'H50',
            'horaDesde': '20:00:00',
            'horaHasta': '00:00:00',
          },
        ]),
      );
      expect(enDialogo('Antes'), findsOneWidget);
      expect(enDialogo('Con el cambio'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(BarraDiaHex),
        ),
        findsNWidgets(2),
      );
      expect(
        enDialogo(
          'Hasta el día anterior se paga con lo de antes; desde esta '
          'fecha, con lo nuevo. Lo ya pagado no cambia.',
        ),
        findsOneWidget,
      );

      // Con la fecha, vuelve a pedir el día en esa fecha.
      await elegirDia(t, 'Rige desde', '15');
      await esperar(t, 3);
      expect(pedidosMapa('HABIL').last['fecha'], dia15);
      expect(pedidosMapa('HABIL').last['codigo'], 'H50');
      expect(enDialogo('Desde $rige15'), findsOneWidget);
      // La propuesta del falso no deja hueco: no hay texto de problema.
      expect(enDialogo(textoHuecoFalso), findsNothing);
      await cerrar(t);
    });

    testWidgets('la vista previa muestra las comidas solo bajo «Desde»', (
      t,
    ) async {
      final semantica = t.ensureSemantics();
      final errores = capturarErrores();
      await montar(t);
      await pestana(t, 'Tramos');
      await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
      await esperar(t, 3);
      final comidas = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.bySemanticsLabel(
          RegExp(
            r'Comidas: D 06:00 a 07:00; A 12:00 a 12:30; C 18:00 a 20:00$',
          ),
        ),
      );
      expect(comidas, findsOneWidget);
      // La franja va en la segunda barra («Con el cambio»), no en «Antes».
      final barras = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(BarraDiaHex),
      );
      expect(
        t.getSize(barras.at(1)).height,
        greaterThan(t.getSize(barras.at(0)).height),
      );
      expect(errores, isEmpty, reason: detalle(errores));
      semantica.dispose();
      await cerrar(t);
    });

    testWidgets('si la propuesta deja un hueco, su texto va bajo «Desde»', (
      t,
    ) async {
      repo.programar('mapaTramos', [mapaTramosFalso]);
      await montar(t, ancho: 800);
      await pestana(t, 'Tramos');
      await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
      await esperar(t, 3);
      // En una ventana angosta la vista previa va bajo el formulario.
      await t.ensureVisible(enDialogo(textoHuecoFalso));
      expect(enDialogo(textoHuecoFalso), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('si el cambio deja huecos, pregunta y reenvía confirmado', (
      t,
    ) async {
      const pregunta =
          'Con este cambio, los días hábiles quedan sin tramo de 20:00 a '
          '20:01: esas horas no se podrán pagar. ¿Guardar igual?';
      repo.programar('nuevaVigenciaTramo', [
        const ConfirmacionHex(pregunta),
        (id: BigInt.from(9), mensaje: 'Tramo guardado.'),
      ]);
      await montar(t);
      await pestana(t, 'Tramos');
      final mapasAntes = pedidosMapa(null).length;
      await accionDe(t, 'Hora extra con recargo del 50 %', 'Nueva vigencia');
      await elegirDia(t, 'Rige desde', '15');
      await guardar(t);
      expect(find.text(pregunta), findsOneWidget);
      await t.tap(find.text('Confirmar'));
      await esperar(t, 4);
      expect(
        [
          for (final a in repo.argumentosDe('nuevaVigenciaTramo'))
            a['confirmado'],
        ],
        [false, true],
      );
      // Cierra y recarga la lista y también el mapa del día.
      expect(find.byType(AlertDialog), findsNothing);
      expect(pedidosMapa(null).length, greaterThan(mapasAntes));
      await cerrar(t);
    });

    /// El botón «Simular» (un `FilledButton.icon`, de subtipo privado).
    final botonSimular = find.ancestor(
      of: find.text('Simular'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );

    Future<void> elegirManuel(WidgetTester t) async {
      await tocar(
        t,
        find
            .ancestor(of: find.text('Empleado'), matching: find.byType(InkWell))
            .first,
        fotogramas: 2,
      );
      await t.tap(
        find.widgetWithText(ListTile, 'Quispe Mamani Manuel').hitTestable(),
      );
      await esperar(t, 2);
    }

    testWidgets('simulador: jornada, total, tramos y avisos con qué hacer', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t);
      await pestana(t, 'Simulador');
      expect(find.text('Elige a alguien y una fecha'), findsOneWidget);
      expect(find.text('Historial de cambios'), findsNothing);
      // Sin empleado no se simula.
      final boton = botonSimular;
      expect(t.widget<ButtonStyleButton>(boton).onPressed, isNull);

      await elegirManuel(t);
      await tocar(t, boton, fotogramas: 4);
      final hoy = DateUtils.dateOnly(DateTime.now());
      expect(repo.argumentosDe('simularJornada').single, {
        'codEmpleado': BigInt.from(155),
        'fechaJornada': hoy,
        'inicio': null,
        'fin': null,
      });
      expect(find.text('Manuel Quispe'), findsOneWidget);
      expect(find.text('Bs 149,40'), findsWidgets);
      expect(find.text('Bs 134,40'), findsOneWidget);
      expect(find.text('Bs 50,40'), findsOneWidget);
      expect(find.text('Monto'), findsOneWidget);
      expect(find.byType(BarraTramosHex), findsOneWidget);
      expect(find.text('De 20:00 a 20:01 ningún tramo paga.'), findsOneWidget);
      expect(
        find.text(
          'Qué hacer: Haga que «H50» empiece a las 20:00.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('RRHH · Tramos'), findsOneWidget);
      expect(find.text('Encargado'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // La entrada y la salida que usó el SP quedan para cambiarlas.
      expect(find.text('05/11 15:00'), findsOneWidget);
      expect(find.text('05/11 21:36'), findsOneWidget);
      await tocar(t, boton, fotogramas: 4);
      final otra = repo.argumentosDe('simularJornada').last;
      expect(otra['inicio'], DateTime(2026, 11, 5, 15));
      expect(otra['fin'], DateTime(2026, 11, 5, 21, 36));
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('simulador: el 400 del SP se muestra tal cual', (t) async {
      const mensaje = 'Elija el empleado y la fecha de la jornada.';
      repo.programar('simularJornada', [const NegocioHex(mensaje)]);
      await montar(t);
      await pestana(t, 'Simulador');
      await elegirManuel(t);
      await tocar(t, botonSimular);
      expect(find.text(mensaje), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('simulador en el teléfono: tarjetas y sin desbordes', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await pestana(t, 'Simulador');
      await elegirManuel(t);
      await tocar(t, botonSimular, fotogramas: 4);
      expect(find.text('Bs 149,40'), findsWidgets);
      // En el angosto la lista de tramos va en tarjetas, sin tabla.
      expect(find.text('Cómo se paga'), findsNothing);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      await t.scrollUntilVisible(
        find.text('Se paga como hora: ×1,5 (recargo del 50 %)'),
        200,
        scrollable:
            find
                .ancestor(
                  of: find.text('Parámetros del cálculo'),
                  matching: find.byType(Scrollable),
                )
                .first,
      );
      await esperar(t, 2);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });
}
