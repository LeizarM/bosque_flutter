// Verificar Traspaso de Efectivo Entre Sistemas — TesBase (2026-09-11).
//
// Marcelo, con la captura de la tarea 289 diciendo "Este tipo de tarea se
// gestiona todavía desde el sistema anterior": "eso también impleméntalo".
// Decidió migrar solo la verificación y que cierre el día como Caja AXA.
//
// Después, con la pantalla andando: "aquí tiene que aparecer de un día
// anterior por defecto y si es feriado, domingo o lunes, de dos días antes".
//
// Lo que se fija aquí es lo que es fácil de volver a romper: que verificar
// TAMBIÉN cierre la tarea (en el sistema anterior no, y la 289 juntó 1372 sin
// responder), que "no pude leer" no se confunda con "no hay pendientes", y qué
// día revisa cada ocurrencia.
import 'package:bosque_flutter/core/state/traspaso_efectivo_tesbase_provider.dart';
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/traspaso_efectivo_tesbase_model.dart';
import 'package:bosque_flutter/domain/entities/traspaso_efectivo_tesbase_entity.dart';
import 'package:bosque_flutter/domain/repositories/traspaso_efectivo_tesbase_repository.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/traspaso_efectivo_tesbase_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

bool _mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

TraspasoEfectivoTesBaseEntity _transferencia(
  int codTes, {
  DateTime? registrada,
  String estado = 'PEN',
  String? obs,
}) => TraspasoEfectivoTesBaseEntity(
  codTes: codTes,
  codCliente: 'C00$codTes',
  datoCliente: 'CLIENTE $codTes S.R.L.',
  nombreEmpresa: 'IMPEXPAP',
  fechaRegistro: registrada ?? DateTime(2026, 9, 10),
  observacion: obs,
  estado: estado,
);

class _RepoFalso implements TraspasoEfectivoTesBaseRepository {
  _RepoFalso({List<TraspasoEfectivoTesBaseEntity>? filas, DiaRevisadoTesBase? revisado})
    : filas = filas ?? [],
      revisado =
          revisado ??
          DiaRevisadoTesBase(
            fechaTarea: DateTime(2026, 9, 11),
            fechaRevisada: DateTime(2026, 9, 10),
          );

  /// Todas, en cualquier estado y fecha, como en ttes_TesBase.
  List<TraspasoEfectivoTesBaseEntity> filas;
  DiaRevisadoTesBase revisado;
  bool fallaAlLeer = false;

  /// Si no es nulo, "sin pendientes" lo rechaza y aparece esta transferencia,
  /// como si Cobranza hubiera registrado una mientras la pantalla estaba
  /// abierta.
  TraspasoEfectivoTesBaseEntity? apareceAlCerrarDia;

  final cerradas = <(int, int)>[];
  final diasRevisados = <int>[];
  final diasPedidos = <DateTime>[];

  void _quizasFalla() {
    if (fallaAlLeer) throw Exception('sin conexión');
  }

  @override
  Future<DiaRevisadoTesBase> diaRevisado({required int idBitTarRuti}) async {
    _quizasFalla();
    return revisado;
  }

  @override
  Future<List<TraspasoEfectivoTesBaseEntity>> delDia(DateTime fecha) async {
    _quizasFalla();
    diasPedidos.add(fecha);
    return [
      for (final f in filas)
        if (_mismoDia(f.fechaRegistro!, fecha)) f,
    ];
  }

  @override
  Future<List<TraspasoEfectivoTesBaseEntity>> pendientes() async {
    _quizasFalla();
    return [
      for (final f in filas)
        if (f.pendiente) f,
    ];
  }

  @override
  Future<void> cerrar({required int codTes, required int idBitTarRuti}) async {
    cerradas.add((codTes, idBitTarRuti));
    filas = [
      for (final f in filas)
        f.codTes == codTes
            ? _transferencia(f.codTes, registrada: f.fechaRegistro, estado: 'CER')
            : f,
    ];
  }

  @override
  Future<void> sinPendientes({required int idBitTarRuti}) async {
    final nueva = apareceAlCerrarDia;
    if (nueva != null) {
      filas = [...filas, nueva];
      throw Exception(
        'Todavia hay 1 transferencia(s) pendiente(s) registrada(s) hasta el '
        '10/09/2026. Hay que cerrarlas antes de dar el dia por revisado.',
      );
    }
    diasRevisados.add(idBitTarRuti);
  }
}

const _idBitTarea = 900;

