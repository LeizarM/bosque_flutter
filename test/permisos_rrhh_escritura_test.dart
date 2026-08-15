import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/models/simulacion_colectiva_model.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/simulacion_colectiva_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:bosque_flutter/presentation/screens/permisos-rrhh/permisos_rrhh_screen.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/abono_dias_tab.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/carga_colectiva_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/nomina_permisos_tab.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/vacacion_asignada_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Lo que tiene que ser cierto de las **escrituras** de Permisos RR.HH.
///
/// Estas pantallas mueven plata: una vacación asignada vale 15 a 30 días
/// pagados y un abono son días libres cobrados. Así que lo que se prueba no es
/// que se vea lindo, es que **no se escriba sola**:
///
/// 1. **Nada llega al servidor sin confirmación**, y la confirmación dice la
///    cantidad, a quién y con qué fecha. Un diálogo que pregunta «¿estás
///    seguro?» no deja verificar nada, así que se comprueba el texto.
/// 2. **Los dos umbrales no se confunden**: cero es válido en la vacación
///    asignada —446 filas lo tienen— y no existe en el abono de días. Es el
///    error fácil de este módulo.
/// 3. **La colectiva muestra antes de aplicar**: a cuántos alcanza, a cuántos
///    no y por qué, y el botón recién se enciende con eso a la vista.
/// 4. **En el teléfono la colectiva no se ofrece**, y la pantalla dice por qué
///    en vez de fingir que no existe.
void main() {
  // `AppConstants.baseUrl` lee `dotenv.env`, que lanza si nadie cargó el
  // archivo. Igual que en `permisos_rrhh_responsive_test.dart`.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  // ── La grilla: sólo lo registrado; el alta va arriba ──────────────────────
  testWidgets('la grilla lista sólo lo registrado y el alta nombra el año', (
    tester,
  ) async {
    await _dibujar(
      tester,
      hijo: const VacacionAsignadaTab(codEmpleado: 130),
      repo: _RepoEspia(historial: _historial),
    );

    // La sintética (id 0) es la que el SP inventa por el aniversario que
    // todavía no tiene registro. **No se lista**: mezclarla con las reales
    // hacía leer un año pendiente como uno cargado en cero.
    expect(find.text('Sin registrar'), findsNothing);

    // Pero el alta no desapareció con ella: subió a la cabecera, y dice a qué
    // aniversario va, porque el backend no acepta cualquier fecha.
    expect(find.text('Asignar 31/07/2026'), findsOneWidget);

    // Y la fila real sigue con sus dos acciones.
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('sin aniversarios pendientes no se ofrece cargar nada', (
    tester,
  ) async {
    await _dibujar(
      tester,
      hijo: const VacacionAsignadaTab(codEmpleado: 130),
      // Sólo la fila real: no queda ningún hueco por asignar.
      repo: _RepoEspia(historial: [_historial.first]),
    );

    // Ofrecer el alta llevaría a un formulario que el backend va a rechazar.
    expect(find.textContaining('Asignar '), findsNothing);
    expect(find.text('Editar'), findsOneWidget);
  });

  // ── Ninguna escritura sale sin confirmación explícita ─────────────────────
  testWidgets(
    'el alta pregunta con los números adentro, y cancelar no escribe',
    (tester) async {
      final repo = _RepoEspia(historial: _historial);
      await _dibujar(
        tester,
        hijo: const VacacionAsignadaTab(codEmpleado: 130),
        repo: repo,
      );

      await tester.tap(find.text('Asignar 31/07/2026'));
      await tester.pumpAndSettle();
      expect(find.text('Asignar vacación'), findsOneWidget);

      await tester.enterText(_campo('Días asignados'), '15');
      await tester.enterText(_campo('Motivo'), 'Aniversario 2026');
      await tester.tap(find.text('Asignar los días'));
      await tester.pumpAndSettle();

      // La confirmación tiene que poder verificarse **en una sola frase**:
      // cantidad, persona y fecha. Con los tres datos sueltos no se sabe si el
      // diálogo habla de la fila que se tocó.
      expect(
        find.textContaining(
          'Vas a asignar 15 días a BALDERRAMA CRISTHIAN ALEJANDRO con fecha '
          '31/07/2026',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.registrosVacacion, isEmpty, reason: 'escribió sin confirmar');

      // Y confirmando sí escribe, con la fecha del aniversario y no otra.
      await tester.tap(find.text('Asignar los días'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar'));
      await tester.pumpAndSettle();

      expect(repo.registrosVacacion, hasLength(1));
      expect(repo.registrosVacacion.single.diasAsignados, 15);
      expect(repo.registrosVacacion.single.fecha, DateTime(2026, 7, 31));
      // El alta va con `codVacacionAsignada` en 0: la acción la decide el id.
      expect(repo.registrosVacacion.single.codVacacionAsignada, 0);
    },
  );

  testWidgets('sin motivo no viaja nada al servidor', (tester) async {
    final repo = _RepoEspia(historial: _historial);
    await _dibujar(
      tester,
      hijo: const VacacionAsignadaTab(codEmpleado: 130),
      repo: repo,
    );

    await tester.tap(find.text('Asignar 31/07/2026'));
    await tester.pumpAndSettle();
    await tester.enterText(_campo('Días asignados'), '15');
    await tester.tap(find.text('Asignar los días'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vas a asignar'), findsNothing);
    expect(repo.registrosVacacion, isEmpty);
  });

  // ── Lo inusual: se avisa, no se bloquea ───────────────────────────────────
  //
  // **Es el 400 con `confirmable: true`, no el 409.** Los dos significan cosas
  // opuestas y el cliente los tenía al revés: el 409 es el doble toque, que
  // reintentando manda el mismo cuerpo y lo vuelven a rechazar.
  testWidgets(
    'lo confirmable se avisa con el texto del servidor y se puede insistir',
    (tester) async {
      final repo = _RepoEspia(historial: _historial, duplicadoLaPrimera: true);
      await _dibujar(
        tester,
        hijo: const VacacionAsignadaTab(codEmpleado: 130),
        repo: repo,
      );

      await tester.tap(find.text('Asignar 31/07/2026'));
      await tester.pumpAndSettle();
      await tester.enterText(_campo('Días asignados'), '15');
      await tester.enterText(_campo('Motivo'), 'Aniversario 2026');
      await tester.tap(find.text('Asignar los días'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar'));
      await tester.pumpAndSettle();

      // El primer intento va sin confirmar y el backend lo rebota con un 400
      // confirmable. **No es un fracaso, es una pregunta**: en esta tabla hay 215
      // grupos duplicados legítimos, casi todos del proceso automático.
      expect(repo.confirmaciones, [false]);
      expect(find.text('Revise antes de guardar'), findsOneWidget);
      expect(
        find.textContaining('Ya existe una asignación de 15 días ese día'),
        findsOneWidget,
      );

      await tester.tap(find.text('Guardar igual'));
      await tester.pumpAndSettle();

      // El reintento es el único que lleva la bandera: se manda porque alguien
      // leyó el aviso y decidió, no porque el cliente la mande siempre.
      expect(repo.confirmaciones, [false, true]);
      // Dos intentos, **una sola fila**: el que rebotó con el 400 no escribió.
      expect(repo.registrosVacacion, hasLength(1));
    },
  );

  testWidgets(
    'un error que no es confirmable se muestra y no ofrece insistir',
    (tester) async {
      // Así llega el 409 —doble toque o carrera con otra persona—: como una
      // excepción común. Insistir mandaría el mismo cuerpo, confirmación
      // incluida, así que la pantalla avisa, relee y no ofrece nada más.
      final repo = _RepoEspia(historial: _historial, errorAlRegistrar: true);
      await _dibujar(
        tester,
        hijo: const VacacionAsignadaTab(codEmpleado: 130),
        repo: repo,
      );

      await tester.tap(find.text('Asignar 31/07/2026'));
      await tester.pumpAndSettle();
      await tester.enterText(_campo('Días asignados'), '15');
      await tester.enterText(_campo('Motivo'), 'Aniversario 2026');
      await tester.tap(find.text('Asignar los días'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar'));
      await tester.pumpAndSettle();

      expect(find.text('Guardar igual'), findsNothing);
      expect(find.textContaining('Ya se cargó hace instantes'), findsOneWidget);
      expect(repo.registrosVacacion, isEmpty);
    },
  );

  // ── Los dos umbrales, que son distintos ───────────────────────────────────
  testWidgets('cero días es válido en la vacación asignada', (tester) async {
    final repo = _RepoEspia(historial: _historial);
    await _dibujar(
      tester,
      hijo: const VacacionAsignadaTab(codEmpleado: 130),
      repo: repo,
    );

    await tester.tap(find.text('Asignar 31/07/2026'));
    await tester.pumpAndSettle();
    await tester.enterText(_campo('Días asignados'), '0');
    await tester.enterText(_campo('Motivo'), 'Este año no le corresponde');
    await tester.tap(find.text('Asignar los días'));
    await tester.pumpAndSettle();

    // 446 de las 1.424 filas de la tabla valen 0: es un dato, no un vacío.
    expect(find.textContaining('Vas a asignar 0 días'), findsOneWidget);
  });

  testWidgets('cero días NO es válido en el abono, y ni pregunta', (
    tester,
  ) async {
    final repo = _RepoEspia(ficha: _ficha);
    await _dibujar(
      tester,
      hijo: const AbonoDiasTab(codEmpleado: 130),
      repo: repo,
    );

    await tester.tap(find.text('Abonar días'));
    await tester.pumpAndSettle();
    await tester.enterText(_campo('Días abonados'), '0');
    await tester.enterText(_campo('Motivo'), 'Compensación');
    await tester.tap(find.text('Abonar los días'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Vas a abonar'), findsNothing);
    expect(repo.registrosAbono, isEmpty);
  });

  // ── La baja: existe, avisa con el texto del servidor y es recuperable ─────
  testWidgets('borrar pide confirmación y muestra el mensaje del servidor', (
    tester,
  ) async {
    final repo = _RepoEspia(historial: _historial);
    await _dibujar(
      tester,
      hijo: const VacacionAsignadaTab(codEmpleado: 130),
      repo: repo,
    );

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sistemas puede recuperarla'), findsOneWidget);

    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(repo.bajasVacacion, hasLength(1));
    // El mensaje del backend se muestra tal cual: ya viene redactado.
    expect(find.text('Se borró la asignación de 15 días.'), findsOneWidget);
  });

  // ── La colectiva: primero la simulación, después el botón ─────────────────
  testWidgets('la vacación colectiva no se aplica sin haber visto a quiénes', (
    tester,
  ) async {
    final repo = _RepoEspia(padron: _padron, simulacion: _simulacion);
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      hijo: _AbridorDeColectiva(tipo: TipoCargaColectiva.vacacion),
      repo: repo,
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Sin nadie marcado no se puede ni pasar al paso 2.
    expect(
      _apagado(tester, 'Revisar antes de guardar'),
      isTrue,
      reason: 'dejaba pasar al paso 2 sin nadie marcado',
    );

    await tester.enterText(_campo('Motivo'), 'Cierre de gestión');
    await tester.tap(find.text('Marcar los 3 de la lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar antes de guardar'));
    await tester.pumpAndSettle();

    // El paso 2 dice a cuántos alcanza y a cuántos no, con el motivo de cada
    // exclusión. Los días son los del servidor: los feriados son por sucursal
    // y el número del cabezal no es el que se graba.
    expect(find.textContaining('2 personas'), findsOneWidget);
    expect(find.textContaining('Se saltean 1'), findsOneWidget);
    expect(find.text('ya tiene permiso ese día'), findsOneWidget);
    expect(repo.vacacionesColectivas, isEmpty);

    await tester.tap(find.text('Declarar la vacación'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Vas a cargar 2 permisos de vacación'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.vacacionesColectivas, isEmpty, reason: 'aplicó sin confirmar');

    await tester.tap(find.text('Declarar la vacación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Declarar'));
    await tester.pumpAndSettle();

    // Sólo los que entran: el excluido no viaja.
    expect(repo.vacacionesColectivas.single, [130, 48]);
  });

  // ── El abono colectivo también pregunta antes de confirmar ────────────────
  testWidgets(
    'el abono colectivo confirma con la lista del servidor, no con la marcada',
    (tester) async {
      // El bug que esto ataja: el paso 2 armaba la previa con la selección local
      // y ni llamaba a simular, así que decía «3 días a 3 empleados» cuando el
      // servidor iba a saltear a uno por no tener relación laboral activa.
      final repo = _RepoEspia(padron: _padron, simulacion: _simulacionAbono);
      await _dibujar(
        tester,
        tamano: const Size(1280, 900),
        hijo: _AbridorDeColectiva(tipo: TipoCargaColectiva.abonoDias),
        repo: repo,
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(_campo('Días a abonar'), '3');
      await tester.enterText(_campo('Motivo'), 'Inventario');
      await tester.tap(find.text('Marcar los 3 de la lista'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revisar antes de guardar'));
      await tester.pumpAndSettle();

      // Se le preguntó al servidor por los tres marcados…
      expect(repo.simulacionesAbono.single, [130, 48, 77]);
      // …y lo que se confirma son los dos que entran, con el motivo del tercero.
      expect(find.textContaining('a 2 personas'), findsOneWidget);
      expect(find.textContaining('Se saltean 1'), findsOneWidget);
      expect(find.text('no tiene relación laboral activa'), findsOneWidget);
      expect(repo.abonosColectivos, isEmpty);

      await tester.tap(find.text('Abonar a todos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abonar'));
      await tester.pumpAndSettle();

      // Sólo los que entran: el salteado no viaja.
      expect(repo.abonosColectivos.single, [130, 48]);
    },
  );

  // ── En el teléfono la colectiva no se ofrece, y se dice por qué ───────────
  testWidgets('en móvil no hay cargas colectivas', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(360, 740),
      hijo: const PermisosRrhhScreen(),
      repo: _RepoEspia(),
      conBreakpoints: true,
    );

    expect(find.byTooltip('Vacación colectiva'), findsNothing);
    expect(find.byTooltip('Abono de días a varias personas'), findsNothing);
  });

  // El motivo ya no vive en una cabecera fija: está en el bloque de altas, que
  // es donde se buscan. Esconder sin explicar se lee como que el sistema falla.
  testWidgets('en móvil el bloque de altas dice por qué faltan', (
    tester,
  ) async {
    await _dibujar(
      tester,
      tamano: const Size(360, 740),
      hijo: const NominaPermisosTab(codEmpleado: 130),
      repo: _RepoEspia(),
    );
    expect(
      find.textContaining('necesitan una tablet o una computadora'),
      findsOneWidget,
    );
  });

  // ── Cambiar de empleado en el panel maestro ───────────────────────────────
  //
  // Elegir a otra persona no destruye esta pestaña: es el mismo tipo de widget
  // en la misma posición del `TabBarView`, así que Flutter reusa su `State` y
  // la clave congelada del kardex —que solo pisa el botón «Buscar permisos»—
  // seguía apuntando al empleado anterior. La pantalla cambiaba de nombre y la
  // lista de abajo era de otro.
  testWidgets('cambiar de empleado vuelve a consultar el kardex', (
    tester,
  ) async {
    final repo = _RepoEspia();
    var cod = 130;
    late void Function(VoidCallback) cambiar;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith(
            (ref) => UserStateNotifier.sinStorage(_admin),
          ),
          permisosRrhhRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, setState) {
                cambiar = setState;
                return NominaPermisosTab(codEmpleado: cod);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 2));
    expect(repo.consultasNomina, [130]);

    cambiar(() => cod = 47);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 2));

    expect(
      repo.consultasNomina,
      [130, 47],
      reason: 'la pestaña se quedó mostrando el kardex del empleado anterior',
    );
  });

  // La contracara, y es la que se rompía midiendo el cajón: en escritorio el
  // panel de detalle mide 879 px —menos que una tablet— y el aviso salía junto
  // a los botones que dice que no existen.
  testWidgets('en escritorio ese aviso no aparece', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 900),
      hijo: const NominaPermisosTab(codEmpleado: 130),
      repo: _RepoEspia(),
    );
    expect(
      find.textContaining('necesitan una tablet o una computadora'),
      findsNothing,
    );
  });

  testWidgets('en escritorio las cargas colectivas sí están', (tester) async {
    await _dibujar(
      tester,
      tamano: const Size(1280, 800),
      hijo: const PermisosRrhhScreen(),
      repo: _RepoEspia(),
      conBreakpoints: true,
    );
    expect(find.byTooltip('Vacación colectiva'), findsOneWidget);
    expect(find.byTooltip('Abono de días a varias personas'), findsOneWidget);
  });

  // ── Que entren, a los anchos del criterio de aceptación ───────────────────
  final anchos = <String, Size>{
    'móvil 360×740': const Size(360, 740),
    'tablet 800×1200': const Size(800, 1200),
    'escritorio 1280×800': const Size(1280, 800),
    'escritorio 1920×1080': const Size(1920, 1080),
    'iPad Pro 1024×1366': const Size(1024, 1366),
  };

  for (final entrada in anchos.entries) {
    testWidgets('la vacación asignada entra en ${entrada.key}', (tester) async {
      await _dibujar(
        tester,
        tamano: entrada.value,
        hijo: const VacacionAsignadaTab(codEmpleado: 130),
        repo: _RepoEspia(historial: _historial),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('los abonos entran en ${entrada.key}', (tester) async {
      await _dibujar(
        tester,
        tamano: entrada.value,
        hijo: const AbonoDiasTab(codEmpleado: 130),
        repo: _RepoEspia(ficha: _ficha, abonos: _abonos),
      );
      expect(tester.takeException(), isNull);
    });
  }

  // ── El total de abonos ────────────────────────────────────────────────────
  //
  // **Este número estuvo mal en producción y ninguna prueba lo vio**, porque el
  // repositorio falso rellenaba `totalDias` a mano. El servidor NO lo manda:
  // `p_list_AbonoDias 'L'` devuelve ocho columnas y ninguna es un total, y
  // `AbonoDiasDao.decorar` sólo agrega `diasAbonadosTxt`. El recuadro leía ese
  // campo vacío y mostraba «0 días» con filas cargadas abajo.
  //
  // Por eso el fixture ya no lo trae: si vuelve a inventarse, la prueba deja de
  // proteger justo lo que se rompió.
  testWidgets('el total suma las filas que se están viendo', (tester) async {
    await _dibujar(
      tester,
      hijo: const AbonoDiasTab(codEmpleado: 130),
      repo: _RepoEspia(ficha: _ficha, abonos: _abonos),
    );

    expect(find.text('Total abonado (2 registros)'), findsOneWidget);
    // 20,5 + 1
    expect(find.text('21,5 días'), findsOneWidget);
    expect(find.text('0 días'), findsNothing);
  });

  testWidgets(
    'la hoja de la colectiva entra en tablet, con el teclado abierto',
    (tester) async {
      await _dibujar(
        tester,
        tamano: const Size(1024, 1366),
        hijo: _AbridorDeColectiva(tipo: TipoCargaColectiva.abonoDias),
        repo: _RepoEspia(padron: _padron),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Abono de días a varias personas'), findsOneWidget);
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ANDAMIAJE
// ═══════════════════════════════════════════════════════════════════════════

/// El campo de texto cuyo rótulo es [etiqueta].
///
/// `find.widgetWithText` sirve acá porque `TextField` es la clase real. Para los
/// **botones** no sirve: `FilledButton.icon` construye una subclase privada y
/// `find.byType` compara el tipo exacto, así que devolvería cero. Por eso los
/// botones se buscan por su texto, que además es lo que ve quien usa la app.
Finder _campo(String etiqueta) => find.widgetWithText(TextField, etiqueta);

/// Si el botón que dice [texto] está apagado.
///
/// `byWidgetPredicate` y no `byType`: ver la nota de [_campo].
bool _apagado(WidgetTester tester, String texto) =>
    tester
        .widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text(texto),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
        )
        .onPressed ==
    null;

/// Un botón que abre la hoja de carga colectiva.
///
/// La hoja se abre desde la barra de la pantalla, que además está detrás del
/// ACL; para probar la hoja en sí alcanza con algo que la muestre.
class _AbridorDeColectiva extends StatelessWidget {
  const _AbridorDeColectiva({required this.tipo});
  final TipoCargaColectiva tipo;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () => mostrarCargaColectivaSheet(context: context, tipo: tipo),
      child: const Text('abrir'),
    ),
  );
}

Future<void> _dibujar(
  WidgetTester tester, {
  required Widget hijo,
  required _RepoEspia repo,
  Size tamano = const Size(1280, 900),
  bool conBreakpoints = false,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Widget app = MaterialApp(home: Scaffold(body: hijo));
  if (conBreakpoints) {
    app = MaterialApp(
      home: hijo,
      builder:
          (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: ResponsiveUtilsBosque.breakpoints,
          ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(_admin),
        ),
        permisosRrhhRepositoryProvider.overrideWithValue(repo),
      ],
      child: app,
    ),
  );
  await tester.pumpAndSettle();
  // `PermissionWidget` deja temporizadores colgados esperando al servidor, que
  // acá no existe. Ver la nota de `permisos_rrhh_responsive_test.dart`.
  await tester.pump(const Duration(minutes: 2));
}

/// `ROLE_ADM` para que `PermissionWidget` deje pasar: el ACL de verdad se
/// resuelve en el servidor.
final _admin = LoginEntity.fromJson(<String, dynamic>{
  'tipoUsuario': 'ROLE_ADM',
  'codUsuario': 34,
});

/// Devuelve lo que se le puso y **anota lo que le pidieron escribir**.
///
/// Lo que estas pruebas miden es justamente eso: que nada llegue acá sin haber
/// pasado por la confirmación.
class _RepoEspia implements PermisosRrhhRepository {
  _RepoEspia({
    this.historial = const [],
    this.abonos = const [],
    this.padron = const [],
    this.simulacion = const [],
    this.ficha,
    this.duplicadoLaPrimera = false,
    this.errorAlRegistrar = false,
  });

  final List<VacacionAsignadaEntity> historial;
  final List<AbonoDiasEntity> abonos;
  final List<SimulacionColectivaEntity> padron;
  final List<SimulacionColectivaEntity> simulacion;
  final FichaSaldoEntity? ficha;

  /// Contesta el **400 confirmable** la primera vez, como haría el backend con
  /// un alta que pisa un aniversario que ya tiene registro.
  final bool duplicadoLaPrimera;

  /// Contesta un error común —el 409 del doble toque llega así—, que no se
  /// arregla insistiendo.
  final bool errorAlRegistrar;

  final registrosVacacion = <VacacionAsignadaEntity>[];

  /// El valor de `confirmado` de cada intento, en orden.
  final confirmaciones = <bool>[];
  final registrosAbono = <AbonoDiasEntity>[];
  final bajasVacacion = <VacacionAsignadaEntity>[];
  final vacacionesColectivas = <List<int>>[];
  final abonosColectivos = <List<int>>[];

  /// A quiénes se le preguntó al servidor antes de mostrar la confirmación.
  /// Que esto quede vacío es el bug que tenía la hoja: confirmaba sin preguntar.
  final simulacionesAbono = <List<int>>[];

  /// El buscador de la pantalla lo llama apenas se dibuja. Sin esto,
  /// `noSuchMethod` lanza y la pantalla se llena con el error en vez de con lo
  /// que la prueba viene a mirar.
  @override
  Future<List<EmpleadoEntity>> buscarEmpleados(
    String texto, {
    bool soloActivos = true,
    int codEmpresa = 0,
    int pagina = 1,
    int porPagina = 50,
  }) async => const [];

  @override
  Future<List<VacacionAsignadaEntity>> getHistorialVacacionAsignada(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    DateTime? hasta,
  }) async => historial;

  @override
  Future<List<AbonoDiasEntity>> getDetalleAbonos(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
  }) async => abonos;

  @override
  Future<FichaSaldoEntity?> getFichaSaldo(int codEmpleado) async => ficha;

  /// A qué empleado se le pidió el kardex, en orden de llamada.
  ///
  /// Es lo único que mide la prueba de cambio de empleado: si el segundo código
  /// no aparece acá, la pestaña se quedó consultando a la persona anterior.
  final consultasNomina = <int>[];

  @override
  Future<List<NominaPermisoEntity>> getNominaPermisos(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    String tipoPermiso = '',
    DateTime? desde,
    DateTime? hasta,
    DateTime? fecRango,
  }) async {
    consultasNomina.add(codEmpleado);
    return const [];
  }

  @override
  Future<List<SimulacionColectivaEntity>> getEmpleadosParaColectiva({
    int codEmpresa = 0,
  }) async => padron;

  @override
  Future<List<SimulacionColectivaEntity>> simularVacacionColectiva({
    required List<int> codEmpleados,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async => simulacion;

  /// Devuelve **la fila releída**, como el controller: `data` es un objeto.
  /// Los días llegan con el texto ya formateado por el backend, que es lo que
  /// la hoja avisa.
  @override
  Future<VacacionAsignadaEntity> registrarVacacionAsignada(
    VacacionAsignadaEntity vacacion, {
    bool confirmado = false,
  }) async {
    confirmaciones.add(confirmado);
    if (errorAlRegistrar) {
      throw Exception('Ya se cargó hace instantes; refrescá la pantalla.');
    }
    if (duplicadoLaPrimera && !confirmado) {
      // El 400 con `confirmable: true`, que SÍ se arregla insistiendo. El 409
      // no llega como este tipo: ver `RequiereConfirmacion`.
      throw const RequiereConfirmacion(
        'Ya existe una asignación de 15 días ese día para este empleado.',
      );
    }
    registrosVacacion.add(vacacion);
    return vacacion.copyWith();
  }

  @override
  Future<AbonoDiasEntity> registrarAbonoDias(
    AbonoDiasEntity abono, {
    bool confirmado = false,
  }) async {
    registrosAbono.add(abono);
    return abono.copyWith();
  }

  @override
  Future<String> eliminarVacacionAsignada(
    VacacionAsignadaEntity vacacion,
  ) async {
    bajasVacacion.add(vacacion);
    return 'Se borró la asignación de 15 días.';
  }

  @override
  Future<String> eliminarAbonoDias(AbonoDiasEntity abono) async =>
      'Se borró el abono.';

  @override
  Future<String> aplicarVacacionColectiva({
    required List<int> codEmpleados,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    vacacionesColectivas.add(codEmpleados);
    return 'Se cargaron ${codEmpleados.length} permisos.';
  }

  @override
  Future<String> aplicarAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  }) async {
    abonosColectivos.add(codEmpleados);
    return 'Se acreditaron días a ${codEmpleados.length} personas.';
  }

  /// El dry-run del abono colectivo. Devuelve lo mismo que el del servidor: los
  /// días del cabezal repetidos y los omitidos con su motivo.
  @override
  Future<List<SimulacionColectivaEntity>> simularAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  }) async {
    simulacionesAbono.add(codEmpleados);
    return simulacion;
  }

  /// El resto del contrato, que estas pruebas no tocan.
  @override
  dynamic noSuchMethod(Invocation invocacion) =>
      throw UnimplementedError(
        'El repositorio de prueba no implementa ${invocacion.memberName}',
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// DATOS DE MENTIRA, CON LA FORMA REAL
// ═══════════════════════════════════════════════════════════════════════════

/// Una fila real y una **sintética**, que es como llega la grilla: el SP mezcla
/// las asignaciones que existen con una fila de `codVacacionAsignada = 0` por
/// cada aniversario que todavía no tiene registro.
final _historial = [
  VacacionAsignadaEntity(
    codVacacionAsignada: 812,
    codEmpleado: 130,
    codRelEmplEmpr: 411,
    diasAsignados: 15,
    diasAsignadosTxt: '15 días',
    motivo: 'Aniversario 2025',
    fecha: DateTime(2025, 7, 31),
    datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
    datoRelacion: 'Desde la fecha : 31/07/2019',
  ),
  VacacionAsignadaEntity(
    codVacacionAsignada: 0,
    codEmpleado: 130,
    codRelEmplEmpr: 411,
    diasAsignados: 0,
    motivo: '',
    fecha: DateTime(2026, 7, 31),
    datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
    datoRelacion: 'Desde la fecha : 31/07/2019',
  ),
];

final _abonos = [
  AbonoDiasEntity(
    codAbonoDias: 55,
    codEmpleado: 130,
    codRelEmplEmpr: 411,
    diasAbonados: 20.5,
    diasAbonadosTxt: '20,5 días',
    fecha: DateTime(2021, 10, 25),
    motivo: 'REGULARIZACION DE DIAS DE VACACION PENDIENTES',
    fila: 1,
  ),
  AbonoDiasEntity(
    codAbonoDias: 56,
    codEmpleado: 130,
    codRelEmplEmpr: 411,
    diasAbonados: 1,
    diasAbonadosTxt: '1 día',
    fecha: DateTime(2021, 10, 25),
    motivo: 'compensacion 23 de octubre',
    fila: 2,
  ),
];

const _ficha = FichaSaldoEntity(
  codEmpleado: 130,
  datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
  datoEmpresa: 'INDUSTRIAS DE PAPEL IMPEXPAP S.A.',
  datoCargo: 'OPERADOR DE MAQUINA CONVERTIDORA',
  datoFechaBeneficio: '01/03/2015',
  datoAntiguedad: '11 Años y 5 Meses',
  diasNoUsados: 12.5,
  diasAbonados: 21.5,
  totalDias: 34,
  diasNoUsadosTxt: '12,5 días',
  diasAbonadosTxt: '21,5 días',
  totalDiasTxt: '34 días',
  datoRelEmplEmprVigente: 411,
  tieneRelacionesAnteriores: false,
  movimientosFueraDeRelacionVigente: 0,
);

const _padron = [
  SimulacionColectivaEntity(
    codEmpleado: 130,
    datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
    codRelEmplEmpr: 411,
    datoEmpresa: 'BOSQUE S.R.L.',
    datoSucursal: 'PLANTA',
  ),
  SimulacionColectivaEntity(
    codEmpleado: 48,
    datoEmpleado: 'RAMOS RODRIGO',
    codRelEmplEmpr: 500,
    datoEmpresa: 'BOSQUE S.R.L.',
    datoSucursal: 'PLANTA',
  ),
  SimulacionColectivaEntity(
    codEmpleado: 77,
    datoEmpleado: 'ZABALLA OSCAR',
    codRelEmplEmpr: 501,
    datoEmpresa: 'IMPEXPAP',
    datoSucursal: 'OFICINA',
  ),
];

/// La simulación del **abono**: los mismos días para todos —ese número no se
/// recalcula— pero uno que igual queda afuera, que es lo que sólo sabe el
/// servidor. Llega con las claves del `model` de la tabla (`diasAbonados`,
/// `aplica`, `motivoOmision`), que el modelo traduce.
final _simulacionAbono = [
  SimulacionColectivaModel.fromJson(const {
    'codEmpleado': 130,
    'datoEmpleado': 'BALDERRAMA CRISTHIAN ALEJANDRO',
    'codRelEmplEmpr': 411,
    'diasAbonados': 3,
    'diasAbonadosTxt': '3 días',
    'aplica': true,
  }).toEntity(),
  SimulacionColectivaModel.fromJson(const {
    'codEmpleado': 48,
    'datoEmpleado': 'RAMOS RODRIGO',
    'codRelEmplEmpr': 500,
    'diasAbonados': 3,
    'diasAbonadosTxt': '3 días',
    'aplica': true,
  }).toEntity(),
  SimulacionColectivaModel.fromJson(const {
    'codEmpleado': 77,
    'datoEmpleado': 'ZABALLA OSCAR',
    'aplica': false,
    'motivoOmision': 'no tiene relación laboral activa',
  }).toEntity(),
];

/// Lo que devuelve el servidor: **días distintos por persona** —los feriados
/// son por sucursal— y uno que queda afuera con su motivo.
const _simulacion = [
  SimulacionColectivaEntity(
    codEmpleado: 130,
    datoEmpleado: 'BALDERRAMA CRISTHIAN ALEJANDRO',
    codRelEmplEmpr: 411,
    dias: 5,
    diasTxt: '5 días',
  ),
  SimulacionColectivaEntity(
    codEmpleado: 48,
    datoEmpleado: 'RAMOS RODRIGO',
    codRelEmplEmpr: 500,
    dias: 4.5,
    diasTxt: '4,5 días',
  ),
  SimulacionColectivaEntity(
    codEmpleado: 77,
    datoEmpleado: 'ZABALLA OSCAR',
    codRelEmplEmpr: 501,
    entra: false,
    detalle: 'ya tiene permiso ese día',
  ),
];
