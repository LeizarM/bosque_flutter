// ABM de empresas y sucursales: sin desbordes en los dos niveles a
// 390/800/1400 px y tocar una empresa muestra solo sus sucursales.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/empresas_sucursales_provider.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:bosque_flutter/domain/repositories/empresas_sucursales_repository.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/empresas_sucursales_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

EmpresaEntity _empresa(int cod, String nombre) => EmpresaEntity(
  codEmpresa: cod,
  nombre: nombre,
  codPadre: 0,
  sigla: '',
  audUsuario: 0,
  sucursales: 2,
  cargos: 30,
);

SucursalEntity _sucursal(int cod, int emp, String nombre, String empresa) =>
    SucursalEntity(
      codSucursal: cod,
      nombre: nombre,
      codEmpresa: emp,
      codCiudad: 1,
      audUsuarioI: 0,
      empresa: _empresa(emp, empresa),
      nombreCiudad: 'LA PAZ',
      codSucursalPlanilla: 0,
      nombrePlanilla: '',
      nombreEmpresa: empresa,
      cargos: 4,
    );

class _Repo implements EmpresasSucursalesRepository {
  ResultadoEscrituraEntity _ok() =>
      ResultadoEscrituraEntity(id: BigInt.one, mensaje: 'Hecho.');

  @override
  Future<List<EmpresaEntity>> listarEmpresas() async => [
    _empresa(5, 'ESPPAPEL'),
    _empresa(8, 'PRODUCTIVA PAPEL'),
  ];
  @override
  Future<List<SucursalEntity>> listarSucursales() async => [
    _sucursal(13, 5, 'Central', 'ESPPAPEL'),
    _sucursal(30, 5, 'Sucursal 14 Galpón El Alto con un nombre bastante largo', 'ESPPAPEL'),
    _sucursal(40, 8, 'Planta Productiva', 'PRODUCTIVA PAPEL'),
  ];
  @override
  Future<List<CiudadEntity>> ciudades() async => [
    CiudadEntity(codCiudad: 1, codPais: 1, ciudad: 'LA PAZ', audUsuario: 0, pais: 'BOLIVIA'),
  ];
  @override
  Future<ResultadoEscrituraEntity> registrarEmpresa(EmpresaEntity e) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> registrarSucursal(SucursalEntity s) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> eliminarEmpresa(int c) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> eliminarSucursal(int c) async => _ok();
}

void main() {
  setUpAll(cargarRoboto);

  Widget app() => appCheques(
    hijo: const EmpresasSucursalesScreen(),
    repo: RepositorioChequesFalso(total: 0),
    login: loginCheques(tipo: 'ROLE_ADM'),
    extra: [empresasSucursalesRepositoryProvider.overrideWithValue(_Repo())],
  );

  for (final ancho in [390.0, 800.0, 1400.0]) {
    for (final escala in [1.0, 1.5]) {
      testWidgets(
        'los dos niveles no desbordan a ${ancho.toInt()} px al ${(escala * 100).toInt()} %',
        (tester) async {
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(() async {
            await montar(tester, app(), ancho: ancho);
            await tester.tap(find.widgetWithText(ChoiceChip, 'Sucursales'));
            await esperar(tester);
          });
          expect(errores, isEmpty, reason: 'a $ancho');
          // En 1400 px el ranking del panel también muestra la sucursal.
          expect(find.text('Planta Productiva'), findsWidgets);
        },
      );
    }
  }

  testWidgets('tocar una empresa muestra solo sus sucursales', (tester) async {
    await montar(tester, app());
    await tester.tap(find.byKey(const ValueKey('fila-empresa-8')));
    await esperar(tester);
    expect(find.byKey(const ValueKey('fila-sucursal-40')), findsOneWidget);
    expect(find.byKey(const ValueKey('fila-sucursal-13')), findsNothing);
  });
}
