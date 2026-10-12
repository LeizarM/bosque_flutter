// Caja chica y talonarios (archivo SQL 93).
//
// - Con un talonario de vales entregado, la caja chica propone el vale que
//   sigue y lo manda; si la persona escribe otro, manda ese. El SP decide.
// - Sin talonario, el vale sigue siendo opcional.
// - En Talonarios, el historial dice en qué egreso se usó cada vale.
import 'dart:typed_data';

import 'package:bosque_flutter/core/state/caja_chica_flujo_provider.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/data/models/caja_chica_model.dart';
import 'package:bosque_flutter/data/models/talonario_caja_chica_model.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_caja_chica_entity.dart';
import 'package:bosque_flutter/domain/repositories/caja_chica_flujo_repository.dart';
import 'package:bosque_flutter/domain/repositories/talonarios_repository.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/caja_chica_screen.dart';
import 'package:bosque_flutter/presentation/widgets/talonarios/uso_caja_chica.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // El formulario arma el buscador de empleados con el cliente HTTP real.
  setUpAll(() => dotenv.testLoad(fileInput: ''));

  group('lectura de las filas del SP', () {
    test('un talonario de la rama V', () {
      final t = talonarioCajaChicaDeJson({
        'codTalonario': 1138,
        'nroTalonario': 'VCC001',
        'numeracionInicial': 1,
        'numeracionFinal': 50,
        'usados': 4,
        'libres': 46,
        'ultimoVale': 5,
        'siguienteVale': 6,
      });
      expect(t.nroTalonario, 'VCC001');
      expect(t.desde, 1);
      expect(t.hasta, 50);
      expect(t.siguienteVale, 6);
    });

    test('el talonario activo de la rama V (archivo 97)', () {
      expect(talonarioCajaChicaDeJson({'activo': true}).activo, isTrue);
      expect(talonarioCajaChicaDeJson({'activo': 1}).activo, isTrue);
      expect(talonarioCajaChicaDeJson({'activo': 0}).activo, isFalse);
      // Sin el 97 la columna no viene: ninguno es el activo.
      expect(talonarioCajaChicaDeJson({}).activo, isFalse);
    });

    test('a nombre de quién está (archivo 98)', () {
      expect(
        talonarioCajaChicaDeJson({'titular': ' JUAN PEREZ '}).titular,
        'JUAN PEREZ',
      );
      // Entregado a la sucursal: sin titular.
      expect(talonarioCajaChicaDeJson({'titular': null}).titular, '');
    });

    test('un vale de la rama T, usado o no', () {
      final usado = valeCajaChicaDeJson({
        'numVale': 3,
        'usado': true,
        'fecha': '2026-10-06',
        'montoEg': 21.0,
        'descripcion': 'Pasajes',
        'nombreSucursal': 'CENTRAL',
        'lote': 22,
        'nombreEmpDestino': 'ELIZABETH VILLARROEL',
      });
      expect(usado.usado, isTrue);
      expect(usado.fecha, DateTime(2026, 10, 6));
      expect(usado.monto, 21.0);

      expect(usado.nombreSucursal, 'CENTRAL');
    });

    test('un movimiento de la rama D trae su talonario (archivo 94)', () {
      final m =
          CajaChicaModel.fromJson({
            'idCC': 3644,
            'numVale': 1,
            'codTalonario': 1138,
            'nroTalonario': 'VCC001',
            'audUsuario': 34,
          }).toEntity();
      expect(m.nroTalonario, 'VCC001');
      // No viaja de vuelta: lo graba el SP después de validar el vale.
      expect(
        CajaChicaModel.fromEntity(m).toJson().containsKey('nroTalonario'),
        isFalse,
      );
    });

    test('un vale de la rama T sin usar', () {
      final libre = valeCajaChicaDeJson({'numVale': 4, 'usado': 0});
      expect(libre.usado, isFalse);
      expect(libre.descripcion, '');
    });
  });

  group('cómo va un talonario', () {
    test('cuenta lo que queda después del último y los saltados', () {
      final uso = UsoTalonarioCajaChica(_vales(50, usados: {1, 2, 3, 5}));
      expect(uso.usados, hasLength(4));
      expect(uso.ultimo, 5);
      expect(uso.quedan, 45);
      expect(uso.saltados, [4]);
    });

    test('sin usar: quedan todos y no hay saltados', () {
      final uso = UsoTalonarioCajaChica(_vales(50));
      expect(uso.ultimo, isNull);
      expect(uso.quedan, 50);
      expect(uso.saltados, isEmpty);
    });
  });

  group('caja chica con talonario', () {
    testWidgets('cada movimiento dice de qué talonario salió su recibo', (
      t,
    ) async {
      await _abrirFormulario(t, _CajaChica(), abrir: false);
      expect(find.textContaining('Recibo N.5 (VCC001)'), findsOneWidget);
    });

    testWidgets('propone el recibo que sigue y lo manda', (t) async {
      final repo = _CajaChica(talonarios: [_vcc001()]);
      await _abrirFormulario(t, repo);

      expect(find.text('Próximo recibo · VCC001'), findsOneWidget);
      final recibo = find.widgetWithText(TextFormField, 'Número de recibo');
      expect(recibo, findsOneWidget);
      expect(
        find.descendant(of: recibo, matching: find.text('6')),
        findsOneWidget,
      );
      expect(
        find.text('VCC001 · folios 1–50 · sigue el 6 · quedan 45'),
        findsOneWidget,
      );

      await _registrar(t);
      expect(repo.valesMandados, [6]);
    });

    testWidgets('muestra la regla que escribe el servidor', (t) async {
      final repo = _CajaChica(
        talonarios: [_vcc001(activo: true)],
        reglas: const ReglasReciboCajaChica(
          titulo: 'Talonarios de tu sucursal',
          regla:
              'El número de recibo es obligatorio: tiene que ser de un '
              'talonario en uso y no haberse usado antes.',
          obligatorio: true,
        ),
      );
      await _abrirFormulario(t, repo);

      expect(find.text('Talonarios de tu sucursal'), findsOneWidget);
      expect(
        find.textContaining('tiene que ser de un talonario en uso'),
        findsOneWidget,
      );
    });

    testWidgets(
      'con varios entregados propone el activo y lista los que esperan',
      (t) async {
        // El activo no viene primero a propósito: manda la columna, no el orden.
        final repo = _CajaChica(
          talonarios: [
            _talonario('VCC002', 51, 100, siguiente: 51),
            _vcc001(activo: true),
            _talonario('VCC003', 101, 150, siguiente: 101),
          ],
        );
        await _abrirFormulario(t, repo);

        expect(find.text('Próximo recibo · VCC001'), findsOneWidget);
        expect(find.text('En uso'), findsOneWidget);
        expect(find.text('En espera'), findsOneWidget);
        expect(find.text('VCC002, VCC003'), findsOneWidget);
        await _registrar(t);
        expect(repo.valesMandados, [6]);
      },
    );

    testWidgets(
      'el talonario del responsable lo usa el cajero y dice de quién es',
      (t) async {
        final repo = _CajaChica(
          talonarios: [
            _talonario(
              'VCC050',
              2451,
              2500,
              siguiente: 2451,
              activo: true,
              titular: 'JUAN PEREZ',
            ),
          ],
        );
        await _abrirFormulario(t, repo);

        expect(
          find.text(
            'VCC050 de JUAN PEREZ · folios 2451–2500 · sigue el 2451 · quedan 50',
          ),
          findsOneWidget,
        );
        await _registrar(t);
        expect(repo.valesMandados, [2451]);
      },
    );

    testWidgets('si escribe otro recibo, manda ese', (t) async {
      final repo = _CajaChica(talonarios: [_vcc001()]);
      await _abrirFormulario(t, repo);

      await t.enterText(
        find.widgetWithText(TextFormField, 'Número de recibo'),
        '9',
      );
      await _registrar(t);
      expect(repo.valesMandados, [9]);
    });

    testWidgets('con el último recibo usado, avisa que no quedan libres', (
      t,
    ) async {
      final repo = _CajaChica(
        talonarios: [_vcc001(usados: 50, siguiente: null)],
      );
      await _abrirFormulario(t, repo);

      expect(find.text('Sin recibos'), findsOneWidget);
      expect(find.text('Sin recibos libres'), findsOneWidget);
      expect(find.text('Terminados'), findsOneWidget);
    });

    testWidgets('sin talonario, el recibo es opcional y va vacío', (t) async {
      final repo = _CajaChica(
        reglas: const ReglasReciboCajaChica(
          titulo: 'Sin talonario de caja chica',
          regla:
              'Tu sucursal no tiene talonarios de caja chica entregados. '
              'El número de recibo es opcional.',
          obligatorio: false,
        ),
      );
      await _abrirFormulario(t, repo);

      expect(find.textContaining('Próximo recibo'), findsNothing);
      expect(
        find.widgetWithText(TextFormField, 'Número de recibo (opcional)'),
        findsOneWidget,
      );
      expect(find.text('Sin talonario de caja chica'), findsOneWidget);
      await _registrar(t);
      expect(repo.valesMandados, [null]);
    });

    testWidgets(
      'si el servidor lo pide, el recibo es obligatorio sin talonario',
      (t) async {
        final repo = _CajaChica(
          reglas: const ReglasReciboCajaChica(
            titulo: 'Falta el talonario de caja chica',
            regla: 'Para registrar un egreso hace falta un talonario.',
            obligatorio: true,
          ),
        );
        await _abrirFormulario(t, repo);

        expect(
          find.widgetWithText(TextFormField, 'Número de recibo'),
          findsOneWidget,
        );
        expect(find.text('Falta el talonario de caja chica'), findsOneWidget);
      },
    );
  });

  group('talonarios: uso en caja chica', () {
    testWidgets('dice cuántos se usaron, en qué egreso y cuáles se saltaron', (
      t,
    ) async {
      await _pintarUso(t, _vales(50, usados: {1, 2, 3, 5}));

      expect(find.text('Uso en caja chica'), findsOneWidget);
      expect(find.text('4 de 50'), findsOneWidget);
      expect(find.text('Quedan 45 recibos después del 5.'), findsOneWidget);
      expect(
        find.textContaining('Sin registrar antes del 5: 4.'),
        findsOneWidget,
      );
      expect(find.text('Pasajes 3'), findsOneWidget);
      expect(find.text('Entregado a ELIZABETH VILLARROEL'), findsNWidgets(4));
      expect(t.takeException(), isNull);
    });

    testWidgets('un talonario de otro tipo no pinta nada', (t) async {
      await _pintarUso(t, const []);
      expect(find.text('Uso en caja chica'), findsNothing);
    });
  });
}

