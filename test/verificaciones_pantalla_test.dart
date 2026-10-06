import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/domain/entities/verificacion_fila_entity.dart';
import 'package:bosque_flutter/presentation/screens/verificaciones/verificar_cheques_screen.dart';

import 'fakes/arnes_verificaciones.dart';
import 'fakes/repositorio_verificaciones.dart';

/// La pantalla «Verificar Cheques» con el repositorio falso: lo que se ve, lo que
/// se pide al servidor y lo que el usuario puede hacer. De 390 a 1800 px y con el
/// texto al 150 %.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  late RepositorioVerificacionesFalso repo;
  final hoy = DateTime(2026, 10, 3);

  setUp(() {
    repo = RepositorioVerificacionesFalso(hoy: hoy);
  });

  Widget pantalla() =>
      appVerificaciones(hijo: const VerificarChequesScreen(), repo: repo);

  /// Una variedad de verificaciones de hoy que estira el diseno: valida y
  /// anulada, en las dos monedas, sin moneda, de un cheque cerrado, con nombres
  /// largos y un numero de cheque con guion.
  List<VerificacionFilaEntity> variadas() => [
    verificacionFalsa(1, monto: 1500.5, observacion: 'Verificado por ventanilla'),
    verificacionFalsa(2, monto: 800, moneda: 'SUS', banco: 'BANCO NACIONAL DE BOLIVIA'),
    verificacionFalsa(3, estado: 'N', observacion: 'Anulada por error de banco'),
    verificacionFalsa(4, monto: 12345678.9, moneda: null, chequeCerrado: true),
    verificacionFalsa(
      5,
      nroCheque: '12-34?56',
      banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890',
      bancoVerificacion: 'BANCO DE CREDITO DE BOLIVIA SOCIEDAD ANONIMA SUCURSAL EL ALTO',
      observacion: 'Observacion larga de cincuenta caracteres justos...',
    ),
  ];

  Finder fila(int codvd) => find.byKey(ValueKey('fila-$codvd'));

  // ── Sin desbordes ────────────────────────────────────────────────────────

  final anchos = [390.0, 600.0, 700.0, 768.0, 800.0, 900.0, 1000.0, 1280.0, 1400.0, 1800.0];
  for (final escala in [1.0, 1.5]) {
    for (final ancho in anchos) {
      testWidgets(
        'no desborda a ${ancho.toInt()} px con texto al ${(escala * 100).toInt()} %',
        (tester) async {
          repo.verificaciones = variadas();
          repo.pendientes = [pendienteFalso(100), pendienteFalso(101, chequeCerrado: true)];
          if (escala != 1.0) conTexto(tester, escala);

          final errores = await capturandoErrores(() async {
            await montar(tester, pantalla(), ancho: ancho);
          });

          expect(errores, isEmpty, reason: 'a $ancho');
          expect(
            // El contenido mide el ancho de la ventana menos el margen (24 a
            // cada lado; 12 en el telefono).
            find.byKey(
              ValueKey(
                ancho - (ancho < 600 ? 24 : 48) >= 720
                    ? 'lista-tabla'
                    : 'lista-tarjetas',
              ),
            ),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('resumen-verificaciones')), findsOneWidget);
          // Ningun scroll horizontal en movil.
          if (ancho - 48 < 720) {
            expect(
              find.byWidgetPredicate(
                (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
              ),
              findsNothing,
            );
          }
        },
      );
    }
  }

  testWidgets('el modal de pendientes tampoco desborda a 390, 768 y 1280 px (150 %)', (tester) async {
    repo.pendientes = [
      pendienteFalso(100, banco: 'Banco Mercantil Santa Cruz - Cuenta corriente 1234567890'),
      pendienteFalso(101, chequeCerrado: true, moneda: null),
      pendienteFalso(102, monto: 99999999.99, moneda: 'SUS'),
    ];
    conTexto(tester, 1.5);
    for (final ancho in [390.0, 768.0, 1280.0]) {
      final errores = await capturandoErrores(() async {
        await montar(tester, pantalla(), ancho: ancho);
        await tester.tap(find.byKey(const ValueKey('boton-verificar-pendientes')));
        await esperar(tester);
      });
      expect(errores, isEmpty, reason: 'a $ancho');
      expect(find.text('Cheques pendientes sin regularizar'), findsOneWidget);
      expect(
        find.byKey(ValueKey(ancho >= 1000 ? 'pendientes-tabla' : 'pendientes-tarjetas')),
        findsOneWidget,
        reason: 'a $ancho',
      );
      // Se cierra para montar el siguiente ancho.
      await tester.tap(find.text('Cerrar'));
      await esperar(tester);
    }
  });

  // ── Lista principal ──────────────────────────────────────────────────────

  group('lista principal', () {
    testWidgets('abre con las verificaciones de hoy, como el legacy', (tester) async {
      repo.verificaciones = [
        verificacionFalsa(1),
        verificacionFalsa(2, fechaBanco: DateTime(2026, 10, 2)),
      ];
      await montar(tester, pantalla());

      expect(repo.consultasListar, hasLength(1));
      expect(repo.consultasListar.single.fechaBanco, DateTime(2026, 10, 3));
      expect(repo.consultasListar.single.pagina, 1);
      expect(fila(1), findsOneWidget);
      expect(fila(2), findsNothing, reason: 'es de ayer');
      expect(find.text('Mostrando las verificaciones del 03/10/2026.'), findsOneWidget);
    });

    testWidgets('cada fila muestra el cheque, su banco, la verificacion y su estado', (tester) async {
      repo.verificaciones = variadas();
      await montar(tester, pantalla(), ancho: 1800);

      // El estado es una pastilla con texto (no solo color).
      expect(find.text('Válida'), findsNWidgets(4));
      expect(find.text('Anulada'), findsOneWidget);
      // Un numero de cheque con guion y signo de pregunta llega como texto.
      expect(find.text('12-34?56'), findsOneWidget);
      // Estado del cheque: el de un cheque cerrado se distingue.
      expect(find.text('CERRADO'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsNWidgets(4));
      expect(find.text('Verificado por ventanilla'), findsOneWidget);
      // Moneda: Bs y $us, y el cheque sin moneda va sin pastilla.
      expect(find.text('Bs'), findsWidgets);
      expect(find.text(r'$us'), findsWidgets);
    });

    testWidgets('el resumen cuenta lo cargado: validas, anuladas y un monto por moneda, sin sumar Bs con \$us', (tester) async {
      repo.verificaciones = [
        verificacionFalsa(1, monto: 1000),
        verificacionFalsa(2, monto: 500.25),
        verificacionFalsa(3, monto: 800, moneda: 'SUS'),
        verificacionFalsa(4, monto: 7777, estado: 'N'),
      ];
      await montar(tester, pantalla(), ancho: 1400);

      Text cifraDe(String clave) => tester.widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey(clave)),
          matching: find.byType(Text),
        ).at(1),
      );
      expect(cifraDe('resumen-total').data, '4');
      expect(cifraDe('resumen-validas').data, '3');
      expect(cifraDe('resumen-anuladas').data, '1');
      // Bs: 1000 + 500.25; $us: 800. La anulada (7777) no suma.
      expect(find.text('1,500.25'), findsOneWidget);
      expect(find.text('800.00'), findsWidgets);
      expect(find.text('9,077.25'), findsNothing, reason: 'nunca se mezclan monedas');
      expect(find.text('9,077.25'), findsNothing);
    });

    testWidgets('con mas de una pagina los numeros del resumen se rotulan «en esta pagina»', (tester) async {
      repo.verificaciones = repetir(45, (i) => verificacionFalsa(i + 1));
      await montar(tester, pantalla(), ancho: 1400);

      expect(find.text('Página 1 de 3 · 45 verificaciones'), findsOneWidget);
      expect(find.text('en esta página'), findsWidgets);
      // Lo mas reciente primero: la primera fila es la de codvd mas alto.
      expect(fila(45), findsOneWidget);
      expect(fila(25), findsNothing, reason: 'es de la pagina 2');

      await tester.ensureVisible(find.byTooltip('Página siguiente'));
      await tester.tap(find.byTooltip('Página siguiente'));
      await esperar(tester);
      expect(repo.consultasListar.last.pagina, 2);
      expect(find.text('Página 2 de 3 · 45 verificaciones'), findsOneWidget);
      expect(fila(25), findsOneWidget);
    });

    testWidgets('una lista vacia no es un error: dice el dia y ofrece ver todas', (tester) async {
      repo.verificaciones = [verificacionFalsa(2, fechaBanco: DateTime(2026, 9, 1))];
      await montar(tester, pantalla());

      expect(find.text('No hay verificaciones del 03/10/2026'), findsOneWidget);

      await tester.tap(find.text('Ver todas las verificaciones'));
      await esperar(tester);
      expect(repo.consultasListar.last.fechaBanco, isNull, reason: 'sin fecha = todas');
      expect(fila(2), findsOneWidget);
      expect(find.text('Mostrando todas las verificaciones, de cualquier fecha.'), findsOneWidget);
    });

    testWidgets('«Hoy» vuelve al dia de hoy y quitar la fecha + «Buscar» pide todas', (tester) async {
      repo.verificaciones = [
        verificacionFalsa(1),
        verificacionFalsa(2, fechaBanco: DateTime(2026, 9, 20)),
      ];
      await montar(tester, pantalla());

      // Quitar la fecha del campo no consulta hasta pulsar «Buscar».
      await tester.tap(find.byTooltip('Quitar Fecha de verificación'));
      await esperar(tester);
      expect(repo.consultasListar, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('boton-buscar')));
      await esperar(tester);
      expect(repo.consultasListar.last.fechaBanco, isNull);
      expect(fila(2), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('boton-hoy')));
      await esperar(tester);
      expect(repo.consultasListar.last.fechaBanco, DateTime(2026, 10, 3));
      expect(fila(2), findsNothing);
    });

    testWidgets('si falla la carga se dice el motivo completo y se puede reintentar', (tester) async {
      repo.errorAlListar = Exception('No se pudo consultar las verificaciones: el servidor no responde.');
      await montar(tester, pantalla());

      expect(find.text('No se pudieron cargar las verificaciones'), findsOneWidget);
      expect(
        find.text('No se pudo consultar las verificaciones: el servidor no responde.'),
        findsOneWidget,
      );

      repo
        ..errorAlListar = null
        ..verificaciones = [verificacionFalsa(1)];
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      expect(fila(1), findsOneWidget);
    });

    testWidgets('la respuesta de una consulta vieja no pisa a la nueva', (tester) async {
      repo.verificaciones = [
        verificacionFalsa(1),
        verificacionFalsa(2, fechaBanco: DateTime(2026, 9, 20)),
      ];
      await montar(tester, pantalla());

      // La consulta de todas las fechas tarda; la de hoy sale enseguida y gana.
      final soltar = Completer<void>();
      repo.antesDeListar = (f) => f.fechaBanco == null ? soltar.future : Future.value();
      await tester.tap(find.byTooltip('Quitar Fecha de verificación'));
      await esperar(tester);
      await tester.tap(find.byKey(const ValueKey('boton-buscar')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('boton-hoy')));
      await esperar(tester);
      soltar.complete();
      await esperar(tester);

      expect(fila(1), findsOneWidget);
      expect(fila(2), findsNothing, reason: 'la consulta vieja (todas) llego tarde y se ignora');
    });
  });

  // ── Anular ───────────────────────────────────────────────────────────────

  group('cancelar (anular)', () {
    testWidgets('pide confirmacion y, al aceptar, la fila queda Anulada (no se borra)', (tester) async {
      repo.verificaciones = [verificacionFalsa(1), verificacionFalsa(2)];
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.descendant(of: fila(2), matching: find.byTooltip('Cancelar verificación')));
      await esperar(tester);
      expect(find.text('Cancelar la verificación'), findsOneWidget);
      expect(find.textContaining('quedará anulada y dejará de valer'), findsOneWidget);
      expect(repo.anulados, isEmpty, reason: 'todavia no se confirmo');

      await tester.tap(find.text('Sí, anular'));
      await esperar(tester);

      expect(repo.anulados, [BigInt.from(2)]);
      expect(fila(2), findsOneWidget, reason: 'sigue en la lista');
      expect(find.text('Anulada'), findsOneWidget);
      expect(find.text('Verificación anulada.'), findsOneWidget);
    });

    testWidgets('«No» no anula nada', (tester) async {
      repo.verificaciones = [verificacionFalsa(1)];
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.byTooltip('Cancelar verificación'));
      await esperar(tester);
      await tester.tap(find.text('No'));
      await esperar(tester);

      expect(repo.anulados, isEmpty);
      expect(find.text('Válida'), findsOneWidget);
    });

    testWidgets('una verificacion ya anulada no ofrece cancelar, pero si editar', (tester) async {
      repo.verificaciones = [verificacionFalsa(1, estado: 'N')];
      await montar(tester, pantalla(), ancho: 1400);

      expect(find.byTooltip('Cancelar verificación'), findsNothing);
      expect(find.byTooltip('Editar'), findsOneWidget);
    });

    testWidgets('si el servidor la rechaza se muestra su mensaje completo', (tester) async {
      repo.verificaciones = [verificacionFalsa(1)];
      repo.errorAlAnular = Exception('No se encontró la verificación 1. Es posible que ya no exista: actualiza la pantalla.');
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.byTooltip('Cancelar verificación'));
      await esperar(tester);
      await tester.tap(find.text('Sí, anular'));
      await esperar(tester);

      expect(
        find.text('No se encontró la verificación 1. Es posible que ya no exista: actualiza la pantalla.'),
        findsOneWidget,
      );
    });

    testWidgets('en el telefono las acciones estan en el menu de la tarjeta', (tester) async {
      repo.verificaciones = [verificacionFalsa(1)];
      await montar(tester, pantalla(), ancho: 390);

      await tester.tap(find.descendant(of: fila(1), matching: find.byTooltip('Acciones')));
      await esperar(tester);
      expect(find.text('Editar'), findsOneWidget);
      await tester.tap(find.text('Cancelar verificación'));
      await esperar(tester);
      expect(find.text('Cancelar la verificación'), findsOneWidget);
    });
  });

  // ── Editar ───────────────────────────────────────────────────────────────

  group('editar', () {
    testWidgets('abre con los datos guardados y manda el cambio con el codvd', (tester) async {
      repo.verificaciones = [
        verificacionFalsa(7, observacion: 'Primera', codBancoVerificacion: 8),
      ];
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.byTooltip('Editar'));
      await esperar(tester);
      expect(find.text('Editar verificación'), findsOneWidget);
      expect(find.byKey(const ValueKey('ficha-cheque')), findsOneWidget);
      // La de la fila y la del campo del formulario.
      expect(find.text('Primera'), findsNWidgets(2));

      await tester.enterText(find.byKey(const ValueKey('campo-observacion-verificacion')), 'Corregida');
      await tester.tap(find.text('Guardar cambios'));
      await esperar(tester);

      expect(repo.registros, hasLength(1));
      final r = repo.registros.single;
      expect(r.codvd, BigInt.from(7));
      expect(r.codBanco, 8);
      expect(r.observacion, 'Corregida');
      expect(r.esAlta, isFalse);
      expect(find.text('Verificación actualizada.'), findsOneWidget);
      expect(find.text('Editar verificación'), findsNothing, reason: 'el dialogo se cerro');
      expect(find.text('Corregida'), findsOneWidget);
    });

    testWidgets('una verificacion anulada avisa que seguira anulada', (tester) async {
      repo.verificaciones = [verificacionFalsa(7, estado: 'N')];
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.byTooltip('Editar'));
      await esperar(tester);
      expect(find.byKey(const ValueKey('nota-anulada')), findsOneWidget);
      expect(find.textContaining('seguirá anulada'), findsOneWidget);
    });
  });

  // ── Nuevo: el modal de pendientes y regularizar ──────────────────────────

  group('nuevo', () {
    testWidgets('abre con lo que abria el legacy: pendientes y fecha de cobranza de hoy', (tester) async {
      repo.pendientes = [
        pendienteFalso(100),
        pendienteFalso(101, fechaCobranza: DateTime(2026, 9, 20)),
      ];
      await montar(tester, pantalla(), ancho: 1400);

      await tester.tap(find.text('Nuevo'));
      await esperar(tester);

      expect(find.text('Cheques pendientes sin regularizar'), findsOneWidget);
      final q = repo.consultasPendientes.last;
      expect(q.estado, 'PEN');
      expect(q.soloCobranzaHoy, isTrue);
      expect(find.byKey(const ValueKey('pendiente-100')), findsOneWidget);
      expect(find.byKey(const ValueKey('pendiente-101')), findsNothing, reason: 'cobranza anterior a hoy');
      expect(find.text('Sin verificar'), findsWidgets);
      expect(find.byKey(const ValueKey('seleccionar-100')), findsOneWidget);
    });

    testWidgets('«Todos (anteriores...)» trae tambien los de cobranza anterior', (tester) async {
      repo.pendientes = [
        pendienteFalso(100),
        pendienteFalso(101, fechaCobranza: DateTime(2026, 9, 20)),
      ];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);

      await tester.tap(find.byKey(const ValueKey('criterio-fecha-true')));
      await esperar(tester);
      await tester.tap(find.text('Todos (anteriores y con fecha de cobranza hasta hoy)').last);
      await esperar(tester);

      expect(repo.consultasPendientes.last.soloCobranzaHoy, isFalse);
      expect(find.byKey(const ValueKey('pendiente-101')), findsOneWidget);
      expect(find.byKey(const ValueKey('pendiente-100')), findsOneWidget);
    });

    testWidgets('el estado «Todos» no manda estado y deja ver un cheque cerrado, que no se puede elegir', (tester) async {
      repo.pendientes = [
        pendienteFalso(100),
        pendienteFalso(101, chequeCerrado: true),
      ];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);
      expect(find.byKey(const ValueKey('pendiente-101')), findsNothing, reason: 'por defecto solo pendientes');

      await tester.tap(find.byKey(const ValueKey('criterio-estado-PEN-2')));
      await esperar(tester);
      await tester.tap(find.text('Todos').last);
      await esperar(tester);

      expect(repo.consultasPendientes.last.estado, isNull);
      expect(find.byKey(const ValueKey('pendiente-101')), findsOneWidget);
      // El cerrado no ofrece «Seleccionar»: dice que esta cerrado.
      expect(find.byKey(const ValueKey('seleccionar-101')), findsNothing);
      expect(find.text('Cerrado'), findsOneWidget);
      expect(find.byKey(const ValueKey('seleccionar-100')), findsOneWidget);
    });

    testWidgets('seleccionar un cheque abre «Cheque a regularizar» con su banco y la fecha de hoy', (tester) async {
      repo.pendientes = [pendienteFalso(100, nroCheque: '7788', banco: 'BANCO MERCANTIL', codBanco: 8)];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);

      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);

      expect(repo.preparados, [BigInt.from(100)]);
      expect(find.text('Cheque a regularizar'), findsOneWidget);
      expect(find.text('Cheque 7788 · BANCO MERCANTIL'), findsOneWidget);
      expect(find.text('03/10/2026'), findsWidgets, reason: 'la fecha propuesta es hoy');
    });

    testWidgets('guardar registra la verificacion, refresca las dos listas y el modal sigue abierto', (tester) async {
      repo.pendientes = [pendienteFalso(100), pendienteFalso(101)];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);
      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);

      await tester.enterText(
        find.byKey(const ValueKey('campo-observacion-verificacion')),
        "Cobrado en ventanilla, sin novedad",
      );
      await tester.tap(find.text('Guardar verificación'));
      await esperar(tester);

      expect(repo.registros, hasLength(1));
      final r = repo.registros.single;
      expect(r.codvd, BigInt.zero, reason: 'es un alta');
      expect(r.esAlta, isTrue);
      expect(r.codCheque, BigInt.from(100));
      expect(r.codBanco, 7, reason: 'el banco del cheque, propuesto');
      expect(r.fechaBanco, DateTime(2026, 10, 3));
      expect(r.observacion, 'Cobrado en ventanilla, sin novedad');

      expect(find.text('Verificación registrada.'), findsOneWidget);
      expect(find.text('Cheque a regularizar'), findsNothing);
      // El modal sigue abierto y ya no ofrece el cheque verificado.
      expect(find.text('Cheques pendientes sin regularizar'), findsOneWidget);
      expect(find.byKey(const ValueKey('seleccionar-100')), findsNothing);
      expect(find.byKey(const ValueKey('seleccionar-101')), findsOneWidget);

      // La lista de atras tambien se refresco: aparece la verificacion nueva.
      await tester.tap(find.text('Cerrar'));
      await esperar(tester);
      expect(find.text('Válida'), findsOneWidget);
    });

    testWidgets('una observacion con tilde o ñ se rechaza antes de enviar y dice cuales sobran', (tester) async {
      repo.pendientes = [pendienteFalso(100)];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);
      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);

      await tester.enterText(
        find.byKey(const ValueKey('campo-observacion-verificacion')),
        'Depósito del año',
      );
      await tester.tap(find.text('Guardar verificación'));
      await esperar(tester);

      expect(repo.registros, isEmpty, reason: 'no se envia con un campo en rojo');
      expect(find.textContaining('«ó», «ñ»'), findsOneWidget);
      expect(find.textContaining('Solo acepta letras sin tilde ni ñ'), findsWidgets);
      expect(find.text('Cheque a regularizar'), findsOneWidget);
    });

    testWidgets('el campo de observacion no pasa de 50 caracteres', (tester) async {
      repo.pendientes = [pendienteFalso(100)];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);
      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);

      await tester.enterText(
        find.byKey(const ValueKey('campo-observacion-verificacion')),
        'x' * 80,
      );
      await tester.pump();
      final campo = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('campo-observacion-verificacion')),
          matching: find.byType(TextField),
        ),
      );
      expect(campo.controller!.text.length, 50);
      expect(find.text('50/50'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza el guardado, su mensaje queda junto al formulario y el dialogo sigue abierto', (tester) async {
      repo.pendientes = [pendienteFalso(100)];
      repo.errorAlRegistrar = Exception(
        'El cheque 480100 ya tiene una verificación válida.\nActualiza la lista.',
      );
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);
      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);

      await tester.tap(find.text('Guardar verificación'));
      await esperar(tester);

      expect(find.text('El cheque 480100 ya tiene una verificación válida.'), findsOneWidget);
      expect(find.text('Actualiza la lista.'), findsOneWidget);
      expect(find.text('Cheque a regularizar'), findsOneWidget);
    });

    testWidgets('si el cheque ya no se puede verificar, el motivo se ve en el modal y la lista se refresca', (tester) async {
      repo.pendientes = [pendienteFalso(100), pendienteFalso(101)];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);

      // Otro usuario verifico el 100 mientras esta lista estaba abierta.
      repo.pendientes = [pendienteFalso(101)];
      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);

      expect(find.textContaining('ya tiene una verificación válida o no existe'), findsOneWidget);
      expect(find.text('Cheque a regularizar'), findsNothing);
      expect(find.byKey(const ValueKey('seleccionar-100')), findsNothing, reason: 'la lista se refresco');
      expect(find.byKey(const ValueKey('seleccionar-101')), findsOneWidget);
    });

    testWidgets('sin cheques pendientes dice por que y que hacer', (tester) async {
      repo.pendientes = [];
      await montar(tester, pantalla(), ancho: 1400);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);

      expect(find.text('No hay cheques pendientes de verificar con esos criterios'), findsOneWidget);
      expect(find.textContaining('No hay cheques con fecha de cobranza de hoy'), findsOneWidget);
    });

    testWidgets('si la lista de bancos falla, el formulario lo dice y deja reintentar', (tester) async {
      repo.pendientes = [pendienteFalso(100)];
      var intentos = 0;
      await tester.pumpWidget(
        appVerificaciones(
          hijo: const VerificarChequesScreen(),
          repo: repo,
          listaDeBancos: () async {
            intentos++;
            if (intentos == 1) throw Exception('El servidor de bancos no responde.');
            return bancosFalsos;
          },
        ),
      );
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await esperar(tester);
      await tester.tap(find.text('Nuevo'));
      await esperar(tester);
      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);

      expect(find.textContaining('No se pudieron cargar los bancos'), findsOneWidget);
      expect(find.textContaining('El servidor de bancos no responde.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      expect(find.textContaining('No se pudieron cargar los bancos'), findsNothing);
      expect(find.text('Banco de la verificación'), findsOneWidget);
    });
  });

  // ── Cuanto falta por verificar ───────────────────────────────────────────

  group('aviso de cheques sin verificar', () {
    testWidgets('dice cuantos faltan (pendientes con cobranza hasta hoy) y abre el modal', (tester) async {
      repo.pendientes = [
        pendienteFalso(100),
        pendienteFalso(101, fechaCobranza: DateTime(2026, 9, 20)),
        pendienteFalso(102, fechaCobranza: DateTime(2026, 11, 1)),
        pendienteFalso(103, chequeCerrado: true),
      ];
      await montar(tester, pantalla(), ancho: 1400);

      // 100 y 101: pendientes con cobranza de hoy o anterior. El 102 es futuro y
      // el 103 esta cerrado.
      expect(find.text('2 cheques pendientes sin verificar'), findsOneWidget);
      final q = repo.consultasPendientes.first;
      expect(q.estado, 'PEN');
      expect(q.soloCobranzaHoy, isFalse);
      expect(q.tamanio, 1, reason: 'solo se pide una fila: lo que importa es el total');

      await tester.tap(find.byKey(const ValueKey('boton-verificar-pendientes')));
      await esperar(tester);
      expect(find.text('Cheques pendientes sin regularizar'), findsOneWidget);
    });

    testWidgets('sin pendientes lo dice en positivo y no ofrece el boton', (tester) async {
      repo.pendientes = [];
      await montar(tester, pantalla(), ancho: 1400);

      expect(find.text('No hay cheques pendientes sin verificar'), findsOneWidget);
      expect(find.byKey(const ValueKey('boton-verificar-pendientes')), findsNothing);
    });

    testWidgets('si la consulta falla no se dibuja nada: no es un dato inventado', (tester) async {
      repo.errorAlListarPendientes = Exception('caido');
      repo.verificaciones = [verificacionFalsa(1)];
      await montar(tester, pantalla(), ancho: 1400);

      expect(find.byKey(const ValueKey('aviso-sin-verificar')), findsNothing);
      expect(fila(1), findsOneWidget, reason: 'la lista principal sigue');
    });

    testWidgets('despues de registrar baja el contador', (tester) async {
      repo.pendientes = [pendienteFalso(100), pendienteFalso(101)];
      await montar(tester, pantalla(), ancho: 1400);
      expect(find.text('2 cheques pendientes sin verificar'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('boton-verificar-pendientes')));
      await esperar(tester);
      await tester.tap(find.byKey(const ValueKey('seleccionar-100')));
      await esperar(tester);
      await tester.tap(find.text('Guardar verificación'));
      await esperar(tester);
      await tester.tap(find.text('Cerrar'));
      await esperar(tester);

      expect(find.text('1 cheque pendiente sin verificar'), findsOneWidget);
    });
  });

  // ── Diseno ───────────────────────────────────────────────────────────────

  test('los widgets de verificaciones no escriben colores a mano', () {
    final carpeta = Directory('lib/presentation/widgets/verificaciones');
    final archivos = [
      ...carpeta.listSync().whereType<File>().where((f) => f.path.endsWith('.dart')),
      File('lib/presentation/screens/verificaciones/verificar_cheques_screen.dart'),
    ];
    expect(archivos, isNotEmpty);
    final prohibido = RegExp(
      r'Color\(\s*0x|Color\.fromARGB|Color\.fromRGBO|Colors\.(?!black\b|white\b|transparent\b)\w+',
    );
    for (final a in archivos) {
      final sinComentarios = a
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(
        prohibido.hasMatch(sinComentarios),
        isFalse,
        reason: '${a.path} escribe un color a mano: ${prohibido.firstMatch(sinComentarios)?.group(0)}',
      );
    }
  });
}
