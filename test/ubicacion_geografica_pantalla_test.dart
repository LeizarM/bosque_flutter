// Pantalla de Ubicación geográfica: sin desbordes en los tres niveles a
// 390/800/1400 px, y tocar un país lleva a sus ciudades ya filtradas.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/ubicacion_geografica_provider.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/domain/repositories/ubicacion_geografica_repository.dart';
import 'package:bosque_flutter/presentation/screens/ubicacion-geografica/ubicacion_geografica_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

class _RepoFalso implements UbicacionGeograficaRepository {
  final paises = [
    PaisEntity(codPais: 1, pais: 'BOLIVIA', audUsuario: 0, ciudades: 2, personas: 410),
    PaisEntity(codPais: 2, pais: 'REPUBLICA BOLIVARIANA DE VENEZUELA', audUsuario: 0, ciudades: 1),
  ];
  final ciudades = [
    CiudadEntity(codCiudad: 1, codPais: 1, ciudad: 'LA PAZ', audUsuario: 0, pais: 'BOLIVIA', zonas: 2, sucursales: 3),
    CiudadEntity(codCiudad: 2, codPais: 1, ciudad: 'SANTA CRUZ DE LA SIERRA', audUsuario: 0, pais: 'BOLIVIA'),
    CiudadEntity(codCiudad: 3, codPais: 2, ciudad: 'CARACAS', audUsuario: 0, pais: 'REPUBLICA BOLIVARIANA DE VENEZUELA'),
  ];
  final zonas = [
    ZonaEntity(codZona: 1, codCiudad: 1, zona: 'SOPOCACHI', audUsuario: 0, ciudad: 'LA PAZ', personas: 12),
    ZonaEntity(codZona: 2, codCiudad: 1, zona: 'ZONA SUR, CALACOTO Y ALREDEDORES DEL RIO', audUsuario: 0, ciudad: 'LA PAZ'),
  ];

  ResultadoEscrituraEntity _ok() =>
      ResultadoEscrituraEntity(id: BigInt.one, mensaje: 'Hecho.');

  @override
  Future<List<PaisEntity>> listarPaises() async => paises;
  @override
  Future<List<CiudadEntity>> listarCiudades() async => ciudades;
  @override
  Future<List<ZonaEntity>> listarZonas() async => zonas;
  @override
  Future<ResultadoEscrituraEntity> registrarPais(PaisEntity p) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> registrarCiudad(CiudadEntity c) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> registrarZona(ZonaEntity z) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> eliminarPais(int c) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> eliminarCiudad(int c) async => _ok();
  @override
  Future<ResultadoEscrituraEntity> eliminarZona(int c) async => _ok();
}

void main() {
  setUpAll(cargarRoboto);

  Widget app() => appCheques(
    hijo: const UbicacionGeograficaScreen(),
    repo: RepositorioChequesFalso(total: 0),
    login: loginCheques(tipo: 'ROLE_ADM'),
    extra: [ubicacionRepositoryProvider.overrideWithValue(_RepoFalso())],
  );

  for (final ancho in [390.0, 800.0, 1400.0]) {
    for (final escala in [1.0, 1.5]) {
      testWidgets(
        'los tres niveles no desbordan a ${ancho.toInt()} px al ${(escala * 100).toInt()} %',
        (tester) async {
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(() async {
            await montar(tester, app(), ancho: ancho);
            await tester.tap(find.widgetWithText(ChoiceChip, 'Ciudades'));
            await esperar(tester);
            await tester.tap(find.widgetWithText(ChoiceChip, 'Zonas'));
            await esperar(tester);
          });
          expect(errores, isEmpty, reason: 'a $ancho');
          // En 1400 px el ranking del panel también muestra la zona.
          expect(find.textContaining('SOPOCACHI'), findsWidgets);
        },
      );
    }
  }

  testWidgets('tocar un país muestra solo sus ciudades', (tester) async {
    await montar(tester, app());
    await tester.tap(find.byKey(const ValueKey('fila-pais-1')));
    await esperar(tester);
    expect(find.byKey(const ValueKey('fila-ciudad-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('fila-ciudad-3')), findsNothing);
    expect(find.textContaining('2 ciudades'), findsOneWidget);
  });
}
