import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/data/models/accion_cheque_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/detalle_cheque.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// El detalle («Completar»): historial, las cuatro acciones que da el servidor,
/// sus dialogos y la baja de acciones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioChequesFalso repo;
  var volvio = 0;

  setUp(() {
    repo = RepositorioChequesFalso();
    volvio = 0;
  });

  final hoy = hoyDeLaPrueba();

  /// Un cheque cuya fecha esta cerca de hoy: asi hoy cae dentro de los +-28
  /// dias de «Fecha de cobro» y el calendario abre en una fecha valida.
  ChequeFilaEntity cheque({String estado = 'PEN'}) => chequeFalso(
    5,
    estado: estado,
    descTipo: 'PAGO',
    // Sin puntos: el validador del legacy solo admite letras.
    aOrdenDe: 'BOSQUE SA',
    fechaCheque: isoDia(hoy.subtract(const Duration(days: 5))),
    fechaCobrar: isoDia(hoy.add(const Duration(days: 10))),
  );

  BotonesChequeEntity botones(String codigo) => BotonesChequeEntity(
    fechaCobro: codigo[0] == '1',
    devolver: codigo[1] == '1',
    cerrarConVerificacion: codigo[2] == '1',
    cerrarSinVerificacion: codigo[3] == '1',
    codigo: codigo,
  );

  AccionChequeEntity accion(
    int n,
    String estado, {
    String descripcion = '',
    String? nroSap,
    String? obs,
    int dia = 1,
  }) => AccionChequeModel.fromJson({
    'codAccion': 500 + n,
    'codCheque': 5,
    'fecha': '2026-08-0${dia}T${(8 + n).toString().padLeft(2, '0')}:30:00',
    'estado': estado,
    'codEmpleado': estado == 'CUS' ? 12 : null,
    'nroSAP': nroSap,
    'observacion': obs,
    'audUsuario': 47,
    'audFecha': '2026-08-0${dia}T${(8 + n).toString().padLeft(2, '0')}:30:00',
    'descripcion': descripcion,
    'nro': n,
  }).toEntity();

  /// Fija lo que devuelve el detalle: botones, estado del cheque y acciones.
  void detalle(
    String codigo, {
    String estado = 'PEN',
    List<AccionChequeEntity>? acciones,
  }) {
    repo.alObtenerDetalle =
        (cod) async => ChequeDetalleEntity(
          cheque: cheque(estado: estado),
          acciones:
              acciones ??
              [
                accion(1, 'REC', descripcion: 'RECIBIDO'),
                accion(2, 'TRASP', descripcion: 'TRASPASO'),
                accion(3, 'CUS', descripcion: 'A COBRANZA'),
              ],
          botones: botones(codigo),
        );
  }

  Widget pantalla({PermisosCheque permisos = permisosAdmin}) => appCheques(
    repo: repo,
    permisos: permisos,
    hijo: DetalleCheque(
      codCheque: BigInt.from(5),
      onVolver: () => volvio++,
    ),
  );

  Future<void> abrir(
    WidgetTester tester, {
    PermisosCheque permisos = permisosAdmin,
    double ancho = 1400,
  }) => montar(tester, pantalla(permisos: permisos), ancho: ancho);

  ButtonStyleButton boton(WidgetTester tester, String tipo) => tester
      .widget<ButtonStyleButton>(find.byKey(ValueKey('accion-$tipo')));

  Future<void> pulsar(WidgetTester tester, String tipo) async {
    final f = find.byKey(ValueKey('accion-$tipo'));
    await tester.ensureVisible(f);
    await tester.tap(f);
    await esperar(tester);
  }

  /// El boton principal del dialogo abierto.
  Future<void> confirmarDialogo(WidgetTester tester, String etiqueta) async {
    final b = find.widgetWithText(FilledButton, etiqueta);
    await tester.ensureVisible(b);
    await tester.tap(b);
    await esperar(tester);
  }

  // ── Las cuatro acciones las da el servidor ───────────────────────────────

  group('acciones habilitadas por botones', () {
    const casos = <String, ({String codigo, Set<String> activas, String estado})>{
      'en la oficina (1000)': (
        codigo: '1000',
        activas: {'fechaCobro'},
        estado: 'PEN',
      ),
      'en cobranza (0101)': (
        codigo: '0101',
        activas: {'devolver', 'cerrarSinVerificacion'},
        estado: 'PEN',
      ),
      'verificado en depositos (0010)': (
        codigo: '0010',
        activas: {'cerrarConVerificacion'},
        estado: 'PEN',
      ),
      'dato inconsistente (0100)': (
        codigo: '0100',
        activas: {'devolver'},
        estado: 'PEN',
      ),
      'sin traspaso (0000)': (codigo: '0000', activas: {}, estado: 'PEN'),
      'cerrado (0000)': (codigo: '0000', activas: {}, estado: 'CER'),
    };
    const todas = [
      'fechaCobro',
      'devolver',
      'cerrarConVerificacion',
      'cerrarSinVerificacion',
    ];

    casos.forEach((nombre, caso) {
      testWidgets('$nombre: exactamente las de botones', (tester) async {
        detalle(caso.codigo, estado: caso.estado);
        await abrir(tester);

        for (final t in todas) {
          expect(
            boton(tester, t).onPressed != null,
            caso.activas.contains(t),
            reason: '$nombre / $t',
          );
        }
      });
    });

    testWidgets('los cuatro botones se dibujan siempre, habilitados o no', (
      tester,
    ) async {
      detalle('0000');
      await abrir(tester);
      for (final (tipo, etiqueta) in [
        ('fechaCobro', 'Fecha de cobro'),
        ('devolver', 'Devolver'),
        ('cerrarConVerificacion', 'Cerrar con verificación'),
        ('cerrarSinVerificacion', 'Cerrar sin verificación'),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('accion-$tipo')),
            matching: find.text(etiqueta),
          ),
          findsOneWidget,
          reason: etiqueta,
        );
      }
    });

    testWidgets('si no hay ninguna, lo dice', (tester) async {
      detalle('0000');
      await abrir(tester);
      expect(
        find.textContaining('Por ahora no hay acciones disponibles'),
        findsOneWidget,
      );
    });

    testWidgets('un cheque cerrado dice que no admite mas acciones', (tester) async {
      detalle('0000', estado: 'CER');
      await abrir(tester);
      expect(find.textContaining('El cheque está cerrado'), findsOneWidget);
    });

    testWidgets('no se calcula en el cliente: lo que dice botones manda', (
      tester,
    ) async {
      // Un cheque cerrado con botones habilitados (algo que el servidor no
      // enviaria): la pantalla dibuja lo que le dicen.
      detalle('1111', estado: 'CER');
      await abrir(tester);
      for (final t in todas) {
        expect(boton(tester, t).onPressed, isNotNull, reason: t);
      }
    });

    testWidgets('«Ir atras» avisa a la pantalla', (tester) async {
      detalle('1000');
      await abrir(tester);
      await tester.tap(find.text('Ir atrás'));
      await esperar(tester);
      expect(volvio, 1);
    });
  });

  // ── Datos e historial ────────────────────────────────────────────────────

  group('ficha e historial', () {
    final acciones = [
      accion(1, 'REC', descripcion: 'RECIBIDO', obs: 'Recibido en caja'),
      accion(2, 'TRASP', descripcion: 'TRASPASO', dia: 2),
      accion(3, 'CUS', descripcion: 'A COBRANZA', dia: 2),
      accion(4, 'DEV', descripcion: 'DEVUELTO', obs: 'No lo recibieron', dia: 3),
      accion(5, 'COB', descripcion: 'COBRADO', nroSap: 'SAP-9988', dia: 4),
      // Un estado fuera del catalogo se muestra igual, con su codigo.
      accion(6, 'XYZ', dia: 5),
    ];

    for (final ancho in [390.0, 1400.0]) {
      testWidgets('muestra el cheque y todo el historial a ${ancho.toInt()} px', (
        tester,
      ) async {
        detalle('0101', acciones: acciones);
        await abrir(tester, ancho: ancho);

        expect(find.text('Cheque 100005'), findsOneWidget);
        expect(find.text('EDITORA MENDEZ'), findsOneWidget);
        expect(find.text('PENDIENTE'), findsOneWidget);
        // La cifra y la moneda (pastilla) van en widgets distintos.
        expect(find.text('1,500.50'), findsOneWidget);
        expect(find.text('Bs'), findsOneWidget);
        expect(find.text('Historial (6)'), findsOneWidget);
        for (final t in [
          'RECIBIDO',
          'TRASPASO',
          'A COBRANZA',
          'DEVUELTO',
          'COBRADO',
        ]) {
          expect(find.text(t), findsOneWidget, reason: t);
        }
        expect(find.text('XYZ'), findsOneWidget);
        expect(find.textContaining('SAP-9988'), findsOneWidget);
        expect(find.text('No lo recibieron'), findsOneWidget);
        // La fecha lleva la hora de la accion.
        expect(find.textContaining('02/08/2026 10:30'), findsWidgets);
      });
    }

    testWidgets('«Editar accion» no se dibuja: el legacy nunca guardo nada', (
      tester,
    ) async {
      detalle('0101', acciones: acciones);
      await abrir(tester);
      expect(find.byTooltip('Editar acción'), findsNothing);
      expect(find.textContaining('Editar acción'), findsNothing);
    });

    testWidgets('un tipo corrupto no se muestra crudo en el detalle', (tester) async {
      repo.alObtenerDetalle =
          (cod) async => ChequeDetalleEntity(
            cheque: chequeFalso(5, tipo: 'BASURA\u0001ÿ', descTipo: null),
            acciones: acciones,
            botones: botones('0000'),
          );
      await abrir(tester);
      expect(find.textContaining('BASURA'), findsNothing);
    });

    testWidgets('sin el cheque (204) avisa en vez de quedar en blanco', (tester) async {
      repo.alObtenerDetalle = (cod) async => null;
      await abrir(tester);
      expect(find.text('No se encontró el cheque'), findsOneWidget);
    });

    testWidgets('si falla, muestra el mensaje del backend y reintenta', (tester) async {
      repo.alObtenerDetalle =
          (cod) async => throw Exception('No tiene habilitado btnDetalleCH.\nLinea 2');
      await abrir(tester);
      expect(find.text('No se pudo cargar el cheque'), findsOneWidget);
      expect(find.text('No tiene habilitado btnDetalleCH.'), findsOneWidget);
      expect(find.text('Linea 2'), findsOneWidget);

      detalle('1000');
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      expect(find.text('Reintentar'), findsNothing);
      expect(find.text('Cheque 100005'), findsOneWidget);
    });
  });

  // ── Eliminar una accion ──────────────────────────────────────────────────

  group('eliminar accion', () {
    final permisosEliminar = permisosCon([
      PermisosCheque.btnDetalle,
      PermisosCheque.btnEliminarAccion,
    ]);

    testWidgets('sin btnEliminarSegCH no hay boton', (tester) async {
      detalle('0101');
      await abrir(tester, permisos: permisosCajero);
      expect(find.byTooltip('Eliminar acción'), findsNothing);
    });

    testWidgets('con el boton, pide confirmacion y elimina', (tester) async {
      detalle('0101');
      await abrir(tester, permisos: permisosEliminar);
      expect(find.byTooltip('Eliminar acción'), findsNWidgets(3));

      // Los tres paneles satelite (notas, transacciones y postergaciones) van
      // entre las acciones y el historial: la fila ya no esta a la vista.
      await tester.ensureVisible(find.byTooltip('Eliminar acción').last);
      await tester.tap(find.byTooltip('Eliminar acción').last);
      await esperar(tester);
      expect(find.text('¿Eliminar esta acción?'), findsOneWidget);
      // Es una accion del circuito: lo dice.
      expect(find.textContaining('cambia las acciones'), findsOneWidget);
      expect(repo.contar('eliminarAccion'), 0);

      await tester.tap(find.text('Eliminar acción'));
      await esperar(tester);
      expect(repo.contar('eliminarAccion'), 1);
      expect(repo.ultimoCuerpo('eliminarAccion'), {'id': 503});
      expect(find.text('Acción eliminada.'), findsOneWidget);
      // Escribir relee el detalle.
      expect(repo.contar('obtenerDetalle'), 2);
    });

    testWidgets('cancelar no elimina nada', (tester) async {
      detalle('0101');
      await abrir(tester, permisos: permisosEliminar);
      await tester.ensureVisible(find.byTooltip('Eliminar acción').first);
      await tester.tap(find.byTooltip('Eliminar acción').first);
      await esperar(tester);
      // El detalle de la recepcion avisa que el cheque deja de verse.
      expect(find.textContaining('deja de aparecer en el listado'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      expect(repo.contar('eliminarAccion'), 0);
    });

    testWidgets('si el servidor rechaza, muestra su mensaje', (tester) async {
      repo.errorEscritura = Exception('Registro No encontrado');
      detalle('0101');
      await abrir(tester, permisos: permisosEliminar);
      await tester.ensureVisible(find.byTooltip('Eliminar acción').first);
      await tester.tap(find.byTooltip('Eliminar acción').first);
      await esperar(tester);
      await tester.tap(find.text('Eliminar acción'));
      await esperar(tester);
      expect(find.text('Registro No encontrado'), findsOneWidget);
      expect(find.text('Acción eliminada.'), findsNothing);
    });

    testWidgets('el administrador tambien puede eliminar', (tester) async {
      detalle('0101');
      await abrir(tester);
      expect(find.byTooltip('Eliminar acción'), findsNWidgets(3));
    });
  });

  // ── Dialogos de las acciones ─────────────────────────────────────────────

  group('devolver', () {
    testWidgets('manda DEV con la fecha de hoy y cierra', (tester) async {
      detalle('0101');
      await abrir(tester);
      await pulsar(tester, 'devolver');
      expect(find.text('Devolver cheque'), findsOneWidget);

      await confirmarDialogo(tester, 'Devolver cheque');

      expect(repo.contar('devolver'), 1);
      final b = repo.ultimoCuerpo('devolver');
      expect(b['codCheque'], 5);
      expect(b['estado'], 'DEV');
      expect(b['fecha'], isoDia(hoy));
      expect(b.containsKey('nroSap'), isFalse);
      expect(b.containsKey('conVerificacion'), isFalse);
      expect(find.text('Devolución registrada.'), findsOneWidget);
      expect(find.text('Devolver cheque'), findsNothing);
    });

    testWidgets('la observacion es opcional pero con formato', (tester) async {
      detalle('0101');
      await abrir(tester);
      await pulsar(tester, 'devolver');

      await tester.enterText(
        find.byKey(const ValueKey('campo-observacion-accion')),
        'x',
      );
      await confirmarDialogo(tester, 'Devolver cheque');
      expect(
        find.text('Letras, números, espacios y , ; : . (de 2 a 200 caracteres).'),
        findsOneWidget,
      );
      expect(repo.contar('devolver'), 0);

      await tester.enterText(
        find.byKey(const ValueKey('campo-observacion-accion')),
        'No lo recibieron en el banco',
      );
      await esperar(tester);
      await confirmarDialogo(tester, 'Devolver cheque');
      expect(
        repo.ultimoCuerpo('devolver')['observacion'],
        'No lo recibieron en el banco',
      );
    });
  });

  group('cerrar', () {
    testWidgets('con verificacion: COB y el nro de SAP es obligatorio', (
      tester,
    ) async {
      detalle('0010');
      await abrir(tester);
      await pulsar(tester, 'cerrarConVerificacion');

      await confirmarDialogo(tester, 'Finalizar cheque');
      expect(
        find.text('Ingresa el nro. de SAP para finalizar el cheque.'),
        findsOneWidget,
      );
      expect(repo.contar('cerrar'), 0);

      await tester.enterText(find.byKey(const ValueKey('campo-nro-sap')), 'SAP 12345');
      await esperar(tester);
      await confirmarDialogo(tester, 'Finalizar cheque');

      expect(repo.contar('cerrar'), 1);
      final b = repo.ultimoCuerpo('cerrar');
      expect(b['estado'], 'COB');
      expect(b['conVerificacion'], isTrue);
      expect(b['nroSap'], 'SAP 12345');
      expect(b['codCheque'], 5);
      expect(find.text('Cheque cerrado.'), findsOneWidget);
    });

    testWidgets('con verificacion el estado es fijo y se ve, bloqueado', (
      tester,
    ) async {
      detalle('0010');
      await abrir(tester);
      await pulsar(tester, 'cerrarConVerificacion');
      expect(find.text('COBRADO'), findsWidgets);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });

    testWidgets('sin verificacion: hay que elegir uno de los cuatro estados', (
      tester,
    ) async {
      detalle('0101');
      await abrir(tester);
      await pulsar(tester, 'cerrarSinVerificacion');

      await tester.enterText(find.byKey(const ValueKey('campo-nro-sap')), 'SAP 777');
      await confirmarDialogo(tester, 'Finalizar cheque');
      expect(find.text('Elige el estado.'), findsOneWidget);
      expect(repo.contar('cerrar'), 0);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await esperar(tester);
      for (final e in [
        'CANJEADO EFECTIVO',
        'CANJEADO CHEQUE',
        'PAGO PARCIAL',
        'DEPOSITADO-RECHAZADO',
      ]) {
        expect(find.text(e), findsWidgets, reason: e);
      }
      await tester.tap(find.text('PAGO PARCIAL').last);
      await esperar(tester);
      await confirmarDialogo(tester, 'Finalizar cheque');

      final b = repo.ultimoCuerpo('cerrar');
      expect(b['estado'], 'PAP');
      expect(b['conVerificacion'], isFalse);
      expect(b['nroSap'], 'SAP 777');
    });

    testWidgets('el nro de SAP tiene formato y largo', (tester) async {
      detalle('0010');
      await abrir(tester);
      await pulsar(tester, 'cerrarConVerificacion');
      await tester.enterText(find.byKey(const ValueKey('campo-nro-sap')), 'AB/12');
      await confirmarDialogo(tester, 'Finalizar cheque');
      expect(
        find.text('Letras, números y espacios (de 2 a 40 caracteres).'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const ValueKey('campo-nro-sap')), 'A');
      await esperar(tester);
      expect(
        find.text('Letras, números y espacios (de 2 a 40 caracteres).'),
        findsOneWidget,
      );
      expect(repo.contar('cerrar'), 0);
    });

    testWidgets('el error del backend se muestra con todas sus lineas', (
      tester,
    ) async {
      repo.errorEscritura = Exception(
        'Verifique que el Cheque Haya salido de Caja y que se diese en Custodia\n'
        'La accion no esta habilitada para este cheque',
      );
      detalle('0010');
      await abrir(tester);
      await pulsar(tester, 'cerrarConVerificacion');
      await tester.enterText(find.byKey(const ValueKey('campo-nro-sap')), 'SAP 1234');
      await esperar(tester);
      await confirmarDialogo(tester, 'Finalizar cheque');

      expect(repo.contar('cerrar'), 1);
      expect(
        find.text(
          'Verifique que el Cheque Haya salido de Caja y que se diese en Custodia',
        ),
        findsOneWidget,
      );
      expect(
        find.text('La accion no esta habilitada para este cheque'),
        findsOneWidget,
      );
      // El dialogo sigue abierto para corregir.
      expect(find.text('Finalizar cheque'), findsWidgets);

      // Se cierra solo cuando sale bien.
      repo.errorEscritura = null;
      await confirmarDialogo(tester, 'Finalizar cheque');
      expect(find.text('Cheque cerrado.'), findsOneWidget);
    });

    testWidgets('cancelar no escribe nada', (tester) async {
      detalle('0010');
      await abrir(tester);
      await pulsar(tester, 'cerrarConVerificacion');
      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      expect(repo.contar('cerrar'), 0);
      expect(find.text('Finalizar cheque'), findsNothing);
    });
  });

  group('fecha de cobro', () {
    Future<void> abrirCalendarioYAceptar(WidgetTester tester) async {
      final f = find.text('Nueva fecha de cobro');
      await tester.ensureVisible(f);
      await tester.tap(f);
      await esperar(tester);
      await tester.tap(find.text('ACEPTAR'));
      await esperar(tester);
    }

    testWidgets('pide estado y nueva fecha; manda VEN/ADE y la nueva fecha', (
      tester,
    ) async {
      detalle('1000');
      await abrir(tester);
      await pulsar(tester, 'fechaCobro');

      await confirmarDialogo(tester, 'Guardar fecha de cobro');
      expect(find.text('Elige el estado.'), findsOneWidget);
      expect(find.text('Indica la fecha.'), findsOneWidget);
      expect(repo.contar('cambiarFechaCobro'), 0);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await esperar(tester);
      expect(find.text('VENCIDO-POSTERGADO'), findsWidgets);
      expect(find.text('ADELANTADO'), findsWidgets);
      await tester.tap(find.text('VENCIDO-POSTERGADO').last);
      await esperar(tester);
      await abrirCalendarioYAceptar(tester);
      await confirmarDialogo(tester, 'Guardar fecha de cobro');

      expect(repo.contar('cambiarFechaCobro'), 1);
      final b = repo.ultimoCuerpo('cambiarFechaCobro');
      expect(b['estado'], 'VEN');
      expect(b['nuevaFechaCobro'], isoDia(hoy));
      expect(b['fecha'], isoDia(hoy));
      expect(b['codCheque'], 5);
      expect(find.text('Fecha de cobro actualizada.'), findsOneWidget);
    });

    testWidgets('sin btnEditar3CH el calendario acota a +-28 dias del cheque', (
      tester,
    ) async {
      detalle('1000');
      await abrir(tester, permisos: permisosCajero);
      await pulsar(tester, 'fechaCobro');

      final fechaCheque = hoy.subtract(const Duration(days: 5));
      final desde = fechaCheque.subtract(const Duration(days: 28));
      final hasta = fechaCheque.add(const Duration(days: 28));
      String f(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      expect(
        find.textContaining('Entre ${f(desde)} y ${f(hasta)}'),
        findsOneWidget,
      );
      // Y se muestra la fecha actual de cobro, de contexto.
      expect(find.textContaining('Fecha de cobro actual'), findsOneWidget);
    });

    testWidgets('con btnEditar3CH no hay tope', (tester) async {
      detalle('1000');
      await abrir(
        tester,
        permisos: permisosCon([
          PermisosCheque.btnDetalle,
          PermisosCheque.btnEditarAdmin,
        ]),
      );
      await pulsar(tester, 'fechaCobro');
      expect(find.textContaining('Entre '), findsNothing);
    });

    testWidgets('el administrador tampoco tiene tope', (tester) async {
      detalle('1000');
      await abrir(tester);
      await pulsar(tester, 'fechaCobro');
      expect(find.textContaining('Entre '), findsNothing);
    });

    testWidgets('el servidor rechaza una accion que la pantalla ofrecia', (
      tester,
    ) async {
      repo.errorEscritura = Exception('No se realizo el Traspaso de Caja, Verificar');
      detalle('1000');
      await abrir(tester);
      await pulsar(tester, 'fechaCobro');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await esperar(tester);
      await tester.tap(find.text('ADELANTADO').last);
      await esperar(tester);
      await abrirCalendarioYAceptar(tester);
      await confirmarDialogo(tester, 'Guardar fecha de cobro');

      expect(
        find.text('No se realizo el Traspaso de Caja, Verificar'),
        findsOneWidget,
      );
      expect(repo.ultimoCuerpo('cambiarFechaCobro')['estado'], 'ADE');
    });
  });

  // ── Sin desbordes ────────────────────────────────────────────────────────

  for (final escala in [1.0, 1.5]) {
    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets(
        'detalle y dialogos sin desborde a ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %',
        (tester) async {
          if (escala != 1.0) conTexto(tester, escala);
          detalle(
            '1111',
            acciones: [
              accion(
                1,
                'REC',
                descripcion: 'RECIBIDO',
                obs: 'Una observacion bastante larga para ver como se acomoda '
                    'en una tarjeta de telefono con el texto grande',
              ),
              accion(2, 'COB', descripcion: 'COBRADO', nroSap: 'SAP 1234567890'),
            ],
          );
          final errores = await capturandoErrores(() async {
            await abrir(tester, ancho: ancho);
            for (final t in [
              'fechaCobro',
              'devolver',
              'cerrarConVerificacion',
              'cerrarSinVerificacion',
            ]) {
              await pulsar(tester, t);
              await tester.tap(find.text('Cancelar'));
              await esperar(tester);
            }
          });
          expect(errores, isEmpty, reason: 'a $ancho');
        },
      );
    }
  }
}
