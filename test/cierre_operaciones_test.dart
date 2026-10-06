// La revisión de Cierre de Operaciones: qué día muestra, qué secciones pide y
// cuándo deja cerrar.
//
// Tres decisiones de Marcelo (2026-09-11) que estas pruebas cuidan:
//
// - La tarea es el permiso: quien tiene la ocurrencia del día ve las cinco
//   secciones. No hay permisos de botón en el medio.
// - "Tiene que revisar TODO, una vez que revise todo, recién se completa": el
//   cierre no se habilita hasta que las cinco estén revisadas.
// - Lo que hizo otra persona no se vuelve a hacer aquí: los traspasos de Caja
//   AXA los marca el cajero en su tarea, y esta pantalla solo los mira. El
//   visto bueno del arqueo y el de la llegada sí son de quien revisa.
import 'dart:typed_data';

import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/models/traspaso_mov_caja_model.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';
import 'package:bosque_flutter/domain/entities/cierre_operaciones_entity.dart';
import 'package:bosque_flutter/domain/entities/login_entity.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/domain/repositories/cierre_operaciones_repository.dart';
import 'package:bosque_flutter/presentation/screens/tareas-rutinarias/cierre_operaciones_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _dia = DateTime(2026, 9, 11);

class _RepoFalso implements CierreOperacionesRepository {
  /// Qué se pidió, en orden: 'arqueos 2026-09-11 todas=false'.
  final pedidos = <String>[];
  final cierres = <String>[];
  final marcados = <String>[];

  List<ArqueoDelCierre> arqueosDe = [];
  List<TraspasoMovCajaEntity> traspasosDe = [];
  List<LlegadaDelCierre> cajaFuerteDe = [];
  List<ChequeDelCierre> chequesDe = [];
  List<BitacoraCumplimientoEntity> tareasDe = [];

  /// Secciones que tienen que fallar, por nombre.
  final fallan = <String>{};

  String _clave(String panel, DateTime fecha, bool todas) =>
      '$panel ${fecha.toIso8601String().substring(0, 10)} todas=$todas';

  List<T> _responder<T>(String panel, DateTime fecha, bool todas, List<T> filas) {
    pedidos.add(_clave(panel, fecha, todas));
    if (fallan.contains(panel)) throw Exception('$panel no responde');
    return filas;
  }

