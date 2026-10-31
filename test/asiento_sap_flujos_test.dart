import 'dart:io';

import 'package:bosque_flutter/core/state/asiento_sap_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/models/asiento_sap_model.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/asiento_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';
import 'package:bosque_flutter/domain/repositories/asiento_sap_repository.dart';
import 'package:bosque_flutter/presentation/screens/planillas/asiento_sap_config_screen.dart';
import 'package:bosque_flutter/presentation/widgets/planillas/planillas_asiento_sap_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Los eventos del asiento SAP de punta a punta, con un repositorio falso: guardar, probar,
/// agregar (eligiendo la conexión), quitar y enviar. Después de cada uno no puede quedar ninguna
/// excepción de Flutter (asserts, setState tras dispose, ref usado después de desmontar,
/// desbordes).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final cargador = FontLoader('Roboto');
    for (final peso in ['400', '500', '600', '700']) {
      final f = File('assets/fonts/PlusJakartaSans-$peso.ttf');
      if (f.existsSync()) {
        cargador.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      }
    }
    await cargador.load();
  });

  Future<void> montar(WidgetTester tester, Size tamano, Widget home, _RepoFalso repo) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          asientoSapRepoProvider.overrideWithValue(repo),
          empresasProvider.overrideWith((ref) => EmpresasNotifier(_Rrhh())),
        ],
        child: MaterialApp(
          builder:
              (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: ResponsiveUtilsBosque.breakpoints,
              ),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Toca lo que encuentre, después de traerlo a la vista.
  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder enDialogo(Finder f) =>
      find.descendant(of: find.byType(Dialog), matching: f);

  /// Los avisos se van solos: se deja pasar su reloj para que no quede ningún Timer vivo.
  Future<void> cerrarAvisos(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
  }

  for (final caso in <(String, Size)>[
    ('escritorio', const Size(1400, 900)),
    ('tablet', const Size(800, 1000)),
    ('móvil', const Size(390, 844)),
  ]) {
    group(caso.$1, () {
      testWidgets('configuración: editar, probar, agregar con su conexión y quitar', (
        tester,
      ) async {
        final repo = _RepoFalso(claveCargada: true);
        await montar(tester, caso.$2, const AsientoSapConfigScreen(), repo);
        expect(tester.takeException(), isNull);
        expect(find.text('Contraseña cargada'), findsOneWidget);

        // Editar y guardar.
        await tocar(tester, find.text('Editar'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'spAsientoSueldosDraft'),
          'spAsientoOtro',
        );
        await tocar(tester, enDialogo(find.text('Guardar')));
        expect(tester.takeException(), isNull);
        expect(find.byType(Dialog), findsNothing);
        expect(find.textContaining('spAsientoOtro'), findsOneWidget);

        // Probar la conexión.
        await tocar(tester, find.text('Probar'));
        await tocar(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('Probar')));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Conexión correcta'), findsOneWidget);
        await tocar(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('Cerrar')));

        // Agregar otra empresa. El aviso de la acción anterior vive arriba y en un teléfono
        // tapa el encabezado unos segundos: se espera a que se vaya, como haría una persona.
        await cerrarAvisos(tester);
        await tocar(
          tester,
          caso.$2.width < 600 ? find.byTooltip('Agregar empresa') : find.text('Agregar empresa'),
        );
        expect(find.text('Elige la empresa para ver sus conexiones a SAP.'), findsOneWidget);
        await tocar(tester, enDialogo(find.byType(DropdownButtonFormField<int>)));
        await tocar(tester, find.text('IMPEXPAP').last);
        // IMPEXPAP tiene una sola conexión: se elige sola.
        expect(find.text('IMPEXPAP - PRUEBA IMPEXPAP · Prueba'), findsOneWidget);
        await tocar(tester, enDialogo(find.text('Guardar')));
        expect(tester.takeException(), isNull);
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('IMPEXPAP'), findsOneWidget);
        expect(find.text('IMPEXPAP - PRUEBA IMPEXPAP'), findsOneWidget);

        // Quitarla.
        await tocar(tester, find.byTooltip('Quitar IMPEXPAP'));
        await tocar(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('Quitar')));
        expect(tester.takeException(), isNull);
        expect(find.text('IMPEXPAP'), findsNothing);

        await cerrarAvisos(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('envío: confirma, envía y cierra; con error se queda abierto', (
        tester,
      ) async {
        final repo = _RepoFalso(claveCargada: true);
        await montar(
          tester,
          caso.$2,
          Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed:
                        () => showDialog(
                          context: context,
                          builder:
                              (_) => const PlanillasAsientoSapDialog(
                                mes: 9,
                                anio: 2026,
                                nombreMes: 'SEPTIEMBRE',
                              ),
                        ),
                    child: const Text('abrir'),
                  ),
            ),
          ),
          repo,
        );

        // Primero SAP rechaza: el diálogo queda abierto y el botón vuelve a estar activo.
        repo.errorAlEnviar = 'SAP respondió con error al crear el asiento: Code undefined';
        await tocar(tester, find.text('abrir'));
        // A qué ambiente va se ve antes de enviar.
        expect(find.text('Base de prueba'), findsOneWidget);
        await tocar(tester, find.text('Enviar a SAP'));
        expect(find.textContaining('(base de prueba)'), findsOneWidget);
        await tocar(tester, find.text('Sí, enviar'));
        expect(tester.takeException(), isNull);
        expect(find.text('Asiento contable en SAP'), findsOneWidget);
        expect(find.textContaining('Code undefined'), findsOneWidget);

        // Después sale bien: avisa y cierra.
        repo.errorAlEnviar = null;
        await tocar(tester, find.text('Enviar a SAP'));
        await tocar(tester, find.text('Sí, enviar'));
        expect(tester.takeException(), isNull);
        expect(find.text('Asiento contable en SAP'), findsNothing);
        expect(repo.enviados, 1);

        await cerrarAvisos(tester);
        expect(tester.takeException(), isNull);
      });
    });
  }
}

