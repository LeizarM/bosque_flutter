// Verificar Cierre (tarea 39) por responsables, archivo SQL 81.
//
// Lo que estas pruebas cuidan (Marcelo, 2026-10-07):
// - La 39 es una sola tarea que hacen varios: cada uno ve SOLO las secciones y
//   sucursales que la matriz le asigna, y nada más se lee.
// - Cada celda revisa el día hábil anterior de SU sucursal: con un feriado,
//   dos sucursales pueden revisar días distintos.
// - Las reglas de la firma son del servidor: la app manda y muestra su mensaje.
// - Archivo 86: una sección nueva (con fuente de otro módulo) sale en el orden
//   del catálogo, con sus filas y su marca; si la fuente falla, el motivo.
// - Archivo 91: los arqueos que nadie hizo salen con quién y su cargo, sin
//   botón, y no traban el Cierre de Operaciones.
// - Archivo 92: se puede mirar un día anterior, solo para consultar: sin
//   marcar ni firmar, con las firmas que tuvo ese día.
import 'dart:typed_data';

import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/verificar_cierre_provider.dart';
import 'package:bosque_flutter/data/models/cierre_operaciones_model.dart';
import 'package:bosque_flutter/data/models/firma_cierre_model.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/firma_cierre_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/cierre_operaciones_repository.dart';
import 'package:bosque_flutter/domain/repositories/firma_cierre_repository.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/verificar_cierre_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _lunes = DateTime(2026, 10, 6);
final _jueves = DateTime(2026, 9, 25);
final _miercoles = DateTime(2026, 9, 23);

class _Paneles implements CierreOperacionesRepository {
  final pedidos = <String>[];
  List<ArqueoDelCierre> Function(DateTime fecha) arqueosDe = (_) => [];

  /// Lo que hace el servidor al marcar (firmar o anular la celda).
  void Function(int idAC, bool revisado)? alMarcar;

  String _dia(DateTime f) => f.toIso8601String().substring(0, 10);

