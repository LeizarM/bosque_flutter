// Capturas del combo «Empresa» de Cheques y de los avisos del combo de cliente,
// para mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_empresa_cheques.dart --dart-define=CAPTURAS=<carpeta>
//
// Usa el repositorio falso de test/fakes (datos de ejemplo, sin backend) y las
// fuentes reales del proyecto. El login de ejemplo es el del bug que se
// corrigio: empresa 6 y sin nombre.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';

import '../fakes/arnes_cheques.dart';
import '../fakes/repositorio_cheques.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_empresa_cheques',
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
  const clientes = [
    'EDITORA MENDEZ LTDA.',
    'LIBRERIA Y PAPELERIA EL PAIS S.R.L.',
    'DISTRIBUIDORA ANDINA DE PAPELES',
    'COMERCIAL SANTA CRUZ',
    'IMPRENTA UNIVERSAL',
  ];
  return RepositorioChequesFalso(total: 0)
    ..cheques = [
      for (var i = 1; i <= 8; i++)
        chequeFalso(
          i,
          cliente: clientes[i % clientes.length],
          descTipo: 'PAGO',
          monto: 1250.5 * i,
          nroCheque: '${480000 + i * 37}',
        ),
    ]
    ..clientes = [
      for (var i = 0; i < clientes.length; i++)
        clienteDeCheque('K$i', clientes[i]),
    ]
    ..personal = const [
      PersonalChequeEntity(codEmpleado: 12, nombreCompleto: 'JUAN CARLOS PEREZ'),
    ];
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre,
  RepositorioChequesFalso repo, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester tester)? antes,
  double escala = 1,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (escala != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = escala;
  }

  // En las pruebas Flutter cambia cada sombra por un trazo negro grueso.
  debugDisableShadows = false;
  try {
    final clave = GlobalKey();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: appCheques(
          hijo: const ChequesScreen(),
          repo: repo,
          permisos: permisosAdmin,
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    dotenv.testLoad(fileInput: 'BASE_URL_DEV=http://capturas.local');
  });

  const tablet = Size(800, 1100);
  const telefono = Size(390, 844);

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await t.pump(const Duration(milliseconds: 120));
    }
  }

  Future<void> cambiarAEsppapel(WidgetTester t) async {
    await tocar(t, comboEmpresa());
    await tocar(t, find.text('ESPPAPEL').last);
  }

  testWidgets('filtros con el combo Empresa', (t) async {
    await _capturar(t, 'filtros_escritorio', _repo());
    await _capturar(t, 'filtros_tablet', _repo(), tam: tablet);
    await _capturar(t, 'filtros_telefono', _repo(), tam: telefono);
    await _capturar(
      t,
      'filtros_telefono_desplegado_150',
      _repo(),
      tam: telefono,
      escala: 1.5,
      antes: (t) => tocar(t, find.byTooltip('Mostrar filtros')),
    );
    await _capturar(
      t,
      'filtros_empresa_esppapel',
      _repo()
        ..cheques = [
          chequeFalso(
            2,
            descTipo: 'PAGO',
            codSucursal: 7,
            codEmpresa: 5,
            cliente: 'CLIENTE DE ESPPAPEL',
          ),
        ],
      antes: cambiarAEsppapel,
    );
    await _capturar(
      t,
      'filtros_error_empresas',
      _repo()..errorEmpresas = Exception('No se pudo conectar con el servidor.'),
    );
    await _capturar(
      t,
      'filtros_error_empresas_telefono',
      _repo()..errorEmpresas = Exception('No se pudo conectar con el servidor.'),
      tam: telefono,
    );
  });

  testWidgets('formulario de alta', (t) async {
    Future<void> abrir(WidgetTester t) => tocar(t, find.text('Registrar'));
    await _capturar(t, 'form_alta_escritorio', _repo(), antes: abrir);
    await _capturar(
      t,
      'form_alta_empresa_esppapel',
      _repo()
        ..clientesPorEmpresa = {
          5: [clienteDeCheque('E1', 'CLIENTE DE ESPPAPEL')],
        },
      antes: (t) async {
        await cambiarAEsppapel(t);
        await abrir(t);
      },
    );
    await _capturar(
      t,
      'form_alta_telefono',
      _repo(),
      tam: telefono,
      antes: (t) async {
        await tocar(t, find.byTooltip('Registrar cheque'));
      },
    );
  });

  testWidgets('combo de cliente: avisos', (t) async {
    Future<void> abrir(WidgetTester t) => tocar(t, find.text('Registrar'));
    await _capturar(
      t,
      'cliente_sin_coincidencias',
      _repo(),
      antes: (t) async {
        await abrir(t);
        await t.enterText(find.byKey(const ValueKey('campo-cliente')), 'zzzz');
      },
    );
    await _capturar(
      t,
      'cliente_sin_coincidencias_telefono_150',
      _repo(),
      tam: telefono,
      escala: 1.5,
      antes: (t) async {
        await tocar(t, find.byTooltip('Registrar cheque'));
        await t.enterText(find.byKey(const ValueKey('campo-cliente')), 'zzzz');
      },
    );
    await _capturar(
      t,
      'cliente_empresa_sin_clientes',
      _repo()..clientes = [],
      antes: abrir,
    );
    await _capturar(
      t,
      'cliente_empresa_sin_clientes_guardar',
      _repo()..clientes = [],
      antes: (t) async {
        await abrir(t);
        await tocar(t, find.widgetWithText(FilledButton, 'Registrar cheque'));
      },
    );
    await _capturar(
      t,
      'cliente_opciones',
      _repo(),
      antes: (t) async {
        await abrir(t);
        await t.enterText(find.byKey(const ValueKey('campo-cliente')), 'a');
      },
    );
  });
}
