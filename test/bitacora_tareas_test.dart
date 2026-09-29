// Bitácoras de tareas rutinarias (2026-09-11).
//
// Marcelo: "necesitamos una bitácora de las tareas que se realizaron y/o no se
// realizaron" y "una bitácora de las tareas rutinarias que se generan a medida
// que pasa el tiempo, del porqué se generó o no para qué empleados con su
// cargo, fecha de presentación".
//
// Lo que se fija aquí es lo que se rompe sin hacer ruido: que el porcentaje
// sea la misma cuenta que imprime el PDF, que elegir un estado no deje los
// demás totales en cero, que el PDF lleve los mismos filtros que la pantalla,
// y que "esta persona no es de tu equipo" llegue a quien pregunta.
import 'dart:typed_data';

import 'package:bosque_flutter/core/state/bitacora_tareas_provider.dart';
import 'package:bosque_flutter/data/models/bitacora_tareas_model.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/repositories/bitacora_tareas_repository.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/bitacora_tareas_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepoFalso implements BitacoraTareasRepository {
  List<BitacoraCumplimientoEntity> filas = [];
  List<ResumenGeneracionEntity> corridas = [];
  List<DiagnosticoGeneracionEntity> diagnostico = [];
  Object? errorPorQue;
  FiltroBitacora? ultimoFiltroPdf;
  ({DateTime desde, DateTime hasta})? ultimoRango;

  @override
  Future<List<BitacoraCumplimientoEntity>> cumplimiento({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    ultimoRango = (desde: desde, hasta: hasta);
    return filas;
  }

  @override
  Future<Uint8List> cumplimientoPdf(FiltroBitacora filtro) async {
    ultimoFiltroPdf = filtro;
    return Uint8List.fromList([37, 80, 68, 70]);
  }

  @override
  Future<List<ResumenGeneracionEntity>> generacion({
    required DateTime desde,
    required DateTime hasta,
  }) async => corridas;

  @override
  Future<List<DiagnosticoGeneracionEntity>> porQue({
    int? codEmpleado,
    required DateTime fecha,
    int? idTarRuti,
  }) async {
    final e = errorPorQue;
    if (e != null) throw e;
    return diagnostico;
  }

  @override
  Future<List<PersonaBuscada>> buscarPersonas(String texto) async => const [];
}

BitacoraCumplimientoEntity _fila(
  int id,
  Cumplimiento c, {
  int suc = 1,
  int cargo = 158,
  int emp = 180,
  int tarea = 295,
}) => BitacoraCumplimientoEntity(
  idBitTarea: id,
  fechaPresentacion: DateTime(2026, 9, 10),
  idTarRuti: tarea,
  nombreTareaRutinaria: 'Tarea $tarea',
  codEmpleado: emp,
  nombreEmpleado: 'Persona $emp',
  codCargo: cargo,
  descripcionCargo: 'Cargo $cargo',
  codSucursal: suc,
  nombreSucursal: 'Sucursal $suc',
  cumplimiento: c,
);

