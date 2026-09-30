import 'dart:async';

import 'package:bosque_flutter/core/state/depositos_cheques_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/socio_negocio_entity.dart';
import 'package:bosque_flutter/domain/repositories/deposito_cheques_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/repositorio_depositos.dart';

/// El notifier de depósitos concentra lo que antes hacía lento y frágil al
/// módulo: una sola bandera para todo, listas vacías que escondían errores,
/// respuestas viejas que pisaban a las nuevas, notas guardadas una por una y un
/// reintento que duplicaba el depósito. Estas pruebas fijan cada punto con un
/// repositorio falso, sin backend ni pantallas.
void main() {
  late RepoDepositosFalso repo;
  late ProviderContainer contenedor;

  DepositosChequesNotifier notifier() =>
      contenedor.read(depositosChequesProvider.notifier);
  DepositosChequesState estado() => contenedor.read(depositosChequesProvider);

  setUp(() {
    repo = RepoDepositosFalso();
    contenedor = ProviderContainer(
      overrides: [
        userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(loginAdminFalso)),
        depositosChequesProvider.overrideWith(
          (ref) => DepositosChequesNotifier(ref, repo: repo),
        ),
      ],
    );
    // autoDispose: sin oyente el provider se destruye entre lecturas.
    contenedor.listen(depositosChequesProvider, (_, __) {});
    addTearDown(() {
      try {
        contenedor.dispose();
      } catch (_) {
        // un test ya lo cerró a propósito
      }
    });
  });

  /// Deja el formulario listo para guardar: empresa, cliente, banco y las
  /// notas [docNums] marcadas.
  Future<void> prepararRegistro(List<int> docNums) async {
    repo.notas = [for (final d in docNums) notaFalsa(d)];
    await notifier().cargarEmpresasSiFalta();
    await notifier().seleccionarEmpresa(repo.empresas.first);
    await notifier().seleccionarCliente(estado().clientes[1]);
    notifier().seleccionarBanco(estado().bancos.first);
    for (final d in docNums) {
      notifier().seleccionarNota(d, true);
    }
  }

  group('carga', () {
    test('crear el notifier no pide nada al backend', () {
      notifier();
      expect(repo.llamadas, isEmpty);
      expect(estado().cargando, isFalse);
    });

    test('las empresas se piden una sola vez y «Todos» va primero', () async {
      final a = notifier().cargarEmpresasSiFalta();
      final b = notifier().cargarEmpresasSiFalta();
      await Future.wait([a, b]);
      await notifier().cargarEmpresasSiFalta();

      expect(repo.contar('getEmpresas'), 1);
      expect(estado().empresas.first.nombre, 'Todos');
      expect(estado().empresas.first.codEmpresa, 0);
      expect(estado().cargandoEmpresas, isFalse);
    });

    test('un fallo queda en `error` y no se disfraza de lista vacía', () async {
      repo.errorEmpresas = const DepositoChequesException('Sin conexión.');
      await notifier().cargarEmpresas();

      expect(estado().error.toString(), 'Sin conexión.');
      expect(estado().empresas, isEmpty);
      expect(estado().cargandoEmpresas, isFalse);
    });

    test('«sin registros» (lista vacía) no es un error', () async {
      repo.notas = [];
      await notifier().cargarEmpresasSiFalta();
      await notifier().seleccionarEmpresa(repo.empresas.first);
      await notifier().seleccionarCliente(estado().clientes[1]);

      expect(estado().error, isNull);
      expect(estado().notasRemision, isEmpty);
      expect(estado().cargandoNotas, isFalse);
    });

    test('reintentar limpia el error anterior', () async {
      repo.errorEmpresas = const DepositoChequesException('Sin conexión.');
      await notifier().cargarEmpresas();
      repo.errorEmpresas = null;
      await notifier().cargarEmpresas();

      expect(estado().error, isNull);
      expect(estado().empresas, isNotEmpty);
    });

    test('con cargarClientes:false no descarga el maestro de clientes', () async {
      await notifier().cargarEmpresasSiFalta();
      await notifier().seleccionarEmpresa(
        repo.empresas.first,
        cargarClientes: false,
      );

      expect(repo.contar('getSociosNegocio'), 0);
      expect(repo.contar('getBancos'), 1);
      expect(estado().clientes, isEmpty);
      expect(estado().cargandoClientes, isFalse);
    });

    test('los bancos aparecen sin esperar a los clientes', () async {
      final lentos = Completer<List<SocioNegocioEntity>>();
      repo.clientesPendientes = lentos;
      await notifier().cargarEmpresasSiFalta();

      final eleccion = notifier().seleccionarEmpresa(repo.empresas.first);
      await Future<void>.delayed(Duration.zero);

      expect(estado().cargandoBancos, isFalse);
      expect(estado().bancos, isNotEmpty);
      expect(estado().cargandoClientes, isTrue);

      lentos.complete([clienteFalso('C1')]);
      await eleccion;
      expect(estado().cargandoClientes, isFalse);
      expect(estado().clientes.first.razonSocial, 'Todos');
      expect(estado().clientes, hasLength(2));
    });

    test('una respuesta vieja no pisa a la de la empresa elegida después', () async {
      final lentos = Completer<List<SocioNegocioEntity>>();
      repo.clientesPendientes = lentos;
      await notifier().cargarEmpresasSiFalta();

      final primera = notifier().seleccionarEmpresa(repo.empresas[1]);
      repo.clientesPendientes = null;
      repo.clientes = [clienteFalso('B1'), clienteFalso('B2')];
      await notifier().seleccionarEmpresa(repo.empresas[2]);

      lentos.complete([clienteFalso('A1')]);
      await primera;

      expect(estado().empresaSeleccionada!.codEmpresa, 3);
      expect(estado().clientes.map((c) => c.codCliente), ['', 'B1', 'B2']);
    });
  });

  group('selección', () {
    test('cambiar de empresa descarta banco, notas y saldos', () async {
      await prepararRegistro([10, 11]);
      notifier().editarSaldoPendiente(10, 5);
      expect(estado().bancoSeleccionado, isNotNull);

      await notifier().seleccionarEmpresa(repo.empresas[2]);

      expect(estado().bancoSeleccionado, isNull);
      expect(estado().clienteSeleccionado?.razonSocial, 'Todos');
      expect(estado().notasRemision, isEmpty);
      expect(estado().notasSeleccionadas, isEmpty);
      expect(estado().saldosEditados, isEmpty);
    });

    test('cambiar de cliente descarta las notas del anterior', () async {
      await prepararRegistro([10, 11]);
      expect(estado().notasSeleccionadas, [10, 11]);

      repo.notas = [notaFalsa(99)];
      await notifier().seleccionarCliente(clienteFalso('C2'));

      expect(estado().notasSeleccionadas, isEmpty);
      expect(estado().notasRemision.map((n) => n.docNum), [99]);
    });

    test('con cargarNotas:false el cliente es solo un filtro', () async {
      await notifier().cargarEmpresasSiFalta();
      await notifier().seleccionarEmpresa(repo.empresas.first);
      final antes = repo.contar('getNotasRemision');

      await notifier().seleccionarCliente(
        estado().clientes[1],
        cargarNotas: false,
      );

      expect(repo.contar('getNotasRemision'), antes);
      expect(estado().clienteSeleccionado!.codCliente, 'C1');
      expect(estado().cargandoNotas, isFalse);
    });

    test('seleccionarBanco(null) sí limpia', () async {
      await prepararRegistro([10]);
      notifier().seleccionarBanco(null);
      expect(estado().bancoSeleccionado, isNull);
    });

    test('el importe suma notas marcadas (con saldo editado) más a cuenta', () async {
      await prepararRegistro([10, 11]);
      notifier().editarSaldoPendiente(10, 40);
      notifier().setACuenta(5);
      // nota 10 editada = 40, nota 11 = 100 (saldo original), a cuenta = 5
      expect(estado().importeTotal, 145);

      notifier().seleccionarNota(11, false);
      expect(estado().importeTotal, 45);
    });
  });

  group('guardar depósito con notas', () {
    test('camino feliz: un depósito, todas las notas, ≤3 a la vez', () async {
      await prepararRegistro([1, 2, 3, 4, 5, 6, 7]);

      final r = await notifier().guardarDepositoConNotas(null);

      expect(r.ok, isTrue);
      expect(repo.contar('registrarDeposito'), 1);
      expect(repo.notasGuardadas.toSet(), {1, 2, 3, 4, 5, 6, 7});
      expect(repo.maxNotasSimultaneas, lessThanOrEqualTo(3));
      expect(repo.maxNotasSimultaneas, greaterThan(1));
      expect(estado().guardando, isFalse);
      expect(estado().depositoRegistrado, isFalse);
    });

    test('si una nota falla, el reintento no duplica depósito ni notas', () async {
      await prepararRegistro([1, 2, 3, 4, 5]);
      repo.notaQueFalla = 3;

      final primero = await notifier().guardarDepositoConNotas(null);

      expect(primero.depositoOk, isTrue);
      expect(primero.notas.ok, isFalse);
      expect(primero.notas.fallidas, contains(3));
      expect(primero.notas.error, isA<DepositoChequesException>());
      expect(estado().depositoRegistrado, isTrue);
      expect(estado().guardando, isFalse);

      final yaGuardadas = repo.notasGuardadas.toList();
      repo.notaQueFalla = null;
      final segundo = await notifier().guardarDepositoConNotas(null);

      expect(segundo.ok, isTrue);
      expect(repo.contar('registrarDeposito'), 1, reason: 'no crea otro depósito');
      final reenviadas = repo.notasGuardadas.sublist(yaGuardadas.length);
      expect(
        reenviadas.toSet().intersection(yaGuardadas.toSet()),
        isEmpty,
        reason: 'no vuelve a enviar las que ya entraron',
      );
      expect(repo.notasGuardadas.toSet(), {1, 2, 3, 4, 5});
      expect(estado().depositoRegistrado, isFalse);
    });

    test('un segundo toque mientras guarda no hace nada', () async {
      await prepararRegistro([1, 2]);

      final a = notifier().guardarDepositoConNotas(null);
      final b = await notifier().guardarDepositoConNotas(null);
      await a;

      expect(b.ignorado, isTrue);
      expect(repo.contar('registrarDeposito'), 1);
    });

    test('si crear el depósito falla, lanza el motivo real y libera el botón', () async {
      await prepararRegistro([1]);
      repo.errorRegistro = const DepositoChequesException(
        'La conexión tardó demasiado.',
      );

      await expectLater(
        notifier().guardarDepositoConNotas(null),
        throwsA(
          isA<DepositoChequesException>().having(
            (e) => e.mensaje,
            'mensaje',
            'La conexión tardó demasiado.',
          ),
        ),
      );
      expect(estado().guardando, isFalse);
      expect(estado().depositoRegistrado, isFalse);
      expect(repo.notasGuardadas, isEmpty);
    });

    test('registrarDeposito por separado también apaga `guardando`', () async {
      await prepararRegistro([1]);
      await notifier().registrarDeposito(null);
      expect(estado().guardando, isFalse);
    });
  });

  group('asignar un depósito por identificar', () {
    test('si falla una nota no toca el depósito; el reintento envía lo pendiente', () async {
      await prepararRegistro([1, 2, 3]);
      repo.notaQueFalla = 2;

      final primero = await notifier().asignarDeposito(idDeposito: 77);

      expect(primero.notas.ok, isFalse);
      expect(primero.depositoOk, isFalse);
      expect(repo.contar('registrarDeposito'), 0);
      expect(repo.idsDeNotas.toSet(), {77}, reason: 'las notas llevan el id');

      repo.notaQueFalla = null;
      final segundo = await notifier().asignarDeposito(idDeposito: 77);

      expect(segundo.ok, isTrue);
      expect(repo.contar('registrarDeposito'), 1);
      expect(repo.ultimoDeposito!.idDeposito, 77);
      expect(repo.notasGuardadas.toSet(), {1, 2, 3});
      expect(
        repo.notasGuardadas.where((d) => d == 1),
        hasLength(1),
        reason: 'la nota 1 no se reenvía',
      );
    });
  });

  group('listado', () {
    test('un fallo de búsqueda queda en `error`, no en «sin depósitos»', () async {
      repo.errorListado = const DepositoChequesException('Error en el servidor.');
      await notifier().buscarDepositos();

      expect(estado().buscando, isFalse);
      expect(estado().error.toString(), 'Error en el servidor.');
      expect(estado().depositos, isEmpty);
    });

    test('buscar reinicia la página', () async {
      repo.depositos = [for (var i = 1; i <= 25; i++) depositoFalso(i)];
      await notifier().buscarDepositos();
      notifier().setPage(2);
      await notifier().buscarDepositos();

      expect(estado().page, 0);
      expect(estado().totalRegistros, 25);
    });

    test('aplicarRangoPorDefecto fija 30 días y respeta fechas ya elegidas', () {
      notifier().aplicarRangoPorDefecto(dias: 30);
      final desde = estado().fechaDesde!;
      final hasta = estado().fechaHasta!;
      expect(desde, DateTime(hasta.year, hasta.month, hasta.day - 30));

      final elegida = DateTime(2026, 1, 15);
      notifier().setFechaDesde(elegida);
      notifier().aplicarRangoPorDefecto(dias: 30);
      expect(estado().fechaDesde, elegida);
    });

    test('borrar una fecha la deja en null', () {
      notifier().aplicarRangoPorDefecto();
      notifier().setFechaDesde(null);
      expect(estado().fechaDesde, isNull);
      expect(estado().fechaHasta, isNotNull);
    });

    test('quitarDeposito saca la fila y ajusta la página', () async {
      repo.depositos = [for (var i = 1; i <= 11; i++) depositoFalso(i)];
      await notifier().buscarDepositos();
      notifier().setPage(1);

      notifier().quitarDeposito(11);

      expect(estado().depositos, hasLength(10));
      expect(estado().totalRegistros, 10);
      expect(estado().page, 0, reason: 'la página 1 quedó vacía');
    });
  });


  group('errores por operación y reintento', () {
    test('un fallo de bancos no se borra al elegir cliente', () async {
      repo.errorBancos = const DepositoChequesException('Bancos caídos.');
      await notifier().cargarEmpresasSiFalta();
      await notifier().seleccionarEmpresa(repo.empresas.first);
      expect(estado().errorEn, OperacionCarga.bancos);

      await notifier().seleccionarCliente(estado().clientes[1]);

      expect(estado().error.toString(), 'Bancos caídos.');
      expect(estado().errorEn, OperacionCarga.bancos);
    });

    test('reintentarUltimaCarga repite justo lo que falló', () async {
      repo.errorBancos = const DepositoChequesException('Bancos caídos.');
      await notifier().cargarEmpresasSiFalta();
      await notifier().seleccionarEmpresa(repo.empresas.first);
      expect(notifier().puedeReintentar, isTrue);
      expect(estado().bancos, isEmpty);

      repo.errorBancos = null;
      await notifier().reintentarUltimaCarga();

      expect(estado().bancos, isNotEmpty);
      expect(estado().error, isNull);
      expect(estado().errorEn, isNull);
    });

    test('el reintento de empresas no depende de la pantalla', () async {
      repo.errorEmpresas = const DepositoChequesException('Sin conexión.');
      await notifier().cargarEmpresasSiFalta();
      repo.errorEmpresas = null;

      await notifier().reintentarUltimaCarga();

      expect(estado().empresas, isNotEmpty);
      expect(estado().error, isNull);
    });

    test('un fallo del listado se reintenta con los mismos filtros', () async {
      repo.errorListado = const DepositoChequesException('Servidor caído.');
      await notifier().buscarDepositosPorIdentificar(idBxC: 7, codCliente: 'X');
      expect(estado().errorEn, OperacionCarga.listado);

      repo.errorListado = null;
      repo.depositos = [depositoFalso(1)];
      await notifier().reintentarUltimaCarga();

      expect(estado().depositos, hasLength(1));
      expect(estado().error, isNull);
      expect(repo.contar('lstDepositxIdentificar'), 2);
    });

    test('guardar no borra un error de carga que sigue pendiente', () async {
      repo.errorBancos = const DepositoChequesException('Bancos caídos.');
      await notifier().cargarEmpresasSiFalta();
      await notifier().seleccionarEmpresa(repo.empresas.first);
      await notifier().registrarDeposito(null);

      expect(estado().errorEn, OperacionCarga.bancos);
    });
  });

  group('importe', () {
    test('cambiar de empresa conserva el importe tecleado si no hay notas', () async {
      await notifier().cargarEmpresasSiFalta();
      notifier().setImporteTotal(250);

      await notifier().seleccionarEmpresa(repo.empresas.first, cargarClientes: false);

      expect(estado().importeTotal, 250);
    });

    test('con notas marcadas, cambiar de empresa vuelve al importe «a cuenta»', () async {
      await prepararRegistro([10]);
      notifier().setACuenta(5);
      expect(estado().importeTotal, 105);

      await notifier().seleccionarEmpresa(repo.empresas[2]);

      expect(estado().importeTotal, 5);
    });
  });

  test('si la pantalla se cierra en pleno guardado, las notas igual se guardan', () async {
    await prepararRegistro([1, 2, 3]);

    final guardado = notifier().guardarDepositoConNotas(null);
    contenedor.dispose(); // el usuario sale de la pantalla
    final r = await guardado;

    expect(r.depositoOk, isTrue);
    expect(r.notas.ok, isTrue);
    expect(repo.notasGuardadas.toSet(), {1, 2, 3});
  });

  test('copyWith puede limpiar lo que `??` no podía', () {
    final banco = bancoFalso(1);
    final conBanco = DepositosChequesState(bancoSeleccionado: banco);
    expect(conBanco.copyWith().bancoSeleccionado, banco);
    expect(conBanco.copyWith(clearBanco: true).bancoSeleccionado, isNull);
    expect(
      DepositosChequesState(error: 'x').copyWith(clearError: true).error,
      isNull,
    );
  });

  test('`cargando` refleja cualquier operación en curso', () {
    expect(DepositosChequesState().cargando, isFalse);
    expect(DepositosChequesState(buscando: true).cargando, isTrue);
    expect(DepositosChequesState(guardando: true).cargando, isTrue);
    expect(DepositosChequesState(cargandoNotas: true).cargando, isTrue);
  });
}

