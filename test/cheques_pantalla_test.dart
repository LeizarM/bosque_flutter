import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_pagina_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/sucursal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// La pantalla principal de cheques con un repositorio falso: tabla en
/// escritorio y tarjetas en movil, acciones segun permisos, filtros, paginacion
/// del servidor y los estados que no son datos (sin sucursal, vacio, error).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  setUp(() => repo = RepositorioChequesFalso());

  Widget pantalla({PermisosCheque permisos = permisosAdmin}) =>
      appCheques(hijo: const ChequesScreen(), repo: repo, permisos: permisos);

  /// Casos que estiran el diseno: textos largos, un cheque cerrado, un tipo
  /// corrupto, un importe enorme y un cheque entregado por un empleado.
  List<ChequeFilaEntity> filasDePrueba() => [
    chequeFalso(
      1,
      cliente:
          'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE - CHIQUITOS',
      banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
      aOrdenDe: 'BOSQUE INDUSTRIAL DE PAPELES Y AFINES S.A.',
      descTipo: 'RESPALDO',
      codEmpleado: 12,
      datoEmpleado: ' - Juan Carlos Pérez de la Fuente Rodríguez -',
      monto: 12345678.9,
    ),
    chequeFalso(2, estado: 'CER', descTipo: 'PAGO'),
    chequeFalso(3, tipo: '\u0001\u0002ÿþ', descTipo: null),
    for (var i = 4; i <= 12; i++) chequeFalso(i, descTipo: 'PAGO'),
  ];

  // ── Sin desbordes: movil, tablet y escritorio, tambien con texto grande ───

  final modoPorAncho = {
    390.0: 'lista-tarjetas',
    700.0: 'lista-tarjetas',
    800.0: 'lista-tabla',
    1000.0: 'lista-tabla',
    1400.0: 'lista-tabla',
    1800.0: 'lista-tabla',
  };

  for (final escala in [1.0, 1.5]) {
    modoPorAncho.forEach((ancho, modo) {
      testWidgets(
        'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} % ($modo)',
        (tester) async {
          repo.cheques = filasDePrueba();
          if (escala != 1.0) conTexto(tester, escala);

          final errores = await capturandoErrores(() async {
            await montar(tester, pantalla(), ancho: ancho);
          });

          expect(errores, isEmpty, reason: 'a $ancho');
          expect(find.byKey(ValueKey(modo)), findsOneWidget);
          expect(find.textContaining('Banco Mercantil'), findsWidgets);
        },
      );
    });
  }

  testWidgets('en escritorio hay una columna por dato', (tester) async {
    repo.cheques = filasDePrueba();
    await montar(tester, pantalla(), ancho: 1800);

    final tabla = find.byKey(const ValueKey('lista-tabla'));
    for (final c in [
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
      'Acciones',
    ]) {
      expect(
        find.descendant(of: tabla, matching: find.text(c)),
        findsOneWidget,
        reason: 'columna $c',
      );
    }
    // El monto, redondeado: la cifra en mono y la moneda en una pastilla aparte
    // («Bs»); un lector de pantalla oye las dos juntas.
    expect(find.text('12,345,678.90'), findsOneWidget);
    expect(find.text('1,500.50'), findsWidgets);
    expect(find.text('Bs'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Bs 12,345,678.90',
      ),
      findsOneWidget,
    );
    expect(find.text('PENDIENTE'), findsWidgets);
    expect(find.text('CERRADO'), findsOneWidget);
    // Sin desplazamiento horizontal cuando sobra ancho.
    expect(
      find.descendant(of: tabla, matching: find.byType(Scrollbar)),
      findsNothing,
    );
  });

  // ── Columnas segun el ancho ───────────────────────────────────────────────

  group('columnas segun el ancho disponible', () {
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
    const esenciales = [
      'Cliente',
      'Nro. cheque',
      'Banco',
      'Monto',
      'F. cobro',
      'Estado',
    ];

    Set<String> visibles(WidgetTester tester) {
      final tabla = find.byKey(const ValueKey('lista-tabla'));
      return {
        for (final c in todas)
          if (find.descendant(of: tabla, matching: find.text(c)).evaluate().isNotEmpty) c,
      };
    }

    final hayBarra = find.descendant(
      of: find.byKey(const ValueKey('lista-tabla')),
      matching: find.byType(Scrollbar),
    );

    testWidgets('con ancho de sobra, todas y sin aviso ni barra', (tester) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 1800);
      expect(visibles(tester), todas.toSet());
      expect(find.byKey(const ValueKey('columnas-ocultas')), findsNothing);
      expect(hayBarra, findsNothing);
    });

    testWidgets('a 1400 se ocultan primero el tipo y el numero de fila, y lo avisa', (
      tester,
    ) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 1400);

      expect(
        visibles(tester),
        todas.toSet()..removeAll({'#', 'Tipo'}),
      );
      final aviso = tester.widget<Text>(
        find.byKey(const ValueKey('columnas-ocultas')),
      );
      expect(aviso.data, contains('#, Tipo'));
      // Entran sin desplazarse y las acciones siguen a la vista.
      expect(hayBarra, findsNothing);
      expect(find.byTooltip('Completar'), findsWidgets);
    });

    testWidgets('a 900 quedan las esenciales y las acciones en un menu', (
      tester,
    ) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 900);

      expect(visibles(tester), esenciales.toSet());
      expect(hayBarra, findsNothing);
      // Tres iconos no entran junto a las esenciales: un solo menu por fila.
      expect(find.byTooltip('Completar'), findsNothing);
      expect(find.byTooltip('Acciones'), findsWidgets);
      await tester.tap(find.byTooltip('Acciones').first);
      await esperar(tester);
      expect(find.text('Completar'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Editar (administrador)'), findsNothing);
    });

    testWidgets('a 1000 el administrador tiene sus tres iconos sueltos', (
      tester,
    ) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 1000);

      expect(visibles(tester), esenciales.toSet());
      expect(hayBarra, findsNothing);
      expect(find.byTooltip('Acciones'), findsNothing);
      // Un solo lapiz, la fecha de cobro y completar: cabe sin menu.
      expect(find.byTooltip('Editar'), findsWidgets);
      expect(find.byTooltip('Fecha de cobro'), findsWidgets);
      expect(find.byTooltip('Completar'), findsWidgets);
    });

    testWidgets('a 1000 con dos acciones siguen los iconos', (tester) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 1000);
      expect(find.byTooltip('Completar'), findsWidgets);
      expect(find.byTooltip('Acciones'), findsNothing);
    });

    testWidgets('a 800 se desplaza de lado y las acciones quedan pegadas', (
      tester,
    ) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 800);

      expect(visibles(tester), esenciales.toSet());
      expect(hayBarra, findsOneWidget);

      double derecha() => tester.getRect(find.byTooltip('Acciones').first).right;
      final antes = derecha();
      expect(antes, lessThanOrEqualTo(800));

      // Despues de desplazar a la derecha el menu sigue en el mismo lugar.
      await tester.drag(
        find.descendant(
          of: find.byKey(const ValueKey('lista-tabla')),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(-300, 0),
      );
      await esperar(tester);
      expect(derecha(), antes);
      await tester.tap(find.byTooltip('Acciones').first);
      await esperar(tester);
      expect(find.text('Completar'), findsOneWidget);
    });

    testWidgets('lo oculto se ve en el detalle', (tester) async {
      final cheque = chequeFalso(1, descTipo: 'RESPALDO');
      repo.cheques = [cheque];
      repo.alObtenerDetalle =
          (cod) async => ChequeDetalleEntity(
            cheque: cheque,
            acciones: const [],
            botones: BotonesChequeEntity.ninguno,
          );
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 1400);
      expect(find.text('RESPALDO'), findsNothing);
      await tester.tap(find.byTooltip('Completar'));
      await esperar(tester);
      expect(find.text('RESPALDO'), findsOneWidget);
    });
  });

  testWidgets('en movil no hay scroll horizontal: tarjetas', (tester) async {
    repo.cheques = filasDePrueba();
    await montar(tester, pantalla(), ancho: 390);

    expect(find.byKey(const ValueKey('lista-tabla')), findsNothing);
    expect(find.byKey(const ValueKey('lista-tarjetas')), findsOneWidget);
    // Ningun scroll horizontal en toda la pantalla.
    final horizontales = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(horizontales, findsNothing);
  });

  // ── Tolerancia a los datos reales ─────────────────────────────────────────

  for (final ancho in [390.0, 1400.0]) {
    testWidgets(
      'un tipo corrupto (descTipo null) no se muestra crudo a ${ancho.toInt()} px',
      (tester) async {
        repo.cheques = [
          chequeFalso(
            3,
            tipo: 'ZZTIPOCORRUPTO\u0001ÿ',
            descTipo: null,
            cliente: 'SOLO ESTE',
          ),
        ];
        final errores = await capturandoErrores(() async {
          await montar(tester, pantalla(), ancho: ancho);
        });

        expect(errores, isEmpty);
        expect(find.textContaining('SOLO ESTE'), findsOneWidget);
        expect(find.textContaining('ZZTIPOCORRUPTO'), findsNothing);
        // La fecha de auditoria es texto del servidor: tampoco se muestra.
        expect(find.textContaining('14:54'), findsNothing);
      },
    );
  }

  testWidgets('un descTipo valido si se muestra', (tester) async {
    repo.cheques = [chequeFalso(3, descTipo: 'RESPALDO')];
    await montar(tester, pantalla(), ancho: 1800);
    expect(find.text('RESPALDO'), findsOneWidget);
  });

  testWidgets('un cheque entregado por el cliente dice quien, sin adornos', (
    tester,
  ) async {
    repo.cheques = [chequeFalso(3, descTipo: 'PAGO')];
    await montar(tester, pantalla(), ancho: 1800);
    expect(find.text('Entregado por el Cliente'), findsOneWidget);
  });

  // ── Acciones por fila, segun los permisos ────────────────────────────────

  group('acciones de la fila (tabla)', () {
    Future<void> abrir(
      WidgetTester tester,
      PermisosCheque permisos, {
      String estado = 'PEN',
    }) async {
      repo.cheques = [chequeFalso(1, estado: estado, descTipo: 'PAGO')];
      await montar(tester, pantalla(permisos: permisos), ancho: 1400);
    }

    // «Editar (administrador)» ya no existe: el administrador tiene un solo
    // lapiz.
    const todas = [
      'Editar',
      'Editar talonario',
      'Fecha de cobro',
      'Editar (administrador)',
      'Completar',
      'Documento PDF',
    ];

    /// Las acciones que dependen de permisos. «Documento PDF» no: esta en toda
    /// fila, con o sin botones, como en el legacy.
    void esperarSolo(List<String> visibles) {
      for (final a in todas) {
        expect(
          find.byTooltip(a),
          (visibles.contains(a) || a == 'Documento PDF')
              ? findsOneWidget
              : findsNothing,
          reason: a,
        );
      }
    }

    testWidgets('cajero con el cheque abierto: editar y completar', (
      tester,
    ) async {
      await abrir(tester, permisosCajero);
      esperarSolo(['Editar', 'Completar']);
    });

    testWidgets('cajero con el cheque cerrado: solo editar talonario y completar', (
      tester,
    ) async {
      await abrir(tester, permisosCajero, estado: 'CER');
      esperarSolo(['Editar talonario', 'Completar']);
    });

    testWidgets('«Fecha de cobro» con btnEditar2CH, y con btnEditar3CH tambien', (
      tester,
    ) async {
      await abrir(tester, permisosCon([PermisosCheque.btnFechaCobro]));
      esperarSolo(['Fecha de cobro']);
    });

    testWidgets('btnEditar3CH: un solo lapiz y la fecha de cobro', (
      tester,
    ) async {
      await abrir(tester, permisosCon([PermisosCheque.btnEditarAdmin]));
      esperarSolo(['Editar', 'Fecha de cobro']);
    });

    testWidgets('con btnEditar3CH un cheque cerrado no ofrece esas variantes', (
      tester,
    ) async {
      await abrir(
        tester,
        permisosCon([PermisosCheque.btnEditarAdmin]),
        estado: 'CER',
      );
      esperarSolo([]);
    });

    testWidgets('administrador con el cheque abierto: un lapiz, fecha y completar', (
      tester,
    ) async {
      await abrir(tester, permisosAdmin);
      esperarSolo(['Editar', 'Fecha de cobro', 'Completar']);
    });

    testWidgets('administrador con el cheque cerrado: lo mismo, sin editar talonario', (
      tester,
    ) async {
      await abrir(tester, permisosAdmin, estado: 'CER');
      esperarSolo(['Editar', 'Fecha de cobro', 'Completar']);
    });

    testWidgets('sin ningun boton: solo el documento PDF', (tester) async {
      await abrir(tester, permisosNinguno);
      esperarSolo([]);
      // La columna de acciones existe porque el PDF no pide permiso.
      expect(find.text('Acciones'), findsOneWidget);
    });

    testWidgets('«Completar» abre el detalle con btnDetalleCH', (tester) async {
      await abrir(tester, permisosCajero);
      await tester.tap(find.byTooltip('Completar'));
      await esperar(tester);
      expect(repo.contar('obtenerDetalle'), 1);
      expect(find.text('Ir atrás'), findsOneWidget);
    });
  });

  testWidgets('en movil las acciones van en un menu contextual', (tester) async {
    repo.cheques = [chequeFalso(1, descTipo: 'PAGO')];
    await montar(tester, pantalla(permisos: permisosCajero), ancho: 390);

    // Ninguna accion suelta en la tarjeta.
    expect(find.byTooltip('Editar'), findsNothing);
    await tester.tap(find.byTooltip('Acciones'));
    await esperar(tester);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Completar'), findsOneWidget);
    expect(find.text('Editar talonario'), findsNothing);
  });

  // ── Cabecera: registrar ───────────────────────────────────────────────────

  group('registrar', () {
    // Un solo «Registrar»: visible con btnNuevoCH o con btnNuevo2CH. Con que
    // formulario abre cada uno se prueba en cheques_barra_edicion_test.dart.
    testWidgets('cajero: «Registrar» y no la variante de administrador', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosCajero));
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Registrar como administrador'), findsNothing);
    });

    testWidgets('btnNuevo2CH solo: tambien ve «Registrar», uno solo', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon([PermisosCheque.btnNuevoAdmin])),
      );
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Registrar como administrador'), findsNothing);
    });

    testWidgets('con los dos permisos de alta sigue habiendo un solo boton', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(
          permisos: permisosCon([
            PermisosCheque.btnNuevo,
            PermisosCheque.btnNuevoAdmin,
          ]),
        ),
      );
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Registrar como administrador'), findsNothing);
    });

    testWidgets('sin boton no hay ninguno de los dos', (tester) async {
      await montar(tester, pantalla(permisos: permisosNinguno));
      expect(find.text('Registrar'), findsNothing);
      expect(find.text('Registrar como administrador'), findsNothing);
    });

    testWidgets('administrador en movil: un solo boton, sin menu', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 390);
      final registrar = find.byTooltip('Registrar cheque');
      expect(registrar, findsOneWidget);
      await tester.tap(registrar);
      await esperar(tester);
      // Abre el formulario directamente; no hay menu con una segunda opcion.
      expect(find.text('Registrar como administrador'), findsNothing);
      expect(find.text('Registrar cheque (administrador)'), findsOneWidget);
    });
  });

  // ── Sucursal ──────────────────────────────────────────────────────────────

  group('sucursal', () {
    DropdownButtonFormField<int> combo(WidgetTester tester) =>
        tester.widget(comboSucursal());

    testWidgets('sin btnChqSucrs el combo esta bloqueado en la sucursal inicial', (
      tester,
    ) async {
      repo.cheques = [chequeFalso(1, descTipo: 'PAGO')];
      await montar(tester, pantalla(permisos: permisosCajero));

      expect(combo(tester).onChanged, isNull);
      expect(find.text('LA PAZ'), findsWidgets);
      expect(repo.filtros.single.codSucursal, 3);
    });

    testWidgets('con btnChqSucrs el combo cambia de sucursal y vuelve a la pagina 1', (
      tester,
    ) async {
      repo.cheques = [
        chequeFalso(1, descTipo: 'PAGO'),
        chequeFalso(2, descTipo: 'PAGO', codSucursal: 4, cliente: 'OTRA SUC'),
      ];
      await montar(
        tester,
        pantalla(permisos: permisosCon([PermisosCheque.btnSucursales])),
      );
      expect(combo(tester).onChanged, isNotNull);

      await tester.tap(comboSucursal());
      await esperar(tester);
      await tester.tap(find.text('EL ALTO').last);
      await esperar(tester);

      expect(repo.filtros.last.codSucursal, 4);
      expect(repo.filtros.last.pagina, 1);
      expect(find.text('OTRA SUC'), findsOneWidget);
    });

    testWidgets(
      'sin sucursal inicial y sin btnChqSucrs: mensaje claro, sin grilla y con la empresa a mano',
      (tester) async {
        repo.sucursalInicial = 0;
        await montar(tester, pantalla(permisos: permisosCajero));

        expect(
          find.text('Tu usuario no tiene una sucursal asignada en esta empresa'),
          findsOneWidget,
        );
        expect(repo.contar('listar'), 0);
        expect(find.byKey(const ValueKey('lista-tabla')), findsNothing);
        // Los filtros siguen: sin sucursal en una empresa se puede pasar a la
        // otra. Buscar espera a tener sucursal.
        expect(comboEmpresa(), findsOneWidget);
        final buscar = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Buscar'),
            matching: find.bySubtype<FilledButton>(),
          ),
        );
        expect(buscar.onPressed, isNull);
        // No es un error tecnico.
        expect(find.text('Reintentar'), findsNothing);
        // Y registrar queda apagado: el cheque no tendria donde quedar.
        final registrar = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Registrar'),
            matching: find.bySubtype<FilledButton>(),
          ),
        );
        expect(registrar.onPressed, isNull);
      },
    );

    testWidgets('sin sucursal inicial pero con btnChqSucrs pide elegir una', (
      tester,
    ) async {
      repo.sucursalInicial = 0;
      repo.cheques = [chequeFalso(1, descTipo: 'PAGO')];
      await montar(
        tester,
        pantalla(permisos: permisosCon([PermisosCheque.btnSucursales])),
      );
      expect(find.text('Elige una sucursal'), findsWidgets);
      expect(find.text('Buscar'), findsOneWidget);
      expect(repo.contar('listar'), 0);
    });
  });

  // ── Empresa ───────────────────────────────────────────────────────────────

  group('empresa', () {
    DropdownButtonFormField<int> combo(WidgetTester tester) =>
        tester.widget(comboEmpresa());

    Future<void> elegirEmpresa(WidgetTester tester, String nombre) async {
      await tester.ensureVisible(comboEmpresa());
      await tester.tap(comboEmpresa());
      await esperar(tester);
      await tester.tap(find.text(nombre).last);
      await esperar(tester);
    }

    testWidgets(
      'arranca en la primera empresa aunque el login sea de otra (la 6, sin nombre)',
      (tester) async {
        repo.cheques = [chequeFalso(1, descTipo: 'PAGO')];
        await montar(tester, pantalla(permisos: permisosCajero));

        expect(find.text('IMPEXPAP'), findsWidgets);
        expect(repo.empresasDeSucursalInicial, [1]);
        expect(repo.empresasDeSucursales, [1]);
        expect(repo.filtros.single.codSucursal, 3);
      },
    );

    testWidgets('cualquier usuario puede cambiarla; la sucursal sigue bloqueada', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosCajero));
      expect(combo(tester).onChanged, isNotNull);
      expect(tester.widget<DropdownButtonFormField<int>>(comboSucursal()).onChanged, isNull);
      // La empresa va inmediatamente antes de la sucursal.
      expect(
        tester.getTopLeft(comboEmpresa()).dx,
        lessThan(tester.getTopLeft(comboSucursal()).dx),
      );
      expect(
        tester.getTopLeft(comboEmpresa()).dy,
        tester.getTopLeft(comboSucursal()).dy,
      );
    });

    testWidgets(
      'cambiarla pide la sucursal de esa empresa, trae sus sucursales y recarga la grilla',
      (tester) async {
        repo.cheques = [
          chequeFalso(1, descTipo: 'PAGO', cliente: 'DE LA UNO'),
          chequeFalso(
            2,
            descTipo: 'PAGO',
            codSucursal: 7,
            codEmpresa: 5,
            cliente: 'DE LA CINCO',
          ),
        ];
        await montar(tester, pantalla(permisos: permisosCajero));
        expect(find.text('DE LA UNO'), findsOneWidget);

        await elegirEmpresa(tester, 'ESPPAPEL');

        expect(repo.empresasDeSucursalInicial, [1, 5]);
        expect(repo.empresasDeSucursales, [1, 5]);
        expect(repo.filtros.last.codSucursal, 7);
        expect(repo.filtros.last.pagina, 1);
        // La grilla se limpio y trae solo lo de la empresa nueva.
        expect(find.text('DE LA UNO'), findsNothing);
        expect(find.text('DE LA CINCO'), findsOneWidget);
        // El combo de sucursal muestra la inicial de la empresa nueva.
        expect(find.text('SANTA CRUZ'), findsWidgets);
        expect(find.text('LA PAZ'), findsNothing);
      },
    );

    testWidgets('con btnChqSucrs, las sucursales ofrecidas son las de la empresa', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon([PermisosCheque.btnSucursales])),
      );
      await elegirEmpresa(tester, 'ESPPAPEL');

      await tester.tap(comboSucursal());
      await esperar(tester);
      expect(find.text('COCHABAMBA'), findsOneWidget);
      expect(find.text('EL ALTO'), findsNothing);
    });

    testWidgets('en movil la empresa esta siempre a la vista, sobre la sucursal', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 390);

      // Con el panel de filtros plegado.
      expect(find.byKey(const ValueKey('filtro-nro')), findsNothing);
      expect(comboEmpresa(), findsOneWidget);
      expect(
        tester.getTopLeft(comboEmpresa()).dy,
        lessThan(tester.getTopLeft(comboSucursal()).dy),
      );
      await elegirEmpresa(tester, 'ESPPAPEL');
      expect(repo.empresasDeSucursalInicial, [1, 5]);
    });

    testWidgets('si falla la lista de empresas lo dice y Reintentar la vuelve a pedir', (
      tester,
    ) async {
      repo.errorEmpresas = Exception('Sin conexión con el servidor');
      await montar(tester, pantalla(), ancho: 1400);

      expect(find.byKey(const ValueKey('error-empresas')), findsOneWidget);
      expect(
        find.textContaining('No se pudo cargar la lista de empresas'),
        findsOneWidget,
      );
      expect(repo.contar('obtenerSucursalInicial'), 0);

      repo.errorEmpresas = null;
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('error-empresas')),
          matching: find.text('Reintentar'),
        ),
      );
      await esperar(tester);

      // Una vez resuelta, la pantalla abre sola: no hace falta un segundo toque.
      expect(find.byKey(const ValueKey('error-empresas')), findsNothing);
      expect(find.byKey(const ValueKey('lista-tabla')), findsOneWidget);
      expect(repo.empresasDeSucursalInicial, [1]);
      expect(find.text('IMPEXPAP'), findsWidgets);
    });

    for (final escala in [1.0, 1.5]) {
      for (final ancho in [390.0, 800.0, 1400.0]) {
        testWidgets(
          'los filtros con empresa no desbordan a ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %',
          (tester) async {
            repo
              ..cheques = filasDePrueba()
              ..empresas = const [
                EmpresaChequeEntity(
                  codEmpresa: 1,
                  nombre: 'IMPORTADORA Y EXPORTADORA DE PAPEL Y AFINES S.A.',
                ),
                EmpresaChequeEntity(codEmpresa: 5, nombre: 'ESPPAPEL'),
              ]
              ..sucursalesPorEmpresa = {
                1: const [
                  SucursalChequeEntity(
                    codSucursal: 3,
                    nombre: 'SUCURSAL CENTRAL DE LA CIUDAD DE LA PAZ - ZONA SUR',
                  ),
                ],
              };
            if (escala != 1.0) conTexto(tester, escala);

            final errores = await capturandoErrores(() async {
              await montar(
                tester,
                pantalla(permisos: permisosCon([PermisosCheque.btnSucursales])),
                ancho: ancho,
              );
              // En movil, tambien con el panel de filtros desplegado.
              if (ancho < 450) {
                await tester.tap(find.byTooltip('Mostrar filtros'));
                await esperar(tester);
              }
            });

            expect(errores, isEmpty, reason: 'a $ancho');
            expect(comboEmpresa(), findsOneWidget);
            expect(comboSucursal(), findsOneWidget);
            // Los dos combos caben en el ancho de la pantalla.
            expect(
              tester.getRect(comboEmpresa()).right,
              lessThanOrEqualTo(ancho),
            );
            expect(
              tester.getRect(comboSucursal()).right,
              lessThanOrEqualTo(ancho),
            );
          },
        );
      }
    }
  });

  // ── Filtros ───────────────────────────────────────────────────────────────

  group('filtros', () {
    testWidgets('Buscar manda los criterios y Limpiar los quita', (tester) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 1400);

      await tester.enterText(find.byKey(const ValueKey('filtro-nro')), ' 100005 ');
      await tester.enterText(
        find.byKey(const ValueKey('filtro-cliente')),
        'editora',
      );
      await tester.tap(find.text('Buscar'));
      await esperar(tester);

      var f = repo.filtros.last;
      expect(f.nroCheque, '100005');
      expect(f.cliente, 'editora');
      expect(f.pagina, 1);

      await tester.tap(find.text('Limpiar'));
      await esperar(tester);
      f = repo.filtros.last;
      // Limpiar no deja «todo»: repone los ultimos tres meses (reloj fijo).
      expect(f.tieneCriteriosSalvoRecepcion, isFalse);
      expect(f.fechaRecepcionDesde, DateTime(2026, 7, 3));
      expect(f.fechaRecepcionHasta, DateTime(2026, 10, 3));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('filtro-nro')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('el estado y el tipo salen del catalogo, con «Todos» por defecto', (
      tester,
    ) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.byKey(const ValueKey('filtro-estado-null-2')));
      await esperar(tester);
      expect(find.text('Todos'), findsWidgets);
      await tester.tap(find.text('CERRADO').last);
      await esperar(tester);
      await tester.tap(find.text('Buscar'));
      await esperar(tester);

      expect(repo.filtros.last.estado, 'CER');
    });

    testWidgets('el orden se aplica al elegirlo', (tester) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.text('Cobro'));
      await esperar(tester);
      expect(repo.filtros.last.orden.codigo, 'COBRO');
    });

    testWidgets('en movil los filtros estan plegados y avisan cuantos hay', (
      tester,
    ) async {
      repo.cheques = filasDePrueba();
      await montar(tester, pantalla(), ancho: 390);

      expect(find.byKey(const ValueKey('filtro-nro')), findsNothing);
      await tester.tap(find.byTooltip('Mostrar filtros'));
      await esperar(tester);
      expect(find.byKey(const ValueKey('filtro-nro')), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('filtro-nro')), '100002');
      await tester.ensureVisible(find.text('Buscar'));
      await tester.tap(find.text('Buscar'));
      await esperar(tester);
      expect(repo.filtros.last.nroCheque, '100002');
      // El badge dice que hay un criterio aplicado.
      expect(find.text('1'), findsWidgets);
    });
  });

  // ── Paginacion del servidor ───────────────────────────────────────────────

  group('paginacion', () {
    testWidgets('pagina X de Y, N cheques; siguiente y anterior piden al servidor', (
      tester,
    ) async {
      // A 1800 px la tabla muestra la columna «#»; mas angosta se oculta.
      await montar(tester, pantalla(), ancho: 1800);
      expect(find.text('Página 1 de 3 · 45 cheques'), findsOneWidget);
      expect(repo.filtros.last.tamanio, 20);

      await tester.ensureVisible(find.byTooltip('Página siguiente'));
      await tester.tap(find.byTooltip('Página siguiente'));
      await esperar(tester);
      expect(find.text('Página 2 de 3 · 45 cheques'), findsOneWidget);
      expect(repo.filtros.last.pagina, 2);
      // La numeracion sigue la pagina: la primera fila de la 2 es la 21.
      expect(find.text('21'), findsOneWidget);

      // Al cambiar de pagina la vista vuelve arriba: el paginador queda abajo.
      await tester.ensureVisible(find.byTooltip('Página anterior'));
      await tester.tap(find.byTooltip('Página anterior'));
      await esperar(tester);
      expect(find.text('Página 1 de 3 · 45 cheques'), findsOneWidget);
    });

    testWidgets('en la primera pagina no hay anterior; en la ultima, no hay siguiente', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 390);
      final anterior = find.widgetWithIcon(IconButton, Icons.chevron_left);
      expect(tester.widget<IconButton>(anterior).onPressed, isNull);

      final siguiente = find.widgetWithIcon(IconButton, Icons.chevron_right);
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(siguiente);
        await tester.tap(siguiente);
        await esperar(tester);
      }
      expect(find.text('Página 3 de 3 · 45 cheques'), findsOneWidget);
      expect(tester.widget<IconButton>(siguiente).onPressed, isNull);
    });
  });

  // ── Estados que no son datos ─────────────────────────────────────────────

  testWidgets('sin cheques: estado vacio, no un error', (tester) async {
    repo.cheques = [];
    await montar(tester, pantalla(), ancho: 1400);
    // Abre con los ultimos tres meses: lo que falta son cheques en esas fechas.
    expect(
      find.text('No hay cheques recibidos en esas fechas'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsNothing);

    // Sin fechas, la sucursal no tiene ninguno.
    await tester.tap(find.text('Ver todos los cheques'));
    await esperar(tester);
    expect(find.text('Todavía no hay cheques en esta sucursal'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('una busqueda sin resultados ofrece quitar los filtros', (
    tester,
  ) async {
    repo.cheques = filasDePrueba();
    await montar(tester, pantalla(), ancho: 1400);
    await tester.enterText(find.byKey(const ValueKey('filtro-nro')), '999999999');
    await tester.tap(find.text('Buscar'));
    await esperar(tester);
    expect(find.text('Ningún cheque coincide con la búsqueda'), findsOneWidget);

    await tester.tap(find.text('Quitar filtros'));
    await esperar(tester);
    expect(find.byKey(const ValueKey('lista-tabla')), findsOneWidget);
  });

  testWidgets('el error del backend se muestra tal cual, con Reintentar', (
    tester,
  ) async {
    repo.errorListar = Exception('No tiene permisos sobre la sucursal.\nCall 2');
    await montar(tester, pantalla(), ancho: 1400);

    expect(find.text('No se pudieron cargar los cheques'), findsOneWidget);
    expect(find.text('No tiene permisos sobre la sucursal.'), findsOneWidget);
    expect(find.text('Call 2'), findsOneWidget);
    expect(find.textContaining('Todavía no hay cheques'), findsNothing);

    repo.errorListar = null;
    await tester.tap(find.text('Reintentar'));
    await esperar(tester);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.byKey(const ValueKey('lista-tabla')), findsOneWidget);
  });

  testWidgets('si falla la sucursal inicial, Reintentar la pide de nuevo', (
    tester,
  ) async {
    repo.errorSucursalInicial = Exception('Sin conexión');
    await montar(tester, pantalla(), ancho: 1400);
    expect(find.text('Sin conexión'), findsOneWidget);

    repo.errorSucursalInicial = null;
    await tester.tap(find.text('Reintentar'));
    await esperar(tester);
    expect(repo.contar('obtenerSucursalInicial'), 2);
    expect(find.byKey(const ValueKey('lista-tabla')), findsOneWidget);
  });

  testWidgets('mientras llega la primera pagina hay un esqueleto', (tester) async {
    final espera = Future<void>.delayed(const Duration(seconds: 3));
    repo.alListar = (f) async {
      await espera;
      return ChequePaginaEntity(
        total: 1,
        pagina: 1,
        tamanio: 20,
        filas: [chequeFalso(1, descTipo: 'PAGO')],
      );
    };
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pantalla());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('esqueleto-grilla')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.byKey(const ValueKey('esqueleto-grilla')), findsNothing);
  });

  // ── Detalle e «Ir atras» ─────────────────────────────────────────────────

  testWidgets('«Ir atras» vuelve a la misma pagina y con los mismos filtros', (
    tester,
  ) async {
    await montar(tester, pantalla(), ancho: 1400);
    await tester.enterText(find.byKey(const ValueKey('filtro-cliente')), 'editora');
    await tester.tap(find.text('Buscar'));
    await esperar(tester);
    await tester.ensureVisible(find.byTooltip('Página siguiente'));
    await tester.tap(find.byTooltip('Página siguiente'));
    await esperar(tester);
    final consultas = repo.contar('listar');

    await tester.tap(find.byTooltip('Completar').first);
    await esperar(tester);
    expect(find.text('Ir atrás'), findsOneWidget);
    expect(find.byKey(const ValueKey('lista-tabla')), findsNothing);

    await tester.tap(find.text('Ir atrás'));
    await esperar(tester);
    expect(find.text('Página 2 de 3 · 45 cheques'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('filtro-cliente')))
          .controller!
          .text,
      'editora',
    );
    // No se volvio a consultar al volver: la grilla sigue como estaba.
    expect(repo.contar('listar'), consultas);
  });

  testWidgets('el atras del sistema vuelve al listado y no sale del modulo', (
    tester,
  ) async {
    repo.cheques = [chequeFalso(1, descTipo: 'PAGO')];
    await montar(tester, pantalla(permisos: permisosCajero), ancho: 1400);
    await tester.tap(find.byTooltip('Completar'));
    await esperar(tester);
    expect(find.text('Ir atrás'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await esperar(tester);
    expect(find.text('Ir atrás'), findsNothing);
    expect(find.byKey(const ValueKey('lista-tabla')), findsOneWidget);
  });

  testWidgets('la grilla se libera al salir de la pantalla', (tester) async {
    repo.cheques = [chequeFalso(1, descTipo: 'PAGO')];
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await montar(
      tester,
      appCheques(
        repo: repo,
        hijo: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, v, __) => v ? const ChequesScreen() : const SizedBox(),
        ),
      ),
      ancho: 1400,
    );
    final contenedor = ProviderScope.containerOf(
      tester.element(find.byType(ChequesScreen)),
    );
    expect(contenedor.exists(grillaChequesProvider), isTrue);

    visible.value = false;
    await esperar(tester);
    expect(contenedor.exists(grillaChequesProvider), isFalse);
  });
}
