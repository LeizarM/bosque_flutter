import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/state/button_permissions_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/models/banco_registro_model.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/usuarioBtn_entity.dart';
import 'package:bosque_flutter/domain/repositories/bancos_repository.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';

/// Escritura de bancos: el estado de «guardando», el error del backend y que la
/// lista de bancos (que vive en el registro de empleados) se relea al guardar.
void main() {
  // El cliente HTTP lee dotenv al armarse; solo lo arma el cableado de permisos.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  late _BancosFalso repo;
  late int lecturas;
  late int lecturasPlanilla;
  late ProviderContainer c;

  setUp(() {
    repo = _BancosFalso();
    lecturas = 0;
    lecturasPlanilla = 0;
    c = ProviderContainer(
      overrides: [
        bancosRepositoryProvider.overrideWithValue(repo),
        // Las lecturas reales llaman al backend: se cuentan en su lugar.
        obtenerBancos.overrideWith((ref) async {
          lecturas++;
          return <BancoEntity>[];
        }),
        obtenerBancosPlanilla.overrideWith((ref) async {
          lecturasPlanilla++;
          return <BancoEntity>[];
        }),
      ],
    );
    addTearDown(c.dispose);
    // Las dos listas ya estan en pantalla: tienen oyente y se releen al
    // invalidarlas.
    c.listen(obtenerBancos, (_, __) {});
    c.listen(obtenerBancosPlanilla, (_, __) {});
  });

  OperacionesBancosNotifier ops() => c.read(operacionesBancosProvider.notifier);
  EstadoOperacionBanco estado() => c.read(operacionesBancosProvider);

  test(
    'registrar devuelve el codBanco y manda solo codBanco y nombre',
    () async {
      final id = await ops().registrar(
        const BancoRegistroEntity(codBanco: 0, nombre: ' BANCO NUEVO '),
      );

      expect(id, BigInt.from(15));
      expect(repo.cuerpos.single, {'codBanco': 0, 'nombre': 'BANCO NUEVO'});
      expect(estado().ocupado, isFalse);
      expect(estado().error, isNull);
    },
  );

  test(
    'al guardar bien se relee la lista de bancos y la de planilla',
    () async {
      await c.read(obtenerBancos.future);
      await c.read(obtenerBancosPlanilla.future);
      expect(lecturas, 1);
      expect(lecturasPlanilla, 1);

      await ops().registrar(
        const BancoRegistroEntity(codBanco: 3, nombre: 'BANCO UNION'),
      );
      await c.read(obtenerBancos.future);
      await c.read(obtenerBancosPlanilla.future);

      expect(lecturas, 2);
      expect(lecturasPlanilla, 2);
    },
  );

  test('eliminar manda el codigo y tambien relee la lista', () async {
    await c.read(obtenerBancos.future);

    final id = await ops().eliminar(5);
    await c.read(obtenerBancos.future);

    expect(id, BigInt.from(5));
    expect(repo.llamadas, ['eliminar:5']);
    expect(lecturas, 2);
  });

  test(
    'un banco en uso: el mensaje del backend llega tal cual y la lista no se relee',
    () async {
      repo.error = Exception(
        'El banco tiene Depositos o Pagos al Exterior y no se puede eliminar.',
      );
      await c.read(obtenerBancos.future);

      final id = await ops().eliminar(5);
      await c.read(obtenerBancos.future);

      expect(id, isNull);
      expect(
        estado().error,
        'El banco tiene Depositos o Pagos al Exterior y no se puede eliminar.',
      );
      expect(estado().ocupado, isFalse);
      expect(lecturas, 1);
    },
  );

  test(
    'un nombre invalido llega como error de negocio, sin disfrazarlo',
    () async {
      repo.error = Exception(
        'El Nombre del Banco solo puede tener letras, numeros, espacios, - y / '
        '( entre 3 y 50 caracteres )',
      );
      await ops().registrar(
        const BancoRegistroEntity(codBanco: 0, nombre: '#'),
      );
      expect(
        estado().error,
        startsWith('El Nombre del Banco solo puede tener'),
      );
    },
  );

  test('limpiarError borra el mensaje', () async {
    repo.error = Exception('Falla.');
    await ops().eliminar(1);
    expect(estado().error, isNotNull);
    ops().limpiarError();
    expect(estado().error, isNull);
  });

  test('una sola escritura a la vez', () async {
    final libre = Completer<void>();
    repo.espera = libre.future;

    final primera = ops().eliminar(1);
    await Future<void>.delayed(Duration.zero);
    expect(estado().ocupado, isTrue);

    expect(await ops().eliminar(2), isNull);
    expect(repo.llamadas, ['eliminar:1']);

    libre.complete();
    expect(await primera, BigInt.one);
    expect(estado().ocupado, isFalse);
  });

  group('listaBancosProvider (la lectura de la pantalla)', () {
    BancoEntity banco(int cod, String nombre) =>
        BancoEntity(codBanco: cod, nombre: nombre, audUsuario: 1, fila: cod);

    test('lee los bancos del repositorio', () async {
      repo.bancos = [banco(7, 'BANCO UNION')];
      c.listen(listaBancosProvider, (_, __) {});

      final lista = await c.read(listaBancosProvider.future);

      expect(lista.single.nombre, 'BANCO UNION');
      expect(repo.lecturasDeLista, 1);
    });

    test('un fallo llega como error, no como lista vacia', () async {
      repo.errorLectura = Exception('No tiene permiso para esta accion.');
      c.listen(listaBancosProvider, (_, __) {});

      await expectLater(
        c.read(listaBancosProvider.future),
        throwsA(isA<Exception>()),
      );
      expect(c.read(listaBancosProvider).hasError, isTrue);
    });

    test('al guardar o eliminar bien se relee; si falla, no', () async {
      c.listen(listaBancosProvider, (_, __) {});
      await c.read(listaBancosProvider.future);
      expect(repo.lecturasDeLista, 1);

      await ops().registrar(
        const BancoRegistroEntity(codBanco: 0, nombre: 'BANCO NUEVO'),
      );
      await c.read(listaBancosProvider.future);
      expect(repo.lecturasDeLista, 2);

      await ops().eliminar(5);
      await c.read(listaBancosProvider.future);
      expect(repo.lecturasDeLista, 3);

      repo.error = Exception('Falla.');
      await ops().eliminar(5);
      await c.read(listaBancosProvider.future);
      expect(repo.lecturasDeLista, 3);
    });
  });

  group('permisosBancoProvider (cableado con usuario y botones)', () {
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
      pertenVist: 43,
    );

    ProviderContainer conUsuario(
      LoginEntity? user,
      AsyncValue<List<UsuarioBtnEntity>> botones,
    ) {
      final contenedor = ProviderContainer(
        overrides: [
          userProvider.overrideWith(
            (ref) => UserStateNotifier.sinStorage(user),
          ),
          buttonPermissionsProvider.overrideWith(
            (ref) => _BotonesFalsos(ref, botones),
          ),
        ],
      );
      addTearDown(contenedor.dispose);
      return contenedor;
    }

    test('sin sesion no hay nada', () {
      final p = conUsuario(null, const AsyncValue.data([]));
      expect(p.read(permisosBancoProvider), PermisosBanco.ninguno);
    });

    test('un usuario comun recibe sus botones con permiso distinto de 0', () {
      final p = conUsuario(
        login('ROLE_LIM'),
        AsyncValue.data([btn('btnNuevoB', 1), btn('btnEliminarB', 0)]),
      );
      final permisos = p.read(permisosBancoProvider);
      expect(permisos.esAdmin, isFalse);
      expect(permisos.puedeCrear, isTrue);
      expect(permisos.puedeEliminar, isFalse);
      expect(permisos.puedeEditar, isFalse);
    });

    test('el administrador pasa aunque los botones sigan cargando', () {
      final p = conUsuario(login('ROLE_ADM'), const AsyncValue.loading());
      final permisos = p.read(permisosBancoProvider);
      expect(permisos.esAdmin, isTrue);
      expect(permisos.puedeEliminar, isTrue);
    });

    test('un usuario comun no tiene nada mientras cargan los botones', () {
      final p = conUsuario(login('ROLE_LIM'), const AsyncValue.loading());
      expect(p.read(permisosBancoProvider).botones, isEmpty);
      expect(p.read(permisosBancoProvider).puedeCrear, isFalse);
    });
  });
}

