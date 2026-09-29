import 'dart:async';

import 'package:bosque_flutter/core/state/garantias_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/models/accion_cbr_model.dart';
import 'package:bosque_flutter/data/models/cbr_detalle_model.dart';
import 'package:bosque_flutter/data/models/garantia_resumen_cliente_model.dart';
import 'package:bosque_flutter/data/models/garantia_vista_model.dart';
import 'package:bosque_flutter/data/models/tipo_cbr_model.dart';
import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/cliente_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_cbr_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_resumen_cliente_entity.dart';
import 'package:bosque_flutter/domain/entities/garantia_vista_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_cbr_entity.dart';
import 'package:bosque_flutter/domain/repositories/garantias_repository.dart';
import 'package:bosque_flutter/presentation/screens/garantias/garantias_screen.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/detalle_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/dialogos_garantias.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/formularios_garantia.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/garantias_cliente.dart';
import 'package:bosque_flutter/presentation/widgets/garantias/piezas_garantias.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// El modulo de garantias no puede volver a congelar la pantalla.
///
/// **Lo que paso (2026-09-21):** el detalle de una garantia mostraba la espera
/// de documentos y acciones con `EsqueletoLista`, que es un `ListView`, dentro
/// del cuerpo de `MarcoPanel`, que ya va en un `SingleChildScrollView`. La
/// lista recibia altura infinita, reventaba con "Vertical viewport was given
/// unbounded height" y el panel quedaba sin tamano: ningun toque le llegaba.
/// `flutter analyze` no lo ve; solo aparece al dibujar, y solo mientras carga.
///
/// Por eso aqui se abre **cada panel del modulo en cada estado que puede
/// tener** —esperando, con error, vacio y con datos— a ancho de telefono y de
/// escritorio, con un repositorio falso que puede quedarse esperando para
/// siempre. Cualquier excepcion de layout hace fallar la prueba.
void main() {
  // AppConstants.baseUrl lee dotenv; sin esto, PermissionWidget revienta al
  // armar el cliente HTTP antes de dibujar nada.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  final tamanos = <String, Size>{
    'telefono chico 320x640': const Size(320, 640),
    'telefono 360x740': const Size(360, 740),
    'tablet 800x1200': const Size(800, 1200),
    'escritorio 1280x800': const Size(1280, 800),
    'escritorio 1920x1080': const Size(1920, 1080),
  };

  // ── Control: prueba que el banco de pruebas SI detecta este error ─────────
  testWidgets('control: EsqueletoLista suelto en un panel revienta '
      '(por eso existe EsperaEnPanel)', (tester) async {
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      repo: _RepoFalso(),
      abrir:
          (context) => abrirPanel<void>(
            context,
            contenido:
                (_) => const MarcoPanel(
                  titulo: 'Control',
                  cuerpo: Column(children: [EsqueletoLista(filas: 2)]),
                ),
          ),
    );
    expect(
      _errores.map((d) => d.exceptionAsString()).join(),
      contains('unbounded height'),
    );
  });

  testWidgets('control: EsperaEnPanel en un panel no revienta', (tester) async {
    await _abrir(
      tester,
      tamano: const Size(1280, 800),
      repo: _RepoFalso(),
      abrir:
          (context) => abrirPanel<void>(
            context,
            contenido:
                (_) => const MarcoPanel(
                  titulo: 'Control',
                  cuerpo: Column(children: [EsperaEnPanel(filas: 2)]),
                ),
          ),
    );
    _sinErrores(tester);
  });

  for (final t in tamanos.entries) {
    final tam = t.value;

    // ── Pantalla principal ──────────────────────────────────────────────────
    for (final estado in _Estado.values) {
      testWidgets('pantalla principal ${estado.name} en ${t.key}', (
        tester,
      ) async {
        await _dibujarPantalla(tester, tam, _RepoFalso(resumen: estado));
        _sinErrores(tester);
      });
    }

    // ── Vista «Por garantía» ────────────────────────────────────────────────
    for (final estado in _Estado.values) {
      testWidgets('por garantia ${estado.name} en ${t.key}', (tester) async {
        await _dibujarPorGarantia(tester, tam, _RepoFalso(lista: estado));
        _sinErrores(tester);
      });
    }

    // ── Detalle de una garantia ─────────────────────────────────────────────
    final casosDetalle = <String, _RepoFalso>{
      // El caso que congelaba la pantalla.
      'documentos y acciones cargando': _RepoFalso(
        detalles: _Estado.espera,
        acciones: _Estado.espera,
      ),
      'garantia cargando': _RepoFalso(garantia: _Estado.espera),
      'garantia con error': _RepoFalso(garantia: _Estado.error),
      'garantia inexistente': _RepoFalso(garantia: _Estado.vacio),
      'documentos y acciones con error': _RepoFalso(
        detalles: _Estado.error,
        acciones: _Estado.error,
      ),
      'sin documentos ni acciones': _RepoFalso(
        detalles: _Estado.vacio,
        acciones: _Estado.vacio,
      ),
      'con datos': _RepoFalso(),
      'catalogos cargando': _RepoFalso(catalogos: _Estado.espera),
      // Los avisos de estado (cerrada, caducada, por vencer) cambian el texto
      // de arriba del detalle: tienen que entrar a todos los anchos.
      'garantia cerrada': _RepoFalso(
        garantiaDato: _garantiaCerrada,
        accionesDato: _accionesCerrada,
      ),
      'garantia caducada con traspaso': _RepoFalso(
        garantiaDato: _garantiaCaducada,
      ),
      'garantia caducada sin traspaso': _RepoFalso(
        garantiaDato: _garantiaCaducadaSinTraspaso,
      ),
      'garantia por vencer': _RepoFalso(garantiaDato: _garantia),
    };
    for (final caso in casosDetalle.entries) {
      testWidgets('detalle: ${caso.key} en ${t.key}', (tester) async {
        await _abrir(
          tester,
          tamano: tam,
          repo: caso.value,
          abrir: (c) => abrirDetalleGarantia(c, BigInt.from(162)),
        );
        _sinErrores(tester);
      });
    }

    // ── Garantias de un cliente ─────────────────────────────────────────────
    for (final estado in _Estado.values) {
      testWidgets('garantias del cliente ${estado.name} en ${t.key}', (
        tester,
      ) async {
        await _abrir(
          tester,
          tamano: tam,
          repo: _RepoFalso(lista: estado),
          abrir: (c) => abrirGarantiasCliente(c, _resumen.first),
        );
        _sinErrores(tester);
      });
    }

    // ── Formularios y dialogos ──────────────────────────────────────────────
    final dialogos = <String, Future<void> Function(BuildContext)>{
      'alta': (c) => abrirAltaGarantia(c),
      'alta con cliente elegido':
          (c) => abrirAltaGarantia(
            c,
            cliente: const ClienteSapEntity(
              codClienteSAP: 'ADI0229',
              datoCliente: _nombreLargo,
            ),
          ),
      'edicion': (c) => abrirEdicionGarantia(c, _garantia),
      'edicion administrativa': (c) => abrirEdicionAdministrativa(c, _garantia),
      'documento nuevo':
          (c) => abrirDocumento(c, codGarantia: BigInt.from(162)),
      'documento existente':
          (c) => abrirDocumento(
            c,
            codGarantia: BigInt.from(162),
            existente: _detalles.first,
          ),
      'nota nueva': (c) => abrirAccion(c, garantia: _garantia),
      'accion existente':
          (c) => abrirAccion(c, garantia: _garantia, existente: _acciones.last),
      'cierre con traspaso': (c) => abrirCierre(c, _garantiaCaducada),
      'cierre sin traspaso': (c) => abrirCierre(c, _garantia),
      'guia del modulo': (c) => mostrarGuiaGarantias(c),
      'extension': (c) => abrirExtension(c, _garantia),
      'firmas y protesta': (c) => abrirFirmasYProtesta(c, _garantia),
      'traspaso': (c) => abrirTraspaso(c),
      'reporte': (c) => abrirReporte(c, _resumen),
    };
    for (final d in dialogos.entries) {
      for (final catalogos in [_Estado.datos, _Estado.espera, _Estado.error]) {
        testWidgets('${d.key} con catalogos ${catalogos.name} en ${t.key}', (
          tester,
        ) async {
          await _abrir(
            tester,
            tamano: tam,
            repo: _RepoFalso(catalogos: catalogos, pendientes: catalogos),
            abrir: d.value,
          );
          _sinErrores(tester);
        });
      }
    }
  }

  // ── Comportamiento del cierre: que sea explicito y no se haga por descuido ──
  group('cierre de una garantia', () {
    testWidgets(
      'con traspaso: el boton espera a "Entiendo que es definitivo"',
      (tester) async {
        await _abrir(
          tester,
          tamano: const Size(1280, 800),
          repo: _RepoFalso(),
          abrir: (c) => abrirCierre(c, _garantiaCaducada),
        );
        _sinErrores(tester);

        expect(find.textContaining('no se puede deshacer'), findsOneWidget);
        expect(find.text('Motivo del cierre'), findsOneWidget);
        expect(_botonCerrar(tester).enabled, isFalse);

        await tester.tap(find.text('Entiendo que el cierre es definitivo.'));
        await tester.pump();
        expect(_botonCerrar(tester).enabled, isTrue);
      },
    );

    testWidgets('sin traspaso: explica por que y no deja confirmar', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirCierre(c, _garantia),
      );
      _sinErrores(tester);

      expect(find.textContaining('Todavía no se puede cerrar'), findsOneWidget);
      expect(find.text('Entiendo que el cierre es definitivo.'), findsNothing);
      expect(_botonCerrar(tester).enabled, isFalse);
    });

    testWidgets('el detalle ofrece "Cerrar garantía" aparte de las notas', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(garantiaDato: _garantiaCaducada),
        abrir: (c) => abrirDetalleGarantia(c, BigInt.from(162)),
      );
      _sinErrores(tester);

      expect(find.text('Cerrar garantía'), findsOneWidget);
      expect(find.text('Nueva nota'), findsOneWidget);
      expect(find.textContaining('vencerse no la cierra'), findsOneWidget);
    });

    testWidgets('una garantia cerrada dice cuando, por que y oculta el boton', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(
          garantiaDato: _garantiaCerrada,
          accionesDato: _accionesCerrada,
        ),
        abrir: (c) => abrirDetalleGarantia(c, BigInt.from(163)),
      );
      _sinErrores(tester);

      expect(find.textContaining('Garantía cerrada el'), findsOneWidget);
      expect(
        find.textContaining('Deuda cancelada por el cliente'),
        findsWidgets,
      );
      expect(find.text('Cerrar garantía'), findsNothing);
      expect(find.text('Nueva nota'), findsNothing);
    });
  });

  // ── Que el usuario entienda que esta viendo ─────────────────────────────────
  group('explicaciones', () {
    testWidgets('la guia explica el recorrido, los estados y cada dato', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => mostrarGuiaGarantias(c),
      );
      _sinErrores(tester);

      expect(find.text('El recorrido de una garantía'), findsOneWidget);
      expect(find.text('Traspasarla a custodia'), findsOneWidget);
      expect(find.text('¿Cuándo se cierra una garantía?'), findsOneWidget);
      expect(find.text('Qué significa cada dato'), findsOneWidget);
      for (final t in Glosario.enGuia) {
        expect(find.text(t.ayuda), findsOneWidget, reason: t.nombre);
      }
    });

    testWidgets('cada columna de la planilla trae su explicacion', (
      tester,
    ) async {
      await _dibujarPantalla(tester, const Size(1920, 1080), _RepoFalso());
      _sinErrores(tester);

      for (final t in [
        Glosario.vigentes,
        Glosario.valorVigente,
        Glosario.lineaVigente,
        Glosario.lineaSap,
        Glosario.saldoSap,
        Glosario.proximoVencimiento,
      ]) {
        expect(find.byTooltip(t.ayuda), findsWidgets, reason: t.nombre);
      }
      expect(find.text('¿Cómo funciona?'), findsOneWidget);
    });

    testWidgets('en el telefono la guia esta en el menu', (tester) async {
      await _dibujarPantalla(tester, const Size(360, 740), _RepoFalso());
      _sinErrores(tester);

      await tester.tap(find.byTooltip('Más acciones'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('¿Cómo funciona?'), findsOneWidget);
    });

    testWidgets('el detalle dice en que etapa esta y que sigue', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirDetalleGarantia(c, BigInt.from(162)),
      );
      _sinErrores(tester);

      // Cada etapa es un solo texto: nombre + fecha (o «pendiente»).
      // «Registrada» esta en el recorrido y en la ficha de datos.
      expect(
        find.textContaining('Registrada', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('En custodia  pendiente', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Siguiente paso: traspasarla'),
        findsOneWidget,
      );
      expect(find.byTooltip(Glosario.sinTraspaso.ayuda), findsOneWidget);
      expect(find.byTooltip(Glosario.lineaSap.ayuda), findsOneWidget);
    });

    testWidgets('los mismos nombres en el panel del cliente', (tester) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirGarantiasCliente(c, _resumen.first),
      );
      _sinErrores(tester);

      expect(find.text(Glosario.valor.nombre), findsWidgets);
      expect(find.text(Glosario.plazoPago.nombre), findsWidgets);
      expect(find.text('Pago a'), findsNothing);
      expect(find.text('Monto garantizado'), findsNothing);
    });
  });

  group('Esc cierra los paneles', () {
    testWidgets('sin tocar nada, Esc cierra el detalle', (tester) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirDetalleGarantia(c, BigInt.from(162)),
      );
      expect(find.byType(MarcoPanel), findsOneWidget);

      await _esc(tester);
      _sinErrores(tester);
      expect(find.byType(MarcoPanel), findsNothing);
    });

    testWidgets('con paneles apilados cierra solo el de arriba', (
      tester,
    ) async {
      // Como en la app: el detalle abierto desde el panel del cliente.
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) async {
          abrirGarantiasCliente(c, _resumen.first);
          await abrirDetalleGarantia(c, BigInt.from(162));
        },
      );
      expect(find.byType(MarcoPanel), findsNWidgets(2));
      expect(find.text('Garantía N° 162'), findsOneWidget);

      await _esc(tester);
      expect(find.byType(MarcoPanel), findsOneWidget);
      expect(find.text('Garantía N° 162'), findsNothing);

      await _esc(tester);
      _sinErrores(tester);
      expect(find.byType(MarcoPanel), findsNothing);
    });

    testWidgets('Esc hace lo mismo que la X: mientras guarda, nada', (
      tester,
    ) async {
      var veces = 0;
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir:
            (c) => abrirPanel<void>(
              c,
              // Lo que pasan los paneles mientras guardan: una X que no cierra.
              contenido:
                  (_) => MarcoPanel(
                    titulo: 'Guardando',
                    onCerrar: () => veces++,
                    cuerpo: const Text('…'),
                  ),
            ),
      );

      await _esc(tester);
      expect(veces, 1);
      expect(find.byType(MarcoPanel), findsOneWidget);
    });

    testWidgets('en un formulario con cambios, Esc pregunta antes de '
        'descartar', (tester) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirAltaGarantia(c),
      );
      await _capturando(() async {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Observación del registro'),
          'algo escrito',
        );
        await _avanzar(tester);
      });

      await _esc(tester);
      _sinErrores(tester);
      expect(find.text('¿Descartar los cambios?'), findsOneWidget);
      expect(find.byType(MarcoPanel), findsOneWidget);

      await _tocar(tester, find.text('Descartar'));
      expect(find.byType(MarcoPanel), findsNothing);
    });

    testWidgets('con el menu ⋮ abierto, Esc cierra el menu y despues el '
        'panel', (tester) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirGarantiasCliente(c, _resumen.first),
      );
      await _tocar(tester, find.byTooltip('Más acciones').first);
      expect(find.text('Recibo en PDF'), findsOneWidget);

      await _esc(tester);
      expect(find.text('Recibo en PDF'), findsNothing);
      expect(find.byType(MarcoPanel), findsOneWidget);

      await _esc(tester);
      _sinErrores(tester);
      expect(find.byType(MarcoPanel), findsNothing);
    });
  });

  // ── Menu ⋮ y ventana que cambia de tamano ────────────────────────────────────
  //
  // Lo que paso (2026-09-24): con el menu ⋮ de una fila abierto, la ventana
  // cambio de tamano, la fila paso de diseno angosto a ancho y el boton del
  // menu se reemplazo. El menu de PopupMenuButton recalculaba su posicion con
  // el boton que ya no existia y la pantalla quedaba roja: "Looking up a
  // deactivated widget's ancestor is unsafe". Ahora es MenuAcciones.
  group('menu y cambio de tamano de la ventana', () {
    testWidgets('con el menu abierto, agrandar la ventana no rompe nada', (
      tester,
    ) async {
      // Angosto: a pantalla completa y con todas las acciones en el menu.
      await _abrir(
        tester,
        tamano: const Size(560, 900),
        repo: _RepoFalso(),
        abrir: (c) => abrirGarantiasCliente(c, _resumen.first),
      );
      await _tocar(tester, find.byTooltip('Más acciones').first);
      expect(find.text('Recibo en PDF'), findsOneWidget);

      await _capturando(() async {
        tester.view.physicalSize = const Size(1906, 930);
        await _avanzar(tester);
      });
      _sinErrores(tester);
      expect(find.text('Recibo en PDF'), findsNothing, reason: 'se cierra');
      expect(find.byType(MarcoPanel), findsOneWidget);
    });

    testWidgets('elegir una opcion del menu la ejecuta; la deshabilitada dice '
        'por que', (tester) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirGarantiasCliente(c, _resumen.first),
      );
      await _tocar(tester, find.byTooltip('Más acciones').first);
      expect(
        find.textContaining('primero debe hacerse el traspaso'),
        findsOneWidget,
      );

      await _tocar(tester, find.text('Editar firmas y documentos'));
      _sinErrores(tester);
      expect(find.text('Editar garantía'), findsOneWidget);
      expect(find.byType(MarcoPanel), findsNWidgets(2));
    });

    testWidgets('el panel sigue a la ventana y no pierde lo escrito', (
      tester,
    ) async {
      await _abrir(
        tester,
        tamano: const Size(1280, 800),
        repo: _RepoFalso(),
        abrir: (c) => abrirAltaGarantia(c),
      );
      await _capturando(() async {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Observación del registro'),
          'algo escrito',
        );
        await _avanzar(tester);
      });
      double ancho() => tester.getSize(find.byType(MarcoPanel)).width;
      expect(ancho(), 760, reason: 'dialogo con el ancho del alta');

      await _capturando(() async {
        tester.view.physicalSize = const Size(390, 800);
        await _avanzar(tester);
      });
      _sinErrores(tester);
      expect(ancho(), 390, reason: 'a pantalla completa en el telefono');
      expect(find.text('algo escrito'), findsOneWidget);

      await _capturando(() async {
        tester.view.physicalSize = const Size(1280, 800);
        await _avanzar(tester);
      });
      _sinErrores(tester);
      expect(ancho(), 760, reason: 'otra vez dialogo');
      expect(find.text('algo escrito'), findsOneWidget);
    });

    // Las pruebas de arriba miran cinco anchos fijos; los desbordes aparecian
    // entre medio (a 900 y 1000 px). Aqui la ventana se estira y se encoge de
    // a poco, como al arrastrar su borde.
    final arrastres = <String, Future<void> Function(WidgetTester)>{
      'pantalla por cliente':
          (t) => _dibujarPantalla(t, const Size(320, 900), _RepoFalso()),
      'pantalla por garantia':
          (t) => _dibujarPorGarantia(t, const Size(320, 900), _RepoFalso()),
      'panel del cliente abierto en el telefono':
          (t) => _abrir(
            t,
            tamano: const Size(320, 900),
            repo: _RepoFalso(),
            abrir: (c) => abrirGarantiasCliente(c, _resumen.first),
          ),
      'panel del cliente abierto en escritorio':
          (t) => _abrir(
            t,
            tamano: const Size(1920, 900),
            repo: _RepoFalso(),
            abrir: (c) => abrirGarantiasCliente(c, _resumen.first),
          ),
      'detalle':
          (t) => _abrir(
            t,
            tamano: const Size(320, 900),
            repo: _RepoFalso(),
            abrir: (c) => abrirDetalleGarantia(c, BigInt.from(162)),
          ),
      'alta':
          (t) => _abrir(
            t,
            tamano: const Size(1280, 900),
            repo: _RepoFalso(),
            abrir: (c) => abrirAltaGarantia(c),
          ),
    };
    for (final a in arrastres.entries) {
      testWidgets('${a.key}: ningun ancho de 320 a 1920 px desborda', (
        tester,
      ) async {
        await a.value(tester);
        _sinErrores(tester);
        await _arrastrarBorde(tester);
      });
    }
  });

  group('vista por garantia', () {
    final n = DateTime.now();
    final hoy = DateTime(n.year, n.month, n.day);

    testWidgets('numera las filas en la tabla y en las tarjetas', (
      tester,
    ) async {
      await _dibujarPorGarantia(tester, const Size(1280, 800), _RepoFalso());
      _sinErrores(tester);
      expect(find.text('#'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('N° 162'), findsOneWidget);

      await _dibujarPorGarantia(tester, const Size(360, 740), _RepoFalso());
      _sinErrores(tester);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
    });

    testWidgets('el rango de vencimiento lo filtra el servidor y queda a la '
        'vista con su cruz', (tester) async {
      final repo = _RepoFalso();
      await _dibujarPorGarantia(tester, const Size(1280, 800), repo);
      expect(repo.ultimoListado?.vencDesde, isNull);

      await _tocar(tester, find.text('Filtrar por fechas'));
      await _tocar(tester, find.text('Vencen en los próximos 30 días'));
      _sinErrores(tester);
      expect(repo.ultimoListado?.vencDesde, hoy);
      expect(repo.ultimoListado?.vencHasta, hoy.add(const Duration(days: 30)));
      expect(repo.ultimoListado?.regDesde, isNull);
      expect(find.text('Vencen en los próximos 30 días'), findsOneWidget);
      expect(find.text('Filtrar por fechas'), findsNothing);

      await _tocar(tester, find.byTooltip('Quitar el filtro de fechas'));
      expect(repo.ultimoListado?.vencDesde, isNull);
      expect(find.text('Filtrar por fechas'), findsOneWidget);
    });

    testWidgets('el rango de registro va por la fecha de registro', (
      tester,
    ) async {
      final repo = _RepoFalso();
      await _dibujarPorGarantia(tester, const Size(1280, 800), repo);
      await _tocar(tester, find.text('Filtrar por fechas'));
      await _tocar(tester, find.text('Registradas este mes'));
      _sinErrores(tester);
      expect(repo.ultimoListado?.regDesde, DateTime(hoy.year, hoy.month));
      expect(repo.ultimoListado?.regHasta, hoy);
      expect(repo.ultimoListado?.vencDesde, isNull);
    });

    testWidgets('un estado sin garantias ofrece quitar los filtros', (
      tester,
    ) async {
      await _dibujarPorGarantia(tester, const Size(1280, 800), _RepoFalso());
      await _tocar(tester, find.widgetWithText(ChoiceChip, 'Caducadas'));
      _sinErrores(tester);
      expect(find.text('Ninguna garantía cumple el filtro'), findsOneWidget);
      expect(find.text('N° 162'), findsNothing);

      await _tocar(tester, find.text('Quitar filtros'));
      expect(find.text('N° 162'), findsOneWidget);
    });

    testWidgets('la barra de vigencia pinta el tramo transcurrido', (
      tester,
    ) async {
      // Una caducada lleva el plazo entero transcurrido: el tramo de color
      // tiene que cubrir toda la pista. Paso que midiera 0 de alto.
      _tamano(tester, const Size(400, 200));
      await _capturando(() async {
        await tester.pumpWidget(
          _app(
            _RepoFalso(),
            Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: BarraVigencia(garantia: _garantiaCaducada),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      });
      _sinErrores(tester);
      final cajas =
          find
              .descendant(
                of: find.byType(BarraVigencia),
                matching: find.byType(ColoredBox),
              )
              .evaluate()
              .map((e) => tester.getSize(find.byWidget(e.widget)))
              .toList();
      expect(cajas, hasLength(2));
      final (pista, tramo) = (cajas[0], cajas[1]);
      expect(tramo.height, pista.height);
      expect(tramo.width, closeTo(pista.width, 0.5));
    });

    testWidgets('en el telefono los filtros van plegados', (tester) async {
      await _dibujarPorGarantia(tester, const Size(360, 740), _RepoFalso());
      expect(find.text('Filtrar por fechas'), findsNothing);

      await _tocar(tester, find.byTooltip('Mostrar filtros'));
      _sinErrores(tester);
      expect(find.text('Filtrar por fechas'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Por vencer'), findsOneWidget);
    });
  });
}

/// El boton de confirmar del dialogo de cierre.
ButtonStyleButton _botonCerrar(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.text('Cerrar garantía'),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  ),
);

// ═══════════════════════════════════════════════════════════════════════════
// BANCO DE PRUEBAS
// ═══════════════════════════════════════════════════════════════════════════

Widget _app(_RepoFalso repo, Widget home) => ProviderScope(
  overrides: [
    userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(_admin)),
    garantiasRepositoryProvider.overrideWithValue(repo),
  ],
  child: MaterialApp(
    home: home,
    // ResponsiveUtilsBosque lanza si no hay ResponsiveBreakpoints arriba; en la
    // app lo pone main.dart sobre todo el arbol.
    builder:
        (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: ResponsiveUtilsBosque.breakpoints,
        ),
  ),
);

void _tamano(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _dibujarPantalla(
  WidgetTester tester,
  Size tamano,
  _RepoFalso repo,
) async {
  _tamano(tester, tamano);
  await _capturando(() async {
    await tester.pumpWidget(_app(repo, const GarantiasScreen()));
    await _avanzar(tester);
  });
}

/// La pantalla principal ya pasada a la vista «Por garantía».
Future<void> _dibujarPorGarantia(
  WidgetTester tester,
  Size tamano,
  _RepoFalso repo,
) async {
  _tamano(tester, tamano);
  await _capturando(() async {
    await tester.pumpWidget(_app(repo, const GarantiasScreen()));
    await _avanzar(tester);
    await tester.tap(find.textContaining('Por garantía').first);
    await _avanzar(tester);
  });
}

/// Aprieta Esc y deja avanzar, capturando errores de dibujo.
Future<void> _esc(WidgetTester tester) => _capturando(() async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await _avanzar(tester);
});

/// Anchos de ventana para [_arrastrarBorde]: de 20 en 20 hasta 1000 px, donde
/// cambian los disenos, y de 80 en 80 despues.
final _anchosDeArrastre = [
  for (var w = 320.0; w < 1000; w += 20) w,
  for (var w = 1000.0; w <= 1920; w += 80) w,
];

/// Estira la ventana de 320 a 1920 px y la vuelve a encoger, como al arrastrar
/// su borde, y falla con cada error junto al ancho en que aparecio.
Future<void> _arrastrarBorde(WidgetTester tester) async {
  final errores = <String>[];
  for (final w in [..._anchosDeArrastre, ..._anchosDeArrastre.reversed]) {
    await _capturando(() async {
      tester.view.physicalSize = Size(w, 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
    errores.addAll(_errores.map((d) => 'A $w px:\n$d'));
  }
  await _capturando(() => _avanzar(tester));
  errores.addAll(_errores.map((d) => 'Al final:\n$d'));
  if (errores.isNotEmpty) fail(errores.join('\n\n'));
}

/// Toca y deja avanzar, capturando errores de dibujo.
Future<void> _tocar(WidgetTester tester, Finder f) async {
  await _capturando(() async {
    await tester.tap(f);
    await _avanzar(tester);
  });
}

/// Abre el panel desde un boton, como en la app (showDialog necesita contexto).
Future<void> _abrir(
  WidgetTester tester, {
  required Size tamano,
  required _RepoFalso repo,
  required Future<void> Function(BuildContext) abrir,
}) async {
  _tamano(tester, tamano);
  await _capturando(() async {
    await tester.pumpWidget(
      _app(
        repo,
        Scaffold(
          body: Builder(
            builder:
                (context) => Center(
                  child: FilledButton(
                    onPressed: () => abrir(context),
                    child: const Text('abrir'),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await _avanzar(tester);
  });
}

/// Cuadros con tiempo simulado. No `pumpAndSettle`: los esqueletos de espera
/// tienen una animacion que no termina nunca, y ese es justo el estado que hay
/// que dibujar. Los dos minutos del final dejan vencer los temporizadores de la
/// carga real de permisos (PermissionWidget sale a una red que aqui no existe).
Future<void> _avanzar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(minutes: 2));
}

/// Errores de Flutter del ultimo dibujo, con su reporte completo.
final _errores = <FlutterErrorDetails>[];

/// Dibuja capturando cada error de Flutter con su `FlutterErrorDetails`.
///
/// `tester.takeException()` solo entrega la excepcion, y la de un desborde dice
/// "A RenderFlex overflowed by N pixels" sin decir que fila ni en que archivo:
/// eso viaja en el reporte. El manejador se restaura siempre antes de que
/// termine la prueba (flutter_test lo exige).
Future<void> _capturando(Future<void> Function() dibujar) async {
  _errores.clear();
  final original = FlutterError.onError;
  FlutterError.onError = _errores.add;
  try {
    await dibujar();
  } finally {
    FlutterError.onError = original;
  }
}

/// Falla mostrando cada error completo: el widget culpable con archivo y linea.
void _sinErrores(WidgetTester tester) {
  if (_errores.isEmpty) return;
  fail(_errores.map((d) => d.toString()).join('\n\n'));
}

/// ROLE_ADM: tienePermisoDeBoton deja pasar todo y se dibujan todos los botones.
final _admin = LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
});

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORIO FALSO
// ═══════════════════════════════════════════════════════════════════════════

enum _Estado { espera, error, vacio, datos }

class _RepoFalso implements GarantiasRepository {
  _RepoFalso({
    this.resumen = _Estado.datos,
    this.lista = _Estado.datos,
    this.garantia = _Estado.datos,
    this.detalles = _Estado.datos,
    this.acciones = _Estado.datos,
    this.catalogos = _Estado.datos,
    this.pendientes = _Estado.datos,
    this.garantiaDato,
    this.accionesDato,
  });

  /// La garantia que devuelve `obtenerGarantia` con datos (por defecto,
  /// [_garantia]: vigente, por vencer y sin traspaso).
  final GarantiaVistaEntity? garantiaDato;

  /// Las acciones que devuelve `obtenerAcciones` con datos.
  final List<AccionCbrEntity>? accionesDato;

  final _Estado resumen;
  final _Estado lista;
  final _Estado garantia;
  final _Estado detalles;
  final _Estado acciones;
  final _Estado catalogos;
  final _Estado pendientes;

  /// Lo que pidio la ultima llamada a `listarGarantias`: el filtro que le toca
  /// al servidor (fechas y tipo).
  ({
    String? tipo,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  })?
  ultimoListado;

  /// `espera` devuelve un Future que no termina nunca: el panel se queda en su
  /// estado de carga todo lo que dura la prueba.
  Future<T> _segun<T>(_Estado e, T datos, T vacio) {
    switch (e) {
      case _Estado.espera:
        return Completer<T>().future;
      case _Estado.error:
        return Future<T>.error('El servidor no respondió (error de prueba).');
      case _Estado.vacio:
        return Future.value(vacio);
      case _Estado.datos:
        return Future.value(datos);
    }
  }

  @override
  Future<List<GarantiaResumenClienteEntity>> obtenerResumenClientes({
    String? buscar,
  }) => _segun(resumen, _resumen, const []);

  @override
  Future<List<GarantiaVistaEntity>> listarGarantias({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  }) {
    ultimoListado = (
      tipo: tipoGarantia,
      vencDesde: vencDesde,
      vencHasta: vencHasta,
      regDesde: regDesde,
      regHasta: regHasta,
    );
    return _segun(lista, [_garantia, _garantiaCerrada], const []);
  }

  @override
  Future<GarantiaVistaEntity?> obtenerGarantia(BigInt codGarantia) =>
      _segun<GarantiaVistaEntity?>(garantia, garantiaDato ?? _garantia, null);

  @override
  Future<List<ClienteSapEntity>> buscarClientesSap(String buscar) =>
      Future.value(const [
        ClienteSapEntity(codClienteSAP: 'ADI0229', datoCliente: _nombreLargo),
      ]);

  @override
  Future<List<CbrDetalleEntity>> obtenerDetalles(BigInt codGarantia) =>
      _segun(detalles, _detalles, const []);

  @override
  Future<List<AccionCbrEntity>> obtenerAcciones(BigInt codGarantia) =>
      _segun(acciones, List.of(accionesDato ?? _acciones), const []);

  @override
  Future<int> contarTraspasosPendientes() => _segun(pendientes, 107, 0);

  @override
  Future<List<TipoCbrEntity>> obtenerTiposGarantia() =>
      _segun(catalogos, _tipos, const []);

  @override
  Future<List<TipoCbrEntity>> obtenerEstadosAccion() =>
      _segun(catalogos, _estadosAccion, const []);

  // Las escrituras y los PDF no se usan: solo se dibuja.
  @override
  Future<BigInt> registrarGarantia(GarantiaRegistroEntity registro) =>
      throw UnimplementedError();
  @override
  Future<BigInt> actualizarGarantia(GarantiaCbrEntity garantia) =>
      throw UnimplementedError();
  @override
  Future<BigInt> registrarExtension({
    required BigInt codGarantia,
    required DateTime fecha,
    required String? observacion,
    required DateTime fechaExpiracion,
  }) => throw UnimplementedError();
  @override
  Future<BigInt> registrarDetalle(CbrDetalleEntity detalle) =>
      throw UnimplementedError();
  @override
  Future<BigInt> eliminarDetalle(BigInt codDetalle) =>
      throw UnimplementedError();
  @override
  Future<BigInt> registrarAccion(AccionCbrEntity accion) =>
      throw UnimplementedError();
  @override
  Future<BigInt> eliminarAccion(BigInt codAccion) => throw UnimplementedError();
  @override
  Future<int> generarTraspaso() => throw UnimplementedError();
  @override
  Future<Uint8List> reporteRecibo(BigInt codGarantia) =>
      throw UnimplementedError();
  @override
  Future<Uint8List> reporteTraspaso() => throw UnimplementedError();
  @override
  Future<Uint8List> reporteBusqueda({
    String? codClienteSAP,
    String? estado,
    String? tipoGarantia,
    DateTime? vencDesde,
    DateTime? vencHasta,
    DateTime? regDesde,
    DateTime? regHasta,
  }) => throw UnimplementedError();
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS
//
// Armados con los Model.fromJson reales y con la forma que devuelve el backend
// (fechas "yyyy-MM-dd HH:mm:ss"), a partir de la garantia 162 de PRUEBA. Los
// textos largos son a proposito: el nombre SAP y las observaciones llegan asi.
// ═══════════════════════════════════════════════════════════════════════════

const _nombreLargo =
    'ADDY  SALAZAR ORTIZ - EDITORA MENDEZ - CBBA - IMPRESIONES Y SERVICIOS GRAFICOS';
const _textoLargo =
    'Firma de Reconocimiento de deuda con garantia personal del Sr Cesar '
    'Antonio Mendez Montaño, con pagare al 31 de diciembre por Bs 14000 que se '
    'ingresa despues del reconocimiento y queda en custodia de cobranzas.';

Map<String, dynamic> _garantiaJson({
  int codGarantia = 162,
  String estado = 'VIGENTE',
  int traspasada = 0,
  int diasParaVencer = 14,
  String fechaExpiracion = '2026-10-05 00:00:00',
}) => {
  'codGarantia': codGarantia,
  'codClienteSAP': 'ADI0229',
  'montoGarantia': 1250000.5,
  'montoCredito': 14000,
  'tiempoPago': 30,
  'fechaInicio': '2026-02-23 00:00:00',
  'fechaExpiracion': fechaExpiracion,
  'montoGarantiaCalc': 1250000.5,
  'recFirmas': 'RF-000123',
  'nroProtesta': null,
  'audUsuario': 47,
  'audFecha': '2026-03-17 14:46:25',
  'datoCliente': _nombreLargo,
  'datoEstado': estado,
  'diasParaVencer': diasParaVencer,
  'creditLine': 21000,
  'balance': 3500.75,
  'traspasada': traspasada,
  'cantDetalles': 2,
  'tiposGarantia': 'RECONOCIMIENTO DE DEUDA, PAGARE',
  'fechaRegistro': '2026-03-17 14:46:25',
  'observacionRegistro': _textoLargo,
  'realizoEmp': 'ZEBALLOS  ZUE HELEN SCARLET',
};

final _garantia = GarantiaVistaModel.fromJson(_garantiaJson()).toEntity();
final _garantiaCerrada =
    GarantiaVistaModel.fromJson(
      _garantiaJson(codGarantia: 163, estado: 'CERRADO', traspasada: 1),
    ).toEntity();
final _garantiaCaducada =
    GarantiaVistaModel.fromJson(
      _garantiaJson(
        estado: 'CADUCADO',
        traspasada: 1,
        diasParaVencer: -45,
        fechaExpiracion: '2026-08-07 00:00:00',
      ),
    ).toEntity();
final _garantiaCaducadaSinTraspaso =
    GarantiaVistaModel.fromJson(
      _garantiaJson(
        estado: 'CADUCADO',
        diasParaVencer: -45,
        fechaExpiracion: '2026-08-07 00:00:00',
      ),
    ).toEntity();

/// Historial de una garantia cerrada: registro, traspaso y cierre con motivo.
final _accionesCerrada = [
  for (final (cod, fecha, estado, obs) in [
    (401, '2026-03-17 14:46:25', 'REG', 'Recepción de la garantía.'),
    (402, '2026-03-20 09:00:00', 'TRASP', ' '),
    (
      403,
      '2026-09-10 11:30:00',
      'CER',
      'Deuda cancelada por el cliente; se devuelve el pagaré original.',
    ),
  ])
    AccionCbrModel.fromJson({
      'codAccion': cod,
      'codGarantia': 163,
      'fecha': fecha,
      'estado': estado,
      'observacion': obs,
      'audUsuario': 47,
      'audFecha': fecha,
    }).toEntity(),
];

final _detalles = [
  for (final j in [
    {
      'codDetalle': 219,
      'codGarantia': 162,
      'fecha': '2026-03-17 14:46:25',
      'tipoGarantia': 'RDD',
      'detalle': _textoLargo,
      'montoGarantiaParc': 1000000,
      'audUsuario': 47,
      'audFecha': '2026-03-17 14:46:25',
    },
    {
      'codDetalle': 220,
      'codGarantia': 162,
      'fecha': '2026-04-03 00:00:00',
      'tipoGarantia': 'PAG',
      'detalle': 'Pagare 123',
      'montoGarantiaParc': 250000.5,
      'audUsuario': 47,
      'audFecha': '2026-04-03 00:00:00',
    },
  ])
    CbrDetalleModel.fromJson(j).toEntity(),
];

final _acciones = [
  for (final j in [
    {
      'codAccion': 330,
      'codGarantia': 162,
      'fecha': '2026-03-17 14:46:25',
      'estado': 'REG',
      'observacion': _textoLargo,
      'audUsuario': 47,
      'audFecha': '2026-03-17 14:46:25',
    },
    {
      'codAccion': 364,
      'codGarantia': 162,
      'fecha': '2026-04-03 00:00:00',
      'estado': 'NOT',
      'observacion': 'Pagare al 31 de diciembre por Bs 14000.',
      'audUsuario': 47,
      'audFecha': '2026-04-03 00:00:00',
    },
  ])
    AccionCbrModel.fromJson(j).toEntity(),
];

final _resumen = [
  for (final j in [
    {
      'codClienteSAP': 'ADI0229',
      'datoCliente': _nombreLargo,
      'cantGarantias': 3,
      'cantVigentes': 1,
      'montoGarantia': 1250000.5,
      'montoCredito': 14000,
      'proximoVencimiento': '2026-10-05 00:00:00',
      'diasParaVencer': 14,
      'creditLine': 21000,
      'balance': 3500.75,
    },
    {
      'codClienteSAP': 'AC00592',
      'datoCliente': 'ACNO',
      'cantGarantias': 1,
      'cantVigentes': 0,
      'montoGarantia': 0,
      'montoCredito': 0,
      'proximoVencimiento': null,
      'diasParaVencer': null,
      'creditLine': 0,
      'balance': 0,
    },
  ])
    GarantiaResumenClienteModel.fromJson(j).toEntity(),
];

final _tipos = [
  for (final (c, n) in [
    ('CDS', 'CONTRATO DE SUMINISTRO'),
    ('INM', 'INMUEBLE'),
    ('PAG', 'PAGARE'),
    ('RDD', 'RECONOCIMIENTO DE DEUDA'),
    ('VEH', 'VEHICULO'),
  ])
    TipoCbrModel.fromJson({
      'codTipos': c,
      'nombre': n,
      'codGrupo': 28,
    }).toEntity(),
];

final _estadosAccion = [
  for (final (c, n) in [
    ('REG', 'REGISTRADO BOSQUE'),
    ('TRASP', 'TRASPASO'),
    ('EXT', 'EXTENSION'),
    ('NOT', 'NOTA'),
    ('CER', 'CERRADO'),
  ])
    TipoCbrModel.fromJson({
      'codTipos': c,
      'nombre': n,
      'codGrupo': 29,
    }).toEntity(),
];
