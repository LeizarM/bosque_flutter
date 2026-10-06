import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bosque_flutter/core/state/cheques_provider.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';
import 'package:bosque_flutter/presentation/screens/cheques/cheques_screen.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/aviso_talonario_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/formulario_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

import 'fakes/arnes_cheques.dart';
import 'fakes/repositorio_cheques.dart';

/// La linea de estado que avisa, mientras se escribe, si el par talonario /
/// recibo no corresponde a un talonario de la empresa. Es un aviso temprano:
/// nunca bloquea el guardado.
///
/// El tiempo se maneja con `tester.pump(Duration)`; no hay esperas reales. Para
/// no disparar el debounce sin querer, aqui se escribe con [teclear] (sin pasar
/// por `esperar`, que deja correr 600 ms).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);

  // El caso real que origino el cambio: un talonario de IMPEXPAP usado en un
  // cheque de ESPPAPEL.
  const mensajeReal =
      'El talonario «ER1076» no pertenece a la empresa ESPPAPEL: está '
      'registrado en la empresa IMPEXPAP (y el recibo 3752 sí está dentro de su '
      'numeración, 3751 a 3800), y este cheque se está registrando en '
      'ESPPAPEL. Cambia la empresa en los filtros o usa un talonario de '
      'ESPPAPEL.';

  // El mismo motivo en varias lineas, para ver que no se recorta ninguna.
  const mensajeVariasLineas =
      'El talonario «ER1076» no pertenece a la empresa ESPPAPEL.\n'
      'Está registrado en la empresa IMPEXPAP: el recibo 3752 sí está dentro de '
      'su numeración (3751 a 3800).\n'
      'Este cheque se está registrando en ESPPAPEL.\n'
      'Cambia la empresa en los filtros o usa un talonario de ESPPAPEL.';

  const detalleReal = 'Talonario ER1076 (IMPEXPAP): recibos del 3751 al 3800.';

  const invalido = TalonarioValidacionEntity(
    valido: false,
    mensaje: mensajeReal,
  );
  const valido = TalonarioValidacionEntity(valido: true, detalle: detalleReal);

  const medioSegundo = Duration(milliseconds: 600);

  late RepositorioChequesFalso repo;

  setUp(() {
    repo = RepositorioChequesFalso()
      ..clientes = [clienteDeCheque('C1', 'EDITORA MENDEZ')]
      ..personal = const [
        PersonalChequeEntity(codEmpleado: 12, nombreCompleto: 'JUAN PEREZ'),
      ];
  });

  // ── Ayudas ───────────────────────────────────────────────────────────────

  Widget abridor(ModoRegistroCheque modo, {ChequeFilaEntity? existente}) =>
      appCheques(
        repo: repo,
        hijo: Builder(
          builder:
              (context) => Center(
                child: ElevatedButton(
                  onPressed:
                      () => abrirFormularioCheque(
                        context,
                        modo: modo,
                        codSucursal: 3,
                        existente: existente,
                      ),
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

  Finder editable(String id) => find.byKey(ValueKey('editable-$id'));
  Finder entrada(String id) =>
      find.descendant(of: editable(id), matching: find.byType(TextFormField));

  /// Escribe sin dejar correr el reloj: el debounce arranca desde aqui.
  Future<void> teclear(WidgetTester tester, String id, String valor) async {
    await tester.ensureVisible(entrada(id));
    await tester.enterText(entrada(id), valor);
    await tester.pump();
  }

  /// Escribe el par y deja que el debounce dispare la consulta y su respuesta
  /// se dibuje.
  Future<void> parYComprobar(
    WidgetTester tester, {
    String talonario = 'ER1076',
    String recibo = '3752',
  }) async {
    await teclear(tester, 'talonario', talonario);
    await teclear(tester, 'recibo', recibo);
    await tester.pump(medioSegundo);
    await tester.pump();
  }

  /// Hay una linea de estado de esta fase y ninguna otra.
  void soloEsta(Key? clave) {
    for (final k in [
      claveAvisoTalonarioComprobando,
      claveAvisoTalonarioValido,
      claveAvisoTalonarioInvalido,
      claveAvisoTalonarioNoComprobado,
    ]) {
      expect(
        find.byKey(k),
        k == clave ? findsOneWidget : findsNothing,
        reason: '$k',
      );
    }
  }

  ChequeFilaEntity chequeConPar({
    String talonario = 'ER1076',
    String recibo = '3752',
    int codEmpresa = 1,
    int codSucursal = 3,
    String estado = 'PEN',
  }) => chequeFalso(
    5,
    estado: estado,
    descTipo: 'PAGO',
    codEmpresa: codEmpresa,
    codSucursal: codSucursal,
    fechaCheque: '2026-08-10',
    fechaCobrar: '2026-08-20',
    aOrdenDe: 'BOSQUE SA',
    codEmpleado: 12,
    datoEmpleado: ' - JUAN PEREZ -',
    nroTalonario: talonario,
    reciboManual: recibo,
  );

  FilledButton botonGuardar(WidgetTester tester, String etiqueta) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, etiqueta));

  // ── (b) El par valido dispara una consulta y muestra el detalle ──────────

  group('el par valido', () {
    testWidgets(
      'tras 600 ms sin teclas consulta UNA vez, recortado y con la empresa del formulario',
      (tester) async {
        repo.respuestaTalonario = valido;
        await abrir(tester, ModoRegistroCheque.estandar);

        await teclear(tester, 'talonario', '  ER1076 ');
        await teclear(tester, 'recibo', ' 3752  ');

        // Mientras espera: «Comprobando…» y nada consultado todavia.
        soloEsta(claveAvisoTalonarioComprobando);
        expect(find.text('Comprobando talonario…'), findsOneWidget);
        expect(repo.consultasTalonario, isEmpty);
        await tester.pump(const Duration(milliseconds: 599));
        expect(repo.consultasTalonario, isEmpty);

        await tester.pump(const Duration(milliseconds: 1));
        expect(repo.consultasTalonario, hasLength(1));
        // Respuesta en camino: sigue «Comprobando…».
        await tester.pump();

        expect(repo.consultasTalonario.single, (
          codEmpresa: 1,
          nroTalonario: 'ER1076',
          reciboManual: '3752',
        ));
        soloEsta(claveAvisoTalonarioValido);
        expect(find.text(detalleReal), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

        // Nada mas se consulta solo.
        await tester.pump(const Duration(seconds: 5));
        expect(repo.consultasTalonario, hasLength(1));
        expect(repo.contar('validarTalonario'), 1);
      },
    );

    testWidgets('mientras responde el servidor se ve «Comprobando…»', (
      tester,
    ) async {
      repo
        ..respuestaTalonario = valido
        ..demoraTalonario = const Duration(milliseconds: 300);
      await abrir(tester, ModoRegistroCheque.estandar);
      await teclear(tester, 'talonario', 'ER1076');
      await teclear(tester, 'recibo', '3752');

      await tester.pump(medioSegundo);
      expect(repo.consultasTalonario, hasLength(1));
      await tester.pump(const Duration(milliseconds: 200));
      soloEsta(claveAvisoTalonarioComprobando);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      soloEsta(claveAvisoTalonarioValido);
    });

    testWidgets('valido sin detalle no muestra nada', (tester) async {
      repo.respuestaTalonario = TalonarioValidacionEntity.sinObjeciones;
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);

      expect(repo.consultasTalonario, hasLength(1));
      soloEsta(null);
    });

    testWidgets('un formulario recien abierto no muestra nada ni consulta', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await tester.pump(const Duration(seconds: 5));
      soloEsta(null);
      expect(repo.consultasTalonario, isEmpty);
    });
  });

  // ── (c) El caso real: se ve completo ─────────────────────────────────────

  group('el par invalido', () {
    testWidgets('el motivo de ER1076 en ESPPAPEL se ve entero, en tono de error', (
      tester,
    ) async {
      repo.respuestaTalonario = invalido;
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);

      soloEsta(claveAvisoTalonarioInvalido);
      final texto = find.text(mensajeReal);
      expect(texto, findsOneWidget);
      final t = tester.widget<Text>(texto);
      expect(t.maxLines, isNull);
      expect(t.overflow, isNull);
      expect(t.softWrap, isNull);

      // El tono de error del tema, con su icono.
      final cs = Theme.of(tester.element(texto)).colorScheme;
      final recuadro = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(claveAvisoTalonarioInvalido),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((recuadro.decoration! as BoxDecoration).color, cs.errorContainer);
      expect(t.style?.color, cs.onErrorContainer);
      expect(
        find.descendant(
          of: find.byKey(claveAvisoTalonarioInvalido),
          matching: find.byIcon(Icons.error_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('un mensaje de varias lineas conserva todas', (tester) async {
      repo.respuestaTalonario = const TalonarioValidacionEntity(
        valido: false,
        mensaje: mensajeVariasLineas,
      );
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);

      expect(find.text(mensajeVariasLineas), findsOneWidget);
      // Cada linea esta en pantalla: el texto no se recorta con puntos
      // suspensivos ni se limita a un maximo de renglones.
      final render = tester.renderObject<RenderParagraph>(
        find.text(mensajeVariasLineas),
      );
      expect(render.didExceedMaxLines, isFalse);
      expect(render.text.toPlainText(), mensajeVariasLineas);
      expect(render.size.height, greaterThan(render.text.style!.fontSize! * 3));
    });

    testWidgets('sin motivo dice algo en vez de quedarse en blanco', (
      tester,
    ) async {
      repo.respuestaTalonario = const TalonarioValidacionEntity(valido: false);
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);

      soloEsta(claveAvisoTalonarioInvalido);
      expect(find.text(textoTalonarioSinMotivo), findsOneWidget);
    });

    testWidgets('(h) un par invalido no deshabilita Registrar ni Guardar', (
      tester,
    ) async {
      repo.respuestaTalonario = invalido;
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);
      soloEsta(claveAvisoTalonarioInvalido);
      expect(botonGuardar(tester, 'Registrar cheque').onPressed, isNotNull);
    });

    testWidgets('el guardado sigue en manos del servidor aunque el aviso diga invalido', (
      tester,
    ) async {
      repo.respuestaTalonario = invalido;
      repo.errorEscritura = Exception(mensajeReal);
      await abrir(
        tester,
        ModoRegistroCheque.talonario,
        existente: chequeConPar(estado: 'CER'),
      );
      // Otro par que el guardado: escribir el mismo texto no cambia nada.
      await parYComprobar(tester, talonario: 'ER1077', recibo: '3760');
      soloEsta(claveAvisoTalonarioInvalido);

      final boton = find.widgetWithText(FilledButton, 'Guardar cambios');
      await tester.ensureVisible(boton);
      await tester.tap(boton);
      await esperar(tester);

      // El formulario no lo freno: pidio guardar y el error del servidor sale
      // en su banner de siempre.
      expect(repo.contar('registrar'), 1);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.text(mensajeReal), findsWidgets);
    });
  });

  // ── (d) Teclear rapido: una sola consulta, la ultima ─────────────────────

  group('rapidez y respuestas tardias', () {
    testWidgets('teclear rapido manda una sola consulta, la del ultimo valor', (
      tester,
    ) async {
      repo.respuestaTalonario = valido;
      await abrir(tester, ModoRegistroCheque.estandar);

      await teclear(tester, 'talonario', 'ER1076');
      for (final r in ['3', '37', '375', '3752']) {
        await teclear(tester, 'recibo', r);
        await tester.pump(const Duration(milliseconds: 200));
      }
      // Cada tecla reinicio la espera: todavia no salio nada.
      expect(repo.consultasTalonario, isEmpty);
      soloEsta(claveAvisoTalonarioComprobando);

      await tester.pump(medioSegundo);
      await tester.pump();
      expect(repo.consultasTalonario, hasLength(1));
      expect(repo.consultasTalonario.single.reciboManual, '3752');
      soloEsta(claveAvisoTalonarioValido);
    });

    testWidgets('la respuesta tardia de una consulta vieja no pisa a la nueva', (
      tester,
    ) async {
      final pendientes = <Completer<TalonarioValidacionEntity>>[];
      repo.alValidarTalonario = (_, _, _) {
        final c = Completer<TalonarioValidacionEntity>();
        pendientes.add(c);
        return c.future;
      };
      await abrir(tester, ModoRegistroCheque.estandar);

      await teclear(tester, 'talonario', 'ER1076');
      await teclear(tester, 'recibo', '3752');
      await tester.pump(medioSegundo);
      expect(pendientes, hasLength(1));

      // El usuario corrige el recibo con la primera consulta todavia en vuelo.
      await teclear(tester, 'recibo', '3753');
      await tester.pump(medioSegundo);
      expect(pendientes, hasLength(2));
      expect(repo.consultasTalonario.map((c) => c.reciboManual), [
        '3752',
        '3753',
      ]);

      // Responde primero la nueva...
      pendientes[1].complete(valido);
      await tester.pump();
      soloEsta(claveAvisoTalonarioValido);

      // ...y la vieja llega tarde, diciendo otra cosa: se ignora.
      pendientes[0].complete(invalido);
      await tester.pump();
      soloEsta(claveAvisoTalonarioValido);
      expect(find.text(mensajeReal), findsNothing);
      expect(find.text(detalleReal), findsOneWidget);
    });

    testWidgets('una respuesta vieja tampoco apaga el «Comprobando…» de la nueva', (
      tester,
    ) async {
      final pendientes = <Completer<TalonarioValidacionEntity>>[];
      repo.alValidarTalonario = (_, _, _) {
        final c = Completer<TalonarioValidacionEntity>();
        pendientes.add(c);
        return c.future;
      };
      await abrir(tester, ModoRegistroCheque.estandar);
      await teclear(tester, 'talonario', 'ER1076');
      await teclear(tester, 'recibo', '3752');
      await tester.pump(medioSegundo);
      expect(pendientes, hasLength(1));

      // Cambia el recibo y, antes de que salga la segunda, llega la primera.
      await teclear(tester, 'recibo', '3753');
      pendientes[0].complete(invalido);
      await tester.pump();

      soloEsta(claveAvisoTalonarioComprobando);
      expect(find.text(mensajeReal), findsNothing);

      await tester.pump(medioSegundo);
      pendientes[1].complete(valido);
      await tester.pump();
      soloEsta(claveAvisoTalonarioValido);
    });

    testWidgets('la respuesta de un par que ya quedo vacio se descarta', (
      tester,
    ) async {
      final pendientes = <Completer<TalonarioValidacionEntity>>[];
      repo.alValidarTalonario = (_, _, _) {
        final c = Completer<TalonarioValidacionEntity>();
        pendientes.add(c);
        return c.future;
      };
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);
      expect(pendientes, hasLength(1));

      await teclear(tester, 'recibo', '0');
      pendientes[0].complete(invalido);
      await tester.pump();
      soloEsta(null);
    });
  });

  // ── (e) y (f) Cuando NO se consulta ──────────────────────────────────────

  group('cuando no hay nada que comprobar', () {
    for (final (campo, valor, porque) in const [
      ('recibo', '0', 'recibo 0'),
      ('recibo', '', 'recibo vacio'),
      ('recibo', '   ', 'recibo de espacios'),
      ('talonario', '0', 'talonario 0'),
      ('talonario', '', 'talonario vacio'),
    ]) {
      testWidgets('$porque: limpia la linea y no consulta mas', (tester) async {
        repo.respuestaTalonario = invalido;
        await abrir(tester, ModoRegistroCheque.estandar);
        await parYComprobar(tester);
        soloEsta(claveAvisoTalonarioInvalido);
        expect(repo.consultasTalonario, hasLength(1));

        await teclear(tester, campo, valor);
        // Se limpia al instante, sin esperar los 600 ms.
        soloEsta(null);
        await tester.pump(const Duration(seconds: 3));
        soloEsta(null);
        expect(repo.consultasTalonario, hasLength(1));
      });

      testWidgets('$porque con la espera pendiente: la cancela', (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar);
        await teclear(tester, 'talonario', 'ER1076');
        await teclear(tester, 'recibo', '3752');
        soloEsta(claveAvisoTalonarioComprobando);
        await tester.pump(const Duration(milliseconds: 300));

        await teclear(tester, campo, valor);
        soloEsta(null);
        await tester.pump(const Duration(seconds: 3));
        expect(repo.consultasTalonario, isEmpty);
        soloEsta(null);
      });
    }

    testWidgets('los dos en 0 (como abre el alta) no consulta', (tester) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await teclear(tester, 'talonario', '0');
      await teclear(tester, 'recibo', '0');
      await tester.pump(const Duration(seconds: 3));
      expect(repo.consultasTalonario, isEmpty);
      soloEsta(null);
    });

    for (final (talonario, recibo, porque) in const <(String, String, String)>[
      ('ER-1076', '3752', 'el guion no entra en el talonario'),
      ('ER/1076', '3752', 'la barra no entra en el talonario'),
      ('ER1076', '37/52', 'la barra no entra en el recibo'),
      ('ER1076', '3752.5', 'el punto no entra en el recibo'),
    ]) {
      testWidgets('formato invalido ($porque): no consulta', (tester) async {
        await abrir(tester, ModoRegistroCheque.estandar);
        await teclear(tester, 'talonario', talonario);
        await teclear(tester, 'recibo', recibo);
        soloEsta(null);
        await tester.pump(const Duration(seconds: 3));
        expect(repo.consultasTalonario, isEmpty);
        soloEsta(null);
      });
    }

    testWidgets('al corregir el formato si consulta', (tester) async {
      repo.respuestaTalonario = valido;
      await abrir(tester, ModoRegistroCheque.estandar);
      await teclear(tester, 'talonario', 'ER-1076');
      await teclear(tester, 'recibo', '3752');
      await tester.pump(const Duration(seconds: 2));
      expect(repo.consultasTalonario, isEmpty);

      await teclear(tester, 'talonario', 'ER1076');
      await tester.pump(medioSegundo);
      await tester.pump();
      expect(repo.consultasTalonario, hasLength(1));
      soloEsta(claveAvisoTalonarioValido);
    });
  });

  // ── (g) Si la consulta falla: aviso neutro, sin rojo, sin bloquear ───────

  group('si la consulta falla', () {
    for (final (nombre, error) in <(String, Object)>[
      ('de red', Exception('No se pudo conectar con el servidor.')),
      ('400', Exception('La empresa no es una de las empresas de cheques.')),
      (
        '403',
        Exception('No tiene permiso para registrar ni editar cheques.'),
      ),
    ]) {
      testWidgets('error $nombre: aviso neutro y Registrar sigue habilitado', (
        tester,
      ) async {
        repo.errorTalonario = error;
        await abrir(tester, ModoRegistroCheque.estandar);
        await parYComprobar(tester);

        soloEsta(claveAvisoTalonarioNoComprobado);
        expect(
          find.text(
            'No se pudo comprobar el talonario ahora; se validará al guardar.',
          ),
          findsOneWidget,
        );
        // No muestra el error del servidor, ni en rojo ni de ninguna forma.
        expect(find.textContaining('No se pudo conectar'), findsNothing);
        expect(find.textContaining('no es una de las empresas'), findsNothing);
        expect(find.textContaining('No tiene permiso'), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
        final aviso = find.byKey(claveAvisoTalonarioNoComprobado);
        expect(
          find.descendant(of: aviso, matching: find.byIcon(Icons.error_outline)),
          findsNothing,
        );
        expect(
          find.descendant(of: aviso, matching: find.byType(Container)),
          findsNothing,
          reason: 'sin recuadro de error',
        );
        // El color del texto no es el del error del tema.
        final cs = Theme.of(tester.element(aviso)).colorScheme;
        final textos = tester.widgetList<Text>(
          find.descendant(of: aviso, matching: find.byType(Text)),
        );
        for (final t in textos) {
          expect(t.style?.color, isNot(cs.error));
          expect(t.style?.color, isNot(cs.onErrorContainer));
        }

        expect(botonGuardar(tester, 'Registrar cheque').onPressed, isNotNull);
      });
    }

    testWidgets('al volver a escribir se reintenta y el aviso se va', (
      tester,
    ) async {
      repo.errorTalonario = Exception('sin red');
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);
      soloEsta(claveAvisoTalonarioNoComprobado);

      repo
        ..errorTalonario = null
        ..respuestaTalonario = valido;
      await teclear(tester, 'recibo', '3753');
      await tester.pump(medioSegundo);
      await tester.pump();
      soloEsta(claveAvisoTalonarioValido);
      expect(repo.consultasTalonario, hasLength(2));
    });

    testWidgets('el error de la consulta no toca el banner del guardado', (
      tester,
    ) async {
      repo.errorTalonario = Exception('sin red');
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);
      // El banner de error del servidor (de una escritura) sigue siendo suyo.
      expect(find.byType(ErrorServidorCheque), findsNothing);
      expect(
        ProviderScope.containerOf(
          tester.element(find.text('Registrar cheque').first),
        ).read(operacionesChequesProvider).error,
        isNull,
      );
    });
  });

  // ── (i) Edicion: no consulta al abrir, si al tocar un campo ──────────────

  group('edicion', () {
    testWidgets('con talonario y recibo ya cargados no consulta al abrir', (
      tester,
    ) async {
      repo.respuestaTalonario = invalido;
      await abrir(
        tester,
        ModoRegistroCheque.estandar,
        existente: chequeConPar(),
      );
      // Los dos campos traen lo guardado.
      expect(
        tester.widget<TextFormField>(entrada('talonario')).controller!.text,
        'ER1076',
      );
      expect(
        tester.widget<TextFormField>(entrada('recibo')).controller!.text,
        '3752',
      );

      await tester.pump(const Duration(seconds: 5));
      expect(repo.consultasTalonario, isEmpty);
      soloEsta(null);
    });

    testWidgets('al tocar uno de los dos campos, consulta con los dos valores', (
      tester,
    ) async {
      repo.respuestaTalonario = valido;
      await abrir(
        tester,
        ModoRegistroCheque.estandar,
        existente: chequeConPar(),
      );

      await teclear(tester, 'talonario', 'ER1077');
      soloEsta(claveAvisoTalonarioComprobando);
      await tester.pump(medioSegundo);
      await tester.pump();

      expect(repo.consultasTalonario, hasLength(1));
      expect(repo.consultasTalonario.single, (
        codEmpresa: 1,
        nroTalonario: 'ER1077',
        reciboManual: '3752',
      ));
      soloEsta(claveAvisoTalonarioValido);
    });

    testWidgets(
      'sin tocar los campos, ni un cambio de la empresa activa dispara la consulta',
      (tester) async {
        // Un cheque sin empresa propia usa la activa de la pantalla.
        await abrir(
          tester,
          ModoRegistroCheque.estandar,
          existente: chequeConPar(codEmpresa: 0),
        );
        final contenedor = ProviderScope.containerOf(
          tester.element(find.text('Guardar cambios').first),
        );
        unawaited(
          contenedor.read(grillaChequesProvider.notifier).elegirEmpresa(5),
        );
        await tester.pump(const Duration(seconds: 3));
        expect(repo.consultasTalonario, isEmpty);
        soloEsta(null);

        // Ya tocado, un cambio de empresa vuelve a comprobar con la nueva.
        repo.respuestaTalonario = valido;
        await teclear(tester, 'recibo', '3753');
        await tester.pump(medioSegundo);
        await tester.pump();
        expect(repo.consultasTalonario.map((c) => c.codEmpresa), [5]);
        unawaited(
          contenedor.read(grillaChequesProvider.notifier).elegirEmpresa(1),
        );
        await tester.pump();
        await tester.pump(medioSegundo);
        await tester.pump();
        expect(repo.consultasTalonario.map((c) => c.codEmpresa), [5, 1]);
      },
    );

    testWidgets('tocar otro campo del formulario no dispara la consulta', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.estandar,
        existente: chequeConPar(),
      );
      await tester.ensureVisible(entrada('nroCheque'));
      await tester.enterText(entrada('nroCheque'), '777');
      await tester.pump(const Duration(seconds: 3));
      expect(repo.consultasTalonario, isEmpty);
      soloEsta(null);
    });

    testWidgets('en modo talonario tambien: nada al abrir, algo al tocar', (
      tester,
    ) async {
      repo.respuestaTalonario = invalido;
      await abrir(
        tester,
        ModoRegistroCheque.talonario,
        existente: chequeConPar(estado: 'CER'),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(repo.consultasTalonario, isEmpty);

      await teclear(tester, 'recibo', '3760');
      await tester.pump(medioSegundo);
      await tester.pump();
      expect(repo.consultasTalonario, hasLength(1));
      soloEsta(claveAvisoTalonarioInvalido);
      expect(find.text(mensajeReal), findsOneWidget);
    });

    testWidgets('en modo administrador tambien se comprueba', (tester) async {
      repo.respuestaTalonario = valido;
      await abrir(tester, ModoRegistroCheque.admin);
      await parYComprobar(tester);
      expect(repo.consultasTalonario, hasLength(1));
      soloEsta(claveAvisoTalonarioValido);
    });
  });

  // ── (j) La empresa es la del formulario, no la del login ─────────────────

  group('empresa consultada', () {
    testWidgets('el alta consulta con la empresa activa de la pantalla (no la del login)', (
      tester,
    ) async {
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);
      // El login de las pruebas es de la empresa 6; la activa es la 1.
      expect(repo.consultasTalonario.single.codEmpresa, 1);
    });

    testWidgets('con ESPPAPEL elegida en los filtros consulta con la 5', (
      tester,
    ) async {
      await montar(
        tester,
        appCheques(
          hijo: const ChequesScreen(),
          repo: repo,
          permisos: permisosAdmin,
        ),
      );
      await tester.tap(comboEmpresa());
      await esperar(tester);
      await tester.tap(find.text('ESPPAPEL').last);
      await esperar(tester);
      await tester.tap(find.text('Registrar'));
      await esperar(tester);

      await parYComprobar(tester);
      expect(repo.consultasTalonario, hasLength(1));
      expect(repo.consultasTalonario.single.codEmpresa, 5);
    });

    testWidgets('al editar un cheque de la 5 con la 1 activa, usa la del cheque', (
      tester,
    ) async {
      await abrir(
        tester,
        ModoRegistroCheque.estandar,
        existente: chequeConPar(codEmpresa: 5, codSucursal: 7),
      );
      await teclear(tester, 'recibo', '3753');
      await tester.pump(medioSegundo);
      await tester.pump();
      expect(repo.consultasTalonario.single.codEmpresa, 5);
    });

    testWidgets('si la empresa activa cambia con el par ya escrito, consulta de nuevo', (
      tester,
    ) async {
      repo.respuestaTalonario = valido;
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);
      expect(repo.consultasTalonario.map((c) => c.codEmpresa), [1]);
      soloEsta(claveAvisoTalonarioValido);

      final contenedor = ProviderScope.containerOf(
        tester.element(find.text('Registrar cheque').first),
      );
      unawaited(contenedor.read(grillaChequesProvider.notifier).elegirEmpresa(5));
      await tester.pump();
      // El resultado de la otra empresa ya no vale.
      soloEsta(claveAvisoTalonarioComprobando);

      await tester.pump(medioSegundo);
      await tester.pump();
      expect(repo.consultasTalonario.map((c) => c.codEmpresa), [1, 5]);
      expect(
        repo.consultasTalonario.last.nroTalonario,
        'ER1076',
        reason: 'el mismo par, contra la empresa nueva',
      );
    });

    testWidgets('si la empresa llega despues de escribir el par, lo comprueba al llegar', (
      tester,
    ) async {
      repo.errorEmpresas = Exception('Sin conexión con el servidor');
      await abrir(tester, ModoRegistroCheque.estandar);
      expect(find.textContaining('No se pudo cargar la empresa'), findsOneWidget);

      // Sin empresa no hay a quien preguntar: no consulta.
      await parYComprobar(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(repo.consultasTalonario, isEmpty);
      soloEsta(null);

      repo.errorEmpresas = null;
      // Al escribir se desplazo el cuerpo: el aviso de la empresa quedo arriba.
      await tester.ensureVisible(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      // La empresa llego: el par ya escrito se comprueba contra ella.
      soloEsta(claveAvisoTalonarioComprobando);
      await tester.pump(medioSegundo);
      await tester.pump();
      expect(repo.consultasTalonario.map((c) => c.codEmpresa), [1]);
    });
  });

  // ── (k) Cerrar el formulario con algo pendiente ──────────────────────────

  group('cerrar el formulario', () {
    Future<void> cerrarDescartando(WidgetTester tester) async {
      await tester.tap(find.text('Cancelar'));
      await esperar(tester);
      await tester.tap(find.text('Descartar'));
      await esperar(tester);
    }

    testWidgets('con la espera pendiente no lanza consulta ni falla', (
      tester,
    ) async {
      final errores = await capturandoErrores(() async {
        await abrir(tester, ModoRegistroCheque.estandar);
        await teclear(tester, 'talonario', 'ER1076');
        await teclear(tester, 'recibo', '3752');
        soloEsta(claveAvisoTalonarioComprobando);

        // Se cierra antes de que venza la espera. Se avanza por fotogramas: el
        // panel se desmonta al terminar su animacion de salida, y recien
        // despues pasan los 600 ms.
        await tester.tap(find.text('Cancelar'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Descartar'));
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
      expect(errores, isEmpty);
      expect(repo.consultasTalonario, isEmpty);
      expect(find.text('Registrar cheque'), findsNothing);
    });

    testWidgets('con una consulta en vuelo, su respuesta no hace nada al llegar', (
      tester,
    ) async {
      repo
        ..respuestaTalonario = invalido
        ..demoraTalonario = const Duration(seconds: 2);
      final errores = await capturandoErrores(() async {
        await abrir(tester, ModoRegistroCheque.estandar);
        await teclear(tester, 'talonario', 'ER1076');
        await teclear(tester, 'recibo', '3752');
        await tester.pump(medioSegundo);
        expect(repo.consultasTalonario, hasLength(1));

        await cerrarDescartando(tester);
        expect(find.text('Registrar cheque'), findsNothing);
        // Llega la respuesta de un formulario que ya no existe.
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
      });
      expect(errores, isEmpty);
      expect(find.text(mensajeReal), findsNothing);
    });

    testWidgets('un formulario nuevo no hereda el aviso del anterior', (
      tester,
    ) async {
      repo.respuestaTalonario = invalido;
      await abrir(tester, ModoRegistroCheque.estandar);
      await parYComprobar(tester);
      soloEsta(claveAvisoTalonarioInvalido);

      await cerrarDescartando(tester);
      await tester.tap(find.text('abrir'));
      await esperar(tester);
      soloEsta(null);
      expect(
        tester.widget<TextFormField>(entrada('talonario')).controller!.text,
        '0',
      );
    });
  });

  // ── La linea no estorba al resto del formulario ──────────────────────────

  group('lugar en el formulario', () {
    testWidgets('no desordena los demas campos: la observacion conserva su estado', (
      tester,
    ) async {
      repo.respuestaTalonario = valido;
      await abrir(tester, ModoRegistroCheque.estandar);
      await teclear(tester, 'observacion', 'Recibido en caja');
      final antes = tester.state(entrada('observacion'));

      await parYComprobar(tester);
      soloEsta(claveAvisoTalonarioValido);

      // El mismo campo, no uno nuevo que se llamo igual.
      expect(tester.state(entrada('observacion')), same(antes));
      expect(
        tester.widget<TextFormField>(entrada('observacion')).controller!.text,
        'Recibido en caja',
      );

      // Y al irse la linea, tampoco.
      await teclear(tester, 'recibo', '0');
      soloEsta(null);
      expect(tester.state(entrada('observacion')), same(antes));
    });

    for (final ancho in [390.0, 800.0, 1400.0]) {
      testWidgets(
        'a ${ancho.toInt()} px va debajo de talonario y recibo, antes de la observacion',
        (tester) async {
          repo.respuestaTalonario = valido;
          await abrir(tester, ModoRegistroCheque.estandar, ancho: ancho);
          await parYComprobar(tester);

          final aviso = tester.getRect(find.byKey(claveAvisoTalonarioValido));
          final tal = tester.getRect(editable('talonario'));
          final rec = tester.getRect(editable('recibo'));
          final obs = tester.getRect(editable('observacion'));

          expect(aviso.top, greaterThanOrEqualTo(tal.bottom));
          expect(aviso.top, greaterThanOrEqualTo(rec.bottom));
          expect(obs.top, greaterThanOrEqualTo(aviso.bottom));
          // Todo el ancho de su fila.
          expect(aviso.left, tal.left);
          if (ancho >= 800) {
            // Dos columnas: talonario y recibo lado a lado; el aviso abarca los
            // dos.
            expect(rec.left, greaterThan(tal.right));
            expect(aviso.right, greaterThanOrEqualTo(rec.right - 0.5));
          } else {
            // Una columna: recibo debajo de talonario y el aviso debajo de ambos.
            expect(rec.top, greaterThanOrEqualTo(tal.bottom));
            expect(aviso.right, greaterThanOrEqualTo(rec.right - 0.5));
            expect(aviso.top, greaterThanOrEqualTo(rec.bottom));
          }
          // Dentro del panel, sin salirse por los lados.
          final panel = tester.getRect(find.byType(Dialog));
          expect(aviso.left, greaterThanOrEqualTo(panel.left));
          expect(aviso.right, lessThanOrEqualTo(panel.right));
        },
      );
    }
  });

  // ── El comprobador solo, sin pantalla ────────────────────────────────────

  // En testWidgets un Timer que sigue vivo al terminar la prueba la hace fallar:
  // asi se comprueba que dispose() cancela la espera.
  group('ComprobadorTalonarioCheque', () {
    ComprobadorTalonarioCheque nuevo(
      List<(int, String, String)> consultas, {
      TalonarioValidacionEntity respuesta = valido,
    }) => ComprobadorTalonarioCheque(
      consultar: (e, t, r) async {
        consultas.add((e, t, r));
        return respuesta;
      },
    );

    testWidgets('dispose con la espera pendiente cancela el temporizador', (
      tester,
    ) async {
      final consultas = <(int, String, String)>[];
      final c = nuevo(consultas);
      c.programar(codEmpresa: 1, talonario: 'ER1076', recibo: '3752');
      expect(c.estado.fase, FaseTalonarioCheque.comprobando);
      c.dispose();
      // Sin pasar el tiempo: si el Timer siguiera vivo, la prueba terminaria
      // con uno pendiente y fallaria.
      expect(consultas, isEmpty);
    });

    testWidgets('dispose con la espera pendiente: al vencer, no consulta', (
      tester,
    ) async {
      final consultas = <(int, String, String)>[];
      final c = nuevo(consultas);
      c.programar(codEmpresa: 1, talonario: 'ER1076', recibo: '3752');
      c.dispose();
      await tester.pump(const Duration(seconds: 2));
      expect(consultas, isEmpty);
    });

    testWidgets('tras dispose, programar no hace nada', (tester) async {
      final consultas = <(int, String, String)>[];
      final c = nuevo(consultas);
      c.dispose();
      c.programar(codEmpresa: 1, talonario: 'ER1076', recibo: '3752');
      await tester.pump(const Duration(seconds: 2));
      expect(consultas, isEmpty);
    });

    testWidgets('sin empresa no consulta y limpia', (tester) async {
      final consultas = <(int, String, String)>[];
      final c = nuevo(consultas);
      addTearDown(c.dispose);
      c.programar(codEmpresa: 1, talonario: 'ER1076', recibo: '3752');
      expect(c.estado.visible, isTrue);
      c.programar(codEmpresa: null, talonario: 'ER1076', recibo: '3752');
      expect(c.estado.visible, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(consultas, isEmpty);
    });

    testWidgets('manda los textos recortados y avisa a quien escucha', (
      tester,
    ) async {
      final consultas = <(int, String, String)>[];
      final c = nuevo(consultas);
      addTearDown(c.dispose);
      final fases = <FaseTalonarioCheque>[];
      c.addListener(() => fases.add(c.estado.fase));

      c.programar(codEmpresa: 5, talonario: ' ER1076 ', recibo: ' 3752');
      await tester.pump(medioSegundo);
      await tester.pump();

      expect(consultas, [(5, 'ER1076', '3752')]);
      expect(fases, [FaseTalonarioCheque.comprobando, FaseTalonarioCheque.valido]);
      expect(c.estado.texto, detalleReal);
    });

    testWidgets('repetir lo mismo no vuelve a avisar', (tester) async {
      final c = nuevo(<(int, String, String)>[]);
      addTearDown(c.dispose);
      var avisos = 0;
      c.addListener(() => avisos++);
      c.programar(codEmpresa: 1, talonario: 'ER1076', recibo: '3752');
      c.programar(codEmpresa: 1, talonario: 'ER1076', recibo: '3752');
      expect(avisos, 1);
      await tester.pump(medioSegundo);
      await tester.pump();
    });
  });

  // ── (l) Sin desbordes ────────────────────────────────────────────────────

  group('sin desbordes', () {
    final estados =
        <String, ({TalonarioValidacionEntity? respuesta, Object? error, Key clave})>{
          'valido con detalle': (
            respuesta: valido,
            error: null,
            clave: claveAvisoTalonarioValido,
          ),
          'invalido, una linea larga': (
            respuesta: invalido,
            error: null,
            clave: claveAvisoTalonarioInvalido,
          ),
          'invalido, varias lineas': (
            respuesta: const TalonarioValidacionEntity(
              valido: false,
              mensaje: mensajeVariasLineas,
            ),
            error: null,
            clave: claveAvisoTalonarioInvalido,
          ),
          'no se pudo comprobar': (
            respuesta: null,
            error: Exception('sin red'),
            clave: claveAvisoTalonarioNoComprobado,
          ),
        };

    for (final escala in [1.0, 1.5]) {
      for (final ancho in [390.0, 800.0, 1400.0]) {
        for (final e in estados.entries) {
          testWidgets(
            '${e.key}: ${ancho.toInt()} px, texto al ${(escala * 100).toInt()} %',
            (tester) async {
              if (escala != 1.0) conTexto(tester, escala);
              if (e.value.respuesta != null) {
                repo.respuestaTalonario = e.value.respuesta!;
              }
              repo.errorTalonario = e.value.error;

              final errores = await capturandoErrores(() async {
                await abrir(tester, ModoRegistroCheque.estandar, ancho: ancho);
                await parYComprobar(tester);
              });
              expect(errores, isEmpty, reason: '${e.key} a $ancho');
              expect(find.byKey(e.value.clave), findsOneWidget);

              // Cabe en el panel y no se recorta.
              final aviso = tester.getRect(find.byKey(e.value.clave));
              final panel = tester.getRect(find.byType(Dialog));
              expect(aviso.left, greaterThanOrEqualTo(panel.left));
              expect(aviso.right, lessThanOrEqualTo(panel.right));
              for (final t in tester.widgetList<Text>(
                find.descendant(
                  of: find.byKey(e.value.clave),
                  matching: find.byType(Text),
                ),
              )) {
                expect(t.maxLines, isNull);
                expect(t.overflow, isNull);
              }
            },
          );
        }
      }
    }

    testWidgets('«Comprobando…» tambien cabe a 390 px con texto al 150 %', (
      tester,
    ) async {
      conTexto(tester, 1.5);
      final errores = await capturandoErrores(() async {
        await abrir(tester, ModoRegistroCheque.estandar, ancho: 390);
        await teclear(tester, 'talonario', 'ER1076');
        await teclear(tester, 'recibo', '3752');
      });
      expect(errores, isEmpty);
      soloEsta(claveAvisoTalonarioComprobando);
      // Sin consulta resuelta: se corta aqui para no dejar un Timer pendiente.
      await tester.pump(medioSegundo);
      await tester.pump();
    });
  });
}