  @override
  Future<List<ArqueoDelCierre>> arqueos(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async => _responder('arqueos', fecha, todasSucursales, arqueosDe);

  @override
  Future<List<TraspasoMovCajaEntity>> traspasos({required DateTime fecha}) async =>
      _responder('traspasos', fecha, false, traspasosDe);

  @override
  Future<List<LlegadaDelCierre>> cajaFuerte(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async => _responder('cajaFuerte', fecha, todasSucursales, cajaFuerteDe);

  @override
  Future<List<ChequeDelCierre>> cheques(
    int idBitTarea, {
    required DateTime fecha,
  }) async => _responder('cheques', fecha, false, chequesDe);

  @override
  Future<List<BitacoraCumplimientoEntity>> tareas(
    int idBitTarea, {
    required DateTime fecha,
    bool todasSucursales = false,
  }) async => _responder('tareas', fecha, todasSucursales, tareasDe);

  @override
  Future<void> marcarArqueoRevisado(
    int idAC, {
    required int idBitTarea,
    bool revisado = true,
  }) async {
    marcados.add(
      revisado
          ? 'arqueo:$idAC ocurrencia=$idBitTarea'
          : 'arqueo:$idAC quitado ocurrencia=$idBitTarea',
    );
  }

  @override
  Future<void> marcarLlegadaVerificada(
    int idRp, {
    required int idBitTarea,
    bool verificada = true,
  }) async {
    marcados.add(
      verificada
          ? 'llegada:$idRp ocurrencia=$idBitTarea'
          : 'llegada:$idRp quitado ocurrencia=$idBitTarea',
    );
  }

  @override
  Future<int> cerrar(
    int idBitTarea, {
    required ModoCierre modo,
    required DateTime fecha,
  }) async {
    cierres.add(
      '$idBitTarea ${modo.name} ${fecha.toIso8601String().substring(0, 10)}',
    );
    return 1;
  }

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

/// Deja correr la lectura que el notifier programa al nacer.
Future<void> _dejarCargar() => Future<void>.delayed(Duration.zero);

CierreOperacionesNotifier _abrir(
  _RepoFalso repo, {
  ModoCierre modo = ModoCierre.verificacion,
}) => CierreOperacionesNotifier(
  repo,
  AperturaCierre(idBitTarea: 900, modo: modo, fechaOcurrencia: _dia),
);

/// Da por revisadas las secciones que no tienen nada que marcar.
void _confirmarLoQueFalta(CierreOperacionesNotifier n) {
  for (final panel in PanelCierre.values) {
    if (n.state.necesitaConfirmacion(panel)) n.confirmarSeccion(panel, true);
  }
}

TraspasoMovCajaEntity _traspaso({required int idTrasp, int? fueVerificado}) =>
    TraspasoMovCajaModel.fromJson({
      'idTrasp': idTrasp,
      'bd': 'PRODPAP',
      'fecha': '2026-09-11 00:00:00',
      'account': '1110108',
      'contraAct': '1110101',
      'dolares': 9136.21,
      'bs': 110000,
      'fueVerificado': fueVerificado,
    }).toEntity();

ArqueoDelCierre _arqueo({required int idAC, bool revisado = false}) =>
    ArqueoDelCierre(idAC: idAC, encargado: 'QUISPE RONALDO', revisado: revisado);

BitacoraCumplimientoEntity _tarea(Cumplimiento estado) =>
    BitacoraCumplimientoEntity(
      idBitTarea: 1,
      nombreTareaRutinaria: 'Arqueo de Caja',
      nombreEmpleado: 'MAMANI EDWIN',
      cumplimiento: estado,
    );

void main() {
  group('el día que se revisa', () {
    test('abre en el día de la tarea y pide las cinco secciones', () async {
      final repo = _RepoFalso();
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();

      expect(repo.pedidos, [
        'arqueos 2026-09-11 todas=false',
        'traspasos 2026-09-11 todas=false',
        'cajaFuerte 2026-09-11 todas=false',
        'cheques 2026-09-11 todas=false',
        'tareas 2026-09-11 todas=false',
      ]);
      expect(notifier.state.fecha, _dia);
    });

    test('mirando otro día no se cierra', () async {
      final repo = _RepoFalso();
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();

      await notifier.cambiarFecha(DateTime(2026, 9, 8, 15, 30));
      _confirmarLoQueFalta(notifier);

      expect(repo.pedidos.last, 'tareas 2026-09-08 todas=false');
      expect(notifier.state.mirandoElDiaDeLaTarea, isFalse);
      expect(notifier.state.puedeCerrar, isFalse);

      await notifier.cerrar();
      expect(repo.cierres, isEmpty);
    });

    test('cambiar de día borra lo que se había dado por revisado', () async {
      final repo = _RepoFalso();
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(notifier);
      expect(notifier.state.todoRevisado, isTrue);

      await notifier.cambiarFecha(DateTime(2026, 9, 8));
      expect(notifier.state.seccionesConfirmadas, isEmpty);
      expect(notifier.state.todoRevisado, isFalse);
    });

    test('"todas las sucursales" solo recarga las secciones de sucursal', () async {
      final repo = _RepoFalso();
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();
      repo.pedidos.clear();

      await notifier.alternarTodasSucursales(true);
      expect(repo.pedidos, [
        'arqueos 2026-09-11 todas=true',
        'cajaFuerte 2026-09-11 todas=true',
        'tareas 2026-09-11 todas=true',
      ]);
    });
  });

  group('una lectura que falla', () {
    test('no borra las otras secciones y no deja cerrar', () async {
      final repo =
          _RepoFalso()
            ..fallan.add('cheques')
            ..arqueosDe = [_arqueo(idAC: 1, revisado: true)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(notifier);

      final s = notifier.state;
      expect(s.cheques.error, isNotNull);
      expect(s.arqueos.filas, hasLength(1));
      expect(s.algoFallo, isTrue);
      expect(s.seccionRevisada(PanelCierre.cheques), isFalse);
      expect(s.puedeCerrar, isFalse);
    });

    test('reintentar esa sección la deja revisable', () async {
      final repo = _RepoFalso()..fallan.add('cheques');
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();

      repo.fallan.clear();
      await notifier.recargar(PanelCierre.cheques);
      _confirmarLoQueFalta(notifier);

      expect(notifier.state.cheques.cargado, isTrue);
      expect(notifier.state.puedeCerrar, isTrue);
    });
  });

  group('lo que hace otra persona aquí solo se mira', () {
    test('los traspasos no se marcan: la sección se confirma entera', () async {
      final repo = _RepoFalso()..traspasosDe = [_traspaso(idTrasp: 0)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();

      // Con una fila sin marcar del cajero, la sección igual se puede dar por
      // revisada: lo que falta es trabajo de él, no de quien revisa.
      expect(notifier.state.traspasosSinRevisar, 1);
      expect(notifier.state.filasSinMarcar(PanelCierre.traspasos), 0);
      expect(notifier.state.necesitaConfirmacion(PanelCierre.traspasos), isTrue);

      _confirmarLoQueFalta(notifier);
      expect(notifier.state.seccionRevisada(PanelCierre.traspasos), isTrue);
      expect(notifier.state.puedeCerrar, isTrue);
      expect(repo.marcados, isEmpty);
    });

    test('los cheques y las tareas del día también', () async {
      final repo =
          _RepoFalso()
            ..chequesDe = [
              const ChequeDelCierre(nroCheque: '123', textoResultado: 'SIN COBRAR'),
            ]
            ..tareasDe = [_tarea(Cumplimiento.noRealizada)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();

      expect(notifier.state.necesitaConfirmacion(PanelCierre.cheques), isTrue);
      expect(notifier.state.necesitaConfirmacion(PanelCierre.tareas), isTrue);

      _confirmarLoQueFalta(notifier);
      expect(notifier.state.todoRevisado, isTrue);
    });
  });

  group('revisar todo antes de cerrar', () {
    test('un arqueo sin visto bueno no deja cerrar, y marcándolo sí', () async {
      final repo = _RepoFalso()..arqueosDe = [_arqueo(idAC: 7)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(notifier);

      expect(notifier.state.puedeCerrar, isFalse);
      expect(notifier.state.faltaParaCerrar, ['1 arqueo por revisar']);
      expect(notifier.state.necesitaConfirmacion(PanelCierre.arqueos), isFalse);

      await notifier.marcarArqueoRevisado(7);

      expect(repo.marcados, ['arqueo:7 ocurrencia=900']);
      expect(notifier.state.seccionRevisada(PanelCierre.arqueos), isTrue);
      expect(notifier.state.puedeCerrar, isTrue);
    });

    test('una llegada sin verificar tampoco', () async {
      final repo = _RepoFalso()..cajaFuerteDe = [const LlegadaDelCierre(idRp: 5)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(notifier);

      expect(notifier.state.faltaParaCerrar, ['1 llegada por verificar']);

      await notifier.marcarLlegadaVerificada(5);

      expect(repo.marcados, ['llegada:5 ocurrencia=900']);
      expect(notifier.state.puedeCerrar, isTrue);
    });

    test('quitar el visto bueno deja el arqueo otra vez por revisar', () async {
      // Marcelo, 2026-10-05: "a veces se equivocan y tiene que volver a como
      // estaba". Desmarcado, el día vuelve a no poder cerrarse.
      final repo = _RepoFalso()..arqueosDe = [_arqueo(idAC: 7)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(notifier);

      await notifier.marcarArqueoRevisado(7);
      expect(notifier.state.puedeCerrar, isTrue);

      await notifier.marcarArqueoRevisado(7, revisado: false);

      expect(repo.marcados, [
        'arqueo:7 ocurrencia=900',
        'arqueo:7 quitado ocurrencia=900',
      ]);
      expect(notifier.state.puedeCerrar, isFalse);
      expect(notifier.state.faltaParaCerrar, ['1 arqueo por revisar']);
    });

    test('y quitar la verificación de una llegada, igual', () async {
      final repo = _RepoFalso()..cajaFuerteDe = [const LlegadaDelCierre(idRp: 5)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(notifier);

      await notifier.marcarLlegadaVerificada(5);
      expect(notifier.state.puedeCerrar, isTrue);

      await notifier.marcarLlegadaVerificada(5, verificada: false);

      expect(repo.marcados, [
        'llegada:5 ocurrencia=900',
        'llegada:5 quitado ocurrencia=900',
      ]);
      expect(notifier.state.puedeCerrar, isFalse);
      expect(notifier.state.faltaParaCerrar, ['1 llegada por verificar']);
    });

    test('una sección vacía se revisa con su interruptor', () async {
      final repo = _RepoFalso();
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();

      expect(notifier.state.necesitaConfirmacion(PanelCierre.arqueos), isTrue);
      expect(notifier.state.puedeCerrar, isFalse);

      _confirmarLoQueFalta(notifier);
      expect(notifier.state.todoRevisado, isTrue);
      expect(notifier.state.puedeCerrar, isTrue);
    });

    test('lo que falta se dice en palabras', () async {
      final repo =
          _RepoFalso()
            ..arqueosDe = [_arqueo(idAC: 1), _arqueo(idAC: 2, revisado: true)]
            ..traspasosDe = [_traspaso(idTrasp: 71, fueVerificado: 1)]
            ..cajaFuerteDe = [const LlegadaDelCierre(idRp: 5)];
      final notifier = _abrir(repo);
      addTearDown(notifier.dispose);
      await _dejarCargar();

      expect(notifier.state.faltaParaCerrar, [
        '1 arqueo por revisar',
        'confirmar los traspasos',
        '1 llegada por verificar',
        'confirmar los cheques',
        'confirmar las tareas del día',
      ]);
    });
  });

  group('cerrar', () {
    test('el modo decide qué se cierra, siempre con el día de la tarea', () async {
      final repo = _RepoFalso();

      final cierre = _abrir(repo, modo: ModoCierre.cierre);
      addTearDown(cierre.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(cierre);
      await cierre.cerrar();

      final verificacion = _abrir(repo, modo: ModoCierre.verificacion);
      addTearDown(verificacion.dispose);
      await _dejarCargar();
      _confirmarLoQueFalta(verificacion);
      await verificacion.cerrar();

      expect(repo.cierres, [
        '900 cierre 2026-09-11',
        '900 verificacion 2026-09-11',
      ]);
    });
  });

  group('en pantalla', () {
    testWidgets('el traspaso se ve como quedó, sin botones para marcarlo', (
      t,
    ) async {
      final repo = _RepoFalso()..traspasosDe = [_traspaso(idTrasp: 0)];
      await t.pumpWidget(_app(repo));
      await t.pumpAndSettle();

      expect(find.text('Sin revisar'), findsOneWidget);
      expect(find.text('Cuadra'), findsNothing);
      expect(find.text('No cuadra'), findsNothing);
    });

    testWidgets('las secciones sin nada que marcar traen su interruptor', (
      t,
    ) async {
      final repo = _RepoFalso();
      await t.pumpWidget(_app(repo));
      await t.pumpAndSettle();

      // Una por sección: las cinco vinieron vacías.
      expect(find.text('Revisado'), findsNWidgets(5));
    });
  });
}

/// La pantalla con un usuario cualquiera: la tarea es el permiso, así que no
/// hacen falta botones de la vista 78.
Widget _app(_RepoFalso repo, {ModoCierre modo = ModoCierre.verificacion}) =>
    ProviderScope(
      overrides: [
        cierreOperacionesRepoProvider.overrideWithValue(repo),
        userProvider.overrideWith(
          (ref) => UserStateNotifier.sinStorage(_usuario),
        ),
      ],
      child: MaterialApp(
        home: CierreOperacionesScreen(
          idBitTarea: 900,
          nombreTarea: 'Verificar Cierre de Operaciones',
          modo: modo,
          fecha: _dia,
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
  codEmpleado: 20,
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
