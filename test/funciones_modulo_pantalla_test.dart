// Funciones por módulo y Asignación de funciones: sin desbordes a
// 390/800/1400 px, filtros y el cambio de estado de una asignación.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/funciones_modulo_provider.dart';
import 'package:bosque_flutter/domain/entities/asignacion_funcion_entity.dart';
import 'package:bosque_flutter/domain/entities/funcion_modulo_entity.dart';
import 'package:bosque_flutter/domain/entities/opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/repositories/funciones_modulo_repository.dart';
import 'package:bosque_flutter/presentation/screens/funciones-modulo/funciones_modulo_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

const _modulos = [
  OpcionEntity(codigo: 41, nombre: 'Cheques'),
  OpcionEntity(codigo: 65, nombre: 'Cambio de Precios'),
];

final _funciones = [
  FuncionModuloEntity(codFuncMod: BigInt.one, codModulo: 41, modulo: 'Cheques', funcion: 'CAJERO', detalle: 'Recibe los cheques en caja y los registra en el sistema', requerido: true, asignaciones: 2),
  FuncionModuloEntity(codFuncMod: BigInt.two, codModulo: 41, modulo: 'Cheques', funcion: 'CHOFER', asignaciones: 37),
  FuncionModuloEntity(codFuncMod: BigInt.from(5), codModulo: 65, modulo: 'Cambio de Precios', funcion: 'AUTORIZADOR', activo: false),
];

class _Repo implements FuncionesModuloRepository {
  final escritas = <AsignacionFuncionEntity>[];
  final asignaciones = [
    AsignacionFuncionEntity(codAsignacion: BigInt.one, codFuncMod: 1, funcion: 'CAJERO', codModulo: 41, modulo: 'Cheques', codEmpleado: 10, empleado: 'PEREZ MAMANI JUAN CARLOS ALBERTO', codSucursal: 13, sucursal: 'Central', empresa: 'ESPPAPEL'),
    AsignacionFuncionEntity(codAsignacion: BigInt.two, codFuncMod: 2, funcion: 'CHOFER', codModulo: 41, modulo: 'Cheques', codEmpleado: 11, empleado: 'QUISPE ANA', codSucursal: 17, sucursal: 'Sucursal 12 Santa Cruz', empresa: 'ESPPAPEL', activo: false),
  ];

  ResultadoEscrituraEntity _ok(String m) =>
      ResultadoEscrituraEntity(id: BigInt.one, mensaje: m);

  @override
  Future<List<OpcionEntity>> modulos() async => _modulos;
  @override
  Future<List<FuncionModuloEntity>> listar() async => _funciones;
  Future<List<FuncionModuloEntity>> funciones() async => _funciones;
  Future<List<OpcionEntity>> sucursales() async => const [
    OpcionEntity(codigo: 13, nombre: 'Central', grupo: 'ESPPAPEL'),
    OpcionEntity(codigo: 17, nombre: 'Sucursal 12 Santa Cruz', grupo: 'ESPPAPEL'),
  ];
  Future<List<OpcionEntity>> empleados(int codSucursal) async => const [
    OpcionEntity(codigo: 10, nombre: 'PEREZ MAMANI JUAN CARLOS ALBERTO'),
  ];
  @override
  Future<ResultadoEscrituraEntity> registrar(Object x) async {
    if (x is AsignacionFuncionEntity) escritas.add(x);
    return _ok(x is AsignacionFuncionEntity && !x.activo ? 'Asignación desactivada.' : 'Hecho.');
  }

  @override
  Future<ResultadoEscrituraEntity> eliminar(BigInt codFuncMod) async => _ok('Eliminada.');

  // `listar` de asignaciones: mismo nombre que el de funciones en la otra
  // interfaz, así que se expone con un adaptador abajo.
  Future<List<AsignacionFuncionEntity>> listarAsignaciones() async => asignaciones;
}

/// Adaptador: la interfaz de asignaciones con su propio `listar`.
class _RepoAsignaciones implements AsignacionFuncionesRepository {
  _RepoAsignaciones(this.r);
  final _Repo r;
  @override
  Future<List<AsignacionFuncionEntity>> listar() => r.listarAsignaciones();
  @override
  Future<List<OpcionEntity>> modulos() => r.modulos();
  @override
  Future<List<FuncionModuloEntity>> funciones() => r.funciones();
  @override
  Future<List<OpcionEntity>> sucursales() => r.sucursales();
  @override
  Future<List<OpcionEntity>> empleados(int codSucursal) => r.empleados(codSucursal);
  @override
  Future<ResultadoEscrituraEntity> registrar(AsignacionFuncionEntity a) => r.registrar(a);
}

void main() {
  setUpAll(cargarRoboto);

  late _Repo repo;
  setUp(() => repo = _Repo());

  Widget app(Widget pantalla) => appCheques(
    hijo: pantalla,
    repo: RepositorioChequesFalso(total: 0),
    login: loginCheques(),
    extra: [
      funcionesModuloRepositoryProvider.overrideWithValue(repo),
      asignacionFuncionesRepositoryProvider.overrideWithValue(
        _RepoAsignaciones(repo),
      ),
    ],
  );

  for (final ancho in [390.0, 800.0, 1400.0]) {
    for (final escala in [1.0, 1.5]) {
      testWidgets(
        'las dos pantallas no desbordan a ${ancho.toInt()} px al ${(escala * 100).toInt()} %',
        (tester) async {
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(() async {
            await montar(tester, app(const FuncionesModuloScreen()), ancho: ancho);
            expect(find.textContaining('CAJERO'), findsWidgets);
            await montar(tester, app(const AsignacionFuncionesScreen()), ancho: ancho);
            expect(find.textContaining('PEREZ MAMANI'), findsOneWidget);
          });
          expect(errores, isEmpty, reason: 'a $ancho');
        },
      );
    }
  }

  testWidgets('las asignaciones arrancan filtradas en activas', (tester) async {
    await montar(tester, app(const AsignacionFuncionesScreen()));
    expect(find.textContaining('QUISPE ANA'), findsNothing);
    await tester.tap(find.text('Todas'));
    await esperar(tester);
    expect(find.textContaining('QUISPE ANA'), findsOneWidget);
  });

  testWidgets('desactivar manda el mismo código con estado inactivo', (
    tester,
  ) async {
    await montar(tester, app(const AsignacionFuncionesScreen()));
    await tester.tap(find.byTooltip('Desactivar'));
    await esperar(tester);
    final a = repo.escritas.single;
    expect(a.codAsignacion, BigInt.one);
    expect(a.activo, isFalse);
    expect(find.text('Asignación desactivada.'), findsOneWidget);
  });
}
