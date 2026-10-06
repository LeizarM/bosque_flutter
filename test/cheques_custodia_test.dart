import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_resumen_entity.dart';
import 'package:bosque_flutter/domain/entities/entrega_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// Las tres acciones del grupo «Custodia» de la barra de Cheques y sus dialogos:
/// «Traspaso», «A Custodio» y «Dar Custodia». Con un repositorio falso: que cada
/// una aparezca solo con su permiso (en un menu «Custodia», o como boton directo
/// si es la unica), que cada dialogo habilite y apague lo que toca, que el error
/// del backend se vea completo y que una escritura buena relea la grilla.
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

  List<ChequeFilaEntity> chequesDeHoy() => [
    chequeFalso(1, cliente: 'EDITORA MENDEZ'),
    chequeFalso(2, cliente: 'LIBRERIA PAIS'),
    chequeFalso(3, cliente: 'PAPELERA DEL SUR'),
  ];

  ChequeResumenEntity resumen(
    int cod,
    String cliente, {
    String monto = '1,500.50',
  }) => ChequeResumenEntity(
    codCheque: BigInt.from(cod),
    datoCheque:
        'Nro Cheque : ${100000 + cod}, Cliente : $cliente, Monto (BS) : $monto',
  );

  EntregaChequeEntity entrega(int cod, String hora) =>
      EntregaChequeEntity(codAccion: BigInt.from(cod), hora: hora);

  setUp(() {
    repo =
        RepositorioChequesFalso()
          ..cheques = [chequeFalso(1, descTipo: 'PAGO')]
          ..responsables = const [juan, ana]
          ..chequesCustodia = chequesDeHoy()
          ..chequesDarCustodia = [
            resumen(1, 'EDITORA MENDEZ'),
            resumen(2, 'LIBRERIA PAIS'),
            resumen(3, 'PAPELERA DEL SUR'),
          ]
          ..entregas = [
            entrega(88, '09:15 · Entregado a JUAN PEREZ'),
            entrega(89, '16:40 · Entregado a ANA ROJAS'),
          ];
  });

  Widget pantalla({PermisosCheque permisos = permisosAdmin}) =>
      appCheques(hijo: const ChequesScreen(), repo: repo, permisos: permisos);

  // ── Ayudas ────────────────────────────────────────────────────────────────

  /// El menu del telefono: con los reportes incluidos (el administrador) se
  /// llama «Traspaso, custodia y reportes»; sin ellos, «Traspaso y custodia». Se
  /// busca por su icono, que es el mismo en los dos casos.
  final menuTelefono = find.widgetWithIcon(IconButton, Icons.swap_horiz);

  /// Abre el dialogo desde la barra: una opcion del menu «Custodia» (o su boton
  /// directo, con un solo permiso) en escritorio y del menu «Traspaso y
  /// custodia» en el telefono.
  Future<void> abrirDialogo(
    WidgetTester tester,
    String etiqueta, {
    double ancho = 1400,
    PermisosCheque permisos = permisosAdmin,
  }) async {
    await montar(tester, pantalla(permisos: permisos), ancho: ancho);
    if (ancho < 600) {
      await tester.tap(menuTelefono);
      await esperar(tester);
    }
    await tocarCustodia(tester, etiqueta);
  }

  /// El `FilledButton` con esa etiqueta, tambien el de `FilledButton.icon`
  /// (que es un subtipo: `widgetWithText` no lo encuentra).
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

  Future<void> elegirResponsable(WidgetTester tester, String nombre) async {
    await tocar(tester, enDialogo(find.byType(DropdownButtonFormField<int>)));
    await tester.tap(find.text(nombre).last);
    await esperar(tester);
  }

  String contador(WidgetTester tester) =>
      tester
          .widget<Text>(find.byKey(const ValueKey('contador-marcados')))
          .data!;

  // ── Los botones de la barra, segun los permisos ───────────────────────────

  group('botones de la barra', () {
    const todas = ['Traspaso', 'A Custodio', 'Dar Custodia'];
    final menuCustodia = find.text('Custodia');

    final casos = <String, ({PermisosCheque permisos, Set<String> visibles})>{
      'administrador': (permisos: permisosAdmin, visibles: todas.toSet()),
      'btnTraspasoCH y btnCustodiaCH': (
        permisos: permisosCon([
          PermisosCheque.btnTraspaso,
          PermisosCheque.btnCustodia,
        ]),
        visibles: {'Traspaso', 'A Custodio'},
      ),
      'btnCustodiaCH y btnCustodia2CH': (
        permisos: permisosCon([
          PermisosCheque.btnCustodia,
          PermisosCheque.btnDarCustodia,
        ]),
        visibles: {'A Custodio', 'Dar Custodia'},
      ),
      'solo btnTraspasoCH': (
        permisos: permisosCon([PermisosCheque.btnTraspaso]),
        visibles: {'Traspaso'},
      ),
      'solo btnCustodiaCH': (
        permisos: permisosCon([PermisosCheque.btnCustodia]),
        visibles: {'A Custodio'},
      ),
      'solo btnCustodia2CH': (
        permisos: permisosCon([PermisosCheque.btnDarCustodia]),
        visibles: {'Dar Custodia'},
      ),
      'cajero (sin ninguno de los tres)': (
        permisos: permisosCajero,
        visibles: <String>{},
      ),
      'sin ningun boton': (permisos: permisosNinguno, visibles: <String>{}),
    };

    casos.forEach((nombre, caso) {
      testWidgets('escritorio, $nombre', (tester) async {
        await montar(tester, pantalla(permisos: caso.permisos), ancho: 1400);
        // Sin el menu del telefono.
        expect(menuTelefono, findsNothing);

        if (caso.visibles.isEmpty) {
          // Sin ninguno de los tres no aparece nada.
          expect(menuCustodia, findsNothing);
          for (final e in todas) {
            expect(find.text(e), findsNothing, reason: '$nombre / $e');
          }
        } else if (caso.visibles.length == 1) {
          // Un solo permiso: no hay menu de un elemento, sino el boton directo.
          expect(menuCustodia, findsNothing);
          final e = caso.visibles.single;
          expect(find.text(e), findsOneWidget, reason: '$nombre / $e');
          expect(
            find.ancestor(
              of: find.text(e),
              matching: find.bySubtype<OutlinedButton>(),
            ),
            findsOneWidget,
          );
        } else {
          // Dos o tres: un menu «Custodia» con solo las entradas permitidas.
          expect(menuCustodia, findsOneWidget);
          for (final e in todas) {
            expect(find.text(e), findsNothing, reason: 'suelto $e');
          }
          await tester.tap(menuCustodia);
          await esperar(tester);
          for (final e in todas) {
            expect(
              find.text(e),
              caso.visibles.contains(e) ? findsOneWidget : findsNothing,
              reason: '$nombre / $e en el menu',
            );
          }
        }
      });

      testWidgets('movil, $nombre: agrupados en un menu', (tester) async {
        await montar(tester, pantalla(permisos: caso.permisos), ancho: 390);
        // Nunca sueltos en la barra, ni con un boton «Custodia» propio.
        expect(menuCustodia, findsNothing);
        for (final e in todas) {
          expect(find.text(e), findsNothing, reason: 'suelto $e');
        }
        if (caso.visibles.isEmpty) {
          expect(menuTelefono, findsNothing);
          return;
        }
        await tester.tap(menuTelefono);
        await esperar(tester);
        for (final e in todas) {
          expect(
            find.text(e),
            caso.visibles.contains(e) ? findsOneWidget : findsNothing,
            reason: '$nombre / $e en el menu',
          );
        }
      });
    });

    testWidgets('el menu Custodia ofrece las entradas en el orden del legacy', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(menuCustodia);
      await esperar(tester);
      final y = [
        for (final e in todas) tester.getTopLeft(find.text(e)).dy,
      ];
      expect(y[0], lessThan(y[1]));
      expect(y[1], lessThan(y[2]));
    });

    testWidgets('sin sucursal el menu Custodia se apaga', (tester) async {
      repo.sucursalInicial = 0;
      await montar(tester, pantalla(), ancho: 1400);
      final b = tester.widget<OutlinedButton>(
        find.ancestor(
          of: menuCustodia,
          matching: find.bySubtype<OutlinedButton>(),
        ),
      );
      expect(b.onPressed, isNull);
    });

    for (final e in todas) {
      testWidgets('sin sucursal el boton directo de $e se apaga', (
        tester,
      ) async {
        repo.sucursalInicial = 0;
        final permiso = switch (e) {
          'Traspaso' => PermisosCheque.btnTraspaso,
          'A Custodio' => PermisosCheque.btnCustodia,
          _ => PermisosCheque.btnDarCustodia,
        };
        await montar(
          tester,
          pantalla(permisos: permisosCon([permiso])),
          ancho: 1400,
        );
        final b = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.text(e),
            matching: find.bySubtype<OutlinedButton>(),
          ),
        );
        expect(b.onPressed, isNull, reason: e);
      });
    }

    /// Cada opcion abierta del menu y si se puede elegir.
    Map<String, bool> opcionesDelMenu(WidgetTester tester) => {
      for (final m in tester.widgetList<MenuItemButton>(
        find.byType(MenuItemButton),
      ))
        if (m.child is Text) (m.child as Text).data!: m.onPressed != null,
    };

    testWidgets(
      'sin sucursal y SIN btnNuevoCH el menu del telefono se apaga (todo lo que trae necesita sucursal)',
      (tester) async {
        repo.sucursalInicial = 0;
        await montar(
          tester,
          pantalla(
            permisos: permisosCon([
              PermisosCheque.btnTraspaso,
              PermisosCheque.btnCustodia,
              PermisosCheque.btnDarCustodia,
            ]),
          ),
          ancho: 390,
        );
        final menu = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(menu.onPressed, isNull);
      },
    );

    testWidgets(
      'sin sucursal y CON btnNuevoCH el menu del telefono abre y solo «Actualizar datos SAP» esta activa (diferencia #5)',
      (tester) async {
        repo.sucursalInicial = 0;
        await montar(tester, pantalla(), ancho: 390);
        final menu = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.swap_horiz),
        );
        expect(menu.onPressed, isNotNull);

        await tester.tap(menuTelefono);
        await esperar(tester);
        final opciones = opcionesDelMenu(tester);
        // Traspaso, custodias y los cinco reportes del administrador aparecen, apagados.
        expect(opciones.keys, containsAll(['Traspaso', 'A Custodio', 'Dar Custodia']));
        expect(opciones.length, greaterThan(4));
        for (final o in opciones.entries) {
          expect(
            o.value,
            o.key == 'Actualizar datos SAP',
            reason: '«${o.key}» sin sucursal',
          );
        }
        expect(opciones['Actualizar datos SAP'], isTrue);
      },
    );

    testWidgets(
      'sin sucursal, elegir una opcion apagada del telefono no abre ningun dialogo ni llama al servidor',
      (tester) async {
        repo.sucursalInicial = 0;
        await montar(tester, pantalla(), ancho: 390);
        await tester.tap(menuTelefono);
        await esperar(tester);

        await tester.tap(find.text('Traspaso'), warnIfMissed: false);
        await esperar(tester);

        expect(find.byType(Dialog), findsNothing);
        expect(repo.contar('contarTraspasosPendientes'), 0);
      },
    );

    testWidgets('con sucursal todas las opciones del menu del telefono estan activas', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 390);
      await tester.tap(menuTelefono);
      await esperar(tester);

      final opciones = opcionesDelMenu(tester);
      expect(opciones, isNotEmpty);
      expect(opciones.values.every((v) => v), isTrue, reason: '$opciones');
    });
  });

  // ── Traspaso ──────────────────────────────────────────────────────────────

  group('traspaso', () {
    testWidgets('sin pendientes: lo dice y Generar queda deshabilitado', (
      tester,
    ) async {
      repo.pendientes = 0;
      await abrirDialogo(tester, 'Traspaso');

      expect(find.text('Traspaso de cheques'), findsOneWidget);
      expect(find.text('Sucursal LA PAZ'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('traspaso-pendientes')))
            .data,
        '0',
      );
      expect(find.text('No hay nada que traspasar por ahora.'), findsOneWidget);
      expect(habilitado(tester, 'Generar'), isFalse);
      expect(repo.contar('traspasar'), 0);
    });

    testWidgets('con pendientes: cuantos son y Generar habilitado', (
      tester,
    ) async {
      repo.pendientes = 4;
      await abrirDialogo(tester, 'Traspaso');

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('traspaso-pendientes')))
            .data,
        '4',
      );
      expect(
        find.text('cheques esperan el traspaso a cobranza'),
        findsOneWidget,
      );
      expect(habilitado(tester, 'Generar'), isTrue);
      // El conteo se pidio una vez, para la sucursal de la grilla.
      expect(repo.contar('contarTraspasosPendientes'), 1);
    });

    testWidgets('uno solo se dice en singular', (tester) async {
      repo.pendientes = 1;
      await abrirDialogo(tester, 'Traspaso');
      expect(find.text('cheque espera el traspaso a cobranza'), findsOneWidget);
    });

    testWidgets('Generar traspasa, cuenta lo que hizo y relee la grilla', (
      tester,
    ) async {
      repo.pendientes = 4;
      repo.traspasados = 4;
      await abrirDialogo(tester, 'Traspaso');
      final consultas = repo.contar('listar');

      await tocar(tester, boton('Generar'));

      expect(repo.contar('traspasar'), 1);
      expect(repo.ultimoCuerpo('traspasar'), {'id': 3});
      expect(find.text('Se traspasaron 4 cheques.'), findsOneWidget);
      // Ya no se ofrece generar de nuevo: solo cerrar.
      expect(boton('Generar'), findsNothing);
      expect(repo.contar('listar'), consultas + 1);

      await tester.tap(boton('Listo'));
      await esperar(tester);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('el error del backend se ve completo y no da nada por hecho', (
      tester,
    ) async {
      repo.errorEscritura = Exception(
        'No tiene permisos para modificar datos de otras sucursales\n'
        'No hay cheques para traspasar.',
      );
      await abrirDialogo(tester, 'Traspaso');
      final consultas = repo.contar('listar');

      await tocar(tester, boton('Generar'));

      expect(
        find.text('No tiene permisos para modificar datos de otras sucursales'),
        findsOneWidget,
      );
      expect(find.text('No hay cheques para traspasar.'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Se traspasaron'), findsNothing);
      // Sigue abierto, con el boton disponible, y la grilla no se releyo.
      expect(boton('Generar'), findsOneWidget);
      expect(repo.contar('listar'), consultas);

      // Corregido el problema, reintentar cierra el error y traspasa.
      repo.errorEscritura = null;
      await tocar(tester, boton('Generar'));
      expect(find.text('No hay cheques para traspasar.'), findsNothing);
      expect(find.text('Se traspasaron 4 cheques.'), findsOneWidget);
    });

    testWidgets('si falla la consulta de pendientes: el motivo y Reintentar', (
      tester,
    ) async {
      repo.erroresDeLectura['contarTraspasosPendientes'] = Exception(
        'Sin conexión',
      );
      await abrirDialogo(tester, 'Traspaso');

      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(habilitado(tester, 'Generar'), isFalse);

      repo.erroresDeLectura.clear();
      await tocar(tester, find.text('Reintentar'));
      expect(find.text('Reintentar'), findsNothing);
      expect(habilitado(tester, 'Generar'), isTrue);
    });

    testWidgets('respeta la sucursal elegida en la grilla', (tester) async {
      await montar(tester, pantalla(), ancho: 1400);
      // Con btnChqSucrs (aqui, administrador) el combo deja cambiar de sucursal.
      await tester.tap(comboSucursal());
      await esperar(tester);
      await tester.tap(find.text('EL ALTO').last);
      await esperar(tester);

      await tocarCustodia(tester, 'Traspaso');
      expect(find.text('Sucursal EL ALTO'), findsOneWidget);

      await tocar(tester, boton('Generar'));
      expect(repo.ultimoCuerpo('traspasar'), {'id': 4});
    });

    testWidgets('con otra empresa elegida trabaja en la sucursal de esa empresa', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(comboEmpresa());
      await esperar(tester);
      await tester.tap(find.text('ESPPAPEL').last);
      await esperar(tester);

      await tocarCustodia(tester, 'Traspaso');
      // El nombre sale de las sucursales de la empresa 5, no de las de la 1.
      expect(find.text('Sucursal SANTA CRUZ'), findsOneWidget);

      await tocar(tester, boton('Generar'));
      expect(repo.ultimoCuerpo('traspasar'), {'id': 7});
    });

    testWidgets('el error de una escritura anterior no aparece al abrir', (
      tester,
    ) async {
      repo.errorEscritura = Exception('Error viejo de otra pantalla');
      await abrirDialogo(tester, 'Traspaso');
      await tocar(tester, boton('Generar'));
      expect(find.text('Error viejo de otra pantalla'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      await tocarCustodia(tester, 'Traspaso');
      expect(find.text('Error viejo de otra pantalla'), findsNothing);
    });
  });

  // ── A Custodio ────────────────────────────────────────────────────────────

  group('a custodio', () {
    testWidgets('abre con Guardar deshabilitado y nada marcado', (
      tester,
    ) async {
      await abrirDialogo(tester, 'A Custodio');

      expect(find.text('Responsable'), findsOneWidget);
      expect(find.text('Cheque 100001 · EDITORA MENDEZ'), findsOneWidget);
      expect(find.text('Cheque 100003 · PAPELERA DEL SUR'), findsOneWidget);
      expect(contador(tester), '0 de 3 marcados');
      expect(habilitado(tester, 'Guardar'), isFalse);
    });

    testWidgets('Guardar pide las dos cosas: responsable y algun cheque', (
      tester,
    ) async {
      await abrirDialogo(tester, 'A Custodio');

      // Solo el responsable.
      await elegirResponsable(tester, 'JUAN PEREZ');
      expect(habilitado(tester, 'Guardar'), isFalse);

      // Responsable y un cheque.
      await tocar(tester, find.byKey(const ValueKey('custodia-2')));
      expect(contador(tester), '1 de 3 marcados');
      expect(habilitado(tester, 'Guardar'), isTrue);

      // Se desmarca el unico: otra vez apagado.
      await tocar(tester, find.byKey(const ValueKey('custodia-2')));
      expect(contador(tester), '0 de 3 marcados');
      expect(habilitado(tester, 'Guardar'), isFalse);
    });

    testWidgets('solo con cheques marcados, sin responsable, sigue apagado', (
      tester,
    ) async {
      await abrirDialogo(tester, 'A Custodio');
      await tocar(tester, find.byKey(const ValueKey('custodia-1')));
      expect(contador(tester), '1 de 3 marcados');
      expect(habilitado(tester, 'Guardar'), isFalse);
    });

    testWidgets('marcar todos marca y desmarca todos, y cuenta', (
      tester,
    ) async {
      await abrirDialogo(tester, 'A Custodio');

      await tocar(tester, find.byKey(const ValueKey('marcar-todos')));
      expect(contador(tester), '3 de 3 marcados');
      for (final c in [1, 2, 3]) {
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(ValueKey('custodia-$c')))
              .value,
          isTrue,
        );
      }

      // Con uno desmarcado ya no estan todos.
      await tocar(tester, find.byKey(const ValueKey('custodia-1')));
      expect(contador(tester), '2 de 3 marcados');

      // Pulsarlo con algunos marcados los marca todos; con todos, ninguno.
      await tocar(tester, find.byKey(const ValueKey('marcar-todos')));
      expect(contador(tester), '3 de 3 marcados');
      await tocar(tester, find.byKey(const ValueKey('marcar-todos')));
      expect(contador(tester), '0 de 3 marcados');
    });

    testWidgets(
      'Guardar entrega los marcados al responsable y relee la grilla',
      (tester) async {
        await abrirDialogo(tester, 'A Custodio');
        final consultas = repo.contar('listar');

        await elegirResponsable(tester, 'ANA ROJAS');
        await tocar(tester, find.byKey(const ValueKey('marcar-todos')));
        await tocar(tester, boton('Guardar'));

        expect(repo.contar('entregarEnCustodia'), 1);
        expect(repo.ultimoCuerpo('entregarEnCustodia'), {
          'codSucursal': 3,
          'codEmpleado': 13,
          'codCheques': [1, 2, 3],
        });
        expect(
          find.text('Se entregaron 3 cheques en custodia.'),
          findsOneWidget,
        );
        expect(find.byType(Dialog), findsNothing);
        expect(repo.contar('listar'), consultas + 1);
      },
    );

    testWidgets('con un solo cheque el aviso va en singular', (tester) async {
      await abrirDialogo(tester, 'A Custodio');
      await elegirResponsable(tester, 'JUAN PEREZ');
      await tocar(tester, find.byKey(const ValueKey('custodia-3')));
      await tocar(tester, boton('Guardar'));

      expect(repo.ultimoCuerpo('entregarEnCustodia')['codCheques'], [3]);
      expect(find.text('Se entregó 1 cheque en custodia.'), findsOneWidget);
    });

    testWidgets(
      'si el servidor rechaza, todo el mensaje se ve y nada queda dado',
      (tester) async {
        repo.errorEscritura = Exception(
          'El cheque 100002 no esta entre los listos para custodia\n'
          'No se entrego ningun cheque',
        );
        await abrirDialogo(tester, 'A Custodio');
        final consultas = repo.contar('listar');

        await elegirResponsable(tester, 'JUAN PEREZ');
        await tocar(tester, find.byKey(const ValueKey('marcar-todos')));
        await tocar(tester, boton('Guardar'));

        expect(
          find.text('El cheque 100002 no esta entre los listos para custodia'),
          findsOneWidget,
        );
        expect(find.text('No se entrego ningun cheque'), findsOneWidget);
        expect(find.textContaining('Exception'), findsNothing);
        // Nada de «se entregaron»; el dialogo sigue abierto con lo marcado y la
        // grilla no se releyo.
        expect(find.textContaining('Se entreg'), findsNothing);
        expect(contador(tester), '3 de 3 marcados');
        expect(boton('Guardar'), findsOneWidget);
        expect(repo.contar('listar'), consultas);

        // Corregido, se puede guardar de nuevo con lo que ya estaba marcado.
        repo.errorEscritura = null;
        await tocar(tester, boton('Guardar'));
        expect(
          find.text('Se entregaron 3 cheques en custodia.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('sin cheques de hoy lo dice y no se puede guardar', (
      tester,
    ) async {
      repo.chequesCustodia = const [];
      await abrirDialogo(tester, 'A Custodio');

      expect(
        find.text('No hay cheques de hoy listos para entregar en custodia.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('marcar-todos')), findsNothing);
      await elegirResponsable(tester, 'JUAN PEREZ');
      expect(habilitado(tester, 'Guardar'), isFalse);
    });

    testWidgets('sin responsables activos lo avisa', (tester) async {
      repo.responsables = const [];
      await abrirDialogo(tester, 'A Custodio');
      expect(
        find.textContaining('No hay responsables de custodia activos'),
        findsOneWidget,
      );
      expect(habilitado(tester, 'Guardar'), isFalse);
    });

    testWidgets('si falla la lista de cheques: el motivo y Reintentar', (
      tester,
    ) async {
      repo.erroresDeLectura['listarChequesParaCustodia'] = Exception(
        'No tiene permiso para esta accion.',
      );
      await abrirDialogo(tester, 'A Custodio');
      expect(
        find.textContaining('No tiene permiso para esta accion.'),
        findsOneWidget,
      );

      repo.erroresDeLectura.clear();
      await tocar(tester, find.text('Reintentar'));
      expect(find.byKey(const ValueKey('custodia-1')), findsOneWidget);
    });

    testWidgets('si falla la lista de responsables: el motivo y Reintentar', (
      tester,
    ) async {
      repo.erroresDeLectura['listarResponsablesDeCustodia'] = Exception(
        'Sin conexión',
      );
      await abrirDialogo(tester, 'A Custodio');
      expect(find.textContaining('Sin conexión'), findsOneWidget);

      repo.erroresDeLectura.clear();
      await tocar(tester, find.text('Reintentar'));
      await elegirResponsable(tester, 'JUAN PEREZ');
      await tocar(tester, find.byKey(const ValueKey('custodia-1')));
      expect(habilitado(tester, 'Guardar'), isTrue);
    });
  });

  // ── Dar Custodia ──────────────────────────────────────────────────────────

  group('dar custodia', () {
    final hoy = hoyDeLaPrueba();

    /// Elige el dia [dia] del mes que muestra el calendario (el actual) y lo
    /// acepta. La fecha mas tardia permitida es hoy, asi que se usa el 1.
    Future<void> elegirDia1(WidgetTester tester) async {
      // Dentro del dialogo: los filtros de la grilla, detras, tambien tienen
      // campos de fecha.
      await tester.tap(
        find
            .descendant(
              of: find.descendant(
                of: find.byType(Dialog),
                matching: find.byType(CampoFechaCheque),
              ),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await esperar(tester);
      if (hoy.day == 1) {
        await tester.tap(find.byTooltip('Mes anterior'));
        await esperar(tester);
      }
      await tester.tap(find.text('1').last);
      await esperar(tester);
      await tester.tap(find.text('ACEPTAR'));
      await esperar(tester);
    }

    testWidgets('paso 1: la fecha es hoy y las entregas traen su hora', (
      tester,
    ) async {
      await abrirDialogo(tester, 'Dar Custodia');

      expect(find.textContaining('Paso 1 de 2'), findsOneWidget);
      expect(repo.fechasDeEntregas.single, hoy);
      expect(find.text('09:15 · Entregado a JUAN PEREZ'), findsOneWidget);
      expect(find.text('16:40 · Entregado a ANA ROJAS'), findsOneWidget);
      // Sin elegir una entrega no se avanza.
      expect(habilitado(tester, 'Siguiente'), isFalse);
      // Asignar todavia no existe: es del paso 2.
      expect(boton('Asignar'), findsNothing);
    });

    testWidgets('sin entregas en esa fecha: lo dice y no se avanza', (
      tester,
    ) async {
      repo.entregas = const [];
      await abrirDialogo(tester, 'Dar Custodia');

      expect(find.text('No hay entregas en esa fecha'), findsOneWidget);
      expect(habilitado(tester, 'Siguiente'), isFalse);
    });

    testWidgets('elegir otra fecha pide esas entregas y descarta la eleccion', (
      tester,
    ) async {
      await abrirDialogo(tester, 'Dar Custodia');
      await tocar(tester, find.byKey(const ValueKey('entrega-88')));
      expect(habilitado(tester, 'Siguiente'), isTrue);

      repo.entregas = [entrega(90, '08:00 · Entregado a ANA ROJAS')];
      await elegirDia1(tester);

      expect(
        repo.fechasDeEntregas.last,
        hoy.day == 1
            ? DateTime(hoy.year, hoy.month - 1, 1)
            : DateTime(hoy.year, hoy.month, 1),
      );
      expect(find.text('08:00 · Entregado a ANA ROJAS'), findsOneWidget);
      expect(find.text('09:15 · Entregado a JUAN PEREZ'), findsNothing);
      // Otro dia, otras entregas: la elegida antes ya no vale.
      expect(habilitado(tester, 'Siguiente'), isFalse);
    });

    testWidgets('asistente completo: entrega, cheque y Asignar', (
      tester,
    ) async {
      await abrirDialogo(tester, 'Dar Custodia');
      final consultas = repo.contar('listar');

      await tocar(tester, find.byKey(const ValueKey('entrega-88')));
      await tocar(tester, find.text('Siguiente'));

      expect(find.textContaining('Paso 2 de 2'), findsOneWidget);
      expect(
        find.textContaining('09:15 · Entregado a JUAN PEREZ'),
        findsWidgets,
      );
      // Con la entrega y sin cheque, Asignar no se puede.
      expect(habilitado(tester, 'Asignar'), isFalse);

      await tocar(tester, find.byKey(const ValueKey('cheque-2')));
      expect(habilitado(tester, 'Asignar'), isTrue);
      await tocar(tester, boton('Asignar'));

      expect(repo.contar('darCustodia'), 1);
      expect(repo.ultimoCuerpo('darCustodia'), {
        'codSucursal': 3,
        'codAccionOrigen': 88,
        'codCheque': 2,
      });
      expect(find.text('Se asignó la custodia al cheque.'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(repo.contar('listar'), consultas + 1);
    });

    testWidgets('Atras vuelve al paso 1 sin perder la entrega elegida', (
      tester,
    ) async {
      await abrirDialogo(tester, 'Dar Custodia');
      await tocar(tester, find.byKey(const ValueKey('entrega-89')));
      await tocar(tester, find.text('Siguiente'));
      await tocar(tester, find.text('Atrás'));

      expect(find.textContaining('Paso 1 de 2'), findsOneWidget);
      expect(habilitado(tester, 'Siguiente'), isTrue);
    });

    testWidgets('la busqueda filtra en memoria por palabras', (tester) async {
      await abrirDialogo(tester, 'Dar Custodia');
      await tocar(tester, find.byKey(const ValueKey('entrega-88')));
      await tocar(tester, find.text('Siguiente'));
      expect(find.byKey(const ValueKey('cheque-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('cheque-3')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('buscar-cheque')),
        'mendez 100001',
      );
      await esperar(tester);
      expect(find.byKey(const ValueKey('cheque-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('cheque-2')), findsNothing);
      expect(find.byKey(const ValueKey('cheque-3')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('buscar-cheque')),
        'zzz sin coincidencia',
      );
      await esperar(tester);
      expect(
        find.text('Ningún cheque coincide con la búsqueda.'),
        findsOneWidget,
      );
    });

    testWidgets('no pinta mas de 40 cheques aunque haya miles', (tester) async {
      repo.chequesDarCustodia = [
        for (var i = 1; i <= 3000; i++) resumen(i, 'CLIENTE NUMERO $i'),
      ];
      await abrirDialogo(tester, 'Dar Custodia');
      await tocar(tester, find.byKey(const ValueKey('entrega-88')));
      await tocar(tester, find.text('Siguiente'));

      final pintados = enDialogo(find.byType(ListTile)).evaluate().length;
      expect(pintados, lessThanOrEqualTo(40));
      expect(
        find.text('Hay 3000 coincidencias: escribe más para acotar.'),
        findsOneWidget,
      );

      // Acotando, aparece el que se busca aunque estuviera mas alla del 40.
      await tester.enterText(
        find.byKey(const ValueKey('buscar-cheque')),
        'numero 2999',
      );
      await esperar(tester);
      expect(find.byKey(const ValueKey('cheque-2999')), findsOneWidget);
      expect(find.byKey(const ValueKey('mas-coincidencias')), findsNothing);
    });

    testWidgets(
      'si el servidor rechaza, todo el mensaje se ve y no se da por asignado',
      (tester) async {
        repo.errorEscritura = Exception(
          'La accion de origen debe ser una custodia\n'
          'El cheque no es de esa sucursal',
        );
        await abrirDialogo(tester, 'Dar Custodia');
        await tocar(tester, find.byKey(const ValueKey('entrega-88')));
        await tocar(tester, find.text('Siguiente'));
        await tocar(tester, find.byKey(const ValueKey('cheque-3')));
        await tocar(tester, boton('Asignar'));

        expect(
          find.text('La accion de origen debe ser una custodia'),
          findsOneWidget,
        );
        expect(find.text('El cheque no es de esa sucursal'), findsOneWidget);
        expect(find.textContaining('Se asignó'), findsNothing);
        expect(boton('Asignar'), findsOneWidget);

        // Volver al paso 1 limpia el error de ese intento.
        await tocar(tester, find.text('Atrás'));
        expect(find.text('El cheque no es de esa sucursal'), findsNothing);
      },
    );

    testWidgets('si fallan las entregas: el motivo y Reintentar', (
      tester,
    ) async {
      repo.erroresDeLectura['listarEntregasDelDia'] = Exception('Sin conexión');
      await abrirDialogo(tester, 'Dar Custodia');
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(habilitado(tester, 'Siguiente'), isFalse);

      repo.erroresDeLectura.clear();
      await tocar(tester, find.text('Reintentar'));
      expect(find.byKey(const ValueKey('entrega-88')), findsOneWidget);
    });

    testWidgets('si falla la lista de cheques: el motivo y Reintentar', (
      tester,
    ) async {
      repo.erroresDeLectura['listarChequesParaDarCustodia'] = Exception(
        'Sin conexión',
      );
      await abrirDialogo(tester, 'Dar Custodia');
      await tocar(tester, find.byKey(const ValueKey('entrega-88')));
      await tocar(tester, find.text('Siguiente'));
      expect(find.textContaining('Sin conexión'), findsOneWidget);

      repo.erroresDeLectura.clear();
      await tocar(tester, find.text('Reintentar'));
      expect(find.byKey(const ValueKey('cheque-1')), findsOneWidget);
    });

    testWidgets('una sucursal sin cheques lo dice', (tester) async {
      repo.chequesDarCustodia = const [];
      await abrirDialogo(tester, 'Dar Custodia');
      await tocar(tester, find.byKey(const ValueKey('entrega-88')));
      await tocar(tester, find.text('Siguiente'));
      expect(find.text('No hay cheques en esta sucursal.'), findsOneWidget);
      expect(habilitado(tester, 'Asignar'), isFalse);
    });
  });

  // ── Sin desbordes: movil, tablet y escritorio, tambien con texto grande ───

  const clienteLargo =
      'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE - CHIQUITOS Y MAS';

  for (final escala in [1.0, 1.5]) {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      final sufijo =
          'a ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %';

      Future<void> preparar(WidgetTester tester) async {
        if (escala != 1.0) conTexto(tester, escala);
        repo
          ..pendientes = 1234
          ..chequesCustodia = [
            chequeFalso(
              1,
              cliente: clienteLargo,
              banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
              monto: 12345678.9,
            ),
            chequeFalso(2),
            chequeFalso(3),
          ]
          ..chequesDarCustodia = [
            resumen(1, clienteLargo, monto: '12,345,678.90'),
            resumen(2, 'LIBRERIA PAIS'),
          ]
          ..entregas = [
            entrega(
              88,
              '09:15 · Entregado a UN RESPONSABLE CON UN NOMBRE MUY LARGO DE LA SUCURSAL',
            ),
          ];
      }

      testWidgets('traspaso sin desborde $sufijo', (tester) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrirDialogo(tester, 'Traspaso', ancho: ancho);
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.text('Generar'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
      });

      testWidgets('traspaso con error largo sin desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        repo.errorEscritura = Exception(
          'No tiene permisos para modificar datos de otras sucursales\n'
          'No hay cheques para traspasar en la sucursal elegida, revise la fecha',
        );
        final errores = await capturandoErrores(() async {
          await abrirDialogo(tester, 'Traspaso', ancho: ancho);
          await tocar(tester, boton('Generar'));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(
          find.text(
            'No tiene permisos para modificar datos de otras sucursales',
          ),
          findsOneWidget,
        );
      });

      testWidgets('a custodio sin desborde $sufijo', (tester) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrirDialogo(tester, 'A Custodio', ancho: ancho);
          await elegirResponsable(tester, 'JUAN PEREZ');
          await tocar(tester, find.byKey(const ValueKey('marcar-todos')));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(contador(tester), '3 de 3 marcados');
        expect(habilitado(tester, 'Guardar'), isTrue);
      });

      testWidgets('a custodio con error largo sin desborde $sufijo', (
        tester,
      ) async {
        await preparar(tester);
        repo.errorEscritura = Exception(
          'El cheque 100001 de $clienteLargo no esta entre los listos para custodia\n'
          'No se entrego ningun cheque',
        );
        final errores = await capturandoErrores(() async {
          await abrirDialogo(tester, 'A Custodio', ancho: ancho);
          await elegirResponsable(tester, 'JUAN PEREZ');
          await tocar(tester, find.byKey(const ValueKey('marcar-todos')));
          await tocar(tester, boton('Guardar'));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.text('No se entrego ningun cheque'), findsOneWidget);
      });

      testWidgets('dar custodia, paso 1 sin desborde $sufijo', (tester) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrirDialogo(tester, 'Dar Custodia', ancho: ancho);
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(find.text('Siguiente'), findsOneWidget);
      });

      testWidgets('dar custodia, paso 2 sin desborde $sufijo', (tester) async {
        await preparar(tester);
        final errores = await capturandoErrores(() async {
          await abrirDialogo(tester, 'Dar Custodia', ancho: ancho);
          await tocar(tester, find.byKey(const ValueKey('entrega-88')));
          await tocar(tester, find.text('Siguiente'));
          await tocar(tester, find.byKey(const ValueKey('cheque-1')));
        });
        expect(errores, isEmpty, reason: sufijo);
        expect(habilitado(tester, 'Asignar'), isTrue);
      });
    }
  }

  testWidgets(
    'en movil los dialogos ocupan toda la pantalla y el pie baja al borde',
    (tester) async {
      // Con pocos datos el contenido no llena la pantalla: los botones igual
      // quedan abajo, donde el pulgar los alcanza.
      repo.chequesCustodia = [chequeFalso(1)];
      await abrirDialogo(tester, 'A Custodio', ancho: 390);
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.getSize(find.byType(Dialog)).width, 390);
      expect(tester.getSize(find.byType(Dialog)).height, 844);
      expect(tester.getBottomLeft(boton('Guardar')).dy, greaterThan(780));
    },
  );
}