class _RepoFalso implements AsientoSapRepository {
  _RepoFalso({bool claveCargada = false}) {
    _conexiones[1] = SapConexionEntity(
      idConexion: 1,
      nombre: 'ESPPAPEL - PRUEBA ESPPAPEL 2',
      codEmpresa: 5,
      empresa: 'ESPPAPEL',
      linkedServer: '192.168.3.114',
      baseSap: 'PRUEBA ESPPAPEL 2',
      claveCargada: claveCargada,
    );
    _conexiones[2] = const SapConexionEntity(
      idConexion: 2,
      nombre: 'IMPEXPAP - PRUEBA IMPEXPAP',
      codEmpresa: 1,
      empresa: 'IMPEXPAP',
      linkedServer: '192.168.3.114',
      baseSap: 'PRUEBA IMPEXPAP',
      claveCargada: true,
    );
    _filas[5] = AsientoSapConfigModel.toJson(AsientoSapConfigEntity.plantilla(codEmpresa: 5))
      ..['idConexion'] = 1;
  }

  static const _nombres = {1: 'IMPEXPAP', 5: 'ESPPAPEL'};
  final Map<int, Map<String, dynamic>> _filas = {};
  final Map<int, SapConexionEntity> _conexiones = {};
  String? errorAlEnviar;
  int enviados = 0;

  /// Lo que devuelve p_list_tsap_AsientoPlanilla: la configuración con los datos de su conexión.
  AsientoSapConfigEntity _entidad(int cod) {
    final cx = _conexiones[_filas[cod]!['idConexion']]!;
    return AsientoSapConfigModel.fromJson({
      ..._filas[cod]!,
      'empresa': _nombres[cod],
      'conexion': cx.nombre,
      'ambiente': cx.ambiente,
      'linkedServer': cx.linkedServer,
      'baseSap': cx.baseSap,
      'conexionHabilitada': cx.habilitada,
      'claveCargada': cx.claveCargada,
    });
  }

  @override
  Future<List<AsientoSapEmpresaEntity>> empresas() async => [
    for (final cod in _filas.keys)
      if (_entidad(cod).claveCargada)
        AsientoSapEmpresaEntity(codEmpresa: cod, empresa: _nombres[cod]!),
  ];

  @override
  Future<AsientoSapEntity?> vistaPrevia({
    required int anio,
    required int mes,
    required int codEmpresa,
  }) async => AsientoSapEntity(
    anio: anio,
    mes: mes,
    codEmpresa: codEmpresa,
    empresa: _nombres[codEmpresa]!,
    baseSap: 'PRUEBA ESPPAPEL 2',
    conexion: 'ESPPAPEL - PRUEBA ESPPAPEL 2',
    ambiente: SapConexionEntity.prueba,
    fecha: '2026-09-30',
    memo: 'Asiento de Planilla - Periodo 9/2026',
    referencia: 'PLANILLA-2026-09',
    lineas: const [
      AsientoSapLineaEntity(
        codigo: '6110101',
        nombre: 'Sueldos',
        cuenta: '6110101',
        debito: 100,
        credito: 0,
      ),
      AsientoSapLineaEntity(
        codigo: 'SU00464',
        nombre: 'SUELDOS Y SALARIOS',
        cuenta: '2120101',
        socio: 'SU00464',
        debito: 0,
        credito: 100,
      ),
    ],
    totalDebito: 100,
    totalCredito: 100,
    diferencia: 0,
    cuadra: true,
  );

  @override
  Future<String> enviar({
    required int anio,
    required int mes,
    required int codEmpresa,
  }) async {
    if (errorAlEnviar != null) throw Exception(errorAlEnviar);
    enviados++;
    return 'Asiento N° 123 creado en SAP.';
  }

  @override
  Future<List<AsientoSapConfigEntity>> listarConfig() async => [
    for (final cod in _filas.keys) _entidad(cod),
  ];

  @override
  Future<String> guardarConfig(AsientoSapConfigEntity c) async {
    _filas[c.codEmpresa] = AsientoSapConfigModel.toJson(c);
    return 'Guardado. Rige desde el próximo asiento.';
  }

  @override
  Future<String> eliminarConfig(int codEmpresa) async {
    _filas.remove(codEmpresa);
    return 'Configuración eliminada.';
  }

  @override
  Future<String> probar(int codEmpresa) async =>
      'Conexión correcta: finanzas entró a PRUEBA ESPPAPEL 2.';

  @override
  Future<List<SapConexionEntity>> conexiones() async => _conexiones.values.toList();
}

class _Rrhh extends Fake implements RRHHRepositoryImpl {
  @override
  Future<List<EmpresaEntity>> lstEmpresas() async => [
    EmpresaEntity(codEmpresa: 1, nombre: 'IMPEXPAP', codPadre: 0, sigla: 'IPX', audUsuario: 0),
    EmpresaEntity(codEmpresa: 5, nombre: 'ESPPAPEL', codPadre: 0, sigla: 'ESP', audUsuario: 0),
  ];
}
