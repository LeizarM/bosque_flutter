// Capturas de la linea de estado del talonario en el formulario de cheque, para
// mirarlas.
//
// NO es una prueba: no afirma nada y `flutter test` no la levanta solo (el
// nombre no termina en _test.dart). Se corre a mano:
//
//   flutter test test/capturas/capturas_talonario_cheques.dart --dart-define=CAPTURAS=<carpeta>
//
// Usa el repositorio falso de test/fakes (datos de ejemplo, sin backend) y las
// fuentes reales del proyecto. Reproduce el caso real: ER1076 / 3752 en un
// cheque de ESPPAPEL, cuando ese talonario es de IMPEXPAP.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/aviso_talonario_cheque.dart';

import '../fakes/arnes_cheques.dart';
import '../fakes/repositorio_cheques.dart';

const _salida = String.fromEnvironment(
  'CAPTURAS',
  defaultValue: 'build/capturas_talonario_cheques',
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

const _mensajeReal =
    'El talonario «ER1076» no pertenece a la empresa ESPPAPEL: está registrado '
    'en la empresa IMPEXPAP (y el recibo 3752 sí está dentro de su numeración, '
    '3751 a 3800), y este cheque se está registrando en ESPPAPEL. Cambia la '
    'empresa en los filtros o usa un talonario de ESPPAPEL.';

const _detalle = 'Talonario ER1076 (IMPEXPAP): recibos del 3751 al 3800.';

RepositorioChequesFalso _repo() {
  return RepositorioChequesFalso(total: 0)
    ..clientesPorEmpresa = {
      5: [clienteDeCheque('E1', 'EDITORA MENDEZ LTDA.')],
    }
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

    Future<void> dejarQueCargue({int vueltas = 8}) async {
      for (var i = 0; i < vueltas; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await dejarQueCargue();
    if (antes != null) await antes(tester);

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

  Future<void> pasar(WidgetTester t, {int ms = 120, int vueltas = 6}) async {
    for (var i = 0; i < vueltas; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await t.pump(Duration(milliseconds: ms));
    }
  }

  Future<void> tocar(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    await pasar(t);
  }

  Future<void> cambiarAEsppapel(WidgetTester t) async {
    await tocar(t, comboEmpresa());
    await tocar(t, find.text('ESPPAPEL').last);
  }

  Finder entrada(String id) => find.descendant(
    of: find.byKey(ValueKey('editable-$id')),
    matching: find.byType(TextFormField),
  );

  /// Abre el alta en ESPPAPEL, llena lo basico y escribe el par. No deja correr
  /// la espera: [esperar] dice cuanto pasa despues.
  Future<void> altaConPar(
    WidgetTester t, {
    required bool telefonoChico,
    required Duration esperar,
  }) async {
    await cambiarAEsppapel(t);
    await tocar(
      t,
      telefonoChico ? find.byTooltip('Registrar cheque') : find.text('Registrar'),
    );
    await t.enterText(entrada('nroCheque'), '480123');
    await t.enterText(entrada('monto'), '1500');
    await t.enterText(entrada('aOrdenDe'), 'EDITORA MENDEZ');
    await t.enterText(entrada('talonario'), 'ER1076');
    await t.pump();
    await t.enterText(entrada('recibo'), '3752');
    await t.pump();
    if (esperar > Duration.zero) await t.pump(esperar);
    await pasar(t, vueltas: 3);
    // Deja a la vista la linea y los dos campos.
    await t.ensureVisible(entrada('recibo'));
    await pasar(t, vueltas: 2);
  }

  Future<void> nunca(RepositorioChequesFalso r) async {
    r.alValidarTalonario =
        (_, _, _) => Completer<TalonarioValidacionEntity>().future;
  }

  final casos = <String, void Function(RepositorioChequesFalso)>{
    'valido': (r) => r.respuestaTalonario = const TalonarioValidacionEntity(
      valido: true,
      detalle: _detalle,
    ),
    'invalido': (r) => r.respuestaTalonario = const TalonarioValidacionEntity(
      valido: false,
      mensaje: _mensajeReal,
    ),
    'no_comprobado': (r) => r.errorTalonario = Exception('sin red'),
  };

  testWidgets('comprobando', (t) async {
    for (final (nombre, tam, escala) in [
      ('escritorio', const Size(1440, 900), 1.0),
      ('tablet', tablet, 1.0),
      ('telefono', telefono, 1.0),
      ('telefono_150', telefono, 1.5),
    ]) {
      final r = _repo();
      await nunca(r);
      await _capturar(
        t,
        'comprobando_$nombre',
        r,
        tam: tam,
        escala: escala,
        antes:
            (t) => altaConPar(
              t,
              telefonoChico: tam.width < 600,
              esperar: const Duration(milliseconds: 700),
            ),
      );
    }
  });

  for (final c in casos.entries) {
    testWidgets(c.key, (t) async {
      for (final (nombre, tam, escala) in [
        ('escritorio', const Size(1440, 900), 1.0),
        ('tablet', tablet, 1.0),
        ('telefono', telefono, 1.0),
        ('telefono_150', telefono, 1.5),
      ]) {
        final r = _repo();
        c.value(r);
        await _capturar(
          t,
          '${c.key}_$nombre',
          r,
          tam: tam,
          escala: escala,
          antes:
              (t) => altaConPar(
                t,
                telefonoChico: tam.width < 600,
                esperar: const Duration(milliseconds: 700),
              ),
        );
      }
    });
  }

  // El texto de las claves se usa para comprobar, de paso, que la linea esta.
  testWidgets('las lineas existen', (t) async {
    final r = _repo();
    casos['invalido']!(r);
    await _capturar(
      t,
      'invalido_comprobacion',
      r,
      antes: (t) async {
        await altaConPar(
          t,
          telefonoChico: false,
          esperar: const Duration(milliseconds: 700),
        );
        expect(find.byKey(claveAvisoTalonarioInvalido), findsOneWidget);
      },
    );
  });
}