Future<void> _esperar() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('el resumen', () {
    test('el porcentaje es realizadas sobre realizadas más no realizadas', () {
      final r = ResumenCumplimiento.de([
        for (var i = 0; i < 3; i++) _fila(i, Cumplimiento.realizada),
        _fila(10, Cumplimiento.noRealizada),
        for (var i = 20; i < 25; i++) _fila(i, Cumplimiento.noAplica),
        _fila(30, Cumplimiento.enPlazo),
        _fila(31, Cumplimiento.enPlazo),
      ]);
      // La misma cuenta que imprime el PDF (bitacoraCumplimientoPdf): "No
      // aplica" y "En plazo" no son algo que se dejó de hacer.
      expect(r.porcentaje, 0.75);
      expect(r.total, 11);
    });

    test('sin realizadas ni no realizadas no hay porcentaje, no un cero', () {
      final r = ResumenCumplimiento.de([_fila(1, Cumplimiento.noAplica)]);
      expect(r.porcentaje, isNull);
    });
  });

  group('los filtros', () {
    final hasta = DateTime(2026, 9, 11);
    final desde = DateTime(2026, 9, 5);

    test('elegir un estado no cambia los totales', () {
      final s = BitacoraCumplimientoState(
        desde: desde,
        hasta: hasta,
        cargado: true,
        estado: Cumplimiento.noRealizada,
        filas: [
          _fila(1, Cumplimiento.realizada),
          _fila(2, Cumplimiento.noRealizada),
        ],
      );
      expect(s.visibles.map((f) => f.idBitTarea), [2]);
      expect(s.resumen.realizadas, 1);
      expect(s.resumen.noRealizadas, 1);
    });

    test('la sucursal sí cambia totales y filas', () {
      final s = BitacoraCumplimientoState(
        desde: desde,
        hasta: hasta,
        cargado: true,
        codSucursal: 2,
        filas: [
          _fila(1, Cumplimiento.realizada, suc: 1),
          _fila(2, Cumplimiento.noRealizada, suc: 2),
        ],
      );
      expect(s.visibles.map((f) => f.idBitTarea), [2]);
      expect(s.resumen.realizadas, 0);
    });

    test('las opciones salen de todo el rango, sin repetidos y ordenadas', () {
      final s = BitacoraCumplimientoState(
        desde: desde,
        hasta: hasta,
        cargado: true,
        codSucursal: 3,
        filas: [
          _fila(1, Cumplimiento.realizada, suc: 3),
          _fila(2, Cumplimiento.realizada, suc: 1),
          _fila(3, Cumplimiento.realizada, suc: 3),
        ],
      );
      expect(
        s.sucursales.map((o) => o.etiqueta),
        ['Sucursal 1', 'Sucursal 3'],
        reason: 'Con la sucursal 3 elegida, la 1 tiene que seguir en la lista.',
      );
    });

    test('cambiar de rango suelta los filtros que dependen de las filas', () async {
      final repo = _RepoFalso();
      final n = BitacoraCumplimientoNotifier(repo, hoy: hasta);
      await _esperar();

      n.filtrarSucursal(2);
      n.filtrarEstado(Cumplimiento.noRealizada);
      await n.cambiarRango(DateTime(2026, 8, 1), DateTime(2026, 8, 31));

      expect(n.state.codSucursal, isNull);
      expect(n.state.estado, Cumplimiento.noRealizada);
      expect(repo.ultimoRango, (
        desde: DateTime(2026, 8, 1),
        hasta: DateTime(2026, 8, 31),
      ));
      n.dispose();
    });

    test('un rango de más de un año no se consulta', () async {
      final repo = _RepoFalso();
      final n = BitacoraCumplimientoNotifier(repo, hoy: hasta);
      await _esperar();
      repo.ultimoRango = null;

      await n.cambiarRango(DateTime(2025, 1, 1), hasta);
      expect(repo.ultimoRango, isNull);
      expect(n.state.error, contains('un año'));
      n.dispose();
    });

    test('el PDF lleva los mismos filtros que la pantalla', () async {
      final repo = _RepoFalso();
      final n = BitacoraCumplimientoNotifier(repo, hoy: hasta);
      await _esperar();

      n.filtrarSucursal(2);
      n.filtrarTarea(295);
      n.filtrarEstado(Cumplimiento.noRealizada);
      await n.pdf();

      expect(repo.ultimoFiltroPdf!.toJson(), {
        'fechaIni': '2026-09-05',
        'fechaFin': '2026-09-11',
        'codSucursal': 2,
        'idTarRuti': 295,
        'cumplimiento': 'N',
      });
      n.dispose();
    });
  });

  group('los datos del backend', () {
    test('una fila de cumplimiento', () {
      final f = BitacoraTareasModel.cumplimiento({
        'idBitTarea': 77,
        'fechaPresentacion': '2026-09-10 00:00:00',
        'fechaCompletado': '2026-09-10 17:42:10',
        'nombreTareaRutinaria': 'Aplicar  o  supervisar\r\nla aplicación',
        'codEmpleado': 180,
        'nombreEmpleado': 'QUISPE MAMANI RONALDO',
        'cumplimiento': 'N',
      });
      expect(f.fechaPresentacion, DateTime(2026, 9, 10));
      expect(f.fechaCompletado, DateTime(2026, 9, 10, 17, 42, 10));
      expect(f.cumplimiento, Cumplimiento.noRealizada);
      expect(f.nombreTareaRutinaria, 'Aplicar o supervisar la aplicación');
    });

    test('un diagnóstico, con el motivo legible', () {
      final d = BitacoraTareasModel.diagnostico({
        'idTarRuti': 295,
        'filtro': 0,
        'motivo': 'Se genero.',
        'existeOcurrencia': true,
      });
      expect(d.existeOcurrencia, isTrue);
      expect(d.motivoLegible, 'Se generó.');
      expect(d.quedoFuera, isFalse);
    });

    test('una persona del buscador de empleados', () {
      final p = BitacoraTareasModel.persona({
        'codEmpleado': 180,
        'persona': {'datoPersona': 'QUISPE MAMANI RONALDO'},
        'empleadoCargo': {
          'cargoSucursal': {
            'cargo': {'descripcion': 'CAJERO'},
          },
        },
      });
      expect(p!.nombre, 'QUISPE MAMANI RONALDO');
      expect(p.cargo, 'CAJERO');
      expect(BitacoraTareasModel.persona({'codEmpleado': 0}), isNull);
    });

    test('las corridas se agrupan, "Generadas" va aparte y los motivos en el '
        'orden del generador', () {
      final c1 = DateTime(2026, 9, 10, 0, 5);
      final c2 = DateTime(2026, 9, 11, 0, 5);
      final g = agruparCorridas([
        ResumenGeneracionEntity(
          corrida: c1,
          motivo: 'Paso los filtros (frecuencia o ya existia)',
          cantidad: 194,
        ),
        ResumenGeneracionEntity(corrida: c1, motivo: 'Generadas', cantidad: 151),
        ResumenGeneracionEntity(
          corrida: c1,
          motivo: 'Empleado dado de baja',
          cantidad: 6792,
        ),
        ResumenGeneracionEntity(
          corrida: c1,
          motivo: 'A requerimiento',
          cantidad: 663,
        ),
        ResumenGeneracionEntity(corrida: c2, motivo: 'Generadas', cantidad: 150),
      ]);
      expect(g.map((x) => x.corrida), [c2, c1]);
      expect(g[1].generadas, 151);
      expect(g[1].motivos.map((m) => m.motivo), [
        'A requerimiento',
        'Empleado dado de baja',
        'Paso los filtros (frecuencia o ya existia)',
      ]);
      expect(g[1].maximo, 6792);
      expect(
        conTildes('Paso los filtros (frecuencia o ya existia)'),
        'Pasó los filtros (frecuencia o ya existía)',
      );
    });

    test('cada motivo del generador tiene su explicación', () {
      // Marcelo no ubicaba el panel de corridas ("¿es de todos o de cada
      // persona?"): los nombres de los motivos solos no dicen qué cuentan.
      for (final m in [...motivosDelGenerador, motivoGeneradas]) {
        expect(explicacionDelMotivo(m), isNotNull, reason: m);
      }
    });
  });

  test('por qué: el rechazo del servidor llega como error', () async {
    final repo =
        _RepoFalso()
          ..errorPorQue = Exception('Esta persona no pertenece a tu equipo.');
    final n = BitacoraPorQueNotifier(repo, hoy: DateTime(2026, 9, 11));
    await _esperar();
    expect(n.state.error, 'Esta persona no pertenece a tu equipo.');
    expect(
      n.state.consultado,
      isFalse,
      reason: 'Un rechazo no puede verse como "no tiene tareas".',
    );
    n.dispose();
  });

  testWidgets('la pantalla muestra el porcentaje y filtra al tocar un estado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo =
        _RepoFalso()
          ..filas = [
            _fila(1, Cumplimiento.realizada, tarea: 1),
            _fila(2, Cumplimiento.realizada, tarea: 2),
            _fila(3, Cumplimiento.realizada, tarea: 3),
            _fila(4, Cumplimiento.noRealizada, tarea: 4),
          ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [bitacoraTareasRepoProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: BitacoraTareasScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    Finder enLaTabla(String texto) =>
        find.descendant(of: find.byType(ListView), matching: find.text(texto));

    expect(find.text('75 %'), findsOneWidget);
    expect(enLaTabla('Tarea 1'), findsOneWidget);

    await tester.tap(find.text('No realizadas'));
    await tester.pump();

    expect(enLaTabla('Tarea 1'), findsNothing);
    expect(enLaTabla('Tarea 4'), findsOneWidget);
    expect(
      find.text('75 %'),
      findsOneWidget,
      reason: 'Elegir un estado no cambia el porcentaje.',
    );
  });
}
