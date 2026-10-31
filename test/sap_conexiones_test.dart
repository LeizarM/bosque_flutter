import 'dart:io';

import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/sap_conexion_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/repositories/rrhh_repository_impl.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/sap_conexion_entity.dart';
import 'package:bosque_flutter/domain/repositories/sap_conexion_repository.dart';
import 'package:bosque_flutter/presentation/screens/sap/sap_conexiones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Administración > Conexiones SAP, con un repositorio falso: las tarjetas dicen el ambiente, si
/// hay contraseña y si un módulo la usa; y editar, cargar la contraseña, probar, agregar y quitar
/// no dejan ninguna excepción de Flutter en escritorio, tablet ni teléfono.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Fuente parecida a la de la app (ver planillas_asiento_sap_dialog_test.dart).
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

  Future<void> montar(WidgetTester tester, Size tamano, _RepoFalso repo) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sapConexionRepoProvider.overrideWithValue(repo),
          empresasProvider.overrideWith((ref) => EmpresasNotifier(_Rrhh())),
        ],
        child: MaterialApp(
          builder:
              (context, child) => ResponsiveBreakpoints.builder(
                child: child!,
                breakpoints: ResponsiveUtilsBosque.breakpoints,
              ),
          home: const SapConexionesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder enDialogo(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);

  Finder enAlerta(String texto) =>
      find.descendant(of: find.byType(AlertDialog), matching: find.text(texto));

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
      testWidgets('las tarjetas dicen ambiente, contraseña y uso', (tester) async {
        await montar(tester, caso.$2, _RepoFalso());

        expect(tester.takeException(), isNull);
        expect(find.text('ESPPAPEL - PRUEBA ESPPAPEL 2'), findsOneWidget);
        expect(find.text('IMPEXPAP - Producción'), findsOneWidget);
        expect(find.text('Prueba'), findsOneWidget);
        expect(find.text('Producción'), findsOneWidget);
        expect(find.text('Falta la contraseña'), findsOneWidget);
        expect(find.text('La usa 1 configuración'), findsOneWidget);

        // La que usa el asiento no se puede quitar; la otra sí. byTooltip encuentra el Tooltip
        // que el IconButton lleva adentro: se pide el botón que lo contiene.
        IconButton boton(String tooltip) => tester.widget<IconButton>(
          find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
        );
        expect(boton('La usa 1 configuración: no se puede quitar').onPressed, isNull);
        expect(boton('Quitar IMPEXPAP - Producción').onPressed, isNotNull);

        // Sin contraseña no hay nada que probar.
        final probar = tester.widget<TextButton>(
          find.ancestor(of: find.text('Probar').last, matching: find.bySubtype<TextButton>()),
        );
        expect(probar.onPressed, isNull);
      });

      testWidgets('editar, contraseña, probar, agregar y quitar', (tester) async {
        final repo = _RepoFalso();
        await montar(tester, caso.$2, repo);

        // Editar la de IMPEXPAP: cambia la base.
        await tocar(tester, find.text('Editar').last);
        expect(find.text('Conexión IMPEXPAP - Producción'), findsOneWidget);
        await tester.enterText(
          enDialogo(find.widgetWithText(TextFormField, 'Base de SAP (CompanyDB)')),
          'IMPEXPAP',
        );
        await tocar(tester, enDialogo(find.text('Guardar')));
        expect(tester.takeException(), isNull);
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('[192.168.3.114].[IMPEXPAP]'), findsOneWidget);

        // Su contraseña.
        await tocar(tester, find.text('Contraseña').last);
        await tester.enterText(find.byType(TextField).last, 'clave secreta');
        await tocar(tester, enAlerta('Guardar'));
        expect(tester.takeException(), isNull);
        expect(find.text('Falta la contraseña'), findsNothing);

        // Ya con contraseña, probarla.
        await tocar(tester, find.text('Probar').last);
        await tocar(tester, enAlerta('Probar'));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Conexión correcta'), findsOneWidget);
        await tocar(tester, enAlerta('Cerrar'));

        // Agregar la de prueba de IMPEXPAP.
        await cerrarAvisos(tester);
        await tocar(
          tester,
          caso.$2.width < 600 ? find.byTooltip('Agregar conexión') : find.text('Agregar conexión'),
        );
        await tester.enterText(
          enDialogo(find.widgetWithText(TextFormField, 'Nombre')),
          'IMPEXPAP - PRUEBA IMPEXPAP',
        );
        await tocar(tester, enDialogo(find.byType(DropdownButtonFormField<int>)));
        await tocar(tester, find.text('IMPEXPAP').last);
        await tester.enterText(
          enDialogo(find.widgetWithText(TextFormField, 'Base de SAP (CompanyDB)')),
          'PRUEBA IMPEXPAP',
        );
        await tester.enterText(enDialogo(find.widgetWithText(TextFormField, 'Usuario')), 'finanzas');
        await tocar(tester, enDialogo(find.text('Guardar')));
        expect(tester.takeException(), isNull);
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('IMPEXPAP - PRUEBA IMPEXPAP'), findsOneWidget);
        expect(repo.guardadas.last.esPrueba, isTrue);

        // Quitarla.
        await cerrarAvisos(tester);
        await tocar(tester, find.byTooltip('Quitar IMPEXPAP - PRUEBA IMPEXPAP'));
        await tocar(tester, enAlerta('Quitar'));
        expect(tester.takeException(), isNull);
        expect(find.text('IMPEXPAP - PRUEBA IMPEXPAP'), findsNothing);

        await cerrarAvisos(tester);
        expect(tester.takeException(), isNull);
      });
    });
  }
}

