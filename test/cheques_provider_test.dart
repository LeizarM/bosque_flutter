import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_filtro_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_pagina_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/custodia_cheque_request_entity.dart';
import 'package:bosque_flutter/domain/entities/dar_custodia_request_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';

import 'fakes/repositorio_cheques.dart';

/// El estado del modulo de cheques con un repositorio falso: la grilla (sucursal,
/// filtros, paginas), las escrituras y los errores del backend. Sin red ni login.
void main() {
  // El cliente HTTP lee dotenv al armarse; solo lo arma el cableado de permisos.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late RepositorioChequesFalso repo;

  /// Un contenedor con el repositorio falso. [grilla] mantiene viva la grilla
  /// (es autoDispose: sin oyente se destruiria entre lecturas).
  ProviderContainer crear({bool grilla = true, DateTime? hoy}) {
    // El reloj va fijo: el rango por defecto de la grilla sale de «hoy».
    final ahora = hoy ?? DateTime(2026, 10, 3, 15, 30);
    final c = ProviderContainer(
      overrides: [
        chequesRepositoryProvider.overrideWithValue(repo),
        relojChequesProvider.overrideWithValue(() => ahora),
      ],
    );
    addTearDown(c.dispose);
    if (grilla) c.listen(grillaChequesProvider, (_, __) {});
    return c;
  }

  setUp(() => repo = RepositorioChequesFalso());

  EstadoGrillaCheques estado(ProviderContainer c) =>
      c.read(grillaChequesProvider);
  GrillaChequesNotifier grilla(ProviderContainer c) =>
      c.read(grillaChequesProvider.notifier);
  OperacionesChequesNotifier ops(ProviderContainer c) =>
      c.read(operacionesChequesProvider.notifier);
  EstadoOperacionCheque estadoOps(ProviderContainer c) =>
      c.read(operacionesChequesProvider);

  group('grilla: rango de recepcion', () {
    test('al iniciar pide de hace tres meses a hoy, sin la clave antigua', () async {
      final c = crear();
      await grilla(c).iniciar();

      final f = repo.filtros.single;
      expect(f.fechaRecepcionDesde, DateTime(2026, 7, 3));
      expect(f.fechaRecepcionHasta, DateTime(2026, 10, 3));

      final cuerpo = repo.cuerposListar.single;
      expect(cuerpo['fechaRecepcionDesde'], '2026-07-03');
      expect(cuerpo['fechaRecepcionHasta'], '2026-10-03');
      expect(cuerpo.containsKey('fechaRecepcion'), isFalse);
      expect(cuerpo.containsKey('audUsuario'), isFalse);
    });

    test('el rango sale del reloj inyectado y no recorta mal el fin de mes', () async {
      final c = crear(hoy: DateTime(2026, 5, 31, 23, 59));
      await grilla(c).iniciar();

      final f = repo.filtros.single;
      expect(f.fechaRecepcionDesde, DateTime(2026, 2, 28));
      expect(f.fechaRecepcionHasta, DateTime(2026, 5, 31));
      expect(grilla(c).rangoPorDefecto, (
        desde: DateTime(2026, 2, 28),
        hasta: DateTime(2026, 5, 31),
      ));
    });

    test('el estado ya trae el rango antes de iniciar, sin pedir nada', () {
      final c = crear();
      expect(estado(c).filtro.fechaRecepcionDesde, DateTime(2026, 7, 3));
      expect(estado(c).filtro.fechaRecepcionHasta, DateTime(2026, 10, 3));
      expect(repo.llamadas, isEmpty);
    });

    test('quitar las dos fechas y buscar no manda ninguna de las dos claves', () async {
      final c = crear();
      await grilla(c).iniciar();

      await grilla(c).aplicarCriterios();

      final cuerpo = repo.cuerposListar.last;
      expect(cuerpo.containsKey('fechaRecepcionDesde'), isFalse);
      expect(cuerpo.containsKey('fechaRecepcionHasta'), isFalse);
      expect(cuerpo.containsKey('fechaRecepcion'), isFalse);
      expect(estado(c).filtro.tieneRangoRecepcion, isFalse);
    });

    test('quitar solo una fecha manda solo la otra', () async {
      final c = crear();
      await grilla(c).iniciar();

      await grilla(c).aplicarCriterios(fechaRecepcionDesde: DateTime(2026, 7, 3));
      var cuerpo = repo.cuerposListar.last;
      expect(cuerpo['fechaRecepcionDesde'], '2026-07-03');
      expect(cuerpo.containsKey('fechaRecepcionHasta'), isFalse);

      await grilla(c).aplicarCriterios(fechaRecepcionHasta: DateTime(2026, 10, 3));
      cuerpo = repo.cuerposListar.last;
      expect(cuerpo['fechaRecepcionHasta'], '2026-10-03');
      expect(cuerpo.containsKey('fechaRecepcionDesde'), isFalse);
    });

    test('cambiar de sucursal o de empresa conserva el rango elegido', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).aplicarCriterios(
        fechaRecepcionDesde: DateTime(2026, 1, 15),
        fechaRecepcionHasta: DateTime(2026, 2, 20),
      );

      await grilla(c).elegirSucursal(4);
      expect(repo.filtros.last.codSucursal, 4);
      expect(repo.filtros.last.fechaRecepcionDesde, DateTime(2026, 1, 15));
      expect(repo.filtros.last.fechaRecepcionHasta, DateTime(2026, 2, 20));

      await grilla(c).elegirEmpresa(5);
      expect(repo.filtros.last.codSucursal, 7);
      expect(repo.filtros.last.fechaRecepcionDesde, DateTime(2026, 1, 15));
      expect(repo.filtros.last.fechaRecepcionHasta, DateTime(2026, 2, 20));
      expect(
        repo.cuerposListar.last['fechaRecepcionDesde'],
        '2026-01-15',
      );
    });

    test('si el usuario quito las fechas, cambiar de sucursal no las repone', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).aplicarCriterios();

      await grilla(c).elegirSucursal(4);
      await grilla(c).elegirEmpresa(5);

      for (final f in repo.filtros.skip(1)) {
        expect(f.tieneRangoRecepcion, isFalse);
      }
      expect(repo.cuerposListar.last.containsKey('fechaRecepcionDesde'), isFalse);
    });

    test('cambiar de orden o de pagina conserva el rango', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).irAPagina(2);
      await grilla(c).cambiarOrden(OrdenCheques.cobro);

      for (final f in repo.filtros) {
        expect(f.fechaRecepcionDesde, DateTime(2026, 7, 3));
        expect(f.fechaRecepcionHasta, DateTime(2026, 10, 3));
      }
    });

    test('con el filtro del falso activo, el rango recorta y quitarlo trae todo', () async {
      repo
        ..filtrarPorRecepcion = true
        // Recibidos del 23 al 27 de agosto de 2026.
        ..cheques = [for (var i = 1; i <= 5; i++) chequeFalso(i)];
      final c = crear(hoy: DateTime(2026, 8, 31));
      await grilla(c).iniciar();
      expect(estado(c).total, 5);

      await grilla(c).aplicarCriterios(fechaRecepcionDesde: DateTime(2026, 8, 28));
      // Desde el 28 no entra ninguno.
      expect(estado(c).total, 0);

      await grilla(c).aplicarCriterios();
      expect(estado(c).total, 5);
    });
  });

  group('grilla: apertura', () {
    test('crear el notifier no pide nada al backend', () {
      final c = crear();
      expect(repo.llamadas, isEmpty);
      expect(estado(c).iniciado, isFalse);
      expect(estado(c).haySucursal, isFalse);
      expect(estado(c).cargando, isFalse);
    });

    test(
      'iniciar toma la sucursal inicial y carga la primera pagina',
      () async {
        final c = crear();
        await grilla(c).iniciar();

        final e = estado(c);
        expect(e.iniciado, isTrue);
        expect(e.codSucursal, 3);
        expect(e.cargando, isFalse);
        expect(e.error, isNull);
        expect(e.total, 45);
        expect(e.totalPaginas, 3);
        expect(e.pagina, 1);
        expect(e.filas, hasLength(20));
        expect(e.hayAnterior, isFalse);
        expect(e.haySiguiente, isTrue);
        expect(repo.filtros.single.codSucursal, 3);
        expect(repo.filtros.single.pagina, 1);
        expect(repo.filtros.single.tamanio, 20);
      },
    );

    test(
      'un usuario sin sucursal queda iniciado, sin consulta y sin error',
      () async {
        repo.sucursalInicial = 0;
        final c = crear();
        await grilla(c).iniciar();

        final e = estado(c);
        expect(e.iniciado, isTrue);
        expect(e.haySucursal, isFalse);
        expect(e.error, isNull);
        expect(e.resultado, isNull);
        expect(repo.contar('listar'), 0);
      },
    );

    test('iniciar dos veces no repite la consulta', () async {
      final c = crear();
      await Future.wait([grilla(c).iniciar(), grilla(c).iniciar()]);
      await grilla(c).iniciar();
      expect(repo.contar('obtenerSucursalInicial'), 1);
      expect(repo.contar('listar'), 1);
    });

    test(
      'si falla la sucursal inicial el error queda y se puede reintentar',
      () async {
        repo.errorSucursalInicial = Exception(
          'No se pudo consultar la sucursal.',
        );
        final c = crear();
        await grilla(c).iniciar();
        expect(estado(c).error, 'No se pudo consultar la sucursal.');
        expect(estado(c).iniciado, isFalse);
        expect(estado(c).cargando, isFalse);

        repo.errorSucursalInicial = null;
        await grilla(c).iniciar();
        expect(estado(c).error, isNull);
        expect(estado(c).iniciado, isTrue);
        expect(estado(c).codSucursal, 3);
      },
    );

    test(
      'si el usuario elige sucursal mientras se consulta la inicial, manda su eleccion',
      () async {
        final espera = Completer<void>();
        var primera = true;
        // Solo la sucursal inicial se demora.
        final c = ProviderContainer(
          overrides: [
            chequesRepositoryProvider.overrideWithValue(
              _Demorado(repo, () {
                if (primera) {
                  primera = false;
                  return espera.future;
                }
                return null;
              }),
            ),
          ],
        );
        addTearDown(c.dispose);
        c.listen(grillaChequesProvider, (_, __) {});

        final inicio = grilla(c).iniciar();
        await grilla(c).elegirSucursal(4);
        espera.complete();
        await inicio;

        expect(estado(c).codSucursal, 4);
      },
    );
  });

  group('empresa de trabajo', () {
    EmpresaChequeEntity? activa(ProviderContainer c) =>
        c.read(empresaChequeActivaProvider);

    test('resolverEmpresaCheque: la elegida, o la primera', () {
      const lista = empresasChequeFalsas;
      expect(resolverEmpresaCheque(null, 0), isNull);
      expect(resolverEmpresaCheque(const [], 5), isNull);
      expect(resolverEmpresaCheque(lista, 0)!.codEmpresa, 1);
      expect(resolverEmpresaCheque(lista, 5)!.codEmpresa, 5);
      // Una elegida que ya no esta en la lista no deja la pantalla sin empresa.
      expect(resolverEmpresaCheque(lista, 99)!.codEmpresa, 1);
    });

    test(
      'iniciar toma la primera empresa y pide la sucursal inicial de ESA empresa',
      () async {
        final c = crear();
        c.listen(empresaChequeActivaProvider, (_, __) {});
        await grilla(c).iniciar();

        expect(repo.contar('listarEmpresas'), 1);
        expect(repo.empresasDeSucursalInicial, [1]);
        expect(estado(c).codEmpresa, 1);
        expect(estado(c).codSucursal, 3);
        expect(activa(c)!.nombre, 'IMPEXPAP');
      },
    );

    test('la primera es la primera de la lista, no el codigo menor', () async {
      repo.empresas = const [
        EmpresaChequeEntity(codEmpresa: 5, nombre: 'ESPPAPEL'),
        EmpresaChequeEntity(codEmpresa: 1, nombre: 'IMPEXPAP'),
      ];
      final c = crear();
      await grilla(c).iniciar();
      expect(repo.empresasDeSucursalInicial, [5]);
      expect(estado(c).codEmpresa, 5);
      expect(estado(c).codSucursal, 7);
    });

    test('la empresa activa es null mientras la lista carga', () async {
      final espera = Completer<void>();
      final c = ProviderContainer(
        overrides: [
          chequesRepositoryProvider.overrideWithValue(_ListaDemorada(espera.future)),
        ],
      );
      addTearDown(c.dispose);
      c.listen(empresaChequeActivaProvider, (_, __) {});
      expect(activa(c), isNull);

      espera.complete();
      await c.read(empresasChequeProvider.future);
      expect(activa(c)!.codEmpresa, 1);
    });

    test('las empresas se piden una sola vez', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).elegirEmpresa(5);
      await grilla(c).elegirEmpresa(1);
      expect(repo.contar('listarEmpresas'), 1);
    });

    test(
      'cambiar de empresa pone la sucursal de esa empresa, limpia la lista y recarga',
      () async {
        repo.cheques = [
          ...repo.cheques,
          for (var i = 100; i < 103; i++)
            chequeFalso(i, codSucursal: 7, codEmpresa: 5),
        ];
        final c = crear();
        c.listen(empresaChequeActivaProvider, (_, __) {});
        await grilla(c).iniciar();
        await grilla(c).aplicarCriterios(estado: 'PEN');
        await grilla(c).irAPagina(2);

        final pendiente = grilla(c).elegirEmpresa(5);
        // Mientras llega la sucursal de la empresa nueva no queda a la vista nada
        // de la anterior y la sucursal vuelve a 0, como `trasSeleccionEmpresa`.
        expect(estado(c).codEmpresa, 5);
        expect(estado(c).codSucursal, 0);
        expect(estado(c).pagina, 1);
        expect(estado(c).resultado, isNull);
        expect(estado(c).cargando, isTrue);
        await pendiente;

        expect(repo.empresasDeSucursalInicial, [1, 5]);
        expect(estado(c).codSucursal, 7);
        expect(estado(c).total, 3);
        expect(estado(c).cargando, isFalse);
        expect(estado(c).error, isNull);
        // Los criterios se conservan, como al cambiar de sucursal.
        expect(repo.filtros.last.estado, 'PEN');
        expect(repo.filtros.last.codSucursal, 7);
        expect(repo.filtros.last.pagina, 1);
        expect(activa(c)!.nombre, 'ESPPAPEL');
      },
    );

    test('las sucursales que se ofrecen son las de la empresa elegida', () async {
      final c = crear();
      c.listen(sucursalesChequeActivasProvider, (_, __) {});
      await grilla(c).iniciar();
      await c.read(sucursalesChequeProvider(1).future);
      expect(
        c.read(sucursalesChequeActivasProvider).map((s) => s.nombre),
        ['LA PAZ', 'EL ALTO'],
      );

      await grilla(c).elegirEmpresa(5);
      await c.read(sucursalesChequeProvider(5).future);
      expect(
        c.read(sucursalesChequeActivasProvider).map((s) => s.nombre),
        ['SANTA CRUZ', 'COCHABAMBA'],
      );
      expect(repo.empresasDeSucursales, [1, 5]);
    });

    test('elegir la empresa que ya esta, o una invalida, no hace nada', () async {
      final c = crear();
      await grilla(c).iniciar();
      final antes = repo.llamadas.length;
      await grilla(c).elegirEmpresa(1);
      await grilla(c).elegirEmpresa(0);
      await grilla(c).elegirEmpresa(-4);
      expect(repo.llamadas.length, antes);
      expect(estado(c).codEmpresa, 1);
      expect(estado(c).codSucursal, 3);
    });

    test('una empresa sin sucursal para el usuario queda sin consulta y sin error', () async {
      repo.sucursalInicialPorEmpresa = {5: 0};
      final c = crear();
      await grilla(c).iniciar();
      final listados = repo.contar('listar');

      await grilla(c).elegirEmpresa(5);

      expect(estado(c).codEmpresa, 5);
      expect(estado(c).haySucursal, isFalse);
      expect(estado(c).iniciado, isTrue);
      expect(estado(c).error, isNull);
      expect(estado(c).cargando, isFalse);
      expect(estado(c).resultado, isNull);
      expect(repo.contar('listar'), listados);
    });

    group('dos cambios seguidos: gana el ultimo', () {
      /// La grilla ya abierta y cada sucursal inicial pendiente de responder.
      Future<(ProviderContainer, Map<int, Completer<int>>)> preparar() async {
        final c = crear();
        await grilla(c).iniciar();
        final pendientes = <int, Completer<int>>{};
        repo.alObtenerSucursalInicial = (cod) {
          final r = Completer<int>();
          pendientes[cod] = r;
          return r.future;
        };
        return (c, pendientes);
      }

      test('la respuesta de la empresa vieja llega despues y se descarta', () async {
        final (c, pendientes) = await preparar();
        final a = grilla(c).elegirEmpresa(5);
        final b = grilla(c).elegirEmpresa(1);

        pendientes[1]!.complete(3);
        await b;
        expect(estado(c).codEmpresa, 1);
        expect(estado(c).codSucursal, 3);

        pendientes[5]!.complete(7);
        await a;

        expect(estado(c).codEmpresa, 1);
        expect(estado(c).codSucursal, 3);
        expect(estado(c).cargando, isFalse);
        expect(estado(c).filas, isNotEmpty);
        expect(repo.filtros.every((f) => f.codSucursal == 3), isTrue);
      });

      test('la respuesta de la empresa vieja llega antes y no pisa a la nueva', () async {
        final (c, pendientes) = await preparar();
        final a = grilla(c).elegirEmpresa(5);
        final b = grilla(c).elegirEmpresa(1);
        final listadosAntes = repo.contar('listar');

        pendientes[5]!.complete(7);
        await a;
        // La vieja no consulto nada ni cambio la sucursal.
        expect(repo.contar('listar'), listadosAntes);
        expect(estado(c).codSucursal, 0);

        pendientes[1]!.complete(3);
        await b;
        expect(estado(c).codEmpresa, 1);
        expect(estado(c).codSucursal, 3);
        expect(estado(c).filas, isNotEmpty);
      });

      test('un error de la empresa vieja tampoco pisa a la nueva', () async {
        final (c, pendientes) = await preparar();
        final a = grilla(c).elegirEmpresa(5);
        final b = grilla(c).elegirEmpresa(1);

        pendientes[1]!.complete(3);
        await b;
        pendientes[5]!.completeError(Exception('Tardo y fallo.'));
        await a;

        expect(estado(c).error, isNull);
        expect(estado(c).codEmpresa, 1);
        expect(estado(c).iniciado, isTrue);
      });

      test('la pagina de la empresa vieja que ya viajaba no se pinta', () async {
        repo.cheques = [
          ...repo.cheques,
          chequeFalso(100, codSucursal: 7, codEmpresa: 5, cliente: 'DE LA 5'),
        ];
        final c = crear();
        await grilla(c).iniciar();
        final paginas = <int, Completer<ChequePaginaEntity>>{};
        final base = repo.listar;
        repo.alListar = (f) {
          final r = Completer<ChequePaginaEntity>();
          paginas[f.codSucursal] = r;
          return r.future;
        };

        // La empresa 5 llega a consultar su sucursal 7 y, antes de que responda,
        // se vuelve a la 1.
        final a = grilla(c).elegirEmpresa(5);
        await Future<void>.delayed(Duration.zero);
        expect(paginas.containsKey(7), isTrue);
        final b = grilla(c).elegirEmpresa(1);
        await Future<void>.delayed(Duration.zero);
        expect(paginas.containsKey(3), isTrue);

        repo.alListar = null;
        paginas[3]!.complete(await base(const ChequeFiltroEntity(codSucursal: 3)));
        await b;
        paginas[7]!.complete(
          ChequePaginaEntity(
            total: 1,
            pagina: 1,
            tamanio: 20,
            filas: [chequeFalso(100, codSucursal: 7, codEmpresa: 5)],
          ),
        );
        await a;

        expect(estado(c).codEmpresa, 1);
        expect(estado(c).codSucursal, 3);
        expect(estado(c).total, 45);
      });
    });

    test('cambiar de empresa mientras se pide la sucursal inicial de la primera: gana el cambio', () async {
      final pendientes = <int, Completer<int>>{};
      repo.alObtenerSucursalInicial =
          (cod) => (pendientes[cod] = Completer<int>()).future;
      final c = crear();
      final inicio = grilla(c).iniciar();
      await Future<void>.delayed(Duration.zero);
      expect(pendientes.containsKey(1), isTrue);

      final cambio = grilla(c).elegirEmpresa(5);
      pendientes[5]!.complete(7);
      await cambio;
      pendientes[1]!.complete(3);
      await inicio;

      expect(estado(c).codEmpresa, 5);
      expect(estado(c).codSucursal, 7);
      expect(estado(c).iniciado, isTrue);
      expect(repo.filtros.every((f) => f.codSucursal == 7), isTrue);
    });

    test('elegir sucursal a mano gana a la inicial de la empresa que aun viaja', () async {
      final c = crear();
      await grilla(c).iniciar();
      final espera = Completer<int>();
      repo.alObtenerSucursalInicial = (_) => espera.future;

      final cambio = grilla(c).elegirEmpresa(5);
      await grilla(c).elegirSucursal(8);
      espera.complete(7);
      await cambio;

      expect(estado(c).codEmpresa, 5);
      expect(estado(c).codSucursal, 8);
    });

    test('si falla la lista de empresas, el error queda y se puede reintentar', () async {
      repo.errorEmpresas = Exception('Sin conexión.');
      final c = crear();
      c.listen(empresaChequeActivaProvider, (_, __) {});
      await grilla(c).iniciar();

      expect(estado(c).error, 'Sin conexión.');
      expect(estado(c).iniciado, isFalse);
      expect(estado(c).cargando, isFalse);
      expect(activa(c), isNull);
      // Sin empresa no se pidio ninguna sucursal.
      expect(repo.contar('obtenerSucursalInicial'), 0);

      repo.errorEmpresas = null;
      await grilla(c).iniciar();

      expect(estado(c).error, isNull);
      expect(estado(c).iniciado, isTrue);
      expect(estado(c).codEmpresa, 1);
      expect(estado(c).codSucursal, 3);
      expect(repo.contar('listarEmpresas'), 2);
      expect(activa(c)!.codEmpresa, 1);
    });

    test('una lista de empresas vacia es un error, no una pantalla muda', () async {
      repo.empresas = const [];
      final c = crear();
      await grilla(c).iniciar();
      expect(estado(c).error, 'No hay empresas disponibles para cheques.');
      expect(estado(c).iniciado, isFalse);
    });

    test('si falla la sucursal de la empresa nueva, reintentar pide la de ESA empresa', () async {
      final c = crear();
      await grilla(c).iniciar();
      repo.errorSucursalInicial = Exception('Sin conexión.');

      await grilla(c).elegirEmpresa(5);

      expect(estado(c).error, 'Sin conexión.');
      expect(estado(c).iniciado, isFalse);
      expect(estado(c).codEmpresa, 5);
      expect(estado(c).resultado, isNull);

      repo.errorSucursalInicial = null;
      await grilla(c).iniciar();

      expect(repo.empresasDeSucursalInicial, [1, 5, 5]);
      expect(estado(c).error, isNull);
      expect(estado(c).codEmpresa, 5);
      expect(estado(c).codSucursal, 7);
      expect(estado(c).filas, isEmpty);
    });

    test('la empresa elegida no sobrevive a salir de la pantalla', () async {
      final c = crear(grilla: false);
      final sub = c.listen(grillaChequesProvider, (_, __) {});
      await grilla(c).iniciar();
      await grilla(c).elegirEmpresa(5);
      expect(estado(c).codEmpresa, 5);

      sub.close();
      await Future<void>.delayed(Duration.zero);
      c.listen(grillaChequesProvider, (_, __) {});
      expect(estado(c).codEmpresa, 0);
      await grilla(c).iniciar();
      expect(estado(c).codEmpresa, 1);
    });

    test('ninguna lectura pide la empresa 0 ni la del login', () async {
      final c = crear();
      c.listen(sucursalesChequeActivasProvider, (_, __) {});
      await grilla(c).iniciar();
      await grilla(c).elegirEmpresa(5);
      await c.read(sucursalesChequeProvider(5).future);
      expect(repo.empresasDeSucursalInicial.every((e) => e > 0), isTrue);
      expect(repo.empresasDeSucursales.every((e) => e > 0), isTrue);
    });
  });

  group('grilla: paginas, filtros y orden', () {
    test('siguiente y anterior piden la pagina correcta', () async {
      final c = crear();
      await grilla(c).iniciar();

      await grilla(c).siguiente();
      expect(estado(c).pagina, 2);
      expect(estado(c).filas, hasLength(20));
      expect(repo.filtros.last.pagina, 2);

      await grilla(c).siguiente();
      expect(estado(c).pagina, 3);
      expect(estado(c).filas, hasLength(5));
      expect(estado(c).haySiguiente, isFalse);

      // En la ultima, «siguiente» no pide nada.
      final antes = repo.contar('listar');
      await grilla(c).siguiente();
      expect(repo.contar('listar'), antes);

      await grilla(c).anterior();
      expect(estado(c).pagina, 2);
    });

    test('anterior en la primera pagina no pide nada', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).anterior();
      expect(repo.contar('listar'), 1);
    });

    test('irAPagina ignora una pagina fuera de rango o la actual', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).irAPagina(0);
      await grilla(c).irAPagina(-3);
      await grilla(c).irAPagina(4);
      await grilla(c).irAPagina(1);
      expect(repo.contar('listar'), 1);

      await grilla(c).irAPagina(3);
      expect(estado(c).pagina, 3);
    });

    test('aplicar criterios vuelve a la pagina 1 y manda el filtro', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).irAPagina(2);

      await grilla(c).aplicarCriterios(nroCheque: '100007', estado: 'PEN');

      final f = repo.filtros.last;
      expect(f.codSucursal, 3);
      expect(f.nroCheque, '100007');
      expect(f.estado, 'PEN');
      expect(f.pagina, 1);
      expect(estado(c).pagina, 1);
      expect(estado(c).total, 1);
      expect(estado(c).filas.single.cheque.nrocheque, '100007');
    });

    test('aplicar criterios reemplaza los anteriores, no los suma', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).aplicarCriterios(nroCheque: '100007');
      await grilla(c).aplicarCriterios(estado: 'CER');

      final f = repo.filtros.last;
      expect(f.nroCheque, isNull);
      expect(f.estado, 'CER');
      // Y los mensajes en blanco no cuentan como criterio.
      await grilla(c).aplicarCriterios(nroCheque: '   ');
      expect(repo.filtros.last.sinCriterios, isTrue);
    });

    test(
      'limpiar criterios deja la sucursal, quita los criterios y vuelve al '
      'rango por defecto',
      () async {
        final c = crear();
        await grilla(c).iniciar();
        await grilla(c).aplicarCriterios(
          nroCheque: '100007',
          fechaRecepcionDesde: DateTime(2026, 1, 1),
        );
        expect(estado(c).total, 1);

        await grilla(c).limpiarCriterios();
        final f = repo.filtros.last;
        expect(f.tieneCriteriosSalvoRecepcion, isFalse);
        expect(f.fechaRecepcionDesde, DateTime(2026, 7, 3));
        expect(f.fechaRecepcionHasta, DateTime(2026, 10, 3));
        expect(f.codSucursal, 3);
        expect(f.pagina, 1);
        expect(estado(c).total, 45);
      },
    );

    test('cambiar el orden pide COBRO desde la pagina 1', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).irAPagina(2);

      await grilla(c).cambiarOrden(OrdenCheques.cobro);

      expect(repo.filtros.last.orden, OrdenCheques.cobro);
      expect(repo.filtros.last.pagina, 1);
      // Mismo orden: no vuelve a pedir.
      final antes = repo.contar('listar');
      await grilla(c).cambiarOrden(OrdenCheques.cobro);
      expect(repo.contar('listar'), antes);
    });

    test(
      'elegir otra sucursal vuelve a la pagina 1, conserva los criterios y suelta las filas',
      () async {
        repo.cheques = [
          ...repo.cheques,
          for (var i = 100; i < 103; i++) chequeFalso(i, codSucursal: 4),
        ];
        final c = crear();
        await grilla(c).iniciar();
        await grilla(c).aplicarCriterios(estado: 'PEN');
        await grilla(c).irAPagina(2);

        final pendiente = grilla(c).elegirSucursal(4);
        // Mientras carga no quedan a la vista cheques de la otra sucursal.
        expect(estado(c).resultado, isNull);
        expect(estado(c).cargando, isTrue);
        await pendiente;

        expect(estado(c).codSucursal, 4);
        expect(estado(c).pagina, 1);
        expect(repo.filtros.last.estado, 'PEN');
        expect(estado(c).total, 3);
      },
    );

    test('elegir la sucursal 0 no consulta y limpia', () async {
      final c = crear();
      await grilla(c).iniciar();
      final antes = repo.contar('listar');
      await grilla(c).elegirSucursal(0);
      expect(repo.contar('listar'), antes);
      expect(estado(c).resultado, isNull);
      expect(estado(c).haySucursal, isFalse);
    });

    test('recargar relee la misma pagina con los mismos filtros', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).aplicarCriterios(estado: 'PEN');
      await grilla(c).irAPagina(2);
      await grilla(c).recargar();

      expect(repo.filtros.last.pagina, 2);
      expect(repo.filtros.last.estado, 'PEN');
      expect(estado(c).pagina, 2);
    });

    test('sin resultados es un estado vacio, no un error', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).aplicarCriterios(nroCheque: 'no-existe');

      final e = estado(c);
      expect(e.sinResultados, isTrue);
      expect(e.error, isNull);
      expect(e.filas, isEmpty);
      expect(e.total, 0);
    });
  });

  group('grilla: errores y respuestas cruzadas', () {
    test(
      'el mensaje del backend llega al estado tal cual y no se disfraza de lista vacia',
      () async {
        repo.errorListar = Exception(
          'No tiene permisos para modificar datos de otras sucursales',
        );
        final c = crear();
        await grilla(c).iniciar();

        final e = estado(c);
        expect(
          e.error,
          'No tiene permisos para modificar datos de otras sucursales',
        );
        expect(e.cargando, isFalse);
        expect(e.resultado, isNull);
        expect(e.sinResultados, isFalse);
      },
    );

    test('un error se limpia con la consulta siguiente', () async {
      repo.errorListar = Exception('Falla.');
      final c = crear();
      await grilla(c).iniciar();
      expect(estado(c).error, isNotNull);

      repo.errorListar = null;
      await grilla(c).recargar();
      expect(estado(c).error, isNull);
      expect(estado(c).filas, isNotEmpty);
    });

    test('una respuesta vieja no pisa a la nueva', () async {
      final respuestas = <Completer<ChequePaginaEntity>>[];
      repo.alListar = (f) {
        final c = Completer<ChequePaginaEntity>();
        respuestas.add(c);
        return c.future;
      };
      final c = crear();
      final a = grilla(c).elegirSucursal(3); // consulta 1
      final b = grilla(c).aplicarCriterios(nroCheque: '100005'); // consulta 2

      // La segunda responde primero y la primera, que es vieja, despues.
      respuestas[1].complete(
        ChequePaginaEntity(
          total: 1,
          pagina: 1,
          tamanio: 20,
          filas: [chequeFalso(5)],
        ),
      );
      await b;
      expect(estado(c).filas.single.cheque.nrocheque, '100005');

      respuestas[0].complete(
        ChequePaginaEntity(
          total: 45,
          pagina: 1,
          tamanio: 20,
          filas: [for (var i = 1; i <= 20; i++) chequeFalso(i)],
        ),
      );
      await a;

      expect(estado(c).total, 1);
      expect(estado(c).filas, hasLength(1));
      expect(estado(c).cargando, isFalse);
    });

    test('un error viejo tampoco pisa a la respuesta nueva', () async {
      final respuestas = <Completer<ChequePaginaEntity>>[];
      repo.alListar = (f) {
        final c = Completer<ChequePaginaEntity>();
        respuestas.add(c);
        return c.future;
      };
      final c = crear();
      final a = grilla(c).elegirSucursal(3);
      final b = grilla(c).recargar();

      respuestas[1].complete(
        ChequePaginaEntity(
          total: 1,
          pagina: 1,
          tamanio: 20,
          filas: [chequeFalso(9)],
        ),
      );
      await b;
      respuestas[0].completeError(Exception('Tardo y fallo.'));
      await a;

      expect(estado(c).error, isNull);
      expect(estado(c).filas, hasLength(1));
    });

    test('si la pagina pedida ya no existe, retrocede a la ultima', () async {
      var total = 45;
      repo.alListar = (f) async {
        final desde = (f.pagina - 1) * f.tamanio;
        final cuantas = (total - desde).clamp(0, f.tamanio);
        return ChequePaginaEntity(
          total: total,
          pagina: f.pagina,
          tamanio: f.tamanio,
          filas: [for (var i = 0; i < cuantas; i++) chequeFalso(desde + i + 1)],
        );
      };
      final c = crear();
      await grilla(c).elegirSucursal(3);
      await grilla(c).irAPagina(3);
      expect(estado(c).pagina, 3);

      // Entre tanto se borraron cheques: ya solo hay dos paginas.
      total = 25;
      await grilla(c).recargar();

      expect(estado(c).pagina, 2);
      expect(estado(c).filas, hasLength(5));
      expect(estado(c).error, isNull);
    });

    test(
      'si ya no queda ningun cheque, vuelve a la pagina 1 y queda vacia',
      () async {
        var vacio = false;
        repo.alListar =
            (f) async => ChequePaginaEntity(
              total: vacio ? 0 : 45,
              pagina: f.pagina,
              tamanio: f.tamanio,
              filas: vacio ? const [] : [chequeFalso(1)],
            );
        final c = crear();
        await grilla(c).elegirSucursal(3);
        await grilla(c).irAPagina(2);
        vacio = true;
        await grilla(c).recargar();

        expect(estado(c).pagina, 1);
        expect(estado(c).sinResultados, isTrue);
      },
    );
  });

  group('escrituras', () {
    ChequeRegistroEntity alta() => ChequeRegistroEntity(
      codCheque: BigInt.zero,
      nrocheque: '000123',
      codCliente: 'ADI0229',
      aOrdenDe: 'BOSQUE S.A.',
      fechaCheque: DateTime(2026, 8, 31),
      fechaCobrar: DateTime(2026, 8, 31),
      monto: 1500.5,
      moneda: 'BS',
      tipo: 'PAG',
      codBanco: 7,
      codEmpleado: 0,
      reciboManual: '0',
      codSucursal: 3,
      nroTalonario: '0',
      codEmpresa: 1,
      observacion: 'Recibido en caja',
    );

    test(
      'registrar devuelve el codCheque y el cuerpo no lleva el usuario de auditoria',
      () async {
        final c = crear();
        final id = await ops(c).registrar(alta());

        expect(id, BigInt.from(9001));
        final cuerpo = repo.ultimoCuerpo('registrar');
        expect(cuerpo.containsKey('audUsuario'), isFalse);
        expect(cuerpo.containsKey('audFecha'), isFalse);
        expect(cuerpo.containsKey('estado'), isFalse);
        expect(cuerpo.containsKey('nroRecibo'), isFalse);
        expect(cuerpo['fechaCheque'], '2026-08-31');
        expect(cuerpo['modo'], 'ESTANDAR');
        expect(estadoOps(c).ocupado, isFalse);
        expect(estadoOps(c).error, isNull);
      },
    );

    test('ninguna escritura manda audUsuario', () async {
      final c = crear();
      await ops(c).registrar(alta());
      await ops(c).devolver(AccionChequeRequestEntity(codCheque: BigInt.one));
      await ops(c).cerrar(
        AccionChequeRequestEntity(
          codCheque: BigInt.one,
          estado: 'COB',
          nroSap: 'SAP-1',
          conVerificacion: true,
        ),
      );
      await ops(c).cambiarFechaCobro(
        AccionChequeRequestEntity(
          codCheque: BigInt.one,
          estado: 'VEN',
          nuevaFechaCobro: DateTime(2026, 9, 30),
        ),
      );
      await ops(c).entregarEnCustodia(
        CustodiaChequeRequestEntity(
          codSucursal: 3,
          codEmpleado: 12,
          codCheques: [BigInt.one],
        ),
      );
      expect(repo.cuerpos, hasLength(5));
      for (final enviado in repo.cuerpos) {
        expect(
          enviado.cuerpo.containsKey('audUsuario'),
          isFalse,
          reason: enviado.metodo,
        );
      }
    });

    test('el error de negocio llega tal cual, con sus saltos de linea', () async {
      const mensaje =
          'El Nro del Cheque es obligatorio\nLa fecha de cobro esta fuera de rango';
      repo.errorEscritura = Exception(mensaje);
      final c = crear();

      final id = await ops(c).registrar(alta());

      expect(id, isNull);
      expect(estadoOps(c).error, mensaje);
      expect(estadoOps(c).ocupado, isFalse);
    });

    test(
      'un error no se vuelve «problema del sistema» aunque diga «es obligatorio»',
      () async {
        repo.errorEscritura = Exception('El Nombre es obligatorio');
        final c = crear();
        await ops(c).registrar(alta());
        expect(estadoOps(c).error, 'El Nombre es obligatorio');
      },
    );

    test('limpiarError borra el mensaje', () async {
      repo.errorEscritura = Exception('Falla.');
      final c = crear();
      await ops(c).registrar(alta());
      expect(estadoOps(c).error, isNotNull);
      ops(c).limpiarError();
      expect(estadoOps(c).error, isNull);
    });

    test(
      'el error de una escritura se borra al intentar la siguiente',
      () async {
        repo.errorEscritura = Exception('Falla.');
        final c = crear();
        await ops(c).registrar(alta());
        repo.errorEscritura = null;
        await ops(c).registrar(alta());
        expect(estadoOps(c).error, isNull);
      },
    );

    test('una sola escritura a la vez: la segunda se ignora', () async {
      final libre = Completer<void>();
      repo.esperaEscritura = libre.future;
      final c = crear();

      final primera = ops(c).registrar(alta());
      await Future<void>.delayed(Duration.zero);
      expect(estadoOps(c).ocupado, isTrue);

      final segunda = await ops(c).registrar(alta());
      expect(segunda, isNull);
      expect(repo.contar('registrar'), 1);

      libre.complete();
      expect(await primera, BigInt.from(9001));
      expect(estadoOps(c).ocupado, isFalse);
    });

    test('al guardar bien se relee la grilla, en la misma pagina', () async {
      final c = crear();
      await grilla(c).iniciar();
      await grilla(c).irAPagina(2);
      final antes = repo.contar('listar');

      await ops(c).registrar(alta());
      await Future<void>.delayed(Duration.zero);

      expect(repo.contar('listar'), antes + 1);
      expect(repo.filtros.last.pagina, 2);
    });

    test('si fallo, la grilla no se relee', () async {
      repo.errorEscritura = Exception('Falla.');
      final c = crear();
      await grilla(c).iniciar();
      final antes = repo.contar('listar');

      await ops(c).registrar(alta());
      await Future<void>.delayed(Duration.zero);

      expect(repo.contar('listar'), antes);
    });

    test('sin pantalla de grilla abierta, escribir no la crea', () async {
      final c = crear(grilla: false);
      await ops(c).registrar(alta());
      expect(c.exists(grillaChequesProvider), isFalse);
      expect(repo.contar('listar'), 0);
    });

    test(
      'al escribir se invalida el detalle abierto para releer los botones',
      () async {
        final c = crear();
        c.listen(detalleChequeProvider(BigInt.one), (_, __) {});
        await c.read(detalleChequeProvider(BigInt.one).future);
        expect(repo.contar('obtenerDetalle'), 1);

        await ops(c).devolver(AccionChequeRequestEntity(codCheque: BigInt.one));
        await c.read(detalleChequeProvider(BigInt.one).future);

        expect(repo.contar('obtenerDetalle'), 2);
      },
    );

    test(
      'traspasar devuelve cuantos y eliminarAccion devuelve el codigo',
      () async {
        repo.traspasados = 7;
        final c = crear();
        expect(await ops(c).traspasar(3), 7);
        expect(repo.ultimoCuerpo('traspasar'), {'id': 3});
        expect(await ops(c).eliminarAccion(BigInt.from(88)), BigInt.from(88));
        expect(repo.ultimoCuerpo('eliminarAccion'), {'id': 88});
      },
    );

    test(
      'traspasar, entregar en custodia y dar custodia relean la grilla y las listas de apoyo',
      () async {
        final c = crear();
        await grilla(c).iniciar();
        final dia = DateTime(2026, 9, 1);
        // Las listas estan en pantalla: tienen oyente y se releen al invalidarlas.
        c.listen(traspasosPendientesChequesProvider(3), (_, __) {});
        c.listen(chequesParaCustodiaProvider(3), (_, __) {});
        c.listen(chequesParaDarCustodiaProvider(3), (_, __) {});
        c.listen(
          entregasDelDiaChequeProvider((codSucursal: 3, fecha: dia)),
          (_, __) {},
        );

        Future<void> leerTodo() async {
          await c.read(traspasosPendientesChequesProvider(3).future);
          await c.read(chequesParaCustodiaProvider(3).future);
          await c.read(chequesParaDarCustodiaProvider(3).future);
          await c.read(
            entregasDelDiaChequeProvider((codSucursal: 3, fecha: dia)).future,
          );
        }

        await leerTodo();
        final base = repo.contar('listar');
        expect(repo.contar('contarTraspasosPendientes'), 1);

        // Cada escritura buena relee la grilla y las cuatro listas.
        await ops(c).traspasar(3);
        await leerTodo();
        expect(repo.contar('listar'), base + 1);
        expect(repo.contar('contarTraspasosPendientes'), 2);
        expect(repo.contar('listarChequesParaCustodia'), 2);
        expect(repo.contar('listarChequesParaDarCustodia'), 2);
        expect(repo.contar('listarEntregasDelDia'), 2);

        await ops(c).entregarEnCustodia(
          CustodiaChequeRequestEntity(
            codSucursal: 3,
            codEmpleado: 12,
            codCheques: [BigInt.one],
          ),
        );
        await leerTodo();
        expect(repo.contar('listar'), base + 2);
        expect(repo.contar('contarTraspasosPendientes'), 3);

        await ops(c).darCustodia(
          DarCustodiaRequestEntity(
            codSucursal: 3,
            codAccionOrigen: BigInt.from(88),
            codCheque: BigInt.one,
          ),
        );
        await leerTodo();
        expect(repo.contar('listar'), base + 3);
        expect(repo.contar('contarTraspasosPendientes'), 4);

        // Una escritura rechazada no relee nada.
        repo.errorEscritura = Exception('Falla.');
        await ops(c).traspasar(3);
        await leerTodo();
        expect(repo.contar('listar'), base + 3);
        expect(repo.contar('contarTraspasosPendientes'), 4);
      },
    );

    test('un traspaso sin cheques llega como error de negocio', () async {
      repo.errorEscritura = Exception('No hay cheques para traspasar.');
      final c = crear();
      expect(await ops(c).traspasar(3), isNull);
      expect(estadoOps(c).error, 'No hay cheques para traspasar.');
    });
  });

  group('mensajeDeErrorCheque', () {
    test('quita el prefijo Exception y conserva el texto', () {
      expect(mensajeDeErrorCheque(Exception('Hola')), 'Hola');
      expect(mensajeDeErrorCheque(Exception('Exception: Hola')), 'Hola');
      expect(mensajeDeErrorCheque('Texto suelto'), 'Texto suelto');
    });

    test('conserva los saltos de linea', () {
      expect(mensajeDeErrorCheque(Exception('a\nb\nc')), 'a\nb\nc');
    });

    test('un mensaje vacio da un aviso generico', () {
      expect(
        mensajeDeErrorCheque(Exception('')),
        'No se pudo completar la operación.',
      );
    });

    test('un corte de red se traduce al aviso de conexion', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/cheque/listar'),
        type: DioExceptionType.connectionError,
      );
      expect(
        mensajeDeErrorCheque(e),
        'No se pudo conectar con el servidor. Revisa tu conexión a internet.',
      );
    });

    test('un 403 sin cuerpo dice que no tiene permisos', () {
      final o = RequestOptions(path: '/cheque/traspaso');
      final e = DioException(
        requestOptions: o,
        response: Response(requestOptions: o, statusCode: 403),
        type: DioExceptionType.badResponse,
      );
      expect(
        mensajeDeErrorCheque(e),
        'No tienes permisos para realizar esta acción.',
      );
    });

    test(
      'un error de lectura llega al estado de la grilla con ese aviso',
      () async {
        repo.errorListar = DioException(
          requestOptions: RequestOptions(path: '/cheque/listar'),
          type: DioExceptionType.connectionError,
        );
        final c = crear();
        await grilla(c).iniciar();
        expect(
          estado(c).error,
          'No se pudo conectar con el servidor. Revisa tu conexión a internet.',
        );
      },
    );
  });

  group('lecturas de apoyo', () {
    test('los catalogos se piden una sola vez', () async {
      final c = crear(grilla: false);
      c.listen(catalogosChequeProvider, (_, __) {});
      await c.read(catalogosChequeProvider.future);
      await c.read(catalogosChequeProvider.future);
      expect(repo.contar('obtenerCatalogos'), 1);
      final cat = await c.read(catalogosChequeProvider.future);
      expect(cat.estadosCheque.map((o) => o.codigo), ['PEN', 'CER']);
    });

    test('el detalle trae los botones del backend', () async {
      repo.botones = const BotonesChequeEntity(
        fechaCobro: false,
        devolver: true,
        cerrarConVerificacion: false,
        cerrarSinVerificacion: true,
        codigo: '0101',
      );
      final c = crear(grilla: false);
      final d = await c.read(detalleChequeProvider(BigInt.from(12)).future);
      expect(d!.botones.codigo, '0101');
      expect(d.acciones, hasLength(3));
      expect(d.cheque.codCheque, BigInt.from(12));
    });

    test('la sucursal de trabajo se lee de la grilla', () async {
      final c = crear();
      c.listen(sucursalChequeProvider, (_, __) {});
      expect(c.read(sucursalChequeProvider), 0);
      await grilla(c).iniciar();
      expect(c.read(sucursalChequeProvider), 3);
    });
  });

  group('permisosChequeProvider (cableado con usuario y botones)', () {
    LoginEntity login(String tipo) => LoginEntity.fromJson(<String, dynamic>{
      'tipoUsuario': tipo,
      'codUsuario': 7,
    });

    UsuarioBtnEntity btn(String nombre, int permiso) => UsuarioBtnEntity(
      codUsuario: 7,
      codBtn: 1,
      nivelAcceso: permiso,
      audUsuario: 1,
      boton: nombre,
      permiso: permiso,
      pertenVist: 42,
    );

    ProviderContainer conUsuario(
      LoginEntity? user,
      AsyncValue<List<UsuarioBtnEntity>> botones,
    ) {
      final c = ProviderContainer(
        overrides: [
          userProvider.overrideWith(
            (ref) => UserStateNotifier.sinStorage(user),
          ),
          buttonPermissionsProvider.overrideWith(
            (ref) => _BotonesFalsos(ref, botones),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sin sesion no hay nada', () {
      final c = conUsuario(null, const AsyncValue.data([]));
      expect(c.read(permisosChequeProvider), PermisosCheque.ninguno);
    });

    test('un usuario comun recibe sus botones con permiso distinto de 0', () {
      final c = conUsuario(
        login('ROLE_LIM'),
        AsyncValue.data([btn('btnNuevoCH', 1), btn('btnTraspasoCH', 0)]),
      );
      final p = c.read(permisosChequeProvider);
      expect(p.esAdmin, isFalse);
      expect(p.puedeRegistrar, isTrue);
      expect(p.puedeTraspasar, isFalse);
      expect(p.puedeEditar('PEN'), isFalse);
    });

    test('el administrador pasa aunque los botones sigan cargando', () {
      final c = conUsuario(login('ROLE_ADM'), const AsyncValue.loading());
      final p = c.read(permisosChequeProvider);
      expect(p.esAdmin, isTrue);
      expect(p.puedeEditar('CER'), isTrue);
    });

    test('un usuario comun no tiene nada mientras cargan los botones', () {
      final c = conUsuario(login('ROLE_LIM'), const AsyncValue.loading());
      final p = c.read(permisosChequeProvider);
      expect(p.botones, isEmpty);
      expect(p.puedeRegistrar, isFalse);
    });
  });

  test(
    'las sucursales se vuelven a pedir cuando cambia el usuario de la sesion '
    '(p_list_Sucursal C acota a algunos usuarios a una sola)',
    () async {
      LoginEntity usuario(int cod) => LoginEntity.fromJson(<String, dynamic>{
        'tipoUsuario': 'ROLE_LIM',
        'codUsuario': cod,
      });
      final c = ProviderContainer(
        overrides: [
          chequesRepositoryProvider.overrideWithValue(repo),
          userProvider.overrideWith(
            (ref) => _UsuarioCambiante(usuario(7)),
          ),
        ],
      );
      addTearDown(c.dispose);

      await c.read(sucursalesChequeProvider(1).future);
      await c.read(sucursalesChequeProvider(1).future);
      expect(repo.empresasDeSucursales, [1], reason: 'mismo usuario: una sola lectura');

      (c.read(userProvider.notifier) as _UsuarioCambiante).cambiar(usuario(30));
      await c.read(sucursalesChequeProvider(1).future);
      expect(repo.empresasDeSucursales, [1, 1], reason: 'otro usuario: vuelve a pedirlas');
    },
  );
}

/// Un usuario de sesion al que la prueba puede cambiar sin tocar el almacenamiento.
class _UsuarioCambiante extends UserStateNotifier {
  _UsuarioCambiante(super.inicial) : super.sinStorage();

  void cambiar(LoginEntity? otro) => state = otro;
}

/// Un repositorio cuya lista de empresas tarda hasta que [_espera] termine.
class _ListaDemorada extends RepositorioChequesFalso {
  _ListaDemorada(this._espera);

  final Future<void> _espera;

  @override
  Future<List<EmpresaChequeEntity>> listarEmpresas() async {
    await _espera;
    return super.listarEmpresas();
  }
}

/// Un repositorio que delega en [_base] pero puede demorar la consulta de la
/// sucursal inicial.
class _Demorado extends RepositorioChequesFalso {
  _Demorado(this._base, this._demora);

  final RepositorioChequesFalso _base;
  final Future<void>? Function() _demora;

  @override
  Future<int> obtenerSucursalInicial({int codEmpresa = 0}) async {
    final d = _demora();
    if (d != null) await d;
    return _base.obtenerSucursalInicial(codEmpresa: codEmpresa);
  }

  @override
  Future<ChequePaginaEntity> listar(ChequeFiltroEntity filtro) =>
      _base.listar(filtro);
}

/// Los botones que se le digan, sin pasar por la red.
class _BotonesFalsos extends ButtonPermissionsNotifier {
  _BotonesFalsos(Ref ref, AsyncValue<List<UsuarioBtnEntity>> inicial)
    : super(ref, UserStateNotifier.sinStorage(null), null) {
    state = inicial;
  }
}
