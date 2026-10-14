// Escribir en el Arqueo reconstruye solo lo que cambia (2026-10-13).
//
// Antes cada número reconstruía la pantalla entera y en celulares de gama
// media (Xiaomi, Redmi, Infinix…) el teclado se trababa. Ahora una cantidad
// mueve su fila, el subtotal y la barra del total; nada más.
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/arqueo_caja_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _respuestas = <String, Object>{
  AppConstants.tarObtenerCorte: [
    for (final (id, valor, tipo) in [
      (1, 200.0, 'BS'),
      (2, 100.0, 'BS'),
      (3, 50.0, 'BS'),
      (4, 100.0, 'USD'),
    ])
      {
        'idCorte': id,
        'descripcion': 'Billete',
        'corte': valor,
        'tipoCorte': tipo,
      },
  ],
  AppConstants.tarObtenerDocumentacion: [
    {'idDoc': 1, 'nombre': 'Depósitos'},
  ],
};

final _existentes = <Element>{};

/// Anota los elementos que ya están en el árbol, antes de escribir.
void _anotarExistentes(WidgetTester t) {
  _existentes.clear();
  void visitar(Element e) {
    _existentes.add(e);
    e.visitChildren(visitar);
  }

  t.binding.rootElement!.visitChildren(visitar);
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL_DEV=http://prueba.local');
    DioClient.getInstance().interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (o, h) {
          final datos = _respuestas[o.path];
          if (datos == null) {
            return h.resolve(Response(requestOptions: o, statusCode: 204));
          }
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: {'message': 'ok', 'data': datos, 'status': 200},
            ),
          );
        },
      ),
    );
  });

  Future<void> abrir(WidgetTester t, double ancho) async {
    t.view.physicalSize = Size(ancho, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith(
            (ref) => UserStateNotifier.sinStorage(null),
          ),
        ],
        child: const MaterialApp(
          home: ArqueoCajaScreen(
            idTarRuti: 1,
            idBitTarea: 1,
            nombreTarea: 'Arqueo de Caja',
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  for (final (nombre, ancho) in [('escritorio', 1400.0), ('teléfono', 400.0)]) {
    testWidgets('en $nombre, una cantidad no reconstruye la pantalla', (
      t,
    ) async {
      await abrir(t, ancho);
      // La lista se arma a medida que se desplaza: hay que llegar al botón.
      final lista =
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first;
      await t.scrollUntilVisible(
        find.text('Agregar vale'),
        300,
        scrollable: lista,
      );
      await t.tap(find.text('Agregar vale'));
      await t.pumpAndSettle();

      final reconstruidos = <String>[];
      debugOnRebuildDirtyWidget = (e, _) {
        // Solo lo que ya estaba: montar una fila nueva al desplazar no cuenta.
        if (_existentes.contains(e)) {
          reconstruidos.add(e.widget.runtimeType.toString());
        }
      };
      addTearDown(() => debugOnRebuildDirtyWidget = null);

      final cantidad = find.widgetWithText(TextFormField, 'Cantidad').first;
      await t.scrollUntilVisible(cantidad, -300, scrollable: lista);
      // Primero el foco: darlo desplaza la lista, y eso no es escribir.
      await t.showKeyboard(cantidad);
      await t.pumpAndSettle();
      reconstruidos.clear();
      _anotarExistentes(t);
      await t.enterText(cantidad, '3');
      await t.pumpAndSettle();

      for (final quieto in ['ArqueoCajaScreen', '_Seccion', '_FilaVale']) {
        expect(
          reconstruidos,
          isNot(contains(quieto)),
          reason: '$quieto no cambia al escribir una cantidad',
        );
      }
      expect(
        reconstruidos,
        containsAll(['_FilaCorte', '_SubtotalCortes', '_BarraArqueo']),
      );
      // 3 billetes de 200: la fila, el subtotal y el total lo muestran.
      expect(find.text('600.00'), findsOneWidget);
      expect(find.text('Bs 600.00'), findsOneWidget);
      expect(find.textContaining('Total contado: Bs 600.00'), findsOneWidget);
    });
  }

  testWidgets('la observación pide explicar cuando no cuadra', (t) async {
    await abrir(t, 1400);
    expect(find.text('Observación'), findsOneWidget);
    await t.enterText(
      find.widgetWithText(TextFormField, 'Cantidad').first,
      '1',
    );
    await t.pumpAndSettle();
    expect(
      find.text('Observación — explica por qué falta o sobra'),
      findsOneWidget,
    );
  });

  testWidgets('abrir el teclado no rearma el arqueo', (t) async {
    await abrir(t, 400);
    final cantidad = find.widgetWithText(TextFormField, 'Cantidad').first;
    await t.showKeyboard(cantidad);
    await t.pumpAndSettle();

    final reconstruidos = <String>[];
    _anotarExistentes(t);
    debugOnRebuildDirtyWidget = (e, _) {
      if (_existentes.contains(e)) {
        reconstruidos.add(e.widget.runtimeType.toString());
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    for (var paso = 1; paso <= 10; paso++) {
      t.view.viewInsets = FakeViewPadding(bottom: 30.0 * paso);
      await t.pump(const Duration(milliseconds: 16));
    }

    for (final quieto in ['_Seccion', '_FilaCorte', 'TextFormField']) {
      expect(
        reconstruidos,
        isNot(contains(quieto)),
        reason: '$quieto no cambia porque suba el teclado',
      );
    }
  });
}
