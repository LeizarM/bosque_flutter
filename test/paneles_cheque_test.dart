import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/theme/cheques_tema.dart';
import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/nota_remision_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/pdf_cheque_estado_entity.dart';
import 'package:bosque_flutter/domain/entities/postergacion_entity.dart';
import 'package:bosque_flutter/domain/entities/transaccion_bancaria_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/detalle_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/documento_pdf_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/paneles_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/reportes_cheque.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// Los tres paneles del detalle (notas de remision, transacciones bancarias y
/// postergaciones): lo que se ve, los permisos de cada boton, los dialogos
/// «Nuevo» con su validacion en linea, eliminar con confirmacion, los errores del
/// servidor y la disposicion a 390, 768, 1000, 1400 y 1800 px, tambien con el
/// texto al 150 %.
///
/// Todo contra un repositorio falso; nunca contra el servidor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  late VisorPdfFalso visor;
  late SelectorPdfFalso selector;

  final cod = BigInt.from(5);

  setUp(() {
    repo = RepositorioChequesFalso(total: 0);
    visor = VisorPdfFalso();
    selector = SelectorPdfFalso();
  });

  // ── Datos ──────────────────────────────────────────────────────────────────

  ChequeFilaEntity cheque({String estado = 'PEN'}) =>
      chequeFalso(5, estado: estado, descTipo: 'PAGO');

  NotaRemisionChequeEntity nota(
    String n,
    int factura, {
    int fila = 1,
    int dia = 31,
  }) => NotaRemisionChequeEntity(
    codCheque: cod,
    notaRemision: n,
    nroFactura: factura,
    fechaFactura: DateTime(2026, 8, dia),
    audUsuario: 66,
    fila: fila,
  );

  TransaccionBancariaEntity transaccion(
    String nro, {
    String banco = 'BANCO UNION',
    int codBanco = 7,
    int fila = 1,
    int dia = 4,
  }) => TransaccionBancariaEntity(
    codCheque: cod,
    nroTransaccion: nro,
    codBanco: codBanco,
    fechaTransaccion: DateTime(2026, 8, dia),
    datoBanco: banco,
    fila: fila,
  );

  PostergacionEntity postergacion(
    int codPost, {
    String motivo = 'Cliente envió carta solicitando postergación.',
    bool? pdf = false,
    int fila = 1,
    int dia = 20,
  }) => PostergacionEntity(
    codPostergacion: BigInt.from(codPost),
    codCheque: cod,
    fecha: DateTime(2026, 9, dia),
    observacion: motivo,
    audUsuario: 47,
    tienePdf: pdf,
    fila: fila,
  );

  void sembrar() {
    repo.notasPorCheque[cod] = [
      nota('262211881', 1856),
      nota('262211820', 1795, fila: 2, dia: 19),
    ];
    repo.transaccionesPorCheque[cod] = [transaccion('TT26216QW3N3')];
    repo.postergacionesPorCheque[cod] = [
      postergacion(40, pdf: true),
      postergacion(41, fila: 2, motivo: 'Segunda vez.', pdf: false, dia: 27),
    ];
  }

  // ── Montaje ────────────────────────────────────────────────────────────────

  Widget pantalla({
    PermisosCheque permisos = permisosAdmin,
    String estado = 'PEN',
  }) => appCheques(
    repo: repo,
    permisos: permisos,
    extra: [
      visorPdfChequeProvider.overrideWithValue(visor.abrir),
      selectorPdfChequeProvider.overrideWithValue(selector.elegir),
    ],
    hijo: ChequesScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PanelesSatelitesCheque(cheque: cheque(estado: estado)),
      ),
    ),
  );

  Future<void> abrir(
    WidgetTester tester, {
    PermisosCheque permisos = permisosAdmin,
    String estado = 'PEN',
    double ancho = 1400,
  }) => montar(
    tester,
    pantalla(permisos: permisos, estado: estado),
    ancho: ancho,
    alto: 2400,
  );

  Finder panel(String clave) => find.byKey(ValueKey(clave));
  Finder enPanel(String clave, Finder f) =>
      find.descendant(of: panel(clave), matching: f);
  Finder clave(String k) => find.byKey(ValueKey(k));
  final dialogo = find.byType(Dialog);
  Finder enDialogo(Finder f) => find.descendant(of: dialogo, matching: f);

  const notas = 'panel-notas-remision';
  const transacciones = 'panel-transacciones';
  const postergaciones = 'panel-postergaciones';

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await esperar(tester);
  }

  /// Deja correr el reloj del aviso (se retira solo) para que ningun
  /// temporizador quede pendiente al terminar la prueba.
  Future<void> dejarPasarAviso(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Abre el calendario del campo con [etiqueta] y acepta la fecha con la que
  /// abre (hoy, o la ya elegida).
  Future<void> elegirFecha(WidgetTester tester, String etiqueta) async {
    final campo =
        find
            .ancestor(of: find.text(etiqueta), matching: find.byType(InkWell))
            .first;
    await tester.ensureVisible(campo);
    await tester.tap(campo);
    await esperar(tester);
    await tester.tap(find.text('ACEPTAR'));
    await esperar(tester);
  }

  Future<void> escribir(WidgetTester tester, String k, String texto) async {
    await tester.ensureVisible(clave(k));
    await tester.enterText(clave(k), texto);
    await esperar(tester);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUE SE VE
  // ═══════════════════════════════════════════════════════════════════════════

  group('los tres paneles', () {
    testWidgets('cada uno con su titulo, su icono y su contador', (tester) async {
      sembrar();
      await abrir(tester);

      expect(enPanel(notas, find.text('Notas de remisión')), findsOneWidget);
      expect(
        enPanel(transacciones, find.text('Transacciones bancarias')),
        findsOneWidget,
      );
      expect(enPanel(postergaciones, find.text('Postergaciones')), findsOneWidget);

      // El contador de cada uno: 2, 1 y 2.
      Finder contador(String p) =>
          enPanel(p, find.byKey(const ValueKey('contador-panel')));
      expect(tester.widget<Text>(contador(notas)).data, '2');
      expect(tester.widget<Text>(contador(transacciones)).data, '1');
      expect(tester.widget<Text>(contador(postergaciones)).data, '2');

      expect(enPanel(notas, find.byIcon(Icons.description_outlined)), findsOneWidget);
      expect(
        enPanel(transacciones, find.byIcon(Icons.account_balance_outlined)),
        findsOneWidget,
      );
      expect(
        enPanel(postergaciones, find.byIcon(Icons.event_repeat_outlined)),
        findsOneWidget,
      );
    });

    testWidgets('una nota muestra su numero, la factura y la fecha, legibles', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);

      expect(enPanel(notas, find.text('Nota 262211881')), findsOneWidget);
      expect(enPanel(notas, find.text('1856')), findsOneWidget);
      expect(enPanel(notas, find.text('31/08/2026')), findsOneWidget);
      // Con su rotulo, no un numero suelto.
      expect(enPanel(notas, find.text('Factura')), findsNWidgets(2));
      expect(enPanel(notas, find.text('Fecha de la factura')), findsNWidgets(2));
      expect(enPanel(notas, find.text('Nota 262211820')), findsOneWidget);
      expect(enPanel(notas, find.text('19/08/2026')), findsOneWidget);
    });

    testWidgets('una transaccion muestra su numero, el banco y la fecha', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      expect(enPanel(transacciones, find.text('TT26216QW3N3')), findsOneWidget);
      expect(enPanel(transacciones, find.text('BANCO UNION')), findsOneWidget);
      expect(enPanel(transacciones, find.text('04/08/2026')), findsOneWidget);
    });

    testWidgets('las postergaciones son una linea de tiempo: fila, fecha, motivo y PDF', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);

      expect(clave('postergacion-40'), findsOneWidget);
      expect(clave('postergacion-41'), findsOneWidget);
      expect(
        tester.widget<Text>(clave('fecha-postergacion-40')).data,
        '20/09/2026',
      );
      expect(
        tester.widget<Text>(clave('motivo-postergacion-40')).data,
        'Cliente envió carta solicitando postergación.',
      );
      expect(
        tester.widget<Text>(clave('motivo-postergacion-41')).data,
        'Segunda vez.',
      );
      // El numero de orden dentro de la linea de tiempo.
      expect(enPanel('postergacion-40', find.text('1')), findsOneWidget);
      expect(enPanel('postergacion-41', find.text('2')), findsOneWidget);
    });

    testWidgets('el estado del PDF se lee en una pastilla con texto e icono', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      expect(enPanel('postergacion-40', find.text('PDF cargado')), findsOneWidget);
      expect(enPanel('postergacion-41', find.text('Sin PDF')), findsOneWidget);
      expect(
        enPanel('postergacion-40', find.byIcon(Icons.picture_as_pdf)),
        findsOneWidget,
      );
      expect(
        enPanel('postergacion-41', find.byIcon(Icons.picture_as_pdf_outlined)),
        findsOneWidget,
      );
    });

    testWidgets('si el servidor no pudo comprobar el PDF (null) no dice «Sin PDF»', (
      tester,
    ) async {
      repo.postergacionesPorCheque[cod] = [postergacion(40, pdf: null)];
      await abrir(tester);
      expect(
        enPanel('postergacion-40', find.text('PDF sin comprobar')),
        findsOneWidget,
      );
      expect(enPanel('postergacion-40', find.text('Sin PDF')), findsNothing);
      // La fila igual ofrece «Cargar PDF»: ahi el dialogo explica el motivo.
      expect(enPanel('postergacion-40', find.text('Cargar PDF')), findsOneWidget);
    });

    testWidgets('con PDF, la fila ofrece «Descargar PDF»; sin PDF, «Cargar PDF»', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      expect(
        enPanel('postergacion-40', find.text('Descargar PDF')),
        findsOneWidget,
      );
      expect(enPanel('postergacion-40', find.text('Cargar PDF')), findsNothing);
      expect(
        enPanel('postergacion-41', find.text('Cargar PDF')),
        findsOneWidget,
      );
      expect(
        enPanel('postergacion-41', find.text('Descargar PDF')),
        findsNothing,
      );
    });

    testWidgets('pide cada lista una vez y las tres son independientes', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      expect(repo.contar('listarNotasRemision'), 1);
      expect(repo.contar('listarTransacciones'), 1);
      expect(repo.contar('listarPostergaciones'), 1);
      expect(repo.consultasDePaneles.toSet(), {cod});
    });

    testWidgets('una nota repetida se marca y avisa de que son varias', (
      tester,
    ) async {
      repo.notasPorCheque[cod] = [
        nota('262211820', 1795),
        nota('262211820', 1795, fila: 2),
        nota('262211881', 1856, fila: 3),
      ];
      await abrir(tester);
      expect(clave('pastilla-repetida'), findsNWidgets(2));
      expect(enPanel(notas, find.text('Repetida ×2')), findsNWidgets(2));
      // La que no se repite no lleva marca: son 2 de 3 filas.
      expect(enPanel(notas, find.byIcon(Icons.delete_outline)), findsNWidgets(3));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ESTADOS VACIOS, CARGA Y ERROR
  // ═══════════════════════════════════════════════════════════════════════════

  group('estados vacios, carga y error', () {
    testWidgets('sin datos, cada panel explica que es y que hacer (con permiso)', (
      tester,
    ) async {
      await abrir(tester);
      expect(enPanel(notas, find.text('Sin notas de remisión')), findsOneWidget);
      expect(
        enPanel(
          notas,
          find.text('Registra la nota que acompaña a la factura de este cheque.'),
        ),
        findsOneWidget,
      );
      expect(
        enPanel(transacciones, find.text('Sin transacciones bancarias')),
        findsOneWidget,
      );
      expect(
        enPanel(
          transacciones,
          find.textContaining('Anota el número de transacción del banco'),
        ),
        findsOneWidget,
      );
      expect(
        enPanel(postergaciones, find.text('Sin postergaciones')),
        findsOneWidget,
      );
      expect(
        enPanel(
          postergaciones,
          find.textContaining('cuando el cliente pide mover la fecha de cobro'),
        ),
        findsOneWidget,
      );
      // El contador dice 0.
      expect(find.byKey(const ValueKey('contador-panel')), findsNWidgets(3));
    });

    testWidgets('sin permiso para anotar, el vacio no manda a hacer lo que no puede', (
      tester,
    ) async {
      await abrir(tester, permisos: permisosNinguno);
      expect(
        enPanel(notas, find.text('Todavía no se registró ninguna para este cheque.')),
        findsOneWidget,
      );
      expect(
        enPanel(
          transacciones,
          find.text('Todavía no se registró ninguna para este cheque.'),
        ),
        findsOneWidget,
      );
      expect(
        enPanel(postergaciones, find.text('Este cheque no se postergó.')),
        findsOneWidget,
      );
      expect(find.textContaining('Registra la nota'), findsNothing);
    });

    testWidgets('mientras llega la primera lectura se ve un esqueleto', (
      tester,
    ) async {
      final notasEnCamino = Completer<List<NotaRemisionChequeEntity>>();
      final transEnCamino = Completer<List<TransaccionBancariaEntity>>();
      final postEnCamino = Completer<List<PostergacionEntity>>();
      await montar(
        tester,
        appCheques(
          repo: repo,
          extra: [
            notasRemisionChequeProvider.overrideWith((ref, c) => notasEnCamino.future),
            transaccionesChequeProvider.overrideWith((ref, c) => transEnCamino.future),
            postergacionesChequeProvider.overrideWith((ref, c) => postEnCamino.future),
          ],
          hijo: ChequesScope(
            child: SingleChildScrollView(
              child: PanelesSatelitesCheque(cheque: cheque()),
            ),
          ),
        ),
        ancho: 1400,
        alto: 2400,
      );
      // Sin respuesta todavia: tres esqueletos y ningun contador.
      expect(find.byKey(const ValueKey('esqueleto-panel')), findsNWidgets(3));
      expect(find.byKey(const ValueKey('contador-panel')), findsNothing);

      notasEnCamino.complete([nota('262211881', 1856)]);
      transEnCamino.complete(const []);
      postEnCamino.complete(const []);
      await esperar(tester);
      expect(find.byKey(const ValueKey('esqueleto-panel')), findsNothing);
      expect(enPanel(notas, find.text('Nota 262211881')), findsOneWidget);
    });

    testWidgets('si falla un panel dice por que, con Reintentar; los otros siguen', (
      tester,
    ) async {
      sembrar();
      repo.erroresDeLectura['listarTransacciones'] = Exception(
        'No tienes permiso para ver este cheque.\nPídele acceso a tu jefe.',
      );
      await abrir(tester);

      expect(
        enPanel(transacciones, find.text('No tienes permiso para ver este cheque.')),
        findsOneWidget,
      );
      expect(
        enPanel(transacciones, find.text('Pídele acceso a tu jefe.')),
        findsOneWidget,
      );
      expect(enPanel(transacciones, find.text('Reintentar')), findsOneWidget);
      // Los otros dos se dibujaron igual.
      expect(enPanel(notas, find.text('Nota 262211881')), findsOneWidget);
      expect(enPanel(postergaciones, find.text('Postergaciones')), findsOneWidget);
      expect(clave('postergacion-40'), findsOneWidget);
      // Un panel con error no dice «0 transacciones».
      expect(
        enPanel(transacciones, find.byKey(const ValueKey('contador-panel'))),
        findsNothing,
      );

      repo.erroresDeLectura.clear();
      repo.transaccionesPorCheque[cod] = [transaccion('TT26216QW3N3')];
      await tocar(tester, enPanel(transacciones, find.text('Reintentar')));
      expect(enPanel(transacciones, find.text('TT26216QW3N3')), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISOS
  // ═══════════════════════════════════════════════════════════════════════════

  group('permisos', () {
    testWidgets('«Nuevo» de los tres paneles es solo para btnNuevoNRCH', (
      tester,
    ) async {
      await abrir(tester, permisos: permisosCon([PermisosCheque.btnNuevoPanel]));
      expect(clave('nuevo-nota-remision'), findsOneWidget);
      expect(clave('nuevo-transaccion'), findsOneWidget);
      expect(clave('nuevo-postergacion'), findsOneWidget);
    });

    testWidgets('sin btnNuevoNRCH no hay ningun «Nuevo»', (tester) async {
      // Tener otros botones de la vista no basta.
      await abrir(
        tester,
        permisos: permisosCon([
          PermisosCheque.btnNuevo,
          PermisosCheque.btnDetalle,
          PermisosCheque.btnEliminarNota,
        ]),
      );
      expect(clave('nuevo-nota-remision'), findsNothing);
      expect(clave('nuevo-transaccion'), findsNothing);
      expect(clave('nuevo-postergacion'), findsNothing);
    });

    testWidgets('el administrador ve los tres «Nuevo» aunque no tenga el boton', (
      tester,
    ) async {
      await abrir(tester);
      expect(clave('nuevo-nota-remision'), findsOneWidget);
      expect(clave('nuevo-transaccion'), findsOneWidget);
      expect(clave('nuevo-postergacion'), findsOneWidget);
    });

    testWidgets('«Nuevo» tambien esta con el cheque cerrado, como en el legacy', (
      tester,
    ) async {
      await abrir(
        tester,
        permisos: permisosCon([PermisosCheque.btnNuevoPanel]),
        estado: 'CER',
      );
      expect(clave('nuevo-nota-remision'), findsOneWidget);
      expect(clave('nuevo-transaccion'), findsOneWidget);
      expect(clave('nuevo-postergacion'), findsOneWidget);
    });

    testWidgets('eliminar una nota pide btnEliminarNRCH, aparte de «Nuevo»', (
      tester,
    ) async {
      sembrar();
      await abrir(tester, permisos: permisosCon([PermisosCheque.btnNuevoPanel]));
      expect(enPanel(notas, find.byIcon(Icons.delete_outline)), findsNothing);

      await abrir(tester, permisos: permisosCon([PermisosCheque.btnEliminarNota]));
      expect(enPanel(notas, find.byIcon(Icons.delete_outline)), findsNWidgets(2));
      expect(clave('nuevo-nota-remision'), findsNothing);
    });

    testWidgets('eliminar una transaccion o una postergacion no tiene boton de permiso', (
      tester,
    ) async {
      sembrar();
      await abrir(tester, permisos: permisosNinguno);
      expect(
        enPanel(transacciones, find.byIcon(Icons.delete_outline)),
        findsOneWidget,
      );
      expect(
        enPanel(postergaciones, find.byIcon(Icons.delete_outline)),
        findsNWidgets(2),
      );
      // Y el PDF tampoco: la fila lo ofrece a cualquiera que la vea.
      expect(clave('pdf-postergacion-40'), findsOneWidget);
      expect(clave('pdf-postergacion-41'), findsOneWidget);
      // Pero sin permisos tampoco se pueden eliminar notas.
      expect(enPanel(notas, find.byIcon(Icons.delete_outline)), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ELIMINAR (CON CONFIRMACION)
  // ═══════════════════════════════════════════════════════════════════════════

  group('eliminar una nota de remision', () {
    testWidgets('pide confirmacion y, si se cancela, no escribe nada', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      await tocar(tester, clave('eliminar-nota-262211881-0'));

      expect(find.text('¿Eliminar la nota de remisión?'), findsOneWidget);
      expect(
        find.textContaining('Nota 262211881, factura 1856 del 31/08/2026.'),
        findsOneWidget,
      );
      expect(find.textContaining('no se puede deshacer'), findsOneWidget);

      await tocar(tester, find.text('Cancelar'));
      expect(repo.contar('eliminarNotaRemision'), 0);
      expect(enPanel(notas, find.text('Nota 262211881')), findsOneWidget);
    });

    testWidgets('confirmada: manda cheque y numero, refresca la lista y avisa', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      await tocar(tester, clave('eliminar-nota-262211881-0'));
      await tocar(tester, find.text('Eliminar nota'));

      expect(repo.ultimoCuerpo('eliminarNotaRemision'), {
        'codCheque': 5,
        'notaRemision': '262211881',
      });
      expect(enPanel(notas, find.text('Nota 262211881')), findsNothing);
      expect(enPanel(notas, find.text('Nota 262211820')), findsOneWidget);
      expect(find.text('Nota de remisión eliminada.'), findsOneWidget);
      // Se releyo solo lo que cambio.
      expect(repo.contar('listarNotasRemision'), 2);
      expect(repo.contar('listarTransacciones'), 1);
      expect(repo.contar('listarPostergaciones'), 1);
      await dejarPasarAviso(tester);
    });

    testWidgets('una nota repetida: avisa antes que se eliminan todas y dice cuantas despues', (
      tester,
    ) async {
      repo.notasPorCheque[cod] = [
        nota('262211820', 1795),
        nota('262211820', 1795, fila: 2),
      ];
      await abrir(tester);
      await tocar(tester, clave('eliminar-nota-262211820-0'));

      expect(
        find.textContaining(
          'Está registrada 2 veces en este cheque: se eliminarán las 2.',
        ),
        findsOneWidget,
      );
      await tocar(tester, find.text('Eliminar nota'));

      expect(find.text('Se eliminaron las 2 notas de remisión 262211820.'), findsOneWidget);
      expect(enPanel(notas, find.text('Sin notas de remisión')), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('si el servidor lo rechaza, el motivo sale completo y la nota sigue', (
      tester,
    ) async {
      sembrar();
      repo.errorEscritura = Exception(
        'No tienes permiso para eliminar notas de remisión.\n'
        'Pídele a un administrador que te asigne btnEliminarNRCH.',
      );
      await abrir(tester);
      await tocar(tester, clave('eliminar-nota-262211881-0'));
      await tocar(tester, find.text('Eliminar nota'));

      expect(
        find.textContaining('No tienes permiso para eliminar notas de remisión.'),
        findsOneWidget,
      );
      expect(find.textContaining('btnEliminarNRCH'), findsOneWidget);
      expect(enPanel(notas, find.text('Nota 262211881')), findsOneWidget);
      await dejarPasarAviso(tester);
    });
  });

  group('eliminar una transaccion', () {
    testWidgets('pide confirmacion con el numero, el banco y la fecha', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      await tocar(tester, clave('eliminar-transaccion-TT26216QW3N3-0'));
      expect(find.text('¿Eliminar la transacción bancaria?'), findsOneWidget);
      expect(
        find.textContaining(
          'Transacción TT26216QW3N3 de BANCO UNION del 04/08/2026.',
        ),
        findsOneWidget,
      );
      await tocar(tester, find.text('Cancelar'));
      expect(repo.contar('eliminarTransaccion'), 0);
    });

    testWidgets('confirmada: manda cheque y numero y la fila desaparece', (
      tester,
    ) async {
      sembrar();
      await abrir(tester, permisos: permisosNinguno);
      await tocar(tester, clave('eliminar-transaccion-TT26216QW3N3-0'));
      await tocar(tester, find.text('Eliminar transacción'));

      expect(repo.ultimoCuerpo('eliminarTransaccion'), {
        'codCheque': 5,
        'nroTransaccion': 'TT26216QW3N3',
      });
      expect(enPanel(transacciones, find.text('TT26216QW3N3')), findsNothing);
      expect(
        enPanel(transacciones, find.text('Sin transacciones bancarias')),
        findsOneWidget,
      );
      expect(find.text('Transacción bancaria eliminada.'), findsOneWidget);
      await dejarPasarAviso(tester);
    });
  });

  group('eliminar una postergacion', () {
    testWidgets('pide confirmacion y avisa si tiene PDF', (tester) async {
      sembrar();
      await abrir(tester);
      await tocar(tester, clave('eliminar-postergacion-40'));
      expect(find.text('¿Eliminar la postergación?'), findsOneWidget);
      expect(find.textContaining('Postergación del 20/09/2026'), findsOneWidget);
      expect(
        find.textContaining('Su PDF queda guardado en el servidor'),
        findsOneWidget,
      );
      await tocar(tester, find.text('Cancelar'));
      expect(repo.contar('eliminarPostergacion'), 0);
    });

    testWidgets('sin PDF no habla del PDF', (tester) async {
      sembrar();
      await abrir(tester);
      await tocar(tester, clave('eliminar-postergacion-41'));
      expect(find.textContaining('Su PDF queda guardado'), findsNothing);
      await tocar(tester, find.text('Cancelar'));
    });

    testWidgets('confirmada: manda cheque y codigo, y la linea de tiempo se acorta', (
      tester,
    ) async {
      sembrar();
      await abrir(tester);
      await tocar(tester, clave('eliminar-postergacion-41'));
      await tocar(tester, find.text('Eliminar postergación'));

      expect(repo.ultimoCuerpo('eliminarPostergacion'), {
        'codCheque': 5,
        'codPostergacion': 41,
      });
      expect(clave('postergacion-41'), findsNothing);
      expect(clave('postergacion-40'), findsOneWidget);
      expect(find.text('Postergación eliminada.'), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('el motivo largo se resume en la confirmacion', (tester) async {
      final largo = 'x' * 150;
      repo.postergacionesPorCheque[cod] = [postergacion(40, motivo: largo)];
      await abrir(tester);
      await tocar(tester, clave('eliminar-postergacion-40'));
      final alerta = find.byType(AlertDialog);
      expect(
        find.descendant(of: alerta, matching: find.textContaining('${'x' * 80}…')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: alerta, matching: find.textContaining('x' * 81)),
        findsNothing,
      );
      await tocar(tester, find.text('Cancelar'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGO: NUEVA NOTA DE REMISION
  // ═══════════════════════════════════════════════════════════════════════════

  group('nueva nota de remision', () {
    Future<void> abrirDialogo(WidgetTester tester, {double ancho = 1400}) async {
      await abrir(tester, ancho: ancho);
      await tocar(tester, clave('nuevo-nota-remision'));
    }

    testWidgets('abre con el cheque en el subtitulo y los tres campos', (
      tester,
    ) async {
      await abrirDialogo(tester);
      expect(enDialogo(find.text('Nueva nota de remisión')), findsOneWidget);
      expect(
        enDialogo(find.textContaining('Cheque 100005')),
        findsOneWidget,
      );
      expect(clave('campo-nota-remision'), findsOneWidget);
      expect(clave('campo-nro-factura'), findsOneWidget);
      expect(enDialogo(find.text('Fecha de la factura')), findsOneWidget);
    });

    testWidgets('valida en linea mientras se escribe, con el motivo completo', (
      tester,
    ) async {
      await abrirDialogo(tester);

      await escribir(tester, 'campo-nota-remision', '12A4');
      expect(
        enDialogo(find.textContaining('La nota de remisión «12A4» no es válida')),
        findsOneWidget,
      );
      expect(enDialogo(find.textContaining('«A»')), findsOneWidget);

      await escribir(tester, 'campo-nota-remision', '1234');
      expect(enDialogo(find.textContaining('es demasiado corta')), findsOneWidget);

      await escribir(tester, 'campo-nota-remision', '262211881');
      expect(enDialogo(find.textContaining('La nota de remisión')), findsNothing);

      await escribir(tester, 'campo-nro-factura', '0');
      expect(
        enDialogo(find.textContaining('debe ser mayor que 0')),
        findsOneWidget,
      );
      await escribir(tester, 'campo-nro-factura', '1856');
      expect(enDialogo(find.textContaining('mayor que 0')), findsNothing);
    });

    testWidgets('los errores de los campos se pueden leer enteros: no se cortan en una linea', (
      tester,
    ) async {
      await abrirDialogo(tester);
      for (final k in ['campo-nota-remision', 'campo-nro-factura']) {
        final campo = tester.widget<TextField>(
          find.descendant(of: clave(k), matching: find.byType(TextField)),
        );
        // Con 1 (el valor por defecto) el mensaje explicito saldria con puntos
        // suspensivos y el usuario no leeria que hacer.
        expect(
          campo.decoration!.errorMaxLines,
          greaterThanOrEqualTo(3),
          reason: k,
        );
      }
    });

    testWidgets('el campo limita a 10 digitos y la factura a 6', (tester) async {
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nota-remision', '12345678901234');
      await escribir(tester, 'campo-nro-factura', '12345678');
      expect(
        tester
            .widget<TextFormField>(clave('campo-nota-remision'))
            .controller!
            .text,
        '1234567890',
      );
      expect(
        tester.widget<TextFormField>(clave('campo-nro-factura')).controller!.text,
        '123456',
      );
    });

    testWidgets('con campos vacios no escribe nada y marca todo lo que falta', (
      tester,
    ) async {
      await abrirDialogo(tester);
      await tocar(tester, find.text('Guardar nota'));

      expect(repo.contar('registrarNotaRemision'), 0);
      expect(enDialogo(find.textContaining('Falta la nota de remisión')), findsOneWidget);
      expect(enDialogo(find.textContaining('Falta el número de factura')), findsOneWidget);
      expect(enDialogo(find.textContaining('Falta la fecha de la factura')), findsOneWidget);
      expect(dialogo, findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('guardada: manda cuerpo exacto sin usuario, cierra, avisa y refresca', (
      tester,
    ) async {
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nota-remision', ' 262211881 ');
      await escribir(tester, 'campo-nro-factura', '1856');
      await elegirFecha(tester, 'Fecha de la factura');
      await tocar(tester, find.text('Guardar nota'));

      final hoy = hoyDeLaPrueba();
      expect(repo.ultimoCuerpo('registrarNotaRemision'), {
        'codCheque': 5,
        'notaRemision': '262211881',
        'nroFactura': 1856,
        'fechaFactura': isoDia(hoy),
      });
      expect(dialogo, findsNothing);
      expect(find.text('Nota de remisión registrada.'), findsOneWidget);
      // El panel se releyo y muestra la nota nueva.
      expect(enPanel(notas, find.text('Nota 262211881')), findsOneWidget);
      expect(repo.contar('listarNotasRemision'), 2);
      await dejarPasarAviso(tester);
    });

    testWidgets('si el servidor rechaza, el dialogo sigue abierto con el motivo completo', (
      tester,
    ) async {
      repo.errorEscritura = Exception(
        'La nota de remisión no se pudo guardar.\n'
        'El cheque 5 ya no existe: actualiza la pantalla.',
      );
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nota-remision', '262211881');
      await escribir(tester, 'campo-nro-factura', '1856');
      await elegirFecha(tester, 'Fecha de la factura');
      await tocar(tester, find.text('Guardar nota'));

      expect(dialogo, findsOneWidget);
      expect(
        enDialogo(find.text('La nota de remisión no se pudo guardar.')),
        findsOneWidget,
      );
      expect(
        enDialogo(find.text('El cheque 5 ya no existe: actualiza la pantalla.')),
        findsOneWidget,
      );
      // Lo escrito se conserva.
      expect(
        tester
            .widget<TextFormField>(clave('campo-nota-remision'))
            .controller!
            .text,
        '262211881',
      );
    });

    testWidgets('el error de un intento anterior no aparece en un dialogo nuevo', (
      tester,
    ) async {
      repo.errorEscritura = Exception('Fallo viejo.');
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nota-remision', '262211881');
      await escribir(tester, 'campo-nro-factura', '1856');
      await elegirFecha(tester, 'Fecha de la factura');
      await tocar(tester, find.text('Guardar nota'));
      expect(enDialogo(find.text('Fallo viejo.')), findsOneWidget);

      await tocar(tester, find.text('Cancelar'));
      repo.errorEscritura = null;
      await tocar(tester, clave('nuevo-nota-remision'));
      expect(find.text('Fallo viejo.'), findsNothing);
    });

    testWidgets('mientras guarda se bloquea y un doble toque no escribe dos veces', (
      tester,
    ) async {
      final espera = Completer<void>();
      repo.esperaEscrituraPaneles = espera.future;
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nota-remision', '262211881');
      await escribir(tester, 'campo-nro-factura', '1856');
      await elegirFecha(tester, 'Fecha de la factura');

      await tester.tap(find.text('Guardar nota'));
      await tester.pump();
      await tester.tap(find.text('Guardando…'), warnIfMissed: false);
      await esperar(tester);
      expect(enDialogo(find.text('Guardando…')), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
            .onPressed,
        isNull,
      );

      espera.complete();
      await esperar(tester);
      expect(repo.contar('registrarNotaRemision'), 1);
      expect(dialogo, findsNothing);
      await dejarPasarAviso(tester);
    });

    testWidgets('en el telefono abre a pantalla completa', (tester) async {
      await abrirDialogo(tester, ancho: 390);
      expect(find.byType(Dialog), findsOneWidget);
      expect(clave('campo-nota-remision'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGO: NUEVA TRANSACCION
  // ═══════════════════════════════════════════════════════════════════════════

  group('nueva transaccion bancaria', () {
    Future<void> abrirDialogo(WidgetTester tester) async {
      await abrir(tester);
      await tocar(tester, clave('nuevo-transaccion'));
    }

    Future<void> elegirBanco(WidgetTester tester, String nombre) async {
      final combo = find.descendant(
        of: dialogo,
        matching: find.byType(DropdownButtonFormField<int>),
      );
      await tester.ensureVisible(combo);
      await tester.tap(combo);
      await esperar(tester);
      await tester.tap(find.text(nombre).last);
      await esperar(tester);
    }

    testWidgets('la fecha arranca en hoy, como el legacy', (tester) async {
      await abrirDialogo(tester);
      expect(
        enDialogo(find.text(textoFechaDeHoy())),
        findsOneWidget,
      );
    });

    testWidgets('valida en linea: corto, largo y vacio', (tester) async {
      await abrirDialogo(tester);

      await escribir(tester, 'campo-nro-transaccion', 'AB1');
      expect(
        enDialogo(find.textContaining('El número de transacción «AB1» es demasiado corto')),
        findsOneWidget,
      );
      expect(enDialogo(find.textContaining('3 caracteres')), findsOneWidget);

      await escribir(tester, 'campo-nro-transaccion', 'AB123');
      expect(enDialogo(find.textContaining('demasiado corto')), findsNothing);
    });

    testWidgets('limita a 30 caracteres', (tester) async {
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nro-transaccion', 'A' * 40);
      expect(
        tester
            .widget<TextFormField>(clave('campo-nro-transaccion'))
            .controller!
            .text,
        'A' * 30,
      );
    });

    testWidgets('sin banco no guarda: dice que falta elegirlo', (tester) async {
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nro-transaccion', 'TT26216QW3N3');
      await tocar(tester, find.text('Guardar transacción'));
      expect(repo.contar('registrarTransaccion'), 0);
      expect(enDialogo(find.text('Falta elegir el banco.')), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('guardada: cuerpo exacto sin usuario, cierra y el panel la muestra', (
      tester,
    ) async {
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nro-transaccion', ' TT26216QW3N3 ');
      await elegirBanco(tester, 'BANCO MERCANTIL');
      await tocar(tester, find.text('Guardar transacción'));

      expect(repo.ultimoCuerpo('registrarTransaccion'), {
        'codCheque': 5,
        'nroTransaccion': 'TT26216QW3N3',
        'codBanco': 8,
        'fechaTransaccion': isoDia(hoyDeLaPrueba()),
      });
      expect(dialogo, findsNothing);
      expect(find.text('Transacción bancaria registrada.'), findsOneWidget);
      expect(enPanel(transacciones, find.text('TT26216QW3N3')), findsOneWidget);
      expect(enPanel(transacciones, find.text('BANCO MERCANTIL')), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('si el servidor rechaza, queda abierto con el motivo completo', (
      tester,
    ) async {
      repo.errorEscritura = Exception(
        'El banco elegido ya no existe.\nElige otro banco de la lista.',
      );
      await abrirDialogo(tester);
      await escribir(tester, 'campo-nro-transaccion', 'TT26216QW3N3');
      await elegirBanco(tester, 'BANCO UNION');
      await tocar(tester, find.text('Guardar transacción'));
      expect(dialogo, findsOneWidget);
      expect(enDialogo(find.text('El banco elegido ya no existe.')), findsOneWidget);
      expect(enDialogo(find.text('Elige otro banco de la lista.')), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGO: NUEVA POSTERGACION
  // ═══════════════════════════════════════════════════════════════════════════

  group('nueva postergacion', () {
    Future<void> abrirDialogo(WidgetTester tester) async {
      await abrir(tester);
      await tocar(tester, clave('nuevo-postergacion'));
    }

    testWidgets('la fecha arranca vacia, como el legacy', (tester) async {
      await abrirDialogo(tester);
      expect(enDialogo(find.text(textoFechaDeHoy())), findsNothing);
      await tocar(tester, find.text('Guardar postergación'));
      expect(
        enDialogo(find.textContaining('Falta la fecha de la postergación')),
        findsOneWidget,
      );
      expect(repo.contar('registrarPostergacion'), 0);
      await dejarPasarAviso(tester);
    });

    testWidgets('el motivo valida en linea y cuenta hasta 200', (tester) async {
      await abrirDialogo(tester);
      await escribir(tester, 'campo-observacion-postergacion', 'ok');
      expect(enDialogo(find.textContaining('demasiado corto')), findsOneWidget);

      await escribir(tester, 'campo-observacion-postergacion', 'a' * 250);
      expect(
        tester
            .widget<TextFormField>(clave('campo-observacion-postergacion'))
            .controller!
            .text
            .length,
        200,
      );
      expect(enDialogo(find.text('200/200')), findsOneWidget);
    });

    testWidgets('el motivo admite acentos, signos y saltos de linea', (
      tester,
    ) async {
      await abrirDialogo(tester);
      await escribir(
        tester,
        'campo-observacion-postergacion',
        'Cliente envió carta: "postergar al 06/03"\ny pidió tiempo.',
      );
      expect(enDialogo(find.textContaining('demasiado')), findsNothing);
      expect(enDialogo(find.textContaining('no es válid')), findsNothing);
    });

    testWidgets('guardada: cuerpo exacto sin usuario ni archivo, y el panel la muestra sin PDF', (
      tester,
    ) async {
      await abrirDialogo(tester);
      await elegirFecha(tester, 'Fecha de la postergación');
      await escribir(
        tester,
        'campo-observacion-postergacion',
        '  Cliente envió carta.  ',
      );
      await tocar(tester, find.text('Guardar postergación'));

      expect(repo.ultimoCuerpo('registrarPostergacion'), {
        'codCheque': 5,
        'fecha': isoDia(hoyDeLaPrueba()),
        'observacion': 'Cliente envió carta.',
      });
      expect(dialogo, findsNothing);
      expect(find.text('Postergación registrada.'), findsOneWidget);
      expect(find.text('Cliente envió carta.'), findsOneWidget);
      expect(enPanel(postergaciones, find.text('Sin PDF')), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('si el servidor rechaza, queda abierto con el motivo completo', (
      tester,
    ) async {
      repo.errorEscritura = Exception(
        'No se pudo registrar la postergación.\nEl cheque ya no existe.',
      );
      await abrirDialogo(tester);
      await elegirFecha(tester, 'Fecha de la postergación');
      await escribir(tester, 'campo-observacion-postergacion', 'Motivo claro');
      await tocar(tester, find.text('Guardar postergación'));
      expect(dialogo, findsOneWidget);
      expect(
        enDialogo(find.text('No se pudo registrar la postergación.')),
        findsOneWidget,
      );
      expect(enDialogo(find.text('El cheque ya no existe.')), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF DE LA POSTERGACION
  // ═══════════════════════════════════════════════════════════════════════════

  group('PDF de la postergacion', () {
    final conPdf = PdfChequeEstadoEntity(
      existe: true,
      nombreArchivo: '40.pdf',
      tamanoBytes: 120345,
      fechaModificacion: DateTime(2026, 10, 3, 14, 22, 10),
    );

    Future<void> abrirPdf(WidgetTester tester, int codPost) async {
      sembrar();
      await abrir(tester);
      await tocar(tester, clave('pdf-postergacion-$codPost'));
    }

    bool habilitado(WidgetTester tester, String k) =>
        tester
            .widget<ButtonStyleButton>(
              find.descendant(
                of: clave(k),
                matching: find.bySubtype<ButtonStyleButton>(),
              ),
            )
            .onPressed !=
        null;

    testWidgets('sin PDF: dice que no hay y solo ofrece cargar', (tester) async {
      await abrirPdf(tester, 41);
      expect(enDialogo(find.text('PDF de la postergación')), findsOneWidget);
      expect(
        enDialogo(find.text('Esta postergación no tiene PDF todavía')),
        findsOneWidget,
      );
      expect(repo.consultasPdfPostergacion, [BigInt.from(41)]);
      expect(clave('boton-ver-pdf-postergacion'), findsNothing);
      expect(enDialogo(find.text('Cargar PDF')), findsOneWidget);
      expect(habilitado(tester, 'boton-cargar-pdf-postergacion'), isTrue);
      // La cabecera: la postergacion sobre la que se trabaja.
      expect(clave('cabecera-postergacion-pdf'), findsOneWidget);
      expect(enDialogo(find.text('27/09/2026')), findsOneWidget);
      expect(enDialogo(find.textContaining('Segunda vez.')), findsOneWidget);
    });

    testWidgets('con PDF: muestra su tamano y fecha y ofrece descargar o reemplazar', (
      tester,
    ) async {
      repo.estadosPdfPostergacion[BigInt.from(40)] = conPdf;
      await abrirPdf(tester, 40);
      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      expect(enDialogo(find.text('120 KB · 03/10/2026 14:22')), findsOneWidget);
      expect(enDialogo(find.text('40.pdf')), findsOneWidget);
      expect(enDialogo(find.text('Descargar PDF')), findsOneWidget);
      expect(enDialogo(find.text('Reemplazar PDF')), findsOneWidget);
    });

    testWidgets('descargar lo abre en el visor como Posterg_<cod>_.pdf', (
      tester,
    ) async {
      repo.estadosPdfPostergacion[BigInt.from(40)] = conPdf;
      await abrirPdf(tester, 40);
      await tocar(tester, clave('boton-ver-pdf-postergacion'));

      expect(repo.descargasPdfPostergacion, [BigInt.from(40)]);
      expect(visor.abiertos, hasLength(1));
      expect(visor.abiertos.single.nombreArchivo, 'Posterg_40_.pdf');
      expect(visor.abiertos.single.titulo, contains('Postergación del 20/09/2026'));
      expect(visor.abiertos.single.bytes, repo.pdfDeLaPostergacion);
      expect(dialogo, findsOneWidget);
    });

    testWidgets('si no se puede bajar, el motivo sale completo y se vuelve a consultar', (
      tester,
    ) async {
      repo.estadosPdfPostergacion[BigInt.from(40)] = conPdf;
      repo.errorDescargaPdfPostergacion = Exception(
        'No se encontró el archivo PDF de la postergación 40.\nCárgalo de nuevo.',
      );
      await abrirPdf(tester, 40);
      await tocar(tester, clave('boton-ver-pdf-postergacion'));

      expect(
        enDialogo(find.text('No se encontró el archivo PDF de la postergación 40.')),
        findsOneWidget,
      );
      expect(enDialogo(find.text('Cárgalo de nuevo.')), findsOneWidget);
      expect(visor.abiertos, isEmpty);
      expect(repo.consultasPdfPostergacion, hasLength(2));
    });

    testWidgets('cargar sin PDF previo: valida, sube sin confirmar y la fila pasa a «PDF cargado»', (
      tester,
    ) async {
      selector.archivo = archivoPdfFalso('Carta.pdf', tamano: 120000);
      await abrirPdf(tester, 41);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));

      expect(selector.aperturas, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repo.subidasPdfPostergacion, hasLength(1));
      final s = repo.subidasPdfPostergacion.single;
      expect(s.codPostergacion, BigInt.from(41));
      expect(s.nombre, 'Carta.pdf');
      expect(s.bytes, selector.archivo!.bytes);
      expect(enDialogo(find.text('Hay un PDF cargado')), findsOneWidget);
      expect(enDialogo(find.text('Reemplazar PDF')), findsOneWidget);
      expect(find.text('PDF cargado.'), findsOneWidget);
      // El listado de atras se releyo: la pastilla de la fila cambio.
      expect(repo.contar('listarPostergaciones'), 2);
      expect(
        enPanel('postergacion-41', find.text('PDF cargado')),
        findsOneWidget,
      );
      await dejarPasarAviso(tester);
    });

    testWidgets('reemplazar pide confirmacion y, si se cancela, no sube nada', (
      tester,
    ) async {
      repo.estadosPdfPostergacion[BigInt.from(40)] = conPdf;
      selector.archivo = archivoPdfFalso('Nueva.pdf');
      await abrirPdf(tester, 40);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));

      expect(find.text('¿Reemplazar el PDF de la postergación?'), findsOneWidget);
      expect(find.textContaining('Esta postergación ya tiene un PDF'), findsOneWidget);
      expect(find.textContaining('«Nueva.pdf»'), findsOneWidget);
      await tocar(tester, find.text('Cancelar'));
      expect(repo.subidasPdfPostergacion, isEmpty);
    });

    testWidgets('reemplazar confirmado: sube y dice «PDF reemplazado.»', (
      tester,
    ) async {
      repo.estadosPdfPostergacion[BigInt.from(40)] = conPdf;
      selector.archivo = archivoPdfFalso('Nueva.pdf');
      await abrirPdf(tester, 40);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));
      await tocar(tester, find.text('Reemplazar PDF').last);

      expect(repo.subidasPdfPostergacion, hasLength(1));
      expect(find.text('PDF reemplazado.'), findsOneWidget);
      await dejarPasarAviso(tester);
    });

    testWidgets('un archivo que no es PDF se rechaza antes de enviar, con el motivo', (
      tester,
    ) async {
      selector.archivo = archivoPdfFalso('foto.png');
      await abrirPdf(tester, 41);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));
      expect(repo.subidasPdfPostergacion, isEmpty);
      expect(
        enDialogo(
          find.text('El archivo «foto.png» no es un PDF. Elige un archivo con extensión .pdf.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('mas de 2 MB (2.010.001 bytes) se rechaza; 2.010.000 se envia', (
      tester,
    ) async {
      selector.archivo = archivoPdfFalso('grande.pdf', tamano: 2010001);
      await abrirPdf(tester, 41);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));
      expect(repo.subidasPdfPostergacion, isEmpty);
      // Con 2.010.001 contra 2.010.000 ni los decimales los distinguen: bytes.
      expect(enDialogo(find.textContaining('pesa 2010001 bytes')), findsOneWidget);
      expect(enDialogo(find.textContaining('el límite es 2010000 bytes')), findsOneWidget);

      selector.archivo = archivoPdfFalso('justo.pdf', tamano: 2010000);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));
      expect(repo.subidasPdfPostergacion, hasLength(1));
      await dejarPasarAviso(tester);
    });

    testWidgets('cancelar el selector no hace nada ni dice nada', (tester) async {
      selector.archivo = null;
      await abrirPdf(tester, 41);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));
      expect(selector.aperturas, 1);
      expect(repo.subidasPdfPostergacion, isEmpty);
      expect(find.textContaining('No se pudo'), findsNothing);
    });

    testWidgets('si el selector no abre, lo dice', (tester) async {
      selector.error = Exception('sin plugin');
      await abrirPdf(tester, 41);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));
      expect(
        enDialogo(find.text('No se pudo abrir el selector de archivos. Inténtalo de nuevo.')),
        findsOneWidget,
      );
    });

    testWidgets('la subida muestra el progreso y bloquea el cierre', (tester) async {
      final espera = Completer<void>();
      repo.esperaSubidaPdfPostergacion = espera.future;
      repo.avancesDeSubidaPdfPostergacion = const [(500, 1000)];
      selector.archivo = archivoPdfFalso('Carta.pdf', tamano: 1000);
      await abrirPdf(tester, 41);

      await tester.tap(clave('boton-cargar-pdf-postergacion'));
      await esperar(tester);
      expect(clave('progreso-subida-pdf'), findsOneWidget);
      expect(enDialogo(find.text('Subiendo «Carta.pdf» · 50 %')), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cerrar'))
            .onPressed,
        isNull,
      );

      espera.complete();
      await esperar(tester);
      expect(clave('progreso-subida-pdf'), findsNothing);
      await dejarPasarAviso(tester);
    });

    testWidgets('el rechazo del servidor sale completo con el dialogo abierto', (
      tester,
    ) async {
      repo.errorSubidaPdfPostergacion = Exception(
        'El archivo pesa 2.350.000 bytes (2,35 MB).\nElige un PDF más liviano.',
      );
      selector.archivo = archivoPdfFalso('Carta.pdf');
      await abrirPdf(tester, 41);
      await tocar(tester, clave('boton-cargar-pdf-postergacion'));
      expect(
        enDialogo(find.text('El archivo pesa 2.350.000 bytes (2,35 MB).')),
        findsOneWidget,
      );
      expect(enDialogo(find.text('Elige un PDF más liviano.')), findsOneWidget);
      expect(dialogo, findsOneWidget);
      // El estado no cambio.
      expect(enDialogo(find.text('Esta postergación no tiene PDF todavía')), findsOneWidget);
    });

    testWidgets('con la carpeta sin montar en el servidor, el aviso explicito se ve y se puede reintentar', (
      tester,
    ) async {
      repo.errorEstadoPdfPostergacion = Exception(
        'La carpeta de los PDF de postergaciones no está configurada en el '
        'servidor (propiedad cheques.postergacion.pdf.dir).\nAvisa a sistemas.',
      );
      await abrirPdf(tester, 41);
      expect(
        enDialogo(find.textContaining('La carpeta de los PDF de postergaciones')),
        findsOneWidget,
      );
      expect(enDialogo(find.text('Avisa a sistemas.')), findsOneWidget);
      // Sin saber si hay PDF, los botones no actuan a ciegas.
      expect(habilitado(tester, 'boton-cargar-pdf-postergacion'), isFalse);

      repo.errorEstadoPdfPostergacion = null;
      await tocar(tester, enDialogo(find.text('Reintentar')));
      expect(habilitado(tester, 'boton-cargar-pdf-postergacion'), isTrue);
    });

    testWidgets('«Cerrar» cierra el dialogo', (tester) async {
      await abrirPdf(tester, 41);
      await tocar(tester, enDialogo(find.text('Cerrar')));
      expect(dialogo, findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPOSICION
  // ═══════════════════════════════════════════════════════════════════════════

  group('disposicion', () {
    double izq(WidgetTester t, String k) => t.getTopLeft(panel(k)).dx;
    double arriba(WidgetTester t, String k) => t.getTopLeft(panel(k)).dy;

    testWidgets('1400 px: tres columnas, a la misma altura', (tester) async {
      sembrar();
      await abrir(tester, ancho: 1400);
      expect(arriba(tester, notas), arriba(tester, transacciones));
      expect(arriba(tester, notas), arriba(tester, postergaciones));
      expect(izq(tester, notas) < izq(tester, transacciones), isTrue);
      expect(izq(tester, transacciones) < izq(tester, postergaciones), isTrue);
    });

    testWidgets('en tres columnas no se suma altura: cada panel mide lo suyo', (
      tester,
    ) async {
      sembrar();
      await abrir(tester, ancho: 1400);
      final alto =
          tester.getSize(find.byType(PanelesSatelitesCheque)).height;
      final suma =
          tester.getSize(panel(notas)).height +
          tester.getSize(panel(transacciones)).height +
          tester.getSize(panel(postergaciones)).height;
      final mayor = [notas, transacciones, postergaciones]
          .map((k) => tester.getSize(panel(k)).height)
          .reduce((a, b) => a > b ? a : b);
      expect(alto, mayor);
      expect(alto < suma, isTrue);
      // Y los mas cortos no se estiran hasta el mas alto.
      expect(
        tester.getSize(panel(transacciones)).height < mayor ||
            tester.getSize(panel(notas)).height < mayor,
        isTrue,
      );
    });

    testWidgets('768 px: notas y transacciones en una columna, postergaciones al lado', (
      tester,
    ) async {
      sembrar();
      await abrir(tester, ancho: 768);
      expect(izq(tester, notas), izq(tester, transacciones));
      expect(arriba(tester, transacciones) > arriba(tester, notas), isTrue);
      expect(izq(tester, postergaciones) > izq(tester, notas), isTrue);
      expect(arriba(tester, postergaciones), arriba(tester, notas));
    });

    testWidgets('390 px: apilados, uno sobre otro, a todo el ancho', (tester) async {
      sembrar();
      await abrir(tester, ancho: 390);
      expect(izq(tester, notas), izq(tester, transacciones));
      expect(izq(tester, notas), izq(tester, postergaciones));
      expect(arriba(tester, transacciones) > arriba(tester, notas), isTrue);
      expect(arriba(tester, postergaciones) > arriba(tester, transacciones), isTrue);
      expect(
        tester.getSize(panel(notas)).width,
        tester.getSize(panel(postergaciones)).width,
      );
    });

    for (final ancho in [390.0, 768.0, 1000.0, 1400.0, 1800.0]) {
      for (final texto in [1.0, 1.5]) {
        testWidgets('sin desbordes a ${ancho.toInt()} px con texto al ${(texto * 100).toInt()} %', (
          tester,
        ) async {
          conTexto(tester, texto);
          repo.notasPorCheque[cod] = [
            nota('2922800091', 123456),
            nota('2922800091', 123456, fila: 2),
          ];
          repo.transaccionesPorCheque[cod] = [
            transaccion(
              'TRANSFERENCIA-INTERBANCARIA-0098',
              banco: 'Banco Nacional de Bolivia - Cuenta corriente 1234567890',
            ),
            transaccion('14910211612', banco: 'BANCO MERCANTIL SANTA CRUZ', fila: 2),
          ];
          repo.postergacionesPorCheque[cod] = [
            postergacion(
              40,
              motivo:
                  'Cliente envió carta solicitando postergación hasta el 06 de '
                  'marzo, misma que fue aceptada por la gerencia comercial y '
                  'comunicada al grupo de cobranzas por el ejecutivo.',
              pdf: true,
            ),
            postergacion(41, fila: 2, pdf: null),
          ];
          final errores = await capturandoErrores(() async {
            await abrir(tester, ancho: ancho);
          });
          expect(errores, isEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('los dialogos tampoco desbordan a 390 px con texto al 150 %', (
      tester,
    ) async {
      conTexto(tester, 1.5);
      sembrar();
      final errores = await capturandoErrores(() async {
        await abrir(tester, ancho: 390);
        await tocar(tester, clave('nuevo-nota-remision'));
        await tocar(tester, find.text('Cancelar'));
        await tocar(tester, clave('nuevo-transaccion'));
        await tocar(tester, find.text('Cancelar'));
        await tocar(tester, clave('nuevo-postergacion'));
        await tocar(tester, find.text('Cancelar'));
        await tocar(tester, clave('pdf-postergacion-41'));
      });
      expect(errores, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // EN EL DETALLE
  // ═══════════════════════════════════════════════════════════════════════════

  group('en el detalle del cheque', () {
    testWidgets('los tres paneles estan entre las acciones y el historial', (
      tester,
    ) async {
      sembrar();
      await montar(
        tester,
        appCheques(
          repo: repo,
          hijo: ChequesScope(
            child: DetalleCheque(codCheque: cod, onVolver: () {}),
          ),
        ),
        ancho: 1400,
        alto: 2400,
      );

      expect(panel(notas), findsOneWidget);
      expect(panel(transacciones), findsOneWidget);
      expect(panel(postergaciones), findsOneWidget);
      final acciones = tester.getTopLeft(find.text('Acciones')).dy;
      final historial = tester.getTopLeft(find.textContaining('Historial (')).dy;
      final yNotas = arribaDe(tester, panel(notas));
      expect(yNotas > acciones, isTrue);
      expect(yNotas < historial, isTrue);
    });

    testWidgets('«Actualizar» vuelve a leer tambien los tres paneles', (
      tester,
    ) async {
      sembrar();
      await montar(
        tester,
        appCheques(
          repo: repo,
          hijo: ChequesScope(
            child: DetalleCheque(codCheque: cod, onVolver: () {}),
          ),
        ),
        ancho: 1400,
        alto: 2400,
      );
      expect(repo.contar('listarNotasRemision'), 1);
      await tocar(tester, find.byTooltip('Actualizar'));
      expect(repo.contar('listarNotasRemision'), 2);
      expect(repo.contar('listarTransacciones'), 2);
      expect(repo.contar('listarPostergaciones'), 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES
  // ═══════════════════════════════════════════════════════════════════════════

  test('los widgets de los paneles no escriben colores a mano', () {
    final archivos = [
      'lib/presentation/widgets/cheques/paneles_cheque.dart',
      'lib/presentation/widgets/cheques/dialogos_paneles_cheque.dart',
      'lib/presentation/widgets/cheques/documento_pdf_postergacion.dart',
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
        reason:
            '$a escribe un color a mano: ${prohibido.firstMatch(sinComentarios)?.group(0)}',
      );
    }
  });
}

double arribaDe(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

/// «03/10/2026» con la fecha de hoy, tal como la escribe el campo de fecha.
String textoFechaDeHoy() {
  final h = hoyDeLaPrueba();
  return '${h.day.toString().padLeft(2, '0')}/'
      '${h.month.toString().padLeft(2, '0')}/${h.year}';
}
