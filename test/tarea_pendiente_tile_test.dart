// La tarjeta de "Mis tareas rutinarias" después del rediseño de 2026-09-07.
//
// Lo que se prueba aquí es el contrato que Marcelo pidió: responder una tarea
// simple tiene que costar UNA pulsación (antes era abrir un modal, elegir y
// esperar el cierre, por cada una de 30 tareas), y una tarea ya respondida
// "No" tiene que verse distinta de una sin responder — ese era el bug real
// detrás de "el filtro no está funcionando": `fueRealizado` vale 0 cuando se
// responde No, y durante un tiempo eso se leía como pendiente.
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BitTareaRutiEntity tarea({
    int? idATR,
    int? fueRealizado,
    int? idFrec,
    String nombre = 'Administrar el correo electrónico que maneja la empresa',
  }) => BitTareaRutiEntity(
    idBitTarea: 1,
    nombreTareaRutinaria: nombre,
    fechaPresentacion: DateTime(2026, 2, 14),
    idATR: idATR,
    idFrec: idFrec,
    fueRealizado: fueRealizado,
    audUsuario: 0,
  );

  Future<void> montar(
    WidgetTester tester,
    BitTareaRutiEntity t, {
    void Function(int)? onMarcar,
    VoidCallback? onTap,
    bool compacta = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Dentro de un scroll, como vive de verdad en la lista. Es además la
        // única forma de que la tarjeta reciba alto SIN LÍMITE y se mida su
        // alto natural: dentro de un Scaffold a secas se estira al viewport y
        // cualquier medición de densidad da 600 en los dos modos.
        body: SingleChildScrollView(
          child: SizedBox(
            width: 460,
            child: TareaPendienteTile(
              tarea: t,
              onTap: onTap ?? () {},
              onMarcar: onMarcar,
              compacta: compacta,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('una tarea simple se responde con una sola pulsación', (
    tester,
  ) async {
    final elegidos = <int>[];
    await montar(
      tester,
      tarea(fueRealizado: 12),
      onMarcar: elegidos.add,
    );

    expect(find.text('Sí'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('No aplica'), findsOneWidget);

    await tester.tap(find.text('Sí'));
    await tester.pump();

    // 13 = Sí, el mismo valor que guardaba el diálogo anterior.
    expect(elegidos, [13]);
    // Y no se abrió nada: el diálogo era justamente lo lento.
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('los tres valores son los que espera el backend', (tester) async {
    final elegidos = <int>[];
    await montar(tester, tarea(fueRealizado: 12), onMarcar: elegidos.add);

    await tester.tap(find.text('No'));
    await tester.pump();
    await tester.tap(find.text('No aplica'));
    await tester.pump();

    expect(elegidos, [0, 14]);
  });

  testWidgets('mientras guarda, los botones no aceptan otra pulsación', (
    tester,
  ) async {
    final elegidos = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 460,
            child: TareaPendienteTile(
              tarea: tarea(fueRealizado: 12),
              onTap: () {},
              onMarcar: elegidos.add,
              guardando: true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sí'));
    await tester.pump();
    expect(elegidos, isEmpty);
  });

  testWidgets('una tarea respondida "No" no se ve como pendiente', (
    tester,
  ) async {
    await montar(tester, tarea(fueRealizado: 0), onMarcar: (_) {});

    // El texto es la diferencia que el filtro viejo no hacía: respondida que
    // no se hizo, distinto de sin responder.
    expect(find.text('No se hizo'), findsOneWidget);
    expect(find.text('Vencida'), findsNothing);
    expect(find.text('Pendiente'), findsNothing);
  });

  testWidgets('una tarea pendiente no repite su estado como píldora', (
    tester,
  ) async {
    await montar(tester, tarea(fueRealizado: 12), onMarcar: (_) {});

    // El encabezado del grupo ("Vencidas (30)") ya lo dice; repetirlo en las
    // 30 tarjetas era la misma palabra treinta veces.
    expect(find.text('Vencida'), findsNothing);
  });

  testWidgets('una tarea especial navega y NO muestra los tres botones', (
    tester,
  ) async {
    var navego = false;
    await montar(
      tester,
      tarea(idATR: 2, fueRealizado: 12),
      onMarcar: (_) {},
      onTap: () => navego = true,
    );

    expect(find.text('Arqueo de caja'), findsOneWidget);
    expect(find.text('No aplica'), findsNothing);

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expect(navego, isTrue);
  });

  testWidgets('el título entra en dos líneas, no se corta en la primera', (
    tester,
  ) async {
    await montar(tester, tarea(fueRealizado: 12), onMarcar: (_) {});

    final texto = tester.widget<Text>(
      find.text('Administrar el correo electrónico que maneja la empresa'),
    );
    expect(texto.maxLines, 2);
  });

  testWidgets('la frecuencia se muestra con su nombre real', (tester) async {
    await montar(tester, tarea(fueRealizado: 12, idFrec: 6), onMarcar: (_) {});
    expect(find.text('Diario'), findsOneWidget);
  });

  testWidgets('sin frecuencia no inventa una píldora vacía', (tester) async {
    await montar(tester, tarea(fueRealizado: 12), onMarcar: (_) {});
    for (final nombre in ['Diario', 'Semanal', 'Mensual', 'Anual']) {
      expect(find.text(nombre), findsNothing);
    }
  });

  // ── Densidad de escritorio ──────────────────────────────────────────────
  //
  // "En web/desktop parece un celular gigante" (Marcelo, 2026-09-08). Con
  // 28 pendientes en una grilla de tres columnas entraban cinco filas: el
  // problema no era el ancho sino el alto de cada tarjeta.

  testWidgets('en escritorio la misma tarea ocupa menos alto', (tester) async {
    final t = tarea(fueRealizado: 12, idFrec: 6);

    await montar(tester, t, onMarcar: (_) {});
    final altoNormal = tester.getSize(find.byType(TareaPendienteTile)).height;

    await montar(tester, t, onMarcar: (_) {}, compacta: true);
    final altoCompacto = tester.getSize(find.byType(TareaPendienteTile)).height;

    expect(
      altoCompacto,
      lessThan(altoNormal),
      reason:
          'El modo compacto tiene que recortar aire; si empatan, la pantalla '
          'de escritorio sigue siendo la del teléfono estirada.',
    );
  });

  testWidgets('compacta recorta el aire, no el contenido', (tester) async {
    // Lo que NO puede pasar: que para ganar alto se deje de ver de qué tarea
    // se trata, cuándo vence o cómo responderla.
    await montar(
      tester,
      tarea(fueRealizado: 12, idFrec: 6),
      onMarcar: (_) {},
      compacta: true,
    );

    expect(
      find.text('Administrar el correo electrónico que maneja la empresa'),
      findsOneWidget,
    );
    expect(find.text('Diario'), findsOneWidget);
    for (final boton in ['Sí', 'No', 'No aplica']) {
      expect(find.text(boton), findsOneWidget);
    }
  });

  test('el catálogo de frecuencias es el de tac_frecuencia', () {
    // Los ids salen de la tabla, no de una suposición: el filtro por
    // frecuencia de "Mis tareas rutinarias" arma sus chips con este mismo
    // mapa, así que una discrepancia se vería como un chip que no filtra nada.
    expect(TareaPendienteTile.nombreFrecuencia, {
      1: 'Mensual',
      2: 'Semanal',
      3: 'Anual',
      4: 'Bimestral',
      5: 'Semestral',
      6: 'Diario',
    });
  });
}
