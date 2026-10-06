import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/actualizar_socios_sap_provider.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_actualizar_socios_sap.dart';
import 'fakes/repositorio_cheques.dart';

/// «Actualizar datos SAP» en la barra de Cheques, con repositorios falsos:
/// que aparezca solo con `btnNuevoCH` (el administrador siempre), que viva en un
/// menu y no como un boton mas, que el dialogo explique para que sirve, bloquee
/// mientras actualiza, cuente el resultado, muestre completo el error del
/// servidor y, al terminar bien, vuelva a pedir los clientes y la grilla.
///
/// Nunca se probo contra el servidor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  late RepositorioActualizarSociosSapFalso sap;

  setUp(() {
    repo =
        RepositorioChequesFalso()
          ..cheques = [chequeFalso(1, descTipo: 'PAGO')]
          ..clientes = [clienteDeCheque('C1', 'EDITORA MENDEZ')];
    sap = RepositorioActualizarSociosSapFalso();
  });

  Widget pantalla({PermisosCheque permisos = permisosAdmin}) => appCheques(
    hijo: const ChequesScreen(),
    repo: repo,
    permisos: permisos,
    extra: [actualizarSociosSapRepositoryProvider.overrideWithValue(sap)],
  );

  // ── Ayudas ────────────────────────────────────────────────────────────────

  /// El menu discreto «⋯» de la barra de escritorio y el del telefono cuando es
  /// el unico: no es el «⋮» de las filas.
  final menuMas = find.widgetWithIcon(IconButton, Icons.more_horiz);

  /// El menu del telefono cuando trae traspaso, custodia o reportes.
  final menuTelefono = find.widgetWithIcon(IconButton, Icons.swap_horiz);

  final opcion = find.text('Actualizar datos SAP');

  Finder boton(String etiqueta) => find.ancestor(
    of: find.text(etiqueta),
    matching: find.bySubtype<FilledButton>(),
  );

  bool habilitado(WidgetTester tester, String etiqueta) =>
      tester.widget<FilledButton>(boton(etiqueta)).onPressed != null;

  Finder enDialogo(Finder f) =>
      find.descendant(of: find.byType(Dialog), matching: f);

  /// Abre el dialogo desde el menu «⋯» de escritorio.
  Future<void> abrirDialogoEscritorio(
    WidgetTester tester, {
    PermisosCheque permisos = permisosAdmin,
  }) async {
    await montar(tester, pantalla(permisos: permisos));
    await tester.tap(menuMas);
    await esperar(tester);
    await tester.tap(opcion);
    await esperar(tester);
  }

  // ── Quien lo ve y donde ───────────────────────────────────────────────────

  group('escritorio: un menu discreto, solo con btnNuevoCH', () {
    testWidgets('el administrador ve el menu «⋯» y no un boton con texto', (
      tester,
    ) async {
      await montar(tester, pantalla());

      expect(menuMas, findsOneWidget);
      expect(find.byTooltip('Más acciones'), findsOneWidget);
      // No es un boton suelto: la opcion solo existe dentro del menu.
      expect(opcion, findsNothing);

      await tester.tap(menuMas);
      await esperar(tester);
      expect(opcion, findsOneWidget);
    });

    testWidgets('un usuario con btnNuevoCH lo ve', (tester) async {
      await montar(tester, pantalla(permisos: permisosCajero));
      expect(menuMas, findsOneWidget);
    });

    testWidgets('sin btnNuevoCH no hay menu ni opcion (aunque tenga otros botones)', (
      tester,
    ) async {
      for (final botones in [
        <String>[],
        ['btnNuevo2CH'], // ve «Registrar», pero el servidor exigiria btnNuevoCH
        ['btnTraspasoCH', 'btnRpt1CH', 'btnDetalleCH'],
      ]) {
        await montar(tester, pantalla(permisos: permisosCon(botones)));
        expect(menuMas, findsNothing, reason: '$botones');
        expect(opcion, findsNothing, reason: '$botones');
      }
    });

    testWidgets('no se apaga sin sucursal: no depende de ella', (tester) async {
      repo.sucursalInicial = 0;
      await montar(tester, pantalla());

      final b = tester.widget<IconButton>(menuMas);
      expect(b.onPressed, isNotNull);
    });
  });

  group('telefono: dentro del menu contextual', () {
    testWidgets('con traspaso, custodia y reportes es una opcion mas, aparte, y el menu lo dice', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 390);

      expect(
        find.byTooltip('Traspaso, custodia, reportes y datos SAP'),
        findsOneWidget,
      );
      // No hay un segundo menu ni un boton suelto.
      expect(menuMas, findsNothing);

      await tester.tap(menuTelefono);
      await esperar(tester);
      expect(find.text('Traspaso'), findsOneWidget);
      expect(find.text('Cheques recibidos'), findsOneWidget);
      expect(opcion, findsOneWidget);
    });

    testWidgets('su nombre cambia segun lo que trae', (tester) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnNuevoCH', 'btnTraspasoCH'])),
        ancho: 390,
      );
      expect(find.byTooltip('Traspaso, custodia y datos SAP'), findsOneWidget);

      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnNuevoCH', 'btnRpt1CH'])),
        ancho: 390,
      );
      expect(find.byTooltip('Reportes y datos SAP'), findsOneWidget);
    });

    testWidgets('sin ellos el menu se llama como siempre', (tester) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnTraspasoCH', 'btnRpt2CH'])),
        ancho: 390,
      );
      expect(find.byTooltip('Traspaso, custodia y reportes'), findsOneWidget);

      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnTraspasoCH'])),
        ancho: 390,
      );
      expect(find.byTooltip('Traspaso y custodia'), findsOneWidget);
    });

    testWidgets('si es lo unico, el menu es solo ese y no se apaga sin sucursal', (
      tester,
    ) async {
      repo.sucursalInicial = 0;
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnNuevoCH'])),
        ancho: 390,
      );

      expect(find.byTooltip('Actualizar datos SAP'), findsOneWidget);
      final b = tester.widget<IconButton>(menuMas);
      expect(b.onPressed, isNotNull);

      await tester.tap(menuMas);
      await esperar(tester);
      expect(opcion, findsOneWidget);
    });

    /// Cada opcion abierta del menu y si se puede elegir.
    Map<String, bool> opcionesDelMenu(WidgetTester tester) => {
      for (final m in tester.widgetList<MenuItemButton>(
        find.byType(MenuItemButton),
      ))
        if (m.child is Text) (m.child as Text).data!: m.onPressed != null,
    };

    testWidgets(
      'sin sucursal y con traspaso y reportes el menu abre y solo «Actualizar datos SAP» esta activa (diferencia #5)',
      (tester) async {
        repo.sucursalInicial = 0;
        repo.sucursalInicialPorEmpresa = {};
        await montar(
          tester,
          pantalla(
            permisos: permisosCon(['btnNuevoCH', 'btnTraspasoCH', 'btnRpt1CH']),
          ),
          ancho: 390,
        );

        final b = tester.widget<IconButton>(menuTelefono);
        expect(b.onPressed, isNotNull, reason: 'el menu abre: trae una opcion sin sucursal');

        await tester.tap(menuTelefono);
        await esperar(tester);
        expect(opcionesDelMenu(tester), {
          'Traspaso': false,
          'Cheques recibidos': false,
          'Actualizar datos SAP': true,
        });

        // La opcion activa funciona sin sucursal: abre su dialogo.
        await tester.tap(opcion);
        await esperar(tester);
        expect(enDialogo(find.text('Actualizar datos SAP')), findsOneWidget);
        expect(habilitado(tester, 'Actualizar'), isTrue);
      },
    );

    testWidgets(
      'sin sucursal y SIN btnNuevoCH el menu del telefono sigue apagado',
      (tester) async {
        repo.sucursalInicial = 0;
        repo.sucursalInicialPorEmpresa = {};
        await montar(
          tester,
          pantalla(permisos: permisosCon(['btnTraspasoCH', 'btnRpt1CH'])),
          ancho: 390,
        );

        final b = tester.widget<IconButton>(menuTelefono);
        expect(b.onPressed, isNull);
      },
    );

    testWidgets('con sucursal todas las opciones del menu estan activas', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(
          permisos: permisosCon(['btnNuevoCH', 'btnTraspasoCH', 'btnRpt1CH']),
        ),
        ancho: 390,
      );
      await tester.tap(menuTelefono);
      await esperar(tester);

      expect(opcionesDelMenu(tester), {
        'Traspaso': true,
        'Cheques recibidos': true,
        'Actualizar datos SAP': true,
      });
    });

    testWidgets('sin btnNuevoCH no aparece en el menu', (tester) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon(['btnTraspasoCH', 'btnRpt1CH'])),
        ancho: 390,
      );
      await tester.tap(find.widgetWithIcon(IconButton, Icons.swap_horiz));
      await esperar(tester);
      expect(opcion, findsNothing);
    });
  });

  // ── El dialogo ────────────────────────────────────────────────────────────

  group('el dialogo', () {
    testWidgets('explica para que sirve y no hace nada hasta que se pide', (
      tester,
    ) async {
      await abrirDialogoEscritorio(tester);

      expect(enDialogo(find.text('Actualizar datos SAP')), findsOneWidget);
      expect(
        enDialogo(
          find.text(
            'Trae los clientes nuevos de SAP; los cheques de un cliente que no '
            'esté cargado no aparecen en la lista.',
          ),
        ),
        findsOneWidget,
      );
      expect(habilitado(tester, 'Actualizar'), isTrue);
      expect(sap.llamadas, 0);
    });

    testWidgets('Cancelar cierra sin llamar al servidor', (tester) async {
      await abrirDialogoEscritorio(tester);

      await tester.tap(find.text('Cancelar'));
      await esperar(tester);

      expect(find.byType(Dialog), findsNothing);
      expect(sap.llamadas, 0);
    });

    testWidgets('mientras actualiza el boton dice «Actualizando…», se bloquea y no se puede cerrar ni repetir', (
      tester,
    ) async {
      sap.esperar = Completer<void>();
      await abrirDialogoEscritorio(tester);

      await tester.tap(find.text('Actualizar'));
      await esperar(tester);

      expect(find.text('Actualizando…'), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
      expect(habilitado(tester, 'Actualizando…'), isFalse);
      expect(
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar')).onPressed,
        isNull,
        reason: 'no se puede cancelar mientras SAP responde',
      );
      // Un segundo toque (o un Esc) no manda nada ni cierra.
      await tester.tap(find.text('Actualizando…'), warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await esperar(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(sap.llamadas, 1);

      sap.esperar!.complete();
      await esperar(tester);
      expect(find.text('Actualizando…'), findsNothing);
    });

    testWidgets('cuenta el resultado con la frase del servidor y se cierra con «Listo»', (
      tester,
    ) async {
      await abrirDialogoEscritorio(tester);

      await tester.tap(find.text('Actualizar'));
      await esperar(tester);

      expect(sap.llamadas, 1);
      expect(
        find.text(
          'Clientes actualizados desde SAP. Los cheques de los clientes que '
          'antes no estaban cargados ya aparecen en la lista.',
        ),
        findsOneWidget,
      );
      // Ya no se ofrece actualizar de nuevo: solo cerrar.
      expect(find.text('Actualizar'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);

      await tester.tap(find.text('Listo'));
      await esperar(tester);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('el resultado es un aviso de exito SIN numero de clientes (el servidor no lo informa)', (
      tester,
    ) async {
      await abrirDialogoEscritorio(tester);

      await tester.tap(find.text('Actualizar'));
      await esperar(tester);

      final aviso = find.byKey(const ValueKey('actualizar-sap-resultado'));
      expect(aviso, findsOneWidget);
      final texto = tester.widget<Text>(
        find.descendant(of: aviso, matching: find.byType(Text)),
      );
      expect(texto.data, isNot(matches(RegExp(r'\d'))));
      expect(
        find.text('La lista de clientes y la de cheques se volvieron a cargar.'),
        findsOneWidget,
      );
    });

    testWidgets('un error del servidor se ve completo con el dialogo abierto y se puede reintentar', (
      tester,
    ) async {
      const error =
          'No se pudieron traer los clientes de SAP. Lo más probable es que el '
          'servidor de SAP no esté respondiendo en este momento.\n'
          'Intenta de nuevo en unos minutos y, si el error se repite, avisa a '
          'Sistemas.';
      sap.error = error;
      await abrirDialogoEscritorio(tester);

      await tester.tap(find.text('Actualizar'));
      await esperar(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.textContaining('No se pudieron traer los clientes de SAP.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Intenta de nuevo en unos minutos'),
        findsOneWidget,
        reason: 'las dos lineas del mensaje, completas',
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);

      // Se arregla SAP y se reintenta.
      sap.error = null;
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);

      expect(sap.llamadas, 2);
      expect(
        find.textContaining('Clientes actualizados desde SAP.'),
        findsOneWidget,
      );
      expect(find.textContaining('No se pudieron traer'), findsNothing);
    });

    testWidgets('el error de falta de permiso del servidor tambien llega tal cual', (
      tester,
    ) async {
      sap.error =
          'No tienes permiso para traer los clientes nuevos de SAP. Esta acción '
          'usa el botón btnNuevoCH de la pantalla de Cheques (el mismo de '
          '«Registrar»), que tu usuario no tiene asignado; pídele al '
          'administrador que te lo asigne.';
      await abrirDialogoEscritorio(tester);

      await tester.tap(find.text('Actualizar'));
      await esperar(tester);

      expect(find.textContaining('btnNuevoCH'), findsOneWidget);
      expect(find.textContaining('pídele al administrador'), findsOneWidget);
    });

    testWidgets('al abrirlo otra vez no arrastra el resultado ni el error de la vez anterior', (
      tester,
    ) async {
      sap.error = 'Fallo de prueba.';
      await abrirDialogoEscritorio(tester);
      await tester.tap(find.text('Actualizar'));
      await esperar(tester);
      expect(find.text('Fallo de prueba.'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      await tester.tap(menuMas);
      await esperar(tester);
      await tester.tap(opcion);
      await esperar(tester);

      expect(find.text('Fallo de prueba.'), findsNothing);
      expect(find.text('Actualizar'), findsOneWidget);
    });
  });

  // ── Lo que deja viejo ─────────────────────────────────────────────────────

  group('al salir bien vuelve a pedir los clientes y la grilla', () {
    testWidgets('relee la grilla y el combo de clientes', (tester) async {
      await abrirDialogoEscritorio(tester);

      // El combo de clientes de la empresa 1 ya se habia pedido una vez.
      final contenedor = ProviderScope.containerOf(
        tester.element(find.byType(ChequesScreen)),
      );
      await contenedor.read(clientesChequeProvider(1).future);
      final grillaAntes = repo.contar('listar');
      final clientesAntes = repo.contar('listarClientes');

      await tester.tap(find.text('Actualizar'));
      await esperar(tester);

      expect(repo.contar('listar'), grillaAntes + 1, reason: 'la grilla');
      // El combo se vuelve a pedir cuando alguien lo lee.
      await contenedor.read(clientesChequeProvider(1).future);
      expect(repo.contar('listarClientes'), clientesAntes + 1);
    });

    testWidgets('si falla no toca nada', (tester) async {
      sap.error = 'Fallo de prueba.';
      await abrirDialogoEscritorio(tester);
      final contenedor = ProviderScope.containerOf(
        tester.element(find.byType(ChequesScreen)),
      );
      await contenedor.read(clientesChequeProvider(1).future);
      final grillaAntes = repo.contar('listar');
      final clientesAntes = repo.contar('listarClientes');

      await tester.tap(find.text('Actualizar'));
      await esperar(tester);

      expect(repo.contar('listar'), grillaAntes);
      await contenedor.read(clientesChequeProvider(1).future);
      expect(repo.contar('listarClientes'), clientesAntes);
    });

    test('el notifier no lanza una segunda actualizacion mientras otra corre', () async {
      sap.esperar = Completer<void>();
      final contenedor = ProviderContainer(
        overrides: [
          actualizarSociosSapRepositoryProvider.overrideWithValue(sap),
          chequesRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(contenedor.dispose);
      final sub = contenedor.listen(actualizarSociosSapProvider, (_, __) {});
      addTearDown(sub.close);
      final notifier = contenedor.read(actualizarSociosSapProvider.notifier);

      final primera = notifier.actualizar();
      expect(contenedor.read(actualizarSociosSapProvider).ocupado, isTrue);
      final segunda = await notifier.actualizar();
      expect(segunda, isNull);
      expect(sap.llamadas, 1);

      sap.esperar!.complete();
      final r = await primera;
      expect(r?.mensaje, startsWith('Clientes actualizados desde SAP.'));
      expect(contenedor.read(actualizarSociosSapProvider).ocupado, isFalse);
      expect(
        contenedor.read(actualizarSociosSapProvider).resultado?.mensaje,
        startsWith('Clientes actualizados desde SAP.'),
      );
    });
  });

  // ── Responsive y texto grande ─────────────────────────────────────────────

  group('el dialogo no desborda', () {
    for (final ancho in [390.0, 1400.0]) {
      for (final factor in [1.0, 1.5]) {
        testWidgets('a $ancho px con texto al ${(factor * 100).round()} %', (
          tester,
        ) async {
          conTexto(tester, factor);
          sap.error =
              'No se pudieron traer los clientes de SAP. Lo más probable es que '
              'el servidor de SAP no esté respondiendo en este momento.\n'
              'Intenta de nuevo en unos minutos y, si el error se repite, '
              'avisa a Sistemas.';
          final errores = await capturandoErrores(() async {
            await montar(tester, pantalla(), ancho: ancho);
            if (ancho < 600) {
              await tester.tap(menuTelefono);
            } else {
              await tester.tap(menuMas);
            }
            await esperar(tester);
            await tester.tap(opcion);
            await esperar(tester);
            await tester.tap(find.text('Actualizar'));
            await esperar(tester);
            sap.error = null;
            await tester.tap(find.text('Reintentar'));
            await esperar(tester);
          });
          expect(errores, isEmpty);
        });
      }
    }
  });

  test('los widgets nuevos no escriben colores a mano', () {
    final archivos = [
      'lib/presentation/widgets/cheques/actualizar_datos_sap_cheque.dart',
      'lib/presentation/screens/cheques/cheques_screen.dart',
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
