import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/formulario_cheque.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// El formulario de cheque en sus tres modos: que campos deja editar cada uno
/// (los demas se ven, bloqueados), las reglas que repite del servidor, el tipo
/// corrupto de la base y el error del backend con todas sus lineas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  late ValueNotifier<BigInt?> resultado;

  setUp(() {
    repo = RepositorioChequesFalso()
      ..clientes = [
        clienteDeCheque('C1', 'EDITORA MENDEZ'),
        clienteDeCheque('C2', 'LIBRERIA PAIS'),
        clienteDeCheque('C3', 'PAPELERA DEL SUR'),
      ]
      ..personal = const [
        PersonalChequeEntity(codEmpleado: 12, nombreCompleto: 'JUAN PEREZ'),
        PersonalChequeEntity(codEmpleado: 13, nombreCompleto: 'ANA ROJAS'),
      ];
    resultado = ValueNotifier(null);
  });
  tearDown(() => resultado.dispose());

  /// Una pantalla con un boton que abre el formulario con lo que cada prueba
  /// pide: asi se prueba el formulario sin pasar por la grilla.
  Widget abridor(
    ModoRegistroCheque modo, {
    ChequeFilaEntity? existente,
    List<String>? botones,
  }) => appCheques(
    repo: repo,
    hijo: Builder(
      builder:
          (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                resultado.value = await abrirFormularioCheque(
                  context,
                  modo: modo,
                  codSucursal: 3,
                  existente: existente,
                );
              },
              child: const Text('abrir'),
            ),
          ),
    ),
  );

  Future<void> abrir(
    WidgetTester tester,
    ModoRegistroCheque modo, {
    ChequeFilaEntity? existente,
    double ancho = 1400,
  }) async {
    await montar(tester, abridor(modo, existente: existente), ancho: ancho);
    await tester.tap(find.text('abrir'));
    await esperar(tester);
  }

  // ── Ayudas para llenar el formulario ─────────────────────────────────────

  Finder editable(String id) => find.byKey(ValueKey('editable-$id'));
  Finder bloqueado(String id) => find.byKey(ValueKey('bloqueado-$id'));
  Finder entrada(String id) =>
      find.descendant(of: editable(id), matching: find.byType(TextFormField));

  Future<void> escribir(WidgetTester tester, String id, String valor) async {
    await tester.ensureVisible(entrada(id));
    await tester.enterText(entrada(id), valor);
    await esperar(tester);
  }

  Future<void> elegirDeLista(
    WidgetTester tester,
    String id,
    String etiqueta,
  ) async {
    await tester.ensureVisible(editable(id));
    await tester.tap(editable(id));
    await esperar(tester);
    await tester.tap(find.text(etiqueta).last);
    await esperar(tester);
  }

  /// Abre el calendario del campo y acepta la fecha con la que abre (hoy, o la
  /// ya elegida).
  Future<void> elegirFecha(WidgetTester tester, String id) async {
    await tester.ensureVisible(editable(id));
    await tester.tap(
      find.descendant(of: editable(id), matching: find.byType(InkWell)).first,
    );
    await esperar(tester);
    await tester.tap(find.text('ACEPTAR'));
    await esperar(tester);
  }

  Future<void> elegirCliente(WidgetTester tester, String buscar, String nombre) async {
    await tester.ensureVisible(find.byKey(const ValueKey('campo-cliente')));
    await tester.enterText(find.byKey(const ValueKey('campo-cliente')), buscar);
    await esperar(tester);
    await tester.tap(find.text(nombre).last);
    await esperar(tester);
  }

  /// Llena un alta estandar valida. Entregado por, tipo y moneda quedan como
  /// abren (Cliente, Pago, Bs).
  Future<void> llenarAlta(
    WidgetTester tester, {
    String recibo = '0',
    String talonario = '0',
    String? entregadoPor,
    String buscarCliente = 'edi',
    String nombreCliente = 'EDITORA MENDEZ',
  }) async {
    await elegirCliente(tester, buscarCliente, nombreCliente);
    await elegirDeLista(tester, 'banco', 'BANCO UNION');
    await escribir(tester, 'nroCheque', '000123456');
    await escribir(tester, 'monto', '1500.5');
    await escribir(tester, 'aOrdenDe', 'BOSQUE SA');
    await elegirFecha(tester, 'fechaCheque');
    if (entregadoPor != null) {
      await elegirDeLista(tester, 'entregadoPor', entregadoPor);
    }
    await escribir(tester, 'recibo', recibo);
    await escribir(tester, 'talonario', talonario);
  }

  /// Pulsa el boton de guardar (el titulo del panel puede decir lo mismo).
  Future<void> guardar(WidgetTester tester, String etiqueta) async {
    final boton = find.widgetWithText(FilledButton, etiqueta);
    await tester.ensureVisible(boton);
    await tester.tap(boton);
    await esperar(tester);
  }

  /// Un cheque con fechas dentro de +-28 dias y datos buenos.
  ChequeFilaEntity cheque({
    String estado = 'PEN',
    String tipo = 'PAG',
    String? descTipo = 'PAGO',
    String? fechaCobrar,
    int codEmpleado = 0,
    int codEmpresa = 1,
    int codSucursal = 3,
  }) => chequeFalso(
    5,
    estado: estado,
    tipo: tipo,
    descTipo: descTipo,
    codEmpresa: codEmpresa,
    codSucursal: codSucursal,
    fechaCheque: '2026-08-10',
    fechaCobrar: fechaCobrar ?? '2026-08-20',
    // Sin puntos: el validador del legacy solo admite letras (ver ReglasCheque).
    aOrdenDe: 'BOSQUE SA',
    codEmpleado: codEmpleado,
    datoEmpleado: codEmpleado == 0 ? ' - Entregado por el Cliente -' : ' - JUAN PEREZ -',
  );

  // ── Que campos deja editar cada modo ─────────────────────────────────────

  const todos = [
    'empresa',
    'sucursal',
    'entregadoPor',
    'tipo',
    'cliente',
    'banco',
    'nroCheque',
    'monto',
    'moneda',
    'aOrdenDe',
    'fechaCheque',
    'fechaCobrar',
    'talonario',
    'recibo',
    'observacion',
  ];

  const casos = <String, ({ModoRegistroCheque modo, bool alta, Set<String> editables})>{
    'alta estandar': (
      modo: ModoRegistroCheque.estandar,
      alta: true,
      editables: {
        'entregadoPor',
        'tipo',
        'cliente',
        'banco',
        'nroCheque',
        'monto',
        'moneda',
        'aOrdenDe',
        'fechaCheque',
        'talonario',
        'recibo',
        'observacion',
      },
    ),
    'edicion estandar': (
      modo: ModoRegistroCheque.estandar,
      alta: false,
      editables: {
        'cliente',
        'banco',
        'nroCheque',
        'talonario',
        'recibo',
        'observacion',
      },
    ),
    'talonario': (
      modo: ModoRegistroCheque.talonario,
      alta: false,
      editables: {'talonario', 'recibo'},
    ),
    'alta administrador': (
      modo: ModoRegistroCheque.admin,
      alta: true,
      editables: {
        'entregadoPor',
        'tipo',
        'cliente',
        'banco',
        'nroCheque',
        'monto',
        'moneda',
        'aOrdenDe',
        'fechaCheque',
        'fechaCobrar',
        'talonario',
        'recibo',
        'observacion',
      },
    ),
    'edicion administrador': (
      modo: ModoRegistroCheque.admin,
      alta: false,
      editables: {
        'entregadoPor',
        'tipo',
        'cliente',
        'banco',
        'nroCheque',
        'monto',
        'moneda',
        'aOrdenDe',
        'fechaCheque',
        'fechaCobrar',
        'talonario',
        'recibo',
        'observacion',
      },
    ),
  };

  group('campos editables y bloqueados por modo', () {
    casos.forEach((nombre, caso) {
      test('la tabla de campoEditableCheque: $nombre', () {
        for (final campo in todos) {
          expect(
            campoEditableCheque(campo, caso.modo, esAlta: caso.alta),
            caso.editables.contains(campo),
            reason: '$nombre / $campo',
          );
        }
      });

      testWidgets('$nombre: cada campo esta, editable o bloqueado, nunca escondido', (
        tester,
      ) async {
        await abrir(
          tester,
          caso.modo,
          existente: caso.alta ? null : cheque(codEmpleado: 12),
        );

        for (final campo in todos) {
          final debeEditar = caso.editables.contains(campo);
          expect(
            editable(campo),
            debeEditar ? findsOneWidget : findsNothing,
            reason: '$nombre / $campo editable',
          );
          expect(
            bloqueado(campo),
            debeEditar ? findsNothing : findsOneWidget,
            reason: '$nombre / $campo bloqueado',
          );
        }
      });
    });

    testWidgets('en talonario el cheque se ve completo, solo de lectura', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.talonario,
        existente: cheque(codEmpleado: 12),
      );

      String enBloqueado(String id, String texto) =>
          find
              .descendant(of: bloqueado(id), matching: find.text(texto))
              .evaluate()
              .isEmpty
          ? 'FALTA $id: $texto'
          : 'ok';

      expect(enBloqueado('cliente', 'EDITORA MENDEZ'), 'ok');
      expect(enBloqueado('nroCheque', '100005'), 'ok');
      expect(enBloqueado('banco', 'BANCO UNION'), 'ok');
      expect(enBloqueado('monto', '1500.50'), 'ok');
      expect(enBloqueado('moneda', 'Bs'), 'ok');
      expect(enBloqueado('aOrdenDe', 'BOSQUE SA'), 'ok');
      expect(enBloqueado('fechaCheque', '10/08/2026'), 'ok');
      expect(enBloqueado('fechaCobrar', '20/08/2026'), 'ok');
      expect(enBloqueado('entregadoPor', 'JUAN PEREZ'), 'ok');
      expect(enBloqueado('empresa', 'IMPEXPAP'), 'ok');
      expect(enBloqueado('sucursal', 'LA PAZ'), 'ok');
    });
  });

  // ── Reglas de recibo y talonario ─────────────────────────────────────────

  group('recibo y talonario', () {
    testWidgets('lo dejo el cliente: el recibo manual tiene que ser 0', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester, recibo: '5', talonario: '7');
      await guardar(tester, 'Registrar cheque');

      expect(
        find.text('Si el cheque lo dejó el cliente, el recibo manual debe ser 0.'),
        findsOneWidget,
      );
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('lo trajo un empleado: el recibo manual no puede ser 0', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester, recibo: '0', talonario: '0', entregadoPor: 'JUAN PEREZ');
      await guardar(tester, 'Registrar cheque');

      expect(
        find.text('Si lo trajo un empleado, el recibo manual debe ser distinto de 0.'),
        findsOneWidget,
      );
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('un recibo exige un talonario distinto de 0', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester, recibo: '5', talonario: '0', entregadoPor: 'JUAN PEREZ');
      await guardar(tester, 'Registrar cheque');

      expect(
        find.text('Si hay un recibo manual, el talonario manual debe ser distinto de 0.'),
        findsOneWidget,
      );
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('al corregir, los errores se actualizan sin volver a guardar', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester, recibo: '5', talonario: '7');
      await guardar(tester, 'Registrar cheque');
      expect(
        find.text('Si el cheque lo dejó el cliente, el recibo manual debe ser 0.'),
        findsOneWidget,
      );

      await escribir(tester, 'recibo', '0');
      expect(
        find.text('Si el cheque lo dejó el cliente, el recibo manual debe ser 0.'),
        findsNothing,
      );
    });

    testWidgets('formato: el recibo solo letras, numeros y espacios', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester, recibo: '5/9', talonario: '7');
      await guardar(tester, 'Registrar cheque');
      expect(
        find.text('Letras, números y espacios (de 1 a 25 caracteres).'),
        findsOneWidget,
      );
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('en talonario las mismas reglas valen con quien lo trajo', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.talonario,
        existente: cheque(estado: 'CER', codEmpleado: 12),
      );
      await escribir(tester, 'recibo', '0');
      await guardar(tester, 'Guardar cambios');
      expect(
        find.text('Si lo trajo un empleado, el recibo manual debe ser distinto de 0.'),
        findsOneWidget,
      );
      expect(repo.contar('registrar'), 0);
    });
  });

  // ── Alta estandar completa ───────────────────────────────────────────────

  group('alta estandar', () {
    testWidgets('manda solo lo que el servidor acepta y cierra con el codCheque', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(
        tester,
        recibo: '5',
        talonario: '7',
        entregadoPor: 'JUAN PEREZ',
      );
      await guardar(tester, 'Registrar cheque');

      expect(repo.contar('registrar'), 1);
      final b = repo.ultimoCuerpo('registrar');
      final hoy = isoDia(hoyDeLaPrueba());
      expect(b['codCheque'], 0);
      expect(b['modo'], 'ESTANDAR');
      expect(b['codCliente'], 'C1');
      expect(b['codBanco'], 7);
      // Tipo y moneda vienen del catalogo, no escritos a mano.
      expect(b['tipo'], 'PAG');
      expect(b['moneda'], 'BS');
      expect(b['monto'], 1500.5);
      expect(b['aOrdenDe'], 'BOSQUE SA');
      expect(b['codEmpleado'], 12);
      expect(b['reciboManual'], '5');
      expect(b['nroTalonario'], '7');
      expect(b['fechaCheque'], hoy);
      // En el alta estandar la fecha de cobro es la del cheque.
      expect(b['fechaCobrar'], hoy);
      // Donde queda: la sucursal de la grilla y la empresa del usuario.
      expect(b['codSucursal'], 3);
      expect(b['codEmpresa'], 1);
      // Lo que no se manda nunca.
      for (final k in ['estado', 'nroRecibo', 'audUsuario', 'audFecha']) {
        expect(b.containsKey(k), isFalse, reason: k);
      }
      // El nro de cheque viaja como lo escribio el usuario: los ceros a la
      // izquierda los quita el servidor.
      expect(b['nrocheque'], '000123456');
      // El formulario se cerro devolviendo el id.
      expect(resultado.value, BigInt.from(9001));
      expect(find.text('Registrar cheque'), findsNothing);
    });

    testWidgets('la fecha de cobro bloqueada se llena sola con la del cheque', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      expect(
        find.descendant(of: bloqueado('fechaCobrar'), matching: find.text('—')),
        findsOneWidget,
      );
      await elegirFecha(tester, 'fechaCheque');
      final hoy = textoFechaDePrueba(hoyDeLaPrueba());
      expect(
        find.descendant(of: bloqueado('fechaCobrar'), matching: find.text(hoy)),
        findsOneWidget,
      );
      expect(find.text('Es la fecha del cheque.'), findsOneWidget);
    });

    testWidgets('faltan campos: avisa y marca cada uno, sin llamar al servidor', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await guardar(tester, 'Registrar cheque');

      expect(find.text('Elige un cliente de la lista.'), findsOneWidget);
      expect(find.text('Elige el banco.'), findsOneWidget);
      expect(find.text('Ingresa el nro. de cheque.'), findsOneWidget);
      expect(find.text('Ingresa el monto del cheque.'), findsOneWidget);
      expect(find.text('Indica la fecha.'), findsOneWidget);
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('el nro de cheque solo acepta numeros y guion; no solo ceros', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester);
      await escribir(tester, 'nroCheque', '12A34');
      await guardar(tester, 'Registrar cheque');
      expect(find.text('Solo se permiten números y guion medio.'), findsOneWidget);

      await escribir(tester, 'nroCheque', '0000');
      expect(
        find.text('El nro. de cheque no puede ser solo ceros.'),
        findsOneWidget,
      );
      await escribir(tester, 'nroCheque', '123-45');
      expect(find.text('Solo se permiten números y guion medio.'), findsNothing);
    });

    testWidgets('«A la orden de» solo acepta letras', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester);
      await escribir(tester, 'aOrdenDe', 'BOSQUE 2000');
      await guardar(tester, 'Registrar cheque');
      expect(
        find.text('Solo se permiten letras, acentos y espacios.'),
        findsOneWidget,
      );
    });
  });

  // ── El cliente se busca ──────────────────────────────────────────────────

  group('combo de cliente', () {
    testWidgets('filtra en memoria por nombre o codigo', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'mend');
      await esperar(tester);
      expect(find.text('EDITORA MENDEZ'), findsOneWidget);
      expect(find.text('LIBRERIA PAIS'), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'C3');
      await esperar(tester);
      expect(find.text('PAPELERA DEL SUR'), findsOneWidget);
      expect(find.text('EDITORA MENDEZ'), findsNothing);
    });

    testWidgets('no pinta mas de 40 opciones aunque haya miles', (tester) async {
      repo.clientes = [
        for (var i = 0; i < 3000; i++)
          clienteDeCheque('K$i', 'CLIENTE NUMERO $i'),
      ];
      await abrir(tester, ModoRegistroCheque.estandar);
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'cliente');
      await esperar(tester);

      expect(
        find.byType(ListTile).evaluate().length,
        lessThanOrEqualTo(40),
      );
      expect(find.textContaining('Hay 3000 coincidencias'), findsOneWidget);
    });

    testWidgets('escribir despues de elegir invalida la eleccion', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester);
      await tester.enterText(
        find.byKey(const ValueKey('campo-cliente')),
        'EDITORA MENDEZ X',
      );
      await guardar(tester, 'Registrar cheque');
      expect(find.text('Elige un cliente de la lista.'), findsOneWidget);
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('en una edicion el cliente guardado ya viene elegido', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.estandar,
        existente: cheque(),
      );
      await escribir(tester, 'nroCheque', '777');
      await guardar(tester, 'Guardar cambios');

      final b = repo.ultimoCuerpo('registrar');
      expect(b['codCliente'], 'C5');
      expect(b['nrocheque'], '777');
    });
  });

  // ── La empresa del cheque no sale del login ──────────────────────────────

  // El login de estas pruebas es el del bug: empresa 6 (GENERAL) y sin nombre.
  group('empresa del cheque', () {
    testWidgets(
      'el login es de la empresa 6 sin nombre: el alta muestra IMPEXPAP y pide sus clientes',
      (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar);

        expect(
          find.descendant(of: bloqueado('empresa'), matching: find.text('IMPEXPAP')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: bloqueado('empresa'), matching: find.text('—')),
          findsNothing,
        );
        // Ni la del login (6) ni «0 = la del token».
        expect(repo.empresasDeClientes, [1]);
        expect(repo.empresasDeSucursales, [1]);
        expect(
          find.descendant(of: bloqueado('sucursal'), matching: find.text('LA PAZ')),
          findsOneWidget,
        );
      },
    );

    testWidgets('el alta manda codEmpresa de la empresa activa, no el del login', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await llenarAlta(tester);
      await guardar(tester, 'Registrar cheque');

      final b = repo.ultimoCuerpo('registrar');
      expect(b['codEmpresa'], 1);
      expect(b['codSucursal'], 3);
    });

    testWidgets(
      'con la empresa ESPPAPEL elegida en la pantalla: clientes, sucursal y codEmpresa de la 5',
      (tester) async {
        repo.clientesPorEmpresa = {
          1: [clienteDeCheque('U1', 'CLIENTE DE LA UNO')],
          5: [clienteDeCheque('E1', 'CLIENTE DE LA CINCO')],
        };
        await montar(
          tester,
          appCheques(
            hijo: const ChequesScreen(),
            repo: repo,
            permisos: permisosAdmin,
          ),
          ancho: 1400,
        );
        await tester.tap(comboEmpresa());
        await esperar(tester);
        await tester.tap(find.text('ESPPAPEL').last);
        await esperar(tester);

        await tester.tap(find.text('Registrar'));
        await esperar(tester);

        expect(
          find.descendant(of: bloqueado('empresa'), matching: find.text('ESPPAPEL')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: bloqueado('sucursal'),
            matching: find.text('SANTA CRUZ'),
          ),
          findsOneWidget,
        );
        // Solo se pidieron los clientes de la 5: el formulario no toco la 1.
        expect(repo.empresasDeClientes, [5]);

        await llenarAlta(
          tester,
          buscarCliente: 'cinco',
          nombreCliente: 'CLIENTE DE LA CINCO',
        );
        await guardar(tester, 'Registrar cheque');

        final b = repo.ultimoCuerpo('registrar');
        expect(b['codEmpresa'], 5);
        expect(b['codSucursal'], 7);
        expect(b['codCliente'], 'E1');
      },
    );

    testWidgets(
      'editar un cheque de la empresa 5 con la 1 activa pide los clientes de la 5',
      (tester) async {
        repo.clientesPorEmpresa = {
          1: [clienteDeCheque('U1', 'CLIENTE DE LA UNO')],
          5: [clienteDeCheque('C5', 'EDITORA MENDEZ')],
        };
        await abrir(
          tester,
          ModoRegistroCheque.estandar,
          existente: cheque(codEmpresa: 5, codSucursal: 7),
        );

        // La empresa del cheque, no la activa (la 1, que es con la que abre).
        expect(repo.empresasDeClientes, [5]);
        expect(repo.empresasDeSucursales, [5]);
        expect(
          find.descendant(of: bloqueado('empresa'), matching: find.text('ESPPAPEL')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: bloqueado('sucursal'),
            matching: find.text('SANTA CRUZ'),
          ),
          findsOneWidget,
        );

        await escribir(tester, 'nroCheque', '777');
        await guardar(tester, 'Guardar cambios');
        // Una edicion no manda donde esta el cheque.
        final b = repo.ultimoCuerpo('registrar');
        expect(b.containsKey('codEmpresa'), isFalse);
        expect(b['codCliente'], 'C5');
      },
    );

    testWidgets('mientras la empresa no se conoce, el alta avisa y no deja guardar', (
      tester,
    ) async {
      repo.errorEmpresas = Exception('Sin conexión con el servidor');
      await abrir(tester, ModoRegistroCheque.estandar);

      expect(
        find.textContaining('No se pudo cargar la empresa: Sin conexión'),
        findsOneWidget,
      );
      expect(find.text('Esperando la empresa…'), findsOneWidget);
      final guardarBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrar cheque'),
      );
      expect(guardarBtn.onPressed, isNull);
      expect(repo.empresasDeClientes, isEmpty);

      // Reintentar: la empresa llega, los clientes se piden y se puede guardar.
      repo.errorEmpresas = null;
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      expect(find.textContaining('No se pudo cargar la empresa'), findsNothing);
      expect(
        find.descendant(of: bloqueado('empresa'), matching: find.text('IMPEXPAP')),
        findsOneWidget,
      );
      expect(repo.empresasDeClientes, [1]);
      final listo = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registrar cheque'),
      );
      expect(listo.onPressed, isNotNull);
    });

    testWidgets('una lista de empresas vacia no deja registrar y lo explica', (
      tester,
    ) async {
      repo.empresas = const [];
      await abrir(tester, ModoRegistroCheque.estandar);
      expect(
        find.text('No hay empresas disponibles para registrar cheques.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Registrar cheque'))
            .onPressed,
        isNull,
      );
    });
  });

  // ── El combo de cliente dice por que no ofrece nada ──────────────────────

  group('combo de cliente: avisos', () {
    testWidgets('una empresa sin clientes lo dice con texto visible y no deja guardar', (
      tester,
    ) async {
      repo.clientes = [];
      await abrir(tester, ModoRegistroCheque.estandar);

      expect(find.text('No hay clientes para esta empresa.'), findsOneWidget);
      // No hay buscador: no hay a quien buscar.
      expect(find.byKey(const ValueKey('campo-cliente')), findsNothing);

      await guardar(tester, 'Registrar cheque');
      // Al guardar el mismo motivo queda como error del campo: nunca se pierde.
      expect(find.text('No hay clientes para esta empresa.'), findsOneWidget);
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('«Sin coincidencias» cuando lo escrito no esta en la lista', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      expect(find.textContaining('Sin coincidencias'), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'zzzz');
      await esperar(tester);
      expect(find.textContaining('Sin coincidencias'), findsOneWidget);
      // El desplegable no abre con una lista vacia: el aviso va en el campo.
      expect(find.byType(ListTile), findsNothing);

      // Al escribir algo que existe, el aviso se va y aparece la opcion.
      await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'mend');
      await esperar(tester);
      expect(find.textContaining('Sin coincidencias'), findsNothing);
      expect(find.text('EDITORA MENDEZ'), findsOneWidget);
    });

    testWidgets('el aviso no sale con el cliente ya elegido', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await elegirCliente(tester, 'edi', 'EDITORA MENDEZ');
      expect(find.textContaining('Sin coincidencias'), findsNothing);
      expect(find.text('Escribe parte del nombre o del código.'), findsOneWidget);
    });

    testWidgets(
      'en una edicion, el nombre guardado que ya no esta en la lista no es un aviso',
      (tester) async {
        // La lista de la empresa no trae al cliente del cheque.
        repo.clientes = [clienteDeCheque('C2', 'LIBRERIA PAIS')];
        await abrir(tester, ModoRegistroCheque.estandar, existente: cheque());
        expect(find.textContaining('Sin coincidencias'), findsNothing);

        // Pero si el usuario escribe algo que no existe, si.
        await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'zzzz');
        await esperar(tester);
        expect(find.textContaining('Sin coincidencias'), findsOneWidget);
      },
    );

    testWidgets('el aviso cabe a 390 px con texto al 150 %', (tester) async {
      conTexto(tester, 1.5);
      final errores = await capturandoErrores(() async {
        await abrir(tester, ModoRegistroCheque.estandar, ancho: 390);
        await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'zzzz');
        await esperar(tester);
      });
      expect(errores, isEmpty);
      expect(find.textContaining('Sin coincidencias'), findsOneWidget);
    });

    testWidgets('«No hay clientes» cabe a 390 px con texto al 150 %', (tester) async {
      repo.clientes = [];
      conTexto(tester, 1.5);
      final errores = await capturandoErrores(() async {
        await abrir(tester, ModoRegistroCheque.estandar, ancho: 390);
        await guardar(tester, 'Registrar cheque');
      });
      expect(errores, isEmpty);
      expect(find.text('No hay clientes para esta empresa.'), findsOneWidget);
    });
  });

  // ── Edicion estandar y talonario: solo viaja lo que el modo acepta ───────

  group('edicion', () {
    testWidgets(
      'estandar: cliente, banco, nro, talonario y recibo; la observacion solo si se toca',
      (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar, existente: cheque());
        await guardar(tester, 'Guardar cambios');

        final b = repo.ultimoCuerpo('registrar');
        expect(b['codCheque'], 5);
        expect(b['modo'], 'ESTANDAR');
        expect(b.keys.toSet(), {
          'codCheque',
          'modo',
          'nrocheque',
          'codCliente',
          'codBanco',
          'nroTalonario',
          'reciboManual',
        });
        expect(resultado.value, BigInt.from(5));
      },
    );

    group('observacion', () {
      testWidgets('sin tocarla no viaja la clave: el servidor conserva la anterior', (
        tester,
      ) async {
        await abrir(tester, ModoRegistroCheque.estandar, existente: cheque());
        // Aparece con su texto actual.
        expect(
          tester.widget<TextFormField>(entrada('observacion')).controller!.text,
          'Recibido en caja',
        );
        await escribir(tester, 'nroCheque', '777');
        await guardar(tester, 'Guardar cambios');
        expect(repo.ultimoCuerpo('registrar').containsKey('observacion'), isFalse);
      });

      testWidgets('vaciada manda cadena vacia: asi se borra', (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar, existente: cheque());
        await escribir(tester, 'observacion', '');
        await guardar(tester, 'Guardar cambios');

        final b = repo.ultimoCuerpo('registrar');
        expect(b.containsKey('observacion'), isTrue);
        expect(b['observacion'], '');
        expect(resultado.value, BigInt.from(5));
      });

      testWidgets('con solo espacios cuenta como vaciada', (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar, existente: cheque());
        await escribir(tester, 'observacion', '    ');
        await guardar(tester, 'Guardar cambios');
        expect(repo.ultimoCuerpo('registrar')['observacion'], '');
      });

      testWidgets('cambiada manda el texto nuevo', (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar, existente: cheque());
        await escribir(tester, 'observacion', ' Corregida ');
        await guardar(tester, 'Guardar cambios');
        expect(repo.ultimoCuerpo('registrar')['observacion'], 'Corregida');
      });

      testWidgets('un cheque que no tenia observacion y sigue sin ella no manda nada', (
        tester,
      ) async {
        await abrir(
          tester,
          ModoRegistroCheque.estandar,
          existente: chequeFalso(
            5,
            observacion: null,
            descTipo: 'PAGO',
            fechaCheque: '2026-08-10',
            fechaCobrar: '2026-08-20',
            aOrdenDe: 'BOSQUE SA',
          ),
        );
        await guardar(tester, 'Guardar cambios');
        expect(repo.ultimoCuerpo('registrar').containsKey('observacion'), isFalse);
      });

      testWidgets('el administrador tambien puede vaciarla', (tester) async {
        await abrir(tester, ModoRegistroCheque.admin, existente: cheque());
        await escribir(tester, 'observacion', '');
        await guardar(tester, 'Guardar cambios');
        expect(repo.ultimoCuerpo('registrar')['observacion'], '');
      });

      testWidgets('en el alta, vacia no viaja y con texto si', (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar);
        await llenarAlta(tester);
        await guardar(tester, 'Registrar cheque');
        expect(repo.ultimoCuerpo('registrar').containsKey('observacion'), isFalse);
      });

      testWidgets('en el alta, con texto viaja', (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar);
        await llenarAlta(tester);
        await escribir(tester, 'observacion', 'Recibido en caja');
        await guardar(tester, 'Registrar cheque');
        expect(repo.ultimoCuerpo('registrar')['observacion'], 'Recibido en caja');
      });
    });

    testWidgets('talonario: solo talonario y recibo', (tester) async {
      await abrir(
        tester,
        ModoRegistroCheque.talonario,
        existente: cheque(estado: 'CER', codEmpleado: 12),
      );
      await escribir(tester, 'recibo', '88');
      await escribir(tester, 'talonario', '9');
      await guardar(tester, 'Guardar cambios');

      final b = repo.ultimoCuerpo('registrar');
      expect(b, {
        'codCheque': 5,
        'modo': 'TALONARIO',
        'nroTalonario': '9',
        'reciboManual': '88',
      });
    });

    testWidgets('un tipo corrupto no vuelve a salir en una edicion estandar', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.estandar,
        existente: cheque(tipo: 'BASURA\u0001ÿ', descTipo: null),
      );
      await guardar(tester, 'Guardar cambios');

      final b = repo.ultimoCuerpo('registrar');
      expect(b.containsKey('tipo'), isFalse);
      expect(b.toString(), isNot(contains('BASURA')));
    });
  });

  // ── Modo administrador ───────────────────────────────────────────────────

  group('administrador', () {
    testWidgets('con descTipo null el tipo queda sin seleccion y obliga a elegir', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.admin,
        existente: cheque(tipo: 'BASURA\u0001ÿ', descTipo: null),
      );

      // Aviso de por que el combo esta vacio.
      expect(
        find.textContaining('El tipo guardado de este cheque no es válido'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: editable('tipo'), matching: find.text('PAGO')),
        findsNothing,
      );

      await guardar(tester, 'Guardar cambios');
      expect(find.text('Elige el tipo.'), findsOneWidget);
      expect(repo.contar('registrar'), 0);

      await elegirDeLista(tester, 'tipo', 'RESPALDO');
      await guardar(tester, 'Guardar cambios');

      expect(repo.contar('registrar'), 1);
      final b = repo.ultimoCuerpo('registrar');
      expect(b['modo'], 'ADMIN');
      // El tipo que viaja es de la lista, nunca el corrupto.
      expect(b['tipo'], 'RES');
      expect(b.toString(), isNot(contains('BASURA')));
      // Un cheque existente no manda donde esta: el servidor no lo mueve.
      expect(b.containsKey('codSucursal'), isFalse);
      expect(b.containsKey('codEmpresa'), isFalse);
    });

    testWidgets('un tipo valido viene elegido y no hay aviso', (tester) async {
      await abrir(tester, ModoRegistroCheque.admin, existente: cheque());
      expect(
        find.textContaining('El tipo guardado de este cheque no es válido'),
        findsNothing,
      );
      expect(
        find.descendant(of: editable('tipo'), matching: find.text('PAGO')),
        findsOneWidget,
      );
      await guardar(tester, 'Guardar cambios');
      expect(repo.ultimoCuerpo('registrar')['tipo'], 'PAG');
    });

    testWidgets('con descTipo null aunque el tipo parezca valido: no se confia', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.admin,
        existente: cheque(tipo: 'PAG', descTipo: null),
      );
      await guardar(tester, 'Guardar cambios');
      expect(find.text('Elige el tipo.'), findsOneWidget);
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('la fecha de cobro admite +-28 dias de la del cheque', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.admin,
        // 40 dias despues de la fecha del cheque (10/08/2026).
        existente: cheque(fechaCobrar: '2026-09-19'),
      );
      expect(
        find.textContaining('Hasta 28 días antes o después de la fecha del cheque'),
        findsOneWidget,
      );
      await guardar(tester, 'Guardar cambios');

      expect(
        find.textContaining('La fecha de cobro debe estar a 28 días o menos'),
        findsOneWidget,
      );
      expect(repo.contar('registrar'), 0);
    });

    testWidgets('dentro de los 28 dias se guarda y manda la fecha de cobro', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.admin,
        existente: cheque(fechaCobrar: '2026-09-07'),
      );
      await guardar(tester, 'Guardar cambios');
      final b = repo.ultimoCuerpo('registrar');
      expect(b['fechaCobrar'], '2026-09-07');
      expect(b['fechaCheque'], '2026-08-10');
    });

    testWidgets('el alta del administrador manda la fecha de cobro elegida', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.admin);
      await llenarAlta(tester);
      await elegirFecha(tester, 'fechaCobrar');
      await guardar(tester, 'Registrar cheque');
      final b = repo.ultimoCuerpo('registrar');
      expect(b['modo'], 'ADMIN');
      expect(b['fechaCobrar'], isoDia(hoyDeLaPrueba()));
    });
  });

  // ── Errores del backend ──────────────────────────────────────────────────

  group('error del backend', () {
    testWidgets('se muestra completo, linea por linea, y el formulario sigue abierto', (
      tester,
    ) async {
      repo.errorEscritura = Exception(
        'Ingrese el Nro de Cheque\nDebe elegir el Banco\nCheque Duplicado',
      );
      await abrir(
        tester,
        ModoRegistroCheque.talonario,
        existente: cheque(estado: 'CER', codEmpleado: 12),
      );
      await escribir(tester, 'recibo', '5');
      await escribir(tester, 'talonario', '7');
      await guardar(tester, 'Guardar cambios');

      expect(repo.contar('registrar'), 1);
      expect(find.text('Ingrese el Nro de Cheque'), findsOneWidget);
      expect(find.text('Debe elegir el Banco'), findsOneWidget);
      expect(find.text('Cheque Duplicado'), findsOneWidget);
      // Tal cual: sin «Exception:» ni reescrituras.
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.text('Editar talonario y recibo'), findsOneWidget);

      // Al corregirse el problema, guardar cierra y el error desaparece.
      repo.errorEscritura = null;
      await guardar(tester, 'Guardar cambios');
      expect(find.text('Cheque Duplicado'), findsNothing);
      expect(find.text('Editar talonario y recibo'), findsNothing);
      expect(resultado.value, BigInt.from(5));
    });

    testWidgets('una frase de negocio no se reescribe como fallo tecnico', (
      tester,
    ) async {
      repo.errorEscritura = Exception('Fechas Cobro Fuera de Rango');
      await abrir(tester, ModoRegistroCheque.estandar, existente: cheque());
      await guardar(tester, 'Guardar cambios');
      expect(find.text('Fechas Cobro Fuera de Rango'), findsOneWidget);
    });

    testWidgets('el error de una escritura anterior no aparece al abrir', (
      tester,
    ) async {
      repo.errorEscritura = Exception('Error viejo de otra pantalla');
      await montar(tester, abridor(ModoRegistroCheque.estandar), ancho: 1400);
      final contenedor = ProviderScope.containerOf(
        tester.element(find.text('abrir')),
      );
      await contenedor
          .read(operacionesChequesProvider.notifier)
          .registrar(ChequeRegistroEntity(codCheque: BigInt.one));
      expect(
        contenedor.read(operacionesChequesProvider).error,
        'Error viejo de otra pantalla',
      );

      await tester.tap(find.text('abrir'));
      await esperar(tester);
      expect(find.text('Error viejo de otra pantalla'), findsNothing);
      expect(contenedor.read(operacionesChequesProvider).error, isNull);
    });
  });

  // ── Cerrar ───────────────────────────────────────────────────────────────

  group('cerrar el formulario', () {
    testWidgets('sin cambios cierra de una vez', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      expect(find.text('Registrar cheque'), findsNothing);
      expect(resultado.value, isNull);
    });

    testWidgets('con cambios pregunta antes de descartar', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await escribir(tester, 'nroCheque', '123');
      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);

      // «Cancelar» del aviso: se sigue editando y no se pierde nada.
      await tester.tap(find.text('Cancelar').last);
      await esperar(tester);
      expect(find.text('¿Descartar los cambios?'), findsNothing);
      expect(find.text('Registrar cheque'), findsWidgets);

      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      await tester.tap(find.text('Descartar'));
      await esperar(tester);
      expect(find.text('Registrar cheque'), findsNothing);
      expect(resultado.value, isNull);
    });
  });

  // ── Sin desbordes ────────────────────────────────────────────────────────

  for (final escala in [1.0, 1.5]) {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      for (final caso in casos.entries) {
        testWidgets(
          '${caso.key}: sin desborde a ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %',
          (tester) async {
            if (escala != 1.0) conTexto(tester, escala);
            final errores = await capturandoErrores(() async {
              await abrir(
                tester,
                caso.value.modo,
                existente:
                    caso.value.alta
                        ? null
                        : cheque(
                          codEmpleado: 12,
                          tipo: 'BASURA',
                          descTipo: null,
                        ),
                ancho: ancho,
              );
            });
            expect(errores, isEmpty, reason: '${caso.key} a $ancho');
            expect(find.text('Cancelar'), findsOneWidget);
          },
        );
      }
    }
  }

  testWidgets('en movil el formulario ocupa toda la pantalla', (tester) async {
    await abrir(tester, ModoRegistroCheque.estandar, ancho: 390);
    expect(find.byType(Dialog), findsOneWidget);
    final tamano = tester.getSize(find.byType(Dialog));
    expect(tamano.width, 390);
  });
}

/// `dd/MM/yyyy`, como lo pinta el formulario.
String textoFechaDePrueba(DateTime f) =>
    '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
