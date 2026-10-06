import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/hora_traspaso_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/reportes_cheque.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// Los reportes en PDF de la barra de Cheques (`btnRpt1CH` a `btnRpt5CH`) y la
/// nomina del traspaso, con un repositorio falso y un visor de PDF falso.
///
/// Que cada boton aparezca solo con su permiso (con y sin administrador, en
/// escritorio y en el telefono), que cada dialogo mande al repositorio lo que
/// toca —con la empresa y la sucursal de la GRILLA y no las del login, que en las
/// pruebas es la empresa 6—, que lo que no se elige no viaje, que el boton se
/// bloquee mientras genera y que un error del servidor se vea completo con el
/// dialogo abierto y lo elegido intacto.
///
/// Todo contra un repositorio falso: nunca se probo contra el servidor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  const juan = PersonalChequeEntity(
    codEmpleado: 12,
    nombreCompleto: 'JUAN PEREZ',
  );
  const ana = PersonalChequeEntity(
    codEmpleado: 13,
    nombreCompleto: 'ANA ROJAS',
  );

  late RepositorioChequesFalso repo;
  late _VisorFalso visor;

  setUp(() {
    visor = _VisorFalso();
    repo =
        RepositorioChequesFalso()
          ..cheques = [chequeFalso(1, descTipo: 'PAGO')]
          ..clientes = [
            clienteDeCheque('C1', 'EDITORA MENDEZ'),
            clienteDeCheque('C2', 'LIBRERIA PAIS'),
            clienteDeCheque('C3', 'PAPELERA DEL SUR'),
          ]
          ..responsables = const [juan, ana]
          ..horasDeTraspaso = const [
            HoraTraspasoChequeEntity(codAccion: 88, hora: '09:15'),
            HoraTraspasoChequeEntity(codAccion: 91, hora: '16:40'),
          ];
  });

  Widget pantalla({PermisosCheque permisos = permisosAdmin}) => appCheques(
    hijo: const ChequesScreen(),
    repo: repo,
    permisos: permisos,
    extra: [visorPdfChequeProvider.overrideWithValue(visor.abrir)],
  );

  // ── Ayudas ────────────────────────────────────────────────────────────────

  final hoy = hoyDeLaPrueba();

  /// El menu del telefono con traspaso y custodia (y con los reportes, si los
  /// hay). Se busca por su icono: el tooltip depende de lo que trae.
  final menuTelefono = find.widgetWithIcon(IconButton, Icons.swap_horiz);

  /// El menu del telefono cuando solo trae reportes.
  final menuSoloReportes = find.widgetWithIcon(
    IconButton,
    Icons.picture_as_pdf_outlined,
  );

  /// Abre el menu de reportes de la barra: el boton «Reportes» en escritorio y
  /// el menu del telefono (con [menu] si el usuario solo tiene reportes).
  Future<void> abrirMenu(
    WidgetTester tester, {
    required double ancho,
    Finder? menu,
  }) async {
    if (ancho < 600) {
      await tester.tap(menu ?? menuTelefono);
    } else {
      await tester.tap(find.text('Reportes'));
    }
    await esperar(tester);
  }

  Future<void> abrirReporte(
    WidgetTester tester,
    String etiqueta, {
    double ancho = 1400,
    PermisosCheque permisos = permisosAdmin,
    Finder? menu,
  }) async {
    await montar(tester, pantalla(permisos: permisos), ancho: ancho);
    await abrirMenu(tester, ancho: ancho, menu: menu);
    await tester.tap(find.text(etiqueta));
    await esperar(tester);
  }

  /// El `FilledButton` con esa etiqueta, tambien el de `FilledButton.icon` y el
  /// tonal (que son subtipos: `widgetWithText` no los encuentra).
  Finder boton(String etiqueta) => find.ancestor(
    of: find.text(etiqueta),
    matching: find.bySubtype<FilledButton>(),
  );

  bool habilitado(WidgetTester tester, String etiqueta) =>
      tester.widget<FilledButton>(boton(etiqueta)).onPressed != null;

  Finder enDialogo(Finder f) =>
      find.descendant(of: find.byType(Dialog), matching: f);

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await esperar(tester);
  }

  /// Suelta el foco del campo de cliente: con el foco puesto, la lista de
  /// opciones queda abierta encima y tapa los botones del pie.
  Future<void> soltarCampo(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await esperar(tester);
  }

  /// Un desplegable «Todos» + opciones del dialogo, por la clave de su marco.
  Finder desplegable(String clave) => find.descendant(
    of: find.byKey(ValueKey(clave)),
    matching: find.byWidgetPredicate((w) => w is DropdownButtonFormField),
  );

  Future<void> elegirOpcion(
    WidgetTester tester,
    String clave,
    String opcion,
  ) async {
    await tocar(tester, desplegable(clave));
    await tester.tap(find.text(opcion).last);
    await esperar(tester);
  }

  /// El campo de fecha con esa etiqueta.
  Finder campoFecha(String etiqueta) => find
      .ancestor(of: find.text(etiqueta), matching: find.byType(InkWell))
      .first;

  /// Elige el dia 1 del mes que muestra el calendario (el actual; si hoy es el 1,
  /// el anterior, asi la fecha nunca es futura) y lo acepta. Devuelve la fecha.
  Future<DateTime> elegirDia1(WidgetTester tester, String etiqueta) async {
    await tocar(tester, campoFecha(etiqueta));
    if (hoy.day == 1) {
      await tester.tap(find.byTooltip('Mes anterior'));
      await esperar(tester);
    }
    await tester.tap(find.text('1').last);
    await esperar(tester);
    await tester.tap(find.text('ACEPTAR'));
    await esperar(tester);
    return hoy.day == 1
        ? DateTime(hoy.year, hoy.month - 1, 1)
        : DateTime(hoy.year, hoy.month, 1);
  }

  Future<void> quitarFecha(WidgetTester tester, String etiqueta) =>
      tocar(tester, find.byTooltip('Quitar $etiqueta'));

  /// Todos los reportes se piden con la empresa 1 (la primera, la activa) y la
  /// sucursal 3 de la grilla; **nunca con la 6 del login**.
  void conLoginAjeno() {
    for (final r in repo.reportes) {
      expect(r.parametros['codEmpresa'], isNot(6), reason: r.metodo);
    }
    expect(repo.empresasDeClientes, isNot(contains(6)));
  }

  // ── Los botones de la barra, segun los permisos ───────────────────────────

  group('botones de la barra', () {
    /// Etiqueta de cada reporte en el menu y el permiso que lo habilita.
    const reportes = <String, String>{
      'Cheques recibidos': 'btnRpt1CH',
      'Cheques de cobranza': 'btnRpt2CH',
      'Cheques en custodia': 'btnRpt3CH',
      'Recibo del último cheque': 'btnRpt4CH',
      'Reimprimir traspaso': 'btnRpt5CH',
    };

    final casos = <String, ({PermisosCheque permisos, Set<String> visibles})>{
      'administrador': (permisos: permisosAdmin, visibles: reportes.keys.toSet()),
      for (final e in reportes.entries)
        'solo ${e.value}': (
          permisos: permisosCon([e.value]),
          visibles: {e.key},
        ),
      'btnRpt1CH y btnRpt3CH': (
        permisos: permisosCon(['btnRpt1CH', 'btnRpt3CH']),
        visibles: {'Cheques recibidos', 'Cheques en custodia'},
      ),
      'cajero (sin ningun reporte)': (
        permisos: permisosCajero,
        visibles: <String>{},
      ),
      'sin ningun boton': (permisos: permisosNinguno, visibles: <String>{}),
    };

    casos.forEach((nombre, caso) {
      testWidgets('escritorio, $nombre', (tester) async {
        await montar(tester, pantalla(permisos: caso.permisos), ancho: 1400);

        if (caso.visibles.isEmpty) {
          // Sin ningun reporte no aparece nada.
          expect(find.text('Reportes'), findsNothing);
          return;
        }
        // Un solo boton con menu: las opciones no estan sueltas en la barra.
        expect(find.text('Reportes'), findsOneWidget);
        for (final e in reportes.keys) {
          expect(find.text(e), findsNothing, reason: 'suelto $e');
        }
        await tester.tap(find.text('Reportes'));
        await esperar(tester);
        for (final e in reportes.keys) {
          expect(
            find.text(e),
            caso.visibles.contains(e) ? findsOneWidget : findsNothing,
            reason: '$nombre / $e',
          );
        }
      });

      testWidgets('movil, $nombre: dentro del menu de la barra', (
        tester,
      ) async {
        await montar(tester, pantalla(permisos: caso.permisos), ancho: 390);
        // Nunca sueltos ni con un boton «Reportes» propio.
        expect(find.text('Reportes'), findsNothing);
        for (final e in reportes.keys) {
          expect(find.text(e), findsNothing, reason: 'suelto $e');
        }
        if (caso.visibles.isEmpty) return;

        // El menu de siempre si trae algo mas; uno solo de reportes si no.
        final soloReportes =
            caso.permisos.esAdmin
                ? false
                : !(caso.permisos.puedeTraspasar ||
                    caso.permisos.puedeEntregarACustodia ||
                    caso.permisos.puedeDarCustodia);
        await tester.tap(soloReportes ? menuSoloReportes : menuTelefono);
        await esperar(tester);
        for (final e in reportes.keys) {
          expect(
            find.text(e),
            caso.visibles.contains(e) ? findsOneWidget : findsNothing,
            reason: '$nombre / $e en el menu',
          );
        }
      });
    });

    testWidgets('movil: un usuario con traspaso y reportes ve todo junto', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnTraspasoCH', 'btnRpt2CH'])),
        ancho: 390,
      );
      // El menu se nombra por lo que trae.
      expect(find.byTooltip('Traspaso, custodia y reportes'), findsOneWidget);
      await tester.tap(menuTelefono);
      await esperar(tester);
      expect(find.text('Traspaso'), findsOneWidget);
      expect(find.text('Cheques de cobranza'), findsOneWidget);
      expect(find.text('Cheques recibidos'), findsNothing);
    });

    testWidgets('movil: sin reportes el menu sigue llamandose como siempre', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnTraspasoCH'])),
        ancho: 390,
      );
      expect(find.byTooltip('Traspaso y custodia'), findsOneWidget);
      expect(find.byTooltip('Reportes'), findsNothing);
    });

    testWidgets('movil: con solo reportes el menu se llama Reportes', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnRpt1CH'])),
        ancho: 390,
      );
      expect(find.byTooltip('Reportes'), findsOneWidget);
      expect(menuTelefono, findsNothing);
    });

    testWidgets('sin sucursal el boton Reportes se apaga', (tester) async {
      repo.sucursalInicial = 0;
      await montar(tester, pantalla(), ancho: 1400);
      final b = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Reportes'),
          matching: find.bySubtype<OutlinedButton>(),
        ),
      );
      expect(b.onPressed, isNull);
    });

    testWidgets('sin sucursal el menu del telefono con solo reportes se apaga', (
      tester,
    ) async {
      repo.sucursalInicial = 0;
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnRpt1CH'])),
        ancho: 390,
      );
      expect(tester.widget<IconButton>(menuSoloReportes).onPressed, isNull);
    });
  });

  // ── Cheques recibidos (btnRpt1CH) ─────────────────────────────────────────

  group('reporte de cheques recibidos', () {
    testWidgets('abre con hoy en las dos fechas y la empresa y sucursal', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques recibidos');

      expect(find.text('Reporte de cheques recibidos'), findsOneWidget);
      // La empresa y la sucursal sobre las que sale el reporte.
      expect(find.text('IMPEXPAP · Sucursal LA PAZ'), findsOneWidget);
      final f = '${hoy.day.toString().padLeft(2, '0')}/'
          '${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';
      expect(enDialogo(find.text(f)), findsNWidgets(2));
      expect(repo.reportes, isEmpty);
    });

    testWidgets('Generar PDF manda la empresa y la sucursal de la grilla', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques recibidos');
      await tocar(tester, boton('Generar PDF'));

      expect(repo.contar('reporteRecibidos'), 1);
      expect(repo.ultimoReporte('reporteRecibidos'), {
        'codEmpresa': 1,
        'codSucursal': 3,
        'fechaDesde': hoy,
        'fechaHasta': hoy,
      });
      conLoginAjeno();
      // El PDF llega al visor con su titulo y el nombre del archivo.
      expect(visor.abiertos, hasLength(1));
      expect(visor.abiertos.single.bytes, repo.pdfFalso);
      expect(visor.abiertos.single.titulo, 'Cheques recibidos');
      expect(visor.abiertos.single.nombreArchivo, 'reporte-cheques-recibidos.pdf');
      // Un reporte no es una escritura: no relee la grilla.
      expect(repo.contar('listar'), 1);
    });

    testWidgets('quitar una fecha la deja sin mandar', (tester) async {
      await abrirReporte(tester, 'Cheques recibidos');
      await quitarFecha(tester, 'Fecha inicial');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteRecibidos')['fechaDesde'], isNull);
      expect(repo.ultimoReporte('reporteRecibidos')['fechaHasta'], hoy);

      await quitarFecha(tester, 'Fecha final');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteRecibidos')['fechaDesde'], isNull);
      expect(repo.ultimoReporte('reporteRecibidos')['fechaHasta'], isNull);
      expect(repo.contar('reporteRecibidos'), 2);
    });

    testWidgets('elegir otra fecha cambia lo que se manda', (tester) async {
      await abrirReporte(tester, 'Cheques recibidos');
      final dia1 = await elegirDia1(tester, 'Fecha inicial');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteRecibidos')['fechaDesde'], dia1);
      expect(repo.ultimoReporte('reporteRecibidos')['fechaHasta'], hoy);
    });

    testWidgets('una fecha final anterior a la inicial lo dice y no deja', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques recibidos');
      // Dia 1 de la «final», contra la «inicial» de hoy (o del mes que sigue).
      await elegirDia1(tester, 'Fecha final');
      expect(
        find.text('Debe ser igual o posterior a la fecha inicial.'),
        findsOneWidget,
      );
      expect(habilitado(tester, 'Generar PDF'), isFalse);

      // Quitar la fecha inicial lo corrige.
      await quitarFecha(tester, 'Fecha inicial');
      expect(
        find.text('Debe ser igual o posterior a la fecha inicial.'),
        findsNothing,
      );
      expect(habilitado(tester, 'Generar PDF'), isTrue);
    });

    testWidgets('el error del servidor se ve completo y lo elegido queda', (
      tester,
    ) async {
      repo.errorReporte = Exception(
        'No tiene permisos para ver datos de otras sucursales\n'
        'No hay cheques en el rango pedido.',
      );
      await abrirReporte(tester, 'Cheques recibidos');
      final dia1 = await elegirDia1(tester, 'Fecha inicial');
      await tocar(tester, boton('Generar PDF'));

      expect(
        find.text('No tiene permisos para ver datos de otras sucursales'),
        findsOneWidget,
      );
      expect(find.text('No hay cheques en el rango pedido.'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      // Sigue abierto, con lo elegido y sin visor.
      expect(find.text('Reporte de cheques recibidos'), findsOneWidget);
      expect(visor.abiertos, isEmpty);
      final f = '${dia1.day.toString().padLeft(2, '0')}/'
          '${dia1.month.toString().padLeft(2, '0')}/${dia1.year}';
      expect(enDialogo(find.text(f)), findsOneWidget);
      expect(habilitado(tester, 'Generar PDF'), isTrue);

      // Corregido el problema, reintentar con lo mismo funciona y limpia el error.
      repo.errorReporte = null;
      await tocar(tester, boton('Generar PDF'));
      expect(find.text('No hay cheques en el rango pedido.'), findsNothing);
      expect(visor.abiertos, hasLength(1));
      expect(repo.ultimoReporte('reporteRecibidos')['fechaDesde'], dia1);
    });

    testWidgets('mientras genera el boton muestra progreso y no se repite', (
      tester,
    ) async {
      final espera = Completer<void>();
      repo.esperaReporte = espera.future;
      await abrirReporte(tester, 'Cheques recibidos');

      await tester.tap(boton('Generar PDF'));
      await tester.pump();
      expect(find.text('Generando…'), findsOneWidget);
      expect(find.text('Generar PDF'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Generando…'),
                matching: find.bySubtype<FilledButton>(),
              ),
            )
            .onPressed,
        isNull,
      );

      // Un segundo toque, y un tercero, no piden otro PDF.
      await tester.tap(find.text('Generando…'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('Generando…'), warnIfMissed: false);
      await tester.pump();
      expect(repo.contar('reporteRecibidos'), 1);

      // Y no se puede cerrar el dialogo a medio camino.
      expect(
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cerrar')).onPressed,
        isNull,
      );

      espera.complete();
      await esperar(tester);
      expect(repo.contar('reporteRecibidos'), 1);
      expect(visor.abiertos, hasLength(1));
      expect(find.text('Generar PDF'), findsOneWidget);
      expect(habilitado(tester, 'Generar PDF'), isTrue);
    });

    testWidgets('con otra empresa elegida usa la empresa y la sucursal de ella', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(comboEmpresa());
      await esperar(tester);
      await tester.tap(find.text('ESPPAPEL').last);
      await esperar(tester);

      await abrirMenu(tester, ancho: 1400);
      await tester.tap(find.text('Cheques recibidos'));
      await esperar(tester);
      expect(find.text('ESPPAPEL · Sucursal SANTA CRUZ'), findsOneWidget);
      await tocar(tester, boton('Generar PDF'));

      expect(repo.ultimoReporte('reporteRecibidos')['codEmpresa'], 5);
      expect(repo.ultimoReporte('reporteRecibidos')['codSucursal'], 7);
      conLoginAjeno();
    });

    testWidgets('Cerrar cierra el dialogo sin pedir nada', (tester) async {
      await abrirReporte(tester, 'Cheques recibidos');
      await tester.tap(find.widgetWithText(TextButton, 'Cerrar'));
      await esperar(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(repo.reportes, isEmpty);
    });
  });

  // ── Cheques de cobranza (btnRpt2CH) ───────────────────────────────────────

  group('reporte de cheques de cobranza', () {
    testWidgets('sin tocar nada: Todos en estado y cliente, y no manda clave', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      expect(find.text('Reporte de cheques de cobranza'), findsOneWidget);
      await tocar(tester, boton('Generar PDF'));

      expect(repo.ultimoReporte('reporteCobranzas'), {
        'codEmpresa': 1,
        'codSucursal': 3,
        'fechaDesde': hoy,
        'fechaHasta': hoy,
        'estado': null,
        'codCliente': null,
      });
      conLoginAjeno();
      expect(visor.abiertos.single.titulo, 'Cheques de cobranza');
      expect(visor.abiertos.single.nombreArchivo, 'reporte-cheques-cobranza.pdf');
    });

    testWidgets('el estado ofrece Todos y los del catalogo', (tester) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      await tocar(tester, desplegable('reporte-estado'));
      // Las opciones del menu desplegado (la grilla de atras tambien dice
      // «PENDIENTE» en la fila).
      Finder opcion(String t) => find.descendant(
        of: find.byWidgetPredicate((w) => w is DropdownMenuItem),
        matching: find.text(t),
      );
      expect(opcion('Todos'), findsWidgets);
      expect(opcion('PENDIENTE'), findsOneWidget);
      expect(opcion('CERRADO'), findsOneWidget);
    });

    testWidgets('elegir un estado lo manda; volver a Todos lo quita', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      await elegirOpcion(tester, 'reporte-estado', 'CERRADO');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCobranzas')['estado'], 'CER');

      await elegirOpcion(tester, 'reporte-estado', 'Todos');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCobranzas')['estado'], isNull);
    });

    testWidgets('elegir un cliente de la lista manda su codigo', (tester) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'mend');
      await esperar(tester);
      await tester.tap(find.text('EDITORA MENDEZ').last);
      await esperar(tester);
      await tocar(tester, boton('Generar PDF'));

      expect(repo.ultimoReporte('reporteCobranzas')['codCliente'], 'C1');
      // Los clientes se pidieron de la empresa activa, no de la del login.
      expect(repo.empresasDeClientes, isNotEmpty);
      expect(repo.empresasDeClientes, everyElement(1));
      conLoginAjeno();
    });

    testWidgets('borrar el texto vuelve a todos los clientes', (tester) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'mend');
      await esperar(tester);
      await tester.tap(find.text('EDITORA MENDEZ').last);
      await esperar(tester);

      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), '');
      await soltarCampo(tester);
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCobranzas')['codCliente'], isNull);
    });

    testWidgets('un texto sin elegir de la lista no es «todos»: lo senala', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'mend');
      await soltarCampo(tester);
      await tocar(tester, boton('Generar PDF'));

      expect(
        find.text(
          'Elige un cliente de la lista o borra el texto para incluir a todos.',
        ),
        findsOneWidget,
      );
      expect(repo.contar('reporteCobranzas'), 0);
      expect(visor.abiertos, isEmpty);
    });

    testWidgets(
      'el aviso del cliente espera al primer intento y despues sigue al texto',
      (tester) async {
        await abrirReporte(tester, 'Cheques de cobranza');
        const aviso = 'Elige un cliente de la lista';

        // Mientras todavia teclea el nombre no se le avisa nada.
        await tester.enterText(
          find.byKey(const ValueKey('campo-cliente')),
          'zzz',
        );
        await esperar(tester);
        expect(find.textContaining(aviso), findsNothing);

        // Al intentar generar, si.
        await soltarCampo(tester);
        await tocar(tester, boton('Generar PDF'));
        expect(find.textContaining(aviso), findsOneWidget);

        // Y desde entonces se corrige solo al borrar el texto, sin volver a
        // pulsar.
        await tester.enterText(find.byKey(const ValueKey('campo-cliente')), '');
        await soltarCampo(tester);
        expect(find.textContaining(aviso), findsNothing);
        expect(repo.contar('reporteCobranzas'), 0);
      },
    );

    testWidgets('la ayuda del cliente dice si se filtra o son todos', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      expect(find.textContaining('Todos los clientes.'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'mend');
      await esperar(tester);
      await tester.tap(find.text('EDITORA MENDEZ').last);
      await esperar(tester);
      expect(find.textContaining('Solo los cheques de este cliente'), findsOneWidget);
      expect(find.textContaining('Todos los clientes.'), findsNothing);
    });

    testWidgets('escribir despues de elegir invalida la eleccion', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'mend');
      await esperar(tester);
      await tester.tap(find.text('EDITORA MENDEZ').last);
      await esperar(tester);
      await tester.enterText(
        find.byKey(const ValueKey('campo-cliente')),
        'EDITORA MENDEZ X',
      );
      await esperar(tester);
      await tocar(tester, boton('Generar PDF'));

      expect(
        find.textContaining('Elige un cliente de la lista'),
        findsOneWidget,
      );
      expect(repo.contar('reporteCobranzas'), 0);
    });

    testWidgets('una empresa sin clientes no impide generar', (tester) async {
      repo.clientes = const [];
      await abrirReporte(tester, 'Cheques de cobranza');
      expect(find.text('No hay clientes para esta empresa.'), findsOneWidget);
      await tocar(tester, boton('Generar PDF'));
      expect(repo.contar('reporteCobranzas'), 1);
      expect(repo.ultimoReporte('reporteCobranzas')['codCliente'], isNull);
    });

    testWidgets('con otra empresa los clientes son los de esa empresa', (
      tester,
    ) async {
      repo.clientesPorEmpresa = {
        5: [clienteDeCheque('S9', 'IMPRENTA UNIVERSAL')],
      };
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(comboEmpresa());
      await esperar(tester);
      await tester.tap(find.text('ESPPAPEL').last);
      await esperar(tester);
      await abrirMenu(tester, ancho: 1400);
      await tester.tap(find.text('Cheques de cobranza'));
      await esperar(tester);

      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'imp');
      await esperar(tester);
      await tester.tap(find.text('IMPRENTA UNIVERSAL').last);
      await esperar(tester);
      await tocar(tester, boton('Generar PDF'));

      expect(repo.empresasDeClientes.last, 5);
      expect(repo.ultimoReporte('reporteCobranzas'), {
        'codEmpresa': 5,
        'codSucursal': 7,
        'fechaDesde': hoy,
        'fechaHasta': hoy,
        'estado': null,
        'codCliente': 'S9',
      });
      conLoginAjeno();
    });

    testWidgets('el error del servidor deja el dialogo con todo lo elegido', (
      tester,
    ) async {
      repo.errorReporte = Exception(
        'El reporte no se pudo armar.\nRevise los filtros.',
      );
      await abrirReporte(tester, 'Cheques de cobranza');
      await elegirOpcion(tester, 'reporte-estado', 'PENDIENTE');
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'pap');
      await esperar(tester);
      await tester.tap(find.text('PAPELERA DEL SUR').last);
      await esperar(tester);
      await tocar(tester, boton('Generar PDF'));

      expect(find.text('El reporte no se pudo armar.'), findsOneWidget);
      expect(find.text('Revise los filtros.'), findsOneWidget);
      expect(enDialogo(find.text('PENDIENTE')), findsOneWidget);
      expect(find.text('PAPELERA DEL SUR'), findsOneWidget);
      expect(visor.abiertos, isEmpty);

      repo.errorReporte = null;
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCobranzas')['estado'], 'PEN');
      expect(repo.ultimoReporte('reporteCobranzas')['codCliente'], 'C3');
      expect(visor.abiertos, hasLength(1));
    });

    testWidgets('el rango de fechas invertido tampoco deja generar', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques de cobranza');
      await elegirDia1(tester, 'Fecha final');
      expect(
        find.text('Debe ser igual o posterior a la fecha inicial.'),
        findsOneWidget,
      );
      expect(habilitado(tester, 'Generar PDF'), isFalse);
    });
  });

  // ── Cheques en custodia (btnRpt3CH) ───────────────────────────────────────

  group('reporte de cheques en custodia', () {
    testWidgets('sin tocar nada: la fecha de hoy y todos los responsables', (
      tester,
    ) async {
      await abrirReporte(tester, 'Cheques en custodia');
      expect(find.text('Reporte de cheques en custodia'), findsOneWidget);
      await tocar(tester, boton('Generar PDF'));

      expect(repo.ultimoReporte('reporteCustodio'), {
        'codEmpresa': 1,
        'codSucursal': 3,
        'fecha': hoy,
        'codEmpleado': null,
      });
      conLoginAjeno();
      expect(visor.abiertos.single.titulo, 'Cheques en custodia');
      expect(visor.abiertos.single.nombreArchivo, 'reporte-cheques-custodia.pdf');
    });

    testWidgets('elegir un responsable manda su codigo', (tester) async {
      await abrirReporte(tester, 'Cheques en custodia');
      await tocar(tester, desplegable('reporte-responsable'));
      expect(find.text('Todos'), findsWidgets);
      await tester.tap(find.text('ANA ROJAS').last);
      await esperar(tester);
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCustodio')['codEmpleado'], 13);

      await elegirOpcion(tester, 'reporte-responsable', 'Todos');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCustodio')['codEmpleado'], isNull);
    });

    testWidgets('la fecha es opcional: quitarla no la manda', (tester) async {
      await abrirReporte(tester, 'Cheques en custodia');
      await quitarFecha(tester, 'Fecha de asignación');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCustodio')['fecha'], isNull);
    });

    testWidgets('elegir otra fecha la manda', (tester) async {
      await abrirReporte(tester, 'Cheques en custodia');
      final dia1 = await elegirDia1(tester, 'Fecha de asignación');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCustodio')['fecha'], dia1);
    });

    testWidgets('si falla la lista de responsables se puede generar «Todos»', (
      tester,
    ) async {
      repo.erroresDeLectura['listarResponsablesDeCustodia'] = Exception(
        'Sin conexión',
      );
      await abrirReporte(tester, 'Cheques en custodia');
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(habilitado(tester, 'Generar PDF'), isTrue);

      repo.erroresDeLectura.clear();
      await tocar(tester, find.text('Reintentar'));
      expect(find.text('Reintentar'), findsNothing);
      await elegirOpcion(tester, 'reporte-responsable', 'JUAN PEREZ');
      await tocar(tester, boton('Generar PDF'));
      expect(repo.ultimoReporte('reporteCustodio')['codEmpleado'], 12);
    });

    testWidgets('el error del servidor se ve completo y queda el responsable', (
      tester,
    ) async {
      repo.errorReporte = Exception(
        'No tiene permiso para esta accion.\nConsulte con su administrador.',
      );
      await abrirReporte(tester, 'Cheques en custodia');
      await elegirOpcion(tester, 'reporte-responsable', 'JUAN PEREZ');
      await tocar(tester, boton('Generar PDF'));

      expect(find.text('No tiene permiso para esta accion.'), findsOneWidget);
      expect(find.text('Consulte con su administrador.'), findsOneWidget);
      expect(find.text('JUAN PEREZ'), findsOneWidget);
      expect(visor.abiertos, isEmpty);
    });

    testWidgets('mientras genera no se puede repetir', (tester) async {
      final espera = Completer<void>();
      repo.esperaReporte = espera.future;
      await abrirReporte(tester, 'Cheques en custodia');
      await tester.tap(boton('Generar PDF'));
      await tester.pump();
      await tester.tap(find.text('Generando…'), warnIfMissed: false);
      await tester.pump();
      expect(repo.contar('reporteCustodio'), 1);
      espera.complete();
      await esperar(tester);
      expect(visor.abiertos, hasLength(1));
    });
  });

  // ── Recibo del ultimo cheque (btnRpt4CH) ──────────────────────────────────

  group('recibo del ultimo cheque', () {
    testWidgets('un dialogo corto, sin campos, que explica que se genera', (
      tester,
    ) async {
      await abrirReporte(tester, 'Recibo del último cheque');
      expect(find.text('Recibo del último cheque'), findsOneWidget);
      expect(
        find.textContaining('último cheque que registraste en esta sucursal'),
        findsOneWidget,
      );
      expect(enDialogo(find.byType(TextFormField)), findsNothing);
      expect(
        enDialogo(find.byWidgetPredicate((w) => w is DropdownButtonFormField)),
        findsNothing,
      );
      expect(repo.reportes, isEmpty);
    });

    testWidgets('Generar PDF manda solo empresa y sucursal de la grilla', (
      tester,
    ) async {
      await abrirReporte(tester, 'Recibo del último cheque');
      await tocar(tester, boton('Generar PDF'));

      expect(repo.ultimoReporte('reporteUltimoRecibo'), {
        'codEmpresa': 1,
        'codSucursal': 3,
      });
      conLoginAjeno();
      expect(visor.abiertos.single.titulo, 'Recibo del último cheque');
      expect(visor.abiertos.single.nombreArchivo, 'recibo-ultimo-cheque.pdf');
    });

    testWidgets('si no hay cheque, el mensaje del servidor se ve completo', (
      tester,
    ) async {
      repo.errorReporte = Exception(
        'Usted todavia no registro ningun cheque en esta sucursal.\n'
        'Registre uno y vuelva a pedir el recibo.',
      );
      await abrirReporte(tester, 'Recibo del último cheque');
      await tocar(tester, boton('Generar PDF'));

      expect(
        find.text('Usted todavia no registro ningun cheque en esta sucursal.'),
        findsOneWidget,
      );
      expect(
        find.text('Registre uno y vuelva a pedir el recibo.'),
        findsOneWidget,
      );
      expect(find.textContaining('Exception'), findsNothing);
      expect(visor.abiertos, isEmpty);
      // Sigue abierto y se puede cerrar.
      expect(find.text('Recibo del último cheque'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cerrar'));
      await esperar(tester);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('desde el telefono, dentro del menu', (tester) async {
      await abrirReporte(
        tester,
        'Recibo del último cheque',
        ancho: 390,
        permisos: permisosCon(['btnRpt4CH']),
        menu: menuSoloReportes,
      );
      await tocar(tester, boton('Generar PDF'));
      expect(repo.contar('reporteUltimoRecibo'), 1);
    });
  });

  // ── Reimprimir traspaso (btnRpt5CH) ───────────────────────────────────────

  group('reimprimir traspaso', () {
    testWidgets('pide las horas de hoy y no se genera sin elegir una', (
      tester,
    ) async {
      await abrirReporte(tester, 'Reimprimir traspaso');

      expect(find.text('Reimprimir traspaso'), findsOneWidget);
      expect(repo.fechasDeHoras.single, hoy);
      expect(find.byKey(const ValueKey('hora-88')), findsOneWidget);
      expect(find.byKey(const ValueKey('hora-91')), findsOneWidget);
      expect(find.text('09:15'), findsOneWidget);
      expect(find.text('16:40'), findsOneWidget);
      expect(habilitado(tester, 'Generar PDF'), isFalse);
      expect(repo.reportes, isEmpty);
    });

    testWidgets('elegir una hora y generar manda su codAccion', (tester) async {
      await abrirReporte(tester, 'Reimprimir traspaso');
      await tocar(tester, find.byKey(const ValueKey('hora-91')));
      expect(habilitado(tester, 'Generar PDF'), isTrue);
      await tocar(tester, boton('Generar PDF'));

      expect(repo.ultimoReporte('reporteReimpresionTraspaso'), {
        'codEmpresa': 1,
        'codSucursal': 3,
        'codAccion': 91,
      });
      conLoginAjeno();
      expect(visor.abiertos.single.titulo, 'Traspaso de cheques');
      expect(
        visor.abiertos.single.nombreArchivo,
        'reimpresion-traspaso-cheques.pdf',
      );
    });

    testWidgets('cambiar de hora cambia el codAccion', (tester) async {
      await abrirReporte(tester, 'Reimprimir traspaso');
      await tocar(tester, find.byKey(const ValueKey('hora-88')));
      await tocar(tester, find.byKey(const ValueKey('hora-91')));
      await tocar(tester, boton('Generar PDF'));
      expect(
        repo.ultimoReporte('reporteReimpresionTraspaso')['codAccion'],
        91,
      );
    });

    testWidgets('un dia sin traspasos lo dice y no deja generar', (
      tester,
    ) async {
      repo.horasDeTraspaso = const [];
      await abrirReporte(tester, 'Reimprimir traspaso');

      expect(find.byKey(const ValueKey('sin-traspasos')), findsOneWidget);
      expect(find.textContaining('No hay traspasos en esa fecha'), findsOneWidget);
      expect(habilitado(tester, 'Generar PDF'), isFalse);
      expect(repo.reportes, isEmpty);
    });

    testWidgets('cambiar la fecha pide esas horas y descarta la elegida', (
      tester,
    ) async {
      await abrirReporte(tester, 'Reimprimir traspaso');
      await tocar(tester, find.byKey(const ValueKey('hora-88')));
      expect(habilitado(tester, 'Generar PDF'), isTrue);

      repo.horasDeTraspaso = const [
        HoraTraspasoChequeEntity(codAccion: 70, hora: '08:00'),
        HoraTraspasoChequeEntity(codAccion: 71, hora: '12:30'),
      ];
      final dia1 = await elegirDia1(tester, 'Fecha del traspaso');

      expect(repo.fechasDeHoras.last, dia1);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('09:15'), findsNothing);
      // Otro dia, otros traspasos: la hora elegida antes ya no vale.
      expect(habilitado(tester, 'Generar PDF'), isFalse);

      await tocar(tester, find.byKey(const ValueKey('hora-71')));
      await tocar(tester, boton('Generar PDF'));
      expect(
        repo.ultimoReporte('reporteReimpresionTraspaso')['codAccion'],
        71,
      );
    });

    testWidgets(
      'cambiar la fecha descarta la hora aunque el otro dia tenga la misma',
      (tester) async {
        // El mismo codAccion existe en las dos listas: igual hay que volver a
        // elegir, porque la fecha cambio.
        await abrirReporte(tester, 'Reimprimir traspaso');
        await tocar(tester, find.byKey(const ValueKey('hora-88')));
        expect(habilitado(tester, 'Generar PDF'), isTrue);

        await elegirDia1(tester, 'Fecha del traspaso');
        expect(find.byKey(const ValueKey('hora-88')), findsOneWidget);
        expect(habilitado(tester, 'Generar PDF'), isFalse);
      },
    );

    testWidgets('si falla la consulta de horas: el motivo y Reintentar', (
      tester,
    ) async {
      repo.erroresDeLectura['listarHorasDeTraspaso'] = Exception('Sin conexión');
      await abrirReporte(tester, 'Reimprimir traspaso');
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(habilitado(tester, 'Generar PDF'), isFalse);

      repo.erroresDeLectura.clear();
      await tocar(tester, find.text('Reintentar'));
      expect(find.byKey(const ValueKey('hora-88')), findsOneWidget);
    });

    testWidgets('el error del servidor se ve completo y la hora queda elegida', (
      tester,
    ) async {
      repo.errorReporte = Exception(
        'El traspaso ya no existe.\nElija otro de la lista.',
      );
      await abrirReporte(tester, 'Reimprimir traspaso');
      await tocar(tester, find.byKey(const ValueKey('hora-88')));
      await tocar(tester, boton('Generar PDF'));

      expect(find.text('El traspaso ya no existe.'), findsOneWidget);
      expect(find.text('Elija otro de la lista.'), findsOneWidget);
      expect(visor.abiertos, isEmpty);
      // Sigue elegida: no hay que volver a buscarla para reintentar.
      expect(habilitado(tester, 'Generar PDF'), isTrue);
      repo.errorReporte = null;
      await tocar(tester, boton('Generar PDF'));
      expect(
        repo.ultimoReporte('reporteReimpresionTraspaso')['codAccion'],
        88,
      );
    });

    testWidgets('el calendario no deja elegir un dia futuro', (tester) async {
      await abrirReporte(tester, 'Reimprimir traspaso');
      final consultas = repo.fechasDeHoras.length;
      await tocar(tester, campoFecha('Fecha del traspaso'));
      // Un traspaso es algo que ya paso: manana (si cae en el mismo mes) no se
      // puede elegir y la fecha sigue siendo hoy.
      final manana = hoy.add(const Duration(days: 1));
      if (manana.month == hoy.month) {
        await tester.tap(find.text('${manana.day}').last);
        await esperar(tester);
        await tester.tap(find.text('ACEPTAR'));
        await esperar(tester);
        expect(repo.fechasDeHoras.length, consultas);
        expect(repo.fechasDeHoras.last, hoy);
      } else {
        await tester.tap(find.text('CANCELAR'));
        await esperar(tester);
      }
    });
  });

  // ── Nomina del traspaso (btnTraspasoCH) ───────────────────────────────────

  group('nomina del traspaso', () {
    Future<void> abrirTraspaso(
      WidgetTester tester, {
      double ancho = 1400,
    }) async {
      await montar(tester, pantalla(), ancho: ancho);
      if (ancho < 600) {
        await tester.tap(menuTelefono);
        await esperar(tester);
      }
      await tocarCustodia(tester, 'Traspaso');
    }

    testWidgets('no se ofrece antes de traspasar', (tester) async {
      await abrirTraspaso(tester);
      expect(find.text('Imprimir nómina (PDF)'), findsNothing);
      expect(boton('Generar'), findsOneWidget);
      expect(repo.reportes, isEmpty);
    });

    testWidgets('despues de traspasar aparece y manda empresa y sucursal', (
      tester,
    ) async {
      await abrirTraspaso(tester);
      await tocar(tester, boton('Generar'));

      expect(find.text('Se traspasaron 4 cheques.'), findsOneWidget);
      expect(find.text('Imprimir nómina (PDF)'), findsOneWidget);
      // Antes de pulsarlo no se pidio ningun PDF.
      expect(repo.reportes, isEmpty);

      await tocar(tester, find.text('Imprimir nómina (PDF)'));
      expect(repo.ultimoReporte('reporteTraspaso'), {
        'codEmpresa': 1,
        'codSucursal': 3,
      });
      conLoginAjeno();
      expect(visor.abiertos, hasLength(1));
      expect(visor.abiertos.single.titulo, 'Nómina del traspaso de cheques');
      expect(visor.abiertos.single.nombreArchivo, 'nomina-traspaso-cheques.pdf');
      // El dialogo sigue ahi, con el resultado del traspaso.
      expect(find.text('Se traspasaron 4 cheques.'), findsOneWidget);
    });

    testWidgets('con otra empresa elegida imprime la de esa empresa', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(comboEmpresa());
      await esperar(tester);
      await tester.tap(find.text('ESPPAPEL').last);
      await esperar(tester);
      await tocarCustodia(tester, 'Traspaso');
      await tocar(tester, boton('Generar'));
      await tocar(tester, find.text('Imprimir nómina (PDF)'));

      expect(repo.ultimoReporte('reporteTraspaso'), {
        'codEmpresa': 5,
        'codSucursal': 7,
      });
      conLoginAjeno();
    });

    testWidgets('sin cheques traspasados no hay nomina que imprimir', (
      tester,
    ) async {
      repo.traspasados = 0;
      await abrirTraspaso(tester);
      await tocar(tester, boton('Generar'));
      expect(
        find.text('No había cheques pendientes: no se traspasó ninguno.'),
        findsOneWidget,
      );
      expect(find.text('Imprimir nómina (PDF)'), findsNothing);
    });

    testWidgets('si la nomina falla: el motivo completo y el traspaso queda', (
      tester,
    ) async {
      repo.errorReporte = Exception(
        'No se pudo armar la nomina.\nIntente de nuevo en un momento.',
      );
      await abrirTraspaso(tester);
      await tocar(tester, boton('Generar'));
      await tocar(tester, find.text('Imprimir nómina (PDF)'));

      expect(find.text('No se pudo armar la nomina.'), findsOneWidget);
      expect(find.text('Intente de nuevo en un momento.'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      // El traspaso ya estaba hecho y sigue a la vista.
      expect(find.text('Se traspasaron 4 cheques.'), findsOneWidget);
      expect(visor.abiertos, isEmpty);

      // Se puede reintentar.
      repo.errorReporte = null;
      await tocar(tester, find.text('Imprimir nómina (PDF)'));
      expect(find.text('No se pudo armar la nomina.'), findsNothing);
      expect(visor.abiertos, hasLength(1));
      expect(repo.contar('traspasar'), 1);
    });

    testWidgets('mientras genera la nomina no se repite ni se cierra', (
      tester,
    ) async {
      final espera = Completer<void>();
      await abrirTraspaso(tester);
      await tocar(tester, boton('Generar'));
      repo.esperaReporte = espera.future;

      await tester.tap(find.text('Imprimir nómina (PDF)'));
      await tester.pump();
      expect(find.text('Generando…'), findsOneWidget);
      expect(find.text('Imprimir nómina (PDF)'), findsNothing);
      await tester.tap(find.text('Generando…'), warnIfMissed: false);
      await tester.pump();
      expect(repo.contar('reporteTraspaso'), 1);
      // «Listo» tambien espera.
      expect(habilitado(tester, 'Listo'), isFalse);

      espera.complete();
      await esperar(tester);
      expect(repo.contar('reporteTraspaso'), 1);
      expect(visor.abiertos, hasLength(1));
      expect(habilitado(tester, 'Listo'), isTrue);
    });

    testWidgets('desde el telefono tambien se ofrece', (tester) async {
      await abrirTraspaso(tester, ancho: 390);
      await tocar(tester, boton('Generar'));
      await tocar(tester, find.text('Imprimir nómina (PDF)'));
      expect(repo.contar('reporteTraspaso'), 1);
    });
  });

  // ── Sin desbordes: movil, tablet y escritorio, tambien con texto grande ───

  const errorLargo =
      'No tiene permisos para ver los cheques de la sucursal elegida, '
      'consulte con el administrador del sistema antes de volver a pedir el '
      'reporte\n'
      'El rango de fechas pedido es mayor al que permite el servidor para un '
      'solo reporte';

  for (final escala in [1.0, 1.5]) {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      final sufijo =
          'a ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %';

      Future<void> preparar(WidgetTester tester) async {
        if (escala != 1.0) conTexto(tester, escala);
        repo
          ..clientes = [
            clienteDeCheque(
              'C1',
              'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE - CHIQUITOS Y MAS',
            ),
            clienteDeCheque('C2', 'LIBRERIA PAIS'),
          ]
          ..responsables = const [
            PersonalChequeEntity(
              codEmpleado: 12,
              nombreCompleto:
                  'UN RESPONSABLE CON UN NOMBRE MUY LARGO DE LA SUCURSAL CENTRAL',
            ),
          ]
          ..horasDeTraspaso = [
            for (var i = 0; i < 14; i++)
              HoraTraspasoChequeEntity(
                codAccion: 100 + i,
                hora: '${(8 + i).toString().padLeft(2, '0')}:${i % 2 == 0 ? '00' : '30'}',
              ),
          ];
      }

      /// Abre [etiqueta] segun el ancho: menu del telefono o boton Reportes.
      Future<void> abrir(WidgetTester tester, String etiqueta) =>
          abrirReporte(tester, etiqueta, ancho: ancho);

      testWidgets('barra con todos los reportes sin desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await montar(tester, pantalla(), ancho: ancho);
          await abrirMenu(tester, ancho: ancho);
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.text('Reimprimir traspaso'), findsOneWidget);
      });

      testWidgets('recibidos sin desborde $sufijo', (tester) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Cheques recibidos');
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.text('Generar PDF'), findsOneWidget);
      });

      testWidgets('recibidos con error largo sin desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        repo.errorReporte = Exception(errorLargo);
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Cheques recibidos');
          await elegirDia1(tester, 'Fecha final');
          await quitarFecha(tester, 'Fecha inicial');
          await tocar(tester, boton('Generar PDF'));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(
          find.textContaining('El rango de fechas pedido es mayor'),
          findsOneWidget,
        );
      });

      testWidgets('cobranzas sin desborde $sufijo', (tester) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Cheques de cobranza');
          await tester.enterText(
            find.byKey(const ValueKey('campo-cliente')),
            'cliente con',
          );
          await esperar(tester);
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.text('Generar PDF'), findsOneWidget);
      });

      testWidgets('cobranzas con cliente largo elegido y error $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        repo.errorReporte = Exception(errorLargo);
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Cheques de cobranza');
          await tester.enterText(
            find.byKey(const ValueKey('campo-cliente')),
            'cliente con',
          );
          await esperar(tester);
          await tester.tap(find.textContaining('CLIENTE CON UN NOMBRE').last);
          await esperar(tester);
          await tocar(tester, boton('Generar PDF'));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(
          find.textContaining('El rango de fechas pedido es mayor'),
          findsOneWidget,
        );
      });

      testWidgets('custodio con responsable largo sin desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Cheques en custodia');
          await tocar(tester, desplegable('reporte-responsable'));
          await tester.tap(find.textContaining('UN RESPONSABLE CON').last);
          await esperar(tester);
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(habilitado(tester, 'Generar PDF'), isTrue);
      });

      testWidgets('ultimo recibo con error largo sin desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        repo.errorReporte = Exception(errorLargo);
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Recibo del último cheque');
          await tocar(tester, boton('Generar PDF'));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(
          find.textContaining('El rango de fechas pedido es mayor'),
          findsOneWidget,
        );
      });

      testWidgets('reimprimir con muchas horas sin desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Reimprimir traspaso');
          await tocar(tester, find.byKey(const ValueKey('hora-113')));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(habilitado(tester, 'Generar PDF'), isTrue);
      });

      testWidgets('reimprimir sin traspasos ni desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        repo.horasDeTraspaso = const [];
        final errores = await capturandoErrores(() async {
          await abrir(tester, 'Reimprimir traspaso');
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.byKey(const ValueKey('sin-traspasos')), findsOneWidget);
      });

      testWidgets('nomina con error largo sin desborde $sufijo', (tester) async {
        await preparar(tester);
        repo.errorReporte = Exception(errorLargo);
        final errores = await capturandoErrores(() async {
          await montar(tester, pantalla(), ancho: ancho);
          if (ancho < 600) {
            await tester.tap(menuTelefono);
            await esperar(tester);
          }
          await tocarCustodia(tester, 'Traspaso');
          await tocar(tester, boton('Generar'));
          await tocar(tester, find.text('Imprimir nómina (PDF)'));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.text('Se traspasaron 4 cheques.'), findsOneWidget);
        expect(
          find.textContaining('El rango de fechas pedido es mayor'),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('en movil el dialogo ocupa toda la pantalla y el pie baja', (
    tester,
  ) async {
    await abrirReporte(tester, 'Recibo del último cheque', ancho: 390);
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.getSize(find.byType(Dialog)).width, 390);
    expect(tester.getSize(find.byType(Dialog)).height, 844);
    expect(tester.getBottomLeft(boton('Generar PDF')).dy, greaterThan(780));
  });
}

/// El visor de PDF de las pruebas: anota lo que se le pide mostrar en vez de
/// abrir el visor real (que usa plugins que no hay en las pruebas).
class _VisorFalso {
  final List<({Uint8List bytes, String titulo, String nombreArchivo})> abiertos =
      [];

  Future<void> abrir(
    BuildContext context, {
    required Uint8List bytes,
    required String titulo,
    required String nombreArchivo,
  }) async {
    abiertos.add((bytes: bytes, titulo: titulo, nombreArchivo: nombreArchivo));
  }
}
