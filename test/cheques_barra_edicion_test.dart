import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/formulario_cheque.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// La barra nueva de Cheques (`Custodia ▾`, `Reportes ▾` y un solo `Registrar`)
/// y el lapiz unico de la fila: con que formulario se abre cada uno segun los
/// permisos del usuario y el estado del cheque. Con un repositorio falso: nunca
/// se probo contra el servidor.
///
/// La tabla de campos de cada modo esta en `cheques_formulario_test.dart`; aqui
/// se comprueba que la pantalla elija el modo correcto y que el cuerpo enviado
/// lo lleve.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;

  setUp(() {
    repo =
        RepositorioChequesFalso()
          ..clientes = [
            clienteDeCheque('C1', 'EDITORA MENDEZ'),
            clienteDeCheque('C2', 'LIBRERIA PAIS'),
          ]
          ..personal = const [
            PersonalChequeEntity(codEmpleado: 12, nombreCompleto: 'JUAN PEREZ'),
          ];
  });

  Widget pantalla({PermisosCheque permisos = permisosAdmin}) =>
      appCheques(hijo: const ChequesScreen(), repo: repo, permisos: permisos);

  /// Un cheque editable sin tropiezos: fechas dentro de +-28 dias, a la orden de
  /// sin puntos (el validador del legacy no los admite) y tipo conocido.
  ChequeFilaEntity cheque(
    int cod, {
    String estado = 'PEN',
    String fechaCobrar = '2026-08-20',
    int codEmpleado = 0,
  }) => chequeFalso(
    cod,
    estado: estado,
    descTipo: 'PAGO',
    fechaCheque: '2026-08-10',
    fechaCobrar: fechaCobrar,
    aOrdenDe: 'BOSQUE SA',
    codEmpleado: codEmpleado,
    datoEmpleado:
        codEmpleado == 0 ? ' - Entregado por el Cliente -' : ' - JUAN PEREZ -',
  );

  Finder editable(String id) => find.byKey(ValueKey('editable-$id'));
  Finder bloqueado(String id) => find.byKey(ValueKey('bloqueado-$id'));
  Finder entrada(String id) =>
      find.descendant(of: editable(id), matching: find.byType(TextFormField));

  const campos = [
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

  /// Comprueba cuales campos del formulario abierto son editables; los demas
  /// deben estar bloqueados (nunca escondidos).
  void soloEditables(Set<String> esperados) {
    for (final c in campos) {
      expect(
        editable(c),
        esperados.contains(c) ? findsOneWidget : findsNothing,
        reason: 'editable $c',
      );
      expect(
        bloqueado(c),
        esperados.contains(c) ? findsNothing : findsOneWidget,
        reason: 'bloqueado $c',
      );
    }
  }

  const camposAdmin = {
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
  };

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await esperar(tester);
  }

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
    await tocar(tester, editable(id));
    await tester.tap(find.text(etiqueta).last);
    await esperar(tester);
  }

  Future<void> elegirFecha(WidgetTester tester, String id) async {
    await tester.ensureVisible(editable(id));
    await tester.tap(
      find.descendant(of: editable(id), matching: find.byType(InkWell)).first,
    );
    await esperar(tester);
    await tester.tap(find.text('ACEPTAR'));
    await esperar(tester);
  }

  /// Llena un alta valida (entregado por, tipo y moneda quedan como abren).
  Future<void> llenarAlta(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('campo-cliente')));
    await tester.enterText(find.byKey(const ValueKey('campo-cliente')), 'edi');
    await esperar(tester);
    await tester.tap(find.text('EDITORA MENDEZ').last);
    await esperar(tester);
    await elegirDeLista(tester, 'banco', 'BANCO UNION');
    await escribir(tester, 'nroCheque', '000123456');
    await escribir(tester, 'monto', '1500.5');
    await escribir(tester, 'aOrdenDe', 'BOSQUE SA');
    await elegirFecha(tester, 'fechaCheque');
  }

  Future<void> guardar(WidgetTester tester, String etiqueta) async {
    await tocar(tester, find.widgetWithText(FilledButton, etiqueta));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LA BARRA DE ESCRITORIO
  // ═══════════════════════════════════════════════════════════════════════════

  group('barra de escritorio', () {
    testWidgets('administrador: Custodia, Reportes y Registrar, en ese orden', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);

      final custodia = find.text('Custodia');
      final reportes = find.text('Reportes');
      final registrar = find.text('Registrar');
      expect(custodia, findsOneWidget);
      expect(reportes, findsOneWidget);
      expect(registrar, findsOneWidget);
      // Recargar, luego Custodia ▾, Reportes ▾ y Registrar, de izquierda a derecha.
      final x = [
        tester.getCenter(find.byTooltip('Actualizar')).dx,
        tester.getCenter(custodia).dx,
        tester.getCenter(reportes).dx,
        tester.getCenter(registrar).dx,
      ];
      expect(x[0], lessThan(x[1]));
      expect(x[1], lessThan(x[2]));
      expect(x[2], lessThan(x[3]));
    });

    testWidgets('Registrar es el boton primario (relleno); los menus no', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      expect(
        find.ancestor(
          of: find.text('Registrar'),
          matching: find.bySubtype<FilledButton>(),
        ),
        findsOneWidget,
      );
      for (final menu in ['Custodia', 'Reportes']) {
        expect(
          find.ancestor(
            of: find.text(menu),
            matching: find.bySubtype<FilledButton>(),
          ),
          findsNothing,
          reason: menu,
        );
        expect(
          find.ancestor(
            of: find.text(menu),
            matching: find.bySubtype<OutlinedButton>(),
          ),
          findsOneWidget,
          reason: menu,
        );
      }
    });

    testWidgets('ya no hay botones sueltos ni «Registrar como administrador»', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      for (final suelto in [
        'Traspaso',
        'A Custodio',
        'Dar Custodia',
        'Registrar como administrador',
      ]) {
        expect(find.text(suelto), findsNothing, reason: suelto);
      }
    });

    testWidgets('el menu Custodia lista las tres acciones del administrador', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Custodia'));
      await esperar(tester);
      for (final e in ['Traspaso', 'A Custodio', 'Dar Custodia']) {
        expect(find.text(e), findsOneWidget, reason: e);
      }
      // Los reportes siguen en su propio menu.
      expect(find.text('Cheques recibidos'), findsNothing);
    });

    testWidgets('con solo Traspaso y Reportes: boton directo, sin menu Custodia', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(
          permisos: permisosCon([PermisosCheque.btnTraspaso, 'btnRpt1CH']),
        ),
        ancho: 1400,
      );
      expect(find.text('Custodia'), findsNothing);
      expect(find.text('Traspaso'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      // Sin ningun permiso de alta, tampoco Registrar.
      expect(find.text('Registrar'), findsNothing);
    });

    testWidgets('sin custodia ni reportes: solo recargar y Registrar', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 1400);
      expect(find.text('Custodia'), findsNothing);
      expect(find.text('Reportes'), findsNothing);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('sin sucursal: Custodia, Reportes y Registrar se apagan', (
      tester,
    ) async {
      repo.sucursalInicial = 0;
      await montar(tester, pantalla(), ancho: 1400);
      for (final b in ['Custodia', 'Reportes']) {
        final o = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.text(b),
            matching: find.bySubtype<OutlinedButton>(),
          ),
        );
        expect(o.onPressed, isNull, reason: b);
      }
      final r = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Registrar'),
          matching: find.bySubtype<FilledButton>(),
        ),
      );
      expect(r.onPressed, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // REGISTRAR: UN SOLO BOTON, EL MODO LO ELIGE EL PERMISO
  // ═══════════════════════════════════════════════════════════════════════════

  group('Registrar', () {
    testWidgets('administrador: abre en modo administrador, cobro editable', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Registrar'));
      await esperar(tester);

      expect(find.text('Registrar cheque (administrador)'), findsOneWidget);
      soloEditables(camposAdmin);
      expect(editable('fechaCobrar'), findsOneWidget);
    });

    testWidgets('administrador: el cuerpo enviado lleva ADMIN y la fecha de cobro', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Registrar'));
      await esperar(tester);
      await llenarAlta(tester);
      await elegirFecha(tester, 'fechaCobrar');
      await guardar(tester, 'Registrar cheque');

      final b = repo.ultimoCuerpo('registrar');
      expect(b['modo'], 'ADMIN');
      expect(b['fechaCobrar'], isoDia(hoyDeLaPrueba()));
      expect(b['codSucursal'], 3);
      expect(b['codEmpresa'], 1);
    });

    testWidgets('solo btnNuevo2CH: ve Registrar y abre en modo administrador', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(permisos: permisosCon([PermisosCheque.btnNuevoAdmin])),
        ancho: 1400,
      );
      expect(find.text('Registrar'), findsOneWidget);
      await tester.tap(find.text('Registrar'));
      await esperar(tester);
      soloEditables(camposAdmin);

      await llenarAlta(tester);
      await guardar(tester, 'Registrar cheque');
      expect(repo.ultimoCuerpo('registrar')['modo'], 'ADMIN');
    });

    testWidgets('btnNuevoCH y btnNuevo2CH: un solo boton, modo administrador', (
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
        ancho: 1400,
      );
      expect(find.text('Registrar'), findsOneWidget);
      await tester.tap(find.text('Registrar'));
      await esperar(tester);
      expect(editable('fechaCobrar'), findsOneWidget);
    });

    testWidgets('solo btnNuevoCH: abre estandar, cobro bloqueado y cuerpo ESTANDAR', (
      tester,
    ) async {
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 1400);
      await tester.tap(find.text('Registrar'));
      await esperar(tester);

      expect(find.text('Registrar cheque (administrador)'), findsNothing);
      expect(editable('fechaCobrar'), findsNothing);
      expect(bloqueado('fechaCobrar'), findsOneWidget);

      await llenarAlta(tester);
      await guardar(tester, 'Registrar cheque');
      final b = repo.ultimoCuerpo('registrar');
      expect(b['modo'], 'ESTANDAR');
      // En el alta estandar el cobro sigue a la fecha del cheque.
      expect(b['fechaCobrar'], b['fechaCheque']);
    });

    testWidgets('sin btnNuevoCH ni btnNuevo2CH no aparece Registrar', (
      tester,
    ) async {
      await montar(
        tester,
        pantalla(
          permisos: permisosCon([
            PermisosCheque.btnEditar,
            PermisosCheque.btnDetalle,
            PermisosCheque.btnTraspaso,
          ]),
        ),
        ancho: 1400,
      );
      expect(find.text('Registrar'), findsNothing);
      expect(find.byTooltip('Registrar cheque'), findsNothing);
    });

    testWidgets('en movil: administrador abre directo en modo administrador', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 390);
      await tester.tap(find.byTooltip('Registrar cheque'));
      await esperar(tester);
      expect(editable('fechaCobrar'), findsOneWidget);
    });

    testWidgets('en movil: solo btnNuevoCH abre estandar', (tester) async {
      await montar(tester, pantalla(permisos: permisosCajero), ancho: 390);
      await tester.tap(find.byTooltip('Registrar cheque'));
      await esperar(tester);
      expect(editable('fechaCobrar'), findsNothing);
      expect(bloqueado('fechaCobrar'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EDITAR DESDE LA FILA: UN SOLO LAPIZ
  // ═══════════════════════════════════════════════════════════════════════════

  group('lapiz de la fila', () {
    Future<void> abrir(
      WidgetTester tester,
      PermisosCheque permisos,
      ChequeFilaEntity c, {
      String tooltip = 'Editar',
    }) async {
      repo.cheques = [c];
      await montar(tester, pantalla(permisos: permisos), ancho: 1400);
      await tester.tap(find.byTooltip(tooltip));
      await esperar(tester);
    }

    testWidgets('administrador, cheque abierto: todo desbloqueado y cuerpo ADMIN', (
      tester,
    ) async {
      await abrir(tester, permisosAdmin, cheque(5));

      expect(find.text('Editar cheque (administrador)'), findsOneWidget);
      soloEditables(camposAdmin);
      expect(find.byKey(claveAvisoCobroFueraDeRango), findsNothing);
      for (final c in [
        'entregadoPor',
        'tipo',
        'monto',
        'moneda',
        'aOrdenDe',
        'fechaCheque',
        'fechaCobrar',
      ]) {
        expect(editable(c), findsOneWidget, reason: c);
      }

      await guardar(tester, 'Guardar cambios');
      final b = repo.ultimoCuerpo('registrar');
      expect(b['modo'], 'ADMIN');
      expect(b['codCheque'], 5);
      expect(b['fechaCobrar'], '2026-08-20');
    });

    testWidgets('administrador, cheque cerrado dentro de rango: igual, ADMIN', (
      tester,
    ) async {
      await abrir(tester, permisosAdmin, cheque(5, estado: 'CER'));

      soloEditables(camposAdmin);
      expect(find.byKey(claveAvisoCobroFueraDeRango), findsNothing);
      await guardar(tester, 'Guardar cambios');
      expect(repo.ultimoCuerpo('registrar')['modo'], 'ADMIN');
    });

    testWidgets('administrador, cerrado exactamente a 28 dias: sigue siendo ADMIN', (
      tester,
    ) async {
      // 10/08 + 28 dias = 07/09.
      await abrir(
        tester,
        permisosAdmin,
        cheque(5, estado: 'CER', fechaCobrar: '2026-09-07'),
      );
      soloEditables(camposAdmin);
      expect(find.byKey(claveAvisoCobroFueraDeRango), findsNothing);
    });

    testWidgets('administrador, cerrado fuera de rango: talonario, con aviso', (
      tester,
    ) async {
      // 10/08 + 29 dias = 08/09.
      await abrir(
        tester,
        permisosAdmin,
        cheque(5, estado: 'CER', fechaCobrar: '2026-09-08'),
      );

      expect(find.text('Editar talonario y recibo'), findsOneWidget);
      soloEditables({'talonario', 'recibo'});
      expect(find.byKey(claveAvisoCobroFueraDeRango), findsOneWidget);
      expect(
        find.textContaining(
          'La fecha de cobro de este cheque está fuera de ±28 días de la '
          'fecha del cheque: solo se pueden corregir el talonario y el recibo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('el aviso no bloquea: se guarda y el cuerpo es TALONARIO', (
      tester,
    ) async {
      await abrir(
        tester,
        permisosAdmin,
        // Lo trajo un empleado: el recibo manual tiene que ser distinto de 0.
        cheque(5, estado: 'CER', fechaCobrar: '2026-10-20', codEmpleado: 12),
      );
      await escribir(tester, 'recibo', '88');
      await escribir(tester, 'talonario', '9');
      await guardar(tester, 'Guardar cambios');

      expect(repo.contar('registrar'), 1);
      expect(repo.ultimoCuerpo('registrar'), {
        'codCheque': 5,
        'modo': 'TALONARIO',
        'nroTalonario': '9',
        'reciboManual': '88',
      });
      // El formulario se cerro: no hay error ni sigue el aviso.
      expect(find.byKey(claveAvisoCobroFueraDeRango), findsNothing);
    });

    testWidgets('un cheque abierto con el cobro fuera de rango no lleva aviso', (
      tester,
    ) async {
      await abrir(
        tester,
        permisosAdmin,
        cheque(5, fechaCobrar: '2026-10-20'),
      );
      expect(find.byKey(claveAvisoCobroFueraDeRango), findsNothing);
      expect(find.text('Editar cheque (administrador)'), findsOneWidget);
    });

    testWidgets('btnEditar3CH con el cheque abierto: modo administrador', (
      tester,
    ) async {
      await abrir(
        tester,
        permisosCon([PermisosCheque.btnEditarAdmin]),
        cheque(5),
      );
      soloEditables(camposAdmin);
      await guardar(tester, 'Guardar cambios');
      expect(repo.ultimoCuerpo('registrar')['modo'], 'ADMIN');
    });

    testWidgets('solo btnEditar1CH con el cheque abierto: modo estandar', (
      tester,
    ) async {
      await abrir(tester, permisosCajero, cheque(5));
      soloEditables({
        'cliente',
        'banco',
        'nroCheque',
        'talonario',
        'recibo',
        'observacion',
      });
      await guardar(tester, 'Guardar cambios');
      expect(repo.ultimoCuerpo('registrar')['modo'], 'ESTANDAR');
    });

    testWidgets('solo btnEditar1CH con el cheque cerrado: «Editar talonario», sin aviso', (
      tester,
    ) async {
      await abrir(
        tester,
        permisosCajero,
        cheque(5, estado: 'CER', fechaCobrar: '2026-10-20'),
        tooltip: 'Editar talonario',
      );
      soloEditables({'talonario', 'recibo'});
      // El aviso es del administrador que pidio el otro formulario.
      expect(find.byKey(claveAvisoCobroFueraDeRango), findsNothing);
      await guardar(tester, 'Guardar cambios');
      expect(repo.ultimoCuerpo('registrar')['modo'], 'TALONARIO');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MOVIL
  // ═══════════════════════════════════════════════════════════════════════════

  group('movil', () {
    testWidgets('el menu de la barra no ofrece «Registrar como administrador»', (
      tester,
    ) async {
      await montar(tester, pantalla(), ancho: 390);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.swap_horiz));
      await esperar(tester);
      expect(find.text('Registrar como administrador'), findsNothing);
      expect(find.text('Registrar cheque'), findsNothing);
      // Lo suyo sigue: custodia y reportes en un solo menu.
      for (final e in ['Traspaso', 'A Custodio', 'Dar Custodia']) {
        expect(find.text(e), findsOneWidget, reason: e);
      }
      expect(find.text('Cheques recibidos'), findsOneWidget);
    });

    testWidgets('las tarjetas no muestran «Editar (administrador)»', (
      tester,
    ) async {
      repo.cheques = [cheque(1), cheque(2, estado: 'CER')];
      await montar(tester, pantalla(), ancho: 390);

      for (var i = 0; i < 2; i++) {
        // Con el resumen arriba y la tarjeta mas alta, la segunda queda bajo el
        // pliegue de 844 px: se trae a la vista antes de tocarla.
        await tester.ensureVisible(find.byTooltip('Acciones').at(i));
        await esperar(tester);
        await tester.tap(find.byTooltip('Acciones').at(i));
        await esperar(tester);
        expect(find.text('Editar'), findsOneWidget, reason: 'tarjeta $i');
        expect(find.text('Fecha de cobro'), findsOneWidget);
        expect(find.text('Completar'), findsOneWidget);
        expect(find.text('Editar (administrador)'), findsNothing);
        expect(find.text('Editar talonario'), findsNothing);
        // Cierra el menu antes de abrir el siguiente.
        await tester.tapAt(const Offset(5, 400));
        await esperar(tester);
      }
    });

    testWidgets('el lapiz de una tarjeta abre el formulario de administrador', (
      tester,
    ) async {
      repo.cheques = [cheque(1)];
      await montar(tester, pantalla(), ancho: 390);
      await tester.tap(find.byTooltip('Acciones'));
      await esperar(tester);
      await tester.tap(find.text('Editar'));
      await esperar(tester);
      soloEditables(camposAdmin);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SIN DESBORDES
  // ═══════════════════════════════════════════════════════════════════════════

  final cheques = [
    chequeFalso(
      1,
      cliente: 'CLIENTE CON UN NOMBRE MUY LARGO S.R.L. SUCURSAL NORTE',
      banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
      descTipo: 'RESPALDO',
    ),
    chequeFalso(2, estado: 'CER', descTipo: 'PAGO'),
    for (var i = 3; i <= 6; i++) chequeFalso(i, descTipo: 'PAGO'),
  ];

  for (final escala in [1.0, 1.5]) {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      final sufijo =
          'a ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %';

      testWidgets('la barra del administrador no desborda $sufijo', (
        tester,
      ) async {
        repo.cheques = cheques;
        if (escala != 1.0) conTexto(tester, escala);
        final errores = await capturandoErrores(() async {
          await montar(tester, pantalla(), ancho: ancho);
        });
        expect(errores, isEmpty, reason: sufijo);

        if (ancho < 600) {
          // Telefono: tres botones iconicos, todos dentro de la pantalla.
          for (final f in [
            find.byTooltip('Actualizar'),
            find.widgetWithIcon(IconButton, Icons.swap_horiz),
            find.byTooltip('Registrar cheque'),
          ]) {
            expect(f, findsOneWidget);
            expect(tester.getRect(f).right, lessThanOrEqualTo(ancho));
          }
        } else {
          // Escritorio: Custodia ▾, Reportes ▾ y Registrar caben de ancho (si no
          // entran en una linea, el Wrap los baja a otra).
          for (final t in ['Custodia', 'Reportes', 'Registrar']) {
            final r = tester.getRect(find.text(t));
            expect(r.left, greaterThanOrEqualTo(0), reason: t);
            expect(r.right, lessThanOrEqualTo(ancho), reason: t);
          }
        }
      });

      testWidgets('la fila con un solo lapiz no desborda $sufijo', (
        tester,
      ) async {
        repo.cheques = cheques;
        if (escala != 1.0) conTexto(tester, escala);
        final errores = await capturandoErrores(() async {
          await montar(tester, pantalla(), ancho: ancho);
        });
        expect(errores, isEmpty, reason: sufijo);

        // Nunca las variantes que se fusionaron en el lapiz.
        expect(find.byTooltip('Editar (administrador)'), findsNothing);
        expect(find.byTooltip('Editar talonario'), findsNothing);
        if (ancho >= 1000) {
          // Con tres acciones por fila entran como iconos: un lapiz por cheque.
          expect(find.byTooltip('Editar'), findsNWidgets(cheques.length));
          expect(find.byTooltip('Fecha de cobro'), findsNWidgets(cheques.length));
          expect(find.byTooltip('Completar'), findsNWidgets(cheques.length));
        }
      });
    }
  }
}