/// Los botones que se le digan, sin pasar por la red.
class _BotonesFalsos extends ButtonPermissionsNotifier {
  _BotonesFalsos(Ref ref, AsyncValue<List<UsuarioBtnEntity>> inicial)
    : super(ref, UserStateNotifier.sinStorage(null), null) {
    state = inicial;
  }
}

class _BancosFalso implements BancosRepository {
  final List<String> llamadas = [];
  final List<Map<String, dynamic>> cuerpos = [];
  Object? error;
  Future<void>? espera;

  /// Lo que devuelve `listar` y cuantas veces se pidio.
  List<BancoEntity> bancos = const <BancoEntity>[];
  Object? errorLectura;
  int lecturasDeLista = 0;

  @override
  Future<List<BancoEntity>> listar() async {
    lecturasDeLista++;
    if (errorLectura != null) throw errorLectura!;
    return bancos;
  }

  @override
  Future<BigInt> registrar(BancoRegistroEntity registro) async {
    llamadas.add('registrar:${registro.codBanco}');
    cuerpos.add(BancoRegistroModel.fromEntity(registro).toJson());
    if (error != null) throw error!;
    return registro.esAlta ? BigInt.from(15) : BigInt.from(registro.codBanco);
  }

  @override
  Future<BigInt> eliminar(int codBanco) async {
    llamadas.add('eliminar:$codBanco');
    if (espera != null) await espera;
    if (error != null) throw error!;
    return BigInt.from(codBanco);
  }
}
