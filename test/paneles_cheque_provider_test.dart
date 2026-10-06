import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';

import 'fakes/repositorio_cheques.dart';

/// El estado de los tres paneles del detalle con un repositorio falso: las
/// lecturas por cheque, las escrituras, lo que refrescan y los errores del
/// backend. Sin red ni login.
void main() {
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late RepositorioChequesFalso repo;
  final cod = BigInt.from(5);
  final otro = BigInt.from(6);

  setUp(() => repo = RepositorioChequesFalso(total: 0));

  ProviderContainer crear() {
    final c = ProviderContainer(
      overrides: [chequesRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  OperacionesPanelesChequeNotifier ops(ProviderContainer c) =>
      c.read(operacionesPanelesChequeProvider.notifier);
  EstadoOperacionCheque estadoOps(ProviderContainer c) =>
      c.read(operacionesPanelesChequeProvider);

  NotaRemisionChequeEntity nota([BigInt? c]) => NotaRemisionChequeEntity(
    codCheque: c ?? cod,
    notaRemision: '262211881',
    nroFactura: 1856,
    fechaFactura: DateTime(2026, 8, 31),
  );

  TransaccionBancariaEntity transaccion() => TransaccionBancariaEntity(
    codCheque: cod,
    nroTransaccion: 'TT26216QW3N3',
    codBanco: 7,
    fechaTransaccion: DateTime(2026, 8, 4),
  );

  PostergacionEntity postergacion() => PostergacionEntity(
    codPostergacion: BigInt.zero,
    codCheque: cod,
    fecha: DateTime(2026, 9, 20),
    observacion: 'Cliente envió carta.',
  );

  group('lecturas', () {
    test('cada panel lee solo el cheque que se le pide', () async {
      repo.notasPorCheque[cod] = [nota()];
      repo.notasPorCheque[otro] = [nota(otro), nota(otro)];
      final c = crear();
      c.listen(notasRemisionChequeProvider(cod), (_, __) {});
      c.listen(notasRemisionChequeProvider(otro), (_, __) {});

      expect(await c.read(notasRemisionChequeProvider(cod).future), hasLength(1));
      expect(await c.read(notasRemisionChequeProvider(otro).future), hasLength(2));
      expect(repo.consultasDePaneles, [cod, otro]);
    });

    test('una lectura que falla deja el error en el panel y no en los demas', () async {
      repo.erroresDeLectura['listarTransacciones'] = Exception('Sin permiso.');
      final c = crear();
      c.listen(transaccionesChequeProvider(cod), (_, __) {});
      c.listen(notasRemisionChequeProvider(cod), (_, __) {});

      await expectLater(
        c.read(transaccionesChequeProvider(cod).future),
        throwsA(isA<Exception>()),
      );
      expect(await c.read(notasRemisionChequeProvider(cod).future), isEmpty);
    });

    test('el estado del PDF de una postergacion es por postergacion', () async {
      final c = crear();
      c.listen(estadoPdfPostergacionProvider(BigInt.from(40)), (_, __) {});
      final e = await c.read(estadoPdfPostergacionProvider(BigInt.from(40)).future);
      expect(e.existe, isFalse);
      expect(repo.consultasPdfPostergacion, [BigInt.from(40)]);
    });
  });

  group('escrituras', () {
    test('registrar una nota: true, guarda, refresca solo las notas y no mueve la grilla', () async {
      final c = crear();
      c.listen(notasRemisionChequeProvider(cod), (_, __) {});
      c.listen(transaccionesChequeProvider(cod), (_, __) {});
      expect(await c.read(notasRemisionChequeProvider(cod).future), isEmpty);
      await c.read(transaccionesChequeProvider(cod).future);

      final ok = await ops(c).registrarNotaRemision(nota());
      expect(ok, isTrue);
      expect(estadoOps(c).ocupado, isFalse);
      expect(estadoOps(c).error, isNull);
      expect(repo.ultimoCuerpo('registrarNotaRemision'), {
        'codCheque': 5,
        'notaRemision': '262211881',
        'nroFactura': 1856,
        'fechaFactura': '2026-08-31',
      });

      // Se releyo la lista de notas y no la de transacciones.
      expect(await c.read(notasRemisionChequeProvider(cod).future), hasLength(1));
      expect(repo.contar('listarNotasRemision'), 2);
      expect(repo.contar('listarTransacciones'), 1);
      // La grilla no se toco: ni listar ni detalle.
      expect(repo.contar('listar'), 0);
      expect(repo.contar('obtenerDetalle'), 0);
    });

    test('eliminar una nota devuelve cuantas filas se eliminaron', () async {
      repo.notasPorCheque[cod] = [nota(), nota()];
      final c = crear();
      c.listen(notasRemisionChequeProvider(cod), (_, __) {});
      await c.read(notasRemisionChequeProvider(cod).future);

      final n = await ops(c).eliminarNotaRemision(
        codCheque: cod,
        notaRemision: '262211881',
      );
      expect(n, 2);
      expect(await c.read(notasRemisionChequeProvider(cod).future), isEmpty);
    });

    test('registrar y eliminar una transaccion', () async {
      final c = crear();
      c.listen(transaccionesChequeProvider(cod), (_, __) {});
      await c.read(transaccionesChequeProvider(cod).future);

      expect(await ops(c).registrarTransaccion(transaccion()), isTrue);
      expect(await c.read(transaccionesChequeProvider(cod).future), hasLength(1));

      final n = await ops(c).eliminarTransaccion(
        codCheque: cod,
        nroTransaccion: 'TT26216QW3N3',
      );
      expect(n, 1);
      expect(await c.read(transaccionesChequeProvider(cod).future), isEmpty);
    });

    test('registrar una postergacion devuelve su codigo y refresca el listado', () async {
      final c = crear();
      c.listen(postergacionesChequeProvider(cod), (_, __) {});
      await c.read(postergacionesChequeProvider(cod).future);

      final nueva = await ops(c).registrarPostergacion(postergacion());
      expect(nueva, isNotNull);
      expect(nueva! > BigInt.zero, isTrue);
      expect(repo.ultimoCuerpo('registrarPostergacion'), {
        'codCheque': 5,
        'fecha': '2026-09-20',
        'observacion': 'Cliente envió carta.',
      });
      final lista = await c.read(postergacionesChequeProvider(cod).future);
      expect(lista.single.codPostergacion, nueva);
      expect(lista.single.tienePdf, isFalse);
    });

    test('eliminar una postergacion refresca el listado y el estado de su PDF', () async {
      final c = crear();
      c.listen(postergacionesChequeProvider(cod), (_, __) {});
      c.listen(estadoPdfPostergacionProvider(BigInt.from(9100)), (_, __) {});
      final cod1 = await ops(c).registrarPostergacion(postergacion());
      await c.read(postergacionesChequeProvider(cod).future);
      await c.read(estadoPdfPostergacionProvider(cod1!).future);
      expect(repo.consultasPdfPostergacion, hasLength(1));

      final r = await ops(c).eliminarPostergacion(
        codCheque: cod,
        codPostergacion: cod1,
      );
      expect(r, cod1);
      expect(repo.ultimoCuerpo('eliminarPostergacion'), {
        'codCheque': 5,
        'codPostergacion': cod1.toInt(),
      });
      expect(await c.read(postergacionesChequeProvider(cod).future), isEmpty);
      // El estado del PDF de la postergacion borrada se vuelve a pedir.
      await c.read(estadoPdfPostergacionProvider(cod1).future);
      expect(repo.consultasPdfPostergacion, hasLength(2));
    });
  });

  group('errores', () {
    test('un error del backend queda completo y tal cual en el estado', () async {
      repo.errorEscritura = Exception(
        'La nota de remisión «12A» no es válida.\nFalta el número de factura.',
      );
      final c = crear();
      final ok = await ops(c).registrarNotaRemision(nota());

      expect(ok, isFalse);
      expect(estadoOps(c).ocupado, isFalse);
      expect(
        estadoOps(c).error,
        'La nota de remisión «12A» no es válida.\nFalta el número de factura.',
      );
    });

    test('una escritura fallida no refresca nada', () async {
      repo.errorEscritura = Exception('Fallo.');
      final c = crear();
      c.listen(notasRemisionChequeProvider(cod), (_, __) {});
      await c.read(notasRemisionChequeProvider(cod).future);

      expect(await ops(c).registrarNotaRemision(nota()), isFalse);
      expect(
        await ops(c).eliminarNotaRemision(
          codCheque: cod,
          notaRemision: '262211881',
        ),
        isNull,
      );
      expect(repo.contar('listarNotasRemision'), 1);
    });

    test('limpiarError quita el error y la siguiente escritura parte limpia', () async {
      repo.errorEscritura = Exception('Fallo.');
      final c = crear();
      await ops(c).registrarTransaccion(transaccion());
      expect(estadoOps(c).error, 'Fallo.');

      ops(c).limpiarError();
      expect(estadoOps(c).error, isNull);

      repo.errorEscritura = null;
      expect(await ops(c).registrarTransaccion(transaccion()), isTrue);
      expect(estadoOps(c).error, isNull);
    });

    test('un error de otra escritura anterior se borra al empezar la siguiente', () async {
      repo.errorEscritura = Exception('Fallo.');
      final c = crear();
      await ops(c).registrarPostergacion(postergacion());
      expect(estadoOps(c).error, 'Fallo.');
      repo.errorEscritura = null;
      await ops(c).registrarPostergacion(postergacion());
      expect(estadoOps(c).error, isNull);
    });
  });

  group('una escritura a la vez', () {
    test('mientras hay una en vuelo, otra no se lanza', () async {
      final espera = Completer<void>();
      repo.esperaEscrituraPaneles = espera.future;
      final c = crear();

      final primera = ops(c).registrarNotaRemision(nota());
      await Future<void>.delayed(Duration.zero);
      expect(estadoOps(c).ocupado, isTrue);

      // La segunda sale con false, sin tocar el repositorio.
      expect(await ops(c).registrarNotaRemision(nota()), isFalse);
      expect(repo.contar('registrarNotaRemision'), 1);

      espera.complete();
      expect(await primera, isTrue);
      expect(estadoOps(c).ocupado, isFalse);
      expect(repo.contar('registrarNotaRemision'), 1);
    });

    test('es independiente de las escrituras del resto del modulo', () async {
      final espera = Completer<void>();
      repo.esperaEscrituraPaneles = espera.future;
      final c = crear();
      final enVuelo = ops(c).registrarNotaRemision(nota());
      await Future<void>.delayed(Duration.zero);

      // El estado de las otras escrituras (acciones, traspaso...) no se ve
      // afectado por una nota en vuelo.
      expect(c.read(operacionesChequesProvider).ocupado, isFalse);

      espera.complete();
      await enVuelo;
    });
  });
}