TalonarioCajaChica _vcc001({
  int usados = 5,
  int? siguiente = 6,
  bool activo = false,
}) => TalonarioCajaChica(
  codTalonario: 1138,
  nroTalonario: 'VCC001',
  desde: 1,
  hasta: 50,
  usados: usados,
  libres: 50 - usados,
  siguienteVale: siguiente,
  activo: activo,
);

TalonarioCajaChica _talonario(
  String nro,
  int desde,
  int hasta, {
  int? siguiente,
  bool activo = false,
  String titular = '',
}) => TalonarioCajaChica(
  codTalonario: desde,
  nroTalonario: nro,
  desde: desde,
  hasta: hasta,
  libres: hasta - desde + 1,
  siguienteVale: siguiente,
  activo: activo,
  titular: titular,
);

List<ValeCajaChica> _vales(int total, {Set<int> usados = const {}}) => [
  for (var n = 1; n <= total; n++)
    usados.contains(n)
        ? ValeCajaChica(
          numVale: n,
          usado: true,
          fecha: DateTime(2026, 10, 6),
          nombreSucursal: 'CENTRAL',
          lote: 22,
          monto: 10.0 * n,
          descripcion: 'Pasajes $n',
          entregadoA: 'ELIZABETH VILLARROEL',
        )
        : ValeCajaChica(numVale: n),
];

