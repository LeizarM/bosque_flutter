import 'dart:typed_data';

import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/automatizacion_entity.dart';
import 'package:bosque_flutter/domain/entities/cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/convocatoria_entity.dart';
import 'package:bosque_flutter/domain/entities/cumple_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/intervencion_entity.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/permiso_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/programacion_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_entity.dart';
import 'package:bosque_flutter/domain/entities/puente_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/rol_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/rrhh_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/domain/repositories/rol_sabados_repository.dart';
import 'package:bosque_flutter/presentation/screens/rol-sabados/rol_sabados_screen.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/matriz_grilla.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica que el módulo se dibuje sin desbordes en móvil, tablet y escritorio.
///
/// `flutter analyze` no ve esto: un `Row` que no entra compila perfecto y recién
/// falla al renderizar, con la franja amarilla y negra. Estos tests renderizan
/// de verdad a cada ancho y fallan si aparece un `RenderFlex overflowed`.
///
/// Los datos son de mentira pero del tamaño real: 29 personas × 52 sábados, que
/// es el rol de la sucursal 20. Con tres filas no se detecta nada.
void _sinDesborde(WidgetTester tester, String donde) {
  final e = tester.takeException();
  expect(e, isNull, reason: 'Desborde de layout en $donde');
}

void main() {
  final anchos = <String, Size>{
    'móvil 360×740': const Size(360, 740),
    'móvil ancho 414×896': const Size(414, 896),
    'tablet vertical 768×1024': const Size(768, 1024),
    'tablet horizontal 1024×768': const Size(1024, 768),
    'escritorio 1440×900': const Size(1440, 900),
  };

  for (final entrada in anchos.entries) {
    testWidgets('sin desbordes en ${entrada.key}', (tester) async {
      tester.view.physicalSize = entrada.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
            rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );

      await tester.pumpAndSettle();
      _sinDesborde(tester, '${entrada.key} · pestaña Grilla');

      // Las otras pestañas: cada una tiene sus propios Row con texto largo.
      // «Su equipo» está porque el repo falso dice que el que mira es jefe.
      //
      // El `ensureVisible` no es adorno: con cinco pestañas la barra se vuelve
      // scrollable en 360 px, y «Control» (x=362) y «Su equipo» (x=507) caen
      // FUERA del viewport. `tap()` sobre algo que no da hit test no falla el
      // test: escribe un Warning en la salida y sigue. O sea que las dos
      // últimas pestañas se estuvieron dando por probadas sin renderizarse
      // nunca en el ancho donde más importa.
      for (final pestana in ['Grupos', 'Cambios', 'Control', 'Su equipo']) {
        await tester.ensureVisible(find.text(pestana));
        await tester.pumpAndSettle();
        await tester.tap(find.text(pestana));
        await tester.pumpAndSettle();
        _sinDesborde(tester, '${entrada.key} · pestaña $pestana');
      }

      // Los que quedaron fuera de los sábados viven detrás del cuarto chip, así
      // que el recorrido de arriba no dibuja nunca su fila: la que lleva un
      // renglón más —el motivo y la fecha— sobre un nombre largo.
      await tester.ensureVisible(find.text('Grupos'));
      await tester.tap(find.text('Grupos'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Sin sábados · '));
      await tester.pumpAndSettle();
      _sinDesborde(tester, '${entrada.key} · Grupos sin sábados');
      await tester.tap(find.textContaining('Todos · '));
      await tester.pumpAndSettle();
    });

    // El menú de estado, su confirmación y el diálogo de generar sólo existen
    // para RR.HH., así que el recorrido de arriba —que mira con un usuario sin
    // tipo— no los dibuja nunca. Van en su propio test con el usuario que sí
    // los ve: el diálogo de cerrar es el texto más largo del módulo y es justo
    // el que nadie iba a renderizar en 360 px.
    testWidgets('el menú de estado no desborda en ${entrada.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entrada.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith(
              (ref) => UserStateNotifier.sinStorage(_admin),
            ),
            rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PUBLICADO'));
      await tester.pumpAndSettle();
      _sinDesborde(tester, '${entrada.key} · menú de estado');

      await tester.tap(find.text('Cerrar el año'));
      await tester.pumpAndSettle();
      _sinDesborde(tester, '${entrada.key} · confirmación de cerrar');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // El diálogo de generar: un SegmentedButton y párrafos largos. Vive acá
      // desde que la varita dejó de verse para todos — con el usuario sin tipo
      // del recorrido de arriba ya no hay botón que apretar.
      await tester.tap(find.byIcon(Icons.auto_fix_high));
      await tester.pumpAndSettle();
      _sinDesborde(tester, '${entrada.key} · diálogo Generar rol');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // El FAB de Grupos y su confirmación, por el mismo motivo: al esconderlo
      // para quien no administra, el recorrido de arriba dejó de dibujarlo en
      // los cinco anchos sin que nada avisara. Un FloatingActionButton.extended
      // con «Regenerar con estos grupos» en 360 px es justo lo que esta suite
      // existe para atrapar.
      await tester.ensureVisible(find.text('Grupos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grupos'));
      await tester.pumpAndSettle();
      _sinDesborde(tester, '${entrada.key} · FAB regenerar');

      await tester.tap(find.text('Regenerar con estos grupos'));
      await tester.pumpAndSettle();
      _sinDesborde(tester, '${entrada.key} · confirmación de regenerar');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('las hojas del sábado no desbordan en móvil', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Editor de celda: se abre tocando una persona de la agenda.
    await tester.tap(find.textContaining('MONTENEGRO').first);
    await tester.pumpAndSettle();
    _sinDesborde(tester, 'editor de celda en 360');
    expect(find.text('Estado de la celda'), findsOneWidget);
    Navigator.of(tester.element(find.text('Estado de la celda'))).pop();
    await tester.pumpAndSettle();

    // Editor de evento: el botón del encabezado.
    await tester.tap(find.byIcon(Icons.event_available_outlined));
    await tester.pumpAndSettle();
    _sinDesborde(tester, 'editor de evento en 360');

    // El alta de cambio, desde la pestaña Cambios.
    Navigator.of(tester.element(find.text('Tipo de jornada'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo cambio'));
    await tester.pumpAndSettle();
    _sinDesborde(tester, 'alta de cambio en 360');
  });

  testWidgets('arranca en el mes actual y el buscador achica la lista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // El combo arranca en el mes de hoy, no en "Todo el año": es lo que evita
    // dibujar los 52 sábados de entrada.
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final mesDeHoy = meses[DateTime.now().month - 1];
    expect(find.textContaining(mesDeHoy), findsWidgets);

    // Con el mes puesto se dibujan 4 o 5 columnas, no 52.
    final columnasDelMes = find.textContaining(RegExp(r'^\d{2}\$'));
    expect(tester.widgetList(columnasDelMes).length, lessThan(10));

    // El buscador achica las filas y el contador lo dice. ("29 personas"
    // aparece dos veces: en el chip del rol y en la etiqueta del buscador.)
    expect(find.text('29 personas'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'Carlos 7');
    await tester.pumpAndSettle();
    expect(find.text('1 de 29 personas'), findsOneWidget);

    // Una búsqueda sin resultados explica qué hacer, no queda en blanco.
    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Nadie coincide con la búsqueda'), findsOneWidget);
  });

  testWidgets('el alta de cambio sólo ofrece a quien corresponde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
          // Enero fijo: si dependiera de la fecha de hoy, el test cambiaria de
          // resultado cada mes.
          filtroMesProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo cambio'));
    await tester.pumpAndSettle();

    // Sin sabado elegido no se puede elegir gente: quien puede pedir el cambio
    // depende de a quien le tocaba ese dia.
    expect(
      find.textContaining('Elige el sábado primero'),
      findsOneWidget,
    );

    // Elegir el primer sabado de enero (indice 1, impar -> rota el grupo A).
    await tester.tap(find.text('Sábado a cubrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('03/01/2026').last);
    await tester.pumpAndSettle();

    // De 29 personas, las 15 impares son del grupo A y tienen turno; las 14
    // pares estan libres. Nadie queda en las dos listas ni fuera de las dos.
    expect(find.text('15 con turno ese sábado, de 29'), findsOneWidget);
    expect(find.text('14 libres ese sábado'), findsOneWidget);

    // El invariante que importa: quien YA venia no aparece como suplente.
    await tester.tap(find.text('Quién cubre (opcional)'));
    await tester.pumpAndSettle();
    // El participante 1 es del grupo A y ese sabado trabaja.
    expect(
      find.textContaining('MONTENEGRO VILLARROEL Juan Carlos 1  (A)'),
      findsNothing,
    );
    // El 2 es del grupo B y esta libre: ese si tiene que estar.
    expect(
      find.textContaining('MONTENEGRO VILLARROEL Juan Carlos 2  (B)'),
      findsWidgets,
    );
  });

  testWidgets('la tabla se estira hasta el tope y recién ahí se centra', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
          // Enero: 5 sábados de 1600 px. Sobra muchísimo.
          filtroMesProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Antes la matriz se dibujaba siempre en su ancho mínimo (210 + 5×42 =
    // 420 px) y todo el sobrante era margen. Ahora el sobrante se gasta:
    // primero en los nombres —lo verifica el test de más abajo— y después en
    // las celdas, hasta el tope de 64 px.
    final celda = tester.getRect(find.byType(CabeceraSabado).first);
    expect(
      celda.width,
      greaterThan(42),
      reason:
          'Con 5 columnas en 1600 px las celdas tienen que engordar, no '
          'quedarse en el ancho mínimo mientras sobra media pantalla.',
    );
    expect(
      celda.width,
      lessThanOrEqualTo(64),
      reason:
          'Pero con tope: repartir 1600 px entre 5 columnas daría celdas de '
          '~300 px con una sola letra perdida en el medio.',
    );

    // Y lo que sobra DESPUÉS de repartir sigue siendo margen a los dos lados.
    // La esquina "Personal" es el borde izquierdo de la tabla: si estuviera
    // pegada a la izquierda arrancaría en x = 0.
    final esquina = tester.getRect(find.text('Personal').last);
    expect(
      esquina.left,
      greaterThan(100),
      reason:
          'Ni aun estirada la tabla llena 1600 px con 5 columnas: lo que queda '
          'se reparte a los costados, no se apila todo a la derecha.',
    );
  });

  // ── el PDF del sábado ──────────────────────────────────────────────────
  //
  // Es lo que RR.HH. manda al grupo de WhatsApp cada semana. Las dos vistas lo
  // ofrecen distinto porque tienen espacios distintos —un menú en la matriz,
  // donde la columna mide 42 px, y un botón a la vista en el teléfono, que es
  // desde donde se comparte—, así que hay que mirar las dos.

  testWidgets('la cabecera de la matriz ofrece el PDF sin pagar ancho', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Que el menú no cueste ancho no es una opinión: con 52 columnas cada pixel
    // que gane la cabecera se lo saca a la columna de nombres.
    expect(
      tester.getRect(find.byType(CabeceraSabado).first).width,
      lessThanOrEqualTo(64),
      reason: 'El menú se dibuja en el Overlay: la columna no puede engordar.',
    );

    await tester.tap(find.byType(CabeceraSabado).first);
    await tester.pumpAndSettle();
    _sinDesborde(tester, 'menú de la cabecera en 1440');

    // Las dos acciones, cada una con su nombre completo. La del evento estaba
    // antes en el toque directo y no se puede haber perdido en el camino.
    expect(find.text('Exportar el PDF de este sábado'), findsOneWidget);
    expect(find.text('Declarar el evento del día'), findsOneWidget);
  });

  testWidgets('en el teléfono el PDF es un botón a la vista', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Acá no se esconde en un menú: es la pantalla desde la que se comparte.
    expect(
      find.byTooltip('Compartir el PDF de este sábado'),
      findsOneWidget,
      reason: 'El botón de compartir tiene que estar en el encabezado del día.',
    );
    _sinDesborde(tester, 'encabezado de la agenda con el botón de PDF en 360');
  });

  testWidgets('la letra de una celda intervenida se lee sola', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
          filtroMesProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // El repo falso marca la celda del participante 3 en el sábado 5 con
    // origen 'M'. Su letra tiene que ocupar su propio espacio: cuando la marca
    // se dibujaba encima, el Stack se encogía al tamaño del glifo.
    final letras = find.text('1');
    expect(letras, findsWidgets);
    for (final e in tester.widgetList<Text>(letras).take(3)) {
      expect(e.data, '1', reason: 'La letra no puede venir mezclada con nada.');
    }

    // Y la marca es un widget aparte, no parte del texto.
    expect(find.byType(MarcaDeIntervencion), findsWidgets);
  });

  testWidgets('la leyenda ocupa todo el ancho, no el de la tabla', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
          rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
          filtroMesProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Al centrar la tabla, la leyenda quedó adentro del bloque centrado y se
    // cortaba a mitad de palabra: en enero la tabla mide 210 + 5x42 = 420 px.
    final leyenda = tester.getRect(find.byType(LeyendaDeEstados));
    expect(
      leyenda.width,
      greaterThan(1000),
      reason:
          'La leyenda tiene que ir a lo ancho del panel. Si mide como la tabla '
          '(~420 px) es que quedó encerrada en el bloque centrado.',
    );

    // Y su último elemento tiene que estar dibujado, no recortado.
    expect(
      find.textContaining('regenerar no la pisa'),
      findsOneWidget,
    );
  });

  testWidgets('la columna de nombres se estira cuando sobra ancho', (
    tester,
  ) async {
    Future<double> anchoDeLaColumna(Size pantalla, int mes) async {
      tester.view.physicalSize = pantalla;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        ProviderScope(
          // La clave fuerza un árbol nuevo. Sin ella, el segundo pump reusa el
          // contenedor de Riverpod y el StateProvider del mes conserva el valor
          // anterior: la medición saldría dos veces la misma.
          key: ValueKey('mes-$mes'),
          overrides: [
            userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
            rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
            filtroMesProvider.overrideWith((ref) => mes),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // La caja de la esquina mide exactamente lo que mide la columna; el
      // Text de adentro sólo mide la palabra.
      return tester
          .getRect(find.byKey(const Key('trs-esquina-personal')))
          .width;
    }

    addTearDown(tester.view.reset);

    // Enero: 5 columnas en 1600 px. Sobra muchísimo, los nombres entran enteros.
    final conLugar = await anchoDeLaColumna(const Size(1600, 900), 1);
    expect(
      conLugar,
      greaterThan(260),
      reason:
          'Con 5 columnas en 1600 px la columna de nombres tiene que estirarse, '
          'no quedarse en el ancho compacto mientras sobra media pantalla.',
    );

    // Todo el año: 52 columnas. No sobra nada y vuelve al ancho compacto.
    final sinLugar = await anchoDeLaColumna(const Size(1600, 900), 0);
    expect(
      sinLugar,
      lessThan(conLugar),
      reason:
          'Con los 52 sábados no sobra ancho: la columna tiene que volver a lo '
          'compacto para no comerse las celdas.',
    );
  });

  testWidgets('«Su equipo» sólo existe para quien puede programar', (
    tester,
  ) async {
    Future<void> montar(RolSabadosRepository repo, String clave) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        ProviderScope(
          // Árbol nuevo por cada repo: sin la clave, Riverpod reusa el
          // contenedor y `miEquipoProvider` —que no es autoDispose— devuelve
          // la respuesta del montaje anterior.
          key: ValueKey(clave),
          overrides: [
            userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
            rolSabadosRepositoryProvider.overrideWithValue(repo),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(tester.view.reset);

    // Quien no está en trs_Programador no tiene a nadie a cargo: la pestaña no
    // se muestra deshabilitada, directamente no existe.
    await montar(_RepoFalso(miEquipo: MiEquipoEntity.vacio), 'sin-equipo');
    expect(find.text('Su equipo'), findsNothing);
    // Y el resto del módulo sigue entero: la ven todos.
    expect(find.text('Control'), findsWidgets);

    // El mismo módulo, con un jefe mirando.
    await montar(_RepoFalso(), 'con-equipo');
    expect(find.text('Su equipo'), findsWidgets);
  });

  testWidgets('los ABM y la regeneración son de Sistemas y RR.HH., no del jefe', (
    tester,
  ) async {
    Future<void> montar(
      String clave, {
      LoginEntity? usuario,
      MiEquipoEntity equipo = _equipoDeMentira,
    }) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        ProviderScope(
          // Árbol nuevo por montaje: `miEquipoProvider` no es autoDispose y
          // sin la clave el segundo montaje contesta con el equipo del primero.
          key: ValueKey(clave),
          overrides: [
            userProvider.overrideWith(
              (ref) => UserStateNotifier.sinStorage(usuario),
            ),
            rolSabadosRepositoryProvider.overrideWithValue(
              _RepoFalso(miEquipo: equipo),
            ),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Los cuatro controles del mismo permiso. La regeneración va con los dos
    // ABM y no con «Actualizar»: rehace el año de las 85 personas de una.
    Future<void> loVe(Matcher cuantos) async {
      expect(find.byTooltip('Programadores'), cuantos);
      expect(find.byTooltip('RR.HH.'), cuantos);
      expect(find.byIcon(Icons.auto_fix_high), cuantos);

      // El FAB de Grupos hace lo MISMO que la varita —`generarRol` en modo
      // REGENERAR— así que tiene que caer del mismo lado. Esconder uno y dejar
      // el otro no cierra nada; sólo mueve el botón de lugar.
      await tester.tap(find.text('Grupos'));
      await tester.pumpAndSettle();
      expect(find.text('Regenerar con estos grupos'), cuantos);
      await tester.tap(find.text('Grilla'));
      await tester.pumpAndSettle();
    }

    addTearDown(tester.view.reset);

    // Un jefe programador no. Puede mover a su gente entre '1' y 'L', pero
    // quién programa, quién corrige y cuándo se rehace el año no lo decide
    // quien va a usar el permiso.
    await montar('jefe');
    await loVe(findsNothing);
    // Y el resto del módulo sigue entero: la pestaña de su gente y el refresco
    // de pantalla no se tocan.
    expect(find.text('Su equipo'), findsWidgets);
    expect(find.byTooltip('Actualizar'), findsOneWidget);

    // Sistemas, por el token.
    await montar('sistemas', usuario: _admin);
    await loVe(findsOneWidget);

    // RR.HH. SIN ROLE_ADM: el caso que importa. Su permiso no viaja en el
    // token, es una fila en `trs_Rrhh`, así que sale de `/mi-equipo`. Y ni
    // siquiera es jefe —`esProgramador` en 0—: no depende de tener gente a
    // cargo.
    await montar(
      'rrhh',
      equipo: const MiEquipoEntity(codUsuario: 15, codEmpleado: 65, esRrhh: 1),
    );
    await loVe(findsOneWidget);
  });

  testWidgets('el teléfono muestra la agenda y el escritorio la matriz', (
    tester,
  ) async {
    Future<void> montar(Size tamano) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(null)),
            rolSabadosRepositoryProvider.overrideWithValue(_RepoFalso()),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    addTearDown(tester.view.reset);

    await montar(const Size(360, 740));
    // En la agenda cada sábado se elige de la tira; la leyenda de la matriz no
    // existe. Buscamos un texto propio de la agenda.
    expect(find.textContaining('Vienen'), findsWidgets);

    await montar(const Size(1440, 900));
    // En la matriz sí está la leyenda, con su aclaración del libre.
    expect(find.text('vacío = libre'), findsOneWidget);
  });

  // ═════════════════════════════════════════════════════════════════════════
  // EL ESTADO DEL ROL
  // ═════════════════════════════════════════════════════════════════════════

  testWidgets('el estado del rol lo mueve RR.HH. y nadie más', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> montar(String clave, _RepoFalso repo, {bool admin = false}) {
      return tester.pumpWidget(
        ProviderScope(
          // Árbol nuevo por montaje: sin la clave Riverpod reusa el contenedor
          // y la lista de roles queda con el estado del montaje anterior.
          key: ValueKey(clave),
          overrides: [
            userProvider.overrideWith(
              (ref) => UserStateNotifier.sinStorage(admin ? _admin : null),
            ),
            rolSabadosRepositoryProvider.overrideWithValue(repo),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );
    }

    // Un jefe ve la etiqueta y nada más: tocarla no abre nada.
    await montar('jefe', _RepoFalso());
    await tester.pumpAndSettle();
    expect(find.text('PUBLICADO'), findsOneWidget);
    await tester.tap(find.text('PUBLICADO'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar el año'), findsNothing);

    // RR.HH. sobre el mismo rol publicado: puede reabrirlo o cerrarlo.
    await montar('rrhh-publicado', _RepoFalso(), admin: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PUBLICADO'));
    await tester.pumpAndSettle();
    expect(find.text('Reabrir'), findsOneWidget);
    expect(find.text('Cerrar el año'), findsOneWidget);

    // Cerrar avisa que es de ida, porque el SP rechaza cualquier UPDATE sobre
    // un rol cerrado: si esto no se dijera, sería una puerta sin picaporte sin
    // cartel.
    await tester.tap(find.text('Cerrar el año'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no se deshace desde la aplicación'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Y en borrador lo único que se ofrece es publicar: cerrar un año que
    // nunca se publicó saltea el paso donde se avisa que no hay vuelta.
    await montar(
      'rrhh-borrador',
      _RepoFalso(estadoRol: 'BORRADOR'),
      admin: true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('BORRADOR'));
    await tester.pumpAndSettle();
    expect(find.text('Publicar'), findsOneWidget);
    expect(find.text('Cerrar el año'), findsNothing);

    // Un rol cerrado no ofrece nada, ni siquiera a RR.HH.: el backend no lo
    // aceptaría y un botón que siempre falla es peor que ninguno.
    await montar('rrhh-cerrado', _RepoFalso(estadoRol: 'CERRADO'), admin: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CERRADO'));
    await tester.pumpAndSettle();
    expect(find.text('Publicar'), findsNothing);
    expect(find.text('Reabrir'), findsNothing);

    // Y RR.HH. DE VERDAD —el del padrón `trs_Rrhh`, sin ROLE_ADM— también
    // mueve el estado. No es un caso de borde: los dos únicos usuarios del
    // padrón son `lim`, o sea que es el 100% del público de este menú.
    //
    // Sin esto, la varita que RR.HH. acaba de ganar no sirve para nada:
    // `trs_sp_generarRol` rechaza REGENERAR sobre un rol PUBLICADO y en el
    // mensaje manda justamente a «Reabrir». Un botón cuyo único desenlace
    // posible es un error cuyas instrucciones no se pueden seguir.
    await montar(
      'rrhh-del-padron',
      _RepoFalso(
        miEquipo: const MiEquipoEntity(codUsuario: 15, codEmpleado: 2, esRrhh: 1),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('PUBLICADO'));
    await tester.pumpAndSettle();
    expect(find.text('Reabrir'), findsOneWidget);
  });

  testWidgets('publicar recién escribe después de confirmar', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _RepoFalso(estadoRol: 'BORRADOR');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith(
            (ref) => UserStateNotifier.sinStorage(_admin),
          ),
          rolSabadosRepositoryProvider.overrideWithValue(repo),
          rolSeleccionadoProvider.overrideWith((ref) => 1),
        ],
        child: const MaterialApp(home: RolSabadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('BORRADOR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    // El diálogo dice qué deja de andar, que es la mitad de la decisión.
    expect(find.textContaining('Regenerar'), findsWidgets);
    expect(find.textContaining('Su equipo'), findsWidgets);

    // Cancelar no escribe.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.estadosPedidos, isEmpty);

    // Confirmar sí.
    await tester.tap(find.text('BORRADOR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
    await tester.pumpAndSettle();
    expect(repo.estadosPedidos, ['PUBLICADO']);
  });

  // ═════════════════════════════════════════════════════════════════════════
  // LA VENTANA DE SÁBADOS
  // ═════════════════════════════════════════════════════════════════════════

  testWidgets('sacar y devolver gente a los sábados es de RR.HH.', (
    tester,
  ) async {
    // Escritorio, como los otros tests de interacción: en 360 px la cabecera de
    // la pestaña —los cuatro chips, el aviso y el buscador— deja 35 px de lista
    // y sólo entra una fila, así que el recorrido necesitaría scroll para
    // llegar a la segunda persona. Que ese ancho no desborde ya lo cubre el
    // recorrido de arriba, que ahora también entra a la vista de excluidos.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Sábados a caballo de hoy: 26 atrás y 26 adelante, siempre. El menú sólo
    // aparece si queda algún sábado al que llegar, así que con el rol 2026 fijo
    // este test se caería solo cuando ese año quede atrás.
    final hoy = DateTime.now();
    final repo = _RepoFalso(
      primerSabado: DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
      ).subtract(const Duration(days: 7 * 26)),
    );

    Future<void> montar({required bool admin}) async {
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(admin),
          overrides: [
            userProvider.overrideWith(
              (ref) => UserStateNotifier.sinStorage(admin ? _admin : null),
            ),
            rolSabadosRepositoryProvider.overrideWithValue(repo),
            rolSeleccionadoProvider.overrideWith((ref) => 1),
          ],
          child: const MaterialApp(home: RolSabadosScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Grupos'));
      await tester.tap(find.text('Grupos'));
      await tester.pumpAndSettle();
    }

    // Un jefe ve quién quedó afuera —si no lo viera, nadie podría pedir que lo
    // devuelvan— pero no tiene cómo tocarlo.
    await montar(admin: false);
    expect(find.textContaining('Sin sábados · 2'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    _sinDesborde(tester, 'Grupos con excluidos · jefe');

    // RR.HH. sobre el mismo rol.
    await montar(admin: true);
    expect(find.byIcon(Icons.more_vert), findsWidgets);

    // Sacar a alguien: el diálogo dice qué pasa con lo que ya trabajó ANTES de
    // confirmar, que es la mitad de la decisión.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sacar de los sábados…'));
    await tester.pumpAndSettle();
    _sinDesborde(tester, 'diálogo de sacar de los sábados');
    expect(find.textContaining('no se tocan'), findsOneWidget);
    expect(find.textContaining('Se le liberan'), findsOneWidget);

    // Cancelar no escribe.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.ventanasPedidas, isEmpty);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sacar de los sábados…'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sacar'));
    await tester.pumpAndSettle();
    expect(repo.ventanasPedidas.single, startsWith('D:1:'));

    // El chip lleva a los que quedaron afuera, y ahí cada uno dice por qué. Son
    // dos motivos distintos y se leen distinto: uno se deshace con un toque y
    // el otro lo reconcilia la regeneración.
    repo.ventanasPedidas.clear();
    await tester.tap(find.textContaining('Sin sábados · 2'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sin sábados desde el 03/07/2026'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Vuelve a los sábados el 03/10/2026'),
      findsOneWidget,
    );
    _sinDesborde(tester, 'Grupos · vista sin sábados');

    // Y desde ahí se los devuelve.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devolver a los sábados…'));
    await tester.pumpAndSettle();
    _sinDesborde(tester, 'diálogo de devolver a los sábados');
    expect(find.textContaining('Entra de nuevo en la rotación'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Devolver'));
    await tester.pumpAndSettle();
    expect(repo.ventanasPedidas.single, startsWith('R:7:'));
  });
}

/// El usuario de RR.HH. `tipoUsuario` es lo único que mira el portón; el resto
/// de los campos los completa `fromJson` con sus defaults.
final _admin = LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
});

/// Fabrica del repo falso, para reusarlo desde otros tests.
RolSabadosRepository repoFalso() => _RepoFalso();

/// El equipo que devuelve el repo falso por defecto: un jefe con seis personas
/// a cargo, tres directas y tres que cuelgan más abajo (por eso SUBARBOL).
///
/// Los `codDependiente` son los `codEmpleado` de los participantes 1 a 6 del
/// rol de mentira: si no coincidieran, la pestaña mostraría gente que no está
/// en la grilla y el test estaría probando una situación imposible.
const _equipoDeMentira = MiEquipoEntity(
  codUsuario: 15,
  codEmpleado: 65,
  esProgramador: 1,
  esReemplazo: 0,
  idProgramador: 1,
  codEmpleadoTitular: 65,
  jefe: 'AGUILAR ARANIBAR Alvaro Sebastian',
  alcance: 'SUBARBOL',
  codSucursal: 20,
  cantidadDependientes: 6,
  equipo: [
    ProgramadorDependienteEntity(
      idProgramador: 1,
      codProgramador: 65,
      profundidad: 1,
      codDependiente: 101,
      nombreDependiente: 'MONTENEGRO VILLARROEL Juan Carlos 1',
      sucDependiente: 20,
    ),
    ProgramadorDependienteEntity(
      idProgramador: 1,
      codProgramador: 65,
      profundidad: 1,
      codDependiente: 102,
      nombreDependiente: 'MONTENEGRO VILLARROEL Juan Carlos 2',
      sucDependiente: 20,
    ),
    ProgramadorDependienteEntity(
      idProgramador: 1,
      codProgramador: 65,
      profundidad: 1,
      codDependiente: 103,
      nombreDependiente: 'MONTENEGRO VILLARROEL Juan Carlos 3',
      sucDependiente: 20,
    ),
    ProgramadorDependienteEntity(
      idProgramador: 1,
      codProgramador: 65,
      profundidad: 2,
      codDependiente: 104,
      nombreDependiente: 'MONTENEGRO VILLARROEL Juan Carlos 4',
      sucDependiente: 20,
    ),
    ProgramadorDependienteEntity(
      idProgramador: 1,
      codProgramador: 65,
      profundidad: 2,
      codDependiente: 105,
      nombreDependiente: 'MONTENEGRO VILLARROEL Juan Carlos 5',
      sucDependiente: 20,
    ),
    ProgramadorDependienteEntity(
      idProgramador: 1,
      codProgramador: 65,
      profundidad: 2,
      codDependiente: 106,
      nombreDependiente: 'MONTENEGRO VILLARROEL Juan Carlos 6',
      sucDependiente: 20,
    ),
  ],
);

/// Repositorio de mentira con un rol del tamaño real.
class _RepoFalso implements RolSabadosRepository {
  /// Quién dice el servidor que soy. Se puede cambiar para probar el otro lado
  /// del portón: [MiEquipoEntity.vacio] es «no sos programador».
  ///
  /// Sin `const` a propósito: con un constructor constante, los siete
  /// `_RepoFalso()` de arriba se llenarían de avisos de `prefer_const_
  /// constructors` y `flutter analyze` se pondría en rojo por nada.
  _RepoFalso({
    this.miEquipo = _equipoDeMentira,
    this.estadoRol = 'PUBLICADO',
    DateTime? primerSabado,
  }) : primerSabado = primerSabado ?? DateTime(2026, 1, 3);

  final MiEquipoEntity miEquipo;

  /// Desde cuándo corren los 52 sábados.
  ///
  /// Por defecto es el rol 2026 de siempre, con fechas fijas que los tests
  /// pueden buscar por texto. La ventana de sábados es lo único que mira el
  /// reloj de verdad —sólo ofrece los días a los que todavía se llega—, así que
  /// ese test pasa un origen relativo a hoy: con fechas fijas se caería solo el
  /// día que el año del rol quede atrás.
  final DateTime primerSabado;

  /// En qué punto del ciclo está el rol. Decide qué transiciones ofrece la
  /// etiqueta del selector, así que hay tests que necesitan moverlo.
  final String estadoRol;

  /// Qué estados le pidieron al repo, en orden. Es lo único que se puede
  /// observar de un cambio de estado: la acción devuelve void.
  final List<String> estadosPedidos = [];

  static const _personas = 29;
  static const _sabados = 52;

  @override
  Future<List<RolSabadosEntity>> getRoles({
    int codSucursal = 0,
    int anio = 0,
  }) async => [
    RolSabadosEntity(
      idRol: 1,
      codEmpresa: 1,
      codSucursal: 20,
      sucursal: 'SANTA CRUZ PLANTA INDUSTRIAL',
      anio: 2026,
      nombre: 'ROL 2026',
      turnosObjetivoA: 26,
      turnosObjetivoB: 26,
      coberturaObjetivo: 29,
      aplicaAsuetoCumple: 1,
      estado: estadoRol,
      sabados: _sabados,
      participantes: _personas,
      celdas: 754,
    ),
  ];

  @override
  Future<List<SabadoEntity>> getSabados(int idRol) async => [
    for (var i = 1; i <= _sabados; i++)
      SabadoEntity(
        idSabado: i,
        idRol: 1,
        fecha: primerSabado.add(Duration(days: 7 * (i - 1))),
        anio: 2026,
        mes: ((i - 1) ~/ 4.34).clamp(0, 11).toInt() + 1,
        trimestre: ((i - 1) ~/ 13) + 1,
        indiceAnio: i,
        grupoQueRota: i.isOdd ? 'A' : 'B',
        // Un feriado y un evento para que se dibujen las dos marcas.
        esFeriado: i == 18 ? 1 : 0,
        alcanceEvento: i == 27 ? 'SELECTIVA' : null,
        motivoEspecial: i == 27 ? 'Inventario general de almacén' : '',
        activo: 1,
        personasTrabajan: 0,
      ),
  ];

  /// Dos de los 29 no hacen sábados, y **no es adorno**: son los dos estados
  /// que dibujan fila apagada, renglón de motivo y el cuarto chip. Sin ninguno,
  /// todo eso no se renderiza nunca y el recorrido de anchos lo daría por
  /// probado. El 7 salió a mitad de año; el 8 tiene fecha de vuelta.
  ///
  /// El 7 sigue con `activo: 1` a propósito: que RR.HH. lo saque de los sábados
  /// NO lo saca de la empresa. Si esos dos hechos volvieran a la misma columna,
  /// la próxima regeneración lo devolvería al rol.
  @override
  Future<List<ParticipanteTurnoEntity>> getParticipantes(
    int idRol, {
    int activo = 1,
  }) async => [
    for (var i = 1; i <= _personas; i++)
      ParticipanteTurnoEntity(
        idParticipante: i,
        idRol: 1,
        codEmpleado: 100 + i,
        // Nombres largos a propósito: es donde revienta el ancho.
        nombreRol: 'MONTENEGRO VILLARROEL Juan Carlos $i',
        grupoRotacion: i.isOdd ? 'A' : 'B',
        nroOrden: i,
        turnosObjetivo: 26,
        codSucursal: 20,
        esProgramador: 0,
        activo: 1,
        situacion:
            i == 7
                ? 'SIN SABADOS'
                : i == 8
                ? 'VUELVE EL 03/10/2026'
                : 'VIGENTE',
        fechaSituacion:
            i == 7
                ? DateTime(2026, 7, 3)
                : i == 8
                ? DateTime(2026, 10, 3)
                : null,
        turnosTrabaja: 26,
        diasVacacion: 0,
        diasCambio: 0,
        diasAsueto: 0,
        diasExcusado: 0,
      ),
  ];

  @override
  Future<List<CeldaTurnoEntity>> getAsignaciones(
    int idRol, {
    int idSabado = 0,
  }) async {
    final celdas = <CeldaTurnoEntity>[];
    var id = 1;
    for (var p = 1; p <= _personas; p++) {
      for (var s = 1; s <= _sabados; s++) {
        // La rotación A/B: sólo hay celda cuando le toca.
        final leToca = (p.isOdd && s.isOdd) || (p.isEven && s.isEven);
        if (!leToca) continue;
        // La celda del cambio lleva DOS esquinitas a la vez —la de
        // intervención arriba y la del cambio abajo— más el nombre más largo
        // de la lista adentro del tooltip. Es el peor caso de la celda de
        // 42 px, así que es la que tiene que renderizar sin desborde.
        final esCambio = p == 3 && s == 5;
        celdas.add(
          CeldaTurnoEntity(
            idAsignacion: id++,
            idRol: 1,
            idParticipante: p,
            idSabado: s,
            codigoExcel: s == 18 ? 'X' : '1',
            estadoNombre: s == 18 ? 'Feriado' : 'Trabaja',
            origen: esCambio ? 'M' : 'G',
            observacion: esCambio ? 'Cambio pedido por el jefe de planta' : '',
            fecha: primerSabado.add(Duration(days: 7 * (s - 1))),
            nombreRol: 'MONTENEGRO VILLARROEL Juan Carlos $p',
            cambioCon: esCambio ? 'ALMENDRAS ROCHA Erick Alberto' : '',
            cambioRol: esCambio ? 'R' : '',
            cambioTipo: esCambio ? 'PERMUTA' : '',
          ),
        );
      }
    }
    return celdas;
  }

  @override
  Future<List<EstadoTurnoEntity>> getEstadosTurno() async => const [
    EstadoTurnoEntity(
      idEstadoTurno: 1,
      codigoExcel: '1',
      nombre: 'Trabaja',
      cuentaTurno: 1,
      afectaCobertura: 0,
      color: '#C8E6C9',
      estado: 'A',
    ),
    EstadoTurnoEntity(
      idEstadoTurno: 2,
      codigoExcel: 'V',
      nombre: 'Vacación',
      cuentaTurno: 0,
      afectaCobertura: 1,
      color: '#FFF9C4',
      estado: 'A',
    ),
    EstadoTurnoEntity(
      idEstadoTurno: 3,
      codigoExcel: 'X',
      nombre: 'Feriado',
      cuentaTurno: 0,
      afectaCobertura: 1,
      color: '#FFCDD2',
      estado: 'A',
    ),
  ];

  // El resto no lo toca la pestaña de grilla; devuelven vacío.
  @override
  Future<List<ParticipanteTurnoEntity>> getTurnosPorParticipante(
    int idRol,
  ) async => [];

  @override
  Future<List<SabadoEntity>> getCobertura(int idRol, {int mes = 0}) async => [];

  @override
  Future<List<SabadoEntity>> getFeriadosDesincronizados(int idRol) async => [
    SabadoEntity(
      idSabado: 18,
      idRol: 1,
      fecha: DateTime(2026, 5, 2),
      anio: 2026,
      mes: 5,
      trimestre: 2,
      indiceAnio: 18,
      grupoQueRota: 'B',
      esFeriado: 0,
      motivoEspecial: 'DIA DEL TRABAJO — puente declarado por RR.HH.',
      activo: 1,
      personasTrabajan: 14,
    ),
  ];

  /// Un PDF de mentira. Alcanza con que devuelva bytes: lo que sigue después
  /// —`Printing.sharePdf`— es un canal de plataforma que en el test no existe,
  /// así que estos tests llegan hasta el botón y no lo aprietan.
  @override
  Future<Uint8List> getReporteSabadoPdf(int idSabado) async => Uint8List(0);

  @override
  Future<List<CambioEntity>> getCambios(int idRol, {String estado = ''}) async => [
    CambioEntity(
      idCambio: 1,
      idRol: 1,
      idSabado: 12,
      sabadoCubierto: DateTime(2026, 3, 21),
      codEmpleadoTitular: 101,
      titular: 'MONTENEGRO VILLARROEL Juan Carlos',
      codEmpleadoReemplazo: 102,
      reemplazo: 'ECHEVERRIA SANTA CRUZ Maria Fernanda',
      idSabadoReposicion: 14,
      fechaReposicion: DateTime(2026, 4, 4),
      tipo: 'PERMUTA',
      estado: 'SOLICITADO',
      motivo: 'Viaje familiar programado con mucha anticipación al interior',
      codAprobador: 0,
      fechaSolicitud: DateTime(2026, 3, 1),
    ),
  ];

  @override
  Future<List<ProgramacionEntity>> getProgramaciones(
    int idRol, {
    int idSabado = 0,
  }) async => [
    ProgramacionEntity(
      idProgramacion: 1,
      idRol: 1,
      idSabado: 9,
      sabado: DateTime(2026, 2, 28),
      codEmpleadoProgramador: 65,
      codEmpleadoEjecutor: 0,
      fechaProgramacion: DateTime(2026, 2, 26),
      diasAntelacion: 2,
      controlAntelacion: 'AVISO TARDIO (menos de 1 semana)',
      estado: 'VIGENTE',
      motivo: 'Reasignación por cierre de inventario en almacén central',
      celdasAfectadas: 3,
    ),
  ];

  @override
  Future<List<ConvocatoriaEntity>> getDetalleEvento(int idSabado) async => [];

  @override
  Future<List<IntervencionEntity>> getIntervenciones(int idRol) async => [
    IntervencionEntity(
      idRol: 1,
      idSabado: 5,
      fechaSabado: DateTime(2026, 1, 31),
      tipoIntervencion: 'CORRECCION MANUAL',
      codEmpleado: 103,
      nombreRol: 'MONTENEGRO VILLARROEL Juan Carlos 3',
      quedoEn: 'V',
      loHizo: 34,
      cuando: DateTime(2026, 1, 20),
      diasAntelacion: 11,
      motivo: 'Cambio pedido por el jefe de planta',
    ),
  ];

  @override
  Future<List<CumpleSabadoEntity>> getCumplesSabado(int idRol) async => [
    CumpleSabadoEntity(
      idParticipante: 7,
      codEmpleado: 107,
      nombreRol: 'MONTENEGRO VILLARROEL Juan Carlos 7',
      fechaNacimiento: DateTime(1990, 5, 16),
      idSabado: 20,
      fechaSabado: DateTime(2026, 5, 16),
      estadoActual: '1',
      // El texto más largo del catálogo: es el que rompe los trailing.
      situacionAsueto: 'ASUETO ANULADO POR EVENTO',
      motivoEspecial: 'Inventario general de almacén',
    ),
  ];

  @override
  Future<AutomatizacionEntity?> getAutomatizacion(int idRol) async =>
      const AutomatizacionEntity(
        celdasTotales: 754,
        conDecisionHumana: 12,
        generadasSolas: 742,
      );

  @override
  Future<int> generarRol({
    required int anio,
    int codSucursal = 0,
    int codEmpresa = 0,
    String modo = 'CREAR',
    required int audUsuario,
  }) async => 1;

  @override
  Future<void> corregirCelda({
    required int idParticipante,
    required int idSabado,
    required String codigoExcel,
    String observacion = '',
    required int audUsuario,
  }) async {}

  @override
  Future<void> liberarCelda({
    required int idParticipante,
    required int idSabado,
    required int audUsuario,
  }) async {}

  @override
  Future<void> marcarEvento({
    required int idSabado,
    String? alcanceEvento,
    String motivoEspecial = '',
    required int audUsuario,
  }) async {}

  @override
  Future<void> refrescarFeriados({
    required int idRol,
    bool soloInformar = false,
    required int audUsuario,
  }) async {}

  @override
  Future<void> cambiarEstadoRol({
    required int idRol,
    required String estado,
    required int aplicaAsuetoCumple,
    required int audUsuario,
  }) async => estadosPedidos.add(estado);

  @override
  Future<int> registrarCambio({
    required int idRol,
    required int idSabado,
    required int codEmpleadoTitular,
    int codEmpleadoReemplazo = 0,
    int idSabadoReposicion = 0,
    required String tipo,
    String motivo = '',
    required int audUsuario,
  }) async => 1;

  @override
  Future<void> aprobarCambio({
    required int idCambio,
    required int codAprobador,
    required int audUsuario,
  }) async {}

  @override
  Future<void> anularCambio({
    required int idCambio,
    required int audUsuario,
  }) async {}

  @override
  Future<void> asignarGrupo({
    required int idParticipante,
    required String grupoRotacion,
    required int audUsuario,
  }) async {}

  /// Las ventanas que se pidieron, en orden: `idParticipante` con la fecha que
  /// viajó. Es lo único observable de las dos acciones, que devuelven void.
  final List<String> ventanasPedidas = [];

  @override
  Future<void> sacarDeSabados({
    required int idParticipante,
    required DateTime fechaBaja,
    required int audUsuario,
  }) async {
    ventanasPedidas.add('D:$idParticipante:${fechaBaja.toIso8601String()}');
  }

  @override
  Future<void> reincorporar({
    required int idParticipante,
    required DateTime fechaAlta,
    required int audUsuario,
  }) async {
    ventanasPedidas.add('R:$idParticipante:${fechaAlta.toIso8601String()}');
  }

  @override
  Future<List<PermisoSabadoEntity>> getDesfasesPermiso(int idRol) async => [];

  @override
  Future<void> refrescarPermisos({
    required int idRol,
    bool soloInformar = false,
    required int audUsuario,
  }) async {}

  @override
  Future<void> convocar({
    required int idSabado,
    required String tipo,
    int codEmpleado = 0,
    int codEmpleadoJefe = 0,
    int codCargo = 0,
    String motivo = '',
    required int audUsuario,
  }) async {}

  // ── su equipo ─────────────────────────────────────────────────────────
  // Ninguna de las dos primeras lleva audUsuario: el servidor saca la
  // identidad del token. Si algún día aparece acá un parámetro de usuario, es
  // que alguien "arregló" el contrato y abrió la puerta a programar como otro.

  @override
  Future<MiEquipoEntity> getMiEquipo() async => miEquipo;

  @override
  Future<void> programar({
    required int idSabado,
    required int codEmpleadoDependiente,
    required String codigoExcel,
    String motivo = '',
  }) async {}

  @override
  Future<List<ProgramadorEntity>> getProgramadores({
    int codSucursal = 0,
    String estado = 'A',
  }) async => const [
    ProgramadorEntity(
      idProgramador: 1,
      codEmpleado: 65,
      jefe: 'AGUILAR ARANIBAR Alvaro Sebastian',
      codSucursal: 20,
      alcance: 'SUBARBOL',
      codEmpleadoReemplazo: 183,
      reemplazo: 'ZABALLA ENCINAS Edgar Rolando',
      estado: 'A',
      dependientes: 6,
    ),
  ];

  @override
  Future<void> registrarProgramador({
    required int idProgramador,
    required int codEmpleado,
    int codSucursal = 0,
    String alcance = 'DIRECTOS',
    int codEmpleadoReemplazo = 0,
    String observacion = '',
    required int audUsuario,
  }) async {}

  @override
  Future<void> eliminarProgramador({
    required int idProgramador,
    required int audUsuario,
  }) async {}

  /// Dos personas, una de ellas ya con permiso: alcanza para que el resumen
  /// del puente tenga que separar «entran» de «se saltean».
  @override
  Future<List<PuenteVacacionEntity>> simularPuente({
    required int idSabado,
    String horaDesde = '',
    String horaHasta = '',
    String motivo = '',
  }) async => const [
    PuenteVacacionEntity(
      accion: 'ALTA',
      nombreRol: 'MONTENEGRO VILLARROEL Juan Carlos 1',
      codEmpleado: 1,
      dias: 0.4375,
      origen: 'G',
      detalle: '',
      totalAlta: 1,
      totalSalteados: 1,
      diasTotales: 0.4375,
    ),
    PuenteVacacionEntity(
      accion: 'SE SALTEA',
      nombreRol: 'MONTENEGRO VILLARROEL Juan Carlos 3',
      codEmpleado: 3,
      dias: 0.4375,
      origen: 'G',
      detalle: 'ya tenia un permiso ese dia',
      totalAlta: 1,
      totalSalteados: 1,
      diasTotales: 0.4375,
    ),
  ];

  @override
  Future<String> aplicarPuente({
    required int idSabado,
    String horaDesde = '',
    String horaHasta = '',
    String motivo = '',
  }) async => 'Puente aplicado: 1 permiso(s).';

  /// Vacío: en los tests nadie es de RR.HH., así que el permiso de celda queda
  /// decidido por `esAdmin` y por el equipo del jefe. Es el caso que importa
  /// probar — el de RR.HH. abre todo y no distingue nada.
  @override
  Future<List<RrhhSabadosEntity>> getRrhh({String estado = ''}) async => const [];

  @override
  Future<void> registrarRrhh({
    required int idRrhh,
    required int codEmpleado,
    String observacion = '',
    required int audUsuario,
  }) async {}

  @override
  Future<void> eliminarRrhh({
    required int idRrhh,
    required int audUsuario,
  }) async {}

  /// Dos directos y uno más abajo, con uno fuera del rol: alcanza para que la
  /// previsualización tenga que dibujar sus tres casos (directo, sub-árbol y
  /// el aviso de «no participa»).
  @override
  Future<List<ProgramadorDependienteEntity>> previsualizarDependientes({
    required int codEmpleado,
    required int codSucursal,
    required String alcance,
    required int idRol,
  }) async => [
    const ProgramadorDependienteEntity(
      idProgramador: 0,
      codProgramador: 65,
      profundidad: 1,
      codDependiente: 223,
      nombreDependiente: 'BUITRAGO JULIO ANDRES',
      sucDependiente: 20,
      sucursal: 'CENTRAL',
      enElRol: 1,
    ),
    const ProgramadorDependienteEntity(
      idProgramador: 0,
      codProgramador: 65,
      profundidad: 1,
      codDependiente: 245,
      nombreDependiente: 'HOWARD ROGER',
      sucDependiente: 20,
      sucursal: 'CENTRAL',
      enElRol: 0,
    ),
    if (alcance == 'SUBARBOL')
      const ProgramadorDependienteEntity(
        idProgramador: 0,
        codProgramador: 65,
        profundidad: 2,
        codDependiente: 9,
        nombreDependiente: 'CANAVIRI FLAVIO',
        sucDependiente: 20,
        sucursal: 'CENTRAL',
        enElRol: 1,
      ),
  ];
}