Future<void> _abrir(WidgetTester tester, _RepoFalso repo) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        traspasoEfectivoTesBaseProvider.overrideWith(
          (ref, idBitTarea) => TraspasoEfectivoTesBaseNotifier(repo, idBitTarea),
        ),
      ],
      child: MaterialApp(
        home: TraspasoEfectivoTesBaseScreen(
          idBitTarea: _idBitTarea,
          nombreTarea: 'Verificar Traspaso de Efectivo Entre Sistemas',
          fecha: DateTime(2026, 9, 11),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpLecturas(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

bool _sinPendientesHabilitado(WidgetTester tester) {
  final boton = tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text('Sin pendientes'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    ),
  );
  return boton.onPressed != null;
}

/// Deja vencer los avisos: cada uno tiene su propio temporizador.
Future<void> _dejarVencerAvisos(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 15));

void main() {
  group('qué día revisa', () {
    testWidgets('el lunes abre el sábado y dice por qué', (tester) async {
      final repo = _RepoFalso(
        revisado: DiaRevisadoTesBase(
          fechaTarea: DateTime(2026, 9, 7),
          fechaRevisada: DateTime(2026, 9, 5),
        ),
      );
      await _abrir(tester, repo);

      expect(repo.diasPedidos, [DateTime(2026, 9, 5)]);
      expect(find.text('sábado 05/09/2026'), findsOneWidget);
      expect(
        find.text(
          'Es el día hábil anterior a la tarea: el domingo no se trabaja.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('después de un feriado lo nombra', (tester) async {
      await _abrir(
        tester,
        _RepoFalso(
          revisado: DiaRevisadoTesBase(
            fechaTarea: DateTime(2026, 7, 17),
            fechaRevisada: DateTime(2026, 7, 15),
            feriado: 'DIA DE LA PAZ',
          ),
        ),
      );
      expect(
        find.text(
          'Es el día hábil anterior a la tarea: el jueves fue feriado '
          '(Dia de la Paz).',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mirar otro día no cambia lo que revisa la tarea', (
      tester,
    ) async {
      final repo = _RepoFalso(
        filas: [_transferencia(4, registrada: DateTime(2026, 9, 8), estado: 'CER')],
      );
      await _abrir(tester, repo);

      final contenedor = ProviderScope.containerOf(
        tester.element(find.byType(TraspasoEfectivoTesBaseScreen)),
      );
      await contenedor
          .read(traspasoEfectivoTesBaseProvider(_idBitTarea).notifier)
          .verDia(DateTime(2026, 9, 8));
      await _pumpLecturas(tester);

      expect(find.text('martes 08/09/2026'), findsOneWidget);
      expect(find.text('Volver al jueves 10/09/2026'), findsOneWidget);
      expect(find.text('C004 · CLIENTE 4 S.R.L.'), findsOneWidget);
      expect(find.text('Cerrada'), findsOneWidget);
      expect(
        _sinPendientesHabilitado(tester),
        isTrue,
        reason: '"Sin pendientes" sigue siendo sobre el 10/09.',
      );
    });
  });

  group('la pantalla', () {
    testWidgets('sin nada registrado ni pendiente ofrece dar el día por '
        'revisado', (tester) async {
      await _abrir(tester, _RepoFalso());
      expect(
        find.text('No se registraron transferencias el jueves 10/09/2026'),
        findsOneWidget,
      );
      expect(
        find.text('No queda ninguna pendiente hasta el 10/09/2026.'),
        findsOneWidget,
      );
      expect(_sinPendientesHabilitado(tester), isTrue);
    });

    testWidgets('con pendientes del día revisado no lo habilita y dice '
        'cuántas faltan', (tester) async {
      await _abrir(
        tester,
        _RepoFalso(filas: [_transferencia(1), _transferencia(2)]),
      );
      expect(
        find.text('Faltan 2 por cerrar hasta el 10/09/2026.'),
        findsOneWidget,
      );
      expect(_sinPendientesHabilitado(tester), isFalse);
      expect(find.text('C001 · CLIENTE 1 S.R.L.'), findsOneWidget);
    });

    testWidgets('una registrada después del día revisado no bloquea', (
      tester,
    ) async {
      // Le toca a la ocurrencia de mañana. Contarla, como se hacía antes del
      // archivo 58, impedía dar por revisado el día anterior.
      await _abrir(
        tester,
        _RepoFalso(
          filas: [_transferencia(3, registrada: DateTime(2026, 9, 11))],
        ),
      );
      expect(
        find.text('No queda ninguna pendiente hasta el 10/09/2026.'),
        findsOneWidget,
      );
      expect(_sinPendientesHabilitado(tester), isTrue);
    });

    testWidgets('las pendientes de días anteriores se ven arriba', (
      tester,
    ) async {
      await _abrir(
        tester,
        _RepoFalso(
          filas: [_transferencia(8, registrada: DateTime(2026, 9, 8))],
        ),
      );
      expect(find.text('Pendientes de días anteriores'), findsOneWidget);
      expect(find.text('C008 · CLIENTE 8 S.R.L.'), findsOneWidget);
      expect(find.text('Ese día no se registró ninguna.'), findsOneWidget);
      expect(
        find.text('Falta 1 por cerrar hasta el 10/09/2026.'),
        findsOneWidget,
      );
    });

    testWidgets('una falla al leer no habilita "Sin pendientes"', (
      tester,
    ) async {
      final repo = _RepoFalso()..fallaAlLeer = true;
      await _abrir(tester, repo);
      expect(find.text('No se pudo leer las transferencias.'), findsOneWidget);
      expect(find.text('Sin pendientes'), findsNothing);

      repo.fallaAlLeer = false;
      await tester.tap(find.text('Reintentar'));
      await _pumpLecturas(tester);
      expect(_sinPendientesHabilitado(tester), isTrue);
      await _dejarVencerAvisos(tester);
    });

    testWidgets('cerrar pide confirmación y manda la ocurrencia de la tarea', (
      tester,
    ) async {
      final repo = _RepoFalso(filas: [_transferencia(7)]);
      await _abrir(tester, repo);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.cerradas, isEmpty, reason: 'Cancelar no cierra nada.');

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, cerrar'));
      await _pumpLecturas(tester);
      expect(repo.cerradas, [(7, _idBitTarea)]);
      expect(find.text('Cerrada'), findsOneWidget);
      expect(
        _sinPendientesHabilitado(tester),
        isTrue,
        reason: 'Cerrada la última, recién ahí se puede dar el día por revisado.',
      );
      await _dejarVencerAvisos(tester);
    });

    testWidgets('si el servidor rechaza "sin pendientes", la pantalla se queda '
        'y muestra la que apareció', (tester) async {
      final repo = _RepoFalso()..apareceAlCerrarDia = _transferencia(9);
      await _abrir(tester, repo);

      await tester.tap(find.text('Sin pendientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sí, dar por revisado'));
      await _pumpLecturas(tester);

      expect(repo.diasRevisados, isEmpty);
      expect(
        find.text('Falta 1 por cerrar hasta el 10/09/2026.'),
        findsOneWidget,
      );
      expect(find.text('C009 · CLIENTE 9 S.R.L.'), findsOneWidget);
      await _dejarVencerAvisos(tester);
    });
  });

  group('los datos', () {
    test('la fecha DATE no se corre de día por la zona horaria', () {
      // La Paz es UTC-4: la medianoche local viaja como las 04:00 UTC del
      // mismo día. Convertir el instante a la zona del teléfono podía mover
      // el día; tomar la parte de la fecha no.
      expect(soloFecha('2024-10-01T04:00:00.000+00:00'), DateTime(2024, 10, 1));
      expect(soloFecha('2024-10-01'), DateTime(2024, 10, 1));
      expect(soloFecha(null), isNull);
      expect(soloFecha('no es una fecha'), isNull);
    });

    test('la base de origen se lee aunque el SP la llame "nombre"', () {
      final m = TraspasoEfectivoTesBaseModel.fromJson({
        'codTes': 12,
        'nombre': 'IMPEXPAP',
      });
      expect(m.nombreEmpresa, 'IMPEXPAP');
    });

    test('el cliente no deja separadores sueltos cuando falta un dato', () {
      expect(
        const TraspasoEfectivoTesBaseEntity(codTes: 1, datoCliente: 'ACME').cliente,
        'ACME',
      );
      expect(
        const TraspasoEfectivoTesBaseEntity(codTes: 1).cliente,
        'Cliente sin datos',
      );
    });

    test('los días pendientes se cuentan por fecha, no por horas', () {
      final t = TraspasoEfectivoTesBaseEntity(
        codTes: 1,
        fechaRegistro: DateTime(2026, 9, 10),
      );
      expect(t.diasPendiente(DateTime(2026, 9, 11, 0, 30)), 1);
      expect(t.diasPendiente(DateTime(2026, 9, 10, 23, 59)), 0);
    });

    test('el estado se dice para una persona', () {
      expect(_transferencia(1).estadoTexto, 'Pendiente');
      expect(_transferencia(1, estado: 'CER').estadoTexto, 'Cerrada');
      expect(_transferencia(1, estado: 'cer ').pendiente, isFalse);
      expect(_transferencia(1, estado: ' pen').pendiente, isTrue);
    });

    test('los días saltados son los que quedan entre el revisado y la tarea', () {
      // Carnaval 2026: lunes 16 y martes 17. El miércoles 18 revisa el sábado.
      expect(
        DiaRevisadoTesBase(
          fechaTarea: DateTime(2026, 2, 18),
          fechaRevisada: DateTime(2026, 2, 14),
        ).diasSaltados,
        [DateTime(2026, 2, 15), DateTime(2026, 2, 16), DateTime(2026, 2, 17)],
      );
      expect(
        DiaRevisadoTesBase(
          fechaTarea: DateTime(2026, 9, 8),
          fechaRevisada: DateTime(2026, 9, 7),
        ).diasSaltados,
        isEmpty,
      );
    });

    test('el día revisado se lee de la respuesta del servidor', () {
      final e =
          DiaRevisadoTesBaseModel.fromJson({
            'fechaTarea': '2026-09-07 00:00:00',
            'fechaRevisada': '2026-09-05 00:00:00',
            'feriado': null,
          }).toEntity()!;
      expect(e.fechaTarea, DateTime(2026, 9, 7));
      expect(e.fechaRevisada, DateTime(2026, 9, 5));
      expect(e.feriado, isNull);
      expect(const DiaRevisadoTesBaseModel().toEntity(), isNull);
    });
  });
}