class _RepoFalso implements SapConexionRepository {
  _RepoFalso() {
    _filas[1] = const SapConexionEntity(
      idConexion: 1,
      nombre: 'ESPPAPEL - PRUEBA ESPPAPEL 2',
      codEmpresa: 5,
      empresa: 'ESPPAPEL',
      linkedServer: '192.168.3.114',
      baseSap: 'PRUEBA ESPPAPEL 2',
      slUrl: 'https://sequoia:50000/b1s/v1/',
      slUsuario: 'finanzas',
      claveCargada: true,
      enUso: 1,
    );
    _filas[2] = const SapConexionEntity(
      idConexion: 2,
      nombre: 'IMPEXPAP - Producción',
      codEmpresa: 1,
      empresa: 'IMPEXPAP',
      ambiente: SapConexionEntity.produccion,
      linkedServer: '192.168.3.114',
      baseSap: 'IMPEXPAP_REAL',
      slUrl: 'https://sequoia:50000/b1s/v1/',
      slUsuario: 'finanzas',
    );
  }

  static const _nombres = {1: 'IMPEXPAP', 5: 'ESPPAPEL'};
  final Map<int, SapConexionEntity> _filas = {};
  final List<SapConexionEntity> guardadas = [];
  int _siguiente = 3;

  /// Lo que devuelve p_list_tsap_Conexion: lo guardado, más lo que calcula la base.
  SapConexionEntity _fila(SapConexionEntity c, int id, {bool? claveCargada}) {
    final previa = _filas[id];
    return SapConexionEntity(
      idConexion: id,
      nombre: c.nombre,
      codEmpresa: c.codEmpresa,
      empresa: _nombres[c.codEmpresa] ?? '',
      ambiente: c.ambiente,
      linkedServer: c.linkedServer,
      baseSap: c.baseSap,
      slUrl: c.slUrl,
      slUsuario: c.slUsuario,
      habilitada: c.habilitada,
      claveCargada: claveCargada ?? previa?.claveCargada ?? false,
      enUso: previa?.enUso ?? 0,
    );
  }

  @override
  Future<List<SapConexionEntity>> listar() async => _filas.values.toList();

  @override
  Future<String> guardar(SapConexionEntity c) async {
    final id = c.idConexion ?? _siguiente++;
    guardadas.add(c);
    _filas[id] = _fila(c, id);
    return 'Conexión guardada. Rige desde el próximo uso.';
  }

  @override
  Future<String> guardarClave({required int idConexion, required String clave}) async {
    _filas[idConexion] = _fila(_filas[idConexion]!, idConexion, claveCargada: true);
    return 'Contraseña guardada.';
  }

  @override
  Future<String> eliminar(int idConexion) async {
    if ((_filas[idConexion]?.enUso ?? 0) > 0) {
      throw Exception('La usa el asiento de planilla.');
    }
    _filas.remove(idConexion);
    return 'Conexión eliminada.';
  }

  @override
  Future<String> probar(int idConexion) async =>
      'Conexión correcta: finanzas entró a ${_filas[idConexion]!.baseSap}.';
}

class _Rrhh extends Fake implements RRHHRepositoryImpl {
  @override
  Future<List<EmpresaEntity>> lstEmpresas() async => [
    EmpresaEntity(codEmpresa: 1, nombre: 'IMPEXPAP', codPadre: 0, sigla: 'IPX', audUsuario: 0),
    EmpresaEntity(codEmpresa: 5, nombre: 'ESPPAPEL', codPadre: 0, sigla: 'ESP', audUsuario: 0),
  ];
}
