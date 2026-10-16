// Capturas del archivo de documentos, para mirarlas. NO es una prueba: no afirma
// nada y `flutter test` no la levanta solo. Se corre a mano:
//   flutter test test/capturas/capturas_archivo_documental.dart --dart-define=CAPTURAS=<carpeta>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/contenido_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/destruccion_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_documento_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/domain/entities/prestamo_documento_entity.dart';
import 'package:bosque_flutter/presentation/screens/archivo-documental/archivo_documental_screen.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/fotos_caja.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../fakes/repositorio_archivo_documental.dart';
import '../fakes/repositorio_depositos.dart' show loginAdminFalso;

const _salida = String.fromEnvironment('CAPTURAS', defaultValue: 'build/capturas_archivo');

/// Una foto dibujada (cartón, estante y la etiqueta de la caja) para ver la
/// miniatura y el visor con algo parecido a una foto real.
late Uint8List _foto;

Future<Uint8List> _fotoDeCarton() async {
  const w = 1200.0, h = 900.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFC49A6C));
  c.drawRect(const Rect.fromLTWH(0, h * 0.68, w, h * 0.32), Paint()..color = const Color(0xFF7A5C40));
  c.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(w * 0.28, h * 0.16, w * 0.44, h * 0.34), const Radius.circular(14)),
    Paint()..color = const Color(0xFFF7F3E8),
  );
  final tp = TextPainter(
    text: const TextSpan(
      text: 'CAJA 2 ACHOCALLA',
      style: TextStyle(color: Color(0xFF263238), fontSize: 72, fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w * 0.44);
  tp.paint(c, Offset(w / 2 - tp.width / 2, h * 0.33 - tp.height / 2));
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// La caja 2 con dos fotos y un PDF (la primera foto es la portada), un
/// documento prestado y su historial; en la caja 1, un documento destruido.
RepositorioArchivoFalso _repo() {
  final r = RepositorioArchivoFalso()..bytesFoto = _foto;
  r.fotos.addAll(const [
    FotoCajaEntity(codFoto: 7, codCaja: 2, orden: 1, ruta: 'archivo-cajas/7.png'),
    FotoCajaEntity(codFoto: 8, codCaja: 2, orden: 2, ruta: 'archivo-cajas/8.png'),
    FotoCajaEntity(codFoto: 9, codCaja: 2, orden: 3, ruta: 'archivo-cajas/9.pdf'),
  ]);
  r.cajas[0] = const CajaArchivoEntity(
    codCaja: 1,
    codArchivo: 1,
    numero: 1,
    nombreArchivo: 'ACHOCALLA',
    lineas: 1,
    anioDesde: 2010,
    anioHasta: 2010,
    destruidos: 1,
  );
  r.cajas[1] = const CajaArchivoEntity(
    codCaja: 2,
    codArchivo: 1,
    numero: 2,
    nombreArchivo: 'ACHOCALLA',
    lineas: 2,
    fotos: 3,
    anioDesde: 2015,
    anioHasta: 2017,
    codFotoPortada: 7,
    rutaPortada: 'archivo-cajas/7.png',
    prestados: 1,
  );
  r.contenido[0] = const ContenidoCajaEntity(
    codContenido: 1,
    codCaja: 1,
    codTipoDocumento: 11,
    nombreTipoDocumento: 'Notas de remisión',
    detalle: 'Notas de remisión Suc. 8 enero 2010',
    gestion: '2010',
    anioDesde: 2010,
    anioHasta: 2010,
    situacion: ContenidoCajaEntity.destruida,
    fechaDestruccion: '15/10/2026 17:05',
  );
  r.contenido[2] = const ContenidoCajaEntity(
    codContenido: 3,
    codCaja: 2,
    codTipoDocumento: 10,
    nombreTipoDocumento: 'Facturas',
    detalle: 'Facturas Papirus talonarios 1 - 6',
    gestion: '2015 - 2017',
    anioDesde: 2015,
    anioHasta: 2017,
    situacion: ContenidoCajaEntity.prestada,
    codPrestamo: 50,
    prestadoA: 'LLANQUE VICTOR',
    fechaPrestamo: '16/10/2026 09:30',
  );
  // La entrega 12 se lleva un documento de la caja 2 y la caja 1 de OFICINA CENTRAL entera.
  r.cajas[2] = const CajaArchivoEntity(
    codCaja: 3,
    codArchivo: 2,
    numero: 1,
    estante: '1',
    fila: '1',
    nombreArchivo: 'OFICINA CENTRAL',
    lineas: 2,
    anioDesde: 2018,
    anioHasta: 2019,
    codPrestamoCaja: 51,
    prestadaA: 'LLANQUE VICTOR',
    fechaPrestamo: '16/10/2026 09:30',
    prestados: 2,
  );
  r.entregas.addAll(const [
    EntregaDocumentoEntity(
      codEntrega: 12,
      codEmpleado: 23,
      fechaEntrega: '16/10/2026 09:30',
      observacion: 'Revisión de auditoría externa',
      nombreEmpleado: 'LLANQUE VICTOR',
      cajas: 1,
      documentos: 1,
      pendientes: 2,
      nombreUsuario: 'JAIMES MARCELO',
    ),
    EntregaDocumentoEntity(
      codEntrega: 11,
      codEmpleado: 240,
      fechaEntrega: '14/10/2026 08:10',
      nombreEmpleado: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
      cajas: 1,
      fechaDevolucion: '15/10/2026 16:45',
      nombreUsuario: 'JAIMES MARCELO',
    ),
  ]);
  r.prestamos.addAll(const [
    PrestamoDocumentoEntity(
      codPrestamo: 51,
      codEntrega: 12,
      codCaja: 3,
      codEmpleado: 23,
      fechaEntrega: '16/10/2026 09:30',
      observacionEntrega: 'Revisión de auditoría externa',
      numeroCaja: 1,
      codArchivo: 2,
      nombreArchivo: 'OFICINA CENTRAL',
      nombreEmpleado: 'LLANQUE VICTOR',
      nombreUsuario: 'JAIMES MARCELO',
    ),
    PrestamoDocumentoEntity(
      codPrestamo: 50,
      codEntrega: 12,
      codCaja: 2,
      codContenido: 3,
      codEmpleado: 23,
      fechaEntrega: '16/10/2026 09:30',
      observacionEntrega: 'Revisión de auditoría externa',
      numeroCaja: 2,
      codArchivo: 1,
      nombreArchivo: 'ACHOCALLA',
      nombreTipoDocumento: 'Facturas',
      detalle: 'Facturas Papirus talonarios 1 - 6',
      gestion: '2015 - 2017',
      nombreEmpleado: 'LLANQUE VICTOR',
      nombreUsuario: 'JAIMES MARCELO',
    ),
    PrestamoDocumentoEntity(
      codPrestamo: 49,
      codEntrega: 11,
      codCaja: 2,
      codEmpleado: 240,
      fechaEntrega: '14/10/2026 08:10',
      fechaDevolucion: '15/10/2026 16:45',
      observacionDevolucion: 'Volvió completa',
      numeroCaja: 2,
      codArchivo: 1,
      nombreArchivo: 'ACHOCALLA',
      nombreEmpleado: 'CÁRDENAS RIVEROS VICTOR HUMBERTO',
      nombreUsuario: 'JAIMES MARCELO',
    ),
  ]);
  r.destrucciones.add(
    const DestruccionDocumentoEntity(
      codDestruccion: 70,
      codCaja: 1,
      codContenido: 1,
      fechaDestruccion: '15/10/2026 17:05',
      observacion: 'Plazo de guarda cumplido · triturado · acta 12/2026',
      numeroCaja: 1,
      codArchivo: 1,
      nombreArchivo: 'ACHOCALLA',
      nombreTipoDocumento: 'Notas de remisión',
      detalle: 'Notas de remisión Suc. 8 enero 2010',
      gestion: '2010',
      nombreUsuario: 'JAIMES MARCELO',
    ),
  );
  return r;
}

Future<void> _cargarFuentes() async {
  final porFamilia = <String, List<File>>{};
  for (final f in Directory('assets/fonts').listSync().whereType<File>()) {
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
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(iconos.readAsBytesSync())))).load();
  }
}

