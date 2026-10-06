import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/state/menu_provider.dart';
import 'package:bosque_flutter/core/state/verificaciones_provider.dart';
import 'package:bosque_flutter/domain/entities/menu_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/domain/repositories/menu_repository.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/screens/verificaciones/verificar_cheques_screen.dart';
import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/paneles_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';
import 'fakes/repositorio_verificaciones.dart';
import 'permisos_paridad_cheques_test.dart'
    show PerfilReal, VerdadLegacy, perfilesReales;

/// FASE 2 de la auditoria de permisos del modulo Cheques (ver `PERMISOS_CHEQUES.md`,
/// secciones 11 a 14): los **paneles del detalle** (notas de remision,
/// transacciones bancarias y postergaciones con su PDF), **«Actualizar datos SAP»**
/// y **Verificar Cheques** (vista 77) y su lugar en el menu, para los 12 perfiles
/// reales, «sin botones» y el administrador. La verdad del legacy (`VerdadLegacy`)
/// es la misma de `permisos_paridad_cheques_test.dart`.
///
/// La DIFERENCIA #5 (el menu del telefono se apagaba entero sin sucursal y con el
/// «Actualizar datos SAP») esta corregida: su prueba es permanente.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  final verdad = VerdadLegacy.nueva;

  // Los 3 paneles se montan con el cheque 5 y datos sembrados.
  final cod = BigInt.from(5);
  RepositorioChequesFalso repoConPaneles() {
    final repo = RepositorioChequesFalso(total: 0);
    repo.notasPorCheque[cod] = [
      NotaRemisionChequeEntity(
        codCheque: cod,
        notaRemision: '262211881',
        nroFactura: 1856,
        fechaFactura: DateTime(2026, 8, 31),
        audUsuario: 66,
        fila: 1,
      ),
      NotaRemisionChequeEntity(
        codCheque: cod,
        notaRemision: '262211820',
        nroFactura: 1795,
        fechaFactura: DateTime(2026, 8, 19),
        audUsuario: 66,
        fila: 2,
      ),
    ];
    repo.transaccionesPorCheque[cod] = [
      TransaccionBancariaEntity(
        codCheque: cod,
        nroTransaccion: 'TT26216QW3N3',
        codBanco: 7,
        fechaTransaccion: DateTime(2026, 8, 4),
        datoBanco: 'BANCO UNION',
        fila: 1,
      ),
    ];
    repo.postergacionesPorCheque[cod] = [
      PostergacionEntity(
        codPostergacion: BigInt.from(40),
        codCheque: cod,
        fecha: DateTime(2026, 9, 20),
        observacion: 'Cliente envio carta solicitando postergacion.',
        audUsuario: 47,
        tienePdf: true,
        fila: 1,
      ),
      PostergacionEntity(
        codPostergacion: BigInt.from(41),
        codCheque: cod,
        fecha: DateTime(2026, 9, 27),
        observacion: 'Segunda vez.',
        audUsuario: 47,
        tienePdf: false,
        fila: 2,
      ),
    ];
    return repo;
  }

  Widget paneles(PerfilReal p, String estado) => appCheques(
    repo: repoConPaneles(),
    permisos: p.permisos,
    login: loginCheques(tipo: p.tipoUsuario),
    hijo: ChequesScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PanelesSatelitesCheque(
          cheque: chequeFalso(5, estado: estado, descTipo: 'PAGO'),
        ),
      ),
    ),
  );

  Finder conClave(String prefijo) => find.byWidgetPredicate(
    (w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith(prefijo),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGICA PURA
  // ═══════════════════════════════════════════════════════════════════════════

  group('logica pura: paneles y Actualizar datos SAP', () {
    for (final p in perfilesReales) {
      test('${p.id}: Nuevo (btnNuevoNRCH), eliminar nota (btnEliminarNRCH), SAP (btnNuevoCH)', () {
        final l = verdad(p);
        final f = p.permisos;
        expect(f.puedeRegistrarEnPaneles, l.sin('btnNuevoNRCH'), reason: 'cheque.xhtml L279, L311, L342');
        expect(f.puedeEliminarNotaRemision, l.sin('btnEliminarNRCH'), reason: 'L295: esAutorizadoB');
        expect(f.puedeActualizarDatosSap, l.sin('btnNuevoCH'), reason: 'L119: wInfoCenter.esAutorizado');
      });
    }

    test('«Actualizar datos SAP» es btnNuevoCH y solo ese: btnNuevo2CH (Registre) no alcanza', () {
      PermisosCheque con(Set<String> b) => PermisosCheque(botones: b, esAdmin: false);
      expect(con({'btnNuevoCH'}).puedeActualizarDatosSap, isTrue);
      expect(con({'btnNuevo2CH'}).puedeActualizarDatosSap, isFalse);
      expect(con({'btnNuevo2CH', 'btnEditar1CH', 'btnDetalleCH'}).puedeActualizarDatosSap, isFalse);
      expect(const PermisosCheque(botones: {}, esAdmin: true).puedeActualizarDatosSap, isTrue);
    });
  });

  test(
    'imprime la matriz legacy vs frontend de los paneles y de SAP (la de PERMISOS_CHEQUES.md)',
    () {
      final cols = perfilesReales.map((p) => p.id == 'SIN_BOTONES' ? 'SIN' : p.id == 'ADMIN' ? 'ADM' : p.id).toList();
      final lineas = <String>[
        '| Componente (legacy) | ${cols.join(' | ')} |',
        '|---|${cols.map((_) => ':-:').join('|')}|',
      ];
      var dif = 0;
      void fila(String nombre, bool Function(PerfilReal) legacy, bool Function(PerfilReal) front) {
        final celdas = <String>[];
        for (final p in perfilesReales) {
          final l = legacy(p), f = front(p);
          if (l != f) dif++;
          celdas.add(l == f ? (l ? '✔' : '✘') : 'DIF');
        }
        lineas.add('| $nombre | ${celdas.join(' | ')} |');
      }

      fila('Notas · Nuevo (btnNuevoNRCH) · L279', (p) => verdad(p).sin('btnNuevoNRCH'), (p) => p.permisos.puedeRegistrarEnPaneles);
      fila('Notas · Eliminar (btnEliminarNRCH, esAutorizadoB) · L295', (p) => verdad(p).sin('btnEliminarNRCH'), (p) => p.permisos.puedeEliminarNotaRemision);
      fila('Transacciones · Nuevo (btnNuevoNRCH) · L311', (p) => verdad(p).sin('btnNuevoNRCH'), (p) => p.permisos.puedeRegistrarEnPaneles);
      fila('Transacciones · Eliminar (sin boton) · L327', (p) => true, (p) => true);
      fila('Postergaciones · Nuevo (btnNuevoNRCH) · L342', (p) => verdad(p).sin('btnNuevoNRCH'), (p) => p.permisos.puedeRegistrarEnPaneles);
      fila('Postergaciones · Eliminar (sin boton) · L356', (p) => true, (p) => true);
      fila('Postergaciones · Cargar / Descargar PDF (sin boton) · L365, L369', (p) => true, (p) => true);
      fila('ACTUALIZAR DATOS SAP (wInfoCenter, btnNuevoCH) · L119', (p) => verdad(p).sin('btnNuevoCH'), (p) => p.permisos.puedeActualizarDatosSap);
      // ignore: avoid_print
      print('\n=== MATRIZ PANELES ===\n${lineas.join('\n')}\n=== FIN MATRIZ ===');
      expect(dif, 0);
    },
    skip:
        const bool.fromEnvironment('MATRIZ')
            ? false
            : 'solo imprime la matriz del documento: flutter test --dart-define=MATRIZ=true',
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LOS PANELES MONTADOS
  // ═══════════════════════════════════════════════════════════════════════════

  for (final ancho in [1280.0, 390.0]) {
    group('paneles del detalle a ${ancho.toInt()} px', () {
      for (final p in perfilesReales) {
        if (ancho < 450 && !{'P1', 'P3', 'P4', 'P5', 'P8', 'P12', 'SIN_BOTONES', 'ADMIN'}.contains(p.id)) continue;
        for (final estado in ['PEN', 'CER']) {
          testWidgets('${p.id} con el cheque $estado', (tester) async {
            await montar(tester, paneles(p, estado), ancho: ancho, alto: 2600);
            final l = verdad(p);

            // «Nuevo» de los tres paneles: un solo boton, btnNuevoNRCH.
            for (final k in ['nuevo-nota-remision', 'nuevo-transaccion', 'nuevo-postergacion']) {
              expect(
                find.byKey(ValueKey(k)),
                l.sin('btnNuevoNRCH') ? findsOneWidget : findsNothing,
                reason: k,
              );
            }
            // Eliminar nota: btnEliminarNRCH (L295; el estado del cheque se ignora).
            expect(
              conClave('eliminar-nota-'),
              l.sin('btnEliminarNRCH') ? findsNWidgets(2) : findsNothing,
              reason: 'eliminar nota',
            );
            // Eliminar transaccion y postergacion y todo el PDF de la postergacion:
            // sin ningun boton (L327, L356, L365, L369).
            expect(conClave('eliminar-transaccion-'), findsNWidgets(1), reason: 'eliminar transaccion');
            expect(conClave('eliminar-postergacion-'), findsNWidgets(2), reason: 'eliminar postergacion');
            expect(conClave('pdf-postergacion-'), findsNWidgets(2), reason: 'PDF de la postergacion');
          });
        }
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTUALIZAR DATOS SAP EN LA BARRA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget cheques(PerfilReal p, RepositorioChequesFalso repo) => appCheques(
    hijo: const ChequesScreen(),
    repo: repo,
    permisos: p.permisos,
    login: loginCheques(tipo: p.tipoUsuario),
  );

  Set<String> itemsAbiertos(WidgetTester tester) => {
    for (final m in tester.widgetList<MenuItemButton>(find.byType(MenuItemButton)))
      if (m.child is Text) (m.child as Text).data!,
  };

  group('Actualizar datos SAP en la barra', () {
    for (final p in perfilesReales) {
      testWidgets('${p.id} a 1280 px: «⋯ Más acciones» con la opcion solo con btnNuevoCH', (tester) async {
        await montar(tester, cheques(p, RepositorioChequesFalso(total: 0)), ancho: 1280);
        final l = verdad(p);
        expect(find.byTooltip('Más acciones'), l.sin('btnNuevoCH') ? findsOneWidget : findsNothing);
        if (l.sin('btnNuevoCH')) {
          await tester.tap(find.byTooltip('Más acciones'));
          await esperar(tester);
          expect(itemsAbiertos(tester), contains('Actualizar datos SAP'));
          await tester.tap(find.text('Actualizar datos SAP'));
          await esperar(tester);
          expect(find.text('Clientes de SAP'), findsOneWidget, reason: 'abre el dialogo');
        }
      });
    }

    for (final p in perfilesReales.where((p) => {'P1', 'P3', 'P5', 'P8', 'P11', 'P12', 'SIN_BOTONES', 'ADMIN'}.contains(p.id))) {
      testWidgets('${p.id} a 390 px: la opcion esta en el menu solo con btnNuevoCH', (tester) async {
        await montar(tester, cheques(p, RepositorioChequesFalso(total: 0)), ancho: 390);
        final l = verdad(p);
        final menus = find.byType(MenuAccionesCheque);
        var items = <String>{};
        if (menus.evaluate().isNotEmpty) {
          await tester.tap(menus.first);
          await esperar(tester);
          items = itemsAbiertos(tester);
        }
        expect(items.contains('Actualizar datos SAP'), l.sin('btnNuevoCH'));
      });
    }

    // ── DIFERENCIA #5 (corregida): el menu del telefono sin sucursal ───────────
    //
    // En el legacy «Actualizar datos SAP» no mira la sucursal. Antes el menu del
    // telefono se apagaba entero sin sucursal y con el la opcion SAP; ahora el menu abre
    // si trae SAP y se apaga SOLO lo que necesita sucursal.

    // La opcion de cada entrada del menu y el boton del legacy que la habilita.
    const entradasYBoton = {
      'Traspaso': 'btnTraspasoCH',
      'A Custodio': 'btnCustodiaCH',
      'Dar Custodia': 'btnCustodia2CH',
      'Cheques recibidos': 'btnRpt1CH',
      'Cheques de cobranza': 'btnRpt2CH',
      'Cheques en custodia': 'btnRpt3CH',
      'Recibo del último cheque': 'btnRpt4CH',
      'Reimprimir traspaso': 'btnRpt5CH',
      'Actualizar datos SAP': 'btnNuevoCH',
    };

    /// Cada opcion abierta del menu y si se puede elegir.
    Map<String, bool> opcionesDelMenu(WidgetTester tester) => {
      for (final m in tester.widgetList<MenuItemButton>(find.byType(MenuItemButton)))
        if (m.child is Text) (m.child as Text).data!: m.onPressed != null,
    };

    RepositorioChequesFalso repoSinSucursal() {
      final repo = RepositorioChequesFalso(total: 0)..sucursalInicial = 0;
      repo.sucursalInicialPorEmpresa = {};
      return repo;
    }

    for (final p in perfilesReales) {
      testWidgets('${p.id} a 390 px SIN sucursal: el menu abre solo si trae SAP y solo «Actualizar datos SAP» se puede elegir', (tester) async {
        await montar(tester, cheques(p, repoSinSucursal()), ancho: 390);
        final l = verdad(p);
        final esperadas = {
          for (final e in entradasYBoton.entries)
            if (l.sin(e.value)) e.key,
        };
        final menus = find.byType(MenuAccionesCheque);
        if (esperadas.isEmpty) {
          expect(menus, findsNothing, reason: 'sin ninguna opcion no hay menu');
          return;
        }
        expect(menus, findsOneWidget);
        final tieneSap = esperadas.contains('Actualizar datos SAP');
        final boton = tester.widget<IconButton>(
          find.descendant(of: menus, matching: find.byType(IconButton)),
        );
        // Sin SAP el menu sigue apagado (todo lo demas necesita sucursal); con SAP abre.
        expect(boton.onPressed != null, tieneSap, reason: 'el boton del menu');
        if (!tieneSap) return;

        await tester.tap(menus);
        await esperar(tester);
        final opciones = opcionesDelMenu(tester);
        expect(opciones.keys.toSet(), esperadas, reason: 'las opciones que el legacy da a ${p.id}');
        for (final o in opciones.entries) {
          expect(
            o.value,
            o.key == 'Actualizar datos SAP',
            reason: '${p.id}: «${o.key}» ${o.value ? 'activa' : 'apagada'} sin sucursal',
          );
        }
      });
    }

    testWidgets('P5 sin sucursal: elegir una opcion apagada no hace nada y «Actualizar datos SAP» abre su dialogo', (tester) async {
      final p = perfilesReales.firstWhere((p) => p.id == 'P5');
      final repo = repoSinSucursal();
      await montar(tester, cheques(p, repo), ancho: 390);

      await tester.tap(find.byType(MenuAccionesCheque));
      await esperar(tester);
      await tester.tap(find.text('Traspaso'), warnIfMissed: false);
      await esperar(tester);
      expect(find.byType(Dialog), findsNothing, reason: 'Traspaso esta apagada');
      expect(repo.contar('contarTraspasosPendientes'), 0);

      await tester.tap(find.text('Actualizar datos SAP'));
      await esperar(tester);
      expect(find.text('Clientes de SAP'), findsOneWidget, reason: 'abre el dialogo de SAP');
    });

    for (final id in ['P1', 'P5', 'P12', 'ADMIN']) {
      testWidgets('$id a 390 px CON sucursal: todas las opciones del menu estan activas', (tester) async {
        final p = perfilesReales.firstWhere((p) => p.id == id);
        await montar(tester, cheques(p, RepositorioChequesFalso(total: 0)..sucursalInicial = 3), ancho: 390);

        await tester.tap(find.byType(MenuAccionesCheque));
        await esperar(tester);
        final opciones = opcionesDelMenu(tester);
        expect(opciones, isNotEmpty);
        expect(opciones.values.every((v) => v), isTrue, reason: '$id: $opciones');
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFICAR CHEQUES (vista 77) Y EL MENU
  // ═══════════════════════════════════════════════════════════════════════════

  /// Lo que el servidor manda en `/view/vistaDinamica` para quien ve [vistas]: el arbol
  /// Cobranzas (126) > Cheques (41) > Cheques (42), Verificar Cheques (77) y
  /// Cobranzas (126) > Administracion (140) > Bancos (43), podado a lo que ve.
  List<MenuItemEntity> menuDelServidor(Set<int> vistas) {
    MenuItemEntity hoja(int cod, int padre, String dir, String titulo) => MenuItemEntity(
      codVista: cod,
      codVistaPadre: padre,
      direccion: dir,
      titulo: titulo,
      esRaiz: 3,
      autorizar: 0,
      audUsuarioI: 0,
      fila: 0,
      tieneHijo: -1,
      routerLink: dir,
      icon: 'pi pi-circle',
    );
    MenuItemEntity nodo(int cod, int padre, String dir, String titulo, int nivel, List<MenuItemEntity> hijos) =>
        MenuItemEntity(
          codVista: cod,
          codVistaPadre: padre,
          direccion: dir,
          titulo: titulo,
          esRaiz: nivel,
          autorizar: 0,
          audUsuarioI: 0,
          fila: 0,
          tieneHijo: cod,
          items: hijos,
        );
    final cheques41 = [
      if (vistas.contains(42)) hoja(42, 41, 'tchCheque/cheque', 'Cheques'),
      if (vistas.contains(77)) hoja(77, 41, 'tchCheque/verificarDepositos', 'Verificar Cheques'),
    ];
    final admin140 = [if (vistas.contains(43)) hoja(43, 140, 'tchBanco/banco', 'Bancos')];
    return [
      nodo(126, 0, 'Cobranzas', 'Cobranzas', 1, [
        if (vistas.contains(41)) nodo(41, 126, 'modCheques', 'Cheques', 2, cheques41),
        if (admin140.isNotEmpty) nodo(140, 126, 'modAdministracion', 'Administracion', 2, admin140),
      ]),
    ];
  }

  Set<String> rutasDelMenu(ProviderContainer c) {
    final salida = <String>{};
    void recorrer(List<SidebarMenuItem> items) {
      for (final i in items) {
        if (i.children == null || i.children!.isEmpty) salida.add(i.route);
        recorrer(i.children ?? const []);
      }
    }

    recorrer(c.read(sidebarMenuProvider));
    return salida;
  }

  group('el menu muestra exactamente lo que manda el servidor', () {
    // Las combinaciones REALES de las vistas 41, 42, 43 y 77 de los usuarios de PRUEBA y produccion
    // (replicar_menu_cheques.ps1), con quien las tiene entre parentesis.
    final combinaciones = <String, Set<int>>{
      'adm: 41,42,43,77': {41, 42, 43, 77},
      'lim: 41,42,43': {41, 42, 43},
      'lim: 41,42,77': {41, 42, 77},
      'lim: 41,42': {41, 42},
      'lim: 41,43 (solo Bancos)': {41, 43},
      'lim: 41,77 (solo Verificar Cheques)': {41, 77},
    };

    for (final e in combinaciones.entries) {
      test(e.key, () async {
        SharedPreferences.setMockInitialValues({});
        final repoMenu = _MenuFalso(menuDelServidor(e.value));
        final c = ProviderContainer(
          overrides: [menuProvider.overrideWith((ref) => MenuNotifier(repoMenu))],
        );
        addTearDown(c.dispose);
        await c.read(menuProvider.notifier).fetchAndSaveMenu(7);

        final rutas = rutasDelMenu(c);
        expect(rutas.contains('/tchCheque/cheque'), e.value.contains(42), reason: 'Cheques');
        expect(rutas.contains('/tchCheque/verificarDepositos'), e.value.contains(77), reason: 'Verificar Cheques');
        expect(rutas.contains('/tchBanco/banco'), e.value.contains(43), reason: 'Bancos');
      });
    }
  });

  group('Verificar Cheques no consulta permisos: quien llega por la ruta ve la pantalla', () {
    for (final id in ['SIN_BOTONES', 'P8', 'ADMIN']) {
      testWidgets('$id (sin la vista 77 en el menu) abre la pantalla escribiendo la ruta', (tester) async {
        final p = perfilesReales.firstWhere((p) => p.id == id);
        final repo = RepositorioVerificacionesFalso(
          verificaciones: [verificacionFalsa(1, monto: 1500.5)],
        );
        await montar(
          tester,
          appCheques(
            hijo: const VerificarChequesScreen(),
            repo: RepositorioChequesFalso(total: 0),
            permisos: p.permisos,
            login: loginCheques(tipo: p.tipoUsuario),
            extra: [
              verificacionesRepositoryProvider.overrideWithValue(repo),
              listaBancosProvider.overrideWith((ref) async => bancosFalsos),
            ],
          ),
          ancho: 1280,
        );
        expect(find.byKey(const ValueKey('fila-1')), findsOneWidget,
            reason: 'la pantalla pide y dibuja las verificaciones sin mirar ningun boton ni vista');
      });
    }
  });
}

/// El repositorio del menu: devuelve el arbol que armaria el servidor.
class _MenuFalso implements MenuRepository {
  _MenuFalso(this.items);

  final List<MenuItemEntity> items;

  @override
  Future<List<MenuItemEntity>> getMenuItems(int codUsuario) async => items;
}
