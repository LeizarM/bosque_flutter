import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_roles_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_observacion_screen.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';

/// «Observación de reportes» (D45): solo lectura, de todos los estados,
/// agrupada por encargado y mes; sin Aprobar todo ni botones de firma; con
/// tabla en el ancho y tarjetas en el teléfono; el rol lo dice el servidor.
void main() {
  setUpAll(cargarFuentesHex);

  late HexReporteFalso repo;

  setUp(() {
    repo =
        HexReporteFalso()
          ..programar('misRoles', [const HexRolesEntity(esObservador: true)])
          ..programar('bandejaObservador', [(filas: _observados, total: 3)]);
  });

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  Future<void> montar(WidgetTester t, {double ancho = 1400}) async {
    await montarHex(
      t,
      const HexObservacionScreen(),
      ancho: ancho,
      overrides: [hexReporteRepositoryProvider.overrideWithValue(repo)],
    );
    await esperar(t);
  }

  FiltroReportesHex ultimoFiltro() =>
      repo.argumentosDe('bandejaObservador').last['filtro']!
          as FiltroReportesHex;

  bool esLateral(Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;

  /// Todo lo que firma o corrige: nada de esto puede dibujarse aquí.
  const accionesDeFirma = [
    'Aprobar',
    'Aprobar todo',
    'Dar visto bueno',
    'Visto bueno',
    'Rechazar',
    'Corregir hora',
    'Anular',
  ];

  void sinAccionesDeFirma() {
    for (final texto in accionesDeFirma) {
      expect(find.text(texto), findsNothing, reason: texto);
      expect(find.byTooltip(texto), findsNothing, reason: texto);
    }
  }

  group('el rol', () {
    testWidgets('sin el rol de observador avisa y no pide la bandeja', (
      t,
    ) async {
      for (final roles in [
        const HexRolesEntity(),
        const HexRolesEntity(esEncargado: true, esJefe: true, sucursales: '1'),
      ]) {
        repo = HexReporteFalso()..programar('misRoles', [roles]);
        await montar(t);
        expect(find.text('No tienes el rol de observador'), findsOneWidget);
        expect(repo.vecesDe('bandejaObservador'), 0);
        expect(find.text('Todos'), findsNothing);
        expect(find.text('Leyenda de códigos'), findsNothing);
        await cerrar(t);
      }
    });

    testWidgets('un 403 en los roles o en la bandeja dice No tienes permiso', (
      t,
    ) async {
      const sinPermiso = SinPermisoHex(
        'No tienes los permisos necesarios para realizar esta acción.',
      );
      repo = HexReporteFalso()..programar('misRoles', [sinPermiso]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(repo.vecesDe('bandejaObservador'), 0);
      await cerrar(t);

      repo =
          HexReporteFalso()
            ..programar('misRoles', [const HexRolesEntity(esObservador: true)])
            ..programar('bandejaObservador', [sinPermiso]);
      await montar(t, ancho: 390);
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('solo lectura', () {
    testWidgets('en el ancho: tabla con montos, grupos por encargado y mes, '
        'sin botones de firma aunque la fila los traiga', (t) async {
      final errores = capturarErrores();
      await montar(t);
      expect(find.text('Observación de reportes'), findsOneWidget);
      expect(
        find.textContaining('Solo lectura: ves los reportes'),
        findsOneWidget,
      );
      // La tabla del ancho, con la columna de dinero.
      for (final c in ['Empleado', 'Jornada', 'Monto', 'Estado', 'Acciones']) {
        expect(find.text(c), findsOneWidget, reason: c);
      }
      // Un grupo por encargado y mes, sin «Aprobar todo».
      expect(
        find.text('Rojas Vargas Luis — octubre de 2026 · 2 reportes'),
        findsOneWidget,
      );
      expect(
        find.text('Torrez Aliaga Ana — octubre de 2026 · 1 reporte'),
        findsOneWidget,
      );
      for (final n in [
        'Mamani Quispe Juan Carlos',
        'Condori Huanca María Fernanda',
        'Quispe Limachi Rosa',
      ]) {
        expect(find.text(n), findsOneWidget, reason: n);
      }
      // Los estados de todos los reportes: aprobado, rechazado y liquidado.
      expect(find.text('Aprobado'), findsWidgets);
      expect(find.text('Rechazado'), findsWidgets);
      expect(find.text('Liquidado'), findsWidgets);
      sinAccionesDeFirma();
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Leyenda de códigos'), findsOneWidget);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('en el teléfono: tarjetas, sin scroll lateral y solo «Ver '
        'detalle» en el menú', (t) async {
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      expect(find.text('Empleado'), findsNothing);
      expect(find.text('Mamani Quispe Juan Carlos'), findsOneWidget);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      sinAccionesDeFirma();
      expect(find.byType(FilledButton), findsNothing);

      final tarjeta = find.ancestor(
        of: find.text('Mamani Quispe Juan Carlos'),
        matching: find.byType(Card),
      );
      final menu = find.descendant(
        of: tarjeta,
        matching: find.byIcon(Icons.more_vert),
      );
      await t.ensureVisible(menu);
      await esperar(t, 1);
      await t.tap(menu);
      await esperar(t, 2);
      expect(find.text('Ver detalle'), findsOneWidget);
      sinAccionesDeFirma();
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('tocar un reporte abre su detalle', (t) async {
      await montar(t);
      await t.tap(find.text('Mamani Quispe Juan Carlos'));
      await esperar(t, 3);
      expect(repo.argumentosDe('detalle').single, {
        'idReporte': BigInt.from(301),
      });
      await cerrar(t);
    });

    for (final ancho in [390.0, 964.0, 1400.0]) {
      testWidgets('a $ancho px no desborda ni va de lado', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }
  });

  group('filtros', () {
    testWidgets('pide todos los estados por defecto y la página 1', (t) async {
      await montar(t);
      final f = ultimoFiltro();
      expect((f.estado, f.pagina, f.desde, f.hasta), (null, 1, null, null));
      expect(find.text('Todos'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('cada estado se pide al servidor y Todos lo quita', (t) async {
      await montar(t);
      const estados = {
        'Reportado': 'REPORTADO',
        'Visto bueno': 'VISTO_BUENO',
        'Aprobado': 'APROBADO',
        'Rechazado': 'RECHAZADO',
        'Liquidado': 'LIQUIDADO',
        'Anulado': 'ANULADO',
      };
      var actual = 'Todos';
      for (final MapEntry(key: texto, value: valor) in estados.entries) {
        await t.tap(find.text(actual).first);
        await esperar(t, 2);
        await t.tap(find.text(texto).last);
        await esperar(t, 3);
        expect(ultimoFiltro().estado, valor, reason: texto);
        expect(ultimoFiltro().pagina, 1);
        actual = texto;
      }
      await t.tap(find.text(actual).first);
      await esperar(t, 2);
      await t.tap(find.text('Todos').last);
      await esperar(t, 3);
      expect(ultimoFiltro().estado, isNull);
      await cerrar(t);
    });

    testWidgets('sin reportes explica qué se espera ver', (t) async {
      repo.programar('bandejaObservador', [
        (filas: <HexReporteEntity>[], total: 0),
      ]);
      await montar(t);
      expect(find.text('No hay reportes para observar'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      await cerrar(t);
    });
  });
}

final BigInt _rojas = BigInt.from(7);
final BigInt _torrez = BigInt.from(8);

/// Los reportes de los encargados observados, de varios estados. Las
/// banderas `puede*` vienen en verdadero a propósito: el observador nunca
/// las recibe del SP, pero la pantalla tampoco las usa.
final _observados = <HexReporteEntity>[
  _reporte(
    301,
    'Mamani Quispe Juan Carlos',
    DateTime(2026, 10, 23),
    _rojas,
    'Rojas Vargas Luis',
    'APROBADO',
    'Aprobado',
  ),
  _reporte(
    302,
    'Condori Huanca María Fernanda',
    DateTime(2026, 10, 20),
    _rojas,
    'Rojas Vargas Luis',
    'RECHAZADO',
    'Rechazado',
  ),
  _reporte(
    304,
    'Quispe Limachi Rosa',
    DateTime(2026, 10, 15),
    _torrez,
    'Torrez Aliaga Ana',
    'LIQUIDADO',
    'Liquidado',
  ),
];

HexReporteEntity _reporte(
  int id,
  String empleado,
  DateTime jornada,
  BigInt encargado,
  String nombreEncargado,
  String estado,
  String estadoTexto,
) => HexReporteEntity(
  idReporte: BigInt.from(id),
  codEmpleado: BigInt.from(id),
  nombreEmpleado: empleado,
  fechaJornada: jornada,
  tipo: 'DESPUES',
  tipoTexto: 'Después del horario',
  tipoDia: 'HABIL',
  tipoDiaTexto: 'Hábil',
  codSucursal: BigInt.one,
  nombreSucursal: 'Planta El Alto',
  inicio: jornada.add(const Duration(hours: 18)),
  fin: jornada.add(const Duration(hours: 23)),
  origenInicio: 'HORARIO',
  origenFin: 'BIOMETRICO',
  horasPagables: 5,
  montoTotal: 130,
  comidas: 'C',
  costoHora: 20,
  verMontos: true,
  estado: estado,
  estadoTexto: estadoTexto,
  puedeVistoBueno: true,
  puedeAprobar: true,
  puedeRechazar: true,
  puedeEditarHora: true,
  codEncargado: encargado,
  nombreEncargado: nombreEncargado,
);
