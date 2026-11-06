import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/data/repositories/hex_ubicacion_impl.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_requisito_marca_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/domain/repositories/hex_reporte_repository.dart';
import 'package:bosque_flutter/domain/repositories/hex_ubicacion_repository.dart';
import 'package:bosque_flutter/presentation/screens/horas-extras/hex_mis_horas_screen.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

import 'fakes/arnes_hex.dart';
import 'fakes/repositorio_hex.dart';
import 'fakes/ubicacion_hex_falsa.dart';

/// «Mis horas extra»: marcación con ubicación obligatoria (servicio, permiso,
/// doble toque), requisitos en una línea si todo está bien, solo las teclas
/// que valen, lista sin acciones ni dinero (D41), filtros y anchos.
void main() {
  setUpAll(cargarFuentesHex);

  late HexReporteFalso repo;
  late UbicacionHexFalsa ubicacion;

  setUp(() {
    repo = HexReporteFalso();
    ubicacion = UbicacionHexFalsa();
    // «¿Cómo funciona?» ya vista (plegada): las pruebas de la marcación no
    // dependen de ella; la suya empieza como la primera visita.
    SharedPreferences.setMockInitialValues({'hex_como_funciona_plegada': true});
  });

  String detalle(List<FlutterErrorDetails> e) =>
      e.map((x) => x.exceptionAsString()).join('\n');

  Future<void> montar(
    WidgetTester t, {
    double ancho = 1400,
    Set<String>? botones,
  }) async {
    await montarHex(
      t,
      const HexMisHorasScreen(),
      ancho: ancho,
      botones: botones,
      overrides: [
        hexReporteRepositoryProvider.overrideWithValue(repo),
        hexUbicacionProvider.overrideWithValue(ubicacion),
      ],
    );
    await esperar(t);
  }

  ButtonStyleButton boton(WidgetTester t, String texto) =>
      t.widget<ButtonStyleButton>(
        find
            .ancestor(
              of: find.text(texto),
              matching: find.bySubtype<ButtonStyleButton>(),
            )
            .first,
      );

  /// El desplazamiento de la pantalla (el único vertical en el angosto).
  Finder pagina() =>
      find
          .ancestor(
            of: find.text('Mis horas extra'),
            matching: find.byType(Scrollable),
          )
          .first;

  bool esVertical(Widget w) =>
      (w is ScrollView && w.scrollDirection == Axis.vertical) ||
      (w is SingleChildScrollView && w.scrollDirection == Axis.vertical);

  bool esLateral(Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal;

  const salidaRegistrada =
      'Salida registrada a las 19:40: reporte después del horario de la '
      'jornada del 30/10/2026.';

  group('marcación', () {
    testWidgets('sin ubicación no deja marcar', (t) async {
      ubicacion.estado = EstadoUbicacionHex.servicioApagado;
      await montar(t, ancho: 390);
      expect(ubicacion.verificaciones.first, isTrue, reason: 'pide permiso');
      expect(
        find.text('Activa la ubicación del teléfono para marcar.'),
        findsOneWidget,
      );
      expect(boton(t, 'Marcar entrada').onPressed, isNull);
      expect(boton(t, 'Marcar salida').onPressed, isNull);
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 2);
      expect(repo.vecesDe('marcar'), 0);
      expect(ubicacion.posiciones, 0);
      await t.tap(find.text('Activar ubicación'));
      await t.pump();
      expect(ubicacion.ajustesUbicacion, 1);
      await cerrar(t);
    });

    testWidgets('sin permiso para siempre ofrece abrir ajustes', (t) async {
      ubicacion.estado = EstadoUbicacionHex.denegadoSiempre;
      await montar(t);
      expect(
        find.text('Da permiso de ubicación a la aplicación para marcar.'),
        findsOneWidget,
      );
      expect(find.text('Dar permiso'), findsNothing);
      expect(boton(t, 'Marcar salida').onPressed, isNull);
      await t.tap(find.text('Abrir ajustes'));
      await t.pump();
      expect(ubicacion.ajustesApp, 1);
      expect(repo.vecesDe('marcar'), 0);
      await cerrar(t);
    });

    testWidgets('Dar permiso lo vuelve a pedir y habilita marcar', (t) async {
      ubicacion.programar([
        EstadoUbicacionHex.sinPermiso,
        EstadoUbicacionHex.lista,
      ]);
      await montar(t, ancho: 390);
      expect(boton(t, 'Marcar salida').onPressed, isNull);
      await t.tap(find.text('Dar permiso'));
      await esperar(t, 2);
      expect(ubicacion.verificaciones, [true, true]);
      expect(boton(t, 'Marcar salida').onPressed, isNotNull);
      expect(find.text('Todo listo para marcar'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets(
      'si la ubicación se apaga después de abrir la pantalla, no marca',
      (t) async {
        await montar(t);
        expect(boton(t, 'Marcar salida').onPressed, isNotNull);
        ubicacion.estado = EstadoUbicacionHex.servicioApagado;
        await t.tap(find.text('Marcar salida'));
        await esperar(t, 2);
        expect(repo.vecesDe('marcar'), 0);
        expect(ubicacion.posiciones, 0);
        expect(
          find.text('Activa la ubicación del teléfono para marcar.'),
          findsOneWidget,
        );
        await cerrar(t);
      },
    );

    testWidgets('si el servicio se apaga, el panel lo muestra sin tocar nada', (
      t,
    ) async {
      await montar(t);
      ubicacion.estado = EstadoUbicacionHex.servicioApagado;
      ubicacion.servicio.add(false);
      await esperar(t, 2);
      expect(
        find.text('Activa la ubicación del teléfono para marcar.'),
        findsOneWidget,
      );
      expect(boton(t, 'Marcar salida').onPressed, isNull);
      await cerrar(t);
    });

    testWidgets('marcar salida manda la posición y muestra el mensaje del SP', (
      t,
    ) async {
      repo.programar('marcar', [
        (id: BigInt.from(104), mensaje: salidaRegistrada),
      ]);
      await montar(t, ancho: 390);
      final lecturas = repo.vecesDe('misReportes');
      // D41: el motivo no se escribe aquí; es el de la asignación.
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 3);
      expect(repo.argumentosDe('marcar'), [
        {'tipoMarca': 'SALIDA', 'posicion': UbicacionHexFalsa.posicion},
      ]);
      expect(find.text(salidaRegistrada), findsOneWidget);
      expect(repo.vecesDe('misReportes'), greaterThan(lecturas));
      await cerrar(t);
    });

    testWidgets('D41: marcar entrada solo manda el tipo y la posición', (
      t,
    ) async {
      await montar(t);
      await t.tap(find.text('Marcar entrada'));
      await esperar(t, 3);
      expect(repo.argumentosDe('marcar').single.keys, [
        'tipoMarca',
        'posicion',
      ]);
      expect(repo.argumentosDe('marcar').single['tipoMarca'], 'ENTRADA');
      await cerrar(t);
    });

    testWidgets('doble toque en Marcar salida manda un solo pedido', (t) async {
      repo.pausa = Completer<void>();
      await montar(t);
      await t.tap(find.text('Marcar salida'));
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 2);
      expect(repo.vecesDe('marcar'), 1);
      expect(boton(t, 'Marcar salida').onPressed, isNull);
      expect(boton(t, 'Marcar entrada').onPressed, isNull);
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 1);
      expect(repo.vecesDe('marcar'), 1);
      repo.pausa!.complete();
      await esperar(t, 2);
      expect(repo.vecesDe('marcar'), 1);
      expect(ubicacion.posiciones, 1);
      expect(boton(t, 'Marcar salida').onPressed, isNotNull);
      await cerrar(t);
    });

    testWidgets(
      'el botón queda deshabilitado mientras se obtiene la ubicación',
      (t) async {
        ubicacion.pausaPosicion = Completer<void>();
        await montar(t);
        await t.tap(find.text('Marcar salida'));
        await esperar(t, 1);
        expect(ubicacion.posiciones, 1);
        expect(find.text('Obteniendo tu ubicación…'), findsOneWidget);
        expect(boton(t, 'Marcar salida').onPressed, isNull);
        await t.tap(find.text('Marcar salida'));
        await esperar(t, 1);
        // Una verificación al abrir y otra del primer toque; el segundo, nada.
        expect(ubicacion.verificaciones, hasLength(2));
        expect(ubicacion.posiciones, 1);
        ubicacion.pausaPosicion!.complete();
        await esperar(t, 2);
        expect(repo.vecesDe('marcar'), 1);
        await cerrar(t);
      },
    );

    testWidgets('si el GPS no responde a tiempo avisa y no marca', (t) async {
      ubicacion.errorPosicion = const UbicacionNoDisponibleHex();
      await montar(t);
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 2);
      expect(repo.vecesDe('marcar'), 0);
      expect(
        find.textContaining('No se pudo obtener tu ubicación'),
        findsOneWidget,
      );
      expect(boton(t, 'Marcar salida').onPressed, isNotNull);
      await cerrar(t);
    });

    testWidgets(
      'un fallo inesperado del GPS avisa y no deja el toque sin respuesta',
      (t) async {
        ubicacion.errorPosicion = Exception('plataforma sin GPS');
        await montar(t);
        await t.tap(find.text('Marcar salida'));
        await esperar(t, 2);
        expect(
          find.text(
            'No se pudo obtener tu ubicación. Vuelve a marcar en un momento.',
          ),
          findsOneWidget,
        );
        expect(repo.vecesDe('marcar'), 0);
        expect(boton(t, 'Marcar salida').onPressed, isNotNull);
        await cerrar(t);
      },
    );

    testWidgets('D37: una salida ya registrada es 409, sin confirmación', (
      t,
    ) async {
      const ya =
          'Ya registró su salida de la jornada del 30/10/2026 por la app, a '
          'las 19:40.';
      repo.programar('marcar', [const ConflictoHex(ya)]);
      await montar(t);
      final consultas = repo.vecesDe('hoy');
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 3);
      expect(find.text('Confirma antes de seguir'), findsNothing);
      expect(find.text(ya), findsOneWidget);
      expect(repo.vecesDe('marcar'), 1);
      expect(
        repo.argumentosDe('marcar').single.containsKey('confirmado'),
        false,
      );
      // Tras marcar se vuelve a preguntar qué teclas valen.
      expect(repo.vecesDe('hoy'), greaterThan(consultas));
      await cerrar(t);
    });

    testWidgets('sin btnHexMarcar no hay panel ni se pide la ubicación', (
      t,
    ) async {
      await montar(t, botones: {'btnHexAnular'});
      expect(find.text('Marcar salida'), findsNothing);
      expect(ubicacion.verificaciones, isEmpty);
      // D41: quién asignó y el motivo se ven igual.
      expect(find.text('Inventario de fin de mes'), findsOneWidget);
      expect(find.byTooltip('Anular'), findsNothing);
      await cerrar(t);
    });
  });

  group('reportes', () {
    testWidgets('D41: la lista no ofrece ver detalle, editar ni anular', (
      t,
    ) async {
      await montar(t);
      expect(find.text('Acciones'), findsNothing);
      expect(find.byTooltip('Ver detalle'), findsNothing);
      expect(find.byTooltip('Editar'), findsNothing);
      expect(find.byTooltip('Anular'), findsNothing);
      await cerrar(t);
    });

    testWidgets('la lista muestra el origen de las horas', (t) async {
      await montar(t);
      expect(find.textContaining('vacaci'), findsNothing);
      expect(find.text('Biométrico'), findsOneWidget);
      expect(find.text('App · con ubicación'), findsOneWidget);
      expect(find.text('Del horario'), findsNWidgets(3));
      expect(find.text('Pendiente de biométrico'), findsOneWidget);
      expect(find.text('Corregida por el encargado'), findsNWidgets(2));
      expect(find.text('Editado'), findsWidgets);
      // D38 y D41: el operario no ve dinero ni códigos de comida.
      expect(find.text('provisional'), findsNothing);
      expect(find.text('Monto'), findsNothing);
      expect(find.text('Comidas'), findsNothing);
      await cerrar(t);
    });

    testWidgets('las tarjetas del teléfono no hablan de compensación', (
      t,
    ) async {
      await montar(t, ancho: 390);
      expect(find.textContaining('vacaci'), findsNothing);
      expect(find.textContaining('ompensa'), findsNothing);
      expect(find.text('Jornada 23/10/2026'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets(
      'el encabezado no ofrece reportar a mano, ni al administrador',
      (t) async {
        await montar(t);
        expect(find.byIcon(Icons.edit_calendar_outlined), findsNothing);
        expect(find.text('Marcar salida'), findsOneWidget);
        await cerrar(t);
      },
    );

    testWidgets(
      'sin reportes explica que las marcas del biométrico llegan solas',
      (t) async {
        repo.programar('misReportes', [
          (filas: <HexReporteEntity>[], total: 0),
        ]);
        await montar(t);
        expect(
          find.text('Todavía no tienes horas extra reportadas'),
          findsOneWidget,
        );
        expect(
          find.textContaining('aparecen solas cuando llegan las marcas'),
          findsOneWidget,
        );
        expect(
          find.textContaining('«Marcar entrada» o «Marcar salida»'),
          findsOneWidget,
        );
        await cerrar(t);
      },
    );

    testWidgets('D41: en el teléfono las tarjetas no tienen menú ni detalle', (
      t,
    ) async {
      await montar(t, ancho: 390);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      await t.tap(find.text('Jornada 23/10/2026'));
      await esperar(t, 2);
      expect(repo.vecesDe('detalle'), 0);
      await cerrar(t);
    });

    testWidgets('un 403 en la lista muestra No tienes permiso', (t) async {
      repo.programar('misReportes', [
        const SinPermisoHex(
          'No tienes los permisos necesarios para realizar esta acción.',
        ),
      ]);
      await montar(t);
      expect(find.text('No tienes permiso'), findsOneWidget);
      await cerrar(t);
    });

    testWidgets('en el angosto el 403 va en la caja de los estados', (t) async {
      repo.programar('misReportes', [const SinPermisoHex('Sin permiso.')]);
      await montar(t, ancho: 390);
      final caja = find.ancestor(
        of: find.byType(SinPermisoHexVista),
        matching: find.byType(SizedBox),
      );
      expect(t.widget<SizedBox>(caja.first).height, hexAltoEstado);
      await cerrar(t);
    });

    testWidgets(
      'un error del SP en la lista se muestra tal cual y deja filtrar',
      (t) async {
        const regla =
            'El rango de fechas no es válido: la fecha final es anterior.';
        repo.programar('misReportes', [const NegocioHex(regla)]);
        await montar(t);
        expect(find.text(regla), findsOneWidget);
        expect(find.text('Todos los estados'), findsOneWidget);
        await cerrar(t);
      },
    );

    testWidgets('D41: el operario no ve la leyenda de códigos', (t) async {
      await montar(t);
      expect(find.text('Leyenda de códigos'), findsNothing);
      expect(find.text('¿Qué significan los códigos?'), findsNothing);
      expect(find.text('H50'), findsNothing);
      await cerrar(t);
    });

    testWidgets(
      'el filtro de estado pide al servidor la página 1 de ese estado',
      (t) async {
        await montar(t);
        await t.tap(find.text('Todos los estados'));
        await esperar(t, 2);
        await t.tap(find.text('Reportados').last);
        await esperar(t, 3);
        final FiltroReportesHex f =
            repo.argumentosDe('misReportes').last['filtro']!
                as FiltroReportesHex;
        expect(f.estado, 'REPORTADO');
        expect(f.pagina, 1);
        await cerrar(t);
      },
    );

    testWidgets('ya no hay filtro de compensación', (t) async {
      await montar(t);
      expect(find.text('Filtra esta página'), findsNothing);
      expect(find.text('Dinero y vacaciones'), findsNothing);
      expect(find.text('Todos los estados'), findsOneWidget);
      await cerrar(t);
    });
  });

  group('rediseño (D29)', () {
    HexRequisitoMarcaEntity requisito({
      required bool cumple,
      required bool bloquea,
      String detalle = 'Pide a RRHH que te asigne un horario en el biométrico',
    }) => HexRequisitoMarcaEntity(
      requisito: 'HORARIO',
      cumple: cumple,
      bloquea: bloquea,
      titulo: 'Horario asignado en el biométrico',
      detalle: detalle,
      orden: 4,
    );

    testWidgets('todo listo es una línea que se abre con cada requisito', (
      t,
    ) async {
      await montar(t, ancho: 390);
      expect(find.text('Todo listo para marcar'), findsOneWidget);
      expect(find.text('Ubicación activa'), findsNothing);
      expect(find.text(requisitosFalsos.first.titulo), findsNothing);
      await t.tap(find.text('Todo listo para marcar'));
      await esperar(t, 2);
      expect(find.text('Ubicación activa'), findsOneWidget);
      for (final r in requisitosFalsos) {
        expect(find.text(r.titulo), findsOneWidget, reason: r.titulo);
        expect(find.text(r.detalle), findsOneWidget, reason: r.detalle);
      }
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
      expect(find.byIcon(Icons.cancel), findsNothing);
      // D37: cada tecla dice por qué vale, en palabras del SP.
      expect(find.text(vistaMarcacionFalsa.textoMarcarEntrada), findsOneWidget);
      expect(find.text(vistaMarcacionFalsa.textoMarcarSalida), findsOneWidget);
      expect(boton(t, 'Marcar salida').onPressed, isNotNull);
      await cerrar(t);
    });

    testWidgets('un requisito que bloquea deshabilita las teclas', (t) async {
      final errores = capturarErrores();
      repo.programar('requisitosMarca', [
        [...requisitosFalsos.take(3), requisito(cumple: false, bloquea: true)],
      ]);
      await montar(t, ancho: 390);
      expect(
        find.text('Pide a RRHH que te asigne un horario en el biométrico'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(
        find.text('Falta un requisito: revisa «Antes de marcar».'),
        findsOneWidget,
      );
      expect(boton(t, 'Marcar entrada').onPressed, isNull);
      expect(boton(t, 'Marcar salida').onPressed, isNull);
      // Sin poder marcar no se pide el motivo.
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 2);
      expect(repo.vecesDe('marcar'), 0);
      expect(ubicacion.posiciones, 0);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    testWidgets('un requisito que no bloquea solo avisa en ámbar', (t) async {
      repo.programar('requisitosMarca', [
        [requisito(cumple: false, bloquea: false, detalle: 'Hoy es feriado')],
      ]);
      await montar(t);
      expect(find.text('Hoy es feriado'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(boton(t, 'Marcar salida').onPressed, isNotNull);
      await cerrar(t);
    });

    for (final (caso, respuesta) in <(String, Object)>[
      ('falla', Exception('sin conexión')),
      ('responde 204', const <HexRequisitoMarcaEntity>[]),
    ]) {
      testWidgets('si el servidor $caso, queda la ubicación y no traba', (
        t,
      ) async {
        repo.programar('requisitosMarca', [respuesta]);
        await montar(t);
        expect(find.text('Todo listo para marcar'), findsOneWidget);
        expect(find.text('Relación laboral activa'), findsNothing);
        expect(find.text('Revisando tus requisitos…'), findsNothing);
        expect(boton(t, 'Marcar salida').onPressed, isNotNull);
        await t.tap(find.text('Marcar salida'));
        await esperar(t, 3);
        // El SP vuelve a validar al marcar: la app no decidió nada.
        expect(repo.vecesDe('marcar'), 1);
        await cerrar(t);
      });
    }

    testWidgets('el resultado de la marca queda hasta la siguiente', (t) async {
      const fallo = 'No tienes horario asignado para hoy.';
      repo.programar('marcar', [
        (id: BigInt.from(104), mensaje: salidaRegistrada),
        const NegocioHex(fallo),
      ]);
      await montar(t, ancho: 390);
      final revisiones = repo.vecesDe('requisitosMarca');
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 3);
      expect(find.text(salidaRegistrada), findsOneWidget);
      // Solo el de la marca: la asignación va en su propia tarjeta (D41).
      expect(find.byType(AvisoHex), findsOneWidget);
      // Tras marcar se vuelven a pedir los requisitos.
      expect(repo.vecesDe('requisitosMarca'), greaterThan(revisiones));
      await esperar(t, 30);
      expect(find.text(salidaRegistrada), findsOneWidget, reason: 'no se va');
      await t.tap(find.text('Marcar entrada'));
      await esperar(t, 3);
      expect(find.text(salidaRegistrada), findsNothing);
      expect(find.text(fallo), findsOneWidget);
      expect(
        t.widget<AvisoHex>(find.byType(AvisoHex).last).tono,
        TonoHex.error,
      );
      await cerrar(t);
    });

    testWidgets(
      '¿Cómo funciona? se abre la primera vez y después queda plegada',
      (t) async {
        const regla = 'El biométrico crea tus reportes solo.';
        SharedPreferences.setMockInitialValues({});
        await montar(t, ancho: 390);
        expect(find.text(regla), findsOneWidget);
        final p = await SharedPreferences.getInstance();
        expect(p.getBool('hex_como_funciona_plegada'), isTrue);
        await cerrar(t);

        await montar(t, ancho: 390);
        expect(find.text('¿Cómo funciona?'), findsOneWidget);
        expect(find.text(regla), findsNothing);
        // D41: va bajo las teclas y se abre desde su cabecera.
        await t.ensureVisible(find.text('¿Cómo funciona?'));
        await esperar(t, 1);
        await t.tap(find.text('¿Cómo funciona?'));
        await esperar(t, 3);
        expect(find.text(regla), findsOneWidget);
        expect(p.getBool('hex_como_funciona_plegada'), isFalse);
        // Se pliega también tocando su cabecera (ya quieta tras subirla).
        await esperar(t, 20);
        await t.ensureVisible(find.text('¿Cómo funciona?'));
        await esperar(t, 1);
        await t.tap(find.text('¿Cómo funciona?'));
        await esperar(t, 3);
        expect(find.text(regla), findsNothing);
        expect(p.getBool('hex_como_funciona_plegada'), isTrue);
        await cerrar(t);
      },
    );

    testWidgets('D41: las tarjetas no muestran códigos de comida', (t) async {
      await montar(t, ancho: 390);
      expect(find.text('DC'), findsNothing);
      expect(find.text('C'), findsNothing);
      await cerrar(t);
    });

    testWidgets('la tarjeta dice de quién espera y el paso que sigue', (
      t,
    ) async {
      await montar(t, ancho: 390);
      // 101 trae el texto del SP; 102 (con visto bueno) no, y usa el paso.
      expect(
        find.text('Espera el visto bueno de Rojas Vargas Luis'),
        findsOneWidget,
      );
      await t.scrollUntilVisible(
        find.text('Siguiente paso: Aprobado'),
        150,
        scrollable: pagina(),
      );
      expect(find.text('Siguiente paso: Aprobado'), findsOneWidget);
      expect(find.byType(AvanceReporteHex), findsWidgets);
      await cerrar(t);
    });

    testWidgets('un rechazo muestra quién y por qué en la tarjeta', (t) async {
      final rechazado = HexReporteEntity(
        idReporte: BigInt.from(105),
        fechaJornada: DateTime(2026, 10, 20),
        estado: 'RECHAZADO',
        estadoTexto: 'Rechazado',
        textoPendiente: 'Rechazado por Rojas Vargas Luis',
        motivoRechazo: 'La salida real fue a las 18:05.',
        totalFilas: 1,
      );
      repo.programar('misReportes', [
        (filas: [rechazado], total: 1),
      ]);
      await montar(t, ancho: 390);
      await t.scrollUntilVisible(
        find.text('Rechazado por Rojas Vargas Luis'),
        150,
        scrollable: pagina(),
      );
      expect(
        find.text('Motivo: La salida real fue a las 18:05.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cancel_outlined), findsNWidgets(2));
      await cerrar(t);
    });
  });

  group('barra de estado y vibración', () {
    testWidgets('el desplazamiento es el primario: tocar la barra de estado '
        'en iOS sube al inicio', (t) async {
      await montar(t, ancho: 390);
      verificarControlPrimarioHex(t, HexMisHorasScreen);
      await cerrar(t);
    });

    testWidgets('marcar vibra al tocar, y sin posición vibra el aviso', (
      t,
    ) async {
      final vibraciones = capturarVibracionesHex();
      ubicacion.errorPosicion = Exception('plataforma sin GPS');
      await montar(t);
      await t.tap(find.text('Marcar salida'));
      await esperar(t, 2);
      // Un toque de la tecla y, como no hay posición, el aviso del fallo.
      expect(vibraciones, ['lightImpact', 'mediumImpact']);
      await cerrar(t);
    });
  });

  group('anchos', () {
    // 964 px: una laptop de 1280 con el menú lateral de 268.
    for (final ancho in [390.0, 800.0, 964.0, 1400.0]) {
      testWidgets('Mis horas a $ancho px sin desbordes', (t) async {
        final errores = capturarErrores();
        await montar(t, ancho: ancho);
        // Tabla solo con su ancho mínimo en la lista, sin el relleno; por
        // debajo, tarjetas y nunca desplazamiento lateral.
        final tabla = ancho - 48 >= anchoTablaMisHorasHex;
        expect(find.byWidgetPredicate(esLateral), findsNothing);
        expect(find.text('Mis horas extra'), findsOneWidget);
        expect(find.text('Jornada'), tabla ? findsOneWidget : findsNothing);
        expect(find.text('Filtros'), tabla ? findsNothing : findsOneWidget);
        expect(find.text('Marcar salida'), findsOneWidget);
        if (!tabla) {
          await t.tap(find.text('Filtros'));
          await esperar(t, 2);
          expect(find.text('Todos los estados'), findsOneWidget);
        }
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('a 1098 px (1366 con el menú lateral) la tabla no va de lado', (
      t,
    ) async {
      final errores = capturarErrores();
      await montar(t, ancho: 1098);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Acciones'), findsNothing);
      expect(find.byWidgetPredicate(esLateral), findsNothing);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    test('el ancho de la tabla sale de los flex de sus columnas', () {
      // D41: sin Comidas, Monto ni Acciones.
      expect(anchoTablaMisHorasHex, 2.0 * (52 + 48 + 222) + 24);
    });

    testWidgets('arrastrar la pantalla cierra el teclado', (t) async {
      await montar(t, ancho: 390);
      final pantalla = t.widget<SingleChildScrollView>(
        find.byWidgetPredicate(esVertical).first,
      );
      expect(
        pantalla.keyboardDismissBehavior,
        ScrollViewKeyboardDismissBehavior.onDrag,
      );
      await cerrar(t);
    });

    testWidgets('en el angosto hay un solo desplazamiento vertical', (t) async {
      await montar(t, ancho: 390);
      expect(find.byWidgetPredicate(esVertical), findsOneWidget);
      // Las tarjetas van en el mismo scroll que el panel de marcación.
      expect(
        find.ancestor(
          of: find.text('Jornada 23/10/2026'),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      await cerrar(t);
    });

    testWidgets('en el angosto, cambiar de página muestra su primera tarjeta', (
      t,
    ) async {
      repo.programar('misReportes', [(filas: reportesFalsos, total: 45)]);
      await montar(t, ancho: 390);
      await t.scrollUntilVisible(
        find.byIcon(Icons.chevron_right),
        200,
        scrollable: pagina(),
      );
      await t.tap(find.byIcon(Icons.chevron_right));
      await esperar(t, 4);
      final f =
          repo.argumentosDe('misReportes').last['filtro']! as FiltroReportesHex;
      expect(f.pagina, 2);
      expect(find.text('Jornada 23/10/2026').hitTestable(), findsOneWidget);
      await cerrar(t);
    });

    for (final escala in [1.0, 1.5]) {
      testWidgets('con el teclado abierto en 390x741 y AppBar al $escala', (
        t,
      ) async {
        t.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        await montarHex(
          t,
          Scaffold(
            appBar: AppBar(title: const Text('Bosque')),
            body: const HexMisHorasScreen(),
          ),
          ancho: 390,
          overrides: [
            hexReporteRepositoryProvider.overrideWithValue(repo),
            hexUbicacionProvider.overrideWithValue(ubicacion),
          ],
        );
        t.view.physicalSize = const Size(390, 741);
        await esperar(t);
        t.view.viewInsets = const FakeViewPadding(bottom: 336);
        await esperar(t, 3);
        expect(errores, isEmpty, reason: detalle(errores));
        // La lista sigue a mano desplazando, con el teclado abierto.
        await t.scrollUntilVisible(
          find.text('Pendiente de biométrico'),
          150,
          scrollable: pagina(),
        );
        await esperar(t, 2);
        expect(
          find.text('Pendiente de biométrico').hitTestable(),
          findsOneWidget,
        );
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('Mis horas al 150 % en 390 px sin desbordes', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await t.scrollUntilVisible(
        find.text('Pendiente de biométrico'),
        150,
        scrollable: pagina(),
      );
      await esperar(t, 2);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });

    for (final estado in [
      EstadoUbicacionHex.servicioApagado,
      EstadoUbicacionHex.sinPermiso,
      EstadoUbicacionHex.denegadoSiempre,
    ]) {
      testWidgets('el aviso de ubicación ($estado) al 150 % en 390 px', (
        t,
      ) async {
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final errores = capturarErrores();
        ubicacion.estado = estado;
        await montar(t, ancho: 390);
        expect(boton(t, 'Marcar salida').onPressed, isNull);
        expect(errores, isEmpty, reason: detalle(errores));
        await cerrar(t);
      });
    }

    testWidgets('los requisitos abiertos al 150 % en 390 px sin desbordes', (
      t,
    ) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errores = capturarErrores();
      await montar(t, ancho: 390);
      await t.tap(find.text('Todo listo para marcar'));
      await esperar(t, 2);
      expect(find.text('Ubicación activa'), findsOneWidget);
      expect(errores, isEmpty, reason: detalle(errores));
      await cerrar(t);
    });
  });

  group('GeolocatorUbicacionHex', () {
    late _PlataformaFalsa plataforma;
    late GeolocatorPlatform previa;
    late GeolocatorUbicacionHex ubicacionReal;

    setUp(() {
      previa = GeolocatorPlatform.instance;
      plataforma = _PlataformaFalsa();
      GeolocatorPlatform.instance = plataforma;
      ubicacionReal = GeolocatorUbicacionHex();
    });
    tearDown(() => GeolocatorPlatform.instance = previa);

    test('el servicio apagado gana y no se pregunta el permiso', () async {
      plataforma.servicio = false;
      expect(
        await ubicacionReal.verificar(pedirPermiso: true),
        EstadoUbicacionHex.servicioApagado,
      );
      expect(plataforma.pedidos, 0);
    });

    test('cada permiso se traduce a un estado', () async {
      final casos = {
        LocationPermission.whileInUse: EstadoUbicacionHex.lista,
        LocationPermission.always: EstadoUbicacionHex.lista,
        LocationPermission.denied: EstadoUbicacionHex.sinPermiso,
        LocationPermission.unableToDetermine: EstadoUbicacionHex.sinPermiso,
        LocationPermission.deniedForever: EstadoUbicacionHex.denegadoSiempre,
      };
      for (final MapEntry(key: permiso, value: estado) in casos.entries) {
        plataforma.permiso = permiso;
        expect(await ubicacionReal.verificar(), estado, reason: '$permiso');
      }
      expect(plataforma.pedidos, 0, reason: 'sin pedirPermiso no pregunta');
    });

    test('con pedirPermiso pregunta solo si está negado', () async {
      plataforma.permiso = LocationPermission.denied;
      plataforma.alPedir = LocationPermission.whileInUse;
      expect(
        await ubicacionReal.verificar(pedirPermiso: true),
        EstadoUbicacionHex.lista,
      );
      plataforma.permiso = LocationPermission.deniedForever;
      expect(
        await ubicacionReal.verificar(pedirPermiso: true),
        EstadoUbicacionHex.denegadoSiempre,
      );
      expect(plataforma.pedidos, 1);
    });

    test('Android: recuerda el negado para siempre hasta que se dé', () async {
      // checkPermission de Android responde «negado» aun después del «nunca».
      plataforma.permiso = LocationPermission.denied;
      plataforma.alPedir = LocationPermission.deniedForever;
      expect(
        await ubicacionReal.verificar(pedirPermiso: true),
        EstadoUbicacionHex.denegadoSiempre,
      );
      expect(
        await ubicacionReal.verificar(),
        EstadoUbicacionHex.denegadoSiempre,
      );
      plataforma.error = const PermissionDeniedException('negado');
      await expectLater(
        ubicacionReal.posicionActual(),
        throwsA(
          isA<UbicacionNoDisponibleHex>().having(
            (e) => e.estado,
            'estado',
            EstadoUbicacionHex.denegadoSiempre,
          ),
        ),
      );
      plataforma.permiso = LocationPermission.whileInUse;
      expect(await ubicacionReal.verificar(), EstadoUbicacionHex.lista);
      plataforma.permiso = LocationPermission.denied;
      expect(await ubicacionReal.verificar(), EstadoUbicacionHex.sinPermiso);
    });

    test('un pedido de permiso ya en curso cuenta como sin permiso', () async {
      plataforma.permiso = LocationPermission.denied;
      plataforma.errorAlPedir = const PermissionRequestInProgressException(
        'en curso',
      );
      expect(
        await ubicacionReal.verificar(pedirPermiso: true),
        EstadoUbicacionHex.sinPermiso,
      );
    });

    test(
      'la posición lleva la precisión y pide alta precisión en 20 s',
      () async {
        final p = await ubicacionReal.posicionActual();
        expect(p, (lat: -16.5, lon: -68.15, precision: 8.5));
        expect(plataforma.ajustes?.accuracy, LocationAccuracy.high);
        expect(plataforma.ajustes?.timeLimit, const Duration(seconds: 20));
      },
    );

    test('los fallos del GPS se vuelven UbicacionNoDisponibleHex', () async {
      final casos = <Object, EstadoUbicacionHex?>{
        const LocationServiceDisabledException():
            EstadoUbicacionHex.servicioApagado,
        const PermissionDeniedException('negado'):
            EstadoUbicacionHex.sinPermiso,
        TimeoutException('GPS', const Duration(seconds: 20)): null,
        const PositionUpdateException('sin señal'): null,
      };
      for (final MapEntry(key: error, value: estado) in casos.entries) {
        plataforma.error = error;
        await expectLater(
          ubicacionReal.posicionActual(),
          throwsA(
            isA<UbicacionNoDisponibleHex>().having(
              (e) => e.estado,
              'estado',
              estado,
            ),
          ),
          reason: '$error',
        );
      }
    });

    test('servicioActivo traduce el estado del servicio', () async {
      final valores = ubicacionReal.servicioActivo().take(2).toList();
      plataforma.estados
        ..add(ServiceStatus.disabled)
        ..add(ServiceStatus.enabled);
      expect(await valores, [false, true]);
    });

    test('abre los ajustes de ubicación y los de la app', () async {
      await ubicacionReal.abrirAjustesUbicacion();
      await ubicacionReal.abrirAjustesApp();
      expect(plataforma.abiertos, ['ubicacion', 'app']);
    });
  });
}

/// Plataforma de geolocator sin GPS: responde lo que la prueba fija.
class _PlataformaFalsa extends GeolocatorPlatform {
  bool servicio = true;
  LocationPermission permiso = LocationPermission.whileInUse;
  LocationPermission alPedir = LocationPermission.whileInUse;
  Exception? errorAlPedir;
  Object? error;
  int pedidos = 0;
  LocationSettings? ajustes;
  final List<String> abiertos = [];
  final StreamController<ServiceStatus> estados =
      StreamController<ServiceStatus>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => servicio;

  @override
  Future<LocationPermission> checkPermission() async => permiso;

  @override
  Future<LocationPermission> requestPermission() async {
    pedidos++;
    final e = errorAlPedir;
    if (e != null) throw e;
    return alPedir;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    ajustes = locationSettings;
    final e = error;
    if (e != null) throw e;
    return Position(
      latitude: -16.5,
      longitude: -68.15,
      accuracy: 8.5,
      timestamp: DateTime(2026, 10, 30, 19, 40),
      altitude: 3640,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() => estados.stream;

  @override
  Future<bool> openLocationSettings() async {
    abiertos.add('ubicacion');
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    abiertos.add('app');
    return true;
  }
}
