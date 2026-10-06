// Capturas de la fase 2b (traspaso, custodia y Bancos), para mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_custodia_bancos.dart --dart-define=CAPTURAS=<carpeta>
//
// Usa los repositorios falsos de test/fakes (datos de ejemplo, sin backend ni
// login) y las fuentes reales del proyecto: con la de prueba de Flutter cada
// letra es un rectangulo y no se puede juzgar nada.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/cheque_resumen_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';
import 'package:bosque_flutter/presentation/screens/bancos/bancos_screen.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';

import '../fakes/arnes_bancos.dart';
import '../fakes/arnes_cheques.dart';
import '../fakes/repositorio_bancos.dart';
import '../fakes/repositorio_cheques.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_custodia_bancos',
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

RepositorioChequesFalso _repoCheques() {
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
    ..responsables = const [
      PersonalChequeEntity(
        codEmpleado: 12,
        nombreCompleto: 'JUAN CARLOS PEREZ',
      ),
      PersonalChequeEntity(codEmpleado: 13, nombreCompleto: 'ANA MARIA ROJAS'),
    ]
    ..chequesCustodia = [
      for (var i = 1; i <= 7; i++)
        chequeFalso(
          i,
          cliente: clientes[i % clientes.length],
          monto: 1250.5 * i,
          nroCheque: '${480000 + i * 37}',
          banco: i % 2 == 0 ? 'BANCO UNION' : 'BANCO MERCANTIL SANTA CRUZ',
        ),
    ]
    ..chequesDarCustodia = [
      for (var i = 1; i <= 9; i++)
        ChequeResumenEntity(
          codCheque: BigInt.from(i),
          datoCheque:
              'Nro Cheque : ${480000 + i * 37}, Cliente : ${clientes[i % clientes.length]}, '
              'Monto (BS) : ${(1250.5 * i).toStringAsFixed(2)}',
        ),
    ]
    ..entregas = [
      EntregaChequeEntity(
        codAccion: BigInt.from(88),
        hora: '09:15 · Entregado a JUAN CARLOS PEREZ',
      ),
      EntregaChequeEntity(
        codAccion: BigInt.from(89),
        hora: '16:40 · Entregado a ANA MARIA ROJAS',
      ),
    ];
  return r;
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre,
  Widget Function(RepositorioChequesFalso, RepositorioBancosFalso) construir, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester tester)? antes,
  double escala = 1,
  RepositorioChequesFalso? repoCheques,
  RepositorioBancosFalso? repoBancos,
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
        child: construir(
          repoCheques ?? _repoCheques(),
          repoBancos ??
              RepositorioBancosFalso(
                bancos: [
                  bancoFalso(8, 'BANCO MERCANTIL SANTA CRUZ'),
                  bancoFalso(5, 'BANCO NACIONAL DE BOLIVIA'),
                  bancoFalso(7, 'BANCO UNION'),
                  bancoFalso(12, 'BISA'),
                  bancoFalso(3, 'BANCO GANADERO'),
                  bancoFalso(14, "BANCO D'ORO / SUCURSAL CENTRAL"),
                ],
              ),
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

Widget _cheques(RepositorioChequesFalso r, RepositorioBancosFalso _) =>
    appCheques(hijo: const ChequesScreen(), repo: r, permisos: permisosAdmin);

Widget _bancos(
  RepositorioChequesFalso _,
  RepositorioBancosFalso b, {
  PermisosBanco permisos = permisosBancoAdmin,
}) => appBancos(hijo: const BancosScreen(), repo: b, permisos: permisos);

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

  Future<void> elegirResponsable(WidgetTester t) async {
    await tocar(
      t,
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(DropdownButtonFormField<int>),
      ),
    );
    await t.tap(find.text('JUAN CARLOS PEREZ').last);
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('barra de cheques', (t) async {
    await _capturar(t, 'barra_escritorio', _cheques);
    await _capturar(t, 'barra_tablet', _cheques, tam: tablet);
    await _capturar(
      t,
      'barra_telefono_menu',
      _cheques,
      tam: telefono,
      antes: (t) => tocar(t, find.widgetWithIcon(IconButton, Icons.swap_horiz)),
    );
  });

  testWidgets('traspaso', (t) async {
    Future<void> abrir(WidgetTester t) => tocar(t, find.text('Traspaso'));
    await _capturar(t, 'traspaso_escritorio', _cheques, antes: abrir);
    await _capturar(
      t,
      'traspaso_telefono',
      _cheques,
      tam: telefono,
      escala: 1.5,
      antes: (t) async {
        await tocar(t, find.widgetWithIcon(IconButton, Icons.swap_horiz));
        await tocar(t, find.text('Traspaso'));
      },
    );
    await _capturar(
      t,
      'traspaso_hecho',
      _cheques,
      antes: (t) async {
        await abrir(t);
        await tocar(t, find.text('Generar'));
      },
    );
    final conError =
        _repoCheques()
          ..errorEscritura = Exception(
            'No tiene permisos para modificar datos de otras sucursales\n'
            'No hay cheques para traspasar.',
          );
    await _capturar(
      t,
      'traspaso_error',
      _cheques,
      repoCheques: conError,
      antes: (t) async {
        await abrir(t);
        await tocar(t, find.text('Generar'));
      },
    );
  });

  testWidgets('a custodio', (t) async {
    Future<void> abrir(WidgetTester t) => tocar(t, find.text('A Custodio'));
    await _capturar(t, 'custodio_escritorio', _cheques, antes: abrir);
    await _capturar(
      t,
      'custodio_escritorio_marcados',
      _cheques,
      antes: (t) async {
        await abrir(t);
        await elegirResponsable(t);
        await tocar(t, find.byKey(const ValueKey('marcar-todos')));
        await tocar(t, find.byKey(const ValueKey('custodia-3')));
      },
    );
    await _capturar(
      t,
      'custodio_telefono_marcados',
      _cheques,
      tam: telefono,
      antes: (t) async {
        await tocar(t, find.widgetWithIcon(IconButton, Icons.swap_horiz));
        await tocar(t, find.text('A Custodio'));
        await elegirResponsable(t);
        await tocar(t, find.byKey(const ValueKey('custodia-1')));
        await tocar(t, find.byKey(const ValueKey('custodia-2')));
      },
    );
    await _capturar(
      t,
      'custodio_telefono_150',
      _cheques,
      tam: telefono,
      escala: 1.5,
      antes: (t) async {
        await tocar(t, find.widgetWithIcon(IconButton, Icons.swap_horiz));
        await tocar(t, find.text('A Custodio'));
      },
    );
  });

  testWidgets('dar custodia', (t) async {
    Future<void> abrir(WidgetTester t) => tocar(t, find.text('Dar Custodia'));
    await _capturar(t, 'dar_paso1_escritorio', _cheques, antes: abrir);
    await _capturar(
      t,
      'dar_paso1_vacio',
      _cheques,
      repoCheques: _repoCheques()..entregas = const [],
      antes: abrir,
    );
    await _capturar(
      t,
      'dar_paso2_escritorio',
      _cheques,
      antes: (t) async {
        await abrir(t);
        await tocar(t, find.byKey(const ValueKey('entrega-88')));
        await tocar(t, find.text('Siguiente'));
        await tocar(t, find.byKey(const ValueKey('cheque-3')));
      },
    );
    await _capturar(
      t,
      'dar_paso2_telefono',
      _cheques,
      tam: telefono,
      antes: (t) async {
        await tocar(t, find.widgetWithIcon(IconButton, Icons.swap_horiz));
        await tocar(t, find.text('Dar Custodia'));
        await tocar(t, find.byKey(const ValueKey('entrega-89')));
        await tocar(t, find.text('Siguiente'));
        await tocar(t, find.byKey(const ValueKey('cheque-2')));
      },
    );
  });

  testWidgets('bancos', (t) async {
    await _capturar(t, 'bancos_escritorio', _bancos);
    await _capturar(t, 'bancos_tablet', _bancos, tam: tablet);
    await _capturar(t, 'bancos_telefono', _bancos, tam: telefono);
    await _capturar(
      t,
      'bancos_telefono_150',
      _bancos,
      tam: telefono,
      escala: 1.5,
    );
    await _capturar(
      t,
      'bancos_sin_permisos',
      (r, b) => _bancos(r, b, permisos: permisosBancoNinguno),
    );
    await _capturar(
      t,
      'bancos_vacio',
      _bancos,
      repoBancos: RepositorioBancosFalso(bancos: const []),
    );
    await _capturar(
      t,
      'bancos_error',
      _bancos,
      repoBancos:
          RepositorioBancosFalso()
            ..errorLectura = Exception('No tiene permiso para esta accion.'),
    );
  });

  testWidgets('bancos: formulario y baja', (t) async {
    await _capturar(
      t,
      'banco_form_escritorio',
      _bancos,
      antes: (t) => tocar(t, find.text('Nuevo')),
    );
    await _capturar(
      t,
      'banco_form_error_telefono',
      _bancos,
      tam: telefono,
      antes: (t) async {
        await tocar(t, find.byTooltip('Nuevo banco'));
        await t.enterText(
          find.byKey(const ValueKey('campo-nombre-banco')),
          'BANCO S.A.',
        );
        await tocar(t, find.widgetWithText(FilledButton, 'Registrar banco'));
      },
    );
    await _capturar(
      t,
      'banco_eliminar_confirmacion',
      _bancos,
      antes: (t) async {
        await tocar(
          t,
          find.descendant(
            of: find.byKey(const ValueKey('banco-7')),
            matching: find.byTooltip('Eliminar'),
          ),
        );
      },
    );
    await _capturar(
      t,
      'banco_eliminar_error',
      _bancos,
      repoBancos:
          RepositorioBancosFalso()
            ..errorEscritura = Exception(
              'No se puede eliminar el banco: tiene registros relacionados en Depositos o Pagos al Exterior.',
            ),
      antes: (t) async {
        await tocar(
          t,
          find.descendant(
            of: find.byKey(const ValueKey('banco-7')),
            matching: find.byTooltip('Eliminar'),
          ),
        );
        await tocar(t, find.widgetWithText(FilledButton, 'Eliminar banco'));
      },
    );
  });
}