Future<void> _capturar(
  WidgetTester tester,
  String nombre, {
  Size tam = const Size(1440, 900),
  Future<void> Function(WidgetTester t)? antes,
  bool oscuro = false,
}) async {
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  debugDisableShadows = false;
  try {
    final clave = GlobalKey();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(loginAdminFalso)),
            archivoDocumentalRepositoryProvider.overrideWithValue(_repo()),
            camaraDisponibleProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: oscuro ? AppTheme(isDarkMode: true).getTheme() : AppTheme().getTheme(),
            locale: const Locale('es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder:
                (context, child) =>
                    ResponsiveBreakpoints.builder(child: child!, breakpoints: ResponsiveUtilsBosque.breakpoints),
            home: const Scaffold(body: ArchivoDocumentalScreen()),
          ),
        ),
      ),
    );
    Future<void> cargar() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await cargar();
    if (antes != null) {
      await antes(tester);
      await cargar();
    }
    await tester.runAsync(() async {
      final b = clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_salida/$nombre.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _abrirCaja2(WidgetTester t) => t.tap(find.text('Facturas').hitTestable().first);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _cargarFuentes();
    _foto = await _fotoDeCarton();
  });

  const telefono = Size(390, 844);

  testWidgets('listado', (t) async {
    await _capturar(t, 'listado_escritorio');
    await _capturar(t, 'listado_telefono', tam: telefono);
    await _capturar(t, 'listado_oscuro', oscuro: true);
    await _capturar(
      t,
      'busqueda_escritorio',
      antes: (t) => t.enterText(find.byType(TextField).first, 'facturas 2016'),
    );
  });

  testWidgets('detalle', (t) async {
    await _capturar(t, 'detalle_escritorio', antes: _abrirCaja2);
    await _capturar(t, 'detalle_telefono', tam: telefono, antes: _abrirCaja2);
    await _capturar(t, 'detalle_oscuro', oscuro: true, antes: _abrirCaja2);
  });

  Future<void> abrirVisor(WidgetTester t) async {
    await _abrirCaja2(t);
    for (var i = 0; i < 6; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.descendant(of: find.byType(FotosCaja), matching: find.byType(Image)).first);
  }

  testWidgets('visor de fotos', (t) async {
    await _capturar(t, 'visor_escritorio', antes: abrirVisor);
    await _capturar(t, 'visor_telefono', tam: telefono, antes: abrirVisor);
  });

  testWidgets('reportes', (t) async {
    await _capturar(t, 'reportes_escritorio', antes: (t) => t.tap(find.text('Reportes')));
    await _capturar(t, 'reportes_telefono', tam: telefono, antes: (t) => t.tap(find.byTooltip('Reportes en PDF')));
  });

  testWidgets('fichas', (t) async {
    await _capturar(
      t,
      'ficha_documento_escritorio',
      antes: (t) async {
        await _abrirCaja2(t);
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.text('Agregar documento'));
      },
    );
    await _capturar(t, 'catalogos_escritorio', antes: (t) => t.tap(find.text('Catálogos')));
    await _capturar(t, 'ficha_caja_telefono', tam: telefono, antes: (t) => t.tap(find.text('Nueva caja')));
    await _capturar(
      t,
      'ficha_archivo_escritorio',
      antes: (t) async {
        await t.tap(find.text('Catálogos'));
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.text('ACHOCALLA').hitTestable().first);
      },
    );
  });

  Future<void> bajarA(WidgetTester t, String texto) async {
    await t.scrollUntilVisible(find.text(texto), 300, scrollable: find.byType(Scrollable).first);
    await t.pump(const Duration(milliseconds: 200));
  }

  testWidgets('préstamos y destrucción', (t) async {
    Future<void> prestar(WidgetTester t) async {
      await _abrirCaja2(t);
      await t.pump(const Duration(milliseconds: 300));
      await bajarA(t, 'Prestar');
      await t.tap(find.text('Prestar'));
    }

    await _capturar(t, 'detalle_contenido_escritorio', antes: (t) async {
      await _abrirCaja2(t);
      await t.pump(const Duration(milliseconds: 300));
      await bajarA(t, 'Préstamos y destrucciones');
    });
    await _capturar(t, 'detalle_contenido_telefono', tam: telefono, antes: (t) async {
      await _abrirCaja2(t);
      await t.pump(const Duration(milliseconds: 300));
      await bajarA(t, 'Facturas Papirus talonarios 1 - 6');
    });
    await _capturar(t, 'prestar_escritorio', antes: prestar);
    await _capturar(t, 'prestar_telefono', tam: telefono, antes: prestar);
    await _capturar(t, 'destruir_escritorio', antes: (t) async {
      await _abrirCaja2(t);
      await t.pump(const Duration(milliseconds: 300));
      await bajarA(t, 'Destrucción');
      await t.tap(find.text('Destrucción'));
    });
    await _capturar(t, 'prestamos_escritorio', antes: (t) => t.tap(find.text('Préstamos (1)')));
    await _capturar(t, 'prestamos_telefono', tam: telefono, antes: (t) => t.tap(find.byIcon(Icons.outbox_outlined).first));
    await _capturar(t, 'prestamos_oscuro', oscuro: true, antes: (t) => t.tap(find.text('Préstamos (1)')));

    Future<void> Function(WidgetTester) nuevaEntrega(Finder prestamos) => (t) async {
      Future<void> asentar() async {
        for (var i = 0; i < 6; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await t.pump(const Duration(milliseconds: 100));
        }
      }

      await t.tap(prestamos);
      await asentar();
      await t.tap(find.text('Nuevo préstamo'));
      await asentar();
      await t.enterText(find.widgetWithText(TextField, 'Busca una caja o un documento'), 'achocalla 2');
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Facturas emisores septiembre 2016').first);
      await t.pump(const Duration(milliseconds: 300));
    };

    await _capturar(t, 'nueva_entrega_escritorio', antes: nuevaEntrega(find.text('Préstamos (1)')));
    await _capturar(
      t,
      'nueva_entrega_telefono',
      tam: telefono,
      antes: nuevaEntrega(find.byIcon(Icons.outbox_outlined).first),
    );
  });
}
