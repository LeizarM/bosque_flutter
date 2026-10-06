// Capturas de los reportes en PDF de Cheques (barra, dialogos y nomina del
// traspaso), para mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_reportes_cheques.dart --dart-define=CAPTURAS=<carpeta>
//
// Usa el repositorio falso de test/fakes (datos de ejemplo, sin backend ni
// login) y las fuentes reales del proyecto: con la de prueba de Flutter cada
// letra es un rectangulo y no se puede juzgar nada.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/hora_traspaso_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';

import '../fakes/arnes_cheques.dart';
import '../fakes/repositorio_cheques.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_reportes_cheques',
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
  final r = RepositorioChequesFalso(total: 0);
  r.cheques = [
    for (var i = 1; i <= 12; i++)
      chequeFalso(
        i,
        cliente: clientes[i % clientes.length],
        descTipo: 'PAGO',
        monto: 1250.5 * i,
        nroCheque: '${480000 + i * 37}',
      ),
  ];
  r
    ..pendientes = 12
    ..clientes = [
      for (var i = 0; i < clientes.length; i++)
        clienteDeCheque('C$i', clientes[i]),
    ]
    ..responsables = const [
      PersonalChequeEntity(
        codEmpleado: 12,
        nombreCompleto: 'JUAN CARLOS PEREZ',
      ),
      PersonalChequeEntity(codEmpleado: 13, nombreCompleto: 'ANA MARIA ROJAS'),
    ]
    ..horasDeTraspaso = const [
      HoraTraspasoChequeEntity(codAccion: 88, hora: '09:15'),
      HoraTraspasoChequeEntity(codAccion: 91, hora: '11:40'),
      HoraTraspasoChequeEntity(codAccion: 95, hora: '16:05'),
    ];
  return r;
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester tester)? antes,
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
          hijo: const ChequesScreen(),
          repo: repo ?? _repo(),
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

  /// Toca y deja pasar los fotogramas y las peticiones falsas que hagan falta
  /// para que el dialogo termine de abrirse y pida sus datos.
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

  final menuTelefono = find.widgetWithIcon(IconButton, Icons.swap_horiz);

  /// Abre un reporte: el boton «Reportes» en escritorio y el menu del telefono.
  Future<void> abrir(WidgetTester t, String etiqueta, {bool movil = false}) async {
    await tocar(t, movil ? menuTelefono : find.text('Reportes'));
    await tocar(t, find.text(etiqueta));
  }

  Finder boton(String etiqueta) => find.ancestor(
    of: find.text(etiqueta),
    matching: find.bySubtype<FilledButton>(),
  );

  Future<void> elegirCliente(WidgetTester t) async {
    await t.enterText(find.byKey(const ValueKey('campo-cliente')), 'ed');
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('EDITORA MENDEZ LTDA.').last);
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('menu de reportes en la barra', (t) async {
    await _capturar(
      t,
      'barra_escritorio_menu',
      antes: (t) => tocar(t, find.text('Reportes')),
    );
    await _capturar(
      t,
      'barra_tablet_menu',
      tam: tablet,
      antes: (t) => tocar(t, find.text('Reportes')),
    );
    await _capturar(
      t,
      'barra_telefono_menu',
      tam: telefono,
      antes: (t) => tocar(t, menuTelefono),
    );
  });

  testWidgets('recibidos', (t) async {
    await _capturar(
      t,
      'recibidos_escritorio',
      antes: (t) => abrir(t, 'Cheques recibidos'),
    );
    await _capturar(
      t,
      'recibidos_telefono_150',
      tam: telefono,
      escala: 1.5,
      antes: (t) => abrir(t, 'Cheques recibidos', movil: true),
    );
    await _capturar(
      t,
      'recibidos_error',
      repo:
          _repo()
            ..errorReporte = Exception(
              'No tiene permisos para ver cheques de otras sucursales\n'
              'No hay cheques en el rango pedido.',
            ),
      antes: (t) async {
        await abrir(t, 'Cheques recibidos');
        await tocar(t, boton('Generar PDF'));
      },
    );
  });

  testWidgets('cobranzas', (t) async {
    await _capturar(
      t,
      'cobranzas_escritorio',
      antes: (t) => abrir(t, 'Cheques de cobranza'),
    );
    await _capturar(
      t,
      'cobranzas_escritorio_cliente_elegido',
      antes: (t) async {
        await abrir(t, 'Cheques de cobranza');
        await elegirCliente(t);
      },
    );
    await _capturar(
      t,
      'cobranzas_telefono_buscando',
      tam: telefono,
      antes: (t) async {
        await abrir(t, 'Cheques de cobranza', movil: true);
        await t.enterText(find.byKey(const ValueKey('campo-cliente')), 'ed');
        await t.pump(const Duration(milliseconds: 300));
      },
    );
    await _capturar(
      t,
      'cobranzas_texto_sin_elegir',
      antes: (t) async {
        await abrir(t, 'Cheques de cobranza');
        await t.enterText(find.byKey(const ValueKey('campo-cliente')), 'zzzz');
        await t.pump(const Duration(milliseconds: 300));
        FocusManager.instance.primaryFocus?.unfocus();
        await tocar(t, boton('Generar PDF'));
      },
    );
  });

  testWidgets('custodio', (t) async {
    await _capturar(
      t,
      'custodio_escritorio',
      antes: (t) => abrir(t, 'Cheques en custodia'),
    );
    await _capturar(
      t,
      'custodio_telefono',
      tam: telefono,
      antes: (t) => abrir(t, 'Cheques en custodia', movil: true),
    );
  });

  testWidgets('ultimo recibo', (t) async {
    await _capturar(
      t,
      'ultimo_recibo_escritorio',
      antes: (t) => abrir(t, 'Recibo del último cheque'),
    );
    await _capturar(
      t,
      'ultimo_recibo_telefono_error',
      tam: telefono,
      repo:
          _repo()
            ..errorReporte = Exception(
              'Usted todavia no registro ningun cheque en esta sucursal.\n'
              'Registre uno y vuelva a pedir el recibo.',
            ),
      antes: (t) async {
        await abrir(t, 'Recibo del último cheque', movil: true);
        await tocar(t, boton('Generar PDF'));
      },
    );
  });

  testWidgets('reimprimir traspaso', (t) async {
    await _capturar(
      t,
      'reimprimir_escritorio',
      antes: (t) => abrir(t, 'Reimprimir traspaso'),
    );
    await _capturar(
      t,
      'reimprimir_hora_elegida',
      antes: (t) async {
        await abrir(t, 'Reimprimir traspaso');
        await tocar(t, find.byKey(const ValueKey('hora-91')));
      },
    );
    await _capturar(
      t,
      'reimprimir_sin_traspasos',
      repo: _repo()..horasDeTraspaso = const [],
      antes: (t) => abrir(t, 'Reimprimir traspaso'),
    );
    await _capturar(
      t,
      'reimprimir_telefono',
      tam: telefono,
      antes: (t) async {
        await abrir(t, 'Reimprimir traspaso', movil: true);
        await tocar(t, find.byKey(const ValueKey('hora-95')));
      },
    );
  });

  testWidgets('nomina del traspaso', (t) async {
    Future<void> traspasar(WidgetTester t) async {
      // En escritorio, «Traspaso» esta dentro del menu «Custodia»; en el
      // telefono ya viene con el menu de la barra abierto.
      if (find.text('Custodia').evaluate().isNotEmpty) {
        await tocar(t, find.text('Custodia'));
      }
      await tocar(t, find.text('Traspaso'));
      await tocar(t, find.text('Generar'));
    }

    await _capturar(t, 'nomina_hecho_escritorio', antes: traspasar);
    await _capturar(
      t,
      'nomina_error_escritorio',
      repo:
          _repo()
            ..errorReporte = Exception(
              'No se pudo armar la nomina.\nIntente de nuevo en un momento.',
            ),
      antes: (t) async {
        await traspasar(t);
        await tocar(t, find.text('Imprimir nómina (PDF)'));
      },
    );
    await _capturar(
      t,
      'nomina_hecho_telefono_150',
      tam: telefono,
      escala: 1.5,
      antes: (t) async {
        await tocar(t, menuTelefono);
        await traspasar(t);
      },
    );
  });
}
