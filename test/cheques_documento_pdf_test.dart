import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart'
    show ErrorServidorCheque, MarcoPanelCheque;
import 'package:bosque_flutter/presentation/widgets/cheques/reportes_cheque.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// El documento PDF del cheque: el icono de la fila (tabla, menu y tarjeta, sin
/// permiso de boton), el dialogo (sin PDF, con PDF, validaciones, reemplazo con
/// confirmacion, errores del servidor, subida con progreso, ver y descargar) y
/// el panel del detalle.
///
/// Todo contra un repositorio falso, un visor de PDF falso y un selector de
/// archivos falso (`file_picker` no corre en las pruebas): nunca se probo contra
/// el servidor ni con el selector real.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  late VisorPdfFalso visor;
  late SelectorPdfFalso selector;

  final cod = BigInt.one;
  final conPdf = PdfChequeEstadoEntity(
    existe: true,
    nombreArchivo: '1.pdf',
    tamanoBytes: 120345,
    fechaModificacion: DateTime(2026, 10, 3, 14, 22, 10),
  );

  setUp(() {
    visor = VisorPdfFalso();
    selector = SelectorPdfFalso();
    repo = RepositorioChequesFalso(total: 0)
      ..cheques = [chequeFalso(1, descTipo: 'PAGO')];
  });

  Widget pantalla({PermisosCheque permisos = permisosNinguno}) => appCheques(
    hijo: const ChequesScreen(),
    repo: repo,
    permisos: permisos,
    extra: [
      visorPdfChequeProvider.overrideWithValue(visor.abrir),
      selectorPdfChequeProvider.overrideWithValue(selector.elegir),
    ],
  );

  // ── Ayudas ────────────────────────────────────────────────────────────────

  final dialogo = find.byType(Dialog);
  Finder enDialogo(Finder f) => find.descendant(of: dialogo, matching: f);

  /// Pulsa «Documento PDF» de la fila, donde este: icono suelto en la tabla o
  /// menu ⋮ (tabla angosta y tarjetas).
  Future<void> tocarAccionPdf(WidgetTester tester) async {
    final suelto = find.byTooltip('Documento PDF');
    if (suelto.evaluate().isNotEmpty) {
      await tester.tap(suelto.first);
    } else {
      await tester.tap(find.byTooltip('Acciones').first);
      await esperar(tester);
      await tester.tap(find.text('Documento PDF'));
    }
    await esperar(tester);
  }

  Future<void> abrirDialogo(
    WidgetTester tester, {
    double ancho = 1400,
    PermisosCheque permisos = permisosNinguno,
  }) async {
    await montar(tester, pantalla(permisos: permisos), ancho: ancho);
    await tocarAccionPdf(tester);
  }

  Finder boton(String clave) => find.byKey(ValueKey(clave));

  bool habilitado(WidgetTester tester, String clave) =>
      tester
          .widget<ButtonStyleButton>(
            find.descendant(
              of: boton(clave),
              matching: find.bySubtype<ButtonStyleButton>(),
            ),
          )
          .onPressed !=
      null;

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await esperar(tester);
  }

  /// Deja que corra el reloj del aviso (se retira solo a los pocos segundos) para
  /// que ningun temporizador quede pendiente al terminar la prueba.
  Future<void> dejarPasarAviso(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LA FILA
  // ═══════════════════════════════════════════════════════════════════════════

  group('la accion de la fila', () {
    testWidgets('en la tabla esta para todos, tambien sin ningun boton', (
      tester,
    ) async {
      for (final permisos in [permisosNinguno, permisosCajero, permisosAdmin]) {
        await montar(tester, pantalla(permisos: permisos), ancho: 1400);
        expect(
          find.byTooltip('Documento PDF'),
          findsOneWidget,
          reason: '$permisos',
        );
        // Un solo icono por fila: ni «Cargar» ni «Descargar» aparte.
        expect(find.byTooltip('Cargar Documento PDF'), findsNothing);
        expect(find.byTooltip('Descargar Documento PDF'), findsNothing);
        expect(
          find.widgetWithIcon(IconButton, Icons.picture_as_pdf_outlined),
          findsOneWidget,
        );
      }
    });

    testWidgets('el icono de la tabla abre el dialogo y consulta el estado', (
      tester,
    ) async {
      await abrirDialogo(tester);
      expect(dialogo, findsOneWidget);
      expect(enDialogo(find.text('Documento PDF')), findsOneWidget);
      expect(repo.consultasPdf, [cod]);
    });

    testWidgets('en el menu ⋮ de una tabla angosta tambien esta', (tester) async {
      // A 900 px un cajero ya no tiene sitio para sus tres iconos: van en un menu.
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 900);
      expect(find.byTooltip('Documento PDF'), findsNothing);
      await tester.tap(find.byTooltip('Acciones').first);
      await esperar(tester);
      expect(find.text('Documento PDF'), findsOneWidget);
      await tester.tap(find.text('Documento PDF'));
      await esperar(tester);
      expect(dialogo, findsOneWidget);
      expect(repo.consultasPdf, [cod]);
    });

    testWidgets('en la tarjeta del telefono esta en el menu, sin permisos', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 390);
      expect(find.byKey(const ValueKey('lista-tarjetas')), findsOneWidget);
      await tester.tap(find.byTooltip('Acciones'));
      await esperar(tester);
      expect(find.text('Documento PDF'), findsOneWidget);
      // Sin permisos no hay mas opciones que esa.
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Completar'), findsNothing);
      await tester.tap(find.text('Documento PDF'));
      await esperar(tester);
      expect(dialogo, findsOneWidget);
    });

    testWidgets('el menu de la tarjeta la ofrece junto a las demas', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 390);
      await tester.tap(find.byTooltip('Acciones'));
      await esperar(tester);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Completar'), findsOneWidget);
      expect(find.text('Documento PDF'), findsOneWidget);
    });

    testWidgets('con un cheque cerrado tambien: sin permiso y sin estado', (
      tester,
    ) async {
      repo.cheques = [chequeFalso(1, estado: 'CER', descTipo: 'PAGO')];
      await montar(tester, pantalla(), ancho: 1400);
      expect(find.byTooltip('Documento PDF'), findsOneWidget);
    });
  });

  // Los iconos de la tabla miden 28 px para que el del PDF (el cuarto de un
  // administrador) no esconda columnas en los anchos corrientes: aqui se fija lo
  // que se ve a 1280, 1400 y 1800 px para un administrador.
  group('columnas de la tabla con el icono del PDF', () {
    const todas = [
      '#',
      'Recepción',
      'Cliente',
      'Nro. cheque',
      'Banco',
      'A la orden de',
      'Monto',
      'F. cheque',
      'F. cobro',
      'Tipo',
      'Estado',
      'Entregado por',
    ];

    Set<String> visibles() {
      final tabla = find.byKey(const ValueKey('lista-tabla'));
      return {
        for (final c in todas)
          if (find.descendant(of: tabla, matching: find.text(c)).evaluate().isNotEmpty) c,
      };
    }

    testWidgets('un administrador tiene cuatro iconos y a 1800 px las 12 columnas', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosAdmin), ancho: 1800);
      expect(visibles(), todas.toSet());
      for (final t in ['Editar', 'Fecha de cobro', 'Completar', 'Documento PDF']) {
        expect(find.byTooltip(t), findsOneWidget, reason: t);
      }
      // En ese orden: el PDF queda siempre en el borde derecho.
      double x(String t) => tester.getCenter(find.byTooltip(t)).dx;
      expect(x('Editar'), lessThan(x('Fecha de cobro')));
      expect(x('Fecha de cobro'), lessThan(x('Completar')));
      expect(x('Completar'), lessThan(x('Documento PDF')));
    });

    testWidgets('a 1400 px un administrador pierde las mismas dos que antes', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosAdmin), ancho: 1400);
      expect(visibles(), todas.toSet()..removeAll({'#', 'Tipo'}));
      expect(find.byTooltip('Documento PDF'), findsOneWidget);
      expect(find.byTooltip('Acciones'), findsNothing);
    });

    testWidgets('a 1280 px un administrador pierde las mismas tres que antes', (
      tester,
    ) async {
      // Antes del icono del PDF: «#», «Tipo» y «Entregado por». Con iconos de
      // 36 px habria perdido tambien «F. cheque».
      await montar(tester, pantalla(permisos: permisosAdmin), ancho: 1280);
      expect(
        visibles(),
        todas.toSet()..removeAll({'#', 'Tipo', 'Entregado por'}),
      );
    });

    testWidgets('el rotulo «Acciones» cabe sobre un solo icono', (tester) async {
      final errores = await capturandoErrores(() async {
        await montar(tester, pantalla(), ancho: 1400);
      });
      expect(errores, isEmpty);
      expect(find.text('Acciones'), findsOneWidget);
      final rotulo = tester.getRect(find.text('Acciones'));
      final tabla = tester.getRect(find.byKey(const ValueKey('lista-tabla')));
      expect(rotulo.right, lessThanOrEqualTo(tabla.right));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EL DIALOGO: ESTADO
  // ═══════════════════════════════════════════════════════════════════════════

  group('el dialogo: estado', () {
    testWidgets('sin PDF: lo dice y solo ofrece cargar', (tester) async {
      await abrirDialogo(tester);

      expect(enDialogo(find.text('Este cheque no tiene PDF todavía')), findsOneWidget);
      expect(enDialogo(find.text('Hay un PDF cargado')), findsNothing);
      expect(boton('boton-ver-pdf'), findsNothing);
      expect(enDialogo(find.text('Cargar PDF')), findsOneWidget);
      expect(enDialogo(find.text('Reemplazar PDF')), findsNothing);
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
      // Dice las reglas antes de que el usuario elija nada.
      expect(enDialogo(find.textContaining('Solo archivos PDF de hasta 2 MB')), findsOneWidget);
    });

    testWidgets('con PDF: tamano y fecha, y ofrece ver o reemplazar', (tester) async {
      repo.estadoPdfDeTodos = conPdf;
      await abrirDialogo(tester);

      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      expect(enDialogo(find.text('120 KB · 03/10/2026 14:22')), findsOneWidget);
      expect(enDialogo(find.text('1.pdf')), findsOneWidget);
      expect(enDialogo(find.text('Ver / Descargar')), findsOneWidget);
      expect(enDialogo(find.text('Reemplazar PDF')), findsOneWidget);
      expect(enDialogo(find.text('Cargar PDF')), findsNothing);
      expect(habilitado(tester, 'boton-ver-pdf'), isTrue);
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
    });

    testWidgets('la fecha del servidor se muestra tal cual, sin cambiar la hora', (
      tester,
    ) async {
      // Sin zona: el servidor la manda en su hora y no se convierte.
      repo.estadoPdfDeTodos = PdfChequeEstadoEntity(
        existe: true,
        nombreArchivo: '1.pdf',
        tamanoBytes: 2000,
        fechaModificacion: DateTime.parse('2026-10-03T23:59:10'),
      );
      await abrirDialogo(tester);
      expect(enDialogo(find.text('2 KB · 03/10/2026 23:59')), findsOneWidget);
    });

    testWidgets('si el servidor no informa tamano ni fecha, solo dice que hay PDF', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = const PdfChequeEstadoEntity(
        existe: true,
        nombreArchivo: '1.pdf',
      );
      await abrirDialogo(tester);
      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      expect(enDialogo(find.textContaining('KB')), findsNothing);
    });

    testWidgets('la cabecera trae nro, cliente, banco y monto del cheque', (
      tester,
    ) async {
      repo.cheques = [
        chequeFalso(
          1,
          cliente: 'EDITORA MENDEZ',
          banco: 'BANCO UNION',
          nroCheque: '445566',
          monto: 15400.5,
        ),
      ];
      await abrirDialogo(tester);
      final cabecera = find.byKey(const ValueKey('cabecera-cheque-pdf'));
      expect(cabecera, findsOneWidget);
      for (final t in ['Cheque 445566', 'EDITORA MENDEZ', 'BANCO UNION', '15,400.50', 'Bs']) {
        expect(
          find.descendant(of: cabecera, matching: find.text(t)),
          findsWidgets,
          reason: t,
        );
      }
    });

    testWidgets('mientras consulta lo dice y los botones no actuan a ciegas', (
      tester,
    ) async {
      final espera = Completer<void>();
      repo.esperaEstadoPdf = espera.future;
      repo.estadoPdfDeTodos = conPdf;
      await abrirDialogo(tester);

      expect(enDialogo(find.text('Consultando el PDF del cheque…')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf'), isFalse);
      expect(boton('boton-ver-pdf'), findsNothing);

      espera.complete();
      await esperar(tester);
      expect(enDialogo(find.text('Consultando el PDF del cheque…')), findsNothing);
      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
    });

    testWidgets('si la consulta falla muestra el motivo completo y se puede reintentar', (
      tester,
    ) async {
      repo.errorEstadoPdf = Exception(
        'La carpeta de los PDF de cheques no está disponible.\n'
        'Avisa a Sistemas.',
      );
      await abrirDialogo(tester);

      expect(
        enDialogo(find.text('La carpeta de los PDF de cheques no está disponible.')),
        findsOneWidget,
      );
      expect(enDialogo(find.text('Avisa a Sistemas.')), findsOneWidget);
      // Sin saber si hay PDF no se carga: no se podria avisar del reemplazo.
      expect(habilitado(tester, 'boton-cargar-pdf'), isFalse);
      expect(boton('boton-ver-pdf'), findsNothing);

      repo.errorEstadoPdf = null;
      repo.estadoPdfDeTodos = conPdf;
      await tocar(tester, enDialogo(find.text('Reintentar')));
      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
      expect(repo.consultasPdf, hasLength(2));
    });

    testWidgets('Cerrar cierra el dialogo', (tester) async {
      await abrirDialogo(tester);
      await tester.tap(enDialogo(find.text('Cerrar')));
      await esperar(tester);
      expect(dialogo, findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EL DIALOGO: VER / DESCARGAR
  // ═══════════════════════════════════════════════════════════════════════════

  group('el dialogo: ver / descargar', () {
    testWidgets('baja el PDF del cheque y lo abre en el visor con su nombre', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = conPdf;
      repo.pdfDelCheque = Uint8List.fromList([1, 2, 3, 4]);
      await abrirDialogo(tester);

      await tocar(tester, boton('boton-ver-pdf'));

      expect(repo.descargasPdf, [cod]);
      expect(visor.abiertos, hasLength(1));
      expect(visor.abiertos.single.bytes, [1, 2, 3, 4]);
      // El nombre que el servidor ofrece al descargar, armado en el cliente.
      expect(visor.abiertos.single.nombreArchivo, '1_.pdf');
      expect(visor.abiertos.single.titulo, contains('Cheque 100001'));
      // El dialogo sigue abierto debajo del visor.
      expect(dialogo, findsOneWidget);
    });

    testWidgets('mientras baja, los botones se bloquean y Cerrar tambien', (
      tester,
    ) async {
      final espera = Completer<void>();
      repo.estadoPdfDeTodos = conPdf;
      repo.esperaDescargaPdf = espera.future;
      await abrirDialogo(tester);

      await tester.tap(boton('boton-ver-pdf'));
      await esperar(tester);

      expect(enDialogo(find.text('Descargando…')), findsOneWidget);
      expect(habilitado(tester, 'boton-ver-pdf'), isFalse);
      expect(habilitado(tester, 'boton-cargar-pdf'), isFalse);
      final cerrar = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cerrar'),
      );
      expect(cerrar.onPressed, isNull);

      espera.complete();
      await esperar(tester);
      expect(habilitado(tester, 'boton-ver-pdf'), isTrue);
      expect(visor.abiertos, hasLength(1));
    });

    testWidgets('un doble toque no baja el PDF dos veces', (tester) async {
      final espera = Completer<void>();
      repo.estadoPdfDeTodos = conPdf;
      repo.esperaDescargaPdf = espera.future;
      await abrirDialogo(tester);

      await tester.tap(boton('boton-ver-pdf'));
      await tester.pump();
      await tester.tap(boton('boton-ver-pdf'), warnIfMissed: false);
      espera.complete();
      await esperar(tester);
      expect(repo.descargasPdf, hasLength(1));
    });

    testWidgets('si no se puede bajar, el error sale completo con el dialogo abierto', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = conPdf;
      repo.errorDescargaPdf = Exception(
        'No se encontró el archivo PDF del cheque 1.\nCárgalo de nuevo.',
      );
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-ver-pdf'));

      expect(
        enDialogo(find.text('No se encontró el archivo PDF del cheque 1.')),
        findsOneWidget,
      );
      expect(enDialogo(find.text('Cárgalo de nuevo.')), findsOneWidget);
      expect(visor.abiertos, isEmpty);
      expect(dialogo, findsOneWidget);
      // Y se vuelve a consultar el estado: quiza el archivo ya no esta.
      expect(repo.consultasPdf, hasLength(2));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EL DIALOGO: CARGAR
  // ═══════════════════════════════════════════════════════════════════════════

  group('el dialogo: cargar', () {
    testWidgets('sin PDF: valida, sube sin confirmar y vuelve a consultar', (
      tester,
    ) async {
      selector.archivo = archivoPdfFalso('Factura 7.pdf', tamano: 120000);
      await abrirDialogo(tester);

      await tocar(tester, boton('boton-cargar-pdf'));

      expect(selector.aperturas, 1);
      // Sin PDF previo no hay nada que reemplazar: no se pregunta.
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.subidasPdf, hasLength(1));
      final s = repo.subidasPdf.single;
      expect(s.codCheque, cod);
      expect(s.nombre, 'Factura 7.pdf');
      expect(s.bytes, selector.archivo!.bytes);

      // Se vuelve a consultar y ahora hay PDF.
      expect(repo.consultasPdf, hasLength(2));
      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      expect(enDialogo(find.text('120 KB · 03/10/2026 14:22')), findsOneWidget);
      expect(enDialogo(find.text('Reemplazar PDF')), findsOneWidget);
      expect(boton('boton-ver-pdf'), findsOneWidget);
      expect(find.text('PDF cargado.'), findsOneWidget);
      expect(find.text('PDF reemplazado.'), findsNothing);
      await dejarPasarAviso(tester);
    });

    testWidgets('si el usuario cancela el selector no pasa nada', (tester) async {
      selector.archivo = null;
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(selector.aperturas, 1);
      expect(repo.subidasPdf, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      expect(enDialogo(find.byType(ErrorServidorCheque)), findsNothing);
    });

    testWidgets('la extension no distingue mayusculas', (tester) async {
      selector.archivo = archivoPdfFalso('ESCANEO.PDF');
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(repo.subidasPdf.single.nombre, 'ESCANEO.PDF');
      await dejarPasarAviso(tester);
    });

    testWidgets('el limite es 2.010.000 bytes, inclusive', (tester) async {
      selector.archivo = archivoPdfFalso('justo.pdf', tamano: 2010000);
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(repo.subidasPdf, hasLength(1));
      await dejarPasarAviso(tester);
    });

    testWidgets('lo que no es PDF no se envia y dice que hacer', (tester) async {
      selector.archivo = archivoPdfFalso('contrato.docx');
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));

      expect(repo.subidasPdf, isEmpty);
      expect(
        enDialogo(
          find.text(
            'El archivo «contrato.docx» no es un PDF. '
            'Elige un archivo con extensión .pdf.',
          ),
        ),
        findsOneWidget,
      );
      // El boton sigue disponible para elegir otro.
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
    });

    testWidgets('un archivo vacio no se envia', (tester) async {
      selector.archivo = ArchivoPdfElegido(nombre: 'vacio.pdf', bytes: Uint8List(0));
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(repo.subidasPdf, isEmpty);
      expect(enDialogo(find.textContaining('está vacío (0 bytes)')), findsOneWidget);
    });

    testWidgets('un archivo muy pesado dice cuanto pesa y el limite en MB', (
      tester,
    ) async {
      selector.archivo = archivoPdfFalso('escaneo.pdf', tamano: 3400000);
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));

      expect(repo.subidasPdf, isEmpty);
      expect(
        enDialogo(
          find.text(
            'El archivo «escaneo.pdf» pesa 3,4 MB y el límite es 2,0 MB. '
            'Comprímelo o elige un PDF más liviano.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('un archivo que la plataforma no pudo leer se dice', (tester) async {
      selector.archivo = const ArchivoPdfElegido(nombre: 'raro.pdf', bytes: null);
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(repo.subidasPdf, isEmpty);
      expect(enDialogo(find.textContaining('No se pudo leer el archivo «raro.pdf»')), findsOneWidget);
    });

    testWidgets('si el selector falla lo dice y no rompe el dialogo', (tester) async {
      selector.error = Exception('sin permiso de almacenamiento');
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(repo.subidasPdf, isEmpty);
      expect(enDialogo(find.textContaining('No se pudo abrir el selector de archivos')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
    });

    testWidgets('un motivo de rechazo se quita al elegir otro archivo', (tester) async {
      selector.archivo = archivoPdfFalso('mal.txt');
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(enDialogo(find.byType(ErrorServidorCheque)), findsOneWidget);

      selector.archivo = archivoPdfFalso('bien.pdf');
      await tocar(tester, boton('boton-cargar-pdf'));
      expect(enDialogo(find.byType(ErrorServidorCheque)), findsNothing);
      expect(repo.subidasPdf.single.nombre, 'bien.pdf');
      await dejarPasarAviso(tester);
    });

    testWidgets('el error del servidor sale completo y el PDF anterior sigue', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = conPdf;
      repo.errorSubidaPdf = Exception(
        'El archivo no es un PDF válido.\nExporta el documento de nuevo.',
      );
      selector.archivo = archivoPdfFalso('nuevo.pdf');
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      // Pide confirmar porque ya hay uno: se confirma y el servidor rechaza.
      await tocar(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reemplazar PDF'),
        ),
      );

      expect(repo.subidasPdf, hasLength(1));
      expect(enDialogo(find.text('El archivo no es un PDF válido.')), findsOneWidget);
      expect(enDialogo(find.text('Exporta el documento de nuevo.')), findsOneWidget);
      expect(dialogo, findsOneWidget);
      // El estado no cambio y los botones vuelven a estar disponibles.
      expect(enDialogo(find.text('120 KB · 03/10/2026 14:22')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
      expect(habilitado(tester, 'boton-ver-pdf'), isTrue);
    });

    testWidgets('mientras sube hay progreso y todo se bloquea', (tester) async {
      final espera = Completer<void>();
      repo.esperaSubidaPdf = espera.future;
      repo.avancesDeSubidaPdf = const [(50, 100)];
      selector.archivo = archivoPdfFalso('Factura 7.pdf');
      await abrirDialogo(tester);

      await tester.tap(boton('boton-cargar-pdf'));
      await esperar(tester);

      expect(find.byKey(const ValueKey('progreso-subida-pdf')), findsOneWidget);
      expect(enDialogo(find.text('Subiendo «Factura 7.pdf» · 50 %')), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(const ValueKey('progreso-subida-pdf')),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(barra.value, 0.5);
      expect(enDialogo(find.text('Subiendo…')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf'), isFalse);
      final cerrar = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cerrar'),
      );
      expect(cerrar.onPressed, isNull);

      // El boton de cerrar de la cabecera y Esc tampoco cierran a medio subir.
      await tester.tap(find.byTooltip('Cerrar (Esc)'));
      await esperar(tester);
      expect(dialogo, findsOneWidget);

      espera.complete();
      await esperar(tester);
      expect(find.byKey(const ValueKey('progreso-subida-pdf')), findsNothing);
      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('sin total conocido la barra no tiene valor (en movimiento)', (
      tester,
    ) async {
      final espera = Completer<void>();
      repo.esperaSubidaPdf = espera.future;
      repo.avancesDeSubidaPdf = const [(10, -1)];
      selector.archivo = archivoPdfFalso('a.pdf');
      await abrirDialogo(tester);
      await tester.tap(boton('boton-cargar-pdf'));
      await esperar(tester);

      expect(enDialogo(find.text('Subiendo «a.pdf»…')), findsOneWidget);
      final barra = tester.widget<LinearProgressIndicator>(
        find.descendant(
          of: find.byKey(const ValueKey('progreso-subida-pdf')),
          matching: find.byType(LinearProgressIndicator),
        ),
      );
      expect(barra.value, isNull);

      espera.complete();
      await esperar(tester);
      await dejarPasarAviso(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EL DIALOGO: REEMPLAZAR
  // ═══════════════════════════════════════════════════════════════════════════

  group('el dialogo: reemplazar', () {
    Finder enConfirmacion(Finder f) =>
        find.descendant(of: find.byType(AlertDialog), matching: f);

    testWidgets('pide confirmacion con lo que se pierde y lo que se carga', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = conPdf;
      selector.archivo = archivoPdfFalso('nuevo.pdf', tamano: 340000);
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));

      expect(enConfirmacion(find.text('¿Reemplazar el PDF del cheque?')), findsOneWidget);
      expect(
        enConfirmacion(
          find.text(
            'Este cheque ya tiene un PDF (120 KB · 03/10/2026 14:22). '
            'Si cargas «nuevo.pdf» (340 KB), el anterior se borra y no se '
            'puede recuperar.',
          ),
        ),
        findsOneWidget,
      );
      // Mientras se decide no se envio nada.
      expect(repo.subidasPdf, isEmpty);
    });

    testWidgets('Cancelar no envia nada y deja el PDF como estaba', (tester) async {
      repo.estadoPdfDeTodos = conPdf;
      selector.archivo = archivoPdfFalso('nuevo.pdf');
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      await tocar(tester, enConfirmacion(find.text('Cancelar')));

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.subidasPdf, isEmpty);
      expect(dialogo, findsOneWidget);
      expect(enDialogo(find.text('120 KB · 03/10/2026 14:22')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf'), isTrue);
    });

    testWidgets('Reemplazar envia, vuelve a consultar y avisa del reemplazo', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = conPdf;
      repo.cheques = [chequeFalso(1)];
      selector.archivo = archivoPdfFalso('nuevo.pdf', tamano: 340000);
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));
      await tocar(tester, enConfirmacion(find.text('Reemplazar PDF')));

      expect(repo.subidasPdf, hasLength(1));
      expect(repo.subidasPdf.single.nombre, 'nuevo.pdf');
      // Ahora figura el archivo nuevo: 340 KB.
      expect(enDialogo(find.text('340 KB · 03/10/2026 14:22')), findsOneWidget);
      expect(find.text('PDF reemplazado.'), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('con un archivo invalido no se pregunta nada: primero se rechaza', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = conPdf;
      selector.archivo = archivoPdfFalso('mal.docx');
      await abrirDialogo(tester);
      await tocar(tester, boton('boton-cargar-pdf'));

      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.subidasPdf, isEmpty);
      expect(enDialogo(find.textContaining('no es un PDF')), findsOneWidget);
    });

    testWidgets('si otro usuario cargo uno entremedio, el aviso lo dice el servidor', (
      tester,
    ) async {
      // La pantalla creia que no habia PDF; al subir, el servidor dice que si.
      final espera = Completer<void>();
      repo.esperaSubidaPdf = espera.future;
      selector.archivo = archivoPdfFalso('a.pdf');
      await abrirDialogo(tester);
      repo.estadosPdf[cod] = conPdf;
      await tester.tap(boton('boton-cargar-pdf'));
      await esperar(tester);
      espera.complete();
      await esperar(tester);
      expect(find.text('PDF reemplazado.'), findsOneWidget);
      await dejarPasarAviso(tester);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SIN DESBORDES
  // ═══════════════════════════════════════════════════════════════════════════

  group('sin desbordes', () {
    final anchos = [390.0, 700.0, 1280.0, 1800.0];

    for (final escala in [1.0, 1.5]) {
      for (final ancho in anchos) {
        final etiqueta =
            '${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %';

        testWidgets('sin PDF y con un nombre de cliente enorme, a $etiqueta', (
          tester,
        ) async {
          repo.cheques = [
            chequeFalso(
              1,
              cliente:
                  'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE - CHIQUITOS',
              banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
              monto: 12345678.9,
            ),
          ];
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(() async {
            await abrirDialogo(tester, ancho: ancho);
          });
          expect(errores, isEmpty, reason: etiqueta);
          expect(enDialogo(find.text('Cargar PDF')), findsOneWidget);
        });

        testWidgets('con PDF, a $etiqueta', (tester) async {
          repo.estadoPdfDeTodos = conPdf;
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(() async {
            await abrirDialogo(tester, ancho: ancho);
          });
          expect(errores, isEmpty, reason: etiqueta);
          expect(boton('boton-ver-pdf'), findsOneWidget);
          expect(boton('boton-cargar-pdf'), findsOneWidget);
        });

        testWidgets('con un error de varias lineas y subiendo, a $etiqueta', (
          tester,
        ) async {
          final espera = Completer<void>();
          repo.estadoPdfDeTodos = conPdf;
          repo.esperaSubidaPdf = espera.future;
          repo.avancesDeSubidaPdf = const [(30, 100)];
          selector.archivo = archivoPdfFalso(
            'Un nombre de archivo bastante largo para ver como se corta 2026.pdf',
          );
          if (escala != 1.0) conTexto(tester, escala);
          final errores = await capturandoErrores(() async {
            await abrirDialogo(tester, ancho: ancho);
            // Primero un rechazo local de varias palabras...
            selector.archivo = archivoPdfFalso(
              'Otro nombre de archivo bastante largo para ver como se corta.docx',
            );
            await tester.tap(boton('boton-cargar-pdf'));
            await esperar(tester);
            expect(enDialogo(find.byType(ErrorServidorCheque)), findsOneWidget);
            // ...y despues una subida en curso.
            selector.archivo = archivoPdfFalso(
              'Un nombre de archivo bastante largo para ver como se corta 2026.pdf',
            );
            await tester.tap(boton('boton-cargar-pdf'));
            await esperar(tester);
            await tester.tap(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.text('Reemplazar PDF'),
              ),
            );
            await esperar(tester);
            expect(find.byKey(const ValueKey('progreso-subida-pdf')), findsOneWidget);
          });
          expect(errores, isEmpty, reason: etiqueta);

          espera.complete();
          await esperar(tester);
          await dejarPasarAviso(tester);
        });
      }
    }

    testWidgets('en el telefono el dialogo ocupa toda la pantalla y no se desplaza de lado', (
      tester,
    ) async {
      repo.estadoPdfDeTodos = conPdf;
      await abrirDialogo(tester, ancho: 390);
      final d = tester.getRect(dialogo);
      expect(d.width, 390);
      expect(d.height, 844);
      final horizontales = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(enDialogo(horizontales), findsNothing);
    });

    testWidgets('en escritorio es un dialogo con tope de ancho', (tester) async {
      repo.estadoPdfDeTodos = conPdf;
      await abrirDialogo(tester, ancho: 1800);
      // El panel (no el Dialog, que ocupa toda la ruta) respeta el tope de 620.
      final panel = tester.getRect(find.byType(MarcoPanelCheque));
      expect(panel.width, lessThanOrEqualTo(620));
      expect(panel.height, lessThan(900));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EL PANEL DEL DETALLE
  // ═══════════════════════════════════════════════════════════════════════════

  group('el panel del detalle', () {
    Future<void> abrirDetalle(
      WidgetTester tester, {
      double ancho = 1400,
      PermisosCheque permisos = permisosCajero,
    }) async {
      await montar(tester, pantalla(permisos: permisos), ancho: ancho);
      // Icono suelto en la tabla ancha; menu ⋮ en la angosta y en las tarjetas.
      final suelto = find.byTooltip('Completar');
      if (suelto.evaluate().isNotEmpty) {
        await tester.tap(suelto.first);
      } else {
        await tester.tap(find.byTooltip('Acciones').first);
        await esperar(tester);
        await tester.tap(find.text('Completar'));
      }
      await esperar(tester);
    }

    final panel = find.byKey(const ValueKey('seccion-documento-pdf'));
    Finder enPanel(Finder f) => find.descendant(of: panel, matching: f);

    testWidgets('sin PDF: lo dice, junto a las acciones', (tester) async {
      await abrirDetalle(tester);
      expect(panel, findsOneWidget);
      expect(enPanel(find.text('Documento PDF')), findsOneWidget);
      expect(enPanel(find.text('Este cheque no tiene PDF todavía')), findsOneWidget);
      expect(enPanel(find.text('Abrir documento')), findsOneWidget);
      // Con ancho, la tarjeta de acciones y la del PDF van lado a lado.
      final acciones = tester.getRect(find.text('Acciones').first);
      final pdf = tester.getRect(enPanel(find.text('Documento PDF')));
      expect((acciones.top - pdf.top).abs(), lessThan(2));
      expect(pdf.left, greaterThan(acciones.left));
    });

    testWidgets('con PDF: el estado completo en una linea', (tester) async {
      repo.estadoPdfDeTodos = conPdf;
      await abrirDetalle(tester);
      expect(
        enPanel(find.text('Hay un PDF cargado · 120 KB · 03/10/2026 14:22')),
        findsOneWidget,
      );
    });

    testWidgets('no pide permiso de boton: basta llegar al detalle', (tester) async {
      await abrirDetalle(tester, permisos: permisosCon([PermisosCheque.btnDetalle]));
      expect(panel, findsOneWidget);
      expect(enPanel(find.text('Abrir documento')), findsOneWidget);
    });

    testWidgets('el boton abre el dialogo del mismo cheque', (tester) async {
      await abrirDetalle(tester);
      await tocar(tester, enPanel(find.text('Abrir documento')));
      expect(dialogo, findsOneWidget);
      expect(enDialogo(find.text('Documento PDF')), findsOneWidget);
      expect(enDialogo(find.text('Cargar PDF')), findsOneWidget);
    });

    testWidgets('cargar desde el dialogo actualiza el estado del panel', (
      tester,
    ) async {
      selector.archivo = archivoPdfFalso('Factura 7.pdf', tamano: 120000);
      await abrirDetalle(tester);
      expect(enPanel(find.text('Este cheque no tiene PDF todavía')), findsOneWidget);

      await tocar(tester, enPanel(find.text('Abrir documento')));
      await tocar(tester, boton('boton-cargar-pdf'));
      await tester.tap(enDialogo(find.text('Cerrar')));
      await esperar(tester);

      expect(
        enPanel(find.text('Hay un PDF cargado · 120 KB · 03/10/2026 14:22')),
        findsOneWidget,
      );
      expect(enPanel(find.text('Este cheque no tiene PDF todavía')), findsNothing);
      await dejarPasarAviso(tester);
    });

    testWidgets('mientras consulta lo dice', (tester) async {
      final espera = Completer<void>();
      repo.esperaEstadoPdf = espera.future;
      await abrirDetalle(tester);
      expect(enPanel(find.text('Consultando el PDF del cheque…')), findsOneWidget);
      espera.complete();
      await esperar(tester);
      expect(enPanel(find.text('Este cheque no tiene PDF todavía')), findsOneWidget);
    });

    testWidgets('si la consulta falla dice el motivo y se puede reintentar', (
      tester,
    ) async {
      repo.errorEstadoPdf = Exception('La carpeta de los PDF de cheques no está disponible.');
      await abrirDetalle(tester);
      expect(
        enPanel(
          find.textContaining('No se pudo consultar el PDF: La carpeta de los PDF de cheques no está disponible.'),
        ),
        findsOneWidget,
      );
      repo.errorEstadoPdf = null;
      repo.estadoPdfDeTodos = conPdf;
      await tocar(tester, enPanel(find.text('Reintentar')));
      expect(enPanel(find.textContaining('Hay un PDF cargado')), findsOneWidget);
    });

    for (final escala in [1.0, 1.5]) {
      for (final ancho in [390.0, 800.0, 1400.0]) {
        testWidgets(
          'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} %',
          (tester) async {
            repo.estadoPdfDeTodos = conPdf;
            if (escala != 1.0) conTexto(tester, escala);
            final errores = await capturandoErrores(() async {
              await abrirDetalle(tester, ancho: ancho);
            });
            expect(errores, isEmpty);
            expect(panel, findsOneWidget);
            if (ancho < 900) {
              // Con poco ancho, una tarjeta debajo de la otra.
              final acciones = tester.getRect(find.text('Acciones').first);
              final pdf = tester.getRect(enPanel(find.text('Documento PDF')));
              expect(pdf.top, greaterThan(acciones.top));
            }
          },
        );
      }
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES
  // ═══════════════════════════════════════════════════════════════════════════

  test('los widgets del documento PDF no escriben colores a mano', () {
    final archivos = [
      'lib/presentation/widgets/cheques/documento_pdf_cheque.dart',
      'lib/presentation/widgets/cheques/detalle_cheque.dart',
      'lib/presentation/widgets/cheques/lista_cheques.dart',
    ];
    final prohibido = RegExp(
      r'Color\(\s*0x|Color\.fromARGB|Color\.fromRGBO|Colors\.(?!black\b|white\b|transparent\b)\w+',
    );
    for (final a in archivos) {
      final fuente = File(a).readAsStringSync();
      final sinComentarios = fuente
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        prohibido.hasMatch(sinComentarios),
        isFalse,
        reason: '$a escribe un color a mano: ${prohibido.firstMatch(sinComentarios)?.group(0)}',
      );
    }
  });
}
