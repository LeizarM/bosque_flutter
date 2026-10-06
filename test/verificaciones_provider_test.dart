import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart'
    show relojChequesProvider;
import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/domain/entities/verificacion_registro_entity.dart';

import 'fakes/repositorio_verificaciones.dart';

/// El estado de «Verificar Cheques»: la lista principal, el modal de pendientes
/// y las escrituras, con el repositorio falso y sin pantalla.
void main() {
  late RepositorioVerificacionesFalso repo;
  late ProviderContainer c;

  /// Un contenedor con el reloj fijo (3/10/2026 16:20) y el repositorio falso.
  /// Los providers autoDispose se mantienen vivos mientras dura la prueba.
  ProviderContainer contenedor() {
    final cont = ProviderContainer(
      overrides: [
        verificacionesRepositoryProvider.overrideWithValue(repo),
        relojChequesProvider.overrideWithValue(() => DateTime(2026, 10, 3, 16, 20)),
      ],
    );
    addTearDown(cont.dispose);
    return cont;
  }

  setUp(() {
    repo = RepositorioVerificacionesFalso(hoy: DateTime(2026, 10, 3));
    c = contenedor();
  });

  Future<void> reposo() => Future<void>.delayed(Duration.zero);

  group('lista principal', () {
    test('abre en hoy y sin hora, y todavia no consulto nada', () {
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final e = c.read(grillaVerificacionesProvider);
      expect(e.fechaBanco, DateTime(2026, 10, 3));
      expect(e.iniciado, isFalse);
      expect(e.resultado, isNull);
      expect(repo.consultasListar, isEmpty);
    });

    test('iniciar consulta una vez y repetirlo no consulta de nuevo', () async {
      repo.verificaciones = [verificacionFalsa(1)];
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final n = c.read(grillaVerificacionesProvider.notifier);

      await n.iniciar();
      await n.iniciar();

      expect(repo.consultasListar, hasLength(1));
      final e = c.read(grillaVerificacionesProvider);
      expect(e.iniciado, isTrue);
      expect(e.filas, hasLength(1));
      expect(e.cargando, isFalse);
      expect(e.error, isNull);
    });

    test('buscarPorFecha cambia el dia, vuelve a la pagina 1 y quita la hora', () async {
      repo.verificaciones = [
        verificacionFalsa(1),
        verificacionFalsa(2, fechaBanco: DateTime(2026, 9, 20)),
      ];
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final n = c.read(grillaVerificacionesProvider.notifier);
      await n.iniciar();

      await n.buscarPorFecha(DateTime(2026, 9, 20, 23, 59));
      expect(repo.consultasListar.last.fechaBanco, DateTime(2026, 9, 20));
      expect(repo.consultasListar.last.pagina, 1);
      expect(c.read(grillaVerificacionesProvider).filas.single.codvd, BigInt.from(2));

      await n.buscarPorFecha(null);
      expect(repo.consultasListar.last.fechaBanco, isNull);
      expect(c.read(grillaVerificacionesProvider).total, 2);

      await n.irAHoy();
      expect(repo.consultasListar.last.fechaBanco, DateTime(2026, 10, 3));
    });

    test('paginar: siguiente y anterior piden esa pagina; no se baja de la 1', () async {
      repo.verificaciones = repetir(45, (i) => verificacionFalsa(i + 1));
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final n = c.read(grillaVerificacionesProvider.notifier);
      await n.iniciar();

      var e = c.read(grillaVerificacionesProvider);
      expect(e.total, 45);
      expect(e.totalPaginas, 3);
      expect(e.hayAnterior, isFalse);
      expect(e.haySiguiente, isTrue);

      await n.siguiente();
      expect(repo.consultasListar.last.pagina, 2);
      await n.siguiente();
      e = c.read(grillaVerificacionesProvider);
      expect(e.pagina, 3);
      expect(e.haySiguiente, isFalse);

      await n.anterior();
      await n.anterior();
      final antes = repo.consultasListar.length;
      await n.anterior();
      expect(repo.consultasListar, hasLength(antes), reason: 'no hay pagina 0');
      expect(c.read(grillaVerificacionesProvider).pagina, 1);
    });

    test('si el servidor acota la pagina a la ultima, la pantalla la sigue', () async {
      repo.verificaciones = repetir(25, (i) => verificacionFalsa(i + 1));
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final n = c.read(grillaVerificacionesProvider.notifier);
      await n.iniciar();
      await n.siguiente();
      expect(c.read(grillaVerificacionesProvider).pagina, 2);

      // Se anulan filas por otro lado y la pagina 2 deja de existir.
      repo.verificaciones = repetir(10, (i) => verificacionFalsa(i + 1));
      await n.recargar();
      expect(c.read(grillaVerificacionesProvider).pagina, 1);
    });

    test('un fallo queda como mensaje completo y reintentar lo limpia', () async {
      repo.errorAlListar = Exception('El servidor no responde.\nReintenta en un minuto.');
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final n = c.read(grillaVerificacionesProvider.notifier);
      await n.iniciar();

      var e = c.read(grillaVerificacionesProvider);
      expect(e.error, 'El servidor no responde.\nReintenta en un minuto.');
      expect(e.resultado, isNull);
      expect(e.cargando, isFalse);

      repo.errorAlListar = null;
      await n.recargar();
      e = c.read(grillaVerificacionesProvider);
      expect(e.error, isNull);
      expect(e.sinResultados, isTrue);
    });

    test('durante una recarga se conserva la pagina anterior (la tabla no parpadea)', () async {
      repo.verificaciones = [verificacionFalsa(1)];
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final n = c.read(grillaVerificacionesProvider.notifier);
      await n.iniciar();

      final soltar = Completer<void>();
      repo.antesDeListar = (_) => soltar.future;
      final recarga = n.recargar();
      await reposo();
      final e = c.read(grillaVerificacionesProvider);
      expect(e.cargando, isTrue);
      expect(e.filas, hasLength(1), reason: 'sigue la anterior');
      soltar.complete();
      await recarga;
      expect(c.read(grillaVerificacionesProvider).cargando, isFalse);
    });

    test('si dos consultas se cruzan, solo vale la ultima', () async {
      repo.verificaciones = [
        verificacionFalsa(1),
        verificacionFalsa(2, fechaBanco: DateTime(2026, 9, 20)),
      ];
      c.listen(grillaVerificacionesProvider, (_, __) {});
      final n = c.read(grillaVerificacionesProvider.notifier);
      await n.iniciar();

      final lenta = Completer<void>();
      repo.antesDeListar = (f) => f.fechaBanco == null ? lenta.future : Future.value();
      final todas = n.buscarPorFecha(null); // sale primero y llega ultima
      final deHoy = n.buscarPorFecha(DateTime(2026, 10, 3));
      await deHoy;
      lenta.complete();
      await todas;

      final e = c.read(grillaVerificacionesProvider);
      expect(e.fechaBanco, DateTime(2026, 10, 3));
      expect(e.filas.map((f) => f.codvd), [BigInt.one]);
    });
  });

  group('modal de pendientes', () {
    test('abre con lo del legacy: PEN, solo cobranza de hoy, pagina 1', () {
      c.listen(pendientesVerificacionProvider, (_, __) {});
      final f = c.read(pendientesVerificacionProvider).filtro;
      expect(f.estado, 'PEN');
      expect(f.soloCobranzaHoy, isTrue);
      expect(f.pagina, 1);
    });

    test('elegir estado (o «Todos») y la fecha vuelve a la pagina 1 y consulta', () async {
      repo.pendientes = repetir(30, (i) => pendienteFalso(100 + i));
      c.listen(pendientesVerificacionProvider, (_, __) {});
      final n = c.read(pendientesVerificacionProvider.notifier);
      await n.iniciar();
      await n.siguiente();
      expect(c.read(pendientesVerificacionProvider).pagina, 2);

      await n.elegirEstado(null);
      var q = repo.consultasPendientes.last;
      expect(q.estado, isNull);
      expect(q.pagina, 1);
      expect(q.soloCobranzaHoy, isTrue, reason: 'el otro criterio se conserva');

      await n.elegirSoloHoy(false);
      q = repo.consultasPendientes.last;
      expect(q.soloCobranzaHoy, isFalse);
      expect(q.estado, isNull, reason: 'el estado se conserva');

      await n.elegirEstado('CER');
      expect(repo.consultasPendientes.last.estado, 'CER');
    });

    test('un fallo es un mensaje, no una lista vacia', () async {
      repo.errorAlListarPendientes = Exception('No se pudo consultar los cheques pendientes.');
      c.listen(pendientesVerificacionProvider, (_, __) {});
      await c.read(pendientesVerificacionProvider.notifier).iniciar();
      final e = c.read(pendientesVerificacionProvider);
      expect(e.error, 'No se pudo consultar los cheques pendientes.');
      expect(e.sinResultados, isFalse);
    });
  });

  group('escrituras', () {
    VerificacionRegistroEntity alta(int codCheque) => VerificacionRegistroEntity(
      codvd: BigInt.zero,
      codCheque: BigInt.from(codCheque),
      codBanco: 7,
      fechaBanco: DateTime(2026, 10, 3),
      observacion: '',
    );

    test('registrar bien: devuelve el codvd y relee la lista, los pendientes y el contador', () async {
      repo.pendientes = [pendienteFalso(100), pendienteFalso(101)];
      c.listen(grillaVerificacionesProvider, (_, __) {});
      c.listen(pendientesVerificacionProvider, (_, __) {});
      c.listen(chequesSinVerificarProvider, (_, __) {});
      c.listen(operacionesVerificacionesProvider, (_, __) {});
      await c.read(grillaVerificacionesProvider.notifier).iniciar();
      await c.read(pendientesVerificacionProvider.notifier).iniciar();
      expect(await c.read(chequesSinVerificarProvider.future), 2);

      final id = await c.read(operacionesVerificacionesProvider.notifier).registrar(alta(100));
      await reposo();
      await reposo();

      expect(id, isNotNull);
      expect(repo.registros, hasLength(1));
      expect(c.read(grillaVerificacionesProvider).filas, hasLength(1));
      expect(c.read(pendientesVerificacionProvider).filas.map((f) => f.codCheque), [BigInt.from(101)]);
      expect(await c.read(chequesSinVerificarProvider.future), 1);
      final op = c.read(operacionesVerificacionesProvider);
      expect(op.ocupado, isFalse);
      expect(op.error, isNull);
    });

    test('registrar con un rechazo del servidor: null, el mensaje completo y no relee nada', () async {
      repo.pendientes = [pendienteFalso(100)];
      repo.errorAlRegistrar = Exception('Falta la fecha.\nFalta el banco.');
      c.listen(grillaVerificacionesProvider, (_, __) {});
      c.listen(operacionesVerificacionesProvider, (_, __) {});
      await c.read(grillaVerificacionesProvider.notifier).iniciar();
      final antes = repo.consultasListar.length;

      final id = await c.read(operacionesVerificacionesProvider.notifier).registrar(alta(100));

      expect(id, isNull);
      final op = c.read(operacionesVerificacionesProvider);
      expect(op.error, 'Falta la fecha.\nFalta el banco.');
      expect(op.ocupado, isFalse);
      expect(repo.consultasListar, hasLength(antes), reason: 'no se escribio: nada cambio');

      // limpiarError lo borra.
      c.read(operacionesVerificacionesProvider.notifier).limpiarError();
      expect(c.read(operacionesVerificacionesProvider).error, isNull);
    });

    test('mientras hay una escritura en vuelo no se acepta otra', () async {
      c.listen(operacionesVerificacionesProvider, (_, __) {});
      repo.pendientes = [pendienteFalso(100)];
      final n = c.read(operacionesVerificacionesProvider.notifier);
      final primera = n.registrar(alta(100));
      final segunda = n.registrar(alta(100));
      expect(await segunda, isNull);
      expect(await primera, isNotNull);
      expect(repo.registros, hasLength(1));
    });

    test('anular devuelve el mensaje del servidor y relee la lista', () async {
      repo.verificaciones = [verificacionFalsa(1)];
      repo.mensajeAnular = 'Esta verificación ya estaba anulada: no hay nada que cambiar.';
      c.listen(grillaVerificacionesProvider, (_, __) {});
      c.listen(operacionesVerificacionesProvider, (_, __) {});
      await c.read(grillaVerificacionesProvider.notifier).iniciar();

      final m = await c.read(operacionesVerificacionesProvider.notifier).anular(BigInt.one);
      await reposo();

      expect(m, 'Esta verificación ya estaba anulada: no hay nada que cambiar.');
      expect(repo.anulados, [BigInt.one]);
      expect(c.read(grillaVerificacionesProvider).filas.single.estaAnulada, isTrue);
    });

    test('anular sin lista abierta no crea una: solo relee lo que ya existe', () async {
      repo.verificaciones = [verificacionFalsa(1)];
      c.listen(operacionesVerificacionesProvider, (_, __) {});
      await c.read(operacionesVerificacionesProvider.notifier).anular(BigInt.one);
      await reposo();
      expect(repo.consultasListar, isEmpty, reason: 'nadie estaba mirando la lista');
      // Solo pudo pedirse el contador (una fila), nunca la lista del modal.
      expect(repo.consultasPendientes.every((q) => q.tamanio == 1), isTrue);
    });

    test('preparar un cheque que ya no se puede verificar: error y se relee la lista de pendientes', () async {
      repo.pendientes = [pendienteFalso(101)];
      c.listen(pendientesVerificacionProvider, (_, __) {});
      c.listen(operacionesVerificacionesProvider, (_, __) {});
      await c.read(pendientesVerificacionProvider.notifier).iniciar();
      final antes = repo.consultasPendientes.length;

      final r = await c.read(operacionesVerificacionesProvider.notifier).preparar(BigInt.from(100));
      await reposo();

      expect(r, isNull);
      expect(c.read(operacionesVerificacionesProvider).error, contains('ya tiene una verificación válida'));
      expect(repo.consultasPendientes.length, greaterThan(antes), reason: 'la lista estaba vieja');
    });

    test('preparar bien devuelve el cheque y la fecha de hoy y no relee nada', () async {
      repo.pendientes = [pendienteFalso(100, codBanco: 8)];
      c.listen(pendientesVerificacionProvider, (_, __) {});
      c.listen(operacionesVerificacionesProvider, (_, __) {});
      await c.read(pendientesVerificacionProvider.notifier).iniciar();
      final antes = repo.consultasPendientes.length;

      final r = await c.read(operacionesVerificacionesProvider.notifier).preparar(BigInt.from(100));

      expect(r, isNotNull);
      expect(r!.cheque.codBancoCheque, 8);
      expect(r.fechaBanco, DateTime(2026, 10, 3));
      expect(repo.consultasPendientes, hasLength(antes));
    });
  });

  group('apoyo', () {
    test('cuantos cheques faltan sale del total de pendientes con cobranza hasta hoy', () async {
      repo.pendientes = [
        pendienteFalso(100),
        pendienteFalso(101, fechaCobranza: DateTime(2026, 9, 1)),
        pendienteFalso(102, fechaCobranza: DateTime(2026, 12, 1)),
        pendienteFalso(103, chequeCerrado: true),
      ];
      expect(await c.read(chequesSinVerificarProvider.future), 2);
      final q = repo.consultasPendientes.single;
      expect((q.estado, q.soloCobranzaHoy, q.tamanio), ('PEN', false, 1));
    });

    test('los estados de cheque se piden una sola vez por sesion', () async {
      c.listen(estadosChequeVerificacionProvider, (_, __) {});
      final e = await c.read(estadosChequeVerificacionProvider.future);
      expect(e.map((o) => o.codigo), ['PEN', 'CER']);
      await c.read(estadosChequeVerificacionProvider.future);
      expect(repo.consultasEstados, 1);
    });
  });
}