Future<void> _abrirFormulario(
  WidgetTester t,
  _CajaChica repo, {
  bool abrir = true,
}) async {
  await t.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    ProviderScope(
      overrides: [cajaChicaFlujoRepoProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: CajaChicaScreen(nombreTarea: 'Caja Chica'),
      ),
    ),
  );
  await t.pumpAndSettle();
  if (!abrir) return;
  await t.tap(find.text('Registrar egreso'));
  await t.pumpAndSettle();
}

Future<void> _registrar(WidgetTester t) async {
  await t.enterText(find.widgetWithText(TextFormField, 'Monto'), '10');
  await t.tap(find.widgetWithText(FilledButton, 'Registrar'));
  await t.pumpAndSettle();
}

Future<void> _pintarUso(WidgetTester t, List<ValeCajaChica> vales) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        talonariosRepositoryProvider.overrideWithValue(_Talonarios(vales)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UsoEnCajaChica(codTalonario: BigInt.from(1138)),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

class _CajaChica implements CajaChicaFlujoRepository {
  _CajaChica({List<TalonarioCajaChica> talonarios = const [], this.reglas})
    : _talonarios = talonarios;

  final List<TalonarioCajaChica> _talonarios;
  final ReglasReciboCajaChica? reglas;
  final valesMandados = <int?>[];

  @override
  Future<List<CajaChicaEntity>> listarDelLote() async => [
    CajaChicaEntity(
      idCC: 1,
      montoIng: 1000,
      montoEg: 0,
      saldo: 1000,
      descripcion: 'Saldo inicial del lote',
      lote: 3,
      audUsuario: 1,
    ),
    CajaChicaEntity(
      idCC: 2,
      montoIng: 0,
      montoEg: 50,
      saldo: 950,
      numVale: 5,
      nroTalonario: 'VCC001',
      descripcion: 'Pasajes',
      lote: 3,
      audUsuario: 1,
    ),
  ];

  @override
  Future<List<TalonarioCajaChica>> talonarios() async => _talonarios;

  @override
  Future<ReglasReciboCajaChica?> reglasRecibo() async => reglas;

  @override
  Future<void> registrarEgreso({
    required double montoEg,
    required String descripcion,
    int? codEmpDestino,
    int? numFactura,
    int? numVale,
    String? moneda,
  }) async => valesMandados.add(numVale);

  @override
  Future<void> cerrarLote() async {}

  @override
  Future<List<Map<String, dynamic>>> obtenerHistorialLotes() async => [];

  @override
  Future<List<Map<String, dynamic>>> buscarEmpleados(String texto) async => [];

  @override
  Future<Uint8List> generarReportePdf({required int lote}) async =>
      Uint8List(0);
}

class _Talonarios extends Fake implements TalonariosRepository {
  _Talonarios(this.vales);

  final List<ValeCajaChica> vales;

  @override
  Future<List<ValeCajaChica>> usoEnCajaChica(BigInt codTalonario) async =>
      vales;
}