  @override
  Future<List<ArqueoDelCierre>> arqueos(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async {
    pedidos.add('arqueos ${_dia(fecha)} todas=$todasSucursales');
    return arqueosDe(fecha);
  }

  @override
  Future<List<TraspasoMovCajaEntity>> traspasos({
    required DateTime fecha,
  }) async {
    pedidos.add('traspasos ${_dia(fecha)}');
    return [];
  }

  @override
  Future<List<LlegadaDelCierre>> cajaFuerte(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async {
    pedidos.add('cajaFuerte ${_dia(fecha)} todas=$todasSucursales');
    return [];
  }

  @override
  Future<List<ChequeDelCierre>> cheques(
    int idBitTarea, {
    required DateTime fecha,
  }) async {
    pedidos.add('cheques ${_dia(fecha)}');
    return [];
  }

  @override
  Future<List<BitacoraCumplimientoEntity>> tareas(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async {
    pedidos.add('tareas ${_dia(fecha)} todas=$todasSucursales');
    return [];
  }

  @override
  Future<void> marcarArqueoRevisado(
    int idAC, {
    required int idBitTarea,
    bool revisado = true,
  }) async => alMarcar?.call(idAC, revisado);

  @override
  Future<void> marcarLlegadaVerificada(
    int idRp, {
    required int idBitTarea,
    bool verificada = true,
  }) async {}

  @override
  Future<int> cerrar(
    int idBitTarea, {
    required ModoCierre modo,
    required DateTime fecha,
  }) async => 0;

  @override
  Future<Uint8List> pdfArqueo(int idAC) async => Uint8List(0);

  @override
  Future<Uint8List> pdfCajaFuerte(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async => Uint8List(0);

  @override
  Future<Uint8List> pdfCierre(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async => Uint8List(0);
}

class _Firmas implements FirmaCierreRepository {
  List<CeldaCierre> celdas;

  /// Si no es null, el servidor rechaza la firma con este mensaje.
  String? rechazo;
  Object? falla;
  final firmadas = <String>[];

  /// Las filas de las secciones con fuente, por código; y si su lectura falla.
  final filas = <String, List<FilaSeccion>>{};
  String? fallaFuente;
  final marcas = <String>[];

  /// El día pedido en cada lectura de filas (null = el de la celda).
  final fechasFilas = <DateTime?>[];
  List<CeldaTablero> celdasTablero = [];

  _Firmas(this.celdas);

  @override
  Future<List<CeldaCierre>> misSecciones(int idBitTarea) async {
    if (falla != null) throw falla!;
    return celdas;
  }

  @override
  Future<void> firmar(int idBitTarea, CeldaCierre celda, {String? obs}) async {
    if (rechazo != null) throw Exception(rechazo);
    firmadas.add('${celda.clave} obs=$obs');
    celdas = [
      for (final c in celdas)
        c.clave == celda.clave
            ? _celda(
              c.seccion,
              c.codSucursal,
              c.nombreSucursal,
              c.fechaRevisada,
              firmada: true,
              codigo: c.codigo,
              nombre: c.nombreSeccion,
            )
            : c,
    ];
  }

  @override
  Future<void> anular(int idFC, {required String motivo}) async {}

  @override
  Future<List<FilaSeccion>> filasSeccion(
    int idBitTarea,
    CeldaCierre celda, {
    DateTime? fecha,
  }) async {
    fechasFilas.add(fecha);
    if (fallaFuente != null) throw Exception(fallaFuente);
    return filas[celda.codigo] ?? const [];
  }

  @override
  Future<void> marcarFila(
    int idBitTarea,
    CeldaCierre celda,
    FilaSeccion fila, {
    required bool revisada,
  }) async {
    marcas.add('${celda.codigo} ${fila.clave} $revisada');
  }

  @override
  Future<List<CeldaTablero>> tablero({
    DateTime? desde,
    DateTime? hasta,
  }) async => celdasTablero;

  @override
  Future<List<ResumenCierrePersona>> resumen({
    DateTime? desde,
    DateTime? hasta,
  }) async => [];
}

/// [seccion] null = una sección con fuente; entonces van [codigo] y [nombre].
CeldaCierre _celda(
  PanelCierre? seccion,
  int? codSucursal,
  String sucursal,
  DateTime fecha, {
  bool firmada = false,
  bool conBoton = true,
  String? detalle,
  String? codigo,
  String? nombre,
}) => CeldaCierre(
  seccion: seccion,
  codigo: codigo ?? seccion!.codigo,
  nombreSeccion: nombre ?? seccion?.name ?? codigo!,
  codSucursal: codSucursal,
  nombreSucursal: sucursal,
  fechaRevisada: fecha,
  idFC: firmada ? 1 : null,
  firmadoPor: firmada ? 'OSCAR ZABALLA' : null,
  conBoton: conBoton,
  detalle: detalle,
);

ArqueoDelCierre _arqueo(int idAC, String sucursal) =>
    ArqueoDelCierre(idAC: idAC, encargado: 'CAJERO', sucursal: sucursal);

/// Una tarea de arqueo que nadie registró (archivo SQL 91).
ArqueoDelCierre _sinHacer(String persona, String sucursal) => ArqueoDelCierre(
  idAC: 0,
  encargado: persona,
  sucursal: sucursal,
  tarea: 'Arqueo de Caja',
  hecho: false,
  cargo: 'CAJERO',
  fueRealizado: 0,
  obs: 'Venció sin hacerse.',
);

Future<void> _dejarCargar() => Future<void>.delayed(Duration.zero);

void main() {
  group('solo lo que le toca', () {
    test('lee solo las secciones de sus celdas, de toda la empresa', () async {
      final paneles = _Paneles();
      final firmas = _Firmas([
        _celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes),
        _celda(PanelCierre.tareas, null, 'Toda la empresa', _lunes),
      ]);
      final n = VerificarCierreNotifier(paneles, firmas, 900);
      await _dejarCargar();
      await _dejarCargar();

      expect(n.state.secciones, [PanelCierre.arqueos, PanelCierre.tareas]);
      expect(
        paneles.pedidos,
        unorderedEquals([
          'arqueos 2026-10-06 todas=true',
          'tareas 2026-10-06 todas=true',
        ]),
      );
    });

    test('de los arqueos deja solo las sucursales que le tocan', () async {
      final paneles =
          _Paneles()
            ..arqueosDe =
                (_) => [_arqueo(1, 'CENTRAL'), _arqueo(2, 'SANTA CRUZ')];
      final firmas = _Firmas([
        _celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes),
      ]);
      final n = VerificarCierreNotifier(paneles, firmas, 900);
      await _dejarCargar();
      await _dejarCargar();

      expect(n.state.arqueos.filas.map((a) => a.idAC), [1]);
    });

    test('con un feriado, cada sucursal revisa su propio día', () async {
      final paneles =
          _Paneles()
            ..arqueosDe =
                (f) =>
                    f == _jueves
                        ? [_arqueo(1, 'CENTRAL'), _arqueo(2, 'SANTA CRUZ')]
                        : [_arqueo(3, 'CENTRAL'), _arqueo(4, 'SANTA CRUZ')];
      final firmas = _Firmas([
        _celda(PanelCierre.arqueos, 20, 'CENTRAL', _jueves),
        _celda(PanelCierre.arqueos, 24, 'SANTA CRUZ', _miercoles),
      ]);
      final n = VerificarCierreNotifier(paneles, firmas, 900);
      await _dejarCargar();
      await _dejarCargar();

      expect(
        paneles.pedidos,
        containsAll([
          'arqueos 2026-09-25 todas=true',
          'arqueos 2026-09-23 todas=true',
        ]),
      );
      // Central del jueves y Santa Cruz del miércoles.
      expect(n.state.arqueos.filas.map((a) => a.idAC), unorderedEquals([1, 4]));
    });
  });

  group('la firma', () {
    test('firmada, vuelve a leer las celdas y avisa', () async {
      final firmas = _Firmas([
        _celda(PanelCierre.tareas, null, 'Toda la empresa', _lunes),
        _celda(PanelCierre.cheques, null, 'Toda la empresa', _lunes),
      ]);
      final n = VerificarCierreNotifier(_Paneles(), firmas, 900);
      await _dejarCargar();

      final motivo = await n.firmar(
        n.state.celdasDe(PanelCierre.tareas).first,
        obs: 'Se avisó',
      );

      expect(motivo, isNull);
      expect(firmas.firmadas, ['R|E obs=Se avisó']);
      expect(n.state.firmadas, 1);
      expect(n.state.completa, isFalse);
    });

    test('si el servidor la rechaza, devuelve su mensaje tal cual', () async {
      final firmas = _Firmas([
          _celda(PanelCierre.tareas, null, 'Toda la empresa', _lunes),
        ])
        ..rechazo =
            'Hay 98 tarea(s) sin hacer: escribe tu observación antes de firmar.';
      final n = VerificarCierreNotifier(_Paneles(), firmas, 900);
      await _dejarCargar();

      final motivo = await n.firmar(n.state.celdas.filas.first);

      expect(
        motivo,
        'Hay 98 tarea(s) sin hacer: escribe tu observación antes de firmar.',
      );
      expect(n.state.firmadas, 0);
    });

    test('con todas las celdas firmadas, su parte queda completa', () async {
      final firmas = _Firmas([
        _celda(
          PanelCierre.tareas,
          null,
          'Toda la empresa',
          _lunes,
          firmada: true,
        ),
      ]);
      final n = VerificarCierreNotifier(_Paneles(), firmas, 900);
      await _dejarCargar();

      expect(n.state.completa, isTrue);
    });
  });

  group('la firma sola', () {
    test('el modelo lee si lleva botón; sin el dato, lo deja', () {
      Map<String, dynamic> j(Object? conBoton) => {
        'seccion': 'F',
        'nombreSeccion': 'Caja fuerte',
        'codSucursal': 23,
        'nombreSucursal': 'COCHABAMBA',
        'fechaRevisada': '2026-10-06 00:00:00',
        'conBoton': conBoton,
        'detalle': 'Faltan 2 por revisar: se firma sola al terminar.',
      };

      expect(FirmaCierreModel.celda(j(0)).conBoton, isFalse);
      expect(FirmaCierreModel.celda(j(1)).conBoton, isTrue);
      expect(FirmaCierreModel.celda(j(null)).conBoton, isTrue);
      expect(
        FirmaCierreModel.celda(j(0)).detalle,
        'Faltan 2 por revisar: se firma sola al terminar.',
      );
    });

    test('marcar el último arqueo vuelve a leer y avisa la firma', () async {
      final firmas = _Firmas([
        _celda(PanelCierre.arqueos, 23, 'COCHABAMBA', _lunes, conBoton: false),
      ]);
      final paneles =
          _Paneles()
            ..arqueosDe = ((_) => [_arqueo(7, 'COCHABAMBA')])
            // El servidor firma la celda con la última marca.
            ..alMarcar = (_, _) {
              firmas.celdas = [
                _celda(
                  PanelCierre.arqueos,
                  23,
                  'COCHABAMBA',
                  _lunes,
                  firmada: true,
                ),
              ];
            };
      final n = VerificarCierreNotifier(paneles, firmas, 900);
      await _dejarCargar();
      await _dejarCargar();

      await n.marcarArqueoRevisado(7);

      expect(n.state.firmadas, 1);
      expect(n.state.aviso, contains('se firmó'));
      expect(n.state.guardando, isEmpty);
    });

    test('quitar la marca de una celda firmada avisa la anulación', () async {
      final firmas = _Firmas([
        _celda(PanelCierre.arqueos, 23, 'COCHABAMBA', _lunes, firmada: true),
      ]);
      final paneles =
          _Paneles()
            ..arqueosDe = ((_) => [_arqueo(7, 'COCHABAMBA')])
            ..alMarcar = (_, _) {
              firmas.celdas = [
                _celda(PanelCierre.arqueos, 23, 'COCHABAMBA', _lunes),
              ];
            };
      final n = VerificarCierreNotifier(paneles, firmas, 900);
      await _dejarCargar();
      await _dejarCargar();

      await n.marcarArqueoRevisado(7, revisado: false);

      expect(n.state.firmadas, 0);
      expect(n.state.aviso, contains('Se anuló la firma'));
    });
  });

  group('en pantalla', () {
    testWidgets('mientras falta revisar no hay botón: dice qué falta', (
      t,
    ) async {
      await t.pumpWidget(
        _app(
          _Firmas([
            _celda(
              PanelCierre.cajaFuerte,
              23,
              'COCHABAMBA',
              _lunes,
              conBoton: false,
              detalle: 'Faltan 2 por revisar: se firma sola al terminar.',
            ),
          ]),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Firmar'), findsNothing);
      expect(
        find.text('Faltan 2 por revisar: se firma sola al terminar.'),
        findsOneWidget,
      );
    });

    testWidgets('sin celdas dice que no tiene secciones', (t) async {
      await t.pumpWidget(_app(_Firmas([])));
      await t.pumpAndSettle();

      expect(find.text('No tienes secciones en esta tarea'), findsOneWidget);
    });

    testWidgets('si no se pudo leer, ofrece reintentar', (t) async {
      await t.pumpWidget(_app(_Firmas([])..falla = Exception('Sin conexión')));
      await t.pumpAndSettle();

      expect(find.text('No se pudo leer tus secciones'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('cada celda trae su botón para firmar', (t) async {
      await t.pumpWidget(
        _app(
          _Firmas([
            _celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes),
            _celda(PanelCierre.arqueos, 24, 'SANTA CRUZ', _lunes),
          ]),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Firmar'), findsNWidgets(2));
      expect(find.text('0 de 2 secciones firmadas'), findsOneWidget);
    });
  });

  group('secciones con fuente (archivo 86)', () {
    test('el modelo deja sin panel la sección no propia y lee su fila', () {
      final c = FirmaCierreModel.celda({
        'seccion': 'G',
        'nombreSeccion': 'Vales del día',
        'queRevisar': 'Que cada vale tenga respaldo.',
        'propia': 0,
        'marcaPorFila': 1,
        'fechaRevisada': '2026-10-07',
      });
      expect(c.seccion, isNull);
      expect(c.conFuente, isTrue);
      expect(c.codigo, 'G');
      expect(c.clave, 'G|E');
      expect(
        FirmaCierreModel.celda({'seccion': 'A', 'propia': 1}).seccion,
        PanelCierre.arqueos,
      );
      // Un servidor sin el 86 no manda "propia": la A sigue siendo arqueos.
      expect(
        FirmaCierreModel.celda({'seccion': 'A'}).seccion,
        PanelCierre.arqueos,
      );

      final f = FirmaCierreModel.fila({
        'clave': ' 4809 ',
        'titulo': 'Vale 2510',
        'monto': 500,
        'hallazgo': 1,
        'motivo': 'Pasa el tope',
        'revisada': 0,
      }, codSucursalCelda: 20);
      expect(f.clave, '4809');
      expect(f.monto, 500.0);
      expect(f.hallazgo, isTrue);
      expect(f.id, '20|4809');
      expect(f.conMarca(true).revisada, isTrue);
    });

    testWidgets('se ve en el orden del servidor con sus filas, y marca', (
      t,
    ) async {
      final firmas = _Firmas([
        _celda(
          null,
          null,
          'Toda la empresa',
          _lunes,
          codigo: 'G',
          nombre: 'Vales del día',
        ),
        _celda(PanelCierre.tareas, null, 'Toda la empresa', _lunes),
      ]);
      firmas.filas['G'] = const [
        FilaSeccion(clave: '1', titulo: 'Vale 10 · ANA', monto: 50),
        FilaSeccion(
          clave: '2',
          titulo: 'Vale 11 · LUIS',
          monto: 900,
          hallazgo: true,
          motivo: 'Pasa el tope',
        ),
      ];
      await t.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(_app(firmas));
      await t.pumpAndSettle();

      final vales = t.getTopLeft(find.text('Vales del día')).dy;
      final tareas = t.getTopLeft(find.text('Tareas rutinarias del día')).dy;
      expect(vales, lessThan(tareas));
      expect(find.text('Vale 11 · LUIS'), findsOneWidget);
      expect(find.text('Pasa el tope'), findsOneWidget);
      expect(find.text('0/2 revisadas'), findsOneWidget);

      await t.tap(find.text('Marcar revisado').first);
      await t.pumpAndSettle();
      expect(firmas.marcas, ['G 1 true']);
      expect(find.text('1/2 revisadas'), findsOneWidget);
    });

    testWidgets('si la fuente falla, muestra el motivo y deja reintentar', (
      t,
    ) async {
      final firmas = _Firmas([
        _celda(
          null,
          null,
          'Toda la empresa',
          _lunes,
          codigo: 'G',
          nombre: 'Vales del día',
        ),
      ])..fallaFuente = 'No se pudo leer: Invalid object name.';
      await t.pumpWidget(_app(firmas));
      await t.pumpAndSettle();

      expect(find.textContaining('Invalid object name'), findsOneWidget);
      expect(find.text('Reintentar'), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('un hallazgo largo salta de línea y no se sale de su columna', (
      t,
    ) async {
      final firmas = _Firmas([
        _celda(
          null,
          null,
          'Toda la empresa',
          _lunes,
          codigo: 'G',
          nombre: 'Saldo Actual Caja Chica',
        ),
      ]);
      firmas.filas['G'] = const [
        FilaSeccion(
          clave: '30',
          titulo: 'Caja chica COCHABAMBA',
          detalle: 'Lote 30 · fondo Bs 200.00 · último movimiento 07/10/2026',
          monto: 1,
          hallazgo: true,
          motivo: 'Le queda menos del 20% del fondo: hay que reponer',
        ),
      ];
      // El ancho de la captura de Marcelo: ahí se salía 131 píxeles.
      await t.binding.setSurfaceSize(const Size(1300, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(_app(firmas));
      await t.pumpAndSettle();

      expect(
        find.text('Le queda menos del 20% del fondo: hay que reponer'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  });

  group('arqueos sin hacer (archivo 91)', () {
    test('el modelo: sin la columna es un arqueo registrado', () {
      final viejo = CierreOperacionesModel.arqueo({
        'idAC': 9,
        'nombreCompletoEncargado': 'PEDRO QUISPE',
      });
      expect(viejo.hecho, isTrue);

      final a = CierreOperacionesModel.arqueo({
        'idAC': null,
        'nombreCompletoEncargado': 'RONALDO PEREZ LIMACHI',
        'nombreSucursal': 'CENTRAL',
        'obs': 'Venció sin hacerse.',
        'hecho': 0,
        'cargo': 'CAJERO',
        'fueRealizado': 0,
      });
      expect(a.hecho, isFalse);
      expect(a.cargo, 'CAJERO');
      expect(a.fueRealizado, 0);
      expect(a.comoRevisado().hecho, isFalse);
    });

    testWidgets('salen con quién y su cargo, sin botón, en tabla', (t) async {
      final paneles =
          _Paneles()
            ..arqueosDe =
                (_) => [
                  _arqueo(7, 'COCHABAMBA'),
                  _sinHacer('RONALDO PEREZ', 'CENTRAL'),
                ];
      await t.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        _app(
          _Firmas([
            _celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes),
            _celda(PanelCierre.arqueos, 23, 'COCHABAMBA', _lunes),
          ]),
          paneles: paneles,
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('RONALDO PEREZ'), findsOneWidget);
      expect(find.text('CAJERO'), findsWidgets);
      expect(find.text('No se hizo'), findsOneWidget);
      expect(find.text('Venció sin hacerse.'), findsOneWidget);
      // Solo el registrado se marca, y solo él cuenta en el avance.
      expect(find.text('Marcar revisado'), findsOneWidget);
      expect(find.text('0/1 revisados'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('en el celular, como tarjeta', (t) async {
      final paneles =
          _Paneles()
            ..arqueosDe = (_) => [_sinHacer('RONALDO PEREZ', 'CENTRAL')];
      await t.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        _app(
          _Firmas([_celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes)]),
          paneles: paneles,
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('RONALDO PEREZ'), findsOneWidget);
      expect(find.text('No se hizo'), findsOneWidget);
      expect(find.text('1 sin hacer'), findsOneWidget);
      expect(find.text('Marcar revisado'), findsNothing);
      expect(find.text('No hubo arqueos de caja ese día.'), findsNothing);
      expect(t.takeException(), isNull);
    });

    test('en Cierre de Operaciones no traban: se confirma la sección', () {
      CierreOperacionesState con(List<ArqueoDelCierre> filas) =>
          CierreOperacionesState(
            modo: ModoCierre.cierre,
            fecha: _lunes,
            fechaOcurrencia: _lunes,
            arqueos: PanelDatos<ArqueoDelCierre>(filas: filas, cargado: true),
          );

      final soloSinHacer = con([_sinHacer('RONALDO PEREZ', 'CENTRAL')]);
      expect(soloSinHacer.filasSinMarcar(PanelCierre.arqueos), 0);
      expect(soloSinHacer.necesitaConfirmacion(PanelCierre.arqueos), isTrue);
      expect(soloSinHacer.seccionRevisada(PanelCierre.arqueos), isFalse);

      final mezcla = con([
        _arqueo(7, 'COCHABAMBA').comoRevisado(),
        _sinHacer('RONALDO PEREZ', 'CENTRAL'),
      ]);
      expect(mezcla.filasSinMarcar(PanelCierre.arqueos), 0);
      expect(mezcla.seccionRevisada(PanelCierre.arqueos), isTrue);
    });
  });

  group('un día anterior (archivo 92)', () {
    test('lee ese día en cada sección y sus firmas; volver lo deja como antes', () async {
      final paneles = _Paneles();
      final firmas = _Firmas([
          _celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes),
          _celda(
            null,
            null,
            'Toda la empresa',
            _lunes,
            codigo: 'G',
            nombre: 'Saldo de caja chica',
          ),
        ])
        ..celdasTablero = [
          _firmaDel(_diaAnterior, 'CENTRAL'),
          // Otro día que el tablero también trae: no es el que se mira.
          _firmaDel(_lunes, 'CENTRAL', estado: EstadoCelda.sinFirmar),
        ];
      final n = VerificarCierreNotifier(paneles, firmas, 900);
      await _dejarCargar();
      await _dejarCargar();
      paneles.pedidos.clear();
      firmas.fechasFilas.clear();

      await n.consultarDia(_diaAnterior);

      expect(n.state.consultando, isTrue);
      expect(paneles.pedidos, ['arqueos 2026-10-03 todas=true']);
      expect(firmas.fechasFilas, [_diaAnterior]);
      expect(n.state.firmasDelDia.filas, hasLength(1));
      final celda = n.state.celdasDe(PanelCierre.arqueos).first;
      expect(n.state.firmaDelDia(celda)?.firmadoPor, 'OSCAR ZABALLA');

      paneles.pedidos.clear();
      await n.consultarDia(null);
      expect(n.state.consultando, isFalse);
      expect(paneles.pedidos, ['arqueos 2026-10-06 todas=true']);
    });

    test('elegir el mismo día de la tarea no es consultar', () async {
      final firmas = _Firmas([
        _celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes),
      ]);
      final n = VerificarCierreNotifier(_Paneles(), firmas, 900);
      await _dejarCargar();

      await n.consultarDia(DateTime(2026, 10, 6, 15, 30));
      expect(n.state.consultando, isFalse);
    });

    testWidgets('se ve qué pasó ese día, sin marcar ni firmar', (t) async {
      final paneles =
          _Paneles()..arqueosDe = (_) => [_arqueo(7, 'CENTRAL')];
      final firmas = _Firmas([
        _celda(PanelCierre.arqueos, 20, 'CENTRAL', _lunes),
      ])..celdasTablero = [_firmaDel(_diaAnterior, 'CENTRAL')];
      await t.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(_app(firmas, paneles: paneles));
      await t.pumpAndSettle();
      expect(find.text('Marcar revisado'), findsOneWidget);
      expect(find.text('Firmar'), findsOneWidget);

      final contenedor = ProviderScope.containerOf(
        t.element(find.byType(VerificarCierreScreen)),
      );
      await contenedor
          .read(verificarCierreProvider(900).notifier)
          .consultarDia(_diaAnterior);
      await t.pumpAndSettle();

      expect(find.textContaining('solo para consultar'), findsOneWidget);
      expect(find.text('Marcar revisado'), findsNothing);
      expect(find.text('Sin revisar'), findsOneWidget);
      expect(find.text('Firmar'), findsNothing);
      expect(find.textContaining('Firmó OSCAR ZABALLA'), findsOneWidget);
      expect(t.takeException(), isNull);

      await t.tap(find.text('Volver al 06/10/2026'));
      await t.pumpAndSettle();
      expect(find.text('Firmar'), findsOneWidget);
    });
  });
}

final _diaAnterior = DateTime(2026, 10, 3);

/// Lo que el tablero dice de una celda de un día ya pasado.
CeldaTablero _firmaDel(
  DateTime revisada,
  String sucursal, {
  EstadoCelda estado = EstadoCelda.aTiempo,
}) => CeldaTablero(
  fechaTarea: revisada.add(const Duration(days: 1)),
  fechaRevisada: revisada,
  seccion: PanelCierre.arqueos,
  nombreSeccion: 'arqueos',
  nombreSucursal: sucursal,
  estado: estado,
  firmadoPor: estado == EstadoCelda.sinFirmar ? null : 'OSCAR ZABALLA',
  fechaFirma:
      estado == EstadoCelda.sinFirmar ? null : DateTime(2026, 10, 4, 9, 12),
);

Widget _app(_Firmas firmas, {_Paneles? paneles}) => ProviderScope(
  overrides: [
    cierreOperacionesRepoProvider.overrideWithValue(paneles ?? _Paneles()),
    firmaCierreRepoProvider.overrideWithValue(firmas),
    userProvider.overrideWith((ref) => UserStateNotifier.sinStorage(_usuario)),
  ],
  child: const MaterialApp(
    home: VerificarCierreScreen(
      idBitTarea: 900,
      nombreTarea: 'Verificar Cierre de Operaciones',
    ),
  ),
);

final _usuario = LoginEntity(
  token: 'x',
  bearer: 'Bearer',
  nombreCompleto: 'ZABALLA MONASTERIOS OSCAR',
  cargo: 'GERENTE ADMINISTRATIVO',
  tipoUsuario: 'lim',
  codUsuario: 22,
  codEmpleado: 50,
  codEmpresa: 1,
  codCiudad: 1,
  login: 'ozaballa',
  versionApp: '1.0.1',
  codSucursal: 1,
  esAutorizador: 'N',
  estado: 'A',
  audUsuarioI: 22,
  nombreSucursal: 'CENTRAL',
  nombreCiudad: 'LA PAZ',
  nombreEmpresa: 'IMPEXPAP',
  npassword: '',
  password: '',
  password2: '',
);
