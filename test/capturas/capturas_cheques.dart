// Capturas del modulo de cheques, para mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_cheques.dart --dart-define=CAPTURAS=<carpeta>
//
// Usa el repositorio falso de test/fakes/repositorio_cheques.dart (datos de
// ejemplo, sin backend ni login) y las fuentes reales del proyecto: con la de
// prueba de Flutter cada letra es un rectangulo y no se puede juzgar nada.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/models/accion_cheque_model.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/dialogos_accion_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/formulario_cheque.dart';

import '../fakes/arnes_cheques.dart';
import '../fakes/repositorio_cheques.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_cheques',
);

Future<void> _cargarFuentes() async {
  final dir = Directory('assets/fonts');
  final porFamilia = <String, List<File>>{};
  for (final f in dir.listSync().whereType<File>()) {
    final nombre = f.uri.pathSegments.last;
    if (!nombre.endsWith('.ttf') && !nombre.endsWith('.otf')) continue;
    porFamilia.putIfAbsent(nombre.split('-').first, () => []).add(f);
  }
  for (final e in porFamilia.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
  final iconos = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (iconos.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(
      Future.value(ByteData.sublistView(iconos.readAsBytesSync())),
    )).load();
  }
}

RepositorioChequesFalso _repo() {
  final r = RepositorioChequesFalso(total: 0);
  const clientes = [
    'EDITORA MENDEZ LTDA.',
    'LIBRERIA Y PAPELERIA EL PAIS S.R.L.',
    'DISTRIBUIDORA ANDINA DE PAPELES',
    'COMERCIAL SANTA CRUZ',
    'IMPRENTA UNIVERSAL',
  ];
  const bancos = [
    'BANCO UNION',
    'BANCO MERCANTIL SANTA CRUZ',
    'BANCO NACIONAL DE BOLIVIA',
    'BANCO BISA',
  ];
  r.cheques = [
    for (var i = 1; i <= 32; i++)
      chequeFalso(
        i,
        cliente: clientes[i % clientes.length],
        banco: bancos[i % bancos.length],
        estado: i % 6 == 0 ? 'CER' : 'PEN',
        descTipo: i % 4 == 0 ? null : (i % 3 == 0 ? 'RESPALDO' : 'PAGO'),
        codEmpleado: i % 3 == 0 ? 12 : 0,
        datoEmpleado: i % 3 == 0 ? ' - JUAN CARLOS PEREZ -' : ' - Entregado por el Cliente -',
        monto: 1250.5 * i,
        aOrdenDe: 'BOSQUE INDUSTRIAL SA',
        nroCheque: '${480000 + i * 37}',
      ),
  ];
  r.clientes = [
    for (final (i, c) in clientes.indexed) clienteDeCheque('C$i', c),
  ];
  r.personal = const [
    PersonalChequeEntity(codEmpleado: 12, nombreCompleto: 'JUAN CARLOS PEREZ'),
    PersonalChequeEntity(codEmpleado: 13, nombreCompleto: 'ANA MARIA ROJAS'),
  ];
  r.alObtenerDetalle =
      (cod) async => ChequeDetalleEntity(
        cheque: r.cheques.firstWhere((c) => c.codCheque == cod),
        acciones: [
          for (final (i, e) in [
            ('REC', 'RECIBIDO', null, null),
            ('TRASP', 'TRASPASO', null, null),
            ('CUS', 'A COBRANZA', null, null),
            ('DEV', 'DEVUELTO', null, 'El banco lo devolvio por firma'),
          ].indexed)
            AccionChequeModel.fromJson({
              'codAccion': 700 + i,
              'codCheque': cod.toInt(),
              'fecha': '2026-09-0${i + 1}T09:${10 + i}:00',
              'estado': e.$1,
              'codEmpleado': null,
              'nroSAP': null,
              'observacion': e.$4,
              'audUsuario': 1,
              'audFecha': null,
              'descripcion': e.$2,
              'nro': i + 1,
            }).toEntity(),
        ],
        botones: const BotonesChequeEntity(
          fechaCobro: true,
          devolver: false,
          cerrarConVerificacion: false,
          cerrarSinVerificacion: false,
          codigo: '1000',
        ),
      );
  return r;
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre,
  Widget pantalla, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester tester)? antes,
  PermisosCheque permisos = permisosAdmin,
  double escala = 1,
  RepositorioChequesFalso? repo,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
  }

  // En las pruebas Flutter cambia cada sombra por un trazo negro grueso
  // (debugDisableShadows): se vuelve a su valor antes de terminar.
  debugDisableShadows = false;
  try {
    final clave = GlobalKey();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: appCheques(
          hijo: pantalla,
          repo: repo ?? _repo(),
          permisos: permisos,
        ),
      ),
    );

    Future<void> dejarQueCargue() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await dejarQueCargue();
    if (antes != null) {
      await antes(tester);
      await dejarQueCargue();
    }

    await tester.runAsync(() async {
      final boundary =
          clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await boundary.toImage(pixelRatio: 1);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
      File('$_salida/$nombre.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = true;
    if (escala != 1) tester.platformDispatcher.clearTextScaleFactorTestValue();
  }
}

/// Una pantalla con un boton que abre lo que se quiere capturar.
Widget _lanzador(Future<void> Function(BuildContext) abrir) => Builder(
  builder:
      (context) => Center(
        child: FilledButton(
          onPressed: () => abrir(context),
          child: const Text('abrir'),
        ),
      ),
);

Future<void> _tocarAbrir(WidgetTester t) async {
  await t.tap(find.text('abrir'));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    dotenv.testLoad(fileInput: 'BASE_URL_DEV=http://capturas.local');
  });

  const tablet = Size(800, 1100);
  const telefono = Size(390, 844);

  testWidgets('principal', (t) async {
    await _capturar(t, 'principal_escritorio', const ChequesScreen());
    await _capturar(
      t,
      'principal_escritorio_cajero',
      const ChequesScreen(),
      permisos: permisosCajero,
    );
    await _capturar(
      t,
      'principal_escritorio_custodia',
      const ChequesScreen(),
      antes: (t) async {
        await t.tap(find.text('Custodia'));
        await t.pump(const Duration(milliseconds: 300));
      },
    );
    await _capturar(
      t,
      'principal_escritorio_150',
      const ChequesScreen(),
      escala: 1.5,
    );
    await _capturar(
      t,
      'principal_tablet',
      const ChequesScreen(),
      tam: tablet,
    );
    await _capturar(
      t,
      'principal_telefono',
      const ChequesScreen(),
      tam: telefono,
    );
    await _capturar(
      t,
      'principal_telefono_filtros',
      const ChequesScreen(),
      tam: telefono,
      antes: (t) async {
        await t.tap(find.byTooltip('Mostrar filtros'));
        await t.pump(const Duration(milliseconds: 300));
      },
    );
    await _capturar(
      t,
      'principal_telefono_150',
      const ChequesScreen(),
      tam: telefono,
      escala: 1.5,
    );
  });

  testWidgets('rango de recepcion', (t) async {
    // «Hasta» queda en el 01/07/2026, antes de «desde» (03/07/2026).
    Future<void> invertirRango(WidgetTester t) async {
      final hasta = find.byKey(const ValueKey('filtro-recibido-hasta'));
      await t.ensureVisible(hasta);
      await t.tap(hasta);
      await esperar(t);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byTooltip('Mes anterior'));
        await esperar(t);
      }
      await t.tap(find.text('1').last);
      await esperar(t);
      await t.tap(find.text('ACEPTAR'));
      await esperar(t);
    }

    await _capturar(
      t,
      'rango_error_escritorio',
      const ChequesScreen(),
      antes: invertirRango,
    );
    await _capturar(
      t,
      'rango_error_telefono',
      const ChequesScreen(),
      tam: telefono,
      antes: (t) async {
        await t.tap(find.byTooltip('Mostrar filtros'));
        await esperar(t);
        await invertirRango(t);
      },
    );
    await _capturar(
      t,
      'rango_sin_cheques_escritorio',
      const ChequesScreen(),
      repo: RepositorioChequesFalso(total: 0),
    );
    await _capturar(
      t,
      'rango_sin_cheques_telefono',
      const ChequesScreen(),
      tam: telefono,
      repo: RepositorioChequesFalso(total: 0),
    );
  });

  testWidgets('detalle', (t) async {
    Future<void> completar(WidgetTester t) async {
      await t.tap(find.byTooltip('Completar').first);
      await t.pump(const Duration(milliseconds: 300));
    }

    Future<void> completarMovil(WidgetTester t) async {
      await t.tap(find.byTooltip('Acciones').first);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Completar'));
      await t.pump(const Duration(milliseconds: 300));
    }

    await _capturar(
      t,
      'detalle_escritorio',
      const ChequesScreen(),
      antes: completar,
    );
    await _capturar(
      t,
      'detalle_telefono',
      const ChequesScreen(),
      tam: telefono,
      antes: completarMovil,
    );
  });

  testWidgets('formularios', (t) async {
    final abrirAlta = _lanzador(
      (c) => abrirFormularioCheque(
        c,
        modo: ModoRegistroCheque.estandar,
        codSucursal: 3,
      ),
    );
    await _capturar(t, 'form_alta_escritorio', abrirAlta, antes: _tocarAbrir);
    await _capturar(
      t,
      'form_alta_telefono',
      abrirAlta,
      tam: telefono,
      antes: _tocarAbrir,
    );

    final repo = _repo();
    final cheque = repo.cheques[2];
    Widget editar(ModoRegistroCheque modo) => _lanzador(
      (c) => abrirFormularioCheque(
        c,
        modo: modo,
        codSucursal: 3,
        existente: cheque,
      ),
    );
    await _capturar(
      t,
      'form_talonario_escritorio',
      editar(ModoRegistroCheque.talonario),
      antes: _tocarAbrir,
    );
    await _capturar(
      t,
      'form_admin_escritorio',
      editar(ModoRegistroCheque.admin),
      antes: _tocarAbrir,
    );
    // El lapiz de un administrador en un cheque cerrado con el cobro fuera de
    // +-28 dias: talonario y recibo, con el aviso arriba.
    await _capturar(
      t,
      'form_talonario_aviso_escritorio',
      _lanzador(
        (c) => abrirFormularioCheque(
          c,
          modo: ModoRegistroCheque.talonario,
          codSucursal: 3,
          existente: cheque,
          avisoCobroFueraDeRango: true,
        ),
      ),
      antes: _tocarAbrir,
    );
    await _capturar(
      t,
      'form_talonario_aviso_telefono_150',
      _lanzador(
        (c) => abrirFormularioCheque(
          c,
          modo: ModoRegistroCheque.talonario,
          codSucursal: 3,
          existente: cheque,
          avisoCobroFueraDeRango: true,
        ),
      ),
      tam: telefono,
      escala: 1.5,
      antes: _tocarAbrir,
    );
  });

  testWidgets('dialogos', (t) async {
    final cheque = _repo().cheques[2];
    Widget accion(TipoAccionCheque tipo) => _lanzador(
      (c) => abrirAccionCheque(c, cheque: cheque, tipo: tipo),
    );
    await _capturar(
      t,
      'dialogo_cerrar_escritorio',
      accion(TipoAccionCheque.cerrarSinVerificacion),
      antes: _tocarAbrir,
    );
    await _capturar(
      t,
      'dialogo_fecha_cobro_telefono',
      accion(TipoAccionCheque.fechaCobro),
      tam: telefono,
      antes: _tocarAbrir,
      permisos: permisosCajero,
    );
  });
}
